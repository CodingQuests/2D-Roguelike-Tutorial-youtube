# The Last Forge · Lesson 4.1: A room built in code

Chapter 4, Turn It Into a Run. This branch is the project at the **end of lesson 4.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 4.2? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-4.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 3.6](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.6) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 4.2 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.2)

The combat room now has a real floor. A TileMapLayer called Floor builds its own tileset from the tile sheet, fills a 24 x 14 room with floor cells, derives the walls from those cells, gives every wall tile a 16 x 16 collision box, keeps the tiles under the knight and scatters a few cracked floor tiles.


## Files added
- `Scripts/Dungeon.gd` (and its `.uid`): `class_name Dungeon`, a `TileMapLayer`. `_build_tileset()` makes a TileSet from `tilemap_packed.png` with the FLOOR, WALL and three FLOOR_DECO tiles, all at `z_index` -10. `generate()` rebuilds the `Walls` StaticBody2D and fills `Rect2i(0, 0, 24, 14)` with floor cells. `_paint()` paints the floor, then a wall on every one of the 8 neighbours that isn't floor. `_build_wall_collision()` adds one box per wall cell. `_scatter_floor_decor()` swaps 10% of the floor cells for decor tiles.

## Files changed
- `Scenes/CombatRoom.tscn`: a new `Floor` TileMapLayer, the last child of CombatRoom, running `Dungeon.gd`. It has no TileSet in the scene; the script builds one.
- `Scripts/RoomController.gd`: `@onready var floor_layer: Dungeon = $Floor`, and `floor_layer.generate()` at the end of `_ready()`.

## Good to know
- Run CombatRoom with F6 (Run Current Scene). The project's main scene is still `main.tscn` until lesson 5.1.
- The TileMap at the start of the video only shows what the code replaces. It becomes the Floor TileMapLayer in CombatRoom; `main.tscn` doesn't change.
- The video tries 6% and then 16% decor; the code ends at `0.10`.
- Known at this point: monsters still come from 3.5's fixed spawn rectangle, which doesn't know about the walls. A monster can appear outside the room, and then that wave can't be finished. From lesson 4.4, each room spawns its own monsters inside it.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=dungeon

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
