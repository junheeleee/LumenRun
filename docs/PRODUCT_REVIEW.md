# Lumen Run Product Review

## 2026-05-16 Completion Gap Review

### Current Strengths
- Core one-touch orbit concept is easy to understand.
- Three-depth orbit movement gives the game more shape than a simple two-lane runner.
- Fever, shield, slow-time, music, start screen, localization, and device testing foundations exist.
- The project is now organized for GitHub, QA, build notes, balance, and IP tracking.

### Main Gaps Before App Store Quality
- Social comparison is missing. Current best score is local only, so players cannot compare with friends or global rankings.
- Long-term progression is thin. Players need unlocks, achievements, or challenge goals beyond beating a personal score.
- Post-game motivation needs more punch. The game-over screen should make the player want one more run.
- Content variety is still limited. More obstacle patterns, item timing, fever moments, and visual setpieces are needed.
- IP expression needs stronger consistency across player object, obstacles, items, music, app icon, and store screenshots.
- Difficulty needs measured tuning through repeated playtests, not only intuition.

### Recommended Feature Priorities
1. Game Center leaderboard for high score.
2. Achievement set for score milestones, fever streaks, shield saves, and daily return behavior.
3. Better post-game results screen with best score delta, rank prompt, retry, and achievement progress.
4. Daily or weekly challenge mode with fixed seed/rules.
5. Cosmetic unlocks: core skins, orbit trails, fever colors, badges.
6. Stronger obstacle pattern system with named pattern types rather than purely random spawns.
7. App Store polish pack: icon, screenshots, subtitle, keywords, support URL, privacy answers.

### Management Questions To Ask Before Implementation
- Should online comparison use Apple Game Center first?
- Should rankings be global only, friends only, or both?
- Should the first release include achievements, or should achievements ship after the leaderboard?
- What cosmetic reward fits the IP best: core skins, trails, orbit rings, or titles?
- Should daily challenge be a launch feature or a post-launch retention update?

## 2026-05-22 First Beta Midpoint Review

### Current Strengths
- The game now has a fuller loop: stages, relay cards, fever, items, achievements, daily missions, rewards, localization, and Game Center groundwork.
- The simple one-touch control still gives the game a strong mobile-friendly foundation.
- Stage clears and relay cards give the run a roguelike rhythm.
- The object system is deep enough to create patterns and long-term variety.

### Main Beta Risk
- The game is now at risk of becoming hard to read. More objects and systems are valuable only if players can understand them instantly.
- The object guide is not enough. The run itself must teach collect, danger, and disrupt roles through shape, animation, color, and feedback.

### Updated Beta Priorities
1. Object readability redesign: collect/danger/disrupt visual grammar.
2. Stage teaching order: basic rhythm first, pulse at stage 3, void at stage 5.
3. Pattern pass for pulse, void, and safe-lane gates.
4. Real-device performance soak after adding moving hazards and visual telegraphs.
5. Relay card clarity and build feedback.
6. Daily mission and achievement target tuning.
7. Start/reward/game-over polish for friend beta.

### Decision
- Treat object readability as the next highest-priority beta blocker.
- Do not add more object types until the current object set can be read without memorization.
