class_name Atmosphere
extends CanvasModulate
## The room's ambient light — the colour everything falls back to where no
## PointLight2D reaches. Lives on the CombatRoom so it darkens the dungeon
## without touching the HUD (which is on its own CanvasLayer).
##
## This is where the lighting stops being decoration and starts being design:
##   - the ambient sours toward corruption purple as the player's corruption
##     climbs, so the room itself gets sicker as you get stronger;
##   - each room type has its own tint, so you can tell a shop from an altar
##     from the doorway, before reading a word of UI.
##
## Both blends are eased, so walking into a new room is a slow wash rather than
## a cut.

## Neutral dungeon: cool, dark, desaturated so warm torches have headroom.
const BASE := Color(0.38, 0.37, 0.52)
## Where BASE lands at 100% corruption.
const CORRUPTED := Color(0.34, 0.20, 0.44)

## Per-room-type multiplier over the corruption-blended base. Indexed by
## Dungeon.RoomType.
const ROOM_TINT := {
	0: Color(1.00, 1.00, 1.00),  # ENTRANCE — neutral
	1: Color(1.00, 1.00, 1.00),  # COMBAT   — neutral
	2: Color(1.14, 1.04, 0.80),  # TREASURE — warm gold
	3: Color(1.10, 0.80, 0.78),  # BOSS     — hot, red-shifted
	4: Color(1.10, 1.00, 0.86),  # SHOP     — candle-lit
	5: Color(0.86, 0.80, 1.16),  # ALTAR    — cold violet
}

@export var blend_speed: float = 2.2

var _player: Node = null
var _room_tint := Color.WHITE
var _target := BASE


func _ready() -> void:
	color = BASE
	_target = BASE


## Called by RoomController whenever the player enters a room.
func set_room_type(type: int) -> void:
	_room_tint = ROOM_TINT.get(type, Color.WHITE)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	var corrupt_t := 0.0
	if _player and is_instance_valid(_player):
		var maximum: float = maxf(1.0, _player.max_corruption)
		corrupt_t = clampf(_player.corruption / maximum, 0.0, 1.0)

	var base := BASE.lerp(CORRUPTED, corrupt_t)
	_target = Color(
		base.r * _room_tint.r,
		base.g * _room_tint.g,
		base.b * _room_tint.b)
	color = color.lerp(_target, 1.0 - exp(-blend_speed * delta))
