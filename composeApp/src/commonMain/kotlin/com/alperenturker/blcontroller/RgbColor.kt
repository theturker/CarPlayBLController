package com.alperenturker.blcontroller

data class RgbColor(
    val r: Int,
    val g: Int,
    val b: Int
) {
    init {
        require(r in 0..255) { "Red component must be between 0 and 255" }
        require(g in 0..255) { "Green component must be between 0 and 255" }
        require(b in 0..255) { "Blue component must be between 0 and 255" }
    }
}


