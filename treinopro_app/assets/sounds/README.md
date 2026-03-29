# Pasta de Sons

Esta pasta contém os arquivos de áudio do app.

## Sons implementados:

### Notificação de Proposta
- **Arquivo**: Para adicionar um som personalizado, coloque um arquivo `.mp3` ou `.wav` aqui
- **Uso**: Toca quando uma nova proposta aparece (igual ao Uber)
- **Implementação atual**: Usa vibração múltipla para simular o som

## Como adicionar um som personalizado:

1. Coloque o arquivo de áudio nesta pasta (ex: `notification.mp3`)
2. No código `proposal_modal.dart`, substitua a função `_playNotificationSound()` por:

```dart
Future<void> _playNotificationSound() async {
  try {
    await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    await HapticFeedback.mediumImpact();
  } catch (e) {
    await HapticFeedback.mediumImpact();
  }
}
```
