# NixOS Guide — cactoz

Конфиг: `/home/cactoz/nix-temp`, хост `nixos`, канал `nixos-unstable`.
Первый ребилд (пока `nh` еще не установлен):

```bash
doas nixos-rebuild switch --flake /home/cactoz/nix-temp#nixos --accept-flake-config
```

После него доступна команда `nh` и все алиасы ниже
(алиасы определены в `modules/nix.nix`, работают в любом shell).

## Структура конфига

| Файл | Что там |
|---|---|
| `flake.nix` | входы: `nixpkgs`, `home-manager`, `zennotes` |
| `configuration.nix` | только импорты + `stateVersion` (не менять) |
| `modules/nix.nix` | кэши, GC, `nh`, алиасы |
| `modules/boot.nix` | bootloader, ядро (`linuxPackages`, не `_latest` — так обновления берутся из кэша) |
| `modules/network.nix` | NetworkManager, tailscale, firewall |
| `modules/nvidia.nix` | графика + проприетарный драйвер |
| `modules/desktop.nix` | niri, ly, шрифты, xwayland |
| `modules/system.nix` | локаль, docker, localsend, nix-ld, минимальный recovery-набор |
| `modules/users.nix` | юзер `cactoz`, `sudo` + `doas` |
| `home/cactoz.nix` | ВСЕ обычные программы (браузеры, редакторы, dev-тулы) |

Правило: системное (драйверы, сеть, boot, сервисы) → `modules/`,
повседневное (редакторы, `firefox`, `nodejs`, игры) → `home/cactoz.nix`.

## Повседневные команды

### Система (редко, требует root, пересобирает ОС)

```bash
sys-switch    # = nh os switch /home/cactoz/nix-temp — применить конфиг
sys-test      # попробовать без добавления пункта в boot-меню
sys-boot      # добавить пункт в boot-меню без активации сейчас
sys-diff      # = nvd diff /run/current-system result — что изменится
sys-rollback  # откат на предыдущее поколение
sys-search    # = nix search nixpkgs — поиск пакета
```

### Дом (часто, секунды, без sudo)

```bash
home-switch   # = nh home switch — применить home/cactoz.nix
```

Типичный цикл «поставить себе программу»:
1. Добавь пакет в `home/cactoz.nix` → `home-switch`.
2. Полный `sys-switch` нужен только если менял `modules/` или `flake.nix`.

### Пакеты без ребилда вообще (как pacman/apt)

```bash
pkg-add nixpkgs#ripgrep     # установить в ~/.nix-profile, БЕЗ ребилда, БЕЗ sudo
pkg-del ripgrep             # удалить (имя смотри в pkg-list)
pkg-list                    # что установлено через nix profile
pkg-up                      # обновить все profile-пакеты
try yazi                    # запустить, не устанавливая (nix run)
try yazi -- yazi --help     # с аргументами: все после -- уходит программе
pkgshell jq ffmpeg          # временный shell, где есть jq и ffmpeg
, htop                      # то же через comma (без установки)
```

Примеры:

```bash
pkg-add nixpkgs#telegram-desktop
pkg-add nixpkgs#ripgrep nixpkgs#fd
try helix -- hx --version
pkgshell python3 -- python3 script.py
```

> `nix profile` — твое постоянное «императивное» состояние.
> Декларативный `home/cactoz.nix` — воспроизводимое состояние.
> Не смешивай бездумно: любимые инструменты держи в `home/cactoz.nix`,
> разовые эксперименты — через `pkg-add` / `try`.

## Обновления

```bash
sys-update    # обновить ВСЕ входы flake + пересобрать систему
```

Точечно (дешевле и предсказуемее):

```bash
nix flake update nixpkgs --flake /home/cactoz/nix-temp  # только nixpkgs
nh os switch /home/cactoz/nix-temp                      # пересобрать
```

Полное обновление всех входов (включая `zennotes`, `home-manager`):

```bash
nix flake update --flake /home/cactoz/nix-temp
nh os switch /home/cactoz/nix-temp
```

После обновления всегда можно откатиться: `sys-rollback` или выбрать
старое поколение в systemd-boot меню. Лимит поколений в boot-меню: 10
(`modules/nix.nix`, `configurationLimit`).

`flake.lock` — коммить (если заведешь git). Откат обновления = откат `flake.lock`.

## Чистка места

```bash
sys-clean     # = nh clean all --keep 5 --keep-since 14d
```

Автоматика уже включена: `nix.gc` еженедельно удаляет старше 14 дней,
`nix.optimise` дедуплицирует store. Вручную `sys-clean` — после крупных
обновлений.

Проверить, сколько жрет store:

```bash
nix store gc --print-dead 2>/dev/null | du -sh --files0-from=- 2>/dev/null
du -sh /nix/store
nix store optimise
```

## Откат и поколения

```bash
nixos-rebuild --rollback                    # классика (нужен sudo/doas)
nh os rollback                              # то же через nh (= sys-rollback)
nixos-rebuild list-generations              # список поколений
nvd diff /run/current-system result         # сравнить текущее с собранным
```

Сломал графику/ядро — в boot-меню выбери предыдущее поколение, загрузись,
потом чини конфиг и `sys-switch`.

## Поиск пакетов и опций

```bash
sys-search firefox                          # поиск в nixpkgs
nix search nixpkgs# python                  # то же явно
, nixpkgs#nixpkgs-fmt -- --help             # вообще любой пакет без установки
```

Опции NixOS: `https://search.nixos.org/options`,
пакеты: `https://search.nixos.org/packages`.

## Типовые сценарии

**Поставить dev-тул навсегда:**
```bash
# в home/cactoz.nix добавить в home.packages, затем:
home-switch
```

**Быстро глянуть тул и забыть:**
```bash
try ripgrep -- rg --version
```

**Посидеть в окружении с несколькими пакетами:**
```bash
pkgshell nodejs python3 -- bash
```

**Поменял сеть/драйвер/сервис:**
```bash
# правишь modules/*.nix, затем:
sys-diff      # опционально: посмотреть что будет
sys-switch
```

**Прилетело большое обновление unstable, страшно:**
```bash
sys-update
# не загрузилось -> reboot -> в systemd-boot выбрать прошлое поколение
```

**Кончилось место в /boot:**
```bash
sys-clean
# лимит в 10 поколений уже стоит, больше копиться не должно
```

## Нюансы этой машины

- Ядро — `pkgs.linuxPackages` (стабильное для релиза, почти всегда в кэше).
  `linuxPackages_latest` сознательно убран: на unstable он почти каждое
  обновление тянул сборку ядра + nvidia-модулей из исходников.
  Если понадобится свежее железо — верни `_latest` в `modules/boot.nix`.
- `sudo` включен обратно (его ждут `nixos-rebuild`/`nh`), `doas` тоже
  работает для интерактива. Команды выше используй с `doas` вместо `sudo`,
  либо просто `doas -s` для рутовой оболочки.
- `nvidia`: `open=false`, `production`-ветка, `NVreg_EnableGpuFirmware=0`,
  `__GL_THREADED_OPTIMIZATIONS=0` — как было, не трогай без причины.
- `system.stateVersion = "26.05"` и `home.stateVersion = "25.11"` — НЕ менять.
  Это метки первого installs, а не версия системы.
- Кэши: `cache.nixos.org` (дефолт) + `nix-community.cachix.org`
  (см. `modules/nix.nix`). После первого `sys-switch` юзер `cactoz`
  станет доверенным (`trusted-users = @wheel`) и варнинги
  `ignoring untrusted ...` пропадут.
- `nh` знает путь к флейку (`programs.nh.flake`), поэтому короткие
  `nh os switch` / `nh home switch` без пути тоже работают из любого места.
