# Lesson 5.4 — Gold, shops and the deal you shouldn't take

**Chapter 5 · Make Every Run Different · Q5 Loot and Corruption**

**Ends with:** The altar, paid in health.

**Build milestone:** `M10, M11, M12`

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

**Gold** is the in-run currency, lost on death — distinct from `essence`, the meta
currency banked between runs. Kills and smashed props drop `GoldPickup` coins.

**Pedestals**: `ItemPedestal.tscn` is a walk-up stand. Its collision shape, layers
and static plinth live in the **scene**; the script builds only the data-driven orb
and the name/price labels. Stand on it and press **F**.

- *Treasure room:* three free pedestals; taking one dismisses the rest.
- *Shop room:* priced pedestals plus a reroll stand.

**The Forge Altar** offers powerful items for a **max-HP** price rather than
corruption — the signature gamble. Two pedestals, choose one, pay in flesh. This is
the emotional peak of a run: *"I'm strong but I'm down to 40 HP — do I dare?"*

**Active abilities [E]**: a single active slot with a charge bar — Forge Pulse,
Phase Step, Blood Siphon. Phase Step is the blink that grants i-frames in one line,
exactly as promised in lesson 1.3.

> **The bug this design prevents:** an `Area2D` with no `CollisionShape2D`
> *silently never detects anything*. Putting the shape in the scene makes its
> absence obvious. The original pedestal was built entirely in code, forgot the
> shape, and buying just did nothing.

> **Scope note:** this lesson compresses gold, shops, the altar *and* active
> abilities into ~18 minutes. If it overruns on the day, split it rather than
> cutting the altar — the altar is the chapter's best beat.

## Files this lesson touches

- `scripts/Pickup.gd`
- `scenes/GoldPickup.tscn`
- `scenes/HealthPickup.tscn`
- `scripts/ItemPedestal.gd`
- `scenes/ItemPedestal.tscn`


## Next

```bash
git checkout lesson-5.4
```

See `README.md` for the full branch index.
