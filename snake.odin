package snake

import rl "vendor:raylib"
import "core:math"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
Vec2i :: [2]int
Vec2 :: [2]f32

snake: [GRID_WIDTH*GRID_WIDTH]Vec2i
snake_length: int
food_pos: Vec2i
game_over: bool
move_direction: Vec2i
tick_rate: f32 = 0.15
tick_timer := tick_rate

vec2_from_vec2i :: proc(v: Vec2i) -> Vec2 {
	return {f32(v.x), f32(v.y)}
}

place_food :: proc() {
	occupied: [GRID_WIDTH][GRID_WIDTH]bool

	for i in 0..<snake_length {
		occupied[snake[i].x][snake[i].y] = true
	}

	free_cells := make([dynamic]Vec2i, context.temp_allocator)

	for x in 0..<GRID_WIDTH {
		for y in 0..<GRID_WIDTH {
			if !occupied[x][y] {
				append(&free_cells, Vec2i {x,y})
			}
		}
	}

	if len(free_cells) > 0 {
		food_pos = free_cells[rl.GetRandomValue(0, i32(len(free_cells) - 1))]
	}
}

restart :: proc() {
	start_head_pos := Vec2i { GRID_WIDTH/2, GRID_WIDTH/2 }
	snake[0] = start_head_pos
	snake[1] = start_head_pos - {0, 1}
	snake[2] = start_head_pos - {0, 2}
	snake_length = 3
	move_direction = {0, 1}
	game_over = false
}

main :: proc() {
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitAudioDevice()
	
	restart()

	place_food()

	head_sprite := rl.LoadTexture("head.png")
	body_sprite := rl.LoadTexture("body.png")
	tail_sprite := rl.LoadTexture("tail.png")
	food_sprite := rl.LoadTexture("food.png")

	eat_sound := rl.LoadSound("eat.wav")
	crash_sound := rl.LoadSound("crash.wav")

	for !rl.WindowShouldClose() {
		if rl.IsKeyDown(.UP) {
			move_direction = {0, -1}
		}

		if rl.IsKeyDown(.DOWN) {
			move_direction = {0, 1}
		}

		if rl.IsKeyDown(.LEFT) {
			move_direction = {-1, 0}
		}

		if rl.IsKeyDown(.RIGHT) {
			move_direction = {1, 0}
		}

		if game_over {
			if rl.IsKeyPressed(.ENTER) {
				restart()
				place_food()
			}
		} else {
			tick_timer -= rl.GetFrameTime()
		}

		if tick_timer <= 0 {
			ate_food := false
			next_tail_pos := snake[0]
			new_head_pos := snake[0] + move_direction

			if new_head_pos.x < 0 || new_head_pos.y < 0 || new_head_pos.x >= GRID_WIDTH || new_head_pos.y >= GRID_WIDTH {
				game_over = true
				rl.PlaySound(crash_sound)
			} else {
				collided_with_self := false
				for i in 1..<snake_length-1 {
					if snake[i] == new_head_pos {
						collided_with_self = true
						break
					}
				}

				if collided_with_self {
					game_over = true
					rl.PlaySound(crash_sound)
				} else {
					snake[0] = new_head_pos
				}
			}

			for i in 1..<snake_length {
				cur_pos := snake[i]
				snake[i] = next_tail_pos
				next_tail_pos = cur_pos
			}

			if snake[0] == food_pos {
				snake_length += 1
				snake[snake_length - 1] = next_tail_pos
				place_food()
				rl.PlaySound(eat_sound)
			}

			tick_timer = tick_rate + tick_timer
		}
		
		rl.BeginDrawing()
		rl.ClearBackground({76, 53, 83, 255})

		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
		}

		rl.BeginMode2D(camera)

		rl.DrawTextureV(food_sprite, {f32(food_pos.x)*CELL_SIZE, f32(food_pos.y)*CELL_SIZE}, rl.WHITE)

		for i in 0..<snake_length {
			pos := snake[i]
			gfx := body_sprite

			if i == 0 {
				gfx = head_sprite
			} else if i == snake_length - 1 {
				gfx = tail_sprite
			}

			dir: Vec2i

			if i == 0 {
				dir = pos - snake[i + 1]
			} else {
				dir = snake[i - 1] - pos
			}

			rot := math.atan2(f32(dir.y), f32(dir.x)) * (180/math.PI)

			source := rl.Rectangle {
				0, 0,
				f32(gfx.width), f32(gfx.height),
			}

			dest := rl.Rectangle {
				(f32(pos.x) + 0.5)*CELL_SIZE, (f32(pos.y) + 0.5)*CELL_SIZE,
				CELL_SIZE, CELL_SIZE,
			}

			rl.DrawTexturePro(gfx, source, dest, {CELL_SIZE, CELL_SIZE}*0.5, rot, rl.WHITE)
			//rl.DrawRectangleRec({f32(pos.x)*CELL_SIZE, f32(pos.y)*CELL_SIZE, CELL_SIZE, CELL_SIZE}, color)
		}

		rl.EndMode2D()

		if game_over {
			rl.DrawText("Game Over!", 20, 20, 50, rl.RED)
			rl.DrawText("Press Enter to start again", 20, 80, 40, rl.BLACK)
		}

		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.UnloadTexture(body_sprite)
	rl.UnloadTexture(food_sprite)
	rl.UnloadTexture(head_sprite)
	rl.UnloadTexture(tail_sprite)

	rl.UnloadSound(crash_sound)
	rl.UnloadSound(eat_sound)

	rl.CloseAudioDevice()
	rl.CloseWindow()
}