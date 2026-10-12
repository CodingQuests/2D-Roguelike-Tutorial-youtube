# The Last Forge · Lesson 3.6: Debug the game you actually built

Chapter 3, Make One Room Worth Fighting In. This branch is the project at the **end of lesson 3.6** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 4.1? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-3.6.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 3.5](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.5) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 4.1 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.1)

The checkpoint. This branch has every card applied, so the room works end to end:
- The HUD follows your health and dash.
- Warnings are round or rectangular and match the hits they warn about.
- Tints and spawn fades show.
- Overlapping sounds play.
- Clearing the room shows ROOM CLEARED.


## Files added
- None

## Files changed
- `Scripts/PlayerController.gd`: adds the `health` reference (card 04). `_physics_process()` returns while time is stopped and updates aim before reading attacks (card 02), and `move_and_slide()` is guarded ("Also guard the actual movement call").
- `Scripts/EnemyBase.gd`:
  - `_init_telegraph_textures()` builds a radial circle and a white rectangle once.
  - The end of `_ready()` saves `_base_sprite_scale`, builds the textures and hides the telegraph (card 08).
  - Each warning picks its texture, and the circle resets its position.
  - Adds `show_charge_warning()` (card 09).
  - `move_and_slide()` is guarded.
- `Scripts/BossEnemy.gd`: `SLAM_RADIUS` (22) is used for both the slam warning and the hit, and the charge warning covers the path (card 09).
- `Scripts/ChargerEnemy.gd`: `show_charge_warning(charge_speed * charge_time, 7.0, _charge_dir)` (card 09). The card gives 7.0 as the charger's hitbox radius, so the charge's hit uses 7.0 too (`enable_attack_area(Vector2.ZERO, 7.0)`, was 18.0) and the warning covers the hit.
- `Scripts/AudioManager.gd`: a pool of 5 voices, a default of -12 dB, and a `room_clear` sound (card 10).
- `shaders/sprite_fx.gdshader`: passes the vertex tint into `fragment()` (card 07).
- `Scenes/EnemyBase.tscn`: the enemy body is on layer 3 with mask 1 and 2 (card 06).
- `Scenes/Projectile.tscn`: the projectile's mask is the world, layer 1 (card 06).
- `Scenes/HUD.tscn`: `HUD.gd` is attached to the root CanvasLayer (card 04).

## Good to know
- Card 01 (scene paths and `$player`) and card 05 (the swapped grunt and caster scripts) need no edit here. Your project got those right in 3.3 and 3.5. Card 03's registrations are already in: the camera since 2.5 and the player and HUD since 3.5.
- The cards are the source. Where the tested copy used in the demo clips differs and no card shows it, this branch keeps the code from the earlier lessons. For example, the grunt's warning radius and AudioManager's sound lookup are unchanged, and the enemies keep the ranges and hit sizes from lesson 3.3 (the tested copy has smaller ones that the course never shows).
- Run `CombatRoom.tscn` with F6 to test the room. `main.tscn` (the boss) is still the main scene.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=rooms

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
