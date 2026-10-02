package com.sid.signature.maker

import android.graphics.Outline
import android.view.LayoutInflater
import android.view.View
import android.view.ViewOutlineProvider
import android.widget.ImageView
import android.widget.RatingBar
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.NativeAdFactory

/** Arrow Drift–style small native: no media; full-width CTA at bottom. */
class NativeAdSmallFactory(
    private val layoutInflater: LayoutInflater,
) : NativeAdFactory {

    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?,
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.native_ad_small,
            null,
        ) as NativeAdView

        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.starRatingView = adView.findViewById(R.id.ad_stars)

        (adView.headlineView as TextView).text = nativeAd.headline

        val bodyView = adView.bodyView as TextView
        if (nativeAd.body.isNullOrEmpty()) {
            bodyView.visibility = View.GONE
        } else {
            bodyView.visibility = View.VISIBLE
            bodyView.text = nativeAd.body
        }

        val ctaView = adView.callToActionView as TextView
        if (nativeAd.callToAction.isNullOrEmpty()) {
            ctaView.visibility = View.INVISIBLE
        } else {
            ctaView.visibility = View.VISIBLE
            ctaView.text = nativeAd.callToAction
        }

        val iconView = adView.iconView as ImageView
        val icon = nativeAd.icon
        if (icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.setImageDrawable(icon.drawable)
            iconView.visibility = View.VISIBLE
            val radius = 10f * iconView.resources.displayMetrics.density
            iconView.outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, radius)
                }
            }
            iconView.clipToOutline = true
        }

        val starsView = adView.starRatingView as RatingBar
        val rating = nativeAd.starRating
        if (rating == null || rating <= 0) {
            starsView.visibility = View.GONE
        } else {
            starsView.rating = rating.toFloat()
            starsView.visibility = View.VISIBLE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
