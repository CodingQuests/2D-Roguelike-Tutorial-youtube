# Lesson 4.2 — Why random rooms are boring

**Chapter 4 · Turn It Into a Run · Q4 Rooms and Dungeon**

**Ends with:** Constrained randomness, dead space proved.

**Build milestone:** `M07`

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

Pure random scatter produces rooms that feel like noise. Pick an **intentional
layout archetype** — pillars, ring, lanes, cover — and randomise *within* it, so
rooms feel designed rather than generated.

Then dress them: boulders, braziers with flame particles, and `DestructibleProp`s
(barrels and crates) — which are **"enemies that don't fight back"**. They reuse the
exact same Health + Hurtbox components, so your melee smashes them for loot. It's
the best possible argument for the component pattern from chapter 2.

## Files this lesson touches

- `scripts/DestructibleProp.gd`
- `scenes/DestructibleProp.tscn`
- `scripts/BrazierLight.gd`
- `scripts/Atmosphere.gd`
- `light_radial.tres`


## Next

```bash
git checkout lesson-4.2
```

See `README.md` for the full branch index.
