# Lesson 2.3 — The swing

**Chapter 2 · Make Hitting Something Feel Good · Q2 Combat**

**Ends with:** It swings, and it feels like nothing.

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

A tiny state machine on the `WeaponPivot` — `IDLE -> WINDUP -> ACTIVE -> RECOVERY`
— driving a quick slash and a heavier cleave. During `ACTIVE` the attack hitbox is
enabled; otherwise it's disabled. Weapon stats live as **data profiles**
(sword / spear / daggers) in a `const` array, so weapons are just data.

The swing is deliberately unsatisfying at the end of this lesson. That's the setup
for 2.4.

> **Deferred toggling gotcha:** enabling or disabling an Area2D's `monitorable` /
> `disabled` from inside a physics signal throws *"can't change state while
> flushing queries"*. Always use `set_deferred("monitorable", true)`.

## Files this lesson touches

- `scripts/WeaponController.gd`


## Next

```bash
git checkout lesson-2.3
```

See `README.md` for the full branch index.
