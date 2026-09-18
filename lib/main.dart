import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/bills_tab.dart';
import 'screens/history_tab.dart';
import 'screens/home_tab.dart';
import 'screens/profile_tab.dart';
import 'screens/welcome_page.dart';
import 'services/bill_service.dart';
import 'services/preference_service.dart';
import 'services/transaction_service.dart';
import 'theme/app_theme.dart';
import 'widgets/bill_dialogs.dart';
import 'widgets/transaction_dialogs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final service = await TransactionService.load();
  final billService = await BillService.load();
  final hasSeenWelcome = await PreferenceService.hasSeenWelcome();
  runApp(
    SakuPoyApp(
      hasSeenWelcome: hasSeenWelcome,
      service: service,
      billService: billService,
    ),
  );
}

class SakuPoyApp extends StatelessWidget {
  final bool hasSeenWelcome;
  final TransactionService? service;
  final BillService? billService;
  const SakuPoyApp({
    super.key,
    this.hasSeenWelcome = true,
    this.service,
    this.billService,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveService = service ?? TransactionService();
    final effectiveBillService = billService ?? BillService();
    return MaterialApp(
      title: 'SakuPoy - Pencatatan Keuangan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: hasSeenWelcome
          ? FinanceHomePage(
              service: effectiveService,
              billService: effectiveBillService,
            )
          : WelcomePage(service: effectiveService),
    );
  }
}

class FinanceHomePage extends StatefulWidget {
  final TransactionService? service;
  final BillService? billService;
  const FinanceHomePage({super.key, this.service, this.billService});

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
  late final TransactionService _service =
      widget.service ?? TransactionService();
  late final BillService _billService = widget.billService ?? BillService();

  // 0=Beranda, 1=Tagihan, 2=Riwayat, 3=Profil
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabTitles = ['SakuPoy', 'Tagihan', 'Riwayat', 'Profil'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tabTitles[_currentTabIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          if (_currentTabIndex == 1)
            IconButton(
              key: const Key('button_add_bill'),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Tambah Tagihan',
              onPressed: () => showAddBillSheet(context, _billService),
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          HomeTab(
            service: _service,
            billService: _billService,
            onAddWallet: () => showAddWalletDialog(context, _service),
            onDeleteWallet: (wallet) =>
                confirmDeleteWallet(context, _service, wallet),
            onTransfer: () => showTransferSheet(context, _service),
            onPayBill: (bill) =>
                showPayBillDialog(context, bill, _billService, _service),
            onNavigateToBills: () => setState(() => _currentTabIndex = 1),
          ),
          BillsTab(
            billService: _billService,
            onPayBill: (bill) =>
                showPayBillDialog(context, bill, _billService, _service),
            onAddBill: () => showAddBillSheet(context, _billService),
          ),
          HistoryTab(
            service: _service,
            onDeleteTransaction: (item) =>
                confirmDeleteTransaction(context, _service, item),
            onClearAllTransactions: () =>
                confirmClearAllTransactions(context, _service),
            onAddTransaction: () => showQuickActionSheet(context, _service),
          ),
          ProfileTab(
            service: _service,
            onClearAllTransactions: () =>
                confirmClearAllTransactions(context, _service),
            onRestartApp: () => confirmRestartApp(context, _service),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        key: const Key('button_center_action'),
        tooltip: 'Catat Transaksi',
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        shape: const CircleBorder(),
        elevation: 3,
        onPressed: () => showQuickActionSheet(context, _service),
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _billService,
        builder: (context, _) {
          final overdueCount = _billService.overdueBillsCount;
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        key: const Key('tab_home'),
                        index: 0,
                        icon: Icons.home_rounded,
                        label: 'Beranda',
                      ),
                      _buildNavItemWithBadge(
                        key: const Key('tab_bills'),
                        index: 1,
                        icon: Icons.receipt_long_rounded,
                        label: 'Tagihan',
                        badgeCount: overdueCount,
                      ),
                      const SizedBox(width: 56),
                      _buildNavItem(
                        key: const Key('tab_history'),
                        index: 2,
                        icon: Icons.history_rounded,
                        label: 'Riwayat',
                      ),
                      _buildNavItem(
                        key: const Key('tab_profile'),
                        index: 3,
                        icon: Icons.person_rounded,
                        label: 'Profil',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required Key key,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isActive = _currentTabIndex == index;
    return InkWell(
      key: key,
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemWithBadge({
    required Key key,
    required int index,
    required IconData icon,
    required String label,
    required int badgeCount,
  }) {
    final isActive = _currentTabIndex == index;
    return InkWell(
      key: key,
      onTap: () => setState(() => _currentTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.expense,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
