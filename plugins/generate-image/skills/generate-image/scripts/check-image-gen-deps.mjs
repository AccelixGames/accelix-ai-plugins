#!/usr/bin/env node

/**
 * check-image-gen-deps.mjs
 * Dependency check script for the generate-image skill.
 *
 * Usage: node check-image-gen-deps.mjs [project-path]
 * Exit 0 = all checks pass, Exit 1 = any check fails.
 * Outputs JSON to stdout.
 */

import { readFileSync, existsSync } from 'fs';
import { resolve, join } from 'path';
import { execSync } from 'child_process';
import { homedir } from 'os';

const projectPath = resolve(process.argv[2] || process.cwd());

const result = {
  mcp_server: { ok: false },
  api_key: { ok: false },
  config: { ok: false, path: '', error: '' },
  references: { ok: false, registered: [], missing: [] },
};

// --- 1. mcp_server check ---
let settingsParsed = null;
const settingsPath = join(homedir(), '.claude', 'settings.json');

try {
  const raw = readFileSync(settingsPath, 'utf-8');
  settingsParsed = JSON.parse(raw);
} catch {
  settingsParsed = null;
}

if (settingsParsed?.mcpServers?.['image-gen']) {
  result.mcp_server.ok = true;
} else {
  // fallback: claude mcp list
  try {
    const stdout = execSync('claude mcp list', {
      encoding: 'utf-8',
      timeout: 10000,
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    result.mcp_server.ok = /image-gen/i.test(stdout);
  } catch {
    result.mcp_server.ok = false;
  }
}

// --- 2. api_key check ---
// API key is stored in MCP server config (not in settings.json).
// If the MCP server is registered AND connected, the key is presumably valid.
// We verify by checking the mcp list output for "Connected" status.
try {
  if (result.mcp_server.ok) {
    const stdout = execSync('claude mcp list', {
      encoding: 'utf-8',
      timeout: 10000,
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    // Check if image-gen shows "Connected" (not just registered)
    result.api_key.ok = /image-gen.*Connected/i.test(stdout);
  }
} catch {
  result.api_key.ok = false;
}

// --- 3. config check ---
const configPath = join(projectPath, '.generate-image', 'config.json');
result.config.path = configPath;

let configData = null;
try {
  if (!existsSync(configPath)) {
    result.config.error = 'config.json not found';
  } else {
    const raw = readFileSync(configPath, 'utf-8');
    configData = JSON.parse(raw);
    result.config.ok = true;
    result.config.error = '';
  }
} catch (e) {
  result.config.error = e?.message || 'unknown parse error';
}

// --- 4. references check ---
if (configData && typeof configData.categories === 'object' && configData.categories !== null) {
  const genImageDir = join(projectPath, '.generate-image');

  for (const [, category] of Object.entries(configData.categories)) {
    if (typeof category?.reference !== 'string') continue;

    const refPath = join(genImageDir, category.reference);

    if (existsSync(refPath)) {
      result.references.registered.push(category.reference);
    } else {
      result.references.missing.push(category.reference);
    }
  }

  result.references.ok = result.references.missing.length === 0 && result.references.registered.length > 0;
} else {
  result.references.ok = false;
}

// --- Output ---
const allOk = result.mcp_server.ok && result.api_key.ok && result.config.ok && result.references.ok;

process.stdout.write(JSON.stringify(result, null, 2) + '\n');
process.exit(allOk ? 0 : 1);
