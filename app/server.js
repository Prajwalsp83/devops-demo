const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;
let requestCount = 0;
app.get("/", (req, res) => {
  requestCount++;
  res.json({
    message: "Hello from the DevOps demo app2 v2 gitops deploy!",
    version: process.env.APP_VERSION || "1.0.0",
    pod: process.env.HOSTNAME || "unknown",
  });
});
app.get("/health", (req, res) => res.status(200).json({ status: "healthy" }));
app.get("/ready", (req, res) => res.status(200).json({ status: "ready" }));
app.get("/metrics", (req, res) => {
  res.set("Content-Type", "text/plain");
  res.send(`# HELP app_requests_total Total requests served\n# TYPE app_requests_total counter\napp_requests_total ${requestCount}\n`);
});
app.listen(PORT, () => console.log(`App listening on port ${PORT}`));

app.get("/slow", (req, res) => {
  const delay = parseInt(req.query.delay || "5000");
  setTimeout(() => res.json({ message: "slow endpoint", delay_ms: delay }), delay);
});

app.get("/error", (req, res) => {
  console.error("Intentional error at " + new Date().toISOString());
  res.status(500).json({ error: "Database connection failed" });
});

// Scenario 1: Memory leak (simulates data structure not being freed)
let leakedData = [];
app.get("/leak", (req, res) => {
  leakedData.push(new Array(1000000).fill("leaked data"));
  res.json({ message: "leaked data added", heap_mb: Math.round(process.memoryUsage().heapUsed / 1024 / 1024) });
});

// Scenario 2: Flaky endpoint (fails 40% of the time)
app.get("/flaky", (req, res) => {
  if (Math.random() < 0.4) {
    console.error("FLAKY: Random failure - upstream service unavailable");
    res.status(503).json({ error: "Service unavailable" });
  } else {
    res.json({ message: "flaky endpoint succeeded", attempt: Math.random() });
  }
});

// Scenario 3: Slow external service call
app.get("/db", (req, res) => {
  const delay = parseInt(req.query.delay || "2000");
  console.log(`DB query starting, estimated delay: ${delay}ms`);
  setTimeout(() => {
    console.log(`DB query completed after ${delay}ms`);
    res.json({ message: "db query succeeded", query_time_ms: delay });
  }, delay);
});

