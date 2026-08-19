extends Node2D

const PLAYER = preload("res://scripts/player.gd")
const ENEMY = preload("res://scripts/enemy.gd")

var player
var enemies: Array[Node] = []
var cards: Array[Dictionary] = []
var traps: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var spawn_timer := 0.0
var score := 0
var wave := 1
var game_time := 0.0
var rng := RandomNumberGenerator.new()

var purple := Color("#a84cff")
var dark := Color("#080610")
var gold := Color("#d7a94b")

func _ready():
	rng.randomize()
	player = PLAYER.new()
	player.position = Vector2(1200, 700)
	add_child(player)
	var camera := Camera2D.new()
	camera.enabled = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2400
	camera.limit_bottom = 1400
	player.add_child(camera)
	player.shoot_card.connect(_on_shoot_card)
	player.ability_used.connect(_on_ability)
	player.ultimate_used.connect(_on_ultimate)

	for i in range(8):
		spawn_enemy()
	queue_redraw()

func _process(delta):
	game_time += delta
	spawn_timer -= delta

	if spawn_timer <= 0:
		spawn_enemy()
		spawn_timer = max(0.45, 1.6 - wave * 0.04)

	if int(game_time) > wave * 25:
		wave += 1

	update_cards(delta)
	update_traps(delta)
	update_effects(delta)
	clean_enemies()
	queue_redraw()

func spawn_enemy():
	var e = ENEMY.new()
	var side = rng.randi_range(0,3)
	if side == 0:
		e.position = Vector2(rng.randf_range(100,2300), 70)
	elif side == 1:
		e.position = Vector2(rng.randf_range(100,2300), 1330)
	elif side == 2:
		e.position = Vector2(70, rng.randf_range(100,1300))
	else:
		e.position = Vector2(2330, rng.randf_range(100,1300))
	e.setup(player)
	e.hp += wave * 4
	e.speed += wave * 3
	add_child(e)
	enemies.append(e)

func _on_shoot_card(pos, dir):
	cards.append({
		"pos": pos,
		"dir": dir,
		"speed": 900.0,
		"life": 1.2,
		"type": "club"
	})

func _on_ability(name, pos, dir):
	if name == "Q":
		cards.append({"pos":pos, "dir":dir, "speed":1200.0, "life":1.0, "type":"q"})
	elif name == "E":
		traps.append({"pos":pos, "life":5.0, "radius":100.0})
	elif name == "C":
		effects.append({"pos":pos + dir*120.0, "life":0.7, "radius":15.0, "max_radius":150.0, "type":"dust"})

func _on_ultimate():
	effects.append({"pos":player.global_position, "life":2.0, "radius":30.0, "max_radius":900.0, "type":"ultimate"})
	for e in enemies:
		if is_instance_valid(e):
			e.hit(90, "stun")
			# [CORREGIDO] Eliminamos player.add_ultimate(5) para evitar el Stack Overflow (recursión)

func update_cards(delta):
	for i in range(cards.size()-1, -1, -1):
		var c = cards[i]
		c.pos += c.dir * c.speed * delta
		c.life -= delta
		var removed := false
		for e in enemies:
			if is_instance_valid(e) and c.pos.distance_to(e.global_position) < 30:
				var damage = 16 if c.type == "club" else 30
				var effect = "slow" if c.type == "club" else "stun"
				e.hit(damage, effect)
				player.add_ultimate(4)
				score += 10
				removed = true
				break
		if c.life <= 0 or removed:
			cards.remove_at(i)
		else:
			cards[i] = c

func update_traps(delta):
	for i in range(traps.size()-1, -1, -1):
		var t = traps[i]
		t.life -= delta
		for e in enemies:
			if is_instance_valid(e) and e.global_position.distance_to(t.pos) < t.radius:
				e.hit(28, "stun")
				player.add_ultimate(2)
				# [CORREGIDO] Destruimos la trampa al tocar a un enemigo (como una mina) para evitar dar daño infinito
				t.life = 0
				break 
		if t.life <= 0:
			traps.remove_at(i)
		else:
			traps[i] = t

func update_effects(delta):
	for i in range(effects.size()-1, -1, -1):
		var fx = effects[i]
		fx.life -= delta
		fx.radius = lerp(fx.radius, fx.max_radius, delta * 5.0)
		for e in enemies:
			if is_instance_valid(e) and e.global_position.distance_to(fx.pos) < fx.radius:
				# [CORREGIDO] Daño reducido a 1 porque esto se ejecuta 60 veces por segundo
				if fx.type == "dust":
					e.hit(1, "slow")
				elif fx.type == "ultimate":
					e.hit(1, "stun")
		if fx.life <= 0:
			effects.remove_at(i)
		else:
			effects[i] = fx

func clean_enemies():
	for i in range(enemies.size()-1, -1, -1):
		if not is_instance_valid(enemies[i]):
			enemies.remove_at(i)

func _draw():
	draw_rect(Rect2(0,0,2400,1400), dark)
	# Arena grid
	for x in range(0,2401,80):
		draw_line(Vector2(x,0), Vector2(x,1400), Color(0.18,0.10,0.25,0.35), 1)
	for y in range(0,1401,80):
		draw_line(Vector2(0,y), Vector2(2400,y), Color(0.18,0.10,0.25,0.35), 1)

	# Central casino-like ring
	draw_circle(Vector2(1200,700), 310, Color(0.08,0.03,0.12,0.8))
	draw_arc(Vector2(1200,700), 310, 0, TAU, 96, purple, 4)
	draw_arc(Vector2(1200,700), 220, 0, TAU, 96, Color(0.5,0.25,0.8,0.4), 2)

	for c in cards:
		var p: Vector2 = c.pos
		draw_set_transform(p, c.dir.angle(), Vector2.ONE)
		var poly = PackedVector2Array([Vector2(-10,-18),Vector2(10,-18),Vector2(10,18),Vector2(-10,18)])
		draw_colored_polygon(poly, Color("#efe7ff"))
		draw_polyline(poly + PackedVector2Array([poly[0]]), purple, 2)
		draw_string(ThemeDB.fallback_font, Vector2(-6,5), "♣", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, purple)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

	for t in traps:
		draw_circle(t.pos, t.radius, Color(0.45,0.1,0.8,0.08))
		draw_arc(t.pos, t.radius, 0, TAU, 48, purple, 3)
		draw_string(ThemeDB.fallback_font, t.pos + Vector2(-8,5), "♣", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, purple)

	for fx in effects:
		var alpha = clamp(fx.life / 1.5, 0.0, 1.0)
		draw_circle(fx.pos, fx.radius, Color(0.55,0.15,1.0,0.04 * alpha))
		draw_arc(fx.pos, fx.radius, 0, TAU, 80, Color(0.7,0.3,1.0,alpha), 5)
		
	# [CORREGIDO] Llamamos a la función de la interfaz para que se vuelva a ver en pantalla
	draw_ui()

func draw_ui():
	if not player:
		return

	var cam_pos = player.global_position - Vector2(640, 360)

	# Panel superior izquierdo
	draw_rect(
		Rect2(cam_pos + Vector2(24, 24), Vector2(500, 92)),
		Color(0.02, 0.01, 0.04, 0.9)
	)

	draw_string(
		ThemeDB.fallback_font,
		cam_pos + Vector2(45, 52),
		"TRÉFLE  //  ALL IN",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		24,
		gold
	)

	draw_string(
		ThemeDB.fallback_font,
		cam_pos + Vector2(45, 78),
		"WASD mover  •  CLICK cartas  •  Q E C  •  X definitiva",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color("#d8c8e8")
	)

	draw_string(
		ThemeDB.fallback_font,
		cam_pos + Vector2(45, 102),
		"Puntuación: %d    Oleada: %d" % [score, wave],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		purple
	)

	# Barra de vida
	draw_rect(
		Rect2(cam_pos + Vector2(900, 38), Vector2(300, 18)),
		Color("#24152f")
	)

	draw_rect(
		Rect2(
			cam_pos + Vector2(900, 38),
			Vector2(300 * player.hp / player.max_hp, 18)
		),
		Color("#c83c72")
	)

	draw_string(
		ThemeDB.fallback_font,
		cam_pos + Vector2(900, 78),
		"HP %d / %d" % [player.hp, player.max_hp],
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.WHITE
	)

	# Barra de definitiva
	draw_rect(
		Rect2(cam_pos + Vector2(900, 100), Vector2(300, 14)),
		Color("#24152f")
	)

	draw_rect(
		Rect2(
			cam_pos + Vector2(900, 100),
			Vector2(3 * player.ultimate_charge, 14)
		),
		purple
	)

	draw_string(
		ThemeDB.fallback_font,
		cam_pos + Vector2(900, 137),
		"X  ÚLTIMA MANO  %d%%" % int(player.ultimate_charge),
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		Color("#d8c8e8")
	)
