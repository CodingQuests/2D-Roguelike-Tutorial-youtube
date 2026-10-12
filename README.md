# The Last Forge · Lesson 5.3: Power that costs you something

Chapter 5, Make Every Run Different. This branch is the project at the **end of lesson 5.3** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 5.4? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-5.3.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 5.2](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.2) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 5.4 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.4)

Every card now has a corruption cost. Corruption fills a purple bar in four tiers (Stable, Tainted, Corrupted, Overloaded); higher tiers make you hit harder but take even more damage, announce themselves with a ring and floating text, and turn more enemies into violet corrupted elites. Glass Blade, Cleansing Light and a Take Nothing button join the reward screen.


## Files added
- None

## Files changed
- `Scripts/PlayerController.gd`: `signal corruption_changed`, `max_corruption` 100, `corruption`, Glass Blade's two multipliers, `_last_tier`; `add_corruption()` (clamped, emits, checks the tier, refreshes stats) replaces the `on_stats_changed()` call in `apply_upgrade()`; `get_corruption_tier()`, `_corruption_damage_mult()`, `_corruption_taken_mult()`, `get_outgoing_damage_mult()`, `_on_tier_changed()`; `on_stats_changed()` sets the hurtbox's damage multiplier
- `Scripts/UpgradeManager.gd`: Glass Blade (cursed) and Cleansing Light (-25 corruption), `CLEANSE_MIN_CORRUPTION` 12, `_apply_glass()`, `_apply_noop()`, `_player_corruption()`; `get_choices()` leaves Cleansing Light out below 12 corruption
- `Scripts/WeaponController.gd`: `_compute_damage()` multiplies by `get_outgoing_damage_mult()`
- `Scripts/UpgradeCard.gd`: the description adds a `Corruption: +N` line
- `Scripts/Juice.gd`: `floating_text()` (a label that pops, rises and fades)
- `Scripts/EnemyBase.gd`: `is_corrupted` and `make_corrupted()` (more health, speed and damage, violet tint and pulsing outline)
- `Scripts/RoomController.gd`: `_maybe_corrupt()` (18, 38 or 60% chance by tier), called for every spawned enemy
- `Scripts/HUD.gd`: `corruption_bar`, `tier_label`, `_upgrade_callback`, `_skip_upgrade()`; the Skip button is connected; `_process()` updates the bar and the tier text
- `Scenes/HUD.tscn`: `CorruptionBar` (a purple StatBar, top right), `TierLabel` under it, and a `Skip` button ("Take Nothing") in the UpgradePanel

## Good to know
- A corrupted enemy is violet in your game. In the video only its outline shows, because the video's shader still drops the sprite's tint; yours keeps it (3.6 card 07).

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=corruption

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
