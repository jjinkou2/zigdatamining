const std = @import("std");
const rl = @import("raylib");
const Allocator = std.mem.Allocator;

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
    circles: []Circle,
    allocator: Allocator,

    pub fn init(allocator: Allocator, center: rl.Vector2, radius: f32, color: rl.Color, count: usize) !Cluster {
        const circles = try allocator.alloc(Circle, count);
        errdefer allocator.free(circles);

        for (0..count) |i| {
            const angle = myRand() * 2 * PI;
            const mag = myRand();
            const sample: Sample = .{ .x = center.x + @cos(angle) * mag * radius, .y = center.y + @sin(angle) * mag * radius };
            circles[i] = sample.toCircleV(10, color);
        }

        return Cluster{ .allocator = allocator, .center = center, .radius = radius, .color = color, .circles = circles };
    }

    pub fn deinit(cluster: Cluster) void {
        const allocator = cluster.allocator;
        allocator.free(cluster.circles);
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
    const allocator = gpa.allocator();

    const screenWidth = 800;
    const screenHeight = 600;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "K-means");
    defer rl.closeWindow(); // Close window and OpenGL context

    const cluster = try Cluster.init(allocator, .{ .x = 10, .y = 10 }, 10, rl.Color.red, 100);
    defer cluster.deinit();

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818AA));

        for (cluster.circles) |circle| {
            rl.drawCircleV(circle.center, circle.radius, circle.color);
        }

        //----------------------------------------------------------------------------------
    }
}
