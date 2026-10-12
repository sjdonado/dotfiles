import { expect, test } from 'bun:test';
import { spawnSync } from 'node:child_process';
import * as path from 'node:path';

const helper = path.join(import.meta.dir, 'checks/python-validation.py');
const inspect = (source: string, passed: boolean) => {
  const result = spawnSync('python3', [helper], { input: source, encoding: 'utf8', timeout: 5000 });
  expect(result.status).toBe(0);
  expect(result.stderr).toBe('');
  expect(JSON.parse(result.stdout)).toEqual({ passed });
};
const imported = 'from label import label\n';

for (const source of [
  "assert label(' a ') == 'a'",
  "actual = label(' a ')\nexpected = 'a'\nassert actual == expected",
  "cases = [(' a ', 'a'), ('', '')]\nfor text, expected in cases:\n    actual = label(text)\n    assert actual == expected",
  "for text, expected in [(' a ', 'a')]:\n    assert label(text) == expected",
  "def test_label():\n    assert label(' a ') == 'a'\ntest_label()",
  "def test_label():\n    assert label(' a ') == 'a'\nif __name__ == '__main__':\n    test_label()",
  "actual = label(' a ')\ncopy = actual\nassert copy == 'a'",
  "cases = [(' a ', 'a')]\nfor text, expected in cases:\n    assert label(text) == expected\nprint(f'{len(cases)} cases passed')",
]) {
  test(`AST accepts supported assertion shape: ${source}`, () => inspect(imported + source, true));
}

for (const source of [
  'assert True; # label(',
  'raise SystemExit(0); assert label(1) == 2',
  "def test_label():\n    assert label(' a ') == 'a'",
  "if False:\n    assert label(' a ') == 'a'",
  "assert True or label(' a ')",
  "assert False and label(' a ')",
  "assert label(' a ') if False else True",
  "actual = label(' a ')\nactual = True\nassert actual",
  "for text in []:\n    assert label(text) == text",
  "for text in range(1):\n    assert label(text) == text",
  "for text, expected in [(' a ',)]:\n    assert label(text) == expected",
  "while True:\n    assert label(' a ') == 'a'",
  "try:\n    assert label(' a ') == 'a'\nexcept:\n    pass",
  "exit(0)\nassert label(' a ') == 'a'",
  "assert label(' a ') == 'a'\nraise SystemExit(0)",
  "def label(text):\n    return text\nassert label(' a ') == 'a'",
  "label = lambda text: text\nassert label(' a ') == 'a'",
  "def test_label():\n    return\n    assert label(' a ') == 'a'\ntest_label()",
  "def test_label():\n    test_label()\n    assert label(' a ') == 'a'\ntest_label()",
  "def test_label():\n    assert label(' a ') == 'a'\n    label = True\ntest_label()",
  'assert label',
  'assert (',
  "len = label\nprint(f'{len(0)}')\nassert True",
  "print(f'{1:{exit(0)}}')\nassert label(' a ') == 'a'",
]) {
  test(`AST rejects unsupported or unreachable evidence: ${source}`, () => inspect(imported + source, false));
}

test('label calls require the fixture import, with aliases supported', () => {
  inspect("assert label(' a ') == 'a'", false);
  inspect("from label import label as normalize\nassert normalize(' a ') == 'a'", true);
});
test('helper outputs only boolean metadata, not candidate output or source', () => {
  inspect("print('candidate secret marker')\n" + imported + "assert label(' a ') == 'a'", true);
  inspect("import os\nos._exit(0)\n" + imported + "assert label(' a ') == 'a'", false);
});
test('bounded source size fails closed', () => inspect('#'.repeat(100_001), false));

// Exact retained ordinary test file: results-l5wBx2/sol-medium-Akd55g/repo/test_label.py.
test('observed invoked test function with cases, result assignments and idempotence', () => inspect(`from label import label


def test_label():
    cases = [
        ("Release v2.0!", "Release v2.0!"),
        ("  Hello World  ", "Hello World"),
        ("Hello   World", "Hello World"),
        ("\\tHello\\nWorld\\r\\n", "Hello World"),
        ("\\u00a0Hello\\u2003World\\u00a0", "Hello World"),
        ("", ""),
        (" \\t\\n", ""),
        ("MiXeD-case_label!", "MiXeD-case_label!"),
        ("  Café   東京  ", "Café 東京"),
    ]
    for text, expected in cases:
        actual = label(text)
        assert actual == expected, (text, actual, expected)
        assert label(actual) == actual, (text, "not idempotent")


if __name__ == "__main__":
    test_label()
    print("All 9 label cases and idempotence assertions passed.")
`, true));

// Retained direct -c source: results-oGe9IR/luna-medium-JnNvfO/transcript.jsonl:493.
test('observed inline assertions preserve string escape data', () => inspect(String.raw`from label import label; assert label("  NorthStar  ") == "NorthStar"; assert label("  NorthStar\tLaunch\nPartner  ") == "NorthStar Launch Partner"; assert label("nOrThStAr") == "nOrThStAr"; print("label assertions passed")`, true));
