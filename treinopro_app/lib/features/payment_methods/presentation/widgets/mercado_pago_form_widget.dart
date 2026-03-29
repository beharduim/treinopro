import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_methods_bloc.dart';
import '../bloc/payment_methods_event.dart';
import '../bloc/payment_methods_state.dart';

class MercadoPagoFormWidget extends StatefulWidget {
  final VoidCallback onMercadoPagoConfigured;

  const MercadoPagoFormWidget({
    super.key,
    required this.onMercadoPagoConfigured,
  });

  @override
  State<MercadoPagoFormWidget> createState() => _MercadoPagoFormWidgetState();
}

class _MercadoPagoFormWidgetState extends State<MercadoPagoFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isValidating = false;
  bool _isValidEmail = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
      listener: (context, state) {
        if (state is MercadoPagoValidationState) {
          setState(() {
            _isValidating = false;
            _isValidEmail = state.isValid;
          });
          
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (state is PaymentMethodsLoaded && !state.isUpdating) {
          _isLoading = false;
          if (mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            widget.onMercadoPagoConfigured();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mercado Pago configurado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (state is PaymentMethodsLoaded && state.error != null) {
          _isLoading = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Informações sobre Mercado Pago
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00AEEF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00AEEF).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF00AEEF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Conecte sua conta do Mercado Pago para pagamentos mais rápidos e seguros.',
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 14,
                        color: Color(0xFF00AEEF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Campo de email
            Text(
              'Email da Conta Mercado Pago',
              style: const TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'seu@email.com',
                hintStyle: const TextStyle(
                  fontFamily: 'Fira Sans',
                  color: Color(0xFFA0AEC0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryOrange),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _isValidating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
                          ),
                        ),
                      )
                    : _isValidEmail
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                        : null,
              ),
              validator: _validateEmail,
              onChanged: _onEmailChanged,
            ),
            
            const SizedBox(height: 16),
            
            // Status da validação
            if (_isValidEmail) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Conta do Mercado Pago verificada com sucesso!',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Vantagens do Mercado Pago
            Text(
              'Vantagens do Mercado Pago',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A202C),
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildAdvantageItem(
              icon: Icons.credit_card,
              title: 'Múltiplas Formas de Pagamento',
              description: 'Cartão, PIX, boleto e mais',
            ),
            
            const SizedBox(height: 12),
            
            _buildAdvantageItem(
              icon: Icons.security,
              title: 'Segurança Garantida',
              description: 'Proteção contra fraudes',
            ),
            
            const SizedBox(height: 12),
            
            _buildAdvantageItem(
              icon: Icons.speed,
              title: 'Pagamento Rápido',
              description: 'Checkout em segundos',
            ),
            
            const SizedBox(height: 12),
            
            _buildAdvantageItem(
              icon: Icons.receipt,
              title: 'Histórico Completo',
              description: 'Acompanhe todos os pagamentos',
            ),
            
            const SizedBox(height: 32),
            
            // Botão configurar Mercado Pago
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_isValidEmail ? null : _configureMercadoPago,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Configurar Mercado Pago',
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAdvantageItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF00AEEF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00AEEF),
            size: 20,
          ),
        ),
        
        const SizedBox(width: 16),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }

  Timer? _debounce;

  void _onEmailChanged(String value) {
    _debounce?.cancel();
    if (value.isNotEmpty && _validateEmail(value) == null) {
      setState(() {
        _isValidating = true;
        _isValidEmail = false;
      });
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        context.read<PaymentMethodsBloc>().add(
          ValidateMercadoPagoAccount(value),
        );
      });
    } else {
      setState(() {
        _isValidEmail = false;
        _isValidating = false;
      });
    }
  }

  void _configureMercadoPago() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Atualizar método preferido para Mercado Pago
    context.read<PaymentMethodsBloc>().add(
      UpdatePaymentSettings(
        preferredMethod: PaymentMethodType.mercadoPago,
        mpEmail: _emailController.text.trim(),
        mpAllowSaveCard: true,
      ),
    );
  }
}
