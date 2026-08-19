class_name TreflePlayer
extends CharacterBody2D

signal shoot_card(position, direction)
signal ability_used(name, position, direction)
signal ultimate_used()

var speed := 360.0
var max_hp := 100
var hp := 100
var fire_cooldown := 0.0
var q_cooldown := 0.0
var e_cooldown := 0.0
var c_cooldown := 0.0
var ultimate_charge := 0.0
var marks := 0
var invulnerable := 0.0

# Variable para guardar hacia dónde mira el personaje
var look_angle := 0.0

func _ready():
	queue_redraw()

func _physics_process(delta):
	# 1. MOVIMIENTO
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed
	move_and_slide()

	# Limitar al jugador dentro de la arena
	position.x = clamp(position.x, 40.0, 2360.0)
	position.y = clamp(position.y, 40.0, 1360.0)

	# 2. ACTUALIZAR TIEMPOS
	fire_cooldown = max(0.0, fire_cooldown - delta)
	q_cooldown = max(0.0, q_cooldown - delta)
	e_cooldown = max(0.0, e_cooldown - delta)
	c_cooldown = max(0.0, c_cooldown - delta)
	invulnerable = max(0.0, invulnerable - delta)

	# 3. APUNTADO
	var mouse = get_global_mouse_position()
	var dir = (mouse - global_position).normalized()
	
	# En lugar de rotar todo el nodo (que rotaría la sombra), 
	# guardamos el ángulo + PI/2 (90 grados) porque dibujaste al personaje mirando hacia arriba (-Y)
	look_angle = dir.angle() + (PI / 2.0)

	# 4. ENTRADAS DE ACCIÓN
	if Input.is_action_pressed("shoot") and fire_cooldown <= 0.0:
		shoot_card.emit(global_position + dir * 34.0, dir)
		fire_cooldown = 0.20

	if Input.is_action_just_pressed("ability_q") and q_cooldown <= 0.0:
		ability_used.emit("Q", global_position + dir * 45.0, dir)
		q_cooldown = 4.0

	if Input.is_action_just_pressed("ability_e") and e_cooldown <= 0.0:
		ability_used.emit("E", global_position + dir * 110.0, dir)
		e_cooldown = 8.0

	if Input.is_action_just_pressed("ability_c") and c_cooldown <= 0.0:
		ability_used.emit("C", global_position + dir * 150.0, dir)
		c_cooldown = 7.0

	if Input.is_action_just_pressed("ultimate") and ultimate_charge >= 100.0:
		ultimate_charge = 0.0
		ultimate_used.emit()

	# Redibujar cada frame para actualizar la rotación y el efecto de invulnerabilidad
	queue_redraw()

func take_damage(amount):
	if invulnerable > 0.0:
		return
	
	hp -= amount
	invulnerable = 0.15 # Tiempo de inmunidad y parpadeo
	
	if hp <= 0:
		hp = max_hp
		position = Vector2(1200, 700)
		ultimate_charge = 0.0 # Castigo por morir (opcional)

func add_ultimate(amount):
	ultimate_charge = clamp(ultimate_charge + amount, 0.0, 100.0)

func _draw():
	# Efecto visual de daño (parpadeo)
	if invulnerable > 0.0:
		modulate.a = 0.5 # Semi-transparente
	else:
		modulate.a = 1.0 # Opaco normal

# 1. Sombra (Se dibuja PRIMERO y SIN rotación, para que se quede en el piso)
	# Godot pide: (Centro, Radio_X, Radio_Y, Color)
	draw_ellipse(Vector2(0, 18), 25.0, 10.0, Color(0.02, 0.01, 0.04, 0.6))

	# Abrigo
	var coat = PackedVector2Array([
		Vector2(-20, -10), Vector2(-32, 35), Vector2(-16, 60),
		Vector2(0, 38), Vector2(16, 60), Vector2(32, 35), Vector2(20, -10)
	])
	draw_colored_polygon(coat, Color("#15121f"))
	draw_polyline(coat + PackedVector2Array([coat[0]]), Color("#8d46d9"), 3.0)
	
	# Cabeza
	draw_circle(Vector2(0, -31), 15, Color("#d49a7d"))
	
	# Sombrero
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22,-43), Vector2(22,-43), Vector2(13,-58), Vector2(-13,-58)
	]), Color("#0b0a10"))
	draw_line(Vector2(-24,-43), Vector2(24,-43), Color("#c08a36"), 4)
	
	# Carta en mano
	var card = PackedVector2Array([Vector2(18,-8),Vector2(34,-2),Vector2(29,22),Vector2(13,16)])
	draw_colored_polygon(card, Color("#eee8ff"))
	draw_polyline(card + PackedVector2Array([card[0]]), Color("#a85cff"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(18, 10), "♣", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#7b35d4"))

	# Restaurar la rotación del lienzo
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
