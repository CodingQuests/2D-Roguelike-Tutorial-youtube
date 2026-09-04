# Lesson 7.1 — The shell

**Chapter 7 · Make It Feel Finished · Q7 Capstone**

**Ends with:** Title, transitions, pause, restart.

**Build milestone:** `M14`

---

> ### Code snapshot pending
>
> **This branch currently mirrors `main` — the finished game.** It is a working,
> runnable project, but it is *not* yet cut back to this lesson's state.
>
> Chapters 0-2 (`lesson-0.1` through `lesson-2.2`) are line-accurate
> reconstructions built from the lesson scripts. From lesson 2.3 on, the accurate
> per-lesson slice is cut **when the lesson is recorded**, so the code matches what
> you actually see typed on screen. See `BRANCH_STATUS.md` on `main`.
>
> Everything below is accurate now — it's the lesson's real content and the files
> it touches.

---

## What this lesson builds

`TitleScreen.tscn` becomes the entry point. `Transitions.gd` (autoload — a
high-layer `CanvasLayer` with a fade rect, `process_mode = ALWAYS` and
ignore-time-scale tweens) fades to black on **every** scene change. No more hard
cuts.

`Esc` toggles `get_tree().paused`. The pause UI and the HUD need
`process_mode = ALWAYS` so they keep handling input while the tree is paused, and
the HUD's `_process` early-returns when paused.

The shell is the difference between a project and a product. A stranger can now
open it, and nothing about the first thirty seconds says "student build".

## Files this lesson touches

- `scripts/TitleScreen.gd`
- `TitleScreen.tscn`
- `scripts/Transitions.gd`


## Next

```bash
git checkout lesson-7.1
```

See `README.md` for the full branch index.
