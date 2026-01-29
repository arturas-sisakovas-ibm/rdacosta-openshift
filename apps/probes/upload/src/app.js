var express = require('express'),
    app     = express();

var port = process.env.PORT || process.env.OPENSHIFT_NODEJS_PORT || 8080,
    ip   = process.env.IP   || process.env.OPENSHIFT_NODEJS_IP || '0.0.0.0';

var route = express.Router();

// Track startup completion (used by /startup)
var startedUp = false;

// Track application health (used by /healthz)
var healthy = true;

// Track readiness (used by /ready)
var ready = true;

app.use('/', route);

// A route that says hello
route.get('/', function(req, res) {
  res.send('Hello world!\n');
});

// Simulate slow initialisation (e.g. migrations, cache warmup)
// Startup probe should tolerate this window
setTimeout(function () {
  startedUp = true;
  console.log('Startup complete: app initialisation finished');
}, 30 * 1000);

// Startup probe endpoint
// Returns 503 until initialisation completes
route.get('/startup', function(req, res) {
  if (startedUp) {
    console.log('ping /startup => pong [started]');
    res.send('Started\n');
  } else {
    console.log('ping /startup => pong [starting]');
    res.status(503);
    res.send('Starting...\n');
  }
});

// Readiness probe endpoint
route.get('/ready', function(req, res) {
  if (ready) {
    console.log('ping /ready => pong [ready]');
    res.send('Ready for service requests...\n');
  } else {
    console.log('ping /ready => pong [unready]');
    res.status(503);
    res.send('Not ready (manually set to unready)\n');
  }
});

// Liveness probe endpoint
route.get('/healthz', function(req, res) {
  if (healthy) {
    console.log('ping /healthz => pong [healthy]');
    res.send('OK\n');
  } else {
    console.log('ping /healthz => pong [unhealthy]');
    res.status(503);
    res.send('Oops! The app is not healthy and a restart is required.\n');
  }
});

// Flip endpoints to simulate failures and maintenance modes
route.get('/flip', function(req, res) {
  var flag = req.query.op;

  if (flag === "kill") {
    console.log('Received kill request. Changing app state to unhealthy...');
    healthy = false;
    return res.send('Switched app state to unhealthy...\n');
  }

  if (flag === "awaken") {
    console.log('Received awaken request. Changing app state to healthy...');
    healthy = true;
    return res.send('Switched app state to healthy...\n');
  }

  // Readiness toggles
  if (flag === "unready") {
    console.log('Received unready request. Forcing readiness to fail...');
    ready = false;
    return res.send('Switched readiness to unready (503)...\n');
  }

  if (flag === "ready") {
    console.log('Received ready request. Forcing readiness to succeed...');
    ready = true;
    return res.send('Switched readiness to ready (200)...\n');
  }

  res.status(400);
  res.send('Error! unknown op. Use kill, awaken, unready, or ready.\n');
});

app.listen(port, ip);
console.log('nodejs server running on http://%s:%s', ip, port);

module.exports = app;
