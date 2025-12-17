// Phase 4 runner - runs auth matrix -> admin mutations -> audit log validation in order.
// Exits non-zero immediately on any failure.

const { spawnSync } = require('child_process');
const path = require('path');

const scripts = [
  { name: 'Auth matrix validation', cmd: 'node', args: ['test/auth_matrix_script.js'] },
  { name: 'Admin mutations validation', cmd: 'node', args: ['test/admin_mutations_script.js'] },
  { name: 'Audit log validation', cmd: 'node', args: ['test/audit_log_validation_script.js'] },
];

function runOne(s) {
  console.log('\n---- Running:', s.name, '----');
  const res = spawnSync(s.cmd, s.args, { stdio: 'inherit', cwd: path.resolve(__dirname, '..') });
  if (res.error) {
    console.error(`${s.name} runner failed to start:`, res.error);
    process.exit(1);
  }
  if (res.status !== 0) {
    console.error(`${s.name} failed with exit code ${res.status}`);
    process.exit(res.status || 1);
  }
  console.log(`${s.name} completed successfully`);
}

(async function main() {
  for (const s of scripts) {
    runOne(s);
  }
  console.log('\n✅ Phase 4 runner: ALL SCRIPTS PASSED');
  process.exit(0);
})();
