// EditSingleLandmarkScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSingleLandmarkScreen extends StatefulWidget {
  final DocumentSnapshot landmarkDoc;

  const EditSingleLandmarkScreen({super.key, required this.landmarkDoc});

  @override
  State<EditSingleLandmarkScreen> createState() => _EditSingleLandmarkScreenState();
}

class _EditSingleLandmarkScreenState extends State<EditSingleLandmarkScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _terrainController;

  String? _selectedGovernorate;
  String? _selectedType;

  List<TextEditingController> _imageControllers = [];
  bool _isLoading = false;

  final List<String> _governorates = [
    "دمشق","ريف دمشق","درعا","السويداء","القنيطرة","حمص","حماة","اللاذقية","طرطوس",
    "ادلب","الرقة","الحسكة","دير الزور","حلب"
  ];

  final List<String> _types = ["ديني","ثقافي","تاريخي","طبيعي","ترفيهي"];

  @override
  void initState() {
    super.initState();
    final data = widget.landmarkDoc.data() as Map<String, dynamic>;
    _nameController = TextEditingController(text: data['name'] ?? '');
    _descriptionController = TextEditingController(text: data['description'] ?? '');
    _terrainController = TextEditingController(text: data['terrain'] ?? '');
    _latController = TextEditingController(text: (data['latitude'] ?? '').toString());
    _lngController = TextEditingController(text: (data['longitude'] ?? '').toString());
    _selectedGovernorate = data['governorate'];
    _selectedType = data['type'];

    final images = List<String>.from(data['images'] ?? []);
    if (images.isNotEmpty) {
      _imageControllers = images.map((url) => TextEditingController(text: url)).toList();
    } else {
      _imageControllers = [TextEditingController()];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _terrainController.dispose();
    _latController.dispose();
    _lngController.dispose();
    for (var c in _imageControllers) c.dispose();
    super.dispose();
  }

  void _addImageField() => setState(() => _imageControllers.add(TextEditingController()));
  void _removeImageField(int index) => setState(() {
    if (_imageControllers.length > 1) _imageControllers.removeAt(index);
  });

  Future<void> _updateLandmark() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedGovernorate == null || _selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر المحافظة والنوع')));
        return;
      }

      setState(() { _isLoading = true; });

      try {
        final images = _imageControllers.map((c) => c.text.trim()).where((url) => url.isNotEmpty).toList();

        final data = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim(),
          'governorate': _selectedGovernorate,
          'type': _selectedType,
          'terrain': _terrainController.text.trim(),
          'latitude': double.tryParse(_latController.text) ?? 0.0,
          'longitude': double.tryParse(_lngController.text) ?? 0.0,
          'images': images,
        };

        await widget.landmarkDoc.reference.update(data);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تعديل المعلم بنجاح')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      } finally { setState(() { _isLoading = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final fillColor = theme.inputDecorationTheme.fillColor ?? Colors.white;

    return Scaffold(
      appBar: AppBar(title: const Text("تعديل المعلم"), backgroundColor: primaryColor),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'اسم المعلم', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.isEmpty ? 'لا يمكن أن يكون فارغ' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'الوصف', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  validator: (v) => v!.isEmpty ? 'لا يمكن أن يكون فارغ' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGovernorate,
                  decoration: InputDecoration(labelText: 'المحافظة', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: _governorates.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setState(() => _selectedGovernorate = val),
                  validator: (v) => v == null ? 'اختر المحافظة' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(labelText: 'التصنيف', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (val) => setState(() => _selectedType = val),
                  validator: (v) => v == null ? 'اختر التصنيف' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _terrainController,
                  decoration: InputDecoration(labelText: 'طبيعة الطريق ', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: InputDecoration(labelText: 'خط العرض', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'أدخل الإحداثي' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration: InputDecoration(labelText: 'خط الطول', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'أدخل الإحداثي' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('روابط الصور:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._imageControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(labelText: 'رابط صورة ${index + 1}', filled: true, fillColor: fillColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      if (_imageControllers.length > 1)
                        IconButton(onPressed: () => _removeImageField(index), icon: const Icon(Icons.remove_circle, color: Colors.red)),
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
                        onPressed: _updateLandmark,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('تعديل المعلم', style: TextStyle(color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
