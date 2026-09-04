# Lesson 1.2 — The dash

**Chapter 1 · Make the Player Worth Controlling · Q1 Controller**

**Ends with:** one dash, then a wait. Spacing is a decision again.

**Starts from:** `lesson-1.1`.

---

## What this lesson built

`scripts/PlayerController.gd` — `_update_dash()`, `_start_dash()`, `_end_dash()`
and `get_dash_ratio()`, plus three new exports.

`Main.tscn` — two pillars with a gap, so there's something to dash *between*.

## A dash is a state, not a speed

Everybody's first dash is a speed boost: hold a key, go faster, let go, stop. It
feels like nothing, because it *is* the walk with a number changed.

The thing that makes a dash a dash is that **while it's happening, normal
movement doesn't run at all.** It replaces your input rather than being added to
it:

```gdscript
if _is_dashing:
    velocity = _dash_dir * dash_speed
else:
    velocity = _get_move_input() * move_speed
```

Which means a dash is a **state** — something you're in, that starts, lasts a
fixed time, and ends. Not a modifier on your speed.

`dash_speed = 520` is about three times walking speed, and **the ratio matters
more than the number.** If a dash is only slightly faster than a walk, your brain
reads it as walking and the whole thing is wasted. You're not picking a speed,
you're picking a multiple.

## The early return

```gdscript
if _is_dashing:
    _dash_timer -= delta
    if _dash_timer <= 0.0:
        _end_dash()
    return
```

While you're dashing, nothing else in `_update_dash` runs — so you can't start a
dash while you're already dashing.

## The fallback nobody adds

If he's standing still there's no input direction, so `_start_dash()` falls back
to the **mouse** direction. Without it, standing still and pressing dash does
literally nothing — and the player doesn't conclude *"I had no direction"*, they
conclude **the button is broken**. Any input that can silently do nothing needs a
fallback.

## A resource that costs nothing isn't a resource

Mash the dash key without a cooldown and you fly across the room. The dash stops
being an escape and just becomes how you move — so why would you ever walk?

Every ability in every game you've liked has a cost: a cooldown, a charge, a
resource bar, a windup. **The cost is what turns using it into a decision, and the
decision is the fun part.** Take away the cost and you don't get a more powerful
ability, you get a less interesting game.

`dash_cooldown = 0.6` — long enough that you can't chain them across a room,
short enough that it doesn't feel like a punishment.

> **A mistake worth stealing:** that cooldown was tuned in an empty room. Dashed
> around, felt good, moved on — and it was wrong the day enemies existed, because
> a dash cooldown isn't a movement number, it's a **combat** number. It decides
> how often you get to escape, and there was nothing to escape from when it was
> set. Tune anything defensive against the thing it defends you from.

## Why `get_dash_ratio()` returns a float

```gdscript
## 1.0 = ready, 0.0 = just used.
func get_dash_ratio() -> float:
```

This is a **float, not a `Timer` node**, and it's deliberate. The cooldown bar on
the HUD in chapter 6 needs a *fraction* — 0 to 1. That's one division off a float
and genuinely awkward off a Timer. Build this with a Timer today and you'll be
rewriting it three chapters from now.

That's the shape of a lot of decisions in this course: not *"what works now"* but
**"what does the thing that consumes this need later."**

## Your turn

Set `dash_cooldown` to `0` and play for thirty seconds. Then set it to `2` and
play again. One of those versions will make you stop walking entirely — work out
which, and why.

At 0 it becomes your movement and the walk is dead. At 2 it's a panic button you
hoard and never use. **One of those is a movement ability and one is an escape
ability, and you have to decide which your game wants before you pick the
number.** This one is an escape, so it sits nearer the slow end.

## If it goes wrong

| Symptom | Cause |
|---|---|
| Dash does nothing when standing still | The mouse fallback in `_start_dash` is missing |
| He dashes forever | `_dash_timer` isn't counting down — check `delta` reaches `_update_dash` |
| Can dash mid-dash | The `return` after the `_is_dashing` block is missing |
| Dash direction snaps to a cardinal | You're using raw input rather than `.normalized()` |

## Next

```bash
git checkout lesson-1.3   # i-frames, and making them visible
git diff lesson-1.2 lesson-1.3
```
