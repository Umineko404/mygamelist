import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling user profile images.
///
/// Stores compressed profile images in Firebase Realtime Database as base64.
/// Images are compressed to reduce storage and bandwidth usage.
class ProfileImageService extends ChangeNotifier {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String? _profileImageBase64;
  bool _isLoading = false;

  String? get profileImageBase64 => _profileImageBase64;
  bool get isLoading => _isLoading;
  bool get hasProfileImage =>
      _profileImageBase64 != null && _profileImageBase64!.isNotEmpty;

  /// Loads the profile image for the current user.
  Future<void> loadProfileImage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await _db.child('users/$uid/profileImage').get();
      if (snapshot.exists && snapshot.value != null) {
        _profileImageBase64 = snapshot.value as String;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ProfileImageService: Error loading image: $e');
    }
  }

  /// Returns a stream of the profile image base64 string.
  Stream<String?> profileImageStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }

    return _db.child('users/$uid/profileImage').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        return event.snapshot.value as String;
      }
      return null;
    });
  }

  /// Gets the current profile image URL (base64 string).
  Future<String?> getProfileImageUrl() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    try {
      final snapshot = await _db.child('users/$uid/profileImage').get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as String;
      }
    } catch (e) {
      debugPrint('ProfileImageService: Error getting image URL: $e');
    }
    return null;
  }

  /// Picks an image from the specified source and uploads it.
  Future<bool> pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70, // Compress to 70% quality
      );

      if (image == null) return false;

      return await _saveImage(image);
    } catch (e) {
      debugPrint('ProfileImageService: Error picking image: $e');
      return false;
    }
  }

  /// Picks an image from the gallery and saves it.
  Future<bool> pickAndSaveImage() async {
    return pickAndUploadImage(ImageSource.gallery);
  }

  /// Takes a photo with the camera and saves it.
  Future<bool> takeAndSavePhoto() async {
    return pickAndUploadImage(ImageSource.camera);
  }

  /// Saves the image to Firebase.
  Future<bool> _saveImage(XFile image) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      // Read and compress the image
      final bytes = await image.readAsBytes();
      final compressedBytes = await _compressImage(bytes);

      // Convert to base64
      final base64String = base64Encode(compressedBytes);

      // Check size (Firebase has limits)
      if (base64String.length > 1000000) {
        // ~1MB limit
        debugPrint('ProfileImageService: Image too large after compression');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Save to Firebase
      await _db.child('users/$uid/profileImage').set(base64String);

      _profileImageBase64 = base64String;
      _isLoading = false;
      notifyListeners();

      // Also cache locally
      await _cacheImageLocally(compressedBytes);

      return true;
    } catch (e) {
      debugPrint('ProfileImageService: Error saving image: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Compresses image bytes (basic implementation).
  Future<Uint8List> _compressImage(Uint8List bytes) async {
    // The image is already compressed by ImagePicker with quality: 70
    // and maxWidth/maxHeight: 512
    // For further compression, you could use flutter_image_compress package
    return bytes;
  }

  /// Caches the image locally for faster loading.
  Future<void> _cacheImageLocally(Uint8List bytes) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_$uid.jpg');
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('ProfileImageService: Error caching image: $e');
    }
  }

  /// Gets cached image if available.
  Future<Uint8List?> getCachedImage() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_$uid.jpg');

      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      debugPrint('ProfileImageService: Error reading cached image: $e');
    }
    return null;
  }

  /// Removes the profile image.
  Future<bool> removeProfileImage() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _db.child('users/$uid/profileImage').remove();
      _profileImageBase64 = null;

      // Remove cached file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_$uid.jpg');
      if (await file.exists()) {
        await file.delete();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('ProfileImageService: Error removing image: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Converts base64 string to image bytes for display.
  Uint8List? getImageBytes() {
    if (_profileImageBase64 == null || _profileImageBase64!.isEmpty) {
      return null;
    }
    try {
      return base64Decode(_profileImageBase64!);
    } catch (e) {
      debugPrint('ProfileImageService: Error decoding image: $e');
      return null;
    }
  }

  /// Clears the cached profile image (call on logout).
  void clear() {
    _profileImageBase64 = null;
    notifyListeners();
  }
}
