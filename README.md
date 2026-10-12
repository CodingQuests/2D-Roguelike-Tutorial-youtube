# The Last Forge · Lesson 5.1: Make it feel like a game

Chapter 5, Make Every Run Different. This branch is the project at the **end of lesson 5.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 5.2? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-5.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 4.4](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.4) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 5.2 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.2)

The run scene is now the game you get when you press Play, sounds no longer cut each other off, enemies die with a flash, a burst and a fade, and the dungeon has a dim tint, glow and flickering brazier lights.


## Files added
- `Scripts/BrazierLight.gd` (and its `.uid`): a PointLight2D script whose energy flickers around its base value with two sine waves

## Files changed
- `project.godot`: the main scene is now `Scenes/CombatRoom.tscn` (right-click it in the FileSystem, Set as Main Scene)
- `Scripts/AudioManager.gd`: a pool of 16 AudioStreamPlayers that keep playing while paused, several files per sound picked at random, `VARIATION` pitch per sound, sounds preloaded once in `_preload_streams()`, new `telegraph`, `room_clear`, `door_open` and `door_close` sounds; `play()` now takes `pitch = -1.0` (random variation) by default. The new file replaces the whole script, including the 5-voice pool from 3.6 (card 10): paste it over your version
- `Scripts/HurtboxComponent.gd`: the old `print("entered: ", ...)` debug line is deleted
- `Scripts/EnemyBase.gd`: `die()` turns the attack and telegraph off, stops the hurtbox and the body collision, then flashes, bursts, rings and fades the enemy out before freeing it; the telegraph sound plays once when a warning appears (circle and rectangle)
- `Scripts/Dungeon.gd`: every brazier gets a PointLight2D with a shared radial gradient texture (`_radial_light_texture()`) and `BrazierLight.gd`; the flame particles get a brighter colour so they stand out from the light
- `Scripts/RoomController.gd`: the room-clear sound when a fight room is cleared
- `Scenes/CombatRoom.tscn`: WorldEnvironment (canvas background, glow 0.45 / 0.9 / bloom 0.05 / HDR threshold 1.15), CanvasModulate tint, Y Sort Enabled on the root, camera zoom 3

## Good to know
- The video adds `@onready var health: HealthComponent = $Health` to `PlayerController.gd` here. You already did it in 3.6 (card 04), so skip that step. A second copy of the line is a parse error.
- The video also corrects `BOSS_SCENE` to `res://Scenes/BossEnemy.tscn`. Yours has had the capital S since 4.4, so skip that step.
- Your enemies fade out as they die and take the room's tint, because your shader keeps the sprite's tint (3.6 card 07). In the video's project the shader still drops it, so the fade doesn't show there.
- HDR 2D is still off in Project Settings, so the darkness and glow are subtle (the course leaves it off).
- Y Sort is only enabled on the CombatRoom root, as in the video.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=loot

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
