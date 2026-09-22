import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget serbaguna untuk menampilkan foto menu produk secara menarik.
/// Mendukung foto dari file lokal perangkat (Galeri / Kamera) maupun URL online,
/// dengan mode piring melingkar (circular plate) yang elegan sesuai POS modern.
class ProductImageWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final Widget? fallback;
  final IconData defaultIcon;
  final bool isCircularPlate;

  const ProductImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.fallback,
    this.defaultIcon = Icons.restaurant,
    this.isCircularPlate = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    if (imagePath.trim().isEmpty) {
      return fallback ?? _buildPlaceholder(radius);
    }

    final cleanPath = imagePath.trim();
    final isNetwork = cleanPath.startsWith('http://') || cleanPath.startsWith('https://');

    Widget imageContent;

    if (isNetwork) {
      imageContent = Image.network(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[100],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF43A047),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return fallback ?? _buildPlaceholder(radius);
        },
      );
    } else if (!kIsWeb) {
      try {
        String localPath = cleanPath;
        if (localPath.startsWith('file://')) {
          localPath = localPath.replaceFirst('file://', '');
        }
        final file = File(localPath);
        imageContent = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return fallback ?? _buildPlaceholder(radius);
          },
        );
      } catch (e) {
        imageContent = fallback ?? _buildPlaceholder(radius);
      }
    } else {
      imageContent = fallback ?? _buildPlaceholder(radius);
    }

    if (isCircularPlate) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: imageContent,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: imageContent,
    );
  }

  Widget _buildPlaceholder(BorderRadius radius) {
    if (isCircularPlate) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Center(
          child: Icon(
            defaultIcon,
            size: (width != null && height != null)
                ? (width! < height! ? width! * 0.45 : height! * 0.45)
                : 24,
            color: Colors.grey[500],
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: radius,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Icon(
          defaultIcon,
          size: (width != null && height != null)
              ? (width! < height! ? width! * 0.5 : height! * 0.5)
              : 22,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
