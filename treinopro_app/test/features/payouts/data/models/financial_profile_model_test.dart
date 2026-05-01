import 'package:flutter_test/flutter_test.dart';
import 'package:treinopro_app/features/payouts/data/models/financial_profile_model.dart';

void main() {
  test('parses ready Stripe account status from financial profile', () {
    final model = FinancialProfileModel.fromJson({
      'preferredMethod': 'bank_transfer',
      'canReceivePayments': true,
      'stripeAccount': {
        'accountId': 'acct_123',
        'onboardingCompleted': true,
        'chargesEnabled': true,
        'payoutsEnabled': true,
        'detailsSubmitted': true,
        'requirements': {
          'currentlyDue': [],
          'eventuallyDue': [],
          'pastDue': [],
          'pendingVerification': [],
          'disabledReason': null,
        },
      },
    });

    expect(model.hasStripeAccount, isTrue);
    expect(model.requiresStripeOnboarding, isFalse);
    expect(model.stripeAccount?.isReadyForPayout, isTrue);
  });

  test('flags outstanding Stripe requirements as pending onboarding', () {
    final model = FinancialProfileModel.fromJson({
      'preferredMethod': 'bank_transfer',
      'canReceivePayments': false,
      'stripeAccount': {
        'accountId': 'acct_456',
        'onboardingCompleted': false,
        'chargesEnabled': false,
        'payoutsEnabled': false,
        'detailsSubmitted': false,
        'requirements': {
          'currentlyDue': ['external_account'],
          'eventuallyDue': [],
          'pastDue': ['representative.document'],
          'pendingVerification': [],
          'disabledReason': 'requirements.past_due',
        },
      },
    });

    expect(model.requiresStripeOnboarding, isTrue);
    expect(model.stripeAccount?.hasPendingRequirements, isTrue);
    expect(
      model.stripeAccount?.outstandingRequirements,
      containsAll(['external_account', 'representative.document']),
    );
  });
}
