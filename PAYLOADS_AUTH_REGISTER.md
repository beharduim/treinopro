# Payloads prontos para teste de Auth

Base URL local:

```bash
export API_URL="http://localhost:3000"
```

IDs de arquivos seedados (tabela `files`):
- `a1b2c3d4-e5f6-7890-abcd-ef1234567890` (documento)
- `b2c3d4e5-f6a7-8901-bcde-f23456789012` (documento/CREF)

## 1) Registrar Aluno (recomendado para começar)

```bash
curl -X POST "localhost:3000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "aluno.teste1@treinopro.local",
    "password": "123456",
    "firstName": "Joao",
    "lastName": "Silva",
    "birthDate": "1998-05-10",
    "userType": "student",
    "documentType": "RG",
    "documentNumber": "12345678901",
    "documentImageId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "isMinor": false,
    "guardianConsent": false,
    "termsAccepted": true,
    "privacyPolicyAccepted": true
  }'
```

## 2) Login do Aluno

```bash
curl -X POST "localhost:3000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "aluno.teste1@treinopro.local",
    "password": "123456"
  }'
```

## 3) Registrar Personal

Observação:
- O backend valida CREF.
- Se a validação externa falhar na sua rede/ambiente, esse cadastro pode retornar erro mesmo com payload correto.

```bash
curl -X POST "localhost:3000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "personal.teste1@treinopro.local",
    "password": "123456",
    "firstName": "Maria",
    "lastName": "Souza",
    "birthDate": "1990-03-15",
    "userType": "personal",
    "documentType": "CNH",
    "documentNumber": "10987654321",
    "documentImageId": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
    "cref": "SP-106227",
    "crefImageId": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
    "specialties": ["Musculacao", "Funcional"],
    "isMinor": false,
    "guardianConsent": false,
    "termsAccepted": true,
    "privacyPolicyAccepted": true
  }'
```

## 4) Login do Personal

```bash
curl -X POST "localhost:3000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "personal.teste1@treinopro.local",
    "password": "123456"
  }'
```

## 5) Registrar Menor de Idade (Aluno)

```bash
curl -X POST "localhost:3000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "aluno.menor1@treinopro.local",
    "password": "123456",
    "firstName": "Pedro",
    "lastName": "Lima",
    "birthDate": "2010-08-20",
    "userType": "student",
    "documentType": "RG",
    "documentNumber": "22334455667",
    "documentImageId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "isMinor": true,
    "guardianName": "Ana Lima",
    "guardianEmail": "responsavel.teste1@treinopro.local",
    "guardianConsent": true,
    "termsAccepted": true,
    "privacyPolicyAccepted": true
  }'
```

