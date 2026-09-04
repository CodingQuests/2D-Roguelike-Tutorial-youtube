# Lesson 2.2 — Who checks whom

**Chapter 2 · Make Hitting Something Feel Good · Q2 Combat**

**Ends with:** a hitbox that hurts the dummy and physically cannot hurt the
player — with no team-check code anywhere.

**Starts from:** `lesson-2.1`.

---

## What this lesson built

`scripts/HitboxComponent.gd` — deals damage. Completely passive.
`scripts/HurtboxComponent.gd` — receives damage. The active detector.

Plus: the i-frame flag migrates off the player, knockback lands on both bodies,
and the eight collision layers get named in `project.godot`.

## The rule, in one sentence

> **The thing that can be hurt does the checking. The thing that hurts you just
> sits there carrying a number.**

The obvious question in any collision system is *who checks?* — does the sword
look for enemies, or do enemies look for swords? Most projects answer **both**,
usually by accident. Then hits land twice, you fix it with a flag, the flag
doesn't reset properly, and you're three hours into debugging something that
should have been a rule.

One direction, always. Commit to it and the question never comes up again — not
for the sword, not for enemies, not for projectiles, not for the whirlwind in
chapter 5.

Look at `HitboxComponent`: no `_process`, no signals it listens to. It's a label
with a number on it.

## Friendly fire is solved by layers, not by code

The tempting fix is a team check — `if target.team != my.team`. **Don't.** Now
every hitbox needs a team, every hurtbox needs a team, and every new thing you add
has to remember to set one. One day something won't, and it'll hit you, and there
will be no error.

The engine already does this for you:

| Bit | Name | Value |
|---|---|---|
| 1 | World | 1 |
| 2 | PlayerBody | 2 |
| 3 | EnemyBody | 4 |
| 4 | PlayerHurtbox | 8 |
| 5 | EnemyHurtbox | 16 |
| 6 | PlayerHitbox | 32 |
| 7 | EnemyHitbox / projectiles | 64 |
| 8 | Pickups | 128 |

| Node | Layer | Mask |
|---|---|---|
| Player's Hurtbox | PlayerHurtbox (8) | **EnemyHitbox (64) only** |
| Player's AttackHitbox | PlayerHitbox (32) | *none — it's passive* |
| Enemy's Hurtbox | EnemyHurtbox (16) | **PlayerHitbox (32) only** |
| Enemy's AttackHitbox | EnemyHitbox (64) | *none* |

The player's hurtbox masks bit 7 and **only** bit 7. His own sword is on bit 6. As
far as the physics engine is concerned those two objects exist in different
universes. The overlap isn't detected and rejected — **it never happens at all.**

> You're not writing code that decides who to ignore. You're arranging things so
> the question is never asked.

## Hit once per swing

Hold a hitbox inside a target and it damages once per *frame* — one swing, eleven
hits. So the hitbox remembers who it's already hit and clears the list when a new
swing starts.

```gdscript
if area.has_method("try_register_hit"):
    if not area.try_register_hit(self):
        return
```

The hurtbox still doesn't know what a hitbox *is*. It asks *"do you have this
method?"* and if so asks permission. That's what keeps them decoupled.

## The i-frame flag moves — two lines

Chapter 1 put `invulnerable` on the player because there was nothing else to put
it on. Now there is:

```gdscript
hurtbox.invulnerable = true     # in _start_dash
hurtbox.invulnerable = false    # in _end_dash
```

**This is the arrow from lesson 1.3, pointing the right way.** The dash *sets* it,
the damage system *reads* it. The dash doesn't know what damage is and the damage
system doesn't know what a dash is — which is why chapter 5's blink ability grants
invincibility in one line and touches nothing.

`Hazard.gd` was updated to ask the hurtbox too.

## Knockback, and the guard that was waiting for it

```gdscript
if dir.length() < 0.01:
    dir = Vector2.RIGHT.rotated(randf() * TAU)
```

That random fallback is for when something spawns exactly on top of you: direction
is zero, you can't normalize a zero vector, and you get NaN — **exactly the crash
the `_finite()` guard in lesson 1.1 was put there to catch.** `_knockback` is now
a live channel other systems write to; that's the variable it was guarding.

`KNOCKBACK_TAKEN = 0.6` — the player takes about two thirds of the shove an enemy
would. Hits on *you* still need to register, but being flung across the room every
time something touches you feels awful.

> The hurtbox asks `has_method("apply_knockback")`, so a body without it doesn't
> error — **it silently does nothing.** Both bodies have it here.

## Your turn

Give the **dummy** a `HitboxComponent` so it can hurt the player. Layer 7
(EnemyHitbox), and **no code changes anywhere.** If you got it working purely by
ticking boxes in the inspector, you've understood the lesson.

## If it goes wrong

| Symptom | Cause |
|---|---|
| **Nothing is detected at all** | The Area2D has no `CollisionShape2D`. It fails **completely silently** — no error, no warning. Check this first, always |
| Hurtbox detects nothing | Its **mask** doesn't include the hitbox's **layer**. Layer = what I am, mask = what I look for |
| Still hitting yourself | Player hurtbox mask includes bit 6. It should only be bit 7 |
| Damage still stacks | `try_register_hit` isn't wired, or `reset_hits()` is called every frame |
| `area.damage` errors | The overlapping area isn't a HitboxComponent — the group check is missing |

## Next

```bash
git checkout lesson-2.3   # the swing — and it's going to feel terrible
git diff lesson-2.2 lesson-2.3
```
