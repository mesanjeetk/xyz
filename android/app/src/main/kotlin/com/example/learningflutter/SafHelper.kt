package com.example.learningflutter

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.provider.DocumentsContract
import java.io.BufferedReader
import java.io.InputStreamReader

class SafHelper(private val context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("saf_prefs", Context.MODE_PRIVATE)

    fun saveFolderUri(name: String, uri: Uri) {
        val key = System.currentTimeMillis().toString()
        context.contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
        )
        prefs.edit().putString(key, "$name||${uri}").apply()
    }

    fun getAllFolders(): List<Map<String, String>> {
        return prefs.all.map { entry ->
            val parts = (entry.value as String).split("||")
            mapOf(
                "key" to entry.key,
                "name" to parts[0],
                "uri" to parts[1]
            )
        }
    }

    fun getFolderTree(key: String): Map<String, Any>? {
        val value = prefs.getString(key, null) ?: return null
        val uri = Uri.parse(value.split("||")[1])
        val docId = DocumentsContract.getTreeDocumentId(uri)
        val children = getFolderTreeByUri(uri, docId)
        return mapOf(
            "name" to "root",
            "uri" to uri.toString(),
            "type" to "folder",
            "children" to children
        )
    }

    private fun getFolderTreeByUri(uri: Uri, docId: String): List<Map<String, Any>> {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(uri, docId)

        val cursor = context.contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE
            ),
            null, null, null
        )

        val children = mutableListOf<Map<String, Any>>()
        cursor?.use {
            while (it.moveToNext()) {
                val childId = it.getString(0)
                val name = it.getString(1)
                val mime = it.getString(2)

                val childUri = DocumentsContract.buildDocumentUriUsingTree(uri, childId)
                if (DocumentsContract.Document.MIME_TYPE_DIR == mime) {
                    val subChildren = getFolderTreeByUri(uri, childId)
                    children.add(mapOf(
                        "name" to name,
                        "uri" to childUri.toString(),
                        "type" to "folder",
                        "children" to subChildren
                    ))
                } else {
                    children.add(mapOf(
                        "name" to name,
                        "uri" to childUri.toString(),
                        "type" to "file"
                    ))
                }
            }
        }
        return children
    }

    fun createFolder(parentUriString: String, name: String): Boolean {
        val parentUri = Uri.parse(parentUriString)
        return try {
            DocumentsContract.createDocument(
                context.contentResolver,
                parentUri,
                DocumentsContract.Document.MIME_TYPE_DIR,
                name
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    fun createFile(parentUriString: String, name: String): Boolean {
        val parentUri = Uri.parse(parentUriString)
        return try {
            DocumentsContract.createDocument(
                context.contentResolver,
                parentUri,
                "text/plain",
                name
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    fun deleteDocument(uriString: String): Boolean {
        val uri = Uri.parse(uriString)
        return try {
            DocumentsContract.deleteDocument(context.contentResolver, uri)
        } catch (e: Exception) {
            false
        }
    }

    fun readFileContent(uriString: String): String {
        val uri = Uri.parse(uriString)
        return try {
            val input = context.contentResolver.openInputStream(uri)
            val reader = BufferedReader(InputStreamReader(input))
            val text = reader.readText()
            reader.close()
            text
        } catch (e: Exception) {
            "Error: ${e.message}"
        }
    }
}
