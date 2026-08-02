// Shared mixin for hostel photo picking and Cloudinary upload.
//
// Uses Cloudinary unsigned uploads — no API secret is exposed in the client.
// Upload preset must be set to "Unsigned" in the Cloudinary dashboard.

import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '/core/constants/app_colors.dart';

/// Maximum number of photos allowed per hostel.
const int kMaxHostelPhotos = 30;

/// Cloudinary config — unsigned upload preset only, no secret needed.
const String _kCloudName = 'uimjr0md';
const String _kUploadPreset = 'MakHub_uploads';
const String _kUploadUrl =
    'https://api.cloudinary.com/v1_1/$_kCloudName/image/upload';

mixin HostelMediaMixin<T extends StatefulWidget> on State<T> {
  final List<XFile> _pickedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  bool get hasPickedMedia => _pickedPhotos.isNotEmpty;

  // Override in the host screen to report how many photos are already saved,
  // so the combined total stays within kMaxHostelPhotos.
  int get existingPhotosCount => 0;

  // ── Pickers ───────────────────────────────────────────────────────────

  Future<void> pickPhotos() async {
    final remaining =
        kMaxHostelPhotos - _pickedPhotos.length - existingPhotosCount;
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
    setState(() => _pickedPhotos.addAll(images));
  }

  // ── Removal ───────────────────────────────────────────────────────────

  void removePhoto(int index) {
    setState(() => _pickedPhotos.removeAt(index));
  }

  /// Clears all picked photos after a successful upload.
  void clearPickedPhotos() {
    setState(() => _pickedPhotos.clear());
  }

  // ── Upload ────────────────────────────────────────────────────────────

  /// Uploads all picked photos to Cloudinary using an unsigned upload preset.
  /// Returns a list of secure HTTPS URLs.
  Future<List<String>> uploadNewMedia(String hostelId) async {
    final List<String> photoUrls = [];

    debugPrint('[HostelMedia] Uploading ${_pickedPhotos.length} photo(s) to Cloudinary');

    for (int i = 0; i < _pickedPhotos.length; i++) {
      final photo = _pickedPhotos[i];
      debugPrint('[HostelMedia] Photo $i — name: ${photo.name}');

      final bytes = await photo.readAsBytes();
      debugPrint('[HostelMedia] Photo $i — ${bytes.length} bytes read');

      // Build a unique public_id so photos don't overwrite each other.
      final ext = p.extension(photo.name).isNotEmpty
          ? p.extension(photo.name).replaceFirst('.', '')
          : 'jpg';
      final publicId =
          'hostels/$hostelId/${DateTime.now().microsecondsSinceEpoch}_$i';

      final request = http.MultipartRequest('POST', Uri.parse(_kUploadUrl))
        ..fields['upload_preset'] = _kUploadPreset
        ..fields['public_id'] = publicId
        ..fields['folder'] = 'hostels/$hostelId'
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: '${DateTime.now().microsecondsSinceEpoch}_$i.$ext',
        ));

      debugPrint('[HostelMedia] Photo $i — sending to Cloudinary…');
      final streamedResponse = await request.send();
      final body = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final url = json['secure_url'] as String;
        debugPrint('[HostelMedia] Photo $i — uploaded OK: $url');
        photoUrls.add(url);
      } else {
        debugPrint('[HostelMedia] Photo $i — ERROR ${streamedResponse.statusCode}: $body');
        throw Exception(
            'Cloudinary upload failed (${streamedResponse.statusCode}): $body');
      }
    }

    debugPrint('[HostelMedia] All uploads done. ${photoUrls.length} URL(s) returned.');
    return photoUrls;
  }

  // ── UI builders ───────────────────────────────────────────────────────

  /// Renders the upload tile with previews.
  /// Pass [onSave] and [isSaving] to show a "Save Photos" button
  /// inline next to "Choose File" — only visible when photos are picked.
  Widget buildPhotosTile({
    VoidCallback? onSave,
    bool isSaving = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _uploadTileShell(
          icon: Icons.photo,
          title: 'Upload Photos',
          subtitle: _pickedPhotos.isEmpty
              ? 'PNG, JPG — up to $kMaxHostelPhotos photos'
              : '${_pickedPhotos.length}/$kMaxHostelPhotos photo(s) selected',
          onTap: pickPhotos,
          onSave: hasPickedMedia ? onSave : null,
          isSaving: isSaving,
        ),
        if (_pickedPhotos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedPhotos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
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

  Widget _uploadTileShell({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onSave,
    bool isSaving = false,
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            child: const Text('Choose File'),
          ),
          // "Save Photos" appears inline only when photos are picked.
          if (onSave != null) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 16),
              label: Text(
                isSaving ? 'Saving…' : 'Save Photos',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
