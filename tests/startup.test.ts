import { afterEach, expect, test } from 'bun:test';
import { copyFileSync, mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from 'fs';
import { tmpdir } from 'os';
import { join, resolve } from 'path';
import { spawnSync } from 'child_process';

const repo = resolve(import.meta.dirname, '..');
const fixtures: string[] = [];
afterEach(() => {
  for (const fixture of fixtures.splice(0)) rmSync(fixture, { recursive: true, force: true });
});

function runFixture(envFile?: string) {
  const fixture = mkdtempSync(join(tmpdir(), 'video-description-test-'));
  fixtures.push(fixture);
  const clone = join(fixture, 'clone');
  const cwd = join(fixture, 'elsewhere');
  mkdirSync(join(clone, 'lib'), { recursive: true });
  mkdirSync(cwd);
  copyFileSync(join(repo, 'index.ts'), join(clone, 'index.ts'));
  copyFileSync(join(repo, 'lib/run-transcribe.ts'), join(clone, 'lib/run-transcribe.ts'));
  symlinkSync(join(repo, 'node_modules'), join(clone, 'node_modules'), 'junction');
  if (envFile) writeFileSync(join(clone, '.env'), envFile);
  const env = { ...process.env };
  delete env.OPENROUTER_API_KEY;
  return spawnSync(process.execPath, ['run', join(clone, 'index.ts'), join(fixture, 'missing.mp4')], {
    cwd, env, encoding: 'utf8', timeout: 10_000,
  });
}

test('startup loads .env from its own clone when launched from another directory', () => {
  // A nonexistent video stops startup before any API call or interactive prompt.
  const result = runFixture('OPENROUTER_API_KEY=local-test-key\n');
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('Path not found:');
  expect(result.stderr).not.toContain('OPENROUTER_API_KEY is not set');
});

test('startup explains how to configure a missing API key', () => {
  const result = runFixture();
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('OPENROUTER_API_KEY is not set');
  expect(result.stderr).toContain('Copy .env.example to .env');
});
