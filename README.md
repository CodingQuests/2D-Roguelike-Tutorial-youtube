# The Last Forge · Lesson 4.4: Knowing where you are

Chapter 4, Turn It Into a Run. This branch is the project at the **end of lesson 4.4** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 5.1? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-4.4.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 4.3](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.3) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 5.1 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.1)

Walking into a fight or boss room now starts it: gates close every doorway of that room and its monsters spawn inside it. Clearing the room opens the gates, marks it cleared and counts it in `run_stats`. After the boss, the game waits 1.5 s and takes you down to a deeper floor with one more room. A minimap in the HUD draws the floor's rooms and links, colours rooms by type, dims cleared fights and pulses the room you're in.


## Files added
- `Scripts/Minimap.gd` (and its `.uid`): `set_dungeon()`, `_room_center_tiles()`, a `_process()` that animates the pulse, `_draw()` (fits the floor's bounds into the control with one scale, draws links as lines and rooms as boxes, outlines the current room), and `_colour_for()`.

## Files changed
- `Scripts/Dungeon.gd`: `_gate_nodes`, `lock_room()` (one gate body per recorded door cell) and `unlock_room()`.
- `Scripts/RoomController.gd`:
  - New: `BOSS_SCENE`, and the `_current_room`, `_active_room`, `_floor_depth` and `_busy` variables.
  - `_ready()` calls `_enter_floor(1)`.
  - `_physics_process()` tracks which room you're in, counting it only once you're 16 px inside.
  - `_on_enter_room()` hands off to `_start_combat()` or `_start_boss()`.
  - `_spawn(scene, room_index)` spawns inside the room. A new `_clear_active_room()` and `_enter_floor()` are added.
  - `_start_wave()`, the old `_spawn()` and `_random_spawn_point()` are deleted.
- `Scripts/GameManager.gd`: `DEFAULT_RUN_STATS`, and `run_stats` as a duplicate of it.
- `Scenes/HUD.tscn`: the root is renamed HUD. A new `Minimap` Control (bottom right, 135 x 114, in the group "Minimap") runs `Minimap.gd`.
- `Scenes/CombatRoom.tscn`: the HUD instance is renamed HUD.

## Good to know
- `_ready()` still has `floor_layer.generate()` and the player-position line after `_enter_floor(1)`, as in the video. The first floor is generated twice at start, which is harmless; lesson 6.1 removes those two lines.
- `run_stats` already has slots for gold, essence, score and combo; chapters 5 and 6 fill them.
- The gates call `AudioManager.play("door_close")` and `("door_open")`, but those sounds only exist from lesson 5.1. Until then AudioManager ignores the names. Clearing a room also has no sound until 5.1.
- Monsters, projectiles and pickups from the old floor aren't cleaned up when you go down to the next floor; that comes in 6.1.
- The video shows `_assign_types()` with the old "last room is the boss" line for a moment, because it was recorded before the fix. This branch keeps 4.3's fixed version.
- The video types `BOSS_SCENE` as `res://scenes/BossEnemy.tscn` with a small s. This branch uses `res://Scenes/BossEnemy.tscn`, as the correction in lesson 3.3 asks (match the capitals in every preload). Lesson 5.1 corrects the video's line to the same thing.
- The minimap is small; the video suggests making it bigger as an exercise.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=dungeon

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
