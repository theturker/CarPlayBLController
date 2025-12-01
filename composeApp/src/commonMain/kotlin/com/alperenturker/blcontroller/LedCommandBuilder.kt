package com.alperenturker.blcontroller

object LedCommandBuilder {
    /**
     * Build color command (9 bytes)
     * Format: [0x7E, 0x00, 0x05, 0x03, R, G, B, 0x00, 0xEF]
     */
    fun buildColorCommand(r: Int, g: Int, b: Int): ByteArray {
        require(r in 0..255) { "Red must be between 0 and 255" }
        require(g in 0..255) { "Green must be between 0 and 255" }
        require(b in 0..255) { "Blue must be between 0 and 255" }
        
        return byteArrayOf(
            0x7E.toByte(),
            0x00.toByte(),
            0x05.toByte(),
            0x03.toByte(),
            r.toByte(),
            g.toByte(),
            b.toByte(),
            0x00.toByte(),
            0xEF.toByte()
        )
    }
    
    /**
     * Build color command from RgbColor
     */
    fun buildColorCommand(rgb: RgbColor): ByteArray {
        return buildColorCommand(rgb.r, rgb.g, rgb.b)
    }
    
    /**
     * Build brightness command (9 bytes)
     * Format: [0x7E, 0x00, 0x01, brightness, brightness, 0x00, 0x00, 0x00, 0xEF]
     */
    fun buildBrightnessCommand(brightness: Int): ByteArray {
        require(brightness in 0..255) { "Brightness must be between 0 and 255" }
        
        return byteArrayOf(
            0x7E.toByte(),
            0x00.toByte(),
            0x01.toByte(),
            brightness.toByte(),
            brightness.toByte(),
            0x00.toByte(),
            0x00.toByte(),
            0x00.toByte(),
            0xEF.toByte()
        )
    }
    
    /**
     * Build power ON command (9 bytes)
     * Format: [0x7E, 0x04, 0x04, 0xF0, 0x00, 0x01, 0xFF, 0x00, 0xEF]
     */
    fun buildPowerOnCommand(): ByteArray {
        return byteArrayOf(
            0x7E.toByte(),
            0x04.toByte(),
            0x04.toByte(),
            0xF0.toByte(),
            0x00.toByte(),
            0x01.toByte(),
            0xFF.toByte(),
            0x00.toByte(),
            0xEF.toByte()
        )
    }
    
    /**
     * Build power OFF command (9 bytes)
     * Format: [0x7E, 0x04, 0x04, 0x00, 0x00, 0x00, 0xFF, 0x00, 0xEF]
     */
    fun buildPowerOffCommand(): ByteArray {
        return byteArrayOf(
            0x7E.toByte(),
            0x04.toByte(),
            0x04.toByte(),
            0x00.toByte(),
            0x00.toByte(),
            0x00.toByte(),
            0xFF.toByte(),
            0x00.toByte(),
            0xEF.toByte()
        )
    }
}


