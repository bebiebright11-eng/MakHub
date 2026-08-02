// Shared mixin for hostel photo / video picking and Firebase Storage upload.
//
// Usage: mix into the State of a StatefulWidget that needs to pick and upload
// hostel media. The host screen is responsible for calling [uploadNewMedia]
// during its save flow and writing the resulting URLs to Firestore.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '/core/constants/app_colors.dart';

mixin HostelMediaMixin<T extends StatefulWidget> on State<T> {
  final List<File> _pickedPhotos = [];
  final List<File> _pickedVideos = [];

  final ImagePicker _picker = ImagePicker();

  bool get hasPickedMedia =>
      _pickedPhotos.isNotEmpty || _pickedVideos.isNotEmpty;

  // ── Pickers ───────────────────────────────────────────────────────────

  Future<void> pickPhotos() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (images.isEmpty) return;
    setState(() {
      for (final img in images) {
        _pickedPhotos.add(File(img.path));
      }
    });
  }

  Future<void> pickVideo() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() {
      _pickedVideos.add(File(path));
    });
  }

  // ── Removal ───────────────────────────────────────────────────────────

  void removePhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  void removeVideo(int index) {
    setState(() => _pickedVideos.removeAt(index));
  }

  // ── Upload ────────────────────────────────────────────────────────────

  /// Uploads any newly-picked photos and videos under
  /// `hostels/{hostelId}/photos/*` and `hostels/{hostelId}/videos/*`.
  /// Returns a map with two lists of public download URLs:
  /// `{ 'photos': [...], 'videos': [...] }`.
  Future<Map<String, List<String>>> uploadNewMedia(String hostelId) async {
    final storage = FirebaseStorage.instance;
    final List<String> photoUrls = [];
    final List<String> videoUrls = [];

    for (int i = 0; i < _pickedPhotos.length; i++) {
      final ext = p.extension(_pickedPhotos[i].path);
      final ref = storage.ref(
        'hostels/$hostelId/photos/${DateTime.now().microsecondsSinceEpoch}_$i$ext',
      );
      await ref.putFile(_pickedPhotos[i]);
      photoUrls.add(await ref.getDownloadURL());
    }

    for (int i = 0; i < _pickedVideos.length; i++) {
      final ext = p.extension(_pickedVideos[i].path);
      final ref = storage.ref(
        'hostels/$hostelId/videos/${DateTime.now().microsecondsSinceEpoch}_$i$ext',
      );
      await ref.putFile(_pickedVideos[i]);
      videoUrls.add(await ref.getDownloadURL());
    }

    return {'photos': photoUrls, 'videos': videoUrls};
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
              ? "PNG, JPG up to 10MB each"
              : "${_pickedPhotos.length} photo(s) selected",
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
                      child: Image.file(
                        _pickedPhotos[index],
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

  /// Renders a video tile (with filename + remove button) when a video
  /// is picked.
  Widget buildVideoTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _uploadTileShell(
          icon: Icons.videocam,
          title: "Upload Tour Video",
          subtitle: _pickedVideos.isEmpty
              ? "MP4, MOV up to 100MB"
              : p.basename(_pickedVideos.first.path),
          onTap: pickVideo,
        ),
        if (_pickedVideos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_file,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        p.basename(_pickedVideos.first.path),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => removeVideo(0),
                      child: const Icon(Icons.close,
                          size: 16, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // The shared tile chrome used by both photos and videos.
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
