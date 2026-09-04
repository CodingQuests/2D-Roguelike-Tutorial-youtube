# Lesson 3.4 — A boss with a tell

**Chapter 3 · Make One Room Worth Fighting In · Q3 Enemies and AI**

**Ends with:** Patterns and an enrage.

**Build milestone:** `M04`

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

A boss is not an enemy with more health. It's a **sequence of readable patterns**
plus a phase change — an enrage that alters the pattern once you've learned the
first one, so the fight has a second act.

Built on the same `EnemyBase` as everything else.

## Files this lesson touches

- `scripts/BossEnemy.gd`
- `scenes/BossEnemy.tscn`


## Next

```bash
git checkout lesson-3.4
```

See `README.md` for the full branch index.
