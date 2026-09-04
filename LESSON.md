# Lesson 2.4 — Make the hit land

**Chapter 2 · Make Hitting Something Feel Good · Q2 Combat**

**Ends with:** The same swing, before and after seven layers.

**Build milestone:** `M03`

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

`Juice.gd` — a library of static helpers reused everywhere: white hit-`flash`
(via a shader material), `impact` / `spark` particle bursts, `squash` /
`stretch` scale pops, `afterimage` ghosts, `ring` expansions, `decal`
splats, and floating `damage_number` / `floating_text`. One place, so the
player and every enemy share identical polish.

`GameManager.gd` (autoload) — the glue for effects nobody owns:
`shake_camera(trauma)`, `hit_stop(seconds)`, `slow_mo`, `camera_kick`,
`zoom_punch`, `screen_impact`.

> **Leak gotcha:** never use infinitely-looping tweens for ambient motion
> (`create_tween().set_loops()`) — they show up as *"N ObjectDB instances leaked
> at exit"*. Do idle bob procedurally with `sin()`, as lesson 1.4 did.

> **Time-scale gotcha:** when awaiting during hit-stop or slow-mo, use
> `create_timer(d, true, false, true)` (ignore_time_scale) or your awaits get
> stretched by the slowed clock.

## Files this lesson touches

- `scripts/Juice.gd`
- `scripts/GameManager.gd`
- `shaders/sprite_fx.gdshader`
- `shaders/fx_spark.gdshader`
- `shaders/fx_slash.gdshader`
- `shaders/fx_burst.gdshader`
- `shaders/fx_ring.gdshader`
- `shaders/fx_decal.gdshader`
- `fx_quad.tres`


## Next

```bash
git checkout lesson-2.4
```

See `README.md` for the full branch index.
