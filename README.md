# The Last Forge · Lesson 5.4: Items you own, not stats you bump

Chapter 5, Make Every Run Different. This branch is the project at the **end of lesson 5.4** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 5.5? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-5.4.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 5.3](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.3) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 5.5 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-5.5)

Seven new items change what a hit does: Ember Brand sets enemies on fire, Frost Bite slows them, Storm Coil arcs damage to nearby enemies, Reaper's Mark executes low-health enemies, Echo Blade throws a slash wave with every swing, Maelstrom turns the heavy attack into a 360-degree whirlwind, and Twin Fang Curse adds a second strike. Four pairs of items unlock a synergy, and Tab opens a codex listing what you own.


## Files added
- `Scripts/SlashWave.gd` (and its `.uid`) and `Scenes/SlashWave.tscn`: an Area2D wave (layer 6, mask 1, group `hitbox`, a capsule and a sprite turned 90 degrees) that flies, fades over its lifetime, hits each enemy once and passes on burn and chill

## Files changed
- `Scripts/PlayerController.gd`: `burn_dps`, `chill_factor`, `chain_count`, `execute_threshold`, `echo_level`, `whirlwind`, `twin_strike`, the four `syn_` flags and `SYNERGY_DESCS`; `_resolve_synergies()` runs in `apply_upgrade()`; `get_execute_threshold()`
- `Scripts/UpgradeManager.gd`: Ember Brand, Frost Bite, Storm Coil, Reaper's Mark, Echo Blade, Maelstrom and Twin Fang Curse with their apply functions (chill capped at 0.85, chain at 8 jumps, execute at 50%)
- `Scripts/EnemyBase.gd`: `take_damage()`, burn and chill status (`ignite()`, `chill()`, `_tick_status()`), a dead check after the ticks, and the chill slowing the enemy's movement
- `Scripts/HitboxComponent.gd`: `hit_landed` is emitted from the new `notify_hit()` instead of `try_register_hit()`
- `Scripts/HurtboxComponent.gd`: two safety checks (a freed hitbox, a dead body) and the `notify_hit()` call after the damage
- `Scripts/WeaponController.gd`: `SLASH_WAVE`, `_is_whirl`, the whirlwind hitbox (150 x 150) and spin, `_apply_hit_effects()` (burn, chill, execute, chain, Twin Fang), `_chain_to_nearby()`, `_throw_waves()`
- `Scripts/HUD.gd`: `_unhandled_input()` toggles the codex on the `codex` action (Tab) and pauses, `_refresh_codex()`, `_close_codex()`; the codex starts hidden
- `Scenes/HUD.tscn`: `CodexPanel` (full rect, hidden) with a RichTextLabel `BuildText` and a `Close` button

## Course fixes included
These are played inside this lesson in the course, right after the code they repair:
- Chill multiplies only the enemy's own movement: `_physics_process` keeps `_ai_velocity` across frames, sets `velocity = _ai_velocity` before `_ai_process()` and stores it back after.
- The whirlwind size and offset are decided before the hitbox shape is sized (in the first version the shape was sized first, so the whirlwind kept the normal box).
- The chain skips enemies that are already dead (`if not (e is EnemyBase) or e.state == EnemyBase.State.DEAD: continue`).
- Echo Blade's waves deal damage: `SlashWave.gd` connects `body_entered` to `_on_body_entered()`, which ignores enemy bodies, so a wave no longer frees itself on the enemy's body before its hurtbox is hit (screen pickup P15).

## Good to know
- The video types `SLASH_WAVE` as `res://scenes/SlashWave.tscn` (small s). This branch uses `res://Scenes/SlashWave.tscn`, as the correction in lesson 3.3 asks. Lesson 6.1 corrects the video's line.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=loot

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
