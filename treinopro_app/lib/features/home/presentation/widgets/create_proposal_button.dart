import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../proposals/proposals.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../../../../core/constants/app_colors.dart';

/// Widget do botão "Criar proposta"
class CreateProposalButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CreateProposalButton({super.key, this.onTap});

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      // Navegar para a tela de criar proposta
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MultiProvider(
            providers: [
              Provider<SaveProposal>.value(
                value: GetIt.instance<SaveProposal>(),
              ),
              Provider<GetProposal>.value(value: GetIt.instance<GetProposal>()),
              Provider<SearchLocations>.value(
                value: GetIt.instance<SearchLocations>(),
              ),
              Provider<GetModalities>.value(
                value: GetIt.instance<GetModalities>(),
              ),
              Provider<SubmitProposal>.value(
                value: GetIt.instance<SubmitProposal>(),
              ),
              Provider<CreateProposal>.value(
                value: GetIt.instance<CreateProposal>(),
              ),
              Provider<ProposalsRepository>.value(
                value: GetIt.instance<ProposalsRepository>(),
              ),
            ],
            child: const CreateProposalPage(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeBlocState>(
      builder: (context, state) {
        // Verifica se está em busca ativa (deve bloquear o botão)
        bool isSearchingActive = false;
        if (state is HomeLoaded) {
          isSearchingActive = state.homeState.isSearchingActive;
        }

        return Container(
          width: double.infinity,
          height: 56, // Altura fixa 56px
          decoration: BoxDecoration(
            color: isSearchingActive
                ? const Color(0xFFBDBDBD) // Cinza quando desabilitado
                : AppColors.primaryOrange, // Laranja principal quando ativo
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSearchingActive
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSearchingActive ? null : () => _handleTap(context),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Texto do botão
                    Text(
                      isSearchingActive
                          ? 'Buscando profissional...'
                          : 'Criar proposta de treino',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSearchingActive
                            ? const Color(
                                0xFF757575,
                              ) // Texto cinza quando desabilitado
                            : Colors.white, // Texto branco quando ativo
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Ícone do botão
                    if (isSearchingActive)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF757575), // Loading cinza
                          ),
                        ),
                      )
                    else
                      Icon(Icons.edit, size: 20, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
