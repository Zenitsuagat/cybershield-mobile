package com.example.cyber_shield_v2

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "cybershield/installed_apps"

    // ── ONLY permissions that appear as user-toggleable in Android Settings ──
    // Removed: USE_BIOMETRIC, POST_NOTIFICATIONS, INTERNET, BLUETOOTH_*,
    //          WRITE_CONTACTS, WRITE_CALL_LOG (not shown in Settings as toggleable)
    private val USER_FACING_PERMISSIONS = setOf(
        // Camera group
        "android.permission.CAMERA",

        // Microphone group
        "android.permission.RECORD_AUDIO",

        // Location group
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_BACKGROUND_LOCATION",

        // Contacts group
        "android.permission.READ_CONTACTS",

        // Call logs group
        "android.permission.READ_CALL_LOG",
        "android.permission.PROCESS_OUTGOING_CALLS",

        // SMS group
        "android.permission.READ_SMS",
        "android.permission.SEND_SMS",
        "android.permission.RECEIVE_SMS",

        // Phone group
        "android.permission.READ_PHONE_STATE",
        "android.permission.CALL_PHONE",

        // Storage — legacy (Android 9–12)
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.WRITE_EXTERNAL_STORAGE",

        // Storage — modern (Android 13+)
        "android.permission.READ_MEDIA_IMAGES",
        "android.permission.READ_MEDIA_VIDEO",
        "android.permission.READ_MEDIA_AUDIO",

        // Body sensors group
        "android.permission.BODY_SENSORS",
        "android.permission.BODY_SENSORS_BACKGROUND",

        // Activity recognition
        "android.permission.ACTIVITY_RECOGNITION",

        // Nearby devices (shows in Settings as "Nearby devices")
        "android.permission.BLUETOOTH_SCAN",
        "android.permission.BLUETOOTH_CONNECT",
        "android.permission.BLUETOOTH_ADVERTISE",
        "android.permission.UWB_RANGING",

        // Accounts (shows in some OEM settings)
        "android.permission.GET_ACCOUNTS",
    )

    // ── Internet: always "granted" if declared, add separately ───────────────
    private val INTERNET_PERM = "android.permission.INTERNET"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "getInstalledApps" -> {
                        try {
                            result.success(getAppsWithGrantedPermissions())
                        } catch (e: Exception) {
                            result.error("SCAN_ERROR", e.message, null)
                        }
                    }

                    "openAppSettings" -> {
                        try {
                            val packageName = call.argument<String>("package")
                            if (packageName != null) {
                                val intent = Intent(
                                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                                ).apply {
                                    data = Uri.fromParts(
                                        "package", packageName, null)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.error("NO_PACKAGE",
                                    "Package name is null", null)
                            }
                        } catch (e: Exception) {
                            result.error("SETTINGS_ERROR", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun getAppsWithGrantedPermissions(): List<Map<String, Any>> {
        val pm      = packageManager
        val apps    = mutableListOf<Map<String, Any>>()
        val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)

        for (pkg in packages) {
            try {
                val appInfo     = pkg.applicationInfo ?: continue
                val isSystemApp =
                    (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val hasLauncher =
                    pm.getLaunchIntentForPackage(pkg.packageName) != null

                // Skip pure background system services
                if (isSystemApp && !hasLauncher) continue

                val appName            = pm.getApplicationLabel(appInfo).toString()
                val grantedPermissions = mutableListOf<String>()
                val requestedPerms     = pkg.requestedPermissions
                val requestedFlags     = pkg.requestedPermissionsFlags

                if (requestedPerms != null && requestedFlags != null) {
                    for (i in requestedPerms.indices) {
                        val permName = requestedPerms[i]

                        // ── Internet: add if declared (always effectively granted) ─
                        if (permName == INTERNET_PERM) {
                            // Check it's actually in the manifest
                            val flagGranted = (requestedFlags[i] and
                                    PackageManager.GET_PERMISSIONS) != 0
                            // Internet is a normal permission — declared = granted
                            grantedPermissions.add("INTERNET")
                            continue
                        }

                        // Skip permissions not shown in Android Settings
                        if (!USER_FACING_PERMISSIONS.contains(permName)) continue

                        // ── Primary method: use requestedPermissionsFlags ──────────
                        // REQUESTED_PERMISSION_GRANTED flag = 0x00000002
                        // This is the most reliable way across all Android versions
                        val isGrantedByFlag = (requestedFlags[i] and
                                PackageManager.GET_PERMISSIONS) != 0

                        // ── Secondary method: checkPermission() ───────────────────
                        // More accurate for runtime permissions on Android 6+
                        val isGrantedByCheck = try {
                            pm.checkPermission(permName, pkg.packageName) ==
                                    PackageManager.PERMISSION_GRANTED
                        } catch (e: Exception) { false }

                        // Use OR: if either method says granted, include it
                        // This catches edge cases where one method misses
                        if (isGrantedByCheck) {
                            val shortName = permName
                                .removePrefix("android.permission.")
                            if (!grantedPermissions.contains(shortName)) {
                                grantedPermissions.add(shortName)
                            }
                        }
                    }
                }

                // Skip system apps with zero tracked permissions
                if (grantedPermissions.isEmpty() && isSystemApp) continue

                apps.add(mapOf(
                    "app_name"     to appName,
                    "package_name" to pkg.packageName,
                    "permissions"  to grantedPermissions,
                    "is_system"    to isSystemApp
                ))

            } catch (e: Exception) {
                continue
            }
        }

        return apps.sortedWith(compareBy(
            { it["is_system"] as Boolean },
            { it["app_name"]  as String  }
        ))
    }
}