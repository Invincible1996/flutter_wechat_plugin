package com.example.flutter_wechat_plugin

import androidx.annotation.NonNull
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.*

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelmsg.SendMessageToWX
import com.tencent.mm.opensdk.modelmsg.WXImageObject
import com.tencent.mm.opensdk.modelmsg.WXMediaMessage
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.modelbiz.WXLaunchMiniProgram
import com.tencent.mm.opensdk.modelmsg.WXTextObject
import com.tencent.mm.opensdk.modelmsg.WXWebpageObject

/** FlutterWechatPlugin */
class FlutterWechatPlugin: FlutterPlugin, MethodCallHandler, IWXAPIEventHandler {
  companion object {
    private var instance: FlutterWechatPlugin? = null
    private var wxApi: IWXAPI? = null

    @JvmStatic
    fun handleIntent(intent: Intent) {
        instance?.let {
            wxApi?.handleIntent(intent, it)
        }
    }
  }

  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var pendingLoginResult: Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_wechat_plugin")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    instance = this
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "registerApp" -> {
        val appId = call.argument<String>("appId")
        if (appId != null) {
          registerApp(appId, result)
        } else {
          result.error("INVALID_ARGUMENT", "App ID is required", null)
        }
      }
      "isWechatInstalled" -> {
        val isInstalled = wxApi?.isWXAppInstalled ?: false
        Log.d("FlutterWechatPlugin", "WeChat installed check: $isInstalled")
        Log.d("FlutterWechatPlugin", "WeChat API instance: ${wxApi != null}")
        result.success(isInstalled)
      }
      "shareNetworkImage" -> {
        val imageUrl = call.argument<String>("imageUrl")
        if (imageUrl != null) {
          shareNetworkImage(imageUrl, result)
        } else {
          result.error("INVALID_ARGUMENT", "Image URL is required", null)
        }
      }
      "shareNetworkImageToScene" -> {
        val imageUrl = call.argument<String>("imageUrl")
        val scene = call.argument<Int>("scene")
        if (imageUrl != null && scene != null) {
          shareNetworkImageToScene(imageUrl, scene, result)
        } else {
          result.error("INVALID_ARGUMENT", "Image URL and scene are required", null)
        }
      }
      "wechatLogin" -> {
        wechatLogin(result)
      }
      "openMiniProgram" -> {
        val username = call.argument<String>("username")
        val path = call.argument<String>("path")
        val miniProgramType = call.argument<Int>("miniProgramType") ?: 0
        if (username != null && path != null) {
          openMiniProgram(username, path, miniProgramType, result)
        } else {
          result.error("INVALID_ARGUMENT", "Username and path are required", null)
        }
      }
      "shareImage" -> {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath != null) {
          shareLocalImage(imagePath, result)
        } else {
          result.error("INVALID_ARGUMENT", "Image path is required", null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun registerApp(appId: String, result: Result) {
    Log.d("FlutterWechatPlugin", "Registering WeChat app with ID: $appId")
    wxApi = WXAPIFactory.createWXAPI(context, appId, true)
    val success = wxApi?.registerApp(appId) ?: false
    Log.d("FlutterWechatPlugin", "WeChat registration result: $success")
    result.success(success)
  }

  // IWXAPIEventHandler implementation
  override fun onReq(req: BaseReq) {
    Log.d("FlutterWechatPlugin", "onReq: ${req.type}")
    // Handle WeChat requests
  }

  override fun onResp(resp: BaseResp) {
    Log.d("FlutterWechatPlugin", "onResp: ${resp.type}, errCode: ${resp.errCode}")

    when (resp.type) {
      1 -> { // WeChat login response
        if (resp is SendAuth.Resp) {
          handleWeChatLoginResponse(resp)
        }
      }
      2 -> { // Share response
        if (resp is SendMessageToWX.Resp) {
          Log.d("FlutterWechatPlugin", "Share response: errCode=${resp.errCode}")
          val eventData = mapOf(
            "type" to "share",
            "errCode" to resp.errCode,
            "errStr" to (resp.errStr ?: "")
          )
          channel.invokeMethod("onWeChatResponse", eventData)
        }
      }
      19 -> { // Launch mini program response
        if (resp is WXLaunchMiniProgram.Resp) {
          handleLaunchMiniProgramResponse(resp)
        }
      }
      // Other response types can be handled here
    }
  }

  private fun handleLaunchMiniProgramResponse(resp: WXLaunchMiniProgram.Resp) {
    Log.d("FlutterWechatPlugin", "Launch mini program response: errCode=${resp.errCode}")
    val eventData = mapOf(
      "type" to "launchMiniProgram",
      "errCode" to resp.errCode,
      "errStr" to (resp.errStr ?: ""),
      "extMsg" to (resp.extMsg ?: "")
    )
    channel.invokeMethod("onWeChatResponse", eventData)
  }


  private fun buildTransaction(type: String): String {
    return type + System.currentTimeMillis()
  }

  private fun wechatLogin(result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat app is not registered", null)
      return
    }

    if (!wxApi!!.isWXAppInstalled) {
      result.error("NOT_INSTALLED", "WeChat app is not installed", null)
      return
    }

    val req = SendAuth.Req()
    req.scope = "snsapi_userinfo"
    req.state = "wechat_sdk_demo_test"

    val success = wxApi!!.sendReq(req)
    if (success) {
      // Store result to use in callback
      pendingLoginResult = result
    } else {
      result.error("SEND_FAILED", "Failed to send login request", null)
    }
  }

  private fun shareNetworkImage(imageUrl: String, result: Result) {
    shareNetworkImageToScene(imageUrl, SendMessageToWX.Req.WXSceneSession, result)
  }

  private fun shareNetworkImageToScene(imageUrl: String, scene: Int, result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat app is not registered", null)
      return
    }

    CoroutineScope(Dispatchers.IO).launch {
      try {
        val bitmap = downloadImage(imageUrl)
        if (bitmap != null) {
          withContext(Dispatchers.Main) {
            shareDownloadedImage(bitmap, scene, result)
          }
        } else {
          withContext(Dispatchers.Main) {
            result.error("DOWNLOAD_FAILED", "Failed to download image", null)
          }
        }
      } catch (e: Exception) {
        withContext(Dispatchers.Main) {
          result.error("DOWNLOAD_ERROR", "Error downloading image: ${e.message}", null)
        }
      }
    }
  }

  }
  }

  private fun shareLocalImage(imagePath: String, result: Result) {
    val file = File(imagePath)
    if (!file.exists()) {
      result.error("FILE_NOT_FOUND", "Image file not found at path: $imagePath", null)
      return
    }

    try {
      val bitmap = BitmapFactory.decodeFile(imagePath)
      if (bitmap == null) {
        result.error("DECODE_FAILED", "Failed to decode image file", null)
        return
      }
      shareDownloadedImage(bitmap, SendMessageToWX.Req.WXSceneSession, result)
    } catch (e: Exception) {
      result.error("SHARE_ERROR", "Failed to share local image: ${e.message}", null)
    }
  }

  private fun downloadImage(imageUrl: String): Bitmap? {
    return try {
      val url = URL(imageUrl)
      val connection = url.openConnection() as HttpURLConnection
      connection.doInput = true
      connection.connect()
      val inputStream: InputStream = connection.inputStream
      BitmapFactory.decodeStream(inputStream)
    } catch (e: Exception) {
      Log.e("FlutterWechatPlugin", "Error downloading image: ${e.message}")
      null
    }
  }

  private fun shareDownloadedImage(bitmap: Bitmap, scene: Int, result: Result) {
    try {
      val imgObj = WXImageObject(bitmap)

      val msg = WXMediaMessage()
      msg.mediaObject = imgObj

      val thumbBmp = Bitmap.createScaledBitmap(bitmap, 150, 150, true)
      msg.thumbData = bmpToByteArray(thumbBmp, true)

      val req = SendMessageToWX.Req()
      req.transaction = buildTransaction("img")
      req.message = msg
      req.scene = scene

      val success = wxApi?.sendReq(req) ?: false
      result.success(success)
    } catch (e: Exception) {
      result.error("SHARE_ERROR", "Failed to share image: ${e.message}", null)
    }
  }

  private fun bmpToByteArray(bmp: Bitmap, needRecycle: Boolean): ByteArray {
    val output = java.io.ByteArrayOutputStream()
    bmp.compress(Bitmap.CompressFormat.PNG, 100, output)
    if (needRecycle) {
      bmp.recycle()
    }
    val result = output.toByteArray()
    try {
      output.close()
    } catch (e: Exception) {
      e.printStackTrace()
    }
    return result
  }

  private fun openMiniProgram(username: String, path: String, miniProgramType: Int, result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat API not registered", null)
      return
    }

    if (!wxApi!!.isWXAppInstalled) {
      result.error("NOT_INSTALLED", "WeChat app is not installed", null)
      return
    }

    val req = WXLaunchMiniProgram.Req()
    req.userName = username // 小程序原始id
    req.path = path // 拉起小程序页面的可带参路径，不填默认拉起小程序首页
    req.miniprogramType = when (miniProgramType) {
      1 -> WXLaunchMiniProgram.Req.MINIPROGRAM_TYPE_TEST
      2 -> WXLaunchMiniProgram.Req.MINIPROGRAM_TYPE_PREVIEW
      else -> WXLaunchMiniProgram.Req.MINIPTOGRAM_TYPE_RELEASE
    } // 可选打开 开发版，体验版和正式版

    val success = wxApi!!.sendReq(req)
    result.success(success)
  }

  private fun handleWeChatLoginResponse(resp: SendAuth.Resp) {
    val result = pendingLoginResult
    pendingLoginResult = null

    Log.d("FlutterWechatPlugin", "WeChat login response: errCode=${resp.errCode}, code=${resp.code}")

    val eventData = mutableMapOf<String, Any?>(
      "type" to "auth",
      "errCode" to resp.errCode
    )

    when (resp.errCode) {
      0 -> { // Success
        eventData["code"] = resp.code
        eventData["state"] = resp.state
        eventData["lang"] = resp.lang
        eventData["country"] = resp.country

        result?.success(mapOf(
          "code" to resp.code,
          "state" to resp.state,
          "lang" to resp.lang,
          "country" to resp.country
        ))
      }
      -2 -> { // User cancelled
        eventData["errStr"] = "User cancelled login"
        result?.error("USER_CANCELLED", "User cancelled login", null)
      }
      -4 -> { // Auth denied
        eventData["errStr"] = "User denied authorization"
        result?.error("AUTH_DENIED", "User denied authorization", null)
      }
      else -> { // Other errors
        eventData["errStr"] = "Login failed with error code: ${resp.errCode}"
        result?.error("LOGIN_FAILED", "Login failed with error code: ${resp.errCode}", null)
      }
    }

    channel.invokeMethod("onWeChatResponse", eventData)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    instance = null
  }
}
