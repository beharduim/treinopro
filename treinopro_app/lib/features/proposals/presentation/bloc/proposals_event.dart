import 'package:equatable/equatable.dart';
import '../../domain/entities/training_location.dart';
import '../../domain/entities/training_modality.dart';

/// Eventos do BLoC de propostas
abstract class ProposalsEvent extends Equatable {
  const ProposalsEvent();

  @override
  List<Object?> get props => [];
}

/// Inicializar o BLoC
class ProposalsInitialize extends ProposalsEvent {
  const ProposalsInitialize();
}

/// Carregar proposta salva
class ProposalsLoadSaved extends ProposalsEvent {
  const ProposalsLoadSaved();
}

/// Navegar para uma etapa específica
class ProposalsNavigateToStep extends ProposalsEvent {
  final int step;

  const ProposalsNavigateToStep(this.step);

  @override
  List<Object> get props => [step];
}

/// Atualizar local selecionado
class ProposalsUpdateLocation extends ProposalsEvent {
  final TrainingLocation location;

  const ProposalsUpdateLocation(this.location);

  @override
  List<Object> get props => [location];
}

/// Atualizar data do treino
class ProposalsUpdateDate extends ProposalsEvent {
  final DateTime date;

  const ProposalsUpdateDate(this.date);

  @override
  List<Object> get props => [date];
}

/// Atualizar modalidade selecionada
class ProposalsUpdateModality extends ProposalsEvent {
  final TrainingModality modality;

  const ProposalsUpdateModality(this.modality);

  @override
  List<Object> get props => [modality];
}

/// Atualizar horário do treino
class ProposalsUpdateTime extends ProposalsEvent {
  final String time;

  const ProposalsUpdateTime(this.time);

  @override
  List<Object> get props => [time];
}

/// Atualizar duração da aula
class ProposalsUpdateDuration extends ProposalsEvent {
  final int durationMinutes;

  const ProposalsUpdateDuration(this.durationMinutes);

  @override
  List<Object> get props => [durationMinutes];
}

/// Atualizar preço
class ProposalsUpdatePrice extends ProposalsEvent {
  final double price;

  const ProposalsUpdatePrice(this.price);

  @override
  List<Object> get props => [price];
}

/// Atualizar observações adicionais
class ProposalsUpdateNotes extends ProposalsEvent {
  final String notes;

  const ProposalsUpdateNotes(this.notes);

  @override
  List<Object> get props => [notes];
}

/// Atualizar método de pagamento selecionado
class ProposalsUpdatePaymentMethod extends ProposalsEvent {
  final String paymentMethodId;
  final String paymentMethodName;

  const ProposalsUpdatePaymentMethod(
    this.paymentMethodId,
    this.paymentMethodName,
  );

  @override
  List<Object> get props => [paymentMethodId, paymentMethodName];
}

/// Carregar métodos de pagamento do usuário
class ProposalsLoadPaymentMethods extends ProposalsEvent {
  const ProposalsLoadPaymentMethods();
}

/// Definir CVV temporário para cartão salvo
class ProposalsSetSavedCardCvv extends ProposalsEvent {
  final String cvv;

  const ProposalsSetSavedCardCvv(this.cvv);

  @override
  List<Object> get props => [cvv];
}

/// Buscar locais
class ProposalsSearchLocations extends ProposalsEvent {
  final String query;

  const ProposalsSearchLocations(this.query);

  @override
  List<Object> get props => [query];
}

/// Buscar locais com debounce (evento interno)
class ProposalsSearchLocationsDebounced extends ProposalsEvent {
  final String query;

  const ProposalsSearchLocationsDebounced(this.query);

  @override
  List<Object> get props => [query];
}

/// Carregar modalidades
class ProposalsLoadModalities extends ProposalsEvent {
  const ProposalsLoadModalities();
}

/// Carregar horários disponíveis
class ProposalsLoadAvailableTimes extends ProposalsEvent {
  final DateTime date;

  const ProposalsLoadAvailableTimes(this.date);

  @override
  List<Object> get props => [date];
}

/// Salvar proposta atual
class ProposalsSave extends ProposalsEvent {
  const ProposalsSave();
}

/// Submeter proposta finalizada
class ProposalsSubmit extends ProposalsEvent {
  const ProposalsSubmit();
}

/// Limpar proposta atual
class ProposalsClear extends ProposalsEvent {
  const ProposalsClear();
}

/// Ir para próxima etapa
class ProposalsNextStep extends ProposalsEvent {
  const ProposalsNextStep();
}

/// Voltar para etapa anterior
class ProposalsPreviousStep extends ProposalsEvent {
  const ProposalsPreviousStep();
}

// ===== EVENTOS PARA LISTAGEM DE PROPOSTAS (PERSONAL TRAINER) =====

/// Carregar propostas disponíveis para o personal trainer
class ProposalsLoadAvailable extends ProposalsEvent {
  final int page;
  final int limit;
  final String? status;
  final String? modality;
  final String? dateFrom;
  final String? dateTo;

  const ProposalsLoadAvailable({
    this.page = 1,
    this.limit = 50,
    this.status,
    this.modality,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [page, limit, status, modality, dateFrom, dateTo];
}

/// Atualizar filtros de propostas
class ProposalsUpdateFilters extends ProposalsEvent {
  final String? status;
  final String? modality;
  final String? dateFrom;
  final String? dateTo;

  const ProposalsUpdateFilters({
    this.status,
    this.modality,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props => [status, modality, dateFrom, dateTo];
}

/// Aceitar uma proposta
class ProposalsAcceptProposal extends ProposalsEvent {
  final String proposalId;

  const ProposalsAcceptProposal(this.proposalId);

  @override
  List<Object> get props => [proposalId];
}

/// Atualizar propostas via WebSocket
class ProposalsUpdateFromWebSocket extends ProposalsEvent {
  final Map<String, dynamic> data;

  const ProposalsUpdateFromWebSocket({required this.data});

  @override
  List<Object> get props => [data];
}

/// Conectar WebSocket para propostas
class ProposalsConnectWebSocket extends ProposalsEvent {
  const ProposalsConnectWebSocket();
}

/// Desconectar WebSocket para propostas
class ProposalsDisconnectWebSocket extends ProposalsEvent {
  const ProposalsDisconnectWebSocket();
}

/// Refresh manual das propostas
class ProposalsRefresh extends ProposalsEvent {
  const ProposalsRefresh();
}

/// Limpar erros exibidos
class ProposalsClearErrors extends ProposalsEvent {
  const ProposalsClearErrors();
}

