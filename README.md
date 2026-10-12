# The Last Forge · Lesson 1.2: The dash

Chapter 1, Make the Player Worth Controlling. This branch is the project at the **end of lesson 1.2** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 1.3? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-1.2.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 1.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 1.3 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.3)

Press Z to dash: a short burst in the direction you're moving (or toward the mouse if you're standing still), then a cooldown before the next one.


## Files added
- None

## Files changed
- `Scripts/PlayerController.gd`: `dash_speed` 520, `dash_duration` 0.14, `dash_cooldown` 0.6, the dash state variables, `_start_dash`, `_end_dash`, `_update_dash`, the dash branch in `_physics_process`, and `get_dash_ratio`
- `Scenes/main.tscn`: the Player in Main has Dash Cooldown set to 2.965 in the Inspector, as at the end of the video (the script's default stays 0.6; click the revert arrow to go back to it)

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=dash

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
