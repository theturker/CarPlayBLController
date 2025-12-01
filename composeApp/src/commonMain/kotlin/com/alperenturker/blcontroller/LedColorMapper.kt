package com.alperenturker.blcontroller

object LedColorMapper {
    fun mapToRgb(color: LedColor): RgbColor {
        return when (color) {
            LedColor.RED -> RgbColor(255, 0, 0)
            LedColor.BLUE -> RgbColor(0, 0, 255)
            LedColor.GREEN -> RgbColor(0, 255, 0)
            LedColor.PURPLE -> RgbColor(255, 0, 255)
            LedColor.WHITE -> RgbColor(255, 255, 255)
            LedColor.CUSTOM -> RgbColor(255, 255, 255) // Default to white for custom
        }
    }
}


