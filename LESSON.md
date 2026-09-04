# Lesson 6.1 — A HUD that shows less

**Chapter 6 · Make Them Want Another Run · Q6 HUD and Meta**

**Ends with:** Thirteen elements down to five.

**Build milestone:** `M05`

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

`HUD.gd` on a `CanvasLayer`: a health bar with a lerping red "ghost" chip so you
*see* damage, the corruption meter, the dash cooldown, a status banner, the upgrade
cards and the death screen. The HUD registers itself with `GameManager` so any
system can reach it.

The lesson is subtraction. Thirteen elements down to five — a HUD you can read
during a fight beats a HUD that tells you everything.

This is where `get_dash_ratio()` from lesson 1.2 and `get_ratio()` from lesson
2.1 pay off. Both return a **fraction**, which is exactly what a bar needs. Build
either of them with a `Timer` back then and you'd be rewriting it here.

## Files this lesson touches

- `scripts/HUD.gd`
- `scripts/StatBar.gd`
- `ui_theme.tres`


## Next

```bash
git checkout lesson-6.1
```

See `README.md` for the full branch index.
