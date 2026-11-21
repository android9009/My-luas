📦 CORE UI API
Функция	Назначение	Пример
ui.reference(tab, container, name)	Получить ссылку на элемент	local aa = ui.reference("AA", "angles", "enabled")
ui.new_combobox(tab, container, name, ...)	Создать выпадающий список	ui.new_combobox("AA", "angles", "mode", {"Normal", "Luasense"})
ui.new_slider(tab, container, name, min, max, default)	Создать слайдер	ui.new_slider("AA", "angles", "yaw", -180, 180, 0)
ui.new_button(tab, container, name, callback)	Создать кнопку	ui.new_button("AA", "angles", "Test", function() print("test") end)
ui.new_color_picker(tab, container, name, r,g,b,a)	Создать выбор цвета	ui.new_color_picker("AA", "angles", "color", 255,0,0,255)
ui.new_hotkey(tab, container, name, inline)	Создать хоткей	ui.new_hotkey("AA", "angles", "key", true)
ui.new_multiselect(tab, container, name, ...)	Мультивыбор	ui.new_multiselect("AA", "angles", "options", {"A","B","C"})
ui.new_textbox(tab, container, name)	Текстовое поле	ui.new_textbox("AA", "angles", "text")
ui.new_listbox(tab, container, name, ...)	Список	ui.new_listbox("AA", "angles", "list", {"A","B","C"})
ui.get(element)	Получить значение	local val = ui.get(slider)
ui.set(element, value)	Установить значение	ui.set(slider, 100)
ui.set_visible(element, bool)	Скрыть/показать	ui.set_visible(slider, false)
ui.set_callback(element, func)	Установить коллбэк	ui.set_callback(slider, function() end)
ui.is_menu_open()	Проверка открыт ли меню	if ui.is_menu_open() then
ui.mouse_position()	Позиция мыши	local x,y = ui.mouse_position()
ui.name(element)	Имя элемента	print(ui.name(slider))
pui.reference(tab, container, name)	Альтернативная ссылка	pui.reference("AA", "angles", "enabled")
pui.group(tab, container)	Создать группу	local grp = pui.group("AA", "angles")
pui.traverse(table, func)	Обход элементов	pui.traverse(menu, function(v) end)
element:depend({...})	Зависимости видимости	elem:depend({parent, value})
🎮 CLIENT/ENGINE API
Функция	Назначение
client.screen_size()	Разрешение экрана (x,y)
client.key_state(key)	Состояние клавиши (0x01=LMB)
client.exec(command)	Выполнить консольную команду
client.set_event_callback(event, callback)	Установить обработчик события
client.random_int(min, max)	Случайное целое число
client.random_float(min, max)	Случайное float число
client.color_log(r,g,b, text)	Цветной текст в консоль
client.current_threat()	Текущий враг (entity index)
client.userid_to_entindex(userid)	Конвертация userid в entindex
client.trace_line(skip_ent, x1,y1,z1, x2,y2,z2)	Трассировка луча
client.trace_bullet(ent, x1,y1,z1, x2,y2,z2, skip)	Трассировка пули
client.visible(x,y,z)	Проверка видимости точки
client.eye_position()	Позиция глаз локального игрока
client.camera_angles()	Углы камеры
client.camera_position()	Позиция камеры
client.draw_hitboxes(ent, duration, hitboxes)	Отрисовка хитбоксов
client.create_interface(module, interface)	Получить указатель на интерфейс
client.find_signature(module, signature)	Найти сигнатуру
client.timestamp()	Текущее время в миллисекундах
client.delay_call(delay, func)	Отложенный вызов
client.unix_time()	Unix время
client.register_esp_flag(name, color, func)	Регистрация ESP флага
client.update_player_list()	Обновить список игроков
🧠 ENTITY API
Функция	Назначение
entity.get_local_player()	Индекс локального игрока
entity.is_alive(ent)	Проверка жив ли игрок
entity.is_enemy(ent)	Проверка враг ли
entity.is_dormant(ent)	Проверка dormant состояния
entity.get_prop(ent, prop, offset)	Чтение свойства
entity.set_prop(ent, prop, value, offset)	Запись свойства
entity.get_origin(ent)	Координаты сущности (x,y,z)
entity.get_player_name(ent)	Никнейм игрока
entity.get_player_weapon(ent)	Хэндл текущего оружия
entity.get_classname(ent)	Имя класса (CKnife, CWeaponTaser)
entity.get_all(classname)	Все сущности класса
entity.get_players(enemies_only)	Список игроков
entity.hitbox_position(ent, hitbox)	Позиция хитбокса
entity.get_bounding_box(ent)	Bounding box сущности
entity.get_steam64(ent)	SteamID64 игрока
entity.get_game_rules()	Указатель на GameRules
entity.get_player_resource()	Указатель на PlayerResource
entity.get_view_model()	ViewModel игрока
entity.get_weapon_player(weapon)	Владелец оружия
entity.get_csgo_player_resource()	CS:GO PlayerResource
entity.get_player_icon(ent)	Иконка игрока (аватар)
⚙️ RENDER API
Функция	Назначение
renderer.rectangle(x,y,w,h, r,g,b,a)	Прямоугольник
renderer.gradient(x,y,w,h, r1,g1,b1,a1, r2,g2,b2,a2, vertical)	Градиент
renderer.circle(x,y, r,g,b,a, radius, start, percentage)	Круг/сектор
renderer.circle_outline(x,y, r,g,b,a, radius, start, percentage, thickness)	Контур круга
renderer.text(x,y, r,g,b,a, flags, size, text)	Текст
renderer.measure_text(flags, text)	Измерение текста
renderer.world_to_screen(x,y,z)	Конвертация 3D→2D
renderer.load_png(data, w, h)	Загрузить PNG
renderer.load_svg(data, w, h)	Загрузить SVG
renderer.texture(texture_id, x,y,w,h, r,g,b,a, filter)	Отрисовка текстуры
renderer.line(x1,y1, x2,y2, r,g,b,a)	Линия
renderer.triangle(x1,y1, x2,y2, x3,y3, r,g,b,a)	Треугольник
renderer.arc(x,y, radius, start_angle, end_angle, r,g,b,a, thickness)	Дуга
📊 GLOBALS API
Функция	Назначение
globals.tickcount()	Номер текущего тика
globals.curtime()	Текущее время игры (секунды)
globals.realtime()	Реальное время
globals.frametime()	Длительность кадра
globals.framecount()	Номер кадра
globals.chokedcommands()	Количество задержанных команд
globals.tickinterval()	Длительность тика
globals.mapname()	Имя текущей карты
globals.maxplayers()	Максимум игроков
globals.captureticks()	Ticks для захвата
💾 DATABASE API
Функция	Назначение
database.read(key)	Чтение значения
database.write(key, value)	Запись значения
database.delete(key)	Удаление ключа
🛠️ UTILITIES API
Функция	Назначение
bit.band(a,b)	Битовая AND
bit.bor(a,b)	Битовая OR
bit.bxor(a,b)	Битовая XOR
bit.lshift(a,b)	Сдвиг влево
bit.rshift(a,b)	Сдвиг вправо
bit.tohex(num)	Конвертация в HEX
ffi.cast("type*", ptr)	Приведение типа указателя
ffi.typeof(type)	Получить тип FFI
ffi.new(type)	Создать FFI объект
ffi.string(ptr, len)	Конвертация в строку
ffi.copy(dst, src, len)	Копирование памяти
json.stringify(table)	Сериализация в JSON
json.parse(json_str)	Парсинг JSON
clipboard.set(text)	Запись в буфер обмена
clipboard.get()	Чтение из буфера обмена
require("gamesense/http")	HTTP-запросы
require("gamesense/pui")	Кастомный UI
require("vector")	Векторная математика
require("gamesense/urface")	Surface функции
vtable_bind(module, interface, index, signature)	Биндинг vtable
🎯 SPECIAL API
Функция	Назначение
antiaim_funcs.get_double_tap()	Статус Double Tap
antiaim_funcs.get_hide_shots()	Статус Hide Shots
panorama.open()	Доступ к Panorama API
panorama.open().MyPersonaAPI.GetName()	Получить Steam имя
panorama.open().GameStateAPI.IsLocalPlayerPlaying()	Проверка игры
js.eval(code)	Выполнить JS код
js.SteamOverlayAPI.OpenExternalBrowserURL(url)	Открыть URL в оверлее
engine.execute_cmd(command)	Выполнить команду движка
engine.get_player_for_user_id(userid)	Получить игрока по userid
engine.get_view_angles()	Получить углы обзора
engine.set_view_angles(pitch, yaw)	Установить углы обзора
🔧 CUSTOM HELPERS (из твоего скрипта)
Функция	Назначение
render:rect(x,y,w,h, clr, rounding)	Скругленный прямоугольник
render:new_anim(name, target, speed)	Анимация значения
render:measuret(text)	Alias измерения текста
helpers:normalize_yaw(angle)	Нормализация угла (-180..180)
helpers:get_state()	Определение состояния игрока
dragging(name, x, y)	Система перетаскивания UI
rounded_rectangle(x,y,w,h,r,g,b,a,radius)	Скругленный прямоугольник
text_fade_animation(speed, r,g,b,a, text)	Анимация цвета текста
📁 FILE SYSTEM API
Функция	Назначение
readfile(path)	Чтение файла
writefile(path, content)	Запись в файл
filesystem_find(path)	Поиск файла
filesystem_list(path)	Список файлов в директории
🧩 EVENTS
Событие	Назначение
"paint"	Отрисовка кадра
"paint_ui"	Отрисовка UI
"setup_command"	Обработка команд движения
"pre_render"	Перед рендером
"shutdown"	Выгрузка скрипта
"player_death"	Смерть игрока
"aim_hit"	Попадание
"aim_miss"	Промах
"bullet_impact"	Попадание пули
"net_update_start"	Начало сетевого обновления
"net_update_end"	Конец сетевого обновления
"round_prestart"	Начало раунда
"round_start"	Старт раунда
"round_end"	Конец раунда
"player_connect"	Игрок подключился
"player_disconnect"	Игрок отключился
"weapon_fire"	Выстрел оружия
"item_pickup"	Подбор предмета
"bomb_beginplant"	Начало установки бомбы
"bomb_planted"	Бомба установлена
"bomb_begindefuse"	Начало обезвреживания
"bomb_defused"	Бомба обезврежена
"bomb_exploded"	Бомба взорвалась
"item_equip"	Экипировка предмета
"cs_win_panel_match"	Панель победы
"vote_cast"	Голосование
🔢 CONSTANTS
Константа	Значение	Описание
HITBOX_HEAD	0	Голова
HITBOX_CHEST	2	Грудь
HITBOX_STOMACH	3	Живот
FL_ONGROUND	1	На земле
TEAM_T	2	Террористы
TEAM_CT	3	Контр-террористы
WEAPON_AK47	7	AK-47
WEAPON_AWP	9	AWP
🚀 ADVANCED FUNCTIONS
Функция	Назначение
client.dispatch_user_message(msg_id, size, data)	Отправка пользовательского сообщения
client.add_callback(event, func)	Альтернатива set_event_callback
client.get_cvar(name)	Получить значение консольной переменной
client.set_cvar(name, value)	Установить консольную переменную
client.draw_texture(texture_id, x,y,w,h, r,g,b,a)	Рисование текстуры
client.create_texture(rgba_data, width, height)	Создание текстуры
client.register_draw_callback(func)	Регистрация callback для отрисовки
entity.get_player_observer_target(ent)	Цель наблюдателя
entity.get_player_observer_mode(ent)	Режим наблюдения
engine.get_player_info(ent)	Информация об игроке
engine.get_game_directory()	Директория игры
engine.get_level_name()	Имя уровня
engine.get_level_name_short()	Короткое имя уровня
globals.interval_per_tick()	Интервал тика
globals.net_channel_info()	Информация о сетевом канале
VERSION: GameSense Lua API v2.0+
NOTE: Некоторые функции могут требовать определенных версий GameSense или доступны только в специфичных сборках.


Добавлены библиотеки и их использование:

📚 БИБЛИОТЕКИ И ИХ ИСПОЛЬЗОВАНИЕ
🌐 HTTP Библиотека
lua
local http = require("gamesense/http")

-- GET запрос
http.get("https://api.example.com/data", function(success, response)
    if success then
        print("Ответ:", response.body)
    end
end)

-- POST запрос
http.post("https://api.example.com/post", "data=test", function(success, response)
    if success then
        print("Статус:", response.status)
    end
end)

-- С заголовками
local headers = {["Content-Type"] = "application/json"}
http.get("https://api.example.com", headers, callback)
📊 Surface Библиотека
lua
local surface = require("gamesense/surface")

-- Работа с текстурами
local texture = surface.create_texture("materials/example.vtf")
surface.draw_texture(texture, x, y, width, height)

-- Шрифты
local font = surface.create_font("Arial", 14, 400)
surface.draw_text(font, x, y, r,g,b,a, "Текст")

-- Примитивы
surface.draw_line(x1, y1, x2, y2, r,g,b,a)
surface.draw_rect(x, y, w, h, r,g,b,a)
surface.draw_circle(x, y, radius, r,g,b,a)
🔢 Vector Библиотека
lua
local vector = require("vector")

-- Создание векторов
local vec1 = vector(100, 200, 300)
local vec2 = vector(50, 60, 70)

-- Операции
local sum = vec1 + vec2
local diff = vec1 - vec2
local mult = vec1 * 2
local div = vec1 / 2

-- Методы
local length = vec1:length()
local normalized = vec1:normalized()
local distance = vec1:distance(vec2)
local dot = vec1:dot(vec2)
local cross = vec1:cross(vec2)

-- Утилиты
local lerp = vec1:lerp(vec2, 0.5) -- линейная интерполяция
local angle = vector.angle_between(vec1, vec2)
🎨 UI Библиотека (PUI)
lua
local pui = require("gamesense/pui")

-- Создание сложных UI элементов
local group = pui.group("VISUALS", "ESP")

-- Кастомные элементы
local custom_slider = pui.create_slider("Прозрачность", 0, 100, 50)
local custom_color = pui.create_color_picker("Цвет", 255, 0, 0, 255)

-- Работа с видимостью
pui.set_visible(group, true)
pui.set_enabled(element, false)

-- События
pui.set_callback(element, function(value)
    print("Значение изменено:", value)
end)
📦 Memory Библиотека
lua
local memory = require("gamesense/memory")

-- Чтение/запись памяти
local value = memory.read_int(address)
memory.write_float(address, 100.5)

-- Поиск паттернов
local pattern = "FF 75 ?? 8B ?? ?? ?? FF"
local address = memory.find_pattern("client.dll", pattern)

-- Хуки
local hook = memory.hook_vtable(interface, index, function(original, ...)
    -- код до оригинальной функции
    local result = original(...)
    -- код после
    return result
end)

-- Отмена хука
hook:unhook()
🔄 Animations Библиотека
lua
local animations = require("gamesense/animations")

-- Плавные анимации
local anim = animations.new(0, 100, 2.0, animations.easing.linear)

-- Обновление
anim:update(globals.frametime())
local current = anim:get_value()

-- Типы easing
animations.easing.linear
animations.easing.in_quad
animations.easing.out_quad
animations.easing.in_out_quad
animations.easing.in_cubic
animations.easing.out_cubic
animations.easing.in_out_cubic
📐 Math Библиотека
lua
local math_ext = require("gamesense/math")

-- Дополнительные функции
local clamped = math_ext.clamp(value, 0, 100)
local remapped = math_ext.remap(value, 0, 100, 0, 1)
local lerped = math_ext.lerp(start, finish, fraction)

-- Углы
local normalized_angle = math_ext.normalize_angle(angle)
local angle_difference = math_ext.angle_difference(ang1, ang2)

-- Случайные числа
local random = math_ext.random_float(0, 1)
local gaussian = math_ext.random_gaussian(mean, deviation)
📁 Filesystem Библиотека
lua
local fs = require("gamesense/filesystem")

-- Работа с файлами
local files = fs.list("scripts/*.lua")
for _, file in ipairs(files) do
    print("Файл:", file)
end

-- Проверки
if fs.exists("config.json") then
    print("Файл существует")
end

-- Директории
fs.create_directory("scripts/custom")
fs.remove("scripts/old.lua")

-- Пути
local full_path = fs.get_full_path("scripts")
local is_file = fs.is_file(path)
local is_dir = fs.is_directory(path)
🔐 Cryptography Библиотека
lua
local crypto = require("gamesense/crypto")

-- Хэши
local md5 = crypto.md5("text")
local sha1 = crypto.sha1("text")
local sha256 = crypto.sha256("text")

-- Кодирование
local base64 = crypto.base64_encode("text")
local decoded = crypto.base64_decode(base64)

-- Шифрование (простое)
local encrypted = crypto.simple_encrypt("text", "key")
local decrypted = crypto.simple_decrypt(encrypted, "key")
🌍 Network Библиотека
lua
local network = require("gamesense/network")

-- Сетевая информация
local latency = network.get_latency()
local packets = network.get_packet_loss()
local choke = network.get_choke()

-- Пакеты
network.send_packet(data)
network.receive_packet(callback)

-- Серверная информация
local server_ip = network.get_server_address()
local server_port = network.get_server_port()
🎮 Game State Библиотека
lua
local gamestate = require("gamesense/gamestate")

-- Состояние игры
local round = gamestate.get_round_number()
local time_left = gamestate.get_round_time()
local bomb_state = gamestate.get_bomb_state()

-- Игроки
local local_player = gamestate.get_local_player()
local players = gamestate.get_all_players()

-- Карта
local map_name = gamestate.get_map_name()
local game_mode = gamestate.get_game_mode()
🔧 FFI Расширения
lua
local ffi_ext = require("gamesense/ffi_ex")

-- Упрощенная работа с памятью
local buffer = ffi_ext.alloc(1024) -- выделить память
ffi_ext.free(buffer) -- освободить

-- Структуры
local player_info_t = ffi_ext.struct({
    name = "string[32]",
    steam_id = "uint64",
    team = "int"
})

-- Сигнатуры
local sig_result = ffi_ext.find_signature({
    module = "client.dll",
    pattern = "55 8B EC 83 EC ?? 56 57",
    offset = 0
})
💾 Config Библиотека
lua
local config = require("gamesense/config")

-- Сохранение настроек
config.save("my_config", {
    value1 = 100,
    value2 = "text",
    value3 = {255, 0, 0, 255}
})

-- Загрузка
local data = config.load("my_config")
if data then
    print("Загружено:", data.value1)
end

-- Управление
config.list() -- список всех конфигов
config.delete("old_config")
config.export("my_config", "path/to/file.json")
config.import("path/to/file.json")
🎪 Event System
lua
local events = require("gamesense/events")

-- Создание кастомных событий
local my_event = events.new("my_event")

-- Подписка
my_event:subscribe(function(data)
    print("Событие вызвано:", data)
end)

-- Вызов
my_event:trigger({value = 100})

-- Удаление подписки
local handler = my_event:subscribe(callback)
handler:unsubscribe()
📈 Charts & Graphs
lua
local charts = require("gamesense/charts")

-- Создание графика
local chart = charts.new({
    type = "line",
    width = 200,
    height = 100,
    values = {10, 20, 30, 40, 50}
})

-- Обновление
chart:add_value(math.random(0, 100))

-- Отрисовка
chart:draw(x, y)

-- Типы графиков
"line" -- линейный
"bar" -- столбчатый
"pie" -- круговой
"area" -- площадной
⚙️ ПРИМЕР ИСПОЛЬЗОВАНИЯ НЕСКОЛЬКИХ БИБЛИОТЕК
lua
local http = require("gamesense/http")
local vector = require("vector")
local animations = require("gamesense/animations")
local surface = require("gamesense/surface")

-- Получение данных с сервера
http.get("https://api.ipify.org?format=json", function(success, response)
    if success then
        local data = json.parse(response.body)
        print("Ваш IP:", data.ip)
    end
end)

-- Анимация позиции
local pos = vector(0, 0, 0)
local target = vector(100, 200, 0)
local anim = animations.new(0, 1, 2.0, animations.easing.out_quad)

client.set_event_callback("paint", function()
    anim:update(globals.frametime())
    local current_pos = pos:lerp(target, anim:get_value())
    
    -- Отрисовка
    surface.draw_circle(current_pos.x, current_pos.y, 10, 255, 0, 0, 255)
end)