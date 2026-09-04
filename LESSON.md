# Lesson 3.3 — Four enemies from the same base

**Chapter 3 · Make One Room Worth Fighting In · Q3 Enemies and AI**

**Ends with:** Four different decisions.

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

Each enemy overrides `_ai_process()` with its own pattern and sets its own stats:

- **Charger** — telegraph a line, then dash.
- **Caster** — keep distance, fire `Projectile`s.
- **Brute** — slow, huge telegraphed slam.
- **Skitterling** — fast, fragile swarmer.

Four scripts, one base, four genuinely different decisions for the player.

> **Hit-stun — a real bug worth knowing:** a charging enemy re-sets
> `velocity = charge_dir * charge_speed` *every frame*. If your hit just does
> `velocity += knockback`, the knockback stacks on the charge and launches the
> enemy across the room. The fix is a short **hit-stun**: when struck, zero the
> enemy's AI velocity for a beat so the knockback *replaces* its motion.

## Files this lesson touches

- `scripts/ChargerEnemy.gd`
- `scenes/ChargerEnemy.tscn`
- `scripts/CasterEnemy.gd`
- `scenes/CasterEnemy.tscn`
- `scripts/BruteEnemy.gd`
- `scenes/BruteEnemy.tscn`
- `scripts/SkitterlingEnemy.gd`
- `scenes/SkitterlingEnemy.tscn`
- `scripts/Projectile.gd`
- `scenes/Projectile.tscn`


## Next

```bash
git checkout lesson-3.3
```

See `README.md` for the full branch index.
