#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';

const projectRoot = process.cwd();
const envPath = path.join(projectRoot, '.env');
const allowMissing = process.argv.includes('--allow-missing');

const requiredVars = ['VITE_SUPABASE_URL', 'VITE_SUPABASE_PUBLISHABLE_KEY'];
const forbiddenVars = ['SUPABASE_SERVICE_ROLE_KEY', 'VITE_SUPABASE_SERVICE_ROLE_KEY'];

function parseEnv(text) {
  const env = {};
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const eqIndex = trimmed.indexOf('=');
    if (eqIndex <= 0) continue;

    const key = trimmed.slice(0, eqIndex).trim();
    const value = trimmed.slice(eqIndex + 1).trim();
    env[key] = value;
  }
  return env;
}

let env = { ...process.env };

if (fs.existsSync(envPath)) {
  const fileEnv = parseEnv(fs.readFileSync(envPath, 'utf8'));
  env = { ...fileEnv, ...env };
}

const missing = requiredVars.filter((key) => !env[key]);
const forbidden = forbiddenVars.filter((key) => Boolean(env[key]));

if (forbidden.length > 0) {
  console.error('Forbidden env vars detected in website context:');
  for (const key of forbidden) {
    console.error(`- ${key}`);
  }
  console.error('Do not expose service role keys to the website frontend.');
  process.exit(1);
}

if (missing.length > 0 && !allowMissing) {
  console.error('Missing required env vars:');
  for (const key of missing) {
    console.error(`- ${key}`);
  }
  console.error('Set these in website/.env (local) and Cloudflare Pages environment variables (production).');
  process.exit(1);
}

if (missing.length > 0 && allowMissing) {
  console.warn('Warning: missing env vars for local dev mode:');
  for (const key of missing) {
    console.warn(`- ${key}`);
  }
}
