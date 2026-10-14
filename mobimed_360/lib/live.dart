import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'backend.dart';

const stripeTestEnabled = bool.fromEnvironment('STRIPE_TEST_MODE');

String formatPrice(int amount, String currency) {
  final format = NumberFormat.currency(name: currency);
  return format.format(amount / pow(10, format.decimalDigits ?? 2));
}

class ConnectedCareApp extends StatefulWidget {
  const ConnectedCareApp({super.key});
  @override
  State<ConnectedCareApp> createState() => _ConnectedCareAppState();
}

class _ConnectedCareAppState extends State<ConnectedCareApp> {
  int tab = 0;
  String category = 'Doctors', query = '';
  Future<List<Map<String, dynamic>>>? loading;
  final Map<String, Map<String, dynamic>> cart = {};
  final search = TextEditingController();
  bool submitting = false;
  StreamSubscription<AuthState>? authSubscription;
  @override
  void initState() {
    super.initState();
    refresh();
    authSubscription = backend.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        showDialog<void>(
          context: context,
          builder: (_) => const BackendPasswordUpdate(),
        );
      }
      if (state.event == AuthChangeEvent.signedOut) {
        setState(() {
          cart.clear();
          tab = 0;
          loading = load();
        });
      }
    });
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    search.dispose();
    super.dispose();
  }

  void message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  Future<bool> login() async {
    if (backend.auth.currentUser != null) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const BackendSignIn(),
    );
    if (!mounted) return false;
    return result == true;
  }

  void refresh() => setState(() => loading = load());
  Future<List<Map<String, dynamic>>> load() async {
    if (tab < 2) {
      if (category == 'Pharmacy') {
        return await backend
            .from('products')
            .select(
              '*,providers!inner(id,name,facility,currency,verified,country_code)',
            )
            .eq('providers.verified', true)
            .eq('prescription_required', false)
            .gt('stock', 0);
      }
      return await backend
          .from('providers')
          .select()
          .eq('verified', true)
          .eq('category', category)
          .order('name');
    }
    if (backend.auth.currentUser == null) return [];
    if (tab == 2) {
      return await backend
          .from('appointments')
          .select('*,providers(name,category,facility)')
          .order('starts_at');
    }
    return await backend
        .from('orders')
        .select()
        .order('created_at', ascending: false);
  }

  Future<void> changeTab(int value) async {
    if (value >= 2 && !await login()) return;
    if (!mounted) return;
    setState(() {
      tab = value;
      query = '';
      search.clear();
      loading = load();
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final wide = size.maxWidth >= 760;
      const destinations = [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.search), label: 'Find care'),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Orders',
        ),
      ];
      return Scaffold(
        appBar: AppBar(
          title: const Text('MobiMed 360'),
          actions: [
            IconButton(
              tooltip: 'Refresh care',
              onPressed: refresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Care cart',
              onPressed: checkout,
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.length}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Account',
              onSelected: account,
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'workspace',
                  child: Text('Provider workspace'),
                ),
                const PopupMenuItem(
                  value: 'privacy',
                  child: Text('Privacy and support'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Request account deletion'),
                ),
                const PopupMenuItem(value: 'logout', child: Text('Sign out')),
              ],
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: changeTab,
                destinations: destinations,
              ),
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: tab,
                  onDestinationSelected: changeTab,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: d.icon,
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        refresh();
                        await loading;
                      },
                      child: ListView(
                        key: ValueKey('$tab-$category'),
                        padding: const EdgeInsets.all(24),
                        children: [
                          if (tab == 0) ...[
                            const Text(
                              'CARE THAT FITS YOUR LIFE',
                              style: TextStyle(
                                color: Color(0xFF087F75),
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Feel better.\nStart here.',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Connect with verified healthcare providers. Services are available where a licensed provider has been onboarded.',
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (tab < 2) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  ['Doctors', 'Pharmacy', 'Labs', 'Hospitals']
                                      .map(
                                        (c) => ChoiceChip(
                                          label: Text(c),
                                          selected: c == category,
                                          onSelected: (_) => setState(() {
                                            category = c;
                                            query = '';
                                            search.clear();
                                            loading = load();
                                          }),
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: search,
                              onChanged: (v) => setState(() => query = v),
                              decoration: const InputDecoration(
                                labelText: 'Search providers and services',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          if (tab == 2)
                            const Text(
                              'Your bookings',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (tab == 3) ...[
                            const Text(
                              'Your orders',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Order requests do not collect payment. Arrange payment directly with your provider.',
                            ),
                          ],
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: loading,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Unable to load care. Check your connection and try again.',
                                        ),
                                        TextButton(
                                          onPressed: refresh,
                                          child: const Text('Try again'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final rows = (snapshot.data ?? [])
                                  .where(
                                    (row) =>
                                        tab >= 2 ||
                                        row.toString().toLowerCase().contains(
                                          query.toLowerCase(),
                                        ),
                                  )
                                  .toList();
                              if (rows.isEmpty) {
                                return const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Text(
                                      'No results yet. Providers and services appear after verified onboarding.',
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: rows
                                    .map(
                                      (row) => tab < 2
                                          ? providerCard(row)
                                          : tab == 2
                                          ? bookingCard(row)
                                          : orderCard(row),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'For a medical emergency, contact your local emergency service. MobiMed does not provide emergency dispatch.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget providerCard(Map<String, dynamic> row) {
    final pharmacy = category == 'Pharmacy';
    final provider = pharmacy
        ? Map<String, dynamic>.from(row['providers'])
        : row;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  pharmacy
                      ? Icons.medication_outlined
                      : Icons.health_and_safety_outlined,
                  color: const Color(0xFF087F75),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(pharmacy ? provider['facility'] : row['detail']),
            Text('${provider['country_code']} • ${provider['facility']}'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  formatPrice(row['price_cents'], provider['currency']),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                FilledButton(
                  onPressed: () => pharmacy ? add(row) : book(row),
                  child: Text(
                    pharmacy ? 'Add to cart' : 'Available appointments',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void add(Map<String, dynamic> product) {
    final currency = product['providers']['currency'];
    if (cart.isNotEmpty &&
        cart.values.first['providers']['currency'] != currency) {
      message(
        'Please complete your current cart before using another currency.',
      );
      return;
    }
    final qty = (cart[product['id']]?['quantity'] ?? 0) + 1;
    if (qty > product['stock'] || qty > 99) {
      message('Maximum available quantity reached.');
      return;
    }
    setState(() => cart[product['id']] = {...product, 'quantity': qty});
    message('Added to cart');
  }

  Future<void> book(Map<String, dynamic> provider) async {
    if (!await login() || !mounted) return;
    try {
      final slots = await backend
          .from('slots')
          .select()
          .eq('provider_id', provider['id'])
          .gt('starts_at', DateTime.now().toUtc().toIso8601String())
          .order('starts_at');
      if (!mounted) return;
      final selected = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text('Appointments with ${provider['name']}'),
          children: [
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No future appointments available.'),
              ),
            ...slots.map(
              (s) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, s['id']),
                child: Text(date(s['starts_at'])),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request this appointment?'),
          content: Text(
            '${provider['name']}\n${formatPrice(provider['price_cents'], provider['currency'])}\nPayment is arranged with the provider. This request does not charge you.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Request appointment'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await backend.rpc('book_slot', params: {'selected_slot': selected});
      if (mounted) {
        message('Appointment requested');
        changeTab(2);
      }
    } catch (_) {
      if (mounted) {
        message(
          'Unable to book. The slot may have been taken. Refresh and try again.',
        );
      }
    }
  }

  String date(String value) =>
      DateFormat.yMMMd().add_jm().format(DateTime.parse(value).toLocal());
  Widget bookingCard(Map<String, dynamic> row) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row['providers']['name'],
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(date(row['starts_at'])),
          Text('Status: ${row['status']}'),
          if (!['cancelled', 'completed'].contains(row['status']))
            TextButton(
              onPressed: () => cancel(row['id']),
              child: const Text('Cancel appointment'),
            ),
        ],
      ),
    ),
  );
  Future<void> cancel(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await backend.rpc(
        'set_booking',
        params: {'booking_id': id, 'new_status': 'cancelled'},
      );
      if (mounted) refresh();
    } catch (_) {
      if (mounted) message('Unable to cancel. Refresh and try again.');
    }
  }

  Widget orderCard(Map<String, dynamic> row) => Card(
    child: Column(
      children: [
        ListTile(
          title: Text('Order ${row['id'].toString().substring(0, 8)}'),
          subtitle: Text('${date(row['created_at'])} • ${row['status']}'),
          trailing: Text(formatPrice(row['total_cents'], row['currency'])),
        ),
        if (row['status'] == 'requested')
          Wrap(
            spacing: 12,
            children: [
              TextButton(
                onPressed: () => cancelOrder(row['id']),
                child: const Text('Cancel request'),
              ),
              if (stripeTestEnabled)
                TextButton(
                  onPressed: () => testPayment(row['id']),
                  child: const Text('Open test payment'),
                ),
            ],
          ),
      ],
    ),
  );
  Future<void> cancelOrder(String id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await backend.rpc('cancel_order', params: {'selected_order': id});
      if (mounted) refresh();
    } catch (_) {
      if (mounted) message('Unable to cancel this request.');
    }
  }

  Future<void> testPayment(String id) async {
    try {
      final response = await backend.functions.invoke(
        'stripe-test-checkout',
        body: {'order_id': id},
      );
      final data = response.data;
      final url = Uri.tryParse(data['url'] ?? '');
      if (data['mode'] != 'test' ||
          url?.scheme != 'https' ||
          url?.host != 'checkout.stripe.com') {
        throw StateError('Invalid checkout');
      }
      if (!await launchUrl(url!, mode: LaunchMode.externalApplication)) {
        throw StateError('Unable to open checkout');
      }
    } catch (_) {
      if (mounted) {
        message('Test checkout is unavailable. No payment was collected.');
      }
    }
  }

  Future<void> checkout() async {
    if (!await login() || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) {
          final total = cart.values.fold<int>(
            0,
            (sum, p) =>
                sum + (p['price_cents'] as int) * (p['quantity'] as int),
          );
          final currency = cart.isEmpty
              ? 'USD'
              : cart.values.first['providers']['currency'] as String;
          return AlertDialog(
            title: const Text('Your care cart'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cart.isEmpty) const Text('Your cart is empty.'),
                    ...cart.values.toList().map(
                      (p) => Column(
                        children: [
                          Text(p['name']),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Decrease quantity',
                                onPressed: submitting
                                    ? null
                                    : () {
                                        setState(() {
                                          if (p['quantity'] == 1) {
                                            cart.remove(p['id']);
                                          } else {
                                            p['quantity']--;
                                          }
                                        });
                                        update(() {});
                                      },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${p['quantity']}'),
                              IconButton(
                                tooltip: 'Increase quantity',
                                onPressed: submitting
                                    ? null
                                    : () {
                                        add(p);
                                        update(() {});
                                      },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Total ${formatPrice(total, currency)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Submit an order request. No online payment is collected. Contact the provider to arrange payment and collection.',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: cart.isEmpty || submitting
                    ? null
                    : () async {
                        update(() => submitting = true);
                        try {
                          await backend.rpc(
                            'create_order',
                            params: {
                              'items': cart.values
                                  .map(
                                    (p) => {
                                      'product_id': p['id'],
                                      'quantity': p['quantity'],
                                    },
                                  )
                                  .toList(),
                            },
                          );
                          if (!mounted) return;
                          setState(() => cart.clear());
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                          message('Order requested. No payment collected.');
                          changeTab(3);
                        } catch (_) {
                          if (mounted) {
                            message(
                              'Unable to submit. Stock or prices may have changed. Please refresh.',
                            );
                          }
                        } finally {
                          submitting = false;
                          if (dialogContext.mounted) update(() {});
                        }
                      },
                child: Text(submitting ? 'Submitting…' : 'Request order'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> account(String action) async {
    if (action == 'privacy') {
      await info(
        'Privacy and support',
        'This connected build stores account, booking and order data with your configured backend. Health record uploads are disabled. Before public launch, configure an operator privacy policy and monitored support contact.',
      );
      return;
    }
    if (!await login() || !mounted) return;
    if (action == 'logout') {
      try {
        await backend.auth.signOut();
        if (mounted) {
          setState(() {
            cart.clear();
            tab = 0;
            loading = load();
          });
        }
      } catch (_) {
        if (mounted) message('Sign out failed. Please try again.');
      }
      return;
    }
    if (action == 'delete') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request account deletion?'),
          content: const Text(
            'The operator will receive your request to delete your account and associated data, subject to legal retention requirements.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep account'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Request deletion'),
            ),
          ],
        ),
      );
      if (yes == true) {
        try {
          await backend.from('deletion_requests').upsert({
            'user_id': backend.auth.currentUser!.id,
          });
          if (mounted) message('Deletion request submitted.');
        } catch (_) {
          if (mounted) message('Unable to submit deletion request. Try again.');
        }
      }
      return;
    }
    try {
      final providers = await backend
          .from('providers')
          .select()
          .eq('owner_id', backend.auth.currentUser!.id)
          .eq('verified', true);
      if (!mounted) return;
      if (providers.isEmpty) {
        await info(
          'Provider onboarding',
          'A verified provider account must be assigned by the operator. Choosing a role never grants access.',
        );
        return;
      }
      final provider = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Choose your workspace'),
          children: providers
              .map(
                (p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, p),
                  child: Text(p['name']),
                ),
              )
              .toList(),
        ),
      );
      if (provider != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ConnectedProviderPortal(provider: provider),
          ),
        );
      }
    } catch (_) {
      if (mounted) message('Unable to load workspaces.');
    }
  }

  Future<void> info(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class ConnectedProviderPortal extends StatefulWidget {
  final Map<String, dynamic> provider;
  const ConnectedProviderPortal({super.key, required this.provider});
  @override
  State<ConnectedProviderPortal> createState() =>
      _ConnectedProviderPortalState();
}

class _ConnectedProviderPortalState extends State<ConnectedProviderPortal> {
  Future<List<Map<String, dynamic>>>? loading;
  bool busy = false;
  int beds = 0;
  @override
  void initState() {
    super.initState();
    beds = widget.provider['available_beds'];
    refresh();
  }

  bool get pharmacy => widget.provider['category'] == 'Pharmacy';
  void refresh() => setState(
    () => loading = pharmacy
        ? backend
              .from('products')
              .select()
              .eq('provider_id', widget.provider['id'])
        : backend
              .from('appointments')
              .select()
              .eq('provider_id', widget.provider['id'])
              .order('starts_at'),
  );
  Future<void> change(
    Map<String, dynamic> row, {
    int? stock,
    String? status,
  }) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (stock != null) {
        await backend
            .from('products')
            .update({'stock': stock})
            .eq('id', row['id']);
      } else {
        await backend.rpc(
          'set_booking',
          params: {'booking_id': row['id'], 'new_status': status},
        );
      }
      if (mounted) refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update failed. Refresh and try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addSlot() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    final start = DateTime(
      day.year,
      day.month,
      day.day,
      time.hour,
      time.minute,
    ).toUtc();
    if (!start.isAfter(DateTime.now().toUtc())) return;
    try {
      await backend.from('slots').insert({
        'provider_id': widget.provider['id'],
        'starts_at': start.toIso8601String(),
        'ends_at': start.add(const Duration(minutes: 30)).toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment slot published')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to publish this slot.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.provider['name'])),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                '${widget.provider['category']} workspace',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (!pharmacy)
                FilledButton.icon(
                  onPressed: addSlot,
                  icon: const Icon(Icons.add),
                  label: const Text('Publish appointment slot'),
                ),
              if (widget.provider['category'] == 'Hospitals')
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text('$beds available beds'),
                        Slider(
                          value: beds.toDouble(),
                          min: 0,
                          max: 10000,
                          divisions: 10000,
                          label: '$beds',
                          onChanged: (v) => setState(() => beds = v.round()),
                        ),
                        FilledButton(
                          onPressed: () async {
                            try {
                              await backend
                                  .from('providers')
                                  .update({'available_beds': beds})
                                  .eq('id', widget.provider['id']);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Capacity updated'),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Capacity update failed'),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Update capacity'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: loading,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return TextButton(
                      onPressed: refresh,
                      child: const Text('Unable to load. Try again.'),
                    );
                  }
                  final rows = snapshot.data ?? [];
                  if (rows.isEmpty) {
                    return const Text('No requests or inventory yet.');
                  }
                  return Column(
                    children: rows
                        .map(
                          (r) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pharmacy
                                        ? r['name']
                                        : 'Booking ${r['id'].toString().substring(0, 8)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    pharmacy
                                        ? '${r['stock']} in stock'
                                        : '${r['starts_at']} • ${r['status']}',
                                  ),
                                  if (pharmacy)
                                    Wrap(
                                      children: [
                                        IconButton(
                                          tooltip: 'Decrease stock',
                                          onPressed: busy || r['stock'] == 0
                                              ? null
                                              : () => change(
                                                  r,
                                                  stock: r['stock'] - 1,
                                                ),
                                          icon: const Icon(Icons.remove),
                                        ),
                                        IconButton(
                                          tooltip: 'Increase stock',
                                          onPressed: busy
                                              ? null
                                              : () => change(
                                                  r,
                                                  stock: r['stock'] + 1,
                                                ),
                                          icon: const Icon(Icons.add),
                                        ),
                                      ],
                                    ),
                                  if (!pharmacy &&
                                      ![
                                        'cancelled',
                                        'completed',
                                      ].contains(r['status']))
                                    Wrap(
                                      spacing: 8,
                                      children:
                                          [
                                                'confirmed',
                                                'completed',
                                                'cancelled',
                                              ]
                                              .map(
                                                (s) => OutlinedButton(
                                                  onPressed: busy
                                                      ? null
                                                      : () => change(
                                                          r,
                                                          status: s,
                                                        ),
                                                  child: Text(s),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              if (pharmacy) FulfillmentQueue(providerId: widget.provider['id']),
            ],
          ),
        ),
      ),
    ),
  );
}

class FulfillmentQueue extends StatefulWidget {
  final String providerId;
  const FulfillmentQueue({super.key, required this.providerId});
  @override
  State<FulfillmentQueue> createState() => _FulfillmentQueueState();
}

class _FulfillmentQueueState extends State<FulfillmentQueue> {
  late Future<List<Map<String, dynamic>>> loading;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() => setState(
    () => loading = backend
        .from('order_items')
        .select('*,products!inner(name,provider_id)')
        .eq('products.provider_id', widget.providerId)
        .eq('status', 'requested'),
  );
  Future<void> fulfill(Map<String, dynamic> row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm collection?'),
        content: const Text(
          'Mark this item fulfilled only after the customer has received it. This does not confirm online payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm collection'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => busy = true);
    try {
      await backend.rpc(
        'fulfill_item',
        params: {
          'selected_order': row['order_id'],
          'selected_product': row['product_id'],
        },
      );
      if (mounted) refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update fulfillment.')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 24),
      const Text(
        'Collection requests',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return TextButton(
              onPressed: refresh,
              child: const Text('Unable to load. Try again.'),
            );
          }
          final rows = snapshot.data ?? [];
          if (rows.isEmpty) return const Text('No open collection requests.');
          return Column(
            children: rows
                .map(
                  (row) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['products']['name'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Order ${row['order_id'].toString().substring(0, 8)} • Quantity ${row['quantity']}',
                          ),
                          TextButton(
                            onPressed: busy ? null : () => fulfill(row),
                            child: const Text('Confirm collection'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}
