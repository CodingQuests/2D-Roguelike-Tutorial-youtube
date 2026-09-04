# Lesson 2.1 — Something that can be hurt

**Chapter 2 · Make Hitting Something Feel Good · Q2 Combat**

**Ends with:** a test dummy that takes damage, drops to zero, and tells the world
it died.

**Starts from:** `lesson-1.4`.

---

## What this lesson built

`scripts/HealthComponent.gd` — the first **component**. About fifty lines that go
on the player, every enemy, and every barrel.

`scenes/Dummy.tscn` + `scripts/Dummy.gd` — a temporary thing to hit, dropped into
`Main.tscn`.

## Why it's a node and not a variable

The obvious move is `var health = 100` on the enemy. Thirty seconds, done. And it
works completely fine until you have a *second* thing that can be hurt. Then a
third. Then something that heals. Then a boss with a different max. By the time
you notice, you've got health logic in five places and they've all drifted
slightly apart.

What you want instead is **one small thing that knows a number and how to change
it**, that everything else in the game talks to. The player has one. The enemy has
one. The barrel has one. Same script, no copies.

That's a **component** — a node whose whole job is one capability, that you attach
to things. It's the pattern the entire rest of this course is built on, and this
is the first one.

`extends Node`, not `Node2D`. It has no position, it isn't anywhere in the world.
It's just a fact about its parent.

> **The name matters.** Every single thing in this game that can be hurt has a
> child called `Health`, spelled exactly that way. That consistency is what lets
> other systems find it without being told where it is.

## Clamping belongs inside the component

A health component that lets you go negative or overheal isn't a health component,
it's a variable with extra steps. Three guards, all inside:

```gdscript
if current_health <= 0.0:
    return                                   # can't kill something twice
amount = maxf(0.0, amount)                   # negative damage can't heal you
current_health = maxf(0.0, current_health - amount)
```

The second one is the bug you get the first time an upgrade multiplies something
by a negative number.

## The signal is the actual lesson

If the HUD needs to update on damage, the naive fix is to make `HealthComponent`
know about the HUD. Then the death screen. Then the sound system. Then corruption.
That's a component that knows about the entire game.

**A signal flips the arrow round.** The component announces *"I took 9 damage, I'm
on 41 of 100"* and doesn't know or care who's listening. The HUD listens. The
audio manager listens. Nothing ever has to be wired into this file again.

> The component shouts. Other things choose to hear it.

Look at `Dummy.gd`: it contains no health logic at all. It connects one signal and
calls `queue_free()`.

## Two methods that exist for later

`set_max_health(value, keep_ratio)` — chapter 5's Bulwark upgrade raises your
ceiling and chapter 5's altar **lowers** it. `keep_ratio` is the interesting half:
raising max HP by 25 while keeping the *ratio* heals you a bit, keeping the
*absolute* doesn't. Those are different game feelings and the caller should
choose.

`get_ratio()` — because **the HUD needs a fraction, not a number.** A health bar
doesn't care that you're on 41, it cares that you're at 41%.

## Your turn

Put a `HealthComponent` on the **player**, connect `died`, print something when he
dies. Same node, same script, different entity, **zero new code** — that's the
whole argument for building it this way.

*(This branch deliberately leaves the player without one so the exercise is still
there to do. Lesson 2.2 adds it for real, because the hurtbox needs a sibling
`Health` to talk to.)*

## The half-answer

*"Why is this a node and not just a variable?"* — you've had half an answer. The
other half doesn't arrive until chapter 5, when corruption needs a **single** place
that all incoming damage flows through. Hold that thought.

## If it goes wrong

| Symptom | Cause |
|---|---|
| `$Health` is null | Child node isn't named exactly `Health` |
| `died` fires twice | The `if current_health <= 0.0: return` guard is missing |
| Signal never fires | You emitted before changing the value, or forgot `.emit()` |
| `class_name` error | Another script already uses that name — Godot enforces uniqueness |

## Next

```bash
git checkout lesson-2.2   # hitbox, hurtbox, and no friendly-fire code
git diff lesson-2.1 lesson-2.2
```
