// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");

const MIN_X = -20.0;
const MAX_X = 20.0;
const MIN_Y = -20.0;
const MAX_Y = 20.0;

pub fn project_sample_to_screen(sample: rl.Vector2) rl.Vector2 {
    // -20.0 .. 20.0 => 0..40 => 0..1

    const lx: f16 = MAX_X - MIN_X;
    const ly: f16 = MAX_Y - MIN_Y;
    // x normalizé
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
        const sample = rl.Vector2{ .x = -10, .y = -10 };
        const projectedSample = project_sample_to_screen(sample);
        rl.drawCircleV(projectedSample, 10, rl.Color.red);

        //----------------------------------------------------------------------------------
    }
}
