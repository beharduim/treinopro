import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
// Imports de recontratação desativados temporariamente
// import '../../../proposals/presentation/pages/recontract_page.dart';
// import '../../../proposals/presentation/bloc/proposals_bloc.dart';
// import '../../../proposals/presentation/bloc/proposals_event.dart';
import '../../data/services/evaluation_api_service.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_state.dart';

class PersonalEvaluationPage extends StatefulWidget {
  final String trainerName;
  final String classId;
  final String? personalId;
  final bool isRecontracting;

  const PersonalEvaluationPage({
    super.key, 
    required this.trainerName,
    required this.classId,
    this.personalId,
    this.isRecontracting = false,
  });

  @override
  State<PersonalEvaluationPage> createState() => _PersonalEvaluationPageState();
}

class _PersonalEvaluationPageState extends State<PersonalEvaluationPage> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _hasEvaluated = false;

  // Dados do personal para recontratação (desativados temporariamente)
  // String? _personalProfileImageUrl;
  // String? _personalRating;
  // String? _personalTimeOnPlatform;
  double? _getClassPriceFromBloc(BuildContext context) {
    try {
      final state = context.read<ClassesBloc>().state;
      if (state is ClassesLoaded) {
        final classData = state.classes.firstWhere((c) => c.id == widget.classId);
        return classData.proposalPrice;
      }
    } catch (_) {}
    return null;
  }

  String _formatCurrency(double value) {
    return 'R\$ ' + value.toStringAsFixed(2).replaceAll('.', ',');
  }

  @override
  void initState() {
    super.initState();
    _loadLastEvaluationDraft();
    _checkExistingRating();
  }

  Future<void> _checkExistingRating() async {
    try {
      final evaluationService = sl<EvaluationApiService>();
      final exists = await evaluationService.hasExistingRating(
        classId: widget.classId,
        type: 'student_to_personal',
      );
      if (exists && mounted) {
        setState(() => _hasEvaluated = true);
      }
    } catch (_) {
      // Ignora falha de verificação
    }
  }

  Future<void> _loadLastEvaluationDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = widget.personalId != null
          ? 'last_eval_comment_${widget.personalId}'
          : 'last_eval_comment_global';
      final draft = prefs.getString(key);
      if (draft != null && draft.isNotEmpty && mounted) {
        _commentController.text = draft;
      }
    } catch (_) {
      // Ignora falha de cache local
    }
  }

  Future<void> _persistLastEvaluationDraft(String comment) async {
    if (comment.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = widget.personalId != null
          ? 'last_eval_comment_${widget.personalId}'
          : 'last_eval_comment_global';
      await prefs.setString(key, comment);
    } catch (_) {
      // Ignora falha de cache local
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onStarTapped(int rating) {
    print('⭐ [PERSONAL_EVAL] Estrela clicada: $rating');
    setState(() {
      _selectedRating = rating;
    });
    print('⭐ [PERSONAL_EVAL] _selectedRating atualizado para: $_selectedRating');
  }

  void _onSendEvaluation() async {
    // ✅ Validação extra: garantir que rating está entre 1 e 5
    if (_selectedRating == 0 || _selectedRating < 1 || _selectedRating > 5) {
      print('⚠️ [PERSONAL_EVAL] Rating inválido: $_selectedRating');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma avaliação'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    if (_hasEvaluated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já avaliou este personal trainer'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final evaluationService = sl<EvaluationApiService>();
      
      // ✅ Debug: Verificar valor antes de enviar
      print('⭐ [PERSONAL_EVAL] Enviando avaliação - rating: $_selectedRating');
      
      final comment = _commentController.text.trim();

      await evaluationService.createPersonalRating(
        classId: widget.classId,
        rating: _selectedRating,
        comment: comment.isNotEmpty ? comment : null,
        // Para simplificar, usamos a mesma nota para todos os critérios
        punctuality: _selectedRating,
        communication: _selectedRating,
        knowledge: _selectedRating,
        motivation: _selectedRating,
        equipment: _selectedRating,
      );
      
      print('✅ [PERSONAL_EVAL] Avaliação enviada com sucesso - rating: $_selectedRating');

      await _persistLastEvaluationDraft(comment);

      // Estado será atualizado automaticamente via WebSocket

      setState(() {
        _hasEvaluated = true;
        _isLoading = false;
      });

      _showEvaluationSentModal();
    } catch (e) {
      final message = e.toString();
      final alreadyRated = message.contains('já existe') ||
          message.contains('ja existe') ||
          message.contains('already');

      if (alreadyRated) {
        setState(() {
          _hasEvaluated = true;
          _isLoading = false;
        });
        if (mounted) _showEvaluationSentModal();
        return;
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar avaliação: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEvaluationSentModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Avaliação enviada!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Obrigado pela sua avaliação. Isso ajuda a manter a qualidade dos profissionais no TreinoPro.',
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 16,
                    color: Color(0xFF42464D),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final rootNav = Navigator.of(context);
                      rootNav.pop(); // Fecha o modal
                      if (rootNav.canPop()) {
                        rootNav.pop(); // Fecha só a tela de avaliação
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Método de recontratação desativado temporariamente
  // void _onRecontractPersonal() async {
  //   if (_selectedRating == 0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Por favor, selecione uma avaliação antes de recontratar'),
  //         backgroundColor: AppColors.primaryOrange,
  //       ),
  //     );
  //     return;
  //   }

  //   if (_hasEvaluated) {
  //     // Se já avaliou, apenas navega para recontratação
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => BlocProvider(
  //           create: (context) {
  //             final bloc = sl<ProposalsBloc>();
  //             // Inicializar imediatamente
  //             bloc.add(const ProposalsInitialize());
  //             // Carregar métodos de pagamento após inicialização
  //             WidgetsBinding.instance.addPostFrameCallback((_) {
  //               if (!bloc.isClosed) {
  //                 bloc.add(const ProposalsLoadPaymentMethods());
  //               }
  //             });
  //             return bloc;
  //           },
  //           child: RecontractPage(
  //             personalId: widget.personalId,
  //             personalName: widget.trainerName,
  //             personalProfileImageUrl: _personalProfileImageUrl,
  //             personalRating: _personalRating,
  //             personalTimeOnPlatform: _personalTimeOnPlatform,
  //           ),
  //         ),
  //       ),
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     final evaluationService = sl<EvaluationApiService>();
      
  //     // ✅ Debug: Verificar valor antes de enviar (recontratação)
  //     print('⭐ [PERSONAL_EVAL] Enviando avaliação (recontratação) - rating: $_selectedRating');
      
  //     await evaluationService.createPersonalRating(
  //       classId: widget.classId,
  //       rating: _selectedRating,
  //       comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
  //       // Para simplificar, usamos a mesma nota para todos os critérios
  //       punctuality: _selectedRating,
  //       communication: _selectedRating,
  //       knowledge: _selectedRating,
  //       motivation: _selectedRating,
  //       equipment: _selectedRating,
  //     );
      
  //     print('✅ [PERSONAL_EVAL] Avaliação enviada com sucesso (recontratação) - rating: $_selectedRating');

  //     setState(() {
  //       _hasEvaluated = true;
  //       _isLoading = false;
  //     });

  //     // Navegar para tela de recontratação
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => BlocProvider(
  //           create: (context) {
  //             final bloc = sl<ProposalsBloc>();
  //             // Inicializar imediatamente
  //             bloc.add(const ProposalsInitialize());
  //             // Carregar métodos de pagamento após inicialização
  //             WidgetsBinding.instance.addPostFrameCallback((_) {
  //               if (!bloc.isClosed) {
  //                 bloc.add(const ProposalsLoadPaymentMethods());
  //               }
  //             });
  //             return bloc;
  //           },
  //           child: RecontractPage(
  //             personalId: widget.personalId,
  //             personalName: widget.trainerName,
  //             personalProfileImageUrl: _personalProfileImageUrl,
  //             personalRating: _personalRating,
  //             personalTimeOnPlatform: _personalTimeOnPlatform,
  //           ),
  //         ),
  //       ),
  //     );
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //     });

  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Erro ao enviar avaliação: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),

              // Conteúdo rolável (evita overflow em telas menores)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildClassCompletedCard(),
                      const SizedBox(height: 16),
                      _buildEvaluationCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Botões fixos ao rodapé
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            // Voltar pela pilha de navegação
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.chevron_left,
            size: 24,
            color: Color(0xFF2D3748),
          ),
        ),
        Expanded(
          child: const Text(
            'Avalie o personal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildClassCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(14.5),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Aula concluída',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF9F9F9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Obrigado por finalizar a aula. Sua avaliação ajuda outros alunos a escolherem o profissional certo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFFF9F9F9),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          // Valor da aula (com descontos aplicados na proposta)
          Builder(
            builder: (context) {
              final price = _getClassPriceFromBloc(context);
              if (price == null) return const SizedBox.shrink();
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_money, color: AppColors.primaryOrange, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _formatCurrency(price),
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF9F9F9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          
        ],
      ),
    );
  }

  Widget _buildEvaluationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(14.5),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Avalie seu Personal',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Como foi sua experiência com ${widget.trainerName}?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFF2D3748),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildStarRating(),
          const SizedBox(height: 24),
          _buildCommentField(),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print('⭐ [PERSONAL_EVAL] GestureDetector onTap - starIndex: $starIndex');
                _onStarTapped(starIndex);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.star,
                  size: 48,
                  color: starIndex <= _selectedRating
                      ? AppColors.primaryOrange
                      : const Color(0xFFE0E0E0),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ruim',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: Color(0xFF2D3748),
                height: 1.3,
              ),
            ),
            Text(
              'Excelente',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: Color(0xFF2D3748),
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Comentário (opcional)',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 16,
                color: Color(0xFF42464D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF42464D), width: 1),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Conte como foi sua experiência...',
              hintStyle: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: Color(0xFF42464D),
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
              color: Color(0xFF42464D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botão "Recontratar personal" removido temporariamente
        // SizedBox(
        //   width: double.infinity,
        //   child: ElevatedButton(
        //     onPressed: _isLoading ? null : _onRecontractPersonal,
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: AppColors.primaryOrange,
        //       foregroundColor: Colors.white,
        //       padding: const EdgeInsets.all(16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //       elevation: 0,
        //     ),
        //     child: _isLoading
        //         ? const SizedBox(
        //             height: 20,
        //             width: 20,
        //             child: CircularProgressIndicator(
        //               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        //               strokeWidth: 2,
        //             ),
        //           )
        //         : const Text(
        //             'Recontratar personal',
        //             style: TextStyle(
        //               fontFamily: 'Outfit',
        //               fontSize: 20,
        //               fontWeight: FontWeight.w600,
        //               color: AppColors.white,
        //             ),
        //           ),
        //   ),
        // ),
        // const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _onSendEvaluation,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: AppColors.primaryOrange, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Enviar',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryOrange,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
