import { FastMCP } from "fastmcp";
import { registerTools } from "./tools.js";

const transport =
  process.env.MCP_TRANSPORT === "stdio" ? "stdio" : "httpStream";

const apiKey = process.env.MCP_API_KEY;

// The HTTP transport is network-reachable and the tools run with the Supabase
// service-role key (full DB access), so it must never run without a real
// shared secret. Without this guard an unset MCP_API_KEY would make the auth
// check `token !== "Bearer undefined"`, letting `Bearer undefined` through.
if (transport === "httpStream" && (!apiKey || apiKey.length < 16)) {
  throw new Error(
    "MCP_API_KEY must be set to a strong secret (>=16 chars) when running the HTTP transport."
  );
}

const server = new FastMCP({
  name: "rinkler",
  version: "0.1.0",
  authenticate: async (request) => {
    // stdio transport is local-only and has no HTTP headers to authenticate.
    if (transport === "stdio") {
      return { authenticated: true };
    }
    const token = request.headers["authorization"];
    if (!apiKey || token !== `Bearer ${apiKey}`) {
      throw new Error("Unauthorized");
    }
    return { authenticated: true };
  },
});

registerTools(server);

const port = parseInt(process.env.PORT || process.env.MCP_PORT || "8080", 10);
// Default to loopback; set MCP_HOST=0.0.0.0 only when fronted by a proxy/LB.
const host = process.env.MCP_HOST || "127.0.0.1";

if (transport === "httpStream") {
  server.start({ transportType: "httpStream", httpStream: { port, host } });
} else {
  server.start({ transportType: "stdio" });
}
