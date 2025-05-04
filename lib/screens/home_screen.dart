import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../services/theme_service.dart';

import '../providers/debt_provider.dart';
import '../widgets/debt_visualization.dart';
import '../models/debt_profile.dart';
import 'home/index.dart';
import 'home/horizontal_profile_selector.dart';
import 'comparison_screen.dart';
import 'calculator_screen.dart';
import 'education_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDarkMode = false; // Track the theme mode state
  bool _isProfileSelectorVisible = true; // Track profile selector visibility
  
  // Navigation state
  int _currentIndex = 0;
  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );
    
    _controller.forward();
    
    // Load saved dark mode preference
    _isDarkMode = ThemeService.isDarkMode();
    
    // Initialize screens with current dark mode state
    _updateScreens();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Update all screens with current dark mode state
  void _updateScreens() {
    setState(() {
      _screens.clear();
      _screens.addAll([
        _buildMainContent(),
        ComparisonScreen(isDarkMode: _isDarkMode),
        CalculatorScreen(isDarkMode: _isDarkMode),
        EducationScreen(isDarkMode: _isDarkMode),
      ]);
    });
  }
  
  // Build the main dashboard content
  Widget _buildMainContent() {
    return Consumer<DebtProvider>(
      builder: (context, provider, _) {
        // Empty state when no profiles available
        if (provider.profiles.isEmpty) {
          return EmptyStateView(
            isDarkMode: _isDarkMode,
            animation: _animation,
            onCreateProfile: () => showAddDebtProfile(context),
          );
        } else {
          // Main content with horizontal profile selector and debt visualization
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isDarkMode
                    ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                    : [Colors.white, const Color(0xFFF5F5F5)],
              ),
            ),
            child: Column(
              children: [
                // Header with profile toggle button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Button to toggle profile visibility
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isProfileSelectorVisible = !_isProfileSelectorVisible;
                            });
                            // Force rebuild of screens to update in parent widget
                            _updateScreens();
                          },
                          splashColor: Colors.purple.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                            child: Row(
                          children: [
                            Icon(
                              _isProfileSelectorVisible
                                ? CupertinoIcons.chevron_down
                                : CupertinoIcons.chevron_right,
                              color: _isDarkMode ? Colors.white70 : Colors.black54,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'MY PROFILES',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: _isDarkMode ? Colors.white70 : Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Add profile button always visible
                      GestureDetector(
                        onTap: () => showAddDebtProfile(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9C27B0).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                CupertinoIcons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Profile card section with explicit visibility for proper animation
                Visibility(
                  visible: _isProfileSelectorVisible,
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: false,
                  child: Column(
                    children: [
                      // Scrollable profile cards with correct height
                      Container(
                        height: 120,
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          itemCount: provider.profiles.length,
                          itemBuilder: (context, index) {
                            final profile = provider.profiles[index];
                            final isSelected = profile.id == provider.selectedProfile?.id;
                            
                            // Build profile card directly instead of using HorizontalProfileSelector
                            return GestureDetector(
                              onTap: () => provider.selectProfile(profile),
                              child: Container(
                                width: 200,
                                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : LinearGradient(
                                        colors: _isDarkMode
                                            ? [Colors.grey.shade800, Colors.grey.shade900]
                                            : [Colors.grey.shade200, Colors.grey.shade300],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              profile.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.white
                                                    : _isDarkMode
                                                        ? Colors.white
                                                        : Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              // Edit button
                                              GestureDetector(
                                                onTap: () => _showEditProfile(context: context, profile: profile),
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: isSelected 
                                                        ? Colors.white.withOpacity(0.3) 
                                                        : _isDarkMode 
                                                            ? Colors.grey.shade700
                                                            : Colors.grey.shade300,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    CupertinoIcons.pencil,
                                                    size: 14,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : _isDarkMode
                                                            ? Colors.white.withOpacity(0.8)
                                                            : Colors.grey.shade800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              // Delete button
                                              GestureDetector(
                                                onTap: () => showDeleteConfirmation(context: context, provider: provider, profileId: profile.id),
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: isSelected 
                                                        ? Colors.white.withOpacity(0.3) 
                                                        : _isDarkMode 
                                                            ? Colors.grey.shade700
                                                            : Colors.grey.shade300,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    CupertinoIcons.trash,
                                                    size: 14,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : _isDarkMode
                                                            ? Colors.white.withOpacity(0.8)
                                                            : Colors.grey.shade800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      
                                      // Debt amount and interest rate
                                      Row(
                                        children: [
                                          // Debt amount chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(0.2)
                                                  : _isDarkMode
                                                      ? Colors.black.withOpacity(0.2)
                                                      : Colors.grey.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.account_balance_wallet,
                                                  size: 12,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : _isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black54,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  Provider.of<DebtProvider>(context)
                                                      .formatCurrency(profile.totalDebt, profile.currency, compact: true),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : _isDarkMode
                                                            ? Colors.white70
                                                            : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Interest rate chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.white.withOpacity(0.2)
                                                  : _isDarkMode
                                                      ? Colors.black.withOpacity(0.2)
                                                      : Colors.grey.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  CupertinoIcons.percent,
                                                  size: 12,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : _isDarkMode
                                                          ? Colors.white70
                                                          : Colors.black54,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${profile.interestRate}%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : _isDarkMode
                                                            ? Colors.white70
                                                            : Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(
                          color: _isDarkMode ? Colors.white24 : Colors.black12,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main content area - expanded to take remaining space
                Expanded(
                  child: provider.selectedProfile == null
                    ? NoProfileSelectedView(isDarkMode: _isDarkMode)
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: DebtVisualization(
                            profile: provider.selectedProfile!,
                            isDarkMode: _isDarkMode,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Use our local state for dark mode
    final isDarkMode = _isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF121212) 
          : const Color(0xFFF9F9F9),
      
      // App bar with frosted glass effect
      appBar: AppBar(
        backgroundColor: isDarkMode 
            ? Colors.black.withOpacity(0.7) 
            : Colors.white.withOpacity(0.7),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'DEBT VISUALIZER',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 1.0,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode 
                  ? CupertinoIcons.sun_max_fill
                  : CupertinoIcons.moon_fill,
              color: isDarkMode 
                  ? Colors.amber 
                  : Colors.blueGrey,
            ),
            onPressed: () {
              // Toggle dark mode and rebuild the UI
              setState(() {
                _isDarkMode = !_isDarkMode;
                // Save the preference
                ThemeService.setDarkMode(_isDarkMode);
                // Update screens with new dark mode state
                _updateScreens();
              });
            },
          ),
        ],
      ),
      
      // Display the current screen based on bottom navigation selection
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Bottom navigation bar with Apple-inspired design
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                selectedItemColor: const Color(0xFF9C27B0),
                unselectedItemColor: isDarkMode ? Colors.white60 : Colors.black45,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.house_fill),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.chart_bar_alt_fill),
                    label: 'Compare',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calculate), // Using Material icon instead
                    label: 'Calculator',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.book_fill),
                    label: 'Learn',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Show edit profile dialog
  void _showEditProfile({required BuildContext context, required DebtProfile profile}) {
    showEditProfile(context: context, profile: profile);
  }
}
