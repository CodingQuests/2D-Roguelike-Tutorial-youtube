# The Last Forge · Lesson 3.2: Telegraphs: being readable beats being hard

Chapter 3, Make One Room Worth Fighting In. This branch is the project at the **end of lesson 3.2** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 3.3? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-3.2.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 3.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 3.3 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-3.3)

The grunt now warns before it swings: a soft red circle that fills in over the windup and a pulsing red outline. Then comes the attack, then recovery. Every enemy also gets its own collision shapes again, and the grunt is slower.


## Files added
- None

## Files changed
- `Scripts/EnemyBase.gd`: adds the `telegraph` node reference, `_tele_elapsed`, `show_telegraph_circle()` and `_tick_telegraph()`, which turns the warning into a clock. `_physics_process()` calls `_tick_telegraph()` right after `_ai_process()`.
- `Scripts/GruntEnemy.gd`: adds `telegraph_time` and the TELEGRAPH state. `_enter_telegraph()` shows a circle at 0.85 × attack range and turns on the outline. `hide_telegraph()` lives in the grunt's script and runs from `_on_ready()` and `_enter_attack()`. Speed goes from 95 to 60.
- `Scripts/Juice.gd`: adds `_mat()` and `set_outline()`.
- `Scenes/EnemyBase.tscn`: the Telegraph gets a GradientTexture2D. It's white, filled radially from the centre and transparent at the edge, at scale 0.6. The three collision shapes are back (body and hurtbox rectangles, hitbox circle), each with Local to Scene on.
- `Scenes/GruntEnemy.tscn`: stores `telegraph_time = 0.35`.

## Good to know
- This branch includes the first 3:46 of the recorded 3.3 video (radial fill, Local to Scene, grunt speed 60), which the course plays at the end of this lesson.
- Setting the Telegraph's scale in the Inspector does nothing in game, because `show_telegraph_circle()` sets the scale from the radius every time the warning shows.
- The swing reaches about 46 px (22 px radius, 24 px in front), a bit past the 38 px warning. The recap asks you to test that edge.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=enemies

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
