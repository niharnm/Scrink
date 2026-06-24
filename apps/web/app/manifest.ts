import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "Rinkler",
    short_name: "Rinkler",
    description: "kill the endless scroll, not your whole phone.",
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
