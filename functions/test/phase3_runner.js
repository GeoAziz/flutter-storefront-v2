// Phase 3 runner - runs inventory -> payments -> notifications scripts in order.
// Exits non-zero immediately on any failure.

const { spawnSync } = require('child_process');
const path = require('path');

const scripts = [
  { name: 'Inventory flow', cmd: 'node', args: ['test/inventory_flow_script.js'] },
  { name: 'Payments simulator', cmd: 'node', args: ['test/payments_simulator.js'] },
  { name: 'Notifications simulator', cmd: 'node', args: ['test/notifications_simulator.js'] },
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
  console.log('\n✅ Phase 3 runner: ALL SCRIPTS PASSED');
  process.exit(0);
})();
