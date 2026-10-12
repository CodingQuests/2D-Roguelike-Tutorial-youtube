# The Last Forge · Lesson 2.2: Who checks whom

Chapter 2, Make Hitting Something Feel Good. This branch is the project at the **end of lesson 2.2** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 2.3? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-2.2.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 2.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 2.3 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.3)

The sword carries a hitbox, and the player and the dummy have hurtboxes. When a hurtbox touches a hitbox, it checks that the hitbox is really a hitbox, asks it whether this swing already hit, takes the damage through its parent's Health and shoves its parent away. Named collision layers keep the player's own sword off the player. The dummy holds a small sword with an enemy hitbox that can hurt the player, and both the player and the dummy get knocked back.


## Files added
- `Scripts/HitboxComponent.gd` (and its `.uid`): `class_name HitboxComponent`, `extends Area2D`; `damage` (10), `knockback_force` (200), `source_node`; joins the `"hitbox"` group in `_ready()`; `hit_once_per_attack`, the hit list `_hit_this_attack`, `reset_hits()`, `try_register_hit()` and the `hit_landed` signal
- `Scripts/HurtboxComponent.gd` (and its `.uid`): `class_name HurtboxComponent`, `extends Area2D`; `hurt` signal, `damage_multiplier`, `invulnerable`; finds its parent and the parent's `Health`; on `area_entered` it returns if invulnerable or if the area isn't in the `"hitbox"` group, asks `try_register_hit(self)`, damages the Health, emits `hurt` and calls the parent's `apply_knockback()` (random direction if the two are on top of each other)

## Files changed
- `project.godot`: 2D physics layer names: 1 World, 2 PlayerBody, 3 EnemyBody, 4 PlayerHurtbox, 5 EnemyHurtbox, 6 PlayerHitbox, 7 EnemyHitbox / projectiles, 8 Pickups
- `Scenes/player.tscn`: a `Hurtbox` (layer 4, mask 7) with a 12 x 15 rectangle; a `HitboxComponent` under WeaponPivot (layer 6, no mask) with a 15 x 13 rectangle at (16, 0); a `Health` node
- `Scripts/PlayerController.gd`: `hurtbox` @onready; the dash turns `hurtbox.invulnerable` on and off (the player's own `invulnerable` is still there too); `KNOCKBACK_DECAY` 1700 and `KNOCKBACK_TAKEN` 0.6, `_knockback` added to the walking velocity and shrunk toward zero every frame; `apply_knockback()`
- `Scenes/dummy.tscn`: a `HurtboxComponent` (layer 5, mask 6) with a capsule; a `HitboxComponent` (layer 7, no mask) holding a sword sprite; and knockback from the Your Turn at the end: the player's two constants, `_knockback`, `apply_knockback()` and a `_physics_process()` that moves the dummy by `_knockback` and shrinks it toward zero

## Good to know
- The dummy's knockback is this lesson's Your Turn. The branch has it exactly as the reveal shows, because lesson 2.3 starts from it. With the player's numbers the dummy only slides a few pixels; lesson 2.3 works out why.
- Known at this point: the sword hits the dummy once and then never again, because nothing calls `reset_hits()` yet. Fixed in lesson 2.3 (reset on click) and properly in lesson 2.4 (reset at the start of every swing).
- Known at this point: there's no attack yet, so the sword's hitbox is always on. Lesson 2.4 adds the attack states.
- The click test from 2.1 still damages the dummy.
- The hazard still reads the player's own `invulnerable`. Lesson 2.3 deletes that flag and makes the hazard read the hurtbox.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=hitbox

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
