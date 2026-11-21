# My-luas

Раскладка по платформам. Дубликаты удалены — каждый файл существует ровно в одном экземпляре.

```
Lua API/            — документация / API-референсы
  nl/               — Neverlose
  skeet/            — Gamesence / Skeet
  aimware/          — Aimware V5

Luas/               — готовые скрипты
  nl/               — под Neverlose (ui.find, menu.*, render.*, utils.*, neverlose/*)
  nl/patches/       — nl-патчи (копии из Patches/)
  skeet/            — под Gamesence (ui.new_*, entity.*, client.*, plist, cvar.*)
  skeet/patches/    — skeet-патчи (копии из Patches/)

Patches/            — датированные патчи (имена и расширения как в оригинале)
                      + разбивка по читу в Luas/nl/patches и Luas/skeet/patches
```

## Lua API

| Папка | Файлы |
|---|---|
| `Lua API/nl` | `neverlose api.lua`, `nl_full_reverse_report_ru.md` |
| `Lua API/skeet` | `api (1).lua`, `api gamesens (1).lua`, `skeet_full_reverse_report_ru.md` |
| `Lua API/aimware` | `api aimware.lua` |

## Luas

| Файл | Платформа | Признаки |
|---|---|---|
| `nl/666DT.lua` | Neverlose | `ui.find`, `require("neverlose/...")`, `render.gradient` |
| `nl/White strike.lua` | Neverlose | `ui.find`, `ui.get_icon`, `render.*`, `utils.*` |
| `nl/viera utils.lua` | Neverlose | `ffi`, `ui.create`, `utils.get_netvar_offset` |
| `nl/персистанс.lua` | Neverlose | persistence-фреймворк (`ui.find`, `persistence/ui/menu`, `ffi`), бывш. загруженный `2026-10-22_14-47-07-663.txt` |
| `nl/gh.lua` | Neverlose | NadeHelper (`menu.*`, `ui.create`, `db.*`, `utils.trace_hull`). Не патч — лежит в `Luas/`, из `Patches/` удалён |
| `skeet/angelwings_full.lua` | Gamesence | `entity.get_prop`, `client.trace_bullet`, `plist`, `ui.new_checkbox` |
| `skeet/luadeepseek predict.lua` | Gamesence | `ui.new_checkbox`, `cvar.cl_interp`, `client.latency` |
| `all in one.lua` | Gamesense | большой all-in-one скрипт (~640 КБ, бывш. `2026-10-07_20-05-07-185-3.lua`): анти-аим, визуал, статистика, `database`, `sv_maxusrcmdprocessticks` |

## Patches

Датированные патчи в `Patches/`, имена и расширения как в оригинале:

| Файл | Чит | Что внутри |
|---|---|---|
| `2026-10-07_20-05-07-185.lua` | **skeet** | затирание нормалей (`Z_NORM`) через `ffi`; `client.find_signature`, `ui.new_checkbox` |
| `2026-10-07_20-05-07-185-1.lua` | **skeet** | патч `DIR_FLAGS` (три `NOP`) |
| `2026-10-07_20-05-07-185-2.lua` | **skeet** | хук движения/сворачивания меню по сырым адресам |
| `2026-10-07_20-05-07-185-5.lua` | **skeet** | «стрелять как Скала Джонсон» — запись `B8 01 00 00 00 C2 08 00` |
| `2026-11-02_15-31-42-127.lua` | **nl** | Neverlose backtrack-патч PAW (`ui.create("Rage", ...)`, `cvar.sv_maxunlag:float()`) |

### Копии по читам

Каждый патч лежит дважды осознанно: оригинал в `Patches/` + рабочая копия в папке чита.
Побайтовые дубли удалены (см. ниже).

| В `Patches/` | Копия для чита |
|---|---|
| `2026-10-07_20-05-07-185.lua`, `-1`, `-2`, `-5` | `Luas/skeet/patches/` |
| `2026-11-02_15-31-42-127.lua` | `Luas/nl/patches/` |

### Что удалено как копирка

| Удалено | Потому что |
|---|---|
| `Luas/skeet/patches/2026-10-07_20-05-07-185-4.lua` | побайтовый дубль `-3` (md5 `12a2c7ce…`) |
| `Luas/skeet/patches/2026-10-07_20-05-07-185.lua` | побайтовый дубль `2026-10-07_20-05-07-185.lua` (md5 `b4007d97…`) |

В `Patches/` дублей нет: там осталось 5 файлов, все с разным содержимым.

### Что удалено как копирка (корень)

| Удалено | Потому что |
|---|---|
| `panchan cracked.lua` (был в корне, загружен через GitHub) | побайтовый дубль `Luas/all in one.lua` (md5 `12a2c7ce…`) |
