# Metodologia de Planejamento (Baseada na Sua Persona)

## Objetivo deste documento
Registrar, em formato prático e reaproveitável, o método de planejamento que você utilizou: investigação completa, sem implementação inicial, com rastreabilidade total e comunicação executiva para cliente.

## Sua persona de trabalho (extraída das suas mensagens)
- Você quer **planejamento antes de codificação**.
- Você exige **inventário completo** (páginas, componentes, endpoints, controllers, services, DTOs, schemas, testes).
- Você quer documentação **técnica, mas simples**, pronta para cliente.
- Você prefere execução com **clareza de fluxo**: o dev deve seguir o guia e encontrar/corrigir com segurança.
- Você valoriza **objetividade e cobertura total** ("literalmente tudo").

---

## Método passo a passo (como você conduziu)

## Etapa 1 - Definição de restrição principal
1. Declarar que **não é para codificar** inicialmente.
2. Exigir criação de um markdown de plano de ação.
3. Determinar local exato do arquivo (`/planos` ou raiz, conforme objetivo).

## Etapa 2 - Escopo funcional fechado
1. Listar os problemas em formato checklist.
2. Especificar comportamento esperado (mensagem exata, bloqueio de fluxo, validação correta, etc.).
3. Pedir correção com foco em causa-raiz, não apenas sintoma.

## Etapa 3 - Mapeamento sistêmico completo
1. Exigir levantamento de todos os artefatos relacionados e sub-relacionados.
2. Cobrir frontend e backend ponta a ponta.
3. Cobrir também infra e testes (bootstrap, env, schemas, integrações).

## Etapa 4 - Consolidação em guia operacional
1. Organizar por fluxo (cadastro, validação, upload, documento).
2. Mapear endpoints, contratos e dependências.
3. Criar ordem de execução recomendada.
4. Criar critérios de aceite claros.

## Etapa 5 - Reforço técnico com regra oficial
1. Inserir algoritmos formais (CPF/CNH) no plano.
2. Definir regra de decisão por tipo de documento (CPF != CNH).
3. Adicionar matriz de testes com casos positivos e negativos.

## Etapa 6 - Revisão crítica de qualidade
1. Pedir avaliação de qualidade do código no escopo do plano.
2. Exigir identificação de problemas por severidade.
3. Transformar achados em checklist objetivo de correção.

## Etapa 7 - Comunicação executiva para cliente
1. Gerar dossiê técnico simplificado.
2. Traduzir riscos técnicos para impacto de negócio.
3. Priorizar por criticidade (crítica/alta/média).

---

## Template de prompt (reutilizável, no seu estilo)

```text
Quero que você atue como analista técnico de investigação.

Regra principal: NÃO codifique nada nesta fase.

Objetivo:
Criar um plano completo para investigar e corrigir [TEMA/PROBLEMA].

Escopo obrigatório:
- mapear tudo, literalmente tudo que for relacionado e sub-relacionado;
- frontend: páginas, steps, widgets/componentes, bloc/state/event, usecases, services, datasource, models;
- backend: endpoints, controllers, services, DTOs, modules, guards, utils, schemas, testes;
- infra: bootstrap, env, configuração de API, dependências.

Entrega esperada:
1) Um markdown em [PASTA/ARQUIVO] com:
- objetivo;
- inventário completo de arquivos;
- mapa de endpoints;
- fluxo ponta a ponta;
- checklist detalhado por fase;
- critérios de aceite;
- matriz de testes (positivo e negativo).

2) Linguagem técnica, mas simples, para que qualquer dev execute sem ambiguidade.

3) Não implemente código agora; apenas planejamento.

Problemas a tratar:
- [ITEM 1]
- [ITEM 2]
- [ITEM 3]
- [ITEM 4]

Regras específicas:
- quando houver algoritmo oficial (ex.: CPF/CNH), documente no plano;
- inclua mensagem final esperada exata quando aplicável;
- destaque riscos de segurança e inconsistências de contrato/teste.
```

---

## Versão "Prompt + Dossiê" (quando precisar enviar para cliente)

```text
Além do plano técnico, crie também um dossiê executivo em markdown na raiz do projeto com:
- resumo executivo;
- lista de problemas encontrados;
- impacto no negócio/usuário;
- prioridade;
- recomendação em fases.

Tom: técnico, simples e direto, pronto para envio no WhatsApp.
```

---

## Checklist da sua metodologia (rápido)
- [ ] Travar implementação inicial (apenas análise/planejamento).
- [ ] Definir escopo fechado com critérios objetivos.
- [ ] Exigir inventário completo de arquivos e fluxos.
- [ ] Exigir algoritmo formal para validações críticas.
- [ ] Exigir análise de qualidade e priorização de riscos.
- [ ] Exigir saída executiva para cliente.

## Resultado esperado ao aplicar este método
- Menos retrabalho.
- Maior previsibilidade de correção.
- Melhor comunicação com cliente.
- Execução técnica guiada e auditável.
