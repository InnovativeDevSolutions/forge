#!/usr/bin/env node
import { execFileSync } from "node:child_process";

const BRANCHES = {
    master: "master",
    dev: "pre-v0.2",
    missions: "missions/local-mission-copies",
    archive: "archive/pre-v0.1-history",
};

const REQUIRED_BRANCHES = [BRANCHES.master, BRANCHES.dev, BRANCHES.archive];

const MISSION_DIRS = [
    "arma/forge_framework.Malden",
    "arma/forge_pmc_simulator.Tanoa",
    "arma/forge_pmc_simulator_v2.Tanoa",
];

function runGit(args, options = {}) {
    const result = execFileSync("git", args, {
        encoding: "utf8",
        stdio: options.stdio ?? ["ignore", "pipe", "pipe"],
    });

    return typeof result === "string" ? result.trim() : "";
}

function tryGit(args) {
    try {
        return runGit(args);
    } catch {
        return "";
    }
}

function printHelp() {
    console.log(`Forge Git workflow helper

Usage:
  node tools/git-workflow.mjs status
  node tools/git-workflow.mjs doctor
  node tools/git-workflow.mjs switch <master|dev|missions|archive> [--allow-dirty]
  node tools/git-workflow.mjs start-feature <name>
  node tools/git-workflow.mjs release-check

Examples:
  npm run workflow -- status
  npm run workflow -- switch dev
  npm run workflow -- switch missions
  npm run workflow -- start-feature cad-task-request
  npm run workflow -- release-check
`);
}

function currentBranch() {
    return runGit(["branch", "--show-current"]);
}

function statusLines() {
    const status = runGit(["status", "--short", "--branch"]);
    return status.split(/\r?\n/).filter(Boolean);
}

function isDirty() {
    return runGit(["status", "--porcelain"]).length > 0;
}

function ensureClean({ allowDirty = false } = {}) {
    if (!allowDirty && isDirty()) {
        console.error("Working tree has changes. Commit, stash, or pass --allow-dirty.");
        process.exit(1);
    }
}

function branchExists(branchName) {
    return tryGit(["rev-parse", "--verify", branchName]).length > 0;
}

function trackedPaths(ref, paths) {
    return paths.filter((path) => {
        return tryGit(["ls-tree", "-d", "--name-only", ref, path]) === path;
    });
}

function printStatus() {
    console.log(statusLines().join("\n"));
    console.log("");
    console.log(`Current branch: ${currentBranch() || "(detached)"}`);
    console.log(`Dirty: ${isDirty() ? "yes" : "no"}`);

    const missionPaths = trackedPaths("HEAD", MISSION_DIRS);
    if (missionPaths.length > 0) {
        console.log("");
        console.log("Mission folders tracked on this branch:");
        missionPaths.forEach((path) => console.log(`  - ${path}`));
    }
}

function doctor() {
    const branch = currentBranch();
    const missing = REQUIRED_BRANCHES.filter((name) => !branchExists(name));
    const hasMissionBranch = branchExists(BRANCHES.missions);
    const masterMissionPaths = branchExists(BRANCHES.master)
        ? trackedPaths(BRANCHES.master, MISSION_DIRS)
        : [];
    const missionBranchPaths = hasMissionBranch
        ? trackedPaths(BRANCHES.missions, MISSION_DIRS)
        : [];
    const workflowDocExists = tryGit(["ls-tree", "--name-only", "HEAD", "docs/GIT_WORKFLOW.md"]) === "docs/GIT_WORKFLOW.md";

    printStatus();
    console.log("");
    console.log("Workflow checks:");

    if (missing.length === 0) {
        console.log("  ok: expected local branches exist");
    } else {
        console.log(`  warn: missing branches: ${missing.join(", ")}`);
    }

    if (masterMissionPaths.length === 0) {
        console.log("  ok: master has no mission folders");
    } else {
        console.log(`  warn: master tracks mission folders: ${masterMissionPaths.join(", ")}`);
    }

    if (!hasMissionBranch) {
        console.log("  info: optional local mission branch is not present");
    } else if (missionBranchPaths.length === MISSION_DIRS.length) {
        console.log("  ok: mission branch has all mission folders");
    } else {
        console.log(`  warn: mission branch missing mission folders: ${MISSION_DIRS.filter((path) => !missionBranchPaths.includes(path)).join(", ")}`);
    }

    if (workflowDocExists) {
        console.log("  ok: docs/GIT_WORKFLOW.md exists on current branch");
    } else {
        console.log("  warn: docs/GIT_WORKFLOW.md is missing on current branch");
    }

    if (branch === BRANCHES.master && masterMissionPaths.length > 0) {
        process.exitCode = 1;
    }
}

function switchBranch(alias, args) {
    const branchName = BRANCHES[alias] ?? alias;
    const allowDirty = args.includes("--allow-dirty");

    if (!branchName) {
        console.error("Missing branch alias. Use master, dev, missions, or archive.");
        process.exit(1);
    }

    ensureClean({ allowDirty });

    if (!branchExists(branchName)) {
        console.error(`Branch not found: ${branchName}`);
        process.exit(1);
    }

    runGit(["switch", branchName], { stdio: "inherit" });
}

function normalizeFeatureName(name) {
    return String(name || "")
        .trim()
        .replace(/^feature\//, "")
        .replace(/[^a-zA-Z0-9._-]+/g, "-")
        .replace(/^-+|-+$/g, "")
        .toLowerCase();
}

function startFeature(name) {
    const normalized = normalizeFeatureName(name);
    if (!normalized) {
        console.error("Missing feature name.");
        process.exit(1);
    }

    ensureClean();
    runGit(["switch", BRANCHES.dev], { stdio: "inherit" });
    runGit(["pull", "--ff-only"], { stdio: "inherit" });
    runGit(["switch", "-c", `feature/${normalized}`], { stdio: "inherit" });
}

function releaseCheck() {
    const masterCount = Number(tryGit(["rev-list", "--count", BRANCHES.master]) || "0");
    const masterMissionPaths = trackedPaths(BRANCHES.master, MISSION_DIRS);
    const tagTarget = tryGit(["rev-parse", "v0.1.0^{}"]);
    const masterHead = tryGit(["rev-parse", BRANCHES.master]);

    console.log("Release checks:");
    console.log(`  master commit count: ${masterCount}`);
    console.log(`  master head: ${masterHead || "(missing)"}`);
    console.log(`  v0.1.0 target: ${tagTarget || "(missing)"}`);

    if (masterCount !== 1) {
        console.log("  warn: master should have one baseline commit");
        process.exitCode = 1;
    }

    if (masterMissionPaths.length > 0) {
        console.log(`  warn: master tracks mission folders: ${masterMissionPaths.join(", ")}`);
        process.exitCode = 1;
    } else {
        console.log("  ok: master has no mission folders");
    }

    if (tagTarget && masterHead && tagTarget === masterHead) {
        console.log("  ok: v0.1.0 points at master");
    } else {
        console.log("  warn: v0.1.0 does not point at master");
        process.exitCode = 1;
    }
}

const [command, ...args] = process.argv.slice(2);

switch (command) {
    case undefined:
    case "-h":
    case "--help":
    case "help":
        printHelp();
        break;
    case "status":
        printStatus();
        break;
    case "doctor":
        doctor();
        break;
    case "switch":
        switchBranch(args[0], args.slice(1));
        break;
    case "start-feature":
        startFeature(args[0]);
        break;
    case "release-check":
        releaseCheck();
        break;
    default:
        console.error(`Unknown command: ${command}`);
        printHelp();
        process.exit(1);
}
