import 'dart:io';

import 'package:flutter/material.dart';

import '../apis/api.dart';
import '../models/catalog_item.dart';
import '../utils/auth_store.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../utils/native_bridge.dart';
import '../widgets/action_buttons.dart';
import '../widgets/terminal_field.dart';

class ItemFormPage extends StatefulWidget {
  const ItemFormPage({super.key, required this.editItem, required this.onBack, required this.onSaved, required this.onTokenInvalid, required this.showMessage});

  final CatalogItem? editItem;
  final VoidCallback onBack;
  final VoidCallback onSaved;
  final VoidCallback onTokenInvalid;
  final void Function(String message, {required bool success}) showMessage;

  @override
  State<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends State<ItemFormPage> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  String? _type;
  String? _rarity;
  String? _imagePath;
  String? _nameError;
  String? _priceError;
  String? _typeError;
  String? _rarityError;
  String? _imageError;
  bool _loading = false;

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    if (item != null) {
      _name.text = item.name;
      _price.text = item.price.toString();
      _description.text = item.description;
      _type = item.type;
      _rarity = item.rarity.toString();
    }
  }

  Future<void> _pickImage() async {
    final path = await NativeBridge.pickImage();
    if (path != null) setState(() { _imagePath = path; _imageError = null; });
  }

  Future<void> _submit() async {
    if (!_isEdit) {
      setState(() {
        _nameError = _name.text.trim().isEmpty ? 'Nama wajib diisi.' : null;
        _priceError = _price.text.trim().isEmpty ? 'Harga wajib diisi.' : null;
        _typeError = _type == null ? 'Tipe wajib dipilih.' : null;
        _rarityError = _rarity == null ? 'Rarity wajib dipilih.' : null;
        _imageError = _imagePath == null ? 'Gambar wajib dipilih.' : null;
      });
      if ([_nameError, _priceError, _typeError, _rarityError, _imageError].any((item) => item != null)) return;
    }
    final payload = ItemPayload(
      name: _isEdit && _name.text.trim() == widget.editItem!.name ? null : _name.text.trim(),
      type: _isEdit && _type == widget.editItem!.type ? null : _type,
      price: _isEdit && _price.text.trim() == widget.editItem!.price.toString() ? null : _price.text.trim(),
      rarity: _isEdit && _rarity == widget.editItem!.rarity.toString() ? null : _rarity,
      description: _isEdit && _description.text.trim() == widget.editItem!.description ? null : _description.text.trim(),
      imagePath: _imagePath,
    );
    if (_isEdit && payload.isEmpty) {
      widget.onBack();
      return;
    }
    final token = await AuthStore.token;
    if (token == null) {
      widget.showMessage(tokenMissingMessage, success: false);
      widget.onTokenInvalid();
      return;
    }
    setState(() => _loading = true);
    final result = _isEdit ? await Api.updateItem(token, widget.editItem!.id, payload) : await Api.addItem(token, payload);
    if (!mounted) return;
    setState(() => _loading = false);
    widget.showMessage(result.message.isEmpty ? (result.success ? 'Berhasil.' : 'Gagal.') : result.message, success: result.success);
    if (result.message == tokenMissingMessage) {
      widget.onTokenInvalid();
      return;
    }
    if (result.success) widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(22, 18, 22, 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.chevron_left), label: const Text('Kembali')),
      const SizedBox(height: 28),
      Text(_isEdit ? 'UPDATE ITEM' : 'TAMBAH ITEM BARU', style: const TextStyle(color: AppColors.textPrimary, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(height: 26),
      InkWell(onTap: _pickImage, borderRadius: BorderRadius.circular(18), child: Container(height: 190, width: double.infinity, decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(18), border: Border.all(color: _imageError == null ? AppColors.stroke : AppColors.error, style: BorderStyle.solid)), child: _imagePath != null ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(_imagePath!), fit: BoxFit.cover)) : widget.editItem?.image != null ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network('$apiBase${widget.editItem!.image}', fit: BoxFit.cover)) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 42), SizedBox(height: 10), Text('Ketuk untuk unggah gambar', style: TextStyle(color: AppColors.textSecondary))]))),
      if (_imageError != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_imageError!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
      const SizedBox(height: 20),
      TerminalField(label: 'NAMA', hint: 'Nama item', controller: _name, error: _nameError, onChanged: (_) => setState(() => _nameError = null)),
      const SizedBox(height: 16),
      DropdownField(label: 'TIPE', value: _type, error: _typeError, items: const ['equipment', 'supplies'], onChanged: (value) => setState(() { _type = value; _typeError = null; })),
      const SizedBox(height: 16),
      DropdownField(label: 'RARITY', value: _rarity, error: _rarityError, items: const ['1', '2', '3', '4', '5'], onChanged: (value) => setState(() { _rarity = value; _rarityError = null; })),
      const SizedBox(height: 16),
      TerminalField(label: 'HARGA', hint: 'Harga', controller: _price, keyboardType: TextInputType.number, error: _priceError, onChanged: (_) => setState(() => _priceError = null)),
      const SizedBox(height: 16),
      TextField(controller: _description, minLines: 4, maxLines: 6, style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(labelText: 'Deskripsi', labelStyle: const TextStyle(color: AppColors.textSecondary), hintText: 'Deskripsi opsional', hintStyle: const TextStyle(color: AppColors.textMuted), filled: true, fillColor: AppColors.input, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.stroke)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyan)))) ,
      const SizedBox(height: 26),
      PrimaryActionButton(text: _isEdit ? 'UPDATE ITEM' : 'TAMBAH ITEM', loading: _loading, onPressed: _submit),
    ]))));
  }
}

class DropdownField extends StatelessWidget {
  const DropdownField({super.key, required this.label, required this.value, required this.items, required this.onChanged, this.error});

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(height: 6), DropdownButtonFormField<String>(value: value, dropdownColor: AppColors.panel, style: const TextStyle(color: AppColors.textPrimary), items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: onChanged, decoration: InputDecoration(filled: true, fillColor: AppColors.input, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: error == null ? AppColors.stroke : AppColors.error)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.cyan)))), if (error != null) ...[const SizedBox(height: 5), Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12))]]);
}
