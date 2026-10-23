# opencode для Android (Termux)

Экспериментальная ветка [opencode](https://opencode.ai) под Android
**aarch64 / Termux**: дополнительные исправления наблюдения за файлами и
инструменты для сборки и разработки прямо на телефоне. Без proot и root.

**Это не независимая реализация Android-порта.** Ветка использует патченный Bun,
OpenTUI и готовые PTY-компоненты из экосистемы
[`bd-loser`](https://github.com/bd-loser). Для этой ветки доступны
[готовые экспериментальные сборки](https://github.com/kukelivan/opencode-android/releases)
и сборка из исходников.

Эта ветка — исходники, из которых получается такая сборка. Это не руководство
по самому opencode: **если вы ещё не пользуетесь opencode, начните с
[оригинального README](https://github.com/anomalyco/opencode#readme)**, а сюда
возвращайтесь за android-спецификой.

- Оригинальный проект: [`anomalyco/opencode`](https://github.com/anomalyco/opencode)
- Другой проект с готовыми пакетами: [`bd-loser/opencode-bionic`](https://github.com/bd-loser/opencode-bionic)
- Патченный рантайм Bun: [`bd-loser/bun-termux`](https://github.com/bd-loser/bun-termux)

## Ветки

| Ветка | Содержимое |
| --- | --- |
| `android` (по умолчанию) | Этот порт. Android-патчи + сборка в `termux/`. |
| `dev` | Копия upstream `dev` на момент создания форка; автоматическая синхронизация не настроена. |

## Отличия от `bd-loser/opencode-bionic`

**Для обычного использования проще установить готовый пакет `bd-loser`.**
Эта ветка нужна тем, кто хочет собирать, проверять или дорабатывать исходники
на Android и использовать дополнительные изменения, перечисленные ниже.

| Возможность | Эта ветка | `bd-loser/opencode-bionic` |
| --- | --- | --- |
| Установка | Готовые `.deb` и бинарники в релизах или ручная сборка; своего apt-репозитория нет | Готовые бинарники, `.deb`, пакетный репозиторий, каналы stable/beta/dev |
| Рекурсивное наблюдение за файлами | Добавлен Android-backend на `fs.watch` из Bun | В проверенном патче Parcel отключён; отдельного Android-backend нет |
| Разработка на телефоне | Сборка ast-grep и нативного TypeScript, последовательный typecheck без Turborepo, адаптация проверок Astro | Аналогичного набора в проверенной ветке не найдено |
| Исходники в общей памяти Android | Автоматическая сборочная копия во внутренней памяти с восстановлением симлинков | Основная автоматизированная сборка идёт в окружении Termux через Docker на CI |
| Обновления и релизы | Поддерживаются вручную | Есть автоматизированная сборка и публикация пакетов |

Общая основа: Bun 1.4.3 patched, `@androidtui/*` 0.6.6,
`bun-pty` 0.4.11 и PTY-сервис 0.2.0 от `bd-loser`. Отключение bytecode,
code splitting, встроенного веб-интерфейса и неподходящих установочных хуков
также не является уникальным преимуществом этой ветки.

Сравнение выполнено **23 октября 2026 года** по ветке
[`dev` проекта `bd-loser` на коммите `dddf323`](https://github.com/bd-loser/opencode-bionic/tree/dddf323afe0b953706d869a5bb44b706c9bd2413)
и опубликованному dev-релизу `v2.1.2-dev.c9b5a9ff`. База этой ветки —
`c93aaae371`, на 53 коммита новее базы того релиза. Это сравнение исходников
и сборочных скриптов, **не сравнительное тестирование бинарников** и не
гарантия большей стабильности.

Важная деталь: комментарий в проверенном патче `bd-loser` упоминает polling
при отсутствии Parcel. Однако в исходниках базы указанного dev-релиза
рекурсивная подписка без Parcel возвращает `undefined`. Эта ветка добавляет
реальную подписку через `fs.watch`; это не означает, что в другом проекте
не работает вообще никакое отслеживание файлов.

## Требования

- Android на **aarch64** (ARM64). Termux из [F-Droid](https://f-droid.org/packages/com.termux/)
  или [GitHub releases](https://github.com/termux/termux-app/releases).
  Другие варианты установки Termux здесь не проверялись.
- [Патченный Bun **1.4.3**](https://github.com/bd-loser/bun-termux). Стоковый Bun
  не содержит нужных исправлений. Скрипт проверяет номер `1.4.3`, но эта
  проверка сама по себе не отличает патченную сборку от обычной.
- Для сборки: `git`, `curl`, `tar`, `file`, `python`, `ripgrep`.
- Для инструментов разработки: `nodejs-lts`, `rust`, `golang`, `clang`.

## Установка

### Готовый пакет этой ветки — рекомендуемый способ

Для обычной установки не нужны Bun, компиляторы и исходники. Откройте Termux
на ARM64-устройстве и выполните:

```bash
pkg install curl
mkdir -p "$HOME/Downloads/opencode-android-2.1.2-1"
cd "$HOME/Downloads/opencode-android-2.1.2-1"
curl -fLO https://github.com/kukelivan/opencode-android/releases/download/v2.1.2-android.1/opencode-android_2.1.2~android.1_aarch64.deb
curl -fLO https://github.com/kukelivan/opencode-android/releases/download/v2.1.2-android.1/SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS && apt install ./opencode-android_2.1.2~android.1_aarch64.deb
opencode --version
opencode --standalone
```

Пакет называется `opencode-android`, команда после установки — `opencode`.
Зависимость `ripgrep` устанавливается через apt. Экспериментальный релиз
`v2.1.2-android.1` содержит бинарник с версией
`2.1.2-dev.android.ed9333bc5b`, собранный из коммита `ed9333bc5b`.
Проверены сборка, запуск `--version`, `--help` и содержимое пакета; полный
набор проверок для этого релиза повторно не запускался.

**Если opencode уже установлен:** пакеты `opencode-android` и `opencode`
конфликтуют, поскольку устанавливают одну команду. Apt может предложить удалить
старый пакет — внимательно проверьте план перед подтверждением. Если бинарник
раньше копировался вручную, сохраните его отдельно: установка `.deb` не делает
резервную копию. Не запускайте замену из единственной активной сессии opencode;
используйте отдельную сессию Termux и затем перезапустите приложение.
Команды выше не удаляют конфигурацию или историю, но резервная копия данных
перед переходом с другой версии рекомендуется.

Обновления публикуются вручную на
[странице релизов](https://github.com/kukelivan/opencode-android/releases).
Не используйте встроенное `opencode upgrade` для этой сборки: оно не настроено
на релизы этого форка. Для удаления пакета: `apt remove opencode-android`.

### Готовые пакеты другого проекта

Если не нужны дополнительные изменения этой ветки, используйте
[инструкцию `bd-loser`](https://github.com/bd-loser/opencode-bionic#install).
Для версии 2.x у него предусмотрен канал beta:

```bash
curl -fsSL https://raw.githubusercontent.com/bd-loser/opencode-bionic/main/repo-setup.sh | OPENCODE_CHANNEL=beta bash
```

**Это устанавливает пакет `bd-loser`, а не сборку этого форка.** По данным
сравнения, установка без выбора канала использует stable 1.x. Каналы и версии
могут меняться — сверяйтесь с инструкцией автора. Команды с `curl | bash`
скачивают и выполняют сторонний скрипт; перед запуском ознакомьтесь с ним.

### Сборка именно этой ветки

```bash
pkg update
pkg install git curl tar file python ripgrep

# Патченный Bun, ставится в $PREFIX/bin
curl -fsSL https://raw.githubusercontent.com/bd-loser/bun-termux/main/scripts/install.sh | bash
bun --version   # должно быть 1.4.3

git clone -b android https://github.com/kukelivan/opencode-android.git
cd opencode-android

# Сборка: дерево копируется в $TMPDIR, ставятся зависимости, встраиваются
# android-бинарники PTY, на выходе dist/opencode-android-arm64
bash termux/build.sh

# Установка в $PREFIX/bin (старый бинарник бэкапится, проверяется наличие rg)
bash termux/install.sh
opencode --version
```

Установщик Bun по ссылке может со временем перейти на новую версию. Если
установлена не 1.4.3, используйте закреплённый
[релиз `v1.4.3-patched`](https://github.com/bd-loser/bun-termux/releases/tag/v1.4.3-patched),
а не меняйте проверку версии в сборочном скрипте.

Исходники могут лежать на общей памяти, а вот **сборка — нет**: она
автоматически переносится во внутреннюю память Termux, потому что
`/storage/emulated/0` не поддерживает симлинки в `node_modules` и бит
исполнения. `build.sh` записывает итоговый `bun.lock` обратно в исходники.

### Запуск

```bash
opencode               # фоновый сервер под управлением upstream
opencode --standalone  # собственный сервер в этом же процессе
```

`--standalone` удобен для изоляции от общего фонового сервера. Android может
остановить любой из этих процессов, в том числе при ограничениях батареи.
После установки новой сборки перезапустите opencode.

## Что изменено под Android

| Путь | Изменение |
| --- | --- |
| `packages/cli/script/build.ts` | На Android требует `--target=opencode-linux-arm64`, отключает bytecode и code splitting, подменяет биндинг Parcel watcher, которого нет под Bionic. |
| `packages/core/src/filesystem/watcher.ts` | На Android используется рекурсивный `fs.watch` из Bun с прежней фильтрацией игнорируемых путей. |
| `package.json` | OpenTUI заменён на сборки `@androidtui/*` плюс `@opentui/core-android-arm64`; `typecheck` работает без Turborepo; хуки `postinstall`/`prepare` убраны; списка trusted dependencies нет. |
| `bun.lock` | Лок-файл под всё перечисленное. |
| `packages/posts/astro.config.ts`, `services/www/astro.config.ts` | Адаптер Cloudflare подгружается лениво, чтобы `astro check` не тянул `workerd`. |
| `termux/` | `build.sh`, `install.sh`, `check.sh`, `setup-tools.sh` и адаптеры нативных инструментов. Подробности — в [`termux/README.md`](termux/README.md). |

## Ограничения

- **Проверено на ARM64 в Termux.** Сборочный скрипт требует `aarch64`.
  x86_64 и другие оболочки не поддерживаются этими скриптами; запуск
  в эмуляторах отдельно не проверялся.
- **Бинарник обязан лежать во внутренней памяти.** Android не даёт выполнять
  файлы из `/storage/emulated/0` и `/sdcard`; `termux/install.sh` ставит
  `$PREFIX/bin/opencode`.
- **Нет веб-интерфейса.** Сборка идёт с `--skip-web-ui`: только TUI, CLI и
  HTTP API-сервер, без встроенных веб-ассетов.
- **Нет Parcel watcher.** Под Bionic для него нет биндинга, поэтому рекурсивное
  отслеживание работает на `fs.watch` из Bun с собственной фильтрацией путей.
  Полная эквивалентность Parcel не гарантируется; все события передаются
  как `update`, без разделения на создание, изменение и удаление.
- **Нет bytecode и code splitting** в android-бинарнике — ограничения
  `bun --compile` на этой платформе.
- **Нет Turborepo.** Android-бинарника для него не существует, поэтому
  `bun run typecheck` последовательно запускает `typecheck` каждого воркспейса.
  Результат корректный, но медленнее — зато предсказуемо по памяти.
- **Нет `workerd`.** У Cloudflare нет android-сборки: `astro check` работает, а
  сборку сайтов для деплоя нужно запускать в окружении с поддержкой Cloudflare.
- **Нативные инструменты собираются из исходников.** `ast-grep` 0.44.0 и
  нативный компилятор TypeScript 7.0.2 компилируются под Bionic в
  `$HOME/.local/share/opencode-termux-tools`; в TypeScript внесён патч, потому
  что Android убивает процесс на `fanotify_init`.
- **Поиску нужен ripgrep из Termux** (`pkg install ripgrep`) вместо встроенного
  glibc-бинарника.
- **Хуки `postinstall` / `prepare` отключены**: `fix-node-pty` рассчитан только
  на Linux, а husky требует рабочих git-хуков.
- **Закреплённая база, а не всегда свежий upstream.** Ветка использует
  OpenTUI 0.6.6. На дату сравнения upstream уже перешёл на 0.6.8, а
  соответствующие сборки `@androidtui` ещё не были опубликованы. Обновление
  требует проверки совместимости, а не только разрешения конфликтов Git.
- **Обновление пакетов может затереть бинарник.** `pkg upgrade` способен
  перезаписать `$PREFIX/bin/opencode`; сохраняйте бэкап с меткой времени,
  который печатает `install.sh`.

## Разработка

`termux/check.sh` готовит внутреннюю рабочую копию, собирает нативные
инструменты и прогоняет полный набор проверок:

```bash
pkg install nodejs-lts rust golang clang
bash termux/check.sh

# внутри напечатанной рабочей копии:
bun run test:lint-rules
bun run test:effect-simplification-rules
```

В [`termux/README.md`](termux/README.md) зафиксированы результаты прежней
проверки на устройстве: `bun run check`, проверки правил линтера и проверки
Astro. Это не автоматическая гарантия для будущих изменений; при обновлении
документации проверки повторно не запускались. Предупреждения линтера из
upstream не подавляются. После очередного `bun install` повторите `bun termux/link-tools.ts`,
чтобы восстановить ссылки на android-инструменты.

## Обновление

Чтобы получить изменения этой Android-ветки после клонирования:

```bash
git switch android
git pull --ff-only
```

Затем повторите сборку и установку. Команды рассчитаны на новый клон из
инструкции выше; в существующей рабочей копии проверьте адреса `git remote -v`.

Обновление **базы upstream** — отдельная задача для сопровождающего ветки.
В новом клоне можно добавить оригинальный репозиторий:

```bash
git remote add upstream https://github.com/anomalyco/opencode.git
git fetch upstream dev
```

Не выполняйте ребейз на свежий `upstream/dev` вслепую. Сначала проверьте версии
OpenTUI и Android-зависимостей. Сохранение старых пинов при конфликте не
гарантирует совместимость с новым кодом; после переноса нужны сборка и проверки.

### Подготовка пакета сопровождающим

После сборки `bash termux/build.sh`:

```bash
bash termux/package.sh '2.1.2~android.1'
```

Скрипт создаёт `.deb` в `dist/release/`, но не устанавливает его и не публикует
релиз. Требуется `dpkg-deb`; временная упаковка выполняется во внутреннем
`$TMPDIR`. Файлы из `dist/` не добавляются в Git — готовые сборки размещаются
в приложениях к релизам GitHub.

## Закреплённые версии

| Компонент | Версия |
| --- | --- |
| База upstream | `c93aaae371` (2.1.2, `dev`) |
| Bun | 1.4.3 patched (`bd-loser/bun-termux`) |
| OpenTUI | `@androidtui/*` 0.6.6 |
| `bun-pty` | 0.4.11 |
| `opencode-pty` | 0.2.0 |
| `ast-grep` | 0.44.0 |
| Нативный TypeScript | 7.0.2 |

## Лицензия

MIT, см. [LICENSE](LICENSE). Копирайт upstream сохранён без изменений.

Это неофициальный порт, не связанный с мейнтейнерами opencode и не
поддерживаемый ими.
