// EditLandmarkScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class EditLandmarkScreen extends StatefulWidget {
  final DocumentSnapshot landmark;

  const EditLandmarkScreen({super.key, required this.landmark});

  @override
  _EditLandmarkScreenState createState() => _EditLandmarkScreenState();
}

class _EditLandmarkScreenState extends State<EditLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _cityController;
  late TextEditingController _typeController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _terrainController;
  late TextEditingController _tripInfoController;
  List<TextEditingController> _imageControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.landmark.data() as Map<String, dynamic>;

    _nameController = TextEditingController(text: data['name']);
    _descriptionController = TextEditingController(text: data['description']);
    _cityController = TextEditingController(text: data['governorate']);
    _typeController = TextEditingController(text: data['type']);
    _latController = TextEditingController(text: data['latitude'].toString());
    _lngController = TextEditingController(text: data['longitude'].toString());
    _terrainController = TextEditingController(text: data['terrain'] ?? '');
    _tripInfoController = TextEditingController(text: data['tripInfo'] ?? '');

    List<dynamic> images = data['images'] ?? [];
    _imageControllers =
        images.map((url) => TextEditingController(text: url)).toList();
    if (_imageControllers.isEmpty) {
      _imageControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _typeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _terrainController.dispose();
    _tripInfoController.dispose();
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateLandmark() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        List<String> imageUrls = _imageControllers
            .map((controller) => controller.text.trim())
            .where((url) => url.isNotEmpty)
            .toList();

        await widget.landmark.reference.update({
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'governorate': _cityController.text.trim(),
          'type': _typeController.text.trim(),
          'latitude': double.tryParse(_latController.text) ?? 0.0,
          'longitude': double.tryParse(_lngController.text) ?? 0.0,
          'terrain': _terrainController.text.trim(),
          'tripInfo': _tripInfoController.text.trim(),
          'images': imageUrls,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث المعلم بنجاح')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التحديث: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteLandmark() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المعلم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.landmark.reference.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المعلم بنجاح')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الحذف: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bgColor = themeProvider.isDark ? Colors.black : const Color(0xFFFFF5E1);
    final textColor = themeProvider.isDark ? Colors.white : Colors.orange.shade700;
    final cardColor = themeProvider.isDark ? Colors.grey.shade900 : Colors.white;
    final buttonColor = Colors.orange.shade700;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: buttonColor,
        title: const Text('تعديل المعلم'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'اسم المعلم',
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: cardColor,
                  ),
                  validator: (value) => value!.isEmpty ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'الوصف',
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: cardColor,
                  ),
                  validator: (value) => value!.isEmpty ? 'أدخل الوصف' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'المحافظة',
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: cardColor,
                  ),
                  validator: (value) => value!.isEmpty ? 'أدخل المحافظة' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _typeController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'نوع المعلم',
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: cardColor,
                  ),
                  validator: (value) => value!.isEmpty ? 'أدخل النوع' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _terrainController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'وصف التضاريس',
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: cardColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tripInfoController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'معلومات عن الرحلات',
                    labelStyle: TextStyle(color: textColor),
                    filled: true,
                    fillColor: cardColor,
                  ),
                ),
                const SizedBox(height: 10),
                ..._imageControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'رابط صورة ${index + 1}',
                            labelStyle: TextStyle(color: textColor),
                            filled: true,
                            fillColor: cardColor,
                          ),
                        ),
                      ),
                      if (_imageControllers.length > 1)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _imageControllers.removeAt(index);
                            });
                          },
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                        ),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _imageControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة صورة أخرى'),
                  style: TextButton.styleFrom(foregroundColor: buttonColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          labelStyle: TextStyle(color: textColor),
                          filled: true,
                          fillColor: cardColor,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          labelStyle: TextStyle(color: textColor),
                          filled: true,
                          fillColor: cardColor,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _updateLandmark,
                        style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                        child: const Text('تحديث المعلم'),
                      ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _deleteLandmark,
                  child: const Text('حذف المعلم'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
