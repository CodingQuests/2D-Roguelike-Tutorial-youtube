class_name WeaponController
extends Node2D


enum State { IDLE, WINDUP, ACTIVE, RECOVERY }

@onready var weapon_sprite: Sprite2D = $WeaponSprite
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

var state: int = State.IDLE
var _state_timer := 0.0
var _cooldown := 0.0
var _current_is_heavy := false
var _player: Node = null
const SWORD := 0
const SPEAR := 1
const DAGGERS := 2

const PROFILES := [
	{
		"name": "Corrupted Cleaver",
		"q_dmg": 20.0, "q_kb": 170.0, "q_active": 0.10, "q_cd": 0.35,
		"q_box": Vector2(46, 32), "q_off": 30.0,
		"h_dmg": 45.0, "h_kb": 290.0, "h_wind": 0.25, "h_active": 0.16, "h_cd": 0.90,
		"h_box": Vector2(64, 48), "h_off": 40.0,
	},
	{
		"name": "Cursed Pike",
		"q_dmg": 24.0, "q_kb": 160.0, "q_active": 0.10, "q_cd": 0.45,
		"q_box": Vector2(80, 18), "q_off": 48.0,
		"h_dmg": 50.0, "h_kb": 280.0, "h_wind": 0.30, "h_active": 0.16, "h_cd": 1.00,
		"h_box": Vector2(104, 24), "h_off": 60.0,
	},
	{
		"name": "Twin Fangs",
		"q_dmg": 12.0, "q_kb": 120.0, "q_active": 0.08, "q_cd": 0.18,
		"q_box": Vector2(34, 30), "q_off": 20.0,
		"h_dmg": 28.0, "h_kb": 200.0, "h_wind": 0.15, "h_active": 0.12, "h_cd": 0.60,
		"h_box": Vector2(42, 36), "h_off": 24.0,
	},
]
var available_weapons: Array = [SWORD, SPEAR]
var _slot: int = 0
func _profile() -> Dictionary:
	return PROFILES[available_weapons[_slot]]
	
func swap() -> void:
	if available_weapons.size() < 2 or state != State.IDLE:
		return
	_slot = (_slot + 1) % available_weapons.size()
func _ready() -> void:
	_player = get_parent()
	_disable_hitbox()
	attack_hitbox.source_node = _player
	
func _enable_hitbox() -> void:
	attack_hitbox.monitoring = false
	attack_hitbox.set_deferred("monitorable", true)
	hitbox_shape.set_deferred("disabled", false)
	
func _disable_hitbox() -> void:
	hitbox_shape.set_deferred("disabled", true)
	attack_hitbox.set_deferred("monitorable", false)


func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	match state:
		State.WINDUP:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_begin_active()
		State.ACTIVE:
			_state_timer -= delta
			if _state_timer <= 0.0:
				_begin_recovery()
		State.RECOVERY:
			_state_timer -= delta
			if _state_timer <= 0.0:
				state = State.IDLE
		
func try_quick_attack() -> void:
	if state != State.IDLE or _cooldown > 0.0:
		return
	_current_is_heavy = false
	_cooldown = float(_profile()["q_cd"]) * _cd_mult()
	_begin_active()



func try_heavy_attack() -> void:
	if state != State.IDLE or _cooldown > 0.0:
		return
	_current_is_heavy = true
	var p := _profile()
	_cooldown = float(p["h_cd"]) * _cd_mult()
	state = State.WINDUP
	_state_timer = float(p["h_wind"])
		
		
func _begin_active() -> void:
	state = State.ACTIVE
	var p := _profile()
	_state_timer = float(p["h_active"]) if _current_is_heavy else float(p["q_active"])

	var size: Vector2 = p["h_box"] if _current_is_heavy else p["q_box"]
	var offset: float = float(p["h_off"]) if _current_is_heavy else float(p["q_off"])
	(hitbox_shape.shape as RectangleShape2D).size = size
	hitbox_shape.position = Vector2(offset, 0)
	attack_hitbox.damage = _compute_damage()
	attack_hitbox.knockback_force = float(p["h_kb"]) if _current_is_heavy else float(p["q_kb"])
	attack_hitbox.reset_hits()
	_enable_hitbox()
	
	
func _begin_recovery() -> void:
	_disable_hitbox()
	state = State.RECOVERY
	_state_timer = 0.2


func get_move_factor() -> float:
	match state:
		State.WINDUP:
			return 0.35
		State.ACTIVE:
			return 0.6 if _current_is_heavy else 0.85
		State.RECOVERY:
			return 0.8
		_:
			return 1.0
func is_busy() -> bool:
	return state != State.IDLE
	
func _compute_damage() -> float:
	var p := _profile()
	return float(p["h_dmg"]) if _current_is_heavy else float(p["q_dmg"])
func _cd_mult() -> float:
	return 1.0
