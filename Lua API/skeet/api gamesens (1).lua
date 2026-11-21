Global Functions
Description
Global Lua standard library functions and miscellaneous extensions to them.

Functions
assert
assert(expression, message: string)
If the the first argument is false or nil, an error is thrown with the second argument as the message. Otherwise all the arguments are returned.

collectgarbage
collectgarbage(opt: string, arg)
This function is a generic interface to the garbage collector. It performs different functions according to its first argument, opt:

"collect": performs a full garbage-collection cycle. This is the default option.
"stop": stops the garbage collector.
"restart": restarts the garbage collector.
"count": returns the total memory in use by Lua (in Kbytes).
"step": performs a garbage-collection step. The step "size" is controlled by arg (larger values mean more steps) in a non-specified way. If you want to control the step size you must experimentally tune the value of arg. Returns true if the step finished a collection cycle.
"setpause": sets arg as the new value for the pause of the collector (see §2.10). Returns the previous value for pause.
"setstepmul": sets arg as the new value for the step multiplier of the collector (see §2.10). Returns the previous value for step.
Modifying garbage collector settings is generally not recommended, unless you know what you are doing.

defer
defer(callback)
Registers a function to be called at lua shutdown/reload, equivalent to client.set_event_callback("shutdown", callback).

error
error(message: string, level: number)
Terminates the last protected function called and outputs message as an error message. If the function containing the error is not called in a protected function (pcall), then the script which called the function will terminate. The error function itself never returns and acts like a script error. The level argument specifies how to get the error position. With level 1 (the default), the error position is where the error function was called. Level 2 points the error to where the function that called error was called; and so on. Passing a level 0 avoids the addition of error position information to the message.

getfenv
getfenv(stack): table
Returns the environment of the function or stack level passed to it.

getmetatable
getmetatable(tbl: table): table
Returns the metatable of the given table if it has one, otherwise returns nil. If t does have a metatable, and the __metatable metamethod is set, it returns that value instead.

ipairs
ipairs(tbl: table): function, table, number
Returns three values: an iterator function, the table tbl and the number 0. Each time the iterator function is called, it returns the next numerical index-value pair in the table.

When used in a generic for-in-loop, the return values can be used to iterate over each numerical index in the table.

load
load(chunk: string, chunkname: string, mode: string, env: table): function, string
Loads a chunk of Lua source code from a string or a "reader" function.

If there are no syntactic errors, returns the compiled chunk as a function; otherwise, returns nil plus the error message.

If chunk is a function, load calls it repeatedly to get the chunk pieces. Each call to chunk must return a string that concatenates with previous results. A return of an empty string, nil, or no value signals the end of the chunk.

next
next(t: table, key: any): , value
Returns the first key/value pair in the t table. If a key argument was specified then returns the next element in the table based on the key provided.

If the table is empty or the specified key was the last key in the array, it returns nil. This means that you can use next(t) to check whether a table is empty.

The order in which the indices are enumerated is not specified, even for numeric indices. To traverse an array-like table in order, use a numerical for loop or ipairs.

pairs
pairs(tbl: table): function, table, number
Returns three values: an iterator function, the table tbl and nil. Each time the iterator function is called, it returns the next key-value pair in the table.

When used in a generic for-in-loop, the return values can be used to iterate over all key-value pairs in the table. The iteration order is not specified and tables do not keep their insertion order.

pcall
pcall(func, ...): boolean,
Calls the function func in "protected mode". This means that any error inside func is not propagated; instead, pcall catches the error and returns back to the caller. If the first return value is true, the function call succeeded with no errors and the other return values will be the return values from the function. If the first return value is false, the second one will be the error message.

print
print(...)
Logs a message to the console. Equivalent to client.log.

printf
printf(fmt: string, ...)
Logs a formatted message to the console. It accepts the same parameters as string.format

rawequal
rawequal(v1: any, v2: any): boolean
Checks whether v1 is equal to v2, without invoking any metamethod.

rawget
rawget(tbl: table, key):
Gets the raw value of a table field, without invoking any __index metamethod.

rawlen
rawlen(tbl: table): number
Gets the raw length of a table, without invoking the __len metamethod.

rawset
rawset(tbl: table, key, value)
Sets the raw value of a table field, without invoking any __newindex metamethod.

readfile
readfile(filename: string): string
Returns the contents of the file, or nil if the file doesn't exist.

require
require(modname: string):
Loads a Lua module. The package.path is searched for the module, and the first file found is loaded. If the module returns a value, that value is returned by require, otherwise true is returned. Workshop libraries can be loaded using require "gamesense/<id>", if you are subscribed to them.

select
select(index: number, ...)
Returns all the arguments passed to it after the index. Alternatively, if the string "#" is passed as the first argument, it returns the total number of arguments passed to it (including nils).

setfenv
setfenv(stack, env: table): function
Sets the environment of the given function to the given table.

setmetatable
setmetatable(tbl: table, metatable: table)
Sets the metatable of the given table tbl to metatable. If metatable is nil, the metatable of t is removed. Finally, this function returns the table tbl which was passed to it. If tbl already has a metatable whose __metatable metamethod is set, calling this on tbl raises an error.

tonumber
tonumber(value, base: number)
Tries to convert its argument to a number. If the argument is a number, a string or a number cdata object convertible to a number, then tonumber returns this number; otherwise, it returns nil.

tostring
tostring(value): string
Receives an argument of any type and converts it to a string in a reasonable format. For complete control of how numbers are converted, use string.format. If the metatable of value has a __tostring metamethod, then it will be called with value as the only argument and will return the result.

toticks
toticks(time: number): number
Converts time (seconds) to ticks.

totime
totime(ticks: number): number
Converts ticks to time. Return value is in seconds.

type
type(value): string
Returns the type of its only argument, coded as a string. The possible results of this function are "nil" (a string, not the value nil), "number", "string", "boolean", "table", "function", "thread", and "userdata".

unpack
unpack(tbl: table, i: number, j: number):
Returns the items with numeric keys from the given table tbl, from i to j.

vtable_bind
vtable_bind(module_name: string, interface_name: string, index: number, typestring: string, ...): function
Utility for calling virtual functions on FFI objects. This variant works with Interfaces and doesn't require passing the this-pointer as the first argument every time.

vtable_thunk
vtable_thunk(index: number, typestring: string, ...): function
Utility for calling virtual functions on FFI objects. This variant takes the this-pointer as the first argument and grabs the virtual function from it when called.

writefile
writefile(filename: string, text: string)
Overwrites the file with the passed text. The file is created if it doesn't exist.

xpcall
xpcall(func, handler, ...): boolean,
Calls the function func in "protected mode". This means that any error inside func is not propagated; instead, xpcall catches the error, calls the "error handler" function passed to it, then returns back to the caller. If the first return value is true, the function call succeeded with no errors and the other return values will be the return values from the function. If the first return value is false, the second one will be the error message.


bit
Description
LuaJIT library for bitwise operations

Functions
arshift
bit.arshift(x: number, n: number): number
Returns the bitwise arithmetic right-shift of its first argument by the number of bits given by the second argument. Arithmetic right-shift treats the most-significant bit as a sign bit and replicates it. Only the lower 5 bits of the shift count are used (reduces to the range [0..31]).

band
bit.band(x1: number, ...): number
Returns the bitwise and of all of its arguments. Note that more than two arguments are allowed.

bnot
bit.bnot(x: number): number
Returns the bitwise not of its argument (all bits flipped).

bor
bit.bor(x1: number, ...): number
Returns the bitwise or of all of its arguments. Note that more than two arguments are allowed.

bswap
bit.bswap(x: number): number
Swaps the bytes of its argument and returns it. This can be used to convert little-endian 32 bit numbers to big-endian 32 bit numbers or vice versa.

bxor
bit.bxor(x1: number, ...): number
Returns the bitwise xor of all of its arguments. Note that more than two arguments are allowed.

lshift
bit.lshift(x: number, n: number): number
Returns the bitwise logical left-shift of its first argument by the number of bits given by the second argument. Logical shifts treat the first argument as an unsigned number and shift in 0-bits. Only the lower 5 bits of the shift count are used (reduces to the range [0..31]).

rol
bit.rol(x: number, n: number): number
Returns the bitwise left rotation of its first argument by the number of bits given by the second argument. Bits shifted out on one side are shifted back in on the other side. Only the lower 5 bits of the rotate count are used (reduces to the range [0..31]).

ror
bit.ror(x: number, n: number): number
Returns the bitwise right rotation of its first argument by the number of bits given by the second argument. Bits shifted out on one side are shifted back in on the other side. Only the lower 5 bits of the rotate count are used (reduces to the range [0..31]).

rshift
bit.rshift(x: number, n: number): number
Returns the bitwise logical right-shift of its first argument by the number of bits given by the second argument. Logical shifts treat the first argument as an unsigned number and shift in 0-bits. Only the lower 5 bits of the shift count are used (reduces to the range [0..31]).

tobit
bit.tobit(x: number): number
Normalizes a number to the numeric range for bit operations and returns it. This function is usually not needed since all bit operations already normalize all of their input arguments.

tohex
bit.tohex(x: number, n: number): string
Converts its first argument to a hex string. The number of hex digits is given by the absolute value of the optional second argument. Positive numbers between 1 and 8 generate lowercase hex digits. Negative numbers generate uppercase hex digits. Only the least-significant 4*|n| bits are used. The default is to generate 8 lowercase hex digits.

client
Description
General game- and cheat-related functions

Functions
camera_angles
client.camera_angles(pitch: number, yaw: number): number, number
Get or set camera angles. Pass no arguments to get the current camera angles.

camera_position
client.camera_position(): number, number, number
Returns x, y, z world coordinates of the game's camera position.

color_log
client.color_log(r: number, g: number, b: number, ...)
Logs a colored message to console. End the string with \0 to prevent it from adding a newline.

create_interface
client.create_interface(module_name: string, interface_name: string): userdata
Returns a pointer to the interface, or nil on failure.

current_threat
client.current_threat(): number
Returns the entindex of the 'current threat', i.e. the enemy that is currently being used for 'At targets' anti-aim.

delay_call
client.delay_call(delay: number, callback, ...)
Executes the callback after delay seconds, passing the arguments to it.

draw_debug_text
client.draw_debug_text(x: number, y: number, z: number, line_offset: number, duration: number, r: number, g: number, b: number, a: number, ...)
Draws a DebugOverlay text at the specified 3d position. Avoid calling this during the paint event.

draw_hitboxes
client.draw_hitboxes(entindex: number, duration: number, hitboxes: number, r: number, g: number, b: number, a: number, tick: number)
Draws hitbox overlays. Avoid calling this during the paint event.

error_log
client.error_log(msg: string)
Prints an error to the console and plays a sound.

exec
client.exec(...)
Executes a console command. Multiple commands can be combined with ';'. Be careful when passing user input (including player names) to it.

eye_position
client.eye_position(): number, number, number
Returns x, y, z world coordinates of the local player's eye position.

find_signature
client.find_signature(module_name: string, pattern: string): userdata
Finds the specified pattern and returns a pointer to it, or nil if not found.

fire_event
client.fire_event(event_name: string, ...)
Fires a custom event that other scripts can listen to using client.set_event_callback.

get_cvar
client.get_cvar(cvar_name: string): string
Returns the value of a console variable.

get_model_name
client.get_model_name(model_index: number): string
Returns model name, or nil on failure.

key_state
client.key_state(key: number): boolean
Returns true if the key is pressed, or nil on failure

latency
client.latency(): number
Returns your latency in seconds.

log
client.log(...)
Logs a message to the console.

random_float
client.random_float(minimum: number, maximum: number): number
Returns a random float between minimum and maximum.

random_int
client.random_int(minimum: number, maximum: number): number
Returns a random integer between minimum and maximum.

real_latency
client.real_latency(): number
Returns your real latency, regardless of ping spike.

register_esp_flag
client.register_esp_flag(flag: string, r: number, g: number, b: number, callback)
Requires "Flags" in Player ESP to be enabled.

reload_active_scripts
client.reload_active_scripts()
Reloads all scripts the following frame.

request_full_update
client.request_full_update()
Requests a full update from the server, refreshing things like skins, player models and modified netvars.

scale_damage
client.scale_damage(entindex: number, hitgroup: number, damage: number): number
Returns adjusted damage for the specified hitgroup

screen_size
client.screen_size(): number, number
Returns the size of the screen in pixels.

set_clan_tag
client.set_clan_tag(...)
Sets the player's clan tag. The clan tag is removed if no argument is passed or if it is an empty string. Additional arguments will be concatenated.

set_event_callback
client.set_event_callback(event_name: string, callback)
Registers the function as a callback for the specified event. It can be removed later using client.unset_event_callback.

system_time
client.system_time(): number, number, number, number
Returns the user's windows time.

timestamp
client.timestamp(): number
Returns high precision timestamp in milliseconds. This can be used for benchmarking code

trace_bullet
client.trace_bullet(from_player: number, from_x: number, from_y: number, from_z: number, to_x: number, to_y: number, to_z: number, skip_players: boolean): number, number
Returns entindex, damage. Entindex is nil when no player is hit or if players are skipped.

trace_line
client.trace_line(skip_entindex: number, from_x: number, from_y: number, from_z: number, to_x: number, to_y: number, to_z: number): number, number
Returns fraction, entindex. fraction is a percentage in the range [0.0, 1.0] that tells you how far the trace went before hitting something, so 1.0 means nothing was hit. entindex is the entity index that hit, or -1 if no entity was hit.

unix_time
client.unix_time(): number
Returns the current system time as unix time

unset_event_callback
client.unset_event_callback(event_name: string, callback)
Removes a callback that was previously set using client.set_event_callback.

update_player_list
client.update_player_list()
Updates the player list tab without having to open it.

userid_to_entindex
client.userid_to_entindex(userid: number): number
Converts a User ID (from game events, for example) to the entity index.

visible
client.visible(x: number, y: number, z: number): boolean
Returns true if the position is visible from the local player eye position. For more advanced ray tracing use client.trace_line.

config
Description
Configuration related lua functions

Functions
export
config.export(): string
Returns the current config in the export format

import
config.import(config: string)
Imports a config in the export format

load
config.load(name: string, tab_name: string, container_name: string)
Loads an existing config. To load the specified config: config.load('Config name here') To load a tab from the specified config: config.load('Config name here', 'Tab name here') To load a container from the specified config: config.load('Config name here', 'Tab name here', 'Container name here')

cvar
Description
A table letting you get and set the value of cvars and invoke the callbacks of concommands.

-- localize the cvar object
local cl_fullupdate = cvar.cl_fullupdate

-- invoke a callback to the command as if you entered the command in the console
cl_fullupdate:invoke_callback()

--localize the cvar object
local cl_downloadfilter = cvar.cl_downloadfilter

-- print the current value of the cvar
client.log(cl_downloadfilter:get_string())

-- set the cvars value
cl_downloadfilter:set_string("none")

-- print it again
client.log(cl_downloadfilter:get_string()) -- "none"

info
The documentation for the cvar type is unfinished as it relies on types that aren't in the docs yet.

Functions
__index
cvar.__index(name: string): cvar
Finds a cvar by name and returns a cvar object for it, or nil if it doesn't exist or is blocked for security reasons.

coroutine
Description
A coroutine is a function that can be suspended and resumed at a later time, enabling asynchronous execution of synchronous code.

database
Description
Persistent storage that lets you store lua values (including tables) between script / cheat reloads.

Functions
flush
database.flush()
Flushes the database to disk. This is automatically called when the script is reloaded, but you can call it manually if you want to force a flush.

read
database.read(key_name: string):
Gets a value from the database

write
database.write(key_name: string, value)
Writes a value to the database. Avoid calling this often. For example, call read at script load, then call write during the 'shutdown' event


entity
Description
Entity related functions such as iterating them, getting and modifying netvars, etc.

Functions
get_all
entity.get_all(classname: string): table
Returns an array of entity indices matching the classname. Pass no arguments for all entities. Dormant entities are not returned.

get_bounding_box
entity.get_bounding_box(ent: number): number, number, number, number, number
Returns the 2D bounding box and alpha multiplier (dormant esp). The contents of x1, y1, x2, y2 must be ignored when alpha_multiplier is zero, which indicates that the bounding box is invalid and should not be drawn.

get_classname
entity.get_classname(ent: number): string
Returns the name of the entity's class.

get_esp_data
entity.get_esp_data(player: number): table
Returns a table containing alpha, health, flags, and weapon_id, or nil on failure.

get_game_rules
entity.get_game_rules(): number
Returns the entity index of the CCSGameRulesProxy instance, or nil if none exists.

get_local_player
entity.get_local_player(): number
Returns the entity index for the local player, or nil on failure.

get_origin
entity.get_origin(ent: number): number, number, number
Returns x, y, z world coordinates of the entity's origin, or nil if the entity is dormant and dormant ESP information is not available.

get_player_name
entity.get_player_name(player: number): string
Returns the player's name, or the string "unknown" on failure.

get_player_resource
entity.get_player_resource(): number
Returns the entity index of the CCSPlayerResource instance, or nil if none exists.

get_player_weapon
entity.get_player_weapon(player: number): number
Returns the entity index of the player's active weapon, or nil if the player is not alive, dormant, etc.

get_players
entity.get_players(enemies_only: boolean): table
Returns an array of player entity indices. Dormant and dead players will not be added to the list.

get_prop
entity.get_prop(ent: number, prop: string, array_index: number):
Returns the value of the property, or nil on failure. For vectors or angles, this returns three values.

get_steam64
entity.get_steam64(player: number): number
Returns the player's SteamID3, or nil on failure.

hitbox_position
entity.hitbox_position(player: number, hitbox: number): number, number, number
Returns world coordinates of the hitboxes, or nil on failure.

is_alive
entity.is_alive(ent: number): boolean
Returns true if the player is not dead.

is_dormant
entity.is_dormant(ent: number): boolean
Returns true if the entity is dormant.

is_enemy
entity.is_enemy(ent: number): boolean
Returns true if the entity is on the opposing team.

new_prop
entity.new_prop(propname: string, offset: number, type: number, array_type: number, array_element_size: number, array_count: number)
Creates a new entity prop that can then be read and modified with entity.get_prop / entity.set_prop.

set_prop
entity.set_prop(ent: number, prop: string, ..., array_index: number)
Sets the value of the property. For vectors or angles, pass three values.

ffi
Description
The FFI (foreign function interface) allows calling external C functions and using C data structures from pure Lua code.

The FFI library largely obviates the need to write tedious manual Lua/C bindings in C. No need to learn a separate binding language — it parses plain C declarations! These can be cut-n-pasted from C header files or reference manuals. It's up to the task of binding large libraries without the need for dealing with fragile binding generators.

The FFI library is tightly integrated into LuaJIT (it's not available as a separate module). The code generated by the JIT-compiler for accesses to C data structures from Lua code is on par with the code a C compiler would generate. Calls to C functions can be inlined in JIT-compiled code, unlike calls to functions bound via the classic Lua/C API.

globals
Description
Global variables used by the source engine.

Functions
absoluteframetime
globals.absoluteframetime(): number
The absolute time the last frame took to render.

chokedcommands
globals.chokedcommands(): number
The number of choked commands (commands that haven't yet been sent to the server, for example due to fake lag)

commandack
globals.commandack(): number
The command number of the most recent server-acknowledged command.

curtime
globals.curtime(): number
The elapsed game time in seconds. This number is synchronized with the server.

framecount
globals.framecount(): number
The number of frames rendered since the game started

frametime
globals.frametime(): number
The time the last frame took to render.

lastoutgoingcommand
globals.lastoutgoingcommand(): number
The command number of the most recent sent command.

mapname
globals.mapname(): string
The name of the loaded map, or nil if you are not in game.

maxplayers
globals.maxplayers(): number
The maximum number of players in a game (usually 64)

oldcommandack
globals.oldcommandack(): number
The command number of the previous server-acknowledged command.

realtime
globals.realtime(): number
The time in seconds since the game was started.

servertickcount
globals.servertickcount(): number
Returns the most recently receieved tick from the server.

tickcount
globals.tickcount(): number
The number of ticks elapsed on the server.

tickinterval
globals.tickinterval(): number
The time between ticks in seconds, 1/64 for 64 tick.

json
Description
A JSON parser and serializer library. Slightly modified version of Lua CJSON.

Useful tools: JSON Formatter / Validator - JSON Tree Viewer

Functions
decode_invalid_numbers
json.decode_invalid_numbers(setting: boolean): boolean
json.parse may generate an error when trying to decode numbers not supported by the JSON specification. Invalid numbers are defined as: infinity, not-a-number (NaN) and hexadecimal

Available settings: true - Accept and decode invalid numbers. This is the default setting. false - Throw an error when invalid numbers are encountered.

The current setting is always returned, and is only updated when an argument is provided.

decode_max_depth
json.decode_max_depth(depth: number): number
json.parse will generate an error when parsing deeply nested JSON once the maximum array/object depth has been exceeded. This check prevents unnecessarily complicated JSON from slowing down the application, or crashing the application due to lack of process stack space.

An error may be generated before the depth limit is hit if Lua is unable to allocate more objects on the Lua stack. By default, json.parse will reject JSON with arrays and/or objects nested more than 1000 levels deep.

The current setting is always returned, and is only updated when an argument is provided.

encode_invalid_numbers
json.encode_invalid_numbers(setting): boolean
json.stringify may generate an error when encoding floating point numbers not supported by the JSON specification such as Infinity and NaN. This behavior can be changed by calling this function.

Available settings: true - Allow invalid numbers to be encoded. This will generate non-standard JSON, but this output is supported by some libraries. false - Throw an error when attempting to encode invalid numbers. This is the default setting. "null" - Encode invalid numbers as a JSON null value. This allows infinity and NaN to be encoded into valid JSON.

The current setting is always returned, and is only updated when an argument is provided.

encode_max_depth
json.encode_max_depth(depth: number): number
json.stringify will generate an error when encoding deeply nested JSON once the maximum table depth has been exceeded. This check prevents unnecessarily complicated JSON from slowing down the application, or crashing the application due to lack of process stack space.

By default, json.stringify will reject JSON with more than 1000 nested tables.

The current setting is always returned, and is only updated when an argument is provided.

encode_number_precision
json.encode_number_precision(precision: number): number
The amount of significant digits returned by json.stringify when encoding numbers can be changed to balance accuracy versus performance. For data structures containing many numbers, setting json.encode_number_precision to a smaller integer, for example 3, can improve encoding performance by up to 50%. By default, Lua CJSON will output 14 significant digits when converting a number to text.

The current setting is always returned, and is only updated when an argument is provided.

encode_sparse_array
json.encode_sparse_array()
json.stringify classifies a Lua table into one of three kinds when encoding a JSON array. This is determined by the number of values missing from the Lua array as follows:

Normal: All values are available. Sparse: At least 1 value is missing. Excessively sparse: The number of values missing exceeds the configured ratio.

It encodes sparse Lua arrays as JSON arrays using JSON null for the missing entries. An array is excessively sparse when all the following conditions are met: ratio > 0, maximum_index > safe, maximum_index > item_count * ratio

JSON will never consider an array to be excessively sparse when ratio = 0. The safe limit ensures that small Lua arrays are always encoded as sparse arrays. By default, attempting to encode an excessively sparse array will generate an error. If convert is set to true, excessively sparse arrays will be converted to a JSON object.

The current settings are always returned. A particular setting is only changed when the argument is provided (non-nil).

parse
json.parse(json_text: string):
Parses a UTF-8 JSON string into a Lua object (table, number, string, etc).

UTF-16 and UTF-32 JSON strings are not supported. All escape codes will be decoded and other bytes will be passed transparently. JSON null will be converted to a NULL lightuserdata value. This can be compared with json.null for convenience.

By default, numbers incompatible with the JSON specification (infinity, NaN, hexadecimal) can be parsed. This default can be changed with json.decode_invalid_numbers.

stringify
json.stringify(object): string
Serializes a Lua object into a JSON string.

It supports the following types: boolean, nil, number, string, table

The remaining Lua types will generate an error: function, lightuserdata, thread, userdata

By default, numbers are encoded with 14 significant digits. Refer to json.encode_number_precision for details.

!!!warning This function will successfully encode/decode binary strings, but this is technically not supported by JSON and may not be compatible with other JSON libraries. To ensure the output is valid JSON, applications should ensure all Lua strings passed to json.stringify are UTF-8. Base64 is commonly used to encode binary data as the most efficient encoding under UTF-8 can only reduce the encoded size by a further ~8%. !!!

math
Description
Standard library for common mathematical functions.

Functions
abs
math.abs(x: number): number
Returns the absolute value of x, removing the negative sign if present.

acos
math.acos(x: number): number
Returns the arccosine of the given number.

asin
math.asin(x: number): number
Returns the arcsine of the given number.

atan
math.atan(x: number): number
Returns the arc tangent of x (in radians).

atan2
math.atan2(y: number, x: number): number
Returns the arc tangent of y/x (in radians), but uses the signs of both parameters to find the quadrant of the result. It also handles correctly the case of x being zero.

ceil
math.ceil(x: number): number
Rounds the number up to the nearest integer.

cos
math.cos(x: number): number
Returns the cosine of x (assumed to be in radians).

cosh
math.cosh(x: number): number
Returns the hyperbolic cosine of x.

deg
math.deg(x: number): number
Converts the angle x from radians to degrees.

exp
math.exp(x: number): number
Returns the value of e^x.

floor
math.floor(x: number): number
Rounds the number down to the nearest integer.

fmod
math.fmod(x: number, y: number): number
Returns the modulus of the specified values (remainder of x / y). While this is similar to the % operator, it will return a negative value if the first argument is negative, whereas the % operator will return a positive value even if the first operand is negative.

frexp
math.frexp(x: number): number, number
Returns m and e such that x = m2e, e is an integer and the absolute value of m is in the range ((0.5, 1) (or zero when x is zero). Used to split the number value into a normalized fraction and an exponent. Two values are returned: the first is a multiplier in the range 1/2 (inclusive) to 1 (exclusive) and the second is an integer exponent. The result is such that x = m*2^e.

ldexp
math.ldexp(x: number, e: number): number
Returns x*2^e (e should be an integer).

log
math.log(x: number, base: number): number
Returns the logarithm of x using the given base, or the mathematical constant e if no base is provided (natural logarithm).

log10
math.log10(x: number): number
Returns the base-10 logarithm of x.

max
math.max(...): number
Returns the largest of its arguments.

min
math.min(...): number
Returns the smallest of its arguments.

modf
math.modf(base: number): number, number
Returns the integral and fractional component of the modulo operation.

pow
math.pow(x: number, y: number): number
Returns x^y. In particular, math.pow(1.0, x) and math.pow(x, 0.0) always return 1.0, even when x is a zero or NaN. If both x and y are finite, x is negative, and y is not an integer then math.pow(x, y) is undefined.

rad
math.rad(x: number): number
Converts the angle x from degrees to radians.

random
math.random(min: number, max: number): number
Returns a random number between the values provided. When called without arguments, returns a uniform pseudo-random real number in the range [0,1]. When called with an integer number m, math.random returns a uniform pseudo-random integer in the range [1, m]. When called with two integer numbers m and n, math.random returns a uniform pseudo-random integer in the range [m, n].

LuaJIT uses a Tausworthe PRNG with period 2^223 to implement math.random and [math.randomseed(#randomseed).

When called without arguments it generates 52 pseudo-random bits for every call. The result is uniformly distributed between 0.0 and 1.0. It's correctly scaled up and rounded for math.random(n [,m]) to preserve uniformity.

Important: Neither this nor any other PRNG based on the simplistic math.random API is suitable for cryptographic use.

randomseed
math.randomseed(seed: number)
Seeds the random number generator. The same seed will guarantee the same sequence of numbers each time with math.random. Incorrect usage of this function will affect all loaded scripts.

sin
math.sin(x: number): number
Returns the sine of x (assumed to be in radians).

sinh
math.sinh(x: number): number
Returns the hyperbolic sine of x.

sqrt
math.sqrt(x: number): number
Returns the square root of x. (You can also use the expression x^0.5 to compute this value.)

tan
math.tan(x: number): number
Returns the tangent of x (assumed to be in radians).

tanh
math.tanh(x: number): number
Returns the hyperbolic tangent of x.

materialsystem
Description
Functions for interacting with the source engine material system. Refer to the material type for information on how to modify a material.

Functions
arms_material
materialsystem.arms_material(): material
Returns a reference to the arms material when 'Hands' is enabled

chams_material
materialsystem.chams_material(): material
Returns a reference to the player chams material

find_material
materialsystem.find_material(path: string, force_load: boolean): material
Returns a reference to the material

find_materials
materialsystem.find_materials(path: string): table
Returns a table of materials matching the specified path

find_texture
materialsystem.find_texture(path: string)
Returns a pointer to a texture, can be used to override textures with material:set_shader_param.

get_model_materials
materialsystem.get_model_materials(entindex: number): table
Returns a table of materials used by the specified entity's model

override_material
materialsystem.override_material(material: material, material_new: material)
Overrides all of a material properties with another material.

viewmodel_material
materialsystem.viewmodel_material(): material
Returns a reference to the arms material when 'Weapon viewmodel' is enabled

panorama
Description
API for CS:GO's Panorama UI. Lets you execute JavaScript code in CS:GO's V8 engine, which can then interact with your lua code.

Useful tools: JS Syntax Validator

Functions
loadstring
panorama.loadstring(js_code: string, panel: string)
open
panorama.open(panel: string): table

plist
Description
Functions for interacting with the player list

Functions
get
plist.get(entindex: number, field: string)
Returns the value of a built-in player list option

set
plist.set(entindex: number, field: string, value)
Sets the value of a built-in player list option

renderer
Description
Functions for drawing on the screen. Usually won't work outside the paint / paint_ui events.

Functions
blur
renderer.blur(x: number, y: number, w: number, h: number, alpha: number, amount: number)
Creates a region on the screen that blurs everything behind it.

circle
renderer.circle(x: number, y: number, r: number, g: number, b: number, a: number, radius: number, start_degrees: number, percentage: number)
Draws a filled circle on the screen

circle_outline
renderer.circle_outline(x: number, y: number, r: number, g: number, b: number, a: number, radius: number, start_degrees: number, percentage: number, thickness: number)
Draws the outline of a circle on the screen

gradient
renderer.gradient(x: number, y: number, w: number, h: number, r1: number, g1: number, b1: number, a1: number, r2: number, g2: number, b2: number, a2: number, direction: boolean)
Draws a horizontal or vertical gradient on the screen.

indicator
renderer.indicator(r: number, g: number, b: number, a: number, ...): number
Draws an indicator on the screen and returns the Y screen coordinate (vertical offset) of the drawn text, or nil on failure.

line
renderer.line(x1: number, y1: number, x2: number, y2: number, r: number, g: number, b: number, a: number)
Draws a anti-aliased line on the screen.

load_jpg
renderer.load_jpg(contents: string, width: number, height: number): number
Loads a texture from raw JPG contents (with file header). The file can for example be loaded using readfile. Returns a texture ID that can be used with renderer.texture, or nil on failure

load_png
renderer.load_png(contents: string, width: number, height: number): number
Loads a texture from raw PNG contents (with file header). The file can for example be loaded using readfile. Returns a texture ID that can be used with renderer.texture, or nil on failure

load_rgba
renderer.load_rgba(contents: string, width: number, height: number): number
Loads a texture from a RGBA buffer. Returns a texture ID that can be used with renderer.texture, or nil on failure

load_svg
renderer.load_svg(contents: string, width: number, height: number): number
Loads a SVG from a string. The file can for example be loaded using readfile. Returns a texture ID that can be used with renderer.texture, or nil on failure

measure_text
renderer.measure_text(flags: string, ...): number, number
Returns width, height. This can only be called from the paint callback.

rectangle
renderer.rectangle(x: number, y: number, w: number, h: number, r: number, g: number, b: number, a: number)
Draws a filled rectangle on the screen

text
renderer.text(x: number, y: number, r: number, g: number, b: number, a: number, flags: string, max_width: number, ...)
Draws text on the screen.

texture
renderer.texture(texture: number, x: number, y: number, w: number, h: number, r: number, g: number, b: number, a: number, mode: string)
Draws a texture from the texture id created from load_rgba, load_png, load_jpg or load_svg

triangle
renderer.triangle(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, r: number, g: number, b: number, a: number)
Draws a filled triangle on the screen. The points need to be specified in clockwise order.

world_to_screen
renderer.world_to_screen(x: number, y: number, z: number): number, number
Returns the screen coordinates of a world position or nil if the world position is not visible on your screen.

string
Description
Standard library for generic string manipulation, such as finding and extracting substrings or pattern matching.

Functions
byte
string.byte(string: string, start: number, end: number): number
Returns the given string's characters in their numeric ASCII representation.

char
string.char(...): string
Creates a string from one or more numeric ASCII codes.

find
string.find(str: string, pattern: string, start: number, no_patterns: boolean): number, number
Looks for the first match of the pattern in the string str. If it finds a match, then it returns the indices of str where the occurrence starts and ends; otherwise, it returns nil.

Passing true as the fourth argument turns off pattern matching facilities, so the function does a plain “find substring” operation, with no characters in the pattern being considered “magic”. Note that if no_patterns is given, then start must be given as well.

format
string.format(format: string, ...)
Returns a formatted version of its variable number of arguments following the description given in its first argument (which must be a string). === Format string options

Available numeric format specifiers:

%d - Decimal integer, rounded down.
%o - Octal integer, rounded down.
%x - Hexadecimal integer, rounded down. Use %X for uppercase.
%f - Floating-point number, rounded based on the specified precision.
%e - Scientific notation (mantissa/exponent). Use %E for uppercase.
%g - Shortest float representation, either %f or %e. Use %G for uppercase.
%a - Hexadecimal float. Use %A for uppercase.
Numeric specifiers can be combined with one or more of the following sub-specifiers:

Padding: Use %5d to pad a number to at least 5 characters. By default, it will be padded with spaces, use %05d to use zeroes instead. Use %-5d to left-justify instead of right-justify the output.
Sign: Use %+d to preceed positive numbers with a plus sign or % d to preceed them with a space.
#: When used with %o, %x or %X it prefixes the output with 0, 0x or 0X respectively for values different than zero. Used with e, E, f, F, g or G it forces the written output to contain a decimal point even if no more digits follow.
Precision: Number of digits to be printed after the decimal point, for example %011.5f to print 5 digits after the decimal point and pad the output to at least 11 characters (including the decimal point)
Other format specifiers:

%c - Single character as ascii code.
%s - String
%q - String between double quotes, with all special characters escaped
%% - A single % character.
String specifiers can also be combined with the width and right-justify sub-specifiers. Use %16s to make sure the output string is at least 16 characters long.

===

gmatch
string.gmatch(str: string, pattern: string): function
Using lua patterns, returns an iterator which will return either one value if no capture groups are defined, or any capture group matches.

gsub
string.gsub(str: string, pattern: string, replacement: string, max: number): string, number
Using lua patterns, returns a copy of str with all matches of the pattern replaced by the given replacement string.

The pattern may be a string, a table or a function.

If it is a string, then it can contain captures.
If it is a table, the match is looked up in the table as a key, and the value (string) is used to replace it, if it exists.
If it is a function, then the function is called for each match, with the value of the match as the first argument, the value of the n argument as the second argument, and the position of the match as the third argument. The function must then return the replacement string to be used for the match.
len
string.len(str: string): number
Returns the length of the string str in bytes.

lower
string.lower(str: string): string
Returns a copy of str with all uppercase letters replaced by their lowercase counterparts.

match
string.match(str: string, pattern: string, start): table
Using lua patterns, returns the first match of the pattern in the string str. If no match is found, it returns nil.

rep
string.rep(str: string, n: number, sep: string): string
Repeats the string n times and concatenates them using the separator sep.

reverse
string.reverse(str: string): string
Reverses the string str.

sub
string.sub(str: string, s: number, e: number): string
Returns a substring of str starting at s and ending at e. Use negative numbers to start from the end of the string.

upper
string.upper(str: string): string
Returns a copy of str with all lowercase letters replaced by their uppercase counterparts.

ui
Description
Functions for interfacing with the GameSense user interface.

Functions
get
ui.get(item: number): any
For a checkbox, returns true or false. For a slider, returns an integer. For a combobox, returns a string. For a multiselect combobox, returns an array of strings. For a hotkey, returns true if the hotkey is active. For a color picker, returns r, g, b, a. Throws an error on failure.

is_menu_open
ui.is_menu_open(): boolean
Returns true if the menu is currently open.

menu_position
ui.menu_position(): number, number
Returns the x, y of the menu, even when closed.

menu_size
ui.menu_size(): number, number
Returns the width, height of the menu, even when closed.

mouse_position
ui.mouse_position(): number, number
Returns current mouse coordinates x, y

name
ui.name(item: number): string
Returns the display name

new_button
ui.new_button(tab: string, container: string, name: string, callback): number
Throws an error on failure. The return value should not be used with ui.set or ui.get.

new_checkbox
ui.new_checkbox(tab: string, container: string, name: string): number
Returns a special value that can be passed to ui.get and ui.set, or throws an error on failure.

new_color_picker
ui.new_color_picker(tab: string, container: string, name: string, r: number, g: number, b: number, a: number): number
Throws an error on failure. The color picker is placed to the right of the previous menu item.

new_combobox
ui.new_combobox(tab: string, container: string, name: string, ...): number
Returns a special value that can be passed to ui.get and ui.set, or throws an error on failure.

new_hotkey
ui.new_hotkey(tab: string, container: string, name: string, inline: boolean, default_hotkey: number): number
Returns a special value that can be passed to ui.get to see if the hotkey is pressed, or throws an error on failure.

new_label
ui.new_label(tab: string, container: string, name: string): number
Creates a new label, this can be used to make otherwise attached menu items standalone or have interactive menus. Returns a special value that can be passed to ui.set, or throws an error on failure.

new_listbox
ui.new_listbox(tab: string, container: string, name: string, items: table): number
Throws an error on failure. Returns a special value that can be used with ui.get. Calling ui.get on a listbox will return the zero-based index of the currently selected string.

new_multiselect
ui.new_multiselect(tab: string, container: string, name: string, ...): number
Returns a special value that can be passed to ui.get and ui.set, or throws an error on failure.

new_slider
ui.new_slider(tab: string, container: string, name: string, min: number, max: number, init_value: number, show_tooltip: boolean, unit: string, scale: number, tooltips: table): number
Returns a special value that can be passed to ui.get and ui.set, or throws an error on failure.

new_string
ui.new_string(name: string, default_value: string): number
Creates a string UI element, can be used to store arbitrary strings in configs. No menu item is created but it has the same semantics as other ui.new_* functions. Returns a special value that can be passed to ui.get and ui.set, or throws an error on failure.

new_textbox
ui.new_textbox(tab: string, container: string, name: string): number
Throws an error on failure. Returns a special value that can be used with ui.get

reference
ui.reference(tab: string, container: string, name: string): number
Avoid calling this from inside a function. Returns a reference that can be passed to ui.get and ui.set, or throws an error on failure. This allows you to access a built-in pre-existing menu items. This function returns multiple values when the specified menu item is followed by unnamed menu items, for example a color picker or a hotkey.

set
ui.set(item: number, value: any, ...)
For checkboxes, pass true or false. For a slider, pass a number that is within the slider's minimum/maximum values. For a combobox, pass a string value. For a multiselect combobox, pass zero or more strings. For referenced buttons, value is ignored and the button's callback is invoked. For color pickers, pass the arguments r, g, b, a.

set_callback
ui.set_callback(item: number, callback)
Sets the change callback of a custom menu item. It will be executed on change and passed the reference

set_enabled
ui.set_enabled(item: number, enabled: boolean)
Sets the enabled state of the menu item

set_visible
ui.set_visible(item: number, visible: boolean)
Sets the visibility of the menu item

type
ui.type(item: number)
Returns the type of an element

update
ui.update(item: number, value: any, ...)
Creates a string UI element, can be used to store arbitrary strings in configs. No menu item is created but it has the same semantics as other ui.new_* functions. Returns a special value that can be passed to ui.get and ui.set, or throws an error on failure.

vector
Description
Built-in euclidean vector math library. To use it, load it at the top of your script using require:

local vector = require("vector")
local myVec = vector(0, 0, 0)

info
The documentation for the vector type is unfinished as it relies on types that aren't in the docs yet.

Functions
__call
vector.__call(x: number, y: number, z: number): vector
Creates a new vector object











aim_fire
Description
Fired when the rage aimbot shoots at a player.

Example
local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}

local function aim_fire(e)
    local flags = {
        e.teleported and "T" or "",
        e.interpolated and "I" or "",
        e.extrapolated and "E" or "",
        e.boosted and "B" or "",
        e.high_priority and "H" or ""
    }

    local group = hitgroup_names[e.hitgroup + 1] or "?"
    print(string.format(
        "Fired at %s (%s) for %d dmg (chance=%d%%, bt=%2d, flags=%s)",
        entity.get_player_name(e.target), group, e.damage,
        math.floor(e.hit_chance + 0.5), globals.toticks(e.backtrack),
        table.concat(flags)
    ))
end

client.set_event_callback("aim_fire", aim_fire)

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
id	Shot ID, this can be used to find the corresponding aim_hit / aim_miss event
target	Target player entindex
hit_chance	Chance the shot will hit, depends on spread
hitgroup	Targeted hit group, this is not the same thing as a hitbox
damage	Predicted damage the shot will do
backtrack	Amount of ticks the player was backtracked
boosted	True if accuracy boost was used to increase the accuracy of the shot
high_priority	True if the shot was at a high priority record, like on shot backtrack
interpolated	Player was interpolated
extrapolated	Player was extrapolated
teleported	Target player was teleporting (breaking lag compensation)
tick	Tick the shot was fired at. This can be used to draw the hitboxes using client.draw_hitboxes
x	X world coordinate of the aim point
y	X world coordinate of the aim point
z	Z world coordinate of the aim point



aim_hit
Description
Fired when the rage aimbot hit a shot at a player.

Example
local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}

local function aim_hit(e)
    local group = hitgroup_names[e.hitgroup + 1] or "?"

    print(string.format(
        "Hit %s in the %s for %d damage (%d health remaining)",
        entity.get_player_name(e.target), group, e.damage,
        entity.get_prop(e.target, "m_iHealth")
    ))
end

client.set_event_callback("aim_hit", aim_hit)

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
id	Shot ID, the corresponding aim_fire event has the same ID
target	Target player entindex
hit_chance	Actual hit chance the shot had
hitgroup	Hit group that was hit. This is not the same thing as a hitbox
damage	Actual damage the shot did




aim_miss
Description
Fired when the rage aimbot missed a shot at a player.

Example
local hitgroup_names = {"generic", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear"}

local function aim_miss(e)
    local group = hitgroup_names[e.hitgroup + 1] or "?"

    print(string.format(
        "Missed %s (%s) due to %s",
        entity.get_player_name(e.target), group, e.reason
    ))
end

client.set_event_callback("aim_miss", aim_miss)

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
id	Shot ID, the corresponding aim_fire event has the same ID
target	Target player entindex
hit_chance	Actual hit chance the shot had
hitgroup	Hit group that was missed. This is not the same thing as a hitbox
reason	Reason the shot was missed. This can be 'spread', 'prediction error', 'death' or '?' (unknown / resolver)



console_input
Description
Fired every time the user types something in the game console and presses enter. Return true from the event handler to make the game not process the input.

Example
client.set_event_callback("console_input", function(text)
    client.log("entered: '", text, "'")
end)

Arguments
Index	Name	Type
0	console input text	string



finish_command
Description
Unknown

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
command_number	Current command number.
chokedcommands	Amount of commands that the client has choked




indicator
Description
This event lets you lets you override how indicators are drawn. There can only be one callback for this event. This event callback is invoked from renderer.indicator and indicators like "DT".

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
text	Drawn text
r	Drawn color: Red 0-255
g	Drawn color: Green 0-255
b	Drawn color: Blue 0-255
a	Alpha 0-255


net_update_end
Description
Fired after an entity update packet is received from the server. (FrameStageNotify FRAME_NET_UPDATE_END)




net_update_start
Description
Fired before the game processes entity updates from the server. (FrameStageNotify FRAME_NET_UPDATE_START) Be careful when using this event to modify entity data, some things have to be restored manually as not even a full update will update them


output
Description
This event lets you override the text drawn in the top left. There can only be one callback for this event. This event callback is invoked from print, client.log, client.color_log, "Missed due to spread" message, etc.

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
text	Drawn text
r	Drawn color: Red 0-255
g	Drawn color: Green 0-255
b	Drawn color: Blue 0-255
a	Alpha 0-255




override_view
Description
Lets you override the camera position and angles.

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
x	Camera X position
y	Camera Y position
z	Camera Z position
pitch	Pitch view angle
yaw	Yaw view angle
fov	Field of view



paint
Description
Fired every time the game renders a frame while being connected to a server. Can be used to draw to the screen using the renderer.* functions.

Example
client.set_event_callback("paint", function()
    renderer.text(15, 15, 255, 255, 255, 255, nil, 0, "hello world")
end)




paint_ui
Description
Fired every time the game renders a frame, even if you're in the menu. Can be used to draw to the screen using the renderer.* functions.




player_chat
Description
Fired when a player sends a message to chat.

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
teamonly	true if the message was sent to team chat
entity	Entity index of the player sending the message
name	Name of the player sending the message
text	Chat message text



post_config_load
Description
Fired after a config has been loaded.



post_config_save
Description
Fired after a config has been saved.



post_render
Description
Fired after a frame is rendered.




pre_config_load
Description
Fired before a config will be loaded.



pre_config_save
Description
Fired before a config will be saved.




pre_predict_command
Description
This event doesn't have any known information about it yet (awaiting staff clarification).



pre_render
Description
Fired before a frame is rendered.



pre_render_3d
Description
This event doesn't have any known information about it yet (awaiting staff clarification).


predict_command
Description
Fired when the game prediction is ran.

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
command_number	Command number of the predicted command



run_command
Description
Fired every time the game runs a command (usually 64 times a second, equal to tickrate) while you're alive. This is the best event for processing data that only changes when the game receives an update from the server, like information about other players.

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
chokedcommands	Amount of commands that the client has choked
command_number	Current command number


setup_command
Description
Fired every time the game prepares a move command that's sent to the server. This is ran before cheat features like antiaim and can be used to modify user input (view angles, pressed keys, movement) how it's seen by the cheat. For example, setting in_use = 1 will disable antiaim the same way pressing use key ingame does. This is the preferred method of setting user input and should be used instead of client.exec whenever possible.

Arguments
Index	Name	Type
0	Argument #0	table
#0 - Properties
Name	Description
chokedcommands	Amount of commands that the client has choked
command_number	Current command number
discharge_pending	Set to true to discharge double tap. Does not work with other exploit features
pitch	Pitch view angle
yaw	Yaw view angle
forwardmove	Forward / backward speed (-450 to 450)
sidemove	Left / right speed (-450 to 450)
move_yaw	Yaw angle that's used for movement. If not set, view yaw is used
allow_send_packet	Set to false to make the cheat choke the current command (when possible)
no_choke	Set to true to avoid unnecessary choking like fake lag. Some features (like anti-aimbot) don't respect this field
quick_stop	Whether or not quick stop is being triggered
force_defensive	Set to true to forcibly activate defensive
in_attack	IN_ATTACK Button
in_jump	IN_JUMP Button
in_duck	IN_DUCK Button
in_forward	IN_FORWARD Button
in_back	IN_BACK Button
in_use	IN_USE Button
in_cancel	IN_CANCEL Button
in_left	IN_LEFT Button
in_right	IN_RIGHT Button
in_moveleft	IN_MOVELEFT Button
in_moveright	IN_MOVERIGHT Button
in_attack2	IN_ATTACK2 Button
in_run	IN_RUN Button
in_reload	IN_RELOAD Button
in_alt1	IN_ALT1 Button
in_alt2	IN_ALT2 Button
in_score	IN_SCORE Button
in_speed	IN_SPEED Button
in_walk	IN_WALK Button
in_zoom	IN_ZOOM Button
in_weapon1	IN_WEAPON1 Button
in_weapon2	IN_WEAPON2 Button
in_bullrush	IN_BULLRUSH Button
in_grenade1	IN_GRENADE1 Button
in_grenade2	IN_GRENADE2 Button
in_attack3	IN_ATTACK3 Button
weaponselect	
weaponsubtype	

shutdown
Description
Fired when one of the two following conditions are met:

When the game is being closed
When Lua scripts are being unloaded/reloaded


string_cmd
Description
Fired before a string command (chat messages, weapon inspecting, buy commands) is sent to the server.

Arguments
Index	Name	Type
0	string command	string



voice
Description
Fired every time that voice data has been received.

Example
Credits to FlowerHvH1337 for this example:

local voice_data_t = ffi.typeof[[
    struct {
        char     pad_0000[8];
        int32_t  client;
        int32_t  audible_mask;
        uint64_t xuid;
        void*    voice_data;
        bool     proximity;
        bool     caster;
        char     pad_001E[2];
        int32_t  format;
        int32_t  sequence_bytes;
        uint32_t section_number;
        uint32_t uncompressed_sample_offset;
        char     pad_0030[4];
        uint32_t has_bits;
    } *
]]

client.set_event_callback("voice", function(e)
    local data = e.data
    local voice_data = ffi.cast(voice_data_t, data)
end)




achievement_event
Description
A player has received an achievement (OB only)

Arguments
Type	Name	Description
string	achievement_name	non-localized name of achievement
short	cur_val	# of steps toward achievement
short	max_val	total # of steps in achievement



achievement_increment
Description
Sent whenever an achievement that's tracked on the HUD increases (OB only)

Arguments
Type	Name	Description
long	achievement_id	ID of achievement that went up
short	cur_val	# of steps toward achievement
short	max_val	total # of steps in achievement


base_player_teleported
Description
??? (OB only)

Arguments
Type	Name	Description
short	entindex	



bonus_updated
Description
??? (OB only)

Arguments
Type	Name	Description
short	numadvanced	
short	numbronze	
short	numsilver	
short	numgold	


break_breakable
Description
A breakable (func_break) is broken.

Arguments
Type	Name	Description
long	entindex	index of the entity
short	userid	userid who broke the entity
byte	material	BREAK_GLASS, BREAK_WOOD, etc



break_prop
Description
A breakable prop is broken.

Arguments
Type	Name	Description
long	entindex	index of the entity
short	userid	userid who broke the entity



browse_replays
Description
??? (OB only)


cart_updated
Description
??? (OB only)


entered_performance_mode
Description
??? (OB only)


entity_killed
Description
An entity has been killed (OB only)

Arguments
Type	Name	Description
long	entindex_killed	index of the killed entity
long	entindex_attacker	index of the attacker
long	entindex_inflictor	index of the inflictor (weapon id, etc)
long	damagebits	the damagebits of the attack



flare_ignite_npc
Description
A flare has ignited a NPC (OB only)

Arguments
Type	Name	Description
long	entindex	entity ignited



game_end
Description
A game ended

Arguments
Type	Name	Description
byte	winner	winner team/user id




game_init
Description
Sent when a new game is started (OB only)



game_message
Description
A message sent by game logic to everyone

Arguments
Type	Name	Description
byte	target	0 console, 1 HUD
string	text	the message text


game_newmap
Description
Sent when new map is completely loaded

Arguments
Type	Name	Description
string	mapname	map name


Description
A new game starts

Arguments
Type	Name	Description
long	roundslimit	max round
long	timelimit	time limit
long	fraglimit	frag limit
string	objective	round objective


gc_connected
Description
??? (OB only)


helicopter_grenade_punt_miss
Description
??? (OB only)

hltv_changed_mode
Description
??? (OB only)

Arguments
Type	Name	Description
short	oldmode	
short	newmode	
short	obs_target	


hltv_changed_target
Description
??? (OB only)

Arguments
Type	Name	Description
short	mode	
short	old_target	
short	obs_target	

inventory_updated
Description
??? (OB only)

