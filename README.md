# The Last Forge · Lesson 7.3: Finishing it

Chapter 7, Make It Feel Finished. This branch is the project at the **end of lesson 7.3** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

This is the finished game. [Download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-7.3.zip) and open `project.godot` in Godot 4.7.2.

[← lesson 7.2](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-7.2) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube)

The run can now be won. Beating the boss on floor 3 and taking (or skipping) the reward shows THE FORGE IS FREE on the summary screen, and a death shows YOU DIED. The game is exported as a Windows program. This is the finished game.


## Files added
- `export_presets.cfg`: the Windows Desktop export preset (Project > Export > Add > Windows Desktop), exporting to `../builds/TheLastForge.exe`

## Files changed
- `Scripts/RoomController.gd`: `FINAL_FLOOR := 3`; after the boss reward, the final floor shows the victory screen and every other floor descends
- `Scripts/HUD.gd`: `show_victory()` (reuses the death summary, banks once, heading THE FORGE IS FREE); `show_game_over()` sets YOU DIED and hides the pause panel
- `Scenes/HUD.tscn`: a `Heading` label above the summary on the GameOver screen

## Good to know
- The exported files (`TheLastForge.exe` and `TheLastForge.pck`) aren't in the repository. Export them yourself: Godot needs its export templates (Editor > Manage Export Templates) and writes both files next to each other, outside the project folder. Keep them together.
- The save file (`forge_save.cfg`) lives in the game's user data folder (Project > Open User Data Folder). Delete it to test a first launch.
- Still in the game at this point, as in the video: an enemy that drops gold as it dies can print a "flushing queries" error in the Output panel (the coins are added during a physics callback; `call_deferred` would fix it), and the low-health pulse stays hidden since 7.1.
- Because you applied the 3.6 cards, your boss's warnings are round and its slam warning matches the hit. The video's project never got those cards, so its warnings are squares and the slam warns wider than it hits.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=runloop

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
