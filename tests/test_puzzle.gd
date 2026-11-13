extends SceneTree

const Puzzle := preload("res://scripts/puzzle_state.gd")
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
var failures: Array[String] = []


func _initialize() -> void:
	for level in range(Puzzle.LEVEL_COUNT):
		_solve_level(level)
	if failures.is_empty():
		print("PASS: ten room replays, split circuits, timed gates, and reset")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _walkable(s: PuzzleState, cell: Vector2i) -> bool:
	return not s.is_wall(cell) and cell != s.emitter and cell != s.receiver and cell != s.extra_receiver and cell != s.splitter \
		and cell != s.socket and cell != s.battery and not s.mirrors.has(cell) \
		and (cell != s.gate or s.gate_open)


func _path(s: PuzzleState, goal: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if s.player == goal:
		return result
	var queue: Array[Vector2i] = [s.player]
	var came_from: Dictionary = {s.player: s.player}
	var head := 0
	while head < queue.size():
		var cell := queue[head]
		head += 1
		for direction in DIRECTIONS:
			var next_cell := cell + direction
			if came_from.has(next_cell) or not _walkable(s, next_cell):
				continue
			came_from[next_cell] = cell
			queue.append(next_cell)
			if next_cell == goal:
				break
		if came_from.has(goal):
			break
	if not came_from.has(goal):
		return result
	var cursor := goal
	while cursor != s.player:
		var previous: Vector2i = came_from[cursor]
		result.push_front(cursor - previous)
		cursor = previous
	return result


func _walk_to(s: PuzzleState, goal: Vector2i, seconds_per_move: float = 0.0) -> void:
	var path := _path(s, goal)
	if path.is_empty() and goal != s.player:
		_check(false, "No walking route to %s in room %d" % [str(goal), s.level_index + 1])
		return
	for direction in path:
		_check(s.move(direction), "Walking replay blocked in room %d" % (s.level_index + 1))
		if seconds_per_move > 0.0:
			s.tick(seconds_per_move)
	_check(s.player == goal, "Walking replay missed goal in room %d" % (s.level_index + 1))


func _interact_with(s: PuzzleState, device: Vector2i) -> void:
	var found := false
	var best_path: Array[Vector2i] = []
	var best_direction := Vector2i.ZERO
	for direction in DIRECTIONS:
		var stand := device - direction
		if not _walkable(s, stand):
			continue
		var candidate := _path(s, stand)
		if candidate.is_empty() and stand != s.player:
			continue
		if not found or candidate.size() < best_path.size():
			found = true
			best_path = candidate
			best_direction = direction
	if not found:
		_check(false, "No interaction route to %s in room %d" % [str(device), s.level_index + 1])
		return
	for direction in best_path:
		_check(s.move(direction), "Interaction approach blocked in room %d" % (s.level_index + 1))
	_check(not s.move(best_direction), "Device should block movement in room %d" % (s.level_index + 1))
	_check(s.interact(), "Device interaction failed in room %d" % (s.level_index + 1))


func _mirror_solution(index: int) -> Dictionary:
	match index:
		1:
			return {Vector2i(8, 6): true}
		2:
			return {Vector2i(7, 7): true, Vector2i(7, 3): true}
		3:
			return {Vector2i(7, 7): true, Vector2i(7, 3): true}
		4:
			return {Vector2i(5, 7): true, Vector2i(5, 2): true, Vector2i(8, 2): false}
		5:
			return {Vector2i(5, 7): true, Vector2i(5, 2): true, Vector2i(9, 2): false, Vector2i(9, 6): false}
		6:
			return {Vector2i(5, 2): true}
		7:
			return {Vector2i(5, 2): true, Vector2i(8, 2): false, Vector2i(9, 7): true}
		8:
			return {Vector2i(6, 2): true, Vector2i(9, 7): true}
		9:
			return {Vector2i(5, 2): true, Vector2i(9, 2): false, Vector2i(8, 7): true, Vector2i(8, 4): false}
		_:
			return {}


func _solve_level(index: int) -> void:
	var s: PuzzleState = Puzzle.new(index)
	_check(not s.receiver_on and not s.gate_open, "Room %d should begin unpowered" % (index + 1))
	_interact_with(s, s.battery)
	_check(s.carrying, "Room %d cell should be carried" % (index + 1))
	_interact_with(s, s.socket)
	_check(s.socket_filled, "Room %d socket should be filled" % (index + 1))
	if s.splitter != Vector2i(-1, -1):
		_check(not s.gate_open, "Room %d must require both prism branches" % (index + 1))
		_check(s.beam_segments.size() > 1, "Room %d prism should create beam segments" % (index + 1))
	if index == 8:
		_interact_with(s, Vector2i(6, 2))
		_check(s.extra_receiver_on and not s.receiver_on, "Room 9 should have one live branch")
		_walk_to(s, s.plate)
		_check(s.plate_time == 0.0 and not s.gate_open, "Room 9 plate must not arm on partial signal")

	if index == 0:
		_check(s.receiver_on and s.gate_open, "Room 1 socket should open gate")
		_interact_with(s, s.socket)
		_check(s.beam.is_empty() and not s.receiver_on and not s.gate_open, "Removing cell must clear beam and close gate")
		_interact_with(s, s.socket)
		_check(s.receiver_on and s.gate_open, "Reinserting cell should restore power")

	var solution := _mirror_solution(index)
	for cell in solution:
		if s.mirrors[cell] != solution[cell]:
			_interact_with(s, cell)
	_check(s.receiver_on, "Room %d mirrors should light receiver" % (index + 1))
	if s.extra_receiver != Vector2i(-1, -1):
		_check(s.extra_receiver_on, "Room %d second receiver should light" % (index + 1))

	if index == 1:
		_interact_with(s, Vector2i(8, 6))
		_check(not s.receiver_on and not s.gate_open, "Turning mirror away must switch receiver off")
		_interact_with(s, Vector2i(8, 6))
		_check(s.receiver_on, "Turning mirror back should restore signal")
	if index == 6:
		_interact_with(s, Vector2i(5, 2))
		_check(s.receiver_on and not s.extra_receiver_on and not s.gate_open, "Room 7 partial prism signal must not open gate")
		_interact_with(s, Vector2i(5, 2))
		_check(s.gate_open, "Room 7 restoring both branches should open gate")

	if s.plate != Vector2i(-1, -1):
		_check(not s.gate_open, "Room %d should require its plate" % (index + 1))
		_walk_to(s, s.plate)
		_check(s.gate_open and s.plate_time > 0.0, "Room %d plate should open gate" % (index + 1))
		if index == 3:
			_check(s.move(Vector2i.LEFT), "Room 4 player should step off plate")
			s.tick(Puzzle.PLATE_SECONDS + 0.1)
			_check(not s.gate_open, "Room 4 gate must close after timeout")
			_check(s.move(Vector2i.RIGHT), "Room 4 player should re-enter plate")
			_check(s.gate_open, "Room 4 plate should rearm gate")
		_walk_to(s, s.exit_tile, 0.35)
	else:
		_check(s.gate_open, "Room %d receiver should open gate" % (index + 1))
		_walk_to(s, s.exit_tile)
	_check(s.won, "Room %d should be solvable by replay" % (index + 1))
	s.reset()
	_check(not s.socket_filled and not s.receiver_on and not s.gate_open, "Room %d reset should clear circuit" % (index + 1))
