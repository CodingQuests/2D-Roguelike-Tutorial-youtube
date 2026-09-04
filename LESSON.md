# Lesson 6.3 — Unlocks that widen, not unlocks that inflate

**Chapter 6 · Make Them Want Another Run · Q6 HUD and Meta**

**Ends with:** The Forge, and why +5 health is a trap.

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

`MetaProgression.gd` (autoload) banks `essence` and permanent unlocks to
`user://` with `ConfigFile`. The Forge (`Hub.tscn`) spends it.

**Unlocks that widen beat unlocks that inflate.** +5 max health makes every future
run mathematically easier and changes nothing about how you play. A new item in the
pool changes what runs are *possible*. One is a treadmill, the other is content.

> **This is where roguelite vs roguelike gets explained** — when persistence
> actually arrives and the viewer has a reason to care, not in the opening. And the
> distinction runs the opposite way to how it's usually said off the cuff:
> roguelites keep permanent progression between runs, traditional roguelikes reset
> everything. This game banks essence and sells permanent unlocks, so it's a
> **roguelite**.

## Files this lesson touches

- `scripts/MetaProgression.gd`
- `scripts/Hub.gd`
- `Hub.tscn`


## Next

```bash
git checkout lesson-6.3
```

See `README.md` for the full branch index.
