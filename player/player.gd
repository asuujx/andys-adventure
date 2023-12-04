extends CharacterBody2D

var movement_speed = 50.0
var hp = 80

# Experience
var experience = 0
var experience_level = 1
var collected_experience = 0

# GUI
@onready var expBar = get_node("GUILayer/GUI/ExperienceBar")
@onready var lblLevel = get_node("GUILayer/GUI/ExperienceBar/lbl_level")

# Attacks
var iceSpear = preload("res://player/attack/ice_spear.tscn")

# Attack Nodes
@onready var iceSpearTimer = get_node("Attack/IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("Attack/IceSpearTimer/IceSpearAttackTimer")

# Ice Spear
var ice_spear_ammo = 0
var ice_spear_base_ammo = 1
var ice_spear_attack_speed = 1.5
var ice_spear_level = 1

# Enemy Related
var enemy_close = []

func _ready():
	attack()
	set_exp_bar(experience, calculate_experience_cap())

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

func attack():
	if ice_spear_level > 0:
		iceSpearTimer.wait_time = ice_spear_attack_speed
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP

func calculate_experience(gem_exp):
	var exp_required = calculate_experience_cap()
	collected_experience += gem_exp
	
	if experience + collected_experience >= exp_required: # level up
		collected_experience -= exp_required - experience
		experience_level += 1
		lblLevel.text = str("Level: ", experience_level)
		experience = 0
		exp_required = calculate_experience_cap()
		calculate_experience(0)
	else: 
		experience += collected_experience
		collected_experience = 0
	
	set_exp_bar(experience, exp_required)
	
func calculate_experience_cap():
	var exp_cap = experience_level
	
	if experience_level < 20:
		exp_cap = experience_level * 5
	elif experience_level < 40:
		exp_cap = 95 * (experience_level - 19) * 8
	else:
		exp_cap = 255 + (experience_level - 39) * 12
	
	return exp_cap

func set_exp_bar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= damage
	print("HP: ", hp)

func _on_ice_spear_timer_timeout():
	ice_spear_ammo += ice_spear_base_ammo
	iceSpearAttackTimer.start()

func _on_ice_spear_attack_timer_timeout():
	if ice_spear_ammo > 0:
		var ice_spear_attack = iceSpear.instantiate()
		ice_spear_attack.position = position
		ice_spear_attack.target = get_random_target()
		ice_spear_level = ice_spear_level
		add_child(ice_spear_attack)
		ice_spear_ammo -= 1
		if ice_spear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()
		

func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)

func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)
