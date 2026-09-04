# Lesson 3.2 — Telegraphs - being readable beats being hard

**Chapter 3 · Make One Room Worth Fighting In · Q3 Enemies and AI**

**Ends with:** A fight you can learn.

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

The readable-danger loop: every attack shows a red telegraph during `WINDUP`, has
a brief `ACTIVE` window where it can hurt you, then a `RECOVERY` you can punish.

Good enemies are *readable*, not fast. A fight you can learn is a fight worth
having; an unreadable one just teaches players to keep their distance and wait.

## Files this lesson touches

- `shaders/fx_telegraph.gdshader`


## Next

```bash
git checkout lesson-3.2
```

See `README.md` for the full branch index.
