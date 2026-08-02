// Shared mixin for hostel photo picking and Firebase Storage upload.
//
// Usage: mix into the State of a StatefulWidget that needs to pick and upload
// hostel photos. The host screen is responsible for calling [uploadNewMedia]
// during its save flow and writing the resulting URLs to Firestore.

import 'dart:io' show File;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '/core/constants/app_colors.dart';

/// Maximum number of photos allowed per hostel.
const int kMaxHostelPhotos = 30;

mixin HostelMediaMixin<T extends StatefulWidget> on State<T> {
  final List<XFile> _pickedPhotos = [];

  final ImagePicker _picker = ImagePicker();

  bool get hasPickedMedia => _pickedPhotos.isNotEmpty;

  // ── Pickers ───────────────────────────────────────────────────────────

  Future<void> pickPhotos() async {
    final remaining = kMaxHostelPhotos - _pickedPhotos.length;
    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Maximum of $kMaxHostelPhotos photos reached')),
        );
      }
      return;
    }
    final images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
      limit: remaining,
    );
    if (images.isEmpty) return;
    setState(() {
      _pickedPhotos.addAll(images);
    });
  }

  // ── Removal ───────────────────────────────────────────────────────────

  void removePhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  // ── Upload ────────────────────────────────────────────────────────────

  /// Uploads any newly-picked photos under
  /// `hostels/{hostelId}/photos/*`.
  /// Returns a list of public download URLs.
  Future<List<String>> uploadNewMedia(String hostelId) async {
    final storage = FirebaseStorage.instance;
    final List<String> photoUrls = [];

    for (int i = 0; i < _pickedPhotos.length; i++) {
      final ext = p.extension(_pickedPhotos[i].path);
      final ref = storage.ref(
        'hostels/$hostelId/photos/${DateTime.now().microsecondsSinceEpoch}_$i$ext',
      );
      if (kIsWeb) {
        await ref.putData(await _pickedPhotos[i].readAsBytes());
      } else {
        await ref.putFile(File(_pickedPhotos[i].path));
      }
      photoUrls.add(await ref.getDownloadURL());
    }

    return photoUrls;
  }

  // ── UI builders ───────────────────────────────────────────────────────

  /// Renders a photos tile (with previews) plus a horizontal strip of
  /// picked photos below it.
  Widget buildPhotosTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _uploadTileShell(
          icon: Icons.photo,
          title: "Upload Photos",
          subtitle: _pickedPhotos.isEmpty
              ? "PNG, JPG up to $kMaxHostelPhotos photos"
              : "${_pickedPhotos.length}/$kMaxHostelPhotos photo(s) selected",
          onTap: pickPhotos,
        ),
        if (_pickedPhotos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedPhotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb
                          ? Image.network(
                              _pickedPhotos[index].path,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_pickedPhotos[index].path),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => removePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // The shared tile chrome.
  Widget _uploadTileShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            child: const Text("Choose File"),
          ),
        ],
      ),
    );
  }
}
