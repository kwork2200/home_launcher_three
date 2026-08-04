package com.kayfahaarukku.homelauncherthree

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.appwidget.AppWidgetHostView
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode.transparent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import android.provider.Settings
import android.graphics.Bitmap
import java.io.ByteArrayOutputStream
import android.graphics.drawable.BitmapDrawable
import android.graphics.Canvas
import android.util.Log
import android.content.pm.PackageManager
import io.flutter.plugins.GeneratedPluginRegistrant
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import com.facebook.ads.AdView
import com.facebook.ads.NativeAd as FbNativeAd
import com.facebook.ads.NativeBannerAd as FbNativeBannerAd
import com.facebook.ads.AdListener
import com.facebook.ads.NativeAdListener
import com.facebook.ads.AdSize as FbAdSize
import android.app.role.RoleManager
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import com.android.installreferrer.api.ReferrerDetails

// Facebook Audience Network imports
import com.facebook.ads.AudienceNetworkAds
import com.facebook.ads.InterstitialAd
import com.facebook.ads.Ad as FbAd
import com.facebook.ads.AdError
import com.facebook.ads.InterstitialAdListener

fun android.graphics.drawable.Drawable.toBitmap(): Bitmap {
    if (this is BitmapDrawable) {
        return this.bitmap
    }

    val bitmap = Bitmap.createBitmap(
        intrinsicWidth.coerceAtLeast(1),
        intrinsicHeight.coerceAtLeast(1),
        Bitmap.Config.ARGB_8888
    )
    val canvas = Canvas(bitmap)
    setBounds(0, 0, canvas.width, canvas.height)
    draw(canvas)
    return bitmap
}

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.kayfahaarukku.homelauncherthree/widgets"
    private val FB_ADS_CHANNEL = "com.kayfahaarukku.homelauncherthree/facebook_ads"
    private val INSTALL_REFERRER_CHANNEL = "com.kayfahaarukku.homelauncherthree/install_referrer"
    private val CALL_EVENTS_CHANNEL = "com.kayfahaarukku.homelauncherthree/call_events"
    private val REQUEST_PICK_APPWIDGET = 9
    private val REQUEST_CREATE_APPWIDGET = 5
    private val APPWIDGET_HOST_ID = 442
    private val NOTIFICATION_LISTENER_SETTINGS = 1001
    private val REQUEST_READ_CALL_LOG = 1002
    private val REQUEST_CODE_HOME_ROLE = 1003
    private var widgetHost: AppWidgetHost? = null
    internal var widgetManager: AppWidgetManager? = null
    private val widgetViews = mutableMapOf<Int, AppWidgetHostView>()

    // Facebook Ads
    private var fbInterstitialAd: InterstitialAd? = null
    private var fbBannerAd: AdView? = null
    private var fbNativeAd: FbNativeBannerAd? = null
    private var fbAdsMethodChannel: MethodChannel? = null

    // Install Referrer
    private var referrerClient: InstallReferrerClient? = null
    private var referrerMethodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.attributes = window.attributes.also {
                val display = window.context.display
                if (display != null) {
                    val maxRate = display.supportedModes.maxOf { it.refreshRate }
                    it.preferredRefreshRate = maxRate
                    it.preferredDisplayModeId = display.supportedModes.firstOrNull { mode ->
                        mode.refreshRate == maxRate
                    }?.modeId ?: 0
                }
            }
        }
        intent.putExtra("background_mode", transparent.toString())
        super.onCreate(savedInstanceState)

        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = android.graphics.Color.TRANSPARENT
        window.navigationBarColor = android.graphics.Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isStatusBarContrastEnforced = false
            window.isNavigationBarContrastEnforced = false
        }
        window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
        window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)

        // Initialize Facebook Audience Network
        AudienceNetworkAds.initialize(this)
        com.facebook.ads.AdSettings.addTestDevice("6a456e1f-e23f-4a75-9e17-f8fa9481c4e4")
        Log.i("FacebookAds", "✅ Facebook Audience Network initialized")
        Log.i("FacebookAds", "Test device added: 6a456e1f-e23f-4a75-9e17-f8fa9481c4e4")

        // Initialize Install Referrer Client
        referrerClient = InstallReferrerClient.newBuilder(this).build()
        Log.i("InstallReferrer", "✅ Install Referrer Client initialized")

        widgetManager = AppWidgetManager.getInstance(this)
        widgetHost = AppWidgetHost(this, APPWIDGET_HOST_ID)
        widgetHost?.startListening()

        // Add Z to A sorting option
        val sortOptions = listOf(
            "usage" to "Sort by Usage",
            "alphabeticalAsc" to "Sort A to Z",
            "alphabeticalDesc" to "Sort Z to A"
        )
    }

    private fun createWidgetView(appWidgetId: Int, provider: AppWidgetProviderInfo): AppWidgetHostView? {
        val widgetView = widgetHost?.createView(this, appWidgetId, provider)
        if (widgetView != null) {
            val density = resources.displayMetrics.density
            val width = ViewGroup.LayoutParams.MATCH_PARENT
            val height = (provider.minHeight * density).toInt()

            widgetView.setPadding(16, 16, 16, 16)
            widgetView.layoutParams = ViewGroup.LayoutParams(width, height)
            widgetView.setBackgroundColor(android.graphics.Color.TRANSPARENT)
            widgetViews[appWidgetId] = widgetView
        }
        return widgetView
    }

    private fun isDefaultHomeApp(): Boolean {
        val homeIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = packageManager.resolveActivity(homeIntent, PackageManager.MATCH_DEFAULT_ONLY)
        return resolveInfo?.activityInfo?.packageName == packageName
    }

    fun getWidgetView(widgetId: Int): AppWidgetHostView? {
        return widgetViews[widgetId] ?: run {
            val provider = widgetManager?.getAppWidgetInfo(widgetId)
            if (provider != null) {
                createWidgetView(widgetId, provider)
            } else {
                null
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (resultCode == RESULT_OK) {
            if (requestCode == REQUEST_CREATE_APPWIDGET || requestCode == REQUEST_PICK_APPWIDGET) {
                val appWidgetId = data?.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1) ?: -1
                if (appWidgetId != -1) {
                    val provider = widgetManager?.getAppWidgetInfo(appWidgetId)
                    if (provider != null) {
                        createWidgetView(appWidgetId, provider)
                    }
                }
            } else if (requestCode == REQUEST_CODE_HOME_ROLE) {
                // User successfully selected a home app
                Log.d("MainActivity", "Home role selection completed successfully")
            }
        } else if (resultCode == RESULT_CANCELED) {
            if (data != null) {
                val appWidgetId = data.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                if (appWidgetId != -1) {
                    widgetHost?.deleteAppWidgetId(appWidgetId)
                }
            } else if (requestCode == REQUEST_CODE_HOME_ROLE) {
                // User canceled home role selection
                Log.d("MainActivity", "Home role selection canceled by user")
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_READ_CALL_LOG -> {
                if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                    Log.d("CallReceiver", "READ_CALL_LOG permission granted")
                    // Permission granted, get last call details
                    val lastCall = getLastCallDetails()
                    Log.d("CallReceiver", "Last call details after permission grant: $lastCall")
                    // Notify Flutter about the permission grant
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, CALL_EVENTS_CHANNEL).invokeMethod("onCallLogPermissionGranted", lastCall)
                    }
                } else {
                    Log.d("CallReceiver", "READ_CALL_LOG permission denied")
                    // Notify Flutter about the permission denial
                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                        MethodChannel(messenger, CALL_EVENTS_CHANNEL).invokeMethod("onCallLogPermissionDenied", null)
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Register platform view factory
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("android_widget_view", WidgetViewFactory(this))

        // Register Google Mobile Ads Native Ad Factory
        io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "smallNativeAd",
            NativeAdFactory(this)
        )
        io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "nativeAd",
            NativeAdFactory(this)
        )

        // Register Facebook Banner Ad Platform View
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "fb_banner_ad_view",
            FbBannerAdViewFactory()
        )

        // Register Facebook Native Ad Platform View
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "fb_native_ad_view",
            FbNativeAdViewFactory()
        )

        // Facebook Ads Platform Channel
        fbAdsMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FB_ADS_CHANNEL)
        fbAdsMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "loadFbInterstitial" -> {
                    val placementId = call.argument<String>("placementId") ?: ""
                    loadFbInterstitialAd(placementId, result)
                }
                "showFbInterstitial" -> {
                    if (fbInterstitialAd != null && fbInterstitialAd!!.isAdLoaded) {
                        fbInterstitialAd!!.show()
                        result.success(true)
                    } else {
                        Log.w("FacebookAds", "Interstitial ad not ready to show")
                        result.success(false)
                    }
                }
                "destroyFbInterstitial" -> {
                    fbInterstitialAd?.destroy()
                    fbInterstitialAd = null
                    result.success(true)
                }
                "loadFbBanner" -> {
                    val placementId = call.argument<String>("placementId") ?: ""
                    loadFbBannerAd(placementId, result)
                }
                "destroyFbBanner" -> {
                    fbBannerAd?.destroy()
                    fbBannerAd = null
                    result.success(true)
                }
                "loadFbNative" -> {
                    val placementId = call.argument<String>("placementId") ?: ""
                    loadFbNativeAd(placementId, result)
                }
                "destroyFbNative" -> {
                    fbNativeAd?.destroy()
                    fbNativeAd = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Call Events Channel
        val callEventsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_EVENTS_CHANNEL)
        CallReceiver.setMethodChannel(callEventsChannel)
        Log.i("CallReceiver", "✅ Call Receiver channel initialized")
        
        // Test the channel by sending a test message
        callEventsChannel.setMethodCallHandler { call, result ->
            Log.d("CallReceiver", "Received method call from Flutter: ${call.method}")
            when (call.method) {
                "testCallChannel" -> {
                    Log.d("CallReceiver", "Call channel test successful")
                    result.success(true)
                }
                "checkLastCall" -> {
                    // Check if permission is granted
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (checkSelfPermission(android.Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED) {
                            // Permission granted, get last call details
                            val lastCall = getLastCallDetails()
                            Log.d("CallReceiver", "Last call details: $lastCall")
                            result.success(lastCall)
                        } else {
                            // Permission not granted, request it
                            requestPermissions(arrayOf(android.Manifest.permission.READ_CALL_LOG), REQUEST_READ_CALL_LOG)
                            result.success(null)
                        }
                    } else {
                        // Pre-Marshmallow, permission is granted at install time
                        val lastCall = getLastCallDetails()
                        Log.d("CallReceiver", "Last call details: $lastCall")
                        result.success(lastCall)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWidgetList" -> {
                    val widgets = widgetManager?.installedProviders?.map {
                        mapOf(
                            "label" to it.loadLabel(packageManager),
                            "provider" to it.provider.flattenToString(),
                            "minWidth" to it.minWidth,
                            "minHeight" to it.minHeight,
                            "previewImage" to it.previewImage?.toString(),
                            "appName" to packageManager.getApplicationLabel(
                                packageManager.getApplicationInfo(it.provider.packageName, 0)
                            ).toString()
                        )
                    }
                    result.success(widgets)
                }
                "getAddedWidgets" -> {
                    val host = widgetHost
                    if (host != null) {
                        val addedWidgets = host.appWidgetIds?.map { widgetId ->
                            val provider = widgetManager?.getAppWidgetInfo(widgetId)
                            if (provider != null) {
                                val widgetView = widgetViews[widgetId] ?: createWidgetView(widgetId, provider)

                                val previewBase64 = if (provider.previewImage != 0) {
                                    try {
                                        val drawable = packageManager.getDrawable(provider.provider.packageName, provider.previewImage, null)
                                        if (drawable != null) {
                                            val bitmap = drawable.toBitmap()
                                            val stream = ByteArrayOutputStream()
                                            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                            android.util.Base64.encodeToString(stream.toByteArray(), android.util.Base64.NO_WRAP)
                                        } else ""
                                    } catch (e: Exception) {
                                        ""
                                    }
                                } else ""

                                mapOf(
                                    "label" to provider.loadLabel(packageManager),
                                    "provider" to provider.provider.flattenToString(),
                                    "minWidth" to provider.minWidth,
                                    "minHeight" to provider.minHeight,
                                    "previewImage" to previewBase64,
                                    "widgetId" to widgetId,
                                    "appName" to packageManager.getApplicationLabel(
                                        packageManager.getApplicationInfo(provider.provider.packageName, 0)
                                    ).toString(),
                                    "packageName" to provider.provider.packageName
                                )
                            } else null
                        }?.filterNotNull() ?: emptyList()
                        result.success(addedWidgets)
                    } else {
                        result.success(emptyList<Map<String, Any>>())
                    }
                }
                "addWidget" -> {
                    val provider = call.argument<String>("provider")
                    if (provider != null) {
                        val component = ComponentName.unflattenFromString(provider)
                        if (component != null) {
                            val appWidgetId = widgetHost?.allocateAppWidgetId() ?: -1

                            if (appWidgetId != -1 && widgetManager?.bindAppWidgetIdIfAllowed(appWidgetId, component) == true) {
                                val configureIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE)
                                configureIntent.component = component
                                configureIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                                startActivityForResult(configureIntent, REQUEST_CREATE_APPWIDGET)
                                result.success(true)
                            } else {
                                val bindIntent = Intent(AppWidgetManager.ACTION_APPWIDGET_BIND)
                                bindIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                                bindIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_PROVIDER, component)
                                startActivityForResult(bindIntent, REQUEST_PICK_APPWIDGET)
                                result.success(true)
                            }
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "removeWidget" -> {
                    handleRemoveWidget(call, result)
                }
                "updateWidgetSize" -> {
                    val widgetId = call.argument<Int>("widgetId")
                    val width = call.argument<Int>("width")
                    val height = call.argument<Int>("height")

                    if (widgetId != null && width != null && height != null) {
                        val widgetView = widgetViews[widgetId]
                        val density = resources.displayMetrics.density
                        val dpWidth = (width / density).toInt()
                        val dpHeight = (height / density).toInt()
                        widgetView?.updateAppWidgetSize(null, dpWidth, dpHeight, dpWidth, dpHeight)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kayfahaarukku.homelauncherthree/apps")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getApps" -> {
                        val apps = AppQueryHelper.getLauncherActivities(this).map { resolveInfo ->
                            val packageName = resolveInfo.activityInfo.packageName
                            mapOf(
                                "name" to AppQueryHelper.getAppLabel(this, packageName),
                                "packageName" to packageName,
                                "icon" to AppQueryHelper.getAppIcon(this, packageName)?.let { drawable ->
                                    val bitmap = drawable.toBitmap()
                                    ByteArrayOutputStream().use { stream ->
                                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                                        stream.toByteArray()
                                    }
                                }
                            )
                        }
                        result.success(apps)
                    }
                    "openAppSettings" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                            intent.data = Uri.parse("package:$packageName")
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.error("INVALID_PACKAGE", "Package name is null", null)
                        }
                    }
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val intent = packageManager.getLaunchIntentForPackage(packageName)
                            if (intent != null) {
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                                intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                                startActivity(intent)
                                NotificationListener.instance?.clearNotificationsForPackage(packageName)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } else {
                            result.success(false)
                        }
                    }
                    "openHomeSettings" -> {
                        // yeh asli Android Settings screen kholta hai
                        // jahan user default Home app choose kar sakta hai
                        try {
                            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to open home settings", e.message)
                        }
                    }
                    "requestHomeRole" -> {
                        // Robust implementation for all Android versions
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                // Android 10+ (API 29+) - Use RoleManager for guaranteed system dialog
                                val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME)
                                startActivityForResult(intent, REQUEST_CODE_HOME_ROLE)
                                result.success(true)
                            } else {
                                // Android 9 and below - Use HOME_SETTINGS fallback
                                val intent = Intent(Settings.ACTION_HOME_SETTINGS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Failed to request home role", e)
                            result.error("ERROR", "Failed to request home role", e.message)
                        }
                    }
                    "clearStack" -> {
                        clearStack()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kayfahaarukku.homelauncherthree/notifications")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestNotificationAccess" -> {
                        Log.d("MainActivity", "Requesting notification access")
                        if (!isNotificationServiceEnabled()) {
                            startActivityForResult(
                                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS),
                                NOTIFICATION_LISTENER_SETTINGS
                            )
                        }
                        toggleNotificationListenerService()
                        result.success(isNotificationServiceEnabled())
                    }
                    "getCurrentNotifications" -> {
                        NotificationListener.instance?.let { listener ->
                            val notifications = mutableMapOf<String, Int>()
                            listener.activeNotifications?.forEach { sbn ->
                                if (!sbn.isOngoing) {
                                    notifications[sbn.packageName] =
                                        (notifications[sbn.packageName] ?: 0) + 1
                                }
                            }
                            result.success(notifications)
                        } ?: result.success(mapOf<String, Int>())
                    }
                    else -> result.notImplemented()
                }
            }

        NotificationListener.addListener { packageName, isPosted ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kayfahaarukku.homelauncherthree/notifications")
                .invokeMethod(
                    if (isPosted) "onNotificationPosted" else "onNotificationRemoved",
                    mapOf("packageName" to packageName)
                )
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kayfahaarukku.homelauncherthree/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "changeWallpaper" -> {
                        try {
                            val intent = Intent(Intent.ACTION_SET_WALLPAPER)
                            startActivity(Intent.createChooser(intent, "Select Wallpaper"))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to launch wallpaper picker", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kayfahaarukku.homelauncherthree/launcher")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openHomeSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_HOME_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to open home settings", null)
                        }
                    }
                    "requestHomeRole" -> {
                        // Robust implementation for all Android versions
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                // Android 10+ (API 29+) - Use RoleManager for guaranteed system dialog
                                val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME)
                                startActivityForResult(intent, REQUEST_CODE_HOME_ROLE)
                                result.success(true)
                            } else {
                                // Android 9 and below - Use HOME_SETTINGS fallback
                                val intent = Intent(Settings.ACTION_HOME_SETTINGS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Failed to request home role", e)
                            result.error("ERROR", "Failed to request home role", e.message)
                        }
                    }
                    "isDefaultLauncher" -> {
                        try {
                            val isDefault = isDefaultHomeApp()
                            result.success(isDefault)
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Failed to check default launcher", e)
                            result.error("ERROR", "Failed to check default launcher", e.message)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Security check channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.kayfahaarukku.homelauncherthree/security")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkSecurityStatus" -> {
                        val devOptionsEnabled = isDeveloperOptionsEnabled()
                        val dnsEnabled = isPrivateDnsEnabled()
                        result.success(mapOf(
                            "developerOptionsEnabled" to devOptionsEnabled,
                            "dnsEnabled" to dnsEnabled
                        ))
                    }
                    else -> result.notImplemented()
                }
            }

        // Install Referrer channel
        referrerMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INSTALL_REFERRER_CHANNEL)
        referrerMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstallReferrer" -> {
                    getInstallReferrer(result)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun removeWidgetView(widgetId: Int) {
        widgetViews.remove(widgetId)
    }

    private fun handleRemoveWidget(call: MethodCall, result: Result) {
        try {
            val widgetId = call.argument<Int>("widgetId")
            if (widgetId != null) {
                removeWidgetView(widgetId)
                widgetHost?.deleteAppWidgetId(widgetId)
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("ERROR", e.message, null)
        }
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        val enabled = flat?.contains(packageName + "/" + NotificationListener::class.java.name) == true
        Log.d("MainActivity", "Notification service enabled: $enabled")
        return enabled
    }

    private fun toggleNotificationListenerService() {
        val packageManager = packageManager
        packageManager.setComponentEnabledSetting(
            ComponentName(this, NotificationListener::class.java),
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP
        )
        packageManager.setComponentEnabledSetting(
            ComponentName(this, NotificationListener::class.java),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )
    }

    private fun clearStack() {
        val intent = Intent(this, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        startActivity(intent)
    }

    // Security check methods
    private fun isDeveloperOptionsEnabled(): Boolean {
        return try {
            Settings.Global.getInt(contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED) == 1
        } catch (e: Exception) {
            Log.e("SecurityCheck", "Error checking developer options: ${e.message}")
            false
        }
    }

    private fun isPrivateDnsEnabled(): Boolean {
        return try {
            val mode = Settings.System.getString(contentResolver, "private_dns_mode")
            mode != null && mode != "off"
        } catch (e: Exception) {
            Log.e("SecurityCheck", "Error checking private DNS: ${e.message}")
            false
        }
    }

    private fun getInstallReferrer(result: MethodChannel.Result) {
        referrerClient?.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                when (responseCode) {
                    InstallReferrerClient.InstallReferrerResponse.OK -> {
                        try {
                            val referrerDetails: ReferrerDetails = referrerClient!!.installReferrer
                            val referrerUrl = referrerDetails.installReferrer
                            val referrerClickTime = referrerDetails.referrerClickTimestampSeconds
                            val installBeginTime = referrerDetails.installBeginTimestampSeconds

                            Log.i("InstallReferrer", "✅ Referrer URL: $referrerUrl")
                            Log.i("InstallReferrer", "Referrer click time: $referrerClickTime")
                            Log.i("InstallReferrer", "Install begin time: $installBeginTime")

                            // Check if user came from referral link
                            val isReferral = !referrerUrl.isNullOrEmpty() && referrerUrl != "utm_source=google-play&utm_medium=organic"

                            result.success(mapOf(
                                "referrerUrl" to (referrerUrl ?: ""),
                                "referrerClickTime" to referrerClickTime,
                                "installBeginTime" to installBeginTime,
                                "isReferral" to isReferral
                            ))
                        } catch (e: Exception) {
                            Log.e("InstallReferrer", "Error getting referrer details: ${e.message}")
                            result.error("REFERRER_ERROR", e.message, null)
                        }
                    }
                    InstallReferrerClient.InstallReferrerResponse.FEATURE_NOT_SUPPORTED -> {
                        Log.e("InstallReferrer", "Install Referrer API not supported")
                        result.error("FEATURE_NOT_SUPPORTED", "Install Referrer API not supported", null)
                    }
                    InstallReferrerClient.InstallReferrerResponse.SERVICE_UNAVAILABLE -> {
                        Log.e("InstallReferrer", "Install Referrer service unavailable")
                        result.error("SERVICE_UNAVAILABLE", "Install Referrer service unavailable", null)
                    }
                    else -> {
                        Log.e("InstallReferrer", "Unknown response code: $responseCode")
                        result.error("UNKNOWN_ERROR", "Unknown response code: $responseCode", null)
                    }
                }
            }

            override fun onInstallReferrerServiceDisconnected() {
                Log.w("InstallReferrer", "Install Referrer service disconnected")
            }
        })
    }

    // ═══════════════════════════════════════════════════════════════
    // Facebook Ads Methods
    // ═══════════════════════════════════════════════════════════════

    private fun loadFbInterstitialAd(placementId: String, result: MethodChannel.Result) {
        Log.i("FacebookAds", "🔄 Loading interstitial ad with placement: $placementId")

        fbInterstitialAd = InterstitialAd(this, placementId)
        fbInterstitialAd?.loadAd(
            fbInterstitialAd?.buildLoadAdConfig()
                ?.withAdListener(object : InterstitialAdListener {
                    override fun onInterstitialDisplayed(ad: FbAd) {
                        Log.i("FacebookAds", "✅ Interstitial displayed")
                    }

                    override fun onInterstitialDismissed(ad: FbAd) {
                        Log.i("FacebookAds", "✅ Interstitial dismissed")
                        // Notify Flutter that ad was dismissed
                        fbAdsMethodChannel?.invokeMethod("onInterstitialDismissed", null)
                    }

                    override fun onError(ad: FbAd, error: AdError) {
                        Log.e("FacebookAds", "❌ Error loading ad: ${error.errorMessage}")
                        result.error("FB_AD_ERROR", error.errorMessage, null)
                    }

                    override fun onAdLoaded(ad: FbAd) {
                        Log.i("FacebookAds", "✅ Interstitial ad loaded successfully")
                        result.success(true)
                    }

                    override fun onAdClicked(ad: FbAd) {
                        Log.i("FacebookAds", "👆 Interstitial ad clicked")
                    }

                    override fun onLoggingImpression(ad: FbAd) {
                        Log.i("FacebookAds", "📊 Logging impression")
                    }
                })
                ?.build()
        )
    }

    private fun loadFbBannerAd(placementId: String, result: MethodChannel.Result) {
        Log.i("FacebookAds", "🔄 Loading banner ad with placement: $placementId")
        fbBannerAd = AdView(this, placementId, FbAdSize.BANNER_HEIGHT_50)
        fbBannerAd?.loadAd(
            fbBannerAd?.buildLoadAdConfig()
                ?.withAdListener(object : AdListener {
                    override fun onError(ad: FbAd, error: AdError) {
                        Log.e("FacebookAds", "❌ Error loading banner ad: ${error.errorMessage}")
                        result.error("FB_AD_ERROR", error.errorMessage, null)
                    }
                    override fun onAdLoaded(ad: FbAd) {
                        Log.i("FacebookAds", "✅ Banner ad loaded successfully")
                        result.success(true)
                    }
                    override fun onAdClicked(ad: FbAd) {
                        Log.i("FacebookAds", "👆 Banner ad clicked")
                    }
                    override fun onLoggingImpression(ad: FbAd) {
                        Log.i("FacebookAds", "📊 Logging banner impression")
                    }
                })
                ?.build()
        )
    }

    private fun loadFbNativeAd(placementId: String, result: MethodChannel.Result) {
        Log.i("FacebookAds", "🔄 Loading native ad with placement: $placementId")
        fbNativeAd = FbNativeBannerAd(this, placementId)
        fbNativeAd?.loadAd(
            fbNativeAd?.buildLoadAdConfig()
                ?.withAdListener(object : NativeAdListener {
                    override fun onMediaDownloaded(ad: FbAd) {
                        Log.d("FacebookAds", "Media downloaded")
                    }
                    override fun onError(ad: FbAd, error: AdError) {
                        Log.e("FacebookAds", "❌ Error loading native ad: ${error.errorMessage}")
                        result.error("FB_AD_ERROR", error.errorMessage, null)
                    }
                    override fun onAdLoaded(ad: FbAd) {
                        Log.i("FacebookAds", "✅ Native ad loaded successfully")
                        result.success(true)
                    }
                    override fun onAdClicked(ad: FbAd) {
                        Log.d("FacebookAds", "Native ad clicked")
                    }
                    override fun onLoggingImpression(ad: FbAd) {
                        Log.d("FacebookAds", "Logging native impression")
                    }
                })
                ?.build()
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        widgetHost?.stopListening()
        fbInterstitialAd?.destroy()
        fbInterstitialAd = null
        fbBannerAd?.destroy()
        fbBannerAd = null
        fbNativeAd?.destroy()
        fbNativeAd = null
        referrerClient?.endConnection()
    }
    
    private fun getLastCallDetails(): Map<String, Any>? {
        try {
            val contentResolver = contentResolver
            val cursor = contentResolver.query(
                android.provider.CallLog.Calls.CONTENT_URI,
                null,
                null,
                null,
                android.provider.CallLog.Calls.DATE + " DESC"
            )
            
            if (cursor != null && cursor.moveToFirst()) {
                val number = cursor.getString(cursor.getColumnIndex(android.provider.CallLog.Calls.NUMBER))
                val duration = cursor.getInt(cursor.getColumnIndex(android.provider.CallLog.Calls.DURATION))
                val type = cursor.getInt(cursor.getColumnIndex(android.provider.CallLog.Calls.TYPE))
                val date = cursor.getLong(cursor.getColumnIndex(android.provider.CallLog.Calls.DATE))
                
                cursor.close()
                
                val callType = when (type) {
                    android.provider.CallLog.Calls.INCOMING_TYPE -> "INCOMING"
                    android.provider.CallLog.Calls.OUTGOING_TYPE -> "OUTGOING"
                    android.provider.CallLog.Calls.MISSED_TYPE -> "MISSED"
                    else -> "UNKNOWN"
                }
                
                val timeSinceCall = System.currentTimeMillis() - date
                val isRecent = timeSinceCall < 30000 // Within 30 seconds
                
                Log.d("CallReceiver", "Last call: $number, Type: $callType, Duration: $duration, Time since: $timeSinceCall")
                
                return mapOf(
                    "number" to (number ?: "Unknown"),
                    "duration" to duration,
                    "type" to callType,
                    "isRecent" to isRecent,
                    "timeSinceCall" to timeSinceCall
                )
            }
            cursor?.close()
        } catch (e: Exception) {
            Log.e("CallReceiver", "Error getting last call details", e)
        }
        return null
    }

    override fun onBackPressed() {
        val messenger = flutterEngine?.dartExecutor?.binaryMessenger
        if (messenger == null) {
            super.onBackPressed()
            return
        }
        val channel = MethodChannel(messenger, "com.kayfahaarukku.homelauncherthree/system")
        channel.invokeMethod("getNavigationState", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
                when (result as? String) {
                    "settings", "about", "call_screen", "left_view" -> {
                        // Allow back button for settings, about, call screen, and left view pages
                        super@MainActivity.onBackPressed()
                    }
                    "main" -> {
                        // For default launcher, don't close app on back press from home screen
                        // Just consume the back press
                    }
                    else -> {
                        // For any other state, handle in Flutter
                        channel.invokeMethod("onBackPressed", null, object : MethodChannel.Result {
                            override fun success(result: Any?) {
                                // Flutter handled the back press, do nothing
                            }
                            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                                // On error, do nothing
                            }
                            override fun notImplemented() {
                                // Method not implemented, do nothing
                            }
                        })
                    }
                }
            }
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                // On error, do nothing
            }
            override fun notImplemented() {
                // Method not implemented, do nothing
            }
        })
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // Unregister Google Mobile Ads Native Ad Factory
        io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "smallNativeAd"
        )
        io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "nativeAd"
        )
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
// ─────────────────────────────────────────────────────────────────
// Facebook Banner Ad Platform View Factory
// ─────────────────────────────────────────────────────────────────
class FbBannerAdViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any>
        val placementId = params?.get("placementId") as? String
            ?: "IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID"
        return FbBannerAdView(context, placementId)
    }
}

class FbBannerAdView(context: Context, placementId: String) : PlatformView {
    private val adView: AdView = AdView(context, placementId, FbAdSize.BANNER_HEIGHT_50)

    init {
        adView.loadAd(
            adView.buildLoadAdConfig()
                .withAdListener(object : AdListener {
                    override fun onError(ad: FbAd, error: AdError) {
                        android.util.Log.e("FbBannerAd", "Error: ${error.errorMessage}")
                    }
                    override fun onAdLoaded(ad: FbAd) {
                        android.util.Log.i("FbBannerAd", "Banner ad loaded")
                    }
                    override fun onAdClicked(ad: FbAd) {}
                    override fun onLoggingImpression(ad: FbAd) {}
                })
                .build()
        )
    }

    override fun getView(): View = adView

    override fun dispose() {
        adView.destroy()
    }
}

// ─────────────────────────────────────────────────────────────────
// Facebook Native Ad Platform View Factory
// ─────────────────────────────────────────────────────────────────
class FbNativeAdViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any>
        val placementId = params?.get("placementId") as? String
            ?: "IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID"
        return FbNativeAdView(context, placementId)
    }
}

class FbNativeAdView(private val context: Context, placementId: String) : PlatformView {
    private val nativeAd: FbNativeBannerAd = FbNativeBannerAd(context, placementId)
    private val containerLayout: android.widget.FrameLayout = android.widget.FrameLayout(context)
    private var isAdLoaded = false

    init {
        // Show initial loading state
        showLoadingState()

        nativeAd.loadAd(
            nativeAd.buildLoadAdConfig()
                .withAdListener(object : NativeAdListener {
                    override fun onMediaDownloaded(ad: FbAd) {
                        android.util.Log.d("FbNativeAd", "Media downloaded")
                    }
                    override fun onError(ad: FbAd, error: AdError) {
                        android.util.Log.e("FbNativeAd", "❌ Error loading ad: ${error.errorMessage}")
                        showErrorState(error.errorMessage)
                    }
                    override fun onAdLoaded(ad: FbAd) {
                        android.util.Log.i("FbNativeAd", "✅ Native ad loaded successfully")
                        isAdLoaded = true
                        inflateAdView()
                    }
                    override fun onAdClicked(ad: FbAd) {
                        android.util.Log.d("FbNativeAd", "Ad clicked")
                    }
                    override fun onLoggingImpression(ad: FbAd) {
                        android.util.Log.d("FbNativeAd", "Logging impression")
                    }
                })
                .build()
        )
    }

    private fun showLoadingState() {
        containerLayout.removeAllViews()
        val loadingView = android.widget.TextView(context).apply {
            text = "Loading ad..."
            textSize = 14f
            setTextColor(android.graphics.Color.GRAY)
            gravity = android.view.Gravity.CENTER
            setPadding(16, 32, 16, 32)
        }
        containerLayout.addView(loadingView)
    }

    private fun showErrorState(errorMessage: String) {
        containerLayout.removeAllViews()
        val errorView = android.widget.TextView(context).apply {
            text = "Ad failed to load: $errorMessage"
            textSize = 12f
            setTextColor(android.graphics.Color.RED)
            gravity = android.view.Gravity.CENTER
            setPadding(16, 32, 16, 32)
        }
        containerLayout.addView(errorView)
    }

    private fun inflateAdView() {
        // Remove loading state
        containerLayout.removeAllViews()

        // Create a simple native ad layout programmatically
        val linearLayout = android.widget.LinearLayout(context).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setPadding(16, 16, 16, 16)
            setBackgroundColor(android.graphics.Color.parseColor("#F5F5F5"))
            layoutParams = android.widget.FrameLayout.LayoutParams(
                android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
                android.widget.FrameLayout.LayoutParams.WRAP_CONTENT
            )
        }

        // Sponsored label
        val sponsoredText = android.widget.TextView(context).apply {
            text = "Sponsored"
            textSize = 10f
            setTextColor(android.graphics.Color.parseColor("#757575"))
            setPadding(8, 4, 8, 4)
        }
        linearLayout.addView(sponsoredText)

        // Icon ImageView (required for registerViewForInteraction)
        val iconView = android.widget.ImageView(context).apply {
            layoutParams = android.widget.LinearLayout.LayoutParams(80, 80).apply {
                setMargins(0, 8, 0, 8)
            }
            scaleType = android.widget.ImageView.ScaleType.CENTER_CROP
            setBackgroundColor(android.graphics.Color.parseColor("#E0E0E0"))
        }
        linearLayout.addView(iconView)

        // Title
        val titleText = android.widget.TextView(context).apply {
            text = nativeAd.advertiserName ?: "Ad"
            textSize = 16f
            setTextColor(android.graphics.Color.parseColor("#212121"))
            setPadding(0, 8, 0, 8)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        linearLayout.addView(titleText)

        // Body
        val bodyText = android.widget.TextView(context).apply {
            text = nativeAd.adBodyText ?: ""
            textSize = 14f
            setTextColor(android.graphics.Color.parseColor("#616161"))
            setPadding(0, 4, 0, 8)
            maxLines = 3
        }
        linearLayout.addView(bodyText)

        // CTA Button
        val ctaButton = android.widget.Button(context).apply {
            text = nativeAd.adCallToAction ?: "Learn More"
            textSize = 14f
            setTextColor(android.graphics.Color.WHITE)
            setBackgroundColor(android.graphics.Color.parseColor("#1976D2"))
        }
        linearLayout.addView(ctaButton)

        // Register the view - NativeBannerAd requires View + ImageView
        nativeAd.registerViewForInteraction(linearLayout, iconView)

        // Add the ad layout to container
        containerLayout.addView(linearLayout)
        android.util.Log.i("FbNativeAd", "✅ Ad view inflated and displayed")
    }

    override fun getView(): View {
        return containerLayout
    }

    override fun dispose() {
        nativeAd.unregisterView()
        nativeAd.destroy()
    }
}
