# 🤝 Guia de Contribuição — VivaLivre

Este documento define o fluxo de trabalho Git obrigatório para todos que desenvolvem no VivaLivre. **Nenhum código vai direto para a `main`.**

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

# Escolha o prefixo correto:
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
git checkout -b chore/atualizar-api-rest
```

### 2. Desenvolver e commitar

Use mensagens de commit no padrão **Conventional Commits**:

```bash
git add .
git commit -m "feat: adiciona mapa com GPS nativo e pinos de banheiro"
git commit -m "fix: corrige erro de Provider na navegação do onboarding"
git commit -m "chore: atualiza dio para 5.4.0"
git commit -m "docs: adiciona guia de contribuição"
git commit -m "style: padroniza botão Google nas telas de auth"
git commit -m "refactor: extrai widgets de auth para auth_widgets.dart"
git commit -m "test: adiciona testes unitários do AuthBloc"
```

| Prefixo | Quando usar |
|---|---|
| `feat:` | Nova funcionalidade |
| `fix:` | Correção de bug |
| `chore:` | Atualização de dependências, configurações |
| `docs:` | Mudanças na documentação |
| `style:` | Formatação, sem mudança de lógica |
| `refactor:` | Refatoração de código |
| `test:` | Adição ou correção de testes |
| `ci:` | Configuração de CI/CD |

### 3. Publicar a branch e abrir PR para `develop`

```bash
git push origin feature/nome-da-feature
```

Em seguida, acesse o GitHub e abra um **Pull Request**:
- **De:** `feature/nome-da-feature`
- **Para:** `develop`
- Descreva o que foi feito no PR

### 4. Revisão e merge em `develop`

Após revisão (ou auto-aprovação em projeto solo), faça o merge em `develop`. Isso disponibiliza o código para testes de integração.

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

Ou via Pull Request no GitHub: `develop` → `main`.

---

## 🚑 Hotfix (Correção Urgente em Produção)

Quando há um bug crítico em produção que não pode esperar o ciclo normal:

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

# Deletar branch de hotfix
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

## 🏷️ Versionamento (SemVer)

O projeto segue **Semantic Versioning**: `MAJOR.MINOR.PATCH`

| Versão | Quando incrementar |
|---|---|
| `MAJOR` (v**2**.0.0) | Mudança que quebra compatibilidade |
| `MINOR` (v1.**1**.0) | Nova funcionalidade sem quebrar nada |
| `PATCH` (v1.0.**1**) | Correção de bug |

---

## 💻 Setup Inicial para Novos Devs

```bash
# 1. Clonar
git clone https://github.com/GabrielJose2004/vivalivre-app.git
cd vivalivre-app

# 2. Instalar dependências Flutter
flutter pub get

# 3. Configurar Backend
# → Certifique-se que o backend Go está rodando localmente (http://localhost:8080)
# → O ApiClient do app detectará automaticamente o host correto (10.0.2.2 para Android Emulator)

# 4. Confirmar que está na branch develop
git checkout develop

# 5. Rodar o app
flutter run
```
