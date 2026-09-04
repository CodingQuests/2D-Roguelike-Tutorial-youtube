# Lesson 5.3 — Items you own, not stats you bump

**Chapter 5 · Make Every Run Different · Q5 Loot and Corruption**

**Ends with:** Effects that compound.

**Build milestone:** `M09`

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

**The single most important lesson for replayability.** Stop applying upgrades as
one-shot stat bumps. Give the player an `items` array and **composable on-hit
effect fields**: `burn_dps`, `chill_factor`, `chain_count`,
`execute_threshold`. Items add to these, so picking more *compounds* the build.

Some items change *how the weapon works*: **Echo Blade** throws a piercing ranged
`SlashWave` on every swing (giving you ranged), **Maelstrom** turns the heavy
attack into a 360 degree whirlwind, **Twin Fang** strikes twice.

Then **synergies**: owning the right *pair* fuses into a bonus — Ember + Storm =
chain bolts that ignite, Echo + Frost = freezing waves. Even without explicit
pairs, composable effects already create emergent builds. That's the whole magic
of the genre.

> **Friendly-fire reminder:** `SlashWave.tscn` is on the PlayerHitbox layer (32),
> so enemy hurtboxes detect it and the player's never does — the chapter 2.2 rule
> still doing its job with no new code.

## Files this lesson touches

- `scripts/SlashWave.gd`
- `scenes/SlashWave.tscn`


## Next

```bash
git checkout lesson-5.3
```

See `README.md` for the full branch index.
