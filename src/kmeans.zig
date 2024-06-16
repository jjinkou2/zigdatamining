const std = @import("std");
const rl = @import("raylib");

const MIN_X = -20.0;
const MAX_X = 20.0;
const MIN_Y = -20.0;
const MAX_Y = 20.0;

const PI = 3.14159265358979323846;

const Circle = struct {
    x: f16,
    y: f16,
    radius: f16,
    color: rl.Color,

    pub fn init(x: f16, y: f16, radius: f16, color: rl.Color) Circle {
        return Circle{
            .x = x,
            .y = y,
            .radius = radius,
            .color = color,
        };
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

    pub fn toCircle(self: Sample) Circle {
        const lx: f16 = MAX_X - MIN_X;
        const ly: f16 = MAX_Y - MIN_Y;
        // x normalisé
        const nx: f32 = (self.x - MIN_X) / lx; //  shift a 0..40 et ramene a 0..1
        const ny: f32 = (self.y - MIN_Y) / ly; //  shift a 0..40 et ramene a 0..1

        const width: f32 = @floatFromInt(rl.getScreenWidth());
        const height: f32 = @floatFromInt(rl.getScreenHeight());

        return Circle.init(nx * width, height - ny * height, 10, rl.Color.red);
    }
};

pub fn project_sample_to_screen(sample: rl.Vector2) rl.Vector2 {
    // -20.0 .. 20.0 => 0..40 => 0..1

    const lx: f16 = MAX_X - MIN_X;
    const ly: f16 = MAX_Y - MIN_Y;
    // x normalisé
    const nx: f32 = (sample.x - MIN_X) / lx; //  shift a 0..40 et ramene a 0..1
    const ny: f32 = (sample.y - MIN_Y) / ly; //  shift a 0..40 et ramene a 0..1

    const width: f32 = @floatFromInt(rl.getScreenWidth());
    const height: f32 = @floatFromInt(rl.getScreenHeight());
    return rl.Vector2{ .x = nx * width, .y = height - ny * height };
}

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 600;

    rl.setConfigFlags(.{ .window_resizable = true });
    rl.initWindow(screenWidth, screenHeight, "K-means");
    defer rl.closeWindow(); // Close window and OpenGL context

    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.getColor(0x181818AA));
        const sample = rl.Vector2{ .x = 0, .y = 0 };
        const sample1 = Sample{ .x = 10, .y = 10 };
        const projectedSample = project_sample_to_screen(sample);
        const circle = sample1.toCircle();
        rl.drawCircleV(projectedSample, 10, rl.Color.red);
        rl.drawCircle(circle.x, circle.y, circle.radius, circle.color);

        //----------------------------------------------------------------------------------
    }
}
