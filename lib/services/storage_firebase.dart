import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class FirebaseStorageService {
  static final FirebaseStorage storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage under a user's specific folder and return the file URL
  static Future<String> uploadFile(String userId, File file) async {
    try {
      String fileName = Path.basename(file.path);
      // Create a reference to the location you want to upload to in Firebase Storage
      Reference ref = storage.ref().child('$userId/$fileName');

      // Upload the file to Firebase Storage
      UploadTask uploadTask = ref.putFile(file);

      // Manage the task state and catch errors
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      // Handle any errors
      throw Exception('Failed to upload file: ${e.message}');
    }
  }

  /// Get a file URL from Firebase Storage under a user's folder
  static Future<String> getFile(String userId, String fileName) async {
    try {
      // Create a reference by path
      Reference ref = storage.ref().child('$userId/$fileName');

      // Get the file URL
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      // Handle any errors
      throw Exception('Failed to get file: ${e.message}');
    }
  }

  /// Delete a file from Firebase Storage under a user's folder
  static Future<void> deleteFile(String url) async {
    try {
      // Create a reference to the file to delete
      Reference ref = storage.ref().child('$url');

      // Delete the file
      await ref.delete();
    } on FirebaseException catch (e) {
      // Handle any errors
      throw Exception('Failed to delete file: ${e.message}');
    }
  }
}
