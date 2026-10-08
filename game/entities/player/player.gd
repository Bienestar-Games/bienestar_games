class_name Player
extends BaseCharacter
@onready var f_arm_2 = %f_arm_2
@onready var b_arm_2 = %b_arm_2
@onready var player_sprite = $Body
@onready var aim_pivot = %WeaponPivot
@onready var hand = $Body/UpperBody/f_arm_2/Hand
#@onready var head = %Head

func aim(pos: Vector2):
	flip_player_sprite(pos.x < self.global_position.x)
	if (pos.x < self.global_position.x):
		f_arm_2.rotation = lerp_angle(f_arm_2.rotation, - (aim_pivot.global_position - pos).angle(), (0.10))
	else:
		f_arm_2.rotation = lerp_angle(f_arm_2.rotation, (pos - aim_pivot.global_position).angle(), (0.10))
	b_arm_2.look_at(hand.global_position)
	#head.look_at(pos)
	

func _player_input():
	move_direction.x = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
	move_direction.y = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))	

func handle_animation(state: String):
	
	match state:
		"moving":
			animation_tree["parameters/conditions/idle"] = false
			animation_tree["parameters/conditions/moving"] = true
			animation_tree["parameters/Moving/blend_position"] = move_direction.normalized()
		"idle":
			animation_tree["parameters/conditions/moving"] = false
			animation_tree["parameters/conditions/idle"] = true
			animation_tree["parameters/Moving/blend_position"] = Vector2.ZERO
	
