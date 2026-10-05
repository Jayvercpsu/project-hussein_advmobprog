import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';

class HusseinAdvmobprogSignupScreen extends StatefulWidget {
  const HusseinAdvmobprogSignupScreen({super.key});

  @override
  State<HusseinAdvmobprogSignupScreen> createState() => _HusseinAdvmobprogSignupScreenState();
}

class _HusseinAdvmobprogSignupScreenState extends State<HusseinAdvmobprogSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userService = HusseinAdvmobprogUserService();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _loginType = 'User';

  Color get _primaryColor => Colors.purple.shade700;
  Color get _lightPurple => Colors.purple.shade50;
  Color get _buttonColor => Colors.purple.shade200;
  Color get _textColor => Colors.grey.shade900;
  Color get _labelColor => Colors.grey.shade700;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Create account using entered details
  Future<void> _createAccount() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Send signup details to service
      await _userService.createAccount(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        contactNo: _contactController.text.trim(),
        username: _usernameController.text.trim(),
        emailAddress: _emailController.text.trim(),
        password: _passwordController.text,
        loginType: _loginType,
      );

      if (!mounted) return;

      // Show successful account creation message
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 28.sp,
                ),
                SizedBox(width: 10.w),
                const Text('Account Created'),
              ],
            ),
            content: const Text(
              'Your account has been created successfully. You can now sign in using your username and password.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _buttonColor,
                  foregroundColor: _primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // Return user to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/sign',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      // Show signup error message clearly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check if field has-value
  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  // Check names contain letters
  String? _nameValidator(String? value, String label) {
    final required = _required(value, label);
    if (required != null) return required;

    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value!.trim())) {
      return '$label should contain letters only';
    }

    return null;
  }

  // Check age is within-range
  String? _ageValidator(String? value) {
    final required = _required(value, 'Age');
    if (required != null) return required;

    final age = int.tryParse(value!.trim());

    if (age == null) {
      return 'Enter a valid age';
    }

    if (age < 1 || age > 120) {
      return 'Age must be between 1 and 120';
    }

    return null;
  }

  // Check contact number format
  String? _contactValidator(String? value) {
    final required = _required(value, 'Contact No.');
    if (required != null) return required;

    if (!RegExp(r'^[0-9+\-\s()]{7,20}$').hasMatch(value!.trim())) {
      return 'Enter a valid contact number';
    }

    return null;
  }

  // Check username format before signup
  String? _usernameValidator(String? value) {
    final required = _required(value, 'Username');
    if (required != null) return required;

    if (!RegExp(r'^[A-Za-z0-9_.-]{3,30}$').hasMatch(value!.trim())) {
      return 'Use 3-30 letters, numbers, ., _, or -';
    }

    return null;
  }

  // Check email address format
  String? _emailValidator(String? value) {
    final required = _required(value, 'Email Address');
    if (required != null) return required;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // Check password meets minimum length
  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // Check both passwords match
  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Build consistent input field styling
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: _labelColor,
        fontSize: 13.sp,
      ),
      floatingLabelStyle: TextStyle(
        color: _primaryColor,
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.grey.shade600,
        size: 20.sp,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 15.h,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(
          color: Colors.red.shade400,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11.r),
        borderSide: BorderSide(
          color: Colors.red.shade500,
          width: 1.5,
        ),
      ),
    );
  }

  // Build reusable text input fields
  Widget _textField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          color: _textColor,
          fontSize: 14.sp,
        ),
        cursorColor: _primaryColor,
        validator: validator,
        decoration: _inputDecoration(
          label: label,
          icon: icon,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _textColor,
            size: 20.sp,
          ),
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),
        title: Text(
          'Create Account',
          style: TextStyle(
            color: _textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24.w,
              8.h,
              24.w,
              30.h,
            ),
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 20.h,
                ),
                decoration: BoxDecoration(
                  color: _lightPurple,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.purple.shade100,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58.w,
                      height: 58.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.purple.shade100,
                        ),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1,
                        color: _primaryColor,
                        size: 28.sp,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      'Enter your details below to create your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              Text(
                'Personal Information',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12.h),
              _textField(
                label: 'First Name',
                icon: Icons.person_outline,
                controller: _firstNameController,
                keyboardType: TextInputType.name,
                validator: (value) => _nameValidator(
                  value,
                  'First Name',
                ),
              ),
              _textField(
                label: 'Last Name',
                icon: Icons.person_outline,
                controller: _lastNameController,
                keyboardType: TextInputType.name,
                validator: (value) => _nameValidator(
                  value,
                  'Last Name',
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _textField(
                      label: 'Age',
                      icon: Icons.cake_outlined,
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      validator: _ageValidator,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _textField(
                      label: 'Contact No.',
                      icon: Icons.phone_outlined,
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      validator: _contactValidator,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Account Information',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12.h),
              _textField(
                label: 'Username',
                icon: Icons.account_circle_outlined,
                controller: _usernameController,
                keyboardType: TextInputType.text,
                validator: _usernameValidator,
              ),
              _textField(
                label: 'Email Address',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              _textField(
                label: 'Password',
                icon: Icons.lock_outline,
                controller: _passwordController,
                obscureText: !_showPassword,
                validator: _passwordValidator,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade600,
                    size: 20.sp,
                  ),
                ),
              ),
              _textField(
                label: 'Confirm Password',
                icon: Icons.lock_reset_outlined,
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                validator: _confirmPasswordValidator,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade600,
                    size: 20.sp,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                value: _loginType,
                decoration: _inputDecoration(
                  label: 'Login Type',
                  icon: Icons.badge_outlined,
                ),
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14.sp,
                ),
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'User',
                    child: Text('User'),
                  ),
                  DropdownMenuItem(
                    value: 'Student',
                    child: Text('Student'),
                  ),
                  DropdownMenuItem(
                    value: 'Teacher',
                    child: Text('Teacher'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _loginType = value;
                        });
                      },
              ),
              SizedBox(height: 24.h),
              SizedBox(
                height: 50.h,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    foregroundColor: _primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 21.w,
                          height: 21.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: _primaryColor,
                          ),
                        )
                      : Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12.sp,
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/sign',
                              (route) => false,
                            );
                          },
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}