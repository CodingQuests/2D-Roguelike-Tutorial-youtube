# The Last Forge · Lesson 6.1: A HUD that shows less

Chapter 6, Make Them Want Another Run. This branch is the project at the **end of lesson 6.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 6.2? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-6.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 5.5](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.5) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 6.2 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-6.2)

A checkpoint first: a floor change that leaves nothing behind, no rewards for a dead player, the caster's own corrupted bonus and the grunt's final numbers. Then the screen pulses red when your health drops below 30 percent, faster the closer you are to dying.


## Files added
- None

## Files changed
- `Scripts/RoomController.gd`: `_ready()` no longer generates the floor a second time after `_enter_floor(1)`; new `_clear_floor_container()`, which disconnects `defeated` and removes every child of a container; `_enter_floor()` clears Enemies, Projectiles and Pickups, then calls `player.reset_floor_motion()`; `_on_enemy_defeated()` returns early when no fight is running or the player is dead
- `Scripts/PlayerController.gd`: `reset_floor_motion()` stops the dash, phase step, velocity and knockback, resets the safe position and clears the dash tint
- `Scripts/GruntEnemy.gd`: `attack_range` 16 and a smaller hit, `enable_attack_area(dir * 6.0, 7.0)`, the numbers in the grunt code the video shows
- `Scenes/GruntEnemy.tscn`: the grunt scene's own Attack Range is 16 as well (it stored 45, which would override the script)
- `Scripts/CasterEnemy.gd`: `make_corrupted()` calls `super.make_corrupted()` and then raises `projectile_damage`
- `Scripts/UpgradeManager.gd`: `var p: Node = GameManager.player` in `_owned_unique_ids()`
- `Scenes/HUD.tscn`: new `OverloadPulse` ColorRect (Full Rect, alpha 0, Mouse Filter Ignore)
- `Scripts/HUD.gd`: `overload_pulse`, `_time`, `_game_over`, `_leaving`; `_process()` returns while paused (or after game over or while leaving), finds the player again if needed, updates the bars and labels, then drives the red pulse

## Good to know
- The video starts by giving five scene paths a capital S (in `RoomController.gd`, `HUD.gd` and `WeaponController.gd`). Yours already use `res://Scenes/`, as the correction in lesson 3.3 asked, so skip that step.
- The video then swaps the code of `GruntEnemy.gd` and `CasterEnemy.gd` and points `CasterEnemy.tscn` at `CasterEnemy.gd`. You did that in lesson 3.3 and checked it in 3.6 (card 05), so skip the swap. Do take the grunt's two numbers from the code on screen (range 16, `enable_attack_area(dir * 6.0, 7.0)`), and set Attack Range to 16 on the root of `GruntEnemy.tscn` in the Inspector too.
- The caption that adds `_base_sprite_scale = sprite.scale` to `EnemyBase._ready()`: you already did it in 3.6 (card 08), so skip that step. One copy is enough.
- `_game_over` and `_leaving` stay false in this lesson. Lesson 6.2 switches them on.
- The repairs to the whirlwind size, the chain skipping dead enemies and chill reading the AI's own velocity are already in from lesson 5.4, and the boss in the farthest room from lesson 4.3.
- On the very first import Godot may print `Cannot infer the type of "p" variable` for `UpgradeManager.gd` (`_player_corruption()` still uses `var p := GameManager.player`). Opening the project a second time is clean, and the game runs.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=hud

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
