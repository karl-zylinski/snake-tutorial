package snake

import rl "vendor:raylib"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
Vec2i :: [2]int

snake: [GRID_WIDTH*GRID_WIDTH]Vec2i
snake_length: int
food_pos: Vec2i
game_over: bool
move_direction := Vec2i {0, 1}
tick_rate: f32 = 0.15
tick_timer := tick_rate

place_food :: proc() {
	free_cells := make([dynamic]Vec2i, context.temp_allocator)

	for x in 0..<GRID_WIDTH {
		for y in 0..<GRID_WIDTH {
			part_of_snake := false

			for i in 0..<snake_length {
				if snake[i].x == x && snake[i].y == y {
					part_of_snake = true
					break
				}
			}

			if !part_of_snake {
				append(&free_cells, Vec2i {x,y})
			}
		}
	}

	if len(free_cells) > 0 {
		food_pos = free_cells[rl.GetRandomValue(0, i32(len(free_cells) - 1))]
	}
}

main :: proc() {
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
	rl.SetConfigFlags({.VSYNC_HINT})
	
	start_head_pos := Vec2i { GRID_WIDTH/2, GRID_WIDTH/2 }
	snake[0] = start_head_pos
	snake[1] = start_head_pos - {0, 1}
	snake[2] = start_head_pos - {0, 2}
	snake_length = 3

	place_food()

	for !rl.WindowShouldClose() && !game_over {
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

		tick_timer -= rl.GetFrameTime()
		if tick_timer <= 0 {
			ate_food := false
			next_tail_pos := snake[0]
			new_head_pos := snake[0] + move_direction

			if new_head_pos.x < 0 || new_head_pos.y < 0 || new_head_pos.x >= GRID_WIDTH || new_head_pos.y >= GRID_WIDTH {
				game_over = true
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
			}

			tick_timer = tick_rate + tick_timer
		}
		
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
		}

		rl.BeginMode2D(camera)
		rl.DrawRectangleRec({f32(food_pos.x)*CELL_SIZE, f32(food_pos.y)*CELL_SIZE, CELL_SIZE, CELL_SIZE}, rl.RED)

		for i in 0..<snake_length {
			pos := snake[i]

			color := rl.GRAY
			if i == 0 {
				color = rl.WHITE
			}

			rl.DrawRectangleRec({f32(pos.x)*CELL_SIZE, f32(pos.y)*CELL_SIZE, CELL_SIZE, CELL_SIZE}, color)
		}

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}