# The Last Forge · Lesson 3.3: Four enemies from the same base

Chapter 3, Make One Room Worth Fighting In. This branch is the project at the **end of lesson 3.3** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 3.4? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-3.3.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 3.2](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.2) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 3.4 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.4)

Four more enemies on the same base. The charger locks its direction and charges, and the caster keeps its distance and fires projectiles. The walkthrough adds the brute and the skitterling. Hits now cause a short hitstun scaled by the knockback.


## Files added
- `Scenes/ChargerEnemy.tscn`, `Scripts/ChargerEnemy.gd` (and its `.uid`): a new inherited scene with tile 110. The windup locks `_charge_dir` and shows a rectangle warning, then it charges at 360 for 0.45 s and recovers. Its Telegraph texture was made unique, then reset to plain white.
- `Scenes/CasterEnemy.tscn`, `Scripts/CasterEnemy.gd` (and its `.uid`): the charger scene duplicated, with tile 84. `_kite()` keeps the caster about 180 px away. It shows an aim line, then `_fire()` spawns a projectile.
- `Scenes/Projectile.tscn`, `Scripts/Projectile.gd` (and its `.uid`): an Area2D on layer 7 with no mask, added to the `hitbox` group in code. It moves by position, dies after its lifetime, and pops when it hits a body or a hurtbox.
- `Scenes/BruteEnemy.tscn`, `Scripts/BruteEnemy.gd`, `Scenes/SkitterlingEnemy.tscn`, `Scripts/SkitterlingEnemy.gd` (and their `.uid` files): the brute and skitterling from the walkthrough, with this lesson's numbers (range 55 and 28).

## Files changed
- `Scripts/EnemyBase.gd`: adds `_hitstun`. `apply_knockback()` now ignores a non-finite direction and sets a stun scaled by the force (0.08 to 0.22 s), and `_physics_process()` holds the enemy still while stunned. Adds `show_telegraph_rect()`.
- `Scripts/HurtboxComponent.gd`: tells the hitting area about the hit (`on_hurtbox_hit()`), so projectiles pop.
- `Scenes/main.tscn`: the grunt has moved. The charger, caster, brute and two skitterlings are added.

## Good to know
- In the recording, the caster's code is typed into `GruntEnemy.gd`, so the grunts on screen stop and shoot until lesson 3.6. This branch follows the correction in the lesson: the caster's code is in `CasterEnemy.gd` (`class_name CasterEnemy`), `CasterEnemy.tscn` uses that script, and `GruntEnemy.gd` stays the grunt.
- The projectile preload uses `res://Scenes/Projectile.tscn` with a capital S, as the correction in the lesson says. The video types `scenes`.
- Known at this point: `BruteEnemy.gd` and `SkitterlingEnemy.gd` call `hide_telegraph()`, but EnemyBase doesn't have it yet (the grunt, charger and caster each define their own). Godot reports `Function "hide_telegraph()" not found in base self` and the brute and skitterlings stand still. Fixed in lesson 3.4, which moves `hide_telegraph()` into EnemyBase.
- Known at this point: the charger's warning covers only 70% of its charge. Fixed in lesson 3.6.
- The caster, brute and skitterlings were placed in `main.tscn` off camera, so their positions are measured from the video and are approximate.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=enemies

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
