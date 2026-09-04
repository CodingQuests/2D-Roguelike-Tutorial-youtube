# Lesson 3.1 — One enemy, off one script

**Chapter 3 · Make One Room Worth Fighting In · Q3 Enemies and AI**

**Ends with:** It chases and hits you.

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

`EnemyBase.gd` (a `CharacterBody2D`) holds everything enemies share: the
`IDLE / CHASE / TELEGRAPH / ATTACK / RECOVERY / DEAD` state scaffold, telegraph
helpers, the melee `AttackArea`, knockback, hit feedback, spawn-in animation, and
death. Concrete enemies `extend EnemyBase` and override `_ai_process()`.

`EnemyBase.tscn` is the base scene; each enemy is an **inherited scene** that
swaps the texture and stats. The `"enemy"` group is set on the
`EnemyBase.tscn` root *in the editor*, so every inherited enemy joins it
automatically — no `add_to_group` in code.

The Grunt is the first concrete one: chase plus simple melee. It reuses the exact
Health + Hurtbox components the dummy used in chapter 2, unchanged.

## Files this lesson touches

- `scripts/EnemyBase.gd`
- `scenes/EnemyBase.tscn`
- `scripts/GruntEnemy.gd`
- `scenes/GruntEnemy.tscn`


## Next

```bash
git checkout lesson-3.1
```

See `README.md` for the full branch index.
