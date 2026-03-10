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

Point :: struct {
	x: f32,
	y: f32,
}

TOP_PANEL_HEIGHT_PERCENT :: 0.025
BRUSH_SIZE :: 5
BACKGROUND_COLOR :: rl.BLACK


main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(0, 0, "Raynotes")
	defer rl.CloseWindow()

	config := create_config()

	target := rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
	defer rl.UnloadRenderTexture(target)
	rl.BeginTextureMode(target)
	rl.ClearBackground(BACKGROUND_COLOR)
	rl.EndTextureMode()

	prev_point: Point = {-1, -1}

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			new_target := rl.LoadRenderTexture(rl.GetScreenWidth(), rl.GetScreenHeight())
			rl.BeginTextureMode(new_target)
			rl.ClearBackground(BACKGROUND_COLOR)
			rl.DrawTextureRec(
				target.texture,
				rl.Rectangle{0, 0, f32(target.texture.width), f32(-target.texture.height)},
				rl.Vector2{0, 0},
				rl.WHITE,
			)
			rl.EndTextureMode()
			rl.UnloadRenderTexture(target)
			target = new_target

			config.topPanelConfig->update(rl.GetScreenWidth(), rl.GetScreenHeight())
			config.penColorButtonConfig->update(
				config.topPanelConfig.width,
				config.topPanelConfig.height,
			)
			config.colorPickerConfig->update(config.penColorButtonConfig)
		}
		update(&config, target, &prev_point)
		draw(target, &config)
	}
}

draw :: proc(target: rl.RenderTexture2D, config: ^Config) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.ClearBackground(BACKGROUND_COLOR)

	rl.DrawTextureRec(
		target.texture,
		rl.Rectangle{0, 0, f32(target.texture.width), f32(-target.texture.height)},
		rl.Vector2{0, 0},
		rl.WHITE,
	)

	mousePos := rl.GetMousePosition()
	if mousePos.y > config.topPanelConfig.y + config.topPanelConfig.height {
		rl.DrawCircle(rl.GetMouseX(), rl.GetMouseY(), BRUSH_SIZE, config.curColor)
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

update :: proc(config: ^Config, target: rl.RenderTexture2D, prev_point: ^Point) {
	mousePos := rl.GetMousePosition()
	if mousePos.y > config.topPanelConfig.y + config.topPanelConfig.height &&
	   rl.IsMouseButtonDown(.LEFT) &&
	   is_out_of_bounds(
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
		if prev_point.x != -1 && prev_point.y != -1 {
			rl.BeginTextureMode(target)
			start_point := rl.Vector2{prev_point.x, prev_point.y}
			end_point := rl.Vector2{mousePos.x, mousePos.y}
			dist := rl.Vector2Distance(start_point, end_point)
			dir := rl.Vector2Normalize(end_point - start_point)
			spacing := BRUSH_SIZE * 0.4
			steps := int(dist) / int(spacing)
			if steps == 0 {
				rl.DrawCircleV({mousePos.x, mousePos.y}, BRUSH_SIZE, config.curColor)
			} else {
				for i in 0 ..< steps {
					pos := start_point + (dir * (f32(i) * f32(spacing)))
					rl.DrawCircleV(pos, BRUSH_SIZE, config.curColor)
				}
			}
			rl.EndTextureMode()
		}
		prev_point.x = mousePos.x
		prev_point.y = mousePos.y
	}
	if rl.IsMouseButtonReleased(.LEFT) {
		prev_point.x = -1
		prev_point.y = -1
	}
	if rl.IsKeyPressed(.E) {
		rl.BeginTextureMode(target)
		rl.ClearBackground(BACKGROUND_COLOR)
		rl.EndTextureMode()
	}
}

is_out_of_bounds :: proc(mx, my: f32, bounds: rl.Rectangle) -> bool {
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
