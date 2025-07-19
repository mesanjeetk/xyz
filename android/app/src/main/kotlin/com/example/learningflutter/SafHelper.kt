package com.example.learningflutter

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.provider.DocumentsContract
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStream
import java.util.*

class SafHelper(private val context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("saf_prefs", Context.MODE_PRIVATE)

    fun saveFolderUri(name: String, uri: Uri) {
        val key = UUID.randomUUID().toString()
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

    fun removeFolder(key: String) {
        prefs.edit().remove(key).apply()
    }

    fun writeToFolder(key: String, fileName: String, content: String): Boolean {
        val value = prefs.getString(key, null) ?: return false
        val uri = Uri.parse(value.split("||")[1])
        return try {
            val fileUri = DocumentsContract.createDocument(
                context.contentResolver, uri, "text/plain", fileName
            )
            fileUri?.let {
                val outputStream: OutputStream? = context.contentResolver.openOutputStream(it)
                outputStream?.use { stream ->
                    stream.write(content.toByteArray())
                }
                true
            } ?: false
        } catch (e: Exception) {
            false
        }
    }

    fun readFromFolder(key: String, fileName: String): String {
        val value = prefs.getString(key, null) ?: return "Folder not found"
        val uri = Uri.parse(value.split("||")[1])
        return try {
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(
                uri,
                DocumentsContract.getTreeDocumentId(uri)
            )
            val cursor = context.contentResolver.query(
                children, arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID), null, null, null
            )
            cursor?.use {
                while (it.moveToNext()) {
                    val docId = it.getString(0)
                    if (docId.endsWith(fileName)) {
                        val docUri = DocumentsContract.buildDocumentUriUsingTree(uri, docId)
                        val input = context.contentResolver.openInputStream(docUri)
                        val reader = BufferedReader(InputStreamReader(input))
                        val text = reader.readText()
                        reader.close()
                        return text
                    }
                }
            }
            "File not found"
        } catch (e: Exception) {
            "Error reading: ${e.message}"
        }
    }

    fun createFolder(parentUri: String, name: String): Boolean {
        val parent = Uri.parse(parentUri)
        return try {
            DocumentsContract.createDocument(
                context.contentResolver, parent, DocumentsContract.Document.MIME_TYPE_DIR, name
            ) != null
        } catch (e: Exception) {
            false
        }
    }

    fun createFile(parentUri: String, name: String): Boolean {
        val parent = Uri.parse(parentUri)
        return try {
            DocumentsContract.createDocument(
                context.contentResolver, parent, "text/plain", name
            ) != null
        } catch (e: Exception) {
            false
        }
    }

    fun renameDocument(uriString: String, newName: String): Boolean {
        val uri = Uri.parse(uriString)
        val values = ContentValues()
        values.put(DocumentsContract.Document.COLUMN_DISPLAY_NAME, newName)
        return try {
            context.contentResolver.update(uri, values, null, null) > 0
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

    fun getFolderTree(key: String): Map<String, Any>? {
        val value = prefs.getString(key, null) ?: return null
        val uri = Uri.parse(value.split("||")[1])
        val rootName = getDisplayName(uri)
        val rootNode = mutableMapOf<String, Any>(
            "name" to rootName,
            "uri" to uri.toString(),
            "type" to "folder",
            "children" to buildTree(uri)
        )
        return rootNode
    }

    private fun buildTree(uri: Uri): List<Map<String, Any>> {
        val children = mutableListOf<Map<String, Any>>()
        try {
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
                uri,
                DocumentsContract.getTreeDocumentId(uri)
            )
            val cursor = context.contentResolver.query(
                childrenUri,
                arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_MIME_TYPE
                ),
                null, null, null
            )
            cursor?.use {
                while (it.moveToNext()) {
                    val docId = it.getString(0)
                    val name = it.getString(1)
                    val mime = it.getString(2)

                    if (name == "node_modules") continue // skip

                    val childUri = DocumentsContract.buildDocumentUriUsingTree(uri, docId)

                    if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
                        children.add(
                            mapOf(
                                "name" to name,
                                "uri" to childUri.toString(),
                                "type" to "folder",
                                "children" to buildTree(childUri)
                            )
                        )
                    } else {
                        children.add(
                            mapOf(
                                "name" to name,
                                "uri" to childUri.toString(),
                                "type" to "file"
                            )
                        )
                    }
                }
            }
        } catch (_: Exception) { }
        return children
    }

    private fun getDisplayName(uri: Uri): String {
        return DocumentsContract.getDocumentId(uri).split(":").last()
    }
}
