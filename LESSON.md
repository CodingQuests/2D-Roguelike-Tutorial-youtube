# Lesson 7.2 — Sound is half the game

**Chapter 7 · Make It Feel Finished · Q7 Capstone**

**Ends with:** The same fight, muted then scored.

**Build milestone:** `M13`

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

`AudioManager.gd` (autoload) plays SFX **by name** through a pool of players, so
`AudioManager.play("hit")` maps to one of several variants with a little random
pitch — repeats never sound robotic.

Ambient music is generated procedurally (`tools/generate_music.py`): make every
voice frequency and LFO rate complete a *whole number* of cycles over the loop
length and there's no seam. `play_music()` crossfades on a dedicated Music bus and
survives scene changes — calm for menus, tense for the dungeon.

**Background music is the single biggest "this is a finished game" lever**, and the
A/B in this lesson — the same fight muted, then scored — is the whole argument.

## Files this lesson touches

- `scripts/AudioManager.gd`
- `default_bus_layout.tres`
- `audio`
- `tools/generate_sfx.py`
- `tools/generate_music.py`


## Next

```bash
git checkout lesson-7.2
```

See `README.md` for the full branch index.
