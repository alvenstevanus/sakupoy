import 'package:flutter/material.dart';
import '../services/preference_service.dart';
import '../main.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback? onStart;

  const WelcomePage({super.key, this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Selamat Datang di SakuPoy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aplikasi pencatatan keuangan yang fokus pada kepraktisan dan kecepatan mencatat arus keuangan Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _FeatureRow(
                              icon: Icons.add_circle_outline,
                              color: Colors.green,
                              title: 'Catat Cepat',
                              description: 'Tambah uang masuk dan kurang uang keluar dalam hitungan detik.',
                            ),
                            Divider(height: 20),
                            _FeatureRow(
                              icon: Icons.account_balance_wallet,
                              color: Colors.blue,
                              title: 'Total Saldo Otomatis',
                              description: 'Kalkulasi sisa uang dan mutasi secara otomatis dan akurat.',
                            ),
                            Divider(height: 20),
                            _FeatureRow(
                              icon: Icons.calendar_month,
                              color: Colors.deepPurple,
                              title: 'Filter Fleksibel',
                              description: 'Pantau mutasi mulai dari bulan transaksi pertama Anda.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                key: const Key('button_start_app'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'Mulai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await PreferenceService.setHasSeenWelcome(true);
                  if (onStart != null) {
                    onStart!();
                  } else if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const FinanceHomePage()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
