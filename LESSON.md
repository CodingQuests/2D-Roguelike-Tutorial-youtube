# Lesson 4.4 — Knowing where you are

**Chapter 4 · Turn It Into a Run · Q4 Rooms and Dungeon**

**Ends with:** Minimap, room types, gated doors.

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

`Minimap.gd` uses immediate-mode `_draw()` to render a framed map: room boxes
coloured by type, corridor lines from `Dungeon.links`, and a pulsing outline on
your current room.

This one **must** stay in code — it's custom drawing, which is the genuine
exception to "structure belongs in the scene".

## Files this lesson touches

- `scripts/Minimap.gd`


## Next

```bash
git checkout lesson-4.4
```

See `README.md` for the full branch index.
