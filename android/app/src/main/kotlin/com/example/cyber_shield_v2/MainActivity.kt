package com.example.cyber_shield_v2

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "cybershield/installed_apps"

    private val DANGEROUS_PERMISSIONS = setOf(
        "android.permission.CAMERA",
        "android.permission.RECORD_AUDIO",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_BACKGROUND_LOCATION",
        "android.permission.READ_CONTACTS",
        "android.permission.WRITE_CONTACTS",
        "android.permission.READ_CALL_LOG",
        "android.permission.WRITE_CALL_LOG",
        "android.permission.READ_SMS",
        "android.permission.SEND_SMS",
        "android.permission.RECEIVE_SMS",
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.WRITE_EXTERNAL_STORAGE",
        "android.permission.READ_MEDIA_IMAGES",
        "android.permission.READ_MEDIA_VIDEO",
        "android.permission.READ_MEDIA_AUDIO",
        "android.permission.GET_ACCOUNTS",
        "android.permission.USE_BIOMETRIC",
        "android.permission.READ_PHONE_STATE",
        "android.permission.CALL_PHONE",
        "android.permission.BODY_SENSORS",
        "android.permission.ACTIVITY_RECOGNITION",
        "android.permission.BLUETOOTH_SCAN",
        "android.permission.BLUETOOTH_CONNECT",
        "android.permission.PROCESS_OUTGOING_CALLS",
        "android.permission.INTERNET",
        "android.permission.MANAGE_EXTERNAL_STORAGE",
        "android.permission.POST_NOTIFICATIONS"
    )

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

                    // ── Double-tap: open that app's permission settings ─────
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
        val pm   = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)

        for (pkg in packages) {
            try {
                val appInfo    = pkg.applicationInfo ?: continue
                val isSystemApp =
                    (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val hasLauncher =
                    pm.getLaunchIntentForPackage(pkg.packageName) != null
                if (isSystemApp && !hasLauncher) continue

                val appName = pm.getApplicationLabel(appInfo).toString()
                val grantedPermissions = mutableListOf<String>()
                val requestedPerms = pkg.requestedPermissions
                val requestedFlags = pkg.requestedPermissionsFlags

                if (requestedPerms != null && requestedFlags != null) {
                    for (i in requestedPerms.indices) {
                        val permName = requestedPerms[i]
                        if (!DANGEROUS_PERMISSIONS.contains(permName)) continue

                        if (permName == "android.permission.INTERNET") {
                            grantedPermissions.add(
                                permName.removePrefix("android.permission."))
                            continue
                        }

                        val granted = pm.checkPermission(
                            permName, pkg.packageName
                        ) == PackageManager.PERMISSION_GRANTED

                        if (granted) {
                            grantedPermissions.add(
                                permName.removePrefix("android.permission."))
                        }
                    }
                }

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