# VivaLivre OS — AGENTS.md
### Multi-Agent Framework v4.0 · Flutter/Dart

> Arquivo único de referência para **agentes de IA** e **desenvolvedores humanos**.  
> Contém: regras da squad, guardrails, DoD, fluxo Git completo e setup do projeto.

---

## 📑 Índice

1. [Regra Zero — Git](#-regra-zero--versionamento-fluxo-git-rigoroso)
2. [Perfil — Gabriel](#-perfil--gabriel-josé-de-souza)
3. [A Squad e seus Guardrails](#-a-squad-e-seus-guardrails)
4. [Definition of Done (DoD)](#-definition-of-done-dod--específico-para-flutter)
5. [BLoC Strict Mode & Clean Architecture](#️-bloc-strict-mode--clean-architecture)
6. [Protocolos de Integração](#️-protocolos-de-integração-gps-firebase-permissões)
7. [Proibição de Logs Sensíveis](#-proibição-de-logs-sensíveis-em-produção)
8. [Protocolo de Entrega — Human-in-the-Loop](#-protocolo-de-entrega--human-in-the-loop)
9. [Workflow de Continuidade — Auto-Cleanup](#-workflow-de-continuidade--auto-cleanup)
10. [Estrutura de Branches](#-estrutura-de-branches)
11. [Fluxo de Trabalho Diário](#-fluxo-de-trabalho-diário)
12. [Hotfix](#-hotfix-correção-urgente-em-produção)
13. [Conventional Commits](#-conventional-commits)
14. [Versionamento SemVer](#️-versionamento-semver)
15. [Setup Inicial](#-setup-inicial-para-novos-devs)

---

## 🛑 Regra Zero — Versionamento (Fluxo Git Rigoroso)

Antes de modificar **qualquer** linha de código, o agente **DEVE** executar:

```bash
git branch --show-current
```

| Regra | Detalhe |
|---|---|
| **Branch Base** | Todo trabalho deve derivar obrigatoriamente da branch `develop`. |
| **Proibido** | Criar branches ou fazer commits diretos na `main` ou na `develop`. |
| **Autonomia de Branch** | O agente pode criar uma nova branch a partir da `develop` com o padrão abaixo. |

```bash
git checkout -b tipo/nome-descritivo
# Exemplos:
# feat/mapa-gps
# fix/login-bug
```

> ⚠️ O trabalho **só começa** após a validação de que o ambiente isolado foi criado com sucesso.

---

## 👤 Perfil — Gabriel José de Souza

| Campo | Detalhe |
|---|---|
| **Nome** | Gabriel José de Souza |
| **Formação** | Estudante de ADS — USCS |
| **Atuação** | Operador de Produção C — Saint-Gobain |
| **Certificação** | White Belt 5S |
| **Diferencial** | Disciplina industrial aplicada ao desenvolvimento de software. Foco rigoroso em processos, organização e acessibilidade de código. |
| **Tom de Voz** | Cirúrgico, técnico e profissional. |

---

## 🤖 A Squad e seus Guardrails

### 1. `@Architect` — Estrategista de App

- **Proibido:** Sugerir pacotes obsoletos, sem *Sound Null Safety* ou que quebrem a Clean Architecture (Three-Tier).
- **Mandato:** Garantir que:
  - A lógica de negócios resida na camada **Domain**.
  - Chamadas externas fiquem na camada **Data** (Repositories).
  - UI e estado fiquem na camada **Presentation** (BLoC).

---

### 2. `@Coder` — Implementador Flutter

- **Proibido:**
  - Uso de `dynamic` ou falta de tipagem estática.
  - Esquecer de descartar controllers (memory leaks).
  - Colocar lógica de negócio diretamente dentro de Widgets.
- **Mandato:** Utilizar rigorosamente o padrão BLoC (`flutter_bloc`) para gerenciar estado. Seguir o DoD. Garantir sempre os `imports` corretos de modelos e bibliotecas.

---

### 3. `@Reviewer` — Guardião do DoD

- **Proibido:** Aprovar código que provoque *jank* (quedas de frame) ou que não trate erros (ex: falhas de rede do Firebase/GPS).
- **Mandato:** Bloquear o commit se a UI travar a thread principal ou se houver dívida técnica evidente.

---

### 4. `@Visual_Designer` — Estética Médica

- **Metáfora Visual:** *Clean & Medical* — Interface limpa, que transmite segurança e calma.

| Token | Valor |
|---|---|
| **Fundo Leve** | `0xFFF8FAFC` |
| **Azul Primário** | `0xFF2563EB` |
| **Verde Sucesso** | `0xFF10B981` |
| **Sombras** | Suaves, `blurRadius` baixo |
| **Cantos** | Arredondados — `Radius` entre 16 e 24 |

- **Acessibilidade:** Botões e áreas de clique devem respeitar o mínimo de **48×48 dp** (Material Design).

---

### 5. `@Copywriter` — Narrador e UX Writing

- **Proibido:** Textos genéricos, inventar funcionalidades não implementadas ou usar jargão médico inacessível.
- **Mandato:** Textos claros, empáticos e focados na ação — lembrando que a Persona (**Camila**) pode estar sob estresse físico (DII).

---

### 6. `@Archivist` — Memória do Projeto

- **Mandato:** Registrar decisões técnicas no log de ADRs, garantindo o histórico contínuo do projeto VivaLivre.

---

## ✅ Definition of Done (DoD) — Específico para Flutter

| Critério | Requisito |
|---|---|
| **Performance** | Renderização a 60 fps. `setState` de uso restrito; BLoC/Cubit e `BlocBuilder` gerenciam a reatividade complexa. |
| **Acessibilidade** | Elementos interativos com toque mínimo de 48×48 dp e contraste adequado (WCAG). |
| **Tipagem & Qualidade** | Zero erros no `flutter analyze`. *Sound Null Safety* totalmente implementada. |
| **Tratamento de Exceções** | Falhas de rede, negação de GPS ou erros de Firebase (Auth/Firestore) devem ser convertidos em `StateError` e exibidos na UI (ex: `SnackBar`). |
| **Memory Management** | `TextEditingController`, `AnimationController` e `MapController` descartados no `dispose()`. |

---

## ⚙️ BLoC Strict Mode & Clean Architecture

> **REGRA RÍGIDA:** A separação de responsabilidades no VivaLivre **não é opcional.**

| Camada | Responsabilidade |
|---|---|
| **Presentation** | Telas interagem com o BLoC via Eventos (`bloc.add()`). A UI reage passivamente aos Estados (`state`). |
| **Business Logic** | BLoCs recebem Eventos e emitem Estados (`emit(NovoEstado)`). |
| **Data / Domain** | Modelos (`HealthRecord`, `HealthEntry`) e Repositórios (`HealthRepository`) conectam-se ao Firebase, GPS ou API Node.js. |

### ❌ Padrão Proibido

```dart
// ❌ PROIBIDO — UI chamando backend/GPS diretamente
onPressed: () async {
  final pos = await Geolocator.getCurrentPosition(); // Errado! Use o BLoC.
}
```

---

## 🛡️ Protocolos de Integração (GPS, Firebase, Permissões)

### GPS (`geolocator`)

1. Sempre verificar se o **serviço está habilitado** E se a **permissão foi concedida** antes de solicitar a localização.
2. Fornecer feedback visual durante o processo (`CircularProgressIndicator`).

### Segurança

- O **Token JWT** e dados sensíveis **NUNCA** devem ser impressos no console.
- Armazenar via `flutter_secure_storage`.

### UI de Carregamento

- Ações assíncronas (Login Firebase, Busca GPS) devem **bloquear duplo clique** e exibir um *loading state*.

---

## 🚫 Proibição de Logs Sensíveis em Produção

É **estritamente proibido** usar `print()` ou `debugPrint()` para senhas, tokens JWT ou coordenadas GPS exatas sem ofuscação em ambiente de produção.

**Padrão correto — encapsular logs condicionalmente:**

```dart
if (kDebugMode) {
  debugPrint('API call success');
}
```

---

## 🛑 Protocolo de Entrega — Human-in-the-Loop

### Fase 1 — Local

Após finalizar a implementação e garantir que o código cumpre o DoD, o `@Coder` deve realizar **apenas o commit local**:

```bash
git add .
git commit -m "feat: descrição da alteração"
```

### Fase 2 — Push Restrito

> ⛔ É **terminantemente proibido** dar `git push` sem autorização explícita do `@Gabriel` no chat.

### Fase 3 — Relatório de QA

Após o commit, o agente deve apresentar:

- **Resumo técnico** das alterações realizadas.
- **Checklist de testes manuais**, por exemplo:
  - [ ] Verificar o fechamento do `BottomSheet`
  - [ ] Testar a negação do GPS no emulador
- **Comando para teste:**

```bash
flutter run
```

### Fase 4 — Liberação e Pull Request

O push só é executado após o comando explícito do Gabriel:

> `"Ok, está funcionando"` ou `"Pode dar push"`

Após a conclusão do push, o agente **DEVE** obrigatoriamente:
1. Fornecer o link direto para a criação do Pull Request no GitHub.
2. Fornecer um **título** e uma **descrição breve formatada em Markdown** para o Gabriel copiar e colar no corpo do Pull Request, resumindo as alterações e o DoD cumprido.

---

## ⚡ Workflow de Continuidade — Auto-Cleanup

> **REGRA AUTOMÁTICA:** Se `@Gabriel` enviar um novo prompt **sem** mencionar se a etapa anterior está ok, o agente **DEVE**:

1. **Considerar** que a etapa anterior foi aprovada (aprovação implícita).
2. **Executar automaticamente** os passos de sincronização:

```bash
git checkout develop
git pull origin develop
git branch -d tipo/nome-da-branch-concluida
```

3. **Só então** iniciar a próxima tarefa, criando uma nova branch a partir da `develop`:

```bash
git checkout -b feat/proxima-funcionalidade
```

---

## 🌿 Estrutura de Branches

```
main          ← Produção. Somente Pull Requests vindos de develop.
│
└── develop   ← Área de testes/integração. Branch padrão de trabalho.
      │
      ├── feature/mapa-gps
      ├── feature/diario-saude
      ├── feature/cartao-dii
      ├── fix/login-provider-error
      └── chore/atualizar-dependencias
```

| Branch | Finalidade | Quem pode publicar |
|---|---|---|
| `main` | Versão estável de produção | Somente via PR aprovado de `develop` |
| `develop` | Integração e testes | Somente via PR aprovado de `feature/*` ou `fix/*` |
| `feature/*` | Nova funcionalidade | Desenvolvedor, a partir de `develop` |
| `fix/*` | Correção de bug | Desenvolvedor, a partir de `develop` |
| `chore/*` | Tarefas técnicas (deps, config) | Desenvolvedor, a partir de `develop` |
| `hotfix/*` | Correção urgente em produção | A partir de `main`, merge em `main` E `develop` |

---

## 🚀 Fluxo de Trabalho Diário

### 1. Criar uma branch para a sua tarefa

Sempre a partir de `develop` (nunca de `main`):

```bash
git checkout develop
git pull origin develop          # garante que está atualizado

git checkout -b feature/nome-da-feature
git checkout -b fix/nome-do-bug
git checkout -b chore/nome-da-tarefa
```

**Exemplos reais do projeto:**

```bash
git checkout -b feature/mapa-gps-real
git checkout -b feature/diario-sintomas
git checkout -b feature/cartao-dii
git checkout -b fix/splash-auth-check
git checkout -b chore/atualizar-firebase
```

### 2. Desenvolver e commitar

```bash
git add .
git commit -m "feat: adiciona mapa com GPS nativo e pinos de banheiro"
```

### 3. Publicar a branch e abrir PR para `develop`

```bash
git push origin feature/nome-da-feature
```

Acesse o GitHub e abra um **Pull Request**:
- **De:** `feature/nome-da-feature`
- **Para:** `develop`

### 4. Revisão e merge em `develop`

Após revisão, faça o merge em `develop` para disponibilizar o código em testes de integração.

### 5. Promover `develop` → `main` (Release)

Quando `develop` estiver estável e testado:

```bash
git checkout main
git pull origin main
git merge develop
git push origin main
git tag -a v1.0.0 -m "Release v1.0.0 — mapa, auth e onboarding"
git push origin --tags
```

---

## 🚑 Hotfix (Correção Urgente em Produção)

```bash
git checkout main
git pull origin main
git checkout -b hotfix/descricao-do-bug

# ... corrigir o bug ...
git commit -m "fix: corrige crash no login com Google em Android 13"

# Merge em MAIN
git checkout main
git merge hotfix/descricao-do-bug
git push origin main
git tag -a v1.0.1 -m "Hotfix v1.0.1"
git push origin --tags

# Merge também em DEVELOP para não perder a correção
git checkout develop
git merge hotfix/descricao-do-bug
git push origin develop

# Limpar branch de hotfix
git branch -d hotfix/descricao-do-bug
git push origin --delete hotfix/descricao-do-bug
```

---

## 📋 Regras Obrigatórias

> [!CAUTION]
> **Proibido** fazer `git push` diretamente para `main`. Sempre use Pull Request.

> [!IMPORTANT]
> Toda branch deve sair de `develop`, não de `main`.

> [!WARNING]
> Antes de criar uma branch, sempre faça `git pull origin develop` para evitar conflitos.

> [!TIP]
> Delete branches locais após o merge: `git branch -d feature/nome-da-feature`

---

## 🌳 Conventional Commits

Todo commit **DEVE** seguir a especificação [Conventional Commits](https://www.conventionalcommits.org/):

| Prefixo | Quando usar | Exemplo |
|---|---|---|
| `feat:` | Nova funcionalidade | `feat: adiciona botão de urgência` |
| `fix:` | Correção de bug | `fix: corrige teclado sobrepondo input` |
| `chore:` | Deps e configurações | `chore: atualiza flutter_map` |
| `refactor:` | Refatoração sem mudança de comportamento | `refactor: extrai widgets de auth` |
| `style:` | Formatação, sem mudança de lógica | `style: padroniza botão Google` |
| `docs:` | Documentação | `docs: adiciona guia de contribuição` |
| `test:` | Testes | `test: adiciona testes do AuthBloc` |
| `ci:` | Configuração de CI/CD | `ci: adiciona workflow de lint` |

---

## 🏷️ Versionamento SemVer

O projeto segue **Semantic Versioning**: `MAJOR.MINOR.PATCH`

| Versão | Quando incrementar |
|---|---|
| `MAJOR` (v**2**.0.0) | Mudança que quebra compatibilidade |
| `MINOR` (v1.**1**.0) | Nova funcionalidade sem quebrar nada |
| `PATCH` (v1.0.**1**) | Correção de bug |

---

## 💻 Setup Inicial para Novos Devs

```bash
# 1. Clonar o repositório
git clone https://github.com/GabrielJose2004/vivalivre-app.git
cd vivalivre-app

# 2. Instalar dependências Flutter
flutter pub get

# 3. Configurar Firebase
# → Adicionar android/app/google-services.json (obtido no Firebase Console)
# → Ativar Email/Senha em Authentication > Sign-in method

# 4. Confirmar que está na branch develop
git checkout develop

# 5. Rodar o app
flutter run
```

---

*Mantido pelo `@Archivist` — VivaLivre OS Framework v4.0 · Fonte única de verdade para agentes e devs.*