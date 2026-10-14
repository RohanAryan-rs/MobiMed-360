# Ponytail audit — original repository

1. shrink: Four duplicated directory card builders. Replace with one typed service directory and shared card. [lib/main.dart]
2. native: Custom stacked authentication and menu overlays. Replace with Material dialogs, Drawer and PopupMenuButton for focus, dismissal and small screens. [lib/main.dart]
3. delete: ASCII icon state flags and monospace wireframe styling. Replace with accessible Material icons. [lib/main.dart]
4. yagni: Proposed microservices, Riverpod and GoRouter before a production backend exists. Use Flutter state and navigation until real complexity requires them. [docs/02_TECHNICAL_REQUIREMENTS.md]
5. delete: Unused Cupertino icon dependency in the original prototype. Replacement: existing Material icons. [pubspec.yaml]

net: -181 lines, -1 deps possible.

Estimates refer to original Flutter implementation; this audit applies no changes. Implementation work is separately authorized by the application request. Correctness and security findings are outside this audit: fake login, false payment confirmation, fictional video connection, provider roles granted by a client selector, and missing platform projects must be addressed before release.
