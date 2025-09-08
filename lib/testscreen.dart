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
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _terrainController = TextEditingController();

  String? _selectedGovernorate;
  String? _selectedType;

  List<TextEditingController> _imageControllers = [];
  bool _isLoading = false;

  final List<String> _governorates = [
    "دمشق",
    "ريف دمشق",
    "درعا",
    "السويداء",
    "القنيطرة",
    "حمص",
    "حماة",
    "اللاذقية",
    "طرطوس",
    "ادلب",
    "الرقة",
    "الحسكة",
    "دير الزور",
    "حلب"
  ];

  final List<String> _types = ["ديني", "ثقافي", "تاريخي", "طبيعي", "ترفيهي"];

  @override
Color get fieldFillColor => Theme.of(context).brightness == Brightness.dark
    ? Colors.grey.shade800 // إذا الوضع داكن
    : Colors.white;        // إذا الوضع فاتح

Color get fieldTextColor => Theme.of(context).brightness == Brightness.dark
    ? Colors.white
    : Colors.black;

Color get buttonColor => Theme.of(context).brightness == Brightness.dark
    ? Colors.orange.shade700
    : Colors.teal;

Color get buttonTextColor => Colors.white; // نصوص الأزرار


  void initState() {
    super.initState();

    if (widget.landmarkData != null) {
      final data = widget.landmarkData!.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _terrainController.text = data['terrain'] ?? '';
      _latController.text = (data['latitude'] ?? '').toString();
      _lngController.text = (data['longitude'] ?? '').toString();

      _selectedGovernorate = data['governorate'];
      _selectedType = data['type'];

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
    _terrainController.dispose();
    _latController.dispose();
    _lngController.dispose();
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
      if (_selectedGovernorate == null || _selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اختر المحافظة والنوع')),
        );
        return;
      }

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
          'governorate': _selectedGovernorate,
          'type': _selectedType,
          'images': imageUrls,
          'latitude': double.tryParse(_latController.text) ?? 0.0,
          'longitude': double.tryParse(_lngController.text) ?? 0.0,
          'terrain': _terrainController.text.trim(),
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
          _selectedGovernorate = null;
          _selectedType = null;
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
      appBar: AppBar(
        title: Text(isEdit ? 'تعديل معلم' : 'إضافة معلم جديد'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // اسم المعلم
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _nameController,
                      style: TextStyle(color: fieldTextColor), // لون النص
                      decoration: InputDecoration(
                        fillColor: fieldFillColor,             // خلفية الحقل
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: buttonColor), // لون الحدود
                        ),
                      labelText: 'اسم المعلم',
                      filled: true,
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'لا يمكن أن يكون الحقل فارغ' : null,
                  ),
                ),
                // الوصف
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'الوصف',
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
                ),
                // المحافظة Dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGovernorate,
                    decoration: InputDecoration(
                      labelText: 'المحافظة',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                    items: _governorates
                        .map((gov) => DropdownMenuItem(
                              value: gov,
                              child: Text(gov),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedGovernorate = val),
                    validator: (value) =>
                        value == null ? 'اختر المحافظة' : null,
                  ),
                ),
                // النوع / التصنيف Dropdown
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'التصنيف',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                    items: _types
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedType = val),
                    validator: (value) => value == null ? 'اختر التصنيف' : null,
                  ),
                ),
                // الطبيعة / البيئة
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _terrainController,
                    decoration: InputDecoration(
                      labelText: 'الطبيعة/البيئة',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                ),
                // الإحداثيات
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: InputDecoration(
                          labelText: 'خط العرض (Latitude)',
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor)),
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
                          labelText: 'خط الطول (Longitude)',
                          filled: true,
                          fillColor: fillColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value!.isEmpty ? 'أدخل الإحداثي' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // روابط الصور
                const Text('روابط الصور:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._imageControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'رابط صورة ${index + 1}',
                            filled: true,
                            fillColor: fillColor,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor)),
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
                        style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
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
