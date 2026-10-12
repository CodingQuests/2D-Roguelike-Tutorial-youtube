# The Last Forge · Lesson 4.2: Why random rooms are boring

Chapter 4, Turn It Into a Run. This branch is the project at the **end of lesson 4.2** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 4.3? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-4.2.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 4.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 4.3 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.3)

The room is decorated by rules instead of at random. Each room gets 3 to 6 props, never on the cross through the middle and never closer than 24 px to another prop. The first two are boulders (a sprite and a collision box); the rest are destructible barrels that one sword swing breaks. Two braziers with a small flame sit on the top wall. A flood fill then checks that every floor cell can still be reached and clears the decoration if one can't.


## Files added
- `Scenes/DestructibleProp.tscn`: a StaticBody2D with Sprite2D (`tile_0082`), CollisionShape2D (14 x 16), Health (HealthComponent) and Hurtbox (HurtboxComponent with its own 16 x 19 shape). The Hurtbox is on collision layer 5 (EnemyHurtbox) with mask 6 (PlayerHitbox).
- `Scripts/DestructibleProp.gd` (and its `.uid`): `class_name DestructibleProp`. It has 1 HP, and `_break()` plays an impact and the `enemy_death` sound before freeing the barrel.

## Files changed
- `Scripts/Dungeon.gd`:
  - New constants and containers: `BOULDER_TEX`, `BRAZIER_TEX`, `PROP_SCENE`, the `_decor` / `_props` / `_gates` containers and `obstacles`.
  - `_free_helpers()` replaces 4.1's inline wall teardown in `generate()`.
  - New functions: `_decorate_random()` (the first naive scatter), `_decorate_room()`, `_add_static_box()`, `_place_boulder()`, `_place_prop()`, `_place_brazier()`, `_cell_center()`, `_placement_blocked()`, `obstacles_at()`, `_walkable_count()` and `_all_floor_reachable()`.
  - `generate()` now decorates the room, then runs the reachability check.

## Good to know
- The barrel's Hurtbox layer 5 / mask 6 is the correction the course adds right after the barrel is built. The video leaves it on the default layer 1 / mask 1, and the sword then can't break it.
- `_decorate_random()` stays in the file, but nothing calls it any more.
- If the reachability check fails, you get the warning "Decoration blocked the floor — clearing props." and a bare room. That's on purpose.
- The video types `PROP_SCENE` as `res://scenes/DestructibleProp.tscn` with a small s. This branch uses `res://Scenes/DestructibleProp.tscn`, because the correction in lesson 3.3 asks you to match the capitals in every preload from then on (the folder is `Scenes`; a small s works on Windows but fails on Linux and in exported games). Lesson 4.3 opens with the video's line corrected to the same thing.
- Known at this point: Floor is still the last child of CombatRoom, so boulders, barrels and braziers draw on top of the knight when he walks into them. Lesson 4.3 moves Floor to the top of the scene.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=dungeon

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
