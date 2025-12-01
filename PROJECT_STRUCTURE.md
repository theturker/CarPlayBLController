# BLController - Tam Proje Yapısı

Bu dosya, projenin tüm dosyalarını ve yapısını gösterir.

## 📁 Dosya Ağacı

```
BLController/
│
├── build.gradle.kts                    # Root build config (iOS only)
├── settings.gradle.kts                 # Gradle settings
├── gradle.properties                   # Gradle properties
├── gradle/libs.versions.toml          # Dependency versions
│
├── composeApp/                         # KMP Shared Module
│   ├── build.gradle.kts               # KMP module build config
│   └── src/
│       └── commonMain/kotlin/com/alperenturker/blcontroller/
│           ├── LedColor.kt            # ✅ Renk enum (RED, BLUE, GREEN, PURPLE, WHITE, CUSTOM)
│           ├── RgbColor.kt            # ✅ RGB renk data class
│           ├── LedColorMapper.kt      # ✅ LedColor -> RgbColor mapping
│           ├── LedCommandBuilder.kt   # ✅ BLE komut builder'ları
│           ├── FavoritesRepository.kt # ✅ Favori renkler repository (max 5)
│           └── SharedLedController.kt # ✅ Ana controller (Swift bridge)
│
└── iosApp/                             # iOS SwiftUI App
    ├── iosApp/
    │   ├── iOSApp.swift                # ✅ App entry point
    │   ├── ContentView.swift           # ✅ Ana view router
    │   ├── LedBleManager.swift         # ✅ CoreBluetooth BLE Manager (singleton)
    │   ├── DeviceSelectionView.swift   # ✅ Cihaz seçim ekranı
    │   ├── MainControlView.swift        # ✅ Ana kontrol ekranı
    │   ├── KotlinExtensions.swift      # ✅ Kotlin-Swift bridge extensions
    │   ├── Info.plist                  # ✅ BLE izinleri
    │   │
    │   └── AppIntents/                  # ✅ Siri App Intents
    │       ├── SetLedColorIntent.swift      # Renk ayarlama intent
    │       ├── SetLedBrightnessIntent.swift # Parlaklık intent'leri
    │       ├── SetLedPowerIntent.swift      # Açma/kapama intent'leri
    │       └── AppShortcuts.swift           # Siri shortcut tanımları
    │
    └── iosApp.xcodeproj/               # Xcode project
```

## 🔑 Ana Bileşenler

### KMP Shared Module (`composeApp/`)

**LedColor.kt**
- Enum: RED, BLUE, GREEN, PURPLE, WHITE, CUSTOM

**RgbColor.kt**
- Data class: `RgbColor(r: Int, g: Int, b: Int)`
- Validation: 0-255 aralığı

**LedCommandBuilder.kt**
- `buildColorCommand(r, g, b): ByteArray` - 9 byte renk komutu
- `buildBrightnessCommand(brightness): ByteArray` - 9 byte parlaklık komutu
- `buildPowerOnCommand(): ByteArray` - 9 byte açma komutu
- `buildPowerOffCommand(): ByteArray` - 9 byte kapama komutu

**FavoritesRepository.kt**
- `addFavorite(color): Boolean` - Favori ekle (max 5)
- `removeFavorite(color): Boolean` - Favori kaldır
- `getFavorites(): List<RgbColor>` - Tüm favorileri al

**SharedLedController.kt**
- Swift'ten çağrılabilir public API
- Tüm komut builder'ları expose eder
- Favori yönetimi API'leri

### iOS App (`iosApp/iosApp/`)

**LedBleManager.swift**
- Singleton: `LedBleManager.shared`
- CoreBluetooth yönetimi
- Cihaz tarama ve bağlantı
- Son cihaza otomatik yeniden bağlanma
- `setColor(r, g, b)`
- `setBrightness(level: 0-100)`
- `powerOn()` / `powerOff()`
- Published properties: `isConnected`, `currentColor`, `currentBrightness`

**DeviceSelectionView.swift**
- BLE cihaz listesi
- Tarama başlatma/durdurma
- Cihaz seçme ve bağlanma

**MainControlView.swift**
- Renk seçici (ColorPicker)
- Hızlı renk butonları
- Favori renkler bölümü
- Parlaklık slider (0-100%)
- Açma/kapama butonu
- Bağlantı durumu göstergesi

**AppIntents/**
- `SetLedColorIntent` - "Ambiyansı kırmızı yap" gibi komutlar
- `SetLedBrightnessIntent` - Parlaklık seviyesi ayarlama
- `IncreaseBrightnessIntent` - Parlaklığı artır
- `DecreaseBrightnessIntent` - Parlaklığı azalt
- `SetMaxBrightnessIntent` - Maksimum parlaklık
- `TurnOnLedIntent` - "Ambiyansı aç"
- `TurnOffLedIntent` - "Ambiyansı kapat"
- `AppShortcuts` - Türkçe Siri komutları

## 🔌 KMP ↔ Swift Bridge

### Kotlin'den Swift'e Çağrı

```swift
import SharedLedController

// Komut byte array'leri al
let colorBytes = SharedLedController.getColorCommandBytes(
    r: KotlinInt(value: 255),
    g: KotlinInt(value: 0),
    b: KotlinInt(value: 0)
)
let data = colorBytes.toData()  // KotlinByteArray -> Data

// Favori yönetimi
SharedLedController.addFavorite(
    r: KotlinInt(value: 255),
    g: KotlinInt(value: 0),
    b: KotlinInt(value: 0)
)

let favorites = SharedLedController.getFavorites()
// KotlinList<KotlinTriple<KotlinInt, KotlinInt, KotlinInt>>
```

### Tip Dönüşümleri

- **KotlinInt → Swift Int**: `Int(truncating: kotlinInt)`
- **KotlinByteArray → Data**: `kotlinBytes.toData()` (KotlinExtensions.swift)
- **KotlinBoolean → Bool**: `kotlinBool.boolValue`
- **KotlinTriple**: `triple.first`, `triple.second`, `triple.third` property'leri

## 📱 BLE Protokol

### UUIDs
- **Service**: `0000fff0-0000-1000-8000-00805f9b34fb`
- **Write Characteristic**: `0000fff3-0000-1000-8000-00805f9b34fb`

### Komut Formatları (9 byte)

**Renk**: `[0x7E, 0x00, 0x05, 0x03, R, G, B, 0x00, 0xEF]`
**Parlaklık**: `[0x7E, 0x00, 0x01, brightness, brightness, 0x00, 0x00, 0x00, 0xEF]`
**Açma**: `[0x7E, 0x04, 0x04, 0xF0, 0x00, 0x01, 0xFF, 0x00, 0xEF]`
**Kapama**: `[0x7E, 0x04, 0x04, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xEF]`

## 🎤 Siri Komutları

Türkçe komutlar:
- "Ambiyansı kırmızı yap" / "mavi yap" / "yeşil yap" / "mor yap" / "beyaz yap"
- "Ambiyansı aç" / "kapat"
- "Ambiyans parlaklığını artır" / "azalt"
- "Ambiyansı en parlak yap"

## ✅ Özellikler

- ✅ BLE cihaz tarama ve bağlantı
- ✅ Son cihaza otomatik yeniden bağlanma
- ✅ Renk seçici (ColorPicker)
- ✅ Hızlı renk butonları
- ✅ Favori renkler (max 5)
- ✅ Parlaklık kontrolü (0-100%)
- ✅ Açma/kapama kontrolü
- ✅ Siri entegrasyonu (App Intents)
- ✅ Türkçe arayüz

## 🚀 Build ve Çalıştırma

```bash
# KMP framework'ü derle
./gradlew :composeApp:embedAndSignAppleFrameworkForXcode

# Xcode'da aç
open iosApp/iosApp.xcodeproj
```

Xcode'da:
1. Scheme: iosApp
2. Target: iOS 17.0+
3. Run (⌘R)

## 📝 Notlar

- KMP modülü sadece business logic içerir (BLE API'leri yok)
- Tüm BLE işlemleri Swift tarafında (CoreBluetooth)
- Framework adı: `SharedLedController.framework`
- Build script otomatik olarak framework'ü derler ve imzalar


