extends Node2D

const Puzzle := preload("res://scripts/puzzle_state.gd")
const AMBIENT := preload("res://audio/ambient.wav")
const PICKUP_SOUND := preload("res://audio/pickup.wav")
const ROTATE_SOUND := preload("res://audio/rotate.wav")
const POWER_SOUND := preload("res://audio/power.wav")
const SUCCESS_SOUND := preload("res://audio/success.wav")
const TILE := 52.0
const ORIGIN := Vector2(196.0, 157.0)
const START_BUTTON := Rect2(390, 420, 340, 62)
const LEARN_BUTTON := Rect2(390, 494, 340, 54)
const LEARN_BACK_BUTTON := Rect2(250, 601, 260, 58)
const LEARN_START_BUTTON := Rect2(610, 601, 260, 58)
const NEXT_BUTTON := Rect2(425, 459, 270, 58)
const RESET_BUTTON := Rect2(970, 525, 110, 42)

var state: PuzzleState
var mode := "menu"
var clock := 0.0
var flash := 0.0
var hint := ""
var sequence_time := 0.0
var target_level := 0
var audio_enabled := true
var ambient_player: AudioStreamPlayer
var sound_player: AudioStreamPlayer
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
	ambient_player = AudioStreamPlayer.new()
	ambient_player.stream = AMBIENT
	ambient_player.volume_db = -27.0
	ambient_player.finished.connect(_on_ambient_finished)
	add_child(ambient_player)
	sound_player = AudioStreamPlayer.new()
	sound_player.volume_db = -13.0
	add_child(sound_player)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	clock += delta
	flash = maxf(0.0, flash - delta)
	if mode == "play":
		state.tick(delta)
	elif mode == "intro":
		sequence_time += delta
		if sequence_time >= 3.6:
			_start(target_level)
	elif mode == "transition":
		sequence_time += delta
		if sequence_time >= 1.8:
			_start(target_level)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_handle_click(event.position)


func _handle_key(key: Key) -> void:
	if key == KEY_M:
		audio_enabled = not audio_enabled
		if audio_enabled:
			_ensure_ambient()
		else:
			ambient_player.stop()
			sound_player.stop()
		return
	if key == KEY_ENTER or key == KEY_KP_ENTER:
		if mode == "menu":
			_begin_intro(0)
		elif mode == "learn":
			_begin_intro(0)
		elif mode == "intro" or mode == "transition":
			_start(target_level)
		elif mode == "play" and state.won:
			_advance()
		elif mode == "complete":
			_begin_intro(0)
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
			_interact()
		KEY_R:
			state.reset()
			hint = "Room reset."
			_play_sound("rotate")


func _handle_click(pos: Vector2) -> void:
	if mode == "menu":
		if START_BUTTON.has_point(pos):
			_begin_intro(0)
			return
		if LEARN_BUTTON.has_point(pos):
			mode = "learn"
			_ensure_ambient()
			_play_sound("rotate")
			return
		for i in range(Puzzle.LEVEL_COUNT):
			if _level_button(i).has_point(pos):
				_begin_intro(i)
				return
	elif mode == "learn":
		if LEARN_BACK_BUTTON.has_point(pos):
			mode = "menu"
		elif LEARN_START_BUTTON.has_point(pos):
			_begin_intro(0)
		return
	elif mode == "intro" or mode == "transition":
		_start(target_level)
		return
	elif mode == "complete":
		if START_BUTTON.has_point(pos):
			_begin_intro(0)
		return
	elif mode == "play":
		if state.won:
			if NEXT_BUTTON.has_point(pos):
				_advance()
			return
		if RESET_BUTTON.has_point(pos):
			state.reset()
			_play_sound("rotate")
			return
		var buttons := _direction_buttons()
		for direction in buttons:
			if buttons[direction].has_point(pos):
				_move(direction)
				return
		if pos.distance_to(Vector2(1026, 416)) <= 51.0:
			_interact()
			return


func _begin_intro(index: int) -> void:
	target_level = index
	sequence_time = 0.0
	mode = "intro" if index == 0 else "transition"
	_ensure_ambient()
	_play_sound("power")


func _start(index: int) -> void:
	state.load_level(index)
	mode = "play"
	hint = ""
	flash = 0.0
	sequence_time = 0.0


func _advance() -> void:
	if state.level_index < Puzzle.LEVEL_COUNT - 1:
		target_level = state.level_index + 1
		sequence_time = 0.0
		mode = "transition"
	else:
		mode = "complete"


func _move(direction: Vector2i) -> void:
	if state.move(direction):
		hint = ""
		if state.won:
			flash = 0.7
			_play_sound("success")
	else:
		hint = "Blocked. Try another route or interact with the device."


func _interact() -> void:
	var had_cell := state.carrying
	var was_connected := state.socket_filled
	if state.interact():
		flash = 0.32
		hint = ""
		if state.socket_filled != was_connected:
			_play_sound("power")
		elif state.carrying != had_cell:
			_play_sound("pickup")
		else:
			_play_sound("rotate")
	else:
		hint = "Face the cell, socket or mirror first."


func _ensure_ambient() -> void:
	if audio_enabled and not ambient_player.playing:
		ambient_player.play()


func _on_ambient_finished() -> void:
	if audio_enabled:
		ambient_player.play()


func _play_sound(which: String) -> void:
	if not audio_enabled:
		return
	match which:
		"pickup":
			sound_player.stream = PICKUP_SOUND
		"rotate":
			sound_player.stream = ROTATE_SOUND
		"power":
			sound_player.stream = POWER_SOUND
		"success":
			sound_player.stream = SUCCESS_SOUND
	sound_player.play()


func _level_button(index: int) -> Rect2:
	return Rect2(248 + index * 107, 599, 98, 48)


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
		"learn":
			_draw_learn()
		"intro":
			_draw_intro()
		"transition":
			_draw_transition()
		"play":
			_draw_game()
		"complete":
			_draw_complete()
	if flash > 0.0 and mode == "play" and not state.won:
		draw_rect(Rect2(0, 0, 1120, 760), cyan * Color(1, 1, 1, flash * 0.08))


func _draw_background() -> void:
	draw_rect(Rect2(0, 0, 1120, 760), bg)
	draw_circle(Vector2(158, 130), 230, purple * Color(1, 1, 1, 0.025))
	draw_circle(Vector2(965, 625), 280, cyan * Color(1, 1, 1, 0.025))
	for y in range(0, 760, 36):
		for x in range(0, 1120, 36):
			var twinkle := 0.08 + 0.045 * sin(clock * 0.7 + float(x + y) * 0.045)
			draw_circle(Vector2(x + 8, y + 8), 1.1, cyan * Color(1, 1, 1, twinkle))
	var sweep := fmod(clock * 82.0, 760.0)
	draw_line(Vector2(0, sweep), Vector2(1120, sweep), cyan * Color(1, 1, 1, 0.075), 2.0)
	draw_line(Vector2(0, 112), Vector2(1120, 112), Color("#223752"), 1.0)
	draw_line(Vector2(0, 680), Vector2(1120, 680), Color("#223752"), 1.0)


func _draw_menu() -> void:
	_label("THE LAST SIGNAL / A GAME SYSTEMS SHOWCASE", Vector2(58, 58), 17, muted)
	draw_circle(Vector2(560, 268), 190 + 8 * sin(clock * 0.65), cyan * Color(1, 1, 1, 0.035))
	_label("THE LAST", Vector2(238, 211), 72, ink)
	_label("SIGNAL", Vector2(450, 288), 76, cyan)
	draw_line(Vector2(246, 319), Vector2(874, 319), cyan * Color(1, 1, 1, 0.48), 2.0)
	_label("Six rooms. One dying station. Bend light to bring it back.", Vector2(271, 370), 21, muted)
	_button(START_BUTTON, "PLAY CAMPAIGN", cyan)
	_button(LEARN_BUTTON, "LEARN TO PLAY", purple)
	_label("CHOOSE A CHAPTER / RISING DIFFICULTY", Vector2(416, 581), 16, muted)
	for i in range(Puzzle.LEVEL_COUNT):
		var rect := _level_button(i)
		var color := cyan if i == 0 else purple
		_button(rect, "%02d" % (i + 1), color)
		for pip in range(i + 1):
			draw_rect(Rect2(rect.position.x + 18 + pip * 11, rect.end.y - 8, 7, 3), color)
	_label("WASD / ARROWS  MOVE     E / SPACE  USE     R  RESET     M  SOUND", Vector2(239, 722), 16, muted)
	_draw_orbit(Vector2(150, 263), 57, cyan, clock * 0.6)
	_draw_orbit(Vector2(968, 263), 57, purple, -clock * 0.8)


func _draw_learn() -> void:
	_label("FIELD MANUAL", Vector2(79, 66), 48, ink)
	_label("LEARN TO PLAY / FOUR RULES, THEN THE STATION IS YOURS", Vector2(79, 102), 17, cyan)
	_draw_learn_card(Rect2(80, 151, 460, 190), "01", "MOVE & FACE", "WASD or arrow keys move one tile.", "Face a device before using it.", purple)
	_draw_learn_card(Rect2(580, 151, 460, 190), "02", "CARRY POWER", "Face the gold cell and press E.", "Face a socket and press E to connect.", gold)
	_draw_learn_card(Rect2(80, 365, 460, 190), "03", "BEND LIGHT", "Face a mirror and press E to rotate.", "Light the receiver to unlock the gate.", cyan)
	_draw_learn_card(Rect2(580, 365, 460, 190), "04", "BEAT THE CLOCK", "Later rooms have pressure plates.", "Reach the gate before the timer ends.", coral)
	_button(LEARN_BACK_BUTTON, "BACK TO TITLE", purple)
	_button(LEARN_START_BUTTON, "START GUIDED ROOM", cyan)
	_label("ON-SCREEN CONTROLS ALSO WORK   •   ESC RETURNS HOME", Vector2(335, 719), 16, muted)


func _draw_learn_card(rect: Rect2, number: String, title: String, line_a: String, line_b: String, color: Color) -> void:
	draw_rect(rect, panel)
	draw_rect(rect, color * Color(1, 1, 1, 0.6), false, 2.0)
	draw_rect(Rect2(rect.position, Vector2(8, rect.size.y)), color)
	_label(number, rect.position + Vector2(29, 42), 24, color)
	_label(title, rect.position + Vector2(80, 43), 24, ink)
	_label(line_a, rect.position + Vector2(30, 104), 19, muted)
	_label(line_b, rect.position + Vector2(30, 137), 19, muted)


func _draw_intro() -> void:
	var progress := clampf(sequence_time / 3.6, 0.0, 1.0)
	_label("INCOMING TRANSMISSION", Vector2(77, 71), 21, cyan)
	_draw_orbit(Vector2(560, 366), 155, cyan, clock * 0.7)
	if sequence_time > 0.3:
		_label("GRID STATUS / OFFLINE", Vector2(330, 252), 36, coral)
	if sequence_time > 1.15:
		_label("ONE POWER CELL REMAINS", Vector2(317, 363), 34, ink)
	if sequence_time > 2.1:
		var line := "RESTORE THE LAST SIGNAL"
		var letters := clampi(int((sequence_time - 2.1) * 24.0), 0, line.length())
		_label(line.substr(0, letters), Vector2(348, 471), 30, cyan)
	draw_rect(Rect2(270, 603, 580, 4), panel_light)
	draw_rect(Rect2(270, 603, 580 * progress, 4), cyan)
	_label("ENTER OR CLICK TO SKIP", Vector2(455, 653), 17, muted)


func _draw_transition() -> void:
	var preview: PuzzleState = Puzzle.new(target_level)
	_label("SIGNAL ROUTED", Vector2(455, 92), 20, cyan)
	_label(preview.title, Vector2(285, 309), 48, ink)
	_label(preview.story, Vector2(294, 377), 23, muted)
	for i in range(Puzzle.LEVEL_COUNT):
		var rect := Rect2(263 + i * 100, 484, 80, 8)
		draw_rect(rect, cyan if i < target_level else panel_light)
	_label("ENTER OR CLICK TO CONTINUE", Vector2(420, 632), 17, muted)


func _draw_complete() -> void:
	_draw_orbit(Vector2(560, 290), 190, cyan, clock * 0.7)
	_label("TRANSMISSION RESTORED", Vector2(239, 253), 52, cyan)
	_label("Six circuits are live. The station has power again.", Vector2(298, 336), 22, ink)
	_label("06 / 06 ROOMS COMPLETE", Vector2(430, 389), 20, muted)
	_button(START_BUTTON, "PLAY AGAIN", cyan)
	_label("BUILT IN GODOT   •   GDSCRIPT   •   DETERMINISTIC PUZZLE STATE", Vector2(291, 722), 16, muted)


func _draw_game() -> void:
	_label("THE LAST SIGNAL", Vector2(52, 57), 34, ink)
	_label(state.title, Vector2(696, 54), 21, cyan)
	_label(state.subtitle, Vector2(196, 100), 19, muted)
	for i in range(Puzzle.LEVEL_COUNT):
		var bar := Rect2(196 + i * 123, 126, 104, 4)
		draw_rect(bar, cyan if i <= state.level_index else Color("#2b3c55"))
	_draw_board()
	if state.level_index == 0 and not state.won:
		_draw_tutorial()
	_draw_controls()
	_draw_status()
	if state.won:
		_draw_win_overlay()


func _draw_tutorial() -> void:
	var target := state.battery
	var title := "STEP 1 / PICK UP THE CELL"
	var detail := "Face the glowing gold cell. Press E or tap the action button."
	var marker := gold
	if state.carrying:
		target = state.socket
		title = "STEP 2 / CONNECT POWER"
		detail = "Move beside the ringed socket, face it, and press E."
	elif state.socket_filled:
		target = state.exit_tile
		title = "STEP 3 / FOLLOW THE LIGHT"
		detail = "The gate is open. Walk through it to the cyan exit arrow."
		marker = cyan
	var rect := Rect2(260, 168, 600, 75)
	draw_rect(rect, Color(0.05, 0.095, 0.16, 0.96))
	draw_rect(rect, marker, false, 2.0)
	draw_rect(Rect2(rect.position, Vector2(7, rect.size.y)), marker)
	_label(title, Vector2(281, 198), 20, marker)
	_label(detail, Vector2(281, 227), 18, ink)
	var radius := 28.0 + 3.0 * sin(clock * 5.0)
	draw_arc(_center(target), radius, 0, TAU, 48, marker * Color(1, 1, 1, 0.9), 3.0)
	draw_arc(_center(target), radius + 7.0, 0, TAU, 48, marker * Color(1, 1, 1, 0.24), 3.0)


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
	var travel := fmod(clock * 3.6, float(state.beam.size() - 1))
	var segment := mini(int(travel), state.beam.size() - 2)
	var pulse_pos := _center(state.beam[segment]).lerp(_center(state.beam[segment + 1]), travel - float(segment))
	draw_circle(pulse_pos, 13.0, cyan * Color(1, 1, 1, 0.22))
	draw_circle(pulse_pos, 5.0, Color.WHITE)


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
	elif state.level_index == 0:
		_label("Follow the pulsing marker. Each step teaches one action.", Vector2(196, 701), 16, muted)
	else:
		_label("Face a device, then use it.", Vector2(196, 701), 16, muted)


func _draw_win_overlay() -> void:
	draw_rect(Rect2(188, 149, 744, 484), Color(0.035, 0.055, 0.105, 0.88))
	draw_arc(Vector2(560, 346), 184 + 7 * sin(clock * 3.0), 0, TAU, 64, cyan * Color(1, 1, 1, 0.25), 3.0)
	_label("ROOM RESTORED", Vector2(356, 334), 48, cyan)
	_label("%02d / %02d   •   %d MOVES" % [state.level_index + 1, Puzzle.LEVEL_COUNT, state.moves], Vector2(444, 397), 20, ink)
	_button(NEXT_BUTTON, "NEXT ROOM" if state.level_index < Puzzle.LEVEL_COUNT - 1 else "FINISH", cyan)


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
