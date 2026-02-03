import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_icons/app_icons.dart';
import '../constants/app_sizes.dart';

class ImageSelectorWidget extends StatefulWidget {
  final String title;
  final Function(String?) onImageSelected;
  const ImageSelectorWidget(
      {super.key, required this.title, required this.onImageSelected});

  @override
  State<ImageSelectorWidget> createState() => _ImageSelectorWidgetState();
}

class _ImageSelectorWidgetState extends State<ImageSelectorWidget> {
  String _imagePath = '';
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: ShapeDecoration(
            // image: DecorationImage(
            //   image: _imagePath.isEmpty
            //       ? AssetImage(widget.title == 'Profile Picture'
            //           ? AppImages.profileImage
            //           : AppImages.placeHolder) as ImageProvider
            //       : FileImage(File(_imagePath)),
            //   fit: BoxFit.cover,
            // ),
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
            onTap: () async {
              XFile? pickedImage =
                  await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedImage != null) {
                widget.onImageSelected(pickedImage.path);
                setState(() {
                  _imagePath = pickedImage.path;
                });
              } else {
                widget.onImageSelected(null);
                setState(() {
                  _imagePath = '';
                });
              }
            },
            child: _imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imagePath),
                      fit: BoxFit.cover,
                    ),
                  )
                : Align(
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      AppIcons.camera,
                      width: 35,
                    ),
                  ),
          ),
        ),
        gapH4,
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
}
