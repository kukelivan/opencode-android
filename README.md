# opencode для Android (Termux)

Нативная сборка [opencode](https://opencode.ai) под Android **aarch64 / Bionic**,
работающая в Termux. Без proot, chroot, root и glibc.

Эта ветка — исходники, из которых получается такая сборка. Это не руководство
по самому opencode: **если вы ещё не пользуетесь opencode, начните с
[оригинального README](https://github.com/anomalyco/opencode#readme)**, а сюда
возвращайтесь за android-спецификой.

- Оригинальный проект: [`anomalyco/opencode`](https://github.com/anomalyco/opencode)
- Готовые бинарники на том же стеке: [`bd-loser/opencode-bionic`](https://github.com/bd-loser/opencode-bionic)
- Патченный рантайм Bun: [`bd-loser/bun-termux`](https://github.com/bd-loser/bun-termux)

## Ветки

| Ветка | Содержимое |
| --- | --- |
| `android` (по умолчанию) | Этот порт. Android-патчи + сборка в `termux/`. |
| `dev` | Чистое зеркало upstream `dev`, база для ребейза. |

## Требования

- Android на **aarch64** (ARM64). Termux из [F-Droid](https://f-droid.org/packages/com.termux/)
  или [GitHub releases](https://github.com/termux/termux-app/releases) — версия из
  Play Store заброшена и не подойдёт.
- [Патченный Bun **1.4.3**](https://github.com/bd-loser/bun-termux). Стоковый Bun
  не содержит нужных исправлений, и `termux/build.sh` на другой версии просто
  откажется работать.
- Для сборки: `git`, `curl`, `tar`, `file`, `python`, `ripgrep`.
- Для инструментов разработки: `nodejs-lts`, `rust`, `golang`, `clang`.

## Установка

### Готовый бинарник

Если нужен просто работающий `opencode`, не собирайте его сами:

```bash
curl -fsSL https://raw.githubusercontent.com/bd-loser/opencode-bionic/main/repo-setup.sh | bash
```

### Из исходников

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

Исходники могут лежать на общей памяти, а вот **сборка — нет**: она
автоматически переносится во внутреннюю память Termux, потому что
`/storage/emulated/0` не поддерживает симлинки в `node_modules` и бит
исполнения. `build.sh` записывает итоговый `bun.lock` обратно в исходники.

### Запуск

```bash
opencode               # фоновый сервер под управлением upstream
opencode --standalone  # собственный сервер в этом же процессе
```

На Android лучше `--standalone`: система может в любой момент убить фоновый
сервер. После установки новой сборки перезапустите opencode.

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

- **Только ARM64 и только Termux.** Ни x86_64, ни эмуляторов, ни других
  android-оболочек.
- **Бинарник обязан лежать во внутренней памяти.** Android не даёт выполнять
  файлы из `/storage/emulated/0` и `/sdcard`; `termux/install.sh` ставит
  `$PREFIX/bin/opencode`.
- **Нет веб-интерфейса.** Сборка идёт с `--skip-web-ui`: только TUI, CLI и
  HTTP API-сервер, без встроенных веб-ассетов.
- **Нет Parcel watcher.** Под Bionic для него нет биндинга, поэтому рекурсивное
  отслеживание работает на `fs.watch` из Bun с теми же правилами игнорирования.
  Поведение близкое, но не идентичное inotify/FSEvents из upstream.
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
- **Порт отстаёт от upstream.** Ветка закреплена на OpenTUI 0.6.6, потому что
  это последние опубликованные сборки `@androidtui`; более свежие коммиты
  upstream `dev` требуют нового OpenTUI и не вливаются, пока android-сборок нет.
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

Полный `bun run check` (lint, typecheck, оба сайта на Astro) на устройстве
проходит; он показывает предупреждения линтера из upstream, которые порт не
подавляет. После очередного `bun install` повторите `bun termux/link-tools.ts`,
чтобы восстановить ссылки на android-инструменты.

## Обновление из upstream

```bash
git fetch origin dev
git rebase origin/dev
```

Пока порт закреплён на более старом OpenTUI, конфликты в `package.json` и
`bun.lock` ожидаемы — разрешайте их в пользу пинов `@androidtui`.

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
