# Marketing Brain Launch Video Design

## Style Prompt

Editorial field-manual motion graphics for a premium proprietary marketing
system. The visual language matches the repository: cream paper, ink black,
sepia rules, Georgia italic titles, small-caps labels, engraved brain-network
plates, and sparse evidence-first layouts. It should feel like a serious
product manual coming alive, not a generic SaaS explainer.

## Format

- Target: YouTube / Gumroad product explainer
- Runtime: 3:30-4:15
- Canvas: 1920x1080
- Frame rate: 30fps because the piece includes screen-content and animated UI
- Audio target: -14 LUFS for YouTube long-form
- Voice: Daniel's local cloned voice if generated later

## Colors

| Role | Hex |
|---|---|
| Paper | `#FAFAF7` |
| Ink | `#1A1A1A` |
| Sepia rules | `#8B7355` |
| Body grey | `#4A4A4A` |
| Muted paper shadow | `#F2EDE0` |
| Proof green, sparingly | `#6F9D5A` |

## Typography

- Display: Georgia / Times New Roman, italic, weight 400
- Body: Georgia / Times New Roman, weight 400
- Labels: system sans, uppercase, letter-spacing 0.22em
- No Inter, Roboto, gradient headline type, or dark neon tech palette

## Motion Rules

- Reveal one idea at a time. No parallel text reveals.
- Use slow editorial wipes, rule draws, opacity lifts, plate slides, and gentle
  node pulses.
- Keep every final layout readable before animating it.
- Use finite loops only. No infinite animation repeats in render code.
- Use existing SVG assets where possible:
  - `assets/svg/hero-frontispiece-a2.svg`
  - `assets/svg/pipeline-six-step-d1.svg`
  - `assets/svg/flow-framework-e1.svg`
  - `assets/svg/vault-output-map-e1.svg`
  - `assets/svg/release-build-v011-e1.svg`
- Use WebP proof moments as media accents, not as the whole video:
  - `assets/webp/marketing-brain_03.webp`
  - `assets/webp/marketing-brain_01.webp`

## What Not To Do

- Do not use the old dark cyan/orange engineering visuals.
- Do not use purple-blue gradient SaaS styling.
- Do not promise rankings, traffic, or revenue outcomes.
- Do not describe the UI with visible tutorial text.
- Do not clutter the canvas with every feature; the narration carries detail.
- Do not cover a future talking-head/avatar face if one is added later.

## Preferred Build Path

Per local defaults, build in HyperFrames unless Daniel explicitly confirms
Remotion. If Remotion is chosen, keep the same design tokens and motion rules
and use React only as the renderer, not as a reason to change the aesthetic.
