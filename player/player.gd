extends CharacterBody2D

var movement_speed = 50.0
var hp = 80
var last_movement = Vector2.UP

# Experience
var experience = 0
var experience_level = 1
var collected_experience = 0

# GUI
@onready var expBar = get_node("GUILayer/GUI/ExperienceBar")
@onready var lblLevel = get_node("GUILayer/GUI/ExperienceBar/lbl_level")
@onready var levelPanel = get_node("GUILayer/GUI/LevelUp")
@onready var upgradeOptions = get_node("GUILayer/GUI/LevelUp/UpgradeOptions")
@onready var itemOptions = preload("res://utility/item_option.tscn")

# Attacks
var iceSpear = preload("res://player/attack/ice_spear.tscn")
var tornado = preload("res://player/attack/tornado.tscn")
var javelin = preload("res://player/attack/javelin.tscn")

# Attack Nodes
@onready var iceSpearTimer = get_node("Attack/IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("Attack/IceSpearTimer/IceSpearAttackTimer")
@onready var tornadoTimer = get_node("Attack/TornadoTimer")
@onready var tornadoAttackTimer = get_node("Attack/TornadoTimer/TornadoAttackTimer")
@onready var javelinBase = get_node("Attack/JavelinBase")

# Upgrades
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

# Ice Spear
var ice_spear_ammo = 0
var ice_spear_base_ammo = 0
var ice_spear_attack_speed = 1.5
var ice_spear_level = 0

# Tornado
var tornado_ammo = 0
var tornado_base_ammo = 0
var tornado_attack_speed = 3
var tornado_level = 0

# Javelin
var javelin_ammo = 0
var javelin_level = 0

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
		last_movement = mov
		
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
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attack_speed
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()

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
		experience = 0
		exp_required = calculate_experience_cap()
		level_up()
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
	
func level_up():
	lblLevel.text = str("Level: ", experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel, "position", Vector2(220, 50), 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	
	var options = 0
	var options_max = 3
	while options < options_max: 
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	
	get_tree().paused = true
	
func upgrade_character(upgrade):
	var option_children = upgradeOptions.get_children()
	
	for i in option_children:
		i.queue_free()
		
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800, 50)
	get_tree().paused = false
	calculate_experience(0)

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
		
func _on_tornado_timer_timeout():
	tornado_ammo += tornado_base_ammo
	tornadoAttackTimer.start()
	
func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_level = tornado_level
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()
		
func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()
	var calc_spawns = javelin_ammo - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1

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

func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Don't pick food 
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: #Check for prerequisite
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					pass
				else:
					dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var random_item = dblist.pick_random()
		upgrade_options.append(random_item)
		return random_item
	else:
		return null
