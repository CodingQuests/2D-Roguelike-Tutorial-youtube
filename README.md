# The Last Forge · Lesson 7.1: The shell

Chapter 7, Make It Feel Finished. This branch is the project at the **end of lesson 7.1** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 7.2? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-7.1.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 6.3](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-6.3) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 7.2 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-7.2)

The game now opens on a title screen, every scene change fades through black, and a run can be paused, with the codex and the pause menu sharing the Escape key.


## Files added
- `Scenes/TitleScreen.tscn`: Center (full rect) > VBox > Title ("THE LAST FORGE"), StartButton ("Start"), QuitButton ("Quit")
- `Scripts/TitleScreen.gd` (and its `.uid`): the glowing title, Start goes to the run through `Transitions`, Quit fades out and quits
- `Scripts/Transitions.gd` (and its `.uid`): autoload on a CanvasLayer at layer 128 with a ColorRect built in code; `change_scene()` (fade, busy flag, recovers from a bad path), `reload_scene()`, `fade_out_then()`, `is_busy()`

## Files changed
- `project.godot`: `Transitions` autoload; the main scene is now `Scenes/TitleScreen.tscn`
- `Scripts/HUD.gd`: Retry and Forge go through `Transitions`; `_toggle_pause()` and `_toggle_codex()`; Tab and Escape in `_unhandled_input()` (Escape closes the codex first, does nothing on the reward or death screen); `_close_codex()` removed; the pause buttons call `_toggle_pause`, `_on_restart` and `_on_title`
- `Scenes/HUD.tscn`: a `PausePanel` (full rect) with a Backdrop and a VBoxContainer of three buttons (RESUME, RESTART, Return To title Screen); the death screen's FORGE button moved below RUN AGAIN; `OverloadPulse` hidden (its eye is switched off while the pause panel is built)
- `Scripts/Hub.gd`: Start Run goes through `Transitions` to `res://Scenes/CombatRoom.tscn`; unlock buttons ignore presses during a fade

## Good to know
- The fixes shown at the end of the lesson are already in: the title screen's Full Rect and text, the title as the main scene, the Start and Start Run paths (`res://Scenes/CombatRoom.tscn`), the HUD's title path (`res://Scenes/TitleScreen.tscn`), the button labels and the Forge button moved below RUN AGAIN.
- The fixes at the end also add `$GameOver/Forge.pressed.connect(_on_forge)` to `HUD._ready()`. You already have it from 6.3, so skip that step: connecting it twice is an error. (Earlier in the 7.1 video the line is missing from `_ready()`; it was removed off camera before the recording.)
- Known at this point, as on screen: hiding `OverloadPulse` in the scene tree also hides it in the game, because `HUD.gd` only changes its colour. From here the low-health pulse from 6.1 doesn't show. Turn its eye back on if you want the pulse.
- As in the video, the pause panel's container is still named `VBoxContainer` while the code looks for `PausePanel/VBox/...`. Until 7.2 renames it to `VBox`, the HUD prints "Node not found: PausePanel/VBox/Resume" when a run starts and the three pause buttons don't respond. Escape still pauses and resumes. Rename the node now if you like; 7.2 does it at the end.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=runloop

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
