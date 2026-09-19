import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:chess_go/ui/core/theme/app_theme.dart';
import 'package:chess_go/ui/features/game/view_models/game_state_notifier.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _usernameController = TextEditingController();
  bool _isSaving = false;
  String? _statusMessage;
  bool _isSuccess = true;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _updateUsername() async {
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      setState(() {
        _statusMessage = 'Username cannot be empty';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final profileAsync = ref.read(userProfileProvider);
      final currentProfile = profileAsync.value;

      if (currentProfile != null) {
        final updatedProfile = currentProfile.copyWith(
          username: newName,
          displayName: newName,
        );
        await supabase.updateProfile(updatedProfile);
        
        // Refresh the provider cache instantly
        ref.invalidate(userProfileProvider);
        
        if (mounted) {
          setState(() {
            _statusMessage = 'Username updated successfully!';
            _isSuccess = true;
            _isSaving = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error updating profile: $e';
          _isSuccess = false;
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final supabase = ref.read(supabaseServiceProvider);
    await supabase.signOut();
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final supabase = ref.watch(supabaseServiceProvider);
    final email = supabase.currentUser?.email ?? 'N/A';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => context.go('/home'),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load profile: $err',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text(
                'No authenticated session found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          // Initialize controller with current name if empty
          if (_usernameController.text.isEmpty && !_isSaving && _statusMessage == null) {
            _usernameController.text = profile.displayName;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Header
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                    child: Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Elo Rating Display Box
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF262E3E)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CURRENT ELO RATING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${profile.eloRating}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Row Grid
                Row(
                  children: [
                    _buildStatItem('Wins', '${profile.wins}', AppColors.success),
                    const SizedBox(width: 12),
                    _buildStatItem('Losses', '${profile.losses}', AppColors.danger),
                    const SizedBox(width: 12),
                    _buildStatItem('Draws', '${profile.draws}', AppColors.textMuted),
                  ],
                ),
                const SizedBox(height: 32),

                // Details & Edit Section
                const Text(
                  'PREFERENCES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Theme Switcher Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF262E3E)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.palette_outlined, color: AppColors.gold, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Theme Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      DropdownButton<ThemeMode>(
                        value: ref.watch(themeModeProvider),
                        dropdownColor: Theme.of(context).colorScheme.surfaceContainer,
                        underline: const SizedBox(),
                        onChanged: (mode) {
                          if (mode != null) {
                            ref.read(themeModeProvider.notifier).state = mode;
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'ACCOUNT DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // Email Row (Read Only)
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: email),
                  decoration: const InputDecoration(
                    labelText: 'Registered Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 16),

                // Edit Username Field
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username / Display Name',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.gold),
                  ),
                ),
                const SizedBox(height: 12),

                if (_statusMessage != null) ...[
                  Text(
                    _statusMessage!,
                    style: TextStyle(
                      color: _isSuccess ? AppColors.success : AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],

                ElevatedButton(
                  onPressed: _isSaving ? null : _updateUsername,
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
                const SizedBox(height: 24),

                // Logout Button
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                  label: const Text(
                    'Sign Out Account',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger, width: 1.2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF212936)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
