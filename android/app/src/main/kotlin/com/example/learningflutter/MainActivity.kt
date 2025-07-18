package com.example.learningflutter

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.provider.DocumentsContract

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
                    "getFolders" -> result.success(safHelper.getAllFolders())
                    "getFolderTree" -> {
                        val key = call.argument<String>("folderKey")!!
                        val tree = safHelper.getFolderTree(key)
                        result.success(tree)
                    }
                    "createFolder" -> {
                        val parentUri = call.argument<String>("parentUri")!!
                        val name = call.argument<String>("name")!!
                        val success = safHelper.createFolder(parentUri, name)
                        if (success) result.success(true) else result.error("CREATE_FAIL", "", null)
                    }
                    "createFile" -> {
                        val parentUri = call.argument<String>("parentUri")!!
                        val name = call.argument<String>("name")!!
                        val success = safHelper.createFile(parentUri, name)
                        if (success) result.success(true) else result.error("CREATE_FAIL", "", null)
                    }
                    "deleteDocument" -> {
                        val uri = call.argument<String>("uri")!!
                        val success = safHelper.deleteDocument(uri)
                        if (success) result.success(true) else result.error("DELETE_FAIL", "", null)
                    }
                    "readFileContent" -> {
                        val uri = call.argument<String>("uri")!!
                        val content = safHelper.readFileContent(uri)
                        result.success(content)
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
