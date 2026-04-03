import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/constants.dart';

import '../../models/product_model.dart'; // Added import
import '../../widgets/universal_image.dart';

class PostItemScreen extends StatefulWidget {
  final ProductModel? productToEdit; // Added parameter

  const PostItemScreen({Key? key, this.productToEdit}) : super(key: key);

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  String _selectedCategory = Constants.categories.first;
  
  // For mobile
  File? _imageFile;
  // For web
  Uint8List? _imageBytes;
  String? _imageName;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final product = widget.productToEdit;
    _titleController = TextEditingController(text: product?.title ?? '');
    _descController = TextEditingController(text: product?.description ?? '');
    _priceController = TextEditingController(text: product?.price.toString() ?? '');
    if (product != null && Constants.categories.contains(product.category)) {
      _selectedCategory = product.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = pickedFile.name;
        });
      } else {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageBytes = bytes; // Use bytes for upload even on mobile for consistency
          _imageName = pickedFile.name;
        });
      }
    }
  }

  Future<void> _postItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    // If creating new, image is required. If editing, it's optional (keep old one).
    if (widget.productToEdit == null && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image'), backgroundColor: Colors.red),
      );
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    String? error;
    if (widget.productToEdit == null) {
      // Create New
       error = await productProvider.addProduct(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        imageBytes: _imageBytes!, 
        imageName: _imageName ?? 'image.jpg',
        sellerId: user.uid,
        sellerName: user.displayName ?? 'Unknown',
      );
    } else {
      // Update Existing
      final product = widget.productToEdit!;
      error = await productProvider.editProduct(
        productId: product.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        category: _selectedCategory,
        imageBytes: _imageBytes, // Can be null
        imageName: _imageName,
        currentImageUrl: product.imageUrl,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        isSold: product.isSold,
        createdAt: product.createdAt,
      );
    }

    if (error == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.productToEdit == null ? 'Item posted successfully!' : 'Item updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // Image Widget Logic
    Widget imageWidget;
    if (_imageBytes != null) {
       // kIsWeb check not strictly needed if we just use MemoryImage for both after picking
       imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
       );
    } else {
      imageWidget = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.productToEdit == null ? 'Sell Item' : 'Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: _imageBytes != null || widget.productToEdit != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _imageBytes != null 
                                ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                                : UniversalImage(imagePath: widget.productToEdit!.imageUrl, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                              Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _titleController,
                  label: 'Title',
                  validator: (val) => val!.isEmpty ? 'Enter title' : null,
                ),
                CustomTextField(
                  controller: _priceController,
                  label: 'Price (₹)', // Changed currency symbol
                  keyboardType: TextInputType.number,
                  validator: (val) => val!.isEmpty ? 'Enter price' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: Constants.categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val!;
                    });
                  },
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _descController,
                  label: 'Description',
                  maxLines: 3,
                  validator: (val) => val!.isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: widget.productToEdit == null ? 'POST ITEM' : 'UPDATE ITEM',
                  onPressed: _postItem,
                  isLoading: productProvider.isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
