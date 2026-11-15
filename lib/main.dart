import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() => runApp(const TravelExpenseApp());

class TravelExpenseApp extends StatelessWidget {
  const TravelExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2563EB);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel Expense',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        useMaterial3: true,
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final pages = const [DashboardPage(), ExpensesPage(), AddExpensePage(), ProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(CupertinoIcons.house), selectedIcon: Icon(CupertinoIcons.house_fill), label: 'Home'),
          NavigationDestination(icon: Icon(CupertinoIcons.doc_text), selectedIcon: Icon(CupertinoIcons.doc_text_fill), label: 'Expenses'),
          NavigationDestination(icon: Icon(CupertinoIcons.camera), selectedIcon: Icon(CupertinoIcons.camera_fill), label: 'Add'),
          NavigationDestination(icon: Icon(CupertinoIcons.person), selectedIcon: Icon(CupertinoIcons.person_fill), label: 'Profile'),
        ],
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({required this.title, required this.child, this.subtitle, super.key});
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: [
        SliverAppBar.large(
          pinned: true,
          title: Text(title),
          actions: [IconButton(onPressed: () {}, icon: const Icon(CupertinoIcons.bell))],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          sliver: SliverList.list(children: [
            if (subtitle != null) ...[
              Text(subtitle!, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 18),
            ],
            child,
          ]),
        ),
      ]);
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Good afternoon',
        subtitle: 'Your travel expenses at a glance',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Card(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('November total', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: .8))),
                const SizedBox(height: 8),
                Text('₹12,480.00', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 18),
                Row(children: [
                  _pill(context, '8 bills'),
                  const SizedBox(width: 8),
                  _pill(context, '2 pending'),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent expenses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          const ExpenseTile(merchant: 'ABC Components', meta: 'Meals • Today, 1:30 PM', amount: '₹845.50', icon: CupertinoIcons.cart),
          const SizedBox(height: 10),
          const ExpenseTile(merchant: 'City Taxi', meta: 'Transport • Yesterday', amount: '₹1,280.00', icon: CupertinoIcons.car_detailed),
          const SizedBox(height: 10),
          const ExpenseTile(merchant: 'Grand Business Hotel', meta: 'Hotel • 12 Nov', amount: '₹8,950.00', icon: CupertinoIcons.building_2_fill),
        ]),
      );

  Widget _pill(BuildContext context, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: .14), borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600)),
      );
}

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Expenses',
        child: Column(children: [
          const TextField(decoration: InputDecoration(hintText: 'Search merchant or bill', prefixIcon: Icon(CupertinoIcons.search))),
          const SizedBox(height: 14),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Meals', 'Transport', 'Hotel'].map((e) => Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(e), selected: e == 'All', onSelected: (_) {}))).toList())),
          const SizedBox(height: 18),
          const ExpenseTile(merchant: 'ABC Components', meta: 'Meals • Today, 1:30 PM', amount: '₹845.50', icon: CupertinoIcons.cart),
          const SizedBox(height: 10),
          const ExpenseTile(merchant: 'City Taxi', meta: 'Transport • Yesterday', amount: '₹1,280.00', icon: CupertinoIcons.car_detailed),
          const SizedBox(height: 10),
          const ExpenseTile(merchant: 'Grand Business Hotel', meta: 'Hotel • 12 Nov', amount: '₹8,950.00', icon: CupertinoIcons.building_2_fill),
        ]),
      );
}

class ExpenseTile extends StatelessWidget {
  const ExpenseTile({required this.merchant, required this.meta, required this.amount, required this.icon, super.key});
  final String merchant, meta, amount;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
          title: Text(merchant, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(meta),
          trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );
}

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});
  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  String category = 'Meals';
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Add expense',
        subtitle: 'Capture a bill and add its details',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera integration arrives in Build 4.'))),
            child: Container(
              height: 180,
              decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(20), color: Theme.of(context).colorScheme.surface),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(CupertinoIcons.camera_fill, size: 42), SizedBox(height: 12), Text('Tap to photograph bill', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('JPG or PNG • up to 10 MB')]),
            ),
          ),
          const SizedBox(height: 18),
          const TextField(decoration: InputDecoration(labelText: 'Merchant name', prefixIcon: Icon(CupertinoIcons.building_2_fill))),
          const SizedBox(height: 14),
          const Row(children: [
            Expanded(flex: 2, child: TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount', prefixText: '₹ '))),
            SizedBox(width: 12),
            Expanded(child: TextField(decoration: InputDecoration(labelText: 'Currency', hintText: 'INR'))),
          ]),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Meals', 'Transport', 'Hotel', 'Fuel', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (value) => setState(() => category = value ?? category),
          ),
          const SizedBox(height: 14),
          const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Notes', alignLabelWithHint: true)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo saved locally for the UI preview.'))),
            icon: const Icon(CupertinoIcons.check_mark),
            label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Save expense')),
          ),
        ]),
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Profile',
        child: Column(children: [
          const CircleAvatar(radius: 42, child: Icon(CupertinoIcons.person_fill, size: 42)),
          const SizedBox(height: 12),
          Text('Sumanth', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const Text('Demo account • Firebase login in Build 2'),
          const SizedBox(height: 24),
          Card(child: Column(children: [
            ListTile(leading: const Icon(CupertinoIcons.globe), title: const Text('Default currency'), trailing: const Text('INR')),
            const Divider(height: 1),
            SwitchListTile(secondary: const Icon(CupertinoIcons.location), title: const Text('Save bill location'), value: true, onChanged: (_) {}),
            const Divider(height: 1),
            const ListTile(leading: Icon(CupertinoIcons.info), title: Text('App version'), trailing: Text('0.1.0')),
          ])),
        ]),
      );
}
