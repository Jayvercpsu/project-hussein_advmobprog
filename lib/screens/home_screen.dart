import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user.dart';
import '../widgets/custom_text.dart';
import 'cart_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';

class HusseinAdvmobprogHomeScreen extends StatefulWidget {
  final String username;
  const HusseinAdvmobprogHomeScreen({super.key, this.username = ''});

  @override
  State<HusseinAdvmobprogHomeScreen> createState() =>
      HusseinAdvmobprogHomeScreenState();
}

class HusseinAdvmobprogHomeScreenState
    extends State<HusseinAdvmobprogHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final GlobalKey<HusseinAdvmobprogCartScreenState> cartKey =
      GlobalKey<HusseinAdvmobprogCartScreenState>();

  // Enhancement 3: filled in once ProfileScreen loads the saved user, so
  // the app bar can greet them by name while on the Profile tab.
  HusseinAdvmobprogUser? _currentUser;

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }

  @override
  Widget build(BuildContext context) {
    // Enhancement 2: Check if current tab is CartScreen
    final bool isCartScreen = _selectedIndex == 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: (_selectedIndex == 0)
              ? Image.asset(
                  'assets/images/RH_logo.png',
                  scale: 11.sp,
                )
              : CustomText(
                  text: (_selectedIndex == 1)
                      ? 'Cart'
                      : (_selectedIndex == 2)
                          ? (((_currentUser?.firstName ?? '').isNotEmpty)
                              ? _currentUser!.firstName
                              : 'Profile')
                          : 'Home',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
          children: <Widget>[
            const HusseinAdvmobprogProductScreen(),
            // Enhancement 1: Render new CartScreen without redundant appbar
            HusseinAdvmobprogCartScreen(key: cartKey),
            // Enhancement 3: Render the profile UI backed by user.dart
            HusseinAdvmobprogProfileScreen(
              onUserLoaded: (user) {
                setState(() {
                  _currentUser = user;
                });
              },
            ),
          ],
        ),
        // Enhancement 2: Chat bottom navigation transformed as FloatingActionButton
        // Enhancement 2: Hidden when on CartScreen
        floatingActionButton: isCartScreen
            ? null
            : FloatingActionButton(
                backgroundColor: Colors.indigo,
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                child: const Icon(Icons.chat, color: Colors.white),
              ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: _onTappedBar,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shop_2),
              label: 'Shop',
            ),
            // Enhancement 1: Replaced Chat tab with Cart tab
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}