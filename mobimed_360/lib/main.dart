import 'dart:async';
import 'portal.dart';
import 'backend.dart';
import 'live.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!demo) {
    try {
      await initializeBackend();
    } catch (_) {
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Live backend is not configured. Supply SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY, or run with DEMO_MODE=true.',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }
  }
  runApp(const MobiMed360App());
}

const teal = Color(0xFF087F75);
const ink = Color(0xFF173C42);
const demo = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

class MobiMed360App extends StatelessWidget {
  const MobiMed360App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MobiMed 360',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: teal, primary: teal),
      scaffoldBackgroundColor: const Color(0xFFF4F8F7),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: demo ? const MobiMedShell() : const ConnectedCareApp(),
  );
}

class CareService {
  final String id, category, name, detail, provider;
  final int cents;
  final IconData icon;
  const CareService(
    this.id,
    this.category,
    this.name,
    this.detail,
    this.provider,
    this.cents,
    this.icon,
  );
}

const services = [
  CareService(
    'd1',
    'Doctors',
    'Dr. Maya Patel',
    'General physician • English, Hindi',
    'Example Care Clinic',
    3000,
    Icons.person_outline,
  ),
  CareService(
    'd2',
    'Doctors',
    'Dr. Daniel Kim',
    'Cardiology • English, Korean',
    'Example Heart Clinic',
    4500,
    Icons.person_outline,
  ),
  CareService(
    'd3',
    'Doctors',
    'Dr. Sofia Reed',
    'Dermatology • English, Spanish',
    'Example Skin Clinic',
    3500,
    Icons.person_outline,
  ),
  CareService(
    'm1',
    'Pharmacy',
    'Digital thermometer',
    'No prescription required',
    'Example Community Pharmacy',
    1250,
    Icons.medical_services_outlined,
  ),
  CareService(
    'm2',
    'Pharmacy',
    'First aid kit',
    'Home care essentials',
    'Example Community Pharmacy',
    1800,
    Icons.medical_services_outlined,
  ),
  CareService(
    'l1',
    'Labs',
    'Complete blood count',
    'Home collection',
    'Example Diagnostics',
    2200,
    Icons.science_outlined,
  ),
  CareService(
    'l2',
    'Labs',
    'Lipid profile',
    'Confirm preparation instructions with your lab',
    'Example Diagnostics',
    2800,
    Icons.science_outlined,
  ),
  CareService(
    'h1',
    'Hospitals',
    'General OPD visit',
    'Outpatient consultation',
    'Example City Hospital',
    2000,
    Icons.local_hospital_outlined,
  ),
  CareService(
    'h2',
    'Hospitals',
    'Specialist OPD visit',
    'Request a specialist appointment',
    'Example Medical Center',
    3500,
    Icons.local_hospital_outlined,
  ),
];
const categories = ['Doctors', 'Pharmacy', 'Labs', 'Hospitals'];
const categoryIcons = [
  Icons.medical_services_outlined,
  Icons.medication_outlined,
  Icons.science_outlined,
  Icons.local_hospital_outlined,
];
String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

class Booking {
  final CareService service;
  final DateTime date;
  bool cancelled = false;
  Booking(this.service, this.date);
}

class MobiMedShell extends StatefulWidget {
  const MobiMedShell({super.key});
  @override
  State<MobiMedShell> createState() => _MobiMedShellState();
}

class _MobiMedShellState extends State<MobiMedShell> {
  Timer? timer;
  bool splash = true, signedIn = false;
  int tab = 0;
  String category = 'Doctors', query = '', specialty = 'All';
  final search = TextEditingController();
  final Map<String, int> cart = {};
  final List<Booking> bookings = [];
  final List<String> orders = [];
  int get total => cart.entries.fold(
    0,
    (sum, e) => sum + services.firstWhere((s) => s.id == e.key).cents * e.value,
  );
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => splash = false);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }

  void notify(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
  Future<bool> authenticate() async {
    if (signedIn) return true;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to MobiMed'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your care, all in one place. Browse freely or explore a labelled demo account.',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => notify(
                  'Google sign-in requires a configured identity service.',
                ),
                icon: const Icon(Icons.account_circle_outlined),
                label: const Text('Continue with Google'),
              ),
              OutlinedButton.icon(
                onPressed: () => notify(
                  'Apple sign-in requires a configured identity service.',
                ),
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),
              OutlinedButton.icon(
                onPressed: () => notify(
                  'SMS verification requires a configured OTP service.',
                ),
                icon: const Icon(Icons.phone_outlined),
                label: const Text('Continue with mobile'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Live sign-in is unavailable. Never enter real health information in demo mode.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (demo)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Explore demo account'),
            ),
        ],
      ),
    );
    if (!mounted || accepted != true) return false;
    setState(() => signedIn = true);
    return true;
  }

  Future<void> navigate(int value) async {
    if (value >= 2 && !await authenticate()) return;
    if (mounted) {
      setState(() {
        tab = value;
      });
    }
  }

  void openCategory(String value) => setState(() {
    category = value;
    tab = 1;
    query = '';
    search.clear();
    specialty = 'All';
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 760;
      const destinations = [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          label: 'Find care',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          label: 'Records',
        ),
      ];
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: InkWell(
            onTap: () => navigate(0),
            child: const Text(
              'MobiMed 360',
              style: TextStyle(color: ink, fontWeight: FontWeight.w800),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Care cart',
              onPressed: checkout,
              icon: Badge(
                isLabelVisible: cart.isNotEmpty,
                label: Text('${cart.values.fold(0, (a, b) => a + b)}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Profile and portals',
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: profile,
              itemBuilder: (_) => [
                'Patient',
                'Doctor',
                'Hospital',
                'Pathology',
                'Medi-Store',
                'Privacy',
                'About',
                'Support',
                if (signedIn) 'Sign out',
                if (signedIn) 'Delete demo data',
              ].map((r) => PopupMenuItem(value: r, child: Text(r))).toList(),
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: ListView(
              children: [
                const ListTile(
                  title: Text(
                    'Your care companion',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    navigate(0);
                  },
                ),
                ExpansionTile(
                  title: const Text('Services'),
                  children: categories
                      .map(
                        (c) => ListTile(
                          title: Text(c),
                          onTap: () {
                            Navigator.pop(context);
                            openCategory(c);
                          },
                        ),
                      )
                      .toList(),
                ),
                ListTile(
                  title: const Text('Appointments'),
                  onTap: () {
                    Navigator.pop(context);
                    navigate(2);
                  },
                ),
                ListTile(
                  title: const Text('Support'),
                  onTap: () {
                    Navigator.pop(context);
                    profile('Support');
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: wide || splash
            ? null
            : NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: navigate,
                destinations: destinations,
              ),
        body: SafeArea(
          child: splash
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.health_and_safety,
                        color: teal,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome To MobiMed 360',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('A little closer to better care'),
                      TextButton(
                        onPressed: () => setState(() => splash = false),
                        child: const Text('Get started'),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    if (wide)
                      NavigationRail(
                        selectedIndex: tab,
                        onDestinationSelected: navigate,
                        labelType: NavigationRailLabelType.all,
                        destinations: destinations
                            .map(
                              (d) => NavigationRailDestination(
                                icon: d.icon,
                                selectedIcon: d.selectedIcon,
                                label: Text(d.label),
                              ),
                            )
                            .toList(),
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: ListView(
                            key: ValueKey('$tab-$category'),
                            padding: EdgeInsets.all(wide ? 32 : 20),
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  demo
                                      ? 'DEMO • Sample providers, prices and availability • No real transactions'
                                      : 'Live services are not configured in this build',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF59696B),
                                  ),
                                ),
                              ),
                              ...switch (tab) {
                                0 => home(),
                                1 => directory(),
                                2 => appointments(),
                                _ => records(),
                              },
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
                  ],
                ),
        ),
      );
    },
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
  );
  List<Widget> home() => [
    const Text(
      'CARE THAT FITS YOUR LIFE',
      style: TextStyle(
        color: teal,
        fontSize: 12,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(height: 10),
    const Text(
      'Feel better.\nStart here.',
      style: TextStyle(
        fontSize: 38,
        height: 1.15,
        color: ink,
        fontWeight: FontWeight.w800,
      ),
    ),
    const SizedBox(height: 12),
    const Text(
      'Find a doctor, arrange tests and access everyday healthcare from one calm, connected place.',
      style: TextStyle(fontSize: 16, height: 1.6),
    ),
    const SizedBox(height: 24),
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: teal,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_outline, color: Colors.white, size: 36),
          const SizedBox(height: 16),
          const Text(
            'The right care.\nA conversation away.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Explore specialists and choose a time that works for you.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: () => openCategory('Doctors'),
            child: const Text('Find your doctor'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 28),
    heading('How can we help?'),
    LayoutBuilder(
      builder: (context, box) {
        final count = box.maxWidth >= 850
            ? 4
            : box.maxWidth < 340
            ? 1
            : 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (i) => SizedBox(
              width: (box.maxWidth - 12 * (count - 1)) / count,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => openCategory(categories[i]),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(categoryIcons[i], color: teal, size: 32),
                        const SizedBox(height: 20),
                        Text(
                          categories[i],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [
                            'Book a consultation',
                            'Everyday essentials',
                            'Tests & home collection',
                            'Outpatient services',
                          ][i],
                        ),
                        const SizedBox(height: 12),
                        const Icon(Icons.arrow_forward, size: 20, color: teal),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
    const SizedBox(height: 24),
    Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: const Icon(Icons.calendar_month, color: teal),
        title: const Text('Your next step to better health'),
        subtitle: const Text('Keep appointments in one place.'),
        onTap: () => navigate(2),
      ),
    ),
  ];
  List<Widget> directory() {
    final items = services
        .where(
          (s) =>
              s.category == category &&
              '${s.name} ${s.detail} ${s.provider}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (specialty == 'All' || s.detail.contains(specialty)),
        )
        .toList();
    return [
      heading('Find your care'),
      const Text(
        'Sample directory • Location and provider verification are not connected.',
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories
            .map(
              (c) => ChoiceChip(
                label: Text(c),
                selected: category == c,
                onSelected: (_) => openCategory(c),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: search,
        onChanged: (v) => setState(() => query = v),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          labelText: 'Search $category',
        ),
      ),
      if (category == 'Doctors')
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Wrap(
            spacing: 8,
            children: ['All', 'General', 'Cardiology', 'Dermatology']
                .map(
                  (s) => FilterChip(
                    label: Text(s),
                    selected: specialty == s,
                    onSelected: (_) => setState(() => specialty = s),
                  ),
                )
                .toList(),
          ),
        ),
      const SizedBox(height: 12),
      if (items.isEmpty) empty('No matches', 'Try another name or specialty.'),
      ...items.map(
        (s) => Card(
          margin: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE3F2EE),
                      foregroundColor: teal,
                      radius: 26,
                      child: Icon(s.icon),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(s.detail),
                const SizedBox(height: 6),
                Text(
                  s.provider,
                  style: const TextStyle(color: Color(0xFF59696B)),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      money(s.cents),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () =>
                          s.category == 'Pharmacy' ? add(s) : book(s),
                      icon: Icon(
                        s.category == 'Pharmacy'
                            ? Icons.add
                            : Icons.calendar_today_outlined,
                        size: 18,
                      ),
                      label: Text(
                        s.category == 'Pharmacy'
                            ? 'Add to cart'
                            : 'Choose a time',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  void add(CareService s) {
    setState(() => cart.update(s.id, (q) => q + 1, ifAbsent: () => 1));
    notify('${s.name} added to your cart');
  }

  Future<void> book(CareService s) async {
    if (!await authenticate() || !mounted) return;
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    final date = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    if (!date.isAfter(DateTime.now())) {
      notify('Please choose a future appointment time.');
      return;
    }
    if (bookings.any((b) => !b.cancelled && b.date == date)) {
      notify('You already have a booking at this time.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review demo booking'),
        content: Text(
          '${s.name}\n${dateLabel(date)}\n${money(s.cents)}\n\nSample appointment only. No provider is contacted and no payment is collected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create demo booking'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        bookings.add(Booking(s, date));
        bookings.sort((a, b) => a.date.compareTo(b.date));
        tab = 2;
      });
    }
  }

  String dateLabel(DateTime date) =>
      '${MaterialLocalizations.of(context).formatMediumDate(date)} • ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
  List<Widget> appointments() => [
    heading('Your bookings'),
    const Text('Plan your care, one step at a time.'),
    const SizedBox(height: 20),
    if (bookings.isEmpty)
      empty(
        'A fresh start',
        'Choose a provider to create your first demo booking.',
      ),
    ...bookings.map(
      (b) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.service.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(dateLabel(b.date)),
              Text(
                b.service.category == 'Doctors'
                    ? 'Video consultation'
                    : b.service.category == 'Labs'
                    ? 'Home collection'
                    : 'In person',
              ),
              const SizedBox(height: 10),
              Text(
                b.cancelled
                    ? 'Cancelled'
                    : 'Demo booking • Not sent to provider',
                style: const TextStyle(color: teal),
              ),
              if (!b.cancelled)
                Wrap(
                  spacing: 12,
                  children: [
                    if (b.service.category == 'Doctors')
                      OutlinedButton.icon(
                        onPressed: () => notify(
                          'Video consultations require a configured LiveKit service.',
                        ),
                        icon: const Icon(Icons.videocam_outlined),
                        label: const Text('Consultation details'),
                      ),
                    TextButton(
                      onPressed: () => cancel(b),
                      child: const Text('Cancel booking'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    ),
  ];
  Future<void> cancel(Booking b) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this demo booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) setState(() => b.cancelled = true);
  }

  List<Widget> records() => [
    heading('Your health records'),
    empty(
      'Your records belong here',
      'No medical records uploaded. Secure reports and prescriptions require the production service.',
    ),
    const SizedBox(height: 20),
    heading('Demo orders'),
    if (orders.isEmpty) const Text('No demo orders yet.'),
    ...orders.map(
      (o) => Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(o),
          subtitle: const Text('Sample order • No payment or delivery'),
        ),
      ),
    ),
  ];
  Widget empty(String title, String detail) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(Icons.health_and_safety_outlined, color: teal, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
  Future<void> checkout() async {
    if (!await authenticate() || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Your care cart'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cart.isEmpty) const Text('Your cart is empty.'),
                  ...cart.entries.toList().map((e) {
                    final s = services.firstWhere((s) => s.id == e.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Decrease ${s.name}',
                                onPressed: () {
                                  setState(() {
                                    if (e.value == 1) {
                                      cart.remove(e.key);
                                    } else {
                                      cart[e.key] = e.value - 1;
                                    }
                                  });
                                  update(() {});
                                },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${e.value}'),
                              IconButton(
                                tooltip: 'Increase ${s.name}',
                                onPressed: () {
                                  setState(() => cart[e.key] = e.value + 1);
                                  update(() {});
                                },
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              Text(money(s.cents * e.value)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Text(
                    'Total ${money(total)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Demo checkout only. No funds collected. Live payments and delivery are not configured.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: cart.isEmpty || !demo
                  ? null
                  : () {
                      setState(() {
                        orders.insert(
                          0,
                          'Demo order ${orders.length + 1} • ${money(total)}',
                        );
                        cart.clear();
                      });
                      Navigator.pop(dialogContext);
                      notify('Demo order created. No payment was taken.');
                    },
              child: const Text('Create demo order'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> profile(String value) async {
    if (value == 'Sign out') {
      setState(() {
        signedIn = false;
        tab = 0;
      });
      return;
    }
    if (value == 'Delete demo data') {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete all demo data?'),
          content: const Text(
            'Removes sample bookings, orders, cart and your demo session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep data'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete data'),
            ),
          ],
        ),
      );
      if (yes == true && mounted) {
        setState(() {
          bookings.clear();
          orders.clear();
          cart.clear();
          signedIn = false;
          tab = 0;
        });
      }
      return;
    }
    if (['Privacy', 'About', 'Support'].contains(value)) {
      await info(value, switch (value) {
        'Privacy' =>
          'This demo keeps sample bookings and orders in memory for this running app session. It does not authenticate users, collect payment, upload health records or access location. Do not enter real health information. The production privacy policy must identify the operator, data use, retention and deletion process before launch.',
        'About' =>
          'MobiMed 360 connects doctor discovery, pharmacy essentials, diagnostic bookings and hospital services. This evaluation build has fictional sample providers. It does not provide medical advice.',
        _ =>
          'Live support is not configured. Before launch, provide a monitored support contact and account deletion webpage. For urgent medical needs contact your local emergency service.',
      });
      return;
    }
    if (!await authenticate() || !mounted) return;
    if (value == 'Patient') {
      navigate(0);
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ProviderPortal(role: value)),
    );
  }

  Future<void> info(String title, String body) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
