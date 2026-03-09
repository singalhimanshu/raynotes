package main

import rl "vendor:raylib"

ColorPickerConfig :: struct {
	x:      f32,
	y:      f32,
	width:  f32,
	height: f32,
	update: proc(this: ^ColorPickerConfig, penColorButtonConfig: PenColorButtonConfig),
}

PenColorButtonConfig :: struct {
	x:      f32,
	y:      f32,
	width:  f32,
	height: f32,
	update: proc(this: ^PenColorButtonConfig, rel_width, rel_height: f32),
}

PenColorSelectorConfig :: struct {
	isColorSelectorPressed: bool,
}

TopPanelConfig :: struct {
	x:      f32,
	y:      f32,
	height: f32,
	width:  f32,
	update: proc(this: ^TopPanelConfig, screen_width, screen_height: i32),
}

Config :: struct {
	curColor:               rl.Color,
	colorPickerConfig:      ColorPickerConfig,
	penColorSelectorConfig: PenColorSelectorConfig,
	topPanelConfig:         TopPanelConfig,
	penColorButtonConfig:   PenColorButtonConfig,
}

TOP_PANEL_HEIGHT_PERCENT :: 0.025

main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(0, 0, "Raynotes")
	defer rl.CloseWindow()

	config := create_config()

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
			config.topPanelConfig->update(rl.GetScreenWidth(), rl.GetScreenHeight())
			config.penColorButtonConfig->update(
				config.topPanelConfig.width,
				config.topPanelConfig.height,
			)
			config.colorPickerConfig->update(config.penColorButtonConfig)
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
	if mousePos.y > config.topPanelConfig.y + config.topPanelConfig.height {
		rl.DrawCircle(rl.GetMouseX(), rl.GetMouseY(), 50, config.curColor) // TODO: implement pen size
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
	if rl.GuiButton(
		rl.Rectangle {
			config.penColorButtonConfig.x,
			config.penColorButtonConfig.y,
			config.penColorButtonConfig.width,
			config.penColorButtonConfig.height,
		},
		"Pen Color",
	) {
		config.penColorSelectorConfig.isColorSelectorPressed = !config.penColorSelectorConfig.isColorSelectorPressed
	}
	if config.penColorSelectorConfig.isColorSelectorPressed {
		rl.GuiColorPicker(
			rl.Rectangle {
				config.colorPickerConfig.x,
				config.colorPickerConfig.y,
				config.colorPickerConfig.width,
				config.colorPickerConfig.height,
			},
			nil,
			&config.curColor,
		)
	}
}

update :: proc(config: ^Config, target: rl.RenderTexture2D) {
	mousePos := rl.GetMousePosition()
	if mousePos.y > config.topPanelConfig.y + config.topPanelConfig.height &&
	   rl.IsMouseButtonDown(.LEFT) &&
	   isOutOfBounds(
		   mousePos.x,
		   mousePos.y,
		   rl.Rectangle {
			   config.colorPickerConfig.x,
			   config.colorPickerConfig.y,
			   config.colorPickerConfig.width,
			   config.colorPickerConfig.height,
		   },
	   ) {
		config.penColorSelectorConfig.isColorSelectorPressed = false
		mousePos := rl.GetMousePosition()
		rl.BeginTextureMode(target)
		rl.DrawCircle(i32(mousePos.x), i32(mousePos.y), 20, config.curColor) // TODO: implement pen size
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

create_config :: proc() -> Config {
	topPanelConfig: TopPanelConfig = {}
	topPanelConfig.update = proc(this: ^TopPanelConfig, screen_width, screen_height: i32) {
		this.width = f32(screen_width)
		this.height = f32(screen_height) * TOP_PANEL_HEIGHT_PERCENT
	}
	topPanelConfig->update(rl.GetScreenWidth(), rl.GetScreenHeight())
	penColorButtonConfig: PenColorButtonConfig = {}
	penColorButtonConfig.update = proc(this: ^PenColorButtonConfig, rel_width, rel_height: f32) {
		this.x = rel_width * 0.015
		this.y = rel_height * 0.05
		this.width = rel_width * 0.05
		this.height = rel_height - 2 * rel_height * 0.05
	}
	penColorButtonConfig->update(topPanelConfig.width, topPanelConfig.height)
	colorPickerConfig: ColorPickerConfig = {}
	colorPickerConfig.update = proc(
		this: ^ColorPickerConfig,
		penColorButtonConfig: PenColorButtonConfig,
	) {
		this.x = penColorButtonConfig.x
		this.y = penColorButtonConfig.y + penColorButtonConfig.height
		this.width = f32(rl.GetScreenWidth()) * 0.10
		this.height = f32(rl.GetScreenHeight()) * 0.05
	}
	colorPickerConfig->update(penColorButtonConfig)
	penColorSelectorConfig: PenColorSelectorConfig = {}
	config: Config = {
		curColor               = rl.RED, // starting pen color
		colorPickerConfig      = colorPickerConfig,
		penColorSelectorConfig = penColorSelectorConfig,
		topPanelConfig         = topPanelConfig,
		penColorButtonConfig   = penColorButtonConfig,
	}
	return config
}
