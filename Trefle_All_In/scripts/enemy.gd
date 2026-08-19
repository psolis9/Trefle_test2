class_name TrefleEnemy
extends Node2D

var hp := 40.0
var speed := 105.0
var target: Node2D
var slow_timer := 0.0
var stun_timer := 0.0
var marked := 0
var hit_flash := 0.0

func setup(p):
    target = p
    queue_redraw()

func _process(delta):
    if not is_instance_valid(target):
        return
    slow_timer = max(0.0, slow_timer - delta)
    stun_timer = max(0.0, stun_timer - delta)
    hit_flash = max(0.0, hit_flash - delta)

    if stun_timer <= 0.0:
        var d = global_position.direction_to(target.global_position)
        var s = speed * (0.45 if slow_timer > 0 else 1.0)
        global_position += d * s * delta

    if global_position.distance_to(target.global_position) < 38:
        target.take_damage(8)
        global_position -= global_position.direction_to(target.global_position) * 45.0

    queue_redraw()

func hit(damage, effect="normal"):
    hp -= damage
    hit_flash = 0.1
    if effect == "slow":
        slow_timer = 2.0
    elif effect == "stun":
        stun_timer = 1.1
    if hp <= 0:
        queue_free()

func _draw():
    var body_color = Color("#ff3b73") if hit_flash <= 0 else Color.WHITE
    draw_circle(Vector2.ZERO, 22, Color(0.08,0.03,0.10,0.9))
    draw_circle(Vector2.ZERO, 18, body_color)
    draw_circle(Vector2(-7,-4), 3, Color("#120719"))
    draw_circle(Vector2(7,-4), 3, Color("#120719"))
    draw_line(Vector2(-10,8), Vector2(10,8), Color("#120719"), 3)
    draw_arc(Vector2.ZERO, 28, 0, TAU, 32, Color("#8d46d9"), 2)
