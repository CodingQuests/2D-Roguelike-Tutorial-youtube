# Lesson 1.4 — A camera that doesn't fight you

**Chapter 1 · Make the Player Worth Controlling · Q1 Controller · chapter closer**

**Ends with:** the whole controller — walk, aim, dash, shake, and a camera that
leads where you look.

**Starts from:** `lesson-1.3`.

---

## What this lesson built

`scripts/PlayerCamera.gd` — smooth follow, damped aim lead, and trauma shake.

`Main.tscn` — a `Camera2D` in the room (**not** a child of Player), with
`target_path` pointing at it.

`scripts/PlayerController.gd` — `_update_body_juice()`, the procedural walk/idle
bob.

## A good camera lags on purpose

A camera locked exactly to the player is the default, it's one line, and it makes
people motion sick. The reason: your character stops moving on screen and the
whole world moves instead — and your eyes read that as *the world being unstable*
rather than *you being fast*.

So the camera is always slightly behind, and **that lag is what tells your brain
the character is the thing moving.**

## The two fixes, both worth more than this lesson

**1 · `rate * delta` is not framerate independent.**

```gdscript
# wrong — feels different at 30fps and 144fps
global_position.lerp(goal, follow_lerp * delta)

# right — genuinely framerate independent
global_position.lerp(goal, 1.0 - exp(-follow_lerp * delta))
```

It *looks* like it should be independent and isn't: you're applying a percentage
repeatedly, and the number of times you apply it changes with the framerate. The
`1 - exp(-rate * delta)` form is used for **every** ease in the rest of this
course. Write it down once.

**2 · The twitch isn't the follow's fault.**

Add a naive aim lead and flick the mouse — the camera twitches, even though the
follow is already damped. The mouse doesn't move smoothly; it teleports in
discrete steps every frame. **The noise is in the target, not in the follow.**

So the answer isn't to damp harder, it's to damp the *target* first and then
follow the smoothed version of it. Two damped things, one after the other:

```gdscript
_lead = _lead.lerp(want_lead, 1.0 - exp(-aim_lead_lerp * delta))
var goal := _target.global_position + _lead
global_position = global_position.lerp(goal, 1.0 - exp(-follow_lerp * delta))
```

Damp the lead **before** adding it to the goal, not after.

## Why trauma is squared

```gdscript
var shake := _trauma * _trauma
```

Trauma of 0.2 squared is 0.04 — barely a wobble. Trauma of 1.0 squared is still
1.0 — a full kick. The curve is bent, so small hits almost disappear and big hits
keep everything.

**That one character is what makes a heavy attack feel heavier than a light one.**
Without it you get one shake at two volumes and every hit in the game feels the
same size.

And `max_roll_degrees = 4`. Try 12 — it reads as a bug, not as impact. Above about
six degrees people think something's broken.

## Two lines that stop a bug you'd stop seeing

The snap to the target in `_ready()`. Without it, every single time you press play
the camera swoops in from wherever you left it in the editor. It looks like an
intro animation you didn't ask for, and it's the kind of bug you stop *seeing*
after a week because you assume it's normal.

## The bob is a `sin()`, not a tween

```gdscript
_bob_time += delta * freq
sprite.position.y = sin(_bob_time) * amp
```

The obvious way to do idle motion is `create_tween().set_loops()`. Do that and you
get *"N ObjectDB instances leaked at exit"* in your console when you quit.
**Procedural bobbing can't leak.**

## Your turn — chapter closer

Make the movement feel **heavier** — like he's wearing armour — **without making
him slower.** A room crossing should still take about a second, but starting and
stopping should cost something.

There's no single right answer, which is the point. One answer is acceleration:
instead of setting velocity directly, move it toward the target with
`move_toward()`, so he ramps up and coasts down — top speed identical, weight
completely different. But you might do it with the bob, or a squash when he plants
his feet, or a tiny delay before the dash fires. **All of those are correct. If
yours felt heavy, yours worked.**

## If it goes wrong

| Symptom | Cause |
|---|---|
| Camera swoops in from the corner every run | The `_ready` snap to target is missing |
| Camera doesn't move at all | `target_path` not set, or `make_current()` missing |
| Still twitchy | You damped the lead **after** adding it to the goal instead of before |
| Shake never stops | `trauma_decay` is 0, or you're adding trauma every frame |
| "N ObjectDB instances leaked at exit" | A looping tween somewhere. The bob must be `sin()` |
| Camera rotates and never returns | The `else` branch isn't resetting `rotation_degrees` |

## That's chapter 1

He moves, he aims, he dashes, and he's invincible for a fourteenth of a second
while he does it. None of it is a feature you can put on a box — it's the
difference between a project and a game.

## Next

```bash
git checkout lesson-2.1   # something that can be hurt
```

Chapter 2 gives him something to hit — and the first hit is going to feel like
absolutely nothing, on purpose, so you can hear the difference when it's fixed.
