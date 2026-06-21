import Landing from "@/components/marketing/Landing";

// The public marketing site. The dashboard lives at /dashboard (auth-gated);
// the "Open dashboard" CTAs link there and the middleware sends signed-out
// visitors to /login as needed.
export default function Home() {
  return <Landing />;
}
