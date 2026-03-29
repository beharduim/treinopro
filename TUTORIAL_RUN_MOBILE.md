# Tutorial: Rodar Mobile (Android e iOS)

Este guia mostra como rodar o app `treinopro_app` com backend local, em:

- Android Emulator
- Android físico
- iOS Simulator
- iPhone físico

## 1. Pré-requisitos

Backend no ar:

```bash
cd treinopro-api
npm run start:dev
```

App Flutter:

```bash
cd treinopro_app
flutter pub get
```

## 2. Valor correto de `API_BASE_URL`

Edite `treinopro_app/.env`:

```env
API_BASE_URL=...
```

Use este valor por cenário:

| Cenário | API_BASE_URL |
|---|---|
| Android Emulator | `http://10.0.2.2:3000` |
| Android físico (mesma rede Wi-Fi) | `http://SEU_IP_LOCAL:3000` |
| iOS Simulator (macOS) | `http://localhost:3000` |
| iPhone físico (mesma rede Wi-Fi) | `http://SEU_IP_LOCAL:3000` |

## 3. Android Emulator

1. Inicie o emulador:

```bash
flutter emulators
flutter emulators --launch Medium_Phone_API_36.1
```

1. Configure `treinopro_app/.env`:

```env
API_BASE_URL=http://10.0.2.2:3000
```

1. Rode o app:

```bash
cd treinopro_app
flutter devices
flutter run -d emulator-5554
```

## 4. Android físico

Opção A (recomendada por USB com `adb reverse`):

1. Conecte o celular por USB e habilite depuração USB.
2. Rode:

```bash
adb devices
adb reverse tcp:3000 tcp:3000
```

1. Configure `treinopro_app/.env`:

```env
API_BASE_URL=http://localhost:3000
```

1. Rode:

```bash
flutter run -d <android_device_id>
```

Opção B (Wi-Fi na mesma rede):

1. Descubra o IP local da máquina:

```bash
hostname -I
```

1. Configure `treinopro_app/.env`:

```env
API_BASE_URL=http://SEU_IP_LOCAL:3000
```

1. Rode:

```bash
flutter run -d <android_device_id>
```

## 5. iOS Simulator (somente macOS)

1. Abra o Simulator:

```bash
open -a Simulator
```

1. Configure `treinopro_app/.env`:

```env
API_BASE_URL=http://localhost:3000
```

1. Rode:

```bash
cd treinopro_app
flutter devices
flutter run -d "iPhone 15"
```

## 6. iPhone físico (somente macOS)

1. Conecte o iPhone por cabo.
2. Abra `ios/Runner.xcworkspace` no Xcode e configure Signing (Team).
3. No iPhone, marque o computador como confiável.
4. Use a mesma rede Wi-Fi do backend.
5. Descubra o IP local da máquina:

```bash
ipconfig getifaddr en0
```

1. Configure `treinopro_app/.env`:

```env
API_BASE_URL=http://SEU_IP_LOCAL:3000
```

1. Rode:

```bash
cd treinopro_app
flutter run -d <ios_device_id>
```

## 7. Erros comuns

`Connection refused`:

- Backend não está rodando em `:3000`.
- IP/porta no `.env` está incorreto.
- Dispositivo físico não está na mesma rede.

`ENOTFOUND`:

- Host inválido no `API_BASE_URL`.

No Android físico via Wi-Fi não conecta:

- Teste `adb reverse` (USB), que elimina dependência de rede local.

No iOS com URL HTTP local:

- Se houver bloqueio de ATS, use endpoint HTTPS ou adicione exceção de ATS para desenvolvimento em `ios/Runner/Info.plist`.

## 8. Dica para alternar rápido de ambiente

Mantenha arquivos separados:

- `.env.android.emulator`
- `.env.android.device`
- `.env.ios.simulator`
- `.env.ios.device`

E copie para `.env` antes de rodar:

```bash
cp .env.android.emulator .env
```
