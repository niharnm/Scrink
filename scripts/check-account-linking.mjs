#!/usr/bin/env node
/**
 * check-account-linking.mjs
 *
 * Confirms that "Apple sign-in on the phone" and "Apple sign-in on the website"
 * land on ONE Supabase account per person — i.e. your phone's data and the web
 * dashboard share the same user_id.
 *
 * It prints only aggregate counts + the actual red flags. It does NOT dump every
 * user's email into your terminal.
 *
 * Usage (PowerShell):
 *   $env:SUPABASE_URL = "https://jeorvakbhgdytwhjhlfi.supabase.co"
 *   $env:SUPABASE_SECRET_KEY = "<your service_role / secret key>"
 *   node scripts/check-account-linking.mjs
 *
 * Get the secret key from: Supabase dashboard -> Project Settings -> API ->
 * "service_role" (or the new "secret" key). Treat it like a password; never commit it.
 *
 * What to look for:
 *   - "emails on more than one account"  -> 0 is good. Anything > 0 means the same
 *     person has TWO accounts (usually native Apple vs web Apple returning a
 *     different `sub`). That's the failure where the website won't see the phone's
 *     data. Fix: associate the Services ID (com.rinkler.web) with the primary
 *     App ID (com.rinkler.app) in the Apple Developer portal so Apple returns one sub.
 *   - "apple sub shared by >1 user"      -> 0 is good (should be impossible, listed
 *     for completeness).
 */

const URL = process.env.SUPABASE_URL;
const KEY = process.env.SUPABASE_SECRET_KEY;

if (!URL || !KEY) {
  console.error("Set SUPABASE_URL and SUPABASE_SECRET_KEY env vars first. See the header of this file.");
  process.exit(1);
}

const mask = (s) => {
  if (!s) return "(none)";
  const [name, domain] = String(s).split("@");
  if (!domain) return name.slice(0, 2) + "***";
  return name.slice(0, 2) + "***@" + domain;
};

const res = await fetch(`${URL.replace(/\/$/, "")}/auth/v1/admin/users?per_page=1000`, {
  headers: { apikey: KEY, Authorization: `Bearer ${KEY}` },
});
if (!res.ok) {
  console.error(`Auth admin request failed: ${res.status} ${await res.text()}`);
  process.exit(1);
}
const { users = [] } = await res.json();

// Count identities by provider.
const providerCounts = {};
// Group users by email to catch split accounts (same person, two user rows).
const usersByEmail = {};
// Group apple identities by `sub` to catch the (shouldn't-happen) shared-sub case.
const usersByAppleSub = {};

for (const u of users) {
  if (u.email) (usersByEmail[u.email.toLowerCase()] ||= new Set()).add(u.id);
  for (const i of u.identities || []) {
    providerCounts[i.provider] = (providerCounts[i.provider] || 0) + 1;
    if (i.provider === "apple") {
      const sub = i.identity_data?.sub;
      if (sub) (usersByAppleSub[sub] ||= new Set()).add(u.id);
    }
  }
}

const dupEmails = Object.entries(usersByEmail).filter(([, set]) => set.size > 1);
const sharedSubs = Object.entries(usersByAppleSub).filter(([, set]) => set.size > 1);

console.log("\n=== Rinkler account-linking check ===");
console.log("total user accounts:", users.length);
console.log("identities by provider:", JSON.stringify(providerCounts));
console.log("");
console.log("emails on more than one account:", dupEmails.length, dupEmails.length === 0 ? "(good)" : "(PROBLEM — same person, split accounts)");
for (const [email, set] of dupEmails) {
  console.log("   -> " + mask(email) + " appears on " + set.size + " accounts");
}
console.log("apple sub shared by >1 user:", sharedSubs.length, sharedSubs.length === 0 ? "(good)" : "(PROBLEM)");

console.log("");
if (dupEmails.length === 0 && sharedSubs.length === 0) {
  console.log("PASS: one account per person. Phone + web Apple sign-in unify correctly.");
} else {
  console.log("CHECK: a person has more than one account. See the header notes for the Apple Services-ID fix.");
}
console.log("");
console.log("How to fully verify the pipeline once the iOS app builds:");
console.log("  1. Sign in with Apple on the phone, then on rinkler.app.");
console.log("  2. Re-run this script — total accounts should NOT increase, and dupEmails must stay 0.");
console.log("  3. Generate some traffic on the phone, refresh the web dashboard -> the same numbers appear.");
