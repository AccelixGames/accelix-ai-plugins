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
  mcp_server: { ok: true },
  api_key: { ok: false },
  config: { ok: false, path: '', error: '' },
  references: { ok: false, registered: [], missing: [] },
};

// --- 1. mcp_server check (CLI-only mode — always ok) ---
// MCP server removed; all generation via Vertex AI CLI wrapper.

// --- 2. ADC (Application Default Credentials) check ---
// Vertex AI mode uses ADC instead of API key.
// Check: GOOGLE_CLOUD_PROJECT is set + ADC credentials file exists.
const ADC_PATH = join(homedir(), 'AppData', 'Roaming', 'gcloud', 'application_default_credentials.json');
const ADC_PATH_UNIX = join(homedir(), '.config', 'gcloud', 'application_default_credentials.json');

try {
  const adcExists = existsSync(ADC_PATH) || existsSync(ADC_PATH_UNIX);
  const adcPath = existsSync(ADC_PATH) ? ADC_PATH : ADC_PATH_UNIX;
  let project = process.env.GOOGLE_CLOUD_PROJECT;
  if (!project && adcExists) {
    try {
      const adc = JSON.parse(readFileSync(adcPath, 'utf-8'));
      project = adc.quota_project_id;
    } catch {}
  }
  if (adcExists && project) {
    result.api_key.ok = true;
    result.api_key.project = project;
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
