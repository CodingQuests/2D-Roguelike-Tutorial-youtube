# The Last Forge · Lesson 5.2: The reward moment

Chapter 5, Make Every Run Different. This branch is the project at the **end of lesson 5.2** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 5.3? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-5.2.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 5.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 5.3 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.3)

Clearing a room now slows time, pauses the game and offers three upgrade cards drawn with rarity weights; clicking one applies it to the player and the run carries on (after the boss, it also takes you down to the next floor).


## Files added
- `Scripts/UpgradeManager.gd` (and its `.uid`): `class_name UpgradeManager`, `RARITY_WEIGHT`, five stat upgrades stored as dictionaries whose `"apply"` is a Callable (Sharpened Edge, Heavy Soul, Bulwark, Swift Boots, Rapid Edge), `get_choices()` (skips uniques you own, then `_weighted_sample()`), `_owned_unique_ids()`
- `Scripts/UpgradeCard.gd` (and its `.uid`) and `Scenes/UpgradeCard.tscn`: a PanelContainer card (min size 224 x 268) with a VBox, Title and Desc labels and a Choose button; `setup(def)` fills it and tints the title by rarity, the button emits `chosen(def)` once

## Files changed
- `Scripts/PlayerController.gd`: `signal stats_changed`, the variables regrouped (the underscore ones together), `quick_bonus_damage`, `heavy_bonus_damage`, `move_speed_mult`, `attack_cooldown_mult`, `items`, `has_item()`, `apply_upgrade()`, `on_stats_changed()`; movement uses `move_speed_mult`; `_physics_process` returns while the tree is paused (the check goes first, above the time-scale check from 3.6)
- `Scripts/WeaponController.gd`: `_player` is typed `PlayerController`; `_compute_damage()` adds the player's bonus to the weapon's base damage; `_cd_mult()` returns `attack_cooldown_mult`
- `Scripts/RoomController.gd`: `_upgrades` (the Upgrades node), `_reward_is_boss`; `_clear_active_room()` now marks the room, sets `_busy` and defers `_finish_room_clear()` (slow-mo, sound, banner, a 0.4 s real-time wait, then the cards); `_on_upgrade_chosen()` applies the card, unpauses and descends after the boss
- `Scripts/HUD.gd`: `UPGRADE_CARD`, `upgrade_panel`, `_card_row`, `show_upgrades()` (fills the row, pauses the tree); the HUD runs with `PROCESS_MODE_ALWAYS` and hides the panel in `_ready()`
- `Scenes/HUD.tscn`: `UpgradePanel` (full rect, hidden) with an HBoxContainer `Cards` (centred, separation 24)
- `Scenes/CombatRoom.tscn`: an `Upgrades` node running `UpgradeManager.gd`

## Good to know
- The corruption numbers in the pasted card definitions do nothing yet; lesson 5.3 uses them.
- The video types `UPGRADE_CARD` as `res://scenes/UpgradeCard.tscn` (small s). This branch uses `res://Scenes/UpgradeCard.tscn`, as the correction in lesson 3.3 asks (match the capitals in every preload). Lesson 6.1 corrects the video's line.
- Rapid Edge (-20% cooldowns) makes no visible difference on quick attacks (their active and recovery time already outlast the cooldown); it does speed up heavies.
- The very first time Godot imports this project, it may report "Cannot infer the type of "p" variable" in `UpgradeManager.gd` (`var p := GameManager.player`) and fail to load `RoomController.gd`. Reopen the project and it loads; the game runs either way. Lesson 6.1 gives that line an explicit type.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=upgrades

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
