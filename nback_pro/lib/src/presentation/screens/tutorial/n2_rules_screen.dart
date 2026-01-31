import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/asset_paths.dart';

class N2RulesScreen extends StatelessWidget {
  const N2RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(AppStrings.n2RulesTitle),
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
                      AppStrings.n2RulesDescription,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: Lottie.asset(
                        AssetPaths.n2Demo,
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
                onPressed: () => context.go('/tutorial/progression'),
                child: const Text(AppStrings.next),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
