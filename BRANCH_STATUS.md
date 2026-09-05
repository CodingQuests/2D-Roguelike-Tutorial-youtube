# Branch status

All 29 lesson branches exist. They are **not all at the same fidelity yet**, and
this file says exactly which is which so nobody is misled.

There are two states a lesson branch can be in.

**🟢 Sliced** — the code on the branch is the project as it actually stood at the
end of that lesson, reconstructed line by line from the lesson script. Checking it
out gives you a smaller project than `main`: files that don't exist yet aren't
there, and files that do exist are in their earlier form.

**🟡 Pending** — the branch exists and its `LESSON.md` is accurate (what the lesson
builds, which files it touches, the ideas and the gotchas), but **the code mirrors
`main`** — the finished game. It's a working, runnable project; it just hasn't been
cut back to that lesson's state.

Pending branches are deliberately left as the *finished* game rather than a
half-reconstructed one. A working project plus honest docs is more useful than a
broken intermediate that won't open.

---

## Status

| Branch | Lesson | Status |
|---|---|---|
| `lesson-0.1` | The whole game, and why we build it backwards | 🟢 Sliced |
| `lesson-1.1` | Move and aim | 🟢 Sliced |
| `lesson-1.2` | The dash | 🟢 Sliced |
| `lesson-1.3` | The frames that make a dodge work | 🟢 Sliced |
| `lesson-1.4` | A camera that doesn't fight you | 🟢 Sliced |
| `lesson-2.1` | Something that can be hurt | 🟢 Sliced |
| `lesson-2.2` | Who checks whom | 🟢 Sliced |
| `lesson-2.3` | Three bugs and no errors | 🟡 Pending |
| `lesson-2.4` | The swing | 🟡 Pending |
| `lesson-2.5` | Make the hit land | 🟡 Pending |
| `lesson-3.1` | One enemy, off one script | 🟡 Pending |
| `lesson-3.2` | Telegraphs | 🟡 Pending |
| `lesson-3.3` | Four enemies from the same base | 🟡 Pending |
| `lesson-3.4` | A boss with a tell | 🟡 Pending |
| `lesson-3.5` | The room knows the fight is over | 🟡 Pending |
| `lesson-4.1` | A room built in code | 🟡 Pending |
| `lesson-4.2` | Why random rooms are boring | 🟡 Pending |
| `lesson-4.3` | A floor of connected rooms | 🟡 Pending |
| `lesson-4.4` | Knowing where you are | 🟡 Pending |
| `lesson-5.1` | The reward moment | 🟡 Pending |
| `lesson-5.2` | Power that costs you something | 🟡 Pending |
| `lesson-5.3` | Items you own, not stats you bump | 🟡 Pending |
| `lesson-5.4` | Gold, shops and the deal you shouldn't take | 🟡 Pending |
| `lesson-6.1` | A HUD that shows less | 🟡 Pending |
| `lesson-6.2` | Dying properly | 🟡 Pending |
| `lesson-6.3` | Unlocks that widen, not unlocks that inflate | 🟡 Pending |
| `lesson-7.1` | The shell | 🟡 Pending |
| `lesson-7.2` | Sound is half the game | 🟡 Pending |
| `lesson-7.3` | The polish pass, and shipping it | 🟢 Final — *is* `main` |

**7 sliced · 21 pending · 1 final.**

---

## Why chapters 0–2 and not the rest

The chapter 1 and 2 lesson scripts carry their code cumulatively — 1.1 has *"the
complete file at the end of this lesson"*, 1.2 and 1.3 have *"code added this
lesson"*. That's a complete, unambiguous record of the project state at each of
those points, so those branches are reconstructions of a real thing rather than
guesses.

From 2.3 onward the lesson scripts carry the code that gets **typed on camera**
(3–15 blocks each) but not a cumulative snapshot of the whole project. Rebuilding
those states means deciding a hundred small things the scripts don't pin down —
and every one of those decisions is a chance for the repo to disagree with the
video.

There's a second reason, and it's the stronger one: **most of the 29 lessons haven't
been recorded yet.** The code that ends up on screen is the code that should end up
on the branch. Cutting the slice at record time costs nothing extra and is exact by
construction; cutting it now guarantees drift.

---

## Cutting a pending branch

After recording a lesson, with the Godot project in exactly the state the video
ends on:

```bash
# from the game project folder, on the previous lesson's branch
git checkout lesson-2.2
git checkout -b tmp-2.3

# copy in the recorded project state, then:
git add -A
git commit -m "Lesson 2.3 - The swing"

# replace the pending branch
git branch -D lesson-2.3
git branch -m lesson-2.3
git push --force-with-lease origin lesson-2.3
```

`08_Scripts/snapshot-lesson.ps1` in the production repo wraps this up as
`.\snapshot-lesson.ps1 2.3`.

Then move the row in this table to 🟢 and push `main`.

---

## Known reconstruction decisions

Things the lesson scripts didn't pin down, decided one way on the sliced branches:

- **`Main.tscn` is a reconstruction.** The chapter 1 scripts refer to "the room"
  and to obstacles without specifying them, so the sliced branches carry a plain
  walled test room (640×360 interior) with two pillars. Lesson 1.4 needs a room
  scene to hold the camera, so something had to exist.
- **`move_speed = 180` doesn't cross that room in one second** — it takes about
  three and a half. The "one second to cross" figure is the *feeling* the lesson
  asks you to tune toward, and lesson 1.1's `LESSON.md` says so explicitly.
- **Collision shapes match the finished game.** Lesson 1.1 says "capsule"; the
  shipped `Player.tscn` uses a `CircleShape2D` of radius 7. The sliced branches use
  the shipped geometry so that diffs between lessons show only real lesson content,
  never cosmetic churn.
- **Layer names are added in `project.godot` at lesson 2.2**, because lesson 2.2
  teaches naming all eight up front. The shipped project never named them, so they
  disappear again at `lesson-7.3` (which is `main` exactly). Worth adding the block
  to the real project — it's free and it makes every inspector dropdown readable.
- **`Hazard` and `Dummy` are teaching throwaways** that exist only on the sliced
  branches. They aren't in the finished game. Lesson 1.3 explicitly says to keep the
  hazard and disable it rather than delete it.

## Not verified in-engine

**Godot isn't installed on the machine these branches were built on**, so none of
the sliced branches have been opened in the editor or run through
`godot --headless --path . --import`. They were reconstructed by reading, and the
GDScript came verbatim from the lesson scripts, but *"it parses and runs"* is
unproven. Worth doing that pass before the repo goes public:

```bash
godot --headless --path . --import
godot --headless --path . res://Main.tscn --quit-after 300
```

on each 🟢 branch, grepping stderr for `error|warning|invalid|leaked`.
