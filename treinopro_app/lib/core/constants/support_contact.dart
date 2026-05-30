class SupportContact {
  SupportContact._();

  static const email = 'contato@treinopro.com';

  static const accountLookupHint =
      'Informe seus dados completos para localizarmos sua conta:\n'
      '• Nome completo\n'
      '• E-mail cadastrado no app\n'
      '• CPF\n'
      '• CREF (se for personal trainer)';

  static const resubmitDocumentsBody =
      'Sua documentação não foi aceita.\n\n'
      'Envie os documentos corretos para $email com os dados abaixo e anexe os arquivos no e-mail:\n\n'
      '$accountLookupHint\n\n'
      'Analisaremos e entraremos em contato.';

  static const blockedAccountBody =
      'Sua conta está bloqueada.\n\n'
      'Entre em contato pelo e-mail $email informando:\n\n'
      '$accountLookupHint';

  static const inactiveAccountBody =
      'Sua conta está inativa.\n\n'
      'Entre em contato pelo e-mail $email informando:\n\n'
      '$accountLookupHint';

  static const pendingRejectedBody =
      'Seu cadastro foi recusado porque a documentação enviada não foi aceita.\n\n'
      'Envie os documentos corretos para $email informando:\n\n'
      '$accountLookupHint\n\n'
      'Anexe os documentos corretos no e-mail.';
}
