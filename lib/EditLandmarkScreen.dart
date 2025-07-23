// EditLandmarkScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        Navigator.pop(context); // رجوع للشاشة السابقة
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء التحديث: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل المعلم')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المعلم'),
                  validator: (value) => value!.isEmpty ? 'أدخل الاسم' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'الوصف'),
                  validator: (value) => value!.isEmpty ? 'أدخل الوصف' : null,
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'المحافظة'),
                  validator: (value) => value!.isEmpty ? 'أدخل المحافظة' : null,
                ),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'نوع المعلم'),
                  validator: (value) => value!.isEmpty ? 'أدخل النوع' : null,
                ),
                TextFormField(
                  controller: _terrainController,
                  decoration: const InputDecoration(labelText: 'وصف التضاريس'),
                ),
                TextFormField(
                  controller: _tripInfoController,
                  decoration: const InputDecoration(labelText: 'معلومات عن الرحلات'),
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
                          decoration: InputDecoration(
                              labelText: 'رابط صورة ${index + 1}'),
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
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: const InputDecoration(labelText: 'Longitude'),
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
                        child: const Text('تحديث المعلم'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
