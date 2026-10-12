# The Last Forge · Lesson 4.3: A floor of connected rooms

Chapter 4, Turn It Into a Run. This branch is the project at the **end of lesson 4.3** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 4.4? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-4.3.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 4.2](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.2) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 4.4 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-4.4)

`Dungeon.gd` now grows a whole floor instead of one room. It places 6 to 9 rooms of 24 x 14 tiles on a 4 x 4 grid of 26 x 16 slots and joins them as a tree with two-tile doorways. Each room gets a type: the entrance, at least one fight, up to four shop, treasure or altar rooms, and the boss in the room the most doors away from the entrance. Fight and boss rooms are decorated, the whole floor is checked for reachability, and the knight starts in the middle of the entrance room. No monsters spawn yet, because the old wave is no longer started.


## Files added
- None

## Files changed
- `Scripts/Dungeon.gd`:
  - New constants and data: the `RoomType` enum, `SLOT_W`, `SLOT_H`, `GRID_W`, `GRID_H`, and the `rooms` and `links` arrays.
  - Building the floor: `_grow_tree()`, `_place_rooms()`, `_punch_doorways()`, `_door_h()`, `_door_v()` and `_record_door()`.
  - Choosing room types: `_farthest_room()` (a breadth-first search by doors) and `_assign_types()`.
  - `generate(depth: int = 1)` builds `clampi(5 + depth, 6, 9)` rooms and decorates the fight and boss rooms. The `push_warning` line is gone.
  - Helpers for the room controller: `room_at()`, `room_center_world()`, `entrance_center()`, `random_point_in_room()` and `_blocked()`.
- `Scripts/RoomController.gd`: `_ready()` no longer starts a wave. It generates the floor and puts the player at `floor_layer.entrance_center()`.
- `Scenes/CombatRoom.tscn`: Floor is moved to the top of the scene tree, so props and walls draw under the knight. The player instance is at (231, 354), where the video drags it before `entrance_center()` exists. The code moves him to the entrance anyway.

## Good to know
- The video opens with `PROP_SCENE` corrected to `res://Scenes/DestructibleProp.tscn`. You already typed it that way in 4.2 (the 3.3 correction about capitals), so skip that step.
- The boss repair is included. As first recorded, `_assign_types()` put the boss in the last room added, and `_farthest_room()` wasn't called anywhere. At the end of this lesson the course fixes it: `var boss_index := _farthest_room()`, and that index is skipped when choosing the middle rooms. This branch has the fixed function. The 4.4 video still shows the old line for a moment, because it was recorded before the fix.
- `_start_wave()`, `_spawn(scene)` and `_random_spawn_point()` are still in `RoomController.gd`, but nothing calls them. Lesson 4.4 replaces them.
- Shop, treasure and altar rooms are empty until chapter 5.
- The `RoomController.gd` header has two blank lines after `extends`, as in the video from here on.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=dungeon

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
