extends Node2D

const Puzzle := preload("res://scripts/puzzle_state.gd")
const TILE := 52.0
const ORIGIN := Vector2(196.0, 157.0)
const START_BUTTON := Rect2(390, 455, 340, 64)
const NEXT_BUTTON := Rect2(425, 459, 270, 58)
const RESET_BUTTON := Rect2(970, 525, 110, 42)

var state: PuzzleState
var mode := "menu"
var clock := 0.0
var flash := 0.0
var hint := ""
var bg := Color("#0a1020")
var panel := Color("#141f36")
var panel_light := Color("#1c2b45")
var ink := Color("#e9f5ff")
var muted := Color("#899cb6")
var cyan := Color("#6ee9e1")
var gold := Color("#ffc879")
var coral := Color("#ff7589")
var purple := Color("#a995ff")


func _ready() -> void:
	state = Puzzle.new()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	clock += delta
	flash = maxf(0.0, flash - delta)
	if mode == "play":
		state.tick(delta)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_click(event.position)


func _handle_key(key: Key) -> void:
	if key == KEY_ENTER or key == KEY_KP_ENTER:
		if mode == "menu":
			_start(0)
		elif mode == "play" and state.won:
			_advance()
		elif mode == "complete":
			_start(0)
		return
	if key == KEY_ESCAPE:
		mode = "menu"
		return
	if mode != "play" or state.won:
		return
	match key:
		KEY_W, KEY_UP:
			_move(Vector2i.UP)
		KEY_S, KEY_DOWN:
			_move(Vector2i.DOWN)
		KEY_A, KEY_LEFT:
			_move(Vector2i.LEFT)
		KEY_D, KEY_RIGHT:
			_move(Vector2i.RIGHT)
		KEY_E, KEY_SPACE:
			if state.interact():
				flash = 0.26
			else:
				hint = "Face the cell, socket or mirror first."
		KEY_R:
			state.reset()
			hint = "Room reset."


func _handle_click(pos: Vector2) -> void:
	if mode == "menu":
		if START_BUTTON.has_point(pos):
			_start(0)
			return
		for i in range(3):
			if Rect2(335 + i * 158, 564, 136, 52).has_point(pos):
				_start(i)
				return
	elif mode == "complete":
		if START_BUTTON.has_point(pos):
			_start(0)
		return
	elif mode == "play":
		if state.won:
			if NEXT_BUTTON.has_point(pos):
				_advance()
			return
		if RESET_BUTTON.has_point(pos):
			state.reset()
			return
		var buttons := _direction_buttons()
		for direction in buttons:
			if buttons[direction].has_point(pos):
				_move(direction)
				return
		if pos.distance_to(Vector2(1026, 416)) <= 51.0:
			if state.interact():
				flash = 0.26
			return


func _start(index: int) -> void:
	state.load_level(index)
	mode = "play"
	hint = ""
	flash = 0.0


func _advance() -> void:
	if state.level_index < 2:
		_start(state.level_index + 1)
	else:
		mode = "complete"


func _move(direction: Vector2i) -> void:
	if state.move(direction):
		hint = ""
	else:
		hint = "Blocked. Try another route or interact with the device."


func _direction_buttons() -> Dictionary:
	return {
		Vector2i.UP: Rect2(84, 348, 52, 52),
		Vector2i.LEFT: Rect2(28, 404, 52, 52),
		Vector2i.DOWN: Rect2(84, 460, 52, 52),
		Vector2i.RIGHT: Rect2(140, 404, 52, 52),
	}


func _draw() -> void:
	_draw_background()
	match mode:
		"menu":
			_draw_menu()
		"play":
			_draw_game()
		"complete":
			_draw_complete()


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, 1120, 760), bg)
	for y in range(0, 760, 36):
		for x in range(0, 1120, 36):
			var twinkle := 0.08 + 0.045 * sin(clock * 0.7 + float(x + y) * 0.045)
			draw_circle(Vector2(x + 8, y + 8), 1.1, cyan * Color(1, 1, 1, twinkle))
	draw_line(Vector2(0, 112), Vector2(1120, 112), Color("#223752"), 1.0)
	draw_line(Vector2(0, 680), Vector2(1120, 680), Color("#223752"), 1.0)


func _draw_menu() -> void:
	_label("A SMALL GAME / A SYSTEMS SHOWCASE", Vector2(57, 57), 17, muted)
	_label("THE LAST", Vector2(243, 225), 72, ink)
	_label("SIGNAL", Vector2(449, 301), 72, cyan)
	draw_line(Vector2(257, 331), Vector2(863, 331), cyan * Color(1, 1, 1, 0.55), 2.0)
	_label("Carry power. Bend light. Escape before the gate goes dark.", Vector2(276, 380), 21, muted)
	_button(START_BUTTON, "START TRANSMISSION", cyan)
	_label("or jump to a room", Vector2(492, 550), 16, muted)
	for i in range(3):
		var rect := Rect2(335 + i * 158, 564, 136, 52)
		_button(rect, "ROOM %02d" % (i + 1), purple)
	_label("WASD / ARROWS   MOVE     E / SPACE   INTERACT     R   RESET", Vector2(254, 724), 17, muted)
	_draw_orbit(Vector2(164, 268), 56, cyan, clock)
	_draw_orbit(Vector2(963, 268), 56, purple, -clock)


func _draw_complete() -> void:
	_label("TRANSMISSION RESTORED", Vector2(247, 245), 51, cyan)
	_label("All three rooms are live. The station has power again.", Vector2(285, 322), 22, ink)
	_label("03 / 03 rooms complete", Vector2(430, 390), 20, muted)
	_button(START_BUTTON, "PLAY AGAIN", cyan)
	_label("Built in Godot • GDScript • deterministic puzzle state", Vector2(338, 724), 16, muted)


func _draw_game() -> void:
	_label("THE LAST SIGNAL", Vector2(52, 57), 34, ink)
	_label(state.title, Vector2(696, 54), 21, cyan)
	_label(state.subtitle, Vector2(196, 100), 19, muted)
	_draw_board()
	_draw_controls()
	_draw_status()
	if state.won:
		_draw_win_overlay()


func _draw_board() -> void:
	draw_rect(Rect2(188, 149, 744, 484), Color("#0d1729"), true)
	draw_rect(Rect2(188, 149, 744, 484), Color("#314962"), false, 2.0)
	for y in range(Puzzle.HEIGHT):
		for x in range(Puzzle.WIDTH):
			var cell := Vector2i(x, y)
			var rect := Rect2(ORIGIN + Vector2(x, y) * TILE, Vector2(TILE, TILE))
			if state.is_wall(cell):
				draw_rect(rect.grow(-2), panel_light)
				draw_rect(Rect2(rect.position + Vector2(5, 5), Vector2(TILE - 10, 5)), Color("#2a3c57"))
			else:
				var shade := Color("#17243a") if (x + y) % 2 == 0 else Color("#192840")
				draw_rect(rect.grow(-1), shade)
				draw_circle(rect.get_center(), 1.15, Color("#32445e"))
	_draw_beam()
	_draw_exit()
	_draw_plate()
	_draw_socket()
	_draw_emitter()
	_draw_receiver()
	for cell in state.mirrors:
		_draw_mirror(cell, state.mirrors[cell])
	_draw_gate()
	if state.battery != Vector2i(-1, -1):
		_draw_battery(_center(state.battery), false)
	_draw_player()


func _draw_beam() -> void:
	if state.beam.size() < 2:
		return
	for i in range(state.beam.size() - 1):
		var a := _center(state.beam[i])
		var b := _center(state.beam[i + 1])
		draw_line(a, b, cyan * Color(1, 1, 1, 0.12), 22.0)
		draw_line(a, b, cyan * Color(1, 1, 1, 0.3), 9.0)
		draw_line(a, b, Color("#f1fffb"), 3.0)
	for cell in state.beam:
		draw_circle(_center(cell), 3.0 + 0.8 * sin(clock * 9.0), Color("#edfffb"))


func _draw_socket() -> void:
	var c := _center(state.socket)
	draw_circle(c, 21, Color("#304353"))
	draw_arc(c, 19, 0, TAU, 36, gold if state.socket_filled else muted, 3.0)
	draw_circle(c, 11, gold if state.socket_filled else Color("#101a2b"))
	if state.socket_filled:
		draw_circle(c, 5, Color("#fff1c4"))


func _draw_emitter() -> void:
	var c := _center(state.emitter)
	draw_circle(c, 20, Color("#274756") if state.socket_filled else panel_light)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -10), c + Vector2(11, 0), c + Vector2(-8, 10)]), cyan if state.socket_filled else muted)


func _draw_receiver() -> void:
	var c := _center(state.receiver)
	draw_circle(c, 21, cyan * Color(1, 1, 1, 0.2) if state.receiver_on else Color("#382c43"))
	draw_arc(c, 18, 0, TAU, 36, cyan if state.receiver_on else coral, 3.0)
	draw_circle(c, 9, cyan if state.receiver_on else Color("#51364c"))
	if state.receiver_on:
		draw_circle(c, 4, Color.WHITE)


func _draw_mirror(cell: Vector2i, slash: bool) -> void:
	var c := _center(cell)
	draw_rect(Rect2(c - Vector2(20, 20), Vector2(40, 40)), Color("#27354d"))
	draw_rect(Rect2(c - Vector2(20, 20), Vector2(40, 40)), purple, false, 2.0)
	var a := c + (Vector2(-13, 13) if slash else Vector2(-13, -13))
	var b := c + (Vector2(13, -13) if slash else Vector2(13, 13))
	draw_line(a, b, Color("#e4dbff"), 6.0)
	draw_circle(c, 3, purple)


func _draw_gate() -> void:
	var rect := Rect2(ORIGIN + Vector2(state.gate) * TILE, Vector2(TILE, TILE))
	if state.gate_open:
		draw_rect(rect.grow(-4), cyan * Color(1, 1, 1, 0.15))
		draw_line(rect.position + Vector2(8, 10), rect.position + Vector2(8, 42), cyan, 3.0)
		draw_line(rect.position + Vector2(44, 10), rect.position + Vector2(44, 42), cyan, 3.0)
	else:
		draw_rect(rect.grow(-4), Color("#3e2b42"))
		for i in range(3):
			var x := rect.position.x + 13 + i * 13
			draw_line(Vector2(x, rect.position.y + 8), Vector2(x, rect.end.y - 8), coral, 4.0)


func _draw_exit() -> void:
	var c := _center(state.exit_tile)
	draw_rect(Rect2(c - Vector2(19, 19), Vector2(38, 38)), Color("#274956"))
	draw_line(c + Vector2(-10, 0), c + Vector2(8, 0), cyan, 4.0)
	draw_line(c + Vector2(3, -7), c + Vector2(10, 0), cyan, 4.0)
	draw_line(c + Vector2(3, 7), c + Vector2(10, 0), cyan, 4.0)


func _draw_plate() -> void:
	if state.plate == Vector2i(-1, -1):
		return
	var c := _center(state.plate)
	draw_rect(Rect2(c - Vector2(20, 20), Vector2(40, 40)), Color("#4b3b31"))
	draw_rect(Rect2(c - Vector2(15, 15), Vector2(30, 30)), gold if state.plate_time > 0.0 else Color("#806b50"), false, 3.0)
	draw_circle(c, 5, gold)


func _draw_battery(c: Vector2, small: bool) -> void:
	var r := 10.0 if small else 17.0
	draw_rect(Rect2(c - Vector2(r, r), Vector2(r * 2, r * 2)), Color("#5f4737"))
	draw_rect(Rect2(c - Vector2(r - 3, r - 3), Vector2((r - 3) * 2, (r - 3) * 2)), gold)
	draw_line(c + Vector2(-5, 0), c + Vector2(5, 0), Color("#5a3c2c"), 2.0)
	draw_line(c, c + Vector2(0, -5), Color("#5a3c2c"), 2.0)


func _draw_player() -> void:
	var c := _center(state.player)
	draw_circle(c, 22 + sin(clock * 4.0) * 1.3, purple * Color(1, 1, 1, 0.18))
	draw_circle(c, 17, purple)
	draw_circle(c, 11, Color("#dcd4ff"))
	draw_circle(c + Vector2(state.facing) * 7.0, 3.5, bg)
	if state.carrying:
		_draw_battery(c + Vector2(0, -25), true)


func _draw_controls() -> void:
	_label("MOVE", Vector2(79, 326), 16, muted)
	var buttons := _direction_buttons()
	for direction in buttons:
		var rect: Rect2 = buttons[direction]
		draw_rect(rect, panel_light)
		draw_rect(rect, Color("#39516a"), false, 1.5)
		var d := Vector2(direction)
		var center := rect.get_center()
		var side := Vector2(-d.y, d.x) * 7.0
		draw_colored_polygon(PackedVector2Array([center + d * 14.0, center - d * 7.0 + side, center - d * 7.0 - side]), ink)
	_label("ACTION", Vector2(990, 329), 16, muted)
	draw_circle(Vector2(1026, 416), 52, Color("#2a4050"))
	draw_arc(Vector2(1026, 416), 50, 0, TAU, 48, cyan, 3.0)
	_label("E", Vector2(1015, 430), 42, cyan)
	_button(RESET_BUTTON, "RESET", coral)


func _draw_status() -> void:
	var cell_text := "CELL  CARRIED" if state.carrying else ("CELL  CONNECTED" if state.socket_filled else "CELL  IDLE")
	var signal_text := "SIGNAL  LIVE" if state.receiver_on else "SIGNAL  OFFLINE"
	_label(cell_text, Vector2(196, 660), 18, gold if state.carrying or state.socket_filled else muted)
	_label(signal_text, Vector2(440, 660), 18, cyan if state.receiver_on else coral)
	if state.plate != Vector2i(-1, -1):
		_label("GATE  %0.1fs" % state.plate_time if state.plate_time > 0.0 else "GATE  WAITING", Vector2(697, 660), 18, gold if state.plate_time > 0.0 else muted)
	_label("WASD / ARROWS  MOVE     E / SPACE  USE     R  RESET", Vector2(245, 720), 17, muted)
	if not hint.is_empty():
		_label(hint, Vector2(196, 701), 16, coral)
	elif flash > 0.0:
		_label("Circuit updated.", Vector2(196, 701), 16, cyan)
	else:
		_label("Face a device, then use it.", Vector2(196, 701), 16, muted)


func _draw_win_overlay() -> void:
	draw_rect(Rect2(188, 149, 744, 484), Color(0.035, 0.055, 0.105, 0.88))
	_label("ROOM RESTORED", Vector2(356, 334), 48, cyan)
	_label("%d moves  •  signal routed" % state.moves, Vector2(431, 397), 20, ink)
	_button(NEXT_BUTTON, "NEXT ROOM" if state.level_index < 2 else "FINISH", cyan)


func _button(rect: Rect2, title: String, color: Color) -> void:
	draw_rect(rect, color * Color(1, 1, 1, 0.13))
	draw_rect(rect, color, false, 2.0)
	var font := ThemeDB.fallback_font
	var size := 20
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_label(title, Vector2(rect.get_center().x - width / 2.0, rect.get_center().y + 7), size, color)


func _draw_orbit(center: Vector2, radius: float, color: Color, phase: float) -> void:
	draw_arc(center, radius, 0, TAU, 60, color * Color(1, 1, 1, 0.5), 2.0)
	draw_circle(center + Vector2(cos(phase), sin(phase)) * radius, 7, color)
	draw_circle(center, 13, color * Color(1, 1, 1, 0.3))


func _center(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * TILE + Vector2.ONE * TILE * 0.5


func _label(value: String, pos: Vector2, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
