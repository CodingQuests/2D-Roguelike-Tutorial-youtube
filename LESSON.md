# Lesson 4.3 — A floor of connected rooms

**Chapter 4 · Turn It Into a Run · Q4 Rooms and Dungeon**

**Ends with:** Walk a whole floor.

**Build milestone:** `M08`

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

`Dungeon.generate(depth)` grows a **random spanning tree** of rooms on a coarse
grid, carves two-wide doorways, and types each room
(`ENTRANCE / COMBAT / TREASURE / BOSS / SHOP / ALTAR`). The tree edges (`links`)
are stored so the minimap can draw corridors in 4.4.

`RoomController` tracks which room the player is in each physics frame. Entering
an uncleared combat room **locks the doors** and spawns a depth-scaled wave;
clearing unlocks them. Beating the boss descends to a deeper, harder floor.

## Files this lesson touches

*(No new files — this lesson extends scripts that already exist.)*


## Next

```bash
git checkout lesson-4.3
```

See `README.md` for the full branch index.
