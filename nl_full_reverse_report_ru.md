# Полный статический reverse `neverlose/bins/nl.bin`

**Целевой репозиторий:** `https://gitlab.com/luvettee/FemboyLose/`  
**Режим анализа:** только offline static analysis; образ не запускался и не загружался как код.  
**Дата отчёта:** 2026-10-04  
**Основная таблица:** [`nl_reverse_table.csv`](./nl_reverse_table.csv)

---

## 1. Резюме

Проанализирован именно `neverlose/bins/nl.bin` из GitLab-репозитория FemboyLose, а не похожий dump или файл из другого зеркала. Это **не PE-файл на диске**, а готовый к копированию **плоский 32-битный x86 memory image** с жёстко заданной базой `0x412A0000`. Полный mapped range:

```text
0x412A0000–0x447A1000
size = 0x3501000 = 55,578,624 bytes
```

Companion-loader резервирует весь диапазон как RWX, копирует туда ресурс, восстанавливает runtime imports/interfaces/ConVars/signatures, обходит PEB/CPUID/KUSER-проверки, исправляет защитные переходы и только после этого создаёт поток на `0x412A0A00`.

Главные результаты:

* зафиксированы revision, Git blob и SHA-256 точного файла;
* доказан flat-image loader contract, архитектура x86 и фиксированная база;
* полностью проиндексированы и raw-byte-валидированы все доступные companion-карты:
  * **453** активных import slots;
  * **822** interface sites;
  * **164** ConVar sites, **57** уникальных имён;
  * **320** signature sites;
  * **2366** NOP ranges, всего **34,239** байт;
  * **103** short `JZ → JMP` flow repairs;
  * **979** PEB probes;
  * **317** CPUID sites: 68 inline hooks + 249 VEH sites;
  * **9** KUSER_SHARED_DATA sites;
* восстановлена нативная цепочка входа и защищённый dispatcher;
* локализованы damage/trace, lag/interpolation, command/exploit, movement, grenade, configuration, scripting и networking subsystems;
* полностью восстановлена вычислительная часть Air Strafe, включая формулу `min(845.5 / speed, 90)` и collision-aware side scan;
* восстановлена grenade launch setup с формулами силы, скорости, точки старта и компенсацией скорости игрока;
* отдельно проверена гипотеза Super Toss: найденный grenade path является predictor/trajectory path, но **запись компенсированных углов в `CUserCmd` не доказана**;
* создан master CSV на **5623 строки данных** с адресами, file offsets, исходными байтами, семантикой и уровнем доказанности.

---

## 2. Уровни доказательности

Во всём отчёте используются четыре уровня:

| Уровень | Значение |
|---|---|
| **EXACT_BINARY** | Непосредственно доказано байтами, instruction/data flow, xrefs или константами `nl.bin`. |
| **EXACT_BINARY + SOURCE_MAP** | Адрес и binary form проверены в `nl.bin`, а имя runtime-зависимости взято из companion-карты той же revision. |
| **SOURCE_CORROBORATED** | Поведение нативного блока подтверждено companion-кодом, который hook/patch-ит конкретный адрес. |
| **INFERENCE / NEGATIVE_RESULT** | Архитектурная интерпретация либо явно зафиксированный отрицательный результат поиска; не выдаётся за exact proof. |

Открытый C++ в FemboyLose использовался как **cross-reference к фактическим адресам**, а не как замена анализа образа. Для interface/ConVar/signature sites дополнительно проверен реальный binary form `B8 imm32`, для flow sites — исходный opcode `74 rel8`, для CPUID — `0F A2` либо два отдельно отмеченных prefixed sites.

---

## 3. Идентичность и происхождение файла

### 3.1. Git identity

```text
repository:  https://gitlab.com/luvettee/FemboyLose.git
revision:    75800edc95239c5ee29aa5fd3aea71546514b03a
tree:        32cf02ab84d6ab64c7314adbfd796b01cf2cf811
blob:        76722f511c1c29a012edbb38b10a1743d079efc5
path:        neverlose/bins/nl.bin
mode:        100644
commit time: 2026-07-14T18:10:33Z
subject:     Merge branch 'revert-5eff735d' into 'main'
```

### 3.2. File identity

```text
path:        /home/user/nl.bin
size:        55,578,624 bytes = 0x3501000
SHA-256:     682ce73b371349f87da6fd9365f8550e240dcdb97951e80445e70286275ad96e
file(1):     data
```

Таким образом, анализ относится к одному однозначно идентифицированному Git object.

---

## 4. Формат, архитектура и layout

### 4.1. Формат

У файла нет пригодного DOS/NT header в начале, section table, import directory или relocation directory. Первый байт файла соответствует VA `0x412A0000`, а обращение к VA переводится в file offset формулой:

```text
file_offset = VA - 0x412A0000
VA          = 0x412A0000 + file_offset
```

Это **flat mapped image**, а не обычный PE-container. Архитектура — **Intel x86, 32-bit little-endian**. Доказательства: 32-битные opcodes, `FS:[0x30]` PEB access, x86 calling conventions, 4-byte pointers, `CPUID`, x87/SSE и 32-битные absolute VAs.

### 4.2. Аналитические регионы

Указанные ниже регионы — не PE-sections, а границы по фактическим байтам:

| Диапазон | Размер | Энтропия | Интерпретация |
|---|---:|---:|---|
| `0x412A0000–0x425A0000` | `0x1300000` | `6.774` | Основной нативный код, статические библиотеки, constants и globals. |
| `0x425A0000–0x435A0000` | `0x1000000` | `7.961` | Высокоэнтропийная protected region. Нельзя честно назвать её конкретным packer/шифром без runtime proof. |
| `0x435A0000–0x43864E3C` | `0x2C4E3C` | `5.453` | Смешанный защищённый tail, данные и zero gaps. |
| `0x43864E3C–0x44790A00` | `0xF2BBC4` | `0.000` | Полностью нулевой резерв. |
| `0x44790A00–0x44792296` | `0x1896` | `2.017` | Нативный tail bootstrap и служебные функции. |
| `0x44792296–0x4479EE02` | `0xCB6C` | `0.000` | Нулевой tail gap. |
| `0x4479EE02–0x447A1000` | `0x21FE` | — | Tail slots/metadata; последний `0x1000` заполнен ASCII `G`. |

### 4.3. Relocations и fixed base

Обычной relocation table нет. В коде и данных множество абсолютных адресов `0x41xxxxxx–0x44xxxxxx`. Companion class инициализирует:

```cpp
baseAddr  = 0x412A0000;
imageSize = 0x3501000;
```

и передаёт этот preferred address в `NtAllocateVirtualMemory`. Поэтому fixed base является частью контракта. Перенос образа без отдельной полной релокации абсолютных VA невозможен.

### 4.4. Сжатие и шифрование

Цельный файл не является единым compressed stream: в нём одновременно присутствуют исполняемый x86, читаемые version strings, таблицы, WAV и PNG. Высокоэнтропийная область `0x425A0000–0x435A0000` и protected entry содержат VM/opaque-подобные конструкции, но конкретное семейство protector не доказано. Отсутствие имени protector отмечено намеренно.

---

## 5. Loader contract

Companion-loader выполняет следующую последовательность:

1. Извлекает `nl.bin` из ресурса.
2. Резервирует `0x3501000` байт по адресу `0x412A0000` с `PAGE_EXECUTE_READWRITE`.
3. Копирует образ без PE mapping.
4. Ждёт загрузки `serverbrowser.dll`.
5. Восстанавливает imports, interface pointers, ConVars и signature results.
6. Ставит PEB, CPUID и KUSER_SHARED_DATA spoofing.
7. NOP-ит защитные spans, исправляет control flow и точечные opcodes.
8. Заменяет memory dispatcher и SHA-256 transform.
9. Устанавливает VEH и внешние hooks/spoofing.
10. Создаёт suspended thread на `0x412A0A00`, затем resume/wait.

Этот контракт объясняет, почему сырой файл нельзя корректно исполнять сам по себе. В ходе анализа ни original image, ни repaired copy не исполнялись.

### 5.1. Entry chain

Доказанная нативная цепочка:

```text
0x412A0A00  image thread entry
    CALL 0x44790A00

0x44790A00  tail wrapper
    подготавливает base=0x412A0000, reason=1
    CALL 0x4479135C

0x4479135C  DLL-attach style dispatcher
    при attach вызывает 0x447911C8

0x447911C8–0x44791349
    служебная exception/unwind registration логика
```

Protected core имеет entry anchor `0x43354DCB`; в `0x43354FA2` находится computed `JMP EBP`. Это подтверждает dispatcher/virtualized или heavily-obfuscated control flow, но само по себе не определяет protector family.

Tail содержит локальные runtime helpers:

* `0x44791375–0x44791399` — `memcpy`;
* `0x4479139A–0x447913C6` — `memset`.

---

## 6. Восстановление runtime-зависимостей

### 6.1. Imports

В active companion list ровно **453** slot. Распределение:

| DLL | Slots |
|---|---:|
| `kernel32.dll` | 274 |
| `ws2_32.dll` | 40 |
| `user32.dll` | 37 |
| `v8.dll` | 32 |
| `ntdll.dll` | 28 |
| `gdi32.dll` | 8 |
| `advapi32.dll` | 7 |
| `combase.dll` | 6 |
| `crypt32.dll` | 6 |
| `oleaut32.dll` | 5 |
| `imm32.dll` | 3 |
| `shell32.dll` | 2 |
| `kernelbase.dll`, `winmm.dll`, `ole32.dll`, `iphlpapi.dll`, `bcrypt.dll` | по 1 |

Это настоящие 4-byte slots. Их runtime values статически не подставлялись.

### 6.2. Source engine interfaces

Найдено **822** immediate sites. Основные интерфейсы:

| Interface | Sites |
|---|---:|
| `VEngineClient014` | 197 |
| `VClientEntityList003` | 141 |
| `VEngineCvar007` | 87 |
| `EngineTraceClient004` | 60 |
| `VStudioRender026` | 51 |
| `VMaterialSystem080` | 45 |
| `VClientPrediction001` | 35 |
| `VDebugOverlay004` | 33 |
| `VModelInfoClient004` | 31 |
| `VEngineRenderView014` | 27 |
| `VGUI_Surface031` | 24 |
| `VFileSystem017` | 18 |
| `MDLCache004` | 15 |
| `GameMovement001` | 7 |
| `PanoramaUIEngine001` | 7 |
| `GAMEEVENTSMANAGER002` | 6 |

Каждый mapped address проверен как 4-byte immediate field инструкции `MOV EAX, imm32`; полный opcode начинается на `address - 1`.

### 6.3. ConVars

Всего **164 sites**, **57 unique names**. Наиболее частые и функционально важные:

* movement: `sv_stopspeed`, `sv_accelerate`, `sv_friction`, `sv_airaccelerate`, `cl_sidespeed`, `sv_gravity`, `sv_jump_impulse`;
* rage/weapon: `weapon_recoil_scale`, `weapon_accuracy_nospread`, `weapon_debug_spread_show`;
* lag/network timing: `sv_maxunlag`, `sv_maxusrcmdprocessticks`, `cl_interp`, `cl_interp_ratio`, `cl_updaterate`, server updaterate/ratio bounds;
* damage: `mp_damage_scale_ct_head`, `mp_damage_scale_t_head`, `mp_damage_scale_ct_body`, `mp_damage_scale_t_body`, friendly-fire reductions;
* grenade: `weapon_molotov_maxdetonateslope`, `molotov_throw_detonate_time`;
* visuals: `sv_skyname`, `cl_csm_shadows`, `mat_postprocess_enable`.

### 6.4. Signature sites

**320** sites ищут game-module code/data по wildcard patterns:

```text
client.dll          279
engine.dll           25
panorama.dll         12
materialsystem.dll    2
studiorender.dll      2
```

В CSV сохранены pattern bytes, wildcard `CC`, optional offset и различие между direct result и dereferenced result.

---

## 7. Protection, anti-analysis и repair inventory

### 7.1. NOP/flow obfuscation

* **2366** ranges заменяются NOP, суммарно **34,239** байт.
* **103** short conditional branch имеют исходный `74 rel8` и меняются на `EB rel8`.
* Линейная дизассемблировка original image из-за этого регулярно попадает в junk islands. Выводы строились по valid targets, xrefs, полям и константам, а не по слепому linear sweep.

### 7.2. PEB

Найдено **979** source-mapped `FS:[0x30]` probes. Companion создаёт fake PEB и устанавливает байт `fake_peb + 0xA8 = 0x20`. Для каждого site в CSV указаны register, overwrite span и исходные байты.

### 7.3. CPUID

Всего **317 sites**:

* 68 inline hooks с trampoline, который пропускает исходный `CPUID`;
* 249 VEH sites, где первые два байта меняются на `CC 58` (`INT3; POP EAX`).

Два VEH site начинаются с segment prefix перед `0F A2`: `0x42B543DD` и `0x43366DDB`; это отдельно отмечено и не скрыто нормализацией.

Companion CPUID emulator выдаёт AMD-подобный профиль и строку Ryzen 7 7700X. Это crack-side HWID normalization, не характеристика машины автора образа.

### 7.4. KUSER_SHARED_DATA

Девять sites перенаправляют обращения к диапазону `0x7FFE0000–0x7FFE0FFF` в fake KUSER block. Для `0x431CD6B3` companion дополнительно корректирует continuation jump.

### 7.5. Дополнительные protection hooks

* `0x41DA0BA0` — memory dispatcher: register/emplace/erase hooks и pattern scan;
* `0x41EBB510` — SHA-256 block transform;
* `0x41D9F3F0` — crypto data capture, 28 bytes → `0x424AFD88`;
* `0x42026080` — internal exit, подавляемый hook;
* блокировка terminate-process для вызовов из image range;
* spoof disk IO, adapter information, PEB, CPUID и KUSER — свойства companion crack layer.

Важно: localhost redirection, fake serial и HWID spoofing из companion не следует выдавать за original production service behavior `nl.bin`.

---

## 8. Центральные globals и структуры

### 8.1. Globals

| Address | Смысл | Уровень |
|---|---|---|
| `0x424B03CC` | current `CUserCmd*`; запись видна в dispatcher на `0x415954AC` | exact binary |
| `0x424AFD68` | local entity/handle anchor, используемый command и movement кодом | exact binary |
| `0x424AFD88` | 28-byte crypto capture buffer | source-corroborated |
| `0x425006F0` | owner/config-entry pointer для menu config apply | source-corroborated |

### 8.2. `CUserCmd` offsets

По фактическим обращениям к объекту текущей команды:

```text
+0x0C  viewangles.pitch
+0x10  viewangles.yaw
+0x14  viewangles.roll
+0x24  forwardmove
+0x28  sidemove
+0x30  buttons
+0x38  weaponselect
```

Синхронизатор `0x41428C40` и command cluster `0x414E28xx+` копируют/нормализуют движения и buttons после изменения viewangles или replay команды.

---

## 9. Ragebot, damage и trace

### 9.1. Damage scaling

Основной восстановленный блок:

```text
0x4136FFA0–0x41370CE6
```

Он работает с direction/distance/trace state и использует четыре team scaling ConVars:

```text
0x4137080F  mp_damage_scale_ct_body
0x413708A9  mp_damage_scale_t_body
0x41370991  mp_damage_scale_ct_head
0x41370A26  mp_damage_scale_t_head
```

Есть 14 direct call references к entry `0x4136FFA0`, включая `0x4136E09E`, `0x4137183C`, `0x413718CD`, `0x413D2988`, `0x413E266F`, `0x413E26C1`, `0x413E60DF` и `0x413EB73F`. Это общий reusable damage/trace primitive, используемый и соседними simulation paths.

### 9.2. Aim/shot command path

Кластер `0x414E2800+`:

* читает и изменяет `CUserCmd::buttons`;
* работает с command history/replayed command copies;
* копирует `viewangles`, `forwardmove`, `sidemove` и связанные поля;
* вызывает movement/button synchronizer на `0x414E5C15`;
* нормализует pitch/yaw и записывает `cmd+0x10` на `0x414E5DE8`, `cmd+0x0C` на `0x414E5EBF`.

Это exact command/shot-processing code, однако protected control flow не позволяет без дополнительного runtime trace честно присвоить всему большому кластеру одно продуктовое имя вроде “Ragebot fire” или “Anti-Aim”.

### 9.3. Recoil/spread anchors

* `weapon_recoil_scale` имеет 13 sites; `0x41598FC6` расположен непосредственно в command dispatcher области;
* `weapon_accuracy_nospread`: `0x4148FA70`, `0x414A51B5`, `0x415DEEF6`;
* `weapon_debug_spread_show`: cluster `0x4150FFD1–0x4151059F`.

Эти anchors подтверждают управление recoil/spread state, но сами по себе не дают точной формулы hitchance. Конкретные menu policies “minimum damage”, “adaptive safe”, hitbox priority и числовой hitchance нельзя приписывать этому image без доказанного config-to-code data flow.

---

## 10. Resolver, lag compensation и interpolation

### 10.1. Доказанные lag/interpolation blocks

```text
0x41400BF0–0x41400DBE  record/interpolation gate
0x41400DE0–0x41401177  interpolation/history logic
```

Anchors:

* `0x41400CDE` — `sv_maxunlag`;
* `0x41400E76` — `sv_maxupdaterate`;
* `0x41400F2F` — `sv_minupdaterate`;
* `0x4140100B` — `sv_client_max_interp_ratio`;
* `0x414010CA` — `sv_client_min_interp_ratio`.

`0x41400BF0` имеет 11 direct callers; `0x41400DE0` вызывается из `0x4144526C`. Это доказывает centralized record/timing validity path.

### 10.2. Resolver

В image присутствуют player history, animation/shot-processing и command replay блоки, необходимые resolver/lagcomp subsystem. Однако:

* plaintext feature labels отсутствуют;
* часть control flow закрыта protected regions;
* отдельный resolver dispatcher с доказанными mode names и yaw formulas не восстановлен.

Поэтому утверждения вида “это exact resolver mode X” в отчёте не делаются. Это **negative result**, а не утверждение об отсутствии resolver functionality.

---

## 11. Exploit / command budget

Основной dispatcher начинается в:

```text
0x41595380
caller: 0x415AB8ED
```

В начале он сохраняет current command и обрабатывает command state. Внутри находятся непосредственные ConVar anchors:

```text
0x41595543  sv_maxusrcmdprocessticks
0x41595643  sv_maxunlag
0x41598FC6  weapon_recoil_scale
```

На `0x41596ADB` вызывается `0x41428C40` для восстановления movement/button consistency. Это доказывает command scheduling/budget bookkeeping, пригодный для tick-shift/exploit pipeline. Но точное продуктовое разделение на “Double Tap”, “Hide Shots” и их menu modes из статического image не доказано; не следует отождествлять каждый budget branch с конкретным названием.

---

## 12. Anti-Aim

Доказано наличие command-angle mutation, normalizers и movement correction. В частности:

* current command global `0x424B03CC`;
* viewangles fields `+0x0C/+0x10/+0x14`;
* многочисленные writes в cluster `0x414E28xx–0x414E5Exx`;
* movement correction через `0x41428C40`;
* command dispatcher `0x41595380`.

Но exact boundary, mode selector и yaw/desync formula именно Anti-Aim не отделены от Rage/recoil/replay paths. Поэтому report фиксирует инфраструктуру и writes, но не выдумывает unavailable mode semantics.

---

## 13. Movement и Air Strafe

### 13.1. Function map

| Address | Назначение |
|---|---|
| `0x414283A0–0x41428C3F` | collision/path helper |
| `0x41428C40–0x41428ED8` | movement-button synchronizer |
| `0x41428EF0` | Air Strafe entry |
| `0x4142C1B0` | collision-aware angular scan driver |
| `0x41468BA0` | movement-state initialization |
| `0x414A0210` | general movement simulation |

Direct call graph:

```text
0x4141DC76 -> 0x41428EF0       Air Strafe feature call
0x4142C2E5 -> 0x414283A0       collision helper
0x4142C354 -> 0x414283A0       collision helper
0x414E5C15 -> 0x41428C40       command replay/shot path
0x41596ADB -> 0x41428C40       main command dispatcher
```

### 13.2. Exact constants и formula

```text
0x4206CF00 = 845.5f
0x4206CF04 = 90.0f
0x4206CF08 = 450.0f
```

Восстановленная формула ideal angular delta:

```text
horizontal_speed = sqrt(velocity.x² + velocity.y²)
ideal_delta      = min(845.5f / horizontal_speed, 90.0f)
```

Movement magnitude ограничивается `450.0f`. Для side movement используются `cl_sidespeed` sites, включая:

```text
0x4142942F
0x41429527
0x414295FA
0x414296C7
```

Финальная запись sidemove:

```text
0x414296FF  MOVSS [cmd + 0x28], XMM0
```

Yaw/state normalization и update проходят через `0x41429741–0x414297AB`. Byte-state на `0x42502BE0` переключается на `0x414297B0`.

### 13.3. Collision-aware side choice

Driver `0x4142C1B0` перебирает угловые кандидаты и дважды вызывает `0x414283A0`, оценивая путь/столкновение. Это не простой alternating `±sidemove`: выбор стороны связан с collision horizon. Exact user-facing setting, управляющий scan depth, по plaintext label не восстановлен.

---

## 14. Grenade prediction и проверка Super Toss

### 14.1. Function map

| Address | Назначение |
|---|---|
| `0x413DF480` | trajectory builder после launch setup |
| `0x413E3250–0x413E4276` | trajectory simulation |
| `0x413E5ED0–0x413E6378` | collision/detonation |
| `0x413E8FF0–0x413E9AA3` | grenade launch setup |
| `0x413EDF40–0x413EE121` | timing logic |

`0x413E8FF0` имеет ровно один direct call:

```text
0x413E1233  CALL 0x413E8FF0
0x413E123B  CALL 0x413DF480
```

То есть launch outputs сначала записываются в grenade subsystem object, после чего используются trajectory builder.

### 14.2. Exact launch setup

Weapon data:

```text
0x413E9841  MOVSS XMM1, [EAX + 0x114]
weapon_data + 0x114 = throw_velocity
```

Формулы:

```text
effective_base = clamp(throw_velocity * 0.9f, 15.0f, 750.0f)
strength       = clamp(strength, 0.0f, 1.0f)
speed          = effective_base * (strength * 0.7f + 0.3f)
```

Точка старта:

```text
origin.z       += strength * 12.0f - 12.0f
trace_end       = origin + forward * 22.0f
launch_origin   = trace.end - forward * 6.0f
```

Pitch проходит piecewise correction перед `AngleVectors`. Launch velocity:

```text
launch_velocity = forward * speed + player_velocity * 1.25f
```

Адреса constants:

| Constant | Address |
|---|---|
| `0.9f` | `0x42072754` |
| `15.0f` | `0x4206CE24` |
| `750.0f` | `0x42072758` |
| `0.7f` | `0x4206D070` |
| `0.3f` | `0x4205B100` |
| `12.0f` | `0x42070A00` |
| `-12.0f` | `0x4207275C` |
| `22.0f` | `0x42072780` |
| `-6.0f` | `0x42072790` |
| `1.25f` | `0x4206DB5C` / packed copies near `0x420727A0` |

Grenade collision/timing дополнительно использует:

```text
0x413E6224  weapon_molotov_maxdetonateslope
0x413EE0BF  molotov_throw_detonate_time
0x413E376F  sv_gravity
0x413EDA1C  sv_gravity
```

### 14.3. Почему это не доказанный Super Toss

Компенсация `player_velocity * 1.25` действительно присутствует, но она находится внутри predictor/trajectory launch setup. Проверены xrefs текущего command global `0x424B03CC`, включая grenade-adjacent области. Связи, которая:

1. вычисляет обратную компенсацию;
2. записывает скорректированные pitch/yaw в `CUserCmd+0x0C/+0x10`;
3. затем инициирует throw,

не найдено.

Поэтому корректный вывод:

> В образе доказана физически корректная grenade prediction с учётом player velocity. Нативный user-command controller Super Toss, изменяющий углы команды ради сохранения траектории, статически не доказан.

---

## 15. Visuals

Полная продуктовая карта visual modes не восстановлена, но инфраструктура и конкретные state anchors доказаны:

* 51 sites `VStudioRender026`;
* 45 sites `VMaterialSystem080`;
* 27 sites `VEngineRenderView014`;
* 24 sites `VGUI_Surface031`;
* 33 sites `VDebugOverlay004`;
* 31 sites `VModelInfoClient004`.

Конкретные ConVar clusters:

```text
0x41500585/0x41500658/0x415006ED  cl_csm_shadows
0x41502B68/0x41502C2F/0x41502CD5  mat_postprocess_enable
0x415086B1                          sv_skyname
0x4150FFD1–0x4151059F              weapon_debug_spread_show
```

Это подтверждает shadow/postprocess/sky/spread visual control. Названия chams materials и exact render hook boundaries без runtime-resolved interface/vtable targets не присваивались.

Validated embedded assets:

| Address | Type | Size | Дополнительно |
|---|---|---:|---|
| `0x4207A38C` | RIFF/WAV | 135,988 | структурно валиден |
| `0x42243338` | PNG | 4,068 | 66×78 |
| `0x4224431C` | PNG | 12,495 | 512×512 |

Назначение assets в UI не доказано только по формату.

---

## 16. Scripting и configuration

### 16.1. Embedded runtimes

Exact version strings:

```text
0x421A2310  LuaJIT 2.1.0-beta3
0x421A357C  Lua 5.1
0x421719CC  DynASM 1.5.0
```

Также присутствуют sol2-style binding strings (`__sol.*`), `lua-cmsgpack 0.4.0`, bytecode marker `luaJIT_BC_%s` и Lua VM/runtime code. Следовательно, Lua scripting runtime встроен статически и не зависит от обычного `lua51.dll` import.

`v8.dll` имеет 32 import slots. Это доказывает отдельную V8 integration surface, но не даёт автоматически право называть каждый V8 call пользовательским JavaScript API.

### 16.2. Configuration

```text
0x4153DFD0  config apply
0x425006F0  config entry owner/global
```

Companion menu hook на `0x415E9086` и `0x41609C80` переключает menu open state. При закрытии он:

1. разыменовывает config entry через `0x425006F0`;
2. при `entry[39] == -1` копирует `entry[38]`;
3. вызывает `0x4153DFD0`.

Это source-corroborated map конкретной config apply boundary. Формат полного config schema в protected image не восстановлен.

---

## 17. Networking

### 17.1. Exact binary components

* `0x41BC78E0` — requestor serial path;
* `0x41BC98E0` — requestor MakeRequest path;
* 40 import slots из `ws2_32.dll`;
* embedded `WebSocket++/0.8.2` на `0x420F63E4`;
* embedded `OpenSSL 1.1.1n 15 Mar 2022` на `0x42100E30`;
* большой набор protobuf strings/types;
* `0x41D9F3F0` crypto capture target;
* `0x41EBB510` SHA-256 transform.

Это подтверждает HTTP/WebSocket/TLS/protobuf-capable networking stack и request serialization/crypto path.

### 17.2. Production endpoint не восстановлен

Companion перехватывает `getaddrinfo` для вызовов из image range и направляет их на `127.0.0.1:30030`; replacement requestor подключается к `127.0.0.1:30031`. Это локальная crack/test infrastructure. Эти адреса **не являются доказанными production endpoints original image**.

---

## 18. Главная карта функций и anchors

| Address/range | Subsystem | Результат |
|---|---|---|
| `0x412A0A00` | loader | image thread entry |
| `0x44790A00` | loader | tail wrapper |
| `0x447911C8–0x44791349` | loader | exception/unwind registration helper |
| `0x4479135C–0x44791374` | loader | attach dispatcher |
| `0x43354DCB` | protection | protected main entry |
| `0x43354FA2` | protection | computed `JMP EBP` |
| `0x41DA0BA0` | hooks | memory dispatcher |
| `0x41D9F3F0` | crypto | capture hook target |
| `0x41EBB510` | crypto | SHA-256 compression |
| `0x41BC78E0` | networking | requestor serial |
| `0x41BC98E0` | networking | requestor request |
| `0x4136FFA0–0x41370CE6` | rage/damage | damage scaling/trace |
| `0x413DF480` | grenade | trajectory builder |
| `0x413E3250–0x413E4276` | grenade | trajectory simulation |
| `0x413E5ED0–0x413E6378` | grenade | collision/detonation |
| `0x413E8FF0–0x413E9AA3` | grenade | launch setup |
| `0x413EDF40–0x413EE121` | grenade | timing |
| `0x41400BF0–0x41401177` | lagcomp | record/interpolation logic |
| `0x414283A0–0x41428C3F` | movement | collision helper |
| `0x41428C40–0x41428ED8` | movement | movement/button synchronizer |
| `0x41428EF0` | movement | Air Strafe |
| `0x4142C1B0` | movement | collision-aware angular scan |
| `0x41468BA0` | movement | simulation state init |
| `0x414A0210` | movement | general movement simulation |
| `0x414E2800+` | rage/command | shot/replay/angle mutation cluster |
| `0x4153DFD0` | config | config apply |
| `0x41595380` | exploit/command | command dispatcher/budget bookkeeping |
| `0x42026080` | runtime | internal exit |

Полный машинно-читаемый список, включая тысячи dependency/protection sites, находится в CSV.

---

## 19. Static repaired copy

Создана отдельная offline analysis copy:

```text
/home/user/nl_static_repaired.bin
SHA-256: ee8a3936d9884c897e8d5480f29fab4c5c78d9ae6686e06a638052cf56a13000
size:    0x3501000
```

Она включает:

* companion NOP spans;
* 103 flow repairs;
* статически определимые last-resort opcode patches.

Она **не включает** runtime addresses imports/interfaces/ConVars/signatures, allocated pages, live module pointers, hook trampolines, fake PEB/KUSER blocks или decrypted runtime state. Поэтому это не runnable reconstruction. Она использовалась только для более устойчивой дизассемблировки.

---

## 20. Ограничения и отрицательные результаты

1. Не было dynamic execution, debugger trace или memory snapshot после loader.
2. Runtime-resolved interface/vtable targets не подставлялись.
3. Protected regions и opaque predicates ограничивают точное восстановление всех high-level boundaries.
4. Protector family не назван: доказательств для конкретного имени недостаточно.
5. Resolver mode labels/formulas не восстановлены до уровня, позволяющего честно дать продуктовые имена.
6. Exact Hitchance/min-damage/hitbox menu policy не заявляется без config-to-code proof.
7. Command budget path доказан, но exact product split Double Tap/Hide Shots не доказан.
8. Anti-Aim infrastructure и angle writes доказаны, но mode dispatcher не отделён от aim/replay logic.
9. Grenade predictor доказан; native `CUserCmd` angle-compensation Super Toss path не найден.
10. Companion localhost/HWID behavior относится к crack layer, а не автоматически к original production behavior.

Эти ограничения не скрываются за предположениями: соответствующие строки `NEGATIVE_RESULT` внесены в CSV.

---

## 21. Master CSV

`/home/user/nl_reverse_table.csv` содержит 14 колонок:

```text
category
subsystem
address
end_address
file_offset
size
module
symbol_or_item
binary_form
raw_bytes
interpretation_ru
proof_level
source_reference
notes_ru
```

Состав после self-validation:

```text
5623 data rows
453  import_slot
822  interface_site
164  convar_site
320  signature_site
2366 nop_repair
103  flow_repair
979  peb_probe
68   cpuid_hook
249  cpuid_veh
9    kuser_probe
31   recovered function/entry rows
8    direct xref rows
13   exact constants
```

CSV записан в UTF-8 with BOM для корректного открытия в Excel. Для NOP/protection sites сохранены исходные raw bytes original `nl.bin`, а не байты repaired copy.

---

## 22. Воспроизводимость

Генератор таблицы:

```text
/home/user/_build_nl_reverse_table.py
```

Он:

* проверяет размер и SHA-256 target image;
* удаляет comments перед чтением active companion arrays;
* проверяет ожидаемые counts;
* валидирует binary forms;
* сохраняет file offsets и raw bytes;
* повторно читает готовый CSV через `csv.DictReader`.

Static repair воспроизводится скриптом:

```text
/home/user/_make_static_repaired.py
```

Ни один из скриптов не исполняет `nl.bin`.

---

## 23. Итоговый вывод

`nl.bin` — fixed-base x86 flat memory image, рассчитанный на специализированный loader. Его native core сочетает game interfaces, prediction/movement, rage/damage, grenade simulation, command scheduling, rendering, LuaJIT/V8 scripting и сетевой стек; крупные области защищены control-flow и high-entropy transformations.

Наиболее полно статически восстановленные gameplay mechanisms — **Air Strafe** и **grenade prediction**. Air Strafe использует speed-derived angular delta и collision-aware scan, а не только чередование sidemove. Grenade setup учитывает throw velocity, strength, corrected pitch, player velocity и trace-adjusted origin. При этом последняя формула является частью trajectory predictor и не должна без дополнительного proof называться нативным Super Toss controller.

Результат является полным в смысле доступного **статического** материала: проиндексированы все companion maps, восстановлены проверяемые code/data relationships, а недоказанные продуктовые названия явно отделены от exact findings.
