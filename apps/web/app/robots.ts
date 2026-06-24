import type { MetadataRoute } from "next";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      // Keep the app/auth surface out of search results.
      disallow: ["/dashboard", "/api/", "/auth/", "/dev/"],
    },
    sitemap: "https://rinkler.app/sitemap.xml",
    host: "https://rinkler.app",
  };
}
