package main

import rl "vendor:raylib"
import "core:fmt"

ColorPickerConfig :: struct {
    bounds: rl.Rectangle,
}

DrawConfig :: struct {
    isPenButtonPressed: bool,
    curColor: rl.Color,
}
screen_width :: 800
screen_height :: 450

main :: proc() {
    rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(screen_width, screen_height, "Raynotes")
	defer rl.CloseWindow()

	colorsSelection: DrawConfig = {
        curColor = rl.RED,
    }
    colorPickerConfig: ColorPickerConfig = {
        bounds = rl.Rectangle{10, 40, 100, 100}
    }

	target := rl.LoadRenderTexture(screen_width, screen_height)
	defer rl.UnloadRenderTexture(target)
	rl.BeginTextureMode(target)
	rl.ClearBackground(rl.RAYWHITE)
	rl.EndTextureMode()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update(&colorsSelection, target, &colorPickerConfig)
		draw(target, &colorsSelection, &colorPickerConfig)
	}
}

draw :: proc(
	target: rl.RenderTexture2D,
	colorsSelection: ^DrawConfig,
    colorPickerConfig: ^ColorPickerConfig,
) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(rl.RAYWHITE)


	rl.DrawTextureRec(
		target.texture,
		rl.Rectangle{0, 0, f32(target.texture.width), f32(-target.texture.height)},
		rl.Vector2{0, 0},
		rl.WHITE,
	)

	mousePos := rl.GetMousePosition()
	if mousePos.y > 50 {
		rl.DrawCircle(rl.GetMouseX(), rl.GetMouseY(), 50, colorsSelection.curColor)
	}
    rl.GuiPanel(rl.Rectangle{0, 0, screen_width, 50}, nil)
    if rl.GuiButton(rl.Rectangle{10, 10, 60, 40}, "Pen Color") {
        colorsSelection.isPenButtonPressed = !colorsSelection.isPenButtonPressed
    }
    if colorsSelection.isPenButtonPressed {
        rl.GuiColorPicker(colorPickerConfig.bounds, nil, &colorsSelection.curColor)
    }
}

update :: proc(
	colorsSelection: ^DrawConfig,
	target: rl.RenderTexture2D,
    colorPickerConfig: ^ColorPickerConfig,
) {
	mousePos := rl.GetMousePosition()
    // TODO: remove hardcoded values
	if mousePos.y > 50 && rl.IsMouseButtonDown(.LEFT) && isOutOfBounds(mousePos.x, mousePos.y, colorPickerConfig.bounds) {
        colorsSelection.isPenButtonPressed = false
		mousePos := rl.GetMousePosition()
		rl.BeginTextureMode(target)
        rl.DrawCircle(
            i32(mousePos.x),
            i32(mousePos.y),
            20,
            colorsSelection.curColor
        )
		rl.EndTextureMode()
	}
}

isOutOfBounds :: proc(mx, my : f32, bounds: rl.Rectangle) -> bool {
    // +20 because how the color picker works
    result := (mx >= bounds.x && mx <= bounds.x + bounds.width + 20) && (my >= bounds.y && my <= bounds.y + bounds.height)
    fmt.printf("result: %v, mx: %v, my: %v, bounds: %v\n", result, mx, my, bounds)
    return !result
}
