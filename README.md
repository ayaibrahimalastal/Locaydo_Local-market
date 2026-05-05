# locaydo_app

Locaydo is a mobile-based online marketplace application designed to organize and facilitate local buying and selling within the Gaza Strip. The application provides an organized, reliable, and easy-to-use alternative to fragmented commerce via social media platforms.

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://firebase.google.com"><img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  <img src="https://img.shields.io/badge/build-passing-brightgreen" alt="Build Status">
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey" alt="Platform">
</p>

---

## 📚 Project Documentation

> [!IMPORTANT]
> **For complete technical documentation including Requirements Analysis, UML Diagrams, Database Design, Implementation, and Testing Plans, visit our [Locaydo Wiki](https://github.com/ayaibrahimalastal/Locaydo/wiki).**

---

## 🎯 Table of Contents

- [Project Overview](#-project-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Technologies Used](#-technologies-used)
- [Testing](#-testing)
- [Build & Deployment](#-build--deployment)
- [Team & Contribution](#-team--contribution)
- [Known Issues](#known-issues)
- [Future Roadmap](#future-roadmap)
- [License](#-license)

---

## 📖 Project Overview

### The Problem

Online trading in Gaza heavily relies on informal social media platforms (Facebook, WhatsApp, Instagram) leading to:

- 🔍 **Inefficient searching** through disorganized posts
- 📂 **Poor categorization** and product discovery
- 🤝 **Lack of trust** due to absence of verification systems
- 🔄 **Difficulty managing** listings and tracking sold items

### Our Solution

Locaydo provides a centralized, mobile-first marketplace featuring:

- ✅ Structured product categories (Electronics, Clothing, Furniture, Real Estate, Donations,...)
- ✅ Seller verification and rating system
- ✅ Direct communication via WhatsApp/Phone
- ✅ Optimized performance for Gaza's internet conditions
- ✅ Simple, intuitive interface in Arabic (RTL support)

---

## ✨ Features

### Buyer Features

- ✅ Browse products by category
- ✅ Advanced search with filters (location, product name, seller name)
- ✅ View seller profiles and ratings
- ✅ Add products/sellers to favorites
- ✅ Share products on social media
- ✅ Direct contact via WhatsApp/Phone
- ✅ Rate sellers to enhance reliability

### Seller Features

- ✅ Create and manage seller profile
- ✅ Add/edit/delete product listings
- ✅ Mark products as "Available" or "Sold"
- ✅ View available and sold product history
- ✅ Update profile information and avatar
- ✅ Manage inventory effectively

---

## 📱 Screenshots

<table align="center">
  <tr>
    <td valign="top" align="center"><b>Splash Screen</b><br><img src="https://github.com/user-attachments/assets/fedb9efd-d72a-4659-a8e5-4cb7891b5a83" width="200" /></td>
    <td valign="top" align="center"><b>Home Screen</b><br><img src="https://github.com/user-attachments/assets/e9cfb0d4-7d90-40db-8ce4-2d2732a8b2e6" width="200" /></td>
    <td valign="top" align="center"><b>Seller Profile</b><br><img src="https://github.com/user-attachments/assets/b2734066-f280-4e59-bc79-458be5bbc03f" width="200" /></td>
    <td valign="top" align="center"><b>Product Details</b><br><img src="https://github.com/user-attachments/assets/d87b034d-fac3-4e34-b394-799257d08ce7" width="200" /></td>
  </tr>
</table>

---

## 🚀 Installation

### Prerequisites

- Flutter SDK (>= 3.22.0)
- Dart SDK (>= 3.4.0)
- Android Studio / VS Code
- Firebase Account
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/ayaibrahimalastal/Locaydo_Local-market.git
   cd Locaydo
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a new project in [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password) and Cloud Firestore
   - Add Android and iOS apps to your Firebase project
   - Download and place configuration files:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`
   - Run `flutterfire configure` to generate `lib/firebase_options.dart`

4. **Run the application**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

The project follows **Feature-Driven Clean Architecture** with Provider for state management:

```
lib/
├── main.dart
├── core/
│   ├── constants/          # AppAssets, AppStrings
│   ├── di/                 # Dependency injection (buildProviders)
│   ├── enums/              # ProductCategory, GazaLocation, PaymentMethod …
│   ├── extensions/         # BuildContext extensions
│   ├── network/            # FirebaseCollections constants
│   ├── routes/             # AppRoutes
│   ├── services/           # AppLinkHandler
│   ├── theme/              # AppColors, AppTextStyles, FigmaDesignSystem
│   └── utils/              # Animations, Helpers, Validators, Logger …
│
├── features/
│   ├── auth/               # Splash, Welcome, Login, Signup, Activation
│   ├── categories/         # Category list & details
│   ├── favorites/          # Favorite products & sellers
│   ├── home/               # Home feed with filters
│   ├── products/           # Product form, details, models
│   ├── profile/            # User profile, seller setup/edit/view
│   ├── ratings/            # Rating model & repository
│   ├── search/             # Search users & products
│   └── seller/             # Public seller profile view
│
└── shared/
    ├── models/             #bottom_sheet_option
    ├── screens/            # loading_screen
    └── widgets/            # Reusable UI components
        ├── common/         # Button, FavoriteButton, SmartAvatar …
        ├── form/           # Input, PhoneInput, ImageUploader …
        ├── navigation/     # MainNavigationScreen
        ├── product/        # ProductCard, ShareProductOverlay
        └── seller/         # RatingOverlay
```

Each feature follows the layered structure:
```
feature/
├── data/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   └── repositories/
└── presentation/
    ├── screens/
    └── viewmodels/
```

---

## 🛠 Technologies Used

| Technology | Purpose | Version |
|-----------|---------|---------|
| Flutter | Frontend Framework | 3.22+ |
| Dart | Programming Language | 3.4+ |
| Firebase Auth | User Authentication | Latest |
| Cloud Firestore | NoSQL Database | Latest |
| Cloudinary | Image Storage & CDN | Latest |
| Provider | State Management | 6.0+ |
| cached_network_image | Image Caching | Latest |
| image_picker | Camera & Gallery | Latest |
| url_launcher | Phone & WhatsApp | Latest |
| flutter_svg | SVG Assets | Latest |
| app_links | Deep Linking | Latest |

---

## 🧪 Testing

```bash
# Run all unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

---

## 📦 Build & Deployment

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ipa --release
```

---

## 👥 Team & Contribution

### Development Team

- **Aya Ibrahim Mohammed Al-Astal**
- **Doaa Khaled Salama Al-Qarra**
- **Maha Mahmoud Hamed Humaid**
- **Yousef Ashraf Mostafa Aljamal**
- **Ahmed Jamal Mohammed Shannan**

### Supervisor

**Dr. Mohammed Al-Shawwa** — Faculty of Engineering, Al-Azhar University Gaza

### Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/AmazingFeature`
3. Commit: `git commit -m 'Add AmazingFeature'`
4. Push: `git push origin feature/AmazingFeature`
5. Open a Pull Request

---

##  Known Issues

| Issue | Status |
|-------|--------|
| Image upload may be slow on weak connections | Retry mechanism implemented |
| WhatsApp button requires the app to be installed | Fallback message shown |
| RTL layout edge cases on older Android | Under investigation |

---

##  Future Roadmap

**v1.1** — Push notifications, improved offline support, report feature  
**v2.0** — In-app chat, electronic payments, delivery tracking  
**v3.0** — Web platform, analytics dashboard, business subscriptions

---

## 📄 License

MIT License.

```
MIT License

Copyright (c) 2026 Locaydo Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<div align="center">

**Made with ❤️ in Gaza, Palestine 🇵🇸**

*"Connecting communities through technology"*

</div>
