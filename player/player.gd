extends CharacterBody2D

var movement_speed = 50.0
var hp = 80

func _physics_process(delta):
	movement()
	
func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov, y_mov)
	
	velocity = mov.normalized() * movement_speed
	
	if velocity.length() > 0:
		$AnimatedSprite2D.play("walk")
		
		if Input.is_action_pressed("left"):
			$AnimatedSprite2D.flip_h = true
		elif Input.is_action_pressed("right"):
			$AnimatedSprite2D.flip_h = false
	elif velocity.length() == 0:
		$AnimatedSprite2D.play("idle")
	
	
	move_and_slide()


func _on_hurt_box_hurt(damage):
	hp -= damage
	print("HP: ", hp)
