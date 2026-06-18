const { NodeSDK } = require("@opentelemetry/sdk-node");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-http");
const { Resource } = require("@opentelemetry/resources");
const { SemanticResourceAttributes } = require("@opentelemetry/semantic-conventions");
const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://tempo.monitoring.svc.cluster.local:4318";
const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || "devops-demo-app",
  }),
  traceExporter: new OTLPTraceExporter({ url: `${endpoint}/v1/traces` }),
  instrumentations: [getNodeAutoInstrumentations()],
});
sdk.start();
console.log(`OpenTelemetry started — exporting traces to ${endpoint}`);
process.on("SIGTERM", () => sdk.shutdown().finally(() => process.exit(0)));
