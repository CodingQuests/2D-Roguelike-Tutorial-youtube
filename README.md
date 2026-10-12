# The Last Forge · Lesson 1.3: The frames that make a dodge work

Chapter 1, Make the Player Worth Controlling. This branch is the project at the **end of lesson 1.3** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 1.4? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-1.3.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 1.2](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.2) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 1.4 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.4)

There's a hazard in the room that prints HIT when you walk into it, but not while you're dashing, and the knight and his sword turn pale blue while the dash protects you.


## Files added
- `Scenes/Hazard.tscn`: Area2D (no layer, mask 2) with a RectangleShape2D, a white ColorRect and a built-in script that prints HIT unless the body is an invulnerable PlayerController

## Files changed
- `Scripts/PlayerController.gd`: `class_name PlayerController`, the `invulnerable` flag (on in `_start_dash`, off in `_end_dash`), `player_sprite` for the knight, and the pale blue tint `Color(0.7, 0.9, 1.0)` on both sprites during the dash
- `Scenes/main.tscn`: a Hazard added to Main

## Good to know
- HIT appears in the Output panel at the bottom of the editor.
- The hazard stays in the room for now; lesson 1.4 uses it to test the camera shake.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=iframes

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
