# Lesson 0.1 — The whole game, and why we build it backwards

**Chapter 0 · The Plan** · no quest

**Ends with:** an empty project, set up and ready to build in.

---

## There is no code in this lesson

Lesson 0.1 is the argument, not the build. It cold-opens on a full run of the
finished game and makes the case that **procedural generation multiplies whatever
already exists** — so randomising a boring room gets you randomised boredom.

That's why rooms are chapter 4 and not chapter 1, and why the next three chapters
are controller, combat and enemies before a single room is generated.

## What this branch contains

The empty Godot project, set up and ready:

- `project.godot` — Mobile renderer, 1280×720, `canvas_items` stretch with
  `expand` aspect, and the default texture filter set to **Nearest** so the pixel
  art stays crisp.
- **The input map** — all 11 named actions already defined:
  `move_up` / `move_down` / `move_left` / `move_right`, `dash` (Space),
  `quick_attack` (LMB), `heavy_attack` (RMB), `swap_weapon` (Q),
  `active_item` (E), `interact` (F), `codex` (F1).
- `Assets/` — the Kenney tile packs, fonts, icons and UI nine-patches.

No `scripts/`, no `scenes/`. Nothing to run yet.

> **Why the inputs are named up front.** Never hardcode a keycode. `"move_left"`
> reads clearer than `KEY_A` everywhere it appears, and it means rebinding is a
> project setting rather than a find-and-replace through your codebase.

## Run it

Open the folder in **Godot 4.7**. It will open to an empty scene tree — that's
correct. There's no main scene set yet; you'll set one in lesson 1.1.

## Next

```bash
git checkout lesson-1.1
```

Lesson 1.1 builds `Player.tscn` and `PlayerController.gd`: movement, correct
diagonals, and aiming that is independent of the direction you're walking.
