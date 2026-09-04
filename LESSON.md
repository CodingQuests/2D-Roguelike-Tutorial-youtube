# Lesson 1.1 — Move and aim

**Chapter 1 · Make the Player Worth Controlling · Q1 Controller**

**Ends with:** the knight walking one direction while pointing another, diagonals
correct, crossing the room in about a second.

---

## What this lesson built

`scenes/Player.tscn`

```
Player (CharacterBody2D)     layer 2 (PlayerBody), mask 1 (World)
├── Sprite2D                 the knight
├── CollisionShape2D         sized to his feet, not his body
└── WeaponPivot (Node2D)
    └── WeaponSprite         points right at rotation 0
```

`scripts/PlayerController.gd` — movement, correct diagonals, mouse aiming, and a
defensive guard on `move_and_slide()`.

`Main.tscn` — a plain walled test room (640×360 interior) with the player
instanced in the middle. Somewhere to walk, and something to time a crossing
against.

## The three ideas

**1 · The collision shape follows where he stands, not where he's drawn.**
Top-down sprites are drawn as if you're looking slightly down at them, so his head
sits further "up" the screen than he actually is in the world. Match the collision
to the sprite and he bumps into things that visibly look like they're behind him.

**2 · Only normalize when the vector is longer than 1.**

```gdscript
return v.normalized() if v.length() > 1.0 else v
```

Pressing two keys adds two arrows and gets you one that's ~1.41 long — that's the
diagonal-speed bug, and it's the default, not something you introduce. But calling
`normalized()` unconditionally stretches a *half-pushed analog stick* up to full
length, so a gentle push becomes a sprint. Normalize only when it's too long.

**3 · Aiming is not a movement concern.** The moment you separate them you get a
game where you can walk backwards while attacking forwards — and that one decision
is why the dash can be defensive later, why a long thin spear works, and why
ranged enemies become a positioning problem instead of a chase.

## Two details worth keeping

The **4px deadzone** on the sprite flip. Without it, when the mouse sits on top of
him `to_mouse.x` flickers either side of zero and he strobes left-right every
frame.

The **`_finite()` guard** looks like paranoia today and it is. But knockback
arrives in chapter 2, and one bad number turns `velocity` into NaN — at which
point `move_and_slide()` spams *"Vector2 cannot be normalized"* into your console
forever with no line number and no stack trace. Four lines now, and it can never
happen.

## The number that actually matters

`move_speed = 180.0` is meaningless on its own. 180 px/s is fast in a small room
and slow in a big one. **The number that matters is "about one second to cross the
room"** — that's a feeling, and it's the same feeling at any resolution, in any
room, in any game. Every number in this course gets picked that way: not *what's
the value*, but *what should it feel like, and what value gets me there.*

## Your turn

Change `move_speed` until crossing **your** room takes about a second. Time it,
don't guess. Your number won't be 180 and it shouldn't be — if your room is twice
the size, your speed is roughly twice mine. Speed is a ratio, not a number.

## Run it

`project.godot` now points `run/main_scene` at `res://Main.tscn`, so **F5** drops
you into the test room. There's no camera yet — that's lesson 1.4, and until then
the view is fixed. Walk around, watch the weapon track the mouse, and time a
crossing.

> The test room here is 640×360. `move_speed = 180` crosses it in about three and
> a half seconds, *not* one — which is exactly the point of the exercise below.
> The number that's right for your room is the one you measure, not the one you
> copy.

## If it goes wrong

| Symptom | Cause |
|---|---|
| He doesn't move at all | Inputs not named, or you're in `_process` not `_physics_process` |
| Weapon points the wrong way | Placeholder sprite is drawn pointing up; it needs to point **right** at rotation 0 |
| Sprite strobes | Deadzone missing from `_update_aim` |
| He slides along walls oddly | Collision shape is too big — size it to his feet |

## Next

```bash
git checkout lesson-1.2   # the dash
git diff lesson-1.1 lesson-1.2
```
