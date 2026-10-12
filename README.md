# The Last Forge · Lesson 2.5: Make the hit land

Chapter 2, Make Hitting Something Feel Good. This branch is the project at the **end of lesson 2.5** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 3.1? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-2.5.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 2.4](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.4) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 3.1 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.1)

Every accepted hit now flashes the target white, bursts particles and pops a damage number. A sword hit also plays a sound, freezes the game for a few hundredths of a second and shakes the camera. Attacking lunges you forward, and the sword squashes and swings through an arc.


## Files added
- `Scripts/GameManager.gd` (and its `.uid`), an autoload: `register_camera()`, `shake_camera()`, and `hit_stop()` with a token and a timer that ignores time scale
- `Scripts/AudioManager.gd` (and its `.uid`), an autoload: one AudioStreamPlayer and named sounds (`slash`, `heavy`, `hit`, `enemy_hurt`, `enemy_death`, `dash`) loaded from `res://Assets/Audio/`; `play(name, volume_db, pitch)`
- `shaders/sprite_fx.gdshader` (and its `.uid`): flash toward a colour, plus an outline (width, colour, pulse)
- `Scripts/Juice.gd` (and its `.uid`): `class_name Juice`, `extends RefCounted`; static `make_flash_material()`, `flash()`, `impact()` (a one-shot CPUParticles2D burst), `squash()` (elastic, ease out) and `damage_number()`

## Files changed
- `project.godot`: autoloads `GameManager` and `AudioManager`
- `Scripts/PlayerCamera.gd`: `GameManager.register_camera(self)` in `_ready()` (the "Connect the camera too" card)
- `Scripts/HurtboxComponent.gd`: `flash_color`, `impact_color`, `show_damage_numbers`; finds the parent's `Sprite2D` and gives it the flash material; when it deals damage it flashes, bursts particles and shows the damage number
- `Scripts/WeaponController.gd`: hit-stop and shake constants; `_on_hit_landed()` (sounds, hit stop, shake) connected to the hitbox's `hit_landed`; the lunge in `_begin_active()`; squash from the saved `_base_weapon_scale`; `_animate_swing()` from the saved `_base_weapon_rotation`
- `Scripts/PlayerController.gd`: `lunge()`; `player_sprite` points at `$Sprite2D`
- `Scenes/player.tscn`: the knight's sprite node is renamed `Sprite2D` (the hurtbox looks for that name)

## Good to know
- Known at this point: AudioManager has a single player, so `play("heavy")` or `play("slash")` right after `play("hit")` replaces the hit sound before you hear it (the course card says so). It's fixed later in the course, when AudioManager gets more players.
- `print("entered: ", area.name)` from lesson 2.3 is still in the hurtbox, as on screen.
- The CPUParticles2D scene shown in the video is only a demo and isn't saved.
- The Your Turn (one more effect) isn't in this branch.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=shake

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
