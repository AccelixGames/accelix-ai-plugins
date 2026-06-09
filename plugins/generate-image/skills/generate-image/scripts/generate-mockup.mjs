#!/usr/bin/env node

/**
 * generate-mockup.mjs
 * Imagen 4 이미지 생성 — Vertex AI(ADC) 또는 Gemini AI Studio(API key) 선택 가능.
 *
 * Usage:
 *   node generate-mockup.mjs \
 *     --prompt "..." \
 *     --output "output/mockup.png" \
 *     [--aspect-ratio "16:9"] \
 *     [--fast] \
 *     [--model imagen-4.0-ultra-generate-001] \
 *     [--backend vertex|gemini]   ← default: vertex
 *
 * Vertex AI (default):
 *   Auth: ADC — gcloud auth application-default login (1회)
 *   Project: GOOGLE_CLOUD_PROJECT env var 또는 ADC 파일의 quota_project_id 자동 읽음
 *
 * Gemini AI Studio:
 *   Auth: GEMINI_API_KEY env var 필요
 */

import { fileURLToPath, pathToFileURL } from 'url';
import { join, dirname, resolve } from 'path';
import { writeFileSync, mkdirSync, existsSync, readFileSync } from 'fs';
import { parseArgs } from 'util';
import { homedir } from 'os';

// Resolve @google/genai from plugin root (4 levels up from scripts/)
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const pluginRoot = join(__dirname, '..', '..', '..', '..');
const genaiPath = pathToFileURL(join(pluginRoot, 'node_modules', '@google', 'genai', 'dist', 'node', 'index.mjs')).href;

let GoogleGenAI;
try {
  ({ GoogleGenAI } = await import(genaiPath));
} catch {
  ({ GoogleGenAI } = await import('@google/genai/node'));
}

const { values } = parseArgs({
  options: {
    prompt:         { type: 'string', short: 'p' },
    output:         { type: 'string', short: 'o' },
    'aspect-ratio': { type: 'string', default: '16:9' },
    reference:      { type: 'string', short: 'r' },
    fast:           { type: 'boolean', default: false },
    backend:        { type: 'string', default: 'vertex' },
    model:          { type: 'string' },
  },
  strict: true,
});

if (!values.prompt || !values.output) {
  console.error('Usage: node generate-mockup.mjs --prompt "..." --output "path.png" [--aspect-ratio 16:9] [--fast] [--backend vertex|gemini]');
  process.exit(1);
}

if (values.reference) {
  console.error('Warning: --reference is not supported with Imagen 3. Embed style guidance in --prompt.');
}

const backend = values.backend === 'gemini' ? 'gemini' : 'vertex';

let ai;

if (backend === 'gemini') {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error('GEMINI_API_KEY environment variable is required for --backend gemini');
    process.exit(1);
  }
  ai = new GoogleGenAI({ apiKey });
} else {
  // Vertex AI: project from env var or ADC file
  let projectId = process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId) {
    const adcPaths = [
      join(homedir(), 'AppData', 'Roaming', 'gcloud', 'application_default_credentials.json'),
      join(homedir(), '.config', 'gcloud', 'application_default_credentials.json'),
    ];
    for (const p of adcPaths) {
      try {
        if (existsSync(p)) {
          const adc = JSON.parse(readFileSync(p, 'utf-8'));
          if (adc.quota_project_id) { projectId = adc.quota_project_id; break; }
        }
      } catch {}
    }
  }
  if (!projectId) {
    console.error('No project ID found. Set GOOGLE_CLOUD_PROJECT or run: gcloud auth application-default login');
    process.exit(1);
  }
  const location = process.env.GOOGLE_CLOUD_LOCATION || 'us-central1';
  ai = new GoogleGenAI({ vertexai: true, project: projectId, location });
}
const outputPath = resolve(values.output);
const outputDir = dirname(outputPath);

if (!existsSync(outputDir)) {
  mkdirSync(outputDir, { recursive: true });
}

// Aspect ratio mapping: Imagen 3 supports 1:1, 9:16, 16:9, 3:4, 4:3
const ASPECT_MAP = {
  '16:9': '16:9',
  '9:16': '9:16',
  '1:1':  '1:1',
  '3:4':  '3:4',
  '4:3':  '4:3',
};
const aspectRatio = ASPECT_MAP[values['aspect-ratio']] || '16:9';
const model = values.model || (values.fast ? 'imagen-4.0-fast-generate-001' : 'imagen-4.0-generate-001');

try {
  const response = await ai.models.generateImages({
    model,
    prompt: values.prompt,
    config: {
      numberOfImages: 1,
      aspectRatio,
    },
  });

  const imageBytes = response.generatedImages?.[0]?.image?.imageBytes;
  if (!imageBytes) {
    console.error('No image in response.');
    process.exit(1);
  }

  const buffer = Buffer.from(imageBytes, 'base64');
  writeFileSync(outputPath, buffer);
  console.log(outputPath);
} catch (err) {
  console.error(`Generation failed: ${err.message}`);
  process.exit(1);
}
