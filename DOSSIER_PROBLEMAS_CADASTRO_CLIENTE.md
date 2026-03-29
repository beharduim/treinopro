# Dossiê Técnico (Resumo Executivo) - Problemas no Cadastro

## Contexto

Foi realizada uma análise técnica do fluxo de cadastro (App + API), focada em:
- validação de e-mail duplicado,
- validação de CREF e anexos obrigatórios,
- upload de imagens,
- validação de CPF/CNH.

Este documento é um resumo para tomada de decisão do cliente.

## Situação atual

O sistema está funcional em partes, mas foram identificados pontos críticos que podem gerar:
- cadastro com dados inválidos,
- avanço indevido no fluxo,
- mensagens inconsistentes para o usuário,
- risco de segurança por exposição de dados em log,
- falhas de confiabilidade nos testes.

## Problemas encontrados (visão simples)

| # | Problema | Impacto para o negócio/usuário | Prioridade |
|---|---|---|---|
| 1 | Regra de documento com bug no app (ramo de CNH inalcançável) | Pode validar documento errado e aprovar/reprovar indevidamente | Crítica |
| 2 | Avanço duplicado na etapa de e-mail | Usuário pode “pular” etapa e gerar inconsistência no cadastro | Alta |
| 3 | Backend sem validação robusta de CPF/CNH | Cadastro pode aceitar documento inválido | Alta |
| 4 | Regras de upload não totalmente unificadas | Falhas em validação de tamanho/formato/dimensão e erros pouco claros | Alta |
| 5 | Log com payload de cadastro sensível | Risco de exposição de dados sensíveis em logs | Alta |
| 6 | Testes de integração desalinhados com contrato real | Falso positivo/negativo em homologação | Média |
| 7 | Inconsistência na contagem de etapas para menor de idade | Fluxo pode exibir comportamento inesperado entre telas | Média |

## Detalhamento técnico (objetivo e direto)

### 1) Bug de validação de documento no app

A lógica atual possui condição duplicada para documento com 11 dígitos, impedindo o comportamento correto para cenários CNH/CPF.

### 2) Avanço duplicado no fluxo de e-mail

A etapa de e-mail dispara avanço em dois pontos diferentes. Isso pode levar o usuário para frente antes da confirmação ideal do estado.

### 3) Validação fraca no backend para CPF/CNH

Hoje há validação de formato básico, mas sem garantir integralmente os dígitos verificadores e regras completas por tipo de documento.

### 4) Upload com validações parcialmente distribuídas

Existem validações em mais de uma camada, mas não totalmente consistentes entre controller/guard/service, inclusive em regras de dimensão.

### 5) Exposição de dados sensíveis em logs

Há log de payload de cadastro completo. Isso pode incluir dados que não deveriam ficar visíveis em ambientes de log.

### 6) Testes de integração não refletem 100% o contrato atual

Parte dos testes usa campos que não representam o fluxo vigente, reduzindo a confiança do resultado automático.

### 7) Inconsistência de etapas (menor de idade)

Duas partes do app calculam quantidade de etapas de forma diferente, podendo causar comportamento inconsistente de navegação.

## Risco consolidado

- Risco funcional: alto (cadastro pode aceitar/rejeitar incorretamente).
- Risco de experiência: alto (fluxo confuso e mensagens inconsistentes).
- Risco técnico: médio/alto (testes e padronização incompletos).
- Risco de segurança: alto (dados sensíveis em log).

## Recomendação

Aplicar o plano de correção em 2 fases:
1. Fase de estabilização: corrigir os 7 pontos críticos/médios listados.
2. Fase de confiabilidade: consolidar testes de integração e regressão completa dos fluxos aluno/personal.

## Status do trabalho

- Diagnóstico concluído.
- Plano técnico estruturado.
- Implementação ainda não iniciada neste dossiê (somente análise).
