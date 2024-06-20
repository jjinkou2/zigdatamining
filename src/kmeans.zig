const std = @import("std");
const rl = @import("raylib");
const Allocator = std.mem.Allocator;
const CircleList = std.ArrayList(Circle);

const MIN_X = -20.0;
const MAX_X = 20.0;
const MIN_Y = -20.0;
const MAX_Y = 20.0;

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

const Cluster = struct {
    center: rl.Vector2,
    radius: f32,
    color: rl.Color,

    pub fn init(center: rl.Vector2, radius: f32, color: rl.Color, count: usize, circles: *CircleList) !void {
        for (0..count) |_| {
            const angle = myRand() * 2 * PI;
            const mag = myRand();
            const sample: Sample = .{ .x = center.x + @cos(angle) * mag * radius, .y = center.y + @sin(angle) * mag * radius };
            try circles.append(sample.toCircleV(10, color));
        }
    }
};

const Sample = struct {
    x: f32,
    y: f32,

    pub fn toCircleV(self: Sample, radius: f32, color: rl.Color) Circle {
        // -20.0 .. 20.0 => 0..40 => 0..1
        const lx = MAX_X - MIN_X;
        const ly = MAX_Y - MIN_Y;
        // x normalisé
        const nx = (self.x - MIN_X) / lx; //  shift a 0..40 et ramene a 0..1
        const ny = (self.y - MIN_Y) / ly; //  shift a 0..40 et ramene a 0..1

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

    var circles = CircleList.init(gpa.allocator());
    defer circles.deinit();

    const screenWidth = 800;
    const screenHeight = 600;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "K-means");
    defer rl.closeWindow(); // Close window and OpenGL context

    try Cluster.init(.{ .x = 10, .y = 10 }, 10, rl.Color.red, 100, &circles);

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818AA));

        for (circles.items) |circle| {
            rl.drawCircleV(circle.center, circle.radius, circle.color);
        }

        //----------------------------------------------------------------------------------
    }
}
