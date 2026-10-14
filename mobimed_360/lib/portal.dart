import 'package:flutter/material.dart';

/// Sample operations only. Production permissions must come from the server.
class ProviderPortal extends StatefulWidget {
  final String role;
  const ProviderPortal({super.key, required this.role});
  @override
  State<ProviderPortal> createState() => _ProviderPortalState();
}

class _ProviderPortalState extends State<ProviderPortal> {
  bool available = false;
  int beds = 0;
  final inventory = <String, int>{
    'Digital thermometer': 12,
    'First aid kit': 8,
  };
  final tasks = <String, String>{
    'Sample request #001': 'Pending',
    'Sample request #002': 'Pending',
  };
  final note = TextEditingController();
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.role} workspace')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'DEMO WORKSPACE • Changes stay in this screen session',
                style: TextStyle(
                  color: Color(0xFF087F75),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'No real patient data or clinical access. A verified provider account and server permissions are required before live use.',
              ),
              const SizedBox(height: 24),
              if (widget.role == 'Doctor') ...[
                SwitchListTile.adaptive(
                  title: const Text('Accept consultation requests'),
                  subtitle: const Text('Demo availability'),
                  value: available,
                  onChanged: (v) => setState(() => available = v),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Consultation queue',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ...taskCards(['Waiting', 'Reviewed']),
                const SizedBox(height: 18),
                TextField(
                  controller: note,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Sample consultation note',
                    helperText:
                        'No real patient details. This does not issue a prescription.',
                  ),
                ),
                FilledButton(
                  onPressed: () =>
                      message('Sample note remains in this workspace only.'),
                  child: const Text('Save sample note'),
                ),
              ],
              if (widget.role == 'Hospital') ...[
                const Text(
                  'Sample facility capacity',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      children: [
                        Text(
                          '$beds available beds',
                          style: const TextStyle(fontSize: 20),
                        ),
                        IconButton(
                          tooltip: 'Remove bed',
                          onPressed: beds == 0
                              ? null
                              : () => setState(() => beds--),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        IconButton(
                          tooltip: 'Add bed',
                          onPressed: beds == 100
                              ? null
                              : () => setState(() => beds++),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'OPD request queue',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ...taskCards(['Accepted', 'Completed']),
              ],
              if (widget.role == 'Pathology') ...[
                const Text(
                  'Sample collection requests',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ...taskCards(['Assigned', 'Collected']),
                const SizedBox(height: 20),
                const Text(
                  'Reports',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'No reports uploaded. Verified report upload requires secure object storage, patient consent and server authorization.',
                ),
              ],
              if (widget.role == 'Medi-Store') ...[
                const Text(
                  'Sample inventory',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ...inventory.entries.toList().map(
                  (e) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Decrease ${e.key}',
                                onPressed: e.value == 0
                                    ? null
                                    : () => setState(
                                        () => inventory[e.key] = e.value - 1,
                                      ),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${e.value} in stock'),
                              IconButton(
                                tooltip: 'Increase ${e.key}',
                                onPressed: () => setState(
                                  () => inventory[e.key] = e.value + 1,
                                ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sample fulfillment queue',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ...taskCards(['Preparing', 'Dispatched']),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  List<Widget> taskCards(List<String> statuses) => tasks.entries
      .map(
        (e) => Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Status: ${e.value}'),
                Wrap(
                  spacing: 8,
                  children: statuses
                      .map(
                        (s) => OutlinedButton(
                          onPressed: () => setState(() => tasks[e.key] = s),
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
      .toList();
  void message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
