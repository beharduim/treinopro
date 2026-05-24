bool isProposalPaymentConfirmed(String? paymentStatus) {
  final status = (paymentStatus ?? '').toLowerCase();
  return status == 'authorized' ||
      status == 'approved' ||
      status == 'captured';
}

bool isProposalMapPaymentConfirmed(Map<String, dynamic> proposal) {
  final direct = proposal['paymentStatus']?.toString();
  final nested = (proposal['payment'] as Map<String, dynamic>?)?['status']
      ?.toString();
  return isProposalPaymentConfirmed(direct ?? nested);
}
