# Catering Management Application

## Overview

This application is a comprehensive catering management platform designed for customers, staff, and administrators. It allows customers to browse pre-designed meal plates or create custom orders from a menu. Administrators can manage incoming orders, and staff have their own dedicated section.

## Features

*   **Role-Based Access:** The application provides distinct experiences for three user roles:
    *   **Customers:** Can browse menus, customize orders, and place them for delivery.
    *   **Staff:** Have a dedicated portal for their tasks (to be defined).
    *   **Admin:** Can view and confirm incoming customer orders.
*   **Dual Login System:**
    *   **Customers:** Use a fast and secure OTP-based login with their phone number.
    *   **Staff/Admin:** Use a traditional email and password login.
*   **Flexible Ordering:**
    *   **Admin Plates:** Customers can choose from pre-defined meal plates for quick ordering.
    *   **Custom Orders:** Customers can build their own orders by selecting individual items from a menu.
*   **Order Management:**
    *   Customers place orders and provide a delivery address.
    *   Administrators receive new orders and can confirm them.

## Project Structure

*   `lib/main.dart`: Main application entry point.
*   `lib/router.dart`: Defines all application routes using `go_router`.
*   `lib/screens/login_screen.dart`: Handles both customer and staff/admin authentication.
*   `lib/screens/details_screen.dart`: Collects initial details for new customers.
*   `lib/screens/home_screen.dart`: A temporary screen, to be replaced by role-specific screens.
*   `lib/screens/customer_home_screen.dart`: The main dashboard for customers.
*   `lib/screens/admin_home_screen.dart`: The dashboard for administrators to manage orders.
*   `lib/screens/staff_home_screen.dart`: A placeholder dashboard for staff members.
*   `assets/images/logo.png`: Application logo.
*   `pubspec.yaml`: Manages dependencies and assets.

## Current Plan: Role-Based Dashboards & Order Flow

This section outlines the current development phase to implement role-based dashboards and a complete order management workflow.

**Phase 1: Screens and Navigation (In Progress)**

1.  **Update Project Blueprint:** Document the new features and implementation plan. (Completed)
2.  **Create New Screen Files:** Create the Dart files for `customer_home_screen.dart`, `admin_home_screen.dart`, and `staff_home_screen.dart`.
3.  **Update Routing:** Add new routes in `router.dart` for the role-based screens.
4.  **Implement Role-Based Navigation:** Modify the `login_screen.dart` to query the user's role upon login and redirect them to their corresponding dashboard (`/customer`, `/admin`, or `/staff`).

**Phase 2: Customer Order Placement**

1.  **Create Menu and Order Screens:** Develop screens for browsing the menu, customizing plates, and confirming orders.
2.  **Implement Customer Home UI:** Design the `CustomerHomeScreen` with options to view "Admin Plates" or "Create Your Own Order."
3.  **Fetch Menu Data:** Connect to the Supabase backend to retrieve menu items and pre-defined plates.
4.  **Place Order Logic:** Implement the functionality to save a new order, including selected items and the delivery address, to the database.

**Phase 3: Admin Order Management**

1.  **Implement Admin Home UI:** Design the `AdminHomeScreen` to display a list of incoming orders with customer details.
2.  **Fetch Order Data:** Retrieve all pending orders from the Supabase backend.
3.  **Confirm Order Logic:** Add functionality for an admin to accept or confirm an order, updating its status in the database.

**Phase 4: Database Schema**

The following new tables will be created in the Supabase database to support these features:

*   `menu_items`: Stores individual food items.
*   `admin_plates`: Stores pre-defined meal combinations.
*   `plate_items`: A join table linking `admin_plates` to `menu_items`.
*   `orders`: Stores information about each order placed.
*   `order_items`: A join table linking `orders` to `menu_items`.
