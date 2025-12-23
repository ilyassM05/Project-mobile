import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../auth/login_screen.dart';
import '../../services/web3_service.dart';
import '../../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _walletController = TextEditingController(); // Displays address
  final _privateKeyController = TextEditingController(); // Input for connecting
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isEditing = false;
  bool _showPasswordChange = false;
  final Web3Service _web3Service = Web3Service();
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _certificates = [];
  bool _loadingCertificates = true;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController.text = authProvider.currentUser?.displayName ?? '';
    _walletController.text = authProvider.currentUser?.walletAddress ?? '';

    // Initialize Web3
    _web3Service.initialize().then((_) {
      if (mounted) setState(() {});
    });

    // Load certificates
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    try {
      final certs = await _firestoreService.getCompletedCoursesWithCertificates(
        authProvider.currentUser!.userId,
      );
      if (mounted) {
        setState(() {
          _certificates = certs;
          _loadingCertificates = false;
        });
      }
    } catch (e) {
      print('Error loading certificates: $e');
      if (mounted) {
        setState(() => _loadingCertificates = false);
      }
    }
  }

  Future<void> _handlePasswordChange() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Re-authenticate first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      // Clear fields and hide form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordChange = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().contains('wrong-password') ? 'Current password is incorrect' : e}',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _walletController.dispose();
    _privateKeyController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Update display name if changed
    if (_nameController.text != authProvider.currentUser?.displayName) {
      await authProvider.updateDisplayName(_nameController.text);
    }

    // Connect Wallet if Private Key is provided
    if (_privateKeyController.text.isNotEmpty && _isEditing) {
      try {
        await _web3Service.connectWallet(_privateKeyController.text);
        final address = _web3Service.currentAddress?.hex;

        if (address != null) {
          await authProvider.updateWalletAddress(address);
          _walletController.text = address;
          _privateKeyController.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Wallet connected successfully!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error connecting wallet: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return; // Stop if wallet fails
      }
    }

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('No user data')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Edit Profile',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = user.displayName;
                  _walletController.text = user.walletAddress ?? '';
                });
              },
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      user.displayName.isNotEmpty
                          ? user.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.role == AppConstants.roleInstructor
                          ? 'Instructor'
                          : 'Student',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Form
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email (Read-only)
                    Text(
                      'Email',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    TextFormField(
                      initialValue: user.email,
                      enabled: false,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Display Name
                    Text(
                      'Display Name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    TextFormField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    // Wallet Address
                    Text(
                      'Wallet Address',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    TextFormField(
                      controller: _walletController,
                      enabled:
                          false, // Always read-only, use private key to connect
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.account_balance_wallet),
                        hintText: user.walletAddress == null
                            ? 'Connect your Web3 wallet'
                            : null,
                      ),
                      validator: (value) {
                        return null; // Read-only
                      },
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: AppTheme.spacingL),
                      Text(
                        'Private Key (for Dev Wallet)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      TextFormField(
                        controller: _privateKeyController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.vpn_key),
                          hintText: 'Enter Private Key to Connect',
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingS),
                    Text(
                      'Connect your Ethereum wallet for blockchain features',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),

                    // Save Button
                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          child: const Text('Save Changes'),
                        ),
                      ),

                    // Account Info
                    if (!_isEditing) ...[
                      Divider(height: AppTheme.spacingXL * 2),
                      Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _InfoTile(
                        icon: Icons.calendar_today,
                        label: 'Member Since',
                        value: _formatDate(user.createdAt),
                      ),
                      _InfoTile(
                        icon: Icons.update,
                        label: 'Last Updated',
                        value: _formatDate(user.updatedAt),
                      ),
                      const SizedBox(height: AppTheme.spacingXL),

                      // My Certificates Section
                      Divider(height: AppTheme.spacingXL * 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            'My Certificates',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      if (_loadingCertificates)
                        const Center(child: CircularProgressIndicator())
                      else if (_certificates.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Text(
                                  'Complete courses to earn certificates!',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._certificates.map(
                          (cert) => Card(
                            margin: const EdgeInsets.only(
                              bottom: AppTheme.spacingM,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AppTheme.accentColor,
                                child: Icon(
                                  Icons.verified,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(cert['courseTitle'] ?? 'Course'),
                              subtitle: Text(
                                'Instructor: ${cert['instructorName']}',
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Certificate for "${cert['courseTitle']}"',
                                    ),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Change Password Section
                      Divider(height: AppTheme.spacingXL * 2),
                      InkWell(
                        onTap: () => setState(
                          () => _showPasswordChange = !_showPasswordChange,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Text(
                              'Change Password',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Icon(
                              _showPasswordChange
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      if (_showPasswordChange) ...[
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Current Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handlePasswordChange,
                            child: const Text('Update Password'),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingXL),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                            side: const BorderSide(color: AppTheme.errorColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
