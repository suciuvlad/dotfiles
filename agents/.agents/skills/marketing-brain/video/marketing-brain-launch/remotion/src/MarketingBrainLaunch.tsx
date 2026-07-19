import React from "react";
import {
  AbsoluteFill,
  Easing,
  Img,
  Sequence,
  interpolate,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const C = {
  paper: "#FAFAF7",
  ink: "#1A1A1A",
  sepia: "#8B7355",
  body: "#4A4A4A",
  shadow: "#F2EDE0",
  green: "#6F9D5A",
};

const FPS = 30;

type Scene = {
  id: string;
  duration: number;
  render: React.FC<{ localFrame: number; duration: number }>;
};

const s = (seconds: number) => Math.round(seconds * FPS);

const easeOut = Easing.bezier(0.16, 1, 0.3, 1);
const easeInOut = Easing.bezier(0.45, 0, 0.55, 1);

const clamp = {
  extrapolateLeft: "clamp" as const,
  extrapolateRight: "clamp" as const,
};

const enter = (frame: number, start = 0, duration = 24) =>
  interpolate(frame, [start, start + duration], [0, 1], {
    ...clamp,
    easing: easeOut,
  });

const exit = (frame: number, duration: number, length = 18) =>
  interpolate(frame, [duration - length, duration], [1, 0], {
    ...clamp,
    easing: Easing.in(Easing.cubic),
  });

const sceneOpacity = (frame: number, duration: number) =>
  Math.min(enter(frame, 0, 18), exit(frame, duration, 18));

const fontSerif: React.CSSProperties = {
  fontFamily: "Georgia, 'Times New Roman', serif",
};

const labelStyle: React.CSSProperties = {
  fontFamily: "ui-sans-serif, system-ui, sans-serif",
  letterSpacing: "0.24em",
  textTransform: "uppercase",
  color: C.sepia,
  fontSize: 19,
};

const Frame: React.FC<{ children: React.ReactNode; localFrame: number; duration: number }> = ({
  children,
  localFrame,
  duration,
}) => {
  const opacity = sceneOpacity(localFrame, duration);
  const rule = interpolate(localFrame, [8, 52], [0, 1], {
    ...clamp,
    easing: easeInOut,
  });

  return (
    <AbsoluteFill style={{ background: C.paper, opacity }}>
      <div
        style={{
          position: "absolute",
          inset: 48,
          border: `1px solid rgba(139,115,85,${0.34 * rule})`,
        }}
      />
      <div
        style={{
          position: "absolute",
          inset: 72,
          border: `1px solid rgba(139,115,85,${0.18 * rule})`,
        }}
      />
      {children}
    </AbsoluteFill>
  );
};

const Label: React.FC<{ children: React.ReactNode; style?: React.CSSProperties }> = ({ children, style }) => (
  <div style={{ ...labelStyle, ...style }}>{children}</div>
);

const Title: React.FC<{ children: React.ReactNode; size?: number; style?: React.CSSProperties }> = ({
  children,
  size = 82,
  style,
}) => (
  <div
    style={{
      ...fontSerif,
      color: C.ink,
      fontSize: size,
      fontStyle: "italic",
      fontWeight: 400,
      lineHeight: 0.96,
      letterSpacing: 0,
      ...style,
    }}
  >
    {children}
  </div>
);

const Body: React.FC<{ children: React.ReactNode; style?: React.CSSProperties }> = ({ children, style }) => (
  <div style={{ ...fontSerif, color: C.body, fontSize: 31, lineHeight: 1.45, ...style }}>{children}</div>
);

const Rule: React.FC<{ progress: number; width?: number; style?: React.CSSProperties }> = ({
  progress,
  width = 180,
  style,
}) => (
  <div
    style={{
      width: width * progress,
      height: 2,
      background: C.ink,
      transformOrigin: "left center",
      ...style,
    }}
  />
);

const AssetPlate: React.FC<{
  src: string;
  localFrame: number;
  delay?: number;
  width?: number;
  style?: React.CSSProperties;
}> = ({ src, localFrame, delay = 0, width = 1120, style }) => {
  const p = enter(localFrame, delay, 28);
  return (
    <div
      style={{
        width,
        padding: 20,
        background: C.paper,
        border: `1px solid rgba(139,115,85,${0.45 * p})`,
        boxShadow: `0 26px 70px rgba(139,115,85,${0.12 * p})`,
        opacity: p,
        transform: `translateY(${(1 - p) * 28}px)`,
        ...style,
      }}
    >
      <Img src={staticFile(src)} style={{ display: "block", width: "100%" }} />
    </div>
  );
};

const BrainMark: React.FC<{ localFrame: number; style?: React.CSSProperties }> = ({ localFrame, style }) => {
  const pulse = interpolate(Math.sin((localFrame / FPS) * Math.PI * 2 * 0.45), [-1, 1], [0.65, 1]);
  const nodes = Array.from({ length: 16 }, (_, i) => {
    const angle = (-Math.PI / 2) + (Math.PI * 2 * i) / 16;
    const orbit = i % 4 === 0 ? 176 : i % 2 === 0 ? 152 : 132;
    return { x: 220 + Math.cos(angle) * orbit, y: 220 + Math.sin(angle) * orbit, r: i % 4 === 0 ? 6 : 4 };
  });
  return (
    <svg viewBox="0 0 440 440" style={{ width: 440, height: 440, ...style }}>
      <circle cx="220" cy="220" r="70" fill="none" stroke={C.sepia} strokeWidth="1.2" opacity={0.22 * pulse} />
      <circle cx="220" cy="220" r="118" fill="none" stroke={C.sepia} strokeWidth="1" opacity={0.16 * pulse} />
      <circle cx="220" cy="220" r="170" fill="none" stroke={C.sepia} strokeWidth="1" opacity={0.1 * pulse} />
      {nodes.map((n, i) => (
        <line key={`l-${i}`} x1="220" y1="220" x2={n.x} y2={n.y} stroke={C.sepia} strokeWidth="1.1" opacity="0.5" />
      ))}
      {nodes.map((n, i) => (
        <circle key={i} cx={n.x} cy={n.y} r={n.r} fill={C.ink} opacity={0.78 + 0.2 * Math.sin(localFrame / 18 + i)} />
      ))}
      <circle cx="220" cy="220" r={18 + pulse * 2} fill={C.ink} />
    </svg>
  );
};

const ColdOpen: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const p1 = enter(localFrame, 16, 34);
  const p2 = enter(localFrame, 48, 34);
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <div style={{ position: "absolute", left: 170, top: 190, width: 980 }}>
        <Label style={{ opacity: p1, transform: `translateY(${(1 - p1) * 18}px)` }}>VOL. I / MARKETING BRAIN</Label>
        <Title size={112} style={{ marginTop: 52, opacity: p2, transform: `translateY(${(1 - p2) * 28}px)` }}>
          Most SEO work<br />starts too late.
        </Title>
        <Rule progress={enter(localFrame, 86, 28)} width={280} style={{ marginTop: 52 }} />
      </div>
      <BrainMark localFrame={localFrame} style={{ position: "absolute", right: 210, top: 310, opacity: 0.22 + p2 * 0.38 }} />
    </Frame>
  );
};

const Mess: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const items = [
    ["keyword exports", "CSV rows without context"],
    ["SERP tabs", "intent split across browser windows"],
    ["reports nobody reopens", "strategy frozen at delivery"],
  ];
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <div style={{ position: "absolute", left: 160, top: 150 }}>
        <Label>The problem</Label>
        <Title size={74} style={{ marginTop: 30 }}>Data that never becomes a brain.</Title>
      </div>
      <div style={{ position: "absolute", left: 310, top: 415, display: "flex", gap: 44 }}>
        {items.map(([title, note], i) => {
          const p = enter(localFrame, 36 + i * 20, 30);
          return (
            <div
              key={title}
              style={{
                width: 380,
                minHeight: 210,
                padding: "42px 38px",
                background: C.paper,
                border: `1px solid ${C.sepia}`,
                boxShadow: "0 24px 50px rgba(139,115,85,0.12)",
                opacity: p,
                transform: `translateY(${(1 - p) * 38}px) rotate(${[-1.6, 1.1, -0.8][i]}deg)`,
              }}
            >
              <Title size={39}>{title}</Title>
              <Body style={{ marginTop: 26, fontSize: 22 }}>{note}</Body>
            </div>
          );
        })}
      </div>
    </Frame>
  );
};

const Product: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => (
  <Frame localFrame={localFrame} duration={duration}>
    <AssetPlate src="assets/svg/hero-frontispiece-a2.svg" localFrame={localFrame} width={1380} style={{ position: "absolute", left: 270, top: 200 }} />
    <Label style={{ position: "absolute", left: 610, top: 865, opacity: enter(localFrame, 52, 24) }}>
      strategic seo / orchestrated by artificial intelligence
    </Label>
  </Frame>
);

const TwoArtifacts: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const left = enter(localFrame, 18, 30);
  const right = enter(localFrame, 48, 30);
  const line = enter(localFrame, 82, 24);
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <div style={{ position: "absolute", left: 185, top: 165 }}>
        <Label>two artifacts</Label>
        <Title size={70} style={{ marginTop: 25 }}>The vault and the skill.</Title>
      </div>
      <div style={{ position: "absolute", left: 220, top: 410, display: "flex", alignItems: "center", gap: 90 }}>
        <ArtifactCard p={left} title="Obsidian template brain" note="Hot / Index / Wiki, business overlays, Bases views, and strategic concept notes." />
        <div style={{ width: 180 * line, height: 1.5, background: C.sepia, opacity: line }} />
        <ArtifactCard p={right} title="Marketing Brain skill" note="Six-step automation that fills the vault with evidence and produces the BEAST plan." />
      </div>
    </Frame>
  );
};

const ArtifactCard: React.FC<{ p: number; title: string; note: string }> = ({ p, title, note }) => (
  <div
    style={{
      width: 545,
      height: 285,
      padding: 42,
      border: `1px solid ${C.sepia}`,
      opacity: p,
      transform: `translateY(${(1 - p) * 30}px)`,
      background: C.paper,
    }}
  >
    <Title size={47}>{title}</Title>
    <Body style={{ marginTop: 30, fontSize: 25 }}>{note}</Body>
  </div>
);

const Pipeline: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => (
  <Frame localFrame={localFrame} duration={duration}>
    <AssetPlate src="assets/svg/pipeline-six-step-d1.svg" localFrame={localFrame} width={1440} style={{ position: "absolute", left: 240, top: 260 }} />
    <div style={{ position: "absolute", left: 300, bottom: 160, display: "flex", gap: 34 }}>
      {["competitors", "keywords", "workbook", "questions", "vault", "BEAST"].map((n, i) => {
        const p = enter(localFrame, 80 + i * 17, 16);
        return (
          <div key={n} style={{ ...labelStyle, fontSize: 15, color: i === 5 ? C.ink : C.sepia, opacity: p }}>
            {n}
          </div>
        );
      })}
    </div>
  </Frame>
);

const ProofWindow: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const p = enter(localFrame, 12, 28);
  const cap = enter(localFrame, 58, 24);
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <div
        style={{
          position: "absolute",
          left: 200,
          top: 135,
          width: 1520,
          padding: 18,
          border: `1px solid rgba(139,115,85,${0.5 * p})`,
          opacity: p,
          transform: `translateY(${(1 - p) * 28}px)`,
        }}
      >
        <Img src={staticFile("assets/webp/marketing-brain_03.webp")} style={{ display: "block", width: "100%", height: 855, objectFit: "cover" }} />
      </div>
      <div
        style={{
          position: "absolute",
          left: 314,
          bottom: 115,
          width: 1290,
          padding: "28px 40px",
          background: "rgba(250,250,247,0.94)",
          borderTop: `1px solid ${C.sepia}`,
          opacity: cap,
          transform: `translateY(${(1 - cap) * 24}px)`,
        }}
      >
        <Label>the strategy vault is not a report / it is a working graph</Label>
      </div>
    </Frame>
  );
};

const HotIndexWiki: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const cols = [
    ["hot", "what matters now"],
    ["index", "where everything lives"],
    ["wiki", "depth on demand"],
  ];
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <div style={{ position: "absolute", left: 170, top: 150 }}>
        <Label>karpathy pattern</Label>
        <Title size={70} style={{ marginTop: 26 }}>Hot / Index / Wiki</Title>
      </div>
      <div style={{ position: "absolute", left: 210, top: 420, display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 52, width: 1500 }}>
        {cols.map(([title, note], i) => {
          const p = enter(localFrame, 34 + i * 24, 30);
          return (
            <div key={title} style={{ minHeight: 265, borderTop: `1px solid ${C.sepia}`, paddingTop: 38, opacity: p, transform: `translateY(${(1 - p) * 34}px)` }}>
              <Title size={72}>{title}</Title>
              <Body style={{ marginTop: 30, fontSize: 27 }}>{note}</Body>
            </div>
          );
        })}
      </div>
    </Frame>
  );
};

const Flow: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => (
  <Frame localFrame={localFrame} duration={duration}>
    <AssetPlate src="assets/svg/flow-framework-e1.svg" localFrame={localFrame} width={1360} style={{ position: "absolute", left: 280, top: 235 }} />
  </Frame>
);

const Guardrails: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const items = ["env-only credentials", "spend caps", "source manifest", "visual references"];
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <div style={{ position: "absolute", left: 170, top: 150 }}>
        <Label>guardrails where they matter</Label>
        <Title size={72} style={{ marginTop: 26 }}>Built for real client work.</Title>
      </div>
      <div style={{ position: "absolute", left: 230, top: 430, display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 32, width: 1460 }}>
        {items.map((item, i) => {
          const p = enter(localFrame, 36 + i * 18, 26);
          return (
            <div key={item} style={{ height: 220, border: `1px solid ${C.sepia}`, display: "flex", alignItems: "center", justifyContent: "center", padding: 30, opacity: p }}>
              <Label style={{ color: i === 3 ? C.green : C.sepia, textAlign: "center", lineHeight: 1.6 }}>{item}</Label>
            </div>
          );
        })}
      </div>
    </Frame>
  );
};

const Outputs: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => (
  <Frame localFrame={localFrame} duration={duration}>
    <AssetPlate src="assets/svg/vault-output-map-e1.svg" localFrame={localFrame} width={1380} style={{ position: "absolute", left: 270, top: 210 }} />
  </Frame>
);

const Access: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const p = enter(localFrame, 20, 32);
  const p2 = enter(localFrame, 66, 24);
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <div style={{ position: "absolute", left: 205, top: 275, width: 1320 }}>
        <Label style={{ opacity: p }}>proprietary access</Label>
        <Title size={112} style={{ marginTop: 44, opacity: p, transform: `translateY(${(1 - p) * 26}px)` }}>Built for operators.</Title>
        <Rule progress={enter(localFrame, 58, 22)} width={300} style={{ marginTop: 50 }} />
        <Label style={{ marginTop: 48, opacity: p2 }}>paid license holders / ai marketing hub pro members</Label>
        <Body style={{ marginTop: 26, fontSize: 28, opacity: p2 }}>source-available, not open source</Body>
      </div>
    </Frame>
  );
};

const Close: React.FC<{ localFrame: number; duration: number }> = ({ localFrame, duration }) => {
  const p = enter(localFrame, 20, 36);
  const beats = ["read first", "write second", "verify third"];
  return (
    <Frame localFrame={localFrame} duration={duration}>
      <BrainMark localFrame={localFrame} style={{ position: "absolute", left: 230, top: 300, opacity: p }} />
      <div style={{ position: "absolute", left: 820, top: 325 }}>
        <Label style={{ opacity: p }}>marketing brain</Label>
        <Title size={102} style={{ marginTop: 36, opacity: p }}>Marketing<br />Brain</Title>
        <div style={{ display: "flex", gap: 24, marginTop: 70 }}>
          {beats.map((beat, i) => (
            <Label key={beat} style={{ opacity: enter(localFrame, 86 + i * 18, 14), color: i === 2 ? C.ink : C.sepia }}>
              {beat}
            </Label>
          ))}
        </div>
      </div>
    </Frame>
  );
};

const scenes: Scene[] = [
  { id: "cold-open", duration: s(18), render: ColdOpen },
  { id: "mess", duration: s(24), render: Mess },
  { id: "product", duration: s(20), render: Product },
  { id: "two-artifacts", duration: s(23), render: TwoArtifacts },
  { id: "pipeline", duration: s(33), render: Pipeline },
  { id: "proof", duration: s(20), render: ProofWindow },
  { id: "hot-index-wiki", duration: s(25), render: HotIndexWiki },
  { id: "flow", duration: s(19), render: Flow },
  { id: "guardrails", duration: s(23), render: Guardrails },
  { id: "outputs", duration: s(23), render: Outputs },
  { id: "access", duration: s(17), render: Access },
  { id: "close", duration: s(13), render: Close },
];

export const TOTAL_FRAMES = scenes.reduce((sum, scene) => sum + scene.duration, 0);

export const MarketingBrainLaunch = () => {
  useVideoConfig();
  let cursor = 0;
  return (
    <AbsoluteFill style={{ background: C.paper }}>
      {scenes.map((scene) => {
        const start = cursor;
        cursor += scene.duration;
        const SceneComponent = scene.render;
        return (
          <Sequence key={scene.id} from={start} durationInFrames={scene.duration}>
            <SceneWrapper duration={scene.duration} SceneComponent={SceneComponent} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};

const SceneWrapper: React.FC<{
  duration: number;
  SceneComponent: React.FC<{ localFrame: number; duration: number }>;
}> = ({ duration, SceneComponent }) => {
  const frame = useCurrentFrame();
  return <SceneComponent localFrame={frame} duration={duration} />;
};
