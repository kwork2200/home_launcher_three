package com.kayfahaarukku.homelauncherthree

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class NativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_layout, null) as NativeAdView

        // Bind ad elements
        val headlineView = adView.findViewById<TextView>(R.id.native_ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.native_ad_body)
        val callToActionView = adView.findViewById<Button>(R.id.native_ad_btn)
        val iconView = adView.findViewById<ImageView>(R.id.native_ad_icon)
        val mediaView = adView.findViewById<MediaView>(R.id.native_ad_media)

        // Set the headline
        headlineView?.text = nativeAd.headline
        adView.headlineView = headlineView

        // Set the body
        if (nativeAd.body != null) {
            bodyView?.text = nativeAd.body
            bodyView?.visibility = View.VISIBLE
        } else {
            bodyView?.visibility = View.GONE
        }
        adView.bodyView = bodyView

        // Set the call to action
        if (nativeAd.callToAction != null) {
            callToActionView?.text = nativeAd.callToAction
            callToActionView?.visibility = View.VISIBLE
        } else {
            callToActionView?.visibility = View.GONE
        }
        adView.callToActionView = callToActionView

        // Set the icon
        if (nativeAd.icon != null) {
            iconView?.setImageDrawable(nativeAd.icon?.drawable)
            iconView?.visibility = View.VISIBLE
        } else {
            iconView?.visibility = View.GONE
        }
        adView.iconView = iconView

        // Set the media view
        if (nativeAd.mediaContent != null) {
            mediaView?.setMediaContent(nativeAd.mediaContent)
            mediaView?.visibility = View.VISIBLE
        } else {
            mediaView?.visibility = View.GONE
        }
        adView.mediaView = mediaView

        // Populate the ad
        adView.setNativeAd(nativeAd)

        return adView
    }
}
