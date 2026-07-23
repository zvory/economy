#!/usr/bin/env node
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import {
  buildFetchArgs,
  normalizeReport,
  parseArgs,
  renderPrompt,
  resolveHeadBranch,
} from "../scripts/adversarial-quality-pass.mjs";
import { loadPasses, markdownSummary } from "../scripts/agent-pr-passes.mjs";
import {
  phaseMarkedDoneText,
  planNameFromActivePhasePath,
} from "../scripts/archive-completed-plans.mjs";

const repoRoot = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");

assert.equal(parseArgs(["--base", "upstream/trunk", "--dry-run"]).baseRef, "upstream/trunk");
assert.deepEqual(
  buildFetchArgs({ remote: "origin", baseRef: "origin/main" }),
  ["fetch", "origin", "+refs/heads/main:refs/remotes/origin/main"],
);
assert.equal(resolveHeadBranch({ requestedHeadBranch: "", currentBranch: "agent/example" }), "agent/example");
assert.throws(
  () => resolveHeadBranch({ requestedHeadBranch: "agent/a", currentBranch: "agent/b" }),
  /mismatch/,
);
assert.match(renderPrompt({ baseRef: "origin/main", headRef: "HEAD" }), /complete diff/);

const normalized = normalizeReport({
  verdict: "improved",
  summary: "Fixed a problem.",
  issues_found: ["Problem"],
  changes_made: ["Fix"],
  verification: ["Test"],
  remaining_concerns: [],
});
assert.equal(normalized.verdict, "improved");
assert.throws(() => normalizeReport({ verdict: "approved" }), /invalid verdict/);

assert.deepEqual(loadPasses(path.join(repoRoot, "scripts/agent-pr-passes.json")), []);
assert.equal(markdownSummary([]), "");
assert.equal(phaseMarkedDoneText("Status: Done\n"), true);
assert.equal(phaseMarkedDoneText("Status: Not started\n"), false);
assert.equal(planNameFromActivePhasePath("plans/foundation/phase-1.md"), "foundation");
assert.equal(planNameFromActivePhasePath("plans/archive/foundation/phase-1.md"), "");

for (const filename of [
  "adversarial-quality-pass.schema.json",
  "agent-pr-passes.json",
]) {
  JSON.parse(fs.readFileSync(path.join(repoRoot, "scripts", filename), "utf8"));
}

const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "economy-workflows-"));
try {
  const bodyFile = path.join(tempDir, "body.md");
  fs.writeFileSync(bodyFile, `<!-- economy-agent-pr:v1 -->
Agent-Owner: test-agent
Lifecycle-Mode: normal
Agent-Owned: true
Auto-Merge: requested
Focused-Verification: workflow tests passed
Needs-Human: false
<!-- /economy-agent-pr -->
`);
  const ownership = spawnSync(
    "bash",
    ["scripts/check-pr-ownership.sh", "--head-ref", "agent/example", "--body-file", bodyFile],
    { cwd: repoRoot, encoding: "utf8" },
  );
  assert.equal(ownership.status, 0, ownership.stderr);

  const pending = spawnSync("bash", ["scripts/wait-pr.sh", "123", "--once"], {
    cwd: repoRoot,
    encoding: "utf8",
    env: {
      ...process.env,
      ECONOMY_WAIT_PR_VIEW_JSON: JSON.stringify({
        number: 123,
        url: "https://example.invalid/pull/123",
        state: "OPEN",
        mergedAt: null,
        headRefOid: "abc",
        headRefName: "agent/example",
        mergeStateStatus: "BLOCKED",
      }),
      ECONOMY_WAIT_PR_CHECKS_JSON: "[]",
    },
  });
  assert.equal(pending.status, 2, pending.stderr);

  const help = spawnSync("bash", ["scripts/agent-pr.sh", "--help"], {
    cwd: repoRoot,
    encoding: "utf8",
  });
  assert.equal(help.status, 0, help.stderr);
  assert.match(help.stdout, /Usage: scripts\/agent-pr\.sh/);
} finally {
  fs.rmSync(tempDir, { recursive: true, force: true });
}

process.stdout.write("workflow tests passed\n");
