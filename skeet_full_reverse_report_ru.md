# Статический reverse-engineering Skeet: Ragebot, resolver, exploits, anti-aim, movement и grenades

## 0. Область анализа и уровень уверенности

Исследован supplied mapped image:

- файл: `uploads/skeet.bin.txt`;
- архитектура: x86, 32-bit;
- image base: `0x43310000`;
- размер: `3 129 344` bytes;
- SHA-256: `bbb5ee98d00db63dfc5c454b238d5edd3f809976686be226dbc5f6ae55018b07`.

Это статический анализ **именно этой сборки**. Абсолютные адреса нельзя переносить в другой image без нового signature/preflight. В коде есть opaque predicates, недостижимый мусор и зашифрованные обращения к полям сущностей. Поэтому ниже разделены:

- **подтверждено** — следует из reachable x86-кода, data flow и всех найденных потребителей;
- **интерпретация** — назначение структуры ясно, но исходное имя поля/пункта меню отсутствует;
- **не доказано** — гипотезы, которые нельзя превращать в патч только по названию Lua/UI.

Главный практический вывод: улучшения возможны, но наиболее полезные из них находятся не в «одном байте resolver», а на стыке `record -> point -> score -> hitchance -> stop -> exploit schedule -> packet decision`.

---

# 1. Карта подсистем

## Ragebot

| Узел | Адрес |
|---|---:|
| Ragebot vtable | `0x43472A00` |
| основной метод | `0x4334F55F` |
| point/hitbox scanner | `0x4335CD37` |
| record preparation/prediction | `0x4336C53B` |
| hitchance | `0x4341B4C2` |
| hitchance worker | `0x433DF8A0` |
| hitbox-order table | `0x434749F0` |
| descending result comparator | `0x433FF5C7` |

## Resolver

| Узел | Адрес |
|---|---:|
| resolver enable byte | `0x4346754C` |
| основной processor | `0x433240DD` |
| shot-record creation | `0x4341D449` |
| miss classifier | `0x433866BD` |
| outcome callback | `0x43342FA6` |
| matrix/cycle selector | `0x4337CB8A` |
| candidate-count table | `0x4347223C` |
| candidate-slot map | `0x43474944` |

## Command shifting / exploit

Обнаружены два связанных интерфейса:

1. `0x4346EDD4` — core command-shift scheduler. Его методы реально ведут charge, планируют и генерируют дополнительные commands.
2. `0x43470390` — exploit-aware fakelag/choke controller. Он рассчитывает choke goal, движение и packet restrictions, но сам по себе не является полным DT charger.

Ключевые методы core scheduler:

| Смещение vtable `0x4346EDD4` | Метод | Роль |
|---:|---:|---|
| `+0x04` | `0x433ABC86` | update/recharge state machine |
| `+0x08` | `0x433D6A11` | проверка последовательности/command context |
| `+0x0C` | `0x433B56ED` | специальная charged-state интеграция |
| `+0x10` | `0x433CE4BC` | экспорт exploit mode в command context, firing/angle restrictions |
| `+0x14` | `0x4336663F` | главный planner для mode, charge target и shot scheduling |
| `+0x1C` | `0x43359E37` | фактическая генерация/исполнение shifted commands |
| `+0x24` | `0x4340165F` | ограничение choke/usable boundary |

Связанные методы:

- `0x433A069B` — choke/fakelag goal controller;
- `0x433A0EFE` — weapon/movement restriction с запросом state mask `0x200`;
- `0x433A13ED` — вычисление текущего command budget/cap;
- `0x433AC04B` — начало известного 29-byte recharge patch range.

## Anti-aim

| Узел | Адрес |
|---|---:|
| anti-aim vtable | `0x4346F2E0` |
| constructor | `0x43490439` |
| основной command method | `0x4332D1C6` |
| pitch dispatcher | `0x4332D7AA` |
| final pitch write | `0x4332D8D9` |
| master enable | `0x4346A740` |

---

# 2. Ragebot: фактический pipeline

Практически подтвержденный pipeline выглядит так:

1. Собираются доступные enemy/lag records.
2. `0x4336C53B` проверяет record, при необходимости отвергает его или строит predicted/extrapolated variant.
3. Scanner создаёт center и generated multipoints, выполняет geometry/autowall-style проверки.
4. Для результата строится packed priority score в `TargetScanResult +0xE4`.
5. На каждого enemy оставляется лучший result.
6. Победители разных enemies сортируются по `+0xE4`.
7. Выполняется hitchance.
8. При провале основного point возможен переход на secondary/tertiary point.
9. Из фактически активного point строятся aim angles.
10. Quick stop, weapon timing, exploit charge и packet state решают, можно ли отправлять/стрелять сейчас.
11. Создаётся resolver shot record для последующего feedback.

Из этого следуют два важных ограничения:

- первым просканировать head — не значит заставить final selection стрелять в head;
- изменение `cmd.yaw`/`cmd.in_attack` снаружи не заменяет native scanner, resolver matrices, hitchance, backtrack и exploit scheduler.

---

# 3. Hitbox order, center и head priority

## 3.1 Stock scan order

Таблица `0x434749F0` содержит:

```text
{3, 4, 0, 6, 8, 7, 10, 9, 17, 15, 18, 16, 11, 12}
```

При стандартной нумерации CS:GO это соответствует примерно следующему порядку:

1. stomach;
2. lower chest;
3. head;
4. upper chest;
5. thighs;
6. calves;
7. upper arms/forearms;
8. feet.

Перестановка `0` в начало действительно делает head первым в **scan order**. Но final candidate всё равно оценивается packed score, затем сравнивается с другими records/targets и может быть заменён fallback point. Поэтому патч таблицы — это оптимизация порядка работы scanner, а не гарантированный head priority.

## 3.2 Point descriptors

Helper `0x433676D9` добавляет point descriptor со структурой:

| Offset | Значение |
|---:|---|
| `+0x00..+0x08` | world XYZ |
| `+0x0C` | point scale |
| `+0x10` | hitbox ID |
| `+0x14` | flags |

Все подтвержденные generated multipoints получают flag `0x02`. Center добавляется отдельно. Flag bit `0` несёт geometry-safe result.

## 3.3 Stock center preference

В `0x433604F1` center/non-generated point получает point-score bit `7`:

```text
or ecx, 0x80
```

Это tie-break, а не доминирующий приоритет. Подтвержденный narrow center-only patch находится в `0x4335D94C`: он может перепрыгнуть только generated-point block и оставить позднее построение center.

Для сильного center preference можно добавить свободный высокий bit в point score, сохранив обычные multipoints как запасные варианты. Это лучше, чем полностью отключать multipoint, если нужна стабильность против off-center geometry.

## 3.4 Как правильно реализовать head priority

Реалистичны три уровня:

1. **Head-first scan** — переставить таблицу. Дёшево, но не гарантирует final head.
2. **Head score boost** — усиливать packed candidate score, только если активный point имеет hitbox `0`.
3. **Late head-aware rescore** — после secondary/tertiary substitution пересчитать score уже для фактически выбранного point. Это наиболее корректно, но требует hook/trampoline, а не простой замены immediate.

Если одновременно нужны head, safe и lethal/body policies, лучше создать единый policy rank, а не раздавать независимые «самые старшие» bits разным патчам.

---

# 4. Candidate scoring и реальная проблема final fallback

## 4.1 `TargetScanResult`

Подтвержденный размер результата — `0x1190` bytes. Packed priority лежит в `+0xE4`.

Подтвержденные компоненты stock score:

- bits `0..6`: bounded damage contribution;
- bits `9..15`: bounded accuracy/hitchance contribution;
- bit `16`: configured safe-candidate preference;
- bits `17` и `18`: более высокие target/record preferences;
- bits `19..22`: inverse shots-to-kill contribution.

Код сначала сохраняет greatest score для каждого enemy (`0x433548CE`, duplicate `0x433C60A1`), затем сортирует enemy winners через `0x433FF5C7`.

Следовательно, изменение `+0xE4` одновременно меняет:

- выбор lag record внутри enemy;
- выбор target между enemies;
- порядок попыток final hitchance.

## 4.2 Safe candidate

Stock safe preference строится в трёх duplicate paths:

- `0x43354A1D`;
- `0x433646E9`;
- `0x433C61EB`.

Stock instruction добавляет `0x00010000`, то есть bit `16`. Этот bit не сильнее всех полей до bit `22`, поэтому safe result не обязан выиграть.

Для этой exact build подтверждено, что bit `23` не используется reachable producers/consumers `TargetScanResult +0xE4`. Замена `0x00010000 -> 0x00810000` сохраняет stock safe bit и добавляет dominating bit `23`. Это усиливает **priority**, но не подделывает geometry safety.

## 4.3 Primary/secondary/tertiary mismatch

Result содержит три point blocks по 56 bytes:

- primary `+0x0C`;
- secondary `+0x44`;
- tertiary `+0x7C`.

Если primary hitchance не пройден, код в `0x43354B78..0x43354B83` копирует 14 dwords secondary в primary и повторяет HC. Затем аналогично `0x43354BB1..0x43354BBC` может подставить tertiary.

Копируются coordinates, hitbox, damage, point flags и point HC. Но candidate score `+0xE4` **не пересчитывается**.

Это подтвержденный mismatch:

- сортировка была сделана по старому primary point;
- фактический выстрел может пойти по secondary/tertiary;
- hitbox/damage фактического point могут не соответствовать предпосылкам packed score.

### Лучшее реальное улучшение Ragebot

Самая содержательная доработка — не просто «head first», а **late rescore после fallback**:

1. после block copy определить новый hitbox/damage/safe/HC;
2. пересобрать priority для фактического point;
3. при необходимости сравнить его с ещё не проверенными candidates;
4. только затем строить aim и разрешать shot.

Это требует detour/code cave. Одним OR/immediate исправить проблему полностью нельзя.

---

# 5. Safe geometry и hitchance

## 5.1 Два разных понятия safe

В image присутствуют два уровня:

1. point geometry получает safe flag;
2. candidate scoring может предпочесть уже safe point.

Их нельзя смешивать. Score patch не делает unsafe point безопасным.

Safe hitchance умеет проверять три matrix variants. Parent масштабирует требуемый результат по `(2 * safe_mode + 1)`, то есть в подтвержденном safe path используется коэффициент `3`. Это aggregate проверка трёх matrices, а не новый набор spread seeds.

## 5.2 Hitchance seeds/workers

Stock total — **128 spread seeds**.

```text
0x4341BBC7: normal worker divisor/count = 64
0x4341BBF8: fast worker divisor/count   = 32
0x4341BC07: total seeds                 = 128
```

Значения 64/32 — не «число лучей» в бытовом смысле, а worker partition. Код делит 128 на выбранное значение; stack/job area инициализирует не более 64 descriptors.

Безопасные значения для этой реализации:

```text
8, 16, 32, 64
```

Они делят 128 без остатка и не выходят за 64 descriptors. Произвольное `48` теряет корректное покрытие; значение выше `64` рискует выйти за подготовленный массив.

---

# 6. Lag records, prediction и broken lag compensation

## 6.1 Record preparation

`0x4336C53B` может вернуть flags `0x10`, `0x20`, `0x40`.

Две глубокие prediction branches вызывают:

- `0x4333D6D9`;
- `0x43322B09`.

Они рассматриваются только при соответствующем mode, обычно для первого history record и при history count больше одного. Это не простой `origin += velocity * ticks`: helpers проверяют history/timing/movement state, могут отвергнуть запись и пересобирают record через `0x4339C8E2`.

Main Ragebot превращает preparation flags в scan masks:

- `0x10 -> 0x08`;
- `0x20 -> 0x10`;
- `0x40 -> 0x20`.

`0x40` разрешён только для первого record и ставит candidate marker `+0xDD`. Любой flag из `0x70` либо record flag `+0x14C & 0x20` ставит marker `+0xE1`.

## 6.2 Broken-LC threshold

`0x43472B60 = 4096.0`, то есть squared displacement `64 * 64`.

Crossing этого порога не означает «стрелять в stale record». Native flow может:

- отвергнуть record;
- построить predicted replacement;
- пометить специальный path;
- оставить обычную запись, если дополнительные критерии не требуют rebuild.

Поэтому патч «always shoot broken LC» без проверки tick/matrix validity ухудшит систему.

## 6.3 Что можно улучшить

Реалистичный record selector должен ранжировать только подготовленные валидные records и учитывать:

- age/tick delta;
- preparation flags `0x10/0x20/0x40`;
- matrix availability;
- safe state;
- expected damage/HC;
- время, необходимое на quick stop и DT shot schedule.

Лучше добавить telemetry и score weights для predicted records, чем принудительно пропускать native reject/rebuild.

---

# 7. Aim construction, recoil и quick stop

## 7.1 Final aim point

Angles строятся начиная с `0x433551D9` по текущему primary block. После fallback в primary уже лежат secondary/tertiary data, поэтому сам aim использует актуальные coordinates.

Подтвержденные globals:

- `0x434759CC` — LastAimCmdNum;
- `0x434759D0` — LastAimPointVec3;
- `0x434759C8` — delayed-shot command tracking.

Anti-aim позже читает LastAimCmd/LastAimPoint, то есть native pipeline специально сохраняет shot angle от перезаписи обычным yaw logic.

## 7.2 Recoil

Compensation blocks находятся в:

- `0x43355328..0x433553B1`;
- `0x43355ADA..0x43355B63`;
- `0x43357B87..0x43357C12`.

Они вычитают сохранённый three-float punch vector только под guards и ставят flag `0x10`; поздний consumer проверяет flag перед дополнительным вычитанием. Unconditional «убрать ещё один recoil subtraction» не подтвержден.

## 7.3 Quick stop

Главный toggle `0x434671E0` используется в нескольких firing paths. Options лежат в `0x43467E40`; DT-related stop options дополняются из `0x4346A674`. Ragebot выставляет общий `MoveFlags` (`0x434759C0`) для stop/shot/exploit restrictions.

Method `0x43358716`, связанный с post-stop setting, не делает новый полный scan. Он редактирует command buttons и object state. Поэтому forced post-stop не равен «мгновенно пересчитать весь aim после остановки».

### Как улучшать quick stop правильно

Полезная схема:

1. выбран candidate и record;
2. рассчитывается требуемая скорость для HC;
3. stop request публикуется в общий movement state;
4. локальное движение предсказывается на следующий command;
5. проверяется, что record не устарел за время остановки;
6. проверяется weapon readiness и DT charge;
7. только затем ставится shot schedule.

Это устранит часть случаев, когда Ragebot выбрал хороший point до stop, но фактическая скорость/HC на firing command уже отличается.

---

# 8. Resolver: структура и feedback

## 8.1 Shot records

`0x4341D449` выделяет и инициализирует resolver shot record размером `0x1220` bytes. В него копируются:

- target/command/timing identifiers;
- исходные и target coordinates;
- record/matrix metadata;
- resolver mode и cycle;
- дополнительные shot flags.

Поля:

- `shot +0x1D8` — resolver mode;
- `shot +0x1D9` — resolver cycle/candidate index.

Event entries имеют stride `0x20`.

Record creator вызывает selector `0x4337CB8A`, сохраняет выбранный candidate, проверяет mismatch с active cycle и при необходимости:

- ставит shot flag `0x40`;
- сбрасывает часть confidence state;
- находит совпадающие historical lag records;
- ставит им bit `0x40` в record flags `+0x5C`.

## 8.2 Candidate count и mapping

Начало count table:

```text
mode 0 -> 0 candidates
mode 1 -> 3 candidates
mode 2 -> 3 candidates
mode 3 -> 3 candidates
```

В доказанном selector path индексируются только первые три entries `0x43474944`. Эффективная pose-slot последовательность:

```text
{1, 2, 0}
```

Выбранный matrix block:

```text
shot_record + 0x750 + slot * 0x3A0
```

Это подтверждено downstream helper `0x433D725B`. Более поздние bytes mapping table нельзя приписывать этому selector без отдельного reachable path.

## 8.3 Что делает selector

`0x4337CB8A` не является простым `misses % 3`:

- проверяет resolver enable;
- учитывает mode/cycle и shot flags;
- валидирует target/entity/record state;
- строит ray/trajectory context;
- берёт matrix block через mapping;
- вызывает geometry intersection helper;
- при подтвержденном resolver miss может перейти к следующему cycle;
- имеет special handling для mode `3` и временного/state correction path.

То есть реальная resolver correction — это выбор одного из сохранённых matrix candidates плюс feedback. Замена одного enable byte не создаёт новый resolver.

## 8.4 Miss classifier

`0x433866BD` возвращает outcome code. Структурная семантика подтверждается последующим state update:

| Code | Подтвержденная структурная семантика |
|---:|---|
| `0` | shot trajectory пересекает reconstructed target geometry; только этот outcome обновляет resolver miss state |
| `1` | trajectory дошла до ожидаемого endpoint, но не пересекла reconstructed hitboxes — spread/inaccuracy-class miss |
| `2` | фактический impact отличается от ожидаемого endpoint больше порога — obstruction/occlusion-class outcome |
| `3` | expired/unmatched/unresolved shot path без нормальной классификации |

Code `0`:

- увеличивает per-player counter `+0xA8`;
- обновляет timestamp/history;
- записывает статистику по mode/cycle;
- снова вызывает selector;
- при mismatch может сбросить confidence;
- маркирует совпадающие historical records.

Code `1/2/3` не должны отравлять resolver statistics так же, как code `0`.

## 8.5 Реалистичное улучшение resolver

Хороший вариант — сохранить native three-matrix model, но улучшить feedback policy:

1. вести per-player/per-mode/per-slot success/failure с decay;
2. обновлять статистику только для outcome `0`;
3. сбрасывать/ослаблять confidence на dormancy, spawn, large simulation gap и matrix mismatch;
4. учитывать, был ли shot safe across matrices;
5. не считать spread/occlusion resolver miss;
6. выбирать candidate по confidence, но оставлять geometry intersection и native validity gates;
7. логировать active mode/cycle, chosen slot `{1,2,0}` и record flags.

Это требует hook `0x4337CB8A`/feedback update или аккуратного detour. Старый GameSense Lua через `plist Force body yaw` не имеет доступа к этим matrix blocks и не может быть эквивалентом native selector.

---

# 9. Double Tap / command shifting

## 9.1 Подтвержденные поля core state

Названия справа — функциональные, а не восстановленные C++ symbols.

| Offset | Подтвержденная роль |
|---:|---|
| `+0x14` | internal state flags для arm/shift/recharge paths |
| `+0xF4` | active exploit mode/state `0/1/2/3` |
| `+0xF8` | derived reserve/choke boundary, используемая helper-ограничителем |
| `+0xFC` | требуемый charge/usable shift target |
| `+0x100` | текущий command budget/cap |
| `+0x104` | текущий charge/available shifted commands |
| `+0x108` | command marker при completed charge |
| `+0x10C` | last update command marker |
| `+0x11C` | next reuse/reset command threshold |
| `+0x124` | hold/recharge guard scalar; observed values `0` и `0.5f` |
| `+0x128` | predicted shifted tickbase/command target |
| `+0x134` | timing command marker |
| `+0x1C0` | ring head/index |
| `+0x1C4` | ring count, максимум наблюдаемого special path — `8` |
| `+0x1C8` | восемь recent reservation/capacity values |

Точные UI-названия modes `1/2/3` из stripped image не восстановлены с достаточной уверенностью. Они происходят из трёх native exploit bindings. Mode `2` имеет наиболее прямую firing/shift интеграцию, а mode `3` включает defensive angle behavior; называть все три просто «DT» некорректно.

## 9.2 Command budget

Helper `0x433A13ED` читает setting `0x43469274`. В обычном path возвращается configured value. При отдельных network/server-state условиях helper принудительно возвращает `7` или `3`.

Planner требует достаточный budget и вычисляет usable target. Повторяющаяся формула:

```text
usable = clamp(command_budget - reserved_amount - 1, 1, 15)
```

Подтвержденные clamp sites:

- `0x433667AA`;
- `0x43366826`;
- `0x433ABDFC`;
- `0x433ABE5B`.

Следовательно, blindly выставлять shift выше `15` противоречит этой реализации и её storage/scheduling assumptions.

## 9.3 Planner `0x4336663F`

В начале planner:

1. берёт current charge;
2. ограничивает его `budget - current_choke - 1`;
3. дополнительно ограничивает recent ring values;
4. обновляет mode и target;
5. проверяет три bindings, weapon/local state и exploit gates;
6. назначает mode `1/2/3`;
7. рассчитывает `+0xF8/+0xFC`;
8. через internal flags arm-ит command-shift path;
9. проверяет attack/use/weapon state, tickbase windows и send/choke context;
10. публикует restrictions через `MoveFlags`.

Ring buffer является частью usable-charge accounting. Игнорирование `+0x1C0/+0x1C4/+0x1C8` может показать «заряжено» раньше, чем scheduler считает предыдущие reservations безопасно завершёнными.

## 9.4 Фактическая генерация shifted commands

`0x43359E37` — не просто checker. Метод:

- запускается только при подходящем final/send context;
- требует armed state bits;
- снова ограничивает count budget/current choke/charge/ring reservations;
- создаёт и прогоняет дополнительные command entries;
- обновляет command/tickbase-related state;
- после выполнения уменьшает `+0x104` на реально использованный count, не ниже нуля;
- очищает ring bookkeeping;
- выставляет send/state notifications.

Это доказывает, что `+0x104` — расходуемый charge, а не декоративный timer.

## 9.5 Recharge `0x433ABC86`

Recharge state machine:

1. заново получает budget и mode;
2. рассчитывает charge target;
3. при изменении cap может уменьшить charge до допустимого остатка;
4. проверяет command state, movement/weapon restrictions, target/entity context и hold guard;
5. если `charge < target`, пишет в текущий `CUserCmd +0x08` sentinel `0x7F7FFFFF`;
6. увеличивает `+0x104` ровно на один;
7. очищает ring head/count;
8. при достижении target выставляет command markers `+0x108/+0x11C`;
9. публикует `MoveFlags` state и уведомляет registered listeners.

`CUserCmd +0x08` здесь является tick-count field; `0x7F7FFFFF` используется как integer sentinel, хотя bit pattern совпадает с `FLT_MAX`.

Special ring path при count `8` берёт максимальное reservation value. Если текущий charge превышает его хотя бы на `2`, ring сбрасывается, а charge откатывается к этому значению. Это дополнительная синхронизация, которую нельзя удалять без понимания pending commands.

## 9.6 Что реально делает 29-byte «Angelic tap» patch

Оригинальный range начинается `0x433AC04B`:

```text
test [0x434759C0], 0x2008
jne  0x433AC29E
cmp  dword [0x4346DB2C], 0
je   0x433AC16D
```

Далее stock path проверяет last target, entities и spatial/distance conditions перед переходом к charge increment.

Patch:

- NOP-ит первые 24 bytes;
- ставит `JMP rel32`;
- unconditional target — `0x433AC16D`.

Следовательно, patch:

- bypass-ит abort по `MoveFlags & 0x2008`;
- bypass-ит target-valid branch;
- пропускает последующие target/entity/distance checks до `0x433AC16D`;
- но **не** заменяет всю recharge state machine;
- не отменяет поздний `+0x124` guard;
- не отменяет `charge < target`;
- не отменяет budget clamp, ring synchronization и completion markers.

Это aggressive eligibility bypass, а не самостоятельный «улучшенный DT algorithm».

## 9.7 Firing и packet scheduling

`0x433CE4BC` экспортирует charged mode в command context только когда `+0x104 >= +0xFC`. Mode-specific branches могут:

- request-ить state `0x200`;
- удерживать/снимать attack bit в отдельных contexts;
- откладывать действие до command/tickbase window;
- в mode `3` менять pitch/yaw для defensive exploit path.

`0x433A069B` отдельно рассчитывает choke goal. Он учитывает:

- configured choke mode/amount;
- current choked commands;
- local velocity и predicted movement;
- large displacement threshold;
- current target/shot restrictions;
- state masks `0x600`;
- минимальное choking вокруг shot-related conditions.

В конце он обнуляет send bool, пока current choke ниже вычисленной цели. Это exploit-aware fakelag controller, но не charger.

## 9.8 Реалистичные улучшения DT

### Низкий риск

- показывать отдельно `budget`, `target`, `charge`, `mode`, `ring count`, `current choke`;
- запрещать firing schedule, если charge ещё не достиг target;
- сбрасывать UI-ready state при cap change и ring rollback;
- сохранять stock clamp `1..15`.

### Средний риск

- заменить unconditional 29-byte bypass на selectable policy:
  - stock;
  - bypass только конкретного `MoveFlags` restriction;
  - bypass target-distance check;
  - full legacy patch;
- не bypass-ить weapon/death/map transition guards;
- после shot dynamically выбирать recharge delay, но сохранять queue accounting.

### Высокий риск, но максимальный эффект

- hook planner и строить единый shot scheduler:
  1. candidate выбран;
  2. quick stop завершён;
  3. weapon готов;
  4. charge/ring valid;
  5. resolver record ещё valid;
  6. packet/choke state позволяет нужную пару commands;
  7. только после этого arm shift.

Такой scheduler лучше любого фиксированного «instant recharge», потому что устраняет рассинхронизацию между aim, movement и generated commands.

---

# 10. Anti-aim и fake-angle path

## 10.1 Базовая структура

`0x4332D1C6` выполняет большой набор guards до изменения command:

- anti-aim master;
- local alive/entity/weapon state;
- movement type и special actions;
- buttons/use/attack/grenade-related conditions;
- текущий exploit/movement state;
- совпадение исходных command angles с snapshot.

Подтвержденные offsets:

- `CUserCmd +0x0C` — pitch;
- `CUserCmd +0x10` — yaw;
- `CUserCmd +0x30` — buttons;
- context snapshot `+0x20/+0x24` — входные pitch/yaw.

Проверка snapshot важна: native AA не должен безусловно затирать angles, уже изменённые Ragebot или другим command stage.

## 10.2 Pitch

Dispatcher `0x4332D7AA` выбирает несколько pitch sources:

- сохраненное/default значение;
- fixed/custom integer;
- sign-inverted value;
- entity/animation-derived bounded value;
- special weapon/state path;
- random/alternative branch.

Final pitch write:

```text
0x4332D8D9 -> [CUserCmd + 0x0C]
```

Поэтому patch одного значения pitch возможен, но ломать dispatcher целиком нецелесообразно: отдельные branches существуют для weapon/use/special command states.

## 10.3 Yaw base и jitter

После pitch код строит base yaw и применяет mode-specific jitter/offset. Видны варианты:

- alternating side по internal counter;
- fixed signed offset;
- trigonometric/sway-like offset;
- 12-step table sequence;
- entity/last-aim-relative base.

`LastAimCmd`/`LastAimPoint` используются для сохранения shot-related direction. Это подтверждает, что Ragebot shot angle и AA должны быть в одном command pipeline.

## 10.4 Real/fake и send/choke

Command context содержит указатель на final/send bool в `context +0x08`. Anti-aim несколько раз пишет через него `0`, например `0x4332E62A`, `0x4332EBB6`, `0x4332EC5E`.

Branches сравнивают:

- текущий choke `context +0x15C`;
- choke/command limit `context +0xFC`;
- current send bool;
- exploit flags;
- animation-derived yaw bounds.

Код получает min/max desync constraints, нормализует углы вокруг `-180..180`, выбирает real/fake side и может принудительно choke-нуть command, пока limit не достигнут.

State flags в `this +0x128` участвуют в выборе branches. Заменить всё одним `cmd.yaw = value` без сохранения flags/send state — значит потерять fake-angle semantics.

## 10.5 Defensive/exploit interaction

Core exploit method `0x433CE4BC` при charged mode `3` имеет отдельный angle path: он может выставить pitch около `89` и изменить yaw на псевдослучайный/command-derived offset. Это не обычный UI jitter, а exploit-coupled behavior.

Следовательно:

- defensive AA зависит от charge/mode;
- AA зависит от final send/choke;
- DT/recharge patch может изменить момент, когда defensive branch активируется;
- независимый Lua AA легко перезапишет Ragebot shot или native defensive angle на неверном command.

## 10.6 Что улучшать в anti-aim

Наиболее реалистичная архитектура:

1. вычислить base yaw;
2. определить shot command и не затирать Ragebot angle;
3. получить final exploit mode/charge;
4. получить current choke и final send decision;
5. на choked command строить real yaw;
6. на sent command строить fake yaw;
7. заморозить side на всю shift sequence, чтобы generated commands не получили противоречащие стороны;
8. после final angles выполнить movement correction;
9. сохранять telemetry по command number, real/fake side и exploit mode.

Улучшение defensive AA должно находиться после planner decision, но до окончательной упаковки commands. В старом GameSense Lua это можно приблизить через `setup_command`, однако полностью повторить native ordering без hook невозможно.

---

# 11. Что можно реализовать на практике

## 11.1 Простые exact-build patches

Можно относительно надёжно сделать при обязательном byte preflight и restore:

- менять hitbox scan order;
- включать head-first scan;
- strong center priority;
- center-only gate;
- strong configured-safe candidate через подтвержденный bit `23`;
- менять HC worker partition только на `8/16/32/64`;
- управлять отдельными recharge branches вместо полного 29-byte bypass;
- показывать native state/telemetry.

Lua-часть реализована в `unified_aimbot_helper.lua`; exact-image control-flow hooks, fallback rescore, broken-LC guard, adaptive damage и early-stop реализованы отдельно в `FemboySense/skeet/Native/native_rage.cpp`.

## 11.2 Требует native hook/trampoline

Для содержательного улучшения нужны hooks:

- пересчёт `+0xE4` после point fallback;
- единая head/safe/center/lethal priority policy;
- динамический record score с predicted flags;
- resolver confidence по matrix slot;
- selective DT recharge policy;
- единый stop/fire/shift scheduler;
- packet-aware AA с сохранением native shot commands.

## 11.3 Что нельзя качественно сделать обычным Lua

Без доступа к internal matrices/records нельзя полноценно заменить:

- native multipoint/autowall scanner;
- matrix-safe geometry;
- resolver slot selector;
- lag-record reconstruction;
- command cloning/shift generation;
- точный final send-packet stage.

`plist Force body yaw` может быть полезным coarse override, но это не порт `0x4337CB8A`. Аналогично Lua `cmd.in_attack` shooter не заменяет native firing pipeline.

---

# 12. Приоритетный план улучшений

## Этап 1 — telemetry, без изменения решений

Логировать на каждый shot:

- target/record age и preparation flags;
- primary/fallback point;
- hitbox/damage/safe/HC;
- packed score `+0xE4`;
- resolver mode/cycle/slot;
- outcome code `0..3`;
- DT mode/budget/target/charge/ring/choke;
- final send bool;
- AA real/fake side.

Без этого оптимизация resolver/DT будет оцениваться по ощущениям и смешивать spread, occlusion и resolver misses.

## Этап 2 — Ragebot correctness

1. Исправить stale score после secondary/tertiary fallback.
2. Добавить unified priority policy.
3. Оставить head-first только как scan optimization.
4. Не отключать multipoints полностью по умолчанию.

## Этап 3 — Record selection

1. Весить predicted records, не bypass-ить validation.
2. Учитывать время на stop/shot schedule.
3. Отбрасывать record, который станет invalid раньше planned fire command.

## Этап 4 — Resolver

1. Использовать только outcome `0` как resolver evidence.
2. Вести decayed confidence по трём slots.
3. Сохранять native geometry selector и reset rules.
4. Не путать resolver enable byte с matrix correction.

## Этап 5 — DT и quick stop

1. Ввести один readiness predicate для aim/stop/weapon/charge/record.
2. Сохранять ring/budget accounting.
3. Сделать recharge bypass выборочным.
4. Не превышать target `15`.

## Этап 6 — Anti-aim

1. Привязать real/fake к final send decision.
2. Не затирать LastAimCmd.
3. Freeze side на shifted sequence.
4. Defensive angles включать только при подтвержденном charged exploit state.

---

# 13. Что не следует делать

- Называть resolver-enable byte «улучшенным resolver».
- Считать head-first table гарантией final head shot.
- Принудительно стрелять в broken-LC record без rebuild/validity.
- Выставлять arbitrary HC worker count, например `48` или `>64`.
- Поднимать shift выше `15` в этой реализации.
- Считать 29-byte patch полным recharge algorithm.
- Обнулять все DT restrictions, не учитывая ring и budget rollback.
- Писать один fake yaw независимо от send/choke/shifted commands.
- Делать отдельный Lua shooter через `cmd.in_attack`, конкурирующий с native Ragebot.

---

# Итог

Да, эту build можно улучшить заметно. Наибольший ожидаемый эффект дают:

1. исправление score mismatch после fallback point;
2. единая, а не разрозненная head/safe/center policy;
3. outcome-aware resolver по реальным matrix slots `{1,2,0}`;
4. DT scheduler, который ждёт одновременно stop, weapon, charge и valid record;
5. packet-aware anti-aim, не конфликтующий с Ragebot и defensive shift.

Самые простые патчи — scan order, center/safe score и HC workers — уже хорошо локализованы. Но «лучший resolver», корректный adaptive DT и стабильный defensive AA требуют native hooks и общей state machine, а не набора независимых one-byte patches.

---

# 14. Сверка с публичными Skeet/GameSense Lua-коллекциями

После основной реверсии выполнен дедуплицированный статический поиск по крупным workshop dumps и публичным Lua-репозиториям. Проверялись `VirtualProtect`/FFI writes, Rage/HC/min-damage/Quick Stop, lagcomp/extrapolation, AI-peek, jump-stop, `aim_fire` metadata и `plist` resolver scripts.

## 14.1 Что было найдено

- Защищённые memory writes в наиболее заметных скриптах в основном устанавливают VMT hooks, generic detours, меняют animation layers или renderer state. Exact-image Rage scanner patch среди них не подтверждён.
- Adaptive weapon systems синхронизируют UI: damage, hitchance, accuracy boost и Quick Stop options. Это конфигурационные профили, а не новый scanner/readiness path.
- `aim_fire.teleported`, `interpolated`, `extrapolated` и `high_priority` используются преимущественно для логов. Они полезны как telemetry, но не указывают адрес producer.
- Force-body-on-peek и AI-peek экстраполируют позиции и делают `trace_bullet` в несколько hitboxes. Это годится как ранний внешний сигнал, но не заменяет native point damage, record validation и matrix-safe geometry.
- Jump-stop по `cmd.quick_stop` или ESP flag `LOCAL_HITTABLE` зависит от provider API и не переносится в supplied image как exact native patch.
- Публичные resolver scripts обычно отключают native correction и перебирают фиксированные yaw offsets после miss. Это слабее штатного matrix/record pipeline и не было перенесено.

## 14.2 Что реально принято

В `unified_aimbot_helper.lua` добавлен выключенный по умолчанию `Predictive pre-stop from bullet trace`:

1. берётся current threat, а при отсутствии API — не больше двух ближайших врагов;
2. local eye и enemy hitboxes временно экстраполируются на `1..4` ticks без записи в entity properties;
3. hitboxes проверяются в порядке head → все legs/feet → stomach/chest → remaining arms;
4. damage сравнивается с активным configured minimum; значения `101..126` сохраняют GameSense semantics `HP+1..HP+26`, lethal damage допускается;
5. при qualifying trace выставляется только проверенный `MoveFlags |= 0x8`;
6. отдельная опция может отменить новый jump только когда local player находится на земле.

Это companion-сигнал до scanner, а не новый нативный hook. Основной `NativeRage` уже запрашивает stop на первом реально просканированном qualifying point и дополнительно валидирует broken-LC final candidate. Поэтому Lua predictor не обязателен, не меняет native priority и не мутирует чужой origin.

## 14.3 Итог поиска

Ни один дополнительный публичный memory patch не прошёл одновременно три условия: точный адрес в supplied image, подтверждённые исходные байты и доказанная совместимая Rage-семантика. По этой причине `native_rage.cpp` не пополнен спекулятивными адресами. Стабильность exact-image transaction и fail-closed preflight оставлены важнее неподтверждённых «улучшений».

---

# 15. Общая карта movement-команд

## 15.1 Подтверждённый layout `CUserCmd`

| Offset | Поле |
|---:|---|
| `+0x04` | command number |
| `+0x0C/+0x10/+0x14` | pitch/yaw/roll |
| `+0x24/+0x28/+0x2C` | forwardmove/sidemove/upmove |
| `+0x30` | buttons |
| `+0x40` | вероятный `mousedx` (`WORD`); семантика подтверждена слабее остальных полей |

Используемые button bits:

```text
IN_ATTACK    = 0x00000001
IN_JUMP      = 0x00000002
IN_DUCK      = 0x00000004
IN_FORWARD   = 0x00000008
IN_BACK      = 0x00000010
IN_MOVELEFT  = 0x00000200
IN_MOVERIGHT = 0x00000400
IN_ATTACK2   = 0x00000800
IN_BULLRUSH  = 0x00400000
```

Связанные функции:

- `0x4332B300..0x4332B56A` — command sanitation/clamping;
- `0x433B7FE9..0x433B845B` — базовая movement correction после изменения углов;
- `0x433B8974` — используемый grenade callbacks вариант correction;
- `0x43388405..0x43388703` — counter-movement/stop helper;
- `0x433AC9C0` — physical movement resolver, а не простой setter;
- `0x4336F912..0x4337CAA9` — крупный combined movement processor.

Нельзя безопасно менять movement только записью углов: штатные grenade, Rage и anti-aim paths после изменения view angles отдельно восстанавливают или пересчитывают forward/sidemove.

---

# 16. Air Strafe

## 16.1 Object и dispatch

Movement object строится около `0x4348FA90`. Secondary interface находится по `outer+0x08`, его vtable — `0x43470770`.

Подтверждённые slots:

| Slot | Метод | Статус |
|---:|---:|---|
| `+0x04` | `0x4333F746` | directional-button conflict resolver + full-scale movement synthesis; также adjacent `IN_BULLRUSH` injection |
| `+0x08` | `0x4334659B` | movement callback |
| `+0x10` | `0x433D1F99` | late hotkey-gated synthetic `IN_JUMP`; EdgeJump-like behavior, точное UI-имя не доказано |
| `+0x24` | `0x433D2AAC` | movement-related callback |

Основной Air-Strafe path находится не в этих маленьких callbacks, а внутри `0x43372CA2..0x4337C883` combined processor.

## 16.2 Подтверждённая математика

Master gate — `outer+0x2C`. Поле `outer+0x40` выбирает между двумя рабочими algorithm branches; оно не является master enable.

Для обычного steering path вычисляется:

```text
horizontal_speed = sqrt(velocity.x² + velocity.y²)
ideal_angle = min(90.0, 845.5 / horizontal_speed)
```

Объектные constants:

| Offset | Stock value |
|---:|---:|
| `outer+0x1C0` | `845.5f` |
| `outer+0x1C4` | `450.0f` |
| `outer+0x1C8` | `90.0f` |
| `outer+0x1CC` | `15.0f` |
| `outer+0x1D0` | `30.0f` |
| `outer+0x1D4` | `60.0f` |
| `outer+0x1D8` | `286.0f` |

`450.0f` используется как magnitude бокового движения. Код нормализует angular delta, выбирает знак sidemove и меняет внутреннюю сторону после записи:

- `0x4337C52A` и `0x4337C871` — записи `cmd.sidemove`;
- `0x4337C876..0x4337C87C` — toggle направления.

Дополнительные state/config fields:

- `outer+0x54` — mode bits;
- `outer+0x158` — future/collision simulation option;
- `outer+0x1C8=90`, тогда как `286` находится именно в `outer+0x1D8`.

## 16.3 Ограничения и безопасные измерения

Пока не восстановлены полные semantics mode bits, альтернативной ветки и collision simulation, менять `845.5`, `450` или direction branch нельзя считать безопасным улучшением. Наиболее полезная read-only telemetry:

1. входной horizontal speed;
2. `ideal_angle` до/после clamp;
3. выбранный branch `outer+0x40`;
4. mode mask `outer+0x54`;
5. итоговый `cmd.sidemove` и toggle side;
6. факт collision/future-simulation correction.

Это позволит отдельно измерить потерю скорости из-за steering и из-за collision override. Blind patch `450` либо divisor без такой разбивки может увеличить oscillation и ухудшить сохранение скорости.

## 16.4 Bunny-hop-like jump maintenance

Внутри того же combined processor найден отдельный подтверждённый jump-maintenance path:

```text
0x43372D3A: cmp byte [movement_outer+0x194], 0
...
0x43372D64: and dword [CUserCmd+0x30], 0xFFFFFFFD
```

Reachable условия перед очисткой `IN_JUMP`:

- local entity находится не на земле (`flags & 1 == 0`);
- normal movement/movetype guards пройдены;
- `movement_outer+0x194` включён;
- encrypted integer ConVar в `0x43372D43..0x43372D5E` декодируется как zero.

Последняя проверка реализована характерным для image способом: значение ConVar в `root+0x30` XOR-ится самим pointer; zero поэтому выглядит как сравнение `[root+0x30] == root`. Строковое имя ConVar в raw image не восстановлено. По behavior это canonical bunny-hop fallback: если server-side auto-bhop не включён, удерживаемый jump снимается на airborne commands и снова может быть поставлен вводом/следующим command после касания земли.

Соседний clear в `0x43372D31` — другой механизм, не Bunny Hop. Он достижим на земле, при `movement_state_flags & 0x8`, active weapon ID `31` (Taser) и уже установленном `IN_JUMP`; branch одновременно снимает state bit `0x8` и `IN_JUMP`. Это Taser-specific jump suppression/conflict path.

Тот же gate `outer+0x194` имеет второй consumer `0x43379527`: при отдельном успешно прошедшем simulated-movement path он пишет stock `outer+0x1C4 = 450.0f` в `cmd.forwardmove` (`0x43379538..0x43379540`). Поэтому поле можно функционально назвать bunny-hop/air-movement integration gate, но его точное UI-имя пока не следует считать доказанным.

Классификация всех ранее найденных nearby `IN_JUMP` sites:

| Site | Semantics |
|---|---|
| `0x4336FA5F` | early jump exclusion: ветка stop/duck logic выполняется только если jump не нажат |
| `0x43371D7C` | on-ground jump exclusion перед slow-stop block |
| `0x43372D1E..0x43372D31` | Taser ID 31 conflict branch; clear jump и internal request bit |
| `0x43372D64` | real-command airborne Bunny-hop-like clear |
| `0x43373A1A` | simulated-movement branch требует already-present jump; не mutation |
| `0x433A1A4C` | simulator mirror airborne clear с тем же `outer+0x194`/ConVar gate |
| `0x433A22F5` | simulator jump-presence gate; не mutation |
| `0x433D1FDB..0x433D1FDE` | отдельный late EdgeJump-like synthetic set, §16.5 |

Таким образом, из этих sites только `0x43372D64`/mirror относятся к удержанию Bunny Hop, `0x433D1FDB` ставит jump, а остальные являются exclusions/guards либо Taser conflict handling.

Изолированно NOP-ить `and ~IN_JUMP` не рекомендуется: это обходит server-ConVar guard и оставляет второй consumer `forwardmove=450` в другом состоянии. Для измерений достаточно логировать ground flag, decoded ConVar boolean, gate `outer+0x194`, входной/выходной jump bit и позднюю запись forwardmove.

## 16.5 Edge-jump-like late callback

Ранее неклассифицированный movement vtable slot `+0x10` теперь восстановлен до command mutation. Entry `0x433D1F99` вызывается как primary phase `+0x10`; поскольку interface расположен в `movement_outer+8`, его обращение `[this+0x1A0]` соответствует `movement_outer+0x1A8`.

Упрощённый exact flow `0x433D1F99..0x433D1FE1`:

```cpp
if (movement_outer->field_1A8 && hotkey_4346760C()) {
    if (!(cmd->buttons & IN_JUMP) &&
        (state->field_F8 & 1) &&
        !(state->field_00 & 0x40000)) {
        cmd->buttons |= IN_JUMP;
    }
}
```

Set sequence:

```text
0x433D1FDB: 83 C8 02       or eax, IN_JUMP
0x433D1FDE: 89 41 30       mov [cmd+0x30], eax
```

Это не Bunny Hop из §16.4: там airborne command очищается; здесь поздний hotkey-gated callback, наоборот, синтезирует jump на command при комбинации двух transition/state bits. По месту в post-prediction dispatcher и behavior это сильнее всего соответствует Edge Jump. Однако точная семантика `state+0xF8 bit 0` и `state+0x00 bit 0x40000`, а также исходное UI-имя не доказаны символами; поэтому в таблице механизм помечен как **EdgeJump-like**, не как окончательно названная UI option.

Следом `0x433D1FE1..0x433D1FEA` другой независимый gate (`this+0x1D4`, то есть `outer+0x1DC`) ставит `state+0x00 bit 0x80`; его нельзя объединять с jump set без отдельного анализа.

Безопасная preflight telemetry для EdgeJump-like path: gate/hotkey, оба state bit до callback, `cmd.buttons` до/после и local ground flag из соседней prediction stage. Патчить state masks до их runtime correlation не следует.

## 16.6 Directional-button resolver и `IN_BULLRUSH`

Primary movement slot `+0x04`, `0x4333F746..0x4333F8DF`, теперь классифицирован по фактическим writes; прежняя slide-walk гипотеза слишком неточна.

Callback сначала условно добавляет `IN_BULLRUSH`:

```text
0x4333F746: cmp byte [0x43467CEC], 0
0x4333F75A: or edx, 0x00400000
0x4333F760: mov [cmd.buttons], edx
```

Затем отдельный gate `[this+0x128]`, то есть `movement_outer+0x130`, включает обработку direction bits `0x618` (`IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT`). Stock алгоритм:

1. вычисляет newly-pressed bits как `(previous ^ current) & current`;
2. обновляет persistent suppression mask, удаляя противоположное направление для каждой новой нажатой пары;
3. делает `cmd.buttons &= ~suppression_mask`;
4. по оставшимся direction bits синтезирует analog movement с модулем `movement_outer+0x1C4 = 450.0f`:
   - left/right → `sidemove=-450/+450`;
   - forward/back → `forwardmove=+450/-450`;
5. сохраняет исходные buttons в `movement_outer+0x1E0` и рабочую mask в `movement_outer+0x1E4`.

Это не доказанный Slide Walk: направление analog movement соответствует оставшимся command buttons, а opposite bits удаляются, не подставляются. Функционально это directional conflict resolver/full-scale key movement normalizer. Точное UI-имя gate `outer+0x130` не восстановлено.

`IN_BULLRUSH` branch расположен рядом, но не зависит от `outer+0x130`; source byte `0x43467CEC` должен логироваться отдельно. Его isolated force-on patch не рекомендуется без crouch/stamina telemetry.

## 16.7 Slow-motion/autostop controller и triangle dither

В `0x43371E8F..0x4337205C` восстановлен общий stop/slow-motion entry. Он активируется одним из двух источников:

- user gate `movement_outer+0x180` вместе с indirect hotkey wrapper `0x434684AC/0x434684C0`;
- internal request `movement_state_flags & 0x40` в `0x434759C0` — то есть тот же controller переиспользуется другими системами, включая nearby stop logic.

Path обновляет internal flags, получает два runtime scalar, сводит их через NaN-safe minimum helper `0x43367633` и строит command-number-dependent target:

```text
m     = nan_safe_min(runtime_scalar_entity, runtime_scalar_virtual)
phase = (cmd.command_number % 1000) * interval_per_tick * 7.0
tri   = abs(phase - floor(phase) - 0.5) * 2.0 * 4.0
limit = (m - 1.0) * 0.34 - tri
```

Подтверждённые constants:

| Address | Value | Use |
|---|---:|---|
| `0x43472144` | `0.34f` | `(m-1)*0.34` |
| `0x4346EF2C` | `7.0f` | phase frequency |
| `0x43472240` | `0.5f` | triangle centre |
| `0x4346DD40` | `4.0f` | triangle amplitude |

Полученный `limit`, current velocity и command передаются в physical movement controller `0x43340ACB`; call site общего tail — `0x4337CA9F`. Helper:

- пропускает jump commands;
- считает current command movement и horizontal velocity magnitudes;
- при `abs(delta) < 0.5` обнуляет forward/sidemove;
- иначе строит counter/current direction в command space и может использовать stock `450.0f` (`0x43340D7A`) для full counter-movement;
- имеет отдельные ветви для отрицательного и положительного target delta.

Функционально это подтверждённый shared velocity controller с периодическим micro-speed dither. Связь explicit gate `outer+0x180` со Slow Motion/Fake Walk очень сильна, но точное UI-имя по raw image не доказано; internal `0x40` consumer нельзя считать исключительно Ragebot autostop без runtime producer trace.

Практический предел stock реализации — dither привязан к `command_number`, а не к измеренной convergence/error history. Для улучшения предпочтительнее read-only лог `m/phase/tri/limit/current_speed/output_move`, затем per-call policy перед `0x43340ACB`; shared constants `7.0/4.0/0.34` имеют другие xref и глобально патчиться не должны.

---

# 17. Grenade object: интерфейсы и разделение двух механизмов

## 17.1 Constructor и vtables

Constructor grenade object начинается около `0x4348675E`; основной reachable body — `0x43486761...`.

| Object offset | Vtable | Подтверждённая роль |
|---:|---:|---|
| `+0x00` | `0x4346F8B0` | primary grenade interface |
| `+0x08` | `0x4346F0AC` | command/grenade processor interface |
| `+0x10` | `0x434704BC` | одноэлементный дополнительный command callback |
| `+0x18` | `0x4346FE58` | trajectory/prediction renderer callback |
| `+0x20` | `0x4346DC78` | adjacent interface |
| `+0x28` | `0x43470150` | adjacent interface |
| `+0x30` | `0x434727FC` | adjacent interface |

Ключевые methods:

- primary vtable slot `+0x24` (`0x4346F8D4`) → `0x433E76A9`, exact velocity-compensation solver;
- `0x4346F0AC +0x08` → `0x43383139`, применение сохранённого auto-toss solution;
- `0x4346F0AC +0x10` → `0x4338AD80`, большой grenade processor;
- `0x434704BC +0x00` → `0x4337DA8B`, второй application callback;
- `0x4346FE58 +0x00` → `0x433BA5DF`, trajectory/prediction renderer.

Vtable bytes для preflight:

```text
0x4346F8D4: A9 76 3E 43  -> 0x433E76A9
0x4346F0B4: 39 31 38 43  -> 0x43383139
0x4346F0BC: 80 AD 38 43  -> 0x4338AD80
0x434704BC: 8B DA 37 43  -> 0x4337DA8B
0x4346FE58: DF A5 3B 43  -> 0x433BA5DF
```

## 17.2 Важное уточнение классификации

Binary data flow показывает два связанных, но независимых механизма:

1. **velocity compensation / Super-Toss math** — gate `outer+0x68`, solver `0x433E76A9`; корректирует throw angles с учётом скорости игрока;
2. **автоматический planner броска** — enable `outer+0x138`, hotkey wrapper `outer+0x13C`, grenade-type mask `outer+0x1DC/+0x1E0`; строит, симулирует, оценивает и сохраняет полный command candidate.

Второй механизм вызывает первый во время симуляции, но его enable/hotkey и persistent solution принадлежат отдельному control-flow. Поэтому называть весь блок `0x4338E529..0x433934E0` только «quadratic Super Toss» было неточно. Точное UI-имя automated planner из stripped image не доказано; ниже он называется **auto-toss planner** по фактическому поведению.

---

# 18. Exact velocity-compensation / Super-Toss solver

## 18.1 Адрес, ABI и callers

Solver: `0x433E76A9..0x433E79E2`, 826 bytes.

Начальные bytes:

```text
55 8B EC 83 E4 F0 83 EC 28 56 57 8B 7D 0C 8B F1
```

Функциональная сигнатура:

```cpp
// thiscall/stdcall hybrid used by the image
// ECX = grenade outer object
// XMM0 = effective throw speed s
// arg1 = const Vec3* player_velocity
// arg2 = QAngle* in_out_throw_angles
void compensate_throw_velocity(float s,
                               const Vec3* player_velocity,
                               QAngle* in_out_throw_angles);
```

`EDX` в найденном body не участвует в вычислении. Функция возвращает с `ret 8` и изменяет только pitch/yaw; roll не перезаписывается.

Подтверждённые invocation sites:

| Site | Назначение |
|---:|---|
| `0x4338EF23` | compensation внутри построения/simulation candidate |
| `0x433938F9` | compensation фактического `CUserCmd` в хвосте grenade processor |
| `0x433BAD0A` | тот же solver в trajectory/prediction rendering path |

Это важно: prediction и command application используют одну и ту же virtual function, поэтому stock визуальная траектория согласована с фактической angle correction.

## 18.2 Exact object coefficients

Constructor записывает:

| Field | Value | Constructor site / expected bytes |
|---:|---:|---|
| `outer+0x3C` | `0.25f` | `0x434867F2: C7 43 3C 00 00 80 3E` |
| `outer+0x40` | `25.0f` | `0x434867F9: C7 43 40 00 00 C8 41` |
| `outer+0x44` | `16.0f` | `0x43486800: C7 43 44 00 00 80 41` |
| `outer+0x48` | `5.0f` | `0x43486807: C7 43 48 00 00 A0 40` |
| `outer+0x4C` | `1.25f` | `0x4348680E: C7 43 4C 00 00 A0 3F` |

Они читаются непосредственно в `0x433E7831..0x433E78E9`. Это уже не внешняя corroboration, а exact instruction path supplied image.

## 18.3 Восстановленная математика

Обозначения:

- `f` — нормализованный forward vector из входных pitch/yaw;
- `u` — player velocity;
- `v = |u|`;
- `d = dot(normalize(-u), f)`;
- `s` — effective throw speed.

Stock solver вычисляет:

```text
R = 25*d²*v² + 16*s² - 25*v²
A = 0.25 * (sqrt(R) - 5*v*d)
q = (A*f - 1.25*u) / s
```

После этого `q` переводится обратно в angles:

```text
yaw   = atan2(q.y, q.x) * 180/pi
pitch = atan2(-q.z, sqrt(q.x² + q.y²)) * 180/pi
```

Для вертикального vector есть special case с `90/270` degrees. Нормализация векторов использует denominator `length + FLT_EPSILON`, где `FLT_EPSILON` читается по `0x43472108` (`1.1920929e-7f`). Перед записью функция отвергает non-finite pitch/yaw через проверку exponent mask `0x7F800000`.

Алгебраически:

```text
R = 16 * (s² - (1.25 * |u_perpendicular_to_f|)²)
```

То есть реальное физическое условие существования решения:

```text
s >= 1.25 * |u_perpendicular_to_f|
```

Если lateral inherited velocity слишком велика для выбранной throw strength, `sqrtss` получает отрицательный radicand. Stock code не clamp-ит radicand и не имеет отдельной ветки retry; final finite guard просто не записывает новые pitch/yaw.

## 18.4 Caller gates

Во всех подтверждённых paths solver вызывается только если:

- `outer+0x68 != 0`;
- player-velocity squared больше `4.0f`, то есть `|u| > 2 units/s`;
- соответствующий entity/weapon state доступен.

До solver-а caller вычитает three-component vector, полученный через `0x433AE483`, из throw angles. По поведению это punch/recoil-like correction, но точное исходное имя vector field из stripped image всё ещё не доказано.

В final command path:

- gate/angle subtraction: `0x4339375B..0x433937AF`;
- velocity threshold: `0x433937C4..0x43393802`;
- effective-speed reconstruction: `0x43393823..0x433938BE`;
- virtual solver call: `0x433938F9`.

## 18.5 Effective throw speed — binary confirmation

Три independent paths (`0x4338EDBE`, `0x4339383E`, `0x433BABC9`) подтверждают одну формулу:

```text
base = clamp(raw_throw_velocity * 0.9, 15.0, 750.0)
strength = clamp(throw_strength, 0.0, 1.0)
s = base * (0.7 * strength + 0.3)
```

Exact constants:

| Address | Float | Xref count in image |
|---:|---:|---:|
| `0x43472738` | `0.9f` | 27 |
| `0x4346FF70` | `15.0f` | 9 |
| `0x43472614` | `750.0f` | 3 |
| `0x4346FD8C` | `0.7f` | 53 |
| `0x4346ED98` | `0.3f` | 16 |

`raw_throw_velocity` приходит через decoded weapon-property call `0x433E533F` и возвращается через x87 stack. Throw strength берётся из weapon/entity state; ранний candidate path дополнительно моделирует переход strength на основании текущих attack buttons и tick interval.

Глобальные floats имеют много несвязанных xrefs. Поэтому запись новых значений прямо в эти addresses **не является узким grenade patch**. Если потребуется эксперимент, безопаснее detour конкретного solver/call site либо private constants, а не изменение shared data.

## 18.6 Stock limitations и полезная telemetry

Подтверждённые ограничения:

1. При `|u| <= 2` compensation не вызывается; погрешность мала, но это дискретная граница.
2. Negative radicand не получает retry/alternate strength; функция сохраняет входные angles.
3. Solver меняет только pitch/yaw и полагается на downstream movement correction/command pipeline.
4. Коэффициенты `0.25/25/16/5/1.25` алгебраически связаны; менять один из них отдельно математически некорректно.
5. Прямой patch общих constants `0.9/15/750/0.7/0.3` затронет другие subsystems.

Рекомендуемая read-only telemetry для каждого броска:

```text
raw_throw_velocity
throw_strength
s
player_velocity
parallel_velocity
perpendicular_velocity
R / feasibility margin
input angles
output angles
finite-write success
caller kind: candidate / command / renderer
```

При `R < 0` безопаснее отложить автоматический бросок, выбрать более сильный throw либо другой command/tick. Clamp `R` к нулю создаст физически неверное направление и не должен быть default patch.

---

# 19. Auto-toss planner, persistent solution и release scheduler

## 19.1 Gates и grenade types

Большой processor `0x4338AD80..0x43393919` вызывается через `0x4346F0AC +0x10`; его `this` указывает на `outer+0x08`.

Подтверждено:

- enable: `outer+0x138` (`0x4338E529` читает `[this+0x130]`);
- hotkey wrapper: начинается с `outer+0x13C`, invocation использует internal object около `outer+0x14C`;
- grenade type bitset: `outer+0x1DC/+0x1E0 = {0, 0x17800}`;
- подтверждённые IDs: `43, 44, 45, 46, 48`;
- action gate требует `IN_ATTACK|IN_ATTACK2` mask `0x801`;
- candidate path начинается с `0x4338EA50`.

`0x4338EA50..0x43393469` строит launch state, моделирует trajectory/collisions, перебирает/валидирует candidates и выставляет score. Участок `0x43392800..0x43393469` — поздняя path/collision validation и scoring уже построенного candidate, а не quadratic solver.

## 19.2 Persistent solution

Успешный commit начинается в `0x433934AD`.

Expected leading bytes:

```text
8B 94 24 B4 00 00 00
8D 77 14
8B 84 24 B0 00 00 00
8D BA 70 01 00 00
81 60 30 FE F7 FF FF
3B FE 74 05 6A 19 59 F3 A5
```

`rep movsd` копирует `0x19` DWORD, то есть `0x64` bytes, из локального candidate record в `outer+0x178`. Затем current tick отдельно записывается в `outer+0x180`, перезаписывая соответствующее поле copied block.

Подтверждённые persistent fields:

| Offset | Роль |
|---:|---|
| `outer+0x178` | начало сохранённого record |
| `outer+0x180` | command/tick timestamp |
| `outer+0x184/+0x188/+0x18C` | saved angles |
| `outer+0x19C` | saved forwardmove |
| `outer+0x1A0` | saved sidemove |
| `outer+0x1A8` | saved buttons |

Перед commit у buttons удаляются `IN_ATTACK|IN_ATTACK2` через mask `~0x801`.

## 19.3 Application callbacks

`0x43383139`:

- повторно проверяет enable/hotkey/grenade type;
- проверяет возраст solution;
- восстанавливает saved angles, forwardmove, sidemove и buttons;
- очищает attack mask `0x801` в используемом варианте;
- вызывает movement correction `0x433B8974`.

`0x4337DA8B`:

- является единственным slot vtable `0x434704BC` для subobject `outer+0x10`;
- повторяет enable/hotkey/type/age gates;
- очищает `IN_ATTACK|IN_ATTACK2`;
- восстанавливает angles;
- выполняет movement correction.

Revalidation window:

```text
abs(saved_tick - current_tick) < round(0.25 / interval_per_tick)
```

Exact static dispatcher ordering восстановлен через registration vectors и общий dispatcher `0x433D2E40..0x433D59FE`:

1. constructor `0x433F10DB` регистрирует subobject `outer+0x10` в vector `0x43475978..0x4347597C`;
2. dispatcher `0x433D2F59..0x433D2F8E` вызывает slot `+0x00`, то есть `0x4337DA8B` для grenade object (`call` в `0x433D2F7D`);
3. constructor `0x43345EBC` регистрирует primary subobject `outer+8` в vector `0x434757A0..0x434757A4`;
4. тот же dispatcher вызывает primary slot `+0x08`, то есть `0x43383139`, в `0x433D349B`;
5. позднее он вызывает primary slot `+0x10`, то есть processor `0x4338AD80`, в `0x433D4E3F`.

Следовательно, для callbacks, достигнутых в одном проходе, доказанный relative order:

```text
0x4337DA8B  ->  0x43383139  ->  0x4338AD80
```

Это статический порядок dispatch phases; individual gate/early return внутри каждого callback по-прежнему может сделать конкретную stage no-op. Runtime trace полезен для command-level state transition, но больше не нужен для определения относительного порядка этих трёх entry points. Удалять одну из application stages или изолированно NOP-ить очистку `0x801` всё равно небезопасно: обе application stages исполняются до planner/processor и имеют разные gate/restore effects.

## 19.4 Release scheduler

Scheduler state находится в `outer+0x54` (относительно processor `this=outer+8` это `this+0x4C`).

Ключевой участок `0x433935DF..0x43393629` сравнивает текущий command number со scheduled value и `scheduled+1`:

- на одном command меняет внешний release/send state и ставит context flag;
- на следующем возвращает состояние/фиксирует связанный context;
- ранний path около `0x433935A2` может назначить scheduler на `current_command+1`.

Это двухcommand protocol, а не одиночное снятие `IN_ATTACK`. Патч только одного `and ~0x801` либо только одного byte state способен рассинхронизировать planned throw, prediction и фактический release.

### Связь с Jump Throw

В exact grenade processor `0x4338AD80..0x43393919` не найдено instruction, которое само ставит `IN_JUMP`. Processor читает/переносит `IN_ATTACK|IN_ATTACK2`, планирует их release и сохраняет/restores полный buttons field; поэтому уже присутствующий jump bit может пройти через candidate/persistent command, но отдельная синхронная генерация jump здесь не доказана.

Единственный подтверждённый late synthetic `IN_JUMP` в adjacent movement vtable — EdgeJump-like callback `0x433D1F99`, у которого отсутствует attack gate. Следовательно:

- scheduler `0x433935A2..0x43393629` доказан как grenade attack-release protocol;
- называть его полноценным standalone Jump Throw только по release timing нельзя;
- jump-throw behavior в runtime может получаться композицией user/other movement jump bit с этим release protocol, но эта композиция требует command-level trace;
- blind добавление `or [cmd.buttons], IN_JUMP` внутрь scheduler изменит throw origin/velocity и нарушит соответствие planner trajectory.

## 19.5 Практический вывод

Для grenade улучшений нужен такой порядок:

1. логировать candidate score, collision result и chosen tick;
2. логировать feasibility exact solver-а `R`;
3. на runtime trace проверить command-level state transitions в уже доказанном static order `0x4337DA8B -> 0x43383139 -> 0x4338AD80`;
4. только затем менять planner policy или release timing;
5. сохранять один и тот же solver для simulation, renderer и final command, иначе визуальная траектория станет расходиться с броском.

В текущем состоянии безопасны read-only hooks/telemetry. Изолированный patch shared constants, attack-bit clear либо scheduler branch пока не рекомендован.

---

# 20. Обновлённый приоритет movement/grenade работ

1. **Runtime callback state trace** — command number и входные/выходные buttons/angles в уже доказанном порядке `0x4337DA8B -> 0x43383139 -> 0x4338AD80`.
2. **Super-Toss feasibility telemetry** — `s`, `u_perp`, `R`, finite-write result.
3. **Auto-toss candidate telemetry** — source candidate, score, collision reject reason, commit tick.
4. **Air-Strafe/Bunny-hop telemetry** — speed, ideal angle, branch, mode, ground/jump bits, ConVar guard, sidemove и collision override.
5. После измерений — отдельный `NativeMovement`/`NativeGrenade` module с тем же transactional preflight, а не расширение `native_rage.cpp` спекулятивными writes.

Главные результаты этого movement/grenade pass:

- quadratic solver находится в `0x433E76A9`, вызывается через primary grenade vtable slot `+0x24` и согласованно используется в candidate simulation, final command и renderer;
- dispatcher order статически доказан как `0x4337DA8B -> 0x43383139 -> 0x4338AD80`;
- разделены airborne Bunny-hop clear, Taser jump conflict и late EdgeJump-like synthetic set;
- standalone Jump Throw внутри grenade processor не доказан: найден attack-release scheduler без собственного `IN_JUMP` write;
- восстановлен shared slow-stop controller с triangle dither и отдельный directional-button resolver.

Следующий безопасный этап — telemetry этих уже локализованных paths; shared state/constants и scheduler branches остаются read-only до command-level корреляции.
