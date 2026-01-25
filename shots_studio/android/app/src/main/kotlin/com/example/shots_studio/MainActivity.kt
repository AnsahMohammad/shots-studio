package com.ansah.shots_studio

import android.app.Activity
import android.app.RecoverableSecurityException
import android.content.ContentUris
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val UPDATE_CHANNEL = "update_installer"
    private val MEDIA_DELETE_CHANNEL = "media_delete"
    private val INSTALL_REQUEST_CODE = 1001
    private val DELETE_REQUEST_CODE = 1002
    
    // Pending result for async delete operations
    private var pendingDeleteResult: MethodChannel.Result? = null
    private var pendingDeletePaths: List<String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Update installer channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    result.success(canRequestPackageInstalls())
                }
                "requestInstallPermission" -> {
                    requestInstallPermission()
                    result.success(true)
                }
                "installApk" -> {
                    val apkPath = call.argument<String>("apkPath")
                    if (apkPath != null) {
                        try {
                            installApk(apkPath)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "APK path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Media delete channel - for batch deleting media files with single confirmation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_DELETE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "deleteMediaFiles" -> {
                    val filePaths = call.argument<List<String>>("filePaths")
                    if (filePaths != null && filePaths.isNotEmpty()) {
                        deleteMediaFiles(filePaths, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "File paths list is required and cannot be empty", null)
                    }
                }
                "isSupported" -> {
                    // Batch delete with single dialog is supported on Android 11+
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.R)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // AiCore / ML Kit GenAI Image Description Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ansah.shots_studio/ai_core").setMethodCallHandler { call, result ->
            val buildSource = BuildConfig.BUILD_SOURCE
            if (buildSource == "fdroid") {
                 if (call.method == "isAiCoreSupported") {
                     result.success(false)
                 } else {
                     result.error("UNSUPPORTED", "AiCore is not available in F-Droid builds due to proprietary dependencies.", null)
                 }
                 return@setMethodCallHandler
            }

            // For non-fdroid builds, proceed with ML Kit logic
            // Note: Classes will be missing in F-Droid build if we don't guard this, 
            // but since we separate dependencies by flavor, the code path needs to be safe.
            // However, kotlin code is compiled for all flavors. If the dependency is missing for fdroid, 
            // any reference to ML Kit classes will cause compilation error for fdroid flavor.
            // This is a problem. We need to use reflection or separate source sets.
            // Ideally, we should use source sets (src/playstore/kotlin/...), but that requires moving this file or splitting it.
            // For now, assuming the user will build playstore/github flavors mainly, or we use reflection.
            // Wait, if I use flavor specific dependencies, 'fdroid' build will FAIL to compile this file 
            // because imports com.google.mlkit... won't be resolved.
            // 
            // FIX: I must use reflection to access ML Kit classes to ensure it compiles for F-Droid (where dependency is missing).
            
            when (call.method) {
                "isAiCoreSupported" -> {
                    checkAiCoreSupport(result)
                }
                "generateDescriptionWithAiCore" -> {
                    val imagePath = call.argument<String>("imagePath")
                    if (imagePath != null) {
                        generateImageDescriptionWithAiCore(imagePath, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Image path is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun deleteMediaFiles(filePaths: List<String>, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ - Use MediaStore.createDeleteRequest for batch delete with single dialog
            try {
                val uris = mutableListOf<Uri>()
                
                for (path in filePaths) {
                    val uri = getMediaUriFromPath(path)
                    if (uri != null) {
                        uris.add(uri)
                    }
                }
                
                if (uris.isEmpty()) {
                    result.success(mapOf(
                        "success" to false,
                        "deletedCount" to 0,
                        "error" to "No valid media URIs found for the given paths"
                    ))
                    return
                }
                
                // Store pending result for onActivityResult callback
                pendingDeleteResult = result
                pendingDeletePaths = filePaths
                
                // Create delete request with all URIs - shows single confirmation dialog
                val pendingIntent = MediaStore.createDeleteRequest(contentResolver, uris)
                startIntentSenderForResult(
                    pendingIntent.intentSender,
                    DELETE_REQUEST_CODE,
                    null,
                    0,
                    0,
                    0
                )
                
            } catch (e: Exception) {
                result.success(mapOf(
                    "success" to false,
                    "deletedCount" to 0,
                    "error" to "Error creating delete request: ${e.message}"
                ))
            }
        } else {
            // Android 10 and below - Use direct file deletion
            var deletedCount = 0
            var errorMessage: String? = null
            
            for (path in filePaths) {
                try {
                    val file = File(path)
                    if (file.exists() && file.delete()) {
                        deletedCount++
                        // Also remove from MediaStore
                        contentResolver.delete(
                            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                            "${MediaStore.Images.Media.DATA}=?",
                            arrayOf(path)
                        )
                    }
                } catch (e: Exception) {
                    errorMessage = e.message
                }
            }
            
            val allDeleted = deletedCount == filePaths.size
            result.success(mapOf(
                "success" to allDeleted,
                "deletedCount" to deletedCount,
                "totalRequested" to filePaths.size,
                "error" to errorMessage
            ))
        }
    }
    
    private fun getMediaUriFromPath(path: String): Uri? {
        // Query MediaStore to get the URI for a file path
        val projection = arrayOf(MediaStore.Images.Media._ID)
        val selection = "${MediaStore.Images.Media.DATA}=?"
        val selectionArgs = arrayOf(path)
        
        contentResolver.query(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
                val id = cursor.getLong(idColumn)
                return ContentUris.withAppendedId(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id)
            }
        }
        
        return null
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == DELETE_REQUEST_CODE) {
            val result = pendingDeleteResult
            val paths = pendingDeletePaths
            pendingDeleteResult = null
            pendingDeletePaths = null
            
            if (result != null) {
                if (resultCode == Activity.RESULT_OK) {
                    // User approved deletion
                    result.success(mapOf(
                        "success" to true,
                        "deletedCount" to (paths?.size ?: 0),
                        "totalRequested" to (paths?.size ?: 0),
                        "userApproved" to true
                    ))
                } else {
                    // User denied deletion
                    result.success(mapOf(
                        "success" to false,
                        "deletedCount" to 0,
                        "totalRequested" to (paths?.size ?: 0),
                        "userApproved" to false,
                        "error" to "User denied deletion request"
                    ))
                }
            }
        }
    }

    private fun canRequestPackageInstalls(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true // On older versions, this permission is granted by default
        }
    }

    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (!packageManager.canRequestPackageInstalls()) {
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivityForResult(intent, INSTALL_REQUEST_CODE)
            }
        }
    }

    private fun installApk(apkPath: String) {
        val apkFile = File(apkPath)
        if (!apkFile.exists()) {
            throw Exception("APK file not found: $apkPath")
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Use FileProvider for Android N and above
                val apkUri = FileProvider.getUriForFile(
                    this@MainActivity,
                    "$packageName.fileprovider",
                    apkFile
                )
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                // Direct file access for older versions
                setDataAndType(Uri.fromFile(apkFile), "application/vnd.android.package-archive")
            }
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(intent)
    }

    // AiCore Implementation using Reflection to support F-Droid builds (where dependency is missing)
    private var imageDescriber: Any? = null
    
    // Helper to find method in hierarchy
    private fun findMethodRecursive(clazz: Class<*>, name: String, paramCount: Int): java.lang.reflect.Method? {
        var current: Class<*>? = clazz
        while (current != null) {
            try {
                 val methods = current.declaredMethods
                 val match = methods.find { it.name == name && it.parameterTypes.size == paramCount }
                 if (match != null) {
                     match.isAccessible = true
                     return match
                 }
            } catch (e: Exception) { }
            current = current.superclass
        }
        try {
             val methods = clazz.methods
             val match = methods.find { it.name == name && it.parameterTypes.size == paramCount }
             if (match != null) return match
        } catch (e: Exception) {}
        return null
    }
    
    // Generic helper to listen to Task or ListenableFuture via Reflection
    private fun listenToFuture(future: Any, onSuccess: (Any?) -> Unit, onFailure: (Exception) -> Unit) {
        try {
            // Strategy 1: ListenableFuture (addListener)
            // Found in beta1 logs: addListener(Runnable, Executor) to support Guava/ListenableFuture style
            val addListenerMethod = findMethodRecursive(future.javaClass, "addListener", 2)
            
            if (addListenerMethod != null) {
                val executor = java.util.concurrent.Executor { command -> 
                    android.os.Handler(android.os.Looper.getMainLooper()).post(command)
                }
                
                val runnable = Runnable {
                    try {
                        val getMethod = future.javaClass.getMethod("get")
                        val result = getMethod.invoke(future)
                        onSuccess(result)
                    } catch (e: Exception) {
                        // Unpack InvocationTargetException
                        val cause = if (e is java.lang.reflect.InvocationTargetException) e.cause else e
                        // Check for ExecutionException
                        val realException = if (cause is java.util.concurrent.ExecutionException) cause.cause else cause
                        onFailure(realException as? Exception ?: Exception(realException))
                    }
                }
                
                addListenerMethod.invoke(future, runnable, executor)
                return
            }

            // Strategy 2: Task (addOnSuccessListener)
            // Fallback for standard GMS Tasks
            // Use findMethodRecursive to handle internal default implementations
            val onSuccessMethod = findMethodRecursive(future.javaClass, "addOnSuccessListener", 1)
            val onFailureMethod = findMethodRecursive(future.javaClass, "addOnFailureListener", 1)
            
            if (onSuccessMethod != null && onFailureMethod != null) {
                 // Success Listener
                 val onSuccessListenerClass = Class.forName("com.google.android.gms.tasks.OnSuccessListener")
                 val successProxy = java.lang.reflect.Proxy.newProxyInstance(
                    onSuccessListenerClass.classLoader,
                    arrayOf(onSuccessListenerClass)
                 ) { _, method, args ->
                    if (method.name == "onSuccess") onSuccess(args?.get(0))
                    null
                 }
                 onSuccessMethod.invoke(future, successProxy)
                 
                 // Failure Listener
                 val onFailureListenerClass = Class.forName("com.google.android.gms.tasks.OnFailureListener")
                 val failureProxy = java.lang.reflect.Proxy.newProxyInstance(
                    onFailureListenerClass.classLoader,
                    arrayOf(onFailureListenerClass)
                 ) { _, method, args ->
                    if (method.name == "onFailure") {
                        val exception = args?.get(0) as? Exception ?: Exception("Unknown error")
                        onFailure(exception)
                    }
                    null
                 }
                 onFailureMethod.invoke(future, failureProxy)
                 return
            }
            
            android.util.Log.e("AiCore", "Unknown async object type: ${future.javaClass.name} - neither Task nor ListenableFuture")
            onFailure(Exception("Unknown async object type: ${future.javaClass.name}"))

        } catch (e: Exception) {
            android.util.Log.e("AiCore", "Failed to attach listener", e)
            onFailure(e)
        }
    }



    // Helper to add failure listener via reflection
    private fun addOnFailureListener(task: Any, callback: (Exception) -> Unit) {
        try {
            val onFailureListenerClass = Class.forName("com.google.android.gms.tasks.OnFailureListener")
            val listenerProxy = java.lang.reflect.Proxy.newProxyInstance(
                onFailureListenerClass.classLoader,
                arrayOf(onFailureListenerClass)
            ) { _, method, args ->
                if (method.name == "onFailure") {
                    val exception = args?.get(0) as? Exception ?: Exception("Unknown error")
                    callback(exception)
                }
                null
            }
            
            val method = findMethodRecursive(task.javaClass, "addOnFailureListener", 1)
            
            if (method != null) {
                method.invoke(task, listenerProxy)
                android.util.Log.d("AiCore", "Added failure listener successfully")
            } else {
                android.util.Log.e("AiCore", "Could not find addOnFailureListener method on ${task.javaClass.name} or parents")
            }
        } catch (e: Exception) {
            android.util.Log.e("AiCore", "Failed to add failure listener", e)
            e.printStackTrace()
        }
    }

    private fun checkAiCoreSupport(result: MethodChannel.Result) {
        android.util.Log.d("AiCore", "checkAiCoreSupport called on Android SDK: ${Build.VERSION.SDK_INT}")
        
        // ML Kit GenAI requires Android API 26 (Oreo) or higher
        // We forced build with overrideLibrary, so we must safely return false on older devices
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            android.util.Log.e("AiCore", "SDK version too low for AiCore")
            result.success(false)
            return
        }

        try {
            // Check if ML Kit class exists (it won't in F-Droid flavor)
            val optionsClass = Class.forName("com.google.mlkit.genai.imagedescription.ImageDescriberOptions")
            val imageDescriptionClass = Class.forName("com.google.mlkit.genai.imagedescription.ImageDescription")
            
            android.util.Log.d("AiCore", "ML Kit classes found via reflection")

            // Initialize describer if needed
            if (imageDescriber == null) {
                val builderMethod = optionsClass.getMethod("builder", android.content.Context::class.java)
                val builder = builderMethod.invoke(null, context)
                val buildMethod = builder.javaClass.getMethod("build")
                val options = buildMethod.invoke(builder)
                
                val getClientMethod = imageDescriptionClass.getMethod("getClient", optionsClass)
                imageDescriber = getClientMethod.invoke(null, options)
                android.util.Log.d("AiCore", "ImageDescriber initialized")
            }
            
            val describer = imageDescriber 
            if (describer == null) {
                 android.util.Log.e("AiCore", "Failed to initialize ImageDescriber (is null)")
                 return result.error("INIT_ERROR", "Failed to initialize ImageDescriber", null)
            }
            
            // checkFeatureStatus() returns a Task<FeatureStatus>
            val checkStatusMethod = describer.javaClass.getMethod("checkFeatureStatus")
            val task = checkStatusMethod.invoke(describer)
            
            if (task == null) {
                android.util.Log.e("AiCore", "checkFeatureStatus task is null")
                result.error("TASK_ERROR", "checkFeatureStatus returned null", null)
                return
            }
            
            listenToFuture(task, { featureStatus ->
                // featureStatus is an object (likely Enum or Int, but we use toString for safety)
                val statusString = featureStatus.toString()
                android.util.Log.d("AiCore", "Feature Status received: $statusString")
                
                // User requirement: "if possible allow it... if returns false say device not supported"
                // So DOWNLOADABLE, DOWNLOADING, AVAILABLE are "supported".
                
                val isSupported = !statusString.contains("UNAVAILABLE")
                android.util.Log.d("AiCore", "Is AiCore Supported? $isSupported")
                
                result.success(isSupported)
            }, { e ->
                android.util.Log.e("AiCore", "checkFeatureStatus task failed", e)
                result.error("CHECK_ERROR", e.message, null)
            })
            
        } catch (e: ClassNotFoundException) {
            // Dependency missing (F-Droid build)
            android.util.Log.w("AiCore", "ML Kit classes NOT found (Expected for F-Droid)")
            result.success(false)
        } catch (e: Exception) {
            android.util.Log.e("AiCore", "Exception in checkAiCoreSupport", e)
            result.error("REFLECTION_ERROR", e.message, null)
        }
    }
    
    private fun generateImageDescriptionWithAiCore(imagePath: String, result: MethodChannel.Result) {
        try {
            val describer = imageDescriber
            if (describer == null) {
                // Try initialization again
                try {
                    val optionsClass = Class.forName("com.google.mlkit.genai.imagedescription.ImageDescriberOptions")
                    val imageDescriptionClass = Class.forName("com.google.mlkit.genai.imagedescription.ImageDescription")
                    val builderMethod = optionsClass.getMethod("builder", android.content.Context::class.java)
                    val builder = builderMethod.invoke(null, context)
                    val buildMethod = builder.javaClass.getMethod("build")
                    val options = buildMethod.invoke(builder)
                    val getClientMethod = imageDescriptionClass.getMethod("getClient", optionsClass)
                    imageDescriber = getClientMethod.invoke(null, options)
                } catch (e: Exception) {
                    result.error("INIT_ERROR", "Could not initialize ML Kit: ${e.message}", null)
                    return
                }
            }
            
            val safeDescriber = imageDescriber ?: return result.error("STATE_ERROR", "ImageDescriber is null", null)

            // Load Bitmap
            val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
            if (bitmap == null) {
                result.error("IMAGE_ERROR", "Failed to decode image at $imagePath", null)
                return
            }
            
            // ImageDescriptionRequest.builder(bitmap).build()
            val requestClass = Class.forName("com.google.mlkit.genai.imagedescription.ImageDescriptionRequest")
            val builderMethod = requestClass.getMethod("builder", android.graphics.Bitmap::class.java)
            val builder = builderMethod.invoke(null, bitmap)
            val buildMethod = builder.javaClass.getMethod("build")
            val request = buildMethod.invoke(builder)
            
            // runInference(request)
            val runInferenceMethod = safeDescriber.javaClass.getMethod("runInference", requestClass)
            val task = runInferenceMethod.invoke(safeDescriber, request)
            
            if (task == null) {
                result.error("TASK_ERROR", "runInference returned null", null)
                return
            }
            
            listenToFuture(task, { response ->
                try {
                    if (response == null) {
                         result.error("RESPONSE_ERROR", "Inference response is null", null)
                         return@listenToFuture
                    }
                    val getDescriptionMethod = response.javaClass.getMethod("getDescription")
                    val description = getDescriptionMethod.invoke(response) as String
                    result.success(description)
                } catch (e: Exception) {
                    result.error("PARSE_ERROR", "Failed to parse response: ${e.message}", null)
                }
            }, { e ->
               result.error("INFERENCE_ERROR", "Analysis failed: ${e.message}", null)
            })
            
        } catch (e: Exception) {
             result.error("EXECUTION_ERROR", e.message, null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            imageDescriber?.let {
                val closeMethod = it.javaClass.getMethod("close")
                closeMethod.invoke(it)
            }
        } catch (e: Exception) {
            // Ignore close errors
        }
    }
}
