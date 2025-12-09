package com.alperenturker.blcontroller

class FavoritesRepository {
    private val maxFavorites = 5
    private val storageKey = "favorite_colors"
    private val favorites = mutableListOf<RgbColor>()
    
    init {
        loadFavorites()
    }
    
    private fun loadFavorites() {
        favorites.clear()
        val saved = Storage.getString(storageKey, "")
        if (saved.isNotEmpty()) {
            saved.split("|").forEach { colorString ->
                val parts = colorString.split(",")
                if (parts.size == 3) {
                    try {
                        val r = parts[0].toInt()
                        val g = parts[1].toInt()
                        val b = parts[2].toInt()
                        if (r in 0..255 && g in 0..255 && b in 0..255) {
                            favorites.add(RgbColor(r, g, b))
                        }
                    } catch (e: Exception) {
                        // Geçersiz format, atla
                    }
                }
            }
        }
    }
    
    private fun saveFavorites() {
        val colorStrings = favorites.map { "${it.r},${it.g},${it.b}" }
        val saved = colorStrings.joinToString("|")
        Storage.saveString(storageKey, saved)
    }
    
    fun addFavorite(color: RgbColor): Boolean {
        if (favorites.size >= maxFavorites) {
            return false
        }
        if (favorites.contains(color)) {
            return false
        }
        favorites.add(color)
        saveFavorites()
        return true
    }
    
    fun removeFavorite(color: RgbColor): Boolean {
        val removed = favorites.remove(color)
        if (removed) {
            saveFavorites()
        }
        return removed
    }
    
    fun getFavorites(): List<RgbColor> {
        return favorites.toList()
    }
    
    fun clearFavorites() {
        favorites.clear()
        saveFavorites()
    }
    
    fun isFavorite(color: RgbColor): Boolean {
        return favorites.contains(color)
    }
    
    fun canAddMore(): Boolean {
        return favorites.size < maxFavorites
    }
}


