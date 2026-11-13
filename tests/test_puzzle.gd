extends SceneTree

const Puzzle := preload("res://scripts/puzzle_state.gd")
var failures: Array[String] = []


func _initialize() -> void:
	_run()
	if failures.is_empty():
		print("PASS: all puzzle state and input replay checks")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _move_many(s: PuzzleState, direction: Vector2i, count: int) -> void:
	for i in range(count):
		_check(s.move(direction), "Expected move %d toward %s in room %d" % [i + 1, str(direction), s.level_index + 1])


func _run() -> void:
	var s := Puzzle.new()
	_check(not s.receiver_on and not s.gate_open, "Room 1 should begin unpowered")
	_check(not s.move(Vector2i.RIGHT), "Loose cell should block walking")
	_check(s.interact(), "Room 1 cell should be pickable")
	_check(s.carrying, "Cell should be carried")
	_check(s.move(Vector2i.RIGHT), "Player should move into former cell position")
	_check(s.interact(), "Room 1 cell should fit the socket")
	_check(s.receiver_on and s.gate_open, "Socket should power receiver and gate")
	_check(s.interact(), "Cell should be removable from socket")
	_check(not s.receiver_on and not s.gate_open and s.beam.is_empty(), "Removing cell must clear beam and close gate")
	_check(s.interact(), "Cell should fit the socket again")
	_move_many(s, Vector2i.DOWN, 1)
	_move_many(s, Vector2i.RIGHT, 7)
	_move_many(s, Vector2i.UP, 1)
	_move_many(s, Vector2i.RIGHT, 2)
	_check(s.won, "Room 1 replay should reach exit")

	s.load_level(1)
	_check(s.interact(), "Room 2 cell should be pickable")
	_move_many(s, Vector2i.RIGHT, 1)
	_move_many(s, Vector2i.DOWN, 1)
	_check(not s.move(Vector2i.RIGHT), "Socket should block walking and set facing")
	_check(s.interact(), "Room 2 cell should connect")
	_check(not s.receiver_on, "Room 2 mirror should initially miss receiver")
	_move_many(s, Vector2i.UP, 1)
	_move_many(s, Vector2i.RIGHT, 6)
	_check(not s.move(Vector2i.DOWN), "Mirror should block walking and set facing")
	_check(s.interact(), "Room 2 mirror should rotate")
	_check(s.receiver_on and s.gate_open, "Rotated mirror should power receiver")
	_check(s.interact(), "Room 2 mirror should rotate back")
	_check(not s.receiver_on and not s.gate_open, "Receiver must turn off when beam misses")
	_check(s.interact(), "Room 2 mirror should rotate into solution")
	_move_many(s, Vector2i.RIGHT, 2)
	_move_many(s, Vector2i.UP, 1)
	_move_many(s, Vector2i.RIGHT, 2)
	_check(s.won, "Room 2 replay should reach exit")

	s.load_level(2)
	_check(s.interact(), "Room 3 cell should be pickable")
	_move_many(s, Vector2i.RIGHT, 1)
	_check(not s.move(Vector2i.DOWN), "Room 3 socket should block walking")
	_check(s.interact(), "Room 3 cell should connect")
	_move_many(s, Vector2i.RIGHT, 5)
	_move_many(s, Vector2i.UP, 2)
	_check(not s.move(Vector2i.UP), "Second mirror should block walking")
	_check(s.interact(), "Second mirror should rotate")
	_check(s.receiver_on and not s.gate_open, "Plate should still be required")
	_move_many(s, Vector2i.RIGHT, 1)
	_move_many(s, Vector2i.DOWN, 2)
	_move_many(s, Vector2i.RIGHT, 1)
	_check(s.gate_open and s.plate_time > 0.0, "Plate should start timed gate")
	_move_many(s, Vector2i.RIGHT, 1)
	s.tick(6.1)
	_check(not s.gate_open, "Gate should close after timer expires")
	_move_many(s, Vector2i.LEFT, 1)
	_check(s.gate_open, "Plate should rearm gate")
	_move_many(s, Vector2i.RIGHT, 1)
	_move_many(s, Vector2i.UP, 1)
	_move_many(s, Vector2i.RIGHT, 2)
	_check(s.won, "Room 3 replay should reach exit")
	s.reset()
	_check(not s.socket_filled and not s.receiver_on and not s.gate_open, "Reset should clear all circuit state")
