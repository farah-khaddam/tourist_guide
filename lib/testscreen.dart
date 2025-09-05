// testscreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddLandmarkScreen extends StatefulWidget {
  final DocumentSnapshot? landmarkData;

  const AddLandmarkScreen({super.key, this.landmarkData});

  @override
  _AddLandmarkScreenState createState() => _AddLandmarkScreenState();
}

class _AddLandmarkScreenState extends State<AddLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _typeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _terrainController = TextEditingController();
  final _tripsController = TextEditingController();

  List<TextEditingController> _imageControllers = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.landmarkData != null) {
      final data = widget.landmarkData!.data() as Map<String, dynamic>;

      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _cityController.text = data['governorate'] ?? '';
      _typeController.text = data['type'] ?? '';
      _latController.text = (data['latitude'] ?? '').toString();
      _lngController.text = (data['longitude'] ?? '').toString();
      _terrainController.text = data['terrain'] ?? '';
      _tripsController.text = data['trips'] ?? '';

      final images = List<String>.from(data['images'] ?? []);
      if (images.isNotEmpty) {
        _imageControllers =
            images.map((url) => TextEditingController(text: url)).toList();
      } else {
        _imageControllers = [TextEditingController()];
      }
    } else {
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
    _tripsController.dispose();
    for (var controller in _imageControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    setState(() {
      if (_imageControllers.length > 1) {
        _imageControllers.removeAt(index);
      }
    });
  }

  Future<void> _addLandmark() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;

        List<String> imageUrls = _imageControllers
            .map((controller) => controller.text.trim())
            .where((url) => url.isNotEmpty)
            .toList();

        final data = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'governorate': _cityController.text.trim(),
          'type': _typeController.text.trim(),
          'images': imageUrls,
          'latitude': double.tryParse(_latController.text) ?? 0.0,
          'longitude': double.tryParse(_lngController.text) ?? 0.0,
          'terrain': _terrainController.text.trim(),
          'trips': _tripsController.text.trim(),
          'createdAt': Timestamp.now(),
          'createdBy': user?.uid ?? 'admin',
        };

        if (widget.landmarkData == null) {
          await FirebaseFirestore.instance.collection('location').add(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة المعلم بنجاح')),
          );
        } else {
          await widget.landmarkData!.reference.update(data);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تعديل المعلم بنجاح')),
          );
        }

        _formKey.currentState!.reset();
        setState(() {
          _imageControllers = [TextEditingController()];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final fillColor = theme.inputDecorationTheme.fillColor ?? Colors.white;

    final isEdit = widget.landmarkData != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(isEdit ? 'تعديل معلم' : 'إضافة معلم جديد'), backgroundColor: primaryColor),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...[
                  _nameController,
                  _descriptionController,
                  _cityController,
                  _typeController,
                  _terrainController,
                  _tripsController
                ].map((controller) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'لا يمكن أن يكون الحقل فارغ' : null,
                      ),
                    )),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor)),
                          labelText: 'Latitude',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'أدخل الإحداثي' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor)),
                          labelText: 'Longitude',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'أدخل الإحداثي' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('روابط الصور:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                ..._imageControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor)),
                            labelText: 'رابط صورة ${index + 1}',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'أدخل رابط الصورة' : null,
                        ),
                      ),
                      if (_imageControllers.length > 1)
                        IconButton(
                          onPressed: () => _removeImageField(index),
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                        ),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: _addImageField,
                  icon: Icon(Icons.add, color: primaryColor),
                  label: Text('إضافة صورة أخرى', style: TextStyle(color: primaryColor)),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator(color: primaryColor)
                    : ElevatedButton(
                        onPressed: _addLandmark,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(isEdit ? 'تعديل المعلم' : 'إضافة المعلم',
                            style: const TextStyle(color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
