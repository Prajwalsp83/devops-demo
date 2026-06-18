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
