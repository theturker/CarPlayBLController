package com.alperenturker.blcontroller

object SharedLedController {
    private val favoritesRepository = FavoritesRepository()
    
    /**
     * Get color command bytes for a LedColor
     */
    fun getColorCommandBytes(color: LedColor): ByteArray {
        val rgb = LedColorMapper.mapToRgb(color)
        return LedCommandBuilder.buildColorCommand(rgb)
    }
    
    /**
     * Get color command bytes for custom RGB values
     */
    fun getColorCommandBytes(r: Int, g: Int, b: Int): ByteArray {
        return LedCommandBuilder.buildColorCommand(r, g, b)
    }
    
    /**
     * Get brightness command bytes
     */
    fun getBrightnessCommandBytes(brightness: Int): ByteArray {
        return LedCommandBuilder.buildBrightnessCommand(brightness)
    }
    
    /**
     * Get power ON command bytes
     */
    fun getPowerOnCommandBytes(): ByteArray {
        return LedCommandBuilder.buildPowerOnCommand()
    }
    
    /**
     * Get power OFF command bytes
     */
    fun getPowerOffCommandBytes(): ByteArray {
        return LedCommandBuilder.buildPowerOffCommand()
    }
    
    /**
     * Add a favorite color
     */
    fun addFavorite(r: Int, g: Int, b: Int): Boolean {
        return favoritesRepository.addFavorite(RgbColor(r, g, b))
    }
    
    /**
     * Remove a favorite color
     */
    fun removeFavorite(r: Int, g: Int, b: Int): Boolean {
        return favoritesRepository.removeFavorite(RgbColor(r, g, b))
    }
    
    /**
     * Get all favorite colors
     */
    fun getFavorites(): List<Triple<Int, Int, Int>> {
        return favoritesRepository.getFavorites().map { Triple(it.r, it.g, it.b) }
    }
    
    /**
     * Check if can add more favorites
     */
    fun canAddMoreFavorites(): Boolean {
        return favoritesRepository.canAddMore()
    }
}


