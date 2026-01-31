import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/asset_paths.dart';

class N1RulesScreen extends StatelessWidget {
  const N1RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(AppStrings.n1RulesTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      AppStrings.n1RulesDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                        AssetPaths.n1Demo,
                        fit: BoxFit.contain,
                        repeat: true,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.grid_on, size: 120),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/tutorial/n2'),
                child: const Text(AppStrings.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
