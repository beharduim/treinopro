package com.treinopro.app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.lifecycle.lifecycleScope
import com.stripe.android.connect.AccountOnboardingProps
import com.stripe.android.connect.EmbeddedComponentManager
import com.stripe.android.connect.StripeComponentController.OnDismissListener
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterFragmentActivity() {
    private var stripeConnectChannel: MethodChannel? = null
    private var stripeEmbeddedComponentManager: EmbeddedComponentManager? = null
    private var stripeOnboardingResult: MethodChannel.Result? = null
    private var stripeConfig: StripeConnectConfig? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        EmbeddedComponentManager.onActivityCreate(this)
        applyLockScreenFlags()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        stripeConnectChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.treinopro.oficial/stripe_connect"
        )
        stripeConnectChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "presentEmbeddedOnboarding" -> handlePresentStripeOnboarding(call, result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        applyLockScreenFlags()
    }

    private fun applyLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    private fun handlePresentStripeOnboarding(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (stripeOnboardingResult != null) {
            result.error(
                "stripe_onboarding_in_progress",
                "Já existe um onboarding de recebimento em andamento.",
                null
            )
            return
        }

        val publishableKey = call.argument<String>("publishableKey")
        val baseUrl = call.argument<String>("baseUrl")
        val accessToken = call.argument<String>("accessToken")
        val locale = call.argument<String>("locale") ?: "pt-BR"
        val localAppearance = call.argument<Map<String, Any?>>("appearance")

        if (publishableKey.isNullOrBlank() || baseUrl.isNullOrBlank() || accessToken.isNullOrBlank()) {
            result.error(
                "stripe_onboarding_invalid_arguments",
                "Parâmetros inválidos para iniciar o onboarding do Stripe.",
                null
            )
            return
        }

        StripeConnectAppearanceFactory.applyLocale(this, locale)
        stripeOnboardingResult = result

        val newConfig = StripeConnectConfig(
            publishableKey = publishableKey,
            baseUrl = baseUrl.trimEnd('/'),
            accessToken = accessToken,
            locale = locale,
            localAppearance = localAppearance,
        )

        lifecycleScope.launch {
            try {
                val sessionPayload = withContext(Dispatchers.IO) {
                    fetchAccountSessionPayload(
                        baseUrl = newConfig.baseUrl,
                        accessToken = newConfig.accessToken,
                    )
                }

                if (sessionPayload == null) {
                    failStripeOnboarding(
                        "stripe_onboarding_session_failed",
                        "Não foi possível iniciar a sessão de onboarding do Stripe.",
                    )
                    return@launch
                }

                val mergedAppearance = StripeConnectAppearanceFactory.mergeAppearance(
                    local = newConfig.localAppearance,
                    remote = sessionPayload,
                )
                val resolvedConfig = newConfig.copy(localAppearance = mergedAppearance)
                val appearance =
                    StripeConnectAppearanceFactory.buildAppearance(mergedAppearance)

                if (
                    stripeEmbeddedComponentManager == null ||
                    stripeConfig?.publishableKey != resolvedConfig.publishableKey ||
                    stripeConfig?.baseUrl != resolvedConfig.baseUrl ||
                    stripeConfig?.accessToken != resolvedConfig.accessToken
                ) {
                    stripeConfig = resolvedConfig
                    stripeEmbeddedComponentManager = EmbeddedComponentManager(
                        publishableKey = publishableKey,
                        fetchClientSecret = {
                            fetchAccountSessionPayload(
                                baseUrl = resolvedConfig.baseUrl,
                                accessToken = resolvedConfig.accessToken,
                            )?.optString("clientSecret")?.takeIf { it.isNotBlank() }
                        },
                        appearance = appearance,
                    )
                } else {
                    stripeConfig = resolvedConfig
                    stripeEmbeddedComponentManager?.update(appearance)
                }

                val onboardingTitle =
                    (mergedAppearance["title"] as? String)?.takeIf { it.isNotBlank() }
                        ?: "Configurar recebimento"
                val onboardingProps = buildAccountOnboardingProps(mergedAppearance)

                val controller = stripeEmbeddedComponentManager
                    ?.createAccountOnboardingController(
                        activity = this@MainActivity,
                        title = onboardingTitle,
                        props = onboardingProps,
                    )
                    ?.apply {
                        onDismissListener = OnDismissListener {
                            stripeOnboardingResult?.success(null)
                            stripeOnboardingResult = null
                        }
                    }

                if (controller == null) {
                    failStripeOnboarding(
                        "stripe_onboarding_unavailable",
                        "Não foi possível criar o controller de onboarding do Stripe.",
                    )
                    return@launch
                }

                controller.show()
            } catch (error: Throwable) {
                failStripeOnboarding(
                    "stripe_onboarding_failed",
                    error.message ?: "Falha ao abrir o onboarding do Stripe.",
                )
            }
        }
    }

    private fun failStripeOnboarding(code: String, message: String) {
        stripeOnboardingResult?.error(code, message, null)
        stripeOnboardingResult = null
    }

    private fun buildAccountOnboardingProps(
        appearance: Map<String, Any?>?,
    ): AccountOnboardingProps {
        val privacyPolicyUrl = appearance?.get("privacyPolicyUrl") as? String
        val termsOfServiceUrl = appearance?.get("termsOfServiceUrl") as? String

        return AccountOnboardingProps(
            fullTermsOfServiceUrl = termsOfServiceUrl,
            recipientTermsOfServiceUrl = termsOfServiceUrl,
            privacyPolicyUrl = privacyPolicyUrl,
        )
    }

    private fun fetchAccountSessionPayload(
        baseUrl: String,
        accessToken: String,
    ): JSONObject? {
        return try {
            val connection = URL(
                "$baseUrl/payments/profile/financial/stripe/account-session"
            ).openConnection() as HttpURLConnection

            connection.requestMethod = "POST"
            connection.setRequestProperty("Authorization", "Bearer $accessToken")
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Accept-Language", "pt-BR,pt;q=0.9")
            connection.connectTimeout = 15000
            connection.readTimeout = 15000
            connection.doOutput = true
            connection.outputStream.use { output ->
                output.write(ByteArray(0))
            }

            val stream = if (connection.responseCode in 200..299) {
                connection.inputStream
            } else {
                connection.errorStream
            }

            val responseBody = stream?.use { input ->
                BufferedReader(InputStreamReader(input)).readText()
            }.orEmpty()

            if (connection.responseCode !in 200..299) {
                null
            } else {
                JSONObject(responseBody).optJSONObject("data")
            }
        } catch (_: Throwable) {
            null
        }
    }

    private data class StripeConnectConfig(
        val publishableKey: String,
        val baseUrl: String,
        val accessToken: String,
        val locale: String,
        val localAppearance: Map<String, Any?>?,
    )
}
