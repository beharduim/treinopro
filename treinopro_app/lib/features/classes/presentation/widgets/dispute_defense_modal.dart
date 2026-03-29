import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../auth/domain/usecases/upload_usecase.dart';
import '../../data/models/class_response_dto.dart';
import '../bloc/classes_bloc.dart';

/// Modal de defesa em disputa de no-show — com texto + anexos de evidência.
/// Integrado ao ClassesBloc para loading/success/error.
class DisputeDefenseModal extends StatefulWidget {
  final String classId;
  final ClassResponseDto classData;

  const DisputeDefenseModal({
    super.key,
    required this.classId,
    required this.classData,
  });

  /// Exibe o modal como bottom sheet.
  static Future<void> show(
    BuildContext context,
    String classId,
    ClassResponseDto classData,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ClassesBloc>(),
        child: DisputeDefenseModal(classId: classId, classData: classData),
      ),
    );
  }

  @override
  State<DisputeDefenseModal> createState() => _DisputeDefenseModalState();
}

class _DisputeDefenseModalState extends State<DisputeDefenseModal> {
  final TextEditingController _textController = TextEditingController();
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _awaitingBlocResult = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
      if (image != null && mounted) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (_isUploading || _isSubmitting) return;

    if (!_isDefenseDeadlineOpen(widget.classData.evidenceDeadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.classData.evidenceDeadline != null
                ? 'Prazo para enviar a defesa encerrado em ${_formatDeadlineDateTime(widget.classData.evidenceDeadline!)}.'
                : 'Prazo para enviar a defesa expirado.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, descreva sua defesa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<String>? evidenceUrls;

    // Upload de imagens se houver
    if (_selectedImages.isNotEmpty) {
      setState(() => _isUploading = true);
      try {
        final uploadUseCase = sl<UploadUseCase>();
        evidenceUrls = [];
        for (final image in _selectedImages) {
          final response = await uploadUseCase.uploadDisputeEvidence(
            file: image,
            classId: widget.classId,
          );
          if (response.url.isNotEmpty) {
            evidenceUrls.add(response.url);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao enviar imagens: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (mounted) setState(() => _isUploading = false);
    }

    // Enviar via Bloc
    if (mounted) {
      setState(() {
        _isSubmitting = true;
        _awaitingBlocResult = true;
      });
      context.read<ClassesBloc>().add(
        ClassesSubmitDisputeDefense(
          classId: widget.classId,
          text: text,
          evidenceUrls: evidenceUrls,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final deadline = widget.classData.evidenceDeadline;
    final hasDeadline = deadline != null;
    final isDeadlineOpen = _isDefenseDeadlineOpen(deadline);

    return BlocListener<ClassesBloc, ClassesState>(
      listener: (context, state) {
        if (!_awaitingBlocResult) return;

        if (state is ClassesOperationSuccess) {
          _awaitingBlocResult = false;
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else if (state is ClassesOperationFailure) {
          setState(() {
            _awaitingBlocResult = false;
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(bottom: bottomPadding),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Título
                Row(
                  children: [
                    IconButton(
                      onPressed: (_isUploading || _isSubmitting)
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      splashRadius: 20,
                    ),
                    Icon(Icons.gavel, color: Colors.orange.shade700, size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Enviar Defesa',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Info de prazo
                if (hasDeadline)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDeadlineOpen
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDeadlineOpen
                            ? Colors.orange.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isDeadlineOpen
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isDeadlineOpen
                                ? 'Prazo máximo para enviar a defesa: ${_formatDeadlineDateTime(deadline!)}'
                                : 'Prazo para enviar a defesa encerrado em ${_formatDeadlineDateTime(deadline!)}',
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 12,
                              color: isDeadlineOpen
                                  ? Colors.orange.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Descrição
                const Text(
                  'Descreva sua versão dos fatos. O moderador avaliará sua defesa junto com as evidências.',
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Campo de texto
                TextField(
                  controller: _textController,
                  maxLines: 5,
                  maxLength: 1000,
                  enabled: isDeadlineOpen,
                  decoration: InputDecoration(
                    hintText: isDeadlineOpen
                        ? 'Eu estava no local às...'
                        : 'Prazo encerrado para envio da defesa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Seção de evidências
                const Text(
                  'Evidências (opcional)',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                // Botões de seleção de imagem
                Row(
                  children: [
                    _buildImageButton(
                      icon: Icons.camera_alt,
                      label: 'Câmera',
                      onTap: isDeadlineOpen
                          ? () => _pickImage(ImageSource.camera)
                          : () {},
                    ),
                    const SizedBox(width: 12),
                    _buildImageButton(
                      icon: Icons.photo_library,
                      label: 'Galeria',
                      onTap: isDeadlineOpen
                          ? () => _pickImage(ImageSource.gallery)
                          : () {},
                    ),
                  ],
                ),

                // Preview das imagens selecionadas
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (_, index) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Botão de enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_isUploading || _isSubmitting || !isDeadlineOpen)
                        ? null
                        : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: (_isUploading || _isSubmitting)
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Enviar Defesa',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isDefenseDeadlineOpen(DateTime? deadline) {
    return deadline == null || deadline.isAfter(DateTime.now());
  }

  String _formatDeadlineDateTime(DateTime deadline) {
    final day = deadline.day.toString().padLeft(2, '0');
    final month = deadline.month.toString().padLeft(2, '0');
    final year = deadline.year.toString().padLeft(4, '0');
    final hour = deadline.hour.toString().padLeft(2, '0');
    final minute = deadline.minute.toString().padLeft(2, '0');
    return '$day/$month/$year às $hour:$minute';
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h restantes';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m restantes';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m restantes';
    } else {
      return 'Prazo expirado';
    }
  }
}
