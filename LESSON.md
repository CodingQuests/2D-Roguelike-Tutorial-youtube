# Lesson 4.1 — A room built in code

**Chapter 4 · Turn It Into a Run · Q4 Rooms and Dungeon**

**Ends with:** Floor, walls, a dressed space.

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

`Dungeon.gd` (a `TileMapLayer`) builds floor and walls procedurally. The tiny
`TileSet` — one atlas, a few tiles — is fine to **build in code**; there's no
benefit to a hand-authored `.tres` when the geometry is generated anyway.

## Files this lesson touches

- `scripts/Dungeon.gd`


## Next

```bash
git checkout lesson-4.1
```

See `README.md` for the full branch index.
