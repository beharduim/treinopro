# Sistema de Notificações

Este módulo implementa um sistema completo de notificações integrado com a API.

## Componentes

### 1. NotificationsApiService
Serviço para consumir a API de notificações:
- `getNotifications(token)` - Obtém todas as notificações
- `getUnreadCount(token)` - Obtém contagem de não lidas
- `markAsRead(token, notificationId)` - Marca como lida
- `markAllAsRead(token)` - Marca todas como lidas
- `deleteNotification(token, notificationId)` - Remove notificação
- `clearAllNotifications(token)` - Limpa todas

### 2. NotificationModel
Modelo de dados para notificações:
- `id` - ID único
- `title` - Título da notificação
- `message` - Mensagem
- `type` - Tipo (info, success, warning, error)
- `isRead` - Se foi lida
- `createdAt` - Data de criação
- `data` - Dados extras (opcional)

### 3. NotificationsModal
Modal para exibir notificações:
- Lista todas as notificações
- Botão "Limpar todas"
- Marcar como lida individual
- Remover individual
- Estado vazio quando não há notificações

### 4. NotificationBell
Widget do sino de notificações:
- Ícone de sino
- Indicador vermelho com contador
- Suporte a números > 9 (mostra "9+")

### 5. NotificationsMixin
Mixin para gerenciar notificações em páginas:
- Carrega notificações automaticamente
- Gerencia estado local
- Métodos para marcar como lida, remover, etc.
- Mostra modal de notificações

## Como Usar

### Em uma página (ex: HomePage):

```dart
class _MyHomePageState extends State<MyHomePage> with NotificationsMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomTopBar(
        unreadNotificationsCount: unreadCount,
        onNotificationTap: showNotificationsModal,
      ),
      // ... resto do código
    );
  }
}
```

### Propriedades disponíveis no mixin:
- `notifications` - Lista de notificações
- `unreadCount` - Contagem de não lidas
- `isLoadingNotifications` - Se está carregando

### Métodos disponíveis no mixin:
- `showNotificationsModal()` - Mostra o modal
- `markAsRead(notificationId)` - Marca como lida
- `deleteNotification(notificationId)` - Remove notificação
- `clearAllNotifications()` - Limpa todas
- `markAllAsRead()` - Marca todas como lidas
- `refreshNotifications()` - Recarrega notificações

## Integração com API

O sistema espera os seguintes endpoints:

- `GET /notifications` - Lista notificações
- `GET /notifications/unread-count` - Contagem não lidas
- `PATCH /notifications/:id/read` - Marcar como lida
- `PATCH /notifications/mark-all-read` - Marcar todas como lidas
- `DELETE /notifications/:id` - Remover notificação
- `DELETE /notifications/clear-all` - Limpar todas

## Exemplo de Resposta da API

```json
{
  "notifications": [
    {
      "id": "123",
      "title": "Nova aula agendada",
      "message": "Sua aula com João foi agendada para amanhã às 14h",
      "type": "info",
      "isRead": false,
      "createdAt": "2024-01-15T10:30:00Z",
      "data": {
        "classId": "456",
        "personalId": "789"
      }
    }
  ]
}
```
