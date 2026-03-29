import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/image_orientation_fix.dart';
import '../../data/models/upload_response.dart';
import '../../domain/usecases/upload_usecase.dart';
import '../../../../core/di/dependency_injection.dart';

/// Widget reutilizável para upload de imagens durante o cadastro
class ImageUploadWidget extends StatefulWidget {
  final String title;
  final String description;
  final String uploadType; // 'document', 'cref', 'profile'
  final String? documentType; // Para documentos: 'RG', 'CNH', etc.
  final Function(UploadResponse) onUploadSuccess;
  final Function(String) onUploadError;
  final UploadResponse? currentUpload;

  const ImageUploadWidget({
    super.key,
    required this.title,
    required this.description,
    required this.uploadType,
    this.documentType,
    required this.onUploadSuccess,
    required this.onUploadError,
    this.currentUpload,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final UploadUseCase _uploadUseCase = sl<UploadUseCase>();

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  File? _selectedFile;

  @override
  Widget build(BuildContext context) {
    final hasUpload = widget.currentUpload != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTextStyles.paragraph.copyWith(
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        GestureDetector(
          onTap: _isUploading ? null : _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: hasUpload
                  ? AppColors.primaryOrange.withValues(alpha: 0.1)
                  : AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasUpload
                    ? AppColors.primaryOrange
                    : AppColors.secondaryDark,
                width: hasUpload ? 2 : 0.5,
              ),
            ),
            child: _buildUploadContent(),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          widget.description,
          style: AppTextStyles.small.copyWith(color: AppColors.secondaryDark),
        ),
      ],
    );
  }

  Widget _buildUploadContent() {
    if (_isUploading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              value: _uploadProgress,
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enviando... ${(_uploadProgress * 100).toInt()}%',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (widget.currentUpload != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 32,
            color: AppColors.primaryOrange,
          ),
          const SizedBox(height: 8),
          Text(
            'Arquivo enviado com sucesso',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.cloud_upload_outlined,
          size: 32,
          color: AppColors.secondaryDark,
        ),
        const SizedBox(height: 8),
        Text(
          'Toque para adicionar foto',
          style: AppTextStyles.small.copyWith(color: AppColors.secondaryDark),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecionar ${widget.title.toLowerCase()}',
              style: AppTextStyles.h6Semibold.copyWith(
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Câmera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeria',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.small.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (image != null) {
        // Corrigir orientação EXIF antes de fazer upload
        // Passar isFromCamera: true se veio da câmera, false se veio da galeria
        File imageFile = File(image.path);
        imageFile = await fixImageOrientation(
          imageFile,
          isFromCamera: source == ImageSource.camera,
        );
        _selectedFile = imageFile;
        await _uploadImage();
      }
    } catch (e) {
      widget.onUploadError('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      UploadResponse response;

      switch (widget.uploadType) {
        case 'document':
          response = await _uploadUseCase.uploadDocument(
            file: _selectedFile!,
            documentType: widget.documentType ?? 'RG',
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        case 'cref':
          response = await _uploadUseCase.uploadCrefDocument(
            file: _selectedFile!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        case 'profile':
          response = await _uploadUseCase.uploadProfileImage(
            file: _selectedFile!,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;

        default:
          response = await _uploadUseCase.uploadTempFile(
            file: _selectedFile!,
            description: widget.title,
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
      }

      widget.onUploadSuccess(response);
    } catch (e) {
      widget.onUploadError(e.toString());
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }
}
