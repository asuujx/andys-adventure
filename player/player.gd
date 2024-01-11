extends CharacterBody2D

var movement_speed = 50.0
var hp = 80
var max_hp = 80
var last_movement = Vector2.UP
var time = 0

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
@onready var healthBar = get_node("GUILayer/GUI/HealthBar")
@onready var lblTimer = get_node("GUILayer/GUI/lblTimer")
@onready var collectedWeapons = get_node("GUILayer/GUI/CollectedWeapons")
@onready var collectedUpgrades = get_node("GUILayer/GUI/CollectedUpgrades")
@onready var itemContainer = preload("res://player/GUI/item_container.tscn")

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
	upgrade_character("icespear1")
	attack()
	set_exp_bar(experience, calculate_experience_cap())
	_on_hurt_box_hurt(0, 0, 0)

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
		iceSpearTimer.wait_time = ice_spear_attack_speed * (1 - spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attack_speed * (1 - spell_cooldown)
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
	match upgrade:
		"icespear1":
			ice_spear_level = 1
			ice_spear_base_ammo += 1
		"icespear2":
			ice_spear_level = 2
			ice_spear_base_ammo += 1
		"icespear3":
			ice_spear_level = 3
		"icespear4":
			ice_spear_level = 4
			ice_spear_base_ammo += 2
		"tornado1":
			tornado_level = 1
			tornado_base_ammo += 1
		"tornado2":
			tornado_level = 2
			tornado_base_ammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attack_speed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_base_ammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"armor1", "armor2", "armor3", "armor4":
			armor += 1
		"speed1", "speed2", "speed3", "speed4":
			movement_speed += 20.0
		"tome1", "tome2", "tome3", "tome4":
			spell_size += 0.10
		"scroll1", "scroll2", "scroll3", "scroll4":
			spell_cooldown += 0.05
		"ring1", "ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp, 0, max_hp)
			
	adjust_gui_collection(upgrade)
	attack()
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
	hp -= clamp(damage - armor, 1.0, 999.0)
	healthBar.max_value = max_hp
	healthBar.value = hp
	print("HP: ", hp)

func _on_ice_spear_timer_timeout():
	ice_spear_ammo += ice_spear_base_ammo + additional_attacks
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
	tornado_ammo += tornado_base_ammo + additional_attacks
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
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1
	
	#update javeling
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("updade_javelin"):
			i.update_javelin()

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
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
			if to_add:
				dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var random_item = dblist.pick_random()
		upgrade_options.append(random_item)
		return random_item
	else:
		return null
		
func change_time(argtime = 0):
	time = argtime
	var get_m = int(time / 60.0)
	var get_s = time % 60
	
	if get_m < 10:
		get_m = str(0, get_m)
	if get_s < 10:
		get_s = str(0, get_s)
	lblTimer.text = str(get_m, ":", get_s)
	
func adjust_gui_collection(upgrade):
	var get_upgraded_display_names = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "type":
		var get_collected_display_names = []
		for i in collected_upgrades:
			get_collected_display_names.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_display_names in get_collected_display_names:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)
