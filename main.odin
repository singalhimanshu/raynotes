package main

import "core:fmt"
import "core:math"
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
CANVAS_SIZE :: 10_000


main :: proc() {
	rl.SetConfigFlags({rl.ConfigFlag.WINDOW_RESIZABLE})
	rl.InitWindow(0, 0, "Raynotes")
	defer rl.CloseWindow()

	config := create_config()

	target := rl.LoadRenderTexture(CANVAS_SIZE, CANVAS_SIZE)
	defer rl.UnloadRenderTexture(target)
	rl.BeginTextureMode(target)
	rl.ClearBackground(BACKGROUND_COLOR)
	rl.EndTextureMode()

	prev_point: Point = {-1, -1}

	camera := rl.Camera2D {
		offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)},
		target = {f32(CANVAS_SIZE / 2), f32(CANVAS_SIZE / 2)},
		zoom   = f32(1),
	}

	is_drawing := true

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			camera.offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
			config.topPanelConfig->update(rl.GetScreenWidth(), rl.GetScreenHeight())
			config.penColorButtonConfig->update(
				config.topPanelConfig.width,
				config.topPanelConfig.height,
			)
			config.colorPickerConfig->update(config.penColorButtonConfig)
		}
		update(&config, target, &prev_point, &camera, &is_drawing)
		draw(target, &config, camera)
	}
}

draw :: proc(target: rl.RenderTexture2D, config: ^Config, camera: rl.Camera2D) {
	rl.BeginDrawing()
	defer rl.EndDrawing()
	rl.BeginMode2D(camera)
	rl.ClearBackground(rl.RAYWHITE)

	rl.DrawTextureRec(
		target.texture,
		rl.Rectangle{0, 0, f32(target.texture.width), f32(-target.texture.height)},
		rl.Vector2{0, 0},
		rl.WHITE,
	)
	rl.EndMode2D()

	mousePos := rl.GetMousePosition()
	if mousePos.y > config.topPanelConfig.y + config.topPanelConfig.height {
		rl.HideCursor()
		rl.DrawCircle(rl.GetMouseX(), rl.GetMouseY(), BRUSH_SIZE, config.curColor)
	} else {
		rl.ShowCursor()
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

update :: proc(
	config: ^Config,
	target: rl.RenderTexture2D,
	prev_point: ^Point,
	camera: ^rl.Camera2D,
	is_drawing: ^bool,
) {
	mousePos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera^)
	if is_drawing^ &&
	   mousePos.y > config.topPanelConfig.y + config.topPanelConfig.height &&
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
	if rl.GetMouseWheelMove() != 0 {
		camera.target = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera^)
		camera.offset = rl.GetMousePosition()
		camera.zoom = rl.Clamp(
			math.exp_f32(math.log_f32(camera.zoom, math.E) + f32(rl.GetMouseWheelMove() * 0.1)),
			0.125,
			64.0,
		)
	}
	// panning
	if rl.IsMouseButtonDown(.MIDDLE) || rl.IsKeyDown(.SPACE) {
		is_drawing^ = false
		mouse_delta := rl.GetMouseDelta()
		mouse_delta = mouse_delta * (-1.0 / camera.zoom)
		camera.target = camera.target + mouse_delta
	} else {
		is_drawing^ = true
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
