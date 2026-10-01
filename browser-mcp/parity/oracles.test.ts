import { expect, test } from "bun:test";
import { check, scenarios } from "./scenarios.ts";

const sc = (id: string) => scenarios.find((s) => s.id === id)!;
const ok = (id: string, answer: string, log: { event: string; value: string }[] = [], calls: { name: string; isError?: boolean }[] = [], server = "browser") =>
  check(sc(id), answer, log, calls, server).every((o) => o.pass);

test("event-listener: ANSWER line, id case-insensitive, logged text case-sensitive", () => {
  const p = (l: string) => ok("event-listener", `The go button has a handler.\n${l}`);
  expect(p("ANSWER: go | GO-CLICKED")).toBe(true);
  expect(p("ANSWER: #go | GO-CLICKED")).toBe(true);
  expect(p("ANSWER: `GO` | `GO-CLICKED`")).toBe(true);
  expect(p("ANSWER: stop | GO-CLICKED")).toBe(false);
  expect(p("ANSWER: go | go-clicked")).toBe(false);
  expect(p("ANSWER: go- | GO-CLICKED")).toBe(false);
  expect(ok("event-listener", 'The "go" button logs GO-CLICKED.')).toBe(false);
  // Only the last ANSWER line counts.
  expect(ok("event-listener", "ANSWER: go | GO-CLICKED\nANSWER: stop | GO-CLICKED")).toBe(false);
});

test("failed-request: ANSWER line pairs each path with its own status", () => {
  const p = (l: string) => ok("failed-request", `Two requests failed.\n${l}`);
  expect(p("ANSWER: /api/broken 500, /api/missing 404")).toBe(true);
  expect(p("ANSWER: /api/missing 404, /api/broken 500")).toBe(true);
  expect(p("ANSWER: `/api/broken` HTTP 500, `/api/missing` HTTP 404")).toBe(true);
  expect(p("ANSWER: /api/broken 404, /api/missing 500")).toBe(false);
  expect(p("ANSWER: /api/broken 500, /api/missing 404, /api/ok 200")).toBe(false);
  expect(p("ANSWER: /api/broken 500")).toBe(false);
  expect(ok("failed-request", "/api/broken returned 500, /api/missing returned 404")).toBe(false);
});

test("console-errors: ANSWER line lists both errors and 2 warnings", () => {
  const p = (l: string) => ok("console-errors", `Findings below.\n${l}`);
  expect(p("ANSWER: PARITY_ERR_1, PARITY_ERR_2 | 2")).toBe(true);
  expect(p("ANSWER: PARITY_ERR_2, PARITY_ERR_1 | two")).toBe(true);
  expect(p("ANSWER: PARITY_ERR_1, PARITY_ERR_2 | 3")).toBe(false);
  expect(p("ANSWER: PARITY_ERR_1 | 2")).toBe(false);
  expect(p("ANSWER: PARITY_ERR_1, PARITY_ERR_2")).toBe(false);
  expect(ok("console-errors", "PARITY_ERR_1, PARITY_ERR_2. There were two warnings")).toBe(false);
});

test("geolocation: echoing the prompt without the page log fails", () => {
  expect(ok("geolocation", "The page prints 40.7128, -74.006")).toBe(false);
  expect(ok("geolocation", "The page prints 40.7128, -74.006", [{ event: "geo", value: "40.7128,-74.006" }])).toBe(true);
});

test("cleanup: close must come after the last open", () => {
  const a = "Page A heading";
  const close = { name: "browser_close" };
  const open = { name: "browser_open" };
  expect(ok("cleanup", a, [], [close, open])).toBe(false);
  expect(ok("cleanup", a, [], [open, close])).toBe(true);
  expect(ok("cleanup", a, [], [open, { name: "browser_close", isError: true }])).toBe(false);
  expect(ok("cleanup", a, [], [{ name: "safari_close_tab" }, { name: "safari_navigate_to_url" }], "safari")).toBe(false);
  expect(ok("cleanup", a, [], [{ name: "safari_navigate_to_url" }, { name: "safari_close_tab" }], "safari")).toBe(true);
});

test("screenshot-color: reddish is not red", () => {
  expect(ok("screenshot-color", "The square is red.")).toBe(true);
  expect(ok("screenshot-color", "The square is reddish.")).toBe(false);
});

test("lcp-element: paragraph fails", () => {
  expect(ok("lcp-element", "The LCP element is img#i7.")).toBe(true);
  expect(ok("lcp-element", "The LCP element is p#t3.")).toBe(false);
});
