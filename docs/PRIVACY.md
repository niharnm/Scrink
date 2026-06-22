# Rinkler Privacy Policy

**Effective date:** [FILL IN — e.g. 2026-06-21]
**Last updated:** [FILL IN]

This policy explains what Rinkler ("Rinkler", "we", "us") collects, why, and what we do not do. Rinkler is a personal focus tool that filters short‑video traffic (such as Instagram Reels and TikTok) on your device to help you scroll less. It is operated by [LEGAL ENTITY / YOUR NAME], contactable at **nihar.manchikalapudi@gmail.com**.

We wrote this to be readable, not to hide things. If anything here is unclear, email us.

---

## 1. The short version

- Rinkler filters traffic **locally on your device** using a VPN configuration (a network filter). Your traffic does **not** get routed through our servers.
- We do **not** read the contents of your messages, posts, photos, or the pages you visit.
- To show you a dashboard and sync your settings, we store a small amount of **metadata** about blocked connections (destination hostnames, byte counts, timestamps, block/allow status) tied to your account.
- We use **Supabase** (database + authentication) and **Apple / Google** sign‑in. That's it for third parties.
- We do **not** sell your data or use it for advertising.

---

## 2. How the on‑device filter works

Rinkler installs a local **VPN configuration** (an Apple Network Extension "packet tunnel"). iOS requires your explicit permission to add it. This is the mechanism that lets Rinkler interrupt short‑video streams.

Important: although it uses the VPN permission, **Rinkler is not a traditional VPN** — it does not send your internet traffic to a remote server or hide your IP address. Filtering happens entirely on your device. The extension only inspects connection **metadata** (for example the destination hostname/SNI and the size of a stream) to decide whether to interrupt short‑video traffic. It does **not** decrypt, read, or store the contents of your encrypted connections.

---

## 3. What we collect

**Account information**
- Your **email address** and a Supabase **user ID** when you sign in (via email code, Apple, or Google). If you use Sign in with Apple's "Hide My Email", we only ever see the relay address Apple provides.

**Usage metadata (for your dashboard and stats)**
When protection is on, Rinkler may record, tied to your account:
- Destination **hostnames** and a coarse **category** (e.g. "short‑video")
- **Block/allow** status and **byte counts**
- **Timestamps** of blocked/allowed connections
- Aggregate **summaries** (counts and time saved) derived from the above

**Focus settings**
- Your rules, schedules, strictness, streaks, and session history. These are stored on your device (in an app group container) and, if you are signed in, associated with your account so they sync.

**We do NOT collect:**
- The **contents** of your traffic, messages, DMs, posts, photos, or browsing.
- Full URLs/paths, request bodies, or packet contents.
- Your location, contacts, photos, microphone, or camera.

---

## 4. Why we collect it

- **Account info** — to authenticate you and sync your Focus System across devices.
- **Usage metadata** — to power your Scroll Report / dashboard (how much short‑video you blocked, time reclaimed) and to make the filter work.
- **Focus settings** — to apply your rules and show your progress and streaks.

We rely on this processing to provide the service you asked for. Where required by law, our basis is performance of our agreement with you and our legitimate interest in operating and improving Rinkler.

---

## 5. Who we share it with (sub‑processors)

- **Supabase** — hosts our database and handles authentication. Your account and usage metadata are stored there. See Supabase's privacy terms.
- **Apple** — Sign in with Apple, and the App Store. Governed by Apple's privacy policy.
- **Google** — only if you choose "Continue with Google" for sign‑in. Governed by Google's privacy policy.

We do not share your data with advertisers or data brokers, and we do not sell it.

### Optional AI insights (off by default)
Rinkler can optionally generate written insights from your **aggregate** dashboard stats using a third‑party AI provider. This is **disabled by default** and only runs if you explicitly opt in. When enabled, only aggregate numbers (not raw events or content) are sent. You can turn it off at any time.

---

## 6. Data retention & deletion

- Usage metadata is retained to show your history and is bounded over time.
- You can **delete your account and associated data** by emailing **nihar.manchikalapudi@gmail.com** (or via the in‑app option if available). We will remove your account record and associated usage data from our database.
- Deleting the app removes the on‑device data (rules, session history, the VPN configuration).

---

## 7. Security

- Auth tokens are stored in the iOS **Keychain**.
- Connections to our backend use HTTPS/TLS.
- Database access is restricted per‑user with row‑level security so you can only read your own data.

No system is perfectly secure, but we keep the data we hold minimal on purpose.

---

## 8. Children

Rinkler is not directed to children under 13 (or the minimum age in your country). If you believe a child under that age has provided us personal information, contact us and we will delete it. If a parent sets Rinkler up for a teen, the same data practices in this policy apply.

---

## 9. Your rights

Depending on where you live, you may have rights to access, correct, export, or delete your personal data, and to object to certain processing. To exercise any of these, email **nihar.manchikalapudi@gmail.com**. We don't discriminate against you for exercising them.

---

## 10. Changes to this policy

If we make material changes, we'll update the "Last updated" date and, where appropriate, notify you in the app. Continued use after changes means you accept the updated policy.

---

## 11. Contact

Questions, requests, or concerns: **nihar.manchikalapudi@gmail.com**.

---

### Implementation notes (delete before publishing)
- Apple requires a **publicly reachable Privacy Policy URL** in App Store Connect. Host this (e.g. as a page on the Rinkler web app `apps/web`, or GitHub Pages) and put that URL in App Store Connect → App Privacy.
- Fill every **[BRACKETED]** placeholder.
- Make sure the **App Privacy "nutrition labels"** in App Store Connect match this policy (see `docs/APP_STORE_METADATA.md`). Apple rejects mismatches.
- If you ship the optional AI insights feature, name the provider here.
