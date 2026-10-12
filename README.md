# The Last Forge · Lesson 6.3: Unlocks that widen, not unlocks that inflate

Chapter 6, Make Them Want Another Run. This branch is the project at the **end of lesson 6.3** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 7.1? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-6.3.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 6.2](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-6.2) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 7.1 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-7.1)

Banked essence buys four permanent unlocks at the Forge (Twin Fangs, Vigor, Honed Edge, Fleet Boots), each bought once, saved, and applied once when a new player starts. The death screen gets a button that takes you to the Forge.


## Files added
- `Hub.tscn` (at the project root): the Forge screen, a full-rect Control with an `Essence` label, an `Unlocks` VBoxContainer holding four buttons named `daggers`, `vigor`, `honed` and `swift`, and a `StartRun` button
- `Scripts/Hub.gd` (and its `.uid`): connects each unlock button with `bind(id)`, `_refresh()` shows the essence, each name and price, greys out what you own or can't afford and ticks what you own, and `_on_unlock_pressed()` buys

## Files changed
- `Scripts/MetaProgression.gd`: `COSTS` (daggers 60, vigor 40, honed 35, swift 30) and `NAMES`; `cost()`, `is_unlocked()`, `can_buy()` and `buy()`, which saves straight away
- `Scripts/WeaponController.gd`: `set_available()` replaces the weapon list and goes back to the first slot
- `Scripts/PlayerController.gd`: `_apply_meta_unlocks()`, called at the end of `_ready()`: Twin Fangs joins the weapon list, Vigor adds 25 max health (and fills it), Honed Edge adds 6 quick damage, Fleet Boots multiplies speed by 1.08
- `Scripts/GameManager.gd`: `shake_camera()` checks `is_instance_valid(camera)`, because the autoload outlives the scene and its camera
- `Scenes/HUD.tscn`: `GameOver/Forge`, a duplicate of the Retry button
- `Scripts/HUD.gd`: `_on_forge()` changes the scene to `res://Hub.tscn`; `_ready()` connects it with `$GameOver/Forge.pressed.connect(_on_forge)`, under the Retry connection (typed at the end of the video, with a caption)

## Good to know
- To try the Forge, open `Hub.tscn` and press F6 (Run Current Scene). The main scene is still the combat room; lesson 7.1 adds a title screen and makes it the main scene.
- Known at this point: Start Run loads `res://Main.tscn`, which doesn't exist, so it does nothing but print an error. Fixed in lesson 7.1.
- Known at this point: the Forge button is an exact copy of Retry, with the same RUN AGAIN text and the same position, so it sits on top of Retry and clicking RUN AGAIN takes you to the Forge. Fixed in lesson 7.1.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=death

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
