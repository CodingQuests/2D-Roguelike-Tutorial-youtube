# The Last Forge · Lesson 3.5: The room knows the fight is over

Chapter 3, Make One Room Worth Fighting In. This branch is the project at the **end of lesson 3.5** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 3.6? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-3.5.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 3.4](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.4) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 3.6 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.6)

A combat room that spawns a wave away from the player and counts the enemies. At depth 1 that's three grunts, a caster, a charger and two skitterlings. Each enemy fades in with a ring. The last kill slows time and asks the HUD to show ROOM CLEARED. The HUD scene with a health bar, a dash bar and a status label is in.


## Files added
- `Scenes/CombatRoom.tscn`: duplicated from main. It has an `Enemies` container, `Projectiles` (group `projectiles`) and `Pickups` (group `pickups`), plus the HUD instance, and the root runs `RoomController.gd`.
- `Scripts/RoomController.gd` (and its `.uid`): preloads the five enemy scenes and builds the wave list by depth. `_random_spawn_point()` tries 12 times for a spot at least 120 px from the player, then falls back to the farthest corner. It tracks the alive count. `_clear_active_room()` runs slow-mo, the status text and the `room_clear` sound.
- `Scenes/HUD.tscn`: a CanvasLayer with HealthBar, DashBar and StatusLabel.
- `Scripts/HUD.gd` (and its `.uid`): registers with GameManager, reads the player's health and dash every frame, and has `show_status()`.
- `Scripts/StatBar.gd` (and its `.uid`): a bar drawn in `_draw()` with a delayed "ghost" behind it.

## Files changed
- `Scripts/EnemyBase.gd`: adds `spawn_in()` (ring, particles, then a scale and fade tween), `_spawning`, `_base_sprite_scale`, and a spawning guard in `_physics_process()`.
- `Scripts/GameManager.gd`: adds `hud`, `player`, `register_hud()`, `register_player()` and `slow_mo()`.
- `Scripts/PlayerController.gd`: calls `GameManager.register_player(self)` in `_ready()`.

## Good to know
- Run `CombatRoom.tscn` with F6 (Run Current Scene). `main.tscn` (the boss arena) is still the main scene.
- `RoomController.gd` uses `$player` (lowercase) to match the node in CombatRoom, fixed in the silent pickup near the end. Its preloads use `res://Scenes/` with a capital S, following 3.3's correction.
- Known at this point: `HUD.gd` isn't attached to `HUD.tscn`, so the bars don't follow the player and ROOM CLEARED never appears. `room_clear` has no sound in AudioManager. `_base_sprite_scale` is never set, so `spawn_in()` grows every sprite back to scale 1. Lesson 3.6 fixes all three (cards 04, 10 and 08), along with 3.4's open items (the boss's square warnings, the 80/22 slam and the warning visible at start).

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=rooms

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
