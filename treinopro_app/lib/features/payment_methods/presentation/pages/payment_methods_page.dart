import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_methods_bloc.dart';
import '../bloc/payment_methods_event.dart';
import '../bloc/payment_methods_state.dart';
import '../widgets/payment_method_card.dart';
import '../widgets/add_payment_method_bottom_sheet.dart';
import '../widgets/saved_cards_list.dart';

class PaymentMethodsPage extends StatefulWidget {
  final bool fromStep3;

  const PaymentMethodsPage({super.key, this.fromStep3 = false});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentMethodsBloc>().add(const LoadPaymentMethods());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      appBar: const CustomAppBar(
        title: 'Métodos de Pagamento',
        showBackButton: true,
      ),
      body: BlocConsumer<PaymentMethodsBloc, PaymentMethodsState>(
        listenWhen: (previous, current) {
          // Passar para o listener apenas eventos relevantes:
          // - Erro explícito
          if (current is PaymentMethodsError) return true;
          // - Estado carregado com erro
          if (current is PaymentMethodsLoaded && current.error != null)
            return true;
          // - Transição de isUpdating true -> false (operação concluída com sucesso)
          if (previous is PaymentMethodsLoaded && previous.isUpdating) {
            if (current is PaymentMethodsLoaded &&
                !current.isUpdating &&
                current.error == null) {
              return true;
            }
          }
          return false;
        },
        listener: (context, state) {
          if (state is PaymentMethodsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PaymentMethodsLoaded && state.error != null) {
            // Mostrar mensagem amigável ao usuário; logar o erro técnico para debugging
            debugPrint('PaymentMethods error (user-facing): ${state.error}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Não foi possível salvar o método de pagamento. Tente novamente mais tarde.',
                ),
                backgroundColor: Colors.red,
              ),
            );
            // Limpar erro após mostrar
            context.read<PaymentMethodsBloc>().add(const ClearErrors());
          } else if (state is PaymentMethodsLoaded &&
              !state.isUpdating &&
              state.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Método de pagamento salvo com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PaymentMethodsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
              ),
            );
          }

          if (state is PaymentMethodsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar métodos de pagamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<PaymentMethodsBloc>().add(
                        const LoadPaymentMethods(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (state is PaymentMethodsLoaded) {
            return _buildContent(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PaymentMethodsLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seção de métodos de pagamento disponíveis
          _buildSectionTitle('Adicionar Método de Pagamento'),
          const SizedBox(height: 16),

          // Cards de métodos de pagamento
          _buildPaymentMethodCards(context),

          const SizedBox(height: 32),

          // Seção de cartões salvos
          if (state.settings.savedCards.isNotEmpty) ...[
            _buildSectionTitle('Cartões Salvos'),
            const SizedBox(height: 16),
            SavedCardsList(
              cards: state.settings.savedCards,
              onRemoveCard: (cardId) {
                context.read<PaymentMethodsBloc>().add(RemoveCard(cardId));
              },
              onSetDefault: (cardId) {
                context.read<PaymentMethodsBloc>().add(SetDefaultCard(cardId));
              },
            ),
            const SizedBox(height: 32),
          ],

          // Seção de configurações - COMENTADO PARA USO FUTURO
          // _buildSectionTitle('Configurações'),
          // const SizedBox(height: 16),
          // _buildSettingsCard(context, state),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A202C),
      ),
    );
  }

  Widget _buildPaymentMethodCards(BuildContext context) {
    return Column(
      children: [
        // Cartão de Crédito
        PaymentMethodCard(
          title: 'Cartão de Crédito',
          subtitle: 'Visa, Mastercard, Elo, etc.',
          icon: Icons.credit_card,
          color: const Color(0xFF4F46E5),
          onTap: () => _showAddCardBottomSheet(context, CardType.credit),
        ),

        const SizedBox(height: 12),

        // Cartão de Débito
        PaymentMethodCard(
          title: 'Cartão de Débito',
          subtitle: 'Visa, Mastercard, Elo, etc.',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF059669),
          onTap: () => _showAddCardBottomSheet(context, CardType.debit),
        ),

        const SizedBox(height: 12),

        // PIX - sempre disponível, sem necessidade de cadastro
        _buildPixInfoCard(),

        const SizedBox(height: 12),

        // Mercado Pago — fluxo OAuth
        PaymentMethodCard(
          title: 'Mercado Pago',
          subtitle: 'Conectar conta via Mercado Pago',
          icon: Icons.payment,
          color: const Color(0xFF00AEEF),
          onTap: _startMercadoPagoOAuth,
        ),
      ],
    );
  }

  Widget _buildPixInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF32BCAD).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF32BCAD).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF32BCAD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.qr_code, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIX',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Sempre disponível — basta escolher na hora de criar a proposta',
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 12,
                    color: Color(0xFF4A5568),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF32BCAD), size: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, PaymentMethodsLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Método preferido
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Método Preferido',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                _getPaymentMethodName(state.settings.preferredMethod),
                style: const TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 14,
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pagamento automático
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pagamento Automático',
                style: TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
              Switch(
                value: state.settings.enableAutoPayment,
                onChanged: (value) {
                  context.read<PaymentMethodsBloc>().add(
                    UpdatePaymentSettings(
                      preferredMethod: state.settings.preferredMethod,
                      enableAutoPayment: value,
                    ),
                  );
                },
                activeColor: AppColors.primaryOrange,
              ),
            ],
          ),

          if (state.settings.mpEmail != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conta Mercado Pago',
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      state.settings.mpIsVerified
                          ? Icons.verified
                          : Icons.pending,
                      size: 16,
                      color: state.settings.mpIsVerified
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      state.settings.mpEmail!,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 14,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getPaymentMethodName(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'Cartão de Crédito';
      case PaymentMethodType.debitCard:
        return 'Cartão de Débito';
      case PaymentMethodType.mercadoPago:
        return 'Mercado Pago';
      case PaymentMethodType.pix:
        return 'PIX';
    }
  }

  void _showAddCardBottomSheet(BuildContext context, CardType cardType) {
    final bloc = context.read<PaymentMethodsBloc>();
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: AddPaymentMethodBottomSheet(
          cardType: cardType,
          bloc: bloc,
          fromStep3: widget.fromStep3,
          onCardSaved: () {
            bloc.add(const LoadPaymentMethods());
          },
        ),
      ),
    );
  }

  Future<void> _startMercadoPagoOAuth() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Abrindo Mercado Pago...'),
          duration: Duration(seconds: 2),
        ),
      );

      final apiService = GetIt.instance<ApiService>();
      final response = await apiService.dio.get(
        '/payments/mercadopago/oauth/start',
      );
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Não foi possível iniciar conexão com o Mercado Pago. Tente novamente.',
        );
      }

      if (data['success'] == true) {
        final authUrl = data['data']?['authUrl']?.toString() ?? '';
        if (authUrl.isEmpty) {
          throw Exception('URL de autorização não recebida. Tente novamente.');
        }
        final uri = Uri.tryParse(authUrl);
        if (uri == null || !uri.hasScheme) {
          throw Exception('URL de autorização inválida. Tente novamente.');
        }

        var launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
        if (!launched) {
          throw Exception(
            'Não foi possível abrir o navegador. Verifique se há um navegador instalado.',
          );
        }
      } else {
        final backendMessage = data['message']?.toString().trim();
        throw Exception(
          backendMessage != null && backendMessage.isNotEmpty
              ? backendMessage
              : 'Não foi possível iniciar conexão com o Mercado Pago. Tente novamente.',
        );
      }
    } on DioException catch (e) {
      final message = _extractDioMessage(
        e,
        fallback:
            'Não foi possível iniciar conexão com o Mercado Pago. Tente novamente.',
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  String _extractDioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    final message = e.message;
    if (message != null && message.trim().isNotEmpty) {
      return message.trim();
    }

    return fallback;
  }
}
