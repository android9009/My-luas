# My-luas

Раскладка по платформам.

```
Lua API/            — документация / API-референсы
  nl/               — Neverlose
  skeet/            — Gamesence / Skeet
  aimware/          — Aimware V5

Luas/               — готовые скрипты (разложены по читу)
  nl/               — под Neverlose (ui.find, menu.*, render.*, utils.*, neverlose/*)
  nl/patches/       — копии nl-патчей из Patches/
  skeet/            — под Gamesence (ui.new_*, entity.*, client.*, plist, cvar.*)
  skeet/patches/    — копии skeet-патчей из Patches/

Patches/            — ВСЕ датированные дампы/патчи (имена и расширения как в оригинале);
                      здесь они просто лежат подряд, разбивка по читу — в Luas/*/patches
```

## Lua API

| Папка | Файлы |
|---|---|
| `Lua API/nl` | `neverlose api.txt`, `nl_full_reverse_report_ru.md` |
| `Lua API/skeet` | `api (1).txt`, `api gamesens (1).txt`, `skeet_full_reverse_report_ru.md` |
| `Lua API/aimware` | `api aimware.txt` |

## Luas

| Файл | Платформа | Признаки |
|---|---|---|
| `nl/666DT.lua` | Neverlose | `ui.find`, `require("neverlose/...")`, `render.gradient` |
| `nl/White strike.lua` | Neverlose | `ui.find`, `ui.get_icon`, `render.*`, `utils.*` |
| `nl/viera utils.lua` | Neverlose | `ffi`, `ui.create`, `utils.get_netvar_offset` |
| `skeet/angelwings_full.lua` | Gamesence | `entity.get_prop`, `client.trace_bullet`, `plist`, `ui.new_checkbox` |
| `skeet/luadeepseek predict.lua` | Gamesence | `ui.new_checkbox`, `cvar.cl_interp`, `client.latency` |

## Patches

Все датированные файлы (`2026-10-07_*`, `2026-11-02_*`), имена и расширения возвращены к исходным.
Плюс каждый продублирован в `Luas/nl/patches` или `Luas/skeet/patches` по своему читу.

| Файл | Чит | Почему | Что внутри |
|---|---|---|---|
| `2026-10-07_20-05-07-185.lua` | **skeet** | `client.find_signature`, `client.dll`, `ui.new_checkbox`, `client.set_event_callback` | затирание нормалей (`Z_NORM`) через `ffi` |
| `2026-10-07_20-05-07-185.lua.txt` | **skeet** | копия предыдущего | то же самое |
| `2026-10-07_20-05-07-185-1.lua.txt` | **skeet** | `client.find_signature`, `ui.new_checkbox` | патч `DIR_FLAGS` (три `NOP`) |
| `2026-10-07_20-05-07-185-2.lua.txt` | **skeet** | `ui.new_slider`, `globals.frametime`, `client.screen_size` | хук движения/сворачивания меню по сырым адресам |
| `2026-10-07_20-05-07-185-3.lua.txt` | **skeet** | `ui.reference`, `database.read/write`, `entity.get_prop`, `cvar.*` | большой Gamesence-скрипт (~640 КБ) |
| `2026-10-07_20-05-07-185-4.lua.txt` | **skeet** | побайтовый дубль `-3` (md5 совпадает) | то же |
| `2026-10-07_20-05-07-185-5.lua.txt` | **skeet** | `client.find_signature`, `ui.new_checkbox` | «стрелять как Скала Джонсон» — запись `B8 01 00 00 00 C2 08 00` |
| `2026-11-02_15-30-49-889.txt` | **nl** | `db.nhx_trajectory_style`, `require("neverlose/clipboard")`, `menu.*`, `ui.create` | Neverlose NadeHelper |
| `2026-11-02_15-31-42-127.txt` | **nl** | `ui.create("Rage", ...)`, `group:switch/slider`, `cvar.sv_maxunlag:float()` | Neverlose backtrack-патч (PAW Backtrack) |

> Все 7 файлов `2026-10-07_*` — gamesense/skeet API (`client.*`, `ui.new_*`, `entity.*`, `database.*`).
> Оба `2026-11-02_*` — Neverlose (`menu.*`, `db.*`, `ui.create`, `cvar:float()`). Ни один файл не является aimware-скриптом.

