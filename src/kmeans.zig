const std = @import("std");
const rl = @import("raylib");

const MIN_X = -20.0;
const MAX_X = 20.0;
const MIN_Y = -20.0;
const MAX_Y = 20.0;

const PI = 3.14159265358979323846;

const Circle = struct {
    position: rl.Vector2,
    radius: f16,
    color: rl.Color,

    pub fn init(self: *Circle, position: rl.Vector2, radius: f16, color: rl.Color) void {
        self.position = position;
        self.radius = radius;
        self.color = color;
    }
};

const Samples = struct { items: *rl.Vector2, count: usize, capacity: usize };

// pub fn generate_cluster(center: rl.Vector2, radius: f16, count: usize, samples: Samples) void {
//     var rand = std.rand.DefaultPrng.init(@as(u64, @bitCast(std.time.milliTimestamp())));
//     const num = rand.random().int(i32);
//     for (0..count) |i| {
//         const angle: f16 = num * 2 * PI;
//         const mag: f16 = num;
//
//         var sample = rl.Vector2{ .x = center.x + @cos(angle) * mag * radius, .y = center.y + @sin(angle) * mag * radius };
//     }
// }

const Sample = struct {
    x: f16,
    y: f16,

    pub fn init(self: *Sample, x: f16, y: f16) void {
        self.x = x;
        self.y = y;
    }

    pub fn toCircleV(self: *Sample, circle: *Circle, radius: f16, color: rl.Color) void {
        // -20.0 .. 20.0 => 0..40 => 0..1
        const lx: f16 = MAX_X - MIN_X;
        const ly: f16 = MAX_Y - MIN_Y;
        // x normalisé
        const nx: f16 = (self.*.x - MIN_X) / lx; //  shift a 0..40 et ramene a 0..1
        const ny: f16 = (self.*.y - MIN_Y) / ly; //  shift a 0..40 et ramene a 0..1

        const width: f16 = @floatFromInt(rl.getScreenWidth());
        const height: f16 = @floatFromInt(rl.getScreenHeight());

        const position = rl.Vector2{ .x = nx * width, .y = height - ny * height };
        circle.init(position, radius, color);
    }
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 600;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "K-means");
    defer rl.closeWindow(); // Close window and OpenGL context

    //--------------------------------------------------------------------------------------

    // const circle1 = Circle.init(.{ .x = 0, .y = 10 }, 10, rl.Color.red);
    // std.debug.print("ptr ext:{*}\n", .{&circle1});
    // std.debug.print("circle:{}\n", .{circle1});
    //
    // var circle2: Circle = undefined;
    // circle2.init1(.{ .x = 10, .y = 12 }, 11, rl.Color.blue);
    // std.debug.print("ptr ext:{*}\n", .{&circle2});
    // std.debug.print("circle2:{}\n", .{circle2});
    // //
    // const position = rl.Vector2{ .x = 20, .y = 22 };
    // var circle3 = Circle{ .position = position, .radius = 21, .color = rl.Color.red };
    //
    // init2(.{ .x = 30, .y = 52 }, 11, rl.Color.blue, &circle3);
    // std.debug.print("ptr ext:{*}\n", .{&circle3});
    // std.debug.print("circle3:{}\n", .{circle3});

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818AA));
        var sample: Sample = .{ .x = 0, .y = 0 };
        var circle: Circle = undefined;
        sample.toCircleV(&circle, 10, rl.Color.blue);
        rl.drawCircleV(circle.position, circle.radius, circle.color);

        //----------------------------------------------------------------------------------
    }
}
