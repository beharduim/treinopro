import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_method.dart';
import '../bloc/payment_methods_bloc.dart';
import '../bloc/payment_methods_event.dart';
import '../bloc/payment_methods_state.dart';

class PixFormWidget extends StatefulWidget {
  final VoidCallback onPixConfigured;

  const PixFormWidget({
    super.key,
    required this.onPixConfigured,
  });

  @override
  State<PixFormWidget> createState() => _PixFormWidgetState();
}

class _PixFormWidgetState extends State<PixFormWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentMethodsBloc, PaymentMethodsState>(
      listener: (context, state) {
        if (state is PaymentMethodsLoaded && !state.isUpdating) {
          _isLoading = false;
          if (mounted) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            widget.onPixConfigured();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('PIX configurado com sucesso!'),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Informações sobre PIX
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'O PIX será processado automaticamente quando você fizer um pagamento. Não é necessário configurar dados adicionais.',
                    style: const TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 14,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Vantagens do PIX
          Text(
            'Vantagens do PIX',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A202C),
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildAdvantageItem(
            icon: Icons.flash_on,
            title: 'Pagamento Instantâneo',
            description: 'Confirmação imediata do pagamento',
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvantageItem(
            icon: Icons.security,
            title: 'Seguro e Confiável',
            description: 'Tecnologia do Banco Central do Brasil',
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvantageItem(
            icon: Icons.savings,
            title: 'Sem Taxas',
            description: 'Sem custos adicionais para você',
          ),
          
          const SizedBox(height: 12),
          
          _buildAdvantageItem(
            icon: Icons.speed,
            title: 'Rápido e Prático',
            description: 'Apenas alguns cliques para pagar',
          ),
          
          const SizedBox(height: 32),
          
          // Botão configurar PIX
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _configurePix,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
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
                        Icon(Icons.qr_code, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Configurar PIX',
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
            color: const Color(0xFF7C3AED).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF7C3AED),
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

  void _configurePix() {
    setState(() {
      _isLoading = true;
    });
    
    // Atualizar método preferido para PIX
    context.read<PaymentMethodsBloc>().add(
      UpdatePreferredMethod(PaymentMethodType.pix),
    );
  }
}
