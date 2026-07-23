#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const DEFAULT_BASE_REF = "origin/main";
const DEFAULT_CONTEXT = "adversarial-quality-pass";
const DEFAULT_REMOTE = "origin";
const VERDICTS = new Set(["passed_unchanged", "improved", "improved_with_concerns"]);
export const QUALITY_PASS_ENV = "ECONOMY_ADVERSARIAL_QUALITY_PASS";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const defaultRepoRoot = path.resolve(scriptDir, "..");
const defaultSchemaFile = path.join(scriptDir, "adversarial-quality-pass.schema.json");

export function usage() {
  return `Usage: scripts/adversarial-quality-pass.mjs [options]

Runs the final autonomous quality pass for the current branch. The pass reviews
origin/main..HEAD, may improve and commit the branch, optionally pushes it, and
optionally posts a GitHub commit status on the final head.

Options:
  --base REF                  Base ref to review. Default: ${DEFAULT_BASE_REF}
  --head-branch BRANCH        Branch to push/status. Default: current branch.
  --context NAME              Commit status context. Default: ${DEFAULT_CONTEXT}
  --repo DIR                  Repository root. Default: script parent.
  --schema FILE               JSON schema passed to Codex.
  --report-file FILE          JSON report output. Default: temporary file.
  --markdown-report-file FILE Optional Markdown report for the PR body.
  --codex-command COMMAND     Codex CLI command. Default: codex.
  --codex-model MODEL         Optional model passed to Codex.
  --gh-bin COMMAND            GitHub CLI command. Default: gh.
  --remote NAME               Git remote for fetch/push. Default: origin.
  --post-status               Post a success status on the final head.
  --push                      Push the final head.
  --no-fetch                  Skip fetching the base branch.
  --dry-run                   Print the prompt and commands without running them.
  -h, --help                  Show this help.
`;
}

function usageError(message) {
  const error = new Error(message);
  error.exitCode = 2;
  return error;
}

export function parseArgs(argv) {
  const options = {
    baseRef: DEFAULT_BASE_REF,
    codexCommand: "codex",
    codexModel: "",
    context: DEFAULT_CONTEXT,
    dryRun: false,
    fetchBase: true,
    ghBin: "gh",
    headBranch: "",
    help: false,
    markdownReportFile: "",
    postStatus: false,
    push: false,
    remote: DEFAULT_REMOTE,
    reportFile: "",
    repoRoot: defaultRepoRoot,
    schemaFile: defaultSchemaFile,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    const value = (name) => {
      const inline = `${name}=`;
      if (arg.startsWith(inline)) return arg.slice(inline.length);
      index += 1;
      if (index >= argv.length || argv[index].startsWith("--")) {
        throw usageError(`${name} requires a value`);
      }
      return argv[index];
    };

    if (arg === "-h" || arg === "--help") options.help = true;
    else if (arg === "--base" || arg.startsWith("--base=")) options.baseRef = value("--base");
    else if (arg === "--head-branch" || arg.startsWith("--head-branch=")) options.headBranch = value("--head-branch");
    else if (arg === "--context" || arg.startsWith("--context=")) options.context = value("--context");
    else if (arg === "--repo" || arg.startsWith("--repo=")) options.repoRoot = path.resolve(value("--repo"));
    else if (arg === "--schema" || arg.startsWith("--schema=")) options.schemaFile = path.resolve(value("--schema"));
    else if (arg === "--report-file" || arg.startsWith("--report-file=")) options.reportFile = path.resolve(value("--report-file"));
    else if (arg === "--markdown-report-file" || arg.startsWith("--markdown-report-file=")) options.markdownReportFile = path.resolve(value("--markdown-report-file"));
    else if (arg === "--codex-command" || arg.startsWith("--codex-command=")) options.codexCommand = value("--codex-command");
    else if (arg === "--codex-model" || arg.startsWith("--codex-model=")) options.codexModel = value("--codex-model");
    else if (arg === "--gh-bin" || arg.startsWith("--gh-bin=")) options.ghBin = value("--gh-bin");
    else if (arg === "--remote" || arg.startsWith("--remote=")) options.remote = value("--remote");
    else if (arg === "--post-status") options.postStatus = true;
    else if (arg === "--push") options.push = true;
    else if (arg === "--no-fetch") options.fetchBase = false;
    else if (arg === "--dry-run") options.dryRun = true;
    else throw usageError(`unknown argument: ${arg}`);
  }
  return options;
}

export function renderPrompt({ baseRef, headRef }) {
  return `You are the final autonomous quality pass for this branch.

Assume no human will review this and no later agent will clean it up. Leave the best coherent system
you can. The outer helper owns pushing and pull-request lifecycle; do not invoke those helpers.

Read the repository guidance, then review the complete diff from ${baseRef} to ${headRef}. Inspect
surrounding code and documentation where needed to understand the change.

Focus on:
1. Correctness, security, data-loss, and lifecycle bugs.
2. Architectural choices that make the whole system harder to understand or extend.
3. Missing or inadequate verification for behavior changed by the branch.
4. Inaccurate documentation or user-facing notes caused by the change.
5. Any other issue important enough to fix before merge.

You may improve the branch directly. Prefer the simplest resulting system over the smallest diff.
Do not expand product scope or invent requirements. If a larger ideal rewrite cannot be completed
coherently, make only improvements that leave the branch working and record the remaining concern.

Commit any changes you make and run focused verification appropriate to the final state.

Return JSON with:
{
  "verdict": "passed_unchanged | improved | improved_with_concerns",
  "summary": "...",
  "issues_found": [],
  "changes_made": [],
  "verification": [],
  "remaining_concerns": []
}
`;
}

export function buildCodexArgs({ repoRoot, gitCommonDir, schemaFile, reportFile, codexModel, prompt }) {
  const args = ["exec", "--cd", repoRoot];
  if (gitCommonDir) args.push("--add-dir", gitCommonDir);
  args.push(
    "--sandbox", "workspace-write",
    "-c", 'approval_policy="never"',
    "--ephemeral",
    "--output-schema", schemaFile,
    "--output-last-message", reportFile,
  );
  if (codexModel) args.push("--model", codexModel);
  args.push(prompt);
  return args;
}

export function buildFetchArgs({ remote, baseRef }) {
  const prefix = `${remote}/`;
  const branch = baseRef.startsWith(prefix)
    ? baseRef.slice(prefix.length)
    : baseRef.includes("/") ? "" : baseRef;
  return branch
    ? ["fetch", remote, `+refs/heads/${branch}:refs/remotes/${remote}/${branch}`]
    : ["fetch", remote, baseRef];
}

function cleanString(value) {
  return typeof value === "string" ? value.trim() : "";
}

function normalizeStringArray(value) {
  return Array.isArray(value) ? value.map(cleanString).filter(Boolean) : [];
}

function parseJsonObject(raw) {
  const text = String(raw || "").trim();
  try {
    return JSON.parse(text);
  } catch {
    const fenced = /```(?:json)?\s*([\s\S]*?)```/i.exec(text);
    if (fenced) return JSON.parse(fenced[1]);
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}");
    if (start >= 0 && end > start) return JSON.parse(text.slice(start, end + 1));
    throw new Error("quality pass report was not parseable JSON");
  }
}

export function normalizeReport(raw) {
  const parsed = typeof raw === "string" ? parseJsonObject(raw) : raw;
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("quality pass report must be a JSON object");
  }
  const verdict = cleanString(parsed.verdict);
  if (!VERDICTS.has(verdict)) {
    throw new Error(`quality pass report has invalid verdict: ${verdict || "<missing>"}`);
  }
  return {
    verdict,
    summary: cleanString(parsed.summary),
    issues_found: normalizeStringArray(parsed.issues_found),
    changes_made: normalizeStringArray(parsed.changes_made),
    verification: normalizeStringArray(parsed.verification),
    remaining_concerns: normalizeStringArray(parsed.remaining_concerns),
  };
}

export function resolveHeadBranch({ requestedHeadBranch, currentBranch }) {
  const current = cleanString(currentBranch);
  const requested = cleanString(requestedHeadBranch);
  if (!current) throw new Error("quality pass requires a named branch");
  if (requested && requested !== current) {
    throw new Error(`quality pass branch mismatch: current='${current}' requested='${requested}'`);
  }
  return requested || current;
}

export function markdownReport(report) {
  const list = (items) => items.length ? items.map((item) => `- ${item}`).join("\n") : "- None.";
  return [
    "## Adversarial quality pass", "",
    `Verdict: ${report.verdict}`, "",
    "### Summary", "", report.summary || "Not recorded.", "",
    "### Issues found", "", list(report.issues_found), "",
    "### Changes made", "", list(report.changes_made), "",
    "### Verification", "", list(report.verification), "",
    "### Remaining concerns", "", list(report.remaining_concerns), "",
  ].join("\n");
}

function autoCommitBody(report) {
  return `Verdict: ${report.verdict}\n\n${report.summary || "No summary recorded."}`;
}

function statusDescription(report) {
  const suffix = report.remaining_concerns.length
    ? `; ${report.remaining_concerns.length} concern(s)`
    : "";
  return `${report.verdict.replaceAll("_", " ")}${suffix}`.slice(0, 140);
}

function run(command, args, { cwd, env = {}, capture = false } = {}) {
  const result = spawnSync(command, args, {
    cwd,
    env: { ...process.env, ...env },
    encoding: capture ? "utf8" : undefined,
    stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) {
    const detail = capture && (result.stderr?.trim() || result.stdout?.trim());
    throw new Error(detail || `${command} exited ${result.status}`);
  }
  return capture ? result.stdout.trim() : "";
}

function git(repoRoot, args) {
  return run("git", args, { cwd: repoRoot, capture: true });
}

function shellQuote(value) {
  return `'${String(value).replaceAll("'", "'\\''")}'`;
}

export function execute(options) {
  if (options.help) {
    process.stdout.write(usage());
    return;
  }
  if (!fs.existsSync(options.schemaFile)) {
    throw new Error(`missing quality pass schema: ${options.schemaFile}`);
  }

  const headBranch = resolveHeadBranch({
    requestedHeadBranch: options.headBranch,
    currentBranch: git(options.repoRoot, ["branch", "--show-current"]),
  });
  const reportFile = options.reportFile
    || path.join(os.tmpdir(), `economy-quality-pass-${process.pid}.json`);
  const prompt = renderPrompt({ baseRef: options.baseRef, headRef: "HEAD" });
  const codexArgs = buildCodexArgs({
    repoRoot: options.repoRoot,
    gitCommonDir: git(options.repoRoot, ["rev-parse", "--path-format=absolute", "--git-common-dir"]),
    schemaFile: options.schemaFile,
    reportFile,
    codexModel: options.codexModel,
    prompt,
  });

  if (options.dryRun) {
    process.stdout.write(`quality-pass: would run ${options.codexCommand} ${codexArgs.map(shellQuote).join(" ")}\n`);
    process.stdout.write(prompt);
    return;
  }

  const status = git(options.repoRoot, ["status", "--porcelain=v1"]);
  if (status) throw new Error(`quality pass requires a clean worktree:\n${status}`);
  if (options.fetchBase) {
    run("git", buildFetchArgs({ remote: options.remote, baseRef: options.baseRef }), {
      cwd: options.repoRoot,
    });
  }

  const beforeHead = git(options.repoRoot, ["rev-parse", "HEAD"]);
  process.stdout.write(`quality-pass: reviewing ${headBranch}\n`);
  run(options.codexCommand, codexArgs, {
    cwd: options.repoRoot,
    env: { [QUALITY_PASS_ENV]: "1" },
  });
  if (!fs.existsSync(reportFile)) {
    throw new Error(`quality pass did not write report: ${reportFile}`);
  }
  const report = normalizeReport(fs.readFileSync(reportFile, "utf8"));

  const dirty = git(options.repoRoot, ["status", "--porcelain=v1"]);
  if (dirty) {
    run("git", ["add", "-A"], { cwd: options.repoRoot });
    run("git", ["commit", "-m", "Run adversarial quality pass", "-m", autoCommitBody(report)], {
      cwd: options.repoRoot,
    });
  }
  const finalHead = git(options.repoRoot, ["rev-parse", "HEAD"]);
  if (finalHead === beforeHead) process.stdout.write("quality-pass: final state unchanged\n");
  if (options.markdownReportFile) {
    fs.writeFileSync(options.markdownReportFile, markdownReport(report));
  }
  if (options.push) {
    run("git", ["push", "-u", options.remote, `HEAD:refs/heads/${headBranch}`], {
      cwd: options.repoRoot,
    });
  }
  if (options.postStatus) {
    run(options.ghBin, [
      "api", "-X", "POST", `repos/:owner/:repo/statuses/${finalHead}`,
      "-f", "state=success",
      "-f", `context=${options.context}`,
      "-f", `description=${statusDescription(report)}`,
    ], { cwd: options.repoRoot });
  }
  process.stdout.write(`quality-pass: verdict ${report.verdict}\n${markdownReport(report)}`);
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    execute(parseArgs(process.argv.slice(2)));
  } catch (error) {
    process.stderr.write(`${error.message}\n`);
    if (error.exitCode === 2) process.stderr.write(usage());
    process.exit(error.exitCode || 1);
  }
}
