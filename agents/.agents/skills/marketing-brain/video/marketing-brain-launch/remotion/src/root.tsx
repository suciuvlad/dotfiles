import { Composition } from "remotion";
import { MarketingBrainLaunch, TOTAL_FRAMES } from "./MarketingBrainLaunch";

export const RemotionRoot = () => {
  return (
    <Composition
      id="MarketingBrainLaunch"
      component={MarketingBrainLaunch}
      durationInFrames={TOTAL_FRAMES}
      fps={30}
      width={1920}
      height={1080}
    />
  );
};
