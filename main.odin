package main

import "core:fmt"
import rl "vendor:raylib"

ColorPickerConfig :: struct {
	bounds: rl.Rectangle,
}

PenConfig :: struct {
	isColorSelectorPressed: bool,
}

TopPanelConfig :: struct {
	x:      f32,
	y:      f32,
	height: f32,
	width:  f32,
}

Config :: struct {
	curColor:          rl.Color,
	colorPickerConfig: ColorPickerConfig,
	penConfig:         PenConfig,
	topPanelConfig:    TopPanelConfig,
}

TOP_PANEL_HEIGHT_PERCENT :: 0.025

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(0, 0, "Raynotes")
	defer rl.CloseWindow()
	topPanelConfig: TopPanelConfig = {
		x      = 0,
		y      = 0,
		width  = f32(rl.GetScreenWidth()),
		height = f32(rl.GetScreenHeight()) * TOP_PANEL_HEIGHT_PERCENT,
	}
	config: Config = {
		curColor = rl.RED, // starting color
		colorPickerConfig = {bounds = rl.Rectangle{10, 40, 100, 100}}, // TODO:
		penConfig = {},
		topPanelConfig = topPanelConfig,
	}

	target := rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
	defer rl.UnloadRenderTexture(target)
	rl.BeginTextureMode(target)
	rl.ClearBackground(rl.RAYWHITE)
	rl.EndTextureMode()

	rl.SetTargetFPS(120)

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			// TODO: problem: right now resizing will remove all the strokes
			rl.UnloadRenderTexture(target)
			target = rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
			config.topPanelConfig.width = f32(rl.GetScreenWidth())
			config.topPanelConfig.height = f32(rl.GetScreenHeight()) * TOP_PANEL_HEIGHT_PERCENT
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
	rl.GuiPanel(
		rl.Rectangle {
			config.topPanelConfig.x,
			config.topPanelConfig.y,
			config.topPanelConfig.width,
			config.topPanelConfig.height,
		},
		nil,
	)
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
