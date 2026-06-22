"use client";

import { useEffect, useRef, useState, useCallback, CSSProperties } from "react";
import Image from "next/image";
import { theme } from "@/lib/theme";

interface AppData {
  name: string;
  slug: string;
  icon: string;
  requests: number;
  blockedPercent: number;
}

interface RinklerClusterProps {
  apps: AppData[];
  onAppClick?: (slug: string) => void;
}

interface RinklerState {
  x: number;
  y: number;
  vx: number;
  vy: number;
  size: number;
}

const CENTER_SIZE = 80;
const ORBIT_SIZE = 56;
const ORBIT_GAP = 10;
const MIN_ORBIT_RADIUS = 120;
const SPRING_K = 0.02;
const CENTER_SPRING_K = 0.12;
const DAMPING = 0.88;
const COLLISION_STIFFNESS = 0.15;
const MAX_VELOCITY = 8;
const SETTLE_THRESHOLD = 0.05;

function orbitRadius(numOrbiting: number): number {
  // Ensure circumference fits all orbs without overlap
  const needed = numOrbiting * (ORBIT_SIZE + ORBIT_GAP) / (2 * Math.PI);
  return Math.max(MIN_ORBIT_RADIUS, needed);
}

function clampVel(v: number): number {
  return Math.max(-MAX_VELOCITY, Math.min(MAX_VELOCITY, v));
}

export default function RinklerCluster({ apps, onAppClick }: RinklerClusterProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const orbsRef = useRef<RinklerState[]>([]);
  const frameRef = useRef<number>(0);
  const [positions, setPositions] = useState<RinklerState[]>([]);
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
  const didDragRef = useRef(false);
  const [dragging, setDragging] = useState<number | null>(null);
  const dragStartRef = useRef({ x: 0, y: 0 });

  const numOrbiting = Math.max(apps.length - 1, 0);
  const radius = orbitRadius(numOrbiting);
  const containerHeight = Math.max(320, radius * 2 + ORBIT_SIZE + 40);

  const initRinklers = useCallback(() => {
    const container = containerRef.current;
    if (!container || apps.length === 0) return;

    const rect = container.getBoundingClientRect();
    const cx = rect.width / 2;
    const cy = rect.height / 2;

    const orbs: RinklerState[] = apps.map((_, i) => {
      if (i === 0) {
        return { x: cx, y: cy, vx: 0, vy: 0, size: CENTER_SIZE };
      }
      const angleStep = (2 * Math.PI) / numOrbiting;
      const angle = -Math.PI / 2 + (i - 1) * angleStep;
      return {
        x: cx + Math.cos(angle) * radius,
        y: cy + Math.sin(angle) * radius,
        vx: 0,
        vy: 0,
        size: ORBIT_SIZE,
      };
    });
    orbsRef.current = orbs;
    setPositions([...orbs]);
  }, [apps, numOrbiting, radius]);

  useEffect(() => {
    initRinklers();
  }, [initRinklers]);

  const startSimulation = useCallback(() => {
    cancelAnimationFrame(frameRef.current);
    const container = containerRef.current;
    if (!container || orbsRef.current.length === 0) return;
    const rect = container.getBoundingClientRect();
    const cx = rect.width / 2;
    const cy = rect.height / 2;

    const simulate = () => {
      const orbs = orbsRef.current;
      let maxSpeed = 0;

      for (let i = 0; i < orbs.length; i++) {
        if (i === dragging) continue;
        const b = orbs[i];

        let tx = cx;
        let ty = cy;
        if (i > 0) {
          const angleStep = (2 * Math.PI) / numOrbiting;
          const angle = -Math.PI / 2 + (i - 1) * angleStep;
          tx = cx + Math.cos(angle) * radius;
          ty = cy + Math.sin(angle) * radius;
        }

        const springK = i === 0 ? CENTER_SPRING_K : SPRING_K;
        b.vx += (tx - b.x) * springK;
        b.vy += (ty - b.y) * springK;
        b.vx *= DAMPING;
        b.vy *= DAMPING;

        for (let j = 0; j < orbs.length; j++) {
          if (i === j) continue;
          const o = orbs[j];
          const dx = b.x - o.x;
          const dy = b.y - o.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          const minDist = (b.size + o.size) / 2 + 8;
          if (dist < minDist && dist > 0) {
            const push = (minDist - dist) * COLLISION_STIFFNESS;
            b.vx += (dx / dist) * push;
            b.vy += (dy / dist) * push;
          }
        }

        b.vx = clampVel(b.vx);
        b.vy = clampVel(b.vy);
        b.x += b.vx;
        b.y += b.vy;

        const speed = Math.abs(b.vx) + Math.abs(b.vy);
        if (speed > maxSpeed) maxSpeed = speed;
      }

      setPositions(orbs.map((b) => ({ ...b })));

      if (maxSpeed < SETTLE_THRESHOLD && dragging === null) {
        // Snap to rest
        for (const b of orbs) { b.vx = 0; b.vy = 0; }
        setPositions(orbs.map((b) => ({ ...b })));
        return;
      }

      frameRef.current = requestAnimationFrame(simulate);
    };

    frameRef.current = requestAnimationFrame(simulate);
  }, [dragging, numOrbiting, radius]);

  useEffect(() => {
    startSimulation();
    return () => cancelAnimationFrame(frameRef.current);
  }, [startSimulation]);

  const handlePointerDown = (index: number, e: React.PointerEvent) => {
    didDragRef.current = false;
    dragStartRef.current = { x: e.clientX, y: e.clientY };
    setDragging(index);
    (e.target as HTMLElement).setPointerCapture?.(e.pointerId);
  };

  const handlePointerMove = useCallback(
    (e: React.PointerEvent) => {
      if (dragging === null) return;
      const container = containerRef.current;
      if (!container) return;

      const dx = e.clientX - dragStartRef.current.x;
      const dy = e.clientY - dragStartRef.current.y;
      if (Math.abs(dx) > 4 || Math.abs(dy) > 4) {
        didDragRef.current = true;
      }

      const rect = container.getBoundingClientRect();
      const b = orbsRef.current[dragging];
      if (!b) return;
      b.x = e.clientX - rect.left;
      b.y = e.clientY - rect.top;
      b.vx = 0;
      b.vy = 0;
    },
    [dragging]
  );

  const handlePointerUp = useCallback(
    (index?: number) => {
      if (!didDragRef.current && index !== undefined && onAppClick) {
        onAppClick(apps[index]?.slug ?? "");
      }
      setDragging(null);
      // Kick the simulation so orbs spring back and settle
      requestAnimationFrame(() => startSimulation());
    },
    [onAppClick, apps, startSimulation]
  );

  const containerStyle: CSSProperties = {
    position: "relative",
    width: "100%",
    height: containerHeight,
    cursor: dragging !== null ? "grabbing" : "default",
  };

  return (
    <div
      ref={containerRef}
      style={containerStyle}
      onPointerMove={handlePointerMove}
      onPointerUp={() => handlePointerUp()}
      onPointerLeave={() => { if (dragging !== null) setDragging(null); }}
    >
      {positions.map((pos, i) => {
        const app = apps[i];
        if (!app) return null;
        const isHovered = hoveredIndex === i;
        const isDragged = dragging === i;
        const scale = isDragged ? 1.1 : isHovered ? 1.08 : 1;

        const orbStyle: CSSProperties = {
          position: "absolute",
          left: pos.x - pos.size / 2,
          top: pos.y - pos.size / 2,
          width: pos.size,
          height: pos.size,
          borderRadius: "50%",
          background: theme.colors.white,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          cursor: "pointer",
          transform: `scale(${scale})`,
          transition: isDragged ? "none" : "transform 0.15s ease",
          boxShadow: isHovered
            ? "0 0 22px rgba(91,124,255,0.55)"
            : "0 2px 14px rgba(91,124,255,0.18)",
          userSelect: "none",
          touchAction: "none",
        };

        const iconStyle: CSSProperties = {
          width: pos.size * 0.6,
          height: pos.size * 0.6,
          borderRadius: 10,
          objectFit: "contain",
        };

        const labelStyle: CSSProperties = {
          position: "absolute",
          bottom: -20,
          left: "50%",
          transform: "translateX(-50%)",
          fontFamily: theme.fonts.body,
          fontSize: 13,
          color: theme.colors.white,
          whiteSpace: "nowrap",
          opacity: isHovered ? 1 : 0,
          transition: "opacity 0.15s ease",
          pointerEvents: "none",
        };

        return (
          <div
            key={app.slug}
            style={orbStyle}
            onPointerDown={(e) => handlePointerDown(i, e)}
            onPointerUp={() => handlePointerUp(i)}
            onPointerEnter={() => setHoveredIndex(i)}
            onPointerLeave={() => setHoveredIndex(null)}
          >
            {app.icon.startsWith("/") ? (
              <Image
                src={app.icon}
                alt={app.name}
                width={Math.round(pos.size * 0.6)}
                height={Math.round(pos.size * 0.6)}
                style={iconStyle}
                unoptimized
              />
            ) : (
              <span
                style={{
                  fontSize: pos.size * 0.3,
                  color: theme.colors.skyBlue,
                  fontWeight: "bold",
                  fontFamily: theme.fonts.body,
                }}
              >
                {app.icon}
              </span>
            )}
            <span style={labelStyle}>{app.name}</span>
          </div>
        );
      })}
    </div>
  );
}
