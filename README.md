# My-luas

Раскладка по платформам.

```
Lua API/            — документация / API-референсы
  nl/               — Neverlose
  skeet/            — Gamesence / Skeet
  aimware/          — Aimware V5

Luas/               — готовые скрипты
  nl/               — под Neverlose (ui.find, menu.*, render.*, utils.*, neverlose/*)
  skeet/            — под Gamesence (ui.new_*, entity.*, client.*, plist, cvar.*)

Patches/            — датированные дампы/патчи (имена и расширения как в оригинале)
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

Все датированные файлы (`2026-10-07_*`, `2026-11-02_*`), имена и расширения возвращены к исходным:

| Файл | Что внутри |
|---|---|
| `2026-10-07_20-05-07-185.lua` | оригинал: затирание нормалей (`Z_NORM`) через `ffi` |
| `2026-10-07_20-05-07-185.lua.txt` | копия предыдущего (содержимое идентично) |
| `2026-10-07_20-05-07-185-1.lua.txt` | патч `DIR_FLAGS` (три `NOP`) |
| `2026-10-07_20-05-07-185-2.lua.txt` | хук движения/сворачивания меню по сырым адресам |
| `2026-10-07_20-05-07-185-3.lua.txt` | ~640 КБ Gamesence-скрипт (`ui.reference`, `database.read/write`, `entity.get_prop`) |
| `2026-10-07_20-05-07-185-4.lua.txt` | побайтовый дубль `-3` (md5 совпадает) |
| `2026-10-07_20-05-07-185-5.lua.txt` | «стрелять как Скала Джонсон» — запись `B8 01 00 00 00 C2 08 00` |
| `2026-11-02_15-30-49-889.txt` | Neverlose NadeHelper (`menu.*`, `ui.create`, `render.load_image_from_file`) |
| `2026-11-02_15-31-42-127.txt` | Neverlose backtrack-патч (`db.*`, `ui.create`, `cvar.sv_maxunlag`) |
