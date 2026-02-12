import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configurez votre compagnie, les moyens de paiement et les notifications.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9CA3AF),
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: const [
              _SettingsCard(
                icon: Icons.domain_outlined,
                title: 'Informations de la compagnie',
                description: 'Nom, logo, contacts et adresses de vos agences.',
              ),
              _SettingsCard(
                icon: Icons.payments_outlined,
                title: 'Moyens de paiement',
                description: 'Mobile money, carte bancaire, espèces…',
              ),
              _SettingsCard(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                description:
                    'SMS, e‑mail et push pour les réservations et annulations.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Préférences générales',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: true,
                    onChanged: (_) {},
                    title: const Text('Activer le thème sombre'),
                    subtitle: const Text(
                        'Permet aux utilisateurs de passer en mode sombre.'),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: true,
                    onChanged: (_) {},
                    title: const Text('Exiger confirmation des annulations'),
                    subtitle: const Text(
                        'Demander une double validation avant d\'annuler un ticket.'),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: false,
                    onChanged: (_) {},
                    title: const Text('Partage automatique des rapports'),
                    subtitle: const Text(
                        'Envoyer un rapport PDF hebdomadaire par e‑mail.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {},
                child: const Text('Configurer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

