package com.example.learningflutter

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "directory_permission_advanced"
    private val safHelper by lazy { SafHelper(this) }

    private var currentFolderName: String = ""
    private var resultChannel: MethodChannel.Result? = null

    private val folderPickerLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val data = result.data
        if (result.resultCode == RESULT_OK && data != null) {
            val uri: Uri? = data.data
            if (uri != null) {
                safHelper.saveFolderUri(currentFolderName, uri)
                resultChannel?.success(mapOf("uri" to uri.toString()))
            } else {
                resultChannel?.error("NO_URI", "No folder selected", null)
            }
        } else {
            resultChannel?.error("CANCELLED", "User cancelled", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickDirectory" -> {
                        val name = call.argument<String>("folderName") ?: "Unnamed"
                        currentFolderName = name
                        resultChannel = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                        intent.addFlags(
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                        )
                        folderPickerLauncher.launch(intent)
                    }

                    "getFolders" -> {
                        result.success(safHelper.getAllFolders())
                    }

                    "removeFolder" -> {
                        val key = call.argument<String>("folderKey")!!
                        safHelper.removeFolder(key)
                        result.success(true)
                    }

                    "getFolderTree" -> {
                        val key = call.argument<String>("folderKey")!!
                        val tree = safHelper.getFolderTree(key)
                        result.success(tree)
                    }

                    "createFolder" -> {
                        val parentUri = call.argument<String>("parentUri")!!
                        val name = call.argument<String>("name")!!
                        val ok = safHelper.createFolder(parentUri, name)
                        if (ok) result.success(true) else result.error("CREATE_FOLDER_FAIL", "", null)
                    }

                    "createFile" -> {
                        val parentUri = call.argument<String>("parentUri")!!
                        val name = call.argument<String>("name")!!
                        val ok = safHelper.createFile(parentUri, name)
                        if (ok) result.success(true) else result.error("CREATE_FILE_FAIL", "", null)
                    }

                    "renameDocument" -> {
                        val uri = call.argument<String>("uri")!!
                        val name = call.argument<String>("name")!!
                        val ok = safHelper.renameDocument(uri, name)
                        if (ok) result.success(true) else result.error("RENAME_FAIL", "", null)
                    }

                    "deleteDocument" -> {
                        val uri = call.argument<String>("uri")!!
                        val ok = safHelper.deleteDocument(uri)
                        if (ok) result.success(true) else result.error("DELETE_FAIL", "", null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
