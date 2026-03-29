import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter/services.dart';

/// Modal de match confirmado para quando o personal aceita a proposta
/// Design baseado no Figma do TreinoPro
class MatchModal extends StatefulWidget {
  final String studentName;
  final String studentRating;
  final String studentExperience;
  final String studentBio;
  final String studentImageUrl;
  final VoidCallback onChatPressed;
  final VoidCallback onClose;

  const MatchModal({
    super.key,
    required this.studentName,
    required this.studentRating,
    required this.studentExperience,
    required this.studentBio,
    required this.studentImageUrl,
    required this.onChatPressed,
    required this.onClose,
  });

  @override
  State<MatchModal> createState() => _MatchModalState();
}

class _MatchModalState extends State<MatchModal> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Animação de entrada do modal
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
    _playSuccessSound();
  }

  // Som de sucesso quando o match é confirmado
  Future<void> _playSuccessSound() async {
    try {
      // Som de sucesso com feedback tátil positivo
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Ignora se não conseguir reproduzir
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF42464D), width: 0.24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header com ícone de handshake
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.handshake,
                            size: 29,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Match confirmado',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF42464D),
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Encontramos para você um aluno qualificado para sua aula.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                          fontFamily: 'Fira Sans',
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Divisor
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: const Color(0xFFA6A6A6),
                ),

                const SizedBox(height: 16),

                // Informações do aluno
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Foto e dados básicos
                      Row(
                        children: [
                          // Foto do aluno
                          Container(
                            width: 47,
                            height: 47,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              shape: BoxShape.circle,
                              image: widget.studentImageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.studentImageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: widget.studentImageUrl.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.grey,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Nome e avaliação
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.studentName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D3748),
                                    fontFamily: 'Fira Sans',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 22,
                                      color: AppColors.primaryOrange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.studentRating,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2D3748),
                                        fontFamily: 'Fira Sans',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '|',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2D3748),
                                        fontFamily: 'Fira Sans',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.studentExperience,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF2D3748),
                                        fontFamily: 'Fira Sans',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Bio do aluno
                      Container(
                        width: double.infinity,
                        child: Text(
                          widget.studentBio,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2D3748),
                            fontFamily: 'Fira Sans',
                            height: 1.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botão Chat
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onChatPressed,
                          icon: const Icon(
                            Icons.chat,
                            size: 16,
                            color: AppColors.primaryOrange,
                          ),
                          label: const Text(
                            'Chat',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primaryOrange,
                              fontFamily: 'Fira Sans',
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 40,
                            ),
                            side: const BorderSide(
                              color: AppColors.primaryOrange,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Divisor
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  color: const Color(0xFFA6A6A6),
                ),

                const SizedBox(height: 24),

                // Seção de atenção
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D3748),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.warning,
                            size: 21,
                            color: Color(0xFFF9F9F9),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Atenção',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF9F9F9),
                              fontFamily: 'Fira Sans',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'O TreinoPro não se responsabiliza por eventuais custos adicionais que o profissional tenha com a academia onde irá atuar. É de responsabilidade do personal verificar e arcar com possíveis taxas exigidas pelo local.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF9F9F9),
                            fontFamily: 'Fira Sans',
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
