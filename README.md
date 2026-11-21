# My-luas

Раскладка по платформам. Дубликаты удалены — каждый файл существует ровно в одном экземпляре.

```
Lua API/            — документация / API-референсы
  nl/               — Neverlose
  skeet/            — Gamesence / Skeet
  aimware/          — Aimware V5

Luas/               — готовые скрипты
  nl/               — под Neverlose (ui.find, menu.*, render.*, utils.*, neverlose/*)
  skeet/            — под Gamesence (ui.new_*, entity.*, client.*, plist, cvar.*)

Patches/            — ВСЕ датированные дампы/патчи (имена и расширения как в оригинале)
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

Датированные файлы в `Patches/`, имена и расширения как в оригинале:

| Файл | Чит | Что внутри |
|---|---|---|
| `2026-10-07_20-05-07-185.lua` | **skeet** | затирание нормалей (`Z_NORM`) через `ffi`; `client.find_signature`, `ui.new_checkbox` |
| `2026-10-07_20-05-07-185-1.lua.txt` | **skeet** | патч `DIR_FLAGS` (три `NOP`) |
| `2026-10-07_20-05-07-185-2.lua.txt` | **skeet** | хук движения/сворачивания меню по сырым адресам |
| `2026-10-07_20-05-07-185-3.lua.txt` | **skeet** | большой Gamesence-скрипт (~640 КБ): `ui.reference`, `database.read/write`, `entity.get_prop` |
| `2026-10-07_20-05-07-185-5.lua.txt` | **skeet** | «стрелять как Скала Джонсон» — запись `B8 01 00 00 00 C2 08 00` |
| `2026-11-02_15-30-49-889.txt` | **nl** | Neverlose NadeHelper (`menu.*`, `ui.create`, `db.*`) |
| `2026-11-02_15-31-42-127.txt` | **nl** | Neverlose backtrack-патч PAW (`ui.create("Rage", ...)`, `cvar.sv_maxunlag:float()`) |

### Что удалено как копирки

| Удалено | Потому что |
|---|---|
| `2026-10-07_20-05-07-185-4.lua.txt` | побайтовый дубль `-3` (md5 `12a2c7ce...`) |
| `2026-10-07_20-05-07-185.lua.txt` | побайтовый дубль `2026-10-07_20-05-07-185.lua` (md5 `b4007d97...`) |
| `Luas/nl/patches/`, `Luas/skeet/patches/` | полные копии файлов из `Patches/`; разбивка по читу — в таблице выше |
