# The Last Forge · Lesson 2.4: The swing

Chapter 2, Make Hitting Something Feel Good. This branch is the project at the **end of lesson 2.4** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 2.5? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-2.4.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 2.3](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.3) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 2.5 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.5)

Left click is a quick attack and right click a heavy attack with a short windup. A WeaponController on the WeaponPivot moves through IDLE, WINDUP, ACTIVE and RECOVERY, switches the hitbox on only while ACTIVE, sizes it and sets its damage and knockback from the current weapon's profile, and slows you down while you attack. Q swaps between the two available weapons.


## Files added
- `Scripts/WeaponController.gd` (and its `.uid`): `class_name WeaponController`, `extends Node2D`; the `State` enum; `weapon_sprite`, `attack_hitbox` and `hitbox_shape`; `_enable_hitbox()` and `_disable_hitbox()`; the state machine in `_process()`; `try_quick_attack()`, `try_heavy_attack()`, `_begin_active()` (hitbox size, offset, damage, knockback, `reset_hits()`), `_begin_recovery()`; `get_move_factor()` and `is_busy()`; three weapon profiles in `PROFILES` (Corrupted Cleaver, Cursed Pike, Twin Fangs), `available_weapons`, `_profile()` and `swap()`; `_compute_damage()` and `_cd_mult()`

## Files changed
- `Scenes/player.tscn`: WeaponPivot runs `WeaponController.gd`; its children are renamed `WeaponSprite` (the sword) and `AttackHitbox`
- `Scripts/PlayerController.gd`: `weapon` (the WeaponController on `$WeaponPivot`) replaces `weapon_pivot`, so aiming rotates `weapon`; `sprite_2d` and `hitbox` follow the renamed nodes; `_handle_attack_input()` (Q swaps, left click quick attack, right click heavy attack) replaces the click reset at the top of `_physics_process()`; walking velocity is multiplied by `weapon.get_move_factor()` before the knockback is added

## Good to know
- Only Corrupted Cleaver and Cursed Pike are in `available_weapons`, and every weapon still looks like the same sword: Q changes the numbers, not the picture.
- `_enable_hitbox()` sets `monitoring = false` directly while the other two lines use `set_deferred`, as on screen. It works here.
- `hitbox` in PlayerController isn't used anymore; it stays, as on screen.
- `_cd_mult()` returns 1.0 and `_compute_damage()` just reads the profile. Later chapters hook bonuses into them.
- The Your Turn (another weapon) isn't in this branch.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=weapon

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
