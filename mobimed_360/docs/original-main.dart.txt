import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MobiMed360App());
}

enum MobiMedRole { patient, doctor, hospital, pathology, mediStore }

extension MobiMedRoleLabel on MobiMedRole {
  String get label {
    switch (this) {
      case MobiMedRole.patient:
        return 'Patient';
      case MobiMedRole.doctor:
        return 'Doctor';
      case MobiMedRole.hospital:
        return 'Hospital';
      case MobiMedRole.pathology:
        return 'Pathology';
      case MobiMedRole.mediStore:
        return 'Medi-Store';
    }
  }
}

class CartItem {
  final String id;
  final String title;
  final String providerName;
  final String category;
  final double price;
  int qty;

  CartItem({
    required this.id,
    required this.title,
    required this.providerName,
    required this.category,
    required this.price,
    this.qty = 1,
  });
}

class MobiMed360App extends StatelessWidget {
  const MobiMed360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobiMed-360',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          primary: const Color(0xFF0D9488),
          secondary: const Color(0xFF2563EB),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const MobiMedShell(),
    );
  }
}

class MobiMedShell extends StatefulWidget {
  const MobiMedShell({super.key});

  @override
  State<MobiMedShell> createState() => _MobiMedShellState();
}

class _MobiMedShellState extends State<MobiMedShell> {
  // First View: disappears automatically after 3 seconds
  bool _showFirstViewSplash = true;
  Timer? _splashTimer;

  // Navigation & Dropdown states (Views 2, 3, 4, 5)
  String _activeScreen = 'home'; // home, doctors, medistore, pathology, hospital, appointments, checkout, about, support
  bool _isHamburgerMenuOpen = false; // ||| -> |*| (Third View)
  bool _isServicesSubmenuOpen = false; // < Services flyout (Third View)
  bool _isRoleMenuOpen = false; // (@) -> (P) (Fourth View)
  bool _showAuthModal = false; // Fifth View modal

  // Auth & Role State
  bool _isLoggedIn = false;
  MobiMedRole _selectedRole = MobiMedRole.patient;
  String _userPhoneOrEmail = '';
  String? _pendingProtectedScreen;

  final List<CartItem> _cart = [
    CartItem(
      id: 'MED-1',
      title: 'Augmentin 625 Duo (10 Tabs)',
      providerName: 'Apollo Nearest Medi-Store (0.8 km)',
      category: 'Medi-Store',
      price: 18.50,
    ),
    CartItem(
      id: 'LAB-1',
      title: 'Full Body Checkup + HbA1c',
      providerName: 'Dr. Lal Pathology Center (1.2 km)',
      category: 'Pathology',
      price: 49.00,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _splashTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showFirstViewSplash = false);
      }
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    super.dispose();
  }

  void _navigateTo(String screen, {bool requiresAuth = false}) {
    setState(() {
      _isHamburgerMenuOpen = false;
      _isServicesSubmenuOpen = false;
      _isRoleMenuOpen = false;

      if (requiresAuth && !_isLoggedIn) {
        // Third View Rule: "If login then open, otherwise ask to login"
        _pendingProtectedScreen = screen;
        _showAuthModal = true;
      } else {
        _activeScreen = screen;
      }
    });
  }

  void _selectRoleFromDropdown(MobiMedRole role) {
    setState(() {
      _selectedRole = role;
      _isRoleMenuOpen = false;
      _isHamburgerMenuOpen = false;
      _showAuthModal = true; // Opens Fifth View SignUp/Login modal
    });
  }

  void _completeLogin(String identifier) {
    setState(() {
      _isLoggedIn = true;
      _userPhoneOrEmail = identifier;
      _showAuthModal = false;
      if (_pendingProtectedScreen != null) {
        _activeScreen = _pendingProtectedScreen!;
        _pendingProtectedScreen = null;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged in as ${_selectedRole.label} ($identifier)'),
      ),
    );
  }

  void _addToCart(CartItem item) {
    setState(() {
      final index = _cart.indexWhere((e) => e.id == item.id);
      if (index >= 0) {
        _cart[index].qty += 1;
      } else {
        _cart.add(item);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.title} added to cart')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(bottom: BorderSide(color: Colors.white24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => _navigateTo('home'),
                    child: Row(
                      children: [
                        const Text(
                          'MobiMed-360',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (_isLoggedIn) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _selectedRole.label,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Cart Shortcut
                      IconButton(
                        onPressed: () =>
                            _navigateTo('checkout', requiresAuth: true),
                        icon: Badge(
                          isLabelVisible: _cart.isNotEmpty,
                          label: Text('${_cart.length}'),
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Fourth View Trigger: (@) -> (P)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isRoleMenuOpen = !_isRoleMenuOpen;
                            _isHamburgerMenuOpen = false;
                          });
                        },
                        child: Text(
                          _isRoleMenuOpen ? '(P)' : '(@)',
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      // Third View Trigger: ||| -> |*|
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isHamburgerMenuOpen = !_isHamburgerMenuOpen;
                            _isRoleMenuOpen = false;
                          });
                        },
                        child: Text(
                          _isHamburgerMenuOpen ? '|*|' : '|||',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Body: Either First View (3s Splash) or Active View
          _showFirstViewSplash ? _buildFirstViewSplash() : _buildActiveBody(),

          // Third View Overlay: Hamburger Menu (||| -> |*|) + < Services Flyout
          if (_isHamburgerMenuOpen) _buildThirdViewMenu(),

          // Fourth View Overlay: Role Selector ((@) -> (P))
          if (_isRoleMenuOpen) _buildFourthViewRoleDropdown(),

          // Fifth View Overlay: SignUp / Login Modal (|G| |A| or Mobile Number)
          if (_showAuthModal) _buildFifthViewAuthModal(),
        ],
      ),
    );
  }

  // ==========================================================================
  // FIRST VIEW: 3-SECOND SPLASH VIEW
  // ==========================================================================
  Widget _buildFirstViewSplash() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome\nTo\nMobiMed\n360',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.35,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => setState(() => _showFirstViewSplash = false),
            child: const Text(
              'Auto-entering in 3 sec... (Tap to skip)',
              style: TextStyle(color: Colors.tealAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // THIRD VIEW: CASCADING HAMBURGER MENU (||| -> |*|)
  // ==========================================================================
  Widget _buildThirdViewMenu() {
    return Positioned(
      top: 8,
      right: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isServicesSubmenuOpen)
            Card(
              color: const Color(0xFF1E293B),
              child: SizedBox(
                width: 150,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _menuTile('Doctors', () => _navigateTo('doctors')),
                    _menuTile('Medi-store', () => _navigateTo('medistore')),
                    _menuTile('Pathology', () => _navigateTo('pathology')),
                    _menuTile('Hospitals', () => _navigateTo('hospital')),
                  ],
                ),
              ),
            ),
          Card(
            color: const Color(0xFF0F172A),
            child: SizedBox(
              width: 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _menuTile('Home', () => _navigateTo('home')),
                  _menuTile(
                    '< Services',
                    () => setState(() =>
                        _isServicesSubmenuOpen = !_isServicesSubmenuOpen),
                  ),
                  _menuTile(
                    'Appointments',
                    () => _navigateTo('appointments', requiresAuth: true),
                  ),
                  _menuTile('About', () => _navigateTo('home')),
                  _menuTile('Support', () => _navigateTo('home')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // FOURTH VIEW: 5-ROLE PORTAL DROPDOWN ((@) -> (P))
  // ==========================================================================
  Widget _buildFourthViewRoleDropdown() {
    return Positioned(
      top: 8,
      right: 56,
      child: Card(
        color: const Color(0xFF0F172A),
        child: SizedBox(
          width: 180,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: MobiMedRole.values
                .map((role) => _menuTile(
                      '> ${role.label}',
                      () => _selectRoleFromDropdown(role),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _menuTile(String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  // ==========================================================================
  // FIFTH VIEW: SIGNUP / LOGIN MODAL (|G| |A| OR MOBILE NUMBER)
  // ==========================================================================
  Widget _buildFifthViewAuthModal() {
    final phoneCtrl = TextEditingController(text: '+1 555-019-2834');
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Card(
          color: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Colors.white38),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => setState(() => _showAuthModal = false),
                    child: const Text(
                      '*',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Text(
                  'SignUp (${_selectedRole.label})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Continue with',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          _completeLogin('google.${_selectedRole.name}@mobimed.app'),
                      child: const Text('|G|',
                          style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () =>
                          _completeLogin('apple.${_selectedRole.name}@mobimed.app'),
                      child: const Text('|A|',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('or', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () => _completeLogin(phoneCtrl.text),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // SECOND VIEW & SERVICE SCREENS
  // ==========================================================================
  Widget _buildActiveBody() {
    switch (_activeScreen) {
      case 'doctors':
        return _buildDoctorsScreen();
      case 'medistore':
        return _buildMediStoreScreen();
      case 'pathology':
        return _buildPathologyScreen();
      case 'hospital':
        return _buildHospitalScreen();
      case 'appointments':
        return _buildAppointmentsAndLiveConsultScreen();
      case 'checkout':
        return _buildCheckoutScreen();
      case 'home':
      default:
        return _buildSecondViewHome();
    }
  }

  Widget _buildSecondViewHome() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Exact Second View Mission Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
          ),
          child: const Text(
            '+ MobiMed is an application to help you to reach the best '
            'global doctors and can book appointment for live consultant '
            'and purchase the medicine online the nearest medical store '
            '& find the nearest pathology & online services from Hospital',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _quickServiceCard(
              icon: Icons.medical_services_outlined,
              title: 'Global Doctors',
              subtitle: 'Book appointment for live video consultant',
              onTap: () => _navigateTo('doctors'),
            ),
            _quickServiceCard(
              icon: Icons.local_pharmacy_outlined,
              title: 'Nearest Medi-Store',
              subtitle: 'Purchase medicines online from nearest store',
              onTap: () => _navigateTo('medistore'),
            ),
            _quickServiceCard(
              icon: Icons.biotech_outlined,
              title: 'Nearest Pathology',
              subtitle: 'Home sample collection & smart lab reports',
              onTap: () => _navigateTo('pathology'),
            ),
            _quickServiceCard(
              icon: Icons.local_hospital_outlined,
              title: 'Hospital Services',
              subtitle: 'Online OPD, ICU beds & 24x7 emergency',
              onTap: () => _navigateTo('hospital'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 260,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: const Color(0xFF0D9488), size: 32),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorsScreen() {
    final doctors = [
      ('Dr. Aanya Sharma', 'Global Cardiologist (MD, DM)', 'Apollo Global', 30.0),
      ('Dr. James Carter', 'Neurologist (Johns Hopkins)', 'Global TeleMed', 45.0),
      ('Dr. Vikram Nair', 'Internal Medicine Specialist', 'City Care', 20.0),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Global Doctors — Live Consultant Booking',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...doctors.map((d) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(d.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${d.$2} • ${d.$3}'),
                trailing: FilledButton.icon(
                  onPressed: () {
                    _addToCart(CartItem(
                      id: d.$1,
                      title: 'Live Consult: ${d.$1}',
                      providerName: d.$3,
                      category: 'Doctor',
                      price: d.$4,
                    ));
                    _navigateTo('appointments', requiresAuth: true);
                  },
                  icon: const Icon(Icons.videocam, size: 16),
                  label: Text('Book (\$${d.$4.toInt()})'),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildMediStoreScreen() {
    final meds = [
      ('Augmentin 625 Duo', 'Apollo Medi-Store (0.8 km away)', 18.50),
      ('Telma 40mg (30 Tabs)', 'MedPlus Pharmacy (1.1 km away)', 14.00),
      ('Accu-Chek Glucometer', 'Wellness Forever (1.5 km away)', 39.99),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Nearest Medi-Store — Online Medicine Purchase',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...meds.map((m) => Card(
              child: ListTile(
                leading: const Icon(Icons.medication, color: Color(0xFF0D9488)),
                title: Text(m.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(m.$2),
                trailing: FilledButton(
                  onPressed: () => _addToCart(CartItem(
                    id: m.$1,
                    title: m.$1,
                    providerName: m.$2,
                    category: 'Medi-Store',
                    price: m.$3,
                  )),
                  child: Text('+ \$${m.$3.toStringAsFixed(2)}'),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPathologyScreen() {
    final labs = [
      ('Full Body Checkup (82 Tests)', 'Dr. Lal PathLabs (1.2 km away)', 49.00),
      ('HbA1c & Lipid Profile', 'SRL Diagnostics (1.9 km away)', 22.00),
      ('Thyroid Profile (T3, T4, TSH)', 'Metropolis Lab (2.4 km away)', 15.00),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Nearest Pathology Labs & Home Sample Collection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...labs.map((l) => Card(
              child: ListTile(
                leading: const Icon(Icons.biotech, color: Color(0xFF2563EB)),
                title: Text(l.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(l.$2),
                trailing: FilledButton(
                  onPressed: () => _addToCart(CartItem(
                    id: l.$1,
                    title: l.$1,
                    providerName: l.$2,
                    category: 'Pathology',
                    price: l.$3,
                  )),
                  child: Text('Book \$${l.$3.toStringAsFixed(0)}'),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildHospitalScreen() {
    final hospitals = [
      ('Apollo Multi-Specialty Hospital', '1.8 km • 14 ICU Beds Available', 15.0),
      ('City Care Super Hospital', '3.1 km • 24x7 Emergency & OPD', 12.0),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Nearest Hospital Online Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...hospitals.map((h) => Card(
              child: ListTile(
                leading:
                    const Icon(Icons.local_hospital, color: Colors.redAccent),
                title: Text(h.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(h.$2),
                trailing: FilledButton(
                  onPressed: () => _addToCart(CartItem(
                    id: h.$1,
                    title: 'OPD Priority Pass: ${h.$1}',
                    providerName: h.$2,
                    category: 'Hospital',
                    price: h.$3,
                  )),
                  child: const Text('Book OPD'),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildAppointmentsAndLiveConsultScreen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Live Appointments (${_selectedRole.label} Portal: $_userPhoneOrEmail)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam, color: Colors.tealAccent, size: 48),
              SizedBox(height: 8),
              Text(
                'Live WebRTC Consultation Room — Dr. Aanya Sharma',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              Text(
                '● Encrypted HD Stream Connected',
                style: TextStyle(color: Colors.tealAccent, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutScreen() {
    final total = _cart.fold<double>(0, (s, i) => s + i.price * i.qty);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Unified Checkout & Payment Gateway',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._cart.map((c) => Card(
              child: ListTile(
                title: Text(c.title),
                subtitle: Text('${c.category} • ${c.providerName}'),
                trailing:
                    Text('\$${(c.price * c.qty).toStringAsFixed(2)}'),
              ),
            )),
        const Divider(),
        ListTile(
          title: const Text('Total Payable',
              style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text('\$${total.toStringAsFixed(2)}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        FilledButton(
          onPressed: () {
            setState(() => _cart.clear());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment Confirmed!')),
            );
          },
          child: const Text('Pay Now (UPI / Card / Apple Pay)'),
        ),
      ],
    );
  }
}
