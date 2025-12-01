package com.alperenturker.blcontroller

class FavoritesRepository {
    private val maxFavorites = 5
    private val favorites = mutableListOf<RgbColor>()
    
    fun addFavorite(color: RgbColor): Boolean {
        if (favorites.size >= maxFavorites) {
            return false
        }
        if (favorites.contains(color)) {
            return false
        }
        favorites.add(color)
        return true
    }
    
    fun removeFavorite(color: RgbColor): Boolean {
        return favorites.remove(color)
    }
    
    fun getFavorites(): List<RgbColor> {
        return favorites.toList()
    }
    
    fun clearFavorites() {
        favorites.clear()
    }
    
    fun isFavorite(color: RgbColor): Boolean {
        return favorites.contains(color)
    }
    
    fun canAddMore(): Boolean {
        return favorites.size < maxFavorites
    }
}


