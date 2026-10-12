# The Last Forge · Lesson 2.3: Three bugs and no errors

Chapter 2, Make Hitting Something Feel Good. This branch is the project at the **end of lesson 2.3** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 2.4? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-2.3.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 2.2](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.2) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 2.4 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-2.4)

The sword can hit the dummy again after every click, because the click now resets the sword's hit list. The dummy is shoved a distance you can see, the click no longer damages it, and invulnerability lives in one place: the hurtbox.


## Files added
- None

## Files changed
- `Scenes/dummy.tscn`: the click test (`_unhandled_input`) is deleted; the dummy's knockback is retuned to `KNOCKBACK_DECAY` 900.0 and `KNOCKBACK_TAKEN` 1.0; Hit Once Per Attack is unticked on the dummy's HitboxComponent
- `Scripts/PlayerController.gd`: `hitbox` @onready (`$WeaponPivot/HitboxComponent`); at the top of `_physics_process()` a `quick_attack` press calls `hitbox.reset_hits()`; the player's own `invulnerable` flag and its two assignments in the dash are deleted
- `Scripts/HurtboxComponent.gd`: `print("entered: ", area.name)` at the top of `_on_area_entered()`
- `Scenes/Hazard.tscn`: the hazard checks `body.hurtbox.invulnerable`

## Good to know
- Resetting on click is a stopgap. Lesson 2.4 resets the hit list at the start of every swing.
- The breakpoint set in the video isn't saved in the project files.
- The comment on the dummy's `KNOCKBACK_TAKEN` still says the player is shoved less than enemies: it was copied from the player, as on screen.
- The Your Turn (measure the shove) isn't in this branch.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=hitbox

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
