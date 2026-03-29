# Imagens do Onboarding

Esta pasta deve conter as imagens necessárias para o sistema de onboarding.

## Imagens Necessárias

### Para Alunos
- `student_logo.png` - Logo principal para a primeira página
- `student_training.png` - Imagem para a segunda página (treinos personalizados)
- `student_progress.png` - Imagem para a terceira página (acompanhamento)

### Para Professores (futuro)
- `teacher_logo.png` - Logo principal para professores
- `teacher_training.png` - Imagem para treinos de professores

### Imagem de Fundo (Compartilhada)
- `gym_background.png` - **IMAGEM ESSENCIAL** - Imagem de fundo da academia para todas as páginas

## Especificações Técnicas

### Resoluções Recomendadas
- **Logo principal**: 240x240px (1x), 480x480px (2x), 720x720px (3x)
- **Imagens de conteúdo**: 300x200px (1x), 600x400px (2x), 900x600px (3x)
- **Imagem de fundo da academia**: 412x400px (1x), 824x800px (2x), 1236x1200px (3x)

### Formatos
- **PNG**: Para logos e imagens com transparência
- **JPG**: Para imagens de fundo e fotografias

### Otimização
- Comprimir imagens para reduzir o tamanho do app
- Usar WebP quando possível para melhor compressão
- Manter qualidade visual adequada

## Estrutura de Arquivos

```
onboarding/
├── README.md
├── gym_background.png          ← IMAGEM ESSENCIAL
├── student_logo.png
├── student_training.png
├── student_progress.png
├── teacher_logo.png
├── teacher_training.png
└── teacher_progress.png
```

## Notas de Design

- **gym_background.png** é a imagem mais importante - ela aparece em todas as páginas
- A imagem deve mostrar uma academia moderna e atrativa
- Cores devem ser consistentes com a paleta do app
- Estilo visual deve ser moderno e profissional
- A imagem será sobreposta com um gradiente semi-transparente

## Como Adicionar

1. **Coloque a imagem `gym_background.png` nesta pasta** (prioridade máxima)
2. Adicione as outras imagens conforme necessário
3. Atualize o `pubspec.yaml` se necessário
4. Verifique se os caminhos estão corretos no código
5. Teste em diferentes resoluções de tela

## Importante

⚠️ **Sem a imagem `gym_background.png`, o onboarding não funcionará corretamente!**

Esta imagem é usada como fundo para todas as páginas e é essencial para o layout funcionar conforme o design do Figma.
