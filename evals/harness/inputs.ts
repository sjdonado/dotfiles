import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

// Frozen fixture skills are historical evidence, never execution inputs.
export function materialize(workdir: string, root: string) {
  const hashes: Record<string, string> = {};
  const record = (source: string, target: string, key: string) => {
    const body = readFileSync(source);
    writeFileSync(target, body);
    hashes[key] = createHash("sha256").update(body).digest("hex");
  };
  const guidance = readFileSync(join(workdir, "AGENTS.md"), "utf8");
  record(join(root, "agents/AGENTS.md"), join(workdir, "AGENTS.md"), "agents/AGENTS.md");
  writeFileSync(join(workdir, "AGENTS.md"), readFileSync(join(workdir, "AGENTS.md"), "utf8") + "\n" + guidance);
  const names = ["proto", "ponytail", "ask", "feedback", "land", "yolo", "verification", "address-review", "harness-boostrap"];
  const walk = (source: string, target: string, key: string) => {
    mkdirSync(target, { recursive: true });
    for (const entry of readdirSync(source, { withFileTypes: true })) {
      if (entry.isDirectory()) walk(join(source, entry.name), join(target, entry.name), `${key}/${entry.name}`);
      else record(join(source, entry.name), join(target, entry.name), `${key}/${entry.name}`);
    }
  };
  for (const name of names) walk(join(root, "agents/skills", name), join(workdir, ".agents/skills", name), `agents/skills/${name}`);
  hashes["materialized/AGENTS.md"] = createHash("sha256").update(readFileSync(join(workdir, "AGENTS.md"))).digest("hex");
  return hashes;
}

// Hash only execution inputs, never generated runs or obsolete fixture skills.
export function sourceHashes(root: string, fixture: string) {
  const hashes: Record<string, string> = {};
  const walk = (key: string) => {
    for (const entry of readdirSync(join(root, key), { withFileTypes: true })) {
      if ([".agents", ".git"].includes(entry.name) || /^\.env(?:\.|$)/.test(entry.name)) continue;
      const path = `${key}/${entry.name}`;
      if (entry.isDirectory()) walk(path);
      else hashes[`evals/harness/${path}`] = createHash("sha256").update(readFileSync(join(root, path))).digest("hex");
    }
  };
  for (const key of ["run.ts", "inputs.ts", "gh.ts", "scenarios.json"])
    hashes[`evals/harness/${key}`] = createHash("sha256").update(readFileSync(join(root, key))).digest("hex");
  hashes["pi/settings.json"] = createHash("sha256").update(readFileSync(join(root, "../../pi/settings.json"))).digest("hex");
  walk("checks"); walk(fixture.replace(/^\.\//, ""));
  return hashes;
}
