# Lesson 5.1 — The reward moment

**Chapter 5 · Make Every Run Different · Q5 Loot and Corruption**

**Ends with:** Three cards, one choice.

**Build milestone:** `M06`

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

`UpgradeManager.gd` holds every upgrade as a **plain dictionary** — `id`,
`title`, `desc`, `corruption` cost, `rarity`, and an `apply` Callable.
Plain dicts rather than Resources keep it trivial to read and extend.

On room clear, offer three random upgrades (rarity-weighted) as `UpgradeCard`s.
The player picks one.

## Files this lesson touches

- `scripts/UpgradeManager.gd`
- `scripts/UpgradeCard.gd`
- `scenes/UpgradeCard.tscn`


## Next

```bash
git checkout lesson-5.1
```

See `README.md` for the full branch index.
