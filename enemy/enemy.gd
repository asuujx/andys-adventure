extends CharacterBody2D

@export var movement_speed = 20.0
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1

var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")

var death_anim = preload("res://enemy/enemy_death.tscn")
var exp_flower = preload("res://objects/experience_flower.tscn")

signal remove_from_array(object)

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * movement_speed
	velocity += knockback
	
	if velocity.length() > 0:
		$AnimatedSprite2D.play("run")
		
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	move_and_slide()

func death():
	# Enemy dies
	emit_signal("remove_from_array", self)
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = $AnimatedSprite2D.scale
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child", enemy_death)
	
	# Experience flower appears
	var new_flower = exp_flower.instantiate()
	new_flower.global_position = global_position
	new_flower.experience = experience
	loot_base.call_deferred("add_child", new_flower)
	
	queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	
	if hp <= 0:
		death()
