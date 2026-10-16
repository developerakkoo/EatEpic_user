# UI/UX Gaps and Improvements

This document is the single source of truth for what is missing and what can be added to make the app look and feel like a professional food delivery app (e.g. Zomato, Swiggy).

---

## Current state

### Screens and routes

| Screen | Route / entry | Status |
|--------|----------------|--------|
| SplashScreen | `/` (initial) | App logo, 2.2s then → onboarding or permissions (SharedPreferences) |
| OnboardingScreen | `/onboarding` | 3 slides: location, notifications, how it works; Skip / Get started → permissions |
| PermissionsScreen | `/permissions` | Request location/notification then navigate to Login |
| LoginScreen | `/login` | Phone input, +91, "Continue" sends OTP and navigates to location picker (no OTP verification step) |
| LocationPickerScreen | `/location-picker` (args: fromHome, fromCart) | Map picker with search; save address to LocationProvider |
| MainShell | `/home` | BottomNavigationBar: Home, Subscription, Search, Account; no cart badge |
| HomeScreen | Tab 0 | Banner carousel, categories, hotel list with HotelCard, loading shimmers; tap opens HotelDetailScreen |
| HotelDetailScreen | Push from Home/Search | SliverAppBar with Hero image, single hardcoded menu item (MenuItemCard), View Cart slide-up bar |
| SearchScreen | Tab 2 | Search field, debounce, filter by name/cuisine, suggestions chips, recent searches, HotelCard results, empty state |
| AccountScreen | Tab 3 | Profile header (avatar, "User", phone), Saved address, Orders (snackbar), Subscriptions (push), Help (dialog), Logout |
| CartScreen | `/cart` | Items list, clear cart, offers (mock), delivery address, order summary, payment (delivery/online), place order bar; empty state |
| SubscriptionScreen | Tab 1 | List or empty state; FAB to create; cancel subscription confirmation |
| CreateSubscriptionScreen | `/create-subscription` | 5-step flow (restaurant, frequency, days, time, confirm); progress bar; snackbar on create |

### Dialogs and overlays

- **Clear cart** – AlertDialog confirmation.
- **Place order success** – SnackBar only.
- **Cancel subscription** – AlertDialog confirmation.
- **Help** – AlertDialog with placeholder support text.
- **No orders yet** – SnackBar from Account > Orders.

### Theme

- `lib/core/app_theme.dart`: Material 3, primary green, Poppins typography, light and dark theme (dark theme only partially defined).
- `lib/core/typography/app_typography.dart`: Centralized text styles.

---

## 1. What is missing (screens and flows)

### Auth

- [ ] No OTP verification screen; login skips real verification and navigates after "send OTP".
- [ ] No "Resend OTP", timer, or error state for wrong OTP.

### Orders

- [ ] No Orders screen; Account only shows a snackbar "No orders yet".
- [ ] No order history, status, or reorder.

### Place order

- [ ] No validation that delivery address is set before placing order.
- [ ] No loading state or success screen after place order (only SnackBar and pop).

### Cart access

- [ ] No cart icon or badge in AppBar/MainShell; users must go to cart from hotel details "View Cart" or an unspecified entry point.

### Hotel details

- [ ] Single hardcoded menu item; no real menu list from hotel.
- [ ] No categories (Starters, Main, etc.), no customisation/add-ons UI.

### Restaurant info

- [ ] No "About", opening hours, or address on hotel details.
- [ ] No call/direction actions.

### Profile

- [ ] No edit profile (name, email, photo).
- [ ] No "Add phone number" action when phone is null; placeholder "User" only.

### Addresses

- [ ] Single address only (LocationProvider); no saved addresses list.
- [ ] No "Home/Work/Other" labels, no default address selection.

### Payments

- [ ] Payment section is placeholder (delivery/online); no saved payment methods.
- [ ] No UPI/card list, no payment success/failure handling.

### Offers

- [ ] Mock offers only; no apply/remove feedback, no discount breakdown in order summary.

### Notifications

- [ ] Not mentioned in Account; no in-app notification center or settings.

### Onboarding / splash

- [ ] No splash screen.
- [ ] No first-time onboarding carousel, no "Skip" / "Get started".

### Errors and retry

- [ ] No global or screen-level error state (e.g. failed to load hotels).
- [ ] No retry button or error illustration; only image-level error placeholders.

### Pull-to-refresh

- [ ] No RefreshIndicator on home, search, or subscription list.

### Empty states

- [ ] Present on cart, subscription, search (no results); could be more consistent (illustrations, primary CTA styling).

### Loading

- [ ] Home has shimmers; other screens use CircularProgressIndicator or none.
- [ ] No skeleton for cart/subscription.

### Navigation

- [ ] No cart route from MainShell (e.g. FAB or nav item); back from cart goes to previous screen but no "Cart" in bottom nav.

---

## 2. What is missing (dialogs and feedback)

- [ ] **Place order success:** Replace or supplement SnackBar with a success dialog or full-screen "Order placed" with order ID and "Track" / "Continue browsing".
- [ ] **Clear cart:** Dialog exists; consider destructive styling for "Clear" (e.g. red text button).
- [ ] **Logout:** No confirmation dialog; direct logout can feel abrupt.
- [ ] **Network/API errors:** No dialog or banner for "Something went wrong" with retry.
- [ ] **Location permission denied:** PermissionsScreen continues to login; no "Denied" state with "Open settings" CTA.
- [ ] **Snackbars:** No consistent styling (e.g. behavior, action button); "Order placed" disappears without explicit "View order" action.

---

## 3. Recommendations (what can be added)

### Splash and onboarding

- **Done:** Splash screen with app logo (`/` → `SplashScreen`); 3-slide onboarding (`/onboarding`) for first launch (location, notifications, how it works); "Get started" and "Skip" go to permissions. Returning users skip onboarding via SharedPreferences.

### Auth flow

- OTP entry screen with resend timer, error message, and loading state.
- Optional "Change number" link.

### MainShell and cart

- Add cart badge (e.g. on Home AppBar or a persistent cart icon) showing item count.
- Consider 5th tab for Cart or prominent cart FAB from home.

### Orders

- New Orders screen: list of past orders (mock or real).
- Status chips (Delivered, Preparing, etc.), tap for order details, "Reorder" button.

### Place order flow

- Validate address before enabling "Place order".
- Loading overlay during submit.
- Success screen (illustration, order ID, ETA, "Track" / "Back to home").

### Hotel details

- Full menu from data (by category).
- Restaurant info section (address, hours, "Call" / "Direction").
- Optional "Favourite" icon.

### Profile

- Edit profile screen (name, email, profile photo).
- "Add phone number" tap navigates to login or dedicated edit; use auth name if available.

### Saved addresses

- List of addresses with labels (Home, Work, Other), add/edit/delete, set default.
- LocationPicker for add/edit.

### Payment methods

- List of saved methods (e.g. UPI, Card); add payment flow placeholder; select default.
- Show in cart payment section.

### Offers

- Apply/remove with clear feedback.
- Show discount line in order summary when applied.
- Optional "No offers" empty state.

### Reusable components

- Consistent empty and error states: illustration + title + subtitle + primary button.
- Use on cart, orders, search, subscription, and error views.

### Pull-to-refresh

- Home (hotels), Search (results), Subscription list, Orders list.

### Loading and skeletons

- Skeleton loaders for list screens (home already has shimmer).
- Loading overlay for cart place order and auth.

### Dialogs

- Logout confirmation.
- "Location denied" with Open settings.
- Generic error dialog with retry.
- Place-order success as dialog or screen.

### Accessibility and polish

- Semantic labels for icons; sufficient contrast; focus order on login/OTP.
- Optional haptic on add to cart.
- Consistent padding (e.g. 16 horizontal, 12–14 vertical) and section dividers.

### Dark theme

- Complete dark theme (scaffold, cards, dialogs) so the app looks consistent in system dark mode.

### Micro-interactions

- Add-to-cart animation (already present via package).
- Optional success checkmark or brief animation on place order.
