import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProductProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Stream<List<ProductModel>> get productsStream => _firestoreService.getProducts();

  Future<String?> addProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required Uint8List imageBytes, // Changed from File
    required String imageName,
    required String sellerId,
    required String sellerName,
  }) async {
    _setLoading(true);
    try {
      String imageUrl = await _storageService.uploadProductImage(imageBytes, imageName);
      ProductModel product = ProductModel(
        id: '', // Firestore auto-id
        sellerId: sellerId,
        sellerName: sellerName,
        title: title,
        description: description,
        price: price,
        category: category,
        imageUrl: imageUrl,
        isSold: false,
        createdAt: DateTime.now(),
      );
      await _firestoreService.addProduct(product);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> editProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
    required Uint8List? imageBytes, // Optional if not changing
    required String? imageName,
    required String currentImageUrl,
    required String sellerId,
    required String sellerName,
    required bool isSold,
    required DateTime createdAt,
  }) async {
    _setLoading(true);
    try {
      String imageUrl = currentImageUrl;
      if (imageBytes != null && imageName != null) {
        imageUrl = await _storageService.uploadProductImage(imageBytes, imageName);
      }

      ProductModel product = ProductModel(
        id: productId,
        sellerId: sellerId,
        sellerName: sellerName,
        title: title,
        description: description,
        price: price,
        category: category,
        imageUrl: imageUrl,
        isSold: isSold,
        createdAt: createdAt,
      );
      await _firestoreService.updateProduct(product);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsSold(String productId) async {
    await _firestoreService.updateProductStatus(productId, true);
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _firestoreService.deleteProduct(productId);
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
