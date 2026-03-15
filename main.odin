package main

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
	is_color_selector_pressed: bool,
}

TopPanelConfig :: struct {
	x:      f32,
	y:      f32,
	height: f32,
	width:  f32,
	update: proc(this: ^TopPanelConfig, screen_width, screen_height: i32),
}

Config :: struct {
	cur_color:                 rl.Color,
	color_picker_config:       ColorPickerConfig,
	pen_color_selector_config: PenColorSelectorConfig,
	top_panel_config:          TopPanelConfig,
	pen_color_button_config:   PenColorButtonConfig,
	brush_size:                f32,
}

Point :: struct {
	x: f32,
	y: f32,
}

Tool :: enum {
	PEN,
	ERASER,
	PAN,
}

Stroke :: struct {
	points:       [dynamic]Point,
	stroke_color: rl.Color,
}

Stroke_List :: struct {
	strokes: [dynamic]Stroke,
}

TOP_PANEL_HEIGHT_PERCENT :: 0.025
BACKGROUND_COLOR :: rl.BLACK
CANVAS_SIZE :: 10_000
INITIAL_BRUSH_SIZE :: 5


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

	tool_selected := Tool.PEN

	stroke_list := Stroke_List{}
	defer {
		for stroke in stroke_list.strokes {
			stroke_points := stroke.points
			clear(&stroke_points)
		}
		clear(&stroke_list.strokes)
	}
	stroke_idx := 0

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			camera.offset = {f32(rl.GetScreenWidth() / 2), f32(rl.GetScreenHeight() / 2)}
			config.top_panel_config->update(rl.GetScreenWidth(), rl.GetScreenHeight())
			config.pen_color_button_config->update(
				config.top_panel_config.width,
				config.top_panel_config.height,
			)
			config.color_picker_config->update(config.pen_color_button_config)
		}
		update(
			&config,
			target,
			&prev_point,
			&camera,
			&is_drawing,
			&tool_selected,
			&stroke_list,
			&stroke_idx,
		)
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
	if mousePos.y > config.top_panel_config.y + config.top_panel_config.height {
		rl.HideCursor()
		rl.DrawCircle(rl.GetMouseX(), rl.GetMouseY(), config.brush_size, config.cur_color)
	} else {
		rl.ShowCursor()
	}
	rl.GuiPanel(
		rl.Rectangle {
			config.top_panel_config.x,
			config.top_panel_config.y,
			config.top_panel_config.width,
			config.top_panel_config.height,
		},
		nil,
	)
	if rl.GuiButton(
		rl.Rectangle {
			config.pen_color_button_config.x,
			config.pen_color_button_config.y,
			config.pen_color_button_config.width,
			config.pen_color_button_config.height,
		},
		"Pen Color",
	) {
		config.pen_color_selector_config.is_color_selector_pressed = !config.pen_color_selector_config.is_color_selector_pressed
	}
	if config.pen_color_selector_config.is_color_selector_pressed {
		rl.GuiColorPicker(
			rl.Rectangle {
				config.color_picker_config.x,
				config.color_picker_config.y,
				config.color_picker_config.width,
				config.color_picker_config.height,
			},
			nil,
			&config.cur_color,
		)
	}
}

update :: proc(
	config: ^Config,
	target: rl.RenderTexture2D,
	prev_point: ^Point,
	camera: ^rl.Camera2D,
	is_drawing: ^bool,
	tool_selected: ^Tool,
	stroke_list: ^Stroke_List,
	stroke_idx: ^int,
) {
	mousePos := rl.GetScreenToWorld2D(rl.GetMousePosition(), camera^)
	if (tool_selected^ == .PEN || tool_selected^ == .ERASER) &&
	   is_drawing^ &&
	   rl.IsMouseButtonReleased(.LEFT) &&
	   mousePos.y > config.top_panel_config.y + config.top_panel_config.height &&
	   is_out_of_bounds(
		   mousePos.x,
		   mousePos.y,
		   rl.Rectangle {
			   config.color_picker_config.x,
			   config.color_picker_config.y,
			   config.color_picker_config.width,
			   config.color_picker_config.height,
		   },
	   ) {
		stroke_idx^ += 1
	}
	if (tool_selected^ == .PEN || tool_selected^ == .ERASER) &&
	   is_drawing^ &&
	   mousePos.y > config.top_panel_config.y + config.top_panel_config.height &&
	   rl.IsMouseButtonDown(.LEFT) &&
	   is_out_of_bounds(
		   mousePos.x,
		   mousePos.y,
		   rl.Rectangle {
			   config.color_picker_config.x,
			   config.color_picker_config.y,
			   config.color_picker_config.width,
			   config.color_picker_config.height,
		   },
	   ) {
		draw_color := config.cur_color
		if tool_selected^ == .ERASER {
			draw_color = BACKGROUND_COLOR
		}
		config.pen_color_selector_config.is_color_selector_pressed = false
		cur_point: Point = {mousePos.x, mousePos.y}
		if stroke_idx^ >= len(stroke_list.strokes) {
			append(&stroke_list.strokes, Stroke{stroke_color = draw_color})
		}
		cur_stroke := stroke_list.strokes[stroke_idx^]
		if !(len(cur_stroke.points) > 0 &&
			   cur_stroke.points[len(cur_stroke.points) - 1].x == cur_point.x &&
			   cur_stroke.points[len(cur_stroke.points) - 1].y == cur_point.y) {
			append(&cur_stroke.points, cur_point)
			stroke_list.strokes[stroke_idx^] = cur_stroke
		}
		rl.BeginTextureMode(target)
		rl.ClearBackground(BACKGROUND_COLOR)
		for stroke in stroke_list.strokes {
			if len(stroke.points) == 0 {
				continue
			}
			rl.DrawCircleV(
				{stroke.points[0].x, stroke.points[0].y},
				config.brush_size,
				stroke.stroke_color,
			)
			for i in 1 ..< len(stroke.points) {
				prev_point := stroke.points[i - 1]
				cur_point := stroke.points[i]
				start_point := rl.Vector2{prev_point.x, prev_point.y}
				end_point := rl.Vector2{cur_point.x, cur_point.y}
				dist := rl.Vector2Distance(start_point, end_point)
				dir := rl.Vector2Normalize(end_point - start_point)
				spacing := config.brush_size * 0.4
				steps := int(dist) / int(spacing)
				for i in 0 ..< steps {
					pos := start_point + (dir * (f32(i) * f32(spacing)))
					rl.DrawCircleV(pos, config.brush_size, stroke.stroke_color)
				}
			}
		}
		rl.EndTextureMode()
	}
	if rl.IsMouseButtonReleased(.LEFT) {
		prev_point.x = -1
		prev_point.y = -1
	}
	if rl.IsKeyPressed(.X) {
		rl.BeginTextureMode(target)
		rl.ClearBackground(BACKGROUND_COLOR)
		rl.EndTextureMode()
	}
	if rl.GetMouseWheelMove() != 0 && !rl.IsKeyDown(.LEFT_SHIFT) {
		camera.target = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera^)
		camera.offset = rl.GetMousePosition()
		camera.zoom = rl.Clamp(
			math.exp_f32(math.log_f32(camera.zoom, math.E) + f32(rl.GetMouseWheelMove() * 0.1)),
			0.125,
			64.0,
		)
	}
	// panning
	if rl.IsKeyDown(.SPACE) {
		is_drawing^ = false
		mouse_delta := rl.GetMouseDelta()
		mouse_delta = mouse_delta * (-1.0 / camera.zoom)
		camera.target = camera.target + mouse_delta
		tool_selected^ = .PAN
	}
	if rl.IsKeyReleased(.SPACE) {
		is_drawing^ = true
		// TODO: better to store the last tool and reset to that
		tool_selected^ = .PEN
	}
	if rl.IsKeyPressed(.R) {
		camera.zoom = 1.0
	}
	if rl.IsKeyPressed(.E) {
		tool_selected^ = .ERASER
	}
	if rl.IsKeyPressed(.D) {
		tool_selected^ = .PEN
	}
	if rl.IsKeyDown(.LEFT_SHIFT) {
		config.brush_size = rl.Clamp(config.brush_size + rl.GetMouseWheelMove() * 4.0, 2.0, 50.0)
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
		cur_color                 = rl.RED, // starting pen color
		color_picker_config       = colorPickerConfig,
		pen_color_selector_config = penColorSelectorConfig,
		top_panel_config          = topPanelConfig,
		pen_color_button_config   = penColorButtonConfig,
		brush_size                = INITIAL_BRUSH_SIZE,
	}
	return config
}
