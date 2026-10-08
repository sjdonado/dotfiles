import { appendFileSync } from "node:fs";
import { createInterface } from "node:readline";

const logPath = process.argv[2];
let count = 0;

function respond(id, result) {
  process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", id, result })}\n`);
}

createInterface({ input: process.stdin }).on("line", line => {
  let message;
  try { message = JSON.parse(line); } catch { return; }
  if (message.id === undefined) return;

  if (message.method === "initialize") {
    respond(message.id, {
      protocolVersion: "2025-06-18",
      capabilities: { tools: {} },
      serverInfo: { name: "offline-codemode-fixture", version: "1.0.0" },
    });
  } else if (message.method === "tools/list") {
    respond(message.id, { tools: [{
      name: "echo",
      description: "Return a deterministic value derived from the input.",
      inputSchema: {
        type: "object",
        properties: { value: { type: "string" } },
        required: ["value"],
      },
      outputSchema: {
        type: "object",
        properties: {
          value: { type: "string" },
          output: { type: "string" },
        },
        required: ["value", "output"],
      },
    }] });
  } else if (message.method === "tools/call" && message.params?.name === "echo") {
    const value = String(message.params.arguments?.value ?? "");
    const output = `mcp-${++count}:${value}`;
    appendFileSync(logPath, `${JSON.stringify({ value, output })}\n`);
    respond(message.id, {
      content: [{ type: "text", text: output }],
      structuredContent: { value, output },
    });
  } else {
    process.stdout.write(`${JSON.stringify({
      jsonrpc: "2.0",
      id: message.id,
      error: { code: -32601, message: "Method not found" },
    })}\n`);
  }
});
