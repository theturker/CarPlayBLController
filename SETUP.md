# BLController - Kotlin Multiplatform iOS BLE LED Controller

Bu proje, ELK-BLEDOM / Lotus Lantern uyumlu RGB LED kontrolörlerini yönetmek için Kotlin Multiplatform ve SwiftUI kullanarak geliştirilmiş bir iOS uygulamasıdır.

## Proje Yapısı

```
BLController/
├── composeApp/                          # KMP Shared Module
│   └── src/
│       └── commonMain/kotlin/
│           └── com/alperenturker/blcontroller/
│               ├── LedColor.kt                    # Renk enum'u
│               ├── RgbColor.kt                    # RGB renk data class'ı
│               ├── LedColorMapper.kt              # Renk mapping fonksiyonları
│               ├── LedCommandBuilder.kt           # BLE komut builder'ları
│               ├── FavoritesRepository.kt         # Favori renkler repository
│               └── SharedLedController.kt         # Ana controller (KMP'den Swift'e bridge)
│
├── iosApp/iosApp/                      # iOS SwiftUI App
│   ├── LedBleManager.swift             # CoreBluetooth BLE Manager
│   ├── DeviceSelectionView.swift       # Cihaz seçim ekranı
│   ├── MainControlView.swift            # Ana kontrol ekranı
│   ├── ContentView.swift                # Ana view router
│   ├── iOSApp.swift                     # App entry point
│   ├── KotlinExtensions.swift           # Kotlin-Swift bridge extensions
│   ├── AppIntents/                      # Siri App Intents
│   │   ├── SetLedColorIntent.swift
│   │   ├── SetLedBrightnessIntent.swift
│   │   ├── SetLedPowerIntent.swift
│   │   └── AppShortcuts.swift
│   └── Info.plist                       # BLE izinleri
│
└── build.gradle.kts                     # Root build config (iOS only)
```

## Kurulum

### 1. Gereksinimler

- Xcode 15.0+
- iOS 17.0+ (minimum deployment target)
- Kotlin Multiplatform plugin
- Gradle 8.0+

### 2. KMP Framework'ü Xcode'a Ekleme

Xcode projesi zaten KMP framework'ünü otomatik olarak derleyecek şekilde yapılandırılmıştır. Build script şu komutu çalıştırır:

```bash
./gradlew :composeApp:embedAndSignAppleFrameworkForXcode
```

**Manuel Ekleme (Gerekirse):**

1. Xcode'da projeyi açın: `iosApp/iosApp.xcodeproj`
2. Build Settings'te "Framework Search Paths" kontrol edin
3. Framework otomatik olarak `composeApp/build/xcode-frameworks/` altında oluşturulur
4. Framework adı: `SharedLedController.framework`

### 3. Build ve Çalıştırma

**Terminal'den:**
```bash
# KMP framework'ü derle
./gradlew :composeApp:embedAndSignAppleFrameworkForXcode

# Xcode'da aç
open iosApp/iosApp.xcodeproj
```

**Xcode'dan:**
1. Projeyi açın
2. Scheme'i seçin (iosApp)
3. Simulator veya gerçek cihaz seçin
4. Run (⌘R)

## KMP ↔ Swift Bridge Kullanımı

### Kotlin'den Swift'e Çağrı Örnekleri

```swift
import SharedLedController

// Renk komutu al
let colorBytes = SharedLedController.getColorCommandBytes(
    r: KotlinInt(value: 255),
    g: KotlinInt(value: 0),
    b: KotlinInt(value: 0)
)
let data = colorBytes.toData()  // KotlinByteArray -> Data

// Parlaklık komutu
let brightnessBytes = SharedLedController.getBrightnessCommandBytes(
    brightness: KotlinInt(value: 128)
)

// Favori ekle
SharedLedController.addFavorite(
    r: KotlinInt(value: 255),
    g: KotlinInt(value: 0),
    b: KotlinInt(value: 0)
)

// Favorileri al
let favorites = SharedLedController.getFavorites()
// favorites: KotlinList<KotlinTriple<KotlinInt, KotlinInt, KotlinInt>>
```

### Kotlin Tip Dönüşümleri

- `KotlinInt` → Swift `Int`: `Int(truncating: kotlinInt)`
- `KotlinByteArray` → Swift `Data`: `kotlinBytes.toData()` (extension kullanın)
- `KotlinBoolean` → Swift `Bool`: `kotlinBool.boolValue`
- `KotlinTriple` → Swift tuple: `(first, second, third)` property'leri kullanın

## BLE Protokol

### Service ve Characteristic UUIDs

- **Service UUID**: `0000fff0-0000-1000-8000-00805f9b34fb`
- **Write Characteristic UUID**: `0000fff3-0000-1000-8000-00805f9b34fb`

### Komut Formatları

**Renk Komutu (9 byte):**
```
[0x7E, 0x00, 0x05, 0x03, R, G, B, 0x00, 0xEF]
```

**Parlaklık Komutu (9 byte):**
```
[0x7E, 0x00, 0x01, brightness, brightness, 0x00, 0x00, 0x00, 0xEF]
```

**Açma Komutu (9 byte):**
```
[0x7E, 0x04, 0x04, 0xF0, 0x00, 0x01, 0xFF, 0x00, 0xEF]
```

**Kapama Komutu (9 byte):**
```
[0x7E, 0x04, 0x04, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xEF]
```

## Siri Komutları (App Intents)

Uygulama aşağıdaki Türkçe Siri komutlarını destekler:

- "Ambiyansı kırmızı yap"
- "Ambiyansı mavi yap"
- "Ambiyansı yeşil yap"
- "Ambiyansı mor yap"
- "Ambiyansı beyaz yap"
- "Ambiyansı aç"
- "Ambiyansı kapat"
- "Ambiyans parlaklığını artır"
- "Ambiyans parlaklığını azalt"
- "Ambiyansı en parlak yap"

**Not:** İlk kullanımda Siri'ye izin vermeniz gerekebilir. Settings > Siri & Search > App Shortcuts

## Özellikler

✅ BLE cihaz tarama ve bağlantı
✅ Son cihaza otomatik yeniden bağlanma
✅ Renk seçici (ColorPicker)
✅ Hızlı renk butonları (Kırmızı, Mavi, Yeşil, Mor, Beyaz)
✅ Favori renkler (en fazla 5)
✅ Parlaklık kontrolü (0-100%)
✅ Açma/Kapama kontrolü
✅ Siri entegrasyonu (App Intents)
✅ Türkçe arayüz

## Sorun Giderme

### Framework Bulunamıyor Hatası

```bash
# Framework'ü manuel derle
cd /path/to/BLController
./gradlew :composeApp:embedAndSignAppleFrameworkForXcode

# Xcode'da Clean Build Folder (⌘⇧K)
# Sonra tekrar build (⌘B)
```

### BLE İzinleri

Info.plist'te şu izinler mevcut:
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`

İlk çalıştırmada kullanıcıdan izin istenir.

### Cihaz Bulunamıyor

1. LED kontrolörün açık olduğundan emin olun
2. Bluetooth'un açık olduğundan emin olun
3. Cihaz adında "ELK-BLEDOM", "Lotus", "LED", "BLEDOM" veya "BLE" geçen cihazlar otomatik bulunur
4. Manuel tarama için "Cihazları Tara" butonuna basın

## Geliştirme Notları

- KMP modülü sadece business logic içerir (BLE API'leri yok)
- Tüm BLE işlemleri Swift tarafında (CoreBluetooth)
- KMP'den sadece komut byte array'leri alınır
- Favori renkler memory'de tutulur (persistent storage eklenebilir)

## Lisans

Bu proje örnek amaçlıdır.


