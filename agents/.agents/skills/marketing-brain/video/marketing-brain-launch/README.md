# Marketing Brain Launch Video

This folder contains the launch-video package for the 3-5 minute Marketing
Brain walkthrough.

Files:

- `DESIGN.md` - visual identity, palette, typography, motion rules
- `VIDEO_SCRIPT.md` - voiceover script and CTA variants
- `STORYBOARD.md` - scene-by-scene timing and animation plan
- `remotion/` - deterministic 1920x1080 Remotion composition

Production path:

1. Edit `VIDEO_SCRIPT.md` and `STORYBOARD.md` if the narrative changes.
2. Update the Remotion composition in `remotion/src/MarketingBrainLaunch.tsx`.
3. Render still frames for representative scenes and inspect layout before
   final render.
4. Add voiceover and master to -14 LUFS when the narration take is approved.
5. Render 1920x1080 at 30fps.

Useful commands:

```bash
cd video/marketing-brain-launch/remotion
npm install
npm run compositions
npm run render
```

The default render target is `remotion/out/marketing-brain-launch.mp4`.
