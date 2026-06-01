# Lumen Run IP Bible

This document defines the first-pass identity system for Lumen Run. It is the source of truth for user-facing naming, tone, and visual meaning.

## Core Premise

Lumen Run is about carrying a fading signal through a collapsing orbital network.

The player is not "a lumen." The player is the Relay Core: a small signal carrier trying to keep the last light moving. Lumen is the recoverable energy scattered through the orbit. Glitch is the corruption breaking the network.

## Naming Rules

Use the smallest possible public vocabulary. New players should only need to learn these seven families:

1. **Relay Core**: the player.
2. **Lumen Spark**: basic score energy.
3. **Core**: helpful or high-value pickup.
4. **Glitch Shard**: lethal hazard.
5. **Void Gate**: combo-disrupting blocker.
6. **Oversync**: temporary invincible scoring state.
7. **Relay Module**: build choice.

Internal implementation names can stay as code terms, but user-facing text should avoid leaking them unless they are already canonical below.

| Concept | Korean | English | Notes |
| --- | --- | --- | --- |
| Game | 루멘런 | Lumen Run | Keep the title simple and readable. |
| Player | 릴레이 코어 | Relay Core | The controllable object. Avoid calling it just "lumen." |
| Score pickup | 루멘 스파크 | Lumen Spark | Basic collectible light/signal fragment. |
| Big score pickup | 오버차지 코어 | Overcharge Core | Greedy reward object. |
| Protection pickup | 실드 필드 | Shield Field | Defensive pickup/effect. |
| Slow pickup | 타임 코어 | Time Core | Time-reading utility. |
| Magnet pickup | 자력 코어 | Magnet Core | Pulls scattered lumen sparks. |
| Clear pickup | 클리어 코어 | Clear Core | Clears nearby glitch hazards. |
| Lethal hazard | 글리치 샤드 | Glitch Shard | Sharp corruption. Same-orbit collision is fatal unless protected. |
| Moving hazard | 펄스 샤드 | Pulse Shard | A moving glitch shard. |
| Combo disruptor | 보이드 게이트 | Void Gate | Disrupts signal/combo without ending the run. |
| Fever state | 오버싱크 | Oversync | The Relay Core temporarily overclocks and turns danger into score. |
| Stage | 루트 | Route | User-facing UI may still show ST for compact HUD, but route language should carry the fantasy. |
| Upgrade card | 릴레이 모듈 | Relay Module | Route-clear build choice. |
| Start card | 시동 모듈 | Ignition Module | First-run strategic starting condition. |

## Avoid In User-Facing Copy

| Avoid | Use Instead | Reason |
| --- | --- | --- |
| Fever | Oversync / 오버싱크 | Fever is a generic genre term; Oversync is the IP term. |
| Stage | Route / 루트 | Route better fits the orbit-network fantasy. Compact HUD may still use ST if space is tight. |
| Surge item | Overcharge Core / 오버차지 코어 | Surge is too generic and overlaps with module names. |
| Bomb | Clear Core / 클리어 코어 | The object is a route-system core, not a conventional bomb. |
| Power-up | Core / Field / Module | Keep the signal-network vocabulary consistent. |
| Lumen as the player | Relay Core / 릴레이 코어 | Lumen is energy, not the controllable character. |

## Tone

- Short, urgent, and signal-like.
- Prefer verbs like relay, sync, ignite, overload, carry, fracture, stabilize.
- Avoid long lore paragraphs in gameplay UI.
- Korean copy can mix short English nouns only when they are already genre-readable: Core, Sync, Route, Module.
- Do not introduce new noun families unless they clarify gameplay.

## Visual Language

- Good objects should have rounder forms and positive `+` markers.
- Lethal glitch objects should use sharp silhouettes and warning frames.
- Disruptive objects should look broken, gated, or interrupted rather than lethal.
- The brand mark is the Relay Core plus orbit lines plus signal nodes.
- The icon, loading mark, start mark, object guide, and in-game core should all feel like the same signal network.

## Brand Mark Rules

- The app icon and start/loading mark should prioritize the Relay Core at the center of three route rings.
- Route rings should read as playable paths, not decorative atom or planet orbits.
- Lumen Sparks should carry the small positive `+` badge whenever space allows.
- Glitch Shards should carry a triangular warning frame so danger is readable without relying only on red or magenta color.
- Void Gates should use interrupted purple arc language and a broken-signal mark, not the same danger frame as lethal hazards.
- Background signal lines may exist, but they should stay subtle so they do not compete with the core silhouette.

## UI Design Rules

- Corner radius stays at 8px or lower. Lumen Run should feel like a compact game interface, not a soft productivity app.
- Primary actions use the Lumen gold-to-accent gradient. Secondary actions stay dark, thin, and outlined.
- The start screen must keep one dominant CTA: Start Relay. Rewards, records, object guide, and settings belong in a lower-priority utility dock.
- Large display text is reserved for the title, route clear, Oversync, and final score. Dense panels use compact labels and monospaced numbers.
- Relay Module cards should read like hardware slots: role header, icon, rarity/tag chips, effect text, and a clear pick action.
- Relay Module cards should show physical module language through contact rails, side signal rails, and compact socket marks.
- Risk modules should always show a visible warning color or socket mark before the player reads the detailed text.
- HUD and results panels should prefer functional scan speed over decoration.
- The in-run HUD should stay limited to score, route progress, Oversync/buff state, and pause/settings controls. Secondary destinations should not compete with gameplay.

## Audio Language

- The core music identity is fast, bright, synthetic, and loopable: signal pulses over a dark orbital bed.
- Normal music should feel like a controlled relay run, while Oversync music should feel faster and more urgent.
- Lumen Spark collection should be a short bright ping, not a generic coin sound.
- Relay Module and Ignition Module choices should sound like a module locking into the route system.
- Route clear should have its own positive chime so the player feels a route has truly ended.
- Glitch hits should stay lower, noisier, and more broken than helpful object sounds.

## Current First-Pass Decision

Keep the game title as Lumen Run for now. The title is short, pronounceable, and still works once "lumen" is defined as the collectible signal energy rather than the player character.
