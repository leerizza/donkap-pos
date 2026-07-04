# Donkap POS — CLAUDE.md

## Project Overview
Flutter offline-first POS (Point of Sale) app for small-medium retail shops.
Target platform: Android (primary). iOS secondary.
Package name: `billing_app`

## Architecture
**Clean Architecture + Feature-First layout:**
```
lib/
├── core/              # Shared utilities, theme, DI, Hive init
│   ├── data/          # HiveDatabase (all box registrations here)
│   ├── error/         # Failure (abstract), CacheFailure
│   ├── theme/         # AppTheme
│   ├── usecase/       # UseCase<Result,Params> base + NoParams
│   ├── utils/         # AppValidators, PrinterHelper, AppFormatters
│   └── widgets/       # PrimaryButton, InputLabel
└── features/
    ├── billing/       # Cart, checkout, scanner — BillingBloc
    ├── product/       # CRUD inventory — ProductBloc
    ├── transaction/   # Saved receipts, sales report — TransactionBloc
    ├── shop/          # Shop info for receipts — ShopBloc
    └── settings/      # Bluetooth printer — PrinterBloc
```

Each feature: `domain/` (entities, repos, usecases) → `data/` (models, repo_impl) → `presentation/` (bloc, pages).

## Key Rules

### Code
- No comments unless the WHY is non-obvious
- No error handling for impossible scenarios
- No `stock < 0` — always clamp: `(stock - qty).clamp(0, maxInt)`
- Currency display: `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)` — never `toStringAsFixed(2)` for display
- Low-stock threshold: `AppConstants.lowStockThreshold` (= 5) — never hardcode the literal

### Hive TypeIds (DO NOT REUSE)
| typeId | Class |
|--------|-------|
| 0 | ProductModel |
| 1 | ShopModel |
| 2 | TransactionItemModel |
| 3 | TransactionModel |
| 4 | StockAdjustmentModel |

Next available typeId: **5**

### After adding/changing Hive models
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Validators
- Price → `AppValidators.price`
- Stock → `AppValidators.stockCount`  (rejects non-integer and negative)
- Required text → `AppValidators.required('message')`

### Service Locator (get_it)
- Blocs → `registerFactory`
- UseCases & Repositories → `registerLazySingleton`
- Root BlocProviders in `main.dart` consume the factory instance; never call `sl<XBloc>()` from within a page

### Routing (go_router)
All routes in `lib/config/routes/app_routes.dart`. Current routes:
- `/` → HomePage (scanner + cart)
- `/checkout` → CheckoutPage
- `/scanner` → ScannerPage (shared between billing & products)
- `/products` → ProductListPage
- `/products/add` → AddProductPage
- `/products/edit/:id` → EditProductPage (requires `extra: Product`)
- `/shop` → ShopDetailsPage
- `/settings` → SettingsPage
- `/report` → SalesReportPage

### TransactionBloc save flow
After `SaveTransactionEvent` succeeds, bloc dispatches `LoadTransactionsEvent` to keep `TransactionLoaded` state alive for `SalesReportPage`.

## Build & Deploy
```bash
# Generate Hive adapters (run after model changes)
dart run build_runner build --delete-conflicting-outputs

# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Install to connected Android device
flutter install -d <device-id> --release

# List connected devices
flutter devices
```

## Dependencies (key)
- State: `flutter_bloc`
- DI: `get_it`
- DB: `hive`, `hive_flutter`
- Router: `go_router`
- Scanner: `mobile_scanner`
- Printer: `print_bluetooth_thermal`
- Haptic: `vibration`
- QR display: `pretty_qr_code`
- Formatting: `intl`
- IDs: `uuid`
