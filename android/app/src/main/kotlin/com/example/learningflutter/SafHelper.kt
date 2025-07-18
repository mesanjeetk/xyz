package com.example.learningflutter

import android.content.Intent
import android.content.Context
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
}
