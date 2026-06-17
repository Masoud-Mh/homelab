#!/usr/bin/env node
// session-guard MCP server (stdio).
// Thin wrapper over scripts/session-guard/*.sh — the bash substrate is the single
// source of truth for parsing; this server never re-implements it.
//
// Tools:
//   get_usage{refresh}             -> normalized usage JSON (structuredContent), ~60s cache
//   wait_for_reset{window,...}     -> launches wait-until-reset.sh DETACHED, returns immediately
//   get_wait_status{}              -> reads the wait sentinel

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { readFile } from "node:fs/promises";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = resolve(HERE, "../../..");
const CHECK = resolve(HERE, "../check-usage.sh");
const WAIT = resolve(HERE, "../wait-until-reset.sh");
const SENTINEL = resolve(ROOT, ".ai/memory/runtime/session-guard.wait");

let cache = { at: 0, value: null };
const CACHE_MS = 60_000;

function runCheck(fast = false) {
  return new Promise((res) => {
    const args = [CHECK];
    if (fast) args.push("--fast");
    const child = spawn("bash", args, { cwd: ROOT });
    let out = "";
    child.stdout.on("data", (d) => (out += d));
    child.on("close", () => {
      try {
        res(JSON.parse(out.trim()));
      } catch (e) {
        res({ source: "none", ok: false, recommendation: "proceed_unknown",
              advice: "MCP could not parse usage output.", error: String(e) });
      }
    });
    child.on("error", (e) =>
      res({ source: "none", ok: false, recommendation: "proceed_unknown",
            advice: "MCP could not run check-usage.sh.", error: String(e) }));
  });
}

async function getUsage(refresh) {
  const now = Date.now();
  if (!refresh && cache.value && now - cache.at < CACHE_MS) return cache.value;
  const value = await runCheck(false);
  if (value.ok) cache = { at: now, value };
  return value;
}

const tools = [
  {
    name: "get_usage",
    description:
      "Get current Claude Max usage (session %, weekly %, reset times) and an adaptive recommendation. Source 'usage' is authoritative; 'ccusage' is an approximate 5h-block proxy with no weekly view.",
    inputSchema: {
      type: "object",
      properties: {
        refresh: { type: "boolean", description: "Bypass the ~60s cache.", default: false },
      },
    },
  },
  {
    name: "wait_for_reset",
    description:
      "Launch the auto-sleep waiter as a DETACHED background process that exits when the usage window resets (so the agent resumes). Returns immediately; does NOT block. Use the 'session' window for the 5h limit.",
    inputSchema: {
      type: "object",
      properties: {
        window: { type: "string", enum: ["session", "week"], default: "session" },
        buffer_seconds: { type: "number", default: 120 },
        max_wait_seconds: { type: "number", default: 21600 },
      },
    },
  },
  {
    name: "get_wait_status",
    description: "Report whether an auto-sleep wait is currently active (reads the sentinel).",
    inputSchema: { type: "object", properties: {} },
  },
];

const server = new Server(
  { name: "session-guard", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args = {} } = req.params;

  if (name === "get_usage") {
    const usage = await getUsage(Boolean(args.refresh));
    return {
      content: [{ type: "text", text: JSON.stringify(usage) }],
      structuredContent: usage,
    };
  }

  if (name === "wait_for_reset") {
    const usage = await getUsage(false);
    const window = args.window === "week" ? "week" : "session";
    const target =
      window === "week" ? usage.week_reset_epoch : usage.session_reset_epoch;
    if (!target) {
      const payload = { started: false, error: `no ${window} reset epoch available` };
      return { content: [{ type: "text", text: JSON.stringify(payload) }], structuredContent: payload };
    }
    const child = spawn("bash", [WAIT, String(target)], {
      cwd: ROOT,
      detached: true,
      stdio: "ignore",
      env: {
        ...process.env,
        SG_BUFFER_SECONDS: String(args.buffer_seconds ?? 120),
        SG_MAX_WAIT_SECONDS: String(args.max_wait_seconds ?? 21600),
      },
    });
    child.unref();
    const payload = { started: true, window, target_epoch: target, sentinel: SENTINEL };
    return { content: [{ type: "text", text: JSON.stringify(payload) }], structuredContent: payload };
  }

  if (name === "get_wait_status") {
    let payload;
    try {
      const raw = await readFile(SENTINEL, "utf8");
      const s = JSON.parse(raw);
      const remaining = s.target_epoch - Math.floor(Date.now() / 1000);
      payload = { waiting: true, target_epoch: s.target_epoch, seconds_remaining: remaining };
    } catch {
      payload = { waiting: false };
    }
    return { content: [{ type: "text", text: JSON.stringify(payload) }], structuredContent: payload };
  }

  return {
    content: [{ type: "text", text: `unknown tool: ${name}` }],
    isError: true,
  };
});

const transport = new StdioServerTransport();
await server.connect(transport);
