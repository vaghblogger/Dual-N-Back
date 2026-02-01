import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../logic/providers/audio_service_provider.dart';

/// Help / Tutorial hub: entry point for N=1 and N=2 guided flows.
class HelpHubScreen extends ConsumerStatefulWidget {
  const HelpHubScreen({super.key});

  @override
  ConsumerState<HelpHubScreen> createState() => _HelpHubScreenState();
}

class _HelpHubScreenState extends ConsumerState<HelpHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).preloadAudio();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(AppStrings.helpHubTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _HubCard(
                title: AppStrings.n1RulesTitle,
                onTap: () => context.go('/tutorial/flow?start=1'),
              ),
              const SizedBox(height: 20),
              _HubCard(
                title: AppStrings.n2RulesTitle,
                onTap: () => context.go('/tutorial/flow?start=5'),
              ),
              const SizedBox(height: 20),
              _HubCard(
                title: AppStrings.aboutAutoN,
                onTap: () => context.go('/tutorial/flow?start=9'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
