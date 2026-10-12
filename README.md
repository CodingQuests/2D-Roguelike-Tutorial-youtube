# The Last Forge · Lesson 7.2: Sound is half the game

Chapter 7, Make It Feel Finished. This branch is the project at the **end of lesson 7.2** of the free Godot 4 roguelike course on the [CodingQuests YouTube channel](https://www.youtube.com/@CodingQuests).

Starting lesson 7.3? This branch is your starting point: [download it as a ZIP](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/archive/refs/heads/lesson-7.2.zip), unzip it, and open `project.godot` in Godot 4.7.2.

[← lesson 7.1](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-7.1) · [all lessons](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube) · [lesson 7.3 →](https://github.com/CodingQuests/2D-Roguelike-Tutorial-youtube/tree/lesson-7.3)

Sound effects and music get their own buses, music keeps playing across scene changes and fades between a calm and a combat track, it ducks on a room clear and on death, and the pause menu has volume sliders that are saved with the Forge progress.


## Files added
- `default_bus_layout.tres`: SFX (about -4 dB) and Music (about -12 dB) buses next to Master

## Files changed
- `project.godot`: `audio/buses/default_bus_layout` points at the new layout
- `Scripts/AudioManager.gd`: `BUS_BASE_DB`; pickup, upgrade and click sounds; the pool plays on the SFX bus; a warning for a missing sound file; `MUSIC` / `MUSIC_DB`, a music player on the Music bus, `play_music()` with a fade, `duck_music()` with a token, `apply_mix()`
- `Scripts/MetaProgression.gd`: `audio_settings`, loaded and saved in an `[audio]` section, `set_audio_setting()`, `apply_mix()` after loading
- `Scripts/HUD.gd`: a loop in `_ready()` that sets up the master, sfx and music sliders from the save and saves every change
- `Scenes/HUD.tscn`: the pause VBox renamed to `VBox`, spaced out, with an `Audio` box (MasterLabel, master, Sfxlabel, sfx, MusicLabel, music)
- `Scripts/RoomController.gd`: combat music on start, the upgrade sound when a card is taken, a music duck on room clear
- `Scripts/PlayerController.gd`: a music duck when the player dies
- `Scripts/TitleScreen.gd`, `Scripts/Hub.gd`: calm music
- `Assets/Audio/music_calm.wav.import`, `Assets/Audio/music_combat.wav.import`: Loop Mode Forward, so the music loops

## Good to know
- The two fixes shown later in this lesson are already in: Loop Mode Forward on both music files (without it the track stops after 24 seconds), and the save order in `MetaProgression.save_game()`. The audio values are now written before `cfg.save()`; in the first version of the video they were set after the save and never reached the file.
- The pause buttons read RESUME and RESTART because of the fix at the end of 7.1. The video was recorded before that fix and still shows RUN AGAIN.
- The slider nodes must be named exactly `master`, `sfx` and `music` (lowercase), because the code builds their paths from those keys.

## Build this part yourself

The same game is a set of interactive quests on CodingQuests: you write each system yourself and your code gets
checked. The whole controller quest is free, no account needed: https://codingquests.io/roguelike?utm_source=github&utm_medium=readme&utm_campaign=fcc_2d_roguelike&utm_content=audio

## Requirements

[Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/), the standard version (not .NET). Anything from 4.6 on should open it.

Art and sound by [Kenney](https://kenney.nl) (CC0). Font: Silkscreen (OFL). See `CREDITS.md`.
