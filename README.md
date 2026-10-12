# The Last Forge · Lesson 3.1: One enemy, off one script

Chapter 3, Make One Room Worth Fighting In. This branch is the project at the **end of lesson 3.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 3.2? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-3.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 2.5](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.5) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 3.2 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.2)

The first monster. EnemyBase is a scene and a script that every enemy builds on, and the grunt is the first enemy made from it. It finds you, chases you, swings when you're close, and then needs a moment to recover.


## Files added
- `Scenes/EnemyBase.tscn`: a duplicate of the dummy. The root `EnemyBase` is in the `enemy` group. It has Sprite2D, CollisionShape2D, Health, HurtboxComponent (layer 5, mask 6) and HitboxComponent (layer 7, no mask, sword sprite removed), plus a hidden, empty `Telegraph` Sprite2D. Its three collision shapes are cleared so each enemy can give its own.
- `Scripts/EnemyBase.gd` (and its `.uid`): `class_name EnemyBase` with the State enum, exported stats, node references and the `defeated` signal. `_ready()` calls our own `_on_ready()` hook, and `_physics_process()` calls `_ai_process()`. It finds the player through the `player` group, faces it and applies knockback. Also has `apply_knockback()`, `die()`, `player_pos()`, `has_player()`, `dir_to_player()`, `distance_to_player()`, `enable_attack_area()` and `_disable_attack_area()`.
- `Scenes/GruntEnemy.tscn`: a new inherited scene of EnemyBase, using tile 108 and its own circle shapes.
- `Scripts/GruntEnemy.gd` (and its `.uid`): `class_name GruntEnemy extends EnemyBase`. Its `_on_ready()` sets health 50, speed 95, damage 12 and knockback 200. The loop is chase, then attack when in range, then recovery and a cooldown.

## Files changed
- `Scenes/player.tscn`: the Player root is in the `player` group.
- `Scenes/main.tscn`: the dummy and the hazard are gone and the grunt is in. The player node is now called `player`.

## Good to know
- Known at this point: knockback stacks on top of the grunt's own velocity, so a hit can send it flying (the video points this out at the end). Lesson 3.3 adds hitstun.
- `_ready()` calls `_on_ready()` second, before the health and hitbox values are copied, as the video shows from 12:52.
- `dummy.tscn` and `Hazard.tscn` stay in the project. They're just no longer in `main.tscn`.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=enemies

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
