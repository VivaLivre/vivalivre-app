# 💙 VivaLivre — Aplicativo Mobile

> Devolvendo autonomia, segurança e qualidade de vida para quem tem pressa.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![BLoC](https://img.shields.io/badge/BLoC-State%20Management-blueviolet?style=flat-square)](https://bloclibrary.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

---

## 📖 Sobre o Aplicativo

**VivaLivre App** é um aplicativo mobile nativo desenvolvido com **Flutter/Dart**, projetado para oferecer segurança, autonomia e qualidade de vida para pessoas que vivem com doenças autoimunes intestinais, como **Doença de Crohn** e **Retocolite Ulcerativa (RCU)**.

O aplicativo utiliza arquitetura **Clean Architecture** com padrão **BLoC** para gerenciamento de estado, conectando-se a um **Backend REST próprio desenvolvido em Go**, garantindo total autonomia e soberania dos dados dos utilizadores.

### 🎯 Objetivo Principal

Fornecer uma ferramenta que permita aos utilizadores com DII:
- Localizar rapidamente banheiros adaptados em situações de emergência
- Registar e acompanhar sintomas e padrões de saúde
- Manter um histórico digital de saúde para consultas médicas
- Validar-se como portador de DII em locais públicos
- Contribuir para um mapa colaborativo de banheiros acessíveis

---

## ✨ Principais Funcionalidades

### 🚨 Botão de Emergência
- Localiza o banheiro mais próximo em um toque
- Integração com rotas e navegação GPS
- Avaliações e comentários de utilizadores
- Informações de acessibilidade (adaptado, espaço, limpeza)

### 🗺️ Mapa Colaborativo de Banheiros
- Busca de banheiros adaptados via geolocalização avançada
- Integração com **PostGIS** para queries geoespaciais eficientes
- Filtros por tipo de adaptação e avaliação
- Contribuição comunitária: adicionar novos banheiros
- Atualização de informações em tempo real

### 🩺 Diário de Saúde
- Registo diário de sintomas e evacuações
- Rastreamento de humor e bem-estar
- Notas e observações personalizadas
- Histórico completo com timestamps
- Sincronização automática com backend

### 🪪 Cartão Digital DII
- Validação visual rápida para uso em filas
- Acesso a banheiros preferenciais
- Informações médicas essenciais
- Contacto de emergência
- Sem necessidade de documento físico

### 📊 Relatórios e Análises
- Exportação de histórico em PDF
- Gráficos de padrões de sintomas
- Relatórios para profissionais de saúde
- Análise de tendências ao longo do tempo

### 👤 Perfil e Configurações
- Gestão de dados pessoais e médicos
- Preferências de privacidade
- Notificações e alertas
- Logout seguro com limpeza de tokens

---

## 🛠️ Stack Tecnológico

| Camada | Tecnologia | Propósito |
|---|---|---|
| **Front-end (Mobile)** | Flutter 3.x & Dart 3.x | Aplicativo nativo multiplataforma (iOS/Android) |
| **Gerenciamento de Estado** | BLoC (`flutter_bloc` 8.x) | Separação clara entre lógica e UI |
| **HTTP Client** | Dio | Requisições REST com interceptadores |
| **Armazenamento Local** | `flutter_secure_storage` | Tokens JWT e dados sensíveis |
| **Geolocalização** | `geolocator` | Localização do utilizador |
| **Mapas** | `flutter_map` + OpenStreetMap | Visualização de banheiros |
| **Imagens** | `image_picker` | Upload de fotos |
| **Testes** | `flutter_test`, `mockito` | Testes unitários e de widget |
| **Análise Estática** | `dart_linter` | Qualidade de código |
| **Back-end & API** | Go (Golang) com Gin Gonic | API REST de alta performance |
| **Banco de Dados** | PostgreSQL + PostGIS | Dados relacionais + queries geoespaciais |
| **Autenticação** | JWT Proprietário | Tokens seguros e stateless |

### Dependências Principais

```yaml
# Estado e BLoC
flutter_bloc: ^8.1.6
bloc: ^8.1.4

# HTTP e Networking
dio: ^5.3.1
retrofit: ^4.0.1

# Armazenamento
flutter_secure_storage: ^9.2.4

# Geolocalização e Mapas
geolocator: ^10.1.0
flutter_map: ^6.0.0
latlong2: ^0.9.1

# UI e Temas
flutter_localizations:
  sdk: flutter

# Testes
mockito: ^5.4.4
```

---

## 🏗️ Arquitetura

O projeto segue princípios de **Clean Architecture** com separação clara entre as camadas de apresentação, domínio e dados. Cada feature é independente e segue o padrão **BLoC** para gerenciamento de estado.

### Estrutura de Pastas

```
lib/
├── core/
│   ├── api/                     # ApiClient (Dio + Interceptadores)
│   ├── theme/                   # Temas Material 3 (Light/Dark)
│   ├── constants/               # Constantes globais
│   └── utils/                   # Funções utilitárias
│
├── features/
│   ├── auth/                    # Autenticação (Login, Cadastro, JWT)
│   │   ├── data/
│   │   │   ├── datasources/     # API calls
│   │   │   ├── models/          # Modelos JSON
│   │   │   └── repositories/    # Implementação do repositório
│   │   ├── domain/
│   │   │   ├── entities/        # Entidades de negócio
│   │   │   ├── repositories/    # Interface do repositório
│   │   │   └── usecases/        # Casos de uso
│   │   └── presentation/
│   │       ├── bloc/            # BLoC (Events, States)
│   │       ├── pages/           # Telas
│   │       └── widgets/         # Componentes reutilizáveis
│   │
│   ├── map/                     # Mapa de Banheiros (PostGIS)
│   ├── health/                  # Diário de Saúde
│   ├── profile/                 # Perfil e Configurações
│   └── home/                    # Shell principal + Navegação
│
└── main.dart                    # Inicialização e Injeção de Dependência
```

### Padrão BLoC

Cada feature implementa o padrão **BLoC** (Business Logic Component):

```dart
// Events — Ações disparadas pela UI
class FetchHealthEntries extends HealthEvent {
  final String userId;
  const FetchHealthEntries(this.userId);
}

// States — Estados emitidos pelo BLoC
class HealthLoading extends HealthState {}
class HealthEntriesLoaded extends HealthState {
  final List<HealthEntry> entries;
  const HealthEntriesLoaded(this.entries);
}

// BLoC — Lógica de negócio
class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final IHealthRepository _repository;
  
  HealthBloc({required IHealthRepository repository})
      : _repository = repository,
        super(HealthInitial()) {
    on<FetchHealthEntries>(_onFetchHealthEntries);
  }
  
  Future<void> _onFetchHealthEntries(
    FetchHealthEntries event,
    Emitter<HealthState> emit,
  ) async {
    emit(HealthLoading());
    try {
      final entries = await _repository.getEntries(event.userId);
      emit(HealthEntriesLoaded(entries));
    } catch (e) {
      emit(HealthError('Erro ao carregar registos'));
    }
  }
}
```

### Princípios de Design

- **Separação de Responsabilidades**: Cada camada tem uma responsabilidade clara
- **Inversão de Dependência**: BLoC depende de interfaces, não de implementações
- **Testabilidade**: Fácil mockar repositórios e datasources
- **Reusabilidade**: Widgets e componentes reutilizáveis
- **Reatividade**: Fluxo de dados unidirecional (UI → BLoC → Repository → API)

---

## 🚀 Como Executar Localmente

### Pré-requisitos

- [Flutter SDK 3.x](https://docs.flutter.dev/get-started/install) — Verificar com `flutter --version`
- [Dart SDK 3.x](https://dart.dev/get-dart) — Incluído no Flutter
- [Git](https://git-scm.com/) — Para clonar o repositório
- **Backend VivaLivre Go** rodando localmente em `http://localhost:8080`
  - Veja [vivalivre-backend](https://github.com/VivaLivre/vivalivre-backend) para setup

### Passo a Passo

**1. Clone o repositório**
```bash
git clone https://github.com/VivaLivre/vivalivre-app.git
cd vivalivre-app
```

**2. Instale as dependências**
```bash
flutter pub get
```

**3. Configure o Host da API**

O aplicativo detecta automaticamente o ambiente via `ApiClient`:

- **Android Emulator**: `http://10.0.2.2:8080` (IP especial para localhost)
- **iOS Simulator**: `http://localhost:8080`
- **Dispositivo Físico**: Ajuste em `lib/core/api/api_client.dart` para o IP da máquina
- **Web**: `http://localhost:8080`

Para dispositivo físico, edite:
```dart
// lib/core/api/api_client.dart
const String baseUrl = 'http://192.168.1.100:8080'; // Seu IP local
```

**4. Execute o aplicativo**

```bash
# Modo debug (desenvolvimento)
flutter run

# Modo release (otimizado)
flutter run --release

# Específico para Android
flutter run -d android

# Específico para iOS
flutter run -d ios
```

**5. Verificar Análise Estática**

```bash
# Analisar código
flutter analyze

# Formatar código
dart format .

# Executar testes
flutter test
```

### Troubleshooting

| Problema | Solução |
|---|---|
| `flutter: command not found` | Adicione Flutter ao PATH: `export PATH="$PATH:~/flutter/bin"` |
| Erro de conexão com backend | Verifique se backend está rodando em `http://localhost:8080` |
| Erro de permissões (Android) | Execute `flutter clean` e `flutter pub get` novamente |
| Erro de certificado SSL | Verifique se backend está em HTTP (não HTTPS) em desenvolvimento |
| Emulador não encontrado | Execute `flutter emulators --launch <emulator_id>` |

---

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Siga os passos abaixo para manter a qualidade e consistência do projeto.

### Workflow de Contribuição

1. **Faça um fork** do projeto no GitHub
2. **Clone seu fork** localmente:
   ```bash
   git clone https://github.com/seu-usuario/vivalivre-app.git
   cd vivalivre-app
   ```

3. **Crie uma branch a partir de `develop`**:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feat/sua-feature
   ```
   
   Tipos de branch:
   - `feat/` — Nova funcionalidade
   - `fix/` — Correção de bug
   - `refactor/` — Refatoração de código
   - `docs/` — Documentação
   - `chore/` — Tarefas de manutenção

4. **Faça suas alterações** seguindo os padrões:
   - Código limpo e bem documentado
   - Testes unitários para novas funcionalidades (cobertura ≥ 70%)
   - Sem `print()` em produção (usar `debugPrint()` apenas em debug)
   - Sem `any`, `dynamic` sem type hints
   - Respeitar Material 3 theme

5. **Commit com mensagens semânticas**:
   ```bash
   git commit -m "feat(health): add symptom tracking feature"
   git commit -m "fix(auth): handle token expiration correctly"
   git commit -m "refactor(map): optimize PostGIS queries"
   ```

6. **Verifique a qualidade do código**:
   ```bash
   flutter analyze      # Sem erros
   dart format .        # Formatar código
   flutter test         # Testes passando
   flutter build apk    # Build sem erros
   ```

7. **Envie para seu fork**:
   ```bash
   git push origin feat/sua-feature
   ```

8. **Abra um Pull Request** para `develop`:
   - Descreva o que foi alterado
   - Inclua screenshots/vídeos se for UI
   - Referencie issues relacionadas (#123)
   - Aguarde revisão do @Reviewer

### Padrões de Código

#### BLoC Pattern
```dart
// ✅ CORRETO
class HealthBloc extends Bloc<HealthEvent, HealthState> {
  final IHealthRepository _repository;
  
  HealthBloc({required IHealthRepository repository})
      : _repository = repository,
        super(HealthInitial()) {
    on<FetchHealthEntries>(_onFetchHealthEntries);
  }
}

// ❌ ERRADO - Lógica de negócio na UI
class HealthPage extends StatefulWidget {
  void loadData() {
    final data = await http.get('/api/health');
  }
}
```

#### Nomes e Convenções
```dart
// ✅ Classes: PascalCase
class HealthEntry { }

// ✅ Funções/variáveis: camelCase
void fetchHealthEntries() { }
String userName = 'João';

// ✅ Constantes: camelCase
const int maxRetries = 3;

// ✅ Documentação de funções públicas
/// Carrega os registos de saúde do utilizador.
/// 
/// Retorna uma lista de [HealthEntry] ordenada por timestamp.
/// Lança [Exception] se a conexão falhar.
Future<List<HealthEntry>> getEntries(String userId) async { }
```

#### Testes
```dart
// ✅ Teste bem estruturado
void main() {
  group('HealthBloc', () {
    late HealthBloc healthBloc;
    late MockHealthRepository mockRepository;
    
    setUp(() {
      mockRepository = MockHealthRepository();
      healthBloc = HealthBloc(repository: mockRepository);
    });
    
    tearDown(() {
      healthBloc.close();
    });
    
    test('emits [HealthLoading, HealthEntriesLoaded] on FetchHealthEntries', () async {
      // Arrange
      when(mockRepository.getEntries('user123'))
        .thenAnswer((_) async => [testEntry]);
      
      // Act
      healthBloc.add(FetchHealthEntries('user123'));
      
      // Assert
      expect(
        healthBloc.stream,
        emitsInOrder([
          HealthLoading(),
          HealthEntriesLoaded([testEntry]),
        ]),
      );
    });
  });
}
```

### Definition of Done (DoD)

Antes de fazer PR, verifique:

- [ ] Código compila sem erros (`flutter analyze`)
- [ ] Testes passam (`flutter test`)
- [ ] Cobertura de testes ≥ 70%
- [ ] Commits semânticos e bem documentados
- [ ] Branch atualizada com `develop`
- [ ] Sem hard-coded strings (usar `strings.dart`)
- [ ] Responsivo (360px-2560px)
- [ ] Dark mode suportado
- [ ] Sem memory leaks (listeners dispostos)
- [ ] Screenshots/vídeos inclusos (se UI)

### Recursos Úteis

- [Flutter Documentation](https://flutter.dev/docs)
- [BLoC Library](https://bloclibrary.dev)
- [Clean Architecture](https://resocoder.com/flutter-clean-architecture)
- [AGENTS.md](./AGENTS.md) — Definição de papéis e responsabilidades
- [CONTRIBUTING.md](./CONTRIBUTING.md) — Guia detalhado de contribuição

---

## 📚 Documentação Adicional

- **[AGENTS.md](./AGENTS.md)** — Definição de papéis, responsabilidades e workflows de colaboração
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** — Guia detalhado de contribuição
- **[docs/](./docs/)** — Documentação técnica, ADRs e guias de arquitetura
- **[Backend VivaLivre](https://github.com/VivaLivre/vivalivre-backend)** — API REST em Go
- **[Admin Portal VivaLivre](https://github.com/VivaLivre/vivalivre-admin)** — Painel Administrativo Web em Flutter

## 📞 Suporte e Comunidade

- **Issues**: [GitHub Issues](https://github.com/VivaLivre/vivalivre-app/issues)
- **Discussões**: [GitHub Discussions](https://github.com/VivaLivre/vivalivre-app/discussions)
- **Email**: [contato@vivalivre.com](mailto:contato@vivalivre.com)

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

<div align="center">

Feito com 💙 por **Gabriel José de Souza** para a comunidade DII brasileira.

*"Toda pessoa com DII merece viver com liberdade e dignidade."*

[⬆ Voltar ao topo](#-vivalivre--aplicativo-mobile)

</div>
