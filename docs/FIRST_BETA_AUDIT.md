# Lumen Run First Beta Audit

Date: 2026-05-22

This audit defines what Lumen Run still needs before a first friend-facing beta. The target is not App Store release yet. The target is a build that feels coherent, readable, stable, and interesting enough for repeated outside playtests.

## Current Verdict

Lumen Run is past prototype. It has a real loop: one-touch orbit control, stages, fever, items, achievements, daily missions, rewards, localization, sound, Game Center groundwork, and a clearer IP direction.

It is not yet first-beta complete because the game is now adding depth faster than it teaches that depth. The biggest risk is no longer "too simple"; it is "too many objects and systems without enough instant readability."

## Beta Standard

The first beta should satisfy these five conditions:

- A new player understands what to collect and what to avoid without opening the object guide.
- Stage 1 teaches the game safely, then later stages add danger and build variety.
- Runs feel meaningfully different through stage layouts, relay cards, and object mixes.
- The app looks like one authored game, not a collection of generated mockup parts.
- A real iPhone can survive longer runs without stutter, invisible player states, stuck overlays, or broken audio.

## Priority 0: Beta Blockers

These should be fixed before showing the game broadly.

### 1. Object Readability

Problem:
- There are now many object types: spark, surge, shield, slow, magnet, bomb, shard, pulse, void.
- A new player cannot reliably know which are good, dangerous, or disruptive by looking at them once.
- The object guide helps after the fact, but it is not an intuitive in-run teaching system.

Required direction:
- Good objects must share a clear visual language: bright core, soft glow, stable shapes, inviting motion.
- Dangerous objects must share a clear visual language: sharp silhouettes, black X/crack marks, warning pulse, aggressive glow.
- Disruptive objects must share a third language: translucent purple, barrier/field shape, combo-break feedback, not death-like.
- Stage 1 should show only the core language first: spark, shield, maybe surge.
- New object categories should be introduced gradually with visual telegraphing.

Concrete tasks:
- Redesign in-run object shapes around three categories: collect, danger, disrupt.
- Add a small pre-spawn warning pulse for pulse/void the first time they appear in a run.
- Add a short "new object" non-blocking hint the first time pulse and void appear, then never spam it.
- Update object guide only after in-run readability is solved.

Progress:
- 2026-05-22: Started the visual role pass. Collect objects now share a bright core, danger objects share black X/warning language, pulse gets stronger danger markings, and void keeps a distinct purple disruptor arc.
- 2026-05-22: Added a staged teaching pass. Stage 1 now stays focused on sparks, shield, and basic shards; Stage 2 introduces utility pickups; Stage 3 introduces pulse; Stage 5 introduces void with non-blocking first-appearance hints.

Acceptance:
- A first-time player can correctly guess "collect", "avoid", or "combo hazard" from the object silhouette and color within one second.

### 2. Stage Pacing and Teaching

Problem:
- Stages exist, but the player still needs clearer reason to care about each new stage.
- More objects should not simply mean more chaos.

Required direction:
- Stage 1: teach orbit rhythm, sparks, shield, basic shard.
- Stage 2: introduce reward routes and surge/magnet utility.
- Stage 3: introduce pulse as the first moving hazard.
- Stage 5: introduce void as a combo-disrupting orbit blocker.
- Stage clear should feel like "I survived a chapter", not just a pause.

Concrete tasks:
- Define a stage object unlock table.
- Ensure new stage hazards appear first in simple, readable placements.
- Add route identity cues that are visual, not long text.
- Keep stage intervals long enough for a stage to feel earned.

Acceptance:
- A new player can reach stage 2 and explain what changed.
- An experienced player can reach stage 3 and feel a new pattern, not only higher speed.

Progress:
- 2026-05-22: Started the stage identity pass. New stage intros now show route descriptions, Stage 3 opens with Pulse Chase, Stage 5 opens with Void Trap, and stage restarts now use the stage's intended opening pattern instead of defaulting back to flow.

### 3. Performance Stability

Problem:
- The game has had stutter history around fever, magnet, respawn, and visual effects.
- New moving hazards and more effects increase risk.

Required direction:
- Limit particle/effect counts aggressively.
- Keep moving hazards cheap: update only simple position/userData.
- Avoid spawning too many nodes during fever or magnet chain collection.

Concrete tasks:
- Run a 5-minute real-device soak test after object readability changes.
- Watch fever + magnet + stage clear + pulse/void in one run.
- Keep effectLayer and objectLayer trimming limits conservative.

Acceptance:
- A real iPhone can play for 5 minutes without severe stutter.
- Player never remains tiny, transparent, hidden, or stuck after retry.

Progress:
- 2026-05-22: Added a conservative SpriteKit effect budget pass. Fever now uses lower effect/object node limits, transient nodes are trimmed more frequently, magnet chain-collection feedback is throttled harder, and fever burst beams are capped to reduce frame spikes during dense moments.
- 2026-05-22: Added batched magnet spark collection. Magnet captures now process up to 4 sparks per frame and update score, missions, achievements, best score, and upgrade checks once per batch instead of once per spark.
- 2026-05-22: Throttled normal spark collection feedback. Consecutive spark pickups now share lighter visual, haptic, flash, and lumen sound cadence so score trails do not spawn full feedback every pickup.
- 2026-05-22: Merged Fever spark scoring into the spark collection path. Fever spark pickups no longer call both collectSpark and collectFeverHit separately, reducing duplicate published state updates during high-speed Fever collection.
- 2026-05-22: Added throttled HUD stat publishing. Internal score, combo, multiplier, and level now update immediately for game logic, while displayed HUD values publish at a short cadence to reduce SwiftUI invalidation during dense score chains and Fever.
- 2026-05-22: Removed the Glitch Device +40 starting score because it made runs appear to start at an unexplained non-zero score. The device now stays as a high-risk Stage 1 pulse-shard modifier.

## Priority 1: Gameplay Depth

### 4. Relay Card Quality

Problem:
- The roguelike card layer exists, but card choices can feel abstract if the result is not visible.

Required direction:
- Cards should alter the next run segment enough that the player feels a build forming.
- Risk cards need clearer downside preview.

Concrete tasks:
- Add stronger selected-card feedback in HUD.
- Group cards by build fantasy: safety, score, fever, control, risk.
- Reduce repeated card patterns.
- Tune card frequency after stage pacing is stable.

Acceptance:
- After choosing a card, the player can feel or see its effect within the next stage.

Progress:
- 2026-05-22: Added role tags to relay cards so choices read as safety, control, score, fever, or high-risk at a glance. Risk cards now show a short warning line to make the tradeoff clearer.
- 2026-06-01: Added start-module build links and biased the first route-clear module choices toward the selected start module, so early choices begin forming a readable build path.

### 5. Pattern Variety

Problem:
- Current patterns are better than random spawning, but beta players need a stronger sense of route variety.

Required direction:
- Each stage route should have a recognizable pattern identity.
- Patterns should create skill questions: stay, switch, chase, delay, risk.

Concrete tasks:
- Add at least one "safe lane gate" pattern with clear telegraph.
- Add one "moving hazard chase" pattern for pulse.
- Add one "combo trap" pattern for void.
- Make reward routes readable before they become punishing.

Acceptance:
- A player can describe at least two different route types after a few runs.

Progress:
- 2026-05-22: Added stronger non-text route telegraphs. Gate waves now mark the safe lane and blocked lanes separately, pulse chase marks both the chase lane and reward lane, and void trap marks the safe lane versus combo-blocking lane before objects resolve.
- 2026-06-01: Added route-specific pattern variants: Stage 3 Pulse Slalom, Stage 4 Gate Corridor, and Stage 5 Void Split Trap so the mid-run routes ask more distinct skill questions.

## Priority 2: Motivation and Retention

### 6. Achievements and Daily Missions

Status:
- Achievement count expanded to 20.
- Daily mission variety expanded to score, sparks, fever, shields, combo, stages, surges, bombs.

Remaining risks:
- Some achievements may be too hidden if progress feedback is not visible.
- Daily missions need to feel achievable in normal play, not like chores.

Concrete tasks:
- Review daily mission target ranges after 10 device runs.
- Show mission progress clearly on game over.
- Make reward progress feel satisfying on start/reward screens.

Acceptance:
- A player sees one realistic short-term goal before starting another run.

Progress:
- 2026-06-01: Improved the mission/reward loop visibility. Daily mission panels now show today's completion count plus a next-reward progress bar, and game-over reward prompts now consider both themes and core skins instead of only themes.

### 7. Social Comparison

Status:
- Game Center groundwork exists.
- Full leaderboard availability depends on App Store Connect setup.

Concrete tasks:
- Keep local best and run records polished for free/dev builds.
- Once paid developer setup is available, verify leaderboard button opens the exact high-score leaderboard.

Acceptance:
- Beta testers can at minimum compare local best/run history.
- App Store/TestFlight path can later activate Game Center without redesigning the results flow.

## Priority 3: Presentation Polish

### 8. Start, Loading, Icon, and IP Cohesion

Problem:
- The IP direction is clearer, but the whole app still needs a final pass so it feels authored.

Required direction:
- The first screen, app icon, in-game core, orbits, hazards, and rewards should all speak the same "lumen relay vs glitch collapse" language.

Concrete tasks:
- Review icon at small size against start/loading logo.
- Make start screen shorter and more action-focused.
- Keep rewards/shop separate from the main start CTA.
- Ensure object colors match the IP bible.

Acceptance:
- A tester can recognize the game from icon, title, and in-run visuals as one coherent product.

### 9. Audio Feedback

Problem:
- Audio exists, but object growth means feedback needs more semantic clarity.

Concrete tasks:
- Ensure collect, surge, shield, bomb, shard crash, pulse crash, void combo break, fever start, and fever loop sound distinct.
- Confirm mute disables every effect and music path.

Acceptance:
- Players can tell "good pickup", "danger hit", and "combo disrupted" by sound.

### 10. UI and Localization

Problem:
- More systems increase screen density.

Concrete tasks:
- Check achievements, daily missions, rewards, game over, object guide, and card screens on small iPhones in Korean.
- Avoid long tutorial text that truncates into ellipses.
- Keep stage/card text short and functional.

Acceptance:
- No important Korean or English UI text is truncated in core beta screens.

## Working Order

Recommended next tasks:

1. Object readability redesign for collect/danger/disrupt categories.
2. Stage unlock/teaching table for spark/shard/surge/magnet/pulse/void.
3. Pulse/void first-appearance telegraph and non-blocking hint.
4. Pattern pass: one pulse pattern, one void pattern, one safe-lane pattern.
5. 5-minute real-device performance soak.
6. Daily mission and achievement target tuning after real play.
7. Start/rewards flow polish.
8. Audio semantic pass.
9. Korean/English small-screen text QA.
10. Friend beta handoff checklist.

## First Task To Start

Start with object readability. It has the highest leverage because it affects onboarding, fairness, stage difficulty, IP polish, and player trust at the same time.

## Progress Log

### 2026-05-22: Runtime Smoothness Pass

Changes:
- Split gameplay timers from SwiftUI display timers so SpriteKit can read exact values without causing per-frame view invalidation.
- Added throttled displayed HUD state for score, combo, multiplier, level, power-up timers, fever progress, and fever active state.
- Power-up timer badges now publish only whole-second display changes instead of every frame.
- Fever backdrop and meter now use displayed fever state instead of raw gameplay timer state.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Real-device run with fever, magnet, and dense spark chains. If stutter remains, profile SpriteKit node/effect work rather than SwiftUI invalidation first.

### 2026-05-22: SpriteKit Effect Load Pass

Changes:
- Removed repeat-forever pulse/spin actions from spawned sparks, power-ups, shards, and pulse hazards.
- Lowered effect and object node budgets during fever.
- Reduced fever spark feedback frequency and particle count.
- Added throttling for fever hazard conversion feedback so chains of collisions do not emit full effects every frame.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Test a longer run on device. If jank persists, capture node count/FPS or profile a fever-heavy segment to find whether the remaining cost is shape rendering, collision iteration, audio/haptics, or state updates.

### 2026-05-22: First-Minute Tempo Pass

Changes:
- Lowered Stage 1 clear target from 80 to 60 so the first upgrade choice arrives sooner.
- Lowered stage score requirement ramp from `170 + 50/level` to `130 + 45/level`.
- Added more Stage 1 opening sparks so the run starts with immediate collection rhythm.
- Added a gentle Stage 1 teaching shard on the outer orbit with a reward spark nearby.
- Enabled a first-stage shard hint when the player first sees the danger object in-run.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- First run should reach the first upgrade choice quickly without feeling like a long tutorial corridor.

### 2026-05-22: Fever Start Hitch Pass

Changes:
- Reused a pre-created `FEVER!` label instead of allocating a new `SKLabelNode` at fever activation.
- Reduced fever start burst rings and beams.
- Removed the SwiftUI full-screen fever backdrop transition so fever activation stays mostly inside SpriteKit.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Trigger fever repeatedly and confirm the hitch is gone or meaningfully reduced at the exact `FEVER!` popup moment.

### 2026-05-22: Stage Identity Pass

Changes:
- Stage 4 now explicitly uses the Gate Pressure route instead of falling through to Overdrive labeling.
- Stage 4 opening now demonstrates the safe-lane gate pattern immediately.
- Stage 3 opening adds a clearer pulse hazard plus reward read.
- Stage 5 opening adds a clearer void blocker plus safe-lane reward.
- Stage 4 pattern rotation emphasizes gate and switchback pressure instead of early overdrive chaos.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Stage 2 should feel like collection, Stage 3 like moving hazards, Stage 4 like safe-lane reading, and Stage 5 like combo disruption.

### 2026-05-22: Stage Clear Feedback Pass

Changes:
- Added a stage clear sound cue using existing time-core and shield effects.
- Added success haptic feedback on stage clear.
- Added a reusable `STAGE N CLEAR` SpriteKit label.
- Strengthened stage clear rings, flash, and center burst before the upgrade choice appears.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Stage clear should now read as a reward moment instead of a sudden pause.

### 2026-05-22: Centered Upgrade Cards

Changes:
- Moved run upgrade cards out of the lower HUD stack into a full-screen centered reward overlay.
- Added a dimmed backdrop and scroll-safe centered layout for smaller screens.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Upgrade cards should feel like a deliberate reward choice, not a bottom-sheet interruption.

### 2026-05-23: Upgrade Build Tags and Stacking

Changes:
- Added upgrade build tags: Shield, Orbit, Fever, Harvest, and Risk.
- Upgrade cards now show their build tag and display `Lv.N > N+1` when picking a previously collected card.
- The upgrade pool now sometimes offers a card matching the current dominant build tag.
- Repeated picks for several core upgrades now scale their effect, including shield, magnet, slow time, score, combo, flow, echo, and phase cards.
- The reward card header now shows the current build focus when a dominant tag exists.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Card picks should begin to feel like a build path instead of three unrelated one-off bonuses.

### 2026-05-23: Stage Personality Tuning

Changes:
- Added per-stage pacing modifiers for threat spawns, spark spawns, power-up timing, pattern waves, and pattern duration.
- Reduced early-stage difficulty pressure while keeping later stages more active.
- Stage 2 now leans harder into Harvest identity with faster spark and utility pickup pacing.
- Stage 3 now leans harder into Pulse Chase with a higher moving-hazard chance.
- Stage 4 now rotates patterns faster and pressures safe-lane reading.
- Stage 5 now gives Void Trap a clearer combo-disruption identity with stage-specific void probability.
- Added static stage signature motifs to the orbit layer so stages have different visual texture, not just different spawn rules.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Stages should feel meaningfully different without becoming visually noisy or unfair.

### 2026-05-23: Object Role Readability Pass

Changes:
- Added a shared small `+` badge to collectible/helpful objects so sparks and power-ups read as safe pickups in motion.
- Added triangular warning frames to lethal shard and pulse hazards so danger is not only communicated by red/orange color.
- Added a purple disruption mark to void blockers so they read as combo-disrupting objects rather than instant-death hazards.
- Kept the changes inside SpriteKit shape overlays to avoid adding new assets or more object types.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- In a fresh run, good pickups should read as safe before reading the guide, while shard/pulse/void should feel visually separate by role.

### 2026-05-23: Risk Card Clarity Pass

Changes:
- Replaced the generic risk warning row with explicit Gain/Cost chips for risk relay cards.
- Added per-card risk summaries for volatile surge, compression gate, unstable fever, chain reactor, single orbit, glitch mode, and meltdown.
- Localized risk tradeoff labels and summaries in Korean and English.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Risk cards should feel like strategic high-reward choices, not mysterious penalty cards.

### 2026-05-23: Game Over Motivation Pass

Changes:
- Added a run feedback panel near the top of the game-over screen.
- The result screen now calls out the run's highlight: new best, deep route, active build, or close attempt.
- Added a short detail line for the strongest selected build, starting choice, or reached stage.
- Added a dynamic next-goal chip for best-score chase, remaining daily missions, reward unlock progress, or next-stage target.
- Localized all new result feedback copy in Korean and English.

Validation:
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- After dying, the result screen should make the next run feel obvious and tempting instead of only reporting score.

### 2026-05-23: IP Terminology Pass 1

Changes:
- Added `docs/IP_BIBLE.md` as the first source of truth for Lumen Run's naming, tone, and visual language.
- Clarified the core IP roles: the player is the Relay Core, Lumen is scattered signal energy, and Glitch is network corruption.
- Standardized key terms across high-visibility Korean and English UI: Lumen Spark, Relay Core, Glitch Shard, Void Gate, Relay Module, Ignition Module, Route, and Oversync.
- Updated loading, start, tutorial, object guide, route intro, upgrade, mission, achievement, record, and game-over copy to use the new terminology.
- Updated `README.md` and `docs/VISION.md` to match the same premise.

Validation:
- `plutil -lint` passed for Korean and English localization files.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Play the first two minutes and confirm the new terminology feels memorable rather than confusing, especially `Relay Core`, `Lumen Spark`, `Glitch Shard`, and `Oversync`.

### 2026-05-23: IP Visual Mark Pass 1

Changes:
- Regenerated the app icon around the Relay Core plus three route rings instead of the older atom-like orbit mark.
- Added the same role grammar to the icon mark: Lumen Spark `+` badge, Glitch Shard warning frame, and Void Gate broken-signal mark.
- Reworked the loading/start brand mark in SwiftUI to match the icon's route-ring and Relay Core identity.
- Updated object guide icons so collectible, lethal, and disruptive objects use the same visual grammar as the in-game SpriteKit objects.
- Added brand mark rules to `docs/IP_BIBLE.md` for future visual changes.

Validation:
- `swift scripts/generate_app_icon.swift` regenerated a 1024x1024 app icon.
- `sips -g pixelWidth -g pixelHeight LumenRun/Assets.xcassets/AppIcon.appiconset/AppIcon.png` confirmed 1024x1024 output.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- On device, check the home-screen icon, loading screen, start screen, and object guide together. They should now feel like one IP system rather than separate mockup pieces.

### 2026-05-23: IP Audio Pass 1

Changes:
- Added `scripts/generate_sounds.swift` so Lumen Run's sound set is reproducible and internally consistent.
- Regenerated background music, Oversync music, collect pings, shield/time/glitch sounds, and core UI sounds with a fast synthetic signal tone.
- Added three dedicated cues: run ignition (`start.wav`), relay module lock-in (`module.wav`), and route clear (`stageclear.wav`).
- Wired start run, start module selection, relay module selection, and stage clear to their dedicated cues.
- Added audio language rules to `docs/IP_BIBLE.md`.

Validation:
- `swift scripts/generate_sounds.swift` regenerated the WAV set.
- `afinfo` confirmed the new `background.wav`, `start.wav`, `module.wav`, and `stageclear.wav` files are valid WAV assets.

Next check:
- On device with sound enabled, test the first run start, first module pick, spark collection, Oversync transition, and route clear. The game should feel more like a single SF signal-run IP rather than mixed placeholder effects.

### 2026-05-23: Start And Route Transition Pass

Changes:
- Added a loading boot halo and three-step boot sequence so the app feels like the Relay Core is being ignited before play.
- Reworked the start hero with a route scan sweep, animated Relay Core halo, and compact core/route/signal status rail.
- Expanded the route-entry toast with a linking meter so new stages feel like route transitions rather than plain notifications.
- Reworked the route-clear module screen header to show a clear → module → next-route flow before the player chooses a relay module.
- Replaced hardcoded SpriteKit `FEVER!` and `STAGE CLEAR` labels with localized `OVERSYNC` and `ROUTE CLEAR` language.

Validation:
- `plutil -lint` passed for Korean and English localization files.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Test without sound first: loading, start, route clear, relay module selection, and next-route entry should read as one continuous ritual instead of separate UI popups.

### 2026-05-23: Start Screen Simplification Pass

Changes:
- Removed the full tutorial row group, core object primer, and daily mission panel from the main start screen.
- Kept only a compact three-chip briefing for tap, spark, and Oversync so the start screen stays focused on ignition and play.
- Moved the daily mission panel into the rewards screen, keeping progression visible without crowding the first screen.
- Left rewards and object guide as secondary actions instead of first-screen content blocks.

Validation:
- `plutil -lint` passed for Korean and English localization files.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Start screen should now feel like a clean launch surface: title, identity mark, short hint, play button, then secondary actions only.

### 2026-05-23: Start Background Clarity Pass

Changes:
- Hid the live SpriteKit game scene behind loading and start screens, removing the double-orbit visual conflict.
- Added a dedicated static start-screen backdrop using the selected theme gradient, faint signal lines, and a soft center glow.
- Removed the extra signal-field layer from the start hero so the central brand mark is the only strong orbit element on the screen.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Start screen should now feel calmer: one main Relay Core mark, no visible gameplay orbit moving behind it.

### 2026-05-23: HUD Relay Cockpit Pass

Changes:
- Reframed the in-game score area as a Relay Score panel with the core mark, current score, and best score in one cockpit-style cluster.
- Grouped pause, achievements, and settings into a compact action cluster so controls no longer compete with scoring information.
- Replaced plain text status pills with route, goal, level, and multiplier chips using the same color language as the IP objects.
- Restyled the Oversync gauge and active power-up timers to read as small instruments instead of loose labels.

Validation:
- `plutil -lint` passed for Korean and English localization files.
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- On device, check whether the HUD reads faster during play and whether route/goal/Oversync feel like one relay system rather than separate UI labels.

### 2026-05-23: Route Signal Onboarding Pass

Changes:
- Extended the route intro toast so it stays visible long enough to teach the next route without blocking play input.
- Added a compact route-signal preview row showing the key objects for each stage before the route starts.
- Tagged each previewed object by role: collect, power, avoid, or combo risk, so new players can classify objects without opening the guide.
- Added specific preview sets for early learning routes, including Pulse Shard on route 3 and Void Gate on route 5.

Validation:
- `plutil -lint` passed for Korean and English localization files.
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- On a fresh run, route 1 should teach Spark vs Glitch Shard, route 3 should warn about Pulse Shard, and route 5 should make Void Gate read as a combo-risk object instead of instant death.

### 2026-05-23: Route Gameplay Identity Pass

Changes:
- Route 1 now uses a clearer 1-2-3-2 rhythm of Lumen Sparks with slower teaching Glitch Shard pressure, making the first route feel like controlled orbit training instead of random waiting.
- Route 2 now has a dedicated harvest pattern with wider Spark sweeps, more frequent Magnet/Surge rewards, and lighter hazard pressure so it feels like a score-building route.
- Route 3 Pulse Chase pressure now arrives a little faster, making the moving Pulse Shard identity more noticeable after it is introduced.
- Route 4 Gate Pressure now runs gate waves more frequently, pushing the player to read the safe lane rather than treating it like a normal shard route.
- Route 5 Void Trap now places combo-risk blockers more often, making Void Gate feel like its own combo-management rule.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Play routes 1 through 5 and check whether each route can be described in one sentence by feel: learn rhythm, harvest, chase, gate, combo trap.

### 2026-05-23: Relay Module Choice Logic Pass

Changes:
- Reworked relay module generation so the three choices usually serve distinct purposes: route response, current-build synergy, and risk or bonus.
- Added route-specific recommendation pools: route 2 favors harvest tools, route 3 favors protection/control against Pulse Shards, route 4 favors gate-control tools, and route 5 favors combo protection/recovery.
- Avoided recently offered modules as well as recently selected modules, reducing the feeling that the same three cards keep coming back.
- Increased the recent selected-module memory from two picks to three picks.
- Preserved build stacking by allowing the synergy slot to repeat the current dominant build tag when the player is clearly leaning into a build.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- After each route clear, the card trio should feel less repetitive and more like: one answer to the route, one build path, one tempting risk or bonus.

### 2026-05-23: Route 3 Performance Trim

Changes:
- Removed duplicate Pulse Shard warning effects during Route 3 Pulse Chase and first-teaching spawns.
- Shortened active Pulse Shard lifetime in Route 3 so moving hazards do not stack up as heavily.
- Reduced Route 3 static arc motif count and glow cost while keeping the route identity visible.
- Lowered transient effect budgets from Route 3 onward and cleaned effect nodes more frequently.
- Reduced heavy glow widths on large orbit pulse and route-arc warning effects after Route 3 begins.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- On device, reach Route 3 and play for 30-60 seconds. Pulse Chase should still read clearly, but the sudden slowdown around Route 3 should be noticeably reduced.

### 2026-05-23: Dense Fever Magnet Performance Pass

Changes:
- Removed transparent SpriteKit compositing during gameplay and moved the scene background color into SpriteKit, reducing per-frame blend cost under the SwiftUI HUD.
- Batched magnet spark scoring so Fever + Magnet clusters no longer trigger score, sound, mission, and achievement updates every frame.
- Kept player and moving-hazard updates on every frame while throttling only decorative object wobble during dense scoring moments.
- Reduced collect feedback during Fever + Magnet overlap to lightweight burst cues instead of repeated rings, flashes, and power signals.
- Suppressed repeated Magnet refresh sound/effect spam when another Magnet is collected while Magnet is already active.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- On device, intentionally stack Fever + Magnet with many Sparks on screen. Orbit movement should feel closer to stable 60fps, and Magnet chains should no longer produce obvious frame stalls.

### 2026-05-23: Oversync Entry And Direction Cue Pass

Changes:
- Removed the full orbit redraw from the exact Oversync activation frame, avoiding a costly scene rebuild when the mode flips on.
- Simplified the Oversync burst to one clear pulse plus the label, cutting extra beam/ring nodes created at the activation moment.
- Batched nearby hazard conversion scoring at Oversync start so multiple converted hazards no longer each trigger score, sound, mission, achievement, and upgrade checks.
- Added a lightweight next-move chevron on the next orbit/direction so players can read what the next tap will do without opening a guide.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Trigger Oversync during dense play and watch the exact activation moment. The Oversync label should still feel clear, but the spike should be smaller.
- During normal play, the small chevron should make the next orbit/direction readable without feeling noisy.

### 2026-05-25: Claude Review Fix Pass

Changes:
- Fixed the Stage 4 clear header route title so Gate route clears no longer fall through to Overdrive text.
- Replaced the run-upgrade overlay's deprecated `UIScreen.main` sizing with `GeometryReader`.
- Cached frequently reused SpriteKit paths for sparks, shards, pulse hazards, power-ups, and burst motes to reduce repeated CGPath creation.
- Added spawn timestamps to live objects and skipped collision checks for very freshly spawned nodes.
- Tightened transient cleanup cadence during dense Oversync + Magnet scoring and reduced effect glow cost on later-stage rings/shockwaves.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Play a dense Oversync + Magnet run and verify that collision/readability still feels fair while frame spikes are reduced.

### 2026-05-25: Onboarding Visual Teaching Pass

Changes:
- Added a live Oversync countdown in the HUD so players can read fever timing even with sound off.
- Added one-time visual teaching moments for the first Spark pickup and first Oversync activation.
- Limited the first route-clear module choice to two common beginner-friendly options focused on safety or scoring.
- Added role icons and tinted headers to relay module cards so defense, control, scoring, fever, and risk cards separate faster at a glance.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- On device, start a fresh run and confirm that the first Spark, first Oversync, and first route-clear card choice teach the basics without adding extra reading burden.

### 2026-05-25: Oversync End Readability Pass

Changes:
- Added a distinct visual shutdown cue when Oversync ends: cool blue screen wash, player pulse, short orbit-collapse rings, and a brief end label.
- Made the end wash bypass normal flash throttling so it still appears during dense scoring moments.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Test with sound off and trigger Oversync. The end moment should be readable from the playfield itself, not only from the HUD.

### 2026-06-01: Stage Differentiation Pass 1

Changes:
- Increased route identity in the pattern sequence: Harvest, Pulse, Gate, and Void routes now keep their signature pattern dominant instead of rotating back too quickly into generic patterns.
- Added one-time route start signatures so each stage opens with a distinct visual cue before its first object wave.
- Rebalanced random power-up bias by stage: Stage 2 favors Surge/Magnet, Stage 3 favors control and shielding, Stage 4 favors Bomb/Gate survival, and Stage 5 favors Shield/Bomb/Slow recovery.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Play through stages 1-5 and verify each stage has a clearer job: learn rhythm, collect, dodge moving Pulse, read Gate safe lanes, then manage Void disruption.

### 2026-06-01: Difficulty Curve Pass 1

Changes:
- Reduced Stage 1 movement pressure and hazard cadence so the first route gives more room for input learning.
- Kept Stage 2 reward-heavy by preserving fast Spark cadence while slightly extending combo grace.
- Increased Stage 3-5 pressure through tighter pattern cadence, faster hazard cadence, and stronger route pressure instead of changing collision/scoring formulas.
- Increased early threat spacing clearance so hazards are less likely to cluster into unreadable or unfair sequences in the first two stages.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Play from Stage 1 through Stage 5 and verify the curve feels like: learn safely, collect confidently, then start making tighter decisions from Stage 3 onward.

### 2026-06-01: First Run Tutorial Flow Pass

Changes:
- Fixed the first-run flow so choosing a start module no longer marks the tutorial as completed before the player sees it.
- The first session now proceeds as: start screen -> start module choice -> core tutorial/object primer -> gameplay.
- Returning players who have already completed the tutorial still start immediately after choosing a module.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Reset tutorial from settings or install fresh, then verify the first run pauses on the Relay Protocol screen after picking a start module.

### 2026-06-01: Relay Card Strategy Pass 1

Checklist:
- 4/10 - Relay Card Quality.

Changes:
- Added a short build-link line to each start module so players can see whether it leads toward defense, harvest, fever, control, or risk.
- Made the first route-clear module choices bias toward the selected start module's preferred tags while preserving beginner-safe fallbacks.
- Recorded the 4/10 checklist progress under Relay Card Quality.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Start several runs with different start modules and verify the first route-clear choices feel connected instead of random.

### 2026-06-01: Pattern Variety Pass 1

Checklist:
- 5/10 - Pattern Variety.

Changes:
- Added a Pulse Slalom variant that chains a moving Pulse threat into a visible escape lane.
- Added a Gate Corridor variant that repeats a safe-lane gate pattern instead of isolated one-off blocks.
- Added a Void Split Trap variant that marks one safe lane while two void blockers threaten combo continuity.

Validation:
- `git diff --check` passed.
- `xcodebuild -project LumenRun.xcodeproj -scheme LumenRun -destination 'generic/platform=iOS Simulator' build` succeeded.

Next check:
- Play Routes 3-5 and verify Pulse, Gate, and Void routes feel mechanically different, not just faster.
