package main

import "core:fmt"
import rl "vendor:raylib"

ColorPickerConfig :: struct {
	bounds: rl.Rectangle,
}

PenConfig :: struct {
	isColorSelectorPressed: bool,
}

Config :: struct {
	curColor:          rl.Color,
	colorPickerConfig: ColorPickerConfig,
	penConfig:         PenConfig,
}
initial_screen_width :: 800
initial_screen_height :: 450

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(0, 0, "Raynotes")
	defer rl.CloseWindow()

	config: Config = {
		curColor = rl.RED,
		colorPickerConfig = {bounds = rl.Rectangle{10, 40, 100, 100}},
		penConfig = {},
	}

	target := rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
	defer rl.UnloadRenderTexture(target)
	rl.BeginTextureMode(target)
	rl.ClearBackground(rl.RAYWHITE)
	rl.EndTextureMode()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			// TODO: problem: right now resizing will remove all the strokes
			rl.UnloadRenderTexture(target)
			target = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
		}
		update(&config, target)
		draw(target, &config)
	}
	rl.UnloadRenderTexture(target)
}

draw :: proc(target: rl.RenderTexture2D, config: ^Config) {
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
		rl.DrawCircle(rl.GetMouseX(), rl.GetMouseY(), 50, config.curColor)
	}
	rl.GuiPanel(rl.Rectangle{0, 0, initial_screen_width, 50}, nil)
	if rl.GuiButton(rl.Rectangle{10, 10, 60, 40}, "Pen Color") {
		config.penConfig.isColorSelectorPressed = !config.penConfig.isColorSelectorPressed
	}
	if config.penConfig.isColorSelectorPressed {
		rl.GuiColorPicker(config.colorPickerConfig.bounds, nil, &config.curColor)
	}
}

update :: proc(config: ^Config, target: rl.RenderTexture2D) {
	mousePos := rl.GetMousePosition()
	// TODO: remove hardcoded values
	if mousePos.y > 50 &&
	   rl.IsMouseButtonDown(.LEFT) &&
	   isOutOfBounds(mousePos.x, mousePos.y, config.colorPickerConfig.bounds) {
		config.penConfig.isColorSelectorPressed = false
		mousePos := rl.GetMousePosition()
		rl.BeginTextureMode(target)
		rl.DrawCircle(i32(mousePos.x), i32(mousePos.y), 20, config.curColor)
		rl.EndTextureMode()
	}
}

isOutOfBounds :: proc(mx, my: f32, bounds: rl.Rectangle) -> bool {
	// +20 because how the color picker works
	result :=
		(mx >= bounds.x && mx <= bounds.x + bounds.width + 20) &&
		(my >= bounds.y && my <= bounds.y + bounds.height)
	return !result
}
