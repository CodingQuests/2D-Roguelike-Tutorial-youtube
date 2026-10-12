# The Last Forge · Lesson 1.4: A camera that doesn't fight you

Chapter 1, Make the Player Worth Controlling. This branch is the project at the **end of lesson 1.4** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 2.1? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-1.4.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 1.3](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.3) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 2.1 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.1)

The camera follows the knight smoothly and leans toward where you aim, it can shake, and the knight bobs as he walks and breathes when he stands still.


## Files added
- `Scripts/PlayerCamera.gd` (and its `.uid`): target path, frame-rate independent follow (`follow_lerp` 12), aim lead, trauma shake with `add_trauma()`

## Files changed
- `Scenes/main.tscn`: the Camera2D runs `PlayerCamera.gd`, with Target Path set to the Player
- `Scripts/PlayerController.gd`: `_base_sprite_scale`, `_bob_time` and `_update_body_juice` (the walk and idle bob), called from `_physics_process`

## Good to know
- The test calls from the video are already removed: `add_trauma(1.2)` in the camera's `_ready()` and the shake line in the hazard script.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=camera

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
