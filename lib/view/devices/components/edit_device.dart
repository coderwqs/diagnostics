import 'dart:io';
import 'package:diagnosis/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:diagnosis/model/device.dart';

class EditDeviceDialog extends StatefulWidget {
  final Device device;
  final Function(Device) onSubmit;

  const EditDeviceDialog({
    super.key,
    required this.device,
    required this.onSubmit,
  });

  @override
  _EditDeviceDialogState createState() => _EditDeviceDialogState();
}

class _EditDeviceDialogState extends State<EditDeviceDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController identityController = TextEditingController();
  final TextEditingController secretController = TextEditingController();
  MachineType selectedType = MachineType.motor;
  List<int> selectedImage = [];
  bool isFormValid = false;

  @override
  void initState() {
    super.initState();
    // 初始化表单字段
    nameController.text = widget.device.name;
    identityController.text = widget.device.identity;
    secretController.text = widget.device.secret;
    selectedType = widget.device.type;
    selectedImage = widget.device.image;
    isFormValid = false;
  }

  void checkFormVerify() {
    Device d = Device(
      name: nameController.text,
      type: selectedType,
      identity: identityController.text,
      secret: secretController.text,
      image: selectedImage.toList(),
    );

    setState(() {
      if (widget.device.isModified(d)) {
        isFormValid = true;
      } else {
        isFormValid = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      content: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 600, minWidth: 450),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.devices_edit,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 20),
            _buildFormContent(l10n),
            const SizedBox(height: 24),
            _buildDialogActions(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.devices_name,
              hintText: l10n.devices_add_tips,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(Icons.devices, size: 20),
            ),
            onChanged: (value) => checkFormVerify(),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<MachineType>(
            value: selectedType,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.devices_category,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              prefixIcon: const Icon(Icons.category, size: 20),
            ),
            items: MachineType.values.map((type) {
              return DropdownMenuItem<MachineType>(
                value: type,
                child: Text(
                  type.displayName(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                selectedType = newValue!;
              });
              checkFormVerify();
            },
            isExpanded: true,
            dropdownColor: Theme.of(context).colorScheme.surface,
            menuMaxHeight: 300,
            itemHeight: 48,
            style: Theme.of(context).textTheme.bodyMedium,
            borderRadius: BorderRadius.circular(12),
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: identityController,
            decoration: InputDecoration(
              labelText: l10n.devices_identity,
              hintText: l10n.devices_identity_tips,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(Icons.qr_code, size: 20),
            ),
            onChanged: (value) => checkFormVerify(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: secretController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.devices_secret,
              hintText: l10n.devices_secret_tips,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(Icons.lock, size: 20),
            ),
            onChanged: (value) => checkFormVerify(),
          ),
          const SizedBox(height: 20),
          _buildImagePicker(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.devices_image,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final ImagePicker _picker = ImagePicker();
            final XFile? image = await _picker.pickImage(
              source: ImageSource.gallery,
            );
            if (image != null) {
              final file = File(image.path);
              List<int> imgBytes = await file.readAsBytes();
              setState(() {
                selectedImage = imgBytes;
              });
              checkFormVerify();
            }
          },
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedImage.isEmpty
                    ? Colors.grey.shade300
                    : Colors.transparent,
                width: 1.5,
              ),
              color: selectedImage.isEmpty ? Colors.grey.shade50 : null,
            ),
            child: selectedImage.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.devices_image_tips,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      Uint8List.fromList(selectedImage),
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDialogActions(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.app_cancel, style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
          onPressed: isFormValid
              ? () {
                  widget.onSubmit(
                    Device(
                      name: nameController.text,
                      type: selectedType,
                      identity: identityController.text,
                      secret: secretController.text,
                      image: selectedImage.toList(),
                    ),
                  );
                }
              : null,
          child: Text(l10n.app_save, style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
