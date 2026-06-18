const assert = require("assert");
function add(a, b) { return a + b; }
assert.strictEqual(add(2, 3), 5);
assert.strictEqual(add(-1, 1), 0);
console.log("All unit tests passed.");
process.exit(0);
