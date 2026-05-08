import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../service_locator.dart';
import '../../data/models/financial_profile_model.dart';
import '../../data/services/payout_methods_api_service.dart';
import '../services/stripe_connect_onboarding_service.dart';

enum PayoutMethodType { stripeConnect }

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
  late final StripeConnectOnboardingService _stripeConnectOnboardingService;
  late final PayoutMethodType _selected;

  StripeConnectAccountModel? _stripeAccount;
  bool _isLoadingStatus = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialType ?? PayoutMethodType.stripeConnect;
    _payoutApi = sl<PayoutMethodsApiService>();
    _stripeConnectOnboardingService = sl<StripeConnectOnboardingService>();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    try {
      final profile = await _payoutApi.getFinancialProfile();
      if (!mounted) return;
      setState(() {
        _stripeAccount = profile.stripeAccount;
        _isLoadingStatus = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar o status atual.';
        _isLoadingStatus = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoadingStatus = true;
      _error = null;
    });
    try {
      await _payoutApi.ensureStripeConnectedAccount();
    } catch (_) {
      // Ainda tenta carregar o último status persistido se a sincronização falhar.
    }
    await _loadExistingData();
    widget.onSaved();
  }

  Future<void> _startStripeOnboarding() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _payoutApi.ensureStripeConnectedAccount();
      await _stripeConnectOnboardingService.presentEmbeddedOnboarding();
      await _refreshStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configuração financeira encerrada. Atualizamos seu status no app.',
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
              'Não foi possível iniciar o onboarding de recebimento. Tente novamente.',
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
      case PayoutMethodType.stripeConnect:
        return _buildStripeConnectForm();
    }
  }

  Widget _buildStripeConnectForm() {
    final stripeAccount = _stripeAccount;
    final outstandingRequirements =
        stripeAccount?.outstandingRequirements ?? [];
    final isReady = stripeAccount?.isReadyForPayout ?? false;
    final hasAccount = stripeAccount?.accountId.isNotEmpty == true;
    final shouldOpenOnboarding =
        !hasAccount ||
        isReady ||
        (stripeAccount?.hasPendingRequirements ?? false);
    final showSecondaryRefresh = shouldOpenOnboarding;

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
                  _buildText('Recebimento pelo TreinoPro'),
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
                      'A plataforma cria sua conta conectada automaticamente. Depois disso, você só completa o onboarding embutido para cadastrar sua conta bancária e enviar os dados pendentes.',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingStatus)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isReady
                            ? const Color(0xFFECFDF3)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isReady
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFFCD34D),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isReady
                                    ? Icons.check_circle_outline
                                    : Icons.pending_outlined,
                                size: 18,
                                color: isReady
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB45309),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  stripeAccount?.statusTitle ??
                                      'Recebimento não iniciado',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isReady
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            stripeAccount?.statusDescription ??
                                'Inicie o onboarding quando quiser liberar saques.',
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 13,
                              color: isReady
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF92400E),
                            ),
                          ),
                          if (outstandingRequirements.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Itens pendentes',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...outstandingRequirements
                                .take(4)
                                .map(
                                  (requirement) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• $requirement',
                                      style: const TextStyle(
                                        fontFamily: 'Fira Sans',
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
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
              onPressed: _submitting
                  ? null
                  : shouldOpenOnboarding
                  ? _startStripeOnboarding
                  : _refreshStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
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
                      stripeAccount?.actionLabel ?? 'Começar configuração',
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          if (showSecondaryRefresh) ...[
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
      case PayoutMethodType.stripeConnect:
        return 'Configurar recebimento';
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
