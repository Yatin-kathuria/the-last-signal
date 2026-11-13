class_name PuzzleState
extends RefCounted

## Deterministic rules for the three-room game. The renderer never owns puzzle state.

const WIDTH := 14
const HEIGHT := 9
const PLATE_SECONDS := 6.0

var level_index := 0
var map_rows: Array[String] = []
var title := ""
var subtitle := ""
var player := Vector2i.ZERO
var facing := Vector2i.RIGHT
var battery := Vector2i(-1, -1)
var carrying := false
var socket := Vector2i.ZERO
var socket_filled := false
var emitter := Vector2i.ZERO
var receiver := Vector2i.ZERO
var mirrors: Dictionary = {}
var gate := Vector2i.ZERO
var exit_tile := Vector2i.ZERO
var plate := Vector2i(-1, -1)
var plate_time := 0.0
var beam: Array[Vector2i] = []
var receiver_on := false
var gate_open := false
var won := false
var moves := 0


func _init(index: int = 0) -> void:
	load_level(index)


func load_level(index: int) -> void:
	level_index = clampi(index, 0, 2)
	var data := _level_data(level_index)
	map_rows.clear()
	for row in data.rows:
		map_rows.append(row)
	title = data.title
	subtitle = data.subtitle
	player = data.player
	facing = Vector2i.RIGHT
	battery = data.battery
	carrying = false
	socket = data.socket
	socket_filled = false
	emitter = data.emitter
	receiver = data.receiver
	mirrors = data.mirrors.duplicate()
	gate = data.gate
	exit_tile = data.exit_tile
	plate = data.get("plate", Vector2i(-1, -1))
	plate_time = 0.0
	beam.clear()
	receiver_on = false
	gate_open = false
	won = false
	moves = 0
	_recompute()


func reset() -> void:
	load_level(level_index)


func is_wall(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= WIDTH or cell.y >= HEIGHT:
		return true
	return map_rows[cell.y].substr(cell.x, 1) == "#"


func move(direction: Vector2i) -> bool:
	if won or direction == Vector2i.ZERO:
		return false
	facing = direction
	var target := player + direction
	if is_wall(target) or target == emitter or target == receiver:
		return false
	if mirrors.has(target) or target == battery:
		return false
	if target == socket:
		return false
	if target == gate and not gate_open:
		return false
	player = target
	moves += 1
	if target == exit_tile:
		won = true
	elif plate != Vector2i(-1, -1) and target == plate and receiver_on:
		plate_time = PLATE_SECONDS
	_recompute_gate()
	return true


func interact() -> bool:
	if won:
		return false
	var target := player + facing
	if target == battery and not carrying:
		battery = Vector2i(-1, -1)
		carrying = true
		return true
	if target == socket:
		if carrying and not socket_filled:
			carrying = false
			socket_filled = true
			_recompute()
			return true
		if socket_filled and not carrying:
			carrying = true
			socket_filled = false
			_recompute()
			return true
	if mirrors.has(target):
		mirrors[target] = not mirrors[target]
		_recompute()
		return true
	return false


func tick(delta: float) -> void:
	if won or plate == Vector2i(-1, -1):
		return
	if player == plate and receiver_on:
		plate_time = PLATE_SECONDS
	elif plate_time > 0.0:
		plate_time = maxf(0.0, plate_time - delta)
	_recompute_gate()


func _recompute() -> void:
	beam.clear()
	receiver_on = false
	if socket_filled:
		var cell := emitter
		var direction := Vector2i.RIGHT
		beam.append(cell)
		# A hard cap also makes a pair of reflecting mirrors safe.
		for step in range(WIDTH * HEIGHT * 4):
			cell += direction
			if is_wall(cell):
				break
			beam.append(cell)
			if cell == receiver:
				receiver_on = true
				break
			if mirrors.has(cell):
				if mirrors[cell]: # slash (/)
					direction = Vector2i(-direction.y, -direction.x)
				else: # backslash (\)
					direction = Vector2i(direction.y, direction.x)
	_recompute_gate()


func _recompute_gate() -> void:
	gate_open = receiver_on and (plate == Vector2i(-1, -1) or plate_time > 0.0)


func _level_data(index: int) -> Dictionary:
	var split_rows: Array[String] = [
		"##############",
		"#..........#.#",
		"#..........#.#",
		"#..........#.#",
		"#..........#.#",
		"#............#",
		"#..........#.#",
		"#..........#.#",
		"##############",
	]
	match index:
		0:
			return {
				"title": "01 / FIRST CONTACT",
				"subtitle": "Carry the cell to its socket. Follow the light.",
				"rows": split_rows,
				"player": Vector2i(2, 5), "battery": Vector2i(3, 5),
				"socket": Vector2i(4, 5), "emitter": Vector2i(5, 3),
				"receiver": Vector2i(9, 3), "mirrors": {},
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		1:
			var rows := split_rows.duplicate()
			rows[4] = "#............#"
			rows[5] = "#..........#.#"
			return {
				"title": "02 / CHANGE OF DIRECTION",
				"subtitle": "Rotate the mirror until the receiver catches the beam.",
				"rows": rows,
				"player": Vector2i(1, 5), "battery": Vector2i(2, 5),
				"socket": Vector2i(3, 6), "emitter": Vector2i(4, 6),
				"receiver": Vector2i(8, 2), "mirrors": {Vector2i(8, 6): false},
				"gate": Vector2i(11, 4), "exit_tile": Vector2i(12, 4),
			}
		_:
			return {
				"title": "03 / THE WINDOW",
				"subtitle": "Route the beam, then race from the plate to the gate.",
				"rows": split_rows,
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"receiver": Vector2i(10, 3),
				"mirrors": {Vector2i(7, 7): true, Vector2i(7, 3): false},
				"plate": Vector2i(9, 6),
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
