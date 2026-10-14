// Test-only adapter. Live keys are rejected; this endpoint never marks orders paid.
// No patient details or medical line-item names are sent to Stripe.
const getEnv = (key: string) => Deno.env.get(key) || '';
Deno.serve(async (request: Request) => {
  const origin = getEnv('APP_ORIGIN');
  const headers = { 'content-type': 'application/json', 'access-control-allow-origin': origin,
    'access-control-allow-headers': 'authorization, apikey, content-type, x-client-info', 'access-control-allow-methods': 'POST, OPTIONS', 'vary': 'Origin' };
  const reply = (status: number, message: unknown) => new Response(JSON.stringify(message), { status, headers });
  if (request.headers.get('origin') && request.headers.get('origin') !== origin) return reply(403, { error: 'Origin not allowed' });
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
  if (request.method !== 'POST') return reply(405, { error: 'POST required' });
  const secret = getEnv('STRIPE_TEST_SECRET_KEY');
  if (!secret.startsWith('sk_test_') || !origin.startsWith('https://')) return reply(503, { error: 'Test checkout is not configured' });
  const authorization = request.headers.get('authorization') || '';
  if (!authorization.startsWith('Bearer ')) return reply(401, { error: 'Sign in required' });
  try {
    const api = getEnv('SUPABASE_URL');
    const apikey = getEnv('SUPABASE_PUBLISHABLE_KEY');
    const userResponse = await fetch(`${api}/auth/v1/user`, { headers: { apikey, authorization }, signal: AbortSignal.timeout(10000) });
    if (!userResponse.ok) return reply(401, { error: 'Invalid session' });
    const user = await userResponse.json();
    const payload = await request.json();
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(payload.order_id || '')) return reply(400, { error: 'Invalid order' });
    const response = await fetch(`${api}/rest/v1/orders?id=eq.${payload.order_id}&patient_id=eq.${user.id}&select=id,total_cents,currency,status`, { headers: { apikey, authorization }, signal: AbortSignal.timeout(10000) });
    if (!response.ok) return reply(502, { error: 'Unable to read order' });
    const rows = await response.json();
    const order = rows[0];
    if (!order || order.status !== 'requested' || order.total_cents <= 0) return reply(404, { error: 'Order unavailable' });
    const body = new URLSearchParams({ mode: 'payment', success_url: `${origin}/?checkout=test-success`, cancel_url: `${origin}/?checkout=test-cancelled`,
      'line_items[0][price_data][currency]': order.currency.toLowerCase(), 'line_items[0][price_data][unit_amount]': String(order.total_cents),
      'line_items[0][price_data][product_data][name]': 'MobiMed test order', 'line_items[0][quantity]': '1' });
    const checkout = await fetch('https://api.stripe.com/v1/checkout/sessions', { method: 'POST', headers: {
      authorization: `Bearer ${secret}`, 'content-type': 'application/x-www-form-urlencoded', 'idempotency-key': `test:${order.id}` }, body, signal: AbortSignal.timeout(15000) });
    if (!checkout.ok) return reply(502, { error: 'Unable to create test checkout' });
    const session = await checkout.json();
    if (session.livemode !== false || !session.url?.startsWith('https://checkout.stripe.com/')) return reply(502, { error: 'Invalid test checkout' });
    return reply(200, { mode: 'test', url: session.url });
  } catch { return reply(502, { error: 'Test checkout failed. Try again.' }); }
});
