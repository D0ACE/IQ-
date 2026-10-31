# Visual Theme and Typography Documentation (`theme_font.md`)

This document serves as the authoritative, comprehensive design system specification for the **IQ +** Flutter application. It captures the complete visual theme, typography scale, color palette, component specifications, screen-specific adaptations, and architectural patterns found in the project.

---

## Section 1: Theme Overview

### Visual Design Characteristics
The **IQ +** application utilizes a **hybrid enterprise-modern design language**. The styling integrates:
1. **Brand Identity Foundation**: A corporate palette centered around Deep Navy (`#053459`), Steel Blue (`#5899CC`), and Teal Accent (`#39A28F`), paired with clean light surfaces (`#FFFFFF`, `#F2F2F2`, `#F7F9FB`).
2. **Action Paradigm**: High-contrast, brand-distinguished actions utilizing a dark forest green background (`#006400`) paired with golden yellow text (`#FFD700`) for elevated, filled, outlined, text, and floating action buttons.
3. **Glassmorphism & Depth Effects**: Fluid gradient animations, backdrop blur (`sigmaX: 40, sigmaY: 40`), radial glow orbs, and soft directional shadows (`Color(0x140E2A3D)`) applied across login, onboarding, and dashboard command centers.
4. **Theme Architecture**: The theme is **both centralized and distributed**:
   - **Centralized Engine**: Defined in `lib/common/themes/app_colors.dart`, `lib/common/themes/app_theme_data.dart`, `lib/common/themes/app_const.dart`, and `lib/common/themes/app_strings.dart`. The main theme is configured in `lib/common/routes/app.dart` via `AppThemeData.appThemeData()` and injected into `MaterialApp.router`.
   - **Distributed Screen Extensions**: Individual feature modules (such as Login, Dashboards, Customer Management, Policies, Video Quiz, and Chatbot) frequently introduce localized styling, custom background painters (`_DotPatternPainter`, `GeometricPainter`), and custom container decorations.
5. **Theme Mode**: The application runs exclusively in **Light Theme** (`ColorScheme.light`, `useMaterial3: false`). Dark mode is not implemented; status bar icons and system overlays default to dark (`SystemUiOverlayStyle.dark`).

---

## Section 2: Complete Color Palette

The table below lists all visual color tokens extracted directly from the codebase.

| Property | Color Name | Hex Value | RGB Value | Usage | Source |
|---|---|---|---|---|---|
| Primary Brand | `brandPrimary` / `kPrimaryColor` / `primary` / `primaryPink` / `purple` | `#053459` | `rgb(5, 52, 89)` | Primary brand color, app bar foreground, active navigation, focus rings, table headers | `lib/common/themes/app_colors.dart:44` |
| Primary Dark | `brandPrimaryDark` / `darkPink` / `drawerBg` | `#032338` | `rgb(3, 35, 56)` | High-emphasis hover/pressed state, drawer header gradient end | `lib/common/themes/app_colors.dart:47` |
| Primary Light | `brandPrimaryLight` | `#1B4E7D` | `rgb(27, 78, 125)` | Gradients, hover states | `lib/common/themes/app_colors.dart:50` |
| Primary Surface | `brandPrimarySurface` / `primary20` / `kPrimaryLightColor` / `pink` | `#E8EFF5` | `rgb(232, 239, 245)` | Selected list tile background, chip selected state, soft badges | `lib/common/themes/app_colors.dart:53` |
| Secondary Brand | `brandSecondary` / `secondary` / `mediumPink` / `semanticInfo` | `#5899CC` | `rgb(88, 153, 204)` | Steel blue accent, secondary actions, chart series 2, snack bar actions | `lib/common/themes/app_colors.dart:57` |
| Secondary Dark | `brandSecondaryDark` | `#3F7EAF` | `rgb(63, 126, 175)` | Pressed variant of secondary brand | `lib/common/themes/app_colors.dart:60` |
| Secondary Surface | `brandSecondarySurface` / `semanticInfoSurface` | `#E7F1F9` | `rgb(231, 241, 249)` | Text selection highlighting, secondary subtle panels | `lib/common/themes/app_colors.dart:63` |
| Brand Accent | `brandAccent` | `#39A28F` | `rgb(57, 162, 143)` | Teal accent, chart series 3, emphasis badges, subtle highlights | `lib/common/themes/app_colors.dart:66` |
| Brand Accent Surface | `brandAccentSurface` | `#E4F2EF` | `rgb(228, 242, 239)` | Subtle teal tint for chips and badges | `lib/common/themes/app_colors.dart:69` |
| Button Surface | `buttonDarkGreen` | `#006400` | `rgb(0, 100, 0)` | Universal background for Elevated, Outlined, Text, Filled, and Gradient buttons | `lib/common/themes/app_colors.dart:33` |
| Button Foreground | `buttonYellow` | `#FFD700` | `rgb(255, 215, 0)` | Universal button label and action text color across all standard buttons | `lib/common/themes/app_colors.dart:36` |
| Semantic Success | `semanticSuccess` / `success` / `green` / `paid` / `readyForPickup` | `#76A751` | `rgb(118, 167, 81)` | Positive outcome, approved items, chart series 4 | `lib/common/themes/app_colors.dart:76` |
| Success Dark Text | `semanticSuccessDark` | `#47711F` | `rgb(71, 113, 31)` | Accessible green text for light surfaces | `lib/common/themes/app_colors.dart:79` |
| Success Surface | `semanticSuccessSurface` / `lightGreen` | `#EDF5E5` | `rgb(237, 245, 229)` | Success chip background, status banner fill | `lib/common/themes/app_colors.dart:82` |
| Semantic Warning | `semanticWarning` / `orange` / `delayed` / `picked` | `#E08A00` | `rgb(224, 138, 0)` | Pending items, due soon, caution states, chart series 5 | `lib/common/themes/app_colors.dart:85` |
| Warning Dark Text | `semanticWarningDark` | `#8A5400` | `rgb(138, 84, 0)` | Accessible amber text on light backgrounds | `lib/common/themes/app_colors.dart:88` |
| Warning Surface | `semanticWarningSurface` | `#FFF4E0` | `rgb(255, 244, 224)` | Warning chip fill, warning banner background | `lib/common/themes/app_colors.dart:91` |
| Semantic Error | `semanticError` / `error` / `redTextStatusColor` / `cancelled` / `orderRejectTextColor` | `#C62828` | `rgb(198, 40, 40)` | Form errors, validation borders, overdue badges, destructive prompts | `lib/common/themes/app_colors.dart:94` |
| Error Dark Text | `semanticErrorDark` | `#9F1C1C` | `rgb(159, 28, 28)` | Accessible error text, form inline helper error messages | `lib/common/themes/app_colors.dart:97` |
| Error Surface | `semanticErrorSurface` | `#FDECEC` | `rgb(253, 236, 236)` | Error banner fill, error container tint | `lib/common/themes/app_colors.dart:100` |
| Hover Overlay | `semanticHoverOverlay` | `#14053459` | `rgba(5, 52, 89, 0.08)` | Translucent hover overlay for interactive cards and surfaces | `lib/common/themes/app_colors.dart:112` |
| App Scaffold Canvas | `neutralBackground` / `background` / `scaffoldBg` / `backgroundColor` | `#F2F2F2` | `rgb(242, 242, 242)` | Global scaffold canvas background | `lib/common/themes/app_colors.dart:119` |
| Neutral Surface | `neutralSurface` / `surface` / `cardBg` / `scaffoldColor` / `whiteColor` | `#FFFFFF` | `rgb(255, 255, 255)` | Cards, elevated surfaces, sheets, dialogs, app bars | `lib/common/themes/app_colors.dart:122` |
| Muted Surface | `neutralSurfaceMuted` / `shimmerWhiteLight` | `#F7F9FB` | `rgb(247, 249, 251)` | Table alternating stripes, chip idle background, inset groupings | `lib/common/themes/app_colors.dart:125` |
| Sunken Surface | `neutralSurfaceSunken` | `#EEF2F6` | `rgb(238, 242, 246)` | Text field input fill, linear progress track, chip disabled fill | `lib/common/themes/app_colors.dart:128` |
| Primary Body/Title Text | `neutralTextPrimary` / `primaryText` / `blackColor` / `blackTextColor` / `titleText` | `#0E2A3D` | `rgb(14, 42, 61)` | Default body typography, section titles, headers, dialog titles | `lib/common/themes/app_colors.dart:131` |
| Supporting/Icon Text | `neutralTextSecondary` / `secondaryText` / `iconColor` / `textFieldGreyColor` / `subText` | `#54697B` | `rgb(84, 105, 123)` | Subtitles, input hint/label defaults, icon color, unselected tabs | `lib/common/themes/app_colors.dart:134` |
| Disabled Text / Borders | `neutralTextDisabled` / `disabled` / `textGrayColor` / `grey40TextColor` | `#9BAAB6` | `rgb(155, 170, 182)` | Disabled inputs, scrollbar thumb, inactive icons, navigation unselected | `lib/common/themes/app_colors.dart:137` |
| Hairline Borders | `neutralBorder` / `border` / `borderColor` / `greyBorderColor` / `textFieldBorderColor` | `#D5DDE4` | `rgb(213, 221, 228)` | Text field default border, card outlines, chip borders, dividers | `lib/common/themes/app_colors.dart:140` |
| Hairline Divider | `neutralDivider` | `#E8EDF1` | `rgb(232, 237, 241)` | Subtle divider lines, card separators, tab bar dividers | `lib/common/themes/app_colors.dart:143` |
| On-Primary Contrast | `neutralOnPrimary` / `whiteTextColor` | `#FFFFFF` | `rgb(255, 255, 255)` | Icons and text rendered on top of `brandPrimary` surfaces | `lib/common/themes/app_colors.dart:146` |
| Login Background Canvas | `loginBackground` | `#032B45` | `rgb(3, 43, 69)` | Full-screen background for authentication portal | `lib/features/auth/Login/login_page.dart:44` / `app_colors.dart:20` |
| Login Primary Green | `loginPrimary` | `#086B0A` | `rgb(8, 107, 10)` | Focused border in login form, blur orb effect in login background | `lib/common/themes/app_colors.dart:21` |
| Login Accent Yellow | `loginAccent` | `#D6C42A` | `rgb(214, 196, 42)` | Selected role tab indicator label, circular progress indicator in login button | `lib/common/themes/app_colors.dart:23` |
| Login Input Surface | `loginInputSurface` | `#F0ECEC` | `rgb(240, 236, 236)` | Fill color for login inputs | `lib/features/auth/Login/components/login_form.dart:420` / `app_colors.dart:25` |
| Login Text Primary | `loginTextPrimary` | `#2C292C` | `rgb(44, 41, 44)` | Heading ("Access Portal") and input text in login form | `lib/common/themes/app_colors.dart:26` |
| Login Text Secondary | `loginTextSecondary` | `#686368` | `rgb(104, 99, 104)` | Sub-heading ("Manage your compliance") in login form | `lib/common/themes/app_colors.dart:27` |
| Login Text Muted | `loginTextMuted` | `#8A858A` | `rgb(138, 133, 138)` | Field category headers ("SYSTEM IDENTIFIER", "ENCRYPTED KEY"), icons | `lib/common/themes/app_colors.dart:28` |
| Login Border | `loginBorder` | `#D8D3D3` | `rgb(216, 211, 211)` | Input outline borders, divider line in login card | `lib/common/themes/app_colors.dart:29` |
| Login Error | `loginError` | `#C9362C` | `rgb(201, 54, 44)` | SnackBar error background on failed employee login | `lib/common/themes/app_colors.dart:30` |
| Card Soft Shadow | `shadowColor` / `cardShadow` | `#140E2A3D` | `rgba(14, 42, 61, 0.08)` | Standard card and container elevation blur shadow | `lib/common/themes/app_colors.dart:462` |
| Floating Strong Shadow | `shadowColorStrong` | `#240E2A3D` | `rgba(14, 42, 61, 0.14)` | Floating dialogs, FABs, bottom sheets | `lib/common/themes/app_colors.dart:465` |
| Brand Glow Shadow | `shadowColorBrand` | `#1F053459` | `rgba(5, 52, 89, 0.12)` | Glow beneath primary gradient buttons | `lib/common/themes/app_colors.dart:468` |
| Slate Surface (Screen Override) | Local Slate Background | `#F8FAFC` | `rgb(248, 250, 252)` | Background for Customer List, Policy List, Policy Detail, Table Headers | `lib/features/admin/customers/pages/customer_list_page.dart:61` |
| Blue-Grey Input Fill (Screen Override) | Local Search/Dropdown Fill | `#F1F5F9` | `rgb(241, 245, 249)` | Background of search inputs, company filter dropdowns, and choice chips | `lib/features/admin/customers/pages/customer_list_page.dart:128` |
| Deep Slate Header Text | Local Slate Header Text | `#1E293B` | `rgb(30, 41, 59)` | Section titles and header labels in customer portfolio & onboarding | `lib/features/auth/customer_onboarding/page/customer_onboarding_page.dart:388` |
| Medium Slate Subtitle | Local Slate Subtitle | `#475569` | `rgb(71, 85, 105)` | Department level section titles in customer dialogs | `lib/features/admin/customers/widgets/customer_add_edit_dialog.dart:377` |
| Chatbot User Message | Local Chatbot Purple | `#6F35A5` | `rgb(111, 53, 165)` | Bubble background for user messages and chip text in chatbot | `lib/features/chatbot/messages_screen.dart:44` |
| Chatbot Chip Fill | Local Chatbot Lavender | `#F1E6FF` | `rgb(241, 230, 255)` | Background for suggested quick reply action chips | `lib/features/chatbot/messages_screen.dart:84` |
| Module Icon Indigo | Local Module Indigo | `#6366F1` | `rgb(99, 102, 241)` | "Policies & Procedures" card icon on Employee Dashboard | `lib/features/dashboard/page/employee_dashbaord_page.dart:608` |
| Module Icon Sky Blue | Local Module Sky Blue | `#0EA5E9` | `rgb(14, 165, 233)` | "Visit Summary" card icon on Employee Dashboard | `lib/features/dashboard/page/employee_dashbaord_page.dart:596` |
| Module Icon Violet | Local Module Violet | `#8B5CF6` | `rgb(139, 92, 246)` | "Policy History" & "Training Videos" card icons | `lib/features/dashboard/page/employee_dashbaord_page.dart:620` |
| Module Icon Emerald | Local Module Emerald | `#10B981` | `rgb(16, 185, 129)` | "Training Results" card icon on Employee Dashboard | `lib/features/dashboard/page/employee_dashbaord_page.dart:653` |
| Module Icon Pink | Local Module Pink | `#EC4899` | `rgb(236, 72, 153)` | "Employees" directory card icon on Employee Dashboard | `lib/features/dashboard/page/employee_dashbaord_page.dart:632` |
| Module Icon Amber | Local Module Amber | `#F59E0B` | `rgb(245, 158, 11)` | "Change Password" card icon on Employee Dashboard | `lib/features/dashboard/page/employee_dashbaord_page.dart:677` |
| Module Icon Red | Local Module Red | `#EF4444` | `rgb(239, 68, 68)` | "NCR" card icon on Employee Dashboard | `lib/features/dashboard/page/employee_dashbaord_page.dart:584` |

---

## Section 3: Typography and Font System

### Font Declarations in `pubspec.yaml`
The application bundles the **OpenSans** font family through local assets:

| Declared Font Family | Asset Path | Actual Weight/Style |
|---|---|---|
| `OpenSansRegular` | `fonts/OpenSans-Regular.ttf` | Weight 400, Normal |
| `OpenSansSemiBold` | `fonts/OpenSans-SemiBold.ttf` | Weight 600, Normal |
| `OpenSansBold` | `fonts/OpenSans-Bold.ttf` | Weight 700, Normal |
| `OpenSansExtraBold` | `fonts/OpenSans-ExtraBold.ttf` | Weight 800/900, Normal |

*(Note: `OpenSans-Light.ttf` and `OpenSans-Medium.ttf` exist in `fonts/` on disk, but are not declared in `pubspec.yaml`).*

### Typography Hierarchy & Scaling

| Element | Font Family | Font Size | Font Weight | Font Style | Font Color | Letter Spacing | Source |
|---|---|---|---|---|---|---|---|
| Display Large | `OpenSansExtraBold` | 32.0 | `FontWeight.w800` | Normal | `#0E2A3D` (`neutralTextPrimary`) | -0.6 | `lib/common/themes/app_theme_data.dart:26` |
| Display Medium | `OpenSansExtraBold` | 28.0 | `FontWeight.w800` | Normal | `#0E2A3D` (`neutralTextPrimary`) | -0.5 | `lib/common/themes/app_theme_data.dart:34` |
| Display Small | `OpenSansExtraBold` | 24.0 | `FontWeight.w800` | Normal | `#0E2A3D` (`neutralTextPrimary`) | -0.4 | `lib/common/themes/app_theme_data.dart:42` |
| Headline Large | `OpenSansBold` | 24.0 | `FontWeight.w700` | Normal | `#0E2A3D` (`neutralTextPrimary`) | -0.3 | `lib/common/themes/app_theme_data.dart:51` |
| Headline Medium | `OpenSansBold` | 20.0 | `FontWeight.w700` | Normal | `#0E2A3D` (`neutralTextPrimary`) | -0.2 | `lib/common/themes/app_theme_data.dart:59` |
| Headline Small | `OpenSansBold` | 18.0 | `FontWeight.w700` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:67` |
| Title Large | `OpenSansSemiBold` | 20.0 | `FontWeight.w600` | Normal | `#0E2A3D` (`neutralTextPrimary`) | -0.2 | `lib/common/themes/app_theme_data.dart:75` |
| Title Medium | `OpenSansSemiBold` | 16.0 | `FontWeight.w600` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:83` |
| Title Small | `OpenSansSemiBold` | 14.0 | `FontWeight.w600` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:90` |
| Body Large | `OpenSansRegular` | 16.0 | `FontWeight.w400` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:98` |
| Body Medium | `OpenSansRegular` | 14.0 | `FontWeight.w400` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:105` |
| Body Small | `OpenSansRegular` | 12.0 | `FontWeight.w400` | Normal | `#54697B` (`neutralTextSecondary`) | 0.0 | `lib/common/themes/app_theme_data.dart:112` |
| Label Large | `OpenSansSemiBold` | 15.0 | `FontWeight.w600` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:120` |
| Label Medium | `OpenSansSemiBold` | 13.0 | `FontWeight.w600` | Normal | `#54697B` (`neutralTextSecondary`) | 0.0 | `lib/common/themes/app_theme_data.dart:127` |
| Label Small | `OpenSansSemiBold` | 11.0 | `FontWeight.w600` | Normal | `#54697B` (`neutralTextSecondary`) | +0.4 | `lib/common/themes/app_theme_data.dart:134` |
| Label On Primary | `OpenSansSemiBold` | 15.0 | `FontWeight.w600` | Normal | `#FFFFFF` (`neutralOnPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:143` |
| Primary Button Text | `OpenSansBold` | 15.0 | `FontWeight.w700` | Normal | `#FFD700` (`buttonYellow`) | 0.0 | `lib/common/themes/app_theme_data.dart:609` |
| App Bar Title | `OpenSansSemiBold` | 18.0 | `FontWeight.w600` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:218` |
| CommonAppBar Title | Inherited / System | 18.0 | `FontWeight.w700` | Normal | `#0E2A3D` (`neutralTextPrimary`) | -0.3 | `lib/common/widgets/common_app_bar.dart:47` |
| Input Text (Default) | `OpenSansRegular` | 14.0 | `FontWeight.w400` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:626` |
| Input Label (Default) | `OpenSansSemiBold` | 14.0 | `FontWeight.w600` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:629` |
| Input Hint | `OpenSansRegular` | 14.0 | `FontWeight.w400` | Normal | `#9BAAB6` (`neutralTextDisabled`) | 0.0 | `lib/common/themes/app_theme_data.dart:372` |
| Input Error Message | `OpenSansRegular` | 12.0 | `FontWeight.w400` | Normal | `#9F1C1C` (`semanticErrorDark`) | 0.0 | `lib/common/themes/app_theme_data.dart:375` |
| Login Heading Title | Inherited / System | 40.0 | `FontWeight.w900` | Normal | `#2C292C` (`loginTextPrimary`) | -2.0 | `lib/features/auth/Login/components/login_form.dart:214` |
| Login Field Label | Inherited / System | 9.0 | `FontWeight.w900` | Normal | `#8A858A` (`loginTextMuted`) | +2.0 | `lib/features/auth/Login/components/login_form.dart:403` |
| Role Switcher Tab Label | Inherited / System | 10.0 | `FontWeight.w900` | Normal | `#D6C42A` (active) / `0.55 White` (idle) | +0.5 | `lib/features/auth/Login/login_page.dart:294` |
| Dashboard Stat Number | Inherited / System | 32.0 | `FontWeight.w900` | Normal | `#0E2A3D` (`titleText`) | -1.0 | `lib/features/dashboard/page/admin_dashbaord_page.dart:700` |
| Dialog Title | `OpenSansBold` | 18.0 | `FontWeight.w700` | Normal | `#0E2A3D` (`neutralTextPrimary`) | 0.0 | `lib/common/themes/app_theme_data.dart:487` |

---

## Section 4: Button Theme

Every button in the application is standardized under a distinct action theme featuring **Dark Forest Green (`#006400`)** surfaces paired with **Golden Yellow (`#FFD700`)** typography.

| Button Type | Background Color | Text Color | Font Family | Font Size | Font Weight | Border Color | Border Radius | Width | Height | Disabled Style | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `ElevatedButton` (Global) | `#006400` | `#FFD700` | `OpenSansBold` | 15.0 | `FontWeight.w700` | None | 12.0 px (`radiusMd`) | Min 64 px | 48.0 px (`buttonHeight`) | Bg: `#D5DDE4`, Fg: `#9BAAB6` | `lib/common/themes/app_theme_data.dart:259-280` |
| `OutlinedButton` (Global) | `#006400` | `#FFD700` | `OpenSansBold` | 15.0 | `FontWeight.w700` | `#D5DDE4` | 12.0 px (`radiusMd`) | Min 64 px | 48.0 px (`buttonHeight`) | Fg: `#9BAAB6` | `lib/common/themes/app_theme_data.dart:281-300` |
| `TextButton` (Global) | `#006400` | `#FFD700` | `OpenSansBold` | 15.0 | `FontWeight.w700` | None | 8.0 px (`radiusSm`) | Min 0 px | 48.0 px (`minTouchTarget`) | Fg: `#9BAAB6` | `lib/common/themes/app_theme_data.dart:302-318` |
| `FilledButton` (Global) | `#006400` | `#FFD700` | `OpenSansBold` | 15.0 | `FontWeight.w700` | None | 12.0 px (`radiusMd`) | Min 64 px | 48.0 px (`buttonHeight`) | Default Material disabled | `lib/common/themes/app_theme_data.dart:319-333` |
| `IconButton` (Global) | Transparent | `#053459` (`brandPrimary`) | N/A | N/A | N/A | None | Circle/Default | 48.0 px | 48.0 px (`minTouchTarget`) | Inherited disabled | `lib/common/themes/app_theme_data.dart:334-342` |
| `FloatingActionButton` (Theme) | `#006400` | `#FFD700` | Inherited | 14.0 | Bold | None | 16.0 px (`radiusLg`) | 56.0 px | 56.0 px | Elevation: 4.0 | `lib/common/themes/app_theme_data.dart:343-352` |
| `FloatingActionButton` (Screen Overrides) | `#053459` (`brandPrimary`) | `#FFFFFF` | Inherited | 14.0 | Bold | None | Extended / Pill | Auto | 48-56 px | Disabled N/A | `lib/features/admin/customers/pages/customer_list_page.dart:72` |
| `GradientButton` (Component) | `#006400` -> `#006400` (LinearGradient) | `#FFD700` | `OpenSansBold` | 15.0 | `FontWeight.w700` | None | 12.0 px (or 16.0 px) | Infinite / Block | 56.0 px (`buttonHeightLarge`) | Opacity 0.60 green, cursor: forbidden | `lib/common/app_widget/common_gradient_button.dart:7` |

### Interaction States for Buttons
- **Hover & Focus Effects**: Standard buttons do not alter hue on hover; they utilize Material default splash (`btnRippleEffectColor = Colors.white30`) and mouse hover pointer (`SystemMouseCursors.click`).
- **GradientButton Shadow**: Active state projects a brand glow shadow: `BoxShadow(color: Color(0x1F053459), blurRadius: 20, offset: Offset(0, 5))`.
- **Loading State in Buttons**:
  - `GradientButton`: Displays a centered `CircularProgressIndicator` (stroke width 2.5, color: `#D6C42A` / `loginAccent`).
  - Dialog / Form ElevatedButtons: Displays a centered `CircularProgressIndicator` (stroke width 2.0, color: `#FFFFFF`).

---

## Section 5: Input Fields and Forms

Inputs are defined globally via `inputDecorationTheme` in `AppThemeData` and wrapped by the reusable `AppTextFieldWidget`.

### Form Element Properties

| Property | Global Theme Specification | `AppTextFieldWidget` Override | Source File |
|---|---|---|---|
| **Fill Color** | `#FFFFFF` (`neutralSurface`) | `#EEF2F6` (`neutralSurfaceSunken`) | `lib/common/app_widget/app_text_field_widget.dart:270` |
| **Filled** | `true` | `true` | `lib/common/themes/app_theme_data.dart:369` |
| **Default Text Style** | `fontSize: 14`, `height: 1.45`, `#0E2A3D` | `fontSize: 14`, `height: 1.45`, `#0E2A3D` | `lib/common/themes/app_theme_data.dart:105, 626` |
| **Hint Style** | `fontSize: 14`, `#9BAAB6` (`neutralTextDisabled`) | `fontSize: 14`, `#54697B` (`neutralTextSecondary`) | `lib/common/app_widget/app_text_field_widget.dart:326` |
| **Label Style** | `fontSize: 14`, `#54697B` (`neutralTextSecondary`) | External Label: `fontSize: 14`, `FontWeight.w600`, `#0E2A3D` | `lib/common/app_widget/app_text_field_widget.dart:148` |
| **Required Asterisk** | Not in theme | `Text('*', style: TextStyle(fontSize: 16.0, color: #C62828))` | `lib/common/app_widget/app_text_field_widget.dart:155` |
| **Default Border** | `OutlineInputBorder`, radius 12 px, color: `#D5DDE4` | `OutlineInputBorder`, radius 10 px, borderSide: `none` | `lib/common/app_widget/app_text_field_widget.dart:225` |
| **Enabled Border** | `OutlineInputBorder`, radius 12 px, color: `#D5DDE4` | `OutlineInputBorder`, radius 10 px, borderSide: `none` | `lib/common/app_widget/app_text_field_widget.dart:251` |
| **Focused Border** | `OutlineInputBorder`, radius 12 px, width: 1.5, color: `#053459` | `OutlineInputBorder`, radius 10 px, width: 1.5, color: `#053459` | `lib/common/app_widget/app_text_field_widget.dart:263` |
| **Error Border** | `OutlineInputBorder`, radius 12 px, width: 1.0, color: `#C62828` | `OutlineInputBorder`, radius 10 px, width: 1.0, color: `#C62828` | `lib/common/app_widget/app_text_field_widget.dart:233` |
| **Focused Error Border**| `OutlineInputBorder`, radius 12 px, width: 1.5, color: `#C62828` | `OutlineInputBorder`, radius 10 px, width: 1.5, color: `#C62828` | `lib/common/app_widget/app_text_field_widget.dart:240` |
| **Disabled Border** | `OutlineInputBorder`, radius 12 px, color: `#E8EDF1` | `OutlineInputBorder`, radius 10 px, borderSide: `none` | `lib/common/app_widget/app_text_field_widget.dart:247` |
| **Cursor Color** | `#053459` (`brandPrimary`) | `#053459` (`brandPrimary`) | `lib/common/themes/app_theme_data.dart:203` |
| **Prefix Icon Color** | `#9BAAB6` (`neutralTextDisabled`) | Configurable widget; defaults to `#053459` or `#8A858A` | `lib/common/themes/app_theme_data.dart:377` |
| **Suffix Icon Color** | `#54697B` (`neutralTextSecondary`) | Eye toggle icon: `#053459` (`brandPrimary`), size 24.0 | `lib/common/app_widget/app_text_field_widget.dart:317` |
| **Content Padding** | Horizontal 16.0, Vertical 12.0 | FromLTRB(10.0, 20.0, 10.0, 20.0) | `lib/common/app_widget/app_text_field_widget.dart:333` |
| **Density** | `isDense: true` | `isDense: true` | `lib/common/themes/app_theme_data.dart:371` |

### Multi-Select Dropdown Fields (`AppMultiSelectDropdownWidget`)
- **Field Container**: Height ~48 px, background `#EEF2F6`, border radius 12.0 px, border side 1.0 px `#D5DDE4` (or 1.5 px `#C62828` on validation error).
- **Prefix Icon**: `Icons.widgets_outlined`, color `#053459`, size 20.0 px.
- **Selected Tag Chips**: Background `#E8EFF5` (`brandPrimarySurface`), border `#053459`, border radius 8.0 px, padding horizontal 8 px, vertical 4 px.

---

## Section 6: Application Bars and Navigation

### Global AppBar Theme (`AppBarTheme`)
- **Background Color**: `#FFFFFF` (`neutralSurface`)
- **Foreground Color**: `#053459` (`brandPrimary`)
- **Elevation**: `0.0` (scrolled under elevation: `0.0`)
- **Surface Tint Color**: `Colors.transparent`
- **Icon Theme**: Color `#053459`, size 24 px
- **Actions Icon Theme**: Color `#053459`, size 24 px
- **Title Typography**: `OpenSansSemiBold`, size 18.0 px, weight `FontWeight.w600`, color `#0E2A3D`
- **Center Title**: `false`
- **System Overlay Style**: `SystemUiOverlayStyle.dark` (Dark status bar icons on light canvas)

### Reusable `CommonAppBar` Component
- **Container Decoration**: Background `#FFFFFF`, border radius bottom vertical 16.0 px (`radiusLg`), box shadow `[BoxShadow(color: Color(0x140E2A3D), blurRadius: 20, offset: Offset(0, 10))]`.
- **Height**: 70.0 px.
- **Title Typography**: Font size 18.0 px, `FontWeight.w700`, color `#0E2A3D` (`neutralTextPrimary`), letter spacing -0.3.
- **Center Title**: `true` by default.
- **Icon Theme**: Color `#053459` (`brandPrimary`), size 24.0 px (`iconLg`).

### Dashboard Drawer Theme & Implementations
- **Drawer Global Theme**: Background `#FFFFFF`, elevation 1.0, surface tint `Colors.transparent`.
- **Drawer Shape**: Rounded rectangle with top-right and bottom-right corners radius 30.0 px.
- **Drawer Header**:
  - Background: Solid `#053459` (`kPrimaryColor`).
  - Decorative Elements: Watermark `Icon(Icons.admin_panel_settings_rounded, size: 150, color: 0.15 White)`.
  - Profile Name: Font size 20.0 px, `FontWeight.w900`, color `#FFFFFF`, letter spacing -0.5.
  - Subtitle / Email: Font size 12.0 px, `FontWeight.w500`, color `0.60 White`.
  - Badge: Background `0.15 White`, border radius 8.0 px, text "VIEW PROFILE" (`FontWeight.w900`, size 10 px, letter spacing 1).
- **Drawer Section Header**: Font size 10.0 px, `FontWeight.w900`, color `#9BAAB6` (`neutralTextDisabled`), letter spacing 1.5.
- **Drawer Item ListTile**:
  - Container margin vertical 2.0 px.
  - Shape: Rounded rectangle border with radius 12.0 px.
  - Leading Icon: Color `#0E2A3D` (`neutralTextPrimary`), size 22.0 px.
  - Title: Font size 14.0 px, `FontWeight.w600`, color `#0E2A3D`.
  - Density: `dense: true`.

### Bottom Navigation Bar Theme (`BottomNavigationBarThemeData`)
- **Background Color**: `#FFFFFF` (`neutralSurface`)
- **Selected Item Color**: `#053459` (`brandPrimary`)
- **Unselected Item Color**: `#9BAAB6` (`neutralTextDisabled`)
- **Selected Label Style**: `OpenSansSemiBold`, size 12.0 px
- **Unselected Label Style**: `OpenSansRegular`, size 12.0 px
- **Type**: `BottomNavigationBarType.fixed`
- **Elevation**: 8.0 px

### Tab Bar Theme (`TabBarThemeData`)
- **Label Color**: `#053459` (`brandPrimary`)
- **Unselected Label Color**: `#54697B` (`neutralTextSecondary`)
- **Indicator Color**: `#053459` (`brandPrimary`)
- **Divider Color**: `#E8EDF1` (`neutralDivider`)
- **Selected Label Style**: `OpenSansSemiBold`, size 14.0 px, color `#053459`
- **Unselected Label Style**: `OpenSansSemiBold`, size 14.0 px, color `#54697B`

---

## Section 7: Cards, Containers, and Surfaces

### Global Card Theme (`CardThemeData`)
- **Background Color**: `#FFFFFF` (`neutralSurface`)
- **Surface Tint Color**: `#FFFFFF`
- **Shadow Color**: `#140E2A3D` (`shadowColor`)
- **Elevation**: `0.0` (`elevationFlat`)
- **Margin**: `EdgeInsets.zero`
- **Border Shape**: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0), side: BorderSide(color: #E8EDF1))`

### Hero and Stat Cards (Dashboards)
- **Container Fill**: `#FFFFFF`
- **Border Radius**: 24.0 px
- **Shadow**: `BoxShadow(color: [AccentColor].withValues(alpha: 0.1), blurRadius: 20, offset: Offset(0, 8))`
- **Leading Icon Badge**: 60 x 60 px, border radius 18.0 px, gradient `LinearGradient(begin: topLeft, end: bottomRight, colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)])`.
- **Value Typography**: Font size 32.0 px, `FontWeight.w900`, color `#0E2A3D`, letter spacing -1.0.
- **Label Typography**: Font size 14.0 px, `FontWeight.bold`, color `#54697B`, letter spacing 0.5.

### Glassmorphic Surfaces (Login & Customer Onboarding)
- **Container Blur**: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40))` (Login) / `20, 20` (Onboarding).
- **Background Fill**: `#FFFFFF` with alpha 0.98 (Login) / alpha 0.85 (Onboarding).
- **Border Radius**: 44.0 px.
- **Outline Border**: 1.5 px (Login: `#FFFFFF` with alpha 0.9) / 2.0 px (Onboarding: `#FFFFFF`).
- **Shadow**: `BoxShadow(color: Color(0x59032B45), blurRadius: 60, offset: Offset(0, 30))`.

---

## Section 8: Icons and Interactive Elements

### Icon Styles
- **Global Icon Theme**: Color `#54697B` (`neutralTextSecondary`), size 24.0 px.
- **Primary Icon Theme**: Color `#FFFFFF` (`neutralOnPrimary`).
- **AppBar Icon Theme**: Color `#053459` (`brandPrimary`), size 24.0 px.
- **Standard Scale**: `iconSm: 16.0`, `iconMd: 20.0`, `iconLg: 24.0`, `iconXl: 32.0`.

### Selection Controls

#### 1. Checkbox Theme (`CheckboxThemeData`)
- **Selected Fill Color**: `#053459` (`brandPrimary`).
- **Unselected Fill Color**: `Colors.transparent`.
- **Checkmark Color**: `#FFFFFF` (`neutralOnPrimary`).
- **Border Side**: `BorderSide(color: #D5DDE4, width: 1.5)`.
- **Shape**: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0))`.

#### 2. Radio Button Theme (`RadioThemeData`)
- **Selected Fill Color**: `#053459` (`brandPrimary`).
- **Unselected Fill Color**: `#D5DDE4` (`neutralBorder`).

#### 3. Switch Theme (`SwitchThemeData`)
- **Thumb Color**: `#FFFFFF` (`neutralSurface`) across all states.
- **Track Color**: Selected `#053459` (`brandPrimary`), unselected `#D5DDE4` (`neutralBorder`).
- **Track Outline Color**: Selected `#053459` (`brandPrimary`), unselected `#D5DDE4` (`neutralBorder`).

#### 4. Sliders
- **Video Player SliderTheme**:
  - `trackHeight`: 3.0 px
  - `activeTrackColor`: `Colors.red`
  - `inactiveTrackColor`: `Colors.white54`
  - `thumbColor`: `Colors.red`
  - `thumbShape`: `RoundSliderThumbShape(enabledThumbRadius: 5.0)`
  - `overlayShape`: `RoundSliderOverlayShape(overlayRadius: 10.0)`

#### 5. Progress Indicators
- **LinearProgressIndicator**: Color `#053459` (`brandPrimary`), track color `#EEF2F6` (`neutralSurfaceSunken`).
- **CircularProgressIndicator**: Color `#053459` (`brandPrimary`) globally; overridden in GradientButton with `#D6C42A` (`loginAccent`) and in dialogs with `#FFFFFF`.

---

## Section 9: Tables, Lists, and Data Display

### 1. Flutter Standard `DataTable` Implementations
- **Header Row Color**:
  - Global Version History: `WidgetStateProperty.all(Color(0xFFF8FAFC))`.
  - Training Results: `WidgetStateProperty.all(AppColors.purple.withValues(alpha: 0.1))` (`#053459` at 10% opacity).
- **Header Typography**: Font size 13.0 px, `FontWeight.bold`, color `#0E2A3D` (`titleText`).
- **Data Cell Typography**: Font size 13.0 px, `FontWeight.normal`, color `Colors.black87`.
- **Alternating Rows**:
  - Odd rows: `WidgetStateProperty.all(Color(0xFFFAFAFA))`.
  - Even rows: `WidgetStateProperty.all(Colors.white)`.
- **Table Padding & Spacing**: `horizontalMargin: 16.0`, `columnSpacing: 20.0`.

### 2. PlutoGrid Data Grid Configuration (`lib/features/superadmin/pages/excel_editor_page.dart`)
- **Selecting Mode**: `PlutoGridSelectingMode.cell`.
- **Grid Border Color**: `Colors.transparent`.
- **Column Header Typography**: Font size default, `FontWeight.bold`.

### 3. List Tiles (`ListTileThemeData`)
- **Icon Color**: `#54697B` (`neutralTextSecondary`).
- **Text Color**: `#0E2A3D` (`neutralTextPrimary`).
- **Title Style**: `titleSmall` (`OpenSansSemiBold`, size 14.0 px, color `#0E2A3D`).
- **Subtitle Style**: `bodySmall` (`OpenSansRegular`, size 12.0 px, color `#54697B`).
- **Selected Color**: `#053459` (`brandPrimary`).
- **Selected Tile Color**: `#E8EFF5` (`brandPrimarySurface`).
- **Shape**: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))`.

### 4. Interactive Charts (`fl_chart`)
- **Bar Chart Color**: `#053459` (`kPrimaryColor` / `barColor` / `dataSeries1`).
- **Chart Card Container**: Background `#FFFFFF`, border radius 24.0 px, box shadow `Color(0x0A053459)` (blur 20 px).
- **Real-Time Badge**: Background `#E8EFF5` (primary surface), text `#053459`, font size 10 px, `FontWeight.w900`.

---

## Section 10: Dialogs, Popups, and Notifications

### Global Dialog Theme (`DialogThemeData`)
- **Background Color**: `#FFFFFF` (`neutralSurface`)
- **Surface Tint Color**: `#FFFFFF`
- **Elevation**: 8.0 px (`elevationFloating`)
- **Shape**: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))` (Overridden in modern dialogs to 28.0 px or 32.0 px).
- **Title Text Style**: `headlineSmall` (`OpenSansBold`, size 18.0 px, color `#0E2A3D`).
- **Content Text Style**: `bodyMedium` (`OpenSansRegular`, size 14.0 px, color `#0E2A3D`).
- **Action Buttons**:
  - Cancel Button: `TextButton` with yellow text `#FFD700` (`buttonYellow`), `FontWeight.bold`.
  - Affirmative Button: `ElevatedButton` with background `#006400` (`buttonDarkGreen`), foreground `#FFD700` (`buttonYellow`), radius 12.0 px.

### SnackBar Theme (`SnackBarThemeData`)
- **Background Color**: `#0E2A3D` (`neutralTextPrimary`)
- **Content Text Style**: `bodyMedium` (`OpenSansRegular`, size 14.0 px, color `#FFFFFF`).
- **Action Text Color**: `#5899CC` (`brandSecondary`).
- **Behavior**: `SnackBarBehavior.floating`.
- **Elevation**: 8.0 px (`elevationFloating`).
- **Shape**: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))`.
- **Blocked User SnackBar**: Background `#C62828` (`AppColors.error`), border radius 15.0 px, white bold text.

### Popup Menu Theme (`PopupMenuThemeData`)
- **Color**: `#FFFFFF` (`neutralSurface`)
- **Surface Tint Color**: `#FFFFFF`
- **Elevation**: 4.0 px (`elevationRaised`)
- **Text Style**: `bodyMedium` (size 14.0 px, `#0E2A3D`)
- **Shape**: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))`

### Tooltip Theme (`TooltipThemeData`)
- **Decoration**: `BoxDecoration(color: Color(0xEB0E2A3D), borderRadius: BorderRadius.circular(8.0))`
- **Text Style**: `bodySmall` (size 12.0 px, color `#FFFFFF`)
- **Wait Duration**: 400 milliseconds

---

## Section 11: Gradients and Special Effects

| Effect Type | Colors & Parameters | Direction / Geometry | Usage & Source |
|---|---|---|---|
| **Main Brand Gradient** | `[#053459, #5899CC, #39A28F]` | `Alignment.topLeft` to `Alignment.bottomRight` | Brand banners, decorative fills (`app_colors.dart:428`) |
| **Primary Button Gradient** | `[#006400, #006400]` | `Alignment.centerLeft` to `Alignment.centerRight` | Solid dual-stop green gradient for `GradientButton` (`app_colors.dart:435`) |
| **Legacy Button Gradient** | `[#5899CC, #053459]` (`btnGradientStartColor` -> `btnGradientEndColor`) | Left to Right | Legacy gradient button alias (`app_colors.dart:321`) |
| **Login Ambient Mesh** | 3 dynamically interpolated stops between `#032B45` and `#032B45` | `Alignment.topLeft` to `Alignment.bottomRight` | Base background wash in login screen (`login_page.dart:108`) |
| **Liquid Sheen Reflection** | `[0.0 White, 0.3 White, 0.0 White]` | Rotated at $\frac{\pi}{4}$ (45 degrees) | Moving reflection line across active role indicator (`login_page.dart:248`) |
| **Onboarding Dynamic Gradient**| Dynamic `HSLColor.fromAHSL` shifting 360 degrees: stops $[0.0, 0.5, 1.0]$ | `Alignment.topLeft` to `Alignment.bottomRight` | Animated mesh in Customer Onboarding (`customer_onboarding_page.dart:328`) |
| **Video Player Bottom Fade** | `[Colors.black87, Colors.transparent]` | `Alignment.bottomCenter` to `Alignment.topCenter` | Video player control overlay gradient (`video_player_page.dart:250`) |
| **Soft Card BoxShadow** | `Color(0x140E2A3D)`, blur: 20 px, offset: $(0, 10)$ | Y-offset 10 px | Universal soft card shadow (`app_const.dart:104`) |
| **Floating Surface BoxShadow** | `Color(0x240E2A3D)`, blur: 30 px, offset: $(0, 15)$ | Y-offset 15 px | Elevated modals, profile cards (`app_colors.dart:465`) |
| **Brand Glow Shadow** | `Color(0x1F053459)`, blur: 20 px, offset: $(0, 5)$ | Y-offset 5 px | Shadow beneath `GradientButton` (`common_gradient_button.dart:51`) |
| **Dot Pattern Painter** | `Color(0x0D053459)` (5% opacity `#053459`), dot stroke: 3.0 px, spacing: 30 px | Uniform 2D grid matrix | Textured canvas behind customer & policy lists (`customer_list_page.dart:84`) |

---

## Section 12: Screen-Specific Styling

| Screen or Component | Property | Actual Value | Source File | Notes |
|---|---|---|---|---|
| **Login Page** | Canvas Background | `#032B45` | `login_page.dart:44` | High-tech dark navy canvas; diverges from global `#F2F2F2` scaffold background |
| **Login Role Switcher** | Outer Pill Decoration | Height 68 px, radius 34 px, fill `0.08 White`, border 1.2 px `0.20 White`, blur 30 px | `login_page.dart:170` | Custom liquid glassmorphic role tab switcher |
| **Login Role Tab Label** | Typography | Size 10 px, `FontWeight.w900`, color `#D6C42A` (active) / `0.55 White` (idle) | `login_page.dart:294` | All-caps tracking with letter spacing 0.5 |
| **Login Input Fields** | Fill Color & Padding | Fill `#F0ECEC`, vertical padding 22 px, horizontal padding 24 px | `login_form.dart:418` | Oversized input fields with radius 16.0 px and `#D8D3D3` border |
| **Customer List Page** | Scaffold Canvas | `#F8FAFC` | `customer_list_page.dart:61` | Cool slate canvas with `_DotPatternPainter` overlay |
| **Customer List Page** | Search Field Container | Height 48 px, background `#F1F5F9`, border radius 14 px | `customer_list_page.dart:128` | Borderless sunken input container |
| **Customer Card** | Card Container | Background `#FFFFFF`, radius 24 px, shadow `0.05 brandPrimary` (blur 20) | `customer_list_page.dart:406` | Custom borderless card with 60x60 avatar gradient |
| **Customer Onboarding** | Header Label | Font size 10 px, `FontWeight.w900`, letter spacing 10, color `#1E293B` | `customer_onboarding_page.dart:384` | Wide tracking header "O N B O A R D I N G" |
| **Customer Onboarding** | Mesh Background | 2 floating blur orbs: Indigo `#6366F1` (600 px) & Teal `#14B8A6` (550 px) | `customer_onboarding_page.dart:341` | Ambient orb animations with 20 px blur filter |
| **Customer Profile** | Canvas Background | `#F0F4F8` | `customer_profile_page.dart:57` | Soft blue-grey background with `GeometricPainter` animation |
| **Customer Profile** | Mosaic Metric Box | Background `0.70 White`, radius 24 px, border `1.0 White` | `customer_profile_page.dart:264` | Frosted glass metric container |
| **Employee Dashboard** | Grid Module Tiles | 9 individual role module cards with distinct hex colors (`#EF4444`, `#0EA5E9`, etc.) | `employee_dashbaord_page.dart:584` | Role-filtered action tiles with 20% opacity gradient avatars |
| **Chatbot Screen** | User Message Bubble | `#6F35A5` with white text, top-left/top-right radius 20 px, bottom-left radius 20 px, bottom-right radius 4 px | `messages_screen.dart:44` | Diverges completely from brand palette (legacy purple) |
| **Chatbot Screen** | Bot Quick Reply Chips | Background `#F1E6FF`, label style: size 12 px, `FontWeight.bold`, color `#6F35A5` | `messages_screen.dart:84` | Lavender pill buttons with deep purple text |
| **Video Player Page** | Custom Slider | Track height 3 px, active color `Colors.red`, thumb `Colors.red` (radius 5 px) | `video_player_page.dart:279` | Custom scrub bar overriding global brand colors |
| **Video Quiz Page** | Option Selection | `RadioGroup<int>` wrapping `RadioListTile<int>` with `dense: true` | `video_quiz_page.dart:197` | Custom MCQ quiz layout inside cards with radius 12 px |
| **NCR Form Page** | Status Action Buttons | Green background `#006400`, yellow text `#FFD700`, radius 20 px, elevation 2 | `ncr_form_page.dart:471` | Pill action buttons ("Mark In Progress", "Close NCR") |
| **Document Editor** | Toolbar & Editor | Embedded Word-processing toolbar (`QuillSimpleToolbar`) & white editor pane | `document_editor_page.dart:351` | Rich-text word processor layout with customer selector |
| **Audit Report Worksheet**| Table Cells | Min height 96 px, border 0.5 px `#D5DDE4`, padding 8 px | `audit_report_page.dart:981` | Matrix grid cell layout for ISO compliance worksheets |

---

## Section 13: Theme Consistency and Exceptions

### Documented Inconsistencies & Local Overrides
1. **Button Theme Enforcement**:
   - The global theme configures all buttons (`ElevatedButton`, `OutlinedButton`, `TextButton`, `FilledButton`, `FloatingActionButton`) with Forest Green (`#006400`) background and Golden Yellow (`#FFD700`) typography.
   - Screen implementations universally align with this requirement by either inheriting from `AppThemeData` or explicitly reinforcing `styleFrom(backgroundColor: AppColors.buttonDarkGreen, foregroundColor: AppColors.buttonYellow)`.
2. **FloatingActionButton Overrides**:
   - `AppThemeData` sets `floatingActionButtonTheme` to `#006400` background with `#FFD700` foreground.
   - Multiple screen implementations (e.g., `CustomerListPage`, `LocalDocumentListPage`) locally override the FAB background color using `AppColors.primary` / `AppColors.purple` (`#053459`) with a white icon.
3. **Legacy Aliases in `AppColors`**:
   - `app_colors.dart` contains extensive legacy color aliases (`primaryPink`, `darkPink`, `mediumPink`, `purple`, `pink`, `kPrimaryColor`) which were repointed to `brandPrimary` (`#053459`) or `brandPrimarySurface` (`#E8EFF5`) to preserve backwards compatibility.
   - Legacy template leftovers (`sendAgainBtnGrayColor`, `riderImageBackground`, `favoriteTileBackgroundColor`) remain declared in `app_colors.dart` but are unreferenced by live core workflows.
4. **Scaffold Background Variation**:
   - While the global `scaffoldBackgroundColor` is `#F2F2F2` (`neutralBackground`), several pages declare their own local background colors:
     - `LoginPage`: `#032B45` (`loginBackground`).
     - `CustomerListPage`: `#F8FAFC`.
     - `CustomerPolicyListPage`: `#F8FAFC`.
     - `CustomerProfilePage`: `#F0F4F8`.
     - `CustomerOnboardingPage`: `#FFFFFF` with animated dynamic HSL mesh.
5. **Chatbot Purple Palette Divergence**:
   - `messages_screen.dart` utilizes hardcoded `#6F35A5` (Deep Purple) and `#F1E6FF` (Light Lavender) for message bubbles and quick reply chips. This is an intentional standalone sub-theme for the AI intelligence assistant.
6. **Input Field Fill Variation**:
   - In `AppThemeData`, `inputDecorationTheme.fillColor` is `#FFFFFF` (`neutralSurface`).
   - In `AppTextFieldWidget`, the fill color is explicitly set to `#EEF2F6` (`neutralSurfaceSunken`) to ensure contrast against white card surfaces.
   - In `LoginForm`, inputs use `#F0ECEC` (`loginInputSurface`).
7. **Font Asset Declarations**:
   - Four OpenSans font weights are registered in `pubspec.yaml` (`Regular`, `SemiBold`, `Bold`, `ExtraBold`).
   - `fonts/OpenSans-Light.ttf` and `fonts/OpenSans-Medium.ttf` exist in the assets directory but have no active declaration in `pubspec.yaml`.

---

## Section 14: Source References

All theme definitions and specifications documented above correspond to exact code declarations:

- **Central Palette Definition**: [`lib/common/themes/app_colors.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/themes/app_colors.dart#L17-L469)
- **Central Theme Configuration**: [`lib/common/themes/app_theme_data.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/themes/app_theme_data.dart#L19-L670)
- **Design Tokens & Constants**: [`lib/common/themes/app_const.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/themes/app_const.dart#L4-L154)
- **Font String Identifiers**: [`lib/common/themes/app_strings.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/themes/app_strings.dart#L2-L7)
- **Font Assets Declaration**: [`pubspec.yaml`](file:///a:/HSA/IQ_Plus.1/pubspec.yaml#L125-L137)
- **Theme Injection Point**: [`lib/common/routes/app.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/routes/app.dart#L69)
- **Gradient Button Component**: [`lib/common/app_widget/common_gradient_button.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/app_widget/common_gradient_button.dart#L7-L90)
- **Standard Text Field Component**: [`lib/common/app_widget/app_text_field_widget.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/app_widget/app_text_field_widget.dart#L11-L345)
- **Multi-Select Dropdown Component**: [`lib/common/app_widget/app_multi_select_dropdown_widget.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/app_widget/app_multi_select_dropdown_widget.dart#L5-L280)
- **Common Rounded App Bar**: [`lib/common/widgets/common_app_bar.dart`](file:///a:/HSA/IQ_Plus.1/lib/common/widgets/common_app_bar.dart#L9-L69)
- **Login Styling & Liquid Glass**: [`lib/features/auth/Login/login_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/auth/Login/login_page.dart#L43-L389)
- **Login Form Specification**: [`lib/features/auth/Login/components/login_form.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/auth/Login/components/login_form.dart#L200-L434)
- **Customer Onboarding Styling**: [`lib/features/auth/customer_onboarding/page/customer_onboarding_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/auth/customer_onboarding/page/customer_onboarding_page.dart#L240-L448)
- **Admin Dashboard Layout**: [`lib/features/dashboard/page/admin_dashbaord_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/dashboard/page/admin_dashbaord_page.dart#L78-L750)
- **Customer List & Cards**: [`lib/features/admin/customers/pages/customer_list_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/admin/customers/pages/customer_list_page.dart#L60-L500)
- **Customer Add/Edit Dialog**: [`lib/features/admin/customers/widgets/customer_add_edit_dialog.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/admin/customers/widgets/customer_add_edit_dialog.dart#L150-L387)
- **Customer Profile Portfolio**: [`lib/features/admin/customers/pages/customer_profile_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/admin/customers/pages/customer_profile_page.dart#L56-L320)
- **Policy List & Filter Chips**: [`lib/features/customer_policies/pages/customer_policy_list_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/customer_policies/pages/customer_policy_list_page.dart#L260-L560)
- **Policy Detail & Dot Canvas**: [`lib/features/customer_policies/pages/customer_policy_detail_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/customer_policies/pages/customer_policy_detail_page.dart#L130-L450)
- **Video Quiz Option Tiles**: [`lib/features/videos/pages/video_quiz_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/videos/pages/video_quiz_page.dart#L185-L215)
- **Video Player Controls**: [`lib/features/videos/pages/video_player_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/videos/pages/video_player_page.dart#L240-L300)
- **Chatbot Message Bubbles**: [`lib/features/chatbot/messages_screen.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/chatbot/messages_screen.dart#L38-L94)
- **Audit Report Worksheet Matrix**: [`lib/features/dashboard/page/audit_report_page.dart`](file:///a:/HSA/IQ_Plus.1/lib/features/dashboard/page/audit_report_page.dart#L13-L21)

---

## Section 15: Reusable Theme Reference

A quick-reference cheat sheet for developers applying the theme to new screens and components.

### 1. Palette Core
```dart
AppColors.brandPrimary         // #053459 (Navy - Header, Active Nav, Borders)
AppColors.brandSecondary       // #5899CC (Steel Blue - Accents, Secondary Links)
AppColors.brandAccent          // #39A28F (Teal - Highlights, Third Series)
AppColors.buttonDarkGreen      // #006400 (Forest Green - All Button Surfaces)
AppColors.buttonYellow         // #FFD700 (Golden Yellow - All Button Labels)
AppColors.neutralBackground    // #F2F2F2 (Canvas Background)
AppColors.neutralSurface       // #FFFFFF (Card, Sheet, Dialog Fill)
AppColors.neutralSurfaceSunken // #EEF2F6 (Text Field Input Fill)
AppColors.neutralTextPrimary   // #0E2A3D (Primary Headings & Body Text)
AppColors.neutralTextSecondary // #54697B (Muted Text, Labels, Hints)
AppColors.neutralBorder        // #D5DDE4 (Hairline Outlines)
AppColors.semanticSuccess      // #76A751 (Approved / Completed / Passed)
AppColors.semanticWarning      // #E08A00 (Pending / Due Soon / Amber)
AppColors.semanticError        // #C62828 (Overdue / Errors / Rejected)
```

### 2. Standard Button Snippet
```dart
// Primary Action Button (Gradient)
GradientButton(
  text: "SAVE CHANGES",
  onPressed: () => _handleSave(),
  isLoading: state is LoadingState,
  radiusSize: AppConst.radiusMd, // 12.0
)

// Standard ElevatedButton
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.buttonDarkGreen, // #006400
    foregroundColor: AppColors.buttonYellow,    // #FFD700
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  onPressed: _onSubmit,
  child: const Text("SUBMIT", style: TextStyle(fontWeight: FontWeight.bold)),
)

// Standard Dialog Action TextButton
TextButton(
  onPressed: () => Navigator.pop(context),
  child: const Text(
    "CANCEL",
    style: TextStyle(color: AppColors.buttonYellow, fontWeight: FontWeight.bold),
  ),
)
```

### 3. Standard Text Input Snippet
```dart
AppTextFieldWidget(
  labelText: "Company Name",
  hintText: "Enter official organization name",
  textFieldController: companyController,
  isRequired: true,
  prefixIconWidget: const Icon(Icons.business_rounded, color: AppColors.brandPrimary),
)
```

### 4. Standard Card Snippet
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.neutralSurface, // #FFFFFF
    borderRadius: BorderRadius.circular(AppConst.radiusLg), // 16.0
    border: Border.all(color: AppColors.neutralDivider),     // #E8EDF1
    boxShadow: AppConst.cardShadow,                         // 0x140E2A3D blur 20
  ),
  child: Padding(
    padding: const EdgeInsets.all(AppConst.spaceLg),        // 16.0
    child: contentWidget,
  ),
)
```

### 5. Standard Screen App Bar Snippet
```dart
// Rounded Floating Header Bar
appBar: const CommonAppBar(title: "My Feature Module"),
```
