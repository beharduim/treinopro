import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/utils/image_orientation_fix.dart';
import '../../data/models/class_response_dto.dart';
import '../../data/models/class_timeline_dto.dart';

class ReportNoShowModal extends StatefulWidget {
  final ClassResponseDto classData;
  final ClassTimelineDto timeline;
  final bool isPersonalNoShow; // true se for reportar ausência do personal
  final Function(Map<String, dynamic>)? onReport;

  const ReportNoShowModal({
    super.key,
    required this.classData,
    required this.timeline,
    this.isPersonalNoShow = false,
    this.onReport,
  });

  @override
  State<ReportNoShowModal> createState() => _ReportNoShowModalState();
}

class _ReportNoShowModalState extends State<ReportNoShowModal> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _evidenceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedReason = '';
  List<File> _selectedImages = [];

  final List<String> _reasonOptions = [
    'Não compareceu ao horário agendado',
    'Cancelou em cima da hora',
    'Não respondeu às mensagens',
    'Local não estava disponível',
    'Outro motivo',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _evidenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.08; // 8% da altura da tela
    final handleBarMargin = screenHeight * 0.02; // 2% da altura da tela

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: handleBarMargin),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.report_problem,
                            color: Colors.red.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isPersonalNoShow
                                    ? 'Reportar Ausência do Personal'
                                    : 'Reportar Ausência do Aluno',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              Text(
                                'Informe o motivo da ausência',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: screenHeight * 0.03,
                    ), // 3% da altura da tela
                    // Informações da aula
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow('Aluno', widget.classData.studentName),
                          _buildInfoRow(
                            'Personal',
                            widget.classData.personalName,
                          ),
                          _buildInfoRow('Local', widget.classData.location),
                          _buildInfoRow(
                            'Data',
                            _formatDate(widget.classData.date),
                          ),
                          _buildInfoRow('Horário', widget.classData.time),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Motivo da ausência
                    const Text(
                      'Motivo da ausência:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Lista de motivos
                    Material(
                      child: Column(
                        children: _reasonOptions
                            .map(
                              (reason) => RadioListTile<String>(
                                title: Text(
                                  reason,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                value: reason,
                                groupValue: _selectedReason,
                                activeColor: const Color(
                                  0xFFFF6B35,
                                ), // Laranja do app
                                onChanged: (value) {
                                  setState(() {
                                    _selectedReason = value ?? '';
                                  });
                                },
                                contentPadding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Campo de motivo personalizado
                    if (_selectedReason == 'Outro motivo')
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Descreva o motivo',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF6B35)),
                          ),
                        ),
                        maxLines: 2,
                      ),

                    const SizedBox(height: 16),

                    // Seção de evidências com imagens
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Evidências (opcional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adicione fotos do local vazio, prints de conversa, etc.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),

                        // Botão para adicionar imagens
                        OutlinedButton.icon(
                          onPressed: _showImageSourceOptions,
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: const Text('Adicionar Fotos'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B35),
                            side: const BorderSide(color: Color(0xFFFF6B35)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        // Galeria de imagens selecionadas
                        if (_selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _selectedImages[index],
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removeImage(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Informação sobre disputa
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este reporte iniciará um processo de disputa. O outro usuário terá 24h para responder.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botões
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _canReport() ? _handleReport : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Confirmar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF2D3748), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  bool _canReport() {
    if (_selectedReason.isEmpty) return false;
    if (_selectedReason == 'Outro motivo' &&
        _reasonController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  void _handleReport() {
    if (widget.onReport != null) {
      // Criar o DTO com os dados do formulário
      final reportData = {
        'reason': _selectedReason,
        'notes': _selectedReason == 'Outro motivo'
            ? _reasonController.text.trim()
            : null,
        'evidenceImages': _selectedImages.map((image) => image.path).toList(),
      };

      widget.onReport!(reportData);
    }
    Navigator.of(context).pop();
  }

  // Abre opções nativas para selecionar imagem (Câmera / Galeria)
  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Usa image_picker para capturar/selecionar imagem
  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        // Para galeria: seleção múltipla
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
          requestFullMetadata: false,
        );
        if (images.isNotEmpty) {
          // Corrigir orientação EXIF de todas as imagens
          // Galeria: isFromCamera = false
          final List<File> correctedImages = [];
          for (final image in images) {
            File imageFile = File(image.path);
            imageFile = await fixImageOrientation(
              imageFile,
              isFromCamera: false, // Imagens da galeria não precisam de flip
            );
            correctedImages.add(imageFile);
          }
          setState(() {
            _selectedImages.addAll(correctedImages);
          });
        }
      } else {
        // Para câmera: seleção única
        final XFile? picked = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
          requestFullMetadata: false,
        );
        if (picked != null) {
          // Corrigir orientação EXIF antes de adicionar
          // Câmera: isFromCamera = true (aplica flip para corrigir selfies)
          File imageFile = File(picked.path);
          imageFile = await fixImageOrientation(
            imageFile,
            isFromCamera:
                true, // Imagens da câmera precisam de flip para selfies
          );
          setState(() {
            _selectedImages.add(imageFile);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
}
