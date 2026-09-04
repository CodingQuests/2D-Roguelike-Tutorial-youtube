# Lesson 3.5 — The room knows the fight is over

**Chapter 3 · Make One Room Worth Fighting In · Q3 Enemies and AI**

**Ends with:** Doors lock, wave clears, HUD reads.

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

`RoomController.gd` orchestrates a fight: spawn a wave, track how many enemies are
alive via the `defeated` signal, and when the count hits zero, clear the room.

Containers (`Enemies`, `Projectiles`, `Pickups`) live in `CombatRoom.tscn`,
and the `Projectiles` / `Pickups` groups are set on those nodes **in the
editor** so drops can find them.

**This is the chapter 3 milestone: one room worth replaying.** Everything after
this multiplies it — which is exactly why procedural generation is chapter 4 and
not chapter 1.

## Files this lesson touches

- `scripts/RoomController.gd`
- `scenes/CombatRoom.tscn`


## Next

```bash
git checkout lesson-3.5
```

See `README.md` for the full branch index.
