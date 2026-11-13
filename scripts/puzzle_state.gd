class_name PuzzleState
extends RefCounted

## Deterministic rules for the campaign. The renderer never owns puzzle state.

const WIDTH := 14
const HEIGHT := 9
const LEVEL_COUNT := 10
const PLATE_SECONDS := 6.0

var level_index := 0
var map_rows: Array[String] = []
var title := ""
var subtitle := ""
var story := ""
var player := Vector2i.ZERO
var facing := Vector2i.RIGHT
var battery := Vector2i(-1, -1)
var carrying := false
var socket := Vector2i.ZERO
var socket_filled := false
var emitter := Vector2i.ZERO
var receiver := Vector2i.ZERO
var extra_receiver := Vector2i(-1, -1)
var splitter := Vector2i(-1, -1)
var mirrors: Dictionary = {}
var gate := Vector2i.ZERO
var exit_tile := Vector2i.ZERO
var plate := Vector2i(-1, -1)
var plate_time := 0.0
var beam: Array[Vector2i] = []
var beam_segments: Array[PackedVector2Array] = []
var receiver_on := false
var extra_receiver_on := false
var gate_open := false
var won := false
var moves := 0


func _init(index: int = 0) -> void:
	load_level(index)


func load_level(index: int) -> void:
	level_index = clampi(index, 0, LEVEL_COUNT - 1)
	var data := _level_data(level_index)
	map_rows.clear()
	for row in data.rows:
		map_rows.append(row)
	title = data.title
	subtitle = data.subtitle
	story = data.story
	player = data.player
	facing = Vector2i.RIGHT
	battery = data.battery
	carrying = false
	socket = data.socket
	socket_filled = false
	emitter = data.emitter
	receiver = data.receiver
	extra_receiver = data.get("extra_receiver", Vector2i(-1, -1))
	splitter = data.get("splitter", Vector2i(-1, -1))
	mirrors = data.mirrors.duplicate()
	gate = data.gate
	exit_tile = data.exit_tile
	plate = data.get("plate", Vector2i(-1, -1))
	plate_time = 0.0
	beam.clear()
	beam_segments.clear()
	receiver_on = false
	extra_receiver_on = false
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
	if is_wall(target) or target == emitter or target == receiver or target == extra_receiver or target == splitter:
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
	elif plate != Vector2i(-1, -1) and target == plate and _signal_complete():
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
	if player == plate and _signal_complete():
		plate_time = PLATE_SECONDS
	elif plate_time > 0.0:
		plate_time = maxf(0.0, plate_time - delta)
	_recompute_gate()


func _recompute() -> void:
	beam.clear()
	beam_segments.clear()
	receiver_on = false
	extra_receiver_on = false
	if socket_filled:
		# Each ray owns its visited states, preventing mirror loops from hanging.
		var rays: Array[Dictionary] = [{"cell": emitter, "direction": Vector2i.RIGHT}]
		var seen: Dictionary = {}
		while not rays.is_empty():
			var ray: Dictionary = rays.pop_front()
			var cell: Vector2i = ray.cell
			var direction: Vector2i = ray.direction
			for step in range(WIDTH * HEIGHT * 4):
				var ray_key := [cell, direction]
				if seen.has(ray_key):
					break
				seen[ray_key] = true
				var next_cell := cell + direction
				if is_wall(next_cell):
					break
				beam_segments.append(PackedVector2Array([Vector2(cell), Vector2(next_cell)]))
				cell = next_cell
				beam.append(cell)
				if cell == receiver:
					receiver_on = true
					break
				if cell == extra_receiver:
					extra_receiver_on = true
					break
				if cell == splitter:
					# The prism sends one ray onward and one to its left.
					rays.append({"cell": cell, "direction": Vector2i(direction.y, -direction.x)})
				if mirrors.has(cell):
					if mirrors[cell]: # slash (/)
						direction = Vector2i(-direction.y, -direction.x)
					else: # backslash (\)
						direction = Vector2i(direction.y, direction.x)
	_recompute_gate()


func _recompute_gate() -> void:
	gate_open = _signal_complete() \
		and (plate == Vector2i(-1, -1) or plate_time > 0.0)


func _signal_complete() -> bool:
	return receiver_on and (extra_receiver == Vector2i(-1, -1) or extra_receiver_on)


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
				"title": "01 / FIRST SPARK",
				"subtitle": "A guided first step through the dark.",
				"story": "ONE CELL. ONE CHANCE TO RESTART THE GRID.",
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
				"title": "02 / REFLECTION",
				"subtitle": "The light needs one turn.",
				"story": "A SINGLE MIRROR CAN CHANGE THE ROUTE.",
				"rows": rows,
				"player": Vector2i(1, 5), "battery": Vector2i(2, 5),
				"socket": Vector2i(3, 6), "emitter": Vector2i(4, 6),
				"receiver": Vector2i(8, 2), "mirrors": {Vector2i(8, 6): false},
				"gate": Vector2i(11, 4), "exit_tile": Vector2i(12, 4),
			}
		2:
			return {
				"title": "03 / DOUBLE BACK",
				"subtitle": "Two mirrors must agree before the receiver wakes.",
				"story": "THE SECOND REFLECTION IS STILL OUT OF ALIGNMENT.",
				"rows": split_rows,
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"receiver": Vector2i(10, 3),
				"mirrors": {Vector2i(7, 7): false, Vector2i(7, 3): false},
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		3:
			return {
				"title": "04 / THE WINDOW",
				"subtitle": "Route the beam, then outrun the gate timer.",
				"story": "POWER ALONE IS NOT ENOUGH. STEP ON THE PLATE.",
				"rows": split_rows,
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"receiver": Vector2i(10, 3),
				"mirrors": {Vector2i(7, 7): true, Vector2i(7, 3): false},
				"plate": Vector2i(9, 6),
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		4:
			return {
				"title": "05 / FRACTURED PATH",
				"subtitle": "Three mirrors. One short window.",
				"story": "THE SIGNAL MUST TURN THREE TIMES TO SURVIVE.",
				"rows": split_rows,
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"receiver": Vector2i(8, 6),
				"mirrors": {Vector2i(5, 7): false, Vector2i(5, 2): false, Vector2i(8, 2): true},
				"plate": Vector2i(9, 6),
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		5:
			var final_rows := split_rows.duplicate()
			final_rows[5] = "#.......#....#"
			return {
				"title": "06 / FINAL TRANSMISSION",
				"subtitle": "Four mirrors. A blocked corridor. The last gate.",
				"story": "THE FINAL PULSE MUST FIND A WAY THROUGH.",
				"rows": final_rows,
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"receiver": Vector2i(10, 6),
				"mirrors": {Vector2i(5, 7): false, Vector2i(5, 2): false, Vector2i(9, 2): true, Vector2i(9, 6): true},
				"plate": Vector2i(8, 6),
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		6:
			return {
				"title": "07 / SPLIT HORIZON",
				"subtitle": "One prism. Two receivers. Every branch matters.",
				"story": "THE SIGNAL DIVIDES, BUT THE GATE DEMANDS BOTH HALVES.",
				"rows": _with_walls(split_rows, [Vector2i(3, 2), Vector2i(3, 3), Vector2i(7, 4), Vector2i(8, 4), Vector2i(9, 4)]),
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"splitter": Vector2i(5, 7), "receiver": Vector2i(10, 7),
				"extra_receiver": Vector2i(9, 2),
				"mirrors": {Vector2i(5, 2): false},
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		7:
			return {
				"title": "08 / CROSS CURRENT",
				"subtitle": "Two branches, three turns, one circuit.",
				"story": "ROUTE THE UPPER AND LOWER CHANNELS SEPARATELY.",
				"rows": _with_walls(split_rows, [Vector2i(4, 4), Vector2i(6, 4), Vector2i(10, 4), Vector2i(3, 3)]),
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"splitter": Vector2i(5, 7), "receiver": Vector2i(9, 5),
				"extra_receiver": Vector2i(8, 4),
				"mirrors": {Vector2i(5, 2): false, Vector2i(8, 2): true, Vector2i(9, 7): false},
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		8:
			return {
				"title": "09 / SHORT WAVE",
				"subtitle": "Feed both channels, then sprint the clock.",
				"story": "THE PRISM IS STABLE. THE GATE IS NOT.",
				"rows": _with_walls(split_rows, [Vector2i(4, 3), Vector2i(4, 4), Vector2i(7, 4), Vector2i(8, 4)]),
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"splitter": Vector2i(6, 7), "receiver": Vector2i(9, 5),
				"extra_receiver": Vector2i(10, 2),
				"mirrors": {Vector2i(6, 2): false, Vector2i(9, 7): false},
				"plate": Vector2i(10, 6),
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}
		_:
			return {
				"title": "10 / THE LAST ARRAY",
				"subtitle": "Four turns. Two targets. One final window.",
				"story": "REBUILD BOTH CHANNELS BEFORE THE STATION FALLS SILENT.",
				"rows": _with_walls(split_rows, [Vector2i(3, 2), Vector2i(3, 3), Vector2i(7, 5), Vector2i(9, 5), Vector2i(4, 4)]),
				"player": Vector2i(1, 6), "battery": Vector2i(2, 6),
				"socket": Vector2i(2, 7), "emitter": Vector2i(3, 7),
				"splitter": Vector2i(5, 7), "receiver": Vector2i(6, 4),
				"extra_receiver": Vector2i(9, 4),
				"mirrors": {Vector2i(5, 2): false, Vector2i(9, 2): true, Vector2i(8, 7): false, Vector2i(8, 4): true},
				"plate": Vector2i(10, 6),
				"gate": Vector2i(11, 5), "exit_tile": Vector2i(12, 5),
			}


func _with_walls(base: Array[String], cells: Array[Vector2i]) -> Array[String]:
	var rows := base.duplicate()
	for cell in cells:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + "#" + row.substr(cell.x + 1)
	return rows
