import 'package:flutter/material.dart';
import '../main.dart';
import '../models/wallet.dart';
import '../services/preference_service.dart';
import '../services/transaction_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback? onStart;
  final TransactionService? service;

  const WelcomePage({super.key, this.onStart, this.service});

  void _showInitialWalletSetupSheet(
    BuildContext parentContext,
    TransactionService targetService,
  ) {
    String selectedPreset = Wallet.presetWallets.first;
    bool isCustom = false;
    final customNameController = TextEditingController();
    final balanceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Atur Dompet & Saldo Awal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih sumber dana utama Anda dan masukkan uang bawaan (saldo awal) yang ingin Anda catat pertama kali.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Dompet Utama:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                          'setup_preset_${isCustom ? 'Lainnya' : selectedPreset}'),
                      initialValue: isCustom ? 'Lainnya' : selectedPreset,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: [
                        ...Wallet.presetWallets.map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            )),
                        const DropdownMenuItem(
                          value: 'Lainnya',
                          child: Text('Lainnya (Tulis Sendiri)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() {
                            if (value == 'Lainnya') {
                              isCustom = true;
                            } else {
                              isCustom = false;
                              selectedPreset = value;
                            }
                          });
                        }
                      },
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: customNameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Nama Dompet Kustom',
                          hintText: 'Contoh: Kantong Jago, Tabungan',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama dompet wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('input_initial_balance'),
                      controller: balanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nominal Saldo Awal / Uang Bawaan (Rp)',
                        hintText: 'Contoh: 1.000.000',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      key: const Key('button_submit_initial_wallet'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (isCustom &&
                            !(formKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        final walletName = isCustom
                            ? customNameController.text.trim()
                            : selectedPreset;
                        final rawBalance = balanceController.text
                            .replaceAll(RegExp(r'[^0-9]'), '');
                        final balance = double.tryParse(rawBalance) ?? 0.0;

                        targetService.setupInitialWallet(
                          walletName: walletName,
                          initialBalance: balance,
                        );

                        await PreferenceService.setHasSeenWelcome(true);
                        if (onStart != null) {
                          onStart!();
                        } else if (parentContext.mounted) {
                          Navigator.of(parentContext).pushAndRemoveUntil(
                            MaterialPageRoute(
                              maintainState: true,
                              builder: (_) =>
                                  FinanceHomePage(service: targetService),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text(
                        'Mulai Gunakan SakuPoy',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveService = service ?? TransactionService();

    return Scaffold(
      backgroundColor: const Color(0xFF0C0D0E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          return Stack(
            children: [
              // 1. Ambient Background Glows
              Positioned(
                top: -80,
                right: -60,
                child: IgnorePointer(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -70,
                child: IgnorePointer(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Scrollable Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 40 : 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- TOP APP BAR / BRAND HEADER ---
                      _buildTopHeader(),
                      const SizedBox(height: 32),

                      // --- HERO SECTION: TEXT + PHONE MOCKUP ---
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildHeroTextBlock(),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 5,
                              child: Center(child: _buildPhoneMockupWithAccents()),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroTextBlock(),
                            const SizedBox(height: 28),
                            Center(child: _buildPhoneMockupWithAccents()),
                          ],
                        ),

                      const SizedBox(height: 32),

                      // --- FEATURES CONTAINER ---
                      _buildFeaturesContainer(isWide),

                      const SizedBox(height: 36),

                      // --- BOTTOM CALL TO ACTION (CTA) ---
                      _buildBottomCta(context, effectiveService),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Header: Logo on left, "Catat. Atur. Aman." on right
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/sakupoy_icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Saku',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Poy',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Text(
          'Catat. Atur. Aman.',
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Hero Text: Pill badge, SakuPoy title, Kelola keuanganmu, description
  Widget _buildHeroTextBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill: ● Selamat Datang di
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1C1F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2B2C30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Selamat Datang di',
                style: TextStyle(
                  color: Color(0xFFD1D1D6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Big Headline: SakuPoy
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Saku',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: 'Poy',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Catchy subheading: Kelola keuanganmu dengan lebih mudah.
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
              letterSpacing: -0.4,
            ),
            children: [
              TextSpan(text: 'Kelola keuanganmu\ndengan '),
              TextSpan(
                text: 'lebih mudah.',
                style: TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Paragraph
        const Text(
          'Catat setiap transaksi, pantau saldo, dan atur pengeluaranmu dalam satu aplikasi.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF9E9EA4),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Realistic phone mockup with green neon glow & floating icons
  Widget _buildPhoneMockupWithAccents() {
    return SizedBox(
      width: 290,
      height: 380,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Ambient green glow behind mockup
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Neon dynamic loop curve
          Positioned.fill(
            child: CustomPaint(
              painter: _NeonOrbitalPainter(),
            ),
          ),

          // 3. Floating top-left badge (Wallet +)
          Positioned(
            top: 24,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF18191C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),

          // 4. Floating bottom-right badge (Chart)
          Positioned(
            bottom: 40,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF18191C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),

          // 5. Phone Body (slanted slightly for modern 3D depth)
          Transform.rotate(
            angle: 0.05,
            child: Container(
              width: 205,
              height: 350,
              decoration: BoxDecoration(
                color: const Color(0xFF121316),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF383A40),
                  width: 3.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 28,
                    offset: const Offset(6, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Dynamic island / top notch
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 6),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Phone mini screen content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 250,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // App bar in mockup
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.account_balance_wallet,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      RichText(
                                        text: const TextSpan(
                                          children: [
                                            TextSpan(
                                              text: 'Saku',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            TextSpan(
                                              text: 'Poy',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF222428),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 2.5,
                                          backgroundColor: AppColors.primary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Aktif',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Total Saldo Card in Mockup
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B1C20),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2C2D32),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'TOTAL SALDO',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white54,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        CircleAvatar(
                                          radius: 3,
                                          backgroundColor: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Rp 0',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _buildMiniStat(
                                          '↓ Total Masuk',
                                          'Rp 0',
                                          AppColors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildMiniStat(
                                          '↑ Total Keluar',
                                          'Rp 0',
                                          AppColors.expense,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Dompet Saya Row
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Dompet Saya (3)',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildMiniButton('Pindah'),
                                  const SizedBox(width: 4),
                                  _buildMiniButton('+'),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // 2 Mini Wallets
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMiniWalletCard(
                                      'Tunai / Cash',
                                      'Rp 0',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _buildMiniWalletCard(
                                      'BRImo',
                                      'Rp 0',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Riwayat Mutasi mini
                              const Text(
                                'Riwayat Mutasi',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1B1F),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2A2B30),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Semua Transaksi',
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 13,
                                      color: Colors.white54,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Mini Bottom Bar inside Mockup
                  Container(
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF191A1E),
                      border: Border(
                        top: BorderSide(color: Color(0xFF26282E), width: 0.5),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.home, size: 12, color: AppColors.primary),
                        Icon(Icons.person, size: 12, color: Colors.white38),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF23242A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 7, color: color),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFF24262C),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 7.5,
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMiniWalletCard(String name, String balance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2C2D32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            balance,
            style: const TextStyle(
              fontSize: 9.5,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Large Features Card: Catat Transaksi, Pantau Saldo, Atur Keuangan
  Widget _buildFeaturesContainer(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141518),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF24252A), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          final showRow = boxConstraints.maxWidth > 520;

          if (showRow) {
            return const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Catat Transaksi',
                    description:
                        'Masukkan pemasukan dan pengeluaran dengan cepat dan praktis.',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Pantau Saldo',
                    description:
                        'Lihat total saldo dan riwayat mutasi secara real-time.',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _FeatureItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Atur Keuangan',
                    description:
                        'Buat kategori, kelola anggaran, dan capai tujuan finansialmu.',
                  ),
                ),
              ],
            );
          } else {
            return const Column(
              children: [
                _FeatureItem(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Catat Transaksi',
                  description:
                      'Masukkan pemasukan dan pengeluaran dengan cepat dan praktis.',
                  horizontalMode: true,
                ),
                Divider(height: 24, color: Color(0xFF222328)),
                _FeatureItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Pantau Saldo',
                  description:
                      'Lihat total saldo dan riwayat mutasi secara real-time.',
                  horizontalMode: true,
                ),
                Divider(height: 24, color: Color(0xFF222328)),
                _FeatureItem(
                  icon: Icons.verified_user_outlined,
                  title: 'Atur Keuangan',
                  description:
                      'Buat kategori, kelola anggaran, dan capai tujuan finansialmu.',
                  horizontalMode: true,
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // Bottom CTA: Neon divider bar, Subtitle, and Big Pill Button
  Widget _buildBottomCta(
    BuildContext context,
    TransactionService effectiveService,
  ) {
    return Column(
      children: [
        // Center neon green divider
        Center(
          child: Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Text: Mulai perjalanan finansial yang lebih baik bersama SakuPoy.
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFD1D1D6),
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(text: 'Mulai perjalanan finansial yang lebih baik\nbersama '),
              TextSpan(
                text: 'SakuPoy.',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Big Pill Button: → Mulai Sekarang
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            key: const Key('button_start_app'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              _showInitialWalletSetupSheet(context, effectiveService);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.black,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Mulai Sekarang',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Single Feature item with dark rounded icon badge
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool horizontalMode;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.horizontalMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2024),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C2E35)),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );

    if (horizontalMode) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        iconWidget,
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// Custom Painter for neon green orbital arc around the phone mockup
class _NeonOrbitalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    final path = Path();
    // Curved dynamic loop around phone
    path.moveTo(size.width * 0.1, size.height * 0.55);
    path.cubicTo(
      size.width * 0.0,
      size.height * 0.85,
      size.width * 0.7,
      size.height * 0.95,
      size.width * 0.95,
      size.height * 0.7,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
