package com.example.flutter_wechat_plugin

import androidx.annotation.NonNull
import android.content.Context
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
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.modelmsg.SendMessageToWX
import com.tencent.mm.opensdk.modelmsg.WXTextObject
import com.tencent.mm.opensdk.modelmsg.WXImageObject
import com.tencent.mm.opensdk.modelmsg.WXWebpageObject
import com.tencent.mm.opensdk.modelmsg.WXMediaMessage

/** FlutterWechatPlugin */
class FlutterWechatPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var wxApi: IWXAPI? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_wechat_plugin")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
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
      "wechatLogin" -> {
        wechatLogin(result)
      }
      "shareText" -> {
        val text = call.argument<String>("text")
        if (text != null) {
          shareText(text, result)
        } else {
          result.error("INVALID_ARGUMENT", "Text is required", null)
        }
      }
      "shareImage" -> {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath != null) {
          shareImage(imagePath, result)
        } else {
          result.error("INVALID_ARGUMENT", "Image path is required", null)
        }
      }
      "shareLink" -> {
        val url = call.argument<String>("url")
        val title = call.argument<String>("title")
        val description = call.argument<String>("description")
        val thumbnailPath = call.argument<String>("thumbnailPath")
        if (url != null && title != null) {
          shareLink(url, title, description, thumbnailPath, result)
        } else {
          result.error("INVALID_ARGUMENT", "URL and title are required", null)
        }
      }
      "shareNetworkImage" -> {
        val imageUrl = call.argument<String>("imageUrl")
        if (imageUrl != null) {
          shareNetworkImage(imageUrl, result)
        } else {
          result.error("INVALID_ARGUMENT", "Image URL is required", null)
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

  private fun wechatLogin(result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat app is not registered", null)
      return
    }
    
    val req = SendAuth.Req()
    req.scope = "snsapi_userinfo"
    req.state = "wechat_sdk_demo_test"
    
    val success = wxApi?.sendReq(req) ?: false
    if (success) {
      result.success(null) // 实际结果会在回调中处理
    } else {
      result.error("LOGIN_FAILED", "Failed to send login request", null)
    }
  }

  private fun shareText(text: String, result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat app is not registered", null)
      return
    }
    
    val textObj = WXTextObject()
    textObj.text = text
    
    val msg = WXMediaMessage()
    msg.mediaObject = textObj
    msg.description = text
    
    val req = SendMessageToWX.Req()
    req.transaction = buildTransaction("text")
    req.message = msg
    req.scene = SendMessageToWX.Req.WXSceneSession
    
    val success = wxApi?.sendReq(req) ?: false
    result.success(success)
  }

  private fun shareImage(imagePath: String, result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat app is not registered", null)
      return
    }
    
    try {
      val file = File(imagePath)
      if (!file.exists()) {
        result.error("FILE_NOT_FOUND", "Image file not found", null)
        return
      }
      
      val bitmap = BitmapFactory.decodeFile(imagePath)
      if (bitmap == null) {
        result.error("INVALID_IMAGE", "Invalid image file", null)
        return
      }
      
      val imgObj = WXImageObject(bitmap)
      
      val msg = WXMediaMessage()
      msg.mediaObject = imgObj
      
      val thumbBmp = Bitmap.createScaledBitmap(bitmap, 150, 150, true)
      bitmap.recycle()
      msg.thumbData = bmpToByteArray(thumbBmp, true)
      
      val req = SendMessageToWX.Req()
      req.transaction = buildTransaction("img")
      req.message = msg
      req.scene = SendMessageToWX.Req.WXSceneSession
      
      val success = wxApi?.sendReq(req) ?: false
      result.success(success)
    } catch (e: Exception) {
      result.error("SHARE_ERROR", "Failed to share image: ${e.message}", null)
    }
  }

  private fun shareLink(url: String, title: String, description: String?, thumbnailPath: String?, result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat app is not registered", null)
      return
    }
    
    val webpage = WXWebpageObject()
    webpage.webpageUrl = url
    
    val msg = WXMediaMessage(webpage)
    msg.title = title
    msg.description = description ?: ""
    
    if (thumbnailPath != null) {
      try {
        val thumbBmp = BitmapFactory.decodeFile(thumbnailPath)
        if (thumbBmp != null) {
          msg.thumbData = bmpToByteArray(thumbBmp, true)
        }
      } catch (e: Exception) {
        // 忽略缩略图错误，继续分享
      }
    }
    
    val req = SendMessageToWX.Req()
    req.transaction = buildTransaction("webpage")
    req.message = msg
    req.scene = SendMessageToWX.Req.WXSceneSession
    
    val success = wxApi?.sendReq(req) ?: false
    result.success(success)
  }

  private fun buildTransaction(type: String): String {
    return type + System.currentTimeMillis()
  }

  private fun shareNetworkImage(imageUrl: String, result: Result) {
    if (wxApi == null) {
      result.error("NOT_REGISTERED", "WeChat app is not registered", null)
      return
    }
    
    // 使用协程在后台线程下载图片
    CoroutineScope(Dispatchers.IO).launch {
      try {
        val bitmap = downloadImage(imageUrl)
        if (bitmap != null) {
          // 切换到主线程进行微信分享
          withContext(Dispatchers.Main) {
            shareDownloadedImage(bitmap, result)
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
  
  private fun shareDownloadedImage(bitmap: Bitmap, result: Result) {
    try {
      val imgObj = WXImageObject(bitmap)
      
      val msg = WXMediaMessage()
      msg.mediaObject = imgObj
      
      val thumbBmp = Bitmap.createScaledBitmap(bitmap, 150, 150, true)
      msg.thumbData = bmpToByteArray(thumbBmp, true)
      
      val req = SendMessageToWX.Req()
      req.transaction = buildTransaction("img")
      req.message = msg
      req.scene = SendMessageToWX.Req.WXSceneSession
      
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

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
