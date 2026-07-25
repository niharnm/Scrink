import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Rinkler",
    short_name: "Rinkler",
    description: "block selected apps with Screen Time, with optional experimental network filters.",
    start_url: "/",
    display: "standalone",
    background_color: "#08080A",
    theme_color: "#08080A",
    icons: [
      { src: "/rinkler-mark.png", sizes: "512x512", type: "image/png", purpose: "any" },
      { src: "/rinkler-icon-1024.png", sizes: "1024x1024", type: "image/png", purpose: "any" },
    ],
  };
}
