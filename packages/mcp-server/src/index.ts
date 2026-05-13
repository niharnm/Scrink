import { FastMCP } from "fastmcp";
import { registerTools } from "./tools.js";

const server = new FastMCP({
  name: "bubble",
  version: "0.1.0",
  authenticate: async (request) => {
    const token = request.headers["authorization"];
    if (!token || token !== `Bearer ${process.env.MCP_API_KEY}`) {
      throw new Error("Unauthorized");
    }
    return { authenticated: true };
  },
});

registerTools(server);

const transport =
  process.env.MCP_TRANSPORT === "stdio" ? "stdio" : "httpStream";
const port = parseInt(process.env.PORT || process.env.MCP_PORT || "8080", 10);

if (transport === "httpStream") {
  server.start({ transportType: "httpStream", httpStream: { port, host: "0.0.0.0" } });
} else {
  server.start({ transportType: "stdio" });
}
