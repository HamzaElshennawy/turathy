# Turathy Mobile (Flutter)

Customer app for **التراث الجميل** — package `com.deepblue.turathi`.

## Path

`mobile_app/Mobile/` (this folder). Production API: `https://api.alturathaljmeel.com.sa/`

## Price & Item Number

| UI | Field |
|----|--------|
| List / opening price | `bidPrice` (starting) |
| Reserve | `minBidPrice` — hidden on public API; not for visitor list |
| بند رقم | `lot_number` |

Helpers: `lib/src/core/helper/auction_price_helpers.dart`  
Skill: `.cursor/skills/turathy-mobile-flutter/SKILL.md`

## Setup (this machine — E: drive)

Paths live on **E:** — see [`../DEV_ENV_E_DRIVE.md`](../DEV_ENV_E_DRIVE.md).

```properties
sdk.dir=E:\\dev\\Android\\Sdk
flutter.sdk=E:\\dev\\flutter
```

```powershell
# one-time user env
..\..\scripts\setup-mobile-paths-e.ps1
flutter pub get
flutter test
flutter run
```

## Architecture notes

- REST via Dio (`end_points.dart`)
- Live room via Socket.IO (`socket_config.dart` / `socket_providers.dart`)
- Bid increment = client ladder (`_getIncrementForPrice`), not a product DB field
