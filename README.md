# My-luas

Разложено по платформам. Все `.txt` с луа-кодом переименованы в `.lua` (содержимое не менялось).

```
Lua API/            — документация / API-референсы
  nl/               — Neverlose (никогда не поздно)
  skeet/            — Gamesence / Skeet
  aimware/          — Aimware V5

Luas/               — готовые скрипты
  nl/               — под Neverlose (ui.find, menu.*, render.*, utils.*, neverlose/*)
  skeet/            — под Gamesence (ui.new_*, entity.*, client.*, plist, cvar.*)

Patches/            — патчи памяти (ffi + сырые адреса, привязаны к билду)
```

## Lua API

| Папка | Файлы | Определение |
|---|---|---|
| `Lua API/nl` | `neverlose api.txt`, `nl_full_reverse_report_ru.md` | API Neverlose: `ui.find`, `ui.create`, `menu.*`, `db.*` |
| `Lua API/skeet` | `api (1).txt`, `api gamesens (1).txt`, `skeet_full_reverse_report_ru.md` | API Gamesence: `ui.new_*`, `entity.*`, `plist.*`, `cvar.*` |
| `Lua API/aimware` | `api aimware.txt` | API Aimware: `gui.*`, `callbacks.Register` |

## Luas

| Файл | Платформа | Признаки |
|---|---|---|
| `nl/666DT.lua` | Neverlose | `ui.find`, `require("neverlose/...")`, `render.gradient` |
| `nl/White strike.lua` | Neverlose | `ui.find`, `ui.get_icon`, `render.*`, `utils.*` |
| `nl/viera utils.lua` | Neverlose | `ffi`, `ui.create`, `utils.get_netvar_offset` |
| `nl/2026-11-02_15-30-49-889.lua` | Neverlose | `menu.*`, `ui.create`, `render.load_image_from_file`, `utils.trace_hull` |
| `nl/2026-11-02_15-31-42-127.lua` | Neverlose | `db.*`, `ui.create("Rage", ...)`, `cvar.sv_maxunlag` |
| `skeet/angelwings_full.lua` | Gamesence | `entity.get_prop`, `client.trace_bullet`, `plist`, `ui.new_checkbox` |
| `skeet/luadeepseek predict.lua` | Gamesence | `ui.new_checkbox`, `cvar.cl_interp`, `client.latency` |
| `skeet/2026-10-07_20-05-07-185-3.lua` | Gamesence | ~640 КБ: `ui.reference`, `database.read/write`, `entity.get_prop` |
| `skeet/2026-10-07_20-05-07-185-4 (duplicate).lua` | Gamesence | побайтовый дубль `-3` (md5 совпадает) |

## Patches

| Файл | Что делает |
|---|---|
| `2026-10-07_20-05-07-185.lua` | затирание нормалей (`Z_NORM`) через `ffi` |
| `2026-10-07_20-05-07-185-1.lua` | патч `DIR_FLAGS` (три `NOP`) |
| `2026-10-07_20-05-07-185-2.lua` | хук движения/сворачивания меню по сырым адресам |
| `2026-10-07_20-05-07-185-5.lua` | «стрелять как Скала Джонсон» — запись `B8 01 00 00 00 C2 08 00` |
| `2026-10-07_20-05-07-185 (txt duplicate).lua` | идентичная копия `2026-10-07_20-05-07-185.lua` |

Патчи используют `client.find_signature` в связке с абсолютными адресами — работают только на конкретном билде игры.
