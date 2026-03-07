package main

import rl "vendor:raylib"

MAX_COLORS_COUNT :: 23

DrawConfig :: struct {
	colorSelected:     int,
	colorSelectedPrev: int,
	colorMouseHover:   int,
	// brush size
}

main :: proc() {
	screen_width :: 800
	screen_height :: 450

	rl.InitWindow(screen_width, screen_height, "Raynotes")
	defer rl.CloseWindow()

	colors := [MAX_COLORS_COUNT]rl.Color {
		rl.RAYWHITE,
		rl.YELLOW,
		rl.GOLD,
		rl.ORANGE,
		rl.PINK,
		rl.RED,
		rl.MAROON,
		rl.GREEN,
		rl.LIME,
		rl.DARKGREEN,
		rl.SKYBLUE,
		rl.BLUE,
		rl.DARKBLUE,
		rl.PURPLE,
		rl.VIOLET,
		rl.DARKPURPLE,
		rl.BEIGE,
		rl.BROWN,
		rl.DARKBROWN,
		rl.LIGHTGRAY,
		rl.GRAY,
		rl.DARKGRAY,
		rl.BLACK,
	}
	colorsRecs: [MAX_COLORS_COUNT]rl.Rectangle

	for i in 0 ..< len(colorsRecs) {
		// TODO: define the constants
		colorsRecs[i].x = 10
		colorsRecs[i].x = 10 + f32(30.0) * f32(i) + f32(5 * i)
		colorsRecs[i].y = 10
		colorsRecs[i].width = 30
		colorsRecs[i].height = 30
	}


	colorsSelection: DrawConfig = {}

	target := rl.LoadRenderTexture(screen_width, screen_height)
	defer rl.UnloadRenderTexture(target)
	rl.BeginTextureMode(target)
	rl.ClearBackground(colors[0])
	rl.EndTextureMode()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update(&colorsSelection, colorsRecs, target, colors)
		draw(target, colorsRecs, colors, colorsSelection)
	}
}

draw :: proc(
	target: rl.RenderTexture2D,
	colorsRecs: [MAX_COLORS_COUNT]rl.Rectangle,
	colors: [MAX_COLORS_COUNT]rl.Color,
	colorsSelection: DrawConfig,
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

	for i in 0 ..< len(colorsRecs) {
		rl.DrawRectangleRec(colorsRecs[i], colors[i])
	}

	rl.DrawRectangleLinesEx(
		rl.Rectangle {
			colorsRecs[colorsSelection.colorSelected].x - 2,
			colorsRecs[colorsSelection.colorSelected].y - 2,
			colorsRecs[colorsSelection.colorSelected].width + 4,
			colorsRecs[colorsSelection.colorSelected].height + 4,
		},
		5,
		rl.BLACK,
	)

	// drawing the hover light gray thingy
	if colorsSelection.colorMouseHover >= 0 {
		rl.DrawRectangleRec(
			colorsRecs[colorsSelection.colorMouseHover],
			rl.Fade(rl.WHITE, f32(0.6)),
		)
	}


	mousePos := rl.GetMousePosition()
	if mousePos.y > 50 {
		rl.DrawCircle(rl.GetMouseX(), rl.GetMouseY(), 50, colors[colorsSelection.colorSelected])
	}

}

update :: proc(
	colorsSelection: ^DrawConfig,
	colorsRecs: [MAX_COLORS_COUNT]rl.Rectangle,
	target: rl.RenderTexture2D,
	colors: [MAX_COLORS_COUNT]rl.Color,
) {
	mousePos := rl.GetMousePosition()
	for i in 0 ..< MAX_COLORS_COUNT {
		if rl.CheckCollisionPointRec(mousePos, colorsRecs[i]) {
			colorsSelection.colorMouseHover = i
			break
		} else {
			colorsSelection.colorMouseHover = -1
		}
	}
	if colorsSelection.colorMouseHover >= 0 && rl.IsMouseButtonPressed(.LEFT) {
		colorsSelection.colorSelected = colorsSelection.colorMouseHover
		colorsSelection.colorSelectedPrev = colorsSelection.colorSelected
	}
	if rl.IsMouseButtonDown(.LEFT) {
		mousePos := rl.GetMousePosition()
		rl.BeginTextureMode(target)
		if mousePos.y > 50 {
			rl.DrawCircle(
				i32(mousePos.x),
				i32(mousePos.y),
				20,
				colors[colorsSelection.colorSelected],
			)
		}
		rl.EndTextureMode()
	}
}
