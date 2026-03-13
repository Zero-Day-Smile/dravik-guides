#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const projectRoot = process.cwd();
const distDir = path.join(projectRoot, 'dist');
const distIndex = path.join(distDir, 'index.html');

function runStep(label, command, args) {
  process.stdout.write(`\n[preflight] ${label}...\n`);
  const result = spawnSync(command, args, {
    cwd: projectRoot,
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });

  if (result.status !== 0) {
    console.error(`[preflight] Failed: ${label}`);
    process.exit(result.status ?? 1);
  }
}

runStep('Checking required environment variables', 'npm', ['run', 'check:env']);
runStep('Building production bundle', 'npm', ['run', 'build']);

process.stdout.write('\n[preflight] Validating build artifacts...\n');
if (!fs.existsSync(distDir)) {
  console.error('[preflight] Failed: dist directory not found after build.');
  process.exit(1);
}

if (!fs.existsSync(distIndex)) {
  console.error('[preflight] Failed: dist/index.html not found after build.');
  process.exit(1);
}

const indexHtml = fs.readFileSync(distIndex, 'utf8');
if (!indexHtml.includes('<div id="root"></div>')) {
  console.error('[preflight] Failed: dist/index.html missing app root container.');
  process.exit(1);
}

console.log('\n[preflight] Success: website is ready for deployment checks.');
