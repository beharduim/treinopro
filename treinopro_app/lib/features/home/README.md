# 🏠 Feature Home - TreinoPRO

## 📋 Descrição
A feature Home é responsável por exibir a tela principal do aplicativo após o usuário completar o onboarding. Ela apresenta informações do usuário, missões semanais, questionário de saúde e outras funcionalidades principais.

## 🏗️ Arquitetura

### Estrutura de Pastas
```
lib/features/home/
├── domain/                    # Regras de negócio
│   ├── entities/             # Entidades do domínio
│   ├── repositories/         # Contratos dos repositórios
│   └── usecases/            # Casos de uso
├── data/                     # Implementação dos dados
│   ├── models/               # Modelos de dados
│   └── repositories/         # Implementação dos repositórios
└── presentation/             # Interface do usuário
    ├── bloc/                 # Gerenciamento de estado
    ├── pages/                # Páginas da aplicação
    └── widgets/              # Componentes reutilizáveis
```

## 🚀 Como Usar

### 1. Navegação para a Home
Após completar o onboarding, o usuário é automaticamente direcionado para a home:

```dart
// No onboarding, após completar
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => sl<HomeBloc>(),
      child: const StudentHomePage(),
    ),
  ),
);
```

### 2. Teste da Home
Para testar a home diretamente, use a página de teste:

```dart
import 'package:treinopro_app/features/home/home.dart';

// Em qualquer lugar da aplicação
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const HomeTestPage(),
  ),
);
```

## 🎯 Funcionalidades

### ✅ Implementadas
- **Header com avatar**: Avatar circular 48px com borda branca 2px
- **Saudação do usuário**: "Olá, Lucas!" com nível e XP
- **Status com baseline alignment**: Medalhas + "Iniciante" + "120 xp" + "Ver nível"
- **Missão semanal**: Card com gradiente laranja e progress bar
- **Questionário de saúde**: Botão laranja sólido com ícone de coração
- **Status de treinos**: Card informativo com ícone laranja
- **Grid de conquistas**: Cards simétricos com sombras sutis

### 🔄 Em Desenvolvimento
- **Header completo**: Será implementado posteriormente
- **Navegação inferior**: Será implementada posteriormente
- Navegação para questionário de saúde
- Navegação para perfil do usuário
- Navegação para treinos
- Navegação para conquistas

## 🎨 Design

### Cores Utilizadas
- **Primária**: `#FF6A00` (Laranja)
- **Secundária**: `#FF8C00` (Laranja 2 - gradiente)
- **Título principal**: `#1C1C1C`
- **Texto padrão**: `#5A5A5A`
- **Texto secundário**: `#6B6B6B`
- **Fundo cinza claro**: `#F8F8F8`
- **Fundo branco**: `#FFFFFF`

### Tipografia
- **Títulos**: 24px, semibold (600)
- **Subtítulos**: 18px, bold (700)
- **Corpo**: 16px, semibold (600)
- **Pequeno**: 14px, medium (500)
- **Muito pequeno**: 12-13px, regular (400)

### Layout e Espaçamentos
- **SafeArea**: Top e bottom para evitar cortes
- **SingleChildScrollView**: Com padding 16px horizontal e vertical
- **Espaçamentos verticais**: 16px entre blocos principais
- **Espaçamentos internos**: 8px entre título e subtítulo
- **Padding dos cards**: 20px uniforme
- **Border radius**: 16px para cards, 12px para botões

### Sombras e Efeitos
- **Card missão**: blur 16, y=4, opacidade 0.12
- **Cards gerais**: blur 12, y=4, opacidade 0.08
- **Botões**: blur 12, y=4, opacidade 0.12

## 🔧 Configuração

### Dependências
A feature home está registrada no sistema de injeção de dependências:

```dart
// Home Feature
sl.registerLazySingleton<HomeRepository>(
  () => HomeRepositoryImpl(),
);

sl.registerFactory<HomeBloc>(
  () => HomeBloc(
    getHomeStateUseCase: sl<GetHomeStateUseCase>(),
    updateWeeklyMissionProgressUseCase: sl<UpdateWeeklyMissionProgressUseCase>(),
    completeHealthQuestionnaireUseCase: sl<CompleteHealthQuestionnaireUseCase>(),
  ),
);
```

### Persistência
Os dados são persistidos usando `SharedPreferences`:
- Nome do usuário
- Nível e XP
- Progresso da missão semanal
- Status do questionário de saúde
- Estatísticas de treinos e conquistas

## 📱 Responsividade
A interface é responsiva e se adapta a diferentes tamanhos de tela usando:
- `SafeArea` para evitar cortes
- `SingleChildScrollView` para scroll infinito
- `Expanded` para distribuição proporcional de espaço
- Dimensões relativas em vez de fixas
- Grid responsivo para cards inferiores

## 🧪 Testes
Para testar a feature:

1. **Teste direto**: Use `HomeTestPage`
2. **Teste via onboarding**: Complete o onboarding como aluno
3. **Teste de funcionalidades**: Use os botões e interações disponíveis

## 🔮 Próximos Passos
1. **Implementar header completo**: Com logo/texto e notificações
2. **Implementar navegação inferior**: Home, Treino e Perfil
3. Implementar navegação para outras telas
4. Adicionar animações de transição
5. Implementar notificações push
6. Adicionar modo offline
7. Implementar sincronização com backend

## 📞 Suporte
Para dúvidas ou problemas, consulte:
- Documentação do Flutter
- Padrões de Clean Architecture do projeto
- Exemplos de implementação existentes
