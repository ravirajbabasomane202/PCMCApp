import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/providers/grievance_provider.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/providers/ad_provider.dart';
import 'package:main_ui/widgets/ad_card.dart';
import 'package:main_ui/widgets/CombinedGrievanceCard.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';

final userIdProvider = Provider<int?>((ref) {
  return 1; 
});

class TrackGrievance extends ConsumerStatefulWidget {
  const TrackGrievance({super.key});

  @override
  ConsumerState<TrackGrievance> createState() => _TrackGrievanceState();
}

class _TrackGrievanceState extends ConsumerState<TrackGrievance> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  final PageController _adsPageController = PageController(viewportFraction: 0.9);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(userIdProvider);
      if (userId != null) {
        ref.invalidate(citizenHistoryProvider(userId));
      }
      _startAutoScroll();
      _startAdsAutoScroll(); // ✅ Start ads scroll
    });
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _pageController.hasClients) {
        final nextPage = (_currentPage + 1) % 3; // Use modulo for infinite loop
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  void _startAdsAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted || !_adsPageController.hasClients) return;
      final adsState = ref.read(adProvider);
      adsState.whenData((ads) {
        if (ads.isNotEmpty && _adsPageController.hasClients) {
          final nextPage = (_adsPageController.page!.round() + 1) % ads.length;
          _adsPageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
      _startAdsAutoScroll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) { 
      final userId = ref.read(userIdProvider);
      if (userId != null) {
        ref.invalidate(citizenHistoryProvider(userId));
      }
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final userId = ref.watch(userIdProvider);

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFf8fbff),
        appBar: AppBar(
          title: Text(localizations.track_grievances),
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          elevation: theme.appBarTheme.elevation,
        ),
        body: EmptyState(
          icon: Icons.error_outline,
          title: localizations.error,
          message: localizations.please_login,
          actionButton: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text(localizations.login),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: Text(localizations.track_grievances),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      drawer: const CustomNavigationDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          final userId = ref.read(userIdProvider);
          if (userId != null) {
            ref.invalidate(citizenHistoryProvider(userId));
            await ref.read(citizenHistoryProvider(userId).future);
          }
        },
        child: ref.watch(citizenHistoryProvider(userId)).when(
          data: (grievances) {
            if (grievances.isEmpty) {
              return EmptyState(
                icon: Icons.inbox_rounded,
                title: localizations.noGrievances,
                message: localizations.noGrievancesMessage,
                actionButton: ElevatedButton( 
                  onPressed: _navigateToSubmit,
                  child: Text(localizations.submitGrievance),
                ),
              );
            }
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ads Section - Fixed
                  Consumer(
                    builder: (context, ref, child) {
                      final adsAsync = ref.watch(adProvider);
                      return adsAsync.when(
                        data: (ads) {
                          if (ads.isEmpty) {
                            return const SizedBox.shrink(); // Return empty space if no ads
                          }                          
                          return Column(
                            children: [
                              SizedBox(
                                height: 250,
                                child: PageView.builder(
                                  controller: _adsPageController, // ✅ use the class-level controller
                                  itemCount: ads.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentPage = index);
                                  },
                                  itemBuilder: (context, index) {
                                    final ad = ads[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: AdCard(ad: ad),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (ads.length > 1) // Only show indicators if multiple ads
                                Center(
                                  child: _buildPageIndicator(ads.length, _currentPage, theme),
                                ),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                        loading: () => const SizedBox(
                          height: 150, 
                          child: LoadingIndicator()
                        ),
                        error: (err, stack) => Container(
                          height: 150,
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Failed to load ads',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                 
                  // Banner Section
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        final List<Map<String, dynamic>> banners = [
                          {
                            'title': localizations.submitGrievance,
                            'subtitle': localizations.submitGrievanceSubtitle,
                            'color': theme.colorScheme.primaryContainer,
                            'icon': Icons.add_task_rounded,
                          },
                          {
                            'title': localizations.track_grievances,
                            'subtitle': localizations.trackGrievancesSubtitle,
                            'color': theme.colorScheme.secondaryContainer,
                            'icon': Icons.track_changes_rounded,
                          },
                          {
                            'title': localizations.quickResolutionsTitle,
                            'subtitle': localizations.quickResolutionsSubtitle,
                            'color': theme.colorScheme.tertiaryContainer,
                            'icon': Icons.verified_user_rounded,
                          },
                        ];
                        return _buildBannerItem(banners[index], theme);
                      },
                    ),
                  ),
                  
                  // Page indicators
                  const SizedBox(height: 8),
                  Center(child: _buildPageIndicator(3, _currentPage, theme)),
                  
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      localizations.grievanceDetails,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Grievances List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: grievances.length,
                    itemBuilder: (context, index) {
                      final grievance = grievances[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: CombinedGrievanceCard(
                          grievance: grievance,
                          onTap: () async {
                            await _navigateToDetail(grievance.id);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: localizations.error,
            message: error.toString(),
            actionButton: ElevatedButton(
              onPressed: () => ref.refresh(citizenHistoryProvider(userId)),
              child: Text(localizations.retry),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSubmit,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes_rounded),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Submit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildPageIndicator(int count, int currentIndex, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(
            horizontal: 4.0,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? theme.colorScheme.primary
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: banner['color'],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              banner['icon'],
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner['subtitle'],
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToSubmit() async {
    final result = await Navigator.pushNamed(context, '/citizen/submit');
    if (result == true && mounted) {
      final userId = ref.read(userIdProvider);
      if (userId != null) {
        ref.invalidate(citizenHistoryProvider(userId));
      }
    }
  }

  Future<void> _navigateToDetail(int grievanceId) async {
    final result = await Navigator.pushNamed(
      context, 
      '/citizen/detail', 
      arguments: grievanceId
    );
    if (result == true && mounted) {
      final userId = ref.read(userIdProvider);
      if (userId != null) {
        ref.invalidate(citizenHistoryProvider(userId));
      }
    }
  }
}