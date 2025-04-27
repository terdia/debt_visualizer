import 'dart:io';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final AuthService authService;
  final PaymentService paymentService;

  const SubscriptionScreen({
    required this.authService,
    required this.paymentService,
    super.key,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _handleSubscription() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.paymentService.startSubscription();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.medium(
            title: Text('Cloud Sync'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unlock Cloud Features',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFeatureRow(
                          icon: Icons.sync,
                          title: 'Automatic Cloud Sync',
                          description: 'Keep your data in sync across devices',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(
                          icon: Icons.backup,
                          title: 'Secure Backup',
                          description: 'Never lose your debt tracking progress',
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(
                          icon: Icons.devices,
                          title: 'Multi-device Access',
                          description: 'Use on all your devices seamlessly',
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text(
                                Platform.isIOS ? '$1.99' : '$2.00',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '/month',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const Spacer(),
                              if (_loading)
                                const CircularProgressIndicator()
                              else
                                FilledButton.icon(
                                  onPressed: _handleSubscription,
                                  icon: const Icon(Icons.lock_open),
                                  label: const Text('Subscribe Now'),
                                ),
                            ],
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'Cancel anytime through ${Platform.isIOS ? "App Store" : "Play Store"}. No commitment required.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
