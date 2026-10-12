# The Last Forge · Lesson 0.1: The whole game, and why we build it backwards

Chapter 0, The Plan. This branch is the project at the **end of lesson 0.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 1.1? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-0.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 1.1 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-1.1)

An empty Godot 4.7 project, set up for the course: the art is imported and all the controls are named, but there is nothing to play yet.


## Files added
- `project.godot`: the project, with these settings:
  - Display > Window > Stretch: Mode `canvas_items`, Aspect `expand`
  - Input Map, 11 actions (type the names exactly, lowercase with underscores):
    `move_right` D, `move_left` A, `move_up` W, `move_down` S, `dash` Z,
    `quick_attack` left mouse, `heavy_attack` right mouse, `active_item` E,
    `interact` F, `codex` Tab, `swap_weapon` Q
- `Assets/`: the course art, fonts and sounds (Audio, Fonts, Icons, Tilemap, Tiles, UI, cursor, minimap, overoworld)
- `icon.svg`, `.gitignore`, `.gitattributes`, `.editorconfig`: made by Godot with the new project

## Files changed
- None (first branch)

## Good to know
- No scenes or scripts yet, so pressing Play asks for a main scene. Lesson 1.1 makes one.
- Some controls (attacks, codex, items) do nothing until later chapters.
- This project uses the Mobile renderer, like the lessons. If you picked Compatibility when you made your project, that's fine for this course.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=setup

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
