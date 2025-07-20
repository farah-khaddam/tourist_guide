// testscreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddLandmarkScreen extends StatefulWidget {
  @override
  _AddLandmarkScreenState createState() => _AddLandmarkScreenState();
}

class _AddLandmarkScreenState extends State<AddLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isLoading = false;

  Future<void> _addLandmark() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;

        await FirebaseFirestore.instance.collection('location').add({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'governorate': _cityController.text,
          'type': _typeController.text,
          'imageUrl': _imageUrlController.text,
          'latitude': double.tryParse(_latController.text) ?? 0.0,
          'longitude': double.tryParse(_lngController.text) ?? 0.0,
          'createdAt': Timestamp.now(),
          'createdBy': user?.uid ?? 'admin',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تمت إضافة المعلم بنجاح')),
        );
        _formKey.currentState!.reset();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء الإضافة: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('إضافة معلم جديد')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'اسم المعلم'),
                  validator: (value) => value!.isEmpty ? 'أدخل الاسم' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'الوصف'),
                  validator: (value) => value!.isEmpty ? 'أدخل الوصف' : null,
                ),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(labelText: 'المحافظة'),
                  validator: (value) =>
                      value!.isEmpty ? 'أدخل اسم المحافظة' : null,
                ),
                TextFormField(
                  controller: _typeController,
                  decoration:
                      InputDecoration(labelText: 'نوع المعلم (أثري، طبيعي...)'),
                  validator: (value) =>
                      value!.isEmpty ? 'أدخل نوع المعلم' : null,
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(labelText: 'رابط الصورة (URL)'),
                  validator: (value) =>
                      value!.isEmpty ? 'أدخل رابط الصورة' : null,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: InputDecoration(labelText: 'Latitude'),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'أدخل الإحداثي' : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: InputDecoration(labelText: 'Longitude'),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'أدخل الإحداثي' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _addLandmark,
                        child: Text('إضافة المعلم'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
