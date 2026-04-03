import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class StorageService {
  // Instead of uploading to Firebase Storage, we compress and return Base64 string
  Future<String> uploadProductImage(Uint8List imageBytes, String fileName) async {
    // 1. Decode image
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) return '';

    // 2. Resize if too large (max 800px width/height) to stay under Firestore 1MB limit
    if (image.width > 800 || image.height > 800) {
      image = img.copyResize(image, width: 800, height: 800, maintainAspect: true);
    }

    // 3. Encode as JPEG with quality 70
    List<int> compressedBytes = img.encodeJpg(image, quality: 70);

    // 4. Convert to Base64 string
    String base64Image = base64Encode(compressedBytes);
    return base64Image;
  }
}
