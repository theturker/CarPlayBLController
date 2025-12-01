import AppIntents

struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetLedRedIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını kırmızı yap",
                "ambiyans ışığını kırmızı yap \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: SetLedBlueIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını mavi yap",
                "ambiyans ışığını mavi yap \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: SetLedGreenIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını yeşil yap",
                "ambiyans ışığını yeşil yap \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: SetLedPurpleIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını mor yap",
                "ambiyans ışığını mor yap \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: SetLedWhiteIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını beyaz yap",
                "ambiyans ışığını beyaz yap \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: TurnOnLedIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını aç",
                "ambiyans ışığını aç \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: TurnOffLedIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını kapat",
                "ambiyans ışığını kapat \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: IncreaseBrightnessIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığının parlaklığını artır",
                "ambiyans ışığının parlaklığını artır \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: DecreaseBrightnessIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığının parlaklığını azalt",
                "ambiyans ışığının parlaklığını azalt \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: SetMaxBrightnessIntent(),
            phrases: [
                "\(.applicationName) ambiyans ışığını en parlak yap",
                "ambiyans ışığını en parlak yap \(.applicationName)"
            ]
        )
    }
    
    static var shortcutTileColor: ShortcutTileColor = .blue
}

