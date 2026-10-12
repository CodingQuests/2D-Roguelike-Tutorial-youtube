# The Last Forge · Lesson 2.1: Something that can be hurt

Chapter 2, Make Hitting Something Feel Good. This branch is the project at the **end of lesson 2.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 2.2? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-2.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 1.4](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.4) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 2.2 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.2)

Health lives in its own small node now. A training dummy (a barrel) uses it: every left click takes 10 health off, the number can't drop below zero or rise past the maximum, and when it reaches zero the dummy removes itself.


## Files added
- `Scripts/HealthComponent.gd` (and its `.uid`): `class_name HealthComponent`, `extends Node`; `max_health` (100) and `current_health`; signals `damaged`, `healed` and `died`; `damage()` and `heal()` with the already-dead guard and clamping; `set_max_health(value, keep_ratio)`, `is_alive()` and `get_ratio()`
- `Scenes/dummy.tscn`: a CharacterBody2D named Dummy with a barrel Sprite2D (`tile_0082`), a capsule CollisionShape2D, a child Node named `Health` running HealthComponent, and a built-in script that connects `died` to `_on_health_died()` (`queue_free()`) and holds the temporary click test (`_unhandled_input`: `quick_attack` damages the dummy by 10 and prints its health)

## Files changed
- `Scenes/main.tscn`: a Dummy instance in Main, down and to the left of the player

## Good to know
- The click test is temporary. Lesson 2.3 deletes it.
- `died` is connected in code, in the dummy's `_ready()`. The connection made in the Node panel in the video is disconnected again, so there is only one.
- The Your Turn (health on the player) isn't in this branch. The player gets its Health node on screen at the end of lesson 2.2.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=health

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
