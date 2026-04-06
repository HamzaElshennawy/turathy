/// {@category Components}
///
/// A square-profile widget for capturing or selecting a single image from the device gallery.
/// 
/// This component is typically deployed in registration or listing flows where 
/// users must upload a single visual identity (e.g., Profile Picture, ID Card).
/// 
/// Features:
/// - **Integrated Picker**: Uses the `image_picker` package to invoke native gallery UI.
/// - **Stateful Preview**: Provides immediate visual feedback by rendering a [FileImage] 
///   once a selection is made.
/// - **Standardized Aesthetic**: Enforces a 100x100 square hit area with a consistent 
///   border and camera icon placeholder.
library;

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_icons/app_icons.dart';
import '../constants/app_sizes.dart';

/// A UI component for picking, previewing, and potentially clearing a single image asset.
class ImageSelectorWidget extends StatefulWidget {
  /// The descriptive label displayed below the square selector (supports localization keys).
  final String title;

  /// Callback emitted when a selection occurs. 
  /// 
  /// Passes the absolute path string of the picked file, or `null` if the picker was canceled.
  final Function(String?) onImageSelected;

  /// Creates an [ImageSelectorWidget] with a mandatory [title] and [onImageSelected] handler.
  const ImageSelectorWidget({
    super.key, 
    required this.title, 
    required this.onImageSelected,
  });

  @override
  State<ImageSelectorWidget> createState() => _ImageSelectorWidgetState();
}

class _ImageSelectorWidgetState extends State<ImageSelectorWidget> {
  /// The local filesystem path of the currently selected image.
  String _imagePath = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Selection Hit Area ──────────────────────────────────────────────
        Container(
          height: 100, // Fixed project standard for small image selectors
          width: 100,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface,
                width: 2,
              ),
            ),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onTap: () => _pickImage(),
            child: _imagePath.isNotEmpty
                ? _buildImagePreview()
                : _buildPlaceholder(),
          ),
        ),
        gapH4,
        
        // ── Label Layer ─────────────────────────────────────────────────────
        SizedBox(
          width: 100,
          child: Text(
            widget.title.tr(context: context),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }

  /// Internal: Invokes the native gallery picker and updates the local state.
  Future<void> _pickImage() async {
    final XFile? pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      widget.onImageSelected(pickedImage.path);
      setState(() => _imagePath = pickedImage.path);
    } else {
      // Logic: If canceled, we don't clear the previous image unless 
      // the business logic requires explicit removal.
      // widget.onImageSelected(null);
      // setState(() => _imagePath = '');
    }
  }

  /// Internal: Builds the clipped preview of the selected [File].
  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(_imagePath),
        fit: BoxFit.cover,
      ),
    );
  }

  /// Internal: Builds the default camera icon fallback.
  Widget _buildPlaceholder() {
    return Align(
      alignment: Alignment.center,
      child: SvgPicture.asset(
        AppIcons.camera,
        width: 35,
      ),
    );
  }
}

