extends CharacterBody2D

@export var movement_speed = 20.0
@export var hp = 10

@onready var player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * movement_speed
	
	if velocity.length() > 0:
		$AnimatedSprite2D.play("run")
		
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	move_and_slide()


func _on_hurt_box_hurt(damage):
	hp -= damage
	
	if hp <= 0:
		queue_free()