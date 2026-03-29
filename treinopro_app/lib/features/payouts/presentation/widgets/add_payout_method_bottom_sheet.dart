import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../service_locator.dart';
import '../../data/models/payout_methods_model.dart';
import '../../data/services/payout_methods_api_service.dart';

enum PayoutMethodType { mercadoPago }

class AddPayoutMethodBottomSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final PayoutMethodType? initialType;

  const AddPayoutMethodBottomSheet({
    super.key,
    required this.onSaved,
    this.initialType,
  });

  @override
  State<AddPayoutMethodBottomSheet> createState() =>
      _AddPayoutMethodBottomSheetState();
}

class _AddPayoutMethodBottomSheetState
    extends State<AddPayoutMethodBottomSheet> {
  late final PayoutMethodsApiService _payoutApi;
  late final PayoutMethodType _selected;

  MercadoPagoModel? _existingMercadoPago;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialType ?? PayoutMethodType.mercadoPago;
    _payoutApi = sl<PayoutMethodsApiService>();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final data = await _payoutApi.getPayoutMethods();
      final payoutMethods = PayoutMethodsModel.fromJson(data);
      if (!mounted) return;
      setState(() {
        _existingMercadoPago = payoutMethods.mercadoPago;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar o status atual.';
      });
    }
  }

  Future<void> _refreshStatus() async {
    await _loadExistingData();
    widget.onSaved();
  }

  Future<void> _startMercadoPagoOAuth() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final apiService = sl<ApiService>();
      final response = await apiService.dio.get(
        '/payments/mercadopago/oauth/start',
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception(
          'Não foi possível iniciar conexão com o Mercado Pago. Tente novamente.',
        );
      }

      final success = data['success'] == true;
      final authUrl = data['data']?['authUrl']?.toString();

      if (!success || authUrl == null || authUrl.isEmpty) {
        final backendMessage = data['message']?.toString().trim();
        throw Exception(
          backendMessage != null && backendMessage.isNotEmpty
              ? backendMessage
              : 'Não foi possível iniciar a conexão OAuth.',
        );
      }

      final uri = Uri.tryParse(authUrl);
      if (uri == null || !uri.hasScheme) {
        throw Exception('URL de autorização inválida. Tente novamente.');
      }

      var launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!launched) {
        throw Exception(
          'Não foi possível abrir o navegador. Verifique se há um navegador instalado.',
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Navegador aberto. Após autorizar, volte ao app e toque em "Atualizar status".',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractDioMessage(
          e,
          fallback:
              'Não foi possível iniciar conexão com o Mercado Pago. Tente novamente.',
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildFormPage(_selected)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Color(0xFF1A202C)),
          ),
          Expanded(
            child: Text(
              _getTitle(_selected),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildFormPage(PayoutMethodType type) {
    switch (type) {
      case PayoutMethodType.mercadoPago:
        return _buildMercadoPagoOAuthForm();
    }
  }

  Widget _buildMercadoPagoOAuthForm() {
    final isConnected =
        _existingMercadoPago != null && _existingMercadoPago!.email.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildText('Mercado Pago'),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Conecte sua conta pelo OAuth do Mercado Pago. Não é necessário informar CPF/CNPJ manualmente nesta etapa.',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isConnected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Color(0xFF047857),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Conta conectada: ${_existingMercadoPago!.maskedEmail}',
                              style: const TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 13,
                                color: Color(0xFF065F46),
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
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontFamily: 'Fira Sans',
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _startMercadoPagoOAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: const Color(0xFF2D3748),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isConnected
                          ? 'Reconectar com Mercado Pago'
                          : 'Conectar com Mercado Pago',
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _submitting ? null : _refreshStatus,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Atualizar status',
                style: TextStyle(fontFamily: 'Fira Sans', fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A202C),
      ),
    );
  }

  String _getTitle(PayoutMethodType type) {
    switch (type) {
      case PayoutMethodType.mercadoPago:
        return 'Conectar Mercado Pago';
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
