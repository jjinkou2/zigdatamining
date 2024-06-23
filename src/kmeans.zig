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

const colors = .{ rl.Color.gold, rl.Color.pink, rl.Color.maroon, rl.Color.lime, rl.Color.sky_blue, rl.Color.blue, rl.Color.violet };

// means
const K = 3;

const PI = 3.14159265358979323846;

const Circle = struct {
    center: rl.Vector2,
    radius: f32,
};

pub fn myRand() f32 {
    var seed: u64 = undefined;
    std.posix.getrandom(std.mem.asBytes(&seed)) catch unreachable;
    var rand = std.rand.DefaultPrng.init(seed);
    return rand.random().float(f32);
}

pub fn generateSamples(center: rl.Vector2, radius: f32, count: usize, samples: *SampleList) !void {
    for (0..count) |_| {
        const angle = myRand() * 2 * PI; // sample inside cluster will have this angle
        const mag = std.math.sqrt(myRand()); // it will be distant from the cluster's center with this magnitude
        const sample: Sample = .{ .point = .{ .x = center.x + @cos(angle) * mag * radius, .y = center.y + @sin(angle) * mag * radius } };
        try samples.append(sample);
    }
}

const Sample = struct {
    point: rl.Vector2,

    pub fn toScreenV(self: Sample) rl.Vector2 {
        // -20.0 .. 20.0 => 0..40 => 0..1
        const lx = MAX_X - MIN_X;
        const ly = MAX_Y - MIN_Y;
        // x normalisé
        const nx = (self.point.x - MIN_X) / lx; //  shift a 0..40 et ramene a 0..1
        const ny = (self.point.y - MIN_Y) / ly; //  shift a 0..40 et ramene a 0..1

        const width: f32 = @floatFromInt(rl.getScreenWidth());
        const height: f32 = @floatFromInt(rl.getScreenHeight());

        return rl.Vector2{ .x = nx * width, .y = height - ny * height };
    }
};

pub fn distribute(samples: *SampleList) !void {
    try generateSamples(.{ .x = 0, .y = 0 }, CLUSTER_RADIUS, 100, samples);
    try generateSamples(.{ .x = MIN_X * 0.5, .y = MAX_Y * 0.5 }, CLUSTER_RADIUS * 0.5, 50, samples);
    try generateSamples(.{ .x = MAX_X * 0.5, .y = MAX_Y * 0.5 }, CLUSTER_RADIUS * 0.5, 50, samples);
}
pub fn generateMeans(means: []Sample) void {
    for (means) |*mean| {
        mean.point.x = myRand() * (MAX_X - MIN_X) + MIN_X;
        mean.point.y = myRand() * (MAX_Y - MIN_Y) + MIN_Y;
    }
}
pub fn initClusters(clusters: []SampleList, samples: *SampleList, means: []Sample) !void {
    for (clusters) |*cluster| {
        cluster.clearRetainingCapacity();
    }
    // K means init == find samples nearest mean[k] and put it into the cluster[k]
    for (samples.items) |sample| {
        var k: usize = 0;
        var s = std.math.floatMax(f32);
        for (0..K) |j| {
            const sm = rl.Vector2.lengthSqr(rl.Vector2.subtract(sample.point, means[j].point));
            if (sm < s) {
                s = sm;
                k = j;
            }
        }
        try clusters[k].append(sample);
    }
}

const State = struct {
    samples: SampleList = undefined,
    means: [K]Sample = undefined,
    clusters: [K]SampleList = undefined,

    pub fn init(allocator: Allocator) !State {
        var samples = SampleList.init(allocator);
        var means: [K]Sample = undefined;
        var clusters: [K]SampleList = undefined;

        for (&clusters) |*cluster| {
            cluster.* = SampleList.init(allocator);
        }
        try distribute(&samples);
        generateMeans(&means);
        try initClusters(&clusters, &samples, &means);
        return .{ .samples = samples, .clusters = clusters, .means = means };
    }

    pub fn deinit(self: *State) void {
        self.samples.deinit();
        for (&self.clusters) |*cluster| {
            cluster.deinit();
        }
    }

    pub fn draw(self: State) void {
        inline for (0..K) |i| {
            const color = colors[i % colors.len];
            for (self.clusters[i].items) |sample| {
                rl.drawCircleV(sample.toScreenV(), SAMPLE_RADIUS, color);
            }
            rl.drawCircleV(self.means[i].toScreenV(), MEAN_RADIUS, color);
        }
    }
    pub fn generateNew(self: *State) !void {
        self.samples.clearRetainingCapacity();
        for (&self.clusters) |*cluster| {
            cluster.clearRetainingCapacity();
        }
        try distribute(&self.samples);
        generateMeans(&self.means);
        try initClusters(&self.clusters, &self.samples, &self.means);
    }
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const screenWidth = 800;
    const screenHeight = 600;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "K-means");
    defer rl.closeWindow(); // Close window and OpenGL context

    var state: State = try State.init(gpa.allocator());
    defer state.deinit();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
            try state.generateNew();
        }

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.getColor(0x181818AA));

        state.draw();
    }
}
