package snake

import rl "vendor:raylib"
import "core:slice"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE

Cell_Type :: enum {
	None,
	Head,
	Body,
	Food,
}

Cell :: struct {
	type: Cell_Type,
	velocity: Vec2i,
}

Vec2i :: [2]int

main :: proc() {
	rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
	rl.SetConfigFlags({.VSYNC_HINT})
	

	grid: [GRID_WIDTH][GRID_WIDTH]Cell
	head_pos := Vec2i { GRID_WIDTH/2, GRID_WIDTH/2 }
	tail_pos := head_pos - {0, 1}
	wanted_head_direction := Vec2i {0, 1}

	grid[head_pos.x][head_pos.y] = {
		type = .Head,
		velocity = wanted_head_direction,
	}

	grid[tail_pos.x][tail_pos.y] = {
		type = .Body,
		velocity = wanted_head_direction,
	}

	is_inside_grid :: proc(pos: Vec2i) -> bool {
		return pos.x >= 0 && pos.y >= 0 && pos.x < GRID_WIDTH && pos.y < GRID_WIDTH
	}

	game_over: bool
	tick_rate: f32 = 0.15
	tick_timer := tick_rate

	food_rate: f32 = 1
	food_timer := food_rate
	num_food_spawned := 0

	food := 0

	for !rl.WindowShouldClose() && !game_over {
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		
		camera := rl.Camera2D {
			zoom = f32(WINDOW_SIZE) / CANVAS_SIZE,
		}

		rl.BeginMode2D(camera)

		input: Vec2i

		if rl.IsKeyDown(.UP) {
			input.y -= 1
		}

		if rl.IsKeyDown(.DOWN) {
			input.y += 1
		}

		if rl.IsKeyDown(.LEFT) {
			input.x -= 1
		}

		if rl.IsKeyDown(.RIGHT) {
			input.x += 1
		}

		if input.x != 0 || input.y != 0 {
			wanted_head_direction = input
		}

		tick_timer -= rl.GetFrameTime()
		if tick_timer <= 0 {
			new_tail_pos := tail_pos + grid[tail_pos.x][tail_pos.y].velocity

			if is_inside_grid(new_tail_pos) {
				if food == 0 {
					grid[tail_pos.x][tail_pos.y] = {}
					tail_pos = new_tail_pos
				} else {
					food -= 1
				}
			} else {
				game_over = true
			}

			new_head_pos := head_pos + wanted_head_direction

			if is_inside_grid(new_head_pos) {
				new_head_cell := grid[new_head_pos.x][new_head_pos.y]

				switch new_head_cell.type {
					case .None:

					case .Food:
						food += 1
						num_food_spawned -= 1

					case .Body:
						game_over = true

					case .Head:
						panic("Impossible")
				}

				grid[new_head_pos.x][new_head_pos.y] = {
					type = .Head,
					velocity = wanted_head_direction,
				}
				grid[head_pos.x][head_pos.y] = {
					type = .Body,
					velocity = wanted_head_direction,
				}
				head_pos = new_head_pos
			} else {
				game_over = true
			}

			tick_timer = tick_rate + tick_timer
		}

		food_timer -= rl.GetFrameTime()

		if food_timer <= 0 {
			if num_food_spawned == 0 {
				free_cells := make([dynamic]Vec2i, context.temp_allocator)

				for x in 0..<GRID_WIDTH {
					for y in 0..<GRID_WIDTH {
						if grid[x][y].type == .None {
							append(&free_cells, Vec2i {x, y})
						}
					}
				}

				if len(free_cells) > 0 {
					food_cell := free_cells[rl.GetRandomValue(0, i32(len(free_cells) - 1))]
					grid[food_cell.x][food_cell.y] = {
						type = .Food,
					}
					num_food_spawned += 1
				}
			}
			
			food_timer = food_rate + food_timer
		}

		for x in 0..<GRID_WIDTH {
			for y in 0..<GRID_WIDTH {
				g := &grid[x][y]

				switch g.type {
					case .None:

					case .Head:
						rl.DrawRectangleRec({f32(x)*CELL_SIZE, f32(y)*CELL_SIZE, CELL_SIZE, CELL_SIZE}, rl.WHITE)

					case .Body:
						rl.DrawRectangleRec({f32(x)*CELL_SIZE, f32(y)*CELL_SIZE, CELL_SIZE, CELL_SIZE}, rl.GRAY)

					case .Food:
						rl.DrawRectangleRec({f32(x)*CELL_SIZE, f32(y)*CELL_SIZE, CELL_SIZE, CELL_SIZE}, rl.RED)
				}
			}
		}

		rl.EndMode2D()
		rl.EndDrawing()

		free_all(context.temp_allocator)
	}

	rl.CloseWindow()
}