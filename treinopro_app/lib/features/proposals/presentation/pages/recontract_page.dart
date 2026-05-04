import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../data/services/proposals_api_service.dart';
import '../widgets/location_search_field.dart';
import '../widgets/visual_date_picker.dart';
import '../widgets/time_slot_selector.dart';
import '../widgets/payment_method_selector.dart';
import '../../domain/entities/training_location.dart';
import '../bloc/proposals_bloc.dart';
import '../bloc/proposals_event.dart';
import '../bloc/proposals_state.dart';
import '../../../payment_methods/presentation/pages/payment_methods_page.dart';
import '../../../payment_methods/presentation/bloc/payment_methods_bloc.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';

/// Tela de recontratação para o cliente
class RecontractPage extends StatefulWidget {
  final String? personalId;
  final String? personalName;
  final String? personalEmail;
  final String? personalProfileImageUrl;
  final String? personalRating;
  final String? personalTimeOnPlatform;

  const RecontractPage({
    super.key,
    this.personalId,
    this.personalName,
    this.personalEmail,
    this.personalProfileImageUrl,
    this.personalRating,
    this.personalTimeOnPlatform,
  });

  @override
  State<RecontractPage> createState() => _RecontractPageState();
}

class _RecontractPageState extends State<RecontractPage> {
  DateTime? _selectedDate;
  String? _selectedTime;
  TrainingLocation? _selectedLocation;

  final TextEditingController _valueController = TextEditingController();
  final ProposalsApiService _proposalsApiService = sl<ProposalsApiService>();

  @override
  void initState() {
    super.initState();
    // Inicializar com valor padrão
    _valueController.text = '40,00';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<ProposalsBloc>();
      final currentState = bloc.state;
      if (currentState is ProposalsLoaded &&
          !currentState.isLoadingPaymentMethods &&
          currentState.availablePaymentMethods.isEmpty) {
        bloc.add(const ProposalsLoadPaymentMethods());
      }
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar com botão de voltar e título
              _buildTopBar(),

              const SizedBox(height: 24),

              // Card do profissional selecionado
              _buildProfessionalCard(),

              const SizedBox(height: 24),

              // Formulário de recontratação
              _buildRecontractForm(),

              const SizedBox(height: 24),

              // Botão de confirmar
              _buildConfirmButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F3F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_left,
              size: 16,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Recontratação',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/student-home', (route) => false);
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F3F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_rounded,
              size: 15,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF42464D).withOpacity(0.24),
          width: 0.24,
        ),
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
          // Título do card
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 16, color: Colors.white),
              ),
              const Text(
                'Profissional selecionado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Informações do profissional
          Row(
            children: [
              // Avatar do profissional
              Container(
                width: 47,
                height: 47,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF3F3F3),
                ),
                child:
                    widget.personalProfileImageUrl != null &&
                        widget.personalProfileImageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(23.5),
                        child: Image.network(
                          widget.personalProfileImageUrl!,
                          width: 47,
                          height: 47,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.person,
                                size: 24,
                                color: Color(0xFF42464D),
                              ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 24,
                        color: Color(0xFF42464D),
                      ),
              ),

              const SizedBox(width: 12),

              // Informações do profissional
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.personalName ?? 'Personal Trainer',
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Avaliação
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (widget.personalRating != null &&
                                      widget.personalRating!.isNotEmpty)
                                  ? widget.personalRating!
                                  : '5,0',
                              style: const TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 16,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          (widget.personalTimeOnPlatform != null &&
                                  widget.personalTimeOnPlatform!.isNotEmpty)
                              ? widget.personalTimeOnPlatform!
                              : '0 dias',
                          style: const TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecontractForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo de academia
          _buildLocationField(),

          const SizedBox(height: 24),

          // Campo de data
          _buildDateField(),

          const SizedBox(height: 24),

          // Campo de horário
          _buildTimeField(),

          const SizedBox(height: 24),

          // Campo de valor
          _buildValueField(),

          const SizedBox(height: 24),

          // Campo de forma de pagamento
          _buildPaymentMethodField(),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return BlocBuilder<ProposalsBloc, ProposalsState>(
      builder: (context, state) {
        if (state is! ProposalsLoaded) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção (igual ao step1)
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Qual academia? *',
                        style: AppTextStyles.paragraph.copyWith(
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Academia, parque ou sua casa',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.secondaryDark.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Campo de busca (igual ao step1)
            LocationSearchField(
              initialValue: _selectedLocation?.name,
              suggestions: state.searchedLocations,
              isLoading: state.isLoadingLocations,
              placeholder: 'Pesquise academia ou local que deseja',
              onSearchChanged: (query) {
                context.read<ProposalsBloc>().add(
                  ProposalsSearchLocations(query),
                );
              },
              onLocationSelected: (location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com ícone
        Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 24,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(width: 8),
            const Text(
              'Escolha a data do treino',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 16,
                color: Color(0xFF42464D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Campo de data
        VisualDatePicker(
          selectedDate: _selectedDate,
          onDateSelected: _onDateSelected,
          minDate: DateTime.now(),
          maxDate: DateTime.now().add(const Duration(days: 30)),
          placeholder: 'Selecione uma data',
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com ícone
        Row(
          children: [
            const Icon(
              Icons.access_time,
              size: 24,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(width: 8),
            const Text(
              'Escolha um horário',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 16,
                color: Color(0xFF42464D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Campo de horário
        TimeSlotSelector(
          initialValue: _selectedTime,
          onTimeChanged: _onTimeChanged,
          selectedDate: _selectedDate,
          apiService: _proposalsApiService,
        ),
      ],
    );
  }

  Widget _buildValueField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label com ícone
        Row(
          children: [
            const Icon(
              Icons.attach_money,
              size: 24,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(width: 8),
            const Text(
              'Valor da aula',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 16,
                color: Color(0xFF42464D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Campo de valor
        TextFormField(
          controller: _valueController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (value) {
            // Validar em tempo real
            final doubleValue = double.tryParse(value.replaceAll(',', '.'));
            if (doubleValue != null && doubleValue < 40.0) {
              // Mostrar erro visual
              setState(() {});
            }
          },
          decoration: InputDecoration(
            hintText: 'Digite o valor que deseja pagar (mínimo R\$ 40,00)',
            hintStyle: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFF42464D),
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(
                color: AppColors.secondaryDark,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: _isValidValue() ? AppColors.secondaryDark : Colors.red,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: _isValidValue() ? AppColors.primaryOrange : Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 22,
            ),
            suffixText: 'R\$',
            suffixStyle: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFF42464D),
              fontWeight: FontWeight.w600,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite um valor';
            }
            final doubleValue = double.tryParse(value.replaceAll(',', '.'));
            if (doubleValue == null) {
              return 'Por favor, digite um valor válido';
            }
            if (doubleValue < 40.0) {
              return 'O valor mínimo é R\$ 40,00';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return BlocBuilder<ProposalsBloc, ProposalsState>(
      builder: (context, state) {
        if (state is! ProposalsLoaded) {
          return const SizedBox.shrink();
        }
        final canConfirm =
            _selectedLocation != null &&
            _selectedDate != null &&
            _selectedTime != null &&
            _valueController.text.isNotEmpty &&
            _isValidValue() &&
            state.proposal.paymentMethodId != null;

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              print('🔥 BOTÃO CONFIRMAR PRESSIONADO');
              print('📊 Estado dos campos:');
              print('   - Local: ${_selectedLocation?.name}');
              print('   - Data: $_selectedDate');
              print('   - Horário: $_selectedTime');
              print('   - Valor: ${_valueController.text}');
              print(
                '   - Método de pagamento: ${state.proposal.paymentMethodId}',
              );
              print('   - canConfirm: $canConfirm');

              if (canConfirm) {
                _confirmRecontract();
              } else {
                print('❌ Formulário incompleto - botão desabilitado');
                final missingFields = _getMissingFields(state);
                final missingFieldsText = missingFields.isEmpty
                    ? 'Revise os dados e tente novamente.'
                    : 'Campos pendentes: ${missingFields.join(', ')}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(missingFieldsText),
                    backgroundColor: Color(0xFFB45309),
                  ),
                );
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                (states) => AppColors.primaryOrange,
              ),
              foregroundColor: MaterialStateProperty.all(
                const Color(0xFF2D3748),
              ),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(vertical: 16),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              elevation: MaterialStateProperty.all(0),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: AppColors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isValidValue() {
    final value = double.tryParse(_valueController.text.replaceAll(',', '.'));
    return value != null && value >= 40.0;
  }

  List<String> _getMissingFields(ProposalsLoaded state) {
    final missingFields = <String>[];

    if (_selectedLocation == null) {
      missingFields.add('academia/local');
    }
    if (_selectedDate == null) {
      missingFields.add('data');
    }
    if (_selectedTime == null || _selectedTime!.trim().isEmpty) {
      missingFields.add('horário');
    }
    if (_valueController.text.trim().isEmpty) {
      missingFields.add('valor');
    } else if (!_isValidValue()) {
      missingFields.add('valor (mínimo R\$ 40,00)');
    }
    if (state.proposal.paymentMethodId == null) {
      missingFields.add('forma de pagamento');
    }

    return missingFields;
  }

  Widget _buildPaymentMethodField() {
    return BlocBuilder<ProposalsBloc, ProposalsState>(
      builder: (context, state) {
        if (state is! ProposalsLoaded) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seletor de métodos de pagamento
            PaymentMethodSelector(
              availableMethods: state.availablePaymentMethods,
              selectedMethodId: state.proposal.paymentMethodId,
              isLoading: state.isLoadingPaymentMethods,
              onMethodSelected: (methodId, methodName) {
                context.read<ProposalsBloc>().add(
                  ProposalsUpdatePaymentMethod(methodId, methodName),
                );
              },
            ),

            const SizedBox(height: 16),

            // Botão para adicionar nova forma de pagamento
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToPaymentMethods(context),
                icon: const Icon(
                  Icons.add,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                label: Text(
                  'Adicionar Forma de Pagamento',
                  style: AppTextStyles.paragraph.copyWith(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppColors.primaryOrange,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToPaymentMethods(BuildContext context) async {
    final proposalsBloc = context.read<ProposalsBloc>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider(
          create: (context) => sl<PaymentMethodsBloc>(),
          child: const PaymentMethodsPage(fromStep3: true),
        ),
      ),
    );

    if (!mounted) return;
    proposalsBloc.add(const ProposalsLoadPaymentMethods());
  } // Métodos de callback para os novos campos

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      // Limpar horário quando a data muda para recarregar conflitos
      _selectedTime = null;
    });
  }

  void _onTimeChanged(String time) {
    setState(() {
      _selectedTime = time;
    });
  }

  /// Verifica se uma string é um UUID válido
  bool _isValidUUID(String id) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(id);
  }

  PaymentMethod? _findSelectedPaymentMethod(ProposalsLoaded state) {
    final selectedMethodId = state.proposal.paymentMethodId;
    if (selectedMethodId == null || selectedMethodId.isEmpty) {
      return null;
    }

    for (final method in state.availablePaymentMethods) {
      if (method.id == selectedMethodId) {
        return method;
      }
    }

    final selectedPaymentMethod = state.proposal.selectedPaymentMethod;
    if (selectedPaymentMethod is PaymentMethod) {
      return selectedPaymentMethod;
    }

    return null;
  }

  String _mapPaymentMethodForApi(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'credit_card';
      case PaymentMethodType.debitCard:
        return 'debit_card';
      case PaymentMethodType.pix:
        return 'pix';
    }
  }

  Map<String, String?> _resolvePaymentDataForApi(ProposalsLoaded state) {
    final selectedMethod = _findSelectedPaymentMethod(state);
    final selectedMethodId = state.proposal.paymentMethodId;

    String paymentMethod = 'credit_card';
    String? cardId;

    if (selectedMethod != null) {
      paymentMethod = _mapPaymentMethodForApi(selectedMethod.type);
      if (_isValidUUID(selectedMethod.id)) {
        cardId = selectedMethod.id;
      }
    } else if (selectedMethodId != null) {
      switch (selectedMethodId) {
        case 'stripe_payment_sheet':
          paymentMethod = 'credit_card';
          break;
        case 'credit_card':
        case 'debit_card':
        case 'pix':
          paymentMethod = selectedMethodId;
          break;
        default:
          paymentMethod = 'credit_card';
          if (_isValidUUID(selectedMethodId)) {
            cardId = selectedMethodId;
          }
      }
    }

    return {'paymentMethod': paymentMethod, 'cardId': cardId};
  }

  Future<void> _confirmRecontract() async {
    if (widget.personalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Personal trainer não identificado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentState = context.read<ProposalsBloc>().state;
    if (currentState is! ProposalsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: formulário de recontratação não está pronto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentData = _resolvePaymentDataForApi(currentState);
    final paymentMethod = paymentData['paymentMethod'] ?? 'credit_card';
    final cardId = paymentData['cardId'];
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final appNavigator = Navigator.of(context);

    var loadingShown = false;
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
        ),
      );
      loadingShown = true;

      // Mesclar data + hora para evitar validação de "passado" (meia-noite)
      final timeParts = (_selectedTime ?? '00:00').split(':');
      final mergedDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        int.tryParse(timeParts[0]) ?? 0,
        int.tryParse(timeParts[1]) ?? 0,
      );

      final proposalData = <String, dynamic>{
        'locationName': _selectedLocation?.name ?? '',
        'locationAddress': _selectedLocation?.address ?? '',
        // Enviar a data já com horário embutido
        'trainingDate': mergedDateTime.toIso8601String(),
        // Mantém o campo textual para compatibilidade e exibição
        'trainingTime': _selectedTime!,
        'durationMinutes': 60, // Duração padrão
        'modalityName': 'Musculação', // Modalidade padrão
        'price': double.parse(_valueController.text.replaceAll(',', '.')),
        'additionalNotes': 'Recontratação direta',
        'paymentMethod': paymentMethod,
        'personalId': widget.personalId, // Personal específico
      };

      if (cardId != null) {
        proposalData['cardId'] = cardId;
      }

      // Só adicionar locationId se for um UUID válido
      if (_selectedLocation?.id != null &&
          _isValidUUID(_selectedLocation!.id)) {
        proposalData['locationId'] = _selectedLocation!.id;
      }

      print('🚀 [RECONTRACT] Criando proposta direta:');
      print('   - Personal ID: ${widget.personalId}');
      print('   - Local: ${_selectedLocation?.name}');
      print('   - Data (merge): ${mergedDateTime.toIso8601String()}');
      print('   - Horário (texto): $_selectedTime');
      print('   - Valor: ${_valueController.text}');
      print('   - Método de pagamento (API): $paymentMethod');
      print('   - CardId: ${cardId ?? 'n/a'}');

      // Chamar API de recontratação
      final response = await _proposalsApiService.createRecontract(
        proposalData,
      );

      print('✅ [RECONTRACT] Resposta da API: $response');

      // Fechar loading
      if (loadingShown && mounted) {
        rootNavigator.pop();
        loadingShown = false;
      }
      if (!mounted) return;

      final paymentStatus =
          (response.paymentStatus ?? response.payment?.status ?? '')
              .toLowerCase();
      final isPaymentConfirmed =
          paymentStatus == 'approved' ||
          paymentStatus == 'authorized' ||
          paymentStatus == 'captured';
      final isPaymentPending =
          paymentStatus == 'pending' || paymentStatus == 'in_process';

      if (isPaymentConfirmed) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Recontratação enviada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

        appNavigator.pushNamedAndRemoveUntil('/student-home', (route) => false);
        return;
      }

      if (isPaymentPending) {
        throw Exception(
          'Pagamento pendente. Finalize o pagamento para enviar a recontratação ao personal.',
        );
      }

      throw Exception(
        'Pagamento não confirmado (status: ${response.paymentStatus ?? 'desconhecido'})',
      );
    } catch (e) {
      // Fechar loading se estiver aberto
      if (loadingShown && mounted) {
        rootNavigator.pop();
      }
      if (!mounted) return;
      print('❌ [RECONTRACT] Erro ao criar recontratação: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar recontratação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
