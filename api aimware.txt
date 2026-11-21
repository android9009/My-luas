Introduction
All our software tagged as V5 ship with a Lua scripting language that expose new classes and libraries that allow users to extend the existing features or create new one.

If you are new with the Lua scripting language, the Lua Docs and the examples inside this knowledge base are the perfect start.

To write the code you can use the built-in editor or use any text editor of your choice.

Warning

Encoding errors might happen on some systems. Select UTF-8 encoding in your favorite IDE.

Note

You should keep most of your scripts functions and variables as local to avoid collision with other scripts. Global variables should only be used to write libraries or scripts that interact with each other.Load a script
In order to load a Lua script you have multiple options depending on the use case.

Built-in Editor
The Lua Editor is the built-in editor inside the software.

Copy the selected script you want to clipboard (CTRL+C).
Open Settings tab in the Cheat Menu.
Click Create.
Click CTRL+V on Lua Editor.
Click Run and Save.
Your editor of choice
Click Open Settings Folder from Settings->Advanced tab in the Cheat Menu.
Make new file called example.lua
Paste one of the scripts you want into the file.
Save it then click Refresh under Lua Scripts list in menu.
Select the script from list and press Load.
Console
Open CONSOLE tab in cheat menu and then write the following:

lua.run "print('Hello from lua');"      --To run lua script directly
lua.load script.lua                     --To run lua script from file
Automatically
Select the script and click Set As Autorun. This will set the script to be loaded automatically every time the software is loaded.Register a callback
In short terms a callback is a function that will be invoked at a specific point in time. This will allow you to execute specific logic at the right stage.

Registering a callback is done by using callbacks.Register from the Callbacks library.

Note

Read more about the callbacks.Register.

Let's say you would like to draw the amount of seconds passed since injection. You will require to register a callback that will get called by our software each time is executing the drawing logic.

local function ExampleDrawingHook()
    draw.Color(220, 50, 50, 255);
    draw.Text(128, 128, tostring(common.Time()));
end

callbacks.Register("Draw", "ExampleDrawingHook", ExampleDrawingHook);Examples
Various examples of scripts.

Draw time since cheat inject in seconds
local function ExampleDrawingHook()
    draw.Color(220, 50, 50, 255);
    draw.Text(128, 128, tostring(common.Time()));
end

callbacks.Register("Draw", "ExampleDrawingHook", ExampleDrawingHook);
Snap lines ESP
local function ExampleSnapLines()
    local screenCenterX, screenH = draw.GetScreenSize();
    screenCenterX = screenCenterX * 0.5;

    draw.Color(255, 0, 0, 255);

    local players = entities.FindByClass("CCSPlayer");

    for i = 1, #players do
        local player = players[i];

        if player:IsAlive() then
            local x, y = client.WorldToScreen(player:GetAbsOrigin());

            if x ~= nil and y ~= nil then
                draw.Line(x, y, screenCenterX, screenH);
            end
        end
    end
end

callbacks.Register("Draw", "ExampleSnapLines", ExampleSnapLines);
Kill Say
local Kill_String = "get owned";
local Death_String = "nice luck";

local function CHAT_KillSay(Event)

   if (Event:GetName() == "player_death") then

       local ME = client.GetLocalPlayerIndex();

       local INT_UID = Event:GetInt("userid");
       local INT_ATTACKER = Event:GetInt("attacker");

       local NAME_Victim = client.GetPlayerNameByUserID(INT_UID);
       local INDEX_Victim = client.GetPlayerIndexByUserID(INT_UID);

       local NAME_Attacker = client.GetPlayerNameByUserID(INT_ATTACKER);
       local INDEX_Attacker = client.GetPlayerIndexByUserID(INT_ATTACKER);

       if (INDEX_Attacker == ME and INDEX_Victim ~= ME) then

           client.ChatSay(" " .. tostring(Kill_String) .. " " .. NAME_Victim);

       elseif (INDEX_Victim == ME and INDEX_Attacker ~= ME) then

           client.ChatSay(" " .. tostring(Death_String) .. " " .. NAME_Attacker);

       end

   end

end

client.AllowListener("player_death");

callbacks.Register("FireGameEvent", "AWKS", CHAT_KillSay);
Auto Buy
local function autobuy(event)
   if event:GetName() == "round_prestart" then
       client.Command("buy scar20; buy deagle; buy vest; buy vesthelm; buy incgrenade; buy molotov; buy hegrenade; buy smokegrenade", true)
   end
end

client.AllowListener("round_prestart");

callbacks.Register("FireGameEvent", "autobuy", autobuy);
Radio Spammer
local last_spam  = globals.TickCount()

local function RadioSpam()
   if globals.TickCount() - last_spam > 32 then
       client.Command("getout")
       last_spam = globals.TickCount()
   end
end

callbacks.Register("Draw", "RadioSpam", RadioSpam);
GUI
local msc_ref = gui.Reference("MISC", "Part 1");
local msc_lua_checkbox = gui.Checkbox(msc_ref, "msc_lua_checkbox", "Lua Checkbox", false);

local wnd_luatest = gui.Window("wnd_luatest", "Lua GUI", 200, 200, 200, 400);
local lua_checkbox = gui.Checkbox(wnd_luatest, "lua_checkbox", "Checkbox", false);
local lua_slider = gui.Slider(wnd_luatest, "lua_slider", "Slider", 0, 0, 100);
local lua_keybox = gui.Keybox(wnd_luatest, "lua_keybox", "Keybox", 0);
local lua_combobox = gui.Combobox(wnd_luatest, "lua_combobox", "Combobox", "Combo1", "Combo2", "Combo3");

local lua_groupbox = gui.Groupbox(wnd_luatest, "Groupbox", 16, 200, 168, 100);
local lua_groupcheckbox = gui.Checkbox(lua_groupbox, "lua_groupcheckbox", "Group Checkbox", true);

local debugFont = draw.CreateFont("Tahoma", 60);

local function OnDraw()
    draw.SetFont(debugFont);
    if lua_checkbox:GetValue() then
        draw.Text(200, 200, "Checkbox is checked");
    end
    draw.Text(200, 300, "Slider: " .. lua_slider:GetValue());
end

callbacks.Register("Draw", "LuaGuiTest", OnDraw);
Vector math
print(vector.Length(100, 100, 100));
print(vector.Add({0, 0, 0}, {100, 100, 100}));
print(vector.Add({0, 0, 0}, 100));
print(vector.Distance(0, 0, 0, 100, 100, 100));
print(vector.Distance({0, 0, 0 }, {100, 100, 100}));

local function OnDrawESP(builder)
    local ent = builder:GetEntity();
    local localply = entities.GetLocalPlayer();

    builder:AddTextTop("Distance: " .. vector.Distance({ent:GetAbsOrigin()}, {localply:GetAbsOrigin()}));
end

callbacks.Register("DrawESP", OnDrawESP);
Chat message replacement
callbacks.Register("SendStringCmd", function(cmd)
    -- replace "no" with "yes"
    if string.find(cmd:Get(), "say \"no\"") == 1 then
        cmd:Set("say \"yes\"");
    end
end)
Block sending regular chat messages
callbacks.Register("SendStringCmd", function(cmd)
    if string.find(cmd:Get(), "say") == 1 then
        cmd:Set(""); -- chat message wont be sent
    end
end)
Chat logging
-- For more information about user messages look here:
-- https://github.com/SteamDatabase/Protobufs/blob/master/csgo/cstrike15_usermessages.proto

local function UserMessageCallback(msg)

    -- CS_UM_SayText2
    if msg:GetID() == 6 then

        -- CCSUsrMsg_SayText2.ent_idx
        local index = msg:GetInt(1);

        -- CCSUsrMsg_SayText2.params
        local message = msg:GetString(4, 1);

        local name = client.GetPlayerNameByIndex(index);

        print(name .. " says: " .. message);

    end

end

callbacks.Register("DispatchUserMessage", "UserMessageExample", UserMessageCallback);
SVG drawing
local svgData = http.Get("https://upload.wikimedia.org/wikipedia/commons/f/fd/Ghostscript_Tiger.svg");

local imgRGBA, imgWidth, imgHeight = common.RasterizeSVG(svgData);

local texture = draw.CreateTexture(imgRGBA, imgWidth, imgHeight);

local function ExampleTextureDrawing()
    draw.SetTexture(texture);
    draw.FilledRect(0, 0, imgWidth, imgHeight);
end

callbacks.Register("Draw", "ExampleTextureDrawing", ExampleTextureDrawing);
File writing
local f = file.Open("myfile.txt", "w");
f:Write("mydata");
f:Close();
UDP client and server
local serverIP = "127.0.0.1";
local serverPort = 1234;

local server = network.Socket("UDP");
local client = network.Socket("UDP");

if server:Bind(serverIP, serverPort) then
    print("Socket bound to port " .. serverPort);
end

local size = client:SendTo(serverIP, serverPort, "Hello!");

if size > 0 then
    print("Sent " .. size .. " bytes");
end

callbacks.Register("Draw", function()
    local msg, ip, port = server:RecvFrom("0.0.0.0", 0, 100);

    if msg then
        print("Received message from " .. ip .. ":" .. port .. ": " .. msg);
    end
end)Callbacks
Available callbacks inside all products marked as V5.

Draw()
Called during the drawing stage every frame. Callback returns nothing.

Unload()
Called when script is getting unloaded.Global GetScriptName
Get the current name of the script.

Syntax
string GetScriptName()
Parameters
This function has no parameters.

Return value
The function returns a string with the name of the script.

Example
local name = GetScriptName();

print(name);Global LoadScript
Load an additional script within a script.

Syntax
LoadScript(filename:string)
Parameters
filename The script file to load.

Return value
The function has no return value.Global LoadScript
Unload a script within a script.

Syntax
UnloadScript(filename:string)
Parameters
filename The script file to unload.

Return value
The function has no return value.Global RunScript
This function is a wrapper of LoadScript.

Syntax
RunScript(filename:string)
Parameters
filename The script file to run.

Return value
The function has no return value.Global print
Print a formatted string inside the console.

Syntax
print(...)
Parameters
print is a variadic function.

Return value
The function has no return value.Class: EulerAngles
Fields
number: x

number: y

number: z

Note

Instead of x, y and z you can also use pitch, yaw and roll.

Functions
Clear() Reset the angles to 0.

Vector3 Forward() Get the forward vector of the angle.

Vector3 Right() Get the right vector of the angle.

Vector3 Up() Get the up vector of the angle.

Normalize() Normalize the angle.

Clamp() Clamp the angle.

Example
local targetDirection = localplayer:GetAbsOrigin() - entity:GetAbsOrigin();
local targetAngles = targetDirection:Angles();
cmd.viewangles = targetAngles;Class: File
Fields
This class has no fields.

Functions
string Read() Read the file content.

Write(buffer:string) Write inside the file.

int Size() Get the file size.

Close() Close the handle.

Example
file:Write("file.txt", "1000");
local text = file:Read("file.text");Class: Font
Fields
This class has no fields.

Functions
This class has no functions.Class: GuiObject
Fields
This class has no fields.

Functions
GetName() Return name of the object.

SetName() Set the name of the object. Example, button label.

SetValue(string:varname, object:value)Set value of the object.

GetValue() Return value of the object.

SetActive() Make this object active. For windows, makes the window appear or disappear.

IsActive() Return boolean, true or false if visible.

SetText(string:text) Set the text of the object. For gui.Text, changes the displayed text.

SetOpenKey(keycode) Change the key bind to open/close gui.Window.

SetDescription(string:text) Add description to created object.

SetOptions(option1, option2, ...) Set options for Combobox or Listbox.

SetPosX(integer:number) Set the position of X to the object. Relative to parent

SetPosY(integer:number) Set the position of Y to the object. Relative to parent

SetWidth(integer:number) Set the object width.

SetHeight(integer:number) Set the object Height.

SetInvisible(boolean) Make object invisible or visible.

SetDisabled(boolean) Set object to disabled state (not clickable).

Remove() Remove UI object.

Reference(object) Checks for only the child objects.

GetString() Returns the value as a string object.

SetString(string:text) Sets the object value as a string.

SetIcon(texture, integer:scale) Sets the window icon.

Children() Returns a iterator for child objects.

Example
Gui object creation
local Tab = gui.Tab(gui.Reference("Visuals"), "ScriptTabValue", "MyScript");
local Groupbox = gui.Groupbox(tab, "Groupbox", 16, 16);

local Value, Name = Groupbox:GetValue(), Groupbox:GetName();

Groupbox:SetDescription("New Description");
Groupbox:SetDisabled(true);
Groupbox:Remove();
Getting and setting config values
local ragebotenabled = gui.GetValue("rbot.master");
local speedburst = gui.GetValue("misc.speedburst.enable");

gui.SetValue("misc.speedburst.enable", true);
Note

To retrieve set config values, export your config to clipboard, and you will be able to see the values you can get/set.

Reading children objects
local function PrintChildren(obj, prefix)
    print(prefix .. obj:GetName());
    for child in obj:Children() do
        PrintChildren(child, prefix .. "\t");
    end
end

PrintChildren(gui.Reference("MENU"), "");Class: Socket
Fields
This class has no fields.

Functions
bool Bind(addr:string, port:int)

Bind the socket. Returns a boolean if bound successfully.

int SendTo(addr:string, port:int, message:string)

Send message via UDP. Returns message size.

mixed RecvFrom(addr:string, port:int, size:int)

Receive data from the socket. Returns nil if nothing is received, otherwise message, addr, port.

Close()

Close the connection.

Example
local serverIP = "127.0.0.1";
local serverPort = 1234;

local server = network.Socket("UDP");
local client = network.Socket("UDP");

if server:Bind(serverIP, serverPort) then
    print("Socket bound to port " .. serverPort);
end

local size = client:SendTo(serverIP, serverPort, "Hello!");

if size > 0 then
    print("Sent " .. size .. " bytes");
end

callbacks.Register("Draw", function()
    local msg, ip, port = server:RecvFrom("0.0.0.0", 0, 100);

    if msg then
        print("Received message from " .. ip .. ":" .. port .. ": " .. msg);
    end
end)Class: Texture
Fields
This class has no fields.

Functions
This class has no functions.Class: Vector3
Fields
number: x

number: y

number: z

Functions
Length() Get the length of an vector3.

LengthSqr() Get the length of an vector3 by squareroot.

Length2D() Get the length of an vector3 by 2 dimension.

Length2DSqr() Get the length of an vector3 by 2D to the squareroot value.

Dot(Vector3) Dot the vector3.

Cross(Vector3) Cross the vector3.

Clear() Clear out the vector3.

Normalize() Normalize the vector3.

Right() Get the right value from an vector3.

Up() Get the up value from an vector3.

Angles() Get the angles from an vector3.

Example
local v1 = Vector3(100, 0, 0);
local v2 = Vector3(200, 0, 0);

print(v1:LengthSqr());
print(v2:Length2D());mem.Alloc
Allocate memory with read+write access.

Syntax
mem.Alloc(size:int)
Parameters
size Size of memory to allocate.

Return value
Returns the address of the memory allocated. If the memory could not get allocated returns nil.mem.Free
Free memory allocated with mem.Alloc.

Syntax
mem.Free(ptr:int)
Parameters
ptr Address of the memory previously allocated.

Return value
The function has no return value.mem.GetModuleBase
Get the base address of a loaded module.

Syntax
mem.GetModuleBase(string:name)
Parameters
name Name of the DLL.

Return value
Returns the base address of the loaded module, otherwise nil if not found.mem.GetModuleSection
Get address and size of a module section.

Syntax
{address, size} mem.GetModuleSection(int:address, string:name)
Parameters
address Base address of the DLL module. name Name of the section.

Return value
Returns the address and size of the section. If the section can not be found returns nil.mem.FindPattern
Find inside the .text section of a module a specific location using a pattern.

Syntax
mem.FindPattern(string:name, string:pattern)
Parameters
name Name of the DLL. pattern Pattern to search.

Return value
Returns the address found based on the pattern.

Example
local address = mem.FindPattern("client.dll", "C3 ?? CC")input.GetMousePos
Get the current mouse position.

Syntax
{x, y} input.GetMousePos()
Parameters
This function has no parameters.

Return value
Returns the x, y coordinates of the mouse on screen.

Example
local X, Y = input.GetMousePos();input.IsButtonDown
Checks if an button is down by keycode

Syntax
input.IsButtonDown(keycode:int)
Parameters
keycode Keycode to check for.

Example
if input.IsButtonDown(1) then
    print("Left click is down!");
end
Keylist
For more information about key codes Keylistinput.IsButtonPressed
Checks if an button is pressed by keycode

Syntax
input.IsButtonPressed(keycode:int)
Parameters
keycode Keycode to check for.

Example
if input.IsButtonPressed(2) then
    print("Right click is pressed!");
end
Keylist
For more information about key codes Keylistinput.IsButtonReleased
Checks if an button is released by keycode.

Syntax
input.IsButtonReleased(keycode:int)
Parameters
keycode Keycode to check for.

Example
if input.IsButtonReleased(1) then
    print("Left click is released!");
end
Keylist
For more information about key codes Keylistinput.GetMouseWheelDelta
Returns the accumulated mouse scroll value

Syntax
number input.GetMouseWheelDelta()
Parameters
This function has no parameters.

Return value
This function return the accumulated mouse scroll.

Example
local delta = input.GetMouseWheelDelta();List of keys
KEY	CODE	NAME
KEY_FIRST	0	
KEY_NONE	0	
KEY_0	1	Left Mouse
KEY_1	2	Right Mouse
KEY_3	3	
KEY_4	5	
KEY_5	6	
KEY_6	7	
KEY_7	8	
KEY_9	10	
KEY_A	11	
KEY_B	12	
KEY_C	13	
KEY_D	14	
KEY_E	15	
KEY_F	16	
KEY_G	17	
KEY_H	18	
KEY_I	19	
KEY_J	20	
KEY_K	21	
KEY_L	22	
KEY_M	23	
KEY_N	24	
KEY_O	25	
KEY_P	26	
KEY_Q	27	
KEY_R	28	
KEY_S	29	
KEY_T	30	
KEY_U	31	
KEY_V	32	
KEY_W	33	
KEY_X	34	
KEY_Y	35	
KEY_Z	36	
KEY_PAD_0	37	Keypad number 0 key
KEY_PAD_1	38	Keypad number 1 key
KEY_PAD_2	39	Keypad number 2 key
KEY_PAD_3	40	Keypad number 3 key
KEY_PAD_4	41	Keypad number 4 key
KEY_PAD_5	42	Keypad number 5 key
KEY_PAD_6	43	Keypad number 6 key
KEY_PAD_7	44	Keypad number 7 key
KEY_PAD_8	45	Keypad number 8 key
KEY_PAD_9	46	Keypad number 9 key
KEY_PAD_DIVIDE	47	Keypad division/slash key (/)
KEY_PAD_MULTIPLY	48	Keypad asterisk key (*)
KEY_PAD_MINUS	49	Keypad minus key
KEY_PAD_PLUS	50	Keypad plus key
KEY_PAD_ENTER	51	Keypad enter key
KEY_PAD_DECIMAL	52	Keypad dot key (.)
KEY_LBRACKET	53	
KEY_RBRACKET	54	
KEY_SEMICOLON	55	
KEY_APOSTROPHE	56	
KEY_BACKQUOTE	57	
KEY_COMMA	58	
KEY_PERIOD	59	
KEY_SLASH	60	
KEY_BACKSLASH	61	
KEY_MINUS	62	
KEY_EQUAL	63	
KEY_ENTER	64	
KEY_SPACE	65	
KEY_BACKSPACE	66	
KEY_TAB	67	
KEY_CAPSLOCK	68	
KEY_NUMLOCK	69	
KEY_ESCAPE	70	
KEY_SCROLLLOCK	71	
KEY_INSERT	72	
KEY_DELETE	73	
KEY_HOME	74	
KEY_END	75	
KEY_PAGEUP	76	
KEY_PAGEDOWN	77	
KEY_BREAK	78	
KEY_LSHIFT	79	The left Shift key, has been seen to be triggered by Right Shift in PANEL:OnKeyCodePressed
KEY_RSHIFT	80	
KEY_LALT	81	
KEY_RALT	82	
KEY_LCONTROL	83	
KEY_RCONTROL	84	
KEY_LWIN	85	The left Windows key or the Command key on Mac OSX
KEY_RWIN	86	The right Windows key or the Command key on Mac OSX
KEY_APP	87	
KEY_UP	88	
KEY_LEFT	89	
KEY_DOWN	90	
KEY_RIGHT	91	
KEY_F1	92	
KEY_F2	93	
KEY_F3	94	
KEY_F4	95	
KEY_F5	96	
KEY_F6	97	
KEY_F7	98	
KEY_F8	99	
KEY_F9	100	
KEY_F10	101	
KEY_F11	102	
KEY_F12	103	
KEY_CAPSLOCKTOGGLE	104	
KEY_NUMLOCKTOGGLE	105	
KEY_LAST	106	
KEY_SCROLLLOCKTOGGLE	106	
KEY_COUNT	107	
KEY_XBUTTON_A	114	
KEY_XBUTTON_B	115	
KEY_XBUTTON_X	116	
KEY_XBUTTON_Y	117	
KEY_XBUTTON_LEFT_SHOULDER	118	
KEY_XBUTTON_RIGHT_SHOULDER	119	
KEY_XBUTTON_BACK	120	
KEY_XBUTTON_START	121	
KEY_XBUTTON_STICK1	122	
KEY_XBUTTON_STICK2	123	
KEY_XBUTTON_UP	146	
KEY_XBUTTON_RIGHT	147	
KEY_XBUTTON_DOWN	148	
KEY_XBUTTON_LEFT	149	
KEY_XSTICK1_RIGHT	150	
KEY_XSTICK1_LEFT	151	
KEY_XSTICK1_DOWN	152	
KEY_XSTICK1_UP	153	
KEY_XBUTTON_LTRIGGER	154	
KEY_XBUTTON_RTRIGGER	155	
KEY_XSTICK2_RIGHT	156	
KEY_XSTICK2_LEFT	157	
KEY_XSTICK2_DOWN	158	
KEY_XSTICK2_UP	159	
callbacks.Register
Register a callback.

Syntax
callbacks.Register(id:string, unique:string, function)
callbacks.Register(id:string, function)
Parameters
id Id of callback.

unique Unique name of callback.

function Lua function.

Return value
This function has no return value.

Example
callbacks.Register("Draw", "Unique", function()
    print("Draw Callback");
end)

callbacks.Register("Draw", function()
    print("Draw Callback");
end)callbacks.Unregister
Unregister a callback.

Syntax
callbacks.Unregister(id:string, unique:string)
Parameters
id Id of callback.

unique Unique name of callback.

Return value
This function has no return value.

Example
callbacks.Unregister("Draw", "Unique");common.Time
Time since software was loaded in seconds.

Syntax
number common.Time()
Parameters
This function has no parameters.

Return value
Returns the amount of seconds since software is loaded.common.DecodePNG
Decode a PNG image.

Syntax
{rgba, width:int, height:int} common.DecodePNG(data)
Parameters
data The image data to decode.

Return value
Returns rgba, width and height of the decoded image.common.DecodeJPEG
Decode a JPEG image.

Syntax
{rgba, width:int, height:int} common.DecodeJPEG(data)
Parameters
data The image data to decode.

Return value
Returns rgba, width and height of the decoded image.common.RasterizeSVG
Rasterize a SVG image.

Syntax
{rgba, width:int, height:int} common.RasterizeSVG(data, scale:number)
Parameters
data The image data to decode.

scale Number to scale the image.

Return value
Returns rgba, width and height of the decoded image.draw.AddFontResource
Add .ttf file data to available fonts.

Syntax
draw.AddFontResource(string:ttfdata)
Parameters
string:ttfdata The .ttf file data.

Example
draw.AddFontResource("location/to/ttf/file.ttf")
local Font = draw.CreateFont("ttfname", 20, 100)

callbacks.Register("Draw", function()
    draw.SetFont(Font);

    draw.Color(255, 138, 130, 255);

    draw.Text(60, 60, "Text");
end)
Note

For more information about the different types of fonts check the Font List.draw.Color
Set the color for drawing shapes and texts.

Syntax
draw.Color(r, g, b, a)
Parameters
red The red channel color. Max 255.

green The green channel color. Max 255.

blue The blue channel color. Max 255.

alpha The alpha channel opacity. Max 255.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.Text(0, 0, "TextWithColor");
end)draw.Color
Set the color for drawing shapes and texts.

Syntax
draw.Color(r, g, b, a)
Parameters
red The red channel color. Max 255.

green The green channel color. Max 255.

blue The blue channel color. Max 255.

alpha The alpha channel opacity. Max 255.

Exampledraw.CreateFont
Create a new font to draw with. Set current font for drawing. To be used with DrawText.

Syntax
draw.CreateFont(string:font, int:height, int:weight(optional), bool:outline(optional), bool:smooth(optional))
Parameters
string:font The font type to use.

integer:height The height size that the text will be.

integer:weight(optional) The amount of darkness being added. 100-900, increments of 100.

bool:outline(optional) Enable text outline. False by default.

bool:smooth(optional) Enable ClearType anti-aliasing. True by default.

Example
local Font = draw.CreateFont("Bahnschrift", 20, 100)

callbacks.Register("Draw", function()
    draw.SetFont(Font);

    draw.Color(255, 138, 130, 255);

    draw.Text(60, 60, "Text");
end)


Fontlist
For more information about the different types of fonts. Font List.draw.CreateTexture
Create new texture to use for drawing.

Syntax
{texture} draw.CreateTexture(rgba, int:width, int:height)
Parameters
rgba The color of the texture.

integer:width The width of the texture.

integer:height The height of the texture.

Example
local svgData = http.Get("https://upload.wikimedia.org/wikipedia/commons/f/fd/Ghostscript_Tiger.svg");

local imgRGBA, imgWidth, imgHeight = common.RasterizeSVG(svgData);

local texture = draw.CreateTexture(imgRGBA, imgWidth, imgHeight);

callbacks.Register("Draw", function()
    draw.SetTexture(texture);
    draw.FilledRect(0, 0, imgWidth, imgHeight);
end)
draw.FilledCircle
Draw filled circle.

Syntax
draw.FilledCircle(int:x, int:y, int:radius)
Parameters
integer:x Axis x.

integer:y Axis y.

integer:radius Round size.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.FilledCircle(150, 150, 100);
end)
draw.FilledRect
Draw filled rectangle with top left point at x1, y1 and bottom right point at x2, y2.

Syntax
draw.FilledRect(int:x1, int:y1, int:x2, int:y2)
Parameters
integer:x1 First point number of x.

integer:y1 First point number of y.

integer:x2 Second point number of x, Changes Width.

integer:y2 Second point number of y, Changes Height.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.FilledRect(50, 50, 300, 200);
end)Font List
Note

If a font is not installed in the system the browser would display a fallback version.

NAME	Sample
Arial	
Hey, made by lomar!

Microsoft Himalaya	
Hey, made by lomar!

Segoe UI Black	
Hey, made by lomar!

Audi Type	
Hey, made by lomar!

Microsoft JhengHei	
Hey, made by lomar!

Segoe UI Emoji	
Hey, made by lomar!

Bahnschrift	
Hey, made by lomar!

Microsoft JhengHei Light	
Hey, made by lomar!

Segoe UI Historic	
Hey, made by lomar!

Bahnschrift Light	
Hey, made by lomar!

Microsoft JhengHei UI	
Hey, made by lomar!

Segoe UI Light	
Hey, made by lomar!

Bahnschrift Semibold	
Hey, made by lomar!

Microsoft JhengHei UI Light	
Hey, made by lomar!

Segoe UI Semibold	
Hey, made by lomar!

Bahnschrift Semilight	
Hey, made by lomar!

Microsoft New Tai Lue	
Hey, made by lomar!

Segoe UI Semilight	
Hey, made by lomar!

Calibri	
Hey, made by lomar!

Microsoft PhagsPa	
Hey, made by lomar!

Segoe UI Symbol	
Hey, made by lomar!

Calibri Light	
Hey, made by lomar!

Microsoft Sans Serif	
Hey, made by lomar!

SimSun	
Hey, made by lomar!

Cambria	
Hey, made by lomar!

Microsoft Tai Le	
Hey, made by lomar!

SimSun-ExtB	
Hey, made by lomar!

Cambria Math	
Hey, made by lomar!

Microsoft YaHei	
Hey, made by lomar!

Sitka Banner	
Hey, made by lomar!

Candara	
Hey, made by lomar!

Microsoft YaHei Light	
Hey, made by lomar!

Sitka Display	
Hey, made by lomar!

Comic Sans MS	
Hey, made by lomar!

Microsoft YaHei UI	
Hey, made by lomar!

Sitka Heading	
Hey, made by lomar!

Consolas	
Hey, made by lomar!

Microsoft YaHei UI Light	
Hey, made by lomar!

Sitka Small	
Hey, made by lomar!

Constantia	
Hey, made by lomar!

Microsoft Yi Baiti	
Hey, made by lomar!

Sitka Subheading	
Hey, made by lomar!

Corbel	
Hey, made by lomar!

MingLiU-ExtB	
Hey, made by lomar!

Sitka Text	
Hey, made by lomar!

Courier New	
Hey, made by lomar!

MingLiU_HKSCS-ExtB	
Hey, made by lomar!

Sylfaen	
Hey, made by lomar!

Ebrima	
Hey, made by lomar!

Mongolian Baiti	
Hey, made by lomar!

Symbol	
Hey, made by lomar!

Franklin Gothic	
Hey, made by lomar!

MS Gothic	
Hey, made by lomar!

Tahoma	
Hey, made by lomar!

Gabriola	
Hey, made by lomar!

MS PGothic	
Hey, made by lomar!

Times New Roman	
Hey, made by lomar!

Gadugi	
Hey, made by lomar!

MS UI Gothic	
Hey, made by lomar!

Trebuchet MS	
Hey, made by lomar!

Georgia	
Hey, made by lomar!

MV Boli	
Hey, made by lomar!

Verdana	
Hey, made by lomar!

HoloLens MDL2 Assets	
Hey, made by lomar!

Myanmar Text	
Hey, made by lomar!

Webdings	
Hey, made by lomar!

Impact	
Hey, made by lomar!

Nirmala UI	
Hey, made by lomar!

Wingdings	
Hey, made by lomar!

Javanese Text	
Hey, made by lomar!

Nirmala UI Semilight	
Hey, made by lomar!

Yu Gothic	
Hey, made by lomar!

Leelawadee UI	
Hey, made by lomar!

Open Sans	
Hey, made by lomar!

Yu Gothic Light	
Hey, made by lomar!

Leelawadee UI Semilight	
Hey, made by lomar!

Palatino Linotype	
Hey, made by lomar!

Yu Gothic Medium	
Hey, made by lomar!

Lucida Console	
Hey, made by lomar!

Quire Sans Pro	
Hey, made by lomar!

Yu Gothic UI	
Hey, made by lomar!

Lucida Grande	
Hey, made by lomar!

Segoe MDL2 Assets	
Hey, made by lomar!

Yu Gothic UI Light	
Hey, made by lomar!

Malgun Gothic	
Hey, made by lomar!

Segoe Print	
Hey, made by lomar!

Yu Gothic UI Semibold	
Hey, made by lomar!

Malgun Gothic Semilight	
Hey, made by lomar!

Segoe Script	
Hey, made by lomar!

Yu Gothic UI Semilight	
Hey, made by lomar!draw.GetScreenSize
Get the size of the current screen.

Syntax
{width:int, height:int} draw.GetScreenSize()
Return value
integer:width Width of the screen.

integer:height Height of the screen.

Example
callbacks.Register("Draw", function()
    local w, h = draw.GetScreenSize();

    print(w .. "x" .. h);  

    --1600x900
end)draw.GetTextSize
Get text size with current font.

Syntax
{width:int, height:int} draw.GetTextSize(string:text)
Parameters
string:text The text to get the size of.

Return value
integer:width Width of the text.

integer:height Height of the text.

Example
callbacks.Register("Draw", function()
    local Tw, Th = draw.GetTextSize("The size of this text");

    print("Text Width - " .. Tw .. " Text Height - " .. Th);  

    --Text Width - 123 Text Height - 9
end)draw.Line
Draw line from x1, y1 to x2, y2.

Syntax
draw.Line(int:x1, int:y1, int:x2, int:y2)
Parameters
integer:x1 First point number of x.

integer:y1 First point number of y.

integer:x2 Second point number of x.

integer:y2 Second point number of y.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.Line(60, 60, 200, 90);
end)draw.OutlinedCircle
Draw outlined circle.

Syntax
draw.OutlinedCircle(int:x, int:y, int:radius)
Parameters
integer:x Axis x.

integer:y Axis y.

integer:radius Round size.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.OutlinedCircle(150, 150, 100);
end)draw.OutlinedRect
Draw outlined rectangle with top left point at x1, y1 and bottom right point at x2, y2.

Syntax
draw.OutlinedRect(int:x1, int:y1, int:x2, int:y2)
Parameters
integer:x1 First point number of x.

integer:y1 First point number of y.

integer:x2 Second point number of x, Changes Width.

integer:y2 Second point number of y, Changes Height.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.OutlinedRect(50, 50, 300, 200);
end)draw.RoundedRect
Draw rounded rectangle with top left point at x1, y1 and bottom right point at x2, y2 radius = radius of roundness tl = round top left corner tr = round top right corner bl = round bottom left corner br = round bottom right corner.

Syntax
draw.RoundedRect(int:x1, int:y1, int:x2, int:y2, int:radius, int:tl, int:tr, int:bl, int:br)
Parameters
integer:x1 First point number of x.

integer:y1 First point number of y.

integer:x2 Second point number of x.

integer:y2 Second point number of y.

integer:radius Amount of roundness.

integer:tl Round top left corner.

integer:tr Round top right corner.

integer:bl Round bottom left corner.

integer:br Round bottom right corner.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.RoundedRect(20, 20, 300, 200, 50, 5, 0, 0, 5);
end)draw.RoundedRectFill
Draw rounded filled rectangle with top left point at x1, y1 and bottom right point at x2, y2 radius = radius of roundness tl = round top left corner tr = round top right corner bl = round bottom left corner br = round bottom right corner.

Syntax
draw.RoundedRectFill(int:x1, int:y1, int:x2, int:y2, int:radius, int:tl, int:tr, int:bl, int:br)
Parameters
integer:x1 First point number of x.

integer:y1 First point number of y.

integer:x2 Second point number of x.

integer:y2 Second point number of y.

integer:radius Amount of roundness.

integer:tl Round top left corner.

integer:tr Round top right corner.

integer:bl Round bottom left corner.

integer:br Round bottom right corner.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.RoundedRectFill(20, 20, 300, 200, 50, 5, 0, 0, 5);
end)draw.SetFont
Set current font for drawing. To be used with DrawText

Syntax
draw.SetFont(font)
Parameters
font The font to set.

Example
local Font = draw.CreateFont("Bahnschrift", 20, 100)

callbacks.Register("Draw", function()
    draw.SetFont(Font);

    draw.Color(255, 138, 130, 255);

    draw.Text(60, 60, "Text");
end)
Fontlist
For more information about the different types of fonts. Font List.draw.SetScissorRect
Remove excess things surrounding an area.

Syntax
draw.SetScissorRect(int:x, int:y, int:width, int:height)
Parameters
integer:x Axis x.

integer:y Axis y.

integer:width Width of scissoring.

integer:height Height of scissoring.

Example
callbacks.Register("Draw", function()
    draw.SetScissorRect(300,500,300,300);

    draw.Color(0,0,0,255);
    draw.FilledRect(300, 500, 600, 800);

    draw.Color(255,255,255,255);
    draw.FilledRect(300, 400, 400, 800);

    --Reset scissor area to allow seeing menu.
    draw.SetScissorRect(0, 0, draw.GetScreenSize());
end)
Without Scissor Method


With Scissor Method
draw.SetTexture
Set current drawing texture. To be used with shape drawing like draw.FilledRect Set to nil for default state.

Syntax
{texture} draw.SetTexture(texture)
Parameters
texture The texture to set.

Example
local svgData = http.Get("https://upload.wikimedia.org/wikipedia/commons/f/fd/Ghostscript_Tiger.svg");

local imgRGBA, imgWidth, imgHeight = common.RasterizeSVG(svgData);

local texture = draw.CreateTexture(imgRGBA, imgWidth, imgHeight);

callbacks.Register("Draw", function()
    draw.SetTexture(texture);
    draw.FilledRect(0, 0, imgWidth, imgHeight);
end)draw.ShadowRect
Draw shadow rectangle with top left point at x1, y1 and bottom right point at x2, y2.

Syntax
draw.ShadowRect(int:x1, int:y1, int:x2, int:y2, int:radius)
Parameters
integer:x1 First point number of x.

integer:y1 First point number of y.

integer:x2 Second point number of x, Changes Width.

integer:y2 Second point number of y, Changes Height.

integer:radius Amount of shadow around the rectangle.

Example
callbacks.Register("Draw", function()
    draw.Color(36, 36, 36, 255);
    draw.ShadowRect(50, 50, 300, 200, 100);
end)
draw.Text
Draw text at x, y.

Syntax
draw.Text(string:text)
Parameters
string:text The text to draw.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.Text(60, 60, "Text");
end)draw.TextShadow
Draw text with shadow at x, y.

Syntax
draw.TextShadow(string:text)
Parameters
string:text The text to draw.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.TextShadow(60, 60, "Text");
end)
draw.Triangle
Draw filled triangle.

Syntax
draw.Triangle(int:x1, int:y1, int:x2, int:y2, int:x3, int:y3)
Parameters
integer:x1 First point number of x.

integer:y1 First point number of y.

integer:x2 Second point number of x.

integer:y2 Second point number of y.

integer:x3 Third point number of x.

integer:y3 Third point number of y.

Example
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.Triangle(50, 50, 300, 200, 200, 0);
end)
draw.UpdateTexture
Update existing texture with rgba data.

Syntax
{texture, rgba} draw.UpdateTexture(texture, rgba)
Parameters
texture The texture to update.

rgba The color for the texture.file.Open
Used for opening files for write, read, append access.

Syntax
{file} file.Open(string:filelocation, string:mode)
Parameters
string:location filename Directory string to file. "/folder/this.txt"

string:char mode Mode to use for file.

Modes
char:mode w Open write mode to a file. Write contents.

char:mode r Open read mode to a file. Read contents.

char:mode a Open append mode to a file. Add contents.

Note

Writing and appending a file not yet created will be automatically created.

Return value
Returns file object in the set mode.

Example of writing
local fileWriteState = file.Open("write.txt", "w");

fileWriteState:Write("I wrote this.");
fileWriteState:Close();
Example of reading
local fileReadState = file.Open("write.txt", "r");

local readtext = fileReadState:Read();
fileReadState:Close();

print(readtext);
--I wrote this.
Example of appending
local fileAppendState = file.Open("write.txt", "a");
fileAppendState:Write("another writing");
fileAppendState:Close();

--
I wrote this.
another writingfile.Delete
Used for deleting files.

Syntax
file.Delete(string:filelocation)
Parameters
string:location filename Directory string to file. "/folder/this.txt"

Example of deleting
local delete = file.Delete("write.txt");file.Enumerate
Used for searching through the directory of files.

Syntax
{files} file.Enumerate(callback(filename))
Return value
Returns a callback of files.

Example of enumerating
file.Enumerate(function(fil)
    print(fil);
    --Prints list of files.
end)file.Read
Read contents from a file.

Syntax
{data} file.Read(string:filelocation)
Parameters
string:location filename Directory string to file. "/folder/this.txt"

Return value
Returns data of the file.

Example of reading
local data = file.Read("write.txt", "r");

print(data);
--I wrote this.file.Write
Write contents to a file.

Syntax
file.Write(string:filelocation, string:data)
Parameters
string:location filename Directory string to file. "/folder/this.txt"

string:data Contents Contents to write to the file.

Note

Writing to a file not yet created will be automatically created.

Example of writing
file.Write("write.txt", "I wrote this.");gui.Button
Syntax
gui.Button(parent:string, name:string, function)
Parameters
parent A gui object.

name Text on the button.

function Lua function.

Return value
This does not return a value.

Example
local ebtn_misc = gui.Reference("MISC");
local ebtn_gui = gui.Tab(ebtn_misc, "ebtn_gui", "Example Button");


-- Creating the object with a function embeded
local ebtn_button = gui.Button(ebtn_gui, "Clicky Clicky! #1", function()
        print("you clicked me! Yay! #1");
    end);


-- Creating the object using a non-embeded function
local ebtn_button = gui.Button(ebtn_gui, "Clicky Clicky! #2", button_click);


function button_click()
    print("you clicked me! Yay! #2");
endgui.Checkbox
Syntax
gui.Checkbox(parent:string, varname:string, name:string, value:boolean)
Parameters
parent A gui object.

varname Varname of this object.

name Label of object.

value true/false boolean.

Return value
Returns a single value of true/false.

Example
General usage.

local ecb_misc = gui.Reference("MISC");
local ecb_gui = gui.Tab(ecb_misc, "ecb_gui", "Example Checkbox");


-- Creating the object
local ecb_checkbox = gui.Checkbox(ecb_gui, "ecb_checkbox", "Check me!", false);


-- Return Example
callbacks.Register("Draw", function()
local ecb_value = ecb_checkbox:GetValue();
print(ecb_value);
end);
Simple checkbox listener.

-- Basic setup stuff
local ecb_misc = gui.Reference("MISC");
local ecb_gui = gui.Tab(ecb_misc, "ecb_gui", "Example Checkbox");


-- Creating the object
local ecb_checkbox = gui.Checkbox(ecb_gui, "ecb_checkbox", "Check me!", false);


-- We are gonna keep track of the last value
local ecb_value = ecb_checkbox:GetValue();


-- Return Example
callbacks.Register("Draw",function()
    -- Now to check if the text has changed
    if ecb_value ~= ecb_checkbox:GetValue() then
        ecb_value = ecb_checkbox:GetValue()
        ecb_checkbox_Changed();
    end
end);


function ecb_checkbox_Changed()
    print(ecb_value);
end
Set the value of the checkbox.

ecb_checkbox:SetValue(true);gui.ColorPicker
Syntax
gui.ColorPicker(parent:object, varname:string, name:string, red:0-255, green:0-255, blue:0-255, alpha:0-255)
Parameters
parent A gui object.

varname Varname of this object.

name Label of object.

red Value of red.

green Value of green.

blue Value of blue.

alpha Value of alpha.

Return value
Return 4 values between 0 and 255. They are refered to as RGBA in that order.

Example
General Usage

local ecp_misc = gui.Reference("MISC");
local ecp_gui = gui.Tab(ecp_misc, "ecp_gui", "Example Color Picker");


-- Creating the object
local ecp_colorpicker = gui.ColorPicker(ecp_gui, "ecp_colorpicker", "Pick your color!", 255, 0, 0, 255);


-- Return Example
local r, g, b, a = ecp_colorpicker:GetValue();


-- Passing into Function Examples
callbacks.Register("Draw", function()
    Colors_A(ecp_colorpicker);
    Colors_B(ecp_colorpicker:GetValue());
end);


function Colors_A(color)
    local r, g, b, a = color:GetValue();
    print("Colors_A - " .. "Red: " .. r .. " Green: " .. g .. " Blue: " .. b .. " Alpha: " .. a);
end


function Colors_B(r, g, b, a)
    print("Colors_B - " .. "Red: " .. r .. " Green: " .. g .. " Blue: " .. b .. " Alpha: " .. a);
end
Setting the value of a color picker

-- SetValue({r,g,b,a})
ecp_colorpicker:SetValue({255, 255, 255, 255});gui.Combobox
Syntax
gui.Combobox(parent:object, varname:string, name:string, options:string)
Parameters
parent A gui object.

varname Varname of this object.

name Label of object.

string Value of the item(s).

Return value
Return the selected index value of the item starting with 0.

Example
local ecb_misc = gui.Reference("MISC");
local ecb_gui = gui.Tab(ecb_misc, "ecb_gui", "Example Combobox");


-- Creating the object with a single item

local ecb_combobox_a = gui.Combobox(ecb_gui, "ecb_combobox_a", "Hmmm! Pretty Items", "Item 1");


-- Creating the object with multiple item(s)

local ecb_items = {"Item1", "Item2", "Item3", "Item4"};
local ecb_combobox_b = gui.Combobox(ecb_gui, "ecb_combobox_b", "Hmmm! Pretty Items", unpack(ecb_items));

-- Return selected value
callbacks.Register("Draw", function()
    local ecb_value_a = ecb_combobox_a:GetValue();
    local ecb_value_b = ecb_combobox_b:GetValue();
    print("ecb_value_a: " .. ecb_value_a);
    print("ecb_value_b: " .. ecb_value_b);
end);
Simple combobox listener

local ecb_misc = gui.Reference("MISC");
local ecb_gui = gui.Tab(ecb_misc, "ecb_gui", "Example Combobox");


-- Creating the object with a single item
local ecb_combobox_a = gui.Combobox(ecb_gui, "ecb_combobox_a", "Hmmm! Pretty Items", "Item 1");


-- We are gonna keep track of the last value
local ecb_value_a = ecb_combobox_a:GetValue();


-- Creating the object with multiple item(s)
local ecb_items = {"Item1", "Item2", "Item3", "Item4"};
local ecb_combobox_b = gui.Combobox(ecb_gui, "ecb_combobox_b", "Hmmm! Pretty Items", unpack(ecb_items));


-- We are gonna keep track of the last value
local ecb_value_b = ecb_combobox_b:GetValue();


-- Return selected value
callbacks.Register("Draw", function()
    -- We are gonna check for a value and see if it has changed
    if ecb_value_a ~= ecb_combobox_a:GetValue() then
        ecb_value_a = ecb_combobox_a:GetValue();
        ecb_combobox_a_Changed();
    end


    -- We are gonna do it again for the b value!
    if ecb_value_b ~= ecb_combobox_b:GetValue() then
        ecb_value_b = ecb_combobox_b:GetValue();
        ecb_combobox_b_Changed();
    end
end);


function ecb_combobox_a_Changed()
    print(ecb_value_a);
end


function ecb_combobox_b_Changed()
    print(ecb_value_b);
end
How to add more items to a combobox or set new ones

-- Setting new items
-- Example 1
ecb_combobox_a:SetOptions("value1", "value2");


-- Example 2
local items = {"value1", "value2"};
ecb_combobox_a:SetOptions(unpack(items));


-- Adding items from a prior combobox is harder and requires having an array of the igui.Command
Execute a command.

Syntax
gui.Command(command:string)
Parameters
command String that is use to call a command.

Return value
This function has no return value.

Example
This command will clear the chat

gui.Command("clear");
This will load a script

gui.Command("lua.load <scriptname>.lua");gui.Editbox
Syntax
gui.Editbox(parent:string, varname:string, value:string)
Parameters
parent A gui object.

varname Varname of this object.

title A string value.

Return value
Returns a single string.

Example
General usage

local eeb_misc = gui.Reference("MISC");
local eeb_gui = gui.Tab(eeb_misc, "eeb_gui", "Example Editbox");


-- Creating the object
local eeb_editbox = gui.Editbox(eeb_gui, "eeb_editbox", "This is the text above the box");


-- Return Example
callbacks.Register("Draw",function()
    local eeb_value = eeb_editbox:GetValue();
    print(eeb_value);
end);
Simple text change listener.

-- Basic setup stuff
local eeb_misc = gui.Reference("MISC");
local eeb_gui = gui.Tab(eeb_misc, "eeb_gui", "Example Editbox");


-- Creating the object
local eeb_editbox = gui.Editbox(eeb_gui, "eeb_editbox", "This is the text above the box");


-- We are gonna keep track of the last text set here
local cur_text = eeb_editbox:GetValue();


-- Return Example
callbacks.Register("Draw",function()
    -- Now to check if the text has changed
    if cur_text ~= eeb_editbox:GetValue() then
        cur_text = eeb_editbox:GetValue()
        eeb_editbox_TextChanged();
    end
end);


function eeb_editbox_TextChanged()
    -- We will now print the current text to the console
    print(cur_text);
end
How to set the text inside the box.

eeb_editbox:SetValue("This will be in the box");gui.Groupbox
Syntax
gui.Groupbox(parent:string, name:string, x:int, y:int, width:int, height:int)
Parameters
parent A gui object.

name Label of object.

x Integer of the horizontal axias. (Optional)

y Integer of the vertical axis. (Optional)

width Integer of the width. (Optional)

height Integer of the height. (Optional)

Return value
This does not return a value.

Example
local egb_misc = gui.Reference("MISC");
local egb_gui = gui.Tab(egb_misc, "egb_gui", "Example Groupbox");


-- Creating the object
local egb_groupbox_a = gui.Groupbox(egb_gui, "Wanna be a groupie? A", 16, 16, 287.5, 50);
local egb_groupbox_b = gui.Groupbox(egb_gui, "Wanna be a groupie? B", 319.5, 16, 287.5, 100);


-- Lets add a few objects to make it look pretty
-- So we call groupbox here instead of gui so it will put it inside the gui instead
local egb_checkbox_a = gui.Checkbox(egb_groupbox_a, "egp_checkbox_a", "My checkbox groupie A", true);
local egb_checkbox_b = gui.Checkbox(egb_groupbox_b, "egp_checkbox_b", "My checkbox groupie B", true);
© 2023 AIMWARE. All rights reserved.gui.Keybox
Syntax
gui.Keybox(parent:string, varname:string, name:string, key:int)
Parameters
parent A gui object.

varname Label of object.

name Integer of the horizontal axias. (Optional)

key Integer of the vertical axis. (Optional)

Return value
This returns a single integer value.

Example
General Usage

local egb_misc = gui.Reference("MISC");
local ekb_gui = gui.Tab(egb_misc, "ekb_gui", "Example Keybox");

-- Creating the object
local ekb_keybox = gui.Keybox(ekb_gui, "ekb_keybox", "What key would you like", 0);


-- Return value
callbacks.Register("Draw", function()
    print(ekb_keybox:GetValue());
end)
Simple Keybox listener.

local egb_misc = gui.Reference("MISC");
local ekb_gui = gui.Tab(egb_misc, "ekb_gui", "Example Keybox");


-- Creating the object
local ekb_keybox = gui.Keybox(ekb_gui, "ekb_keybox", "What key would you like", 0);
local ekb_value = ekb_keybox:GetValue();


-- Return value
callbacks.Register("Draw", function()
    -- Now to check if the text has changed
    if ekb_value ~= ekb_keybox:GetValue() then
        ekb_value = ekb_keybox:GetValue();
        ekb_keybox_Changed();
    end
end)


function ekb_keybox_Changed()
    print(ekb_value);
end
Setting a key

ekb_keybox:SetValue(188) -- This will set the key to a comma
Keylist
For more information about key codes for setting buttons Keylistgui.Listbox
Syntax
gui.Listbox(parent:object, varname:string, height:int, options:string)
Parameters
parent A gui object.

varname Varname of this object.

height Interger value for the height of the box.

string Value of the item(s).

Return value
Return the selected index value of the item starting with 0.

Example
local elb_misc = gui.Reference("MISC");
local elb_gui = gui.Tab(elb_misc, "ecb_gui", "Example Listbox");


-- Creating the object with a single item

local elb_listbox_a = gui.Listbox(elb_gui, "elb_listbox_a", 200, "Item 1");


-- Creating the object with multiple item(s)

local elb_items = {"Item1", "Item2", "Item3", "Item4"};
local elb_listbox_b = gui.Listbox(elb_gui, "elb_listbox_b", 200, unpack(elb_items));

-- Return selected value
callbacks.Register("Draw", function()
    local elb_value_a = elb_listbox_a:GetValue();
    local elb_value_b = elb_listbox_b:GetValue();
    print("elb_value_a: " .. elb_value_a);
    print("elb_value_b: " .. elb_value_b);
end);
Simple listbox listener

local elb_misc = gui.Reference("MISC");
local elb_gui = gui.Tab(elb_misc, "ecb_gui", "Example Listbox");


-- Creating the object with a single item

local elb_listbox_a = gui.Listbox(elb_gui, "elb_listbox_a", 200, "Item 1");


-- We are gonna keep track of the last value
local elb_value_a = elb_listbox_a:GetValue();


-- Creating the object with multiple item(s)

local elb_items = {"Item1", "Item2", "Item3", "Item4"};
local elb_listbox_b = gui.Listbox(elb_gui, "elb_listbox_b", 200, unpack(elb_items));


-- We are gonna keep track of the last value
local elb_value_b = elb_listbox_b:GetValue();


-- Return selected value
callbacks.Register("Draw", function()
    -- We are gonna check for a value and see if it has changed
    if elb_value_a ~= elb_listbox_a:GetValue() then
        elb_value_a = elb_listbox_a:GetValue();
        elb_listbox_a_Changed();
    end


    -- We are gonna do it again for the b value!
    if elb_value_b ~= elb_listbox_b:GetValue() then
        elb_value_b = elb_listbox_b:GetValue();
        elb_listbox_b_Changed();
    end
end);


function elb_listbox_a_Changed()
    print(elb_value_a);
end


function elb_listbox_b_Changed()
    print(elb_value_b);
end
How to add more items to a listbox or set new ones

-- Setting new items
-- Example 1
elb_listbox_a:SetOptions("value1", "value2");


-- Example 2
local items = {"value1", "value2"};
elb_listbox_a:SetOptions(unpack(items));


-- Adding items from a prior listbox is harder and requires having an array of the items you had in it. In this cause you would just add to an array and use unpack(items) like shown above.
© 2023 AIMWARE. All rights reserved.gui.Multibox
Syntax
gui.Multibox(parent:object, name:string)
Parameters
parent A gui object.

name Varname of this object.

Return value
This function returns the created GUI object.

Example
local emb_misc = gui.Reference("MISC");
local emb_gui = gui.Tab(emb_misc, "emb_gui", "Example Multibox");


-- Creating the object
local emb_multibox = gui.Multibox(emb_gui, "The Name");

-- We will now add 2 checkboxes to the multibox
local emb_checkbox_a = gui.Checkbox(emb_multibox, "emb_checkbox_a", "this checkbox a", true)
local emb_checkbox_b = gui.Checkbox(emb_multibox, "emb_checkbox_b", "this checkbox b", false)
Screenshot

gui.Reference
Finds and creates new reference to UI object. Should be used only once.

Syntax
{guiobject} gui.Reference(string:uiobject)
Parameters
uiobject Object from the UI.

Return value
Returns an guiobject.

Example
local fvis = gui.Reference("VISUALS")
print(fvis:GetName())
--Visualsgui.Slider
Syntax
Slider( parent, varname, name, value, min, max, inc )
gui.Slider(parent:string, varname:string, name:string, value:float, min:float, max:float, inc:float)
Parameters
parent A gui object.

varname Varname of this object.

name Text above the slider.

value Float value of the current value.

min Float value of the lowest value possible.

max Float value of the largest value possible.

inc Float value of the increment of movement. (Optional)

Return value
This returns a single float value.

Example
General Usage

local esdr_misc = gui.Reference("MISC");
local esdr_gui = gui.Tab(esdr_misc, "esdr_gui", "Example Slider");


-- Creating the object with a function embeded
local esdr_slider = gui.Slider(esdr_gui, "esdr_slider", "My happy little slider", 5.0, 0.0, 10.0, 0.01);


-- Return slider value
callbacks.Register("Draw", function()
    local esdr_value = esdr_slider:GetValue();
    print("esdr_value: " .. esdr_value);
end);
Simple slider listener

local esdr_misc = gui.Reference("MISC");
local esdr_gui = gui.Tab(esdr_misc, "esdr_gui", "Example Slider");


-- Creating the object with a function embeded
local esdr_slider = gui.Slider(esdr_gui, "esdr_slider", "My happy little slider", 5.0, 0.0, 10.0, 0.01);


-- We are gonna keep track of the last value
local esdr_value = esdr_slider:GetValue();


-- Return slider value
callbacks.Register("Draw", function()
    -- We are gonna check for a value and see if it has changed
    if esdr_value ~= esdr_slider:GetValue() then
        esdr_value = esdr_slider:GetValue();
        esdr_slider_Changed();
    end
end);


function esdr_slider_Changed()
    print("esdr_value: " .. esdr_value);
end
Set value of the slider

esdr_slider:SetValue(0.172);gui.Tab
Syntax
gui.Tab(parent:string, varname:string, name:string)
Parameters
parent A gui object.

varname Varname of the object.

name String for the text of the tab:

Return value
This does not return a value.

Example
Creating a tab

-- We are setting the location of where the tab will be created
local etab_misc = gui.Reference("MISC");

-- This is creating the tab its self
local etab_gui = gui.Tab(etab_misc, "etab_gui", "Example Tab");
Disabling the tab with button press

-- We are setting the location of where the tab will be created
local etab_misc = gui.Reference("MISC");


-- This is creating the tab its self
local etab_gui = gui.Tab(etab_misc, "etab_gui", "Example Tab");


local etab_button = gui.Button(etab_gui, "Change Name", function()
        etab_gui:SetDisabled(true);
    end);gui.Text
Syntax
gui.Text(parent:string, text:string)
Parameters
parent A gui object.

text String for the text value shown.

Return value
This does not return a value.

Example
Creating a text object

local etxt_misc = gui.Reference("MISC");
local etxt_gui = gui.Tab(etxt_misc, "etxt_gui", "Example Text");

-- Creating the object
local etxt_text = gui.Text(etxt_gui, "Happy little text goes here. Now make sure to beagui.Window
Syntax
gui.Window(varname:string, name:string, x:int, y, width:int, height:int)
Parameters
parent A gui object.

text String for the text value shown.

Return value
This does not return a value.

Example
Creating a new window

local ewnd_window = gui.Window("wnd_window", "Example Window", 100, 100, 200, 400);
Adding a object to the window

local ewnd_window = gui.Window("ewnd_window", "Example Window", 100, 100, 200, 400);
local ewnd_checkbox = gui.Checkbox(ewnd_window, "ewnd_checkbox", "This is a checkbox", trugui.XML
Allows to create more complex UI via XML

Syntax
{guiobject} gui.XML(string:xml)
Parameters
xml The text used for the ui creation.

Return value
Returns an guiobject.

Example layout via XML (test.xml)
<Window var="mymenu" name="My Menu" width="300" height="300">
    <Tab name="Tab 1">
        <Groupbox name="Options">
            <Checkbox var="enable" name="Enable" value="on">
                <ColorPicker var="clr" value="240 30 20 255"/>
            </Checkbox>
            <Slider var="factor" name="Factor" desc="Determine the factor." min="0" max="100"/>
            <Combobox var="mode" name="Mode" options=["Offensive","Defensive"]/>
        </Groupbox>
    </Tab>
    <Tab name="Tab 2">
        <Text>This tab is empty.</Text>
    </Tab>
</Window>
Example loading XML
local test = gui.XML(file.Read("test.xml"));
local enable = test:Reference("enable");
local color = enable:Reference("clr");
local factor = test:Reference("factor");
local mode = test:Reference("mode");

callbacks.Register("Draw", function()
    if enable:GetValue() then
        draw.Color(color:GetValue());
        draw.Text(16, 16, "Enabled with factor " .. factor:GetValue() .. " and mode " .. mode:GetString());
    end
end)
http.Get
Get data from a URL.

Syntax
http.Get(url:string, callback:optional)
Parameters
url URL to fetch.

callback optional Callback function.

Return value
data Returns web page body at given URL.

Note

To make this call non-blocking specify callback(body) function as second argument.network.Socket
Creates new network socket

Syntax
network.Socket(type:string)
Parameters
type Type of Socket.

Return value
If successful, returns a Socket, otherwise returns an error of what failed.

Note

Type "UDP" is only supported currently.network.GetAddrInfo
Resolves hostname to IP.

Syntax
network.GetAddrInfo(name:string)
Parameters
name Hostname to be converted to IP.

Return value
If successful, returns the IP as string, otherwise returns nil.network.GetNameInfo
Resolves IP to hostname.

Syntax
network.GetNameInfo(addr:string)
Parameters
addr IP to be converted to hostname.

Return value
If successful, returns the hostname as string, otherwise returns nil.vector
Warning

This API is obsolete, use Vector3 and EulerAngles classes

Functions
Add(xyz:EulerAngles, xyz:EulerAngles)

Subtract(xyz:EulerAngles, xyz:EulerAngles)

Multiply(xyz:EulerAngles, int:multiply)

Divide(xyz:EulerAngles, int:divide)

Length(xyz:EulerAngles)

LengthSqr(xyz:EulerAngles)

Distance(xyz:EulerAngles, xyz:EulerAngles)

Normalize(xyz:EulerAngles)

Angles(angles:EulerAngles)

AngleForward(angles:EulerAngles)

AngleRight(angles:EulerAngles)

AngleUp(angles:EulerAngles)

AngleNormalize(angles:EulerAngles)
callbacks.Register("Draw", function()
    draw.Color(255, 138, 130, 255);
    draw.Text(0, 0, "TextWithColor");
end)