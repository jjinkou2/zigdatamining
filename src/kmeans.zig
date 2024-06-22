const std = @import("std");
const rl = @import("raylib");
const Allocator = std.mem.Allocator;
const SampleList = std.ArrayList(Sample);

const MIN_X = -20.0;
const MAX_X = 20.0;
const MIN_Y = -20.0;
const MAX_Y = 20.0;

const CLUSTER_RADIUS = 10.0;
const SAMPLE_RADIUS = 4.0;
const MEAN_RADIUS = 2 * SAMPLE_RADIUS;

//Colors
const RED = rl.Color.red;
const YELLOW = rl.Color.yellow;
const BLUE = rl.Color.blue;

const colors: [7]rl.Color = .{ rl.Color.gold, rl.Color.pink, rl.Color.maroon, rl.Color.lime, rl.Color.sky_blue, rl.Color.blue, rl.Color.violet };

// means
const K = 3;

const PI = 3.14159265358979323846;

const Circle = struct {
    center: rl.Vector2,
    radius: f32,
    color: rl.Color,
};

pub fn myRand() f32 {
    var seed: u64 = undefined;
    std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    var rand = std.rand.DefaultPrng.init(seed);
    return rand.random().float(f32);
}

pub fn generate_samples(center: rl.Vector2, radius: f32, count: usize, samples: *SampleList) !void {
    for (0..count) |_| {
        const angle = myRand() * 2 * PI; // sample inside cluster will have this angle
        const mag = std.math.sqrt(myRand()); // it will be distant from the cluster's center with this magnitude
        const sample: Sample = .{ .point = .{ .x = center.x + @cos(angle) * mag * radius, .y = center.y + @sin(angle) * mag * radius } };
        try samples.append(sample);
    }
}

const Sample = struct {
    point: rl.Vector2,

    pub fn toCircleV(self: Sample, radius: f32, color: rl.Color) Circle {
        // -20.0 .. 20.0 => 0..40 => 0..1
        const lx = MAX_X - MIN_X;
        const ly = MAX_Y - MIN_Y;
        // x normalisé
        const nx = (self.point.x - MIN_X) / lx; //  shift a 0..40 et ramene a 0..1
        const ny = (self.point.y - MIN_Y) / ly; //  shift a 0..40 et ramene a 0..1

        const width: f32 = @floatFromInt(rl.getScreenWidth());
        const height: f32 = @floatFromInt(rl.getScreenHeight());

        return Circle{ .center = rl.Vector2{ .x = nx * width, .y = height - ny * height }, .radius = radius, .color = color };
    }
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var samples = SampleList.init(gpa.allocator());
    defer samples.deinit();

    var clusters: [K]SampleList = undefined;
    for (&clusters) |*cluster| {
        cluster.* = SampleList.init(gpa.allocator());
    }
    defer {
        for (&clusters) |cluster| {
            cluster.deinit();
        }
    }

    const screenWidth = 800;
    const screenHeight = 600;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "K-means");
    defer rl.closeWindow(); // Close window and OpenGL context

    var means: [K]Sample = undefined;

    for (&means) |*mean| {
        // pour info == lerp  == interpolation lineaire
        // mean.x = myRand() * (MAX_X - MIN_X) + MIN_X;
        // mean.y = myRand() * (MAX_Y - MIN_Y) + MIN_Y;
        mean.point.x = myRand() * (MAX_X - MIN_X) + MIN_X;
        mean.point.y = myRand() * (MAX_Y - MIN_Y) + MIN_Y;
    }

    // init samples
    try generate_samples(.{ .x = 0, .y = 0 }, CLUSTER_RADIUS, 100, &samples);
    try generate_samples(.{ .x = MIN_X * 0.5, .y = MAX_Y * 0.5 }, CLUSTER_RADIUS * 0.5, 50, &samples);
    try generate_samples(.{ .x = MAX_X * 0.5, .y = MAX_Y * 0.5 }, CLUSTER_RADIUS * 0.5, 50, &samples);

    var k: i16 = -1;
    var s = std.math.floatMax(f32);
    // K means init == find samples nearest mean[k] and put it into the cluster[k]
    for (samples.items) |sample| {
        for (means, 0..) |mean, j| {
            const sm = rl.lengthSqr(rl.subtractValue(sample.point, mean.point));
            if (sm < s) {
                s = sm;
                k = j;
            }
        }
    }

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
            samples.clearRetainingCapacity();
            try generate_samples(.{ .x = 0, .y = 0 }, CLUSTER_RADIUS, 100, &samples);
            try generate_samples(.{ .x = MIN_X * 0.5, .y = MAX_Y * 0.5 }, CLUSTER_RADIUS * 0.5, 50, &samples);
            try generate_samples(.{ .x = MAX_X * 0.5, .y = MAX_Y * 0.5 }, CLUSTER_RADIUS * 0.5, 50, &samples);
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.getColor(0x181818AA));

        for (samples.items) |sample| {
            const circle = sample.toCircleV(SAMPLE_RADIUS, RED);
            rl.drawCircleV(circle.center, circle.radius, circle.color);
        }

        inline for (means, 0..) |sample, i| {
            const circle = sample.toCircleV(MEAN_RADIUS, colors[i % colors.len]);
            rl.drawCircleV(circle.center, circle.radius, circle.color);
        }
    }
}
