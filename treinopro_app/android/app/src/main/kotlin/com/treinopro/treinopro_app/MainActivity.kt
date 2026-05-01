package com.treinopro.app

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import com.stripe.android.connect.AccountOnboardingProps
import com.stripe.android.connect.EmbeddedComponentManager
import com.stripe.android.connect.StripeComponentController.OnDismissListener
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
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

        if (publishableKey.isNullOrBlank() || baseUrl.isNullOrBlank() || accessToken.isNullOrBlank()) {
            result.error(
                "stripe_onboarding_invalid_arguments",
                "Parâmetros inválidos para iniciar o onboarding do Stripe.",
                null
            )
            return
        }

        val newConfig = StripeConnectConfig(
            publishableKey = publishableKey,
            baseUrl = baseUrl.trimEnd('/'),
            accessToken = accessToken
        )

        if (stripeEmbeddedComponentManager == null || stripeConfig != newConfig) {
            stripeConfig = newConfig
            stripeEmbeddedComponentManager = EmbeddedComponentManager(
                publishableKey = publishableKey,
                fetchClientSecret = {
                    fetchClientSecret(
                        baseUrl = newConfig.baseUrl,
                        accessToken = newConfig.accessToken
                    )
                }
            )
        }

        try {
            val controller = stripeEmbeddedComponentManager
                ?.createAccountOnboardingController(
                    activity = this,
                    title = "Configurar recebimento",
                    props = AccountOnboardingProps()
                )
                ?.apply {
                    onDismissListener = OnDismissListener {
                        stripeOnboardingResult?.success(null)
                        stripeOnboardingResult = null
                    }
                }

            if (controller == null) {
                result.error(
                    "stripe_onboarding_unavailable",
                    "Não foi possível criar o controller de onboarding do Stripe.",
                    null
                )
                return
            }

            stripeOnboardingResult = result
            controller.show()
        } catch (error: Throwable) {
            stripeOnboardingResult = null
            result.error(
                "stripe_onboarding_failed",
                error.message ?: "Falha ao abrir o onboarding do Stripe.",
                null
            )
        }
    }

    private suspend fun fetchClientSecret(
        baseUrl: String,
        accessToken: String
    ): String? {
        return try {
            val connection = URL(
                "$baseUrl/payments/profile/financial/stripe/account-session"
            ).openConnection() as HttpURLConnection

            connection.requestMethod = "POST"
            connection.setRequestProperty("Authorization", "Bearer $accessToken")
            connection.setRequestProperty("Content-Type", "application/json")
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
                JSONObject(responseBody)
                    .optJSONObject("data")
                    ?.optString("clientSecret")
                    ?.takeIf { it.isNotBlank() }
            }
        } catch (_: Throwable) {
            null
        }
    }

    private data class StripeConnectConfig(
        val publishableKey: String,
        val baseUrl: String,
        val accessToken: String
    )
}
