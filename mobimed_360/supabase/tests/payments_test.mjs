import assert from 'node:assert/strict';
let handler;
const env = { APP_ORIGIN: 'https://example.test', STRIPE_TEST_SECRET_KEY: 'sk_test_fixture', SUPABASE_URL: 'https://backend.test', SUPABASE_PUBLISHABLE_KEY: 'test_public_key' };
globalThis.Deno = { env: { get: key => env[key] }, serve: fn => { handler = fn; } };
await import('../functions/stripe-test-checkout/index.ts');
const order = '00000000-0000-0000-0000-000000000001';
const request = (body = { order_id: order }, auth = true) => new Request('https://backend.test/functions/v1/stripe-test-checkout', {
  method: 'POST', headers: { origin: env.APP_ORIGIN, 'content-type': 'application/json', ...(auth ? { authorization: 'Bearer test_user_session' } : {}) }, body: JSON.stringify(body),
});
const originalFetch = globalThis.fetch;
let calls = 0;
globalThis.fetch = async (url, options) => {
  calls++;
  if (url.endsWith('/auth/v1/user')) return Response.json({ id: '00000000-0000-0000-0000-000000000002' });
  if (url.includes('/rest/v1/orders')) return Response.json([{ id: order, total_cents: 2500, currency: 'USD', status: 'requested' }]);
  assert.equal(url, 'https://api.stripe.com/v1/checkout/sessions');
  assert.equal(options.body.get('line_items[0][price_data][unit_amount]'), '2500');
  assert.equal(options.body.get('line_items[0][price_data][product_data][name]'), 'MobiMed test order');
  assert.equal(options.body.has('customer_email'), false);
  return Response.json({ livemode: false, url: 'https://checkout.stripe.com/test-fixture' });
};
assert.equal((await handler(request({}, false))).status, 401);
assert.equal((await handler(request({ order_id: 'invalid' }))).status, 400);
env.STRIPE_TEST_SECRET_KEY = 'sk_live_fixture';
const before = calls;
assert.equal((await handler(request())).status, 503);
assert.equal(calls, before);
env.STRIPE_TEST_SECRET_KEY = 'sk_test_fixture';
const response = await handler(request({ order_id: order, total_cents: 1 }));
assert.equal(response.status, 200);
assert.equal((await response.json()).mode, 'test');
globalThis.fetch = originalFetch;
console.log('PASS: test-only payments reject live keys, verify sessions and use server totals without patient details.');
