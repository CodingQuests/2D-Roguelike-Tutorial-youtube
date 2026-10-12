# The Last Forge · Lesson 6.2: Dying properly

Chapter 6, Make Them Want Another Run. This branch is the project at the **end of lesson 6.2** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 6.3? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-6.2.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 6.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-6.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 6.3 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-6.3)

Kills build a combo, dying slows the world and brings up a death screen with the run's summary and the essence banked, Retry starts a fresh run, and the essence total is saved to a file that survives closing the game.


## Files added
- `Scripts/MetaProgression.gd` (and its `.uid`), an autoload: `SAVE_PATH` is `user://forge_save.cfg`; `total_essence`, `unlocks`; `load_game()`, `save_game()` (ConfigFile, section `meta`) and `bank_run()`

## Files changed
- `project.godot`: MetaProgression added to the autoloads
- `Scripts/GameManager.gd`: `COMBO_WINDOW` (3 s), `combo`, `combo_timer` and a `_process()` that runs the window down; `register_kill()`, `break_combo()`, `start_run()` (fresh `run_stats`, time scale and pause reset, start time stamped) and `get_run_time()`
- `Scripts/RoomController.gd`: `GameManager.start_run()` at the top of `_ready()`; `_physics_process()` returns if the player is gone or dead; `_on_enemy_defeated()` registers the kill, counts it, and adds 1 essence (3 more for a corrupted enemy)
- `Scripts/PlayerController.gd`: `_dead`; getting hurt breaks the combo (`_on_hurt`); `_on_died()` stops the player and the weapon, slows the world to quarter speed for 1.2 s and asks the HUD for the death screen; `_physics_process()` returns while dead
- `Scenes/HUD.tscn`: `GameOver` (Full Rect, Process Mode Always) with `Backdrop`, `Summary`, `Essence` and a `Retry` button reading RUN AGAIN
- `Scripts/HUD.gd`: the three GameOver nodes; `_ready()` hides the death screen and connects Retry; `_format_time()`; `show_game_over()` banks the run's essence, fills the summary (floor, rooms, kills, best combo, time), counts the essence up, then pauses after a 1.2 s real-time wait; `_on_retry()` reloads the scene; `_count_up()`

## Good to know
- The run clock counts real time since the run started, so time spent paused counts too.
- `show_game_over(immediate_pause)` already has the branch that lesson 7.3's victory screen uses.
- The save file lives in the game's user data folder (Project > Open User Data Folder), not in the project.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=death

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
