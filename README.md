# The Last Forge · Lesson 1.1: Move and aim

Chapter 1, Make the Player Worth Controlling. This branch is the project at the **end of lesson 1.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 1.2? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-1.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 0.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-0.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 1.2 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.2)

The knight walks with WASD at the same speed in every direction, and his sword points at the mouse, whichever way he walks.


## Files added
- `Scenes/player.tscn`: Player (CharacterBody2D, collision layer 2, mask 1 and 3) with the knight sprite (`Tile0096`), a capsule CollisionShape2D (radius 4, height 10, at y 3) and a WeaponPivot holding the sword sprite (`Sprite2D`)
- `Scenes/main.tscn`: Main (Node2D) with the Player and a Camera2D at zoom 4
- `Scripts/PlayerController.gd` (and its `.uid`): `move_speed` 180, input to velocity, diagonal fix, aim at the mouse with a 4 px flip deadzone, and the finite-value guard

## Files changed
- `project.godot`: default texture filter set to Nearest; main scene set to `Scenes/main.tscn`

## Good to know
- The camera doesn't follow the knight yet; that's lesson 1.4.
- The knight sprite node is still called `Tile0096` (the name Godot gives it when you drag the PNG in).

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=movement

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
