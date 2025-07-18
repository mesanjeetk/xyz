package com.example.learningflutter

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "directory_permission_advanced"
    private val safHelper by lazy { SafHelper(this) }

    private var resultChannel: MethodChannel.Result? = null

    private val REQUEST_CODE_PICK_DIRECTORY = 12345

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDirectory" -> {
                        resultChannel = result

                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                        intent.addFlags(
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                        )
                        startActivityForResult(intent, REQUEST_CODE_PICK_DIRECTORY)
                    }
                    "getFolders" -> {
                        result.success(safHelper.getAllFolders())
                    }
                    "writeToDirectory" -> {
                        val key = call.argument<String>("folderKey")!!
                        val fileName = call.argument<String>("fileName")!!
                        val content = call.argument<String>("content")!!
                        val success = safHelper.writeToFolder(key, fileName, content)
                        if (success) result.success(true) else result.error("WRITE_FAIL", "", null)
                    }
                    "readFromDirectory" -> {
                        val key = call.argument<String>("folderKey")!!
                        val fileName = call.argument<String>("fileName")!!
                        val content = safHelper.readFromFolder(key, fileName)
                        result.success(content)
                    }
                    "removeFolder" -> {
                        val key = call.argument<String>("folderKey")!!
                        safHelper.removeFolder(key)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_CODE_PICK_DIRECTORY) {
            if (resultCode == RESULT_OK && data != null) {
                val uri: Uri? = data.data
                if (uri != null) {
                    safHelper.saveFolderUri("Folder", uri)
                    resultChannel?.success(mapOf("uri" to uri.toString()))
                } else {
                    resultChannel?.error("NO_URI", "No folder selected", null)
                }
            } else {
                resultChannel?.error("CANCELLED", "User cancelled", null)
            }
        }
    }
}
