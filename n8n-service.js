const Service = require('node-windows').Service;
const path = require('path');

const svc = new Service({
  name: 'n8n-service',
  description: 'n8n automation service',
  script: path.join(__dirname, 'node_modules', '.bin', 'n8n'),
  nodeOptions: [
    '--harmony',
    '--max_old_space_size=4096'
  ]
});

svc.on('install', () => svc.start());
svc.install();
