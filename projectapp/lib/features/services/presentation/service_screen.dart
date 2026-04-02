import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/service_card.dart';
import '../data/services_repository.dart';
import '../domain/service_model.dart';
import 'service_detail_screen.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final searchQuery = ref.watch(_searchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'All services',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (v) =>
                    ref.read(_searchQueryProvider.notifier).state = v,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Services list
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.softPurple),
              ),
              error: (e, _) => Center(
                child: Text(
                  '$e',
                  style: TextStyle(color: AppColors.coralError),
                ),
              ),
              data: (services) {
                final filtered = searchQuery.isEmpty
                    ? services
                    : services
                          .where(
                            (s) => s.name.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No services found',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    return ServiceCard(
                          service: filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceDetailScreen(service: filtered[i]),
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: (i * 60).ms)
                        .scale(begin: const Offset(0.95, 0.95));
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
