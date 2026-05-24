package com.treinopro.app

import android.content.res.Configuration
import android.graphics.Color
import android.os.LocaleList
import com.stripe.android.connect.appearance.Appearance
import com.stripe.android.connect.appearance.Button
import com.stripe.android.connect.appearance.Colors
import com.stripe.android.connect.appearance.CornerRadius
import com.stripe.android.connect.appearance.Form
import org.json.JSONObject
import java.util.Locale

object StripeConnectAppearanceFactory {
    fun buildAppearance(raw: Map<*, *>?): Appearance {
        val appearance = raw ?: emptyMap<Any?, Any?>()
        val primary = parseColor(appearance["primaryColor"] as? String, 0xFFFF6A00.toInt())
        val background = parseColor(appearance["backgroundColor"] as? String, 0xFFFCFDFE.toInt())
        val text = parseColor(appearance["textColor"] as? String, 0xFF0F131A.toInt())
        val secondaryText =
            parseColor(appearance["secondaryTextColor"] as? String, 0xFF616161)
        val danger = parseColor(appearance["dangerColor"] as? String, 0xFFE53D00.toInt())
        val border = parseColor(appearance["borderColor"] as? String, 0xFFE2E8F0.toInt())
        val formBackground =
            parseColor(appearance["formBackgroundColor"] as? String, 0xFFF3F3F3.toInt())
        val formAccent =
            parseColor(appearance["formAccentColor"] as? String, primary)
        val borderRadius = (appearance["borderRadius"] as? Number)?.toFloat() ?: 12f
        val spacingUnit = (appearance["spacingUnit"] as? Number)?.toFloat() ?: 8f

        return Appearance.Builder()
            .colors(
                Colors.Builder()
                    .primary(primary)
                    .background(background)
                    .text(text)
                    .secondaryText(secondaryText)
                    .danger(danger)
                    .border(border)
                    .offsetBackground(background)
                    .build()
            )
            .cornerRadius(
                CornerRadius.Builder()
                    .base(borderRadius)
                    .button(borderRadius)
                    .form(borderRadius)
                    .overlay(borderRadius)
                    .badge(borderRadius)
                    .build()
            )
            .spacingUnit(spacingUnit)
            .buttonPrimary(
                Button(
                    colorBackground = primary,
                    colorBorder = primary,
                    colorText = Color.WHITE,
                )
            )
            .buttonSecondary(
                Button(
                    colorBackground = formBackground,
                    colorBorder = border,
                    colorText = text,
                )
            )
            .form(
                Form.Builder()
                    .colorBackground(formBackground)
                    .accent(formAccent)
                    .build()
            )
            .build()
    }

    fun mergeAppearance(
        local: Map<*, *>?,
        remote: JSONObject?,
    ): Map<String, Any?> {
        val merged = mutableMapOf<String, Any?>()
        local?.forEach { (key, value) ->
            if (key is String && value != null) {
                merged[key] = value
            }
        }

        remote?.optJSONObject("appearance")?.let { remoteAppearance ->
            remoteAppearance.keys().forEach { key ->
                merged[key] = remoteAppearance.get(key)
            }
        }

        remote?.optJSONObject("onboarding")?.let { onboarding ->
            onboarding.optString("locale").takeIf { it.isNotBlank() }?.let {
                merged["locale"] = it
            }
            onboarding.optString("title").takeIf { it.isNotBlank() }?.let {
                merged["title"] = it
            }
            onboarding.optString("privacyPolicyUrl").takeIf { it.isNotBlank() }?.let {
                merged["privacyPolicyUrl"] = it
            }
            onboarding.optString("termsOfServiceUrl").takeIf { it.isNotBlank() }?.let {
                merged["termsOfServiceUrl"] = it
            }
        }

        return merged
    }

    fun applyLocale(activity: MainActivity, localeTag: String) {
        val locale = Locale.forLanguageTag(localeTag.replace('_', '-'))
        Locale.setDefault(locale)
        val config = Configuration(activity.resources.configuration)
        config.setLocales(LocaleList(locale))
        @Suppress("DEPRECATION")
        activity.resources.updateConfiguration(config, activity.resources.displayMetrics)
    }

    private fun parseColor(value: String?, fallback: Int): Int {
        if (value.isNullOrBlank()) {
            return fallback
        }

        return try {
            Color.parseColor(value)
        } catch (_: IllegalArgumentException) {
            fallback
        }
    }
}
