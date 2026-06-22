"use client";

import { motion } from "framer-motion";
import Link from "next/link";
import type { ReactNode } from "react";
import styles from "./landing.module.css";

/* Deterministic starfield so server and client render identically (no hydration
   mismatch). A simple seeded PRNG mirrors the iOS SkyBackgroundView. */
function useStars(count: number) {
  let seed = 0x9e3779b9;
  const rand = () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 0xffffffff;
  };
  return Array.from({ length: count }, () => {
    const a = 0.25 + rand() * 0.55;
    return {
      left: `${rand() * 100}%`,
      top: `${rand() * 70}%`,
      size: `${0.8 + rand() * 2.2}px`,
      a,
      dur: `${3 + rand() * 4}s`,
      delay: `${rand() * 4}s`,
    };
  });
}

function Reveal({ children, delay = 0 }: { children: ReactNode; delay?: number }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: "-80px" }}
      transition={{ duration: 0.6, delay, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}

const CHAPTERS = [
  { n: 1, title: "First Light", goal: "Your first focus session" },
  { n: 2, title: "The Haze Lifts", goal: "1 hour protected" },
  { n: 3, title: "Breaking Cloud", goal: "5 sessions" },
  { n: 4, title: "Aurora", goal: "7-day streak" },
  { n: 5, title: "Clear Sky", goal: "50 hours protected" },
];

const COMPARE: { label: string; rinkler: string; opal: string }[] = [
  { label: "What it blocks", rinkler: "Just the endless short-video feed", opal: "The whole app or website" },
  { label: "App stays usable", rinkler: "DMs, posts & search still work", opal: "App fully locked in a session" },
  { label: "Why you keep it on", rinkler: "Nothing to rage-quit — the useful parts remain", opal: "All-or-nothing invites turning it off" },
  { label: "How it works", rinkler: "On-device network filter, no content read", opal: "Screen Time API + account" },
  { label: "Core price", rinkler: "Free — filtering runs locally", opal: "~$99.99 / year for the useful tier" },
  { label: "Motivation", rinkler: "Living-sky Story Mode that clears as you focus", opal: "Streaks & leaderboards" },
];

const FAQ = [
  {
    q: "Does Rinkler block the entire app?",
    a: "No — and that's the whole point. It interrupts the heavy short-video streams (Instagram Reels, TikTok's feed) at the network layer. Messaging, posting, profiles and search keep working, so you never feel the need to switch it off.",
  },
  {
    q: "Can Rinkler read my messages or see what I'm doing?",
    a: "No. Filtering happens on your device and only looks at network metadata — that a large video stream is loading from a known host. It does not decrypt traffic, read messages, or inspect page contents.",
  },
  {
    q: "How is this different from Opal or Screen Time?",
    a: "Opal and Screen Time block whole apps for a window of time. Rinkler is surgical: it removes the addictive feed while leaving the app's useful features intact. You get the calm without losing the tool.",
  },
  {
    q: "What about YouTube Shorts, Reels on Facebook, etc.?",
    a: "Rinkler only ships filters it can enforce honestly. Today that's Instagram and TikTok short-video, because their feeds are identifiable at the network layer. We won't claim precision we can't deliver and accidentally break normal app behavior.",
  },
];

export default function Landing() {
  const stars = useStars(90);

  return (
    <div className={styles.page}>
      <div className={styles.stars} aria-hidden>
        {stars.map((s, i) => (
          <span
            key={i}
            className={styles.star}
            style={
              {
                left: s.left,
                top: s.top,
                width: s.size,
                height: s.size,
                "--a": s.a,
                "--dur": s.dur,
                animationDelay: s.delay,
              } as React.CSSProperties
            }
          />
        ))}
      </div>

      <div className={styles.content}>
        {/* Nav */}
        <nav className={styles.nav}>
          <div className={styles.wordmark}>RINKLER</div>
          <div className={styles.navLinks}>
            <a className={`${styles.navLink} ${styles.hideMobile}`} href="#problem">The problem</a>
            <a className={`${styles.navLink} ${styles.hideMobile}`} href="#how">How it works</a>
            <a className={`${styles.navLink} ${styles.hideMobile}`} href="#story">Story Mode</a>
            <a className={`${styles.navLink} ${styles.hideMobile}`} href="#compare">vs Opal</a>
            <Link className={`${styles.btnGhost} ${styles.navCta}`} href="/dashboard">Open dashboard</Link>
          </div>
        </nav>

        {/* Hero */}
        <header className={styles.hero}>
          <Reveal>
            <div className={styles.heroBadge}>
              <span className={styles.heroDot} /> On-device. Private. Honest.
            </div>
          </Reveal>
          <Reveal delay={0.05}>
            <h1 className={styles.h1}>
              Keep the useful parts. <span className={styles.aurora}>Lose the feed.</span>
            </h1>
          </Reveal>
          <Reveal delay={0.1}>
            <p className={styles.heroSub}>
              Most blockers lock the whole app, so you cave and turn them off. Rinkler
              quietly removes the endless short-video stream — your DMs, posts and search
              still work. The doomscroll just stops.
            </p>
          </Reveal>
          <Reveal delay={0.15}>
            <div className={styles.heroCtas}>
              <a className={styles.btnPrimary} href="#how">See how it works →</a>
              <Link className={styles.btnGhost} href="/dashboard">Open your dashboard</Link>
            </div>
          </Reveal>
          <Reveal delay={0.2}>
            <p className={styles.heroNote}>iOS · Network Extension · No traffic decryption</p>
          </Reveal>

          {/* Phone mock mirroring the real home screen */}
          <Reveal delay={0.25}>
            <div className={styles.heroPhoneWrap}>
              <div className={styles.phone}>
                <div className={styles.phoneScreen}>
                  <div className={styles.phoneLabel}>Today</div>
                  <div className={styles.phoneHero}>2h 14m</div>
                  <div className={styles.phoneHeroUnit}>of focus protected today</div>
                  <div className={styles.phoneChips}>
                    <div className={styles.phoneChip}><div className={styles.phoneChipN}>37</div><div className={styles.phoneChipL}>interrupted</div></div>
                    <div className={styles.phoneChip}><div className={styles.phoneChipN}>3</div><div className={styles.phoneChipL}>sessions</div></div>
                    <div className={styles.phoneChip}><div className={styles.phoneChipN}>6</div><div className={styles.phoneChipL}>day streak</div></div>
                  </div>
                  <div className={styles.phoneBtn}>START FOCUS SESSION</div>
                  <div className={styles.phoneRow}>
                    <div className={styles.phoneRowIcon}>✦</div>
                    <div>
                      <div className={styles.phoneRowText}>Aurora</div>
                      <div className={styles.phoneRowSub}>Next: 50 hours protected</div>
                    </div>
                  </div>
                  <div className={styles.phoneRow}>
                    <div className={styles.phoneRowIcon}>🛡</div>
                    <div>
                      <div className={styles.phoneRowText}>Protection on</div>
                      <div className={styles.phoneRowSub}>Filtering supported traffic</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </Reveal>
        </header>

        {/* Problem */}
        <section className={styles.section} id="problem">
          <Reveal><div className={styles.kicker}>The problem</div></Reveal>
          <Reveal delay={0.05}><h2 className={styles.h2}>It was never your willpower.</h2></Reveal>
          <Reveal delay={0.1}>
            <p className={styles.lead}>
              Infinite feeds aren&apos;t broken — they&apos;re working exactly as designed.
              Short video loads the next hit before you decide to stay. No amount of
              &ldquo;just one more&rdquo; was ever a fair fight. So Rinkler changes the game
              instead of asking you to win it.
            </p>
          </Reveal>

          <div className={styles.split}>
            <Reveal delay={0.1}>
              <div className={`${styles.splitCard} ${styles.splitBad}`}>
                <div className={`${styles.splitTag} ${styles.splitTagBad}`}>The usual blocker</div>
                <ul className={styles.splitList}>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✕</span> Locks the entire app</li>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✕</span> You miss a real DM, so you disable it</li>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✕</span> All-or-nothing, every time</li>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✕</span> Back to scrolling by Tuesday</li>
                </ul>
              </div>
            </Reveal>
            <Reveal delay={0.18}>
              <div className={`${styles.splitCard} ${styles.splitGood}`}>
                <div className={`${styles.splitTag} ${styles.splitTagGood}`}>The Rinkler way</div>
                <ul className={styles.splitList}>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✓</span> Removes only the endless feed</li>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✓</span> DMs, posts &amp; search still work</li>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✓</span> Nothing to rage-quit</li>
                  <li className={styles.splitItem}><span className={styles.splitMark}>✓</span> So it actually stays on</li>
                </ul>
              </div>
            </Reveal>
          </div>
        </section>

        {/* How it works */}
        <section className={styles.section} id="how">
          <Reveal><div className={styles.kicker}>How it works</div></Reveal>
          <Reveal delay={0.05}><h2 className={styles.h2}>Surgical, on-device, and honest.</h2></Reveal>
          <div className={styles.grid3}>
            <Reveal delay={0.1}>
              <div className={styles.featCard}>
                <div className={styles.featIcon}>✂</div>
                <div className={styles.featTitle}>Cuts the feed, not the app</div>
                <div className={styles.featBody}>
                  A local VPN tunnel interrupts the heavy short-video streams from the apps
                  you choose. Everything else passes through untouched.
                </div>
              </div>
            </Reveal>
            <Reveal delay={0.16}>
              <div className={styles.featCard}>
                <div className={styles.featIcon}>🔒</div>
                <div className={styles.featTitle}>It never reads your life</div>
                <div className={styles.featBody}>
                  Filtering runs on your device and only sees network metadata — never your
                  messages, photos, or the page you&apos;re on. No traffic is decrypted.
                </div>
              </div>
            </Reveal>
            <Reveal delay={0.22}>
              <div className={styles.featCard}>
                <div className={styles.featIcon}>◎</div>
                <div className={styles.featTitle}>Focus sessions with teeth</div>
                <div className={styles.featBody}>
                  Pick Gentle, Focused, or Deep. Deep can&apos;t be ended early — each level maps
                  to a real byte threshold on the feed, not a cosmetic timer.
                </div>
              </div>
            </Reveal>
          </div>
        </section>

        {/* Story Mode */}
        <div id="story">
          <section className={styles.story}>
            <Reveal><div className={styles.kicker}>Story Mode</div></Reveal>
            <Reveal delay={0.05}><h2 className={styles.h2}>Every session clears the sky.</h2></Reveal>
            <Reveal delay={0.1}>
              <p className={styles.lead}>
                Rinkler turns your real focus history into a journey from deep night to dawn.
                Protect time, build a streak, and the whole app warms with light — a world
                that remembers the hours you took back. No fake points. Just your progress.
              </p>
            </Reveal>
            <div className={styles.chapters}>
              {CHAPTERS.map((c, i) => (
                <Reveal key={c.n} delay={0.1 + i * 0.06}>
                  <div className={styles.chapter}>
                    <div className={styles.chapterDot}>{c.n}</div>
                    <div className={styles.chapterTitle}>{c.title}</div>
                    <div className={styles.chapterGoal}>{c.goal}</div>
                  </div>
                </Reveal>
              ))}
            </div>
          </section>
        </div>

        {/* Comparison */}
        <section className={styles.section} id="compare">
          <Reveal><div className={styles.kicker}>Rinkler vs Opal</div></Reveal>
          <Reveal delay={0.05}><h2 className={styles.h2}>Same goal. Opposite philosophy.</h2></Reveal>
          <Reveal delay={0.1}>
            <p className={styles.lead}>
              Opal is a great all-or-nothing blocker. But blocking the whole app is exactly
              why people switch it off. Rinkler keeps the tool and removes the trap.
            </p>
          </Reveal>
          <Reveal delay={0.12}>
            <div className={styles.compare}>
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th></th>
                    <th className={`${styles.colRinkler} ${styles.head}`}>Rinkler</th>
                    <th>Opal</th>
                  </tr>
                </thead>
                <tbody>
                  {COMPARE.map((row) => (
                    <tr key={row.label}>
                      <td className={styles.rowLabel}>{row.label}</td>
                      <td className={styles.colRinkler}>{row.rinkler}</td>
                      <td className={styles.colOther}>{row.opal}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Reveal>
        </section>

        {/* FAQ */}
        <section className={styles.section}>
          <Reveal><div className={styles.kicker}>FAQ</div></Reveal>
          <Reveal delay={0.05}><h2 className={styles.h2}>The honest answers.</h2></Reveal>
          <div style={{ marginTop: 36 }}>
            {FAQ.map((item, i) => (
              <Reveal key={item.q} delay={0.05 * i}>
                <div className={styles.faqItem}>
                  <div className={styles.faqQ}>{item.q}</div>
                  <div className={styles.faqA}>{item.a}</div>
                </div>
              </Reveal>
            ))}
          </div>
        </section>

        {/* Final CTA */}
        <section className={`${styles.section} ${styles.finalCta}`}>
          <Reveal>
            <div className={styles.finalCtaInner}>
              <h2 className={styles.h2} style={{ margin: "0 auto" }}>Take your evenings back.</h2>
              <p className={styles.heroSub}>
                Keep the apps you actually use. Let the feed go quiet. Watch the sky clear.
              </p>
              <div className={styles.heroCtas} style={{ justifyContent: "center" }}>
                <Link className={styles.btnPrimary} href="/dashboard">Open your dashboard</Link>
              </div>
            </div>
          </Reveal>
        </section>

        {/* Footer */}
        <footer className={styles.footer}>
          <div>© {new Date().getFullYear()} Rinkler</div>
          <div className={styles.footerLinks}>
            <a href="#how">How it works</a>
            <a href="#story">Story Mode</a>
            <a href="#compare">vs Opal</a>
            <Link href="/dashboard">Dashboard</Link>
            <Link href="/privacy">Privacy</Link>
            <Link href="/terms">Terms</Link>
          </div>
        </footer>
      </div>
    </div>
  );
}
