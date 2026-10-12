# The Last Forge · Lesson 3.4: A boss with a tell

Chapter 3, Make One Room Worth Fighting In. This branch is the project at the **end of lesson 3.4** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 3.5? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-3.4.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 3.3](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.3) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 3.5 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.5)

A boss with three warned patterns, picked at random: a slam, a ring of projectiles and a charge. It keeps its distance between attacks. Below half health it enrages once, with a shake, a hit stop, a red tint and an expanding ring. After that its warnings and recoveries are shorter and its ring has 10 shots instead of 8.


## Files added
- `Scenes/BossEnemy.tscn`: duplicated from the caster scene. Tile 87 at scale 4, larger shapes, and a hitbox circle of radius 54. Its Telegraph is at scale 1.17.
- `Scripts/BossEnemy.gd` (and its `.uid`): the Pattern enum, `_choose_pattern()` with `pick_random()`, `_execute_pattern()`, `_fire_ring()`, `_enter_recovery()`, `_enraged()`, `_on_enrage()` and `set_level()`. The boss joins the `boss` group.

## Files changed
- `Scripts/EnemyBase.gd`: `hide_telegraph()` now lives in EnemyBase, shown on screen as "Telegraph reset and rectangle helper".
- `Scripts/Juice.gd`: adds `ring()` and `_circle_points()`.
- `Scenes/Projectile.tscn`: the projectile sprite gets a texture (tile 118).
- `Scenes/main.tscn`: the other enemies are deleted. Main now holds the player, the camera and the boss.

## Good to know
- With `hide_telegraph()` in EnemyBase, the brute and skitterling scripts from 3.3 load again.
- Known at this point: the slam warns at radius 80 but only hits within 22. The Inspector scale and shape tweaks don't stick, because the code sets both every time. Fixed in lesson 3.6 (`SLAM_RADIUS`).
- Known at this point: the slam and volley warnings are squares, because the boss kept the white texture from the caster and charger. Lesson 3.6 builds a round and a rectangular warning texture in code.
- Known at this point: the boss's Telegraph is saved visible, so its square shows from the first frame until its first attack. Fixed in lesson 3.6, which hides the telegraph at the end of `_ready()`.
- The boss's preload uses `res://Scenes/Projectile.tscn` with a capital S, following 3.3's correction. The video types `scenes`.
- `set_level()` isn't called yet. It's there for scaling by floor later.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=enemies

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
