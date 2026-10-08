import { writeFileSync } from "node:fs";

let requestCount = 0;

function makeMessage(model, content, stopReason) {
  return {
    role: "assistant",
    content,
    api: model.api,
    provider: model.provider,
    model: model.id,
    usage: {
      input: 0,
      output: 0,
      cacheRead: 0,
      cacheWrite: 0,
      totalTokens: 0,
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
    },
    stopReason,
    timestamp: Date.now(),
  };
}

async function streamSimple(model, context) {
  const ai = await import(process.env.PI_FIXTURE_AI_MODULE);
  const stream = ai.createAssistantMessageEventStream();
  const messages = context.messages ?? [];
  const calls = messages.flatMap(message => message.role === "assistant"
    ? (message.content ?? []).filter(content => content.type === "toolCall")
    : []);
  const names = ai.getCurrentTools(messages).map(tool => tool.name);
  const request = { request: ++requestCount, toolNames: names, previousModelToolCalls: calls.length };
  writeFileSync(process.env.PI_FIXTURE_PROVIDER_LOG, `${JSON.stringify(request)}\n`, { flag: "a" });

  if (requestCount === 1) {
    const message = makeMessage(model, [{
      type: "toolCall",
      id: "fixed-codemode-call",
      name: "codemode",
      arguments: {
        code: [
          'const file = await tools.read({ path: "fixture.txt" });',
          'await tools.bash({ command: "printf bash-ok > bash-marker.txt" });',
          'const first = await tools.mcp__fixture__echo({ value: "seed" });',
          'const second = await tools.mcp__fixture__echo({ value: first.structuredContent.output });',
          'return JSON.stringify({ file, first, second });',
        ].join("\n"),
      },
    }], "toolUse");
    stream.push({ type: "start", partial: message });
    stream.push({ type: "toolcall_start", contentIndex: 0, partial: message });
    stream.push({ type: "toolcall_end", contentIndex: 0, toolCall: message.content[0], partial: message });
    stream.push({ type: "done", reason: message.stopReason, message });
  } else if (requestCount === 2) {
    const message = makeMessage(model, [{ type: "text", text: "offline native codemode complete" }], "stop");
    stream.push({ type: "start", partial: message });
    stream.push({ type: "text_start", contentIndex: 0, partial: message });
    stream.push({ type: "text_delta", contentIndex: 0, delta: message.content[0].text, partial: message });
    stream.push({ type: "text_end", contentIndex: 0, content: message.content[0].text, partial: message });
    stream.push({ type: "done", reason: message.stopReason, message });
  } else {
    const message = makeMessage(model, [{ type: "text", text: "unexpected fixture model request" }], "stop");
    stream.push({ type: "start", partial: message });
    stream.push({ type: "text_start", contentIndex: 0, partial: message });
    stream.push({ type: "text_delta", contentIndex: 0, delta: message.content[0].text, partial: message });
    stream.push({ type: "text_end", contentIndex: 0, content: message.content[0].text, partial: message });
    stream.push({ type: "done", reason: message.stopReason, message });
  }
  stream.end();
  return stream;
}

export default function register(pi) {
  pi.registerProvider("harness-fixture", {
    name: "Harness fixture provider",
    baseUrl: "http://127.0.0.1:1",
    apiKey: "offline-fixture-key",
    api: "openai-completions",
    models: [{
      id: "offline",
      name: "Offline deterministic fixture",
      reasoning: false,
      input: ["text"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: 8192,
      maxTokens: 1024,
    }],
    streamSimple,
  });

}
