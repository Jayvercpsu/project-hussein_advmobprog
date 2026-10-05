import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class HusseinAdvmobprogProfileScreen extends StatefulWidget {
  final ValueChanged<HusseinAdvmobprogUser?>? onUserLoaded;

  const HusseinAdvmobprogProfileScreen({
    super.key,
    this.onUserLoaded,
  });

  @override
  State<HusseinAdvmobprogProfileScreen> createState() =>
      HusseinAdvmobprogProfileScreenState();
}

class HusseinAdvmobprogProfileScreenState
    extends State<HusseinAdvmobprogProfileScreen> {
  final HusseinAdvmobprogUserService _userService =
      HusseinAdvmobprogUserService();

  HusseinAdvmobprogUser? _user;
  bool _isLoadingUser = true;
  bool _isBusy = false;

  // Profile photo picked in this session (same behaviour as the reference
  // app: the URL is applied to the avatar as soon as it is saved).
  String? _customImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Load the current user's profile
  Future<void> _loadProfile() async {
    setState(() => _isLoadingUser = true);

    try {
      // Get saved user information now
      final user = await _userService.getUserData();

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoadingUser = false;
      });

      // Send user data back upward
      widget.onUserLoaded?.call(user);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingUser = false);
      _showError(e.toString());
    }
  }

  // Ask for a new profile image
  Future<void> _editImageUrl() async {
    final TextEditingController urlController = TextEditingController(
      text: _customImageUrl ?? _user?.image ?? '',
    );

    final newUrl = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Profile Image'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(
              hintText: 'Enter Image URL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                urlController.text,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    urlController.dispose();

    if (newUrl != null && mounted) {
      setState(() {
        _customImageUrl = newUrl.trim();
      });
    }
  }

  // Ask user for current password
  Future<String?> _askForPassword({
    required String title,
  }) async {
    final controller = TextEditingController();

    // Show password confirmation dialog
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current Password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text,
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return password;
  }

  // Let users change their username
  Future<void> _updateUsername() async {
    if (_user == null) return;

    final usernameController = TextEditingController(
      text: _user!.username,
    );

    // Ask for the new username
    final newUsername = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Username'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'New Username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  usernameController.text.trim(),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    usernameController.dispose();

    if (newUsername == null ||
        newUsername.isEmpty ||
        newUsername == _user!.username) {
      return;
    }

    // Confirm username change securely
    final currentPassword = await _askForPassword(
      title: 'Confirm Username Change',
    );

    if (currentPassword == null || currentPassword.isEmpty) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      // Update username through service
      final updatedUser = await _userService.updateUsername(
        newUsername,
        currentPassword: currentPassword,
      );

      if (!mounted) return;

      setState(() {
        _user = updatedUser;
      });

      // Send updated user data upward
      widget.onUserLoaded?.call(updatedUser);
      _showMessage('Username updated successfully.');
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  // Let users change their password
  Future<void> _changePassword() async {
    // Confirm the current password first
    final currentPassword = await _askForPassword(
      title: 'Change Password',
    );

    if (currentPassword == null || currentPassword.isEmpty) {
      return;
    }

    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Ask for both new passwords
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                ),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  [
                    newPasswordController.text,
                    confirmPasswordController.text,
                  ],
                );
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );

    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (values == null) return;

    // Make sure password is long enough
    if (values[0].length < 6) {
      _showError('New password must be at least 6 characters.');
      return;
    }

    // Make sure both passwords match
    if (values[0] != values[1]) {
      _showError('New passwords do not match.');
      return;
    }

    setState(() => _isBusy = true);

    try {
      // Update password through service
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: currentPassword,
        newPassword: values[0],
      );

      if (mounted) {
        _showMessage('Password updated successfully.');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  // Delete the current user account
  Future<void> _deleteAccount() async {
    // Ask before deleting the account
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Delete this account?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Confirm deletion using password
    final currentPassword = await _askForPassword(
      title: 'Confirm Account Deletion',
    );

    if (currentPassword == null || currentPassword.isEmpty) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      // Delete account through service
      await _userService.deleteAccount(
        currentPassword: currentPassword,
      );

      if (!mounted) return;

      // Return user to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/sign',
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  // Handle logout after confirmation
  Future<void> _handleLogout() async {
    // Ask before logging the user
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Clear the current login session
    await _userService.logout();

    if (!mounted) return;

    // Return user to login screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/sign',
      (route) => false,
    );
  }

  // Show a simple success message
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // Show a simple error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.replaceFirst('Exception: ', ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while profile loads
    if (_isLoadingUser) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show message when session missing
    if (_user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No user session found.'),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/sign',
                  (route) => false,
                );
              },
              child: const Text('Go to Sign In'),
            ),
          ],
        ),
      );
    }

    final user = _user!;
    final activeImageUrl = _customImageUrl ?? user.image;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: 12.h,
        ),
        children: [
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: 24.h,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Show profile photo or icon, with a small edit badge
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 42.r,
                      backgroundColor: Colors.teal.shade50,
                      backgroundImage: activeImageUrl.isNotEmpty
                          ? NetworkImage(activeImageUrl)
                          : null,
                      child: activeImageUrl.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 42.sp,
                              color: Colors.teal,
                            )
                          : null,
                    ),
                    GestureDetector(
                      onTap: _editImageUrl,
                      child: CircleAvatar(
                        radius: 14.r,
                        backgroundColor: Colors.amber.shade700,
                        child: Icon(
                          Icons.edit,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                CustomText(
                  text: user.fullName.isNotEmpty
                      ? user.fullName
                      : user.username,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 2.h),
                CustomText(
                  text: '@${user.username}',
                  fontSize: 12.sp,
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.person_outline,
                  label: 'First Name',
                  value: user.firstName,
                ),
                const Divider(height: 1),
                _infoRow(
                  icon: Icons.person_outline,
                  label: 'Last Name',
                  value: user.lastName,
                ),
                const Divider(height: 1),
                _infoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: user.email,
                ),
                const Divider(height: 1),
                _infoRow(
                  icon: Icons.cake_outlined,
                  label: 'Age',
                  value: user.age > 0 ? '${user.age}' : '-',
                ),
                const Divider(height: 1),
                _infoRow(
                  icon: Icons.phone_outlined,
                  label: 'Contact No',
                  value: user.contactNo.isNotEmpty
                      ? user.contactNo
                      : '-',
                ),
                const Divider(height: 1),
                _infoRow(
                  icon: Icons.badge_outlined,
                  label: 'Login Type',
                  value: user.loginType,
                ),
                const Divider(height: 1),
                _infoRow(
                  icon: Icons.wc_outlined,
                  label: 'Gender',
                  value: user.gender.isNotEmpty
                      ? user.gender[0].toUpperCase() +
                          user.gender.substring(1)
                      : '-',
                ),
                const Divider(height: 1),
                _infoRow(
                  icon: Icons.fingerprint,
                  label: 'User ID',
                  value: user.uid.isNotEmpty ? user.uid : '#${user.id}',
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                  ),
                  title: const Text(
                    'Update Username',
                  ),
                  onTap: _isBusy
                      ? null
                      : _updateUsername,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.lock_reset_outlined,
                  ),
                  title: const Text(
                    'Change Password',
                  ),
                  onTap: _isBusy
                      ? null
                      : _changePassword,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                  ),
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  title: const Text(
                    'Delete Account',
                  ),
                  onTap: _isBusy
                      ? null
                      : _deleteAccount,
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          SizedBox(
            height: 46.h,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5C4D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: _isBusy
                  ? null
                  : _handleLogout,
              icon: const Icon(
                Icons.logout,
                size: 18,
              ),
              label: Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // Build each profile information row
  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 12.h,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: Colors.amber.shade700,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}