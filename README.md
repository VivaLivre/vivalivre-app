# 💙 VivaLivre

> Devolvendo autonomia, segurança e qualidade de vida para quem tem pressa.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?style=flat-square&logo=go&logoColor=white)](https://go.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-PostGIS-336791?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

---

## 📖 Sobre o Projeto

**VivaLivre** é uma plataforma mobile nativa desenvolvida com **Flutter/Dart**, projetada para oferecer segurança, autonomia e qualidade de vida para pessoas que vivem com doenças autoimunes intestinais, como **Doença de Crohn** e **Retocolite Ulcerativa (RCU)**.

O projeto utiliza um ecossistema desacoplado, com um aplicativo Flutter de alta performance conectado a um **Backend próprio desenvolvido em Go**, garantindo total autonomia e soberania dos dados.

---

## ✨ Principais Funcionalidades

- **⚡ Botão de Emergência** — Localiza o banheiro mais próximo e bem avaliado em um toque, com integração de rotas.
- **🗺️ Mapeamento Colaborativo** — Busca de banheiros adaptados via geolocalização avançada com **PostGIS**.
- **🩺 Diário de Saúde** — Controle diário de sintomas, humor e evacuações com persistência em API REST.
- **🪪 Cartão Digital DII** — Validação visual rápida para uso em filas e banheiros preferenciais.
- **📄 Relatório PDF** — Exportação do histórico de sintomas para profissionais de saúde.

---

## 🛠️ Stack Tecnológico

| Camada | Tecnologia |
|---|---|
| **Front-end (Mobile)** | Flutter & Dart |
| **Gerenciamento de Estado** | BLoC (`flutter_bloc`) |
| **Back-end & API** | Go (Golang) com Gin Gonic |
| **Banco de Dados** | PostgreSQL + PostGIS |
| **Autenticação** | JWT Proprietário (JSON Web Token) |
| **Persistência Local** | `flutter_secure_storage` |
| **Comunicação HTTP** | `Dio` |

---

## 🏗️ Arquitetura

O projeto segue princípios de **Clean Architecture**, com separação entre as camadas de apresentação, domínio e dados:

```
lib/
├── core/                       # Utils, API Client, Temas, Modelos Globais
├── features/
│   ├── auth/                   # Login, Cadastro, Gestão de Tokens (JWT)
│   ├── map/                    # Mapa de Banheiros via PostGIS
│   ├── health/                 # Diário de Saúde e Sintomas
│   ├── home/                   # Shell principal + Navegação
│   └── profile/                # Perfil e Configurações
└── main.dart                   # Inicialização e Injeção de Dependência
```

---

## 🚀 Como Executar Localmente

### Pré-requisitos

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install)
- [Backend VivaLivre Go](https://github.com/VivaLivre/vivalivre-backend) rodando localmente

### Passo a Passo

**1. Clone o repositório**
```bash
git clone https://github.com/VivaLivre/vivalivre-app.git
cd vivalivre-app/viva_livre_app
```

**2. Instale as dependências**
```bash
flutter pub get
```

**3. Configure o Host da API**
O aplicativo detecta automaticamente o ambiente:
- **Android Emulator**: Aponta para `http://10.0.2.2:8080`
- **iOS/Web/Físico**: Aponta para `http://localhost:8080` (ajustável no `ApiClient`)

**4. Execute o aplicativo**
```bash
flutter run
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
