# SARV MANGAL — Button, Tab, and Interactive Elements Inventory

**Official Brand:** SARV MANGAL  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  
**Audit Date:** 2026-10-20  
**Phase:** P7 Architecture & Separation  

---

## 1. Scope & Methodology

Every button, tab, menu item, floating action control, and dialog trigger across the mobile client and the dedicated Admin Portal was mapped from source code. Interactive elements were traced from user touch/click through client-side state handling to backend endpoints and database mutations.

---

## 2. Flutter Mobile Application Inventory

### A. Authentication & Onboarding
| Screen / Route | Element Label / Icon | Type | Handler Callback | Target Route / Action | Data Effect / API Call | Status |
|---|---|---|---|---|---|---|
| `RoleSelectScreen` (`/role-select`) | "Continue as Devotee (Yajman)" | Card / Button | `onTap` | `context.go('/yajman-login')` | Sets client role to `YAJMAN` | **WORKING** |
| `RoleSelectScreen` (`/role-select`) | "Continue as Pandit Ji" | Card / Button | `onTap` | `context.go('/pandit-login')` | Sets client role to `PANDIT` | **WORKING** |
| `YajmanLoginScreen` (`/yajman-login`) | "Send Sacred OTP" | Primary Button | `_sendOtp()` | `context.push('/yajman-otp')` | `POST /api/v1/auth/send-otp` | **WORKING** |
| `YajmanLoginScreen` (`/yajman-login`) | Back Arrow Icon | IconButton | `Navigator.pop()` | Returns to Role Selection | Local navigation | **WORKING** |
| `YajmanOtpScreen` (`/yajman-otp`) | 6 OTP Input Boxes | TextField | `onChanged` | Advances focus | In-memory OTP string | **WORKING** |
| `YajmanOtpScreen` (`/yajman-otp`) | "Verify & Enter" | Primary Button | `_verifyOtp()` | `context.go('/home')` | `POST /api/v1/auth/verify-otp` (saves JWT) | **WORKING** |
| `YajmanOtpScreen` (`/yajman-otp`) | "Resend Code" | TextButton | `_resendOtp()` | Restarts 300s timer | `POST /api/v1/auth/send-otp` | **WORKING** |
| `YajmanRegisterScreen` (`/yajman-register`)| "Save Profile & Continue" | Primary Button | `_saveProfile()` | `context.go('/home')` | `PATCH /api/v1/users/profile` | **WORKING** |
| `PanditLoginScreen` (`/pandit-login`) | "Send OTP" | Primary Button | `_sendOtp()` | Shows OTP entry | `POST /api/v1/auth/send-otp` | **WORKING** |
| `PanditLoginScreen` (`/pandit-login`) | "Verify & Enter Portal" | Primary Button | `_verifyOtp()` | Navigates based on profile | `POST /api/v1/auth/verify-otp` | **WORKING** |
| `PanditOnboardingScreen` (`/pandit-onboarding`)| Step 1 "Next: Select Poojas" | Primary Button | `_goToStep2()` | Advances to Step 2 | Validates specialization & city | **WORKING** |
| `PanditOnboardingScreen` (`/pandit-onboarding`)| Step 2 "Next: Upload KYC" | Primary Button | `_goToStep3()` | Advances to Step 3 | Validates selected poojas | **WORKING** |
| `PanditOnboardingScreen` (`/pandit-onboarding`)| Document Upload Buttons | OutlinedButton | `_pickAndUpload()` | Selects Image / PDF | `POST /api/v1/pandits/upload-doc` | **WORKING** |
| `PanditOnboardingScreen` (`/pandit-onboarding`)| Step 3 "Submit Application" | Primary Button | `_submitApplication()`| Shows Pending Screen | `POST /api/v1/pandits/apply` | **WORKING** |

### B. Devotee Home & Navigation
| Screen / Route | Element Label / Icon | Type | Handler Callback | Target Route / Action | Data Effect / API Call | Status |
|---|---|---|---|---|---|---|
| `HomeScreen` (`/home`) | Offline Pooja Tile | Service Card | `onTap` | `context.push('/book?mode=offline')` | Navigates to Pooja Catalog | **WORKING** |
| `HomeScreen` (`/home`) | Online E-Pooja Tile | Service Card | `onTap` | `context.push('/book?mode=online')` | Navigates to Online Catalog | **WORKING** |
| `HomeScreen` (`/home`) | Vedic Jyotish Consultation | Service Card | `onTap` | `showModalBottomSheet()` | Opens `ConsultationFlowModal` | **WORKING** |
| `HomeScreen` (`/home`) | Handmade Kundali Tile | Service Card | `onTap` | `showModalBottomSheet()` | Opens `HandmadeKundliOrderModal` | **WORKING** |
| `HomeScreen` (`/home`) | Temple Darshan Tile | Service Card | `onTap` | `context.push('/nearest-temple')` | Navigates to Temples Screen | **WORKING** |
| `HomeScreen` (`/home`) | Daily Phool & Mala Tile | Service Card | `onTap` | `context.push('/phool-mala')` | Navigates to Phool Mala | **WORKING** |
| `HomeScreen` (`/home`) | "Ask Pandit Ji" | FloatingActionButton | `_openChatModal()` | Opens `PanditChatModal` | Client-side Vedic Assistant | **WORKING** |
| `HomeScreen` (`/home`) | Drawer Menu Icon | IconButton | `Scaffold.openDrawer()`| Opens `AppSideDrawer` | Local navigation | **WORKING** |
| `HomeScreen` (`/home`) | Notifications Bell | IconButton | `context.push('/notifications')`| Navigates to Notifications | `GET /api/v1/notifications` | **WORKING** |
| `AppBottomNavBar` (Shared) | Home Tab | BottomNavItem | `onTap(0)` | `context.go('/home')` | Route transition | **WORKING** |
| `AppBottomNavBar` (Shared) | Bookings Tab | BottomNavItem | `onTap(1)` | `context.go('/bookings')` | `GET /api/v1/bookings` | **WORKING** |
| `AppBottomNavBar` (Shared) | Store Tab | BottomNavItem | `onTap(2)` | `context.go('/shop')` | `GET /api/v1/products` | **WORKING** |
| `AppBottomNavBar` (Shared) | Panchang Tab | BottomNavItem | `onTap(3)` | `context.go('/panchang')` | Panchang calculation | **WORKING** |
| `AppBottomNavBar` (Shared) | Profile Tab | BottomNavItem | `onTap(4)` | `context.go('/profile')` | `GET /api/v1/users/profile` | **WORKING** |
| `AppSideDrawer` (Shared) | Terms & Conditions Tile | ListTile | `_showTermsModal()` | Opens Terms Dialog | Modal view | **WORKING** |
| `AppSideDrawer` (Shared) | FAQs Tile | ListTile | `_showFaqModal()` | Opens FAQs Dialog | Modal view | **WORKING** |
| `AppSideDrawer` (Shared) | Pooja Store Tile | ListTile | `context.go('/shop')` | Navigates to Store | Route transition | **WORKING** |
| `AppSideDrawer` (Shared) | Vedic Panchang Tile | ListTile | `context.go('/panchang')` | Navigates to Panchang | Route transition | **WORKING** |

### C. Booking Flow, Tracking & Pandit Duty
| Screen / Route | Element Label / Icon | Type | Handler Callback | Target Route / Action | Data Effect / API Call | Status |
|---|---|---|---|---|---|---|
| `BookScreen` (`/book`) | Category Tabs (Ghar, Shanti, Sanskar, Path)| TabBar | `_onTabChanged()` | Filters pooja list | Client-side list filter | **WORKING** |
| `BookScreen` (`/book`) | "Book Now" Card Button | Primary Button | `context.push('/book-flow')` | Opens Booking Flow | Passes selected `PoojaDetail` | **WORKING** |
| `PoojaBookingFlowScreen` (`/book-flow`)| Date Picker Control | InkWell Card | `showDatePicker()` | Selects booking date | Updates booking form state | **WORKING** |
| `PoojaBookingFlowScreen` (`/book-flow`)| Time Slot Chips | ChoiceChip | `setState()` | Selects morning/afternoon slot | Updates booking form state | **WORKING** |
| `PoojaBookingFlowScreen` (`/book-flow`)| Samagri Kit Checkbox | CheckboxListTile| `setState()` | Adds/removes samagri kit fee | Recalculates total price | **WORKING** |
| `PoojaBookingFlowScreen` (`/book-flow`)| "Confirm & Book Pooja" | Primary Button | `_submitBooking()` | `context.push('/tracking')` | `POST /api/v1/bookings` | **WORKING** |
| `LivePoojaTrackingScreen` (`/tracking`)| "Call Pandit Ji" | OutlinedButton | `_launchPhoneCall()` | Launches device dialer | `tel:<pandit_phone>` | **WORKING** |
| `LivePoojaTrackingScreen` (`/tracking`)| "Cancel Pooja Booking" | Destructive | `_confirmCancellation()`| Cancels booking | `PATCH /api/v1/bookings/:id/cancel`| **WORKING** |
| `PanditDashboardScreen` (`/pandit-dashboard`)| Duty Status Switch | Switch | `_toggleDuty()` | Online/Offline toggle | `PATCH /api/v1/pandits/duty-status`| **WORKING** |
| `IncomingPoojaRequestModal` | "ACCEPT BOOKING" | Primary Button | `_acceptBooking()` | Accepts pooja allotment | `POST /pandits/accept-booking` | **WORKING** |
| `IncomingPoojaRequestModal` | "DECLINE" | OutlinedButton | `_showDeclineDialog()`| Declines request with reason | `POST /pandits/decline-booking` | **WORKING** |
| `PanditDashboardScreen` | "Collect Cash Dakshina" | Primary Button | `_showCashDakshinaDialog()`| Records cash collection | `POST /bookings/:id/dakshina/cash` | **WORKING** |

### D. Store, Cart & Modals
| Screen / Route | Element Label / Icon | Type | Handler Callback | Target Route / Action | Data Effect / API Call | Status |
|---|---|---|---|---|---|---|
| `ShopScreen` (`/shop`) | Category Filter Chips | FilterChip | `_filterByCategory()`| Filters product list | Client-side filter | **WORKING** |
| `ShopScreen` (`/shop`) | "Add to Sacred Cart" | ElevatedButton | `_addToCart()` | Adds item to cart | Updates SharedPreferences cart | **WORKING** |
| `ShopScreen` (`/shop`) | Cart Floating Button Badge | FloatingActionButton | `context.push('/cart')` | Navigates to Cart | Route transition | **WORKING** |
| `CartScreen` (`/cart`) | '+' / '-' Quantity Buttons | IconButton | `_updateQuantity()` | Increments/decrements qty | Updates local cart | **WORKING** |
| `CartScreen` (`/cart`) | "Proceed to Checkout" | Primary Button | `context.push('/checkout')`| Navigates to Checkout | Validates minimum order | **WORKING** |
| `CheckoutScreen` (`/checkout`)| "Pay via Razorpay" | Primary Button | `_initiateRazorpayPayment()`| Opens Razorpay Checkout | `POST /payments/create-order` | **WORKING** |
| `ConsultationFlowModal` | "Schedule Consultation" | Primary Button | `_submitConsultation()`| Displays Reference Card | `POST /api/v1/consultations` | **WORKING** |
| `HandmadeKundliOrderModal` | "Confirm Kundli Order" | Primary Button | `_submitOrder()` | Displays Order Reference | `POST /api/v1/kundli-orders` | **WORKING** |
| `PanditChatModal` | "Send" Message Button | IconButton | `_handleSendMessage()` | Adds response to chat log | Local heuristic response | **WORKING** |

---

## 3. Dedicated Admin Web Portal Inventory

| View / Module | Element Label | Type | Handler Callback | API Endpoint | Data Effect | Status |
|---|---|---|---|---|---|---|
| **Admin Login** | Email / Admin ID Input | Input Field | `onChange` | Client state | Updates login credentials | **WORKING** |
| **Admin Login** | Password Input | Password Field | `onChange` | Client state | Secure input | **WORKING** |
| **Admin Login** | Show / Hide Password | IconButton | `toggleShowPassword()` | Local state | Toggles `type="text"` / `"password"` | **WORKING** |
| **Admin Login** | "Secure Admin Login" | Primary Button | `handleLogin()` | `POST /api/v1/admin/auth/login` | Validates scrypt hash, issues JWT | **WORKING** |
| **Admin Header** | "Sign Out" | Button | `handleLogout()` | Clears localStorage token | Redirects to `/login` | **WORKING** |
| **Admin Nav** | "Overview & Metrics" | Nav Tab | `setActiveTab('overview')` | `GET /api/v1/admin/stats` | Loads live counts | **WORKING** |
| **Admin Nav** | "Pandit KYC Queue" | Nav Tab | `setActiveTab('pandits')` | `GET /api/v1/admin/pandits` | Loads Pandit applications | **WORKING** |
| **Admin Nav** | "Subscriptions Desk" | Nav Tab | `setActiveTab('subscriptions')` | `GET /api/v1/admin/subscriptions` | Loads active recurring plans | **WORKING** |
| **Admin Nav** | "Consultation Desk" | Nav Tab | `setActiveTab('consultations')` | `GET /api/v1/admin/consultations` | Loads consultation requests | **WORKING** |
| **Admin Nav** | "Kundli Orders Desk" | Nav Tab | `setActiveTab('kundli')` | `GET /api/v1/admin/kundli-orders` | Loads physical Kundli orders | **WORKING** |
| **Pandit KYC Tab** | Filter: PENDING / APPROVED / REJECTED | Button Chips | `setPanditFilter()` | `GET /admin/pandits?status=...` | Filters applicant list | **WORKING** |
| **Pandit KYC Tab** | "View Document" | Link / Button | `window.open(url)` | `GET /admin/documents/:id/download` | Streams secure document buffer | **WORKING** |
| **Pandit KYC Tab** | "Verify Document" | Toggle Button | `handleVerifyDocument()` | `PATCH /admin/documents/:id/verify` | Marks document `isVerified: true` | **WORKING** |
| **Pandit KYC Tab** | "Approve Application" | Success Button | `handleApprovePandit()` | `PATCH /admin/pandits/:id/approval` | Sets status `APPROVED`, sets verified | **WORKING** |
| **Pandit KYC Tab** | "Reject Application" | Danger Button | `openRejectModal()` | `PATCH /admin/pandits/:id/approval` | Sets status `REJECTED` with reason | **WORKING** |
| **Consultation Desk**| Status Filter | Dropdown / Chips | `setConsultationFilter()`| `GET /admin/consultations?status=...`| Filters consultation list | **WORKING** |
| **Consultation Desk**| "Schedule Session" | Action Button | `handleSchedule()` | `PATCH /admin/consultations/:id/schedule`| Sets scheduled start/end timestamps | **WORKING** |
| **Consultation Desk**| "Assign Pandit" | Action Button | `handleAssignPandit()` | `PATCH /admin/consultations/:id/assignment`| Assigns Vedic Acharya | **WORKING** |
| **Consultation Desk**| Status Transition Dropdown | Select | `handleStatusChange()` | `PATCH /admin/consultations/:id/status` | Transitions: SCHEDULED -> COMPLETED | **WORKING** |
| **Kundli Orders Desk**| Status Filter | Dropdown / Chips | `setKundliFilter()` | `GET /admin/kundli-orders?status=...` | Filters orders list | **WORKING** |
| **Kundli Orders Desk**| "Accept Order" | Success Button | `handleDecision('ACCEPT')` | `PATCH /admin/kundli-orders/:id/decision` | Transitions status to `REVIEWED` | **WORKING** |
| **Kundli Orders Desk**| "Reject Order" | Danger Button | `handleDecision('REJECT')` | `PATCH /admin/kundli-orders/:id/decision` | Rejects order with reason | **WORKING** |
| **Kundli Orders Desk**| "Assign Astrologer" | Action Button | `handleAssignPandit()` | `PATCH /admin/kundli-orders/:id/assignment`| Assigns Kundli writer Pandit | **WORKING** |
| **Kundli Orders Desk**| "Dispatch (Speed Post)"| Primary Button | `handleDispatch()` | `PATCH /admin/kundli-orders/:id/status` | Sets tracking number & `DISPATCHED` | **WORKING** |
| **Kundli Orders Desk**| "Mark Delivered" | Success Button | `handleStatusChange('DELIVERED')`| `PATCH /admin/kundli-orders/:id/status` | Closes order lifecycle | **WORKING** |
