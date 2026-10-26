# SARV MANGAL — UI Customization & Central Design System Guide

**Brand Name:** SARV MANGAL  
**Motto / Shloka:** सर्व मंगल मांगल्ये शिवे सर्वार्थ साधिके  
**Platform:** Flutter Mobile (Android & iOS)  
**Location in Repository:** `frontend/pandit_ssetu/lib/theme/` and `frontend/pandit_ssetu/lib/widgets/common/`

---

## 1. Architecture Overview

SARV MANGAL's Flutter presentation layer is built upon a **Centralized Tokenized Design System**. Screen widgets, modal dialogues, and lists reference centralized constants and standardized reusable components. Rebranding, color tuning, typography scaling, and component restyling can be performed centrally in a single folder without rewriting screen business logic.

```
frontend/pandit_ssetu/lib/
├── constants/
│   └── branding.dart                 # App Name, Tagline, Subtitle
├── theme/
│   ├── app_colors.dart               # Palette, Semantic Status, Gradients
│   ├── app_spacing.dart              # Spacing, Radii, Elevation & Shadows
│   ├── app_typography.dart           # Font Scale, Weights, Line Heights
│   └── app_theme.dart                # Global Material 3 ThemeData Factory
└── widgets/
    └── common/
        ├── sarv_button.dart          # Primary, Secondary, Outlined, Destructive buttons
        ├── sarv_text_field.dart      # Input fields with password toggle & validation
        ├── sarv_card.dart            # Elevated warm cards
        ├── sarv_status_badge.dart    # Semantic lifecycle badges
        └── sarv_states.dart          # LoadingState, EmptyState, ErrorRetryState
```

---

## 2. Token Customization Guide

### 2.1 Colors (`app_colors.dart`)
To update the brand color from Sacred Saffron (`#E65100`) to any new primary color, change `AppColors.primary`:
```dart
class AppColors {
  // Primary brand identity
  static const Color primary = Color(0xFFE65100);       // Main actions, AppBar icons, active states
  static const Color primaryLight = Color(0xFFFFA726);  // Hover & accent borders
  static const Color primaryDark = Color(0xFFBF360C);   // Pressed & deep backgrounds

  // Vedic Gold & Marigold
  static const Color secondary = Color(0xFFFFB300);     // Badges, highlights, secondary CTAs
  static const Color secondaryDark = Color(0xFFFF8F00);

  // Backgrounds & Surface
  static const Color background = Color(0xFFFFFBF7);    // Warm off-white devotee background
  static const Color surface = Color(0xFFFFFFFF);       // Card and dialog surface
  static const Color surfaceWarm = Color(0xFFF7ECE0);   // Drawer & highlight backgrounds
  static const Color cardBorder = Color(0xFFF0E0D0);    // Warm subtle card border

  // Semantic Status
  static const Color success = Color(0xFF2E7D32);       // Approved, Completed, Active
  static const Color warning = Color(0xFFED6C02);       // Pending, Scheduled, In Transit
  static const Color error = Color(0xFFD32F2F);         // Rejected, Cancelled, Failed
  static const Color info = Color(0xFF0288D1);          // Informational notices
}
```

### 2.2 Spacing & Radii (`app_spacing.dart`)
Spacing values are defined on a 4-pixel grid:
```dart
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;   // Default for buttons & inputs
  static const double radiusLg = 16.0;   // Default for cards & modals
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0; // Badges & chips
}
```

### 2.3 Typography (`app_typography.dart`)
Typography provides strict hierarchy across all screen titles, subtitles, body copy, and Vedic shlokas:
- `displayLarge`: 28sp / w700
- `headlineLarge`: 20sp / w600
- `headlineMedium`: 18sp / w600
- `titleMedium`: 16sp / w600
- `bodyLarge`: 15sp / w400
- `bodyMedium`: 14sp / w400
- `labelLarge`: 14sp / w600 (Button labels)
- `sacredDevanagari`: 14sp italic Devanagari styling

---

## 3. Standardized Reusable UI Components

### 3.1 `SarvButton`
Unified button component supporting 4 semantic variants, built-in loading indicator, icon support, and automatic disabled state:
```dart
SarvButton(
  label: 'Book Sacred Pooja',
  icon: Icons.temple_hindu_outlined,
  variant: SarvButtonVariant.primary,
  isLoading: isSubmitting,
  onPressed: () => handleBooking(),
)
```

Variants:
- `SarvButtonVariant.primary`: Sacred Saffron fill, white text.
- `SarvButtonVariant.secondary`: Vedic Gold fill, dark text.
- `SarvButtonVariant.outlined`: Transparent fill, Saffron border & text.
- `SarvButtonVariant.destructive`: Vedic Red fill, white text.

### 3.2 `SarvTextField`
Accessible text field with built-in password visibility toggle, error text, prefix icons, and phone formatting:
```dart
SarvTextField(
  label: 'Admin Password',
  hint: 'Enter minimum 8 characters',
  isPassword: true,
  controller: _passwordController,
  errorText: _errorMessage,
)
```

### 3.3 `SarvCard`
Elevated card with warm border and optional ink-splash tap callback:
```dart
SarvCard(
  onTap: () => viewPoojaDetail(pooja),
  child: Column(
    children: [
      Text(pooja.name, style: AppTypography.headlineMedium),
      Text(pooja.description, style: AppTypography.bodyMedium),
    ],
  ),
)
```

### 3.4 `SarvStatusBadge`
Automatically applies semantic colors based on booking, verification, or consultation lifecycle state:
```dart
SarvStatusBadge(status: 'APPROVED')   // Green badge
SarvStatusBadge(status: 'PENDING')    // Amber badge
SarvStatusBadge(status: 'REJECTED')   // Red badge
```

### 3.5 `SarvLoadingState`, `SarvEmptyState`, and `SarvErrorState`
Consistent user feedback across all async lists and screens:
```dart
// Empty
SarvEmptyState(
  icon: Icons.auto_stories_outlined,
  title: 'No Active Kundli Orders',
  message: 'Order a personalized Vedic Kundli prepared by verified astrologers.',
  actionLabel: 'Order Kundli',
  onAction: () => openKundliModal(),
)

// Error & Retry
SarvErrorState(
  error: 'Unable to connect to gateway',
  onRetry: () => fetchCatalog(),
)
```

---

## 4. Mobile App Separation Verification
In compliance with Phase P7 requirements, all Admin dashboard links, tiles, and routes have been removed from the mobile application:
- **Drawer Tile Removed:** `Admin Verification Desk` has been removed from `app_side_drawer.dart`.
- **Router Route Removed:** `/admin-dashboard` has been removed from `main.dart`.
- Devotee and Pandit roles operate with pristine mobile experiences, while Administrative operations reside strictly within the dedicated Admin Web Portal.
