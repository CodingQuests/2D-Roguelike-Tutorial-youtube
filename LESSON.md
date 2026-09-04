# Lesson 5.2 — Power that costs you something

**Chapter 5 · Make Every Run Different · Q5 Loot and Corruption**

**Ends with:** Corruption rising, and you feel it.

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

**This is the game's identity.** Corruption tiers
(`Stable / Tainted / Corrupted / Overloaded`) drive **two** multipliers: damage
*dealt* and damage *taken*. Make it a knife's edge — at Overloaded you deal +22%
but take +40%, and more corrupted elite enemies spawn.

The whole game becomes *"how greedy dare I be?"*

This is also the other half of the chapter 2.1 answer — *why is health a node and
not a variable?* Because corruption needs a **single** place that all incoming
damage flows through, and `HurtboxComponent.damage_multiplier` is it.

## Files this lesson touches

- `scenes/CleansePickup.tscn`


## Next

```bash
git checkout lesson-5.2
```

See `README.md` for the full branch index.
