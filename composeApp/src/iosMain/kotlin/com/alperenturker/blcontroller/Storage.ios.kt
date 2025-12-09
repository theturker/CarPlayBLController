package com.alperenturker.blcontroller

import platform.Foundation.NSUserDefaults

actual object Storage {
    private val userDefaults = NSUserDefaults.standardUserDefaults
    
    actual fun saveString(key: String, value: String) {
        userDefaults.setObject(value, forKey = key)
        userDefaults.synchronize()
    }
    
    actual fun getString(key: String, defaultValue: String): String {
        val value = userDefaults.objectForKey(key) as? String
        return value ?: defaultValue
    }
}

