# 💙 VivaLivre

> Devolvendo autonomia, segurança e qualidade de vida para quem tem pressa.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Node.js](https://img.shields.io/badge/Node.js-LTS-339933?style=flat-square&logo=node.js&logoColor=white)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-Atlas-47A248?style=flat-square&logo=mongodb&logoColor=white)](https://www.mongodb.com/atlas)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

---

## 📖 Sobre o Projeto

**VivaLivre** é uma plataforma mobile nativa desenvolvida com **Flutter/Dart**, projetada para oferecer segurança, autonomia e qualidade de vida para pessoas que vivem com doenças autoimunes intestinais, como **Doença de Crohn** e **Retocolite Ulcerativa (RCU)**.

Existem aproximadamente **200 mil brasileiros diagnosticados com DII**. A imprevisibilidade dos sintomas intestinais gera ansiedade severa e isolamento social. O VivaLivre resolve essa dor conectando os usuários a uma rede colaborativa de banheiros acessíveis via GPS nativo, além de oferecer um controle unificado de saúde e o **Cartão Digital de Prioridade DII**.

---

## ✨ Principais Funcionalidades

- **⚡ Botão de Emergência** — Localiza o banheiro mais próximo e bem avaliado em um toque, com integração de rotas (Google Maps / Apple Maps).
- **🗺️ Mapeamento Colaborativo** — Usuários adicionam e avaliam banheiros por limpeza, acessibilidade e outros critérios, estilo Waze.
- **🩺 Diário de Saúde** — Controle diário de sintomas, humor, evacuações e lembretes de medicação com gráficos evolutivos via `fl_chart`.
- **🪪 Cartão Digital DII** — Validação visual rápida para uso em filas e banheiros preferenciais, garantindo os direitos legais do portador.
- **🔔 Lembretes Push** — Notificações de medicação via Firebase Cloud Messaging integradas a cron jobs no back-end.
- **📄 Relatório PDF** — Exportação do histórico de sintomas para compartilhamento com profissionais de saúde.

---

## 🛠️ Stack Tecnológico

O aplicativo foi construído focado em alta performance e resposta rápida (60fps):

| Camada | Tecnologia |
|---|---|
| **Front-end (Mobile)** | Flutter & Dart — compilação nativa iOS/Android |
| **Gerenciamento de Estado** | BLoC (`flutter_bloc`) |
| **Back-end & API** | Node.js com Express |
| **Banco de Dados** | MongoDB Atlas (queries geoespaciais `$near`) |
| **Autenticação** | Firebase Authentication (e-mail/senha + Google Sign-In) |
| **Notificações Push** | Firebase Cloud Messaging (FCM) |
| **Mapa** | `flutter_map` + `geolocator` (GPS nativo) |
| **Armazenamento Seguro** | `flutter_secure_storage` (JWT no Keychain/Keystore) |

---

## 🏗️ Arquitetura

O projeto segue o padrão **Three-Tier + BLoC**, com separação clara entre UI, lógica de negócio e acesso a dados:

```
lib/
├── main.dart
├── app.dart                    # MaterialApp root + rotas nomeadas
├── features/
│   ├── auth/                   # Login, Cadastro, Onboarding
│   │   └── presentation/       # AuthBloc, LoginPage, RegisterPage
│   ├── map/                    # Mapa de Banheiros
│   │   └── presentation/       # MapPage (GPS + pins + emergência)
│   ├── health/                 # Diário de Saúde
│   ├── home/                   # Shell principal + Bottom Navigation
│   └── profile/                # Perfil do Usuário
└── shared/
    └── widgets/                # Componentes reutilizáveis
```

---

## 📱 Telas do Aplicativo

| Onboarding | Login | Mapa Principal |
|:---:|:---:|:---:|
| *(screenshot)* | *(screenshot)* | *(screenshot)* |

| Botão de Emergência | Card de Banheiro | Perfil |
|:---:|:---:|:---:|
| *(screenshot)* | *(screenshot)* | *(screenshot)* |

> 💡 Substitua os placeholders acima pelos prints reais do app ou exports do Figma.

---

## 🚀 Como Executar Localmente

### Pré-requisitos

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) instalado e no `PATH`
- [Android Studio](https://developer.android.com/studio) ou [VS Code](https://code.visualstudio.com/) com extensão Flutter
- Conta no [Firebase](https://console.firebase.google.com/) com projeto criado
- Dispositivo físico ou emulador Android/iOS

### Passo a Passo

**1. Clone o repositório**
```bash
git clone https://github.com/SEU-USUARIO/vivalivre-app.git
cd vivalivre-app/viva_livre_app
```

**2. Instale as dependências**
```bash
flutter pub get
```

**3. Configure o Firebase**

- Acesse o [Firebase Console](https://console.firebase.google.com/) e crie um projeto
- Ative o método de autenticação **Email/Senha** em *Authentication → Sign-in method*
- Baixe o arquivo `google-services.json` e coloque em `android/app/`
- *(Para iOS)* Baixe o `GoogleService-Info.plist` e adicione via Xcode em `ios/Runner/`

**4. Execute o aplicativo**
```bash
flutter run
```

---

## 🗂️ Variáveis de Ambiente (Back-end)

Crie um arquivo `.env` na raiz do back-end com:

```env
PORT=3000
MONGODB_URI=mongodb+srv://usuario:senha@cluster.mongodb.net/vivalivre
FIREBASE_PROJECT_ID=seu-projeto-id
FCM_SERVER_KEY=sua-chave-fcm
```

---

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Siga os passos:

1. Faça um **fork** do projeto
2. Crie uma branch com sua feature: `git checkout -b feature/minha-feature`
3. Faça o commit das suas alterações: `git commit -m 'feat: adiciona minha feature'`
4. Envie para a branch: `git push origin feature/minha-feature`
5. Abra um **Pull Request**

---

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

<div align="center">

Feito com 💙 por **Gabriel José de Souza** para a comunidade DII brasileira.

*"Toda pessoa com DII merece viver com liberdade e dignidade."*

</div>
