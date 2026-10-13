// OpenCode v2 server plugin: refuse a foreground shell call that starts by sleeping, such as `sleep 60; cat out.log`.
// Waiting belongs in a background shell, whose completion notifies the session. Throwing from tool execute.before
// blocks the call, and the error text is what the model reads. Plugin.define is the identity, so no import is needed.

const LEADING_SLEEP = /^\s*sleep\s+(\d+(?:\.\d+)?)([smhd]?)\s*(?:$|[;&|\n])/;
const SECONDS: Record<string, number> = { "": 1, s: 1, m: 60, h: 3600, d: 86400 };
const ALLOWED_SECONDS = 2;

const blocked = (input: { command?: unknown; background?: unknown }) => {
  if (input.background === true || typeof input.command !== "string") return false;
  const match = input.command.match(LEADING_SLEEP);
  return !!match && Number(match[1]) * SECONDS[match[2]] > ALLOWED_SECONDS;
};

export default {
  id: "dotfiles.no-foreground-wait",
  async setup(ctx: any) {
    await ctx.tool.hook("execute.before", (event: { tool: string; input: unknown }) => {
      if (event.tool !== "shell" || !blocked((event.input ?? {}) as { command?: unknown; background?: unknown })) return;
      throw new Error(
        "Blocked: a foreground shell call that starts with sleep. To wait for a command, run it with background: true and end your turn or keep working; its completion notifies you. To wait for a condition, run one background until-loop (until <check>; do sleep 2; done). Do not chain shorter sleeps to work around this block.",
      );
    });
  },
};
