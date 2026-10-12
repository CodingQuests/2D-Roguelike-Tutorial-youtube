# The Last Forge · Lesson 5.5: Gold, shops and the deal you shouldn't take

Chapter 5, Make Every Run Different. This branch is the project at the **end of lesson 5.5** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 6.1? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-5.5.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 5.4](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.4) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 6.1 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-6.1)

Enemies drop gold coins that fly to you, shown on the HUD. Treasure rooms offer three free items on pedestals (taking one removes the others), shops sell three for gold, altars trade 18% of your max health for one of two items. Three new items fill an active slot used with E: Forge Pulse, Phase Step and Blood Siphon. Coins and room stock are cleared when you go down a floor.


## Files added
- `Scripts/Pickup.gd` (and its `.uid`): `class_name Pickup`, an Area2D with a toss velocity, a magnet pull toward the player and a one-time `_collect()` for subclasses
- `Scripts/GoldPickup.gd` (and its `.uid`) and `Scenes/GoldPickup.tscn`: extends Pickup, adds 1 gold and plays the pickup sound (layer 8 Pickups, mask 2 PlayerBody, a yellow-tinted potion sprite)
- `Scripts/ItemPedestal.gd` (and its `.uid`) and `Scenes/ItemPedestal.tscn`: `class_name ItemPedestal`, an Area2D stand (radius 28, layer 8, mask 2) with a "Press F" prompt, a rarity-coloured orb and a title/price label; F emits `chosen`; `refuse()` and `consume()`

## Files changed
- `Scripts/GameManager.gd`: `register_gold()` and `spend_gold()`
- `Scripts/RoomController.gd`: `GOLD_PICKUP`, `PEDESTAL`, `SHOP_BASE_PRICE`, `pickups`, `_stocked`, `_open_stands`; a 55% chance of 1 to 3 coins per kill (`_drop_gold()`); treasure, shop and altar rooms (`_make_pedestal()`, `_shop_price()`, `_place_pedestals()`, `_open_treasure()`, `_on_treasure_take()`, `_stock_shop()`, `_on_shop_buy()`, `_open_altar()`, `_on_altar_take()`); `_enter_floor()` frees the coins and clears the stock
- `Scripts/PlayerController.gd`: the active slot (`active_item`, `active_name`, `active_cooldown`, `_active_cd_timer`), `_phase_timer`, `set_active_item()`, `_handle_active_input()` (E), `use_active()`, `_forge_pulse()`, `_phase_step()` (uses `test_move` so it stops at walls and gates), `_blood_siphon()`, `_sync_invulnerability()` (also used when the dash ends)
- `Scripts/UpgradeManager.gd`: Forge Pulse, Phase Step and Blood Siphon (unique) with their apply functions
- `Scripts/HUD.gd`: `gold_label` shows `"%d g"` of the run's gold
- `Scenes/HUD.tscn`: `GoldLabel` under the bars, top left

## Good to know
- The pickup, upgrade and click sounds stay silent until lesson 7.2 adds them (`AudioManager.play()` ignores names it doesn't know).
- The video types `GOLD_PICKUP` and `PEDESTAL` with `res://scenes/` (small s). This branch uses `res://Scenes/GoldPickup.tscn` and `res://Scenes/ItemPedestal.tscn`, as the correction in lesson 3.3 asks. Lesson 6.1 corrects the video's lines.
- When a sword hit kills an enemy and it drops coins, the Debugger shows "Can't change this state while flushing queries": `_drop_gold()` adds the coin Area2Ds in the middle of the physics callback. The coins still drop and can be picked up; the course keeps this code as it is.
- Known at this point, fixed in lesson 6.1: enemies and projectiles from the old floor aren't removed when you go down, and `_on_enemy_defeated` doesn't check the player is alive.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=loot

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
