import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import 'detail_screen.dart';

class HusseinAdvmobprogCartScreen extends StatefulWidget {
  const HusseinAdvmobprogCartScreen({
    super.key,
  });

  @override
  State<HusseinAdvmobprogCartScreen> createState() =>
      HusseinAdvmobprogCartScreenState();
}

class HusseinAdvmobprogCartScreenState
    extends State<HusseinAdvmobprogCartScreen>
    with AutomaticKeepAliveClientMixin<HusseinAdvmobprogCartScreen> {
  // This handles the cart data and all the cart actions.
  final HusseinAdvmobprogCartService _cartService =
      HusseinAdvmobprogCartService();

  // Keeps the cart screen alive when switching between screens/tabs.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // Required when using AutomaticKeepAliveClientMixin.
    super.build(context);

    // Rebuilds the screen whenever the cart service changes.
    return AnimatedBuilder(
      animation: _cartService,
      builder: (context, child) {
        // Get the products currently stored in the cart.
        final cartItems = _cartService.localCartItems;

        // Show this when there are no products in the cart.
        if (cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 70.sp,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 15.h),
                Text(
                  'Your cart is empty.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        // If the cart has products, show the list and order section.
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                itemBuilder: (context, index) {
                  // Get the current product from the cart.
                  final item = cartItems[index];

                  return Card(
                    color: Colors.grey.shade50, // Very light gray card background
                    elevation: 1,
                    margin: EdgeInsets.only(
                      bottom: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      side: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),

                      // Tapping a cart item opens its product details.
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return HusseinAdvmobprogDetailScreen(
                                product: HusseinAdvmobprogProduct(
                                  id: item.id,
                                  title: item.title,
                                  description: item.description,
                                  category: item.category,
                                  price: item.price,
                                  discountPercentage:
                                      item.discountPercentage,
                                  rating: 5.0,
                                  stock: 10,
                                  tags: const [],
                                  brand: item.brand,
                                  thumbnail: item.thumbnail,
                                  images: [item.thumbnail],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Product image shown on the left.
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.network(
                                item.thumbnail,
                                width: 55.w,
                                height: 55.h,
                                fit: BoxFit.cover,

                                // Show a simple icon if the image fails to load.
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return Container(
                                    width: 55.w,
                                    height: 55.h,
                                    color: Colors.grey.shade200,
                                    child: Icon(
                                      Icons.shopping_bag,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            ),

                            SizedBox(width: 12.w),

                            // Product information goes in the middle.
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  SizedBox(height: 4.h),

                                  // Original price of the product.
                                  Text(
                                    '₱${item.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12.sp,
                                    ),
                                  ),

                                  SizedBox(height: 2.h),

                                  // Shows how much discount the product has (Light Purple Accent).
                                  Text(
                                    '${item.discountPercentage}% off',
                                    style: TextStyle(
                                      color: Colors.purple.shade400,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  SizedBox(height: 2.h),

                                  // Shows the total price for the current quantity.
                                  Text(
                                    'Total: ₱${item.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 8.w),

                            // These buttons control the product quantity.
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Minus button decreases the quantity.
                                InkWell(
                                  onTap: () {
                                    _cartService.decrementQuantity(index);
                                  },
                                  child: Container(
                                    width: 28.w,
                                    height: 28.h,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      size: 16.sp,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),

                                // Displays the current quantity.
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),

                                // Plus button increases the quantity (Light Purple Accent).
                                InkWell(
                                  onTap: () {
                                    _cartService.incrementQuantity(index);
                                  },
                                  child: Container(
                                    width: 28.w,
                                    height: 28.h,
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 16.sp,
                                      color: Colors.purple.shade900,
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
                },
              ),
            ),

            // Bottom section showing the subtotal and order button.
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50, // Very light gray footer background
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Displays the current cart subtotal.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₱${_cartService.subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.purple.shade700, // Light purple subtotal text
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Confirm Order button (Light Purple Accent).
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade200, // Light purple button
                        foregroundColor: Colors.purple.shade900, // Dark purple text for contrast
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () {
                        // Don't do anything if the cart is empty.
                        if (_cartService.localCartItems.isEmpty) {
                          return;
                        }

                        // Get the current cart total before confirming.
                        final total = _cartService.subtotal;

                        // Show a confirmation dialog after ordering.
                        showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              backgroundColor: Colors.grey.shade50,
                              title: Text(
                                'Order Confirmed',
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              content: Text(
                                'Total: ₱${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    // Close the dialog and clear the cart.
                                    Navigator.pop(dialogContext);
                                    _cartService.clearCart();
                                  },
                                  child: Text(
                                    'OK',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}