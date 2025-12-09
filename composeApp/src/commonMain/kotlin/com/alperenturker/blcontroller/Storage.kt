package com.alperenturker.blcontroller

expect object Storage {
    fun saveString(key: String, value: String)
    fun getString(key: String, defaultValue: String): String
}

