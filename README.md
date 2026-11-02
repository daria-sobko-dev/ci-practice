# ci-practice

Учебный проект для практики CI/CD. Маленькое приложение на NestJS (TypeScript) с тестами, Dockerfile и готовыми пайплайнами для **GitHub Actions** и **GitLab CI**.

Приложение отвечает на два адреса:

- `GET /` → `Hello World!`
- `GET /health` → `{"status":"ok","uptime":...}` (health check для балансировщиков и мониторинга)

## Структура

```
ci-practice/
├── src/                       # код приложения
│   ├── main.ts                # точка входа, порт 3000
│   ├── app.module.ts
│   ├── app.controller.ts      # маршруты / и /health
│   ├── app.service.ts
│   └── app.controller.spec.ts # unit-тесты
├── test/
│   └── app.e2e-spec.ts        # e2e-тесты (настоящие HTTP-запросы)
├── Dockerfile                 # multi-stage сборка образа
├── .dockerignore
├── .github/workflows/ci.yml   # пайплайн GitHub Actions
├── .gitlab-ci.yml             # пайплайн GitLab CI
└── package.json               # зависимости и команды
```

## 1. Запуск на своём компьютере

Нужен Node.js 22 (на Маке: `brew install node@22`).

```bash
npm ci                 # установить зависимости по package-lock.json
npm run start:dev      # запустить с автоперезагрузкой
```

Открой http://localhost:3000 и http://localhost:3000/health

Команды, которые выполняет пайплайн:

```bash
npm run lint:ci        # проверка стиля кода
npm test               # unit-тесты
npm run test:e2e       # e2e-тесты
npm run build          # сборка в папку dist/
```

## 2. Запуск в Docker

```bash
docker build -t ci-practice .
docker run -d --name ci-practice -p 3000:3000 ci-practice
curl localhost:3000/health
docker ps              # через ~30 секунд в STATUS появится (healthy)
docker logs ci-practice
docker rm -f ci-practice
```

## 3. Загрузка на GitHub и первый пайплайн

1. Создай на github.com новый репозиторий `ci-practice`, **без** README и .gitignore.
2. В папке проекта:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin git@github.com:ТВОЙ_GITHUB/ci-practice.git
   git push -u origin main
   ```
3. Открой вкладку **Actions** в репозитории и смотри, как выполняется пайплайн.

Что делает `.github/workflows/ci.yml`:

- **job `test`** — при каждом push и pull request: установка зависимостей, линтер, unit- и e2e-тесты, сборка;
- **job `docker`** — только после успешного `test` и только для ветки `main`: собирает образ под amd64 и arm64 и загружает его в **GitHub Container Registry** (`ghcr.io`).

Секреты настраивать не нужно: для `ghcr.io` GitHub сам выдаёт временный токен `GITHUB_TOKEN`.

Готовый образ появится в репозитории справа, в блоке **Packages**. По умолчанию он приватный.

## 4. Задания

### Чинить (maintaining)
Делай по одному: сломай → push → найди ошибку в логах Actions → почини → push.

1. **Линтер.** Добавь в `src/app.service.ts` неиспользуемую переменную `const unused = 1;`. Какой шаг упадёт и что пишет лог?
2. **Unit-тест.** Поменяй `'Hello World!'` на `'Hello DevOps!'` в `app.service.ts`. Упадут два теста: какие и почему? Почини, исправив тесты.
3. **Сборка.** Сделай опечатку в TypeScript: `retrn` вместо `return`.
4. **Dockerfile.** Поменяй `node:22-alpine` на `node:22-alpinee`. Обрати внимание: job `test` пройдёт, а упадёт `docker`.
5. **Зависимости.** Удали `package-lock.json` и запушь. Что скажет `npm ci`?

### Улучшать (improving)
6. Добавь в README бейдж статуса пайплайна:
   `![CI](https://github.com/ТВОЙ_GITHUB/ci-practice/actions/workflows/ci.yml/badge.svg)`
7. Запусти пайплайн вручную кнопкой **Run workflow** (это `workflow_dispatch`).
8. Сделай ветку `feature/hello`, измени текст, открой **pull request**. Убедись, что job `docker` в PR не запускается, и разберись, какая строка в `ci.yml` за это отвечает.
9. Добавь новый маршрут `GET /version`, который возвращает `{"version":"0.0.1"}`, и e2e-тест к нему.
10. Добавь шаг сканирования образа на уязвимости (например, Trivy) после сборки.
11. Сравни время пайплайна до и после второго запуска: работают ли кеши `cache: npm` и `cache-from: type=gha`?

## 5. Тот же проект в GitLab CI

1. Создай проект на gitlab.com и запушь туда этот же код.
2. Пайплайн из `.gitlab-ci.yml` запустится сам: **Build → Pipelines**.
3. Образ появится в **Deploy → Container Registry** проекта.

Логины к registry GitLab подставляет сам через переменные `CI_REGISTRY_USER` и `CI_REGISTRY_PASSWORD`. Чтобы пользоваться бесплатными общими раннерами на gitlab.com, может понадобиться подтвердить аккаунт.

| GitHub Actions | GitLab CI |
| --- | --- |
| `.github/workflows/*.yml` | `.gitlab-ci.yml` |
| `jobs` → `steps` | `stages` → `jobs` → `script` |
| `needs: test` | порядок задаётся `stages` |
| `if: github.ref == 'refs/heads/main'` | `rules: - if: $CI_COMMIT_BRANCH == "main"` |
| `secrets.GITHUB_TOKEN` | `$CI_REGISTRY_PASSWORD` |
| `github.sha` | `$CI_COMMIT_SHORT_SHA` |
