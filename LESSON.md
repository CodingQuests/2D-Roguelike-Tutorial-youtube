# Lesson 1.3 — The frames that make a dodge work

**Chapter 1 · Make the Player Worth Controlling · Q1 Controller**

**Ends with:** the knight glowing blue and passing straight through a hazard.

**Starts from:** `lesson-1.2`.

---

## What this lesson built

`scripts/PlayerController.gd` — an `invulnerable` flag, set and cleared by the
dash, plus the blue tint that makes it visible.

`scenes/Hazard.tscn` + `scripts/Hazard.gd` — **a deliberate throwaway.** Sitting
in the gap between the two pillars in `Main.tscn`.

## The animation is not the dodge

Ask most people what makes a dodge feel good and they'll say the animation — the
roll, the puff of dust, the way the character tucks in. It isn't. You can put the
best dodge animation in the world on a character and have it feel awful, because
the animation is what the dodge **looks** like and has nothing to do with what the
dodge **does**.

What it does is a **window of time where damage doesn't apply to you**. The dash
and that window are two separate things, and how they line up is the entire feel:

- Window **shorter** than the animation → you get hit while visibly dodging, and
  it feels broken.
- Window **much longer** → you're invincible for free and the game stops being
  tense.
- Window that starts **before** the animation reads as started → sounds like
  cheating, and is what almost every game you've enjoyed does.

## Build the cheapest thing that proves it

`Hazard.gd` prints `"HIT"`. That's the whole implementation, and it's on purpose:

> You cannot test invincibility without something to be invincible *from*, and
> waiting until the real damage system exists would mean writing the i-frames
> blind. **Build the cheapest possible thing that lets you see whether the real
> thing works.**

Keep it after this lesson — disable it, don't delete it. It's your i-frame
visualiser for the rest of chapter 1.

## An invisible rule is an unfair rule

The i-frames work at the end of the first build — and you can't see them. Dash
past the hazard three times at different timings and try to call which one was
invincible. You can't.

That's not a design opinion, it's mechanical. A player learns your game by forming
a theory, testing it, and getting feedback. **If the invincible window can't be
seen, there's nothing to form a theory about** — a dodge they can't see is
indistinguishable from luck. They'll either never trust it, or trust it at the
wrong moment and feel cheated.

The fix is one line:

```gdscript
sprite.modulate = Color(0.7, 0.9, 1.0)
```

The specific colour matters far less than that it's **obviously not his normal
colour**. This is a feedback element, not an art element — it has to be readable
at a glance, in a dark room, while the screen is shaking. **Tasteful loses to
legible every single time in a fight.**

## Which way the arrow points

Right now `invulnerable` lives on the player, because there's literally nothing
else to put it on yet. **It moves in chapter 2** — when the thing that actually
receives damage exists, the flag goes and lives there and the dash sets it from
here. One line changes.

The principle is the part to hold on to: **the dash drives it, and the damage
system reads it.** Never the other way round. Get that arrow backwards and every
future ability that grants invincibility has to go and edit the damage system.
This way each one just flips a flag that already exists.

> In the finished game this is `hurtbox.invulnerable`, an `@export` on
> `HurtboxComponent`. Lesson 2.2 does that migration explicitly.

## Your turn

Make the invulnerable window **longer than the dash** — set it early in
`_start_dash` and clear it a beat after `_end_dash` instead of during it. Play for
a minute.

It gets easier *and* it feels worse, and those two things happening together is
the thing worth noticing. A dodge that always works isn't a dodge, it's a movement
button — you stop reading the enemy and start mashing. **The window has to be
tight enough to miss.**

## If it goes wrong

| Symptom | Cause |
|---|---|
| `HIT` prints even while dashing | `body is PlayerController` failing — check `class_name PlayerController` is at the top |
| Hazard never fires at all | The `Area2D` has no `CollisionShape2D`. It fails silently — you'll meet this properly in chapter 2 |
| Tint never clears | An early `return` is skipping `_end_dash()` |
| Tint flickers | You're setting `modulate` every frame somewhere in `_physics_process` |

## Next

```bash
git checkout lesson-1.4   # the camera, and the chapter 1 payoff
git diff lesson-1.3 lesson-1.4
```
