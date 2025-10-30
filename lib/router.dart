import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/admin_screen.dart';
import 'package:myapp/screens/create_menu_screen.dart';
import 'package:myapp/screens/add_staff_screen.dart';
import 'package:myapp/screens/manage_orders_screen.dart';
import 'package:myapp/screens/create_order_screen.dart';
import 'package:myapp/screens/customer_home_screen.dart';
import 'package:myapp/screens/details_screen.dart';
import 'package:myapp/screens/home_screen.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/review_order_screen.dart';
import 'package:myapp/screens/staff_home_screen.dart';
import 'package:myapp/screens/admin_shell.dart';
import 'package:myapp/screens/order_details_screen.dart';
import 'package:myapp/screens/design_plate_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      path: '/details/:phone',
      builder: (BuildContext context, GoRouterState state) {
        final phone = state.pathParameters['phone']!;
        return DetailsScreen(phone: phone);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
    GoRoute(
      path: '/customer',
      builder: (BuildContext context, GoRouterState state) {
        return const CustomerHomeScreen();
      },
    ),
    GoRoute(
      path: '/staff',
      builder: (BuildContext context, GoRouterState state) {
        return const StaffHomeScreen();
      },
    ),
    GoRoute(
      path: '/create-order',
      builder: (BuildContext context, GoRouterState state) {
        return const CreateOrderScreen();
      },
    ),
    GoRoute(
      path: '/review-order',
      builder: (BuildContext context, GoRouterState state) {
        final orderDetails = state.extra as Map<String, dynamic>;
        return ReviewOrderScreen(orderDetails: orderDetails);
      },
    ),
    GoRoute(
      path: '/admin/order/:orderId',
      builder: (BuildContext context, GoRouterState state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderDetailsScreen(orderId: orderId);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AdminShell(child: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/admin',
              builder: (context, state) => const AdminScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/admin/create-menu',
              builder: (context, state) => const CreateMenuScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/admin/add-staff',
              builder: (context, state) => const AddStaffScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/admin/manage-orders',
              builder: (context, state) => const ManageOrdersScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/admin/design-plate',
              builder: (context, state) => const DesignPlateScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
