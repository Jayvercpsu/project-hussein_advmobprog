import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HusseinAdvmobprogSplashScreen extends StatefulWidget {
  const HusseinAdvmobprogSplashScreen({super.key});

  @override
  State<HusseinAdvmobprogSplashScreen> createState() =>
      _HusseinAdvmobprogSplashScreenState();
}

class _HusseinAdvmobprogSplashScreenState
    extends State<HusseinAdvmobprogSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the timer to transition from the splash screen on init.
    _navigateToNextScreen();
  }

  // Handles the splash screen delay and pushes the sign-in route.
  Future<void> _navigateToNextScreen() async {
    // Show splash screen logo and progress indicator for 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));

    // Ensure the widget is still in the tree before attempting navigation.
    if (!mounted) return;

    // Replace current splash screen with the sign-in screen in the navigation stack.
    Navigator.of(context).pushReplacementNamed('/sign');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 143, 179, 231),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/RH_logo.png',
              width: 200.w,
              height: 200.w,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.storefront,
                  size: 90.sp,
                  color: const Color.fromARGB(255, 149, 153, 177),
                );
              },
            ),

            SizedBox(height: 16.h),

            Text(
              'Hussein',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 129, 132, 165),
              ),
            ),

            SizedBox(height: 40.h),

            SizedBox(
              width: 26.w,
              height: 26.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color.fromARGB(255, 84, 87, 105),
              ),
            ),
          ],
        ),
      ),
    );
  }
}