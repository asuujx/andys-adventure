extends Area2D


@export var experience = 1

var spr_yellow = preload("res://assets/textures/objects/yellow_flower.png")
var spr_red = preload("res://assets/textures/objects/red_flower.png")
var spr_blue = preload("res://assets/textures/objects/blue_flower.png")

var target = null
var speed = -1

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

func _ready():
	if experience < 5:
		return
	elif experience < 25:
		sprite.texture = spr_red
	else:
		sprite.texture = spr_blue

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2 * delta
		
func collect():
	collision.call_deferred("set", "disable", true)
	# sprite.visible = false
	queue_free()
	return experience
