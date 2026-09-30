import { afterEach, expect, test } from 'bun:test';
import { mkdtempSync, readlinkSync, rmSync } from 'fs';
import { tmpdir } from 'os';
import { join, resolve } from 'path';
import { spawnSync } from 'child_process';

const repo = resolve(import.meta.dirname, '..');
const fixtures: string[] = [];
afterEach(() => {
  for (const fixture of fixtures.splice(0)) rmSync(fixture, { recursive: true, force: true });
});

test.skipIf(process.platform === 'win32')('mac installer is repeatable and its symlink runs from another folder', () => {
  const fixture = mkdtempSync(join(tmpdir(), 'video-description-install-'));
  fixtures.push(fixture);
  const target = join(fixture, 'bin with spaces');
  for (let i = 0; i < 2; i++) {
    const result = spawnSync('bash', [join(repo, 'install.sh'), target], { cwd: fixture, encoding: 'utf8' });
    expect(result.status).toBe(0);
  }
  const launcher = join(target, 'video-description');
  expect(readlinkSync(launcher)).toBe(join(repo, 'video-description'));
  const result = spawnSync(launcher, [join(fixture, 'missing.mp4')], {
    cwd: fixture,
    env: { ...process.env, OPENROUTER_API_KEY: 'local-test-key' },
    encoding: 'utf8', timeout: 10_000,
  });
  expect(result.status).toBe(1);
  expect(result.stderr).toContain('Path not found:');
});
