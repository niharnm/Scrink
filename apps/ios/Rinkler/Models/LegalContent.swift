import Foundation

/// The Privacy Policy and Terms of Service, mirrored from the marketing site so
/// the in-app legal screens show the same content (and work offline / at review).
/// Keep in sync with apps/web/app/{privacy,terms}/page.tsx.
enum LegalContent {
    static let contactEmail = "nihar.manchikalapudi@gmail.com"
    static let effective = "June 2026"

    enum Block {
        case text(String)
        case bullets([String])
    }

    struct Doc: Identifiable {
        var id: String { title }
        let title: String
        let lead: String
        let sections: [(title: String, body: [Block])]
    }

    static let privacy = Doc(
        title: "Privacy Policy",
        lead: "This explains what Rinkler collects, why, and what we don't do. Rinkler is a personal focus tool that filters short-video traffic on your device to help you scroll less. We wrote this to be readable, not to hide things — if anything is unclear, email \(contactEmail).",
        sections: [
            ("The short version", [
                .bullets([
                    "Rinkler filters traffic locally on your device using a private VPN configuration. Your traffic is not routed through our servers.",
                    "We do not read the contents of your messages, posts, photos, or the pages you visit.",
                    "To show your dashboard and sync settings, we store a small amount of metadata about blocked connections (destination hostnames, byte counts, timestamps, block status), tied to your account.",
                    "We use Supabase (database + auth) and Apple / Google sign-in. We do not sell your data or use it for ads.",
                ]),
            ]),
            ("How the on-device filter works", [
                .text("Rinkler installs a local VPN configuration (an Apple Network Extension). iOS requires your explicit permission to add it. Although it uses the VPN permission, Rinkler is not a traditional VPN — it does not send your traffic to a remote server or hide your IP address."),
                .text("The filter only inspects connection metadata (such as the destination hostname and the size of a stream) to decide whether to interrupt short-video traffic. It does not decrypt, read, or store the contents of your connections."),
            ]),
            ("What we collect", [
                .text("Account information — your email address and a user ID when you sign in (email code, Apple, or Google). If you use Apple's Hide My Email, we only ever see the relay address."),
                .text("Usage metadata — when protection is on, tied to your account:"),
                .bullets([
                    "Destination hostnames and a coarse category (e.g. \"short-video\")",
                    "Block/allow status and byte counts",
                    "Timestamps of blocked/allowed connections",
                    "Aggregate summaries (counts and time saved)",
                ]),
                .text("Focus settings — your rules, schedules, strictness, streaks, and session history (stored on your device and, if signed in, synced to your account)."),
                .text("We do NOT collect the contents of your traffic, messages, posts, photos, browsing, full URLs, request bodies, packet contents, your location, contacts, microphone, or camera."),
            ]),
            ("Who we share it with", [
                .text("Supabase — hosts our database and handles authentication. Apple — Sign in with Apple and the App Store. Google — only if you choose \"Continue with Google\". We do not share data with advertisers or data brokers, and we do not sell it."),
                .text("Optional AI insights (off by default): Rinkler can generate written insights from your aggregate dashboard stats using a third-party AI provider. This is disabled by default and only runs if you explicitly opt in; only aggregate numbers, never raw events or content, are sent."),
            ]),
            ("Retention & deletion", [
                .text("Usage metadata is retained to show your history and is bounded over time. You can delete your account and associated data by emailing us. Deleting the app removes on-device data (rules, history, the VPN configuration)."),
            ]),
            ("Security", [
                .text("Auth tokens are stored in the iOS Keychain. Connections to our backend use HTTPS/TLS. Database access is restricted per-user with row-level security, so you can only read your own data."),
            ]),
            ("Children", [
                .text("Rinkler is not directed to children under 13 (or the minimum age in your country). If you believe a child under that age has provided us personal information, contact us and we will delete it."),
            ]),
            ("Your rights", [
                .text("Depending on where you live, you may have rights to access, correct, export, or delete your personal data, and to object to certain processing. Email us to exercise any of these. We don't discriminate against you for doing so."),
            ]),
            ("Changes", [
                .text("If we make material changes, we'll update the effective date and, where appropriate, notify you in the app. Continued use after changes means you accept the updated policy."),
            ]),
        ]
    )

    static let terms = Doc(
        title: "Terms of Service",
        lead: "The plain-English version is first; the rest fills in the details. Questions? Email \(contactEmail).",
        sections: [
            ("The short version", [
                .bullets([
                    "Rinkler is a personal focus tool that filters short-video feeds on your device. It helps you scroll less.",
                    "It's a digital-wellbeing tool, not a security product, and not a guarantee. It does its best to interrupt the feed, but it can't promise it catches everything.",
                    "Use it for yourself, don't abuse it, and you're responsible for your own device and choices.",
                    "We provide it as-is, and we're not liable for indirect damages. These terms can change.",
                ]),
            ]),
            ("What Rinkler is", [
                .text("Rinkler runs an on-device filter that interrupts short-video traffic (like Instagram Reels and TikTok) based on rules you set. It's meant to help you spend less time scrolling. It is not antivirus, parental-control certification, or a content-security guarantee."),
            ]),
            ("Who can use it", [
                .text("You need to be at least 13 (or the minimum age in your country). If you're under 18, you should have a parent or guardian's permission to use Rinkler."),
            ]),
            ("Your account", [
                .text("You can sign in with email, Apple, or Google. You're responsible for keeping access to your account secure and for activity under it. Tell us if you think someone else is using it."),
            ]),
            ("Acceptable use", [
                .text("Please don't:"),
                .bullets([
                    "use Rinkler to break the law or harm others",
                    "reverse engineer, resell, or rent the app, or try to bypass its limits in bad faith",
                    "interfere with the service or other people's use of it",
                    "use it to filter or monitor someone else's device without their knowledge and consent",
                ]),
            ]),
            ("The filter is best-effort", [
                .text("Rinkler works at the network level on your phone. It can reduce and interrupt short-video traffic, but it can't guarantee it blocks every feed, every time. Platforms change how they work, and some traffic may slip through. You understand that Rinkler is a tool to help you, not a promise, and you stay responsible for how you use your device."),
            ]),
            ("Early access, changes, and pricing", [
                .text("Rinkler is in early access. Features may change, break, or go away while we build it. If paid plans are introduced, the price and terms will be shown before you buy, and any purchases made through the App Store are handled and billed by Apple under their terms."),
            ]),
            ("Our content", [
                .text("Rinkler, its name, design, and software are owned by us. You get a personal, limited, non-transferable license to use the app for its intended purpose. You don't get any rights beyond that."),
            ]),
            ("No warranty", [
                .text("Rinkler is provided \"as is\" and \"as available,\" without warranties of any kind, to the extent allowed by law. We don't promise it will be uninterrupted, error-free, or that it will block any specific content."),
            ]),
            ("Limitation of liability", [
                .text("To the extent allowed by law, Rinkler and its maker are not liable for any indirect, incidental, or consequential damages, or for time spent, content seen, or habits formed while using (or not using) the app. Our total liability is limited to what you paid us in the last 12 months, which during early access is likely nothing."),
            ]),
            ("Termination", [
                .text("You can stop using Rinkler and delete your account at any time. We may suspend or end access if these terms are broken, or if we need to stop offering the service."),
            ]),
            ("Changes to these terms", [
                .text("We may update these terms as Rinkler evolves. If the changes are material, we'll update the effective date and, where appropriate, let you know in the app. Continuing to use Rinkler after changes means you accept them."),
            ]),
            ("Contact", [
                .text("Reach out any time at \(contactEmail)."),
            ]),
        ]
    )
}
