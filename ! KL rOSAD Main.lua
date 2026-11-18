local a="1.2"
local b="KLOSAD"
local c=(getgenv and getgenv())or _G
local d={t0=os.clock(),last=os.clock(),n={}}
local function rest(e)
d.n[#d.n+1]=e.." "..math.floor((os.clock()-d.last)*1000).."ms"
task.wait()
d.last=os.clock()
end
if c.KLOSAD_BOOT and os.time()-c.KLOSAD_BOOT<30 then warn"[KLOSAD] a run is still starting (or one crashed while starting): try again in 30 s";return end
c.KLOSAD_BOOT=os.time()
if not game:IsLoaded()then game.Loaded:Wait();task.wait(1)end
repeat task.wait()until game:GetService"Players".LocalPlayer and workspace.CurrentCamera
if c.KLOSAD and c.KLOSAD.Unload then pcall(c.KLOSAD.Unload)end
local e=c.KLOSAD_ALL or{}
c.KLOSAD_ALL={}
for g,h in ipairs(e)do pcall(h)end
pcall(function()game:GetService"ContextActionService":UnbindAction"KLOSAD_Shift"end)
pcall(function()game:GetService"ContextActionService":UnbindAction"KLOSAD_Block"end)
for g,h in ipairs{"KLSync","KLSpiderCam","KLOSAD_Mouse","KLVoid"}do pcall(function()game:GetService"RunService":UnbindFromRenderStep(h)end)end
for g,h in ipairs{function()return game:GetService"CoreGui"end,function()return game:GetService"Players".LocalPlayer.PlayerGui end,function()return game:GetService"Lighting"end}do
pcall(function()for i,j in ipairs(h():GetChildren())do if j.Name=="KLOSAD"or j.Name=="KLOSAD_Blur"then j:Destroy()end end end)
end
local g={
}
local h={
{name="HLXP",desc="KL HL XP: half-life movement and physics",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/HLXP"},
{name="Dex++",desc="Explorer (Dex Plus Plus, stable 3.0)",url="https://github.com/AZYsGithub/DexPlusPlus/releases/download/stable-3.0/out.lua"},
{name="Kelsec",desc="In-game executor",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Kelsec.lua"},
{name="WorkWell",desc="Aim assist",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Workwell%20Aimassist.lua"},
{name="Cobalt",desc="Remote spy",url="https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"},
{name="RSpy",desc="Remote spy (SimpleSpy V3)",url="https://raw.githubusercontent.com/infyiff/backup/main/SimpleSpyV3/main.lua"},
{name="ALogger",desc="Audio logger: logs sounds as they play",url="https://raw.githubusercontent.com/infyiff/backup/main/audiologger.lua"},
{name="Freeze Instance Saver",desc="Saves the instance with humanoids and players",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Freeze%20Instance%20Saver.lua"},
{name="LiU",desc="Lighting Utility",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/LiU%20v9.lua"},
{name="Name Spoofer",desc="Name spoofer / streamer mode",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Name%20Spoofer.lua"},
{name="No Sit",desc="Seats can't seat you (used by antisit)",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/No%20Sit.lua"},
{name="Tetris",desc="Tetris in a window",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Tetris%20Localscript.lua"},
{name="WWA Phantom Forces (Workwell)",desc="WorkWell aim assist for Phantom Forces",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/WWA%20Phantom%20Forces.lua"},
{name="Tool Properties Editor",desc="Edits properties for tools (inventory)",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/Properties%20Editor.lua"},
{name="VC Bypasser",desc="Voice chat bypass: prevents you from getting kicked from voice chat",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/refs/heads/main/VC%20Bypass.lua"},
{name="KL PF XP",desc="Half-Life / GoldSrc style movement in Phantom Forces",url="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/main/KL%20PF%20XP.lua"},
}

local i={
[==[Welcome back. rOSAD kept your settings. You're welcome.]==],
[==[rOSAD loaded in under a second. Just thought you should know.]==],
[==[Command bar's open. Don't just stare at it.]==],
[==[Everything loaded. Break something, we'll wait.]==],
[==[The panel's ready. Your move, hotshot.]==],
[==[Back already? Respect. Type something.]==],
[==[Command bar's open. It doesn't bite. Byfron does, but that's different.]==],
[==[Loaded. Try not to type ;cmds ten times in a row.]==],
[==[All modules loaded. Nothing has crashed yet. Give it a minute.]==],
[==[Your settings made it back in one piece. Can't say the same for your last session.]==],
[==[rOSAD is up. The command bar is open and your excuses are closed.]==],
[==[Modules ready. Go on, pick a command. Any command.]==],
[==[Everything's loaded and customizable (or at least some of it). Get to work.]==],
[==[Welcome back, you menace. Command bar's yours.]==],
[==[Loaded without a single error. Don't jinx it.]==],
[==[The cursor's blinking. That's rOSAD's way of saying hurry up.]==],
[==[Settings restored, loops cleared, ego intact. Let's go.]==],
[==[You're in. The command bar is open, so use it.]==],
[==[Ready when you are. Actually, ready before you are. Hurry up.]==],
[==[Fresh session, clean slate. Go ahead and ruin it.]==],
[==[Command bar's open. Typos are free, so take your shot.]==],
[==[Back for another round? Good. The panel's warmed up.]==],
[==[Everything's loaded. Whatever happens next is on you, chief.]==],
[==[No errors on startup. That's already better than yesterday.]==],
[==[rOSAD is awake. The command bar is open. Choose violence (the scripting kind).]==],
[==[Welcome back. Your last command is still in the history. We saw it.]==],
}

local j={
[==[Welcome to your favourite and trusted open-source admin panel, rOSAD.]==],
[==[Welcome to rOSAD, for the humble scripters and exploiters.]==],
[==[Welcome to rOSAD. You're not about to cheat on a game with this, are you? ...Right?]==],
[==[Be gentle with Byfron. It bites, and that one's not on us.]==],
[==[Welcome to rOSAD. Everything here is legal. Probably.]==],
[==[Welcome back. Your admin privileges have been verified by absolutely no one.]==],
[==[Loaded successfully. Whether it works is between you and the game.]==],
[==[Welcome to rOSAD. 40% fewer errors than yesterday's build. We counted. Mostly.]==],
[==[Welcome to rOSAD. Any resemblance to a functioning script is purely intentional.]==],
[==[Thanks for choosing rOSAD. Your patience has been noted and will be needed.]==],
[==[rOSAD is open source, so if it breaks, you're technically on the dev team.]==],
[==[Welcome to rOSAD, where "it works on my machine" is a core design principle.]==],
[==[Byfron says hi. We told it you were just browsing.]==],
[==[Welcome. Not responsible for lag, bans, or sudden existential dread.]==],
[==[Built, broken, and rebuilt more times than we'll admit.]==],
[==[Structured with care, debugged with questionable patience.]==],
[==[If something looks too clean, we're as surprised as you are.]==],
[==[Every bug was found the hard way, usually twice.]==],
[==[rOSAD loaded. It took a lot of "why is this nil" to get here.]==],
[==[Somewhere in here is a pcall holding everything together. Nobody knows which one.]==],
[==[Oh, you're back. Great. Let's go.]==],
[==[The commands are all documented. Not that anyone checked.]==],
[==[Customizable (or at least some), so every complaint is technically your fault.]==],
[==[Customize everything. Break everything. Reset it and pretend it never happened.]==],
[==[Welcome back, you menace. The command bar missed you.]==],
[==[Misspelled a command? rOSAD saw it. rOSAD said nothing.]==],
}

local k={
"Did you know that you can change your default prefix bind to a custom key? Go to the Keybinds tab.",
"Type part of a command in the bar and press Tab to complete it.",
"bind f fly 80 binds F to a command. Manage binds in the Keybinds tab.",
"Drop your own command files in KLOSAD/commands, then type reload.",
"Preferences > Reset all effects turns off fly, noclip, esp and more in one click.",
"Drag the panel by its title bar.",
}

local l=setmetatable({cons={},sel=1,cur={},launched={},alive=true},{__index=function(l,m)
local n,o=pcall(game.GetService,game,m)
if n then l[m]=o;return o end
end})

local m="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/refs/heads/main/!%20KL%20rOSAD%20Main.lua"

m=(m:match"^%s*(.-)%s*$":gsub("^https://github%.com/([^/]+)/([^/]+)/blob/","https://raw.githubusercontent.com/%1/%2/"))

local n={}

local o=(syn and syn.request)or http_request or request
local p=(readfile and writefile and listfiles and isfolder and makefolder)and true or false
local q=pcall(function()return loadstring"return 1"()end)

local r={
theme="Dark",opacity=0.8,glow=75,banner={},accent="#FFFF00",anim=1,scale=1,
lines=12,blur=1,pos="Center",barKey="Semicolon",panelKey="RightShift",
toasts=true,bio="",bios={},binds={},autoExec=false,avc=false,mod={},exp={},hist={},startBar=true,autostart={},
kbTabs={},kbActive="default",expIcon={},carry={},sugCols=false,selfPath="",aliases={},kbDefName="Default",listenPad=0,srvRegion="",srvSort="Ping",srvDesc=false,srvMax=50,notifyUsers={},nuPoll=60,plSort="A-Z",plPoll=1,
}
local s={}
for t,u in pairs(r)do s[t]=u end
s.binds={}
s.mod={}
s.exp={}
s.hist={}
s.kbTabs={}
s.expIcon={}
s.banner={}
s.carry={}
s.aliases={}
s.notifyUsers={}
s.bios={}
s.autostart={onExec=true,items={}}

local function save()
if not writefile then return end
pcall(function()
if makefolder and isfolder and not isfolder(b)then makefolder(b)end
writefile(b.."/settings.json",l.HttpService:JSONEncode(s))
end)
end

if readfile and isfile then
pcall(function()
if isfile(b.."/settings.json")then
for t,u in pairs(l.HttpService:JSONDecode(readfile(b.."/settings.json")))do
if r[t]~=nil and type(u)==type(r[t])then s[t]=u end
end
end
end)
end



local t={
flyDef=50,flyMult=1,speedDef=16,speedMult=1,jpDef=50,jpMult=1,spinDef=2,spinMult=1,
tpMode="Multiplier",tpDef=2,tpCap=10,followRadius=5,fpsCorner="TR",ragdollBlock=true,
streamMe="Streamer",streamOthers="Pasta Hater",
bpDist=1.5,bpHeight=0.5,babyDist=2.2,babyHeight=0.5,babyRot=35,babyLean=0,
afRadius=15,afThreshold=120,afRestore=1.5,atpMin=40,akMax=80,aeThreshold=500,aeDuration=2,
afkInterval=60,spamCount=3,avHeight=50,defNotify=true,
floatStep=3,espCustom=false,espColor="#FF3B3B",actOn=true,actCorner="BL",
predOn=false,predMult=1,srvShow=false,srvHide=0.5,attachVel=true,attachLead=0,attachRoot=false,attachWeld="rep",
chStyle="Cross",chLen=6,chGap=4,chThick=2,chOutline=1,chOutlineAlpha=1,chColor="#00FF00",chCursor=false,
headDist=1.5,headHeight=1.5,headSide=0,headSweep=true,headSweepAmp=0.5,headSweepSpeed=10,
backDist=1.2,backHeight=0.5,backSide=0,backSweep=true,backSweepAmp=0.5,backSweepSpeed=20,srvPingMult=2,
ph1Mult=1,spWall=3,fcDef=50,fcSens=1,
}
for u,w in pairs(t)do
if type(s.mod[u])~=type(w)then s.mod[u]=w end
end

if not s.mod.backV2 then
s.mod.backV2=true
s.mod.backDist,s.mod.backSweep,s.mod.backSweepSpeed=t.backDist,t.backSweep,t.backSweepSpeed
end

if type(s.autostart.items)~="table"then s.autostart.items={}end
if type(s.autostart.onExec)~="boolean"then s.autostart.onExec=true end




local u=Color3.fromRGB

local w={
Dark={panel=u(8,8,10),panelEdge=u(52,50,58),inner=u(15,15,18),edge=u(72,70,80),bar=u(15,15,18),
tabOn=u(110,106,120),tabOff=u(0,0,0),row=u(32,31,37),ctrlOn=u(110,106,120),ctrlOff=u(30,30,35),
btnFill=u(40,40,46),glass=u(0,0,0),sheen=u(255,255,255),text=u(255,255,255),text2=u(238,237,242),sub=u(158,156,168),
dim=u(112,110,124),hint=u(122,122,134),line=u(72,70,80),danger=u(255,99,88),info=u(77,163,255)},
Light={panel=u(242,242,242),panelEdge=u(242,242,242),inner=u(231,230,230),edge=u(158,155,155),bar=u(231,230,230),
tabOn=u(138,134,134),tabOff=u(255,255,255),row=u(191,191,191),ctrlOn=u(138,134,134),ctrlOff=u(250,250,250),
btnFill=u(214,213,213),glass=u(255,255,255),sheen=u(0,0,0),text=u(13,13,13),text2=u(31,31,31),sub=u(84,81,81),
dim=u(107,103,103),hint=u(107,103,103),line=u(138,134,134),danger=u(206,38,30),info=u(0,106,220)},
}
if not w[s.theme]then s.theme="Dark"end
if s.pos~="Top"and s.pos~="Bottom"then s.pos="Center"end

local function parseHex(x)
if type(x)~="string"or not x:match"^#%x%x%x%x%x%x$"then return nil end
return u(tonumber(x:sub(2,3),16),tonumber(x:sub(4,5),16),tonumber(x:sub(6,7),16))
end
local function hex(x)
return string.format("#%02X%02X%02X",math.floor(x.R*255+0.5),math.floor(x.G*255+0.5),math.floor(x.B*255+0.5))
end
l.accent=parseHex(s.accent)or u(255,255,0)

local function lum(x)
local function f(y)return y<=0.03928 and y/12.92 or((y+0.055)/1.055)^2.4 end
return 0.2126*f(x.R)+0.7152*f(x.G)+0.0722*f(x.B)
end
local function contrast(x,y)
local z,A=lum(x),lum(y)
if z<A then z,A=A,z end
return(z+0.05)/(A+0.05)
end

local function legible(x,y)
local z=lum(y)>0.5 and Color3.new(0,0,0)or Color3.new(1,1,1)
for A=0,10 do
local B=x:Lerp(z,A/10)
if contrast(B,y)>=4.5 then return B end
end
return z
end
l.accentText=legible(l.accent,w[s.theme].panel)

local function col(x)
if x=="accent"then return l.accent end
if x=="accentText"then return l.accentText end
if x=="onAccent"then return lum(l.accent)>0.4 and u(16,16,18)or u(255,255,255)end
return w[s.theme][x]
end


local x={}
local function paint(y,z,A)
local B=x[y]
if not B then B={};x[y]=B end
B[z]=A
y[z]=col(A)
end

l.fxSet=setmetatable({},{__mode="k"})
function l.deco(y)
l.fxSet[y]=true
y[y:IsA"UIGradient"and"Enabled"or"Visible"]=s.theme=="Dark"
return y
end
function l.applyDeco()
for y in pairs(l.fxSet)do pcall(function()y[y:IsA"UIGradient"and"Enabled"or"Visible"]=s.theme=="Dark"end)end
end
local function applyTheme()
l.applyDeco()
for y,z in pairs(x)do
if not y.Parent then
x[y]=nil
else
for A,B in pairs(z)do pcall(function()y[A]=col(B)end)end
end
end
end

local function esc(y)return(tostring(y):gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"))end
local function hl(y,z)
if z and z~=""then
local A,B=y:lower():find(z:lower(),1,true)
if A then
return esc(y:sub(1,A-1))..'<font color="'..hex(l.accentText)..'">'..esc(y:sub(A,B)).."</font>"..esc(y:sub(B+1))
end
end
return esc(y)
end

local function mix(y,z)
local A={}
for B,C in pairs(y)do A[B]=C end
for B,C in pairs(z or{})do A[B]=C end
return A
end
local function new(y,z,A)
local B=Instance.new(y)
for C,D in pairs(z)do B[C]=D end
if A then B.Parent=A end
return B
end



local y={0.06,0.1,0.16,0.3}
local function dur(z)
if s.anim==0 then return 0 end
local A,B,C=z or 0.15,y[1],math.huge
for D,E in ipairs(y)do
local F=math.abs(E-A)
if F<C then B,C=E,F end
end
return B*2/s.anim
end
local function tw(z,A,B,C)
if s.anim==0 then
for D,E in pairs(A)do z[D]=E end
return
end


l.TweenService:Create(z,TweenInfo.new(dur(B),C==Enum.EasingStyle.Linear and C or Enum.EasingStyle.Sine,Enum.EasingDirection.Out),A):Play()
end

local function keyFromString(z)
local A=tostring(z):lower()
for B,C in ipairs(Enum.KeyCode:GetEnumItems())do
if C.Name:lower()==A or l.UserInputService:GetStringForKeyCode(C):lower()==A then return C end
end
end
local function keyStr(z)
local A,B=tostring(z):match"^(.*%+)([^%+]+)$"
if A then return A..keyStr(B)end
local C,D=pcall(function()return l.UserInputService:GetStringForKeyCode(Enum.KeyCode[z])end)
return(C and D and D~="")and D or z
end


local function split(z)
local A,B,C={},"",false
for D in z:gmatch"."do
if D=='"'then
C=not C
elseif D:find"%s"and not C then
if B~=""then A[#A+1]=B;B=""end
else
B=B..D
end
end
if B~=""then A[#A+1]=B end
return A
end


local function score(z,A)
local B
for C,D in ipairs(z.names)do
if D==A then return 0 end
if D:sub(1,#A)==A then B=math.min(B or 9,1)
elseif D:find(A,1,true)then B=math.min(B or 9,3)end
end
if B then return B end
if z.desc~=""and z.desc:lower():find(A,1,true)then return 5 end
if z.tags and z.tags~=""and z.tags:lower():find(A,1,true)then return 6 end
end




local z={
Players=l.Players,RunService=l.RunService,UIS=l.UserInputService,Lighting=l.Lighting,
TeleportService=l.TeleportService,HttpService=l.HttpService,StarterGui=l.StarterGui,
SocialService=l.SocialService,TextChatService=l.TextChatService,
lp=l.Players.LocalPlayer,cam=workspace.CurrentCamera,
Commands={},Aliases={},Meta={},
state={conns={},muted={},esp={},saved={},active={},loopGen=0,loopOf={},tools={},cc={},listen={}},
httpRequest=o,
}
local A,B=z.lp,z.state







z.bus={}
do
local C,D={},{}
z.bus.last=D
function z.bus.on(E,F,G)
local H=C[E]
if not H then H={};C[E]=H end
H[#H+1]=F
if G and D[E]then task.spawn(F,table.unpack(D[E],1,D[E].n))end
return function()local I=table.find(H,F);if I then table.remove(H,I)end end
end
function z.bus.fire(E,...)
D[E]=table.pack(...)
local F=C[E]
if not F then return end
for G,H in ipairs(table.clone(F))do task.spawn(H,...)end
end
end
function z.notify(C,D)
if n.toast and s.toasts then n.toast(tostring(C),D)end
end
function z.markMove()B.selfMove=os.clock()end
function z.val(C,D)return(tonumber(D)or s.mod[C.."Def"])*(s.mod[C.."Mult"]or 1)end
function z.char()
local C=B.blink
if C and C.fake and C.fake.Parent then return C.fake end
return A.Character
end
function z.hum()local C=z.char();return C and C:FindFirstChildOfClass"Humanoid"end
function z.root()local C=z.char();return C and C:FindFirstChild"HumanoidRootPart"end


B.seen=B.seen or{}

function z.unpark(C)
local D,E=B.parked,z.root()
B.parked=nil
if not(D and E)then return end
if C then z.markMove();E.CFrame=D.cf end
E.Anchored=D.was
end




function z.reach(C)
local function rootOf()local D=C.Character;return D and D:FindFirstChild"HumanoidRootPart"end
local D=rootOf()
if D or not workspace.StreamingEnabled then return D end
local E=B.seen[C.UserId]
if not E then z.notify(C.Name.." is out of range and was never seen: no coordinates to load")return nil end
local function wait4(F)
local G=os.clock()
repeat
local H=rootOf()
if H then return H end
task.wait(0.1)
until os.clock()-G>F
end
z.notify(("Loading the area around %s (last seen %d s ago)..."):format(C.Name,math.floor(os.clock()-E.t)))
if pcall(function()A:RequestStreamAroundAsync(E.pos,4)end)then
D=wait4(3)
if D then return D end
end
local F=z.root()
if not F then return nil end
B.parked=B.parked or{cf=F.CFrame,was=F.Anchored}
local G,H=pcall(function()return workspace.StreamingTargetRadius end)
H=G and H or 1024
local I=Vector3.new(F.Position.X-E.pos.X,0,F.Position.Z-E.pos.Z)
local J=I.Magnitude>1 and I.Unit or Vector3.xAxis
for K,L in ipairs{1,0.5,0}do
local M=E.pos+J*(math.min(math.max(H-100,0),I.Magnitude)*L)+Vector3.new(0,20,0)
z.markMove();F.Anchored=true;F.CFrame=CFrame.new(M)
D=wait4(3)
if D then return D end
F=z.root()or F
end
z.unpark(true)
z.notify("Could not load "..C.Name..": they are not where they were last seen")
return nil
end

function z.connect(C,D,E)
if B.conns[C]then B.conns[C]:Disconnect()end
B.conns[C]=D:Connect(E)
end
function z.disconnect(C)
if B.conns[C]then B.conns[C]:Disconnect();B.conns[C]=nil end
end
do
local C=0
z.connect("seenDrop",game:GetService"Players".PlayerRemoving,function(D)B.seen[D.UserId]=nil end)
z.connect("seenTrack",game:GetService"RunService".Heartbeat,function()
local D=os.clock()
if D-C<1 then return end
C=D
for E,F in ipairs(game:GetService"Players":GetPlayers())do
local G=F.Character
local H=G and G:FindFirstChild"HumanoidRootPart"
if H then B.seen[F.UserId]={pos=H.Position,t=D}end
end
end)
end


local C={668486568}

function z.findPlayers(D)
D=(D or"me"):lower()
local E,F={},{}
for G,H in ipairs(l.Players:GetPlayers())do
if H==A or not table.find(C,H.UserId)then E[#E+1]=H end
end
if D=="me"then return{A}end
if D=="all"then return E end
if D=="others"then
for G,H in ipairs(E)do if H~=A then F[#F+1]=H end end
return F
end
if D=="random"then return{E[math.random(#E)]}end
for G,H in ipairs(E)do if H.Name:lower()==D then return{H}end end
for G,H in ipairs(E)do if H.DisplayName:lower()==D then return{H}end end
for G,H in ipairs(E)do
if H.Name:lower():sub(1,#D)==D or H.DisplayName:lower():sub(1,#D)==D then F[#F+1]=H end
end
return F
end
function z.findPlayer(D)
local E=z.findPlayers(D)[1]
if not E then z.notify("No player matches '"..tostring(D).."'")end
return E
end


function z.hop(D)
if not z.httpRequest then return z.notify"No request function available"end
local E,F=pcall(function()
local E=z.httpRequest{
Url=("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100"):format(game.PlaceId,D),
Method="GET",
}
return l.HttpService:JSONDecode(E.Body).data
end)
if not E or type(F)~="table"then return z.notify"Server list failed, try again in a moment"end
for G,H in ipairs(F)do
if H.id~=game.JobId and H.playing<H.maxPlayers then
return l.TeleportService:TeleportToPlaceInstance(game.PlaceId,H.id,A)
end
end
z.notify"No server found"
end


function z.hookChat()
if l.chatHooked then return end
l.chatHooked=true
B.chat={spam=false,spamN=3,hist={}}
pcall(function()
local D=l.TextChatService

local E=getcallbackvalue or getcallbackmember
local F,G=false
if E then F,G=pcall(E,D,"OnIncomingMessage")end
if type(G)~="function"then F,G=false,nil end
l.chatPrev={ok=F,fn=G}
D.OnIncomingMessage=function(H)
local I=(F and G(H))or Instance.new"TextChatMessageProperties"
local J=H.TextSource
if J then
local K=J.UserId
if B.muted[K]then I.Text=""end
if B.chat.spam and K~=A.UserId then
local L=B.chat.hist[K]or{}
B.chat.hist[K]=L
local M,N,O=os.clock(),0,tostring(H.Text):lower()
for P=#L,1,-1 do
if M-L[P].t>10 then table.remove(L,P)elseif L[P].k==O then N=N+1 end
end
L[#L+1]={t=M,k=O}
if N+1>=B.chat.spamN then I.Text=""end
end
end
return I
end
end)
end

local function voiceDevices(D,E)
local F=l.Players:GetPlayerByUserId(D)
if not F then return end
B.voiceVol=B.voiceVol or{}
for G,H in ipairs(F:GetDescendants())do
if H:IsA"AudioDeviceInput"then
pcall(function()
if E then
if B.voiceVol[H]==nil then B.voiceVol[H]=H.Volume end
H.Muted,H.Volume=true,0
else
H.Muted,H.Volume=false,B.voiceVol[H]or 1
B.voiceVol[H]=nil
end
end)
end
end
end
function z.setMuted(D,E)
B.muted[D]=E or nil
if E then z.hookChat();z.setListen(D,false)end
pcall(function()
local F=game:GetService"VoiceChatInternal"
local G=E and F.SubscribeBlock or F.SubscribeUnblock

if not pcall(G,F,D)then pcall(G,F,{D})end
end)
voiceDevices(D,E)
if E and not l.voiceLoop then
l.voiceLoop=true
task.spawn(function()
while l.alive and next(B.muted)do
task.wait(2)
for F in pairs(B.muted)do voiceDevices(F,true)end
end
l.voiceLoop=false
end)
end
end



local function quietWires(D,E)
local F=l.Players:GetPlayerByUserId(D)
if not F then return z.setListen(D,false)end
for G,H in ipairs{F,F.Character}do
for I,J in ipairs(H:GetDescendants())do
if J:IsA"Wire"and J.SourceInstance==E.dev and J.TargetInstance~=E.out then
if E.wires[J]==nil then E.wires[J]=J.Enabled end
if J.Enabled then J.Enabled=false end
end
end
end
end
function z.setListen(D,E)
local F=B.listen[D]
if F then
B.listen[D]=nil
pcall(function()F.out:Destroy()end)
for G,H in pairs(F.wires)do pcall(function()G.Enabled=H end)end
end
if not E then return true end
local G=l.Players:GetPlayerByUserId(D)
local H=G and G:FindFirstChildWhichIsA("AudioDeviceInput",true)
if not H then return false,"Can't route this player's voice: the game doesn't use Audio API voice"end
local I=pcall(function()
local I=Instance.new"AudioDeviceOutput"
I.Name="_klListen"
I.Parent=l.SoundService

local J=Instance.new"AudioFader"
J.Name="_klPad"
J.Volume=10^((tonumber(s.listenPad)or 0)/20)
J.Parent=I
local K,L=Instance.new"Wire",Instance.new"Wire"
K.SourceInstance,K.TargetInstance,K.Parent=H,J,I
L.SourceInstance,L.TargetInstance,L.Parent=J,I,I
B.listen[D]={out=I,dev=H,wires={},pad=J}
pcall(quietWires,D,B.listen[D])
end)
if not I then return false,"Couldn't create the audio route in this executor"end
if not l.listenLoop then
l.listenLoop=true
task.spawn(function()
while l.alive and next(B.listen)do
for J,K in pairs(B.listen)do pcall(quietWires,J,K)end
task.wait(0.5)
end
l.listenLoop=false
end)
end
return true
end

function z.vcDrop(D)
local E=B.vcm and B.vcm[D]
if E then pcall(function()E.an:Destroy()end);B.vcm[D]=nil end
end
function z.vcClear()
for D in pairs(B.vcm or{})do z.vcDrop(D)end
end
function z.vcMeter(D)
B.vcm,B.vcMiss=B.vcm or{},B.vcMiss or{}
local E=B.vcm[D]
if E and E.an.Parent and E.dev.Parent then return E end
if E then z.vcDrop(D)end
if B.vcMiss[D]and os.clock()-B.vcMiss[D]<3 then return nil end
B.vcMiss[D]=os.clock()
local F=l.Players:GetPlayerByUserId(D)
local G=F and F:FindFirstChildWhichIsA("AudioDeviceInput",true)
if not G then return nil end
pcall(function()
local H=Instance.new"AudioAnalyzer"
H.Name="_klMeter"
H.Parent=l.SoundService
local I=Instance.new"Wire"
I.SourceInstance,I.TargetInstance,I.Parent=G,H,H
B.vcm[D]={an=H,dev=G}
end)
return B.vcm[D]
end

local function applyVol(D,E)
local F=l.Players:GetPlayerByUserId(D)
if not F then if B.vcVol then B.vcVol[D]=nil end return end
for G,H in ipairs(F:GetDescendants())do
if H:IsA"AudioDeviceInput"then
if B.muted[D]then
if B.voiceVol and B.voiceVol[H]~=nil then B.voiceVol[H]=E end
else
pcall(function()H.Volume=E end)
end
end
end
end
function z.setVoiceVol(D,E)
B.vcVol=B.vcVol or{}
B.vcVol[D]=math.abs(E-1)>0.001 and E or nil
applyVol(D,E)
if next(B.vcVol)and not l.volLoop then
l.volLoop=true
task.spawn(function()
while l.alive and next(B.vcVol)do
task.wait(2)
for F,G in pairs(B.vcVol)do applyVol(F,G)end
end
l.volLoop=false
end)
end
end
function z.applyListenPad()
local D=10^((tonumber(s.listenPad)or 0)/20)
for E,F in pairs(B.listen)do
if F.pad then pcall(function()F.pad.Volume=D end)end
end
end
function z.rememberLighting()
local D=z.Lighting
B.saved.light=B.saved.light or{Brightness=D.Brightness,ClockTime=D.ClockTime,FogEnd=D.FogEnd,
GlobalShadows=D.GlobalShadows,Ambient=D.Ambient}
end


function z.kbTab()
for D,E in ipairs(s.kbTabs)do
if E.id==s.kbActive then return E end
end
end
function z.bindTable()
if s.kbActive=="none"then return nil end
local D=z.kbTab()
return D and D.binds or s.binds
end
function z.activeBinds()
local D=z.kbTab()
if D and D.es and D.exp~=game.GameId then return nil end
return z.bindTable()
end

z.MODS={LeftControl="Ctrl",RightControl="Ctrl",LeftShift="Shift",RightShift="Shift",LeftAlt="Alt",RightAlt="Alt"}
function z.normKey(D)
local E={}
for F in tostring(D):gmatch"[^%+]+"do E[#E+1]=F end
local F=keyFromString(E[#E]or D)
if not F then return nil end
local G,H={},{ctrl="Ctrl",control="Ctrl",shift="Shift",alt="Alt"}
for I=1,#E-1 do
local J=H[E[I]:lower()]
if not J then return nil end
G[J]=true
end
local I=""
for J,K in ipairs{"Ctrl","Shift","Alt"}do if G[K]then I=I..K.."+"end end
return I..F.Name
end
function z.keyName(D)
if z.MODS[D.Name]then return D.Name end
local E,F=l.UserInputService,""
if E:IsKeyDown(Enum.KeyCode.LeftControl)or E:IsKeyDown(Enum.KeyCode.RightControl)then F=F.."Ctrl+"end
if E:IsKeyDown(Enum.KeyCode.LeftShift)or E:IsKeyDown(Enum.KeyCode.RightShift)then F=F.."Shift+"end
if E:IsKeyDown(Enum.KeyCode.LeftAlt)or E:IsKeyDown(Enum.KeyCode.RightAlt)then F=F.."Alt+"end
return F..D.Name
end
function z.bindList(D)
local E,F=z.bindTable(),{}
local G=E and E[D]
if type(G)=="table"then for H,I in ipairs(G)do F[#F+1]=I end
elseif G then F[1]=G end
return F
end
function z.storeBinds(D,E)
local F=z.bindTable()
if not F then return z.notify"Keybinds are off. Pick Default or a tab in Keybinds first"end
if#E==0 then F[D]=nil elseif#E==1 then F[D]=E[1]else F[D]=E end
if z.cycle then z.cycle[tostring(s.kbActive).."|"..D]=nil end
save()
if n.refreshKeys then n.refreshKeys()end
end
function z.setBind(D,E)
local F=z.normKey(D)
if not F then return z.notify("Unknown key: "..tostring(D))end
z.storeBinds(F,(E and E~="")and{E}or{})
end
function z.addBind(D,E)
local F=z.normKey(D)
if not F then return z.notify("Unknown key: "..tostring(D))end
E=tostring(E):match"^%s*(.-)%s*$"
if E==""then return end
local G=z.bindList(F)
G[#G+1]=E
z.storeBinds(F,G)
end
function z.editBind(D,E,F)
local G=z.bindList(D)
if not G[E]then return end
if F==0 then table.remove(G,E)
elseif G[E+F]then G[E],G[E+F]=G[E+F],G[E]end
z.storeBinds(D,G)
end
function z.fireBind(D,E)
local F=z.keyName(E)
local G=D[F]
if G==nil then F=E.Name;G=D[F]end
if G==nil then return end
if type(G)~="table"then return z.Run(G)end
if#G==0 then return end
z.cycle=z.cycle or{}
local H=tostring(s.kbActive).."|"..F
local I=(z.cycle[H]or 0)%#G+1
z.cycle[H]=I
z.Run(G[I])
end
function z.setBarKey(D)
local E=keyFromString(D)
if not E then return z.notify("Unknown key: "..tostring(D))end
s.barKey=E.Name
save()
n.apply()
end

function z.openTab(D)n.setPanel(true);n.selectTab(D)end


local D={
fly="unfly",noclip="clip",infjump="uninfjump",follow="unfollow",view="unview",esp="unesp",
xray="unxray",fullbright="unfullbright",freeze="thaw",invisible="visible",noanim="anim",
float="unfloat",cfly="uncfly",jesus="unjesus",tpwalk="untpwalk",backpack="unattach",baby="unattach",
headsit="unattach",heada="unattach",backa="unattach",ragdoll="unragdoll",spin="unspin",antifling="unantifling",antisit="unantisit",
antivoid="unantivoid",antiteleport="unantiteleport",antiknockback="unantiknockback",antiattach="unantiattach",
antiearrape="unantiearrape",antiblur="unantiblur",antiafk="unantiafk",antispam="unantispam",
antifreeze="unantifreeze",blink="unblink",ghost="unghost",streamer="unstreamer",name="unname",
lockmouse="unlockmouse",ctrllock="unctrllock",showfps="unshowfps",hide="unhide all",placeholder1="unplaceholder1",noplayercollision="playercollision",hidecursor="unhidecursor",look="unlook",keepemotes="unkeepemotes",
}
D.spider,D.serverpos="unspider","unserverpos"
D.antigameplaypaused="unantigameplaypaused"
D.autovoid="unautovoid"

D.freecam="unfreecam"
D.playernames="hidenames"
D.hideui="unhideui"

local E={float=true,blink=true,ghost=true,hide=true}

function z.resetAll()
B.loopGen=B.loopGen+1
B.loopOf={}
B.noAct=true
for F in pairs(B.active)do
B.active[F]=nil
if D[F]then pcall(z.Run,D[F])end
end
B.noAct=nil
if n.act then n.act("stopall","all effects off")end
end

function z.add(F,G)
if type(F)=="string"then F={F}end
z.Commands[F[1] ]=G
for H,I in ipairs(F)do z.Aliases[I:lower()]=F[1]end
end

local F={panel=true,cmds=true,config=true,cfg=true,ui=true,exit=true,selftest=true,prefix=true,reload=true}
function z.Run(G)
local H=split((G:gsub("^%s*;","")))
local I=table.remove(H,1)
if not I then return end

local J=I:match"^[Ll][Oo][Oo][Pp]%^(.+)$"
local K=z.Aliases[(J or I):lower()]
if not K then return z.notify("Unknown command: "..(J or I))end
if J then
local L,M={},z.Commands[K]
B.loopOf[K]=L
B.active["loop^"..K]=true
task.spawn(function()
while B.loopOf[K]==L and l.alive do
if not(E[K]and B.active[K])then pcall(M,table.unpack(H))end
task.wait(0.15)
end
if B.loopOf[K]==nil then B.active["loop^"..K]=nil end
end)
return
end
local L,M=pcall(z.Commands[K],table.unpack(H))
if not L then return z.notify(K.." error: "..tostring(M))end
local N
local O=z.Meta[K]
if O and tostring(O.args):find"^<player"and H[1]and not({me=1,all=1,others=1,random=1})[H[1]:lower()]then
local P=z.findPlayers(H[1])
if#P==1 then N=P[1].Name end
end
if n.act and not B.noAct and not F[K]then
local P,Q=0
for R,S in pairs(D)do if S==K then Q,P=R,P+1 end end
local R=N and table.concat({N,table.unpack(H,2)}," ")or table.concat(H," ")
if#R>30 then R=R:sub(1,28)..".."end
if P>0 then n.act(P==1 and Q or(K:gsub("^un","")),"off")
elseif E[K]then if not B.active[K]then n.act(K,"off")end
elseif D[K]then
else n.act(K,R)end
end
if E[K]then return end
if D[K]then
B.active[K]=true
B.who=B.who or{}
B.who[K]=N
B.val=B.val or{}
B.val[K]=(not N and#H>0)and table.concat(H," ")or nil
else
for P,Q in pairs(D)do
if Q==K then B.active[P]=nil;if B.who then B.who[P]=nil end;if B.val then B.val[P]=nil end end
end
end
end


local G={
view={"<player>","Spectate a player"},unview={"","Stop spectating"},goto=
{"<player>","Teleport to a player"},tpto={"<x> <y> <z>","Teleport to coordinates"},
userinfo={"<player>","Show name, ID and account age"},copyid={"<player>","Copy a player's user ID"},
profile={"<player>","Copy a player's profile link"},players={"","Open the Players tab"},
follow={"<player>","Walk after a player"},unfollow={"","Stop following"},
friend={"<player | username | id>","Open the friend request prompt (not in the server: copies their profile link)"},unfriend={"<player>","Open the unfriend prompt"},
block={"<player>","Open the block prompt"},unblock={"<player>","Open the unblock prompt"},
mute={"<player>","Mute a player's voice and hide their chat"},unmute={"<player>","Hear a player and see their chat again"},
serverhop={"","Join another public server"},smallserver={"","Join the emptiest public server"},
rejoin={"","Rejoins you from the experience"},jobid={"","Copy this server's job ID"},
placeid={"","Copy the place ID"},serverinfo={"","Show player count and uptime"},
speed={"[n]","Set walk speed (default 16)"},jumppower={"[n]","Set jump power (default 50)"},
gravity={"[n]","Set gravity (default 196.2)"},fov={"[n]","Set field of view (default 70)"},
sit={"","Sit down"},unsit={"","Stand up"},
freeze={"","Anchor your character"},thaw={"","Unanchor your character"},
infjump={"","Jump again in mid-air"},uninfjump={"","Turn infinite jump off"},
noclip={"","Walk through walls"},clip={"","Turn noclip off"},
mousetp={"","Teleport to where your mouse points (bind it to a key)"},
fly={"[speed]","Fly with WASD, E up and Q down"},unfly={"","Stop flying"},
reset={"","Respawn your character"},invisible={"","Hide your avatar (only you see this)"},
visible={"","Show your avatar again"},noanim={"","Stop your animations"},
anim={"","Turn your animations back on"},tools={"","List the tools in your backpack"},
esp={"","Highlight and tag other players"},unesp={"","Remove player highlights"},
fullbright={"","Light up the whole map"},unfullbright={"","Restore the original lighting"},
nofog={"","Remove fog"},time={"[hour]","Set the time of day (default 14)"},
xray={"","See through walls"},unxray={"","Turn x-ray off"},
maxzoom={"[n]","Set max camera zoom"},minzoom={"[n]","Set min camera zoom"},
fpscap={"[n]","Cap the frame rate (default 60)"},console={"","Open the developer console"},
cmds={"","Show every command"},prefix={"<key>","Change the command bar key"},
alias={"<new> <command>","Make a shortcut for a command"},
loop={"<n> <command>","Run a command n times"},unloop={"","Stop all running loops"},
bind={"<key> <command>","Run a command when you press a key"},unbind={"<key>","Remove a key bind"},
stopall={"","Turn off every active effect"},reload={"","Reload files from KLOSAD/commands"},
panel={"","Open or close the panel"},selftest={"","Run the built-in self check"},
}


local H={
view="spectate watch camera",unview="spectate watch camera",goto="teleport tp player move",tpto="teleport coordinates position",
userinfo="age id account info",copyid="clipboard id",profile="link url roblox",players="list people",follow="walk chase",
unfollow="walk chase",friend="add request social",unfriend="remove social",block="report ignore social",unblock="social",
mute="voice vc chat audio silence quiet speak talk",unmute="voice vc chat audio hear speak talk",
serverhop="server change join new lobby",smallserver="server empty low population",rejoin="reconnect join again server",
jobid="server id",placeid="game id",serverinfo="server players uptime",speed="walkspeed run fast",jumppower="jump height",
gravity="fall float",fov="camera zoom field view",sit="seat",freeze="anchor stop",thaw="anchor",infjump="infinite jump air",
noclip="wall collide ghost through",clip="wall collide",mousetp="teleport cursor click",fly="flight air",unfly="flight air",
reset="respawn die kill",invisible="hide transparent",visible="show transparent",noanim="animation stop",anim="animation",
tools="backpack items inventory",esp="wallhack highlight name tag players",xray="transparent walls see through",
fullbright="light bright dark",nofog="fog view",time="day night clock",maxzoom="camera zoom",minzoom="camera zoom",
fpscap="frame rate performance",console="developer log output",cmds="list commands help",prefix="key bind bar",
alias="shortcut",loop="repeat",bind="key hotkey",stopall="reset effects off",reload="files commands",
}


z.CAT_ORDER={"Movement","Defense","Offense","Players","Voice","Camera","Visuals","Character","Privacy","Server","Tools","rOSAD","Other"}
local I={
Movement="float unfloat cfly uncfly fly unfly jesus unjesus tpwalk untpwalk hheight follow unfollow sit unsit ragdoll unragdoll spin unspin look unlook speed jumppower goto tpto ptp mousetp freeze thaw infjump uninfjump noclip clip blink unblink ghost gravity clear",
Defense="antiexploit antifling unantifling antisit unantisit antivoid unantivoid antiteleport unantiteleport antiknockback unantiknockback antiattach unantiattach antiearrape unantiearrape antiblur unantiblur antiafk unantiafk antispam unantispam antifreeze unantifreeze",
Offense="backpack baby headsit heada backa unattach",
Players="view unview userinfo copyid profile players friend unfriend block unblock hide unhide",
Voice="mute unmute listen unlisten nostereo stereo refreshaudio arjvc",
Camera="fov maxzoom minzoom freecam lockmouse unlockmouse enableshiftlock ctrllock unctrllock toggleshiftlock crosshair removecrosshair hidecursor unhidecursor",
Visuals="fullbright unfullbright esp unesp xray unxray nofog time showfps unshowfps baseplate removebaseplate",
Character="reset anim noanim invisible visible placeholder1 unplaceholder1 keepemotes unkeepemotes",
Privacy="streamer unstreamer name unname",
Server="serverhop smallserver serverinfo rejoin jobid placeid",
Tools="hlxp liu dex cobalt kelsec rspy alogger workwell tetris untetris workwellpf properties tooleditor klpfxp kill saveinstance freezesave tools console",
rOSAD="ui exit cmds config keeposad unkeeposad alias unalias bind unbind loop unloop breakloop prefix fpscap gamedefault text stopall reload panel selftest",
}
I.Movement=I.Movement.." spider unspider"
I.Defense=I.Defense.." antigameplaypaused unantigameplaypaused aer"
I.Visuals=I.Visuals.." serverpos unserverpos"
I.Visuals=I.Visuals.." hideui unhideui"
I.Server=(I.Server or"").." region serverbrowser scanregions serverhop leave"
I.Players=I.Players.." report"
I.Visuals=I.Visuals.." playernames hidenames"
I.Tools=I.Tools.." update"
I.Defense=I.Defense.." void autovoid unautovoid"
z.catOf={}
for J,K in pairs(I)do
for L in K:gmatch"%S+"do z.catOf[L]=J end
end

function z.register(J)
local K,L=pcall(J,z)
if K and type(L)=="table"and type(L.names)=="string"then L.names={L.names}end
if not K or type(L)~="table"or type(L.names)~="table"or type(L.names[1])~="string"then
warn("[KLOSAD] bad command module: "..tostring(L))
return
end
z.add(L.names,L.run)
local M=G[L.names[1] ]or{}
z.Meta[L.names[1] ]={desc=L.desc or M[2]or"",args=L.args or M[1]or"",tags=L.tags or H[L.names[1] ]or""}
return L
end

function z.loadFolder(J)
if not(p and q and isfolder(J))then return 0 end
local K=0
for L,M in ipairs(listfiles(J))do
if isfolder(M)then
K=K+z.loadFolder(M)
elseif M:sub(-4)==".lua"then
local N,O=pcall(function()return loadstring(readfile(M))()end)
if N and type(O)=="function"then
z.register(O)
K=K+1
else
warn("[KLOSAD] failed to load "..M..": "..tostring(O))
end
end
end
return K
end


function z.selftest()
local J=split'say "hello world" x'
assert(#J==3 and J[2]=="hello world","split")
assert(parseHex"#ff0000"and not parseHex"red","hex")
assert(score({names={"rejoin"},desc=""},"re")==1,"prefix rank")
assert(score({names={"freecam"},desc=""},"re")==3,"substring rank")
z.notify"selftest ok"
end


local function mini(J,K)z.register(function(L)return{names=J,run=K}end)end
mini({"stopall","resetall"},function()z.resetAll()end)
mini({"reload"},function()z.notify(("Reloaded %d command file(s)"):format(z.loadFolder(b.."/commands")))end)
mini({"panel"},function()n.setPanel(not l.panelOpen)end)
mini({"unbind"},function(J)if J then z.setBind(J,nil)end end)
mini({"unloop"},function()z.Run"breakloop"end)
mini({"selftest"},function()z.selftest()end)




local J={}
J[#J+1]=(function()

return function(K)
local L=K.findPlayer

return{
names={"copyid"},
run=function(M)
local N=L(M)
if N and setclipboard then setclipboard(tostring(N.UserId))end
end,
}
end
end)()
J[#J+1]=(function()

return function(K)
return{
names={"players"},
run=function()K.openTab"Players"end,
}
end
end)()
J[#J+1]=(function()

return function(K)
local L=K.findPlayer

return{
names={"profile"},
run=function(M)
local N=L(M)
if N and setclipboard then setclipboard("https://www.roblox.com/users/"..N.UserId.."/profile")end
end,
}
end
end)()

J[#J+1]=(function()

return function(K)
local L,M=K.hum,K.state

return{
names={"unview","unspectate"},
run=function()
K.unpark(true)
if L()then workspace.CurrentCamera.CameraSubject=L()end
M.viewing=nil
end,
}
end
end)()
J[#J+1]=(function()

return function(K)
local L,M=K.findPlayer,K.notify

return{
names={"userinfo"},
run=function(N)
local O=L(N)
if not O then return end
M(("%s (@%s) | ID %d | Age %d days"):format(O.DisplayName,O.Name,O.UserId,O.AccountAge))
end,
}
end
end)()
J[#J+1]=(function()

return function(K)
local L,M,N=K.findPlayer,K.state,K.lp

return{
names={"view","spectate"},
run=function(O)
local P=L(O)
if not P or P==N then return end



M.viewing=P
M.viewGen=(M.viewGen or 0)+1
M.viewRec=M.viewRec or{}
local Q,R=M.viewGen,M.viewRec
local function far(S,T,U)
R[S]=R[S]or{}
if R[S][T]~=nil then return end
local V,W=pcall(function()return S[T]end)
if V and W~=nil then R[S][T]=W;pcall(function()S[T]=U end)end
end
local function body()local S=P.Character;return S and S:FindFirstChildOfClass"Humanoid",S and S:FindFirstChild"HumanoidRootPart"end
if not body()then K.notify(P.Name.." is not loaded yet: the camera moves to them once they stream in")end
task.spawn(function()
local S=0
while M.viewGen==Q and M.viewing==P do
if not P.Parent then K.notify(P.Name.." left the server: view ended");K.Run"unview";break end
local T,U=body()
local V=M.seen[P.UserId]
local W=U and U.Position or(V and V.pos)
if workspace.StreamingEnabled and W and os.clock()-S>=1 then
S=os.clock()
task.spawn(pcall,N.RequestStreamAroundAsync,N,W,2)
end
local X=workspace.CurrentCamera
if T and X.CameraSubject~=T then X.CameraSubject=T end
for Y,Z in ipairs(K.Players:GetPlayers())do
local _=Z.Character
local aa,ab=_ and _:FindFirstChildOfClass"Humanoid",_ and _:FindFirstChild"Head"
if aa then far(aa,"NameDisplayDistance",1e5)end
if ab then for ac,ad in ipairs(ab:GetChildren())do if ad:IsA"BillboardGui"then far(ad,"MaxDistance",math.huge)end end end
end
task.wait(0.25)
end
if not M.viewing and M.viewRec==R then
for aa,ab in pairs(R)do for ac,ad in pairs(ab)do pcall(function()aa[ac]=ad end)end end
M.viewRec=nil
end
end)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.findPlayer,aa.StarterGui

return{
names={"block"},
run=function(ad)
local K=ab(ad)
if K then ac:SetCore("PromptBlockPlayer",K)end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)local
ab, ac=aa.findPlayer, aa.SocialService

return{
names={"friend"},
run=function(ad)
local K=aa.findPlayers(ad)[1]
if not K then
local L,M=pcall(function()return tonumber(ad)or aa.Players:GetUserIdFromNameAsync(ad)end)
if not(L and M)then return aa.notify("No player or Roblox user '"..tostring(ad).."'",4)end
if setclipboard then pcall(setclipboard,"https://www.roblox.com/users/"..M.."/profile")end
return aa.notify("Not in this server: Roblox only lets a game send friend requests to players who are here. Their profile link is copied, open it and press Add Friend",8)
end
local L,M=pcall(function()ac:PromptFriendRequest(K)end)
if not L then
L,M=pcall(function()game:GetService"StarterGui":SetCore("PromptSendFriendRequest",K)end)
end
if not L then aa.notify("Friend request failed: "..tostring(M),5)end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.findPlayers,aa.lp

return{
names={"mute"},
run=function(ad)
for K,L in ipairs(ab(ad))do
if L~=ac then aa.setMuted(L.UserId,true)end
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.findPlayer,aa.StarterGui

return{
names={"unblock"},
run=function(ad)
local K=ab(ad)
if K then ac:SetCore("PromptUnblockPlayer",K)end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.findPlayer,aa.SocialService

return{
names={"unfriend"},
run=function(ad)
local K=ab(ad)
if not K then return aa.notify"Player not found"end
local L,M=pcall(function()ac:PromptUnfriend(K)end)
if not L then
L,M=pcall(function()game:GetService"StarterGui":SetCore("PromptUnfriend",K)end)
end
if not L then aa.notify("Unfriend failed: "..tostring(M),5)end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.findPlayers

return{
names={"unmute"},
run=function(ac)
for ad,K in ipairs(ab(ac))do aa.setMuted(K.UserId,false)end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.notify

return{
names={"jobid"},
run=function()
if setclipboard then setclipboard(game.JobId)end
ab(game.JobId)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.notify

return{
names={"placeid"},
run=function()
if setclipboard then setclipboard(tostring(game.PlaceId))end
ab(game.PlaceId)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac,ad=aa.TeleportService,aa.Players,aa.lp

return{
names={"rejoin","rj"},
run=function()
if#ac:GetPlayers()==1 then
ab:Teleport(game.PlaceId,ad)
else
ab:TeleportToPlaceInstance(game.PlaceId,game.JobId,ad)
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.hop

return{
names={"serverhop","shop"},args="[US / EU / AS / city]",desc="Hop to another server; with a region, to a scanned server there (run ;scanregions first)",
run=function(ac)
if ac and ac~=""then return aa.SRV.hop(ac)end
ab"Desc"
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.Players,aa.notify

return{
names={"serverinfo"},
run=function()
ac(("%d players | up %ds"):format(#ab:GetPlayers(),math.floor(workspace.DistributedGameTime)))
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.hop

return{
names={"smallserver","lowserver"},
run=function()
ab"Asc"
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.disconnect

return{
names={"clip"},
run=function()
ab"noclip";ab"noclip_safe"
local ac=aa.nc
if ac then
for ad,K in pairs(ac.orig)do
if ad.Parent then ad.CanCollide=K end
ac.orig[ad]=nil
end
ac.y=nil
if ac.floor then ac.floor:Destroy();ac.floor=nil end
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)local ab=
aa.cam

return{
names={"fov"},
run=function(ac)
workspace.CurrentCamera.FieldOfView=tonumber(ac)or 70
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
return{
names={"gravity"},
run=function(ab)
workspace.Gravity=tonumber(ab)or 196.2
end,
}
end
end)()
J[#J+1]=(function()



return function(aa)
local ab,ac,ad=aa.connect,aa.RunService,aa.char
local K={orig={}}
aa.nc=K
local L=RaycastParams.new()
L.FilterType,L.RespectCanCollide=Enum.RaycastFilterType.Exclude,true

return{
names={"noclip"},
run=function()
K.y=nil
ab("noclip",ac.Stepped,function()
local M=ad()
if not M then return end
for N,O in ipairs(M:GetDescendants())do
if O:IsA"BasePart"then
if K.orig[O]==nil then K.orig[O]=O.CanCollide end
O.CanCollide=false
end
end
end)
local function floorStep(M)
local N=ad()
local O=N and N:FindFirstChild"HumanoidRootPart"
local P=N and N:FindFirstChildOfClass"Humanoid"
if not(O and P)then return end
local Q=K.floor
if not(Q and Q.Parent)then
Q=Instance.new"Part"
Q.Name,Q.Anchored,Q.CanCollide,Q.Transparency,Q.Size,Q.Locked="_noclipFloor",true,true,1,Vector3.new(8,1,8),true
Q.Parent=workspace
K.floor=Q
end
local R={N,Q}
for S,T in ipairs(aa.Players:GetPlayers())do
if T~=aa.lp and T.Character then R[#R+1]=T.Character end
end
L.FilterDescendantsInstances=R
local S=O.Position.Y-(P.RigType==Enum.HumanoidRigType.R6 and 3 or(P.HipHeight+O.Size.Y/2))
K.y=K.y or S

local T=aa.state.floatY
if not T then
local U=workspace:Raycast(O.Position,Vector3.new(0,-500,0),L)
T=U and U.Position.Y
end
if T then K.y=(T>=K.y)and T or math.max(T,K.y-60*M)end
K.y=math.min(K.y,S+1)
Q.CFrame=CFrame.new(O.Position.X,K.y-0.5,O.Position.Z)
end
floorStep(0.016)
ab("noclip_safe",ac.Heartbeat,floorStep)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.disconnect

return{
names={"uninfjump"},
run=function()
ab"infjump"
end,
}
end
end)()

J[#J+1]=(function()

return function(aa)
local ab=aa.char

return{
names={"anim"},
run=function()
local ac=ab()and ab():FindFirstChild"Animate"
if ac then ac.Disabled=false end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.char

return{
names={"invisible"},
run=function()
if not ab()then return end
for ac,ad in ipairs(ab():GetDescendants())do
if ad:IsA"BasePart"or ad:IsA"Decal"then
if ad.Name~="HumanoidRootPart"then
local K=aa.state.invis or{}
aa.state.invis=K
if K[ad]==nil then K[ad]=ad.Transparency end
ad.Transparency=1
end
end
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.hum,aa.char

return{
names={"noanim"},
run=function()
local ad=ab()
if not ad then return end
for K,L in ipairs(ad:GetPlayingAnimationTracks())do L:Stop()end
local K=ac():FindFirstChild"Animate"
if K then K.Disabled=true end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.hum

return{
names={"reset","respawn"},
run=function()
if ab()then ab().Health=0 end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.lp,aa.notify

return{
names={"tools"},
run=function()
local ad={}
local K=ab:FindFirstChildOfClass"Backpack"
for L,M in ipairs(K and K:GetChildren()or{})do ad[#ad+1]=M.Name end
ac(#ad>0 and table.concat(ad,", ")or"No tools in your backpack")
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.char

return{
names={"visible"},
run=function()
local ac=aa.state.invis
aa.state.invis=nil
if not ab()then return end
for ad,K in ipairs(ab():GetDescendants())do
if(K:IsA"BasePart"or K:IsA"Decal")and K.Name~="HumanoidRootPart"then K.Transparency=ac and ac[K]or 0 end
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.StarterGui

return{
names={"console"},
run=function()
ab:SetCore("DevConsoleVisible",true)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac,ad,K=aa.Players,aa.lp,aa.state,aa.connect


local function espCol(L)
if s.mod.espCustom then return parseHex(s.mod.espColor)or Color3.fromRGB(255,59,59)end
return L.Team and L.TeamColor.Color or Color3.new(1,1,1)
end
local function paintEsp(L)
local M=ad.esp[L]
if not M then return end
local N=espCol(L)
if M[1].Parent then M[1].FillColor=N;M[1].OutlineColor=N end
local O=M[2]:FindFirstChildOfClass"TextLabel"
if O then O.TextColor3=N end
end
function aa.espRefresh()for L in pairs(ad.esp)do paintEsp(L)end end

local function tag(L)
if L==ac or not L.Character then return end
for M,N in ipairs(ad.esp[L]or{})do N:Destroy()end
local M=Instance.new"Highlight"
M.FillTransparency=0.7;M.Name="_esp";M.Parent=L.Character
local N=Instance.new"BillboardGui"
N.Name="_espTag";N.Size=UDim2.fromOffset(120,20)
N.AlwaysOnTop=true;N.StudsOffset=Vector3.new(0,3,0)
local O=Instance.new("TextLabel",N)
O.Size=UDim2.fromScale(1,1);O.BackgroundTransparency=1
O.TextColor3=Color3.new(1,1,1);O.TextStrokeTransparency=0
O.Text=L.Name
N.Adornee=L.Character:FindFirstChild"Head";N.Parent=L.Character
ad.esp[L]={M,N}
paintEsp(L)
end

local function watch(L)
if L==ac then return end
K("espTeam_"..L.UserId,L:GetPropertyChangedSignal"TeamColor",function()paintEsp(L)end)
K("espChar_"..L.UserId,L.CharacterAdded,function()
task.wait(0.5)
if aa.state.conns["espChar_"..L.UserId]and L.Parent then tag(L)end
end)
end

return{
names={"esp"},
run=function()
for L,M in ipairs(ab:GetPlayers())do tag(M);watch(M)end
K("espAdd",ab.PlayerAdded,watch)
K("espRem",ab.PlayerRemoving,function(L)
aa.disconnect("espChar_"..L.UserId);aa.disconnect("espTeam_"..L.UserId)
for M,N in ipairs(aa.state.esp[L]or{})do pcall(function()N:Destroy()end)end
aa.state.esp[L]=nil
end)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.Lighting,aa.state

return{
names={"fullbright","fb"},
run=function()
ac.saved.light=ac.saved.light or{
Brightness=ab.Brightness,ClockTime=ab.ClockTime,
FogEnd=ab.FogEnd,GlobalShadows=ab.GlobalShadows,Ambient=ab.Ambient,
}
ab.Brightness=2
ab.ClockTime=14
ab.FogEnd=1e9
ab.GlobalShadows=false
ab.Ambient=Color3.new(1,1,1)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.lp

return{
names={"maxzoom"},
run=function(ac)
ab.CameraMaxZoomDistance=tonumber(ac)or 128
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.lp

return{
names={"minzoom"},
run=function(ac)
ab.CameraMinZoomDistance=tonumber(ac)or 0.5
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.Lighting

return{
names={"nofog"},
run=function()
aa.rememberLighting()
ab.FogEnd=1e9
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.Lighting

return{
names={"time"},
run=function(ac)
aa.rememberLighting()
ab.ClockTime=tonumber(ac)or 14
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.disconnect,aa.state

return{
names={"unesp"},
run=function()
ab"espAdd";ab"espRem"
for ad in pairs(ac.conns)do
if ad:find"^espChar_"or ad:find"^espTeam_"then ab(ad)end
end
for ad,K in pairs(ac.esp)do
for L,M in ipairs(K)do M:Destroy()end
ac.esp[ad]=nil
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.Lighting,aa.state

return{
names={"unfullbright","unfb"},
run=function()
for ad,K in pairs(ac.saved.light or{})do ab[ad]=K end
ac.saved.light=nil
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
return{
names={"unxray"},
run=function()
for ab,ac in ipairs(workspace:GetDescendants())do
if ac:IsA"BasePart"then ac.LocalTransparencyModifier=0 end
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.char

return{
names={"xray"},
run=function()
for ac,ad in ipairs(workspace:GetDescendants())do
if ad:IsA"BasePart"and not(ab()and ad:IsDescendantOf(ab()))and not ad.Parent:FindFirstChildOfClass"Humanoid"then
ad.LocalTransparencyModifier=0.7
end
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab=aa.Aliases

return{
names={"alias"},
run=function(ac,ad)
local K=ad and ab[ad:lower()]
if ac and K then
ab[ac:lower()]=K
s.aliases[ac:lower()]=K
save()
aa.notify("alias "..ac:lower().." = "..K)
else
aa.notify"Usage: alias <new> <command>"
end
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
return{
names={"bind"},
run=function(ab,...)
if not ab then return aa.notify"Usage: bind <key> <command>"end
aa.setBind(ab,table.concat({...}," "))
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
local ab,ac=aa.Run,aa.state

return{
names={"loop"},
run=function(ad,...)
local K,L,M=table.concat({...}," "),math.min(tonumber(ad)or 1,1000),ac.loopGen
task.spawn(function()
for N=1,L do
if ac.loopGen~=M then break end
ab(K)
task.wait(0.1)
end
end)
end,
}
end
end)()
J[#J+1]=(function()

return function(aa)
return{
names={"prefix"},
run=function(ab)
if ab then aa.setBarKey(ab)else aa.notify"Usage: prefix <key>"end
end,
}
end
end)()
for aa,ab in ipairs(J)do z.register(ab)end



rest"BOOT-CMD_BUILTIN"


do
local aa=s.mod
local ab,ac,ad=z.UIS,z.RunService,z.Players
local function def(K,L,M,N,O)
z.register(function()return{names=K,args=L,desc=M,tags=N,run=O}end)
end
local function active(K,L)B.active[K]=L or nil end
local K={}
local function dnotify(L,M)
if not aa.defNotify then return end
local N=os.clock()
if K[L]and N-K[L]<3 then return end
K[L]=N
z.notify(M)
end
local function typing()return ab:GetFocusedTextBox()~=nil end
local function down(L)return ab:IsKeyDown(L)and not typing()end



local L=z.hum()
c.KLOSAD_DEF=c.KLOSAD_DEF or{
ws=L and L.WalkSpeed or 16,jp=L and L.JumpPower or 50,jh=L and L.JumpHeight or 7.2,ujp=L and L.UseJumpPower,
hip=L and L.HipHeight or 2,grav=workspace.Gravity,fov=workspace.CurrentCamera.FieldOfView,
minz=A.CameraMinZoomDistance,maxz=A.CameraMaxZoomDistance,
light={Brightness=z.Lighting.Brightness,ClockTime=z.Lighting.ClockTime,FogEnd=z.Lighting.FogEnd,
GlobalShadows=z.Lighting.GlobalShadows,Ambient=z.Lighting.Ambient},
}
B.defaults=c.KLOSAD_DEF


z.connect("defCap",A.CharacterAdded,function(M)
if B.swapped and B.swapped[M]then return end
task.wait(1.5)
local N=z.hum()
if B.blink or not N or N.Parent~=M then return end
local O=B.defaults
O.ws,O.jp,O.jh,O.ujp,O.hip=N.WalkSpeed,N.JumpPower,N.JumpHeight,N.UseJumpPower,N.HipHeight
end)


function z.runSource(M,N)
if not q then return z.notify"loadstring isn't available in this executor"end
local O,P=loadstring(M)
if not O then return z.notify(N..": "..tostring(P))end
task.spawn(function()
local Q,R=pcall(O)
if not Q then z.notify(N.." error: "..tostring(R))end
end)
end
function z.fetch(M)
if o then
local N,O=pcall(o,{Url=M,Method="GET"})
if N and O and O.StatusCode==200 then return O.Body end
return nil,N and("HTTP "..tostring(O and O.StatusCode))or tostring(O)
end
local N,O=pcall(function()return game:HttpGet(M)end)
if N then return O end
return nil,tostring(O)
end


def({"breakloop","break"},"[command]","Stop loop^ loops (all, or just one command)","stop loop repeat",function(M)
B.loopGen=B.loopGen+1
if M and z.Aliases[M:lower()]then
B.loopOf[z.Aliases[M:lower()] ]=nil
B.active["loop^"..z.Aliases[M:lower()] ]=nil
else
for N in pairs(B.loopOf)do B.active["loop^"..N]=nil end
B.loopOf={}
end
end)





local function unfloat()
z.disconnect"float"
if B.floatPart then B.floatPart:Destroy();B.floatPart=nil end
if B.floatNoJump then
B.floatNoJump=nil
local M=z.hum()
if M then pcall(M.SetStateEnabled,M,Enum.HumanoidStateType.Jumping,true)end
end
B.floatY=nil
active("float",nil)
end
local function feetY()
local M,N=z.root(),z.hum()
if not(M and N)then return nil end
local O=N.RigType==Enum.HumanoidRigType.R6 and 3 or(N.HipHeight+M.Size.Y/2)
return M.Position.Y-O
end
def({"float"},"","Float over drops deeper than the stair height (E up, Q down, run again to reset)","hover levitate air step platform",function()
local M=feetY()
if not M then return end
B.floatY,B.eLift=M,nil
if not B.floatPart then
local N=Instance.new"Part"
N.Name,N.Anchored,N.CanCollide,N.Transparency,N.Size="_float",true,false,1,Vector3.new(8,1,8)
N.Parent=workspace
B.floatPart=N
end
local N
z.connect("float",ac.Heartbeat,function(O)
local P,Q,R=z.root(),z.hum(),B.floatPart
if not(P and Q and R and R.Parent)then return end
local S=feetY()

if N and(P.Position-N).Magnitude>30 then B.floatY,B.eLift=S or B.floatY,nil end
N=P.Position
if down(Enum.KeyCode.E)then
B.eLift=true
if S then B.floatY=math.max(B.floatY,S)end
B.floatY=B.floatY+36*O
end
if down(Enum.KeyCode.Q)then B.floatY=B.floatY-36*O end

local T=down(Enum.KeyCode.E)or down(Enum.KeyCode.Q)
if T~=(B.floatNoJump or false)then
B.floatNoJump=T
pcall(Q.SetStateEnabled,Q,Enum.HumanoidStateType.Jumping,not T)
end
if down(Enum.KeyCode.E)then local U=P.AssemblyLinearVelocity;P.AssemblyLinearVelocity=Vector3.new(U.X,0,U.Z)end
local U=RaycastParams.new()
U.FilterType,U.RespectCanCollide=Enum.RaycastFilterType.Exclude,true
local V={z.char(),R}
for W,X in ipairs(ad:GetPlayers())do
if X~=A and X.Character then V[#V+1]=X.Character end
end
U.FilterDescendantsInstances=V
local W=workspace:Raycast(P.Position,Vector3.new(0,-2E3,0),U)
local X=W and W.Position.Y or-math.huge
local Y=feetY()

if B.eLift and B.floatY<=X+0.1 then B.eLift=nil end
if W and Y and Q.FloorMaterial~=Enum.Material.Air and math.abs(Y-X)<1.5 and not B.eLift then B.floatY=X end

if W and Y and Q.FloorMaterial~=Enum.Material.Air and math.abs(Y-X)<1 and not down(Enum.KeyCode.E)then B.floatY,B.eLift=X,nil end
R.CFrame=CFrame.new(P.Position.X,B.floatY-0.5,P.Position.Z)
R.CanCollide=B.eLift or(B.floatY-X)>aa.floatStep
end)
active("float",true)
end)
def({"unfloat"},"","Remove the float platform","hover levitate air step platform",unfloat)

def({"cfly"},"[speed]","CFrame fly (WASD, E up, Q down)","flight air cframe",function(M)
local N,O=z.root(),z.hum()
if not(N and O)then return end
local P=z.val("fly",M)
O.PlatformStand=true
z.connect("cfly",ac.Heartbeat,function(Q)
local R,S=z.root(),workspace.CurrentCamera
if not R then return end
local T=Vector3.zero
if down(Enum.KeyCode.W)then T=T+S.CFrame.LookVector end
if down(Enum.KeyCode.S)then T=T-S.CFrame.LookVector end
if down(Enum.KeyCode.D)then T=T+S.CFrame.RightVector end
if down(Enum.KeyCode.A)then T=T-S.CFrame.RightVector end
if down(Enum.KeyCode.E)then T=T+Vector3.yAxis end
if down(Enum.KeyCode.Q)then T=T-Vector3.yAxis end
R.AssemblyLinearVelocity=Vector3.zero
if T.Magnitude>0 then R.CFrame=R.CFrame+T.Unit*P*Q end
end)
end)
def({"uncfly"},"","Stop CFrame flying","flight air cframe",function()
z.disconnect"cfly"
if z.hum()then z.hum().PlatformStand=false end
end)




def({"freecam","fc"},"[speed]","Free camera: WASD move, E up, Q down, Shift faster, hold right mouse to look (;unfreecam to stop)","camera spectate detach cam fly",function(M)
local N=workspace.CurrentCamera
if not N then return end
local O=tonumber(M)
local P=N.CFrame.Position
local Q,R=N.CFrame:ToOrientation()
N.CameraType=Enum.CameraType.Scriptable
local S=l.ContextActionService
pcall(S.BindActionAtPriority,S,"KLOSAD_FC",function()return Enum.ContextActionResult.Sink end,false,Enum.ContextActionPriority.High.Value,
Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Q,Enum.KeyCode.E,Enum.KeyCode.Space)
z.connect("freecam",ac.RenderStepped,function(T)
local U=workspace.CurrentCamera
if U.CameraType~=Enum.CameraType.Scriptable then U.CameraType=Enum.CameraType.Scriptable end
if ab:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)then
ab.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
local V,W=ab:GetMouseDelta(),0.004*(tonumber(aa.fcSens)or 1)
R=R-V.X*W
Q=math.clamp(Q-V.Y*W,-1.55,1.55)
elseif ab.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition then
ab.MouseBehavior=Enum.MouseBehavior.Default
end
local V=CFrame.fromOrientation(Q,R,0)
local W=Vector3.zero
if down(Enum.KeyCode.W)then W=W+V.LookVector end
if down(Enum.KeyCode.S)then W=W-V.LookVector end
if down(Enum.KeyCode.D)then W=W+V.RightVector end
if down(Enum.KeyCode.A)then W=W-V.RightVector end
if down(Enum.KeyCode.E)then W=W+Vector3.yAxis end
if down(Enum.KeyCode.Q)then W=W-Vector3.yAxis end
if W.Magnitude>0 then P=P+W.Unit*(O or tonumber(aa.fcDef)or 50)*(down(Enum.KeyCode.LeftShift)and 3 or 1)*T end
U.CFrame=CFrame.new(P)*V
end)
end)
def({"unfreecam","unfc"},"","Leave the free camera","camera spectate detach cam",function()
z.disconnect"freecam"
pcall(function()l.ContextActionService:UnbindAction"KLOSAD_FC"end)
if ab.MouseBehavior==Enum.MouseBehavior.LockCurrentPosition then ab.MouseBehavior=Enum.MouseBehavior.Default end
local M,N=workspace.CurrentCamera,z.hum()
if M then
M.CameraType=Enum.CameraType.Custom
if N and not B.viewing then M.CameraSubject=N end
end
end)

def({"fly"},"[speed]","Fly with WASD, E up and Q down","flight air",function(M)
local N=z.val("fly",M)
local O,P=z.root(),z.hum()
if not(O and P)then return end
for Q,R in ipairs{"_flyBV","_flyBG"}do
local S=O:FindFirstChild(R)
if S then S:Destroy()end
end
local Q=Instance.new"BodyVelocity"
Q.MaxForce=Vector3.one*1e9;Q.Velocity=Vector3.zero;Q.Name="_flyBV"
local R=Instance.new"BodyGyro"
R.MaxTorque=Vector3.one*1e9;R.P=9e4;R.Name="_flyBG"
Q.Parent,R.Parent=O,O
P.PlatformStand=true
z.connect("fly",ac.RenderStepped,function()
if not Q.Parent then return z.Run"unfly"end
local S=workspace.CurrentCamera
local T=Vector3.zero
if down(Enum.KeyCode.W)then T=T+S.CFrame.LookVector end
if down(Enum.KeyCode.S)then T=T-S.CFrame.LookVector end
if down(Enum.KeyCode.D)then T=T+S.CFrame.RightVector end
if down(Enum.KeyCode.A)then T=T-S.CFrame.RightVector end
if down(Enum.KeyCode.E)then T=T+Vector3.yAxis end
if down(Enum.KeyCode.Q)then T=T-Vector3.yAxis end
Q.Velocity=T.Magnitude>0 and T.Unit*N or Vector3.zero
R.CFrame=S.CFrame
end)
end)
def({"unfly"},"","Stop flying","flight air",function()
z.disconnect"fly"
local M=z.root()
if M then
for N,O in ipairs{"_flyBV","_flyBG"}do
local P=M:FindFirstChild(O)
if P then P:Destroy()end
end
end
if z.hum()then z.hum().PlatformStand=false end
end)

def({"jesus"},"","Walk on water","water swim float",function()
if B.jesusPart then pcall(function()B.jesusPart:Destroy()end)end
local M=Instance.new"Part"
M.Name,M.Anchored,M.CanCollide,M.Transparency,M.Size="_jesus",true,false,1,Vector3.new(12,1,12)
M.Parent=workspace
B.jesusPart=M
local N
z.connect("jesus",ac.Heartbeat,function()
local O,P=z.root(),z.hum()
if not(O and P)then return end
if P:GetState()==Enum.HumanoidStateType.Swimming or P.FloorMaterial==Enum.Material.Water then
N=O.Position.Y-3.2
end
if N and O.Position.Y<N+12 then
M.CFrame=CFrame.new(O.Position.X,N,O.Position.Z)
M.CanCollide=true
else
M.CanCollide=false
if N and O.Position.Y>=N+12 then N=nil end
end
end)
end)
def({"unjesus"},"","Stop walking on water","water swim",function()
z.disconnect"jesus"
if B.jesusPart then B.jesusPart:Destroy();B.jesusPart=nil end
end)

def({"tpwalk","cwalk"},"[multiplier]","Move faster through CFrame (mode and cap in Module Cfg)","speed walkspeed fast",function(M)
local N=math.min(tonumber(M)or aa.tpDef,aa.tpCap)
z.connect("tpwalk",ac.Heartbeat,function(O)
local P,Q=z.root(),z.hum()
if not(P and Q)then return end
local R=Q.MoveDirection
if R.Magnitude>0 then
local S=(aa.tpMode=="Additive")and N or Q.WalkSpeed*(N-1)
P.CFrame=P.CFrame+R*S*O
end
end)
end)
def({"untpwalk","uncwalk"},"","Stop CFrame walking","speed walkspeed",function()z.disconnect"tpwalk"end)

def({"hheight","hipheight"},"[number]","Change your hip height","height ground",function(M)
if z.hum()then z.hum().HipHeight=tonumber(M)or B.defaults.hip end
end)

def({"follow"},"<player> [radius]","Follow a player and stay within a radius (jumps over obstacles)","walk chase",function(M,N)
local O=z.findPlayer(M)
if not O then return end
if tonumber(N)then B.lastRadius=tonumber(N)end
local P=B.lastRadius or aa.followRadius
z.connect("follow",ac.Heartbeat,function()
local Q,R=z.root(),z.hum()
local S=O.Character and O.Character:FindFirstChild"HumanoidRootPart"
if not(Q and R and S)then return end
local T=S.Position-Q.Position
local U=Vector3.new(T.X,0,T.Z)
if U.Magnitude>P then
R:MoveTo(S.Position-U.Unit*math.max(P-1,0))
local V=RaycastParams.new()
V.FilterType=Enum.RaycastFilterType.Exclude
V.FilterDescendantsInstances={z.char(),O.Character}
if workspace:Raycast(Q.Position-Vector3.new(0,1.5,0),U.Unit*3,V)then R.Jump=true end
end
end)
end)
def({"unfollow"},"","Stop following","walk chase",function()z.disconnect"follow"end)






local M={real=nil,root=nil,hist={},parts={},gm=nil,bound=nil,ping=0.1,pingT=0}
local function pingSec()
local N,O=pcall(function()return game:GetService"Stats".Network.ServerStatsItem["Data Ping"]:GetValue()end)
if N and tonumber(O)and O>0 then return O/1000 end
local P,Q=pcall(function()return A:GetNetworkPing()*2 end)
return P and tonumber(Q)or 0.1
end
local function histAt(N)
local O=M.hist
for P=#O,1,-1 do
if O[P][1]<=N then
local Q=O[P+1]
if Q then return O[P][2]:Lerp(Q[2],math.clamp((N-O[P][1])/math.max(Q[1]-O[P][1],1e-4),0,1))end
return O[P][2]
end
end
return O[1]and O[1][2]
end
local function ghostClear()
if M.gm then pcall(function()M.gm:Destroy()end)end
M.gm,M.parts=nil,{}
end
local function ghostBuild()
ghostClear()
local N=z.char()
if not N then return end
local O=Instance.new"Folder"
O.Name="_KLServerPos"
for P,Q in ipairs(N:GetChildren())do
if Q:IsA"BasePart"and Q.Name~="HumanoidRootPart"then
local R=Instance.new"Part"
R.Name,R.Size,R.Anchored,R.CanCollide,R.CanQuery,R.CanTouch,R.CastShadow=Q.Name,Q.Size,true,false,false,false,false
R.Material,R.Color,R.Transparency=Enum.Material.Neon,Color3.fromRGB(255,140,0),0.6
R.Parent=O
M.parts[#M.parts+1]={src=Q,g=R}
end
end
O.Parent=workspace
M.gm=O
end
local function syncStep()
local N=z.root()
if not N then return end
local O=os.clock()
local P=M.hist
P[#P+1]={O,N.CFrame}
while#P>2 and O-P[2][1]>1.5 do table.remove(P,1)end
if M.real then
if M.root==N then N.CFrame=M.real end
M.real=nil
end
if O-M.pingT>0.5 then M.pingT,M.ping=O,pingSec()end
if M.gm then
local Q=histAt(O-M.ping/2-0.03)
if not Q then return end
local R=(Q.Position-N.Position).Magnitude<math.clamp(tonumber(aa.srvHide)or 0.5,0,5)
for S,T in ipairs(M.parts)do
if R or not T.src.Parent then
T.g.Transparency=1
else
T.g.Transparency=0.6
T.g.CFrame=Q*N.CFrame:ToObjectSpace(T.src.CFrame)
end
end
end
end
local function syncBind(N)
if N and not M.bound then
M.bound=true
ac:BindToRenderStep("KLSync",Enum.RenderPriority.First.Value,syncStep)
elseif not N and M.bound then
M.bound=nil
pcall(function()ac:UnbindFromRenderStep"KLSync"end)
if M.real and M.root then pcall(function()M.root.CFrame=M.real end)end
M.real,M.hist=nil,{}
end
end
function M.shift(N,O,P)
M.real,M.root=O,N
N.CFrame=O+P
end
function z.srvApply(N)
if N then
ghostBuild()
z.connect("srvChar",A.CharacterAdded,function()
task.wait(1.5)
if aa.srvShow and l.alive then ghostBuild()end
end)
else
z.disconnect"srvChar"
ghostClear()
end
active("serverpos",N or nil)
syncBind(N or aa.predOn)
end
function z.srvRefresh()
local N=aa.srvShow==true
if N~=(M.gm~=nil)then z.srvApply(N)else syncBind(N or aa.predOn)end
end
function z.syncStop()z.srvApply(false);syncBind(false)end
def({"serverpos","showpos"},"","Show where the server has you (a ghost; hides when it is close to your position)","server position lag ping ghost desync",function()
aa.srvShow=true;save()
z.srvApply(true)
end)
def({"unserverpos","unshowpos"},"","Hide the server position ghost","server position lag ping ghost desync",function()
if l.alive then aa.srvShow=false;save()end
z.srvApply(false)
end)
if aa.predOn or aa.srvShow then task.defer(function()if aa.srvShow then z.srvApply(true)else syncBind(true)end end)end





local N={weld=nil,rep=nil}
local function weldClear()
if N.weld then pcall(function()N.weld:Destroy()end)end
N.weld=nil
local O=N.rep
N.rep=nil
if O and O.Parent and sethiddenproperty then
pcall(sethiddenproperty,O,"PhysicsRepRootPart",nil)
local P=c.InstanceHandle
if P and P.new then pcall(function()sethiddenproperty(O,"PhysicsRepRootRef",P.new(O))end)end
end
end
local function weldPre()
if N.weld then N.weld.Enabled=false end
end
local function weldPost(O,P,Q)
local R,S=Q=="rep"or Q=="both",Q=="weld"or Q=="both"
if S then
if not(N.weld and N.weld.Parent)then
local T=Instance.new"WeldConstraint"
T.Name="_KLAttachWeld"
T.Part0,T.Part1=O,P
T.Parent=O
N.weld=T
for U,V in ipairs(O.Parent:GetDescendants())do
if V:IsA"BasePart"then V.CanCollide=false end
end
end
N.weld.Part1=P
N.weld.Enabled=true
elseif N.weld then
pcall(function()N.weld:Destroy()end)
N.weld=nil
end
if R and sethiddenproperty then
pcall(sethiddenproperty,O,"PhysicsRepRootPart",P)
local T=c.InstanceHandle
if T and T.new then pcall(function()sethiddenproperty(O,"PhysicsRepRootRef",T.new(P))end)end
N.rep=O
elseif N.rep then
local T=N.weld
N.weld=nil
weldClear()
N.weld=T
end
end
local function detach()
z.disconnect"attach";z.disconnect"attachJump"
weldClear()
B.attach=nil
local O=z.hum()
if O then
O.Sit=false
if B.attachPS then
O.PlatformStand=false
O:ChangeState(Enum.HumanoidStateType.GettingUp)
local P=z.root()
if P then P.AssemblyLinearVelocity=Vector3.zero;P.AssemblyAngularVelocity=Vector3.zero end
end
end
B.attachPS=nil
end
local function attach(O,P,Q)
local R=z.findPlayer(P)
if not R or R==A then return end
detach()
B.attach=O
local S=O=="heada"or O=="backa"
B.attachPS=S or nil
local T=z.hum()
if T then
if S then T.PlatformStand=true else T.Sit=true end
end
local U,V,W=0,Vector3.zero
local X,Y,Z=0,Vector3.zero

local _
local ae={}
local function cfOf(af)
if not aa.attachRoot or not(_ and _.Parent)or af==_ then return af.CFrame end
local ag=ae[af]
if not ag then ag=_.CFrame:ToObjectSpace(af.CFrame);ae[af]=ag end
return _.CFrame*ag
end
z.connect("attach",S and ac.PreSimulation or ac.Heartbeat,function()
if not R.Parent then return z.Run"unattach"end
local af,ag=z.root(),R.Character
local ah=ag and(ag:FindFirstChild"UpperTorso"or ag:FindFirstChild"Torso"or ag:FindFirstChild"HumanoidRootPart")
if not(af and ah)then return end
_=ag:FindFirstChild"HumanoidRootPart"
local ai
if O=="backpack"then
ai=cfOf(ah)*CFrame.new(0,aa.bpHeight,tonumber(Q)or aa.bpDist)*CFrame.Angles(0,math.pi,0)
elseif O=="baby"then
ai=cfOf(ah)*CFrame.new(0,aa.babyHeight,-(tonumber(Q)or aa.babyDist))*CFrame.Angles(0,math.rad(180+aa.babyRot),0)*CFrame.Angles(math.rad(tonumber(aa.babyLean)or 0),0,0)
elseif S then
local aj=O=="heada"and"head"or"back"
local ak=tonumber(Q)or aa[aj.."Dist"]
if aa[aj.."Sweep"]then ak=math.max(0,ak+math.sin(os.clock()*aa[aj.."SweepSpeed"])*aa[aj.."SweepAmp"])end
local al=z.hum()
if al then al.PlatformStand=true end
for am,an in ipairs(af.Parent:GetDescendants())do
if an:IsA"BasePart"then an.CanCollide=false end
end
if O=="heada"then
ai=(ag:FindFirstChild"Head"or ah).CFrame*CFrame.new(aa.headSide,aa.headHeight,-ak)*CFrame.Angles(0,math.pi,0)
else
ai=cfOf(ah)*CFrame.new(aa.backSide,aa.backHeight,ak)
end
af.AssemblyAngularVelocity=Vector3.zero
else
local aj=ag:FindFirstChild"Head"or ah
ai=cfOf(aj)*CFrame.new(0,aj.Size.Y/2+(tonumber(Q)or 1.6),0)
end
local aj=aa.attachWeld
if aj=="off"then aj=nil end
if aj then weldPre()elseif N.weld or N.rep then weldClear()end
af.CFrame=ai

local ak,al=Vector3.zero
if aa.attachVel~=false then
al=ah.AssemblyAngularVelocity
if al.Magnitude>30 then al=al.Unit*30 end
ak=ah.AssemblyLinearVelocity+al:Cross(ai.Position-ah.Position)
if ak.Magnitude>100 then ak=ak.Unit*100 end
end

local am=tonumber(aa.attachLead)or 0
if am>0 and al then
local an=os.clock()
if Z and an>X then
Y=Y:Lerp((ak-Z)/(an-X),0.3)
if Y.Magnitude>200 then Y=Y.Unit*200 end
end
Z,X=ak,an
ak=ak+Y*math.min(am,0.5)
if ak.Magnitude>100 then ak=ak.Unit*100 end
end
af.AssemblyLinearVelocity=ak
if al then af.AssemblyAngularVelocity=al end
z.markMove()
if aj then weldPost(af,ag:FindFirstChild"HumanoidRootPart"or ah,aj)end
if aa.predOn and not aj then
local an,ao=os.clock(),ah.Position
if W and an>U then V=V:Lerp((ao-W)/(an-U),0.35)end
W,U=ao,an
local ap=V*(M.ping*(tonumber(aa.predMult)or 1))
if ap.Magnitude>30 then ap=ap.Unit*30 end
M.shift(af,ai,ap)
end
end)
z.connect("attachJump",ab.JumpRequest,detach)
end
def({"backpack","bp"},"<player> [offset]","Ride on a player's back (jump to detach)","carry piggyback attach",function(ae,af)attach("backpack",ae,af)end)
def({"baby"},"<player> [offset]","Sit in front of a player like a baby (jump to detach)","carry attach",function(ae,af)attach("baby",ae,af)end)
def({"headsit"},"<player>","Sit on a player's head (jump to detach)","attach head",function(ae)attach("headsit",ae)end)
def({"heada","headattach"},"<player> [distance]","Attach in front of a player's head, facing them (jump to detach)","attach head face",function(ae,af)attach("heada",ae,af)end)
def({"backa","backattach"},"<player> [distance]","Attach behind a player's back (jump to detach)","attach back carry",function(ae,af)attach("backa",ae,af)end)
def({"attachweld","aweld"},"[rep|weld|both|off]","Welds the attach commands (backpack, baby, headsit, heada, backa) to the target for less lag. On by default (rep). rep = replicate your root relative to theirs (needs sethiddenproperty), weld = local weld, both, off. No argument toggles on / off","attach backpack baby headsit heada backa lag latency weld replication",function(ae)
ae=(ae or""):lower()
if ae==""then ae=(aa.attachWeld~="off")and"off"or"rep"end
if ae=="on"then ae="rep"end
if ae=="off"or ae=="false"or ae=="0"then
ae="off"
elseif ae~="rep"and ae~="weld"and ae~="both"then
return z.notify"attachweld: rep, weld, both or off"
end
aa.attachWeld=ae
save()
if(ae=="rep"or ae=="both")and not sethiddenproperty then
z.notify("Attach weld: "..ae.." (this executor has no sethiddenproperty, so only the weld part can work)",5)
else
z.notify(ae~="off"and("Attach weld: "..ae.." (applies to the next attach, or right away if you are attached)")or"Attach weld off")
end
end)
def({"unattach"},"","Detach from a player","backpack baby headsit heada backa",detach)





do
local ae,af,ag,ah
local function finish(ai)
if not ae then return end
ae=nil;B.voiding=nil
if l.orgDestroyH then workspace.FallenPartsDestroyHeight=l.orgDestroyH end
local aj=z.root()
if ai and aj and aj==ag and af then
z.markMove()
aj.CFrame=af
aj.AssemblyLinearVelocity,aj.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
end
end
local function void(ai)
local aj,ak=z.root(),z.hum()
if not(aj and ak)or ak.Health<=0 then return end
if B.blink then return z.notify"Void: not while blink / ghost is on"end
if ae then return end
local al=math.clamp(tonumber(ai)or 1,0.1,5)
local am=workspace.FallenPartsDestroyHeight
if am==am then l.orgDestroyH=am end
local an=l.orgDestroyH
if not an or an<-1E5 then an=-500 end
af,ag=aj.CFrame,aj
local ao={}
ae=ao
B.voiding=true
workspace.FallenPartsDestroyHeight=0/0
z.markMove()
aj.CFrame=CFrame.new(0,an-25,0)
task.delay(al,function()
if ae~=ao then return end
local ap,O=z.root(),z.hum()
finish(l.alive and ap==aj and O and O.Health>0)
end)
end
function z.voidStop()ah=nil;finish(true)end
def({"void","fakeout"},"[seconds]","Fake out the server: switch the destroy height off, drop 25 studs under it for a second (default 1 s), then come back and switch it on again","server position exploiter desync fake fakeout",void)
def({"autovoid"},"[seconds between]","Void again every second (or the interval you give) until ;unautovoid","server position exploiter attached shake lose follow desync loop",function(ai,aj)
local ak,al=math.max(tonumber(ai)or 1,0.6),{}
ah=al
task.spawn(function()
while ah==al and l.alive do void(nil,aj);task.wait(ak)end
end)
end)
def({"unautovoid"},"","Stop the automatic void","server position exploiter attached shake desync",function()ah=nil end)
end
def({"config","cfg"},"","Open Module Cfg in the panel","module settings options values defaults",function()z.openTab"Module Cfg"end)



function z.eject()
local ae,af,ag=z.hum(),z.char(),z.root()
if not(ae and af)then return end
B.ejectAt=os.clock()
local function strip(ah)
if not ah then return end
for ai,aj in ipairs(ah:GetChildren())do
if aj:IsA"JointInstance"or aj:IsA"WeldConstraint"then
local ak,al=aj.Part0,aj.Part1
if ak and al and ak:IsDescendantOf(af)~=al:IsDescendantOf(af)then aj:Destroy()end
end
end
end
strip(ae.SeatPart);strip(ag)
ae.Sit=false
ae:ChangeState(Enum.HumanoidStateType.Jumping)
end
def({"sit"},"","Sit down","seat",function()
if B.active.antisit then return z.notify"Anti sit is on. Run unantisit first"end
B.allowSit=os.clock()
if z.hum()then z.hum().Sit=true end
end)
def({"unsit"},"","Stand up","seat",function()
B.allowSit=os.clock()
z.eject()
end)


def({"ragdoll","rag"},"","Go stiff and fall over until you press space or move (everyone sees it)","fall limp stiff plank physics",function()
local ae,af=z.hum(),z.root()
if not(ae and af)then return end
if B.ragdollStop then B.ragdollStop()end
ae.PlatformStand=true
ae:ChangeState(Enum.HumanoidStateType.Physics)
local ag=ae:FindFirstChildOfClass"Animator"
local ah={}
local function freeze()
if not ag then return end
for ai,aj in ipairs(ag:GetPlayingAnimationTracks())do
if ah[aj]==nil then ah[aj]=aj.Speed;pcall(function()aj:AdjustSpeed(0)end)end
end
end
freeze()
af.AssemblyAngularVelocity=af.CFrame.RightVector*2
if aa.ragdollBlock then
pcall(function()z.StarterGui:SetCore("ResetButtonCallback",false)end)
B.resetBlocked=true
end
local function stop()
z.disconnect"ragdoll";z.disconnect"ragdollJump"
for ai,aj in pairs(ah)do pcall(function()ai:AdjustSpeed(aj)end)end
local ai=z.hum()
if ai then ai.PlatformStand=false;ai:ChangeState(Enum.HumanoidStateType.GettingUp)end
if B.resetBlocked then
pcall(function()z.StarterGui:SetCore("ResetButtonCallback",true)end)
B.resetBlocked=nil
end
B.ragdollStop=nil
active("ragdoll",nil)
end
B.ragdollStop=stop
z.connect("ragdollJump",ab.JumpRequest,stop)
z.connect("ragdoll",ac.Heartbeat,function()
local ai=z.hum()
if not ai then return end
if ai.MoveDirection.Magnitude>0 then return stop()end
if not ai.PlatformStand then ai.PlatformStand=true end
if ai:GetState()~=Enum.HumanoidStateType.Physics then ai:ChangeState(Enum.HumanoidStateType.Physics)end
freeze()
end)
end)
def({"unragdoll","unrag"},"","Get up from ragdoll","fall limp stiff physics",function()if B.ragdollStop then B.ragdollStop()end end)




do
local ae
local function toward(af,ag,ah)
local ai=af:Lerp(ag,ah)
if ai.Magnitude<0.05 then ai=af:Cross(Vector3.xAxis);if ai.Magnitude<0.05 then ai=af:Cross(Vector3.zAxis)end end
return ai.Unit
end
local function stopSpider()
local af=ae
if not af then return end
ae=nil
z.disconnect"spiderBeat";z.disconnect"spiderJump"
pcall(function()ac:UnbindFromRenderStep"KLSpiderCam"end)
for ag,ah in ipairs(af.objs)do pcall(function()ah:Destroy()end)end
for ag,ah in ipairs(af.tracks)do pcall(function()ah:Stop(0.1)end)end
if af.animate and af.animate.Parent then af.animate.Disabled=false end
local ag,ah=z.hum(),z.root()
if ag then ag.AutoRotate=af.autoRotate;ag.PlatformStand=false;ag:ChangeState(Enum.HumanoidStateType.GettingUp)end
if ah then
local ai=Vector3.new(af.face.X,0,af.face.Z)
ai=ai.Magnitude>0.05 and ai.Unit or Vector3.new(0,0,-1)
local aj=ah.Position+Vector3.new(0,3,0)
ah.CFrame=CFrame.lookAt(aj,aj+ai)
ah.AssemblyLinearVelocity=Vector3.zero;ah.AssemblyAngularVelocity=Vector3.zero
end
active("spider",nil)
if af.ownSit then
local ai=B.noAct
B.noAct=true
pcall(z.Run,"unantisit")
B.noAct=ai
end
end
local function startSpider()
local af,ag,ah=z.hum(),z.char(),z.root()
if not(af and ag and ah)then return end
stopSpider()
local ai=workspace.CurrentCamera
local aj={up=Vector3.yAxis,dwell=0,fall=Vector3.zero,face=ah.CFrame.LookVector,objs={},tracks={},
air=0,jumpT=0,gT=0,fT=0,grounded=false,autoRotate=af.AutoRotate}
ae=aj
local ak=af.RigType==Enum.HumanoidRigType.R6 and 3 or(af.HipHeight+ah.Size.Y/2)

local al=Instance.new"Attachment";al.Name="_SpiderAtt";al.Parent=ah
local am=Instance.new"VectorForce"
am.Name,am.Attachment0,am.RelativeTo,am.ApplyAtCenterOfMass="_SpiderVF",al,Enum.ActuatorRelativeTo.World,true
am.Parent=ah
aj.objs={al,am}
local an=RaycastParams.new()
an.FilterType,an.RespectCanCollide,an.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,true,{ag}


local function lowWall(ao,ap,O,P,Q)
if not(Q and Q>0)then return end
local R=ao.Position+ap*0.35
R=R+O*(Q+0.05-(R-P):Dot(O))
local S=workspace:Raycast(R,-O*(Q+0.65),an)
if S and S.Normal:Dot(O)>0.7 then
local T=(S.Position-P):Dot(O)
if T>0.15 and T<=Q+0.05 then return T end
end
end

local ao,ap=af:FindFirstChildOfClass"Animator",ag:FindFirstChild"Animate"
local function load(O,P)
local Q=ap and ap:FindFirstChild(O)
local R=Q and Q:FindFirstChild(P)
if R and R:IsA"Animation"and ao then
local S,T=pcall(function()return ao:LoadAnimation(R)end)
if S and T then aj.tracks[#aj.tracks+1]=T;return T end
end
end
if ap and ao then
aj.animate=ap
ap.Disabled=true
for O,P in ipairs(ao:GetPlayingAnimationTracks())do P:Stop(0.1)end
end
local O,P,Q=load("walk","WalkAnim"),load("idle","Animation1"),load("fall","FallAnim")
local function setTrack(R)
if not R or aj.cur==R then return end
if aj.cur then aj.cur:Stop(0.15)end
aj.cur=R;R:Play(0.15)
end
local R
pcall(function()R=require(A.PlayerScripts:FindFirstChild"PlayerModule"):GetControls()end)
local function moveInput()
if R then
local S,T=pcall(function()return R:GetMoveVector()end)
if S and typeof(T)=="Vector3"then return T.X,-T.Z end
end
local S,T=0,0
if down(Enum.KeyCode.W)then T=T+1 end
if down(Enum.KeyCode.S)then T=T-1 end
if down(Enum.KeyCode.D)then S=S+1 end
if down(Enum.KeyCode.A)then S=S-1 end
return S,T
end
af:ChangeState(Enum.HumanoidStateType.Physics)
if not B.conns.antisit then
local S=B.noAct
B.noAct=true
pcall(z.Run,"nosit")
aj.ownSit=true
B.noAct=S
end
z.connect("spiderBeat",ac.PreSimulation,function(S)
local T,U=z.hum(),z.root()
if not(T and U and U.Parent==ag)then return stopSpider()end
S=math.min(S,0.1)
if T:GetState()~=Enum.HumanoidStateType.Physics then T:ChangeState(Enum.HumanoidStateType.Physics)end
T.AutoRotate=false
aj.fT=aj.fT-S
if aj.fT<=0 then
aj.fT=1
local V={ag}
for W,X in ipairs(ad:GetPlayers())do
if X~=A and X.Character then V[#V+1]=X.Character end
end
an.FilterDescendantsInstances=V
end
am.Force=Vector3.new(0,U.AssemblyMass*workspace.Gravity,0)
local V,W=U.Position,aj.up

local X,Y=moveInput()
local Z=ai.CFrame

local _,aq=Z.LookVector,Z.UpVector
local ar=(_-W*_:Dot(W))+(aq-W*aq:Dot(W))*math.abs(_:Dot(W))
for as,at in ipairs{aj.face,Vector3.xAxis,Vector3.zAxis}do
if ar.Magnitude>=0.05 then break end
ar=at-W*at:Dot(W)
end
ar=ar.Unit
local as=ar:Cross(W).Unit
local at=ar*Y+as*X
if at.Magnitude>1 then at=at.Unit end
local au=at.Magnitude>0.1

local av=workspace:Raycast(V,-W*(ak+1.5),an)
local aw,ax,ay,az
if aj.jumpT>0 then
aj.jumpT=aj.jumpT-S
av=nil
else
local aA=au and at.Unit
if aA then
local aB=math.max(4.5,ak+1.2)
for aC,aD in ipairs{0,-ak*0.5}do
local aE=workspace:Raycast(V+W*aD,aA*aB,an)
if aE and aj.dwell<=0 and math.abs(aE.Normal:Dot(W))<0.9 then if not lowWall(aE,aA,W,V-W*ak,aa.spWall)then aw,ax,ay=aE.Normal,true,aE;break end
end
end
end
if not av then av=workspace:Raycast(V-(aA or aj.face)*1.2,-W*(ak+1.5),an)end
if not aw and av then aw=av.Normal end
if not aw then
local aB=aA or aj.face
local aC=workspace:Raycast(V+aB*2.4-W*(ak+0.15),-aB*4.2,an)
if aC then
aw=aC.Normal
az,ay=aj.gT<0.4,aC
end
end
end
aj.dwell=aj.dwell-S
aj.gT=av and 0 or aj.gT+S

if aw and(not aj.want or aw:Dot(aj.want)<0.95)then aj.want,aj.dwell=aw,0.12 end
if aw then
aj.air=0
aj.up=toward(aj.up,aw,1-math.exp(-((ax or az)and 14 or 8)*S))
else
aj.air=aj.air+S
if aj.air>0.6 then aj.up=toward(aj.up,Vector3.yAxis,1-math.exp(-3*S))end
end
W=aj.up
local aA=at.Magnitude
at=at-W*at:Dot(W)
if aA>0 and at.Magnitude>0.25*aA then at=at.Unit*aA end

local aB
if av then
aj.fall=Vector3.zero
aB=W*math.clamp((ak-av.Distance)*14,-30,30)
else
if az then
aj.fall=(ay.Position+aw*ak-V)*12
if aj.fall.Magnitude>40 then aj.fall=aj.fall.Unit*40 end
else aj.fall=aj.fall-W*workspace.Gravity*S end
aB=aj.fall
end
aj.grounded=av~=nil
U.AssemblyLinearVelocity=at*T.WalkSpeed+aB

local aC=au and at.Unit or aj.face
aC=aC-W*aC:Dot(W)
if aC.Magnitude<0.05 then aC=ar end
aC=aC.Unit
aj.face=aC
local aD=CFrame.fromMatrix(Vector3.zero,aC:Cross(W).Unit,W,-aC)
U.CFrame=CFrame.new(V)*U.CFrame.Rotation:Lerp(aD,1-math.exp(-12*S))
U.AssemblyAngularVelocity=Vector3.zero
if not aj.grounded and aj.air>0.25 and Q then setTrack(Q)
elseif au and aj.grounded and O then setTrack(O);O:AdjustSpeed(T.WalkSpeed/14.5)
else setTrack(P)end
end)
z.connect("spiderJump",ab.JumpRequest,function()
local aq=z.hum()
if aq and(aj.grounded or aj.air<0.15)then
local ar=aq.UseJumpPower and aq.JumpPower or math.sqrt(2*workspace.Gravity*aq.JumpHeight)
aj.fall,aj.jumpT,aj.grounded=aj.up*ar,0.25,false
end
end)

end
def({"spider","wallwalk"},"","Walk on walls, ceilings and slopes like Spider-Man (jump leaps off the surface)","wall climb ceiling gravity surface walk",startSpider)
def({"unspider","unwallwalk"},"","Stop walking on walls","wall climb ceiling gravity surface walk",stopSpider)
end

def({"spin"},"<rotations per second>","Spin your character (with fling prevention)","rotate turn",function(ae)
local af=z.val("spin",ae)
local ag=z.hum()
if ag then ag.AutoRotate=false end
z.connect("spin",ac.Heartbeat,function(ah)
local ai=z.root()
if not ai then return end
ai.CFrame=ai.CFrame*CFrame.Angles(0,af*2*math.pi*ah,0)
ai.AssemblyAngularVelocity=Vector3.zero
local aj=ai.AssemblyLinearVelocity
if Vector3.new(aj.X,0,aj.Z).Magnitude>120 then ai.AssemblyLinearVelocity=Vector3.new(0,aj.Y,0)end
end)
end)
def({"unspin"},"","Stop spinning","rotate turn",function()
z.disconnect"spin"
if z.hum()then z.hum().AutoRotate=true end
end)


do
local ae
def({"ptp","pulsetp"},"<player> [seconds]","Pulse teleport: go to a player for a moment (default 1 s), then back to where you were","teleport pulse return",function(af,ag)
if ae and os.clock()-ae<31 then return z.notify"Pulse teleport is already running"end
local ah,ai=z.findPlayer(af),z.root()
if not(ah and ai)then return end
if not(ah.Character and ah.Character:FindFirstChild"HumanoidRootPart")then return z.notify(ah.Name.." has no character")end
local aj=math.clamp(tonumber(ag)or 1,0,30)
local ak,al=ai.CFrame,os.clock()
ae=al
repeat
local am=ah.Character and ah.Character:FindFirstChild"HumanoidRootPart"
if not(am and ai.Parent)then break end
z.markMove()
ai.CFrame=am.CFrame
ac.Heartbeat:Wait()
until os.clock()-al>=aj or not l.alive
ae=nil
if ai.Parent then z.markMove();ai.CFrame=ak;ai.AssemblyLinearVelocity=Vector3.zero end
end)
end


do
local function live(ae)
local af=ae.Character
local ag,ah=af and af:FindFirstChildOfClass"Humanoid",af and af:FindFirstChild"HumanoidRootPart"
if ag and ah and ag.Health>0 then return ah,af end
end
local function seen(ae,af,ag)
local ah=RaycastParams.new()
ah.FilterType=Enum.RaycastFilterType.Exclude
ah.FilterDescendantsInstances={z.char(),ag}
return workspace:Raycast(ae,af.Position-ae,ah)==nil
end
local function pick(ae,af)
local ag={}
for ah,ai in ipairs(ad:GetPlayers())do
local aj,ak=live(ai)
if ai~=A and aj then ag[#ag+1]={r=aj,c=ak,d=(aj.Position-af).Magnitude}end
end
table.sort(ag,function(ah,ai)if ae=="far"then return ah.d>ai.d end return ah.d<ai.d end)
for ah,ai in ipairs(ag)do
if ae~="inwall"or seen(af,ai.r,ai.c)then return ai.r end
end
end
def({"look","lookat"},"<player | near | far | inwall>","Face a player without moving the camera (near / far = nearest / farthest, inwall = nearest one not behind a wall)","aim face turn lock aimbot",function(ae)
local af,ag=(tostring(ae or""):lower())
if af~="near"and af~="far"and af~="inwall"then
if not ae then return z.notify"look <player | near | far | inwall>"end
ag=z.findPlayer(ae)
if not ag then return end
end
local ah,ai
z.connect("look",ac.Heartbeat,function()
local aj,ak=z.root(),z.hum()
if not(aj and ak)then return end
if ag then
ah=live(ag)
elseif not(ah and ah.Parent)or os.clock()>=(ai or 0)then
ai=os.clock()+0.1
ah=pick(af,aj.Position)
end
ak.AutoRotate=ah==nil
if not ah then return end
local al=ah.Position-aj.Position
al=Vector3.new(al.X,0,al.Z)
if al.Magnitude<0.05 then return end
aj.CFrame=CFrame.lookAt(aj.Position,aj.Position+al)
aj.AssemblyAngularVelocity=Vector3.zero
end)
end)
def({"unlook","unlookat"},"","Stop looking at a player","aim face turn lock aimbot",function()
z.disconnect"look"
local ae=z.hum()
if ae then ae.AutoRotate=true end
end)
end




do
local ae={idle=1,walk=1,run=1,jump=1,fall=1,climb=1,sit=1,swim=1,swimidle=1,toolnone=1,toolslash=1,toollunge=1,mood=1}
local af,ag,ah,ai,aj,ak=0,0,0
local al=setmetatable({},{__mode="k"})
local function emoteLike(am)
local an,ao=am.Animation,A.Character and A.Character:FindFirstChild"Animate"
return not(an and ao and an:IsDescendantOf(ao)and an.Parent and ae[an.Parent.Name:lower()])
end
local am=0
local function take(an,ao)
if ai~=an then
local ap=ai
ai,af=an,0

if ap and not ao and ap.IsPlaying then pcall(function()ap:Stop(0.1)end)end
end
pcall(function()an.Priority=Enum.AnimationPriority.Action4 end)
end
local function unhook()
local an=aj
aj=nil
if an and an.bf.Parent then pcall(function()an.bf.OnInvoke=an.orig end)end
end
local function playHere(an,ao)
local ap
if typeof(ao)=="Instance"and ao:IsA"Animation"then ap=ao
elseif type(ao)=="string"then local aq=an:FindFirstChild(ao);ap=aq and aq:FindFirstChildOfClass"Animation"end
local aq=z.hum()
local ar=aq and aq:FindFirstChildOfClass"Animator"
if not(ap and ar)then return false end
local as,at=pcall(function()return ar:LoadAnimation(ap)end)
if not(as and at)then return false end
take(at);at:Play(0.1)
return true,at
end
local function attach()
ag=ag+1
local an=ag
unhook()
ai=nil
local ao=A.Character
local ap=ao and ao:WaitForChild("Humanoid",5)
local aq=ap and ap:WaitForChild("Animator",5)
if not aq or A.Character~=ao or an~=ag then return end
ak=aq
z.connect("kemotePlay",aq.AnimationPlayed,function(ar)if emoteLike(ar)then take(ar)end end)
for ar,as in ipairs(aq:GetPlayingAnimationTracks())do if emoteLike(as)then take(as,true)end end

local ar=ao:WaitForChild("Animate",10)
local as=ar and ar:WaitForChild("PlayEmote",10)
if not as or an~=ag then return end
local at
for au=1,40 do
local av,aw=pcall(getcallbackmember,as,"OnInvoke")
if not av then return end
if aw then at=aw;break end
task.wait(0.15)
if an~=ag or not as.Parent then return end
end
if not at or an~=ag then return end
while al[at]do at=al[at]end
local function hk(au)
local av,aw,ax=pcall(at,au)
if av and aw then return aw,ax end
return playHere(ar,au)
end
al[hk]=at
aj={bf=as,orig=at}
as.OnInvoke=hk
end
def({"keepemotes","kemote"},"","Keep emotes / animations playing while you move, jump, fall or sit; default emotes also start mid air (;unkemote to stop)","emote animation dance keep uninterrupted air anywher",function()
z.connect("kemoteChar",A.CharacterAdded,function()task.spawn(attach)end)
z.connect("kemote",ac.Heartbeat,function()
local an=z.hum()
local ao=os.clock()
if ao-ah>=1 then
ah=ao
local ap=an and an:FindFirstChildOfClass"Animator"
if ap and ap~=ak then ak=ap;task.spawn(attach)end
end
local ap=ai
if not ap then return end
if not an or an.Health<=0 then ai=nil;return end
if an.MoveDirection.Magnitude>0.05 or an.FloorMaterial==Enum.Material.Air or an.Sit then am=ao end
if ap.IsPlaying then af=ap.TimePosition;return end
local aq=ap.Length
if aq>0 and not ap.Looped and af>=aq-0.25 then ai=nil;return end

if ao-am>0.4 then ai=nil;return end
local ar=af
pcall(function()ap:Play(0.1);if ar>0 then ap.TimePosition=ar end end)
end)
task.spawn(attach)
end)
def({"unkeepemotes","unkemote"},"","Stop keeping animations (the one playing now is stopped)","emote animation dance keep uninterrupted",function()
for an,ao in ipairs{"kemote","kemoteChar","kemotePlay"}do z.disconnect(ao)end
ag,ak=ag+1,nil
unhook()
local an=ai
ai=nil
if an then pcall(function()an:Stop(0.1)end)end
end)
end


def({"speed","walkspeed","ws"},"[n]","Set walk speed (default and multiplier in Module Cfg)","run fast",function(ae)
if z.hum()then z.hum().WalkSpeed=z.val("speed",ae)end
end)
def({"jumppower","jp"},"[n]","Set jump power (default and multiplier in Module Cfg)","jump height",function(ae)
local af=z.hum()
if not af then return end
af.UseJumpPower=true
af.JumpPower=z.val("jp",ae)
end)
def({"goto","tp"},"<player>","Teleport to a player","teleport move",function(ae)
local af=z.findPlayer(ae)
local ag=af and z.reach(af)
if ag and z.root()then z.markMove();z.root().CFrame=ag.CFrame*CFrame.new(0,0,3);z.unpark(false)end
end)
def({"tpto"},"<x> <y> <z>","Teleport to coordinates","teleport position",function(ae,af,ag)
if z.root()then z.markMove();z.root().CFrame=CFrame.new(tonumber(ae)or 0,tonumber(af)or 0,tonumber(ag)or 0)end
end)



def({"antiexploit","ae"},"[distance] [height] [seconds]","Shake off an exploiter who is attached to you: fly 100000 studs away and 10000 up (fast, but smooth enough that they follow), then snap back to where you were. About 2.5 seconds in all","attach attached exploiter shake lose follow backpack headsit fling",function(ae,af,ag)
local ah=B.aeReset;B.aeReset=nil
local ai,aj=z.root(),z.hum()
if not(ai and aj)or aj.Health<=0 then return end
if B.antiExploit then return z.notify"Anti exploit is already running"end
local ak=math.clamp(tonumber(ae)or 100000,1000,1000000)
local al=math.clamp(tonumber(af)or 10000,0,200000)
local am=math.clamp(tonumber(ag)or 2,0.6,6)
local an=0.5
local ao=ai.CFrame
local ap=Vector3.new(ao.LookVector.X,0,ao.LookVector.Z)
ap=ap.Magnitude>0.01 and ap.Unit or Vector3.new(1,0,0)
local aq=ao-ao.Position
local ar=ap*ak+Vector3.new(0,al,0)
local as=os.clock()
B.antiExploit=true
z.notify("Anti exploit: moving away...",1.5)
local function finish(at)
z.disconnect"antiexploit"
B.antiExploit=nil
if at=="reset"then
local au=z.hum()
local av
av=A.CharacterAdded:Connect(function(aw)
av:Disconnect()
local ax=aw:WaitForChild("HumanoidRootPart",10)
for ay=1,10 do
if not(ax and ax.Parent)then break end
z.markMove();ax.CFrame=ao
ac.Heartbeat:Wait()
end
end)
task.delay(15,function()av:Disconnect()end)
z.unpark(false)
if au then au.Health=0 end
return
end
local au=z.root()
if au then
if at then z.markMove();au.CFrame=ao end
au.AssemblyLinearVelocity,au.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
end
z.unpark(false)
end
z.connect("antiexploit",ac.PreSimulation,function()
local at,au=z.root(),z.hum()
if not(at and au)or au.Health<=0 or not l.alive then return finish(false)end
local av=os.clock()-as
if av>=am+an then return finish(ah and"reset"or true)end
z.markMove()
at.CFrame=CFrame.new(ao.Position+ar*math.min(av/am,1))*aq
at.AssemblyLinearVelocity,at.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
end)
end)
def({"aer","antiexploitreset"},"[distance] [height] [seconds]","Anti exploit, but you reset at the far end and are teleported back to where you were once you respawn","attach attached exploiter shake lose follow backpack headsit fling reset respawn",function(...)
B.aeReset=true
z.Commands.antiexploit(...)
end)
def({"mousetp","mtp"},"","Teleport to where your mouse points (bind it to a key)","teleport cursor click",function()
local ae,af,ag=z.root(),z.char(),workspace.CurrentCamera
if not(ae and af and ag)then return end
local ah=ab:GetMouseLocation()
local ai=ag:ViewportPointToRay(ah.X,ah.Y)
local aj=RaycastParams.new()
aj.FilterType=Enum.RaycastFilterType.Exclude
aj.FilterDescendantsInstances={af}
local ak=workspace:Raycast(ai.Origin,ai.Direction*2000,aj)
if not ak then return z.notify"Nothing under the mouse"end
z.markMove()
ae.CFrame=CFrame.new(ak.Position+Vector3.new(0,3,0))*(ae.CFrame-ae.CFrame.Position)
end)
def({"freeze"},"","Anchor your character","stop lock",function()
B.selfFrozen=true
if z.root()then z.root().Anchored=true end
end)
def({"thaw","unfreeze"},"","Unanchor your character","stop lock",function()
B.selfFrozen=nil
if z.root()then z.root().Anchored=false end
end)

def({"infjump"},"","Jump again in mid-air","infinite air",function()
z.connect("infjump",ab.JumpRequest,function()
local ae,af=z.root(),z.hum()
if not(ae and af)then return end
local ag=af.UseJumpPower and af.JumpPower or math.sqrt(2*workspace.Gravity*af.JumpHeight)
local ah=ae.AssemblyLinearVelocity
ae.AssemblyLinearVelocity=Vector3.new(ah.X,ag,ah.Z)
end)
end)

do
local ae,af=0

function z.lockFps(ag)
af=ag
local ah=(tonumber(c.KLOSAD_FPSGEN)or 0)+1
c.KLOSAD_FPSGEN=ah
z.disconnect"fpsLock";z.disconnect"fpsFocus"
if not ag then return end
pcall(setfpscap,ag)
z.connect("fpsLock",ac.Heartbeat,function()
if c.KLOSAD_FPSGEN~=ah then z.disconnect"fpsLock";z.disconnect"fpsFocus";return end
local ai=os.clock()
if ai-ae<1 then return end
ae=ai
if getfpscap then
local aj,ak=pcall(getfpscap)
if aj and type(ak)=="number"and math.abs(ak-af)<0.5 then return end
end
pcall(setfpscap,af)
end)
z.connect("fpsFocus",ab.WindowFocused,function()
if c.KLOSAD_FPSGEN==ah then pcall(setfpscap,af)end
end)
end
end
def({"fpscap","fps","fpsmax"},"[number|off]","Cap the frame rate (default 60, stays locked; off removes it)","frame rate performance",function(ae)
if not setfpscap then return z.notify"This executor has no setfpscap"end
local af=ae and tostring(ae):lower()
if af=="off"or af=="unlock"then
z.lockFps(nil);pcall(setfpscap,0)
return z.notify"FPS cap removed"
end
z.lockFps(tonumber(ae)or 60)
end)


local function setNoCollide(ae,af)
for ag,ah in ipairs(ae:GetDescendants())do
if ah:IsA"BasePart"then
if af then
if B.cc[ah]==nil then B.cc[ah]=ah.CanCollide end
ah.CanCollide=false
elseif B.cc[ah]~=nil then
ah.CanCollide=B.cc[ah]
B.cc[ah]=nil
end
end
end
end

def({"antifling","af"},"[radius] [threshold] [restore time]","Turn off collision with fast-moving players until they calm down","fling protect safe collision",function(ae,af,ag)
local ah,ai,aj=tonumber(ae)or aa.afRadius,tonumber(af)or aa.afThreshold,tonumber(ag)or aa.afRestore
for ak in pairs(B.afFlagged or{})do if ak.Character then setNoCollide(ak.Character,false)end end
local ak={}
B.afFlagged=ak
z.connect("antifling",ac.Stepped,function()
local al=z.root()
if not al then return end
local am=os.clock()
for an,ao in ipairs(ad:GetPlayers())do
local ap=ao.Character
local aq=ap and ap:FindFirstChild"HumanoidRootPart"
if ao~=A and aq then
local ar=aq.AssemblyLinearVelocity.Magnitude>ai or aq.AssemblyAngularVelocity.Magnitude>ai/3
if ar and(aq.Position-al.Position).Magnitude<=ah then
if not ak[ao]then dnotify("af","Anti fling: "..ao.DisplayName.." is moving fast")end
ak[ao]=am
end
if ak[ao]then
if am-ak[ao]>aj then
ak[ao]=nil
setNoCollide(ap,false)
else
setNoCollide(ap,true)
end
end
end
end
end)
end)
def({"unantifling","unaf"},"","Turn anti fling off","fling protect",function()
z.disconnect"antifling"
for ae in pairs(B.afFlagged or{})do
if ae.Character then setNoCollide(ae.Character,false)end
end
B.afFlagged={}
end)

def({"antisit","nosit"},"","Stop forced sitting: seats can't seat you (No Sit component)","seat lock",function()
if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup)end
local ae
for af,ag in ipairs(h)do
if ag.name=="No Sit"then ae=ag.url end
end
local af=ae and z.fetch(ae)
if af then
local ag=q and loadstring(af)
if ag and pcall(ag)then B.noSitComponent=true end
end

if not B.noSitComponent then z.notify"No Sit component unavailable, using the built-in version"end
z.connect("antisit",ac.Heartbeat,function()
local ag=z.hum()
if not ag then return end
if(ag.Sit or ag.SeatPart)and not B.attach and not(B.allowSit and os.clock()-B.allowSit<1.5)
and os.clock()-(B.ejectAt or 0)>0.4 then
z.eject()
dnotify("sit","Anti sit: stood you back up")
end
end)
end)
def({"unantisit","unnosit"},"","Turn anti sit off","seat lock",function()
if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup)end
B.noSitComponent=nil
z.disconnect"antisit"
end)

def({"antivoid"},"[height]","Catch you before the void and put you back on safe ground","fall void teleport safe",function(ae)
local af=tonumber(ae)or aa.avHeight
local ag
z.connect("antivoid",ac.Heartbeat,function()
local ah,ai=z.root(),z.hum()
if not(ah and ai)then return end
if ai.FloorMaterial~=Enum.Material.Air then ag=ah.CFrame end
local aj=workspace.FallenPartsDestroyHeight
if aj<-1E5 then aj=-500 end
if ag and not B.voiding and ah.Position.Y<aj+af then
z.markMove()
ah.CFrame=ag+Vector3.new(0,3,0)
ah.AssemblyLinearVelocity=Vector3.zero
dnotify("void","Anti void: put you back")
end
end)
end)
def({"unantivoid"},"","Turn anti void off","fall void safe",function()z.disconnect"antivoid"end)

def({"antiteleport","antitp"},"[min distance]","Revert sudden position changes you didn't cause","teleport safe lock",function(ae)
local af,ag,ah=tonumber(ae)or aa.atpMin
z.connect("antiteleport",ac.Heartbeat,function()
local ai=z.root()
if not ai then ag=nil;return end
if ai~=ah then ah,ag=ai,nil end
local aj=ai.Position
if ag and(aj-ag).Magnitude>af and not(B.selfMove and os.clock()-B.selfMove<0.6)then
ai.CFrame=CFrame.new(ag)*(ai.CFrame-ai.CFrame.Position)
dnotify("tp","Anti teleport: reverted a move")
else
ag=aj
end
end)
end)
def({"unantiteleport","unantitp"},"","Turn anti teleport off","teleport safe",function()z.disconnect"antiteleport"end)

def({"antiknockback","antipush"},"[max speed]","Clamp your velocity so pushes and explosions don't launch you","push launch fling safe",function(ae)
local af=tonumber(ae)or aa.akMax
z.connect("antiknockback",ac.Heartbeat,function()
local ag=z.root()
if not ag or B.active.fly or B.active.cfly or B.attach then return end
local ah=ag.AssemblyLinearVelocity
local ai=Vector3.new(ah.X,0,ah.Z)
local aj=math.clamp(ah.Y,-300,af)
if ai.Magnitude>af or aj~=ah.Y then
ag.AssemblyLinearVelocity=(ai.Magnitude>af and ai.Unit*af or ai)+Vector3.new(0,aj,0)
end
end)
end)
def({"unantiknockback","unantipush"},"","Turn anti knockback off","push launch safe",function()z.disconnect"antiknockback"end)

def({"antiattach"},"","Stop players welded or attached to you from moving you","carry headsit weld safe collision",function()
for ae in pairs(B.aaFlagged or{})do if ae.Character then setNoCollide(ae.Character,false)end end
local ae,af={},0
B.aaFlagged=ae
local function joined(ag,ah)
for ai,aj in ipairs(ag:GetDescendants())do
if aj:IsA"JointInstance"or aj:IsA"WeldConstraint"then
local ak,al=aj.Part0,aj.Part1
if(ak and ak:IsDescendantOf(ah))or(al and al:IsDescendantOf(ah))then return true end
end
end
return false
end
z.connect("antiattach",ac.Heartbeat,function(ag)
af=af+ag
if af<0.2 then return end
af=0
local ah=z.char()
if not ah then return end
for ai,aj in ipairs(ad:GetPlayers())do
local ak=aj.Character
if aj~=A and ak then
if joined(ak,ah)or joined(ah,ak)then
if not ae[aj]then dnotify("aa","Anti attach: "..aj.DisplayName)end
ae[aj]=true
elseif ae[aj]then
ae[aj]=nil
setNoCollide(ak,false)
end
end
end
end)
z.connect("antiattachStep",ac.Stepped,function()
for ag in pairs(ae)do
if ag.Character then setNoCollide(ag.Character,true)end
end
end)
end)
def({"unantiattach"},"","Turn anti attach off","carry headsit weld safe",function()
z.disconnect"antiattach";z.disconnect"antiattachStep"
for ae in pairs(B.aaFlagged or{})do
if ae.Character then setNoCollide(ae.Character,false)end
end
B.aaFlagged={}
end)

def({"antiearrape","antiloud"},"[threshold] [duration]","Lower sounds that spike past a loudness threshold (RMS)","voice vc audio loud volume sound mute",function(ae,af)
local ag,ah=tonumber(ae)or aa.aeThreshold,tonumber(af)or aa.aeDuration
local ai,aj,ak={},{},0
B.aeOrig=B.aeOrig or{}
local al=B.aeOrig
z.connect("antiearrape",ac.Heartbeat,function(am)
ak=ak-am
if ak<=0 then
ak=3
ai={}
for an,ao in ipairs(workspace:GetDescendants())do
if ao:IsA"Sound"then ai[#ai+1]=ao end
end
pcall(function()
for an,ao in ipairs(l.SoundService:GetDescendants())do
if ao:IsA"Sound"then ai[#ai+1]=ao end
end
end)
end
for an,ao in ipairs(ai)do
if ao.Parent and ao.IsPlaying then
local ap=aj[ao]
if not ap then ap={sum=0,n=0,t=0};aj[ao]=ap end
local aq=ao.PlaybackLoudness
ap.sum,ap.n,ap.t=ap.sum+aq*aq,ap.n+1,ap.t+am
if ap.t>=ah then
local ar=(al[ao]and ao.Volume>0)and(al[ao]/ao.Volume)or 1
local as=math.sqrt(ap.sum/math.max(ap.n,1))*ar
if as>ag then
if al[ao]==nil then al[ao]=ao.Volume end
ao.Volume=al[ao]*0.15
dnotify("ear","Anti ear rape: lowered a loud sound")
elseif al[ao]~=nil then
ao.Volume=al[ao]
al[ao]=nil
end
aj[ao]=nil
end
end
end
end)
end)
def({"unantiearrape","unantiloud"},"","Turn anti ear rape off and restore volumes","voice vc audio loud volume sound",function()
z.disconnect"antiearrape"
for ae,af in pairs(B.aeOrig or{})do
if ae.Parent then ae.Volume=af end
end
B.aeOrig={}
end)

local ae={blur="BlurEffect",color="ColorCorrectionEffect",bloom="BloomEffect",dof="DepthOfFieldEffect",sunrays="SunRaysEffect"}
def({"antiblur","antieffects"},"[blur|color|bloom|dof|sunrays|all]","Strip blur and screen effects from your camera and lighting","screen effects visual",function(af)
af=(af or"all"):lower()
B.abOff=B.abOff or{}
local ag=B.abOff
local function kill(ah)
if ah.Name=="KLOSAD_Blur"then return end
for ai,aj in pairs(ae)do
if(af=="all"or af==ai)and ah:IsA(aj)then
if ag[ah]==nil then ag[ah]=ah.Enabled end
pcall(function()ah.Enabled=false end)
end
end
end
for ah,ai in ipairs(z.Lighting:GetDescendants())do kill(ai)end
for ah,ai in ipairs(workspace.CurrentCamera:GetDescendants())do kill(ai)end
z.connect("antiblurL",z.Lighting.DescendantAdded,kill)
z.connect("antiblurC",workspace.CurrentCamera.DescendantAdded,kill)
z.connect("antiblur",ac.Heartbeat,function()
for ah in pairs(ag)do
if ah.Parent and ah.Enabled then ah.Enabled=false end
end
end)
end)
def({"unantiblur","unantieffects"},"","Turn anti blur off and bring the effects back","screen effects visual",function()
z.disconnect"antiblur";z.disconnect"antiblurL";z.disconnect"antiblurC"
for af,ag in pairs(B.abOff or{})do
if af.Parent then pcall(function()af.Enabled=ag end)end
end
B.abOff={}
end)

def({"antiafk"},"[interval]","Stop the idle kick by simulating input","idle kick afk",function(af)
local ag,ah=tonumber(af)or aa.afkInterval,0
local function poke()
pcall(function()
local ai=game:GetService"VirtualUser"
ai:CaptureController()
ai:ClickButton2(Vector2.new())
end)
end
z.connect("antiafk",A.Idled,poke)
z.connect("antiafkTick",ac.Heartbeat,function(ai)
ah=ah+ai
if ah>=ag then ah=0;poke()end
end)
end)
def({"unantiafk"},"","Turn anti afk off","idle kick afk",function()z.disconnect"antiafk";z.disconnect"antiafkTick"end)

def({"antispam","antichatspam"},"[messages per interval]","Hide chat from players who repeat messages too fast","chat spam flood mute",function(af)
z.hookChat()
B.chat.spam,B.chat.spamN=true,tonumber(af)or aa.spamCount
end)
def({"unantispam","unantichatspam"},"","Turn anti spam off","chat spam flood",function()
if B.chat then B.chat.spam=false;B.chat.hist={}end
end)

def({"antifreeze"},"","Un-anchor yourself if something locks you in place","anchor stuck lock",function()
z.connect("antifreeze",ac.Heartbeat,function()
local af=z.root()
if af and af.Anchored and not B.selfFrozen and not B.blink and not B.parked then
af.Anchored=false
dnotify("freeze","Anti freeze: un-anchored you")
end
end)
end)
def({"unantifreeze"},"","Turn anti freeze off","anchor stuck lock",function()z.disconnect"antifreeze"end)






do
local af
local function get(ag,ah)
local ai,aj=pcall(function()return ag[ah]end)
if ai then return aj end
if gethiddenproperty then
local ak,al=pcall(gethiddenproperty,ag,ah)
if ak then return al end
end
end
local function set(ag,ah,ai)
if pcall(function()ag[ah]=ai end)and get(ag,ah)==ai then return true end
if sethiddenproperty then return pcall(sethiddenproperty,ag,ah,ai)end
return false
end
local function unpause()
if get(A,"GameplayPaused")then
pcall(function()if setthreadidentity then setthreadidentity(8)end end)
set(A,"GameplayPaused",false)
dnotify("pause","Anti gameplay paused: un-paused you")
end
end
def({"antigameplaypaused","antipause"},"","Stop the game from pausing you (the \"gameplay paused\" state when streaming can't keep up)","pause paused streaming freeze stuck lag loading gameplay",function()
if af==nil then af=get(workspace,"StreamingIntegrityMode")or false end
set(workspace,"StreamingIntegrityMode",Enum.StreamingIntegrityMode.Disabled)
pcall(function()l.GuiService:SetGameplayPausedNotificationEnabled(false)end)

z.connect("antipause",ac.Heartbeat,unpause)
z.connect("antipauseR",ac.RenderStepped,unpause)
z.connect("antipauseS",ac.Stepped,unpause)
pcall(function()z.connect("antipauseC",A:GetPropertyChangedSignal"GameplayPaused",unpause)end)
unpause()

z.notify(("Anti pause on. Player.GameplayPaused: %s. StreamingIntegrityMode: %s (%s)"):format(tostring(get(A,"GameplayPaused")),tostring(get(workspace,"StreamingIntegrityMode")),
get(workspace,"StreamingIntegrityMode")==Enum.StreamingIntegrityMode.Disabled and"set to Disabled"or"could not be changed"),8)
end)
def({"unantigameplaypaused","unantipause"},"","Turn anti gameplay paused off","pause paused streaming gameplay",function()
for ag,ah in ipairs{"antipause","antipauseR","antipauseS","antipauseC"}do z.disconnect(ah)end
pcall(function()l.GuiService:SetGameplayPausedNotificationEnabled(true)end)
if af then set(workspace,"StreamingIntegrityMode",af)end
af=nil
end)
end














local function resetHook(af)
if B.blinkReset then pcall(function()B.blinkReset:Destroy()end);B.blinkReset=nil end
if not af then
if not B.resetBlocked then pcall(function()z.StarterGui:SetCore("ResetButtonCallback",true)end)end
return
end
pcall(function()
local ag=Instance.new"BindableEvent"
B.blinkReset=ag
ag.Event:Connect(function()
local ah=B.blink
local ai=ah and ah.real
if ah then pcall(z.Run,"unblink")end
resetHook(false)
local aj=(ai and ai.Parent and ai:FindFirstChildOfClass"Humanoid")or z.hum()
if aj then aj.Health=0 end
end)
z.StarterGui:SetCore("ResetButtonCallback",ag)
end)
end

local af={"blinkDeath","blinkChar","blinkNC","blinkGuard","blinkMove","blinkJump","blinkAnim"}
local ag={"blinkLockPre","blinkLockStep","blinkLockJump"}

local function blinkOff()
local ah=B.blink
if not ah then return end
B.blink=nil
for ai,aj in ipairs(af)do z.disconnect(aj)end
local ai=ah.fake and ah.fake:FindFirstChild"HumanoidRootPart"
local aj=ai and ai.CFrame
resetHook(false)
local ak=workspace.CurrentCamera
local al
if ah.real and ah.real.Parent then
local am=ah.real:FindFirstChild"HumanoidRootPart"
al=ah.real:FindFirstChildOfClass"Humanoid"
if al then al.Jump=false;pcall(al.Move,al,Vector3.zero,false)end
if ah.thaw then pcall(ah.thaw)end
if am then
am.AssemblyLinearVelocity=Vector3.zero
am.AssemblyAngularVelocity=Vector3.zero
if aj and not ah.ghost then z.markMove();am.CFrame=aj end
am.Anchored=B.selfFrozen and true or false
end
for an,ao in pairs(ah.alpha)do
if an.Parent then an.Transparency=ao end
end
end
ah.locked=false
for am,an in ipairs(ag)do z.disconnect(an)end
if ah.fake then ah.fake:Destroy()end
local am=(al and al.Health>0 and al)or z.hum()
if am and ak and not B.viewing then ak.CameraSubject=am end
active("blink",nil);active("ghost",nil)
end

local function blinkOn(ah)
local ai,aj,ak=z.char(),z.root(),z.hum()
if not(ai and aj and ak)then return z.notify"No character to blink with"end

local al={}
for am,an in ipairs(ai:GetDescendants())do
if an.Archivable==false then al[#al+1]=an;pcall(function()an.Archivable=true end)end
end
ai.Archivable=true
local am,an=pcall(function()return ai:Clone()end)
for ao,ap in ipairs(al)do pcall(function()ap.Archivable=false end)end
local ao=am and an and an:FindFirstChildOfClass"Humanoid"
local ap=am and an and an:FindFirstChild"HumanoidRootPart"
if not(ao and ap)then
if am and an then an:Destroy()end
return z.notify"Couldn't copy your character"
end

ap.Anchored=false
ao.PlatformStand,ao.Sit=false,false
for aq,ar in ipairs(an:GetDescendants())do
if ar:IsA"BodyMover"or ar:IsA"VectorForce"or ar:IsA"LineForce"then pcall(function()ar:Destroy()end)end
if ar:IsA"LuaSourceContainer"then pcall(function()ar.Disabled=true end)end
end


local aq={real=ai,fake=an,ghost=ah,alpha={},locked=true}
for ar,as in ipairs(ai:GetDescendants())do
if as:IsA"BasePart"or as:IsA"Decal"then
aq.alpha[as]=as.Transparency
as.Transparency=math.max(as.Transparency,0.5)
end
end
ak.Jump=false
pcall(ak.Move,ak,Vector3.zero,false)
aj.AssemblyLinearVelocity=Vector3.zero
aj.AssemblyAngularVelocity=Vector3.zero
aj.Anchored=true

local ar,as,at={},{},ai:FindFirstChild"Animate"
local au=at and at:IsA"LuaSourceContainer"and at.Disabled
for av,aw in ipairs(Enum.HumanoidStateType:GetEnumItems())do
if aw~=Enum.HumanoidStateType.Dead and aw~=Enum.HumanoidStateType.None then
local ax,ay=pcall(ak.GetStateEnabled,ak,aw)
if ax then ar[aw]=ay;pcall(ak.SetStateEnabled,ak,aw,false)end
end
end
if au~=nil then at.Disabled=true end
local av=ak:FindFirstChildOfClass"Animator"
local function freeze(aw)if as[aw]==nil then as[aw]=aw.Speed end pcall(aw.AdjustSpeed,aw,0)end
if av then
for aw,ax in ipairs(av:GetPlayingAnimationTracks())do freeze(ax)end
z.connect("blinkAnim",av.AnimationPlayed,freeze)
end
function aq.thaw()
for aw,ax in pairs(ar)do pcall(ak.SetStateEnabled,ak,aw,ax)end
for aw,ax in pairs(as)do pcall(aw.AdjustSpeed,aw,ax)end
if au~=nil and at.Parent then at.Disabled=au end
end

local function lock()
if aq.locked and ak.Parent then
if ak.Jump then ak.Jump=false end
ak:Move(Vector3.zero,false)
end
end
z.connect("blinkLockPre",ac.PreSimulation,lock)
z.connect("blinkLockStep",ac.Stepped,lock)
z.connect("blinkLockJump",ak:GetPropertyChangedSignal"Jump",function()
if aq.locked and ak.Jump then ak.Jump=false end
end)


an.Name=ai.Name
an.Parent=workspace
local aw=workspace.CurrentCamera
if not B.viewing then aw.CameraSubject=ao end
B.blink=aq
active(ah and"ghost"or"blink",true)


local ax
pcall(function()ax=require(A.PlayerScripts:WaitForChild("PlayerModule",3)):GetControls()end)
local function kd(ay)return ab:IsKeyDown(ay)and not ab:GetFocusedTextBox()end

local ay,az={}
do
local aA=an:FindFirstChild"Animate"
local aB=ao:FindFirstChildOfClass"Animator"
if not aB then aB=Instance.new"Animator";aB.Parent=ao end
for aC,aD in ipairs{"idle","walk","run","jump","fall","climb","sit"}do
local aE=aA and aA:FindFirstChild(aD)
local O=aE and aE:FindFirstChildWhichIsA("Animation",true)
if O then
local P,Q=pcall(function()return aB:LoadAnimation(O)end)
if P and Q then ay[aD]=Q end
end
end
end
local function play(aA,aB)
if az~=aA then
if az and ay[az]then ay[az]:Stop(0.15)end
az=aA
if ay[aA]then ay[aA]:Play(0.15)end
end
if aB and ay[aA]then ay[aA]:AdjustSpeed(aB)end
end
local aA=Enum.HumanoidStateType
z.connect("blinkMove",ac.RenderStepped,function()
if not(B.blink==aq and an.Parent and ao.Parent)then return end
local aB
if ax then
local aC,aD=pcall(ax.GetMoveVector,ax)
if aC and typeof(aD)=="Vector3"then aB=aD end
end
if not aB then
aB=Vector3.new((kd(Enum.KeyCode.D)and 1 or 0)-(kd(Enum.KeyCode.A)and 1 or 0),0,(kd(Enum.KeyCode.S)and 1 or 0)-(kd(Enum.KeyCode.W)and 1 or 0))
end
ao:Move(aB,true)
if kd(Enum.KeyCode.Space)then ao.Jump=true end
if not B.viewing and aw.CameraSubject~=ao then aw.CameraSubject=ao end
local aC=an:FindFirstChild"HumanoidRootPart"
local aD=ao:GetState()
local aE=aC and Vector3.new(aC.AssemblyLinearVelocity.X,0,aC.AssemblyLinearVelocity.Z).Magnitude or 0
if aD==aA.Climbing then play"climb"
elseif aD==aA.Seated then play"sit"
elseif aD==aA.Jumping then play"jump"
elseif aD==aA.Freefall or aD==aA.FallingDown then play"fall"
elseif aE>0.5 then play(ay.run and"run"or"walk",math.clamp(aE/16,0.3,2))
else play"idle"end
end)
z.connect("blinkJump",ab.JumpRequest,function()if ao.Parent then ao.Jump=true end end)

z.connect("blinkNC",ac.Stepped,function()
for aB in pairs(aq.alpha)do
if aB.Parent and aB:IsA"BasePart"then aB.CanCollide=false end
end
end)
z.connect("blinkDeath",ao.Died,function()
blinkOff()
pcall(function()if ak.Parent then ak.Health=0 end end)
end)

z.connect("blinkChar",A.CharacterAdded,function(aB)
if B.blink==aq and aB~=aq.real then blinkOff()end
end)

z.connect("blinkGuard",ac.Heartbeat,function()
if B.blink~=aq then
if B.blinkReset and not B.blink then resetHook(false)end
return
end
local aB
if not(aq.fake and aq.fake.Parent)then aB="the copy was removed"
elseif not aq.fake:FindFirstChildOfClass"Humanoid"then aB="the copy lost its humanoid"
elseif not(aq.real and aq.real.Parent)then aB="your real body is gone"
elseif not aq.real:FindFirstChildOfClass"Humanoid"then aB="your real body lost its humanoid"end
if aB then
blinkOff()
z.notify("Blink ended on its own: "..aB,6)
end
end)
resetHook(true)
end
def({"blink"},"","Look frozen to everyone else while you keep moving (toggle)","lag teleport spoof position",function()
if B.blink then blinkOff()else blinkOn(false)end
end)
def({"ghost","ghostblink"},"","Like blink, but sends you back to where you started (toggle)","lag teleport spoof position",function()
if B.blink then blinkOff()else blinkOn(true)end
end)
def({"unblink","unghost"},"","Turn blink / ghost off (either name works for both); also frees you if a blink went wrong","lag spoof position ghost",function()
if B.blink then return blinkOff()end

resetHook(false)
for ah,ai in ipairs(ag)do z.disconnect(ai)end
local ah,ai=z.root(),z.hum()
if ah and ah.Anchored and not B.selfFrozen and not B.parked then ah.Anchored=false end
if ai then workspace.CurrentCamera.CameraSubject=ai end
end)




local function spoofer()return c.NameSpoof end
local function loadSpoofer()
if spoofer()and not B.spoofStale then return spoofer()end
if spoofer()and spoofer().Destroy then pcall(spoofer().Destroy)end
local ah
for ai,aj in ipairs(h)do
if aj.name=="Name Spoofer"then ah=aj.url end
end
local ai,aj=ah and z.fetch(ah)
if not ai then z.notify("Name Spoofer: download failed ("..tostring(aj)..")");return nil end
local ak={}
for al in tostring(aa.streamOthers):gmatch"[^,]+"do
al=al:match"^%s*(.-)%s*$"
if al~=""then ak[#ak+1]=string.format("%q",al)end
end
if#ak==0 then ak[1]='"Player"'end
ai=ai:gsub("local OTHER_NAMES = %b{}",function()return"local OTHER_NAMES = {"..table.concat(ak,", ").."}"end,1)
ai=ai:gsub("local ENABLED = %a+",function()return"local ENABLED = false"end,1)
ai=ai:gsub("local SPOOF_OTHERS = %a+",function()return"local SPOOF_OTHERS = false"end,1)
if not q then z.notify"Name Spoofer needs loadstring (this executor has none)";return nil end
local al,am=loadstring(ai)
if not al then z.notify("Name Spoofer: "..tostring(am));return nil end
local an,ao=pcall(al)
if not an then z.notify("Name Spoofer error: "..tostring(ao));return nil end
B.spoofStale=false
return spoofer()
end
function z.reloadSpoofer()
if spoofer()then B.spoofStale=true end
if z.streamOthersOn and z.streamOthersOn()then z.streamOthers(false);z.streamOthers(true)end
end



do
local ah={on=false,map={},real={},n=0,txt={},cons={},hooked={}}
local function alias(ai)
if ah.map[ai]then return ah.map[ai]end
local aj={}
for ak in tostring(aa.streamOthers):gmatch"[^,]+"do
ak=ak:match"^%s*(.-)%s*$"
if ak~=""then aj[#aj+1]=ak end
end
if#aj==0 then aj[1]="Player"end
local ak=ah.n
ah.n=ak+1
local al=aj[ak%#aj+1]
if ak>=#aj then al=al.." "..(math.floor(ak/#aj)+1)end
ah.map[ai],ah.real[ai]=al,{ai.Name,ai.DisplayName}
return al
end
local function scrub(ai)
if ai:FindFirstAncestor"KLOSAD"then return end
local aj=ai.Text
ah.set=ah.set or{}
if aj==""or aj==ah.set[ai]then return end
local ak=aj
for al,am in pairs(ah.real)do
for an,ao in ipairs(am)do
if#ao>=3 and ah.map[al]and ak:find(ao,1,true)then
ak=ak:gsub((ao:gsub("%p","%%%0")),(ah.map[al]:gsub("%%","%%%%")))
end
end
end
if ak~=aj then
ah.txt[ai],ah.set[ai]=aj,ak
ai.Text=ak
else
ah.txt[ai],ah.set[ai]=nil,nil
end
end
local function hook(ai)
if not(ai:IsA"TextLabel"or ai:IsA"TextButton")then return end
scrub(ai)
if ah.hooked[ai]then return end
ah.hooked[ai]=true
ah.cons[#ah.cons+1]=ai:GetPropertyChangedSignal"Text":Connect(function()scrub(ai)end)
end
local function roots()
local ai={}
local aj,ak=pcall(function()return game:GetService"CoreGui"end)
if aj and ak then ai[#ai+1]=ak end
local al=A:FindFirstChildOfClass"PlayerGui"
if al then ai[#ai+1]=al end
return ai
end
local function scan()
for ai,aj in ipairs(roots())do
local ak,al=pcall(function()return aj:GetDescendants()end)
if ak then
for am,an in ipairs(al)do
if ah.on then pcall(hook,an)end
if am%400==0 then task.wait()end
end
end
end
end
local function apply(ai)
if ai==A then return end
local aj=alias(ai)
pcall(function()ai.DisplayName=aj end)
local ak=ai.Character and ai.Character:FindFirstChildOfClass"Humanoid"
if ak then pcall(function()ak.DisplayName=aj end)end
end
function z.streamOthersOn()return ah.on end
function z.streamOthers(ai)
z.disconnect"soAdd";z.disconnect"soTick"
for aj,ak in ipairs(ah.cons)do ak:Disconnect()end
if ah.on then
for aj,ak in pairs(ah.real)do
pcall(function()aj.DisplayName=ak[2]end)
local al=aj.Character and aj.Character:FindFirstChildOfClass"Humanoid"
if al then pcall(function()al.DisplayName=ak[2]end)end
end
for aj,ak in pairs(ah.txt)do
if aj.Parent then pcall(function()aj.Text=ak end)end
end
end
ah.on,ah.map,ah.real,ah.n,ah.cons=ai and true or false,{},{},0,{}
ah.txt,ah.hooked=setmetatable({},{__mode="k"}),setmetatable({},{__mode="k"})
if not ai then return end
for aj,ak in ipairs(ad:GetPlayers())do apply(ak)end
z.connect("soAdd",ad.PlayerAdded,function(aj)
apply(aj)
task.delay(0.5,scan)
end)
local aj=0
z.connect("soTick",ac.Heartbeat,function()
local ak=os.clock()
if ak-aj<2 then return end
aj=ak
for al,am in pairs(ah.map)do
if not al.Parent then
ah.map[al],ah.real[al]=nil,nil
else
if al.DisplayName~=am then pcall(function()al.DisplayName=am end)end
local an=al.Character and al.Character:FindFirstChildOfClass"Humanoid"
if an and an.DisplayName~=am then pcall(function()an.DisplayName=am end)end
end
end
end)
for ak,al in ipairs(roots())do
ah.cons[#ah.cons+1]=al.DescendantAdded:Connect(function(am)pcall(hook,am)end)
end
task.spawn(scan)
end
end
def({"streamer","streamermode"},"","Hide your name and everyone else's (names set in Module Cfg)","name hide spoof privacy",function()
local ah=loadSpoofer()
if not ah then return end
ah.Name,ah.Enabled,ah.Others=aa.streamMe,true,false
z.streamOthers(true)
end)
def({"unstreamer","unstreamermode"},"","Turn streamer mode off","name hide spoof privacy",function()
z.streamOthers(false)
local ah=spoofer()
if ah then ah.Enabled,ah.Others=false,false end
end)
def({"name","spoof"},"<name>","Spoof your own name","name hide spoof",function(...)
local ah=table.concat({...}," ")
if ah==""then return z.notify"Usage: name <name>"end
local ai=loadSpoofer()
if not ai then return end
ai.Name,ai.Enabled,ai.Others=ah,true,false
end)
def({"unname","unspoof"},"","Stop spoofing your name","name spoof",function()
local ah=spoofer()
if ah then ah.Enabled,ah.Others=false,false end
end)




local ah={byId={},ip={},busy=false,stop=false}
z.SRV=ah
do
local ai
local aj=(getgenv and getgenv())or _G
local function jdec(ak)local al,am=pcall(l.HttpService.JSONDecode,l.HttpService,ak);return al and am or nil end
local function hdr(ak,al)
for am,an in pairs(ak.Headers or{})do if tostring(am):lower()==al then return an end end
end
local function cookie()
for ak,al in ipairs{"getrbxcookie","get_roblox_cookie","getrobloxcookie","getcookie"}do
if type(aj[al])=="function"then
local am,an=pcall(aj[al])
if am and type(an)=="string"and#an>20 then return an end
end
end
end


local ak="https://gamejoin.roblox.com/v1/join-game-instance"
local function viaInternal(al)
local am
for an=1,2 do
am=nil
local ao,ap=pcall(function()
return l.HttpService:RequestInternal{Url=ak,Method="POST",Headers={["Content-Type"]="application/json",["x-csrf-token"]=ai},Body=al}
end)
if not(ao and ap)then return nil end
if not pcall(function()ap:Start(function(aq,ar)am=ar or false end)end)then return nil end
local aq=os.clock()
while am==nil and os.clock()-aq<10 do task.wait(0.05)end
if type(am)~="table"then return nil end
if am.StatusCode==403 and hdr(am,"x-csrf-token")then ai=hdr(am,"x-csrf-token")else break end
end
return{StatusCode=am.StatusCode,Body=am.Body}
end
local function viaApi(al)
local am,an=pcall(function()
return game:GetService"HttpRbxApiService":PostAsyncFullUrl(ak,al,Enum.ThrottlingPriority.Default,Enum.HttpContentType.ApplicationJson)
end)
if am and type(an)=="string"then return{StatusCode=200,Body=an}end
end

local al={"both","header","table"}
local function send(am,an,ao)
am.Headers=am.Headers or{}
am.Headers["User-Agent"]="Roblox/WinInet"
if an~="table"then am.Headers.Cookie=".ROBLOSECURITY="..ao end
if an~="header"then am.Cookies={[".ROBLOSECURITY"]=ao}end
local ap,aq=pcall(o,am)
if ap and type(aq)=="table"then return aq end
end
local function viaRequest(am)
ah.cookie=ah.cookie or cookie()
if not ah.cookie then return nil,"needs your cookie (start region-relay.py)"end
local an
for ao,ap in ipairs(ah.how and{ah.how}or al)do
for aq=1,2 do
an=send({Url=ak,Method="POST",Body=am,Headers={["Content-Type"]="application/json",Referer="https://www.roblox.com/",Origin="https://www.roblox.com",["x-csrf-token"]=ai}},ap,ah.cookie)
if not an then return nil end
if an.StatusCode==403 and hdr(an,"x-csrf-token")then ai=hdr(an,"x-csrf-token")else break end
end
if an.StatusCode~=401 then ah.how=ap;break end
end
return an
end
local function authCheck()
local am,an=tostring(ah.cookie),{}
for ao,ap in ipairs(al)do
local aq=send({Url="https://users.roblox.com/v1/users/authenticated",Method="GET"},ap,am)
local ar=aq and tostring(aq.Body)or""
an[#an+1]=ap.."="..(aq and(tostring(aq.StatusCode).."/"..(ar:match'"code":(%d+)'or"-").."."..(ar:match'"subcode":(%d+)'or"-"))or"fail")
end
local ao=send({Url="https://httpbin.org/headers",Method="GET"},"header","TEST")
return"cookie check: "..table.concat(an," ").." | len "..#am..(am:find("_|WARNING",1,true)and""or" | no _|WARNING prefix")
..(ao and(tostring(ao.Body):find("ROBLOSECURITY=TEST",1,true)and" | executor sends the Cookie header"or" | executor DROPS the Cookie header")or" | echo test failed")
end
local function viaRelay(am)
local an,ao=pcall(o,{Url="http://127.0.0.1:47653/join",Method="POST",Headers={["Content-Type"]="application/json"},Body=am})
ah.relay=an and type(ao)=="table"and tonumber(ao.StatusCode)~=nil
if ah.relay then return{StatusCode=ao.StatusCode,Body=ao.Body}end
end
local am,an={relay=viaRelay,internal=viaInternal,api=viaApi,request=viaRequest},{"relay","internal","api","request"}
local function resolve(ao,ap)
local aq=l.HttpService:JSONEncode{placeId=ao,isTeleport=false,gameId=ap,gameJoinAttemptId=l.HttpService:GenerateGUID(false)}
local ar={}
for as,at in ipairs(ah.mode and{ah.mode}or an)do
local au,av=am[at](aq)
if not au then
ar[#ar+1]=at..": "..(av or"unavailable")
else
if au.StatusCode==429 then return nil,"rate"end
if au.StatusCode==200 then
local aw=jdec(au.Body)
local ax=aw and aw.joinScript
local ay=ax and ax.UdmuxEndpoints and ax.UdmuxEndpoints[1]
local az=(ay and ay.Address)or(ax and ax.MachineAddress)
if type(az)=="string"and not az:match"^10%."then
ah.mode=at
ah.byId[ap]={ip=az,t=os.time()}
return ah.byId[ap]
end

local aA=(aw and aw.joinScript)and""or(" | status "..tostring(aw and aw.status).." "..(tostring(au.Body or""):gsub("%s+"," ")):sub(1,160))
ar[#ar+1]=at..": "..((aw and aw.message)or"reply has no server address")..aA
else
local aw=((tostring(au.Body or""):gsub("%s+"," "))):sub(1,90)
if at=="request"and au.StatusCode==401 then
ah.authNote=ah.authNote or authCheck()
aw=aw.." | "..ah.authNote..(ai and""or" | no csrf token received")
end
ar[#ar+1]=at..": HTTP "..tostring(au.StatusCode).." "..aw
end
end
end
ah.mode=nil
return nil,table.concat(ar," | ")
end
local function put(ao,ap)
if not ao or not ao.city or ao.city==""then return end
local aq,ar,as=ao.countryCode or ao.country_code or"",ao.regionName or ao.region or"",ao.country or""
ah.ip[ap]={label=ao.city..", "..aq,cc=aq:upper(),cont=(ao.continentCode or ao.continent_code or""):upper(),
key=(ao.city.." "..ar.." "..as.." "..aq.." "..(ao.continent or"")):lower()}
end
local function geo(ao)
local ap={}
for aq,ar in ipairs(ao)do ap[#ap+1]={query=ar,fields="status,country,countryCode,regionName,city,query,continent,continentCode"}end
local aq,ar=pcall(o,{Url="http://ip-api.com/batch",Method="POST",Headers={["Content-Type"]="application/json"},Body=l.HttpService:JSONEncode(ap)})
local as=aq and ar and ar.StatusCode==200 and jdec(ar.Body)
if as then
for at,au in ipairs(as)do if au.status=="success"then put(au,au.query)end end
return true
end
for at,au in ipairs(ao)do
local av=z.fetch("https://ipwho.is/"..au)
local aw=av and jdec(av)
if aw and aw.success then put(aw,au)end
end
return next(ah.ip)~=nil
end


local ao,ap=b.."/servers.json",216E2
function ah.save()
if not(p and writefile)then return end
local aq,ar,as={},{},os.time()
for at,au in pairs(ah.byId)do
if au.ip and au.t and as-au.t<ap then aq[at]=au;ar[au.ip]=ah.ip[au.ip]end
end
local at,au=pcall(function()
if not isfolder(b)then makefolder(b)end
writefile(ao,l.HttpService:JSONEncode{ids=aq,ips=ar})
end)
if not at and not ah.saveWarned then ah.saveWarned=true;z.notify("Region cache not saved: "..tostring(au),8)end
end
pcall(function()
if not(p and isfile and isfile(ao))then return end
local aq,ar=jdec(readfile(ao)),os.time()
if not aq then return end
for as,at in pairs(aq.ids or{})do
if type(at)=="table"and type(at.ip)=="string"and type(at.t)=="number"and ar-at.t<ap then ah.byId[as]=at;ah.loaded=(ah.loaded or 0)+1 end
end
for as,at in pairs(aq.ips or{})do if type(at)=="table"and at.label and at.key and at.cont then ah.ip[as]=at end end
end)
function ah.running()return ah.busy and os.clock()-(ah.beat or 0)<90 end
function ah.region(aq)local ar=ah.byId[aq];return ar and ah.ip[ar.ip]end
function ah.match(aq,ar)
local as=ah.region(aq)
if not as then return false end
if#ar<=2 then local at=ar:upper()=="UK"and"GB"or ar:upper();return as.cc==at or as.cont==at end
return as.key:find(ar,1,true)~=nil
end
function ah.list(aq)
local ar,as={}
for at=1,10 do
local au=("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true%s"):format(aq,as and("&cursor="..as)or"")
local av,aw=z.fetch(au)
local ax=av and jdec(av)
if not(ax and ax.data)then return ar,aw or"bad reply"end
for ay,az in ipairs(ax.data)do ar[#ar+1]=az end
as=ax.nextPageCursor
if not as then break end
task.wait(0.3)
end
return ar
end

function ah.scan(aq,ar,as)
if ah.running()then return false end
ah.busy,ah.stop,ah.err,ah.okN,ah.failN,ah.beat=true,false,nil,0,0,os.clock()

local at,au=math.clamp(tonumber(s.srvMax)or 50,1,100),{}
for av,aw in ipairs(ar)do
if(ah.byId[aw.id]and ah.byId[aw.id].ip)or at>0 then
if not(ah.byId[aw.id]and ah.byId[aw.id].ip)then at=at-1 end
au[#au+1]=aw
end
end
ar=au
task.spawn(function()
local av=1
while av<=#ar and not ah.stop and l.alive do
local aw={}
for ax=av,math.min(av+11,#ar)do aw[#aw+1]=ar[ax]end
av=av+12
local ax,ay=1,0
for az=1,4 do
ay=ay+1
task.spawn(function()
while not ah.stop do
local aA=aw[ax]
if not aA then break end
ax=ax+1
if not(ah.byId[aA.id]and ah.byId[aA.id].ip)then
local aB,aC
for aD=1,3 do
local aE,O,P=pcall(resolve,aq,aA.id)
if aE then aB,aC=O,P else aB,aC=nil,tostring(O)end
ah.beat=os.clock()
if aC~="rate"or ah.stop then break end
task.wait(3*aD)
end
if aB then
ah.okN=ah.okN+1
else
ah.failN=ah.failN+1
if aC=="rate"or(ah.okN==0 and ah.failN>=4)then
ah.err=aC=="rate"and"Roblox rate limit, try again in a minute"or aC
ah.stop=true
end
end
task.wait(0.2)
end
end
ay=ay-1
end)
end
while ay>0 do task.wait(0.05)end
local az,aA={},{}
for aB,aC in ipairs(aw)do
local aD=ah.byId[aC.id]
if aD and not ah.ip[aD.ip]and not aA[aD.ip]then aA[aD.ip]=true;az[#az+1]=aD.ip end
end
if#az>0 and not geo(az)then ah.err=ah.err or"IP lookup failed (ip-api.com / ipwho.is)";ah.stop=true end
ah.save()
if as and as(aw)then break end
end
ah.busy=false
if as then as(nil)end
end)
return true
end


function ah.cancelJoin(aq)
local ar=ah.joining
if not ar then return end
ar.stop,ah.joining=true,nil
for as,at in ipairs(ar.conns)do pcall(function()at:Disconnect()end)end
pcall(function()if ar.prompt and ar.prompt.Parent then ar.prompt.Enabled=ar.was end end)
if not aq then z.notify("Join cancelled",3)end
if ah.onJoin then ah.onJoin()end
end
function ah.join(aq,ar)
ah.save()
ah.cancelJoin(true)
local as,at=l.TeleportService,l.GuiService
local au={id=ar,stop=false,conns={},res=nil}
ah.joining=au
pcall(function()
au.prompt=l.CoreGui:FindFirstChild"RobloxPromptGui"
if au.prompt then au.was=au.prompt.Enabled;au.prompt.Enabled=false end
end)
local function hush()pcall(function()at:ClearError()end)end
au.conns[1]=as.TeleportInitFailed:Connect(function(av,aw)au.res=aw;hush()end)
au.conns[2]=at.ErrorMessageChanged:Connect(hush)
z.notify("Joining server... it keeps retrying if it is full. Press Cancel to stop",5)
if ah.onJoin then ah.onJoin()end
task.spawn(function()
local av,aw=0
while not au.stop and ah.joining==au and l.alive do
au.res=nil
local ax,ay=pcall(function()as:TeleportToPlaceInstance(aq,ar,A)end)
local az=2
if ax then
av=0
local aA=os.clock()
while not au.stop and au.res==nil and os.clock()-aA<12 do task.wait(0.1)end
local aB=au.res
if aB==Enum.TeleportResult.Flooded then az=5
elseif aB==Enum.TeleportResult.GameEnded or aB==Enum.TeleportResult.GameNotFound then aw="That server no longer exists"
elseif aB==Enum.TeleportResult.Unauthorized then aw="You are not allowed to join that server"
elseif aB==nil then az=3 end
else
av=av+1
if av>=8 then aw="Teleport failed: "..tostring(ay)end
end
if aw then break end
local aA=os.clock()
while not au.stop and os.clock()-aA<az do task.wait(0.1)end
end
if aw and ah.joining==au then
ah.cancelJoin(true)
z.notify(aw,5)
end
end)
end

function ah.here()
local aq=game.JobId
if aq==""then return nil,"no job id"end
local ar=ah.byId[aq]
if not(ar and ar.ip)then
local as,at=resolve(game.PlaceId,aq)
if not as then return nil,at end
ar=as
end
if not ah.ip[ar.ip]and not geo{ar.ip}then return nil,"IP lookup failed"end
ah.save()
local as=ah.ip[ar.ip]
return as and as.label
end

function ah.find(aq,ar)
for as,at in ipairs(aq)do
if at.id~=game.JobId and(at.playing or 0)<(at.maxPlayers or 1)and ah.match(at.id,ar)then return at end
end
end
end
def({"region","joinregion"},"<region>","Join a server in a region: city, country or code (singapore, de, frankfurt, us). Checks servers 4 at a time and joins the first match with room","server region location ping hop join",function(...)
local ai=table.concat({...}," ")
if ai==""then return z.notify"Usage: region <city / country / code>"end
ai=ai:lower()
local aj=game.PlaceId
z.notify("Looking for a server in "..ai.."...",4)
local ak,al=ah.list(aj,2)
if#ak==0 then return z.notify("Server list failed: "..tostring(al),5)end
local am=ah.find(ak,ai)
if am then return ah.join(aj,am.id)end
local an=false
if not ah.scan(aj,ak,function(ao)
if not ao then
if not an then z.notify(ah.err or("No server with room in '"..ai.."' among "..#ak.." checked"),6)end
return
end
local ap=ah.find(ao,ai)
if ap then an=true;ah.stop=true;ah.join(aj,ap.id);return true end
end)then z.notify("A region scan is already running",4)end
end)


function ah.hop(ai)
ai=ai:lower()
local aj=game.PlaceId
local ak,al=ah.list(aj,1)
if#ak==0 then return z.notify("Server list failed: "..tostring(al),5)end
local am
for an,ao in ipairs(ak)do
if ao.id~=game.JobId and(ao.playing or 0)<(ao.maxPlayers or 1)and ah.match(ao.id,ai)and(not am or(ao.ping or 9e9)<(am.ping or 9e9))then am=ao end
end
if not am then return z.notify("No scanned server in '"..ai.."'. Run ;scanregions first",5)end
ah.join(aj,am.id)
end
def({"scanregions","scanservers"},"","Scan the regions of this game's public servers (up to Preferences > Servers to scan); saved for ;serverhop and the Servers tab. Good for autostart","server region scan ping",function()
local ai=game.PlaceId
local aj,ak=ah.list(ai,1)
if#aj==0 then return z.notify("Server list failed: "..tostring(ak),5)end
if not ah.scan(ai,aj,function(al)
if not al then z.notify(ah.err or("Region scan done: "..ah.okN.." new servers checked"),5)end
end)then z.notify("A region scan is already running",4)end
end)
def({"serverbrowser","server","servers"},"","Open the server browser (Servers tab)","server region list join",function()z.openTab"Servers"end)
def({"leave","leavegame"},"","Leave the game (closes the Roblox client)","exit quit shutdown disconnect close",function()game:Shutdown()end)


def({"listen"},"<player>","Listen to a player's voice chat from anywhere (the game's own voice from them is muted for you)","voice vc audio hear",function(ai)
if not ai or ai==""then return z.notify"Usage: listen <player>"end
local aj=z.findPlayer(ai)
if not aj then return end
local ak,al=z.setListen(aj.UserId,true)
z.notify(ak and("Listening to "..aj.Name)or al,ak and 3 or 5)
end)
def({"unlisten"},"[player]","Stop listening to a player's voice chat (no name = stop all)","voice vc audio hear",function(ai)
if not ai or ai==""then
local aj=0
for ak in pairs(B.listen)do z.setListen(ak,false);aj=aj+1 end
return z.notify(aj>0 and"Stopped listening to everyone"or"You weren't listening to anyone")
end
local aj=z.findPlayer(ai)
if not aj then return end
z.setListen(aj.UserId,false)
z.notify("Stopped listening to "..aj.Name)
end)





do
local ai={on=false,rec={},cons={}}
local function undo(aj,ak)
ai.rec[aj]=nil
pcall(function()if aj.Parent then aj.TargetInstance=ak.out end end)
pcall(function()ak.mono:Destroy()end)
pcall(function()ak.st:Destroy()end)
end
local function try(aj)
if not ai.on or ai.rec[aj]or not aj.Parent then return end
local ak,al=aj.SourceInstance,aj.TargetInstance
if not(ak and al and ak:IsA"AudioListener"and al:IsA"AudioDeviceOutput")or al.Name=="_klListen"then return end
local am=pcall(function()
local am=Instance.new"AudioChannelMixer"
am.Name,am.Layout,am.Parent="_klNS",Enum.AudioChannelLayout.Mono,l.SoundService
local an=Instance.new"AudioChannelMixer"
an.Name,an.Layout,an.Parent="_klNS",Enum.AudioChannelLayout.Stereo,l.SoundService
local ao,ap=Instance.new"Wire",Instance.new"Wire"
ao.SourceInstance,ao.TargetInstance,ao.Parent=am,an,am
ap.SourceInstance,ap.TargetInstance,ap.Parent=an,al,an
ai.rec[aj]={out=al,mono=am,st=an}
aj.TargetInstance=am
end)
if not am and ai.rec[aj]then undo(aj,ai.rec[aj])end
end
function z.noStereo(aj)
for ak,al in ipairs(ai.cons)do al:Disconnect()end
ai.cons={}
ai.on=aj and true or false
for ak,al in pairs(ai.rec)do undo(ak,al)end
if not aj then return true end
local ak={l.Players,l.SoundService,workspace}
for al,am in ipairs(ak)do
ai.cons[#ai.cons+1]=am.DescendantAdded:Connect(function(an)
if an:IsA"Wire"then task.delay(0.2,try,an)end
end)
end
task.spawn(function()
for al,am in ipairs(ak)do
local an,ao=pcall(function()return am:GetDescendants()end)
if an then
for ap,aq in ipairs(ao)do
if aq:IsA"Wire"then try(aq)end
if ap%2000==0 then task.wait()end
end
end
end
if ai.on and next(ai.rec)==nil then
z.notify("No proximity voice wires found yet: this game may not use the Audio API for voice. It will apply if they appear.",6)
end
end)
return true
end
def({"nostereo","mono"},"","Voice chat in mono: everyone centered, proximity volume kept","voice vc audio stereo pan",function()
z.noStereo(true)
z.notify"Voice chat stereo off"
end)
def({"stereo"},"","Back to normal voice chat stereo","voice vc audio stereo pan",function()
z.noStereo(false)
z.notify"Voice chat stereo on"
end)
end




do
local function nosound(ai)return tostring(ai):lower():find("nosound",1,true)~=nil end
local function rescan(ai,aj,ak)
local al,am,an,ao=pcall(function()return ai[aj](ai)end)
if not(al and type(am)=="table"and#am>0)then return nil end
local ap=(tonumber(ao)and am[ao])and ao or 1
if nosound(am[ap])then
for aq,ar in ipairs(am)do
if not nosound(ar)then ap=aq;break end
end
end
pcall(function()ai[ak](ai,am[ap],type(an)=="table"and an[ap]or"")end)
return tostring(am[ap]),#am
end
def({"refreshaudio","refreshdevices"},"","Re-scan audio drivers and re-select the default mic and speaker (fixes \"NoSound Driver\")","audio mic microphone speaker output input driver device voice vc nosound",function()
local ai,aj={},false
for ak,al in ipairs{{"Mic","GetInputDevices","SetInputDevice","GetMicDevices","SetMicDevice"},
{"Speaker","GetOutputDevices","SetOutputDevice","GetSpeakerDevices","SetSpeakerDevice"}}do
local am,an=rescan(l.SoundService,al[2],al[3])
if not am then am,an=rescan(l.VoiceChatInternal,al[4],al[5])end
if am then
ai[#ai+1]=("%s: %s (%d found)"):format(al[1],am,an)
if nosound(am)then aj=true end
end
end
if#ai==0 then
return z.notify("Couldn't read the device list from this client. Restart the Windows Audio service (or replug the device), then run this again",7)
end
z.notify("Audio re-scanned. "..table.concat(ai," | ")..(aj and". Roblox still only sees NoSound: the driver itself is broken in Windows, fix it there first"or""),7)
end)
end





do
local ai={}
local aj
local function group()
if not(aj and aj.Parent)then
aj=Instance.new"SoundGroup"
aj.Name,aj.Volume,aj.Parent="_klHide",0,l.SoundService
end
return aj
end
local function setp(ak,al,am,an)
local ao,ap=pcall(function()return al[am]end)
if not ao then return end
local aq=ak.rec[al]
if not aq then aq={};ak.rec[al]=aq end
if aq[am]==nil then aq[am]={ap}end
pcall(function()al[am]=an end)
end
local function cover(ak,al)
if al:IsA"BasePart"then setp(ak,al,"LocalTransparencyModifier",1)
elseif al:IsA"Decal"or al:IsA"Texture"then setp(ak,al,"Transparency",1)
elseif al:IsA"BillboardGui"or al:IsA"SurfaceGui"or al:IsA"ParticleEmitter"or al:IsA"Trail"or al:IsA"Beam"or al:IsA"Highlight"then setp(ak,al,"Enabled",false)
elseif al:IsA"Humanoid"then setp(ak,al,"DisplayDistanceType",Enum.HumanoidDisplayDistanceType.None)
elseif al:IsA"Sound"then setp(ak,al,"SoundGroup",group())
elseif al:IsA"AudioPlayer"then setp(ak,al,"Volume",0)end
end
local ak,al,am={},1,0
z.connect("hideQ",ac.Heartbeat,function()
for an=1,40 do
if al>am then
if am>0 then ak,al,am={},1,0 end
return
end
local ao=ak[al]
ak[al],al=nil,al+1
if ai[ao[3] ]==ao[1]and ao[2].Parent then pcall(cover,ao[1],ao[2])end
end
end)
local function watch(an,ao)
local ap="hide_"..an.UserId
local function char(aq)
if not aq then return end
for ar,as in ipairs(aq:GetDescendants())do cover(ao,as)end
z.connect(ap.."d",aq.DescendantAdded,function(ar)am=am+1;ak[am]={ao,ar,an.UserId}end)
end
char(an.Character)
z.connect(ap,an.CharacterAdded,function(aq)task.defer(char,aq)end)
end
function z.isHidden(an)return ai[an]~=nil end
function z.hidePlayer(an,ao)
local ap=ai[an]
if not ao then
if not ap then return false end
ai[an]=nil
z.disconnect("hide_"..an);z.disconnect("hide_"..an.."d")
for aq,ar in pairs(ap.rec)do
for as,at in pairs(ar)do pcall(function()aq[as]=at[1]end)end
end
if ap.muted and B.muted[an]then z.setMuted(an,false)end
if not next(ai)and aj then pcall(function()aj:Destroy()end);aj=nil end
B.active.hide=next(ai)and true or nil
return true
end
local aq=l.Players:GetPlayerByUserId(an)
if ap or not aq or aq==A then return false end
ap={rec={}}
ai[an]=ap
if not B.muted[an]then ap.muted=true;z.setMuted(an,true)end
watch(aq,ap)
B.active.hide=true
return true
end
z.connect("hideLeave",ad.PlayerRemoving,function(an)z.hidePlayer(an.UserId,false)end)
def({"hide"},"<player>","Make a player gone: avatar hidden, every sound from their character silenced, voice and chat muted (;unhide undoes it)","hide invisible mute footsteps audio avatar gun",function(an)
if not an then return z.notify"Usage: hide <player>"end
local ao=0
for ap,aq in ipairs(z.findPlayers(an))do
if z.hidePlayer(aq.UserId,true)then ao=ao+1 end
end
z.notify(ao>0 and("Hid "..ao.." player(s)")or"Nobody to hide")
end)
def({"unhide"},"<player|all>","Show a hidden player again (no name = everyone)","hide show visible unmute",function(an)
local ao=0
if not an or an:lower()=="all"then
for ap in pairs(ai)do
if z.hidePlayer(ap,false)then ao=ao+1 end
end
else
for ap,aq in ipairs(z.findPlayers(an))do
if z.hidePlayer(aq.UserId,false)then ao=ao+1 end
end
end
z.notify(ao>0 and("Unhid "..ao.." player(s)")or"Nobody was hidden")
end)
end



do
local ai={}
local function stopAnim()
ai.run=nil
if ai.track then pcall(function()ai.track:Stop(0)end);ai.track=nil end
end
local function startAnim()
local aj=z.hum()
if not aj then return end
local ak={}
ai.run=ak
task.spawn(function()
local al=aj.RigType==Enum.HumanoidRigType.R15
local am=Instance.new"Animation"
am.AnimationId=al and"rbxassetid://698251653"or"rbxassetid://72042024"
local an,ao=pcall(function()return(aj:FindFirstChildOfClass"Animator"or aj):LoadAnimation(am)end)
if not an or not ao then return z.notify"Placeholder1: couldn't load the animation"end
if ai.run~=ak then return end
ai.track=ao
local ap,aq=0.6,al and 0.7 or 0.65
ao.Priority=Enum.AnimationPriority.Action
ao:Play(0)
ao:AdjustSpeed(0)
local ar,as=ap,1
while ai.run==ak and l.alive do
local at=task.wait()
ar=ar+as*math.max(ai.speed or tonumber(aa.ph1Mult)or 1,0.05)*at
if ar>=aq then ar,as=aq,-1 elseif ar<=ap then ar,as=ap,1 end
ao.TimePosition=ar
end
pcall(function()ao:Stop(0)end)
end)
end
local function strip()
stopAnim()
for aj,ak in ipairs{"ph1Eq","ph1Un","ph1Died"}do z.disconnect(ak)end
for aj,ak in ipairs{A:FindFirstChildOfClass"Backpack",z.char()}do
for al,am in ipairs(ak and ak:GetChildren()or{})do
if am:IsA"Tool"and am.Name=="Placeholder1"then am:Destroy()end
end
end
ai.tool=nil
end
def({"placeholder1"},"[animation speed]","Get the Placeholder1 tool (equip it to play the animation); with a number it spawns with that speed, or changes the speed of the one you have","tool animation hand gesture speed",function(aj)
local ak=tonumber(aj)
if aj and not ak then return z.notify"Placeholder1: the speed has to be a number"end
local al,am=A:FindFirstChildOfClass"Backpack",z.hum()
if not(al and am)then return end
if ai.tool and(ai.tool.Parent==al or ai.tool.Parent==z.char())then
if ak then ai.speed=ak;return z.notify("Placeholder1 speed: "..ak)end
return z.notify"Placeholder1 is already in your inventory"
end
ai.speed=ak
stopAnim()
local an=Instance.new"Tool"
an.Name,an.ToolTip,an.RequiresHandle,an.CanBeDropped="Placeholder1","Placeholder1",false,false
an.Parent=al
ai.tool=an
z.connect("ph1Eq",an.Equipped,function()stopAnim();startAnim()end)
z.connect("ph1Un",an.Unequipped,stopAnim)
z.connect("ph1Died",am.Died,stopAnim)
end)
def({"unplaceholder1"},"","Remove the Placeholder1 tool from your inventory","tool animation remove",strip)
end


do
local ai=setmetatable({},{__mode="k"})
local function restore()
for aj in pairs(ai)do pcall(function()aj.CanCollide=true end)end
ai=setmetatable({},{__mode="k"})
end
def({"noplayercollision","noplayercollide","nopc","nopcol","nopcollide","noplayercollusion"},"","Walk through other players (client side)","collide collision collusion ghost pass through players",function()
local function sweep()
for aj,ak in ipairs(ad:GetPlayers())do
local al=ak~=A and ak.Character
for am,an in ipairs(al and al:GetChildren()or{})do
if an:IsA"BasePart"then
if an.CanCollide then ai[an]=true end
an.CanCollide=false
end
end
end
end
z.connect("noPlayerCol",ac.Stepped,sweep)
z.connect("noPlayerCol2",ac.PreSimulation,sweep)
end)
def({"playercollision","playercollide","pc","pcol","pcollide","playercollusion"},"","Other players are solid again (undoes ;noplayercollision)","collide collision collusion players",function()
z.disconnect"noPlayerCol"
z.disconnect"noPlayerCol2"
restore()
end)
end


do
local ai,aj=l.HttpService,"http://127.0.0.1:47653/alt"
B.alts={}
local function post(ak,al)
local am,an=pcall(o,{Url=aj..ak,Method="POST",Headers={["Content-Type"]="application/json"},Body=ai:JSONEncode(al)})
if am and type(an)=="table"and an.StatusCode==200 then
local ao,ap=pcall(ai.JSONDecode,ai,an.Body)
if ao and type(ap)=="table"then return ap end
end
end
local ak=""
task.spawn(function()
local al=0
while l.alive do
local am=post("/ping",{id=tostring(A.UserId),userId=A.UserId,name=A.Name,displayName=A.DisplayName,placeId=game.PlaceId,jobId=game.JobId})
if am then
al=0
local an,ao={},{}
for ap,aq in ipairs(am.alts or{})do an[aq.userId]=aq;ao[#ao+1]=aq.userId..":"..tostring(aq.jobId)end
table.sort(ao)
local ap=table.concat(ao,",")
if ap~=ak then ak,B.alts,B.altsRev=ap,an,(B.altsRev or 0)+1 end
for aq,ar in ipairs(am.cmds or{})do
if type(ar)=="string"and not(ar:lower():match"^%s*;?sudo"or ar:lower():match"^%s*;?all%f[%A]")then
z.notify("sudo: "..ar)
task.spawn(z.Run,ar)
end
end
else
al=al+1
if ak~=""then ak,B.alts,B.altsRev="",{},(B.altsRev or 0)+1 end
end
task.wait(al>3 and 5 or 1.5)
end
end)

local function bcast(al,...)
local am={...}
local an="others"
if am[1]and am[1]:sub(1,1)=="@"then an=table.remove(am,1):sub(2):lower()end
local ao=table.concat(am," ")
if ao==""then return z.notify("Usage: "..(al and"all"or"sudo").." [@alt] <command>")end
local ap=ao:lower()
if ap:match"^;?sudo"or ap:match"^;?all%f[%A]"then return z.notify"Not inside sudo / all"end
local aq=post("/send",{from=tostring(A.UserId),to=an,cmd=ao})
if al then task.spawn(z.Run,ao)end
if not aq then return z.notify("The relay does not answer (start region-relay.py)"..(al and", ran it here only"or""))end
local ar=aq.sent or 0
z.notify(ar>0 and("Sent to %d account(s): %s"):format(ar,ao)or"No other account is connected to the relay")
end
def({"sudo"},"[@alt] <command>","Run a command on your OTHER accounts (not this one; needs region-relay.py running)","alt alts multi instance accounts everywhere execute run",function(...)bcast(false,...)end)
def({"all"},"[@alt] <command>","Run a command on this account AND your other accounts (needs region-relay.py running)","alt alts multi instance accounts everywhere execute run every",function(...)bcast(true,...)end)

local function altChoices(al,am)
local an={}
if al==1 and am:sub(1,1)=="@"then
for ao,ap in pairs(B.alts or{})do
an[#an+1]={text="@"..ap.name,desc=(ap.displayName and ap.displayName~="")and ap.displayName or""}
end
end
return an
end
z.Meta.sudo.complete,z.Meta.all.complete=altChoices,altChoices
end


local ai=ab
def({"lockmouse"},"","Lock the mouse to the centre, like shift lock","shiftlock cursor camera",function()
z.connect("lockmouse",ac.RenderStepped,function()
if not l.mouseFree then ai.MouseBehavior=Enum.MouseBehavior.LockCenter end
end)
end)
def({"unlockmouse"},"","Unlock the mouse","shiftlock cursor camera",function()
z.disconnect"lockmouse"
ai.MouseBehavior=Enum.MouseBehavior.Default
end)
def({"enableshiftlock","enablesl"},"","Turn shift lock on as an option in the Roblox client","mouse lock camera",function()
pcall(function()A.DevEnableMouseLock=true end)
z.notify"Shift lock enabled"
end)
def({"ctrllock","controllock"},"","Make Left Ctrl the shift lock button instead of Shift","mouse lock camera",function()
pcall(function()A.DevEnableMouseLock=false end)
local aj=false
z.connect("ctrllock",ab.InputBegan,function(ak)
if ak.KeyCode==Enum.KeyCode.LeftControl and not typing()then
aj=not aj
if aj then
z.connect("ctrllockLoop",ac.RenderStepped,function()
if not l.mouseFree then ai.MouseBehavior=Enum.MouseBehavior.LockCenter end
end)
else
z.disconnect"ctrllockLoop"
ai.MouseBehavior=Enum.MouseBehavior.Default
end
end
end)
end)
def({"unctrllock","uncontrollock"},"","Put shift lock back on Shift","mouse lock camera",function()
z.disconnect"ctrllock";z.disconnect"ctrllockLoop"
pcall(function()A.DevEnableMouseLock=true end)
ai.MouseBehavior=Enum.MouseBehavior.Default
end)


def({"toggleshiftlock","shiftlock","shl"},"","Toggle shift lock (for when the Shift key is taken)","mouse lock camera shift",function()
local aj,ak=pcall(function()
require(A.PlayerScripts:WaitForChild("PlayerModule",3)):GetCameras().activeMouseLockController:OnMouseLockToggled()
end)
if not aj then z.notify("Shift lock toggle failed ("..tostring(ak).."). Try ;enableshiftlock first",5)end
end)



do
local aj={gui=nil,root=nil,prevIcon=nil}
local function rect(ak,al,am,an,ao,ap,aq,ar)
new("Frame",{Position=UDim2.fromOffset(al,am),Size=UDim2.fromOffset(an,ao),BackgroundColor3=ap,
BackgroundTransparency=1-aq,BorderSizePixel=0,ZIndex=ar},ak)
end
local function build()
local ak=s.mod
local al=math.max(0,math.floor(tonumber(ak.chLen)or 0))
local am=math.floor(tonumber(ak.chGap)or 0)
local an=math.max(1,math.floor(tonumber(ak.chThick)or 1))
local ao=math.max(0,math.floor(tonumber(ak.chOutline)or 0))
local ap=math.clamp(tonumber(ak.chOutlineAlpha)or 1,0,1)
local aq=parseHex(ak.chColor)or u(0,255,0)
local ar=math.floor(an/2)
local as=an%2
local at={}
if ak.chStyle=="Dot"then
at[1]={-ar,-ar,an,an}
elseif al>0 then
at[#at+1]={-ar,am+as,an,al}
at[#at+1]={-(am+al),-ar,al,an}
at[#at+1]={am+as,-ar,al,an}
if ak.chStyle~="T"then at[#at+1]={-ar,-(am+al),an,al}end
end
aj.root:ClearAllChildren()
if ao>0 and ap>0 then
for au,av in ipairs(at)do rect(aj.root,av[1]-ao,av[2]-ao,av[3]+ao*2,av[4]+ao*2,u(0,0,0),ap,1)end
end
for au,av in ipairs(at)do rect(aj.root,av[1],av[2],av[3],av[4],aq,1,2)end
end
local ak=game:GetService"GuiService"

local function place()
z.disconnect"chFollow"
if s.mod.chCursor then
if aj.prevIcon==nil then aj.prevIcon=ab.MouseIconEnabled end
z.connect("chFollow",ac.RenderStepped,function()
local al=ab:GetMouseLocation()
aj.root.Position=UDim2.fromOffset(al.X,al.Y)
ab.MouseIconEnabled=false
end)
else
aj.root.Position=UDim2.fromScale(0.5,0.5)
local al=aj.gui and aj.gui.AbsoluteSize
if al then aj.root.Position=UDim2.fromOffset(math.floor(al.X/2),math.floor(al.Y/2))end
z.connect("chFollow",ac.RenderStepped,function()
local am=ab.MouseBehavior==Enum.MouseBehavior.LockCenter and not l.mouseFree and not ak.MenuIsOpen
if am then
if aj.prevIcon==nil then aj.prevIcon=ab.MouseIconEnabled end
ab.MouseIconEnabled=false
elseif aj.prevIcon~=nil and not z.cursorOff then
ab.MouseIconEnabled=aj.prevIcon;aj.prevIcon=nil
end
end)
end
end
function z.crosshair(al)
if not al then
z.disconnect"chFollow"
if aj.gui then pcall(function()aj.gui:Destroy()end)end
aj.gui,aj.root=nil,nil
aj.prevIcon=nil
if not z.cursorOff then ab.MouseIconEnabled=true end
return
end
if not aj.gui then
aj.gui=new("ScreenGui",{Name="KLCrosshair",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=9999,
ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
aj.root=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,
Position=UDim2.fromScale(0.5,0.5)},aj.gui)
local am=pcall(function()aj.gui.Parent=(gethui and gethui())or l.CoreGui end)
if not am or not aj.gui.Parent then aj.gui.Parent=A:WaitForChild"PlayerGui"end
end
build();place()
end

function z.onMod(al)
al=tostring(al)
if aj.gui and al:match"^ch%u"then build();place()end
if al:match"^esp"and z.espRefresh then z.espRefresh()end
if(al:match"^srv"or al:match"^pred")and z.srvRefresh then z.srvRefresh()end
if al=="actCorner"and n.actLayout then n.actLayout()end
end
end
def({"crosshair","xhair"},"","Show a static CS style crosshair (mode, length, gap, thickness, outline, colour in Module Cfg)","aim reticle cs dot",function()
z.crosshair(true)
end)
def({"removecrosshair","nocrosshair","uncrosshair"},"","Remove the crosshair","aim reticle cs",function()
z.crosshair(false)
z.notify"Crosshair removed"
end)


do
local aj
function z.hideCursor(ak)
z.disconnect"hideCursor"
z.cursorOff=ak and true or false
if not ak then
if aj~=nil then ab.MouseIconEnabled=aj;aj=nil end
return
end
if aj==nil then aj=ab.MouseIconEnabled end
z.connect("hideCursor",ac.RenderStepped,function()
if not l.mouseFree then ab.MouseIconEnabled=false end
end)
end
def({"hidecursor","hidemouse"},"","Hide the Roblox cursor (it still shows while the panel or command bar is open)","mouse pointer cursor hide invisible",function()z.hideCursor(true)end)
def({"unhidecursor","unhidemouse"},"","Show the Roblox cursor again","mouse pointer cursor show",function()z.hideCursor(false)end)
end


def({"showfps","showperf","showping"},"","Show FPS and ping in a corner (corner set in Module Cfg)","performance frame rate latency overlay",function()
if n.showHud then n.showHud(true)end
active("showfps",true)
end)
def({"unshowfps","hidefps","unshowping","hideping","unshowperf","hideperf"},"","Hide the FPS / ping overlay","performance overlay",function()
if n.showHud then n.showHud(false)end
active("showfps",nil)
end)












do
local aj={on=false,gen=0,core={},top=nil,chat={},guis={},conns={},hooked={}}
local ak={KLOSAD=true,KLCrosshair=true,TouchGui=true,RobloxPromptGui=true,RobloxNetworkGui=true}
local function roots()
local al={}
if l.CoreGui then al[#al+1]=l.CoreGui end
local am=A:FindFirstChildOfClass"PlayerGui"
if am then al[#al+1]=am end
if gethui then
local an,ao=pcall(gethui)
if an and typeof(ao)=="Instance"and ao~=l.CoreGui and ao~=am then al[#al+1]=ao end
end
return al
end
local function chatCfgs()
local al={}
for am,an in ipairs{"ChatWindowConfiguration","ChatInputBarConfiguration","BubbleChatConfiguration"}do
local ao=z.TextChatService:FindFirstChildOfClass(an)
if ao then al[#al+1]=ao end
end
return al
end
local function take(al)
if not al:IsA"ScreenGui"or ak[al.Name]then return end
if aj.guis[al]==nil then
aj.guis[al]=al.Enabled
aj.conns[#aj.conns+1]=al:GetPropertyChangedSignal"Enabled":Connect(function()
if aj.on then pcall(function()if al.Enabled then al.Enabled=false end end)end
end)
end
if al.Enabled then al.Enabled=false end
end

local function apply(al)
local am=z.StarterGui
local function current()return aj.on and aj.gen==al end
if not current()then return end
for an,ao in ipairs(roots())do
if not aj.hooked[ao]then
aj.hooked[ao]=true
aj.conns[#aj.conns+1]=ao.ChildAdded:Connect(function(ap)
if aj.on then task.defer(pcall,take,ap)end
end)
end
for ap,aq in ipairs(ao:GetChildren())do pcall(take,aq)end
end
for an in pairs(aj.guis)do if not an.Parent then aj.guis[an]=nil end end
for an,ao in ipairs(Enum.CoreGuiType:GetEnumItems())do
if ao~=Enum.CoreGuiType.All then
local ap,aq=pcall(am.GetCoreGuiEnabled,am,ao)
if ap and type(aq)=="boolean"then
if aj.core[ao]==nil then aj.core[ao]=aq end
if aq then pcall(am.SetCoreGuiEnabled,am,ao,false)end
end
end
end
for an,ao in ipairs(chatCfgs())do
local ap,aq=pcall(function()return ao.Enabled end)
if ap then
if aj.chat[ao]==nil then aj.chat[ao]=aq end
if aq then pcall(function()ao.Enabled=false end)end
end
end
local an,ao=pcall(am.GetCore,am,"TopbarEnabled")
if not current()then return end
if an and type(ao)=="boolean"then
if aj.top==nil then aj.top=ao end
if ao then pcall(am.SetCore,am,"TopbarEnabled",false)end
end
end
local function restore()
local al=z.StarterGui
for am,an in ipairs(aj.conns)do pcall(function()an:Disconnect()end)end
for am,an in pairs(aj.guis)do
if am.Parent then pcall(function()am.Enabled=an end)end
end
for am,an in pairs(aj.core)do pcall(al.SetCoreGuiEnabled,al,am,an)end
if aj.top~=nil then pcall(al.SetCore,al,"TopbarEnabled",aj.top)end
for am,an in pairs(aj.chat)do pcall(function()am.Enabled=an end)end
aj.core,aj.top,aj.chat,aj.guis,aj.conns,aj.hooked={},nil,{},{},{},{}
end
def({"hideui","hidegui"},"","Hide every interface: Roblox button, menu, player list, chat and mic buttons, backpack and the game's own GUIs (rOSAD's panel and bar stay usable)","ui gui hud interface topbar menu roblox button playerlist chat mic voice buttons clean screenshot record clip",function()
if aj.on then return end
aj.on,aj.gen=true,aj.gen+1
local al=aj.gen
if n.actHolder then n.actHolder.Visible=false end
task.spawn(function()
while aj.on and aj.gen==al and l.alive do
pcall(apply,al)
task.wait(0.5)
end
end)
end)
def({"unhideui","showui","unhidegui"},"","Bring every interface back exactly as it was before ;hideui","ui gui hud interface topbar menu roblox button playerlist chat mic voice buttons show restore",function()
aj.on,aj.gen=false,aj.gen+1
restore()
if n.actHolder then n.actHolder.Visible=true end
end)
end





do
local aj="https://raw.githubusercontent.com/waterpb/KL-rOSAD-Components/refs/heads/main/Liu%20Stock%20Presets.json"
local ak="LightingUtilityPresets"
local function ensureDir(al)
local am=""
for an in al:gmatch"[^/]+"do
am=am==""and an or(am.."/"..an)
if not isfolder(am)then makefolder(am)end
end
end
local function fileName(al)
local am=(al:gsub('[\\/:*?"<>|%c]',""))
am=(am:gsub("^%s+",""):gsub("[%s%.]+$",""))
return am
end
local function updateLiu()
z.notify("LiU: downloading presets...",3)
local al,am=z.fetch(aj)
if not al then return z.notify("LiU: download failed ("..tostring(am)..")",6)end
al=al:gsub("^\239\187\191","")
local an,ao=pcall(ensureDir,ak)
if not an then return z.notify("LiU: can't create "..ak.." ("..tostring(ao)..")",6)end
local ap,aq,ar,as,at=0,0,0,0,0
for au in al:gmatch"[^\r\n]+"do
local av,aw=au:match"^%s*LUTPRESET::(.-):+(%b{})%s*$"
local ax=av and fileName(av)
local ay,az=pcall(l.HttpService.JSONDecode,l.HttpService,aw or"")
if ax and ax~=""and ay and type(az)=="table"then
local aA=ak.."/"..ax..".json"
local aB=isfile(aA)
local aC,aD=false
if aB then aC,aD=pcall(readfile,aA)end
if aC and aD==aw then
ar=ar+1
elseif pcall(writefile,aA,aw)then
if aB then aq=aq+1 else ap=ap+1 end
else
as=as+1
end
elseif au:match"%S"then
as=as+1
end
at=at+1
if at%10==0 then task.wait()end
end
if ap+aq+ar+as==0 then return z.notify("LiU: the downloaded file has no presets",6)end
z.notify(("LiU presets: %d new, %d updated, %d unchanged%s (%s)"):format(ap,aq,ar,as>0 and(", "..as.." skipped")or"",ak),7)
end
local function updateRosad()
if m==""then return z.notify("rOSAD: no SELF_URL set to download from",6)end
if not q then return z.notify("rOSAD update needs loadstring, this executor has none",6)end
z.notify("rOSAD: downloading the newest version...",3)
local al,am=z.fetch(m)
if not al then return z.notify("rOSAD: download failed ("..tostring(am)..")",6)end
al=al:gsub("^\239\187\191","")
if not(al:find("KL rOSAD v",1,true)and al:find("local BUILTIN",1,true))then return z.notify("rOSAD: that file is not rOSAD, nothing changed",6)end
local an,ao=loadstring(al)
if not an then return z.notify("rOSAD: the download does not compile ("..tostring(ao).."), nothing changed",8)end
local ap,aq=al:match'local VERSION = "([^"]+)"'or"?",b.."/KL_rOSAD.lua"
local ar=pcall(function()assert(readfile(aq)==al)end)
if ar and ap==a then return z.notify("rOSAD is up to date (v"..a..")",4)end
pcall(function()
if not isfolder(b)then makefolder(b)end
writefile(aq,al)
end)
z.notify("rOSAD v"..ap.." downloaded, restarting...",3)
task.delay(0.6,function()task.spawn(an)end)
end
local al={
rosad={desc="rOSAD itself: download the newest version from GitHub and restart into it",run=updateRosad},
liu={desc="Lighting Utility: download its presets, one .json per preset",run=updateLiu},
}
local am={klosad="rosad",osad="rosad",self="rosad",script="rosad",lighting="liu",lightingutility="liu",liupresets="liu",presets="liu"}
def({"update"},"<liu | rosad | all>","Download the newest data of a tool from GitHub (liu = Lighting Utility's presets, one .json file per preset; rosad = rOSAD itself)","update download github presets lighting liu refresh",function(an)
an=tostring(an or""):lower()
if an==""then return z.notify"Usage: update <liu | rosad | all>"end
if not(writefile and readfile and isfile and isfolder and makefolder)then return z.notify("update needs file access, this executor has none",5)end
if an=="all"then
local ao={}
for ap in pairs(al)do if ap~="rosad"then ao[#ao+1]=ap end end
table.sort(ao)
for ap,aq in ipairs(ao)do al[aq].run()end
return
end
local ao=al[am[an]or an]
if not ao then return z.notify("Unknown update target '"..an.."'. Try: liu, rosad, all")end
ao.run()
end)
z.Meta.update.complete=function(an)
local ao={}
if an==1 then
for ap,aq in pairs(al)do ao[#ao+1]={text=ap,desc=aq.desc}end
ao[#ao+1]={text="all",desc="Update every target"}
end
return ao
end
end







do
local aj={tags={},folder=nil}
local function holder()
if aj.folder and aj.folder.Parent then return aj.folder end
local ak=Instance.new"Folder"
ak.Name="_klPlayerNames"
pcall(function()ak.Parent=(gethui and gethui())or l.CoreGui end)
if not ak.Parent then ak.Parent=A:FindFirstChildOfClass"PlayerGui"end
aj.folder=ak
return ak
end
local function sweep()
local ak={}
for al,am in ipairs(ad:GetPlayers())do
if am~=A then
ak[am]=true
local an=am.Character
local ao=an and(an:FindFirstChild"Head"or an:FindFirstChild"HumanoidRootPart")
local ap=aj.tags[am]
if not(ap and ap.gui.Parent)then
local aq=Instance.new"BillboardGui"
aq.Name,aq.Size,aq.AlwaysOnTop,aq.MaxDistance,aq.LightInfluence,aq.ResetOnSpawn="_klName",UDim2.fromOffset(200,20),true,math.huge,0,false
local ar=Instance.new"TextLabel"
ar.Size,ar.BackgroundTransparency,ar.Text,ar.Font,ar.TextSize=UDim2.fromScale(1,1),1,am.Name,Enum.Font.GothamBold,14
ar.TextStrokeTransparency,ar.TextStrokeColor3=0,Color3.new(0,0,0)
ar.Parent=aq
aq.Parent=holder()
ap={gui=aq,label=ar}
aj.tags[am]=ap
end
if ao~=ap.gui.Adornee then
ap.gui.Adornee=ao
ap.gui.StudsOffset=Vector3.new(0,(ao and ao.Name=="Head")and 2.2 or 4.6,0)
end
ap.label.TextColor3=am.Team and am.TeamColor.Color or Color3.new(1,1,1)
end
end
for al,am in pairs(aj.tags)do
if not ak[al]then pcall(function()am.gui:Destroy()end);aj.tags[al]=nil end
end
end
def({"playernames","usernames","shownames"},"","Show every player's username above them at any distance, through walls, even when their avatar is hidden (;hidenames turns it off)","name username tag nametag overhead esp player distance far visible show",function()
sweep()
local ak=0
z.connect("playerNames",ac.Heartbeat,function(al)
ak=ak+al
if ak<0.25 then return end
ak=0
pcall(sweep)
end)
end)
def({"hidenames","unplayernames","unusernames"},"","Remove the username tags that ;playernames added","name username tag nametag overhead hide remove off",function()
z.disconnect"playerNames"
for ak,al in pairs(aj.tags)do pcall(function()al.gui:Destroy()end);aj.tags[ak]=nil end
if aj.folder then pcall(function()aj.folder:Destroy()end);aj.folder=nil end
end)
end




do
local aj={
chat={swearing="Swearing",bullying="Bullying",scamming="Scamming",dating="Dating",personal="Personal Question",links="Offsite Links"},
username={inappropriate="Inappropriate Username"},
voice={swearing="Swearing",bullying="Bullying",scamming="Scamming",dating="Dating",personal="Personal Question",links="Offsite Links"},
exploit={cheating="Cheating/Exploiting"},
}
local ak={chat="Something they said in chat",voice="Something they said in voice chat",username="Their username",exploit="Cheating / exploiting"}
local function keys(al)local am={}for an in pairs(al)do am[#am+1]=an end table.sort(am)return table.concat(am,", ")end
def({"report"},"<type> <player> <reason> [additional]","Report a player to Roblox (types: chat, voice, username, exploit). The bar fills in types, players and reasons","report abuse moderation chat exploit cheating scam bully swear",function(al,am,an,...)
if not(al and am)then return z.notify"Usage: report <type> <player> <reason> [additional]"end
local ao=aj[al:lower()]
if not ao then return z.notify("Unknown report type '"..al.."'. Types: "..keys(aj),5)end
if({me=1,all=1,others=1,random=1})[am:lower()]then return z.notify"Report one player by name"end
local ap=z.findPlayer(am)
if not ap then return end
if ap==A then return z.notify"You can't report yourself"end
local aq,ar=an and ao[an:lower()],{...}
if not aq then
local as,at=0
for au,av in pairs(ao)do at,as=av,as+1 end
if as==1 and not an then aq=at
else return z.notify("Pick a reason for "..al:lower()..": "..keys(ao),6)end
end
local as=table.concat(ar," "):sub(1,200)

if al:lower()=="voice"then as=(("[Voice chat] "..as):gsub("%s+$","")):sub(1,200)end
local at,au=pcall(function()z.Players:ReportAbuse(ap,aq,as)end)
if at then return z.notify("Reported "..ap.Name.." for "..aq..(as~=""and(": "..as)or""),5)end


local av=("%s | %s%s"):format(ap.Name,aq,as~=""and(" | "..as)or"")
if setclipboard then pcall(setclipboard,av)end
pcall(function()l.GuiService:SetMenuIsOpen(true)end)
z.notify("Scripts can't send reports ("..tostring(au):sub(1,70).."). Roblox's menu is open: Report > Person > "..ap.Name.." > "..aq..(setclipboard and". Your note is copied."or""),10)
end)
z.Meta.report.complete=function(al,am,an)
local ao={}
if al==1 then
for ap in pairs(aj)do ao[#ao+1]={text=ap,desc=ak[ap]}end
elseif al==2 then
for ap,aq in ipairs(ad:GetPlayers())do
if aq~=A then ao[#ao+1]={text=aq.Name,desc=aq.DisplayName~=aq.Name and aq.DisplayName or""}end
end
elseif al==3 then
for ap,aq in pairs(aj[(an[1]or""):lower()]or{})do ao[#ao+1]={text=ap,desc=aq}end
end
table.sort(ao,function(ap,aq)return ap.text:lower()<aq.text:lower()end)
return ao
end
end


def({"text","chat","t"},"<message>","Send a chat message","say talk message",function(...)
local aj=table.concat({...}," ")
if aj==""then return z.notify"Usage: text <message>"end
local ak=pcall(function()z.TextChatService.TextChannels.RBXGeneral:SendAsync(aj)end)
if not ak then
pcall(function()game:GetService"ReplicatedStorage".DefaultChatSystemChatEvents.SayMessageRequest:FireServer(aj,"All")end)
end
end)


local function mode(aj)
local ak,al,am={},0
for an,ao in ipairs(aj)do
local ap=math.floor(ao*100+0.5)
ak[ap]=(ak[ap]or 0)+1
if ak[ap]>al then am,al=ao,ak[ap]end
end
return am
end


local function serverHumanoid()
local aj,ak,al,am={},{},{},{}
for an,ao in ipairs(ad:GetPlayers())do
local ap=ao~=A and ao.Character and ao.Character:FindFirstChildOfClass"Humanoid"
if ap then
aj[#aj+1]=ap.WalkSpeed
if ap.UseJumpPower then ak[#ak+1]=ap.JumpPower else al[#al+1]=ap.JumpHeight end
am[#am+1]=ap.UseJumpPower and 1 or 0
end
end
return mode(aj),mode(ak),mode(al),mode(am)
end
def({"gamedefault","default","reffect","reseteffects"},"","Reset every command's changes back to the server's defaults","reset restore undo",function()
z.resetAll()
local aj,ak=B.defaults,z.hum()
local al,am,an,ao=serverHumanoid()
if ak then
local ap
if ao~=nil then ap=ao==1 else ap=aj.ujp~=false end
ak.WalkSpeed=al or aj.ws
ak.UseJumpPower=ap
ak.JumpPower,ak.JumpHeight=am or aj.jp,an or aj.jh
ak.HipHeight,ak.AutoRotate,ak.PlatformStand=aj.hip,true,false
workspace.CurrentCamera.CameraSubject=ak
end
workspace.Gravity=aj.grav
workspace.CurrentCamera.FieldOfView=aj.fov
pcall(function()
A.CameraMinZoomDistance=l.StarterPlayer.CameraMinZoomDistance
A.CameraMaxZoomDistance=l.StarterPlayer.CameraMaxZoomDistance
end)
for ap,aq in pairs(B.saved.light or aj.light)do z.Lighting[ap]=aq end
B.saved.light=nil
z.lockFps(nil)
if setfpscap then pcall(setfpscap,60)end
z.notify"Back to the game's defaults"
end)



do
local aj={"fly","cfly","noclip","float","jesus","tpwalk","infjump","spin","look","freeze","follow"}
local function off(ak)
local al,am=z.hum(),B.defaults
if ak=="gravity"then workspace.Gravity=am.grav;return true end
if ak=="speed"or ak=="jumppower"then
local an,ao,ap,aq=serverHumanoid()
if al and ak=="speed"then al.WalkSpeed=an or am.ws end
if al and ak=="jumppower"then
if aq~=nil then al.UseJumpPower=aq==1 else al.UseJumpPower=am.ujp~=false end
al.JumpPower,al.JumpHeight=ao or am.jp,ap or am.jh
end
return true
end
if D[ak]then z.Run(D[ak]);B.active[ak]=nil;return true end
end
def({"clear","cls"},"[effect...]","Clear movement effects (fly, noclip, float, walkspeed...), or only the ones you name","reset stop off movement",function(...)
local ak={...}
if#ak==0 then
for al,am in ipairs(aj)do if B.active[am]then off(am)end end
for al,am in ipairs{"speed","jumppower","gravity"}do off(am)end
return z.notify"Cleared movement effects"
end
for al,am in ipairs(ak)do
local an=z.Aliases[am:lower()]
if not(an and off(an))then z.notify("Can't clear \""..am.."\"")end
end
end)
end



local aj={[15546218972]=true,[6884319169]=true}




do
local ak={cells={}}
local function gameBase()
for al,am in ipairs(workspace:GetDescendants())do
if am:IsA"BasePart"and(am.Size-Vector3.new(648,16,648)).Magnitude<0.5 and(am.Position-Vector3.new(8,-8,-482)).Magnitude<0.5 then return am end
end
end
function z.baseplate(al)
z.disconnect"baseplate"
for am,an in pairs(ak.cells)do pcall(an.v.Destroy,an.v);pcall(an.c.Destroy,an.c)end
ak.cells,B.baseParts={},{}
if not al then return true end

local am,an=(gameBase())
if am then
an=am.Position.Y+am.Size.Y/2
else
local ao=z.root()
if not ao then return false,"No character"end
local ap=RaycastParams.new()
ap.FilterType=Enum.RaycastFilterType.Exclude
ap.FilterDescendantsInstances={z.char()}
local aq=workspace:Raycast(ao.Position,Vector3.new(0,-300,0),ap)
if not(aq and aq.Instance:IsA"BasePart")then return false,"Stand on the baseplate first, then run baseplate"end
am,an=aq.Instance,aq.Position.Y
end

local ao,ap,aq,ar=math.huge,-math.huge,math.huge,-math.huge
local function add(as)
if math.abs(as.Position.Y+as.Size.Y/2-an)>0.5 then return end
local at,au=as.CFrame,as.Size
local av,aw,ax=at.RightVector,at.UpVector,at.LookVector
local ay=(math.abs(av.X)*au.X+math.abs(aw.X)*au.Y+math.abs(ax.X)*au.Z)/2
local az=(math.abs(av.Z)*au.X+math.abs(aw.Z)*au.Y+math.abs(ax.Z)*au.Z)/2
ao,ap=math.min(ao,as.Position.X-ay),math.max(ap,as.Position.X+ay)
aq,ar=math.min(aq,as.Position.Z-az),math.max(ar,as.Position.Z+az)
end
add(am)
for as,at in ipairs(workspace:GetDescendants())do
if at:IsA"BasePart"and at~=am and(at.Name=="platform"or(at.Parent and at.Parent.Name=="extra_room"))then add(at)end
end
local as,at=ao,aq
local au,av=math.min(ap-ao,2048),math.min(ar-aq,2048)
local aw={}
for ax,ay in ipairs(am:GetChildren())do if ay:IsA"Texture"then aw[#aw+1]=ay end end
local ax=u(25,25,25)

local ay,az=0.1,0
local function make()
local aA=Instance.new"Part"
aA.Name,aA.Anchored,aA.CanCollide,aA.CanTouch,aA.CanQuery,aA.CastShadow,aA.Locked="_baseplateExt",true,false,false,false,false,true
aA.Material,aA.Transparency,aA.Color,aA.Reflectance=Enum.Material.SmoothPlastic,0.5,ax,0.1
aA.TopSurface,aA.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
aA.Size=Vector3.new(au,ay,av)
for aB,aC in ipairs(aw)do
local aD=aC:Clone()
aD.Parent=aA
end
aA.Parent=workspace
local aB=Instance.new"Part"
aB.Name,aB.Anchored,aB.CanCollide,aB.CanTouch,aB.CastShadow,aB.Locked,aB.Transparency="_baseplateExtCol",true,true,false,false,true,1
aB.Size=Vector3.new(au,16,av)
aB.Parent=workspace
return{v=aA,c=aB}
end
local function sync()
local aA={}
local function around(aB)
if not aB then return end
local aC,aD=math.floor((aB.X-as)/au),math.floor((aB.Z-at)/av)
for aE=-2,2 do
for O=-2,2 do
local P,Q=aC+aE,aD+O
if P~=0 or Q~=0 then aA[P..","..Q]=Vector2.new(P,Q)end
end
end
end
local aB=z.root()
around(aB and aB.Position)
around(workspace.CurrentCamera and workspace.CurrentCamera.Focus.Position)
local aC={}
for aD,aE in pairs(ak.cells)do
if not aA[aD]or not aE.v.Parent or not aE.c.Parent then
ak.cells[aD]=nil
if aE.v.Parent and aE.c.Parent then aC[#aC+1]=aE else pcall(aE.v.Destroy,aE.v);pcall(aE.c.Destroy,aE.c)end
end
end
for aD,aE in pairs(aA)do
if not ak.cells[aD]then
local O=table.remove(aC)or make()
local P,Q=as+(aE.X+0.5)*au,at+(aE.Y+0.5)*av
O.v.CFrame=CFrame.new(P,an-az-ay/2,Q)
O.c.CFrame=CFrame.new(P,an-az-8,Q)
ak.cells[aD]=O
end
end
for aD,aE in ipairs(aC)do aE.v:Destroy();aE.c:Destroy()end
local aD={}
for aE,O in pairs(ak.cells)do aD[#aD+1]=O.v;aD[#aD+1]=O.c end
B.baseParts=aD
end
sync()
local aA=0
z.connect("baseplate",l.RunService.Heartbeat,function(aB)
aA=aA+aB
if aA<0.25 then return end
aA=0
sync()
end)
return true
end
end
def({"baseplate"},"","Endless smooth plastic baseplate in MIC UP / MIC UP 18+: very dark grey, 50% opacity, 10% reflectance, with the game's own texture; the game's baseplate stays as it is. Follows you and the camera","map floor ground mic up glass infinite endless",function()
if not(aj[game.PlaceId]or tostring(game.Name):lower():find("mic up",1,true))then
return z.notify("baseplate only works in MIC UP and MIC UP 18+ (this is place "..game.PlaceId..")",5)
end
local ak,al=z.baseplate(true)
z.notify(ak and"Baseplate extended: endless smooth plastic floor (only you can see and stand on it)"or al,5)
end)

def({"removebaseplate","nobaseplate"},"","Remove the baseplate that ;baseplate added (the game's own was never touched)","map floor ground delete void",function()
if#(B.baseParts or{})==0 then return z.notify"No extended baseplate to remove"end
z.baseplate(false)
z.notify"Removed the extended baseplate"
end)



function z.matchPlayers(ak,al)
al=al or l.Players:GetPlayers()
local am,an,ao=tostring(ak):lower(),tonumber(ak),{{},{},{},{}}
for ap,aq in ipairs(al)do
local ar,as=aq.Name:lower(),aq.DisplayName:lower()
local at=((an and aq.UserId==an)or ar==am)and 1 or as==am and 2 or(ar:sub(1,#am)==am or as:sub(1,#am)==am)and 3 or(ar:find(am,1,true)or as:find(am,1,true))and 4 or nil
if at then table.insert(ao[at],aq)end
end
for ap,aq in ipairs(ao)do if#aq>0 then return aq end end
return{}
end
do
local ak=z.selftest
function z.selftest()
local al,am,an={Name="Fread",DisplayName="Bob",UserId=11},{Name="bobby",DisplayName="Rob",UserId=22},{Name="xbobx",DisplayName="Bob",UserId=33}
local ao={al,am,an}
assert(z.matchPlayers("fread",ao)[1]==al and#z.matchPlayers("fread",ao)==1,"player: exact username")
assert(#z.matchPlayers("bob",ao)==2,"player: a shared display name is ambiguous")
assert(z.matchPlayers("bobb",ao)[1]==am,"player: start of a name")
assert(z.matchPlayers("22",ao)[1]==am,"player: user id")
assert(#z.matchPlayers("zzz",ao)==0,"player: no match")
ak()
end
end
def({"player"},"<player>","Open the Players tab, or straight into a player's profile (username, display name or user id; the start is enough)","profile card avatar outfit friends info players",function(ak)
if not ak or ak==""or ak:lower()=="all"or ak:lower()=="others"then
if n.closeProfile then n.closeProfile(true)end
return z.openTab"Players"
end
local al=ak:lower()=="me"and{A}or z.matchPlayers(ak)
if#al==1 then return n.openProfile(al[1])end
if n.closeProfile then n.closeProfile(true)end
z.openTab"Players"
if#al==0 then return z.notify("No player in this server matches '"..ak.."'",4)end
if n.plSearch then n.plSearch(ak)end
local am={}
for an=1,math.min(#al,4)do am[an]=al[an].Name end
z.notify(("%d players match '%s': %s%s. Pick one in the list"):format(#al,ak,table.concat(am,", "),#al>4 and", ..."or""),5)
end)



local ak={
liu={title="LiU",names={"liu","lighting","lightingutility"},builtin="Lighting Utility",github="LiU"},
dex={title="Dex++",names={"dex","explorer","dexpp"},builtin="Dex",github="Dex++"},
cobalt={title="Cobalt",names={"cobalt","cspy","cobaltspy"},builtin="Cobalt",github="Cobalt"},
kelsec={title="Kelsec",names={"kelsec","executor","exec"},builtin="Kelsec",github="Kelsec"},
workwell={title="WorkWell",names={"workwell"},builtin="WorkWell",github="WorkWell"},
hlxp={title="KL HL XP",names={"hlxp"},builtin="KL HL XP",github="HLXP",
onKill=function()if c.__HLXP_SHUTDOWN then pcall(c.__HLXP_SHUTDOWN)end end},
vcb={title="VC Bypasser",names={"vcb","vcbypass"},github="VC Bypasser",onKill=function()z.bus.fire("vcb:cmd","kill")end,onOpen=function()z.bus.fire("vcb:cmd","open")end},
rspy={title="RSpy",names={"rspy","simplespy","remotespy"},github="RSpy"},
alogger={title="ALogger",names={"alogger","audiologger"},github="ALogger"},
tetris={title="Tetris",names={"tetris"},github="Tetris"},
wwapf={title="WWA Phantom Forces",names={"workwellpf","wwapf"},github="WWA Phantom Forces (Workwell)"},
tooleditor={title="Tool Properties Editor",names={"tooleditor","properties","toolproperties"},github="Tool Properties Editor"},
klpfxp={title="KL PF XP",names={"klpfxp","pfxp"},github="KL PF XP"},
}
local al={}
for am,an in pairs(ak)do
for ao,ap in ipairs(an.names)do al[ap]=am end
end
local function toolSource(am)
for an,ao in ipairs(g)do
if ao.name==am.builtin and(ao.src:gsub("%-%-[^\n]*","")):match"%S"then return ao.src end
end
if am.github then
for an,ao in ipairs(h)do
if ao.name==am.github then
local ap,aq=z.fetch(ao.url)
if ap then return ap end
return nil,"download failed ("..tostring(aq)..")"
end
end
end
return nil,"no source yet. Paste it into the '"..tostring(am.builtin).."' slot in KL_rOSAD.lua, or add a GITHUB link for it"
end
local function guiRoots()
local am={}
pcall(function()am[#am+1]=l.CoreGui end)
pcall(function()am[#am+1]=A.PlayerGui end)
if gethui then pcall(function()am[#am+1]=gethui()end)end
return am
end
local function snapshot()
local am={}
for an,ao in ipairs(guiRoots())do
for ap,aq in ipairs(ao:GetChildren())do am[aq]=true end
end
return am
end
local function openTool(am)
local an,ao=ak[am],B.tools[am]
if ao then
local ap=false
for aq,ar in ipairs(ao.guis)do
if ar.Parent then
ap=true
pcall(function()if ar:IsA"ScreenGui"then ar.Enabled=true end end)
end
end
if ap then
if an.onOpen then an.onOpen()end
return z.notify(an.title.." reopened")
end
end
local ap,aq=toolSource(an)
if not ap then return z.notify(an.title..": "..aq,5)end
local ar=snapshot()
ao={guis={},conns={}}
B.tools[am]=ao


local function track(as)
if as.Name~="KLOSAD"and not ar[as]and as:IsA"ScreenGui"then ao.guis[#ao.guis+1]=as end
end
for as,at in ipairs(guiRoots())do
ao.conns[#ao.conns+1]=at.ChildAdded:Connect(track)
end
z.runSource(ap,an.title)
task.delay(25,function()
for as,at in ipairs(ao.conns)do at:Disconnect()end
ao.conns={}
end)
end

local function killByName(am)
local an,ao={am,ak[am].title:lower()},0
for ap,aq in ipairs(guiRoots())do
for ar,as in ipairs(aq:GetChildren())do
local at=as.Name:lower()
if at~="klosad"then
for au,av in ipairs(an)do
if at:sub(1,#av)==av then pcall(function()as:Destroy()end);ao=ao+1;break end
end
end
end
end
return ao>0
end

local function killTool(am)
local an=B.tools[am]
if not an then return false end
for ao,ap in ipairs(an.conns or{})do ap:Disconnect()end
if ak[am].onKill then ak[am].onKill()end
local ao=0
for ap,aq in ipairs(an.guis)do
if aq.Parent then pcall(function()aq:Destroy()end);ao=ao+1 end
end
B.tools[am]=nil
l.launched["tool:"..am]=nil
return ao>0 or ak[am].onKill~=nil
end
z.openTool=openTool

z.toolKey={["Dex++"]="dex",Dex="dex",Cobalt="cobalt",Kelsec="kelsec",WorkWell="workwell",
["Lighting Utility"]="liu",LiU="liu",HLXP="hlxp",["KL HL XP"]="hlxp",RSpy="rspy",ALogger="alogger",
Tetris="tetris",["WWA Phantom Forces (Workwell)"]="wwapf",["Tool Properties Editor"]="tooleditor",["KL PF XP"]="klpfxp",["VC Bypasser"]="vcb"}
z.killTools=function()
for am in pairs(ak)do
killTool(am)
killByName(am)
end
end
def({"hlxp"},"","Load KL HL XP (half-life movement and physics)","movement physics half life",function()openTool"hlxp"end)
def({"liu","lighting","lightingutility"},"","Open LiU (Lighting Utility)","lighting camera blur shaders",function()openTool"liu"end)
def({"dex","explorer","dexpp"},"","Open Dex++ Explorer (loads once, then reopens)","explorer instances tree",function()openTool"dex"end)
def({"cobalt","cspy","cobaltspy"},"","Open Cobalt remote spy","remote spy",function()openTool"cobalt"end)
def({"kelsec","executor","exec"},"","Open Kelsec, the in-game executor (loads once, then reopens)","execute script run",function()openTool"kelsec"end)
def({"rspy","simplespy","remotespy"},"","Open RSpy (SimpleSpy V3 remote spy)","remote spy",function()openTool"rspy"end)
def({"alogger","audiologger"},"","Open ALogger (logs sounds as they play)","audio sound log",function()openTool"alogger"end)
def({"workwell"},"","Open WorkWell aim assist","aim assist",function()openTool"workwell"end)
def({"tetris"},"","Load Tetris (;untetris closes it)","game play",function()openTool"tetris"end)
def({"untetris"},"","Unload Tetris","game close stop",function()
local am=killTool"tetris"
local an=killByName"tetris"
z.notify((am or an)and"Tetris closed"or"Tetris isn't loaded")
end)

z.bus.on("vcb:state",function(am)B.vcb=(am and not am.closed)and am or nil end)

n.actClick=n.actClick or{}
n.actClick.vcbypass=function()z.bus.fire("vcb:cmd","open")end
function n.vcbText()
local am=B.vcb
if am and am.executed then return am.muted and"muted"or"bypassed"end
end
def({"vcb","vcbypass"},"[mute|unmute|v1|v2|run|close]","Opens the voice chat bypass module. Prevents you from getting kicked from voice chat (optional: mute, unmute, v1, v2, run or close)","voice chat vc bypass kick mute",function(am)
local an=(am or""):lower()
if an==""then an="toggle"end
if B.vcb then return z.bus.fire("vcb:cmd",an)end
openTool"vcb"
task.spawn(function()
for ao=1,40 do if B.vcb then break end task.wait(0.25)end
if B.vcb and an~="toggle"and an~="open"then z.bus.fire("vcb:cmd",an)end
end)
end)
def({"workwellpf","wwapf"},"","Load WorkWell for Phantom Forces (;kill wwapf closes it)","aim assist phantom forces pf",function()openTool"wwapf"end)
def({"properties","tooleditor"},"","Load the Tool Properties Editor (;kill tooleditor closes it)","tool properties edit inventory",function()openTool"tooleditor"end)
def({"klpfxp","pfxp"},"","Load KL PF XP, Half-Life / GoldSrc movement in Phantom Forces (;kill klpfxp closes it)","movement phantom forces pf half life",function()openTool"klpfxp"end)
def({"kill"},"<tool>","Close a loaded tool: dex, kelsec, cobalt, rspy, alogger, workwell, liu, hlxp, tetris, wwapf, tooleditor, klpfxp, all","close unload stop tool",function(am)
if not am then return z.notify"Usage: kill <dex|kelsec|cobalt|rspy|alogger|workwell|liu|hlxp|tetris|wwapf|tooleditor|klpfxp|all>"end
am=am:lower()
if am=="all"then z.killTools();return z.notify"Closed every loaded tool"end
local an=al[am]
if not an then return z.notify("Unknown tool: "..am)end

local ao=killTool(an)
local ap=killByName(an)
z.notify((ao or ap)and(ak[an].title.." closed")or(ak[an].title.." isn't loaded"))
end)

def({"saveinstance","save"},"[dec]","Save the game without humanoids and players (dec = decompile scripts)","save map download place",function(am)
if not saveinstance then return z.notify"This executor has no saveinstance"end
local an=am and(am:lower()=="dec"or am:lower()=="decompile")or false
local ao={}
for ap,aq in ipairs(ad:GetPlayers())do
if aq.Character then ao[#ao+1]=aq.Character end
end
for ap,aq in ipairs(workspace:GetDescendants())do
if aq:IsA"Humanoid"and aq.Parent then ao[#ao+1]=aq.Parent end
end
z.notify"Saving..."
task.spawn(function()
local ap,aq=pcall(saveinstance,{Decompile=an,SavePlayers=false,IgnoreList=ao,ExcludeNames={},mode="optimized"})
if not ap then ap,aq=pcall(saveinstance)end
z.notify(ap and"Saved to your executor's workspace folder"or("Save failed: "..tostring(aq)))
end)
end)
def({"freezesave","fsave","freezesaveinstance"},"[dec]","Save the game with humanoids and players (Freeze Instance Saver)","save map download place",function(am)
c.KLOSAD_DECOMPILE=am and(am:lower()=="dec"or am:lower()=="decompile")or false
for an,ao in ipairs(h)do
if ao.name=="Freeze Instance Saver"then
local ap,aq=z.fetch(ao.url)
if ap then return z.runSource(ap,ao.name)end
return z.notify(ao.name..": download failed ("..tostring(aq)..")")
end
end
end)
def({"ui","openui"},"","Open the panel","panel window",function()n.setPanel(true)end)
def({"exit"},"","Exit rOSAD and every tool it started","quit close unload",function()
z.killTools()
if c.NameSpoof and c.NameSpoof.Destroy then pcall(c.NameSpoof.Destroy)end
if _G.__NoSitCleanup then pcall(_G.__NoSitCleanup)end
n.unload()
end)
def({"cmds","cmd","commands"},"","Open the Commands tab","help list",function()z.openTab"Commands"end)




local function loaderLine()
local am={}
if s.selfPath~=""then am[#am+1]=("%q"):format(s.selfPath)end
am[#am+1]=("%q"):format(b.."/KL_rOSAD.lua")

return('local g = (getgenv and getgenv()) or _G if g.KLOSAD_LD and os.time() - g.KLOSAD_LD < 30 then return end g.KLOSAD_LD = os.time() if not game:IsLoaded() then game.Loaded:Wait() end task.wait(1) local ok, e = pcall(function() if "%s" ~= "" then local okh, src = pcall(game.HttpGet, game, "%s") local fn = okh and type(src) == "string" and loadstring(src) if fn then fn() return end end for _, p in ipairs({%s}) do if isfile and isfile(p) then loadstring(readfile(p))() return end end error("no copy of KL_rOSAD.lua found (and the link did not load)") end) if not ok then warn("[KLOSAD autoexec] " .. tostring(e)) pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "KL rOSAD autoexec", Text = tostring(e):sub(1, 180), Duration = 12 }) end) end'):format(m,m,table.concat(am,", "))
end
local function isSelf(am)
return type(am)=="string"and am:find("KL rOSAD v",1,true)and am:find("open-source admin/dev panel",1,true)and am:find("local BUILTIN",1,true)and true or false
end

local function ensureCopy(am)
local an=b.."/KL_rOSAD.lua"
if not(isfile and writefile and readfile and listfiles and isfolder)then return false end
if not am and(isfile(an)or(s.selfPath~=""and isfile(s.selfPath)))then return true end
local ao,ap=0
local function try(aq)
local ar,as=pcall(readfile,aq)
if ar and isSelf(as)then ap={f=aq,body=as}end
return ap~=nil
end
local function scan(aq,ar)
local as,at=pcall(listfiles,aq)
if not as then return end
for au,av in ipairs(at)do
if ap then return end
if isfolder(av)then
if ar<2 then scan(av,ar+1)end
else
local aw=av:lower():match"%.(%w+)$"
local ax=av:gsub("\\","/")

if(aw=="lua"or aw=="luau"or aw=="txt")and ax:sub(-#an)~=an and ao<300 then
ao=ao+1
try(av)
end
end
end
end
if not(s.selfPath~=""and isfile(s.selfPath)and try(s.selfPath))then
scan("",0)
if not ap then scan(".",0)end
end
if not ap then
if isfile(an)then return true end

if m~=""then
local aq=z.fetch(m)
if isSelf(aq)then
pcall(function()
if makefolder and not isfolder(b)then makefolder(b)end
writefile(an,aq)
end)
if isfile(an)then z.notify("rOSAD: no local copy found, downloaded it from GitHub to "..an,5)end
end
end
return isfile(an)
end
s.selfPath=ap.f
save()
pcall(function()
if makefolder and not isfolder(b)then makefolder(b)end
writefile(an,ap.body)
end)
return true
end
local am={"../autoexec/KLOSAD_autoload.lua","autoexec/KLOSAD_autoload.lua","../../autoexec/KLOSAD_autoload.lua",
"../autoexecute/KLOSAD_autoload.lua","autoexecute/KLOSAD_autoload.lua","../Autoexecute/KLOSAD_autoload.lua","../Autoexec/KLOSAD_autoload.lua"}
function z.setAutoExec(an,ao)
s.autoExec=an and true or false
save()
z.disconnect"autoTp"
if an then
local ap=ensureCopy(not ao)or m~=""
local aq=loaderLine()
local ar=queue_on_teleport and pcall(queue_on_teleport,aq)

if queue_on_teleport then
z.connect("autoTp",A.OnTeleport,function()pcall(queue_on_teleport,loaderLine())end)
end
local as={}
if writefile then
pcall(function()
if makefolder and isfolder and not isfolder(b)then makefolder(b)end
writefile(b.."/KLOSAD_autoload.lua",aq)
end)
for at,au in ipairs(am)do
if pcall(writefile,au,aq)and isfile and isfile(au)then as[#as+1]=au end
end
end
if ao and ap then return end
if not ap then
z.notify("Can't find a copy of this script to load next time. Save it once in your executor's workspace folder (.lua or .txt, any name), then run ;keeposad again",10)
elseif#as>0 then
z.notify("Auto execute on. Loader written to "..as[1]..", it runs on join, hops and rejoins",7)
elseif ar then
z.notify("Auto execute on for hops and teleports. This executor can't write to its autoexec folder: copy "..b.."/KLOSAD_autoload.lua into it once so rOSAD also starts when you open Roblox",10)
else
z.notify("This executor can't write to its autoexec folder and has no queue_on_teleport: copy "..b.."/KLOSAD_autoload.lua into the autoexec folder once",10)
end
elseif not ao then
z.notify"Auto execute off"
pcall(function()
if delfile and isfile then
for ap,aq in ipairs(am)do
if isfile(aq)then delfile(aq)end
end
end
end)
end
end
def({"keeposad"},"","Run rOSAD automatically when you join a game or hop servers","auto execute autoexec startup persist",function()z.setAutoExec(true)end)
def({"unkeeposad"},"","Stop running rOSAD automatically","auto execute autoexec startup",function()z.setAutoExec(false)end)

local an

local function banned()
if an then return end
local ao=os.clock()
an,B.vcban=ao,ao+300
z.notify(s.avc and"Voice chat ban detected. Rejoining in 5 minutes"or"Voice chat ban detected",6)
task.delay(300,function()
if an~=ao then return end
an,B.vcban=nil,nil
if s.avc and l.alive then z.Run"rejoin"end
end)
end
function z.vcbanText()
local ao=math.max(0,math.ceil((B.vcban or 0)-os.clock()))
return(s.avc and"rejoin in "or"")..("%d:%02d"):format(ao//60,ao%60)
end
local ao
function z.setAvc(ap,aq)
s.avc=ap and true or false
save()
if not ao then

pcall(function()
local ar=game:GetService"VoiceChatInternal"
z.connect("avc",ar.PlayerModerated,function(as)
if as==A.UserId then banned()end
end)
ao="event"
end)

pcall(function()
local ar=game:GetService"CoreGui"
local function look(as)
if not(as:IsA"TextLabel"or as:IsA"TextButton")or not as.Parent then return end
if as:FindFirstAncestor"KLOSAD"or as:FindFirstAncestor"ExperienceChat"or as:FindFirstAncestor"Chat"then return end
local at=as.Text:lower()
if at:find("voice chat",1,true)and(at:find("suspend",1,true)or at:find("banned",1,true))then banned()end
end
z.connect("avc",ar.DescendantAdded,function(as)task.delay(0.3,look,as)end)
ao=ao and(ao.." + UI watch")or"UI watch"
end)
end
if aq then return end
if not ap then return z.notify"Auto rejoin on VC ban off"end
z.notify(ao and("Auto rejoin on VC ban on ("..ao..")")or"Couldn't hook VC ban detection in this executor",5)
end
def({"arjvc","avc","arvc","autorejoinvc"},"[on|off]","Toggle: rejoin 5 minutes after a voice chat ban (on / off sets it)","voice vc ban rejoin auto",function(ap)
local aq=not s.avc
if ap=="on"then aq=true elseif ap=="off"then aq=false end
z.setAvc(aq)
end)

local function autoSource(ap)
if ap.kind=="builtin"then
for aq,ar in ipairs(g)do
if ar.name==ap.ref then return ar.src end
end
elseif ap.kind=="github"then
for aq,ar in ipairs(h)do
if ar.name==ap.ref then return z.fetch(ar.url)end
end
elseif ap.kind=="local"then
local aq,ar=pcall(readfile,ap.ref)
if aq then return ar end
elseif ap.kind=="url"then
return z.fetch(ap.ref)
end
return nil,"script not found"
end

local ap={rejoin=true,serverhop=true,smallserver=true,region=true,leave=true}
function z.leaves(aq)
local ar=tostring(aq):lower():gsub("^%s*;?",""):gsub("^loop%^","")
local as,at=ar:match"^(%S+)%s*(.*)$"
if as=="all"or as=="sudo"then return z.leaves((at:gsub("^@%S+%s*","")))end
return as~=nil and ap[z.Aliases[as]or as]==true
end
function z.autoRun(aq)
if aq.kind=="cmd"and z.leaves(aq.ref)then return z.notify("Autostart skipped '"..aq.ref.."': leave / rejoin / hop commands never run on startup",5)end
if aq.kind=="cmd"then return task.spawn(z.Run,aq.ref)end
local ar=z.toolKey[aq.name]
if ar then return z.openTool(ar)end
task.spawn(function()
local as,at=autoSource(aq)
if as then z.runSource(as,aq.name)else z.notify("Autostart "..aq.name..": "..tostring(at or"failed"),5)end
end)
end
function z.runAutostart(aq)
if not l.alive then return end
for ar,as in ipairs(s.autostart.items)do
if aq=="exec"or as.respawn then z.autoRun(as)end
end
end
def({"autostart"},"","Launch (relaunch) everything in Autostart now, like on execute","startup launch run exec relaunch autorun",function()z.runAutostart"exec"end)
z.connect("autoRespawn",A.CharacterAdded,function(aq)
if B.swapped and B.swapped[aq]then return end
task.wait(1)
z.runAutostart"respawn"
end)
if s.autoExec then task.defer(function()z.setAutoExec(true,true)end)end
task.defer(function()z.setAvc(s.avc,true)end)


do
local function mb()local aq,ar=pcall(function()return l.Stats:GetTotalMemoryUsageMb()end);return aq and ar or 0 end
function z.cleanup(aq)
aq=tostring(aq or""):lower()
local ar=aq==""or aq=="all"
local as,at=ar or aq=="scripts"or aq=="script",ar or aq=="game"
if not(as or at)then return z.notify"Usage: ;cleanup [game|scripts] (nothing = both)"end
local au,av,aw=mb(),collectgarbage"count",{}
if as then
local ax=0
for ay,az in ipairs(table.clone(c.KLOSAD_ALL or{}))do if az~=n.unload then pcall(az);ax=ax+1 end end
for ay,az in ipairs{function()return l.CoreGui end,function()return A.PlayerGui end,function()return l.Lighting end}do
pcall(function()
for aA,aB in ipairs(az():GetChildren())do
if(aB.Name=="KLOSAD"and aB~=n.gui)or(aB.Name=="KLOSAD_Blur"and aB~=n.blur)then aB:Destroy();ax=ax+1 end
end
end)
end
for ay=#(B.baseParts or{}),1,-1 do if not B.baseParts[ay].Parent then table.remove(B.baseParts,ay)end end
aw[#aw+1]=ax.." stray run/gui removed"
pcall(collectgarbage,"collect")
end
if at then
if cleardrawcache and pcall(cleardrawcache)then aw[#aw+1]="drawing cache cleared"end
end
task.wait(0.5)
aw[#aw+1]=("Lua %.1f > %.1f MB, client %.0f > %.0f MB"):format(av/1024,collectgarbage"count"/1024,au,mb())
z.notify("Cleanup: "..table.concat(aw,", "),6)
end
def({"cleanup","clean"},"[game|scripts]","Free memory: stray rOSAD runs, Lua garbage, drawing cache (nothing = both)","memory leak optimize clear gc fps lag",z.cleanup)
end



do
local aq,ar,as,at={},{},0,""
z.nuInfo=aq
local au,av=Color3.fromRGB(60,200,90),Color3.fromRGB(150,150,150)
local aw={[0]={"Offline",av},[1]={"Online",Color3.fromRGB(80,160,255)},[2]={"In game",au},[3]={"In Studio",Color3.fromRGB(255,160,50)},[4]={"Invisible",av}}
local function inServer(ax)for ay,az in ipairs(l.Players:GetPlayers())do if az.Name:lower()==ax then return az end end end
local function redraw()if l.panelOpen and n.tab=="Preferences"and n.refreshNu then n.refreshNu()end end
local function entry(ax)local ay=aq[ax];if not ay then ay={user=ax};aq[ax]=ay end;return ay end
local function hdr(ax,ay)for az,aA in pairs(ax.Headers or{})do if tostring(az):lower()==ay then return aA end end end

local function post(ax,ay)
local az,aA=(l.HttpService:JSONEncode(ay))
for aB=1,2 do
aA=nil
local aC,aD=pcall(function()return l.HttpService:RequestInternal{Url=ax,Method="POST",Headers={["Content-Type"]="application/json",["x-csrf-token"]=at},Body=az}end)
if not(aC and aD and pcall(function()aD:Start(function(aE,O)aA=O or false end)end))then aA=nil;break end
local aE=os.clock()
while aA==nil and os.clock()-aE<10 do task.wait(0.05)end
if type(aA)~="table"then aA=nil;break end
local O=aA.StatusCode==403 and hdr(aA,"x-csrf-token")
if not O then break end
at=O
end
if not(aA and aA.StatusCode==200)and o then
local aB,aC=pcall(o,{Url=ax,Method="POST",Headers={["Content-Type"]="application/json"},Body=az})
if aB and type(aC)=="table"and(aC.StatusCode==200 or not aA)then aA=aC end
end
if aA and aA.StatusCode==200 then
local aB,aC=pcall(l.HttpService.JSONDecode,l.HttpService,aA.Body)
return aB and aC or nil,"bad reply"
end
return nil,aA and("HTTP "..tostring(aA.StatusCode))or"no response"
end
local function check(ax)
if ax==A or ar[ax.UserId]or not table.find(s.notifyUsers,ax.Name:lower())then return end
ar[ax.UserId]=true
local ay=entry(ax.Name:lower())
ay.id,ay.user,ay.display=ax.UserId,ax.Name,ax.DisplayName
if n.alertUser then n.alertUser(ax.UserId,ax.Name,ax.DisplayName)end
redraw()
end
function z.nuScan()for ax,ay in ipairs(l.Players:GetPlayers())do check(ay)end end
local function remove(ax,ay)
ax=tostring(ax or""):lower():gsub("^@","")
if ax=="all"then s.notifyUsers={};table.clear(aq)else
local az=table.find(s.notifyUsers,ax)
if not az then return z.notify("Not on the notify list: "..ax)end
table.remove(s.notifyUsers,az);aq[ax]=nil
end
save();redraw()
z.notify(ay or"Notify list updated")
end
function z.nuRemove(ax)remove(ax)end
function z.nuAdd(ax)
local ay={}
for az in tostring(ax or""):gmatch"[^%s,@]+"do
az=az:lower()
if not table.find(s.notifyUsers,az)then table.insert(s.notifyUsers,az);ay[#ay+1]=az end
end
if#ay==0 then return z.notify"Usage: ;notifyuser <username> (or already on the list)"end
save();z.nuScan();redraw()
as=-math.huge
z.notify("Will alert when in the server: "..table.concat(ay,", "))
end

function z.nuStatus(ax)
local ay=aq[ax]
if inServer(ax)then return"In this server",au end
if not ay or ay.kind==nil then return ay and ay.why or"checking…",av end
local az=aw[ay.kind]or aw[0]
local aA=az[1]
if ay.kind==2 and ay.loc and ay.loc~=""then aA=aA..": "..ay.loc
elseif ay.kind==0 and ay.last then
local aB,aC=pcall(function()return DateTime.fromIsoDate(ay.last).UnixTimestamp end)
if aB and aC then
local aD=math.max(0,math.floor((os.time()-aC)/60))
aA=("%s · last seen %s"):format(aA,aD<60 and aD.."m"or aD<2880 and math.floor(aD/60).."h"or math.floor(aD/1440).."d")
end
end
return aA,az[2]
end
function z.nuPoll()
local ax,ay,az,aA={},{},{},{}
for aB,aC in ipairs(s.notifyUsers)do
local aD,aE=entry(aC),inServer(aC)
if aE then aD.id,aD.user,aD.display=aE.UserId,aE.Name,aE.DisplayName end
if not aD.id then
local O,P=pcall(l.Players.GetUserIdFromNameAsync,l.Players,aC)
if O then aD.id=P elseif tostring(P):lower():find"valid"then aA[#aA+1]=aC else aD.why="lookup failed"end
end
if aD.id then
ax[aD.id]=aD;ay[#ay+1]=aD.id
if not aD.display then az[#az+1]=aD.id end
end
end
for aB,aC in ipairs(aA)do remove(aC,"No Roblox user called "..aC)end
if#az>0 then
for aB,aC in ipairs((post("https://users.roblox.com/v1/users",{userIds=az,excludeBannedUsers=false})or{}).data or{})do
local aD=ax[aC.id]
if aD then aD.user,aD.display=aC.name,aC.displayName end
end
end
if#ay>0 then
local aB,aC=post("https://presence.roblox.com/v1/presence/users",{userIds=ay})
for aD,aE in ipairs(aB and aB.userPresences or{})do
local O=ax[aE.userId]
if O then O.kind,O.loc,O.last,O.why=aE.userPresenceType,aE.lastLocation,aE.lastOnline,nil end
end
if not aB then for aD,aE in pairs(ax)do aE.why="status unavailable ("..tostring(aC)..")"end end
end
redraw()
end
z.connect("nuAdd",l.Players.PlayerAdded,check)
z.connect("nuLeft",l.Players.PlayerRemoving,function(ax)ar[ax.UserId]=nil end)
task.delay(3,z.nuScan)
task.spawn(function()
task.wait(4)
while l.alive do
if#s.notifyUsers>0 then as=os.clock();pcall(z.nuPoll)end
repeat task.wait(2)until not l.alive or os.clock()-as>=math.max(15,s.nuPoll)
end
end)
def({"notifyuser","nuser"},"<username> [more]","Alert card whenever this username is in the server (list + status in Preferences)","notify alert watch user player join friend",function(...)z.nuAdd(table.concat({...}," "))end)
def({"unnotifyuser","unuser"},"<username|all>","Remove a username from the notify list","notify alert watch remove",z.nuRemove)
end
end


z.loadFolder(b.."/commands")

for aa,ab in pairs(s.aliases)do
if z.Commands[ab]then z.Aliases[aa]=ab end
end
z.register(function()
return{names={"unalias"},args="<alias>",desc="Remove an alias made with alias",tags="shortcut remove delete",run=function(aa)
aa=aa and aa:lower()
if aa and s.aliases[aa]then
s.aliases[aa]=nil;z.Aliases[aa]=nil;save()
z.notify("Removed alias "..aa)
else
z.notify("No saved alias called "..tostring(aa))
end
end}
end)



rest"CMD_EXTRA"




local function fs(aa)return math.floor(aa*4/3*1.08+0.5)end
local aa,ab,ac=Enum.Font.SourceSans,Enum.Font.SourceSansSemibold,Enum.Font.Code
local ad,ae=0.2,0.25

local af=new("ScreenGui",{Name="KLOSAD",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=10000,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
pcall(function()af.Parent=l.CoreGui end)
if not af.Parent then af.Parent=A:WaitForChild"PlayerGui"end
n.gui=af
n.blur=new("BlurEffect",{Name="KLOSAD_Blur",Size=0},l.Lighting)


l.opK=math.clamp(tonumber(s.opacity)or 0.8,0.2,1)/0.8
function l.opx(ag)return math.clamp(1-(1-ag)*l.opK,0,1)end
local ag=0
local function nx()ag=ag+1;return ag end



local ah={
rCtrl=8,rPane=12,
ctrlEdge=0.7,cardEdge=0.55,
btnPt=9,
hoverTint=0.4,
press=0.97,
fill={hover=0.15,press=0.3},

glow={idle=1,hover=0.82,press=0.65,onIdle=0.55,onHover=0.4,onPress=0.3,cardHover=0.88},
slider={halo=0.8,haloHeld=0.6,aura=0.82,auraHeld=0.6,swell=1.06,lift=1.12},
}

local function fr(ai,aj,ak,al,am,an,ao,ap,aq,ar,as)
local at=new("Frame",{Position=UDim2.fromOffset(aj,ak),Size=UDim2.fromOffset(al,am),BorderSizePixel=0,
BackgroundTransparency=an and ao or 1},ai)
if an then paint(at,"BackgroundColor3",an)end
if l.opScope and an and an~="accent"and al>=14 and am>=14 then at:SetAttribute("raw",ao);at.BackgroundTransparency=l.opx(ao)end
if ap then
if l.opScope then ap=ap<=ah.rCtrl and ah.rCtrl or ah.rPane end
new("UICorner",{CornerRadius=UDim.new(0,ap)},at)
end

if aq then
paint(new("UIStroke",{Thickness=ar or 1,Transparency=(l.opScope and aq=="edge")and ah.cardEdge or(as or 0),ApplyStrokeMode=Enum.ApplyStrokeMode.Border},at),"Color",aq)
end
return at
end


local function txt(ai,aj,ak,al,am,an,ao,ap,aq)
local ar=new("TextLabel",mix({BackgroundTransparency=1,BorderSizePixel=0,Text=aj,TextSize=fs(ak),Font=aa,
TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
Position=UDim2.fromOffset(am,an),Size=UDim2.fromOffset(ao,ap)},aq),ai)
paint(ar,"TextColor3",al)
return ar
end




local ai={
primary={fill="accent",text="onAccent",tr=0,bold=true},
danger={fill="btnFill",text="danger",tint="danger",edge=true},
ghost={fill="text",text="text",tr=1},
ctrlOn={fill="accent",text="accentText",tr=0.78,edge=true,on=true},
}
l.btnV=setmetatable({},{__mode="k"})
local function setFill(aj,ak,al)
local am=ai[ak or"btnFill"]or{fill=ak or"btnFill",text="text",edge=true}
local an=am.tr or al or ae
local ao,ap=l.btnSt[aj],aj:FindFirstChildOfClass"UIStroke"
local aq=aj.BackgroundColor3
l.btnV[aj]=am
paint(aj,"BackgroundColor3",am.fill)
paint(aj,"TextColor3",am.text)
aj.Font=am.bold and ab or aa
aj:SetAttribute("raw",an)
aj:SetAttribute("base",l.opx(an))
aj:SetAttribute("on",am.on==true)
if ap then
paint(ap,"Color",am.on and"accent"or"edge")
ap.Enabled=am.edge==true
end
if ao then
aj.BackgroundColor3=aq
ao()
else
aj.BackgroundTransparency=l.opx(an)
if ap then ap.Transparency=am.on and 0.35 or ah.ctrlEdge end
end
end




function l.hover(aj,ak)
local al=false
local function inside()
local am,an,ao=l.UserInputService:GetMouseLocation(),aj.AbsolutePosition,aj.AbsoluteSize
return am.X>=an.X and am.X<=an.X+ao.X and am.Y>=an.Y and am.Y<=an.Y+ao.Y
end
local function shown()
if aj.AbsoluteSize.X<=0 then return false end
local am=aj
while am and am:IsA"GuiObject"do
if not am.Visible then return false end
am=am.Parent
end
return true
end
local function start()
if al then return end
al=true
ak(true)
task.spawn(function()
repeat l.RunService.Heartbeat:Wait()until not(l.alive and aj.Parent and inside())
al=false
if l.alive and aj.Parent then ak(false)end
end)
end
aj.MouseEnter:Connect(start)


task.spawn(function()
for am=1,3 do
l.RunService.Heartbeat:Wait()
if not(l.alive and aj.Parent)then return end
if aj.AbsoluteSize.X>0 then break end
end
if al or not shown()then return end
if inside()then start()end
end)
end


l.btnSt=setmetatable({},{__mode="kv"})
local function btn(aj,ak,al,am,an,ao,ap,aq,ar,as)
local at=new("TextButton",{Text=ak,TextSize=fs((as and as>=12)and as or ah.btnPt),Font=aa,AutoButtonColor=false,BorderSizePixel=0,
TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,
Position=UDim2.fromOffset(al,am),Size=UDim2.fromOffset(an,ao)},aj)
new("UICorner",{CornerRadius=UDim.new(0,ah.rCtrl)},at)
local au=new("UIStroke",{Thickness=1,Transparency=ah.ctrlEdge,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},at)
paint(au,"Color","edge")
setFill(at,ap,aq)
local av=new("UIScale",{},at)
local aw,ax,ay=false,false,true
local function st()
local az,aA=l.btnV[at]or{fill="btnFill",text="text",edge=true},at.Active
local aB,aC=aw and aA,ax and aA
local aD=col(az.fill)
local aE=aC and aD:Lerp(Color3.new(0,0,0),0.18)or aB and aD:Lerp(col(az.tint or"text"),az.tint and 0.25 or 0.08)or aD
tw(at,{BackgroundColor3=aE,BackgroundTransparency=math.max((at:GetAttribute"base"or 0)-(aC and ah.fill.press or aB and ah.fill.hover or 0),0)},0.1)
if aA~=ay then ay=aA;at.TextTransparency=aA and 0 or 0.55 end
au.Enabled=az.edge==true
if az.edge then tw(au,{Color=az.on and l.accent or aB and col"edge":Lerp(col"text",ah.hoverTint)or col"edge",Transparency=(az.on or aB)and 0.35 or ah.ctrlEdge},0.1)end
tw(av,{Scale=aC and ah.press or 1},0.1)
end
l.btnSt[at]=st
l.hover(at,function(az)aw=az;if not az then ax=false end;st()end)
at.SelectionGained:Connect(function()aw=true;st()end)
at.SelectionLost:Connect(function()aw=false;ax=false;st()end)
at:GetPropertyChangedSignal"Active":Connect(st)
at.MouseButton1Down:Connect(function()ax=true;st()end)
at.MouseButton1Up:Connect(function()ax=false;st()end)
at.MouseButton1Click:Connect(function()if at.Active then ar(at)end end)
return at
end


local function input(aj,ak,al,am,an,ao,ap,aq,ar,as)
local at=new("Frame",{Position=UDim2.fromOffset(al,am),Size=UDim2.fromOffset(an,ao),BorderSizePixel=0,BackgroundTransparency=l.opx(ar or ae)},aj)
at:SetAttribute("raw",ar or ae)
paint(at,"BackgroundColor3",aq or"ctrlOff")
new("UICorner",{CornerRadius=UDim.new(0,ah.rCtrl)},at)
local au=new("UIStroke",{Thickness=1,Transparency=ah.ctrlEdge,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},at)
paint(au,"Color","edge")

local av=new("Frame",{Name="Glow",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,Interactable=false},at)
paint(av,"BackgroundColor3","accent")
new("UICorner",{CornerRadius=UDim.new(0,ah.rCtrl)},av)
new("UIGradient",{Rotation=90,Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.55,1),NumberSequenceKeypoint.new(1,0)}},av)
local aw=new("TextBox",mix({BackgroundTransparency=1,BorderSizePixel=0,Text="",PlaceholderText=ak,ClearTextOnFocus=false,Font=aa,
TextSize=fs(ap or 11),TextXAlignment=Enum.TextXAlignment.Left,Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-20,1,0)},as),at)
paint(aw,"TextColor3","text");paint(aw,"PlaceholderColor3","hint")

local ax,ay=false,{f=false,o=false}
local function edge()
local az=ay.f or ay.o
tw(au,{Color=ax and l.accent or az and col"edge":Lerp(col"text",ah.hoverTint)or col"edge",Thickness=ax and 2 or 1,Transparency=(ax or az)and 0 or ah.ctrlEdge},0.1)
tw(av,{BackgroundTransparency=ax and ah.glow.onIdle or az and ah.glow.hover or ah.glow.idle},0.1)
end
aw.Focused:Connect(function()ax=true;edge()end)
aw.FocusLost:Connect(function()ax=false;edge()end)
for az,aA in pairs{f=at,o=aw}do
l.hover(aA,function(aB)ay[az]=aB;edge()end)

end
return aw
end
local function scroller(aj,ak,al,am,an)
local ao=new("ScrollingFrame",{Position=UDim2.fromOffset(ak,al),Size=UDim2.fromOffset(am,an),BackgroundTransparency=1,BorderSizePixel=0,
ScrollBarThickness=3,ScrollBarImageColor3=col"dim",AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ElasticBehavior=Enum.ElasticBehavior.Never},aj)
paint(ao,"ScrollBarImageColor3","accent")
return ao
end
local function clear(aj)
for ak,al in ipairs(aj:GetChildren())do
if al:IsA"GuiObject"then
x[al]=nil
for am,an in ipairs(al:GetDescendants())do x[an]=nil end
al:Destroy()
end
end
end
local function empty(aj,ak)
local al=new("Frame",{Size=UDim2.new(1,0,0,56),BackgroundTransparency=1,LayoutOrder=nx()},aj)
txt(al,ak,10,"sub",17,14,480,34,{TextWrapped=true})
end
local function thumb(aj,ak,al)return("rbxthumb://type=%s&id=%d&w=%d&h=%d"):format(aj,ak,al,al)end
local function conn(aj,ak)l.cons[#l.cons+1]=aj:Connect(ak)end



function l.sliderParts(aj,ak,al,am,an)
local ao,ap=am-an*2,ah.slider
local aq=new("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromOffset(ak,al),Size=UDim2.fromOffset(am,23)},aj)
local function deco(ar,as,at)as.Interactable,as.BorderSizePixel=false,0;return new(ar,as,at)end
local ar=deco("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,an,0.5,0),Size=UDim2.fromOffset(ao,4),BackgroundTransparency=0.55},aq)
paint(ar,"BackgroundColor3","edge")
new("UICorner",{CornerRadius=UDim.new(1,0)},ar)
local as=deco("Frame",{Size=UDim2.fromOffset(0,4)},ar)
paint(as,"BackgroundColor3","accent")
new("UICorner",{CornerRadius=UDim.new(1,0)},as)
local at=deco("Frame",{AnchorPoint=Vector2.new(0,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.new(1,0,0,12),BackgroundTransparency=ap.aura},as)
paint(at,"BackgroundColor3","accent")
new("UICorner",{CornerRadius=UDim.new(1,0)},at)
local au=deco("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(34,34),BackgroundTransparency=1,ZIndex=2},aq)
paint(au,"BackgroundColor3","accent")
new("UICorner",{CornerRadius=UDim.new(1,0)},au)
local av=deco("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(26,26),BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.82,ZIndex=3},aq)
new("UICorner",{CornerRadius=UDim.new(1,0)},av)
local aw=deco("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(20,20),BackgroundColor3=Color3.new(1,1,1),ZIndex=4},aq)
new("UICorner",{CornerRadius=UDim.new(1,0)},aw)
new("UIStroke",{Thickness=0.5,Color=Color3.new(0,0,0),Transparency=0.8,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},aw)
local ax=new("UIScale",{},aw)
local ay={hit=aq,track=ar,TW=ao}
local az,aA=false,false
local function look()
tw(au,{BackgroundTransparency=aA and ap.haloHeld or az and ap.halo or 1},0.1)
tw(at,{BackgroundTransparency=aA and ap.auraHeld or ap.aura},0.1)
tw(ax,{Scale=aA and ap.lift or az and ap.swell or 1},0.1)
end
function ay.held(aB)aA=aB;look()end
l.hover(aq,function(aB)az=aB;look()end)
function ay.place(aB,aC)
local aD,aE=UDim2.new(0,an+aB*ao,0.5,0),UDim2.fromOffset(aB*ao,4)
if aC then
tw(aw,{Position=aD},aC);tw(av,{Position=aD},aC);tw(au,{Position=aD},aC);tw(as,{Size=aE},aC)
else
aw.Position,av.Position,au.Position,as.Size=aD,aD,aD,aE
end
end
return ay
end

function l.lit(aj)
local ak,al=aj:FindFirstChildOfClass"UIStroke",aj:FindFirstChildOfClass"UICorner"
local am=new("Frame",{Name="Glow",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=0,Interactable=false},aj)
paint(am,"BackgroundColor3","text")
if al then new("UICorner",{CornerRadius=al.CornerRadius},am)end
new("UIGradient",{Rotation=90,Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,1),NumberSequenceKeypoint.new(1,0)}},am)
local an
l.hover(aj,function(ao)
if ao then local ap=ak and x[ak]and x[ak].Color;an=ak and(ap and col(ap)or ak.Color)end
tw(am,{BackgroundTransparency=ao and ah.glow.cardHover or ah.glow.idle},0.16)
if ak and an then tw(ak,{Color=ao and an:Lerp(col"text",ah.hoverTint)or an},0.16)end
end)
end

function l.notch(aj,ak,al,am,an,ao,ap,aq)
local ar,as=#an,40
local at=am-as-8
local au=l.UserInputService
local av=l.sliderParts(aj,al,ak,at,10)
local aw,ax=av.hit,av.track
for ay=1,ar do
local az=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new((ay-1)/(ar-1),0,0.5,0),Size=UDim2.fromOffset(4,4),BorderSizePixel=0,BackgroundTransparency=0.6,ZIndex=2},ax)
paint(az,"BackgroundColor3","text")
new("UICorner",{CornerRadius=UDim.new(1,0)},az)
end
local ay=txt(aj,"",10,"accentText",al+at+8,ak,as,23,{Font=ab,TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center})
local az
local function find()
local aA,aB,aC=aq[ao],1,math.huge
if type(aA)~="number"then return 1 end
for aD,aE in ipairs(an)do
local K=math.abs(aE[2]-aA)
if K<aC then aB,aC=aD,K end
end
return aB
end
local function near(aA)return math.clamp(math.floor(aA*(ar-1)+0.5)+1,1,ar)end
az=find()
ay.Text=an[az][1]
av.place((az-1)/(ar-1))
local aA,aB
local aC,aD=0,1
local function commit()
local aE=an[az][2]
if aq[ao]~=aE then
aq[ao]=aE;save()
if ap then ap(aE)else n.apply()end
end
end
local function drag(aE)
local K=math.clamp((aE-aC)/aD,0,1)
local L=near(K)
if L~=az then
az=L;ay.Text=an[L][1]
if ao~="scale"then commit()end
end
av.place(K)
end
local function finish()
if aA then aA:Disconnect();aA=nil end
if aB then aB:Disconnect();aB=nil end
av.held(false)
av.place((az-1)/(ar-1),0.16)
commit()
end
aw.InputBegan:Connect(function(aE)
if aE.UserInputType~=Enum.UserInputType.MouseButton1 and aE.UserInputType~=Enum.UserInputType.Touch then return end
if aA then return end
aC,aD=ax.AbsolutePosition.X,math.max(ax.AbsoluteSize.X,1)
av.held(true)
drag(aE.Position.X)
aA=au.InputChanged:Connect(function(K)
if K.UserInputType==Enum.UserInputType.MouseMovement or K.UserInputType==Enum.UserInputType.Touch then drag(K.Position.X)end
end)
aB=au.InputEnded:Connect(function(K)
if K.UserInputType==Enum.UserInputType.MouseButton1 or K.UserInputType==Enum.UserInputType.Touch then finish()end
end)
end)
return aw
end

l.swLook=setmetatable({},{__mode="kv"})
function l.syncSwitches()for aj,ak in pairs(l.swLook)do pcall(ak)end end
function l.switch(aj,ak,al,am,an,ao)
local ap=new("TextButton",{Text="",AutoButtonColor=false,BorderSizePixel=0,Position=UDim2.fromOffset(ak,al),Size=UDim2.fromOffset(42,23)},aj)
new("UICorner",{CornerRadius=UDim.new(1,0)},ap)
local aq=new("Frame",{AnchorPoint=Vector2.new(0,0.5),Size=UDim2.fromOffset(19,19),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Interactable=false},ap)
new("UICorner",{CornerRadius=UDim.new(1,0)},aq)
new("UIStroke",{Thickness=0.5,Color=Color3.new(0,0,0),Transparency=0.8},aq)
local ar=new("UIScale",{},aq)
local function look(as)
local at=am[an]==true
local au,av,aw=at and"accent"or"edge",UDim2.new(0,at and 21 or 2,0.5,0),at and 0 or 0.35
if as then
local ax=ap.BackgroundColor3
paint(ap,"BackgroundColor3",au)
ap.BackgroundColor3=ax
tw(ap,{BackgroundColor3=col(au),BackgroundTransparency=aw},0.16)
tw(aq,{Position=av},0.16)
else
paint(ap,"BackgroundColor3",au)
ap.BackgroundTransparency,aq.Position=aw,av
end
end
look()
l.swLook[ap]=look
l.hover(ap,function(as)tw(ar,{Scale=as and 1.08 or 1},0.1)end)
ap.MouseButton1Click:Connect(function()
am[an]=not(am[an]==true);save()
look(true)
if ao then ao(am[an])else n.apply()end
end)
return ap
end

local function seg(aj,ak,al,am,an,ao,ap,aq)
aq=aq or s
if#an==2 and an[1][2]==true and an[2][2]==false then return l.switch(aj,al[2]+am-42,ak,aq,ao,ap)end
local ar=#an>=3
for as,at in ipairs(an)do if type(at[2])~="number"then ar=false end end
if ar then return l.notch(aj,ak,al[1],al[#al]+am-al[1],an,ao,ap,aq)end
local as={}
local function refresh()
for at,au in ipairs(as)do
local av=aq[ao]==au.v
setFill(au.b,av and"ctrlOn"or"ctrlOff",av and ad or ae)
end
end
for at,au in ipairs(an)do
as[at]={v=au[2],b=btn(aj,au[1],al[at],ak,am,23,"ctrlOff",ae,function()
aq[ao]=au[2];save();refresh()
if ap then ap(au[2])else n.apply()end
end)}
end
refresh()
end


do
local aj=new("TextLabel",{Name="Toast",AnchorPoint=Vector2.new(0.5,1),Position=UDim2.new(0.5,0,1,-70),
AutomaticSize=Enum.AutomaticSize.XY,Size=UDim2.fromOffset(0,0),BackgroundTransparency=0.1,BorderSizePixel=0,
Font=aa,TextSize=fs(11),TextWrapped=true,Visible=false,ZIndex=50,ClipsDescendants=true},af)
paint(aj,"BackgroundColor3","bar");paint(aj,"TextColor3","text")
new("UICorner",{CornerRadius=UDim.new(0,8)},aj)
paint(new("UIStroke",{Thickness=1,Transparency=0.35,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},aj),"Color","accent")

local ak=new("Frame",{Position=UDim2.new(0,-14,1,6),Size=UDim2.new(1,28,0,2),BorderSizePixel=0,BackgroundTransparency=0.2},aj)
paint(ak,"BackgroundColor3","accent")
new("UIPadding",{PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14),PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)},aj)
new("UISizeConstraint",{MaxSize=Vector2.new(520,300)},aj)
n.toastScale=new("UIScale",{},aj)
local al,am,an=0,"","Copied to clipboard"
aj.Active=true
aj.InputBegan:Connect(function(ao)
if(ao.UserInputType==Enum.UserInputType.MouseButton1 or ao.UserInputType==Enum.UserInputType.Touch)and aj.Visible and am~=""and aj.Text~=an and setclipboard then
pcall(setclipboard,am)
n.toast(an,1.5)
end
end)
function n.toast(ao,ap)
al=al+1
local aq=al
aj.Text=ao
if ao~=an then am=ao end
aj.Visible=true
aj.Position=UDim2.new(0.5,0,1,-50)
aj.BackgroundTransparency,aj.TextTransparency=1,1
tw(aj,{Position=UDim2.new(0.5,0,1,-70),BackgroundTransparency=0.1,TextTransparency=0},0.2)
ak.BackgroundTransparency,ak.Size=0.2,UDim2.new(1,28,0,2)
if s.anim~=0 then
l.TweenService:Create(ak,TweenInfo.new(ap or 3,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,2),BackgroundTransparency=0.2}):Play()
end
task.delay(ap or 3,function()
if al==aq then
tw(aj,{BackgroundTransparency=1,TextTransparency=1},0.2)
tw(ak,{BackgroundTransparency=1},0.2)
task.delay(dur(0.2)+0.05,function()if al==aq then aj.Visible=false end end)
end
end)
end
end


do
local aj={TL={0,0},TR={1,0},BL={0,1},BR={1,1}}
local ak=new("Frame",{Name="ActFeed",BackgroundTransparency=1,Size=UDim2.fromOffset(300,0),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=40},af)
local al=new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},ak)
n.actScale=new("UIScale",{},ak)
local am,an={},0
n.actHolder,n.actCorner=ak,aj
function n.actLayout()
local ao=aj[s.mod.actCorner]or aj.BL
ak.AnchorPoint=Vector2.new(ao[1],ao[2])
ak.Position=UDim2.new(ao[1],ao[1]==0 and 16 or-16,ao[2],ao[2]==0 and 16 or-16)
al.HorizontalAlignment=ao[1]==0 and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
al.VerticalAlignment=ao[2]==0 and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom
if n.actReorder then n.actReorder()end
end
function n.act(ao,ap)
if not s.mod.actOn then return end
local aq=(ap and ap~="")and("<b>%s</b>  %s"):format(esc(ao),esc(ap))or("<b>%s</b>"):format(esc(ao))
local ar=am[ao]
if not(ar and ar.l.Parent)then
an=an+1
local as=(aj[s.mod.actCorner]or aj.BL)[2]==0
local at=new("TextLabel",{AutomaticSize=Enum.AutomaticSize.XY,Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,TextTransparency=1,
BorderSizePixel=0,Font=aa,TextSize=fs(10),RichText=true,Text=aq,LayoutOrder=as and-an or an,ZIndex=40},ak)
paint(at,"BackgroundColor3","bar");paint(at,"TextColor3","text")
new("UICorner",{CornerRadius=UDim.new(0,8)},at)
new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},at)
local au=new("UIStroke",{Thickness=1,Transparency=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},at)
paint(au,"Color","accent")
ar={l=at,st=au,id=0}
am[ao]=ar
end
ar.l.Text=aq
ar.id=ar.id+1
local as=ar.id
tw(ar.l,{BackgroundTransparency=0.1,TextTransparency=0},0.12)
tw(ar.st,{Transparency=0.4},0.12)
task.delay(2.5,function()
if ar.id~=as or not ar.l.Parent then return end
tw(ar.l,{BackgroundTransparency=1,TextTransparency=1},0.15)
tw(ar.st,{Transparency=1},0.15)
task.delay(dur(0.15)+0.05,function()
if ar.id~=as then return end
pcall(function()ar.l:Destroy()end)
if am[ao]==ar then am[ao]=nil end
end)
end)
end
n.actLayout()
end



do
local aj,ak=n.actHolder,n.actCorner
local al,am={},0
local function order(an)
local ao=(ak[s.mod.actCorner]or ak.BL)[2]==0
return ao and(-1E6+an.seq)or(1000000+an.seq)
end
function n.actReorder()
for an,ao in pairs(al)do
if ao.l.Parent then ao.l.LayoutOrder=order(ao)end
end
end
local function textOf(an)
local ao=(an=="vcbypass"and n.vcbText and n.vcbText())or(an=="vcban"and z.vcbanText())or(B.who and B.who[an])or(B.val and B.val[an])
return('<font color="%s">●</font>  <b>%s</b>%s'):format(hex(l.accent),esc(an=="vcbypass"and"VC Bypass"or an=="vcban"and"VC ban"or an),ao and("  "..esc(tostring(ao):sub(1,26)))or"")
end
local function drop(an,ao)
al[an]=nil
tw(ao.l,{BackgroundTransparency=1,TextTransparency=1},0.15)
tw(ao.st,{Transparency=1},0.15)
task.delay(dur(0.15)+0.05,function()pcall(function()ao.l:Destroy()end)end)
end
function n.syncActive()
local an=s.mod.actOn and B.active or{}
if B.vcb and B.vcb.open==false then
local ao={}
for ap in pairs(an)do ao[ap]=true end
ao.vcbypass=true
an=ao
end
if B.vcban then
local ao={}
for ap in pairs(an)do ao[ap]=true end
ao.vcban=true
an=ao
end
for ao,ap in pairs(al)do
if not an[ao]or not ap.l.Parent then drop(ao,ap)end
end
for ao in pairs(an)do
local ap,aq=textOf(ao),al[ao]
if not aq then
am=am+1
local ar=new("TextLabel",{AutomaticSize=Enum.AutomaticSize.XY,Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,TextTransparency=1,
BorderSizePixel=0,Font=aa,TextSize=fs(10),RichText=true,Text=ap,ZIndex=40},aj)
paint(ar,"BackgroundColor3","bar");paint(ar,"TextColor3","text")
new("UICorner",{CornerRadius=UDim.new(0,8)},ar)
new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},ar)
local as=new("UIStroke",{Thickness=1,Transparency=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},ar)
paint(as,"Color","accent")
aq={l=ar,st=as,seq=am,text=ap}
local at=n.actClick and n.actClick[ao]
if at then
ar.Active=true
local au=new("UIScale",{},ar)
local av,aw=false,false
local function lit()
local ax=aw and 0.34 or av and 0.2 or 0
tw(ar,{BackgroundColor3=col"bar":Lerp(l.accent,ax),BackgroundTransparency=(aw or av)and 0.02 or 0.1},0.1)
tw(as,{Transparency=aw and 0 or av and 0.05 or 0.3},0.1)
tw(au,{Scale=aw and ah.press or 1},0.08)
end
ar.MouseEnter:Connect(function()av=true;lit()end)
ar.MouseLeave:Connect(function()av,aw=false,false;lit()end)
ar.InputBegan:Connect(function(ax)
if ax.UserInputType==Enum.UserInputType.MouseButton1 or ax.UserInputType==Enum.UserInputType.Touch then aw=true;lit();pcall(at)end
end)
ar.InputEnded:Connect(function(ax)
if ax.UserInputType==Enum.UserInputType.MouseButton1 or ax.UserInputType==Enum.UserInputType.Touch then aw=false;lit()end
end)
end
ar.LayoutOrder=order(aq)
al[ao]=aq
tw(ar,{BackgroundTransparency=0.1,TextTransparency=0},0.12)
tw(as,{Transparency=0.3},0.12)
elseif aq.text~=ap then
aq.text,aq.l.Text=ap,ap
end
end
end
local an=0
conn(l.RunService.Heartbeat,function(ao)
an=an+ao
if an<0.2 then return end
an=0
pcall(n.syncActive)
end)
end



do
local aj=56
local ak,al,am,an=Color3.fromRGB(18,18,22),Color3.new(1,1,1),Color3.fromRGB(28,28,34),Color3.fromRGB(255,99,88)

local ao={{"c",28,22,18},{"r",10,22,36,22},{"c",16,44,6},{"c",28,44,6},{"c",40,44,6}}
local ap={{"c",21,26,3},{"c",35,26,3}}
local aq={
{"c",33,11,6},
{"l",30,20,24,35,5},
{"l",30,22,39,28,4.5},{"l",39,28,45,21,4.5},
{"l",30,22,21,26,4.5},{"l",21,26,14,32,4.5},
{"l",24,35,35,40,5},{"l",35,40,33,51,5},
{"l",24,35,17,44,5},{"l",17,44,8,42,5},
}
local ar={{"l",6,6,50,50,5}}
local function draw(as,at,au,av)
for aw,ax in ipairs(at)do
local ay=new("Frame",{BorderSizePixel=0,BackgroundColor3=av},as)
if ax[1]=="c"then
local az=ax[4]+au
ay.AnchorPoint,ay.Position,ay.Size=Vector2.new(0.5,0.5),UDim2.fromOffset(ax[2],ax[3]),UDim2.fromOffset(az*2,az*2)
new("UICorner",{CornerRadius=UDim.new(1,0)},ay)
elseif ax[1]=="r"then
ay.Position,ay.Size=UDim2.fromOffset(ax[2]-au,ax[3]-au),UDim2.fromOffset(ax[4]+au*2,ax[5]+au*2)
else
local az,aA=ax[4]-ax[2],ax[5]-ax[3]
ay.AnchorPoint=Vector2.new(0.5,0.5)
ay.Position=UDim2.fromOffset((ax[2]+ax[4])/2,(ax[3]+ax[5])/2)
ay.Size=UDim2.fromOffset(math.sqrt(az*az+aA*aA)+ax[6]+au*2,ax[6]+au*2)
ay.Rotation=math.deg(math.atan2(aA,az))
new("UICorner",{CornerRadius=UDim.new(1,0)},ay)
end
end
end
local function build(as,at,au)
local av=new("BillboardGui",{Name="_klStatusIcon",Size=UDim2.fromOffset(64,64),AlwaysOnTop=true,LightInfluence=0,
StudsOffset=Vector3.new(0,au.Name=="Head"and 2.4 or 4.4,0),Adornee=au})
local aw=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(aj,aj),BackgroundTransparency=1,BorderSizePixel=0},av)
local ax=new("UIScale",{Scale=0},aw)
if as=="ghost"then
draw(aw,ao,2,ak);draw(aw,ao,0,al);draw(aw,ap,0,am)
else
draw(aw,aq,2,ak);draw(aw,aq,0,al)
draw(aw,ar,3.5,ak);draw(aw,ar,0,an)
end
av.Parent=au
tw(ax,{Scale=1.15},0.1)
task.delay(dur(0.1),function()if ax.Parent then tw(ax,{Scale=1},0.1)end end)
if s.anim~=0 then
l.TweenService:Create(av,TweenInfo.new(1.2/s.anim,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{StudsOffset=av.StudsOffset+Vector3.new(0,0.4,0)}):Play()
end
return{kind=as,fake=at,gui=av,sc=ax}
end
local function drop(as)
pcall(function()
if s.anim==0 or not as.gui.Parent then as.gui:Destroy()return end
tw(as.sc,{Scale=0},0.1)
task.delay(dur(0.1)+0.05,function()pcall(function()as.gui:Destroy()end)end)
end)
end
local as,at,au=0
conn(l.RunService.Heartbeat,function(av)
as=as+av
if as<0.1 then return end
as=0
local aw=B.blink
local ax=(aw and aw.fake and aw.fake.Parent)and(aw.ghost and"ghost"or"blink")or nil
if at and(ax~=at.kind or aw.fake~=at.fake or not at.gui.Parent)then drop(at);at=nil end
if not ax then au=nil end
if ax and not at and aw.fake~=au then
local ay=aw.fake:FindFirstChild"Head"or aw.fake:FindFirstChild"HumanoidRootPart"
if ay then
local az,aA=pcall(build,ax,aw.fake,ay)
if az then at=aA else au=aw.fake end
end
end
end)
end


do
local aj=new("Frame",{Name="UserAlert",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,28),BackgroundTransparency=1,
Size=UDim2.fromOffset(380,0),AutomaticSize=Enum.AutomaticSize.Y,ZIndex=60},af)
new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},aj)
local ak,al=new("UIScale",{},aj),0
function n.alertUser(am,an,ao)
al=al+1
ak.Scale=s.scale
local ap=new("CanvasGroup",{LayoutOrder=al,Size=UDim2.fromOffset(380,92),BackgroundTransparency=0.05,BorderSizePixel=0,GroupTransparency=1,ZIndex=60},aj)
paint(ap,"BackgroundColor3","bar")
new("UICorner",{CornerRadius=UDim.new(0,ah.rPane)},ap)
local aq=new("UIStroke",{Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},ap)
paint(aq,"Color","accent")
local ar=new("ImageLabel",{Position=UDim2.fromOffset(14,16),Size=UDim2.fromOffset(60,60),BorderSizePixel=0,BackgroundTransparency=0.9,Image=thumb("AvatarHeadShot",am,150),ZIndex=61},ap)
paint(ar,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(1,0)},ar)
paint(new("UIStroke",{Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},ar),"Color","accent")
txt(ap,"USER IN SERVER",8,"accentText",90,8,270,14,{Font=ab,ZIndex=61})
txt(ap,ao,14,"text",90,22,276,22,{Font=ab,ZIndex=61,TextTruncate=Enum.TextTruncate.AtEnd})
txt(ap,"@"..an,9,"sub",90,45,276,14,{ZIndex=61,TextTruncate=Enum.TextTruncate.AtEnd})
local as=new("Frame",{Position=UDim2.fromOffset(91,68),Size=UDim2.fromOffset(8,8),BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(60,200,90),ZIndex=61},ap)
new("UICorner",{CornerRadius=UDim.new(1,0)},as)
txt(ap,"In this server",9,"text2",105,64,260,16,{ZIndex=61})
local at=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,3),BorderSizePixel=0,ZIndex=62},ap)
paint(at,"BackgroundColor3","accent")
local au={}
if s.anim~=0 then
au[1]=l.TweenService:Create(at,TweenInfo.new(20,Enum.EasingStyle.Linear),{Size=UDim2.new(0,0,0,3)})
au[2]=l.TweenService:Create(aq,TweenInfo.new(0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=0.7})
for av,aw in ipairs(au)do aw:Play()end
end
tw(ap,{GroupTransparency=0},0.2)
local av=false
local function close()
if av then return end
av=true
for aw,ax in ipairs(au)do pcall(function()ax:Cancel()end)end
tw(ap,{GroupTransparency=1},0.2)
task.delay(dur(0.2)+0.05,function()pcall(function()ap:Destroy()end)end)
end
new("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",ZIndex=70},ap).MouseButton1Click:Connect(close)
task.delay(20,close)
task.spawn(function()
local aw=new("Sound",{SoundId="rbxasset://sounds/electronicpingshort.wav",Volume=2},af)
for ax=1,2 do pcall(aw.Play,aw);task.wait(0.5)end
aw:Destroy()
end)
end
end


do
local aj=new("TextButton",{Name="Welcome",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.fromScale(0.5,0.08),AutomaticSize=Enum.AutomaticSize.XY,
Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,Font=aa,TextSize=fs(12),
RichText=true,TextWrapped=true,Text="",Visible=false,ZIndex=60},af)
paint(aj,"BackgroundColor3","bar");paint(aj,"TextColor3","text")
new("UICorner",{CornerRadius=UDim.new(0,ah.rPane)},aj)
local ak=new("UIStroke",{Thickness=1,Transparency=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},aj)
paint(ak,"Color","accent")
new("UIPadding",{PaddingLeft=UDim.new(0,18),PaddingRight=UDim.new(0,18),PaddingTop=UDim.new(0,12),PaddingBottom=UDim.new(0,12)},aj)
new("UISizeConstraint",{MaxSize=Vector2.new(560,300)},aj)
n.popScale=new("UIScale",{},aj)
local al,am=0,false
aj.MouseButton1Click:Connect(function()am=true end)
function n.welcome()
al=al+1
local an=al
local ao={
("rOSAD loaded. Panel: %s. Command bar: %s. Lost? Type ;cmds."):format(keyStr(s.panelKey),keyStr(s.barKey)),
i[math.random(#i)],
}
local function show(ap)
aj.Text=esc(ao[ap])..'   <font color="'..hex(col"dim")..'">'..ap.."/2</font>"
end
local function hold(ap)
local aq=0
am=false
while aq<ap and an==al and l.alive and not am do
task.wait(0.1)
aq=aq+0.1
end
return an==al and l.alive
end
task.spawn(function()
show(1)
aj.Visible=true
aj.BackgroundTransparency,aj.TextTransparency=1,1
tw(aj,{BackgroundTransparency=0.1,TextTransparency=0},0.25);tw(ak,{Transparency=0},0.25)
if not hold(5)then return end
show(2)
if not hold(5)then return end
tw(aj,{BackgroundTransparency=1,TextTransparency=1},0.25);tw(ak,{Transparency=1},0.25)
task.wait(dur(0.25)+0.05)
if an==al then aj.Visible=false end
end)
end
end


do
local aj=new("TextLabel",{Name="Hud",BackgroundTransparency=0.35,BorderSizePixel=0,Font=aa,TextSize=fs(10),Text="",
AutomaticSize=Enum.AutomaticSize.XY,Size=UDim2.fromOffset(0,0),Visible=false},af)
paint(aj,"BackgroundColor3","bar");paint(aj,"TextColor3","text")
new("UICorner",{CornerRadius=UDim.new(0,ah.rCtrl)},aj)
new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5)},aj)
n.hudScale=new("UIScale",{},aj)
function n.layoutHud()
local ak=s.mod.fpsCorner
local al,am=ak:sub(2,2)=="R",ak:sub(1,1)=="B"
aj.AnchorPoint=Vector2.new(al and 1 or 0,am and 1 or 0)
aj.Position=UDim2.new(al and 1 or 0,al and-12 or 12,am and 1 or 0,am and-12 or 12)
end
function n.showHud(ak)
aj.Visible=ak
if not ak then return z.disconnect"hud"end
n.layoutHud()
local al,am=0,0
z.connect("hud",l.RunService.Heartbeat,function(an)
al,am=al+an,am+1
if al>=0.5 then
local ao,ap=pcall(function()return l.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()end)
aj.Text=("%d FPS  |  %s ms"):format(math.floor(am/al+0.5),ao and tostring(math.floor(ap))or"-")
al,am=0,0
end
end)
end
end



function n.entries()
local aj,ak={},{}
for al,am in pairs(z.Aliases)do
local an=aj[am]
if not an then
local ao=z.Meta[am]or{}
an={canon=am,names={am},desc=ao.desc or"",args=ao.args or"",tags=ao.tags or"",cat=z.catOf[am]or"Other"}
aj[am]=an
ak[#ak+1]=an
end
if al~=am then an.names[#an.names+1]=al end
end
for al,am in ipairs(ak)do
table.sort(am.names,function(an,ao)
if an==ao then return false end
if an==am.canon then return true end
if ao==am.canon then return false end
return an<ao
end)
end
table.sort(ak,function(al,am)return al.canon<am.canon end)
return ak
end

function n.matches(aj)
local ak=n.entries()
aj=(aj or""):lower():match"^%s*(.-)%s*$"
if aj==""then return ak end
local al={}
for am in aj:gmatch"%S+"do al[#al+1]=am end
local am={}
for an,ao in ipairs(ak)do
local ap
for aq,ar in ipairs(al)do
local as=score(ao,ar)
if not as then ap=nil;break end
ap=math.max(ap or 0,as)
end
if ap then am[#am+1]={e=ao,s=ap}end
end
table.sort(am,function(an,ao)
if an.s~=ao.s then return an.s<ao.s end
return an.e.canon<ao.e.canon
end)
local an={}
for ao,ap in ipairs(am)do an[#an+1]=ap.e end
return an
end






function n.syncMouse()
local aj=l.UserInputService
local ak=l.panelOpen or l.barOpen or l.profOpen
if ak and not l.mouseFree then
l.mouseFree=true
local al={icon=aj.MouseIconEnabled}
l.mouseL=al
pcall(function()
l.RunService:BindToRenderStep("KLOSAD_Mouse",Enum.RenderPriority.Last.Value+10,function()


if not aj:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)and aj.MouseBehavior~=Enum.MouseBehavior.Default then aj.MouseBehavior=Enum.MouseBehavior.Default end
if not aj.MouseIconEnabled then al.icon=false;aj.MouseIconEnabled=true end
end)
end)
elseif not ak and l.mouseFree then
l.mouseFree=false
pcall(function()l.RunService:UnbindFromRenderStep"KLOSAD_Mouse"end)
local al=l.mouseL
l.mouseL=nil
if al and al.icon==false then aj.MouseIconEnabled=false end
end
end



do
local aj={asset={},failT={},pend={},user={},busy={},skip={},rapC={},rapF={},workers=0}
z.AV=aj
function aj.comma(ak)local al=tostring(math.floor((tonumber(ak)or 0)+0.5));return(al:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""))end
local function priceOf(ak)
local al=ak.CollectiblesItemDetails
if ak.IsLimited or ak.IsLimitedUnique or(type(al)=="table"and al.IsLimited)then return 0,"limited"end
local am=tonumber(ak.PriceInRobux)
if ak.IsForSale and am and am>0 then return am end
if ak.IsForSale then return 0 end
return 0,"off"
end
function aj.info(ak)
local al=aj.asset[ak]
if al then return al end
if aj.failT[ak]and os.clock()-aj.failT[ak]<30 then return nil end
if aj.pend[ak]then
local am=os.clock()
while aj.pend[ak]and os.clock()-am<15 do task.wait(0.05)end
return aj.asset[ak]
end
aj.pend[ak]=true
local am,an=pcall(function()return l.MarketplaceService:GetProductInfo(ak,Enum.InfoType.Asset)end)
aj.pend[ak]=nil
if am and type(an)=="table"then aj.asset[ak]=an;task.wait(0.15);return an end
aj.failT[ak]=os.clock()
end

function aj.limitedPrice(ak,al)
if aj.rapC[ak]then return aj.rapC[ak]end
if aj.rapF[ak]and os.clock()-aj.rapF[ak]<60 then return nil end
local am=type(al)=="table"and al.CollectiblesItemDetails
local an=type(am)=="table"and tonumber(am.CollectibleLowestResalePrice)or nil
if not(an and an>0)then
local ao=z.fetch("https://economy.roblox.com/v1/assets/"..ak.."/resale-data")
local ap,aq=pcall(function()return l.HttpService:JSONDecode(ao)end)
an=ap and type(aq)=="table"and tonumber(aq.recentAveragePrice)or nil
task.wait(0.25)
end
if an and an>0 then aj.rapC[ak]=an;return an end
aj.rapF[ak]=os.clock()
end
local function wornIds(ak,al)
local am,an={},{}
local function add(ao)ao=tonumber(ao);if ao and ao>0 and not an[ao]then an[ao]=true;am[#am+1]=ao end end
local ao,ap=pcall(function()
local ao=ak.Character and ak.Character:FindFirstChildOfClass"Humanoid"
if ao then return ao:GetAppliedDescription()end
if al then return l.Players:GetHumanoidDescriptionFromUserId(ak.UserId)end
end)
if ao and ap then
pcall(function()for aq,ar in ipairs(ap:GetAccessories(true))do add(ar.AssetId)end end)
for aq,ar in ipairs{"Shirt","Pants","GraphicTShirt","Face","Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg"}do pcall(function()add(ap[ar])end)end
end
return am
end
function aj.fresh(ak)local al=aj.user[ak];return al~=nil and os.clock()-al.t<(al.miss>0 and 30 or 300)end
function aj.value(ak,al)
local am=ak.UserId
if aj.fresh(am)then return aj.user[am]end
if aj.busy[am]then
local an=os.clock()
while aj.busy[am]and os.clock()-an<30 do task.wait(0.1)end
return aj.user[am]
end
aj.busy[am]=true
local an
pcall(function()
local ao=wornIds(ak,al)
if#ao==0 then return end
local ap={total=0,priced=0,n=#ao,other=0,miss=0,lim=0}
for aq,ar in ipairs(ao)do
local as=aj.info(ar)
if not as then
ap.miss=ap.miss+1
else
local at,au=priceOf(as)
local av=(au=="limited")and aj.limitedPrice(ar,as)or nil
if av then ap.total=ap.total+av;ap.priced=ap.priced+1;ap.lim=ap.lim+1
elseif au then ap.other=ap.other+1
else ap.total=ap.total+at;ap.priced=ap.priced+1 end
end
end
ap.t=os.clock()
aj.user[am]=ap
an=ap
end)
aj.busy[am]=nil
return an
end
function aj.srvTotal()
local ak,al,am=0,0,0
for an,ao in ipairs(l.Players:GetPlayers())do
am=am+1
local ap=aj.user[ao.UserId]
if ap then al=al+1;ak=ak+ap.total end
end
return ak,al,am
end
function aj.srvStep()
if aj.workers>0 then return end
local ak,al={},os.clock()
for am,an in ipairs(l.Players:GetPlayers())do
local ao=an.UserId
if an.Character and not aj.fresh(ao)and not(aj.skip[ao]and al-aj.skip[ao]<20)then ak[#ak+1]=an end
end
for am=1,math.min(3,#ak)do
aj.workers=aj.workers+1
task.spawn(function()
while l.alive do
local an=table.remove(ak)
if not an then break end
local ao,ap=pcall(aj.value,an)
if not(ao and ap)then aj.skip[an.UserId]=os.clock()end
end
aj.workers=aj.workers-1
end)
end
end
end



rest"UI_SHARED"

do

local aj=new("CanvasGroup",{Name="BarFade",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=1,Visible=false,ZIndex=10},af)
local ak=new("Frame",{Name="Bar",AnchorPoint=Vector2.new(0.5,0),Size=UDim2.fromOffset(647,51),BackgroundTransparency=1},aj)
n.barScale=new("UIScale",{},ak)
local al=fr(ak,0,0,647,51,"bar",0,25,"accent",2,0.35)


l.glowFields={}
local function glowField(am,an,ao,ap,aq)
local ar=new("CanvasGroup",{Name="Glows",Size=UDim2.fromOffset(an,ao),BackgroundTransparency=1,BorderSizePixel=0,Interactable=false},am)
new("UICorner",{CornerRadius=UDim.new(0,ap)},ar)
local as,at,au,av,aw={},{},false,0,12
for ax,ay in ipairs{{true,0.62,0.3},{true,0.5,0.22},{false,0.4,0.12}}do
local az=an*ay[2]
local aA=new("CanvasGroup",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(math.random(0,an),math.random(0,ao)),Size=UDim2.fromOffset(az,az),
BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=math.random(0,12)/100},ar)
aA:SetAttribute("peak",ay[3])
as[#as+1]=aA
if not ay[1]then l.deco(aA)end
for aB=1,aw do
local aC=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(az*aB/aw,az*aB/aw),BorderSizePixel=0,BackgroundTransparency=1},aA)
if ay[1]then paint(aC,"BackgroundColor3","accent")else aC.BackgroundColor3=Color3.new(1,1,1)end
new("UICorner",{CornerRadius=UDim.new(1,0)},aC)
end
end
local ax={}
function ax.set(ay)
ay=ay*aq
ar.Visible=ay>0
for az,aA in ipairs(as)do
local aB=1-(1-aA:GetAttribute"peak"*ay)^(1/aw)
for aC,aD in ipairs(aA:GetChildren())do aD.BackgroundTransparency=1-aB end
end
end
local function go(ay,az)
if not au or az~=av or not l.alive then return end
local aA=math.random(140,280)/10
local aB=l.TweenService:Create(ay,TweenInfo.new(aA,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=UDim2.fromOffset(math.random(0,math.floor(ar.Size.X.Offset)),math.random(0,math.floor(ar.Size.Y.Offset)))})
local aC=l.TweenService:Create(ay,TweenInfo.new(aA*0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{GroupTransparency=math.random(0,12)/100})
at[ay]={aB,aC}
aB.Completed:Connect(function()go(ay,az)end)
aB:Play();aC:Play()
end
function ax.play()if au or s.anim==0 then return end au,av=true,av+1 for ay,az in ipairs(as)do go(az,av)end end
function ax.stop()au,av=false,av+1 for ay,az in pairs(at)do for aA,aB in ipairs(az)do aB:Cancel()end end at={}end
ax.clip=ar
ax.set(math.clamp((tonumber(s.glow)or 80)/100,0,1)/1.5)
l.glowFields[#l.glowFields+1]=ax
return ax
end
glowField(al,647,51,25,1)
al.Active=true

l.spots={}
function l.spot(am,an,ao,ap,aq,ar,as)
local at=new("CanvasGroup",{Name="Spot",Size=UDim2.fromOffset(an,ao),BackgroundTransparency=1,BorderSizePixel=0,Interactable=false,ZIndex=aq},am)
new("UICorner",{CornerRadius=UDim.new(0,ap)},at)
l.deco(at)
local au,av=120,10
local aw=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(au,au),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,Interactable=false},at)
local ax=1-(0.9)^(1/av)
for ay=1,av do
local az=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(au*ay/av,au*ay/av),BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1-ax,Interactable=false},aw)
new("UICorner",{CornerRadius=UDim.new(1,0)},az)
end
l.spots[#l.spots+1]={area=ar,live=as,hold=aw}
return at
end
l.spot(al,647,51,25,2,al,function()return l.barOpen end)


local am={BackgroundTransparency=1,Position=UDim2.fromOffset(19,0),Size=UDim2.fromOffset(610,51),
Font=aa,TextSize=fs(16),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center}
local an=new("TextLabel",mix(am,{Text=""}),ak)
paint(an,"TextColor3","dim")
local ao=new("TextBox",mix(am,{ClearTextOnFocus=false,Text="",PlaceholderText=""}),ak)
paint(ao,"TextColor3","text");paint(ao,"PlaceholderColor3","hint")
n.box=ao

local ap=new("Frame",{Name="List",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,51),Size=UDim2.fromOffset(593,0),
AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=0.1,BorderSizePixel=0,Visible=false,Active=true},ak)
paint(ap,"BackgroundColor3","bar")
new("UICorner",{CornerRadius=UDim.new(0,ah.rCtrl)},ap)
paint(new("UIStroke",{Thickness=2,Transparency=0.55,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},ap),"Color","accent")
new("UIPadding",{PaddingLeft=UDim.new(0,15),PaddingRight=UDim.new(0,15),PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,10)},ap)
new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},ap)

do
local aq=new("Frame",{Name="GlowHolder",LayoutOrder=0,Size=UDim2.fromOffset(0,0),BackgroundTransparency=1,BorderSizePixel=0,Interactable=false},ap)
local ar=glowField(aq,593,8,ah.rCtrl,0.6).clip
local as=l.spot(aq,593,8,ah.rCtrl,2,ap,function()return l.barOpen and ap.Visible end)
ar.Position,as.Position=UDim2.fromOffset(-15,-8),UDim2.fromOffset(-15,-8)
local function size()ar.Size=UDim2.fromOffset(ap.AbsoluteSize.X/n.barScale.Scale,ap.AbsoluteSize.Y/n.barScale.Scale);as.Size=ar.Size end
ap:GetPropertyChangedSignal"AbsoluteSize":Connect(size)
size()
end
local aq={}
for ar=1,20 do
local as=new("TextLabel",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0,BackgroundTransparency=1,
Font=aa,TextSize=fs(14),RichText=true,TextWrapped=true,Text="",Visible=false,LayoutOrder=ar,
TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},ap)
paint(as,"TextColor3","text");paint(as,"BackgroundColor3","text")
aq[ar]=as
end



local ar=24
local function section(as)
local at=new("ScrollingFrame",{LayoutOrder=as,Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,BorderSizePixel=0,
ScrollBarThickness=3,ScrollBarImageColor3=col"dim",AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),
ElasticBehavior=Enum.ElasticBehavior.Never,Visible=false},ap)
new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},at)
return at
end
local as,at=section(101),section(103)
local au=new("Frame",{LayoutOrder=102,Size=UDim2.new(1,0,0,9),BackgroundTransparency=1,Visible=false},ap)
local av=new("Frame",{Position=UDim2.fromOffset(0,4),Size=UDim2.new(1,0,0,1),BorderSizePixel=0,BackgroundTransparency=0.5},au)
paint(av,"BackgroundColor3","dim")
local aw
for ax,ay in pairs{recent=as,all=at}do
ay.MouseEnter:Connect(function()aw=ax end)
ay.MouseLeave:Connect(function()if aw==ax then aw=nil end end)
end


local ax=new("TextLabel",{Name="Tip",Visible=false,ZIndex=20,Size=UDim2.fromOffset(360,0),AutomaticSize=Enum.AutomaticSize.Y,
BackgroundTransparency=0.05,BorderSizePixel=0,Font=aa,TextSize=fs(13),RichText=true,TextWrapped=true,
TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},ak)
paint(ax,"BackgroundColor3","bar");paint(ax,"TextColor3","text")
new("UICorner",{CornerRadius=UDim.new(0,ah.rCtrl)},ax)
paint(new("UIStroke",{Thickness=1,Transparency=0.4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},ax),"Color","accent")
new("UIPadding",{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9),PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},ax)
local ay=0
local function hideTip()ay=ay+1;ax.Visible=false end
local function showTip(az)
hideTip()
if not az or not az.lbl then return end
local aA=ay
local aB=az.rich:gsub("<[^>]+>",""):gsub("&lt;","<"):gsub("&gt;",">"):gsub("&amp;","&")
local aC,aD=pcall(function()return l.TextService:GetTextSize(aB,fs(14),aa,Vector2.new(10000,ar))end)
if not aC then return end
task.spawn(function()
l.RunService.RenderStepped:Wait();l.RunService.RenderStepped:Wait()
if aA~=ay or not az.lbl.Parent then return end
local aE=n.barScale.Scale
if aD.X<=az.lbl.AbsoluteSize.X/aE-4 then return end
local K,L,M=(az.lbl.AbsolutePosition-ak.AbsolutePosition)/aE,s.pos=="Bottom",ap.Size.X.Offset
ax.AnchorPoint=Vector2.new(0,L and 1 or 0)
ax.Position=UDim2.fromOffset(math.clamp(K.X,323.5-M/2,323.5+M/2-360),L and K.Y-2 or K.Y+ar+2)
ax.Text=az.rich
ax.Visible=true
end)
end
conn(l.UserInputService.InputChanged,function(az)
if az.UserInputType==Enum.UserInputType.MouseWheel then hideTip()end
end)


function n.layoutBar()
local az=s.pos
ak.Position=UDim2.fromScale(0.5,az=="Top"and 0.06 or az=="Bottom"and 0.86 or 0.29444444444444445)
ap.AnchorPoint=Vector2.new(0.5,az=="Bottom"and 1 or 0)
ap.Position=az=="Bottom"and UDim2.new(0.5,0,0,0)or UDim2.new(0.5,0,0,53)
end


local function rowText(az,aA)
local aB={}
for aC,aD in ipairs(az.names)do aB[#aB+1]=hl(aD,aA)end
local aC='<font color="'..hex(col"dim")..'">'
local aD=table.concat(aB," / ")
if az.args~=""then aD=aD.." "..aC..esc(az.args).."</font>"end
if az.desc~=""then aD=aD.." "..aC.."- "..esc(az.desc).."</font>"end
return aD
end

local function hideSug()
as.Visible,at.Visible,au.Visible=false,false,false
hideTip()
end
local function sugHighlight(az)
for aA,aB in ipairs(l.sugItems or{})do
local aC=aA==l.sugSel
paint(aB.lbl,"BackgroundColor3","text")
aB.lbl.BackgroundTransparency=aC and 0.85 or 1
if aC and not az then
local aD,aE=aB.sf or aB.lbl.Parent,aB.rowY or(aB.lbl.LayoutOrder-1)*ar
local K=aD.Size.Y.Offset
if aE<aD.CanvasPosition.Y then aD.CanvasPosition=Vector2.new(0,aE)
elseif aE+ar>aD.CanvasPosition.Y+K then aD.CanvasPosition=Vector2.new(0,aE+ar-K)end
end
end
showTip((l.sugItems or{})[l.sugSel])
end

local function addRows(az,aA,aB)
for aC,aD in ipairs(az:GetChildren())do
if aD:IsA"GuiButton"or aD:IsA"GuiLabel"or aD.Name=="Cols"then aD:Destroy()end
end
aB=aB or 1
local aC={}
if aB>1 then
local aD=new("Frame",{Name="Cols",Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1},az)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder},aD)
for aE=1,aB do
local K=new("Frame",{Size=UDim2.new(1/aB,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=aE},aD)
new("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},K)
aC[aE]=K
end
else
aC[1]=az
end
local aD=math.ceil(#aA/aB)
local aE,K=1,0
for L,M in ipairs(aA)do
if aE<aB and K>=aD and(M.header or K>=aD+6)then aE,K=aE+1,0 end
K=K+1
if M.header then
local N=new("TextLabel",{Size=UDim2.new(1,-6,0,ar),LayoutOrder=K,BackgroundTransparency=1,BorderSizePixel=0,
Font=ab,TextSize=fs(12),RichText=true,Text=M.rich,TextXAlignment=Enum.TextXAlignment.Left,
TextYAlignment=Enum.TextYAlignment.Bottom},aC[aE])
paint(N,"TextColor3","accentText")
else
local N=new("TextButton",{Size=UDim2.new(1,-6,0,ar),LayoutOrder=K,BackgroundTransparency=1,BorderSizePixel=0,AutoButtonColor=false,
Font=aa,TextSize=fs(14),RichText=true,Text=M.rich,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},aC[aE])
paint(N,"TextColor3","text");paint(N,"BackgroundColor3","text")
M.lbl,M.sf,M.rowY,M.col,M.row=N,az,(K-1)*ar,aE,K
N.MouseButton1Click:Connect(function()n.pickSug(M)end)
N.MouseEnter:Connect(function()
for O,P in ipairs(l.sugItems or{})do
if P==M then
if l.sugSel~=O then l.sugSel=O;sugHighlight(true)end
break
end
end
end)
end
end
end
function n.sugRender()
local az=l.sugMode or"both"
local aA,aB={},{}
for aC,aD in ipairs(s.hist)do aA[#aA+1]={text=aD,rich=esc(aD)}end
for aC,aD in ipairs(n.entries())do aB[#aB+1]={text=aD.canon,rich=rowText(aD,"")}end
local function cut(aC,aD)
local aE={}
for K=1,math.min(#aC,aD)do aE[K]=aC[K]end
return aE
end
local aC,aD=1
if az=="all"then

local aE={}
for K,L in ipairs(n.entries())do
aE[L.cat]=aE[L.cat]or{}
aE[L.cat][#aE[L.cat]+1]={text=L.canon,rich=rowText(L,"")}
end
aD={}
for K,L in ipairs(z.CAT_ORDER)do
if aE[L]then
aD[#aD+1]={header=true,rich=esc(L)..' <font color="'..hex(col"dim")..'">'..#aE[L].."</font>"}
for M,N in ipairs(aE[L])do aD[#aD+1]=N end
end
end
if s.sugCols then
local K=workspace.CurrentCamera.ViewportSize.X/n.curScale()
aC=math.clamp(math.floor((K-80)/400),1,3)
end
end
local aE=az=="all"and{}or(az=="recent"and aA or cut(aA,4))
local K=az=="recent"and{}or(az=="all"and aD or cut(aB,4))
if az~="all"and#aE==0 then
aE={{text="",empty=true,rich='<font color="'..hex(col"dim")..'">No recent commands yet</font>'}}
end
local function height(L,M,N)
if not M then return math.min(#L,4)*ar end
local O=N>1 and math.floor(workspace.CurrentCamera.ViewportSize.Y/n.curScale()*0.55/ar)or 0
return math.min(math.ceil(#L/N),math.max(s.lines,4,O))*ar
end
ap.Size=UDim2.fromOffset(aC>1 and aC*400+30 or 593,0)
as.Size=UDim2.new(1,0,0,height(aE,az=="recent",1))
at.Size=UDim2.new(1,0,0,height(K,az=="all",aC))
as.Visible,at.Visible,au.Visible=az~="all",az~="recent",az=="both"
addRows(as,aE,1);addRows(at,K,aC)
l.sugItems={}
for L,M in ipairs(aE)do
if not M.empty then l.sugItems[#l.sugItems+1]=M end
end
for L,M in ipairs(K)do
if not M.header then l.sugItems[#l.sugItems+1]=M end
end
l.sugSel=math.min(l.sugSel or 1,math.max(#l.sugItems,1))
ap.Visible=true
sugHighlight()
end
function n.pickSug(az)
if az.empty or not l.barOpen then return end
ao.Text=az.text
ao:CaptureFocus()
ao.CursorPosition=#ao.Text+1
end
conn(l.UserInputService.InputChanged,function(az)
if az.UserInputType==Enum.UserInputType.MouseWheel and l.barOpen and l.sugOn and(l.sugMode or"both")=="both"and aw then
l.sugMode,l.sugSel=aw,1
n.sugRender()
end
end)
function n.pushHistory(az)
az=(az:gsub("^%s*;","")):match"^%s*(.-)%s*$"
if az==""then return end
for aA=#s.hist,1,-1 do
if s.hist[aA]==az then table.remove(s.hist,aA)end
end
table.insert(s.hist,1,az)
while#s.hist>30 do table.remove(s.hist)end
save()
end

function n.render()
if not l.sugOn then ap.Size=UDim2.fromOffset(593,0)end
local az=math.min(#l.cur,s.lines)
for aA=1,20 do
local aB,aC=aq[aA],l.cur[aA]
if aA<=az and aC then
aB.Visible=true
aB.Text=rowText(aC,l.q or"")
paint(aB,"BackgroundColor3",aA==l.sel and"accent"or"text")
aB.BackgroundTransparency=(aA==l.sel)and 0.85 or 1
else
aB.Visible=false
end
end
ap.Visible=az>0 or l.sugOn==true
if(l.ghost or"")~=""and l.ghostX then
an.Text=l.ghost
an.Position=UDim2.fromOffset(19+l.ghostX,0)
else
an.Text=""
end
end


function n.argSuggest(az,aA,aB)
local aC={}
for aD in aB:gmatch"%S+"do aC[#aC+1]=aD end
local aD=""
if not aB:match"%s$"then aD=table.remove(aC)or""end
local aE,K=aD:lower(),{}
local L=(l.pre or"")..aA.." "..table.concat(aC," ")..(#aC>0 and" "or"")
for M,N in ipairs(az.complete(#aC+1,aE,aC)or{})do
local O=N.text
if aE==""or O:lower():find(aE,1,true)then
K[#K+1]={names={O},args="",desc=N.desc or"",canon=O,fill=L..(O:find"%s"and('"'..O..'"')or O).." ",pre=O:lower():sub(1,#aE)==aE}
end
end
table.sort(K,function(M,N)
if M.pre~=N.pre then return M.pre end
return M.names[1]:lower()<N.names[1]:lower()
end)
for M=1,math.min(#K,10)do l.cur[#l.cur+1]=K[M]end
if#l.cur>1 then l.sel,l.q=2,aD end
end

function n.search()
local az=ao.Text:gsub("^%s*;","")
local aA,aB=az:match"^%s*(%S*)(.*)$"
aA=(aA or""):lower()
l.pre,l.tail="",aB
do
local aC=z.Aliases[aA]
if aB~=""and(aC=="sudo"or aC=="all")then
local aD=aB:gsub("^%s+","")
local aE=aD:match"^@%S*"
local K=true
if aE then
local L=aD:sub(#aE+1)
if L:match"^%s"then aD=L:gsub("^%s+","")else K=false end
end
if K then
l.pre=az:sub(1,#az-#aD)
az=aD
aA,aB=az:match"^%s*(%S*)(.*)$"
aA=(aA or""):lower()
l.tail=aB
end
end
end
l.q,l.sel,l.cur,l.ghost,l.ghostX,l.sugOn=aA,1,{},"",nil,false
if aB~=""and z.Aliases[aA]then

for aC,aD in ipairs(n.entries())do
if aD.canon==z.Aliases[aA]then l.cur={aD}end
end

local aC=aB:match"^%s+(%S*)$"
local aD=l.cur[1]and z.Meta[l.cur[1].canon]
if aD and aD.complete then n.argSuggest(aD,aA,aB)end
if l.cur[1]and aC and not(aD and aD.complete)and tostring(l.cur[1].args):find"^<player"then
local aE,K=aC:lower(),{}
for L,M in ipairs(l.Players:GetPlayers())do
local N,O=M.Name:lower(),M.DisplayName:lower()
if aE==""or N:find(aE,1,true)or O:find(aE,1,true)then
K[#K+1]={names={M.Name},args="",desc=M.DisplayName~=M.Name and M.DisplayName or"",canon=M.Name,fill=(l.pre or"")..aA.." "..M.Name.." ",pre=N:sub(1,#aE)==aE or O:sub(1,#aE)==aE}
end
end
table.sort(K,function(L,M)
if L.pre~=M.pre then return L.pre end
return L.names[1]:lower()<M.names[1]:lower()
end)
for L=1,math.min(#K,8)do l.cur[#l.cur+1]=K[L]end
if#l.cur>1 then l.sel,l.q=2,aC end
end
elseif aB~=""then

l.cur=n.matches(az)
l.q=""
elseif aA==""then
if l.showAll or l.pre~=""then l.cur=n.entries()else l.sugOn=true end
else
l.cur=n.matches(aA)
for aC,aD in ipairs(l.cur[1]and l.cur[1].names or{})do
if aD:sub(1,#aA)==aA and#aD>#aA then

local aE,K=pcall(function()return l.TextService:GetTextSize(ao.Text,fs(16),aa,Vector2.new(10000,51))end)
if aE then l.ghost,l.ghostX=aD:sub(#aA+1),K.X end
break
end
end
end
if l.sugOn then n.sugRender()else hideSug()end
n.render()
end

function n.move(az)
if l.sugOn then
local aA=#(l.sugItems or{})
if aA==0 then return end
l.sugSel=(l.sugSel-1+az)%aA+1
return sugHighlight()
end
if#l.cur==0 then return end
local aA=math.min(#l.cur,s.lines)
l.sel=(l.sel-1+az)%aA+1
n.render()
end


function n.moveH(az)
local aA=(l.sugItems or{})[l.sugSel]
if not(l.sugOn and aA and aA.col)then return end
local aB,aC
for aD,aE in ipairs(l.sugItems)do
if aE.sf==aA.sf and aE.col==aA.col+az and(not aC or math.abs(aE.row-aA.row)<aC)then aB,aC=aE,math.abs(aE.row-aA.row)end
end
for aD,aE in ipairs(l.sugItems)do
if aE==aB then l.sugSel=aD;sugHighlight()end
end
end


local az=0
function n.hold(aA,aB)
aB()
az=az+1
local aC=az
task.spawn(function()
task.wait(0.3)
while aC==az and l.barOpen and l.UserInputService:IsKeyDown(aA)do aB();task.wait(0.04)end
end)
end


function n.complete()
if l.sugOn then
local aA=(l.sugItems or{})[l.sugSel]
if aA then n.pickSug(aA)end
return
end
local aA=l.cur[l.sel]
if not aA then return end
if aA.fill then
ao.Text=aA.fill
ao.CursorPosition=#ao.Text+1
return
end
local aB,aC=l.q or"",aA.canon
for aD,aE in ipairs(aA.names)do
if aE:sub(1,#aB)==aB then aC=aE;break end
end
ao.Text=(l.pre or"")..aC..(l.tail or"")
ao.CursorPosition=#ao.Text+1
end

function n.openBar(aA,aB)
if l.barOpen then return end
l.barOpen,l.showAll=true,aB
l.sugMode,l.sugSel="both",1
n.layoutBar()
ao.Text=aA or""
aj.Visible=true
aj.Position=UDim2.fromOffset(0,s.pos=="Top"and-16 or 16)
tw(aj,{GroupTransparency=0},0.16)
tw(aj,{Position=UDim2.new()},0.3)
local aC=n.curScale()
n.barScale.Scale=aC
tw(n.blur,{Size=18*s.blur},0.2)
if l.panelOpen and n.shade then n.shade.Visible=true end
n.syncMouse()
for aD,aE in ipairs(l.glowFields)do aE.play()end
l.RunService.RenderStepped:Wait()
ao:CaptureFocus()
ao.Text=aA or""
ao.CursorPosition=#ao.Text+1
n.search()
end

function n.closeBar()
if not l.barOpen then return end
l.barOpen,l.sugOn=false,false
for aA,aB in ipairs(l.glowFields)do aB.stop()end
ao:ReleaseFocus()
tw(aj,{GroupTransparency=1},0.1)
task.delay(dur(0.1),function()
if not l.barOpen then aj.Visible=false;ao.Text=""end
end)
if n.shade then n.shade.Visible=false end
tw(n.blur,{Size=0},0.2)
n.syncMouse()
end


local function mouseInList()
if not ap.Visible then return false end
local aA,aB,aC=l.UserInputService:GetMouseLocation(),ap.AbsolutePosition,ap.AbsoluteSize
return aA.X>=aB.X and aA.X<=aB.X+aC.X and aA.Y>=aB.Y and aA.Y<=aB.Y+aC.Y
end
ao:GetPropertyChangedSignal"Text":Connect(function()
if ao.Text:find"\t"then
ao.Text=ao.Text:gsub("\t","")
ao.CursorPosition=#ao.Text+1
return
end
if l.barOpen then n.search()end
end)
ao.FocusLost:Connect(function(aA)
if not l.barOpen then return end
if not aA and mouseInList()then
task.defer(function()if l.barOpen then ao:CaptureFocus()end end)
return
end
local aB=ao.Text
n.closeBar()
if aA and aB:match"%S"then
n.pushHistory(aB)
z.Run(aB)
end
end)
end



rest"UI_BAR"

local aj,ak,al={},{},{}
local am,an,ao={},{},{}

local ap={PW=760,PH=488,SIDE=152,TOP=58,MARG=12}
ap.IX=ap.SIDE+2
ap.IW=ap.PW-ap.IX-ap.MARG
ap.IH=ap.PH-ap.TOP-ap.MARG
ap.DX=ap.IW-532
ap.DY=ap.IH-379
l.opScope=true
do
local aq=new("CanvasGroup",{Name="PanelFade",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=1,Visible=false},af)
local ar=new("Frame",{Name="Panel",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(ap.PW,ap.PH),BorderSizePixel=0,Active=true},aq)
paint(ar,"BackgroundColor3","panel")
new("UICorner",{CornerRadius=UDim.new(0,12)},ar)

local as=new("UIStroke",{Thickness=1.5,Transparency=0.1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},ar)
paint(as,"Color","accent")
local at=new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,0.88),NumberSequenceKeypoint.new(0.7,0.88),NumberSequenceKeypoint.new(1,0)}},as)
l.deco(at)
n.borderTween=l.TweenService:Create(at,TweenInfo.new(7,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1),{Rotation=360})
if s.anim~=0 then n.borderTween:Play()end

do

local au=new("CanvasGroup",{Size=UDim2.fromOffset(ap.PW,ap.PH),BackgroundTransparency=1,BorderSizePixel=0},ar)
new("UICorner",{CornerRadius=UDim.new(0,12)},au)

local av,aw,ax,ay={},{},false,0

for az,aA in ipairs{{true,900,0.3},{true,760,0.22},{true,1000,0.16},{false,700,0.12}}do
local aB=aA[2]
local aC=new("CanvasGroup",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromOffset(math.random(0,ap.PW),math.random(0,ap.PH)),Size=UDim2.fromOffset(aB,aB),
BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=math.random(0,12)/100},au)
av[#av+1]=aC
if not aA[1]then l.deco(aC)end
local aD=18
aC:SetAttribute("peak",aA[3])
local aE=1-(1-aA[3]*math.clamp((tonumber(s.glow)or 80)/100,0,1)/1.5)^(1/aD)
for K=1,aD do
local L=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(aB*K/aD,aB*K/aD),BorderSizePixel=0,BackgroundTransparency=1-aE},aC)
if aA[1]then paint(L,"BackgroundColor3","accent")else L.BackgroundColor3=Color3.new(1,1,1)end
new("UICorner",{CornerRadius=UDim.new(1,0)},L)
end
end

function n.setGlow()
local az=math.clamp((tonumber(s.glow)or 80)/100,0,1)/1.5
for aA,aB in ipairs(l.glowFields)do aB.set(az)end
au.Visible=az>0
for aA,aB in ipairs(av)do
local aC=1-(1-aB:GetAttribute"peak"*az)^(5.555555555555555E-2)
for aD,aE in ipairs(aB:GetChildren())do
if aE:IsA"Frame"then tw(aE,{BackgroundTransparency=1-aC},0.3)end
end
end
end
local function go(az,aA)
if not ax or aA~=ay then return end
local aB=math.random(140,280)/10
local aC=l.TweenService:Create(az,TweenInfo.new(aB,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Position=UDim2.fromOffset(math.random(0,ap.PW),math.random(0,ap.PH))})
local aD=l.TweenService:Create(az,TweenInfo.new(aB*0.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{GroupTransparency=math.random(0,12)/100})
aw[az]={aC,aD}
aC.Completed:Connect(function()go(az,aA)end)
aC:Play();aD:Play()
end
local function stop()
ax,ay=false,ay+1
for az,aA in pairs(aw)do for aB,aC in ipairs(aA)do aC:Cancel()end end
aw={}
end

n.orbitTween={Play=function()if ax then return end ax,ay=true,ay+1 for az,aA in ipairs(av)do go(aA,ay)end end,Pause=stop,Cancel=stop}
if s.anim~=0 then n.orbitTween:Play()end
end

n.panel=ar
n.panelScale=new("UIScale",{},ar)

l.spot(ar,ap.PW,ap.PH,12,1,ar,function()return l.panelOpen and not l.barOpen end)

fr(ar,14,0,ap.PW-28,2,"accent",0.7)
do
local au=fr(ar,14,0,ap.PW-28,2,"accent",0)
local av=new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)},Offset=Vector2.new(-1,0)},au)
n.glowTween=l.TweenService:Create(av,TweenInfo.new(5,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1),{Offset=Vector2.new(1,0)})
if s.anim~=0 then n.glowTween:Play()end
end


function n.placePanel(au,av)
local aw=workspace.CurrentCamera.ViewportSize
local ax=UDim2.fromScale(n.panelPos.X,n.panelPos.Y+(au or 0)/aw.Y)
if av then tw(ar,{Position=ax},0.3)else ar.Position=ax end
end
function n.centerPanel()
n.panelPos=Vector2.new(0.5,0.5)
n.placePanel(0)
end
n.centerPanel()

n.title=txt(ar,"",14,"text",22,17,150,26,{Font=ac,RichText=true,TextSize=21})
l.deco(new("UIGradient",{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(165,165,178))},n.title))
do
local au=fr(ar,14,ap.TOP-1,ap.PW-28,1,"accent",0.8)
new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)}},au)
l.deco(au)
end
txt(ar,"open-source admin/dev panel",8,"hint",172,25,220,14,{Font=ac,TextSize=11})

btn(ar,"×",ap.PW-46,14,34,28,"ghost",nil,function()n.setPanel(false)end,13)


do
local au={sys={},pid="-",col={ok=Color3.fromRGB(70,200,90),warn=Color3.fromRGB(255,165,40),bad=Color3.fromRGB(230,60,60)}}
n.rel=au
local av=new("Frame",{Position=UDim2.fromOffset(ap.PW-66,24),Size=UDim2.fromOffset(10,10),BorderSizePixel=0,Visible=false},ar)
new("UICorner",{CornerRadius=UDim.new(1,0)},av)
local aw=txt(ar,"",8,"sub",ap.PW-148,22,76,14,{TextXAlignment=Enum.TextXAlignment.Right,TextTruncate=Enum.TextTruncate.AtEnd,Visible=false})
local function poll()
local ax,ay=pcall(o,{Url="http://127.0.0.1:47653/sys",Method="GET"})
local az
if ax and type(ay)=="table"and ay.StatusCode==200 then ax,az=pcall(l.HttpService.JSONDecode,l.HttpService,ay.Body)end
if type(az)=="table"then au.sys,au.s=az,az.err and"bad"or az.warn and"warn"or"ok"
elseif au.s then au.s="bad"end
local aA=(getgenv and getgenv()or{}).getpid or(getgenv and getgenv()or{}).get_pid
local aB,aC=pcall(function()return aA()end)
local aD=au.sys.pids

au.pid=aB and tonumber(aC)and tostring(aC)or(aD and#aD>0 and table.concat(aD,"/"))or"-"
av.Visible,aw.Visible=au.s~=nil,au.s~=nil
if au.s then av.BackgroundColor3,aw.Text=au.col[au.s],"PID "..au.pid end
end
task.spawn(function()
local ax=true
while l.alive do
if l.panelOpen or ax then ax=false;pcall(poll)end
task.wait(3)
end
end)
end


local au=new("Frame",{Size=UDim2.fromOffset(ap.PW-50,ap.TOP-6),BackgroundTransparency=1},ar)
local av,aw,ax
au.InputBegan:Connect(function(ay)
if ay.UserInputType==Enum.UserInputType.MouseButton1 or ay.UserInputType==Enum.UserInputType.Touch then
av,aw,ax=true,ay.Position,n.panelPos
end
end)
conn(l.UserInputService.InputChanged,function(ay)
if av and(ay.UserInputType==Enum.UserInputType.MouseMovement or ay.UserInputType==Enum.UserInputType.Touch)then
local az=workspace.CurrentCamera.ViewportSize
local aA=ay.Position-aw
n.panelPos=Vector2.new(ax.X+aA.X/az.X,ax.Y+aA.Y/az.Y)
n.placePanel(0)
end
end)
conn(l.UserInputService.InputEnded,function(ay)
if av and(ay.UserInputType==Enum.UserInputType.MouseButton1 or ay.UserInputType==Enum.UserInputType.Touch)then
av=false
l.dragged=true
end
end)

local ay=fr(ar,ap.IX,ap.TOP,ap.IW,ap.IH,"glass",0.75,10,"edge",1,0.7)
ay.ClipsDescendants=true
n.inner=ay



do
local az,aA={},false
local aB=new("CanvasGroup",{Name="Busy",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-12,0,10),Size=UDim2.fromOffset(98,24),BackgroundTransparency=0.1,
BorderSizePixel=0,GroupTransparency=1,Visible=false,ZIndex=30,Interactable=false},ay)
paint(aB,"BackgroundColor3","bar")
new("UICorner",{CornerRadius=UDim.new(0,ah.rCtrl)},aB)
paint(new("UIStroke",{Thickness=1,Transparency=0.4,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},aB),"Color","accent")
local aC=txt(aB,"Loading",9,"text",14,0,80,24,{TextYAlignment=Enum.TextYAlignment.Center})
local aD=new("Frame",{Position=UDim2.fromOffset(-90,0),Size=UDim2.fromOffset(90,2),BorderSizePixel=0,Visible=false,ZIndex=30,Interactable=false},ay)
paint(aD,"BackgroundColor3","accent")
new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)}},aD)
local aE=l.TweenService:Create(aD,TweenInfo.new(1.1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1),{Position=UDim2.fromOffset(ap.IW,0)})
n.busyTween=aE
local function want()
local K=os.clock()
for L,M in pairs(az)do
if K-M.t>20 then az[L]=nil
elseif M.tab==nil or M.tab==n.tab then return true end
end
return false
end
function n.busySync()
local K=want()
if K==aA then return end
aA,n.busyOn=K,K
if K then
aB.Visible,aD.Visible=true,true
tw(aB,{GroupTransparency=0},0.16)
if s.anim~=0 and l.panelOpen then aE:Play()end
task.spawn(function()
local L=0
while aA and l.alive do
L=L%3+1
aC.Text="Loading"..("."):rep(L)
task.wait(0.35)
end
end)
else
tw(aB,{GroupTransparency=1},0.16)
task.delay(dur(0.16)+0.05,function()
if not aA then aB.Visible,aD.Visible=false,false;aE:Pause()end
end)
end
end
function n.busy(K,L,M)
az[K]=L and{t=os.clock(),tab=M}or nil
n.busySync()
end
end

function n.ambient()
local az=l.panelOpen and s.anim~=0
for aA,aB in ipairs{"glowTween","borderTween","orbitTween","busyTween"}do
local aC=n[aB]
if aC then
pcall(function()
local aD=az and(aB~="orbitTween"or(tonumber(s.glow)or 0)>0)and(aB~="busyTween"or n.busyOn)
if aD then aC:Play()else aC:Pause()end
end)
end
end
end

function n.lazy(az,aA)an[az]=aA end
n.building={}
function n.tick()
local az=coroutine.running()
if not n.building[az]then return end
n.nTick=(n.nTick or 0)+1
if n.nTick%6==0 then task.wait()end
end

function n.pageIn(az)
if s.anim==0 then az.GroupTransparency,az.Position=0,UDim2.new();return end
az.GroupTransparency,az.Position=1,UDim2.fromOffset(0,18)
tw(az,{GroupTransparency=0},0.16)
tw(az,{Position=UDim2.new()},0.3)
end
function n.showPage(az,aA)
local aB,aC=aj[az],an[az]
if ao[az]then return end
if not aC then
if aA then n.pageIn(aB)end
if al[az]then al[az]()end
return
end
an[az],ao[az]=nil,true
aB.GroupTransparency=1
n.busy("page:"..az,true,az)
task.spawn(function()
local aD=coroutine.running()
n.building[aD]=true
task.wait()
local aE,K=pcall(aC)
n.building[aD],ao[az]=nil,nil
n.busy("page:"..az,false)
if not aE then z.notify(az.." page failed: "..tostring(K),6)end
if n.tab==az then
n.pageIn(aB)
if al[az]then al[az]()end
else
aB.GroupTransparency=0
end
end)
end




local az,aA,aB,aC={},{},32,ap.TOP+8
for aD,aE in ipairs{{nil,{"Home","Players","Servers"}},{"TOOLS",{"Commands","Keybinds","Autostart","Load scripts"}},{"SETTINGS",{"Look and feel","Preferences","Module Cfg"}}}do
if aE[1]then aA[#aA+1]={aE[1],aC+5};aC=aC+22 end
for K,L in ipairs(aE[2])do az[#az+1]={L,aC};aC=aC+36 end
end
n.side=fr(ar,0,ap.TOP,ap.SIDE,ap.IH,"glass",0.75,10,"edge",1,0.7)
for aD,aE in ipairs(aA)do txt(ar,aE[1],7,"hint",6,aE[2],ap.SIDE-26,14,{Font=ab,TextXAlignment=Enum.TextXAlignment.Right})end



for aD,aE in ipairs(az)do
local K=aE[1]

local L={glow=fr(ar,6,aE[2],ap.SIDE-12,aB,nil)}
paint(L.glow,"BackgroundColor3","accent")
L.glow.BackgroundTransparency=1
l.deco(L.glow)
new("UICorner",{CornerRadius=UDim.new(0,8)},L.glow)
new("UIGradient",{Transparency=NumberSequence.new(1,0.75)},L.glow)
n.tabFx=n.tabFx or{}
n.tabFx[K]=L
local M=new("TextButton",{Position=UDim2.fromOffset(6,aE[2]),Size=UDim2.fromOffset(ap.SIDE-12,aB),AutoButtonColor=false,BorderSizePixel=0,
Text=K,Font=aa,TextSize=fs(10.5),TextXAlignment=Enum.TextXAlignment.Right},ar)
new("UICorner",{CornerRadius=UDim.new(0,8)},M)
new("UIPadding",{PaddingRight=UDim.new(0,14)},M)
paint(M,"TextColor3","text")
M.BackgroundTransparency=1
ak[K]=M
L.bar=fr(ar,12,aE[2]+8,3,16,"accent",1,2)
n.tabY=n.tabY or{}
n.tabY[K]=aE[2]
l.hover(M,function(N)
if n.tab~=K then
tw(L.glow,{BackgroundTransparency=N and ah.glow.hover or 1},0.1)
tw(L.bar,{BackgroundTransparency=N and 0.7 or 1},0.1)
end
end)
M.MouseButton1Click:Connect(function()n.selectTab(K)end)
aj[K]=new("CanvasGroup",{Name=K,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,Visible=false},ay)
end



function n.selectTab(aD)
local aE,K=n.tab==nil,n.tab
n.tab=aD
for L,M in pairs(aj)do M.Visible=(L==aD)end
if K and K~=aD and am[K]then pcall(am[K])end
if n.busySync then n.busySync()end
for L,M in pairs(ak)do
local N=L==aD
paint(M,"BackgroundColor3",N and"accent"or"tabOff")
paint(M,"TextColor3",N and"accentText"or"text")
tw(M,{BackgroundTransparency=N and 0.82 or 1},0.12)
tw(n.tabFx[L].glow,{BackgroundTransparency=N and 0 or 1},0.22)
tw(n.tabFx[L].bar,{BackgroundTransparency=N and 0 or 1},0.22)
end

n.showPage(aD,aE or K~=aD)
end


n.shade=fr(ar,0,0,ap.PW,ap.PH,"tabOff",0.45,9)
n.shade.ZIndex,n.shade.Active,n.shade.Visible=50,true,false

function n.setPanel(aD)
if aD and l.panelOpen then return end
l.panelOpen=aD
n.ambient()
if aD then
local aE=n.curScale()
n.panelScale.Scale=aE
n.placePanel(22,false)
aq.Visible=true
tw(aq,{GroupTransparency=0},0.16)
n.placePanel(0,true)

n.shade.Visible=l.barOpen and true or false
if al[n.tab]then al[n.tab]()end
else

tw(aq,{GroupTransparency=1},0.12)
n.placePanel(12,true)
task.delay(dur(0.12),function()if not l.panelOpen then aq.Visible=false end end)
end
n.syncMouse()
end
end




do
local aq=aj.Home


local function goodName(ar)return type(ar)=="string"and ar~=""and ar~="Ugc"and ar~="Game"and not ar:match"^Place%d*$"end
local ar=tostring(game.GameId)

local as=s.carry
if not goodName(game.Name)and not s.exp[ar]and as and as.name and os.time()-(as.t or 0)<300 then
s.exp[ar],s.expIcon[ar]=as.name,as.gid
save()
end
local at=s.exp[ar]or(goodName(game.Name)and game.Name or nil)
if goodName(game.Name)and not s.exp[ar]then s.exp[ar]=game.Name;save()end
if at then z.curExp={gid=s.expIcon[ar]or game.GameId,name=at}end
z.connect("expTp",A.OnTeleport,function()
if z.curExp then s.carry={gid=z.curExp.gid,name=z.curExp.name,t=os.time()};save()end
end)


local au={}
local av,aw=math.floor(ap.IW*0.4),12
local ax=18+av+aw
local ay=ap.IW-ax-18
local az=new("CanvasGroup",{Position=UDim2.fromOffset(ax,16),Size=UDim2.fromOffset(ay,132),BorderSizePixel=0,BackgroundTransparency=0.1},aq)
paint(az,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(0,ah.rPane)},az)
paint(new("UIStroke",{Thickness=1,Transparency=0.55,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},az),"Color","accent")
local aA,aB,aC,aD,aE
do
local K=new("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundTransparency=0.55,ZIndex=1},az)
paint(K,"BackgroundColor3","accent")
new("UIGradient",{Rotation=35,Transparency=NumberSequence.new(0.35,0.85)},K)
aD={}
for L=1,2 do
local M=new("ImageLabel",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,ImageTransparency=1,ZIndex=2},az)
aD[L]={im=M,sc=new("UIScale",{},M)}
end
local L=new("Frame",{Size=UDim2.fromScale(1,1),BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),ZIndex=4},az)
new("UIGradient",{Rotation=90,Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0.7),NumberSequenceKeypoint.new(0.45,0.85),NumberSequenceKeypoint.new(1,0.1)}},L)
local function white(M,N,O,P,Q,R,S)
return new("TextLabel",{BackgroundTransparency=1,Text=M,TextSize=fs(N),Font=S or aa,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=0.88,TextXAlignment=Enum.TextXAlignment.Left,
TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Position=UDim2.fromOffset(O,P),Size=UDim2.fromOffset(Q,R),ZIndex=6},az)
end
local M=new("ImageLabel",{Position=UDim2.fromOffset(14,50),Size=UDim2.fromOffset(64,64),BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop,BackgroundColor3=Color3.new(0.1,0.1,0.12),ZIndex=6,
Image=thumb("GameIcon",s.expIcon[ar]or game.GameId,150)},az)
new("UICorner",{CornerRadius=UDim.new(0,15)},M)
new("UIStroke",{Thickness=1.5,Color=Color3.new(1,1,1),Transparency=0.7,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},M)
aA=white(at or"...",15,90,52,ay-104,26,ab)
aB=white("",9,90,80,ay-104,18)
aB.TextTransparency=0.15
aC=white("",9,90,98,ay-104,16)
aC.TextTransparency=0.15

local N=game.JobId~=""and game.JobId or"local"
local O=new("TextButton",{Position=UDim2.fromOffset(12,10),Size=UDim2.fromOffset(0,20),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,
BorderSizePixel=0,AutoButtonColor=false,Text="●  "..N:sub(1,8),TextSize=fs(8.5),Font=ab,TextColor3=Color3.new(1,1,1),ZIndex=6},az)
new("UICorner",{CornerRadius=UDim.new(1,0)},O)
new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10)},O)
O.MouseEnter:Connect(function()tw(O,{BackgroundTransparency=0.3},0.1)end)
O.MouseLeave:Connect(function()tw(O,{BackgroundTransparency=0.5},0.12)end)
O.MouseButton1Click:Connect(function()
if setclipboard and game.JobId~=""then pcall(setclipboard,game.JobId);n.toast("Server ID copied",1.5)end
end)

aE=new("Frame",{AnchorPoint=Vector2.new(1,1),Position=UDim2.fromOffset(ay-12,120),Size=UDim2.fromOffset(0,14),AutomaticSize=Enum.AutomaticSize.X,BackgroundColor3=Color3.new(0,0,0),
BackgroundTransparency=0.55,BorderSizePixel=0,Visible=false,ZIndex=6},az)
new("UICorner",{CornerRadius=UDim.new(1,0)},aE)
new("UIPadding",{PaddingLeft=UDim.new(0,7),PaddingRight=UDim.new(0,7)},aE)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4),VerticalAlignment=Enum.VerticalAlignment.Center},aE)
end


local K={ids={},cur=0,front=1,dots={}}
local function bannerShow(L)
local M=K.front==1 and 2 or 1
local N,O=aD[M],aD[K.front]
K.cur=L
N.im.Image=("rbxthumb://type=Asset&id=%d&w=768&h=432"):format(K.ids[L])
local P=os.clock()
while not N.im.IsLoaded and os.clock()-P<5 and l.alive do task.wait(0.1)end
if not l.alive then return end
N.im.ZIndex,O.im.ZIndex=3,2
N.sc.Scale=1
tw(N.im,{ImageTransparency=0},0.5)
if s.anim~=0 then l.TweenService:Create(N.sc,TweenInfo.new(7/s.anim,Enum.EasingStyle.Linear),{Scale=1.12}):Play()end
task.delay(dur(0.5)+0.05,function()if K.front==M then O.im.ImageTransparency=1 end end)
K.front=M
for Q,R in ipairs(K.dots)do tw(R,{Size=UDim2.fromOffset(Q==L and 16 or 6,6),BackgroundTransparency=Q==L and 0 or 0.55},0.2)end
end
task.spawn(function()
local L=s.banner[ar]
local M=L and type(L.ids)=="table"and#L.ids>0 and os.time()-(L.t or 0)<86400 and L.ids or nil
if not M then
local N=z.fetch("https://games.roblox.com/v2/games/"..game.GameId.."/media")
local O,P=pcall(function()return l.HttpService:JSONDecode(N).data end)
M={}
if O and type(P)=="table"then
for Q,R in ipairs(P)do
if R.assetType=="Image"and tonumber(R.imageId)then M[#M+1]=tonumber(R.imageId)end
if#M>=6 then break end
end
end
if#M>0 then s.banner[ar]={ids=M,t=os.time()};save()end
end
if#M==0 then
aD[1].im.Image=thumb("GameIcon",s.expIcon[ar]or game.GameId,420)
tw(aD[1].im,{ImageTransparency=0.55},0.5)
return
end
K.ids=M
if#M>1 then
aE.Visible=true
for N=1,#M do K.dots[N]=new("Frame",{Size=UDim2.fromOffset(6,6),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.55,BorderSizePixel=0},aE);new("UICorner",{CornerRadius=UDim.new(1,0)},K.dots[N])end
end
bannerShow(1)
while l.alive and#M>1 do
local N=os.clock()
repeat task.wait(0.5)until not l.alive or(os.clock()-N>8 and l.panelOpen and n.tab=="Home")
if l.alive then bannerShow(K.cur%#M+1)end
end
end)
if not at then
task.spawn(function()

local L=z.fetch("https://games.roblox.com/v1/games?universeIds="..game.GameId)
local M,N=pcall(function()return l.HttpService:JSONDecode(L).data[1].name end)
local O=M and goodName(N)and N or nil
if not O then
local P,Q=pcall(function()return l.MarketplaceService:GetProductInfo(game.PlaceId)end)
O=P and Q and goodName(Q.Name)and Q.Name or nil
end
if O then s.exp[ar]=O;z.curExp={gid=game.GameId,name=O};save()end
aA.Text=O or game.Name
end)
end


local L,M,N={},"..."
local O=z.SRV.region(game.JobId)
if O then M=O.label end
local P,Q=158,8
local R=math.floor((ay-Q)/2)
for S,T in ipairs{"Players","Region","Latency","Uptime"}do
local U,V=ax+((S-1)%2)*(R+Q),P+math.floor((S-1)/2)*(62+Q)
local W=fr(aq,U,V,R,62,"row",0.6,12,"edge",1,0.6)
au[#au+1]={W,U,V}
txt(W,T:upper(),7.5,"sub",14,10,R-28,12,{Font=ab})
L[T]=txt(W,"-",13,"text",14,24,R-28,22,{Font=ab,TextYAlignment=Enum.TextYAlignment.Center,TextScaled=T=="Region"})
if T=="Region"then new("UITextSizeConstraint",{MaxTextSize=fs(13)},L[T])end
if T=="Players"then
local X=fr(W,14,51,R-28,3,"edge",0.5,2)
N=fr(X,0,0,0,3,"accent",0,2)
end
end


local S=av
local function pchFor(T)
local U,V=pcall(function()return l.TextService:GetTextSize(T,fs(9.5),aa,Vector2.new(S-32,1000))end)
return U and math.max(126,92+math.ceil(V.Y)+14)or 126
end
local T=j[math.random(#j)]
local U=pchFor(T)
local V=fr(aq,18,16,S,U,"row",0.6,14,"edge",1,0.6)
au[#au+1]={V,18,16}
local W=new("ImageLabel",{Position=UDim2.fromOffset(16,16),Size=UDim2.fromOffset(62,62),BorderSizePixel=0,BackgroundTransparency=0.9,Image=thumb("AvatarHeadShot",A.UserId,150)},V)
paint(W,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(1,0)},W)
paint(new("UIStroke",{Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},W),"Color","accent")
txt(V,"Good day,",8.5,"sub",92,19,S-104,13)
txt(V,A.DisplayName,13,"text",92,33,S-104,20,{Font=ab,TextTruncate=Enum.TextTruncate.AtEnd})
txt(V,"@"..A.Name,8.5,"sub",92,55,S-104,13,{TextTruncate=Enum.TextTruncate.AtEnd})
local X=txt(V,T,9.5,"sub",16,92,S-32,U-100,{TextWrapped=true})

local Y,Z,_=18,av,16+U+10
local aF=ap.IH-_-18
local aG=fr(aq,Y,_,Z,aF,"row",0.6,14,"edge",1,0.6)
local aH={aG,Y,_}
au[#au+1]=aH
if s.bio~=""then s.bios[tostring(A.UserId)]=s.bios[tostring(A.UserId)]or s.bio;s.bio="";save()end
local aI=new("TextBox",{Position=UDim2.fromOffset(14,14),Size=UDim2.fromOffset(Z-28,aF-80),BorderSizePixel=0,BackgroundTransparency=0.8,
Font=aa,TextSize=fs(9.5),MultiLine=true,TextWrapped=true,ClearTextOnFocus=false,Text=s.bios[tostring(A.UserId)]or"",PlaceholderText="customizable bio",
TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},aG)
paint(aI,"BackgroundColor3","tabOff");paint(aI,"TextColor3","text");paint(aI,"PlaceholderColor3","dim")
new("UICorner",{CornerRadius=UDim.new(0,8)},aI)
local aJ=new("UIStroke",{Thickness=1,Transparency=0.8,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},aI)
paint(aJ,"Color","tabOff")
new("UIPadding",{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,6)},aI)
aI.Focused:Connect(function()tw(aJ,{Color=l.accent,Transparency=0.2},0.1)end)
aI.FocusLost:Connect(function()
tw(aJ,{Color=col"tabOff",Transparency=0.8},0.12)
s.bios[tostring(A.UserId)]=aI.Text~=""and aI.Text or nil;save()
end)
local aK=fr(aG,14,aF-56,3,36,"accent",0,2)
local aL=txt(aG,"TIP",7.5,"accentText",24,aF-58,100,12,{Font=ab})
local aM=txt(aG,k[1],9,"dim",24,aF-43,Z-40,30,{TextWrapped=true,TextTruncate=Enum.TextTruncate.AtEnd})

local function fit(aN)
U=pchFor(aN)
_=16+U+10;aF=ap.IH-_-18
X.Text=aN
V.Size,X.Size=UDim2.fromOffset(S,U),UDim2.fromOffset(S-32,U-100)
aH[3]=_
aG.Position,aG.Size=UDim2.fromOffset(Y,_),UDim2.fromOffset(Z,aF)
aI.Size=UDim2.fromOffset(Z-28,aF-80)
aK.Position,aL.Position,aM.Position=UDim2.fromOffset(14,aF-56),UDim2.fromOffset(24,aF-58),UDim2.fromOffset(24,aF-43)
end


local aN=math.floor((ay-8)/2)
local function quick(aO,aP,aQ,aR,aS)
local aT=btn(aq,aO,aP,aQ,aR,28,nil,nil,aS)
au[#au+1]={aT,aP,aQ}
return aT
end
local function confirmBtn(aO,aP,aQ,aR)
local aS,aT=false
aT=quick(aO,aP,aQ,aN,function()
if aS then aS=false;aT.Text=aO;setFill(aT);return z.Run(aR)end
aS,aT.Text=true,"Click again"
setFill(aT,"danger")
task.delay(3,function()if aS and aT.Parent then aS=false;aT.Text=aO;setFill(aT)end end)
end)
end
local aO=ap.IH-18-28
quick("Open server browser",ax,aO,ay,function()z.openTab"Servers"end)
confirmBtn("Rejoin",ax,aO-34,"rejoin")
confirmBtn("Server hop",ax+aN+8,aO-34,"serverhop")
quick("Copy Job ID",ax,aO-68,aN,function()z.Run"jobid"end)
quick("Copy Place ID",ax+aN+8,aO-68,aN,function()z.Run"placeid"end)


al.Home=function()
if s.anim==0 then return end
az.GroupTransparency=1
tw(az,{GroupTransparency=0},0.3)
for aP,aQ in ipairs(au)do
aQ[1].Position=UDim2.fromOffset(aQ[2],aQ[3]+10)
task.delay(aP*0.03,function()tw(aQ[1],{Position=UDim2.fromOffset(aQ[2],aQ[3])},0.3)end)
end
end


local aP,aQ,aR=0,false,O~=nil
local function regionStep()
if aR or aQ or os.clock()-aP<30 then return end
aQ,aP=true,os.clock()
task.spawn(function()
local aS,aT=pcall(z.SRV.here)
aQ=false
if aS and aT then M,aR=aT,true
else M=z.SRV.relay==false and"Relay inactive"or"unavailable"end
end)
end

task.spawn(function()
local aS=os.clock()
while l.alive do
if l.panelOpen and n.tab=="Home"then
regionStep()
pcall(function()
local aT,aU=#l.Players:GetPlayers(),l.Players.MaxPlayers
L.Players.Text=aT.." / "..aU
tw(N,{Size=UDim2.new(math.clamp(aT/math.max(aU,1),0,1),0,1,0)},0.3)
L.Region.Text=M
local aV,aW=pcall(function()return l.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()end)
L.Latency.Text=aV and(math.floor(aW).." ms")or"-"
L.Latency.TextColor3=not aV and col"text"or aW<80 and Color3.fromRGB(52,199,89)or aW<160 and Color3.fromRGB(255,159,10)or Color3.fromRGB(255,69,58)
local aX=math.floor(workspace.DistributedGameTime)
L.Uptime.Text=("%02d:%02d:%02d"):format(math.floor(aX/3600),math.floor(aX/60)%60,aX%60)
aB.Text=M.."   ·   "..aT.." players"
z.AV.srvStep()
local aY,aZ,a_=z.AV.srvTotal()
aC.Text=("Avatars  R$ %s  ·  %d/%d counted"):format(z.AV.comma(aY),aZ,a_)
end)
end
if os.clock()-aS>300 then
aS=os.clock()
aM.Text=k[math.random(#k)]
fit(j[math.random(#j)])
end
task.wait(1)
end
end)
end



rest"UI_PANEL+HOME"

do
local aq=aj.Players
local ar=input(aq,"Search for player…",9,10,230,32,11)
local as=txt(aq,"",9,"sub",ap.IW-176,10,167,32,{TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center})
local at=scroller(aq,0,56,ap.IW,ap.IH-56)
at.AutomaticCanvasSize=Enum.AutomaticSize.None
new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},at)
new("UIPadding",{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,8)},at)
local au={}
local av={}
local aw
local ax,ay={},0


local az={"A-Z","Z-A","Nearest","Farthest"}
local function sortList(aA)
local aB=s.plSort
local aC,aD=aB=="Nearest"or aB=="Farthest",{}
if aC then
local aE=z.root()
for aF,aG in ipairs(aA)do
local aH=aG.Character and aG.Character:FindFirstChild"HumanoidRootPart"
aD[aG]=(aE and aH)and(aE.Position-aH.Position).Magnitude or math.huge
if aB=="Farthest"and aD[aG]~=math.huge then aD[aG]=-aD[aG]end
end
end
table.sort(aA,function(aE,aF)
local aG,aH=aE.DisplayName:lower(),aF.DisplayName:lower()
if aC and aD[aE]~=aD[aF]then return aD[aE]<aD[aF]end
if aB=="Z-A"then return aG>aH end
return aG<aH
end)
end

local function resort()
local aA={}
for aB,aC in pairs(av)do
local aD=aC.grp and aC.fr and l.Players:GetPlayerByUserId(aB)
if aD then aA[aC.grp]=aA[aC.grp]or{};table.insert(aA[aC.grp],aD)end
end
for aB,aC in pairs(aA)do
sortList(aC)
for aD,aE in ipairs(aC)do av[aE.UserId].fr.LayoutOrder=(ax[aB]or 0)+aD end
end
end
local aA
local aB=btn(aq,"Sort: "..tostring(s.plSort),246,10,104,32,nil,nil,function()aA.Visible=not aA.Visible end)
aA=fr(aq,246,44,104,#az*28+4,"ctrlOff",0,5,"edge",1,0.3)
aA.ZIndex,aA.Visible=20,false
for aC,aD in ipairs(az)do
btn(aA,aD,2,2+(aC-1)*28,100,26,nil,nil,function()
s.plSort,aA.Visible=aD,false
aB.Text="Sort: "..aD
save();aw()
end)
end


local aC={}
local function copyable(aD,aE,aF,aG,aH,aI,aJ,aK,aL,aM,aN)
local aO=txt(aD,aF,aK,aL,aG,aH,aI,aJ,mix({RichText=true,TextTruncate=Enum.TextTruncate.AtEnd},aM))
local aP=new("TextButton",{Text="",BackgroundTransparency=1,AutoButtonColor=false,Position=aO.Position,Size=aO.Size},aD)
local aQ
aP.MouseButton1Click:Connect(function()
local aR=os.clock()
if aC[aP]and aR-aC[aP]<0.3 then
aC[aP]=nil
if setclipboard then
pcall(setclipboard,aE)
z.notify("Copied "..aE)
else
if not aQ then
aQ=new("TextBox",{Text=aE,TextEditable=false,ClearTextOnFocus=false,BackgroundTransparency=1,BorderSizePixel=0,
Font=aa,TextSize=fs(aK),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
Position=aO.Position,Size=aO.Size,Visible=false},aD)
paint(aQ,"TextColor3",aL)
aQ.FocusLost:Connect(function()aQ.Visible=false;aO.Visible=true end)
end
aO.Visible,aQ.Visible=false,true
aQ:CaptureFocus()
aQ.SelectionStart,aQ.CursorPosition=1,#aE+1
end
else
aC[aP]=aR
if aN then task.delay(0.3,function()if aC[aP]==aR then aC[aP]=nil;aN()end end)end
end
end)
return aO
end
local function greyOut(aD,aE)
if not(aD and aD.Parent)then return end
aD.Active=not aE
aD.Text=aE and"Friends"or"Add Friend"
setFill(aD)
end


local aD,aE={},false
local function visible()return l.panelOpen and n.tab=="Players"end
local function later()
if aE then return end
aE=true
task.delay(0.15,function()
aE=false
if visible()then aw()end
end)
end
local function fetchFriends(aF)
for aG,aH in ipairs(l.Players:GetPlayers())do
local aI=aH.UserId
if aH~=A and not aD[aI]and(aF or au[aI]==nil)then
aD[aI]=true
task.spawn(function()
local aJ,aK=pcall(function()return A:IsFriendsWith(aI)end)
aD[aI]=nil
if not aJ then return end
local aL=aK==true
local aM=au[aI]or false
au[aI]=aL
local aN=av[aI]
if aN and aN.fb then greyOut(aN.fb,aL)end
if aM~=aL then later()end
end)
end
end
end
local function blockedSet()
local aF={}
pcall(function()
for aG,aH in ipairs(z.StarterGui:GetCore"GetBlockedUserIds")do aF[aH]=true end
end)
return aF
end


local aF
conn(l.UserInputService.InputChanged,function(aG)
if aF and(aG.UserInputType==Enum.UserInputType.MouseMovement or aG.UserInputType==Enum.UserInputType.Touch)then aF(aG.Position.X)end
end)
conn(l.UserInputService.InputEnded,function(aG)
if aG.UserInputType==Enum.UserInputType.MouseButton1 or aG.UserInputType==Enum.UserInputType.Touch then
aF=nil
if l.dragEnd then pcall(l.dragEnd);l.dragEnd=nil end
end
end)
local function slider(aG,aH,aI,aJ,aK)
local aL=l.sliderParts(aG,aH-10,aI-3,aJ+20,10)
local aM=txt(aG,"",9,"sub",aH+aJ+14,aI,38,18,{TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center})
local aN=0
local function show(aO)
aL.place(aO/2)
aM.Text=math.floor(aO*100+0.5).."%"
end
local function set(aO)
local aP=math.clamp((aO-aL.track.AbsolutePosition.X)/math.max(aL.track.AbsoluteSize.X,1),0,1)
local aQ=math.floor(aP*40+0.5)/20
if math.abs(aQ-1)<0.04 then aQ=1 end
show(aQ)
z.setVoiceVol(aK,aQ)
end
aL.hit.InputBegan:Connect(function(aO)
if aO.UserInputType==Enum.UserInputType.MouseButton1 or aO.UserInputType==Enum.UserInputType.Touch then
local aP=os.clock()
if aP-aN<0.35 then aN=0;aF=nil;show(1);z.setVoiceVol(aK,1);return end
aN=aP
aF=set
l.dragEnd=function()aL.held(false)end
aL.held(true)
set(aO.Position.X)
end
end)
aL.hit.MouseButton2Click:Connect(function()show(1);z.setVoiceVol(aK,1)end)
show(B.vcVol and B.vcVol[aK]or 1)
end

local aG,aH,aI,aJ=ap.IW-21,80,26,6
local aK=aG-12-(3*aH+2*aJ)
local aL={accounts="Accounts",listening="Listening",friends="Friends",players="Players",hidden="Blocked / Hidden"}
local function header(aM,aN,aO)
local aP=new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,LayoutOrder=aO},at)
fr(aP,2,5,3,11,"accent",0,2)
txt(aP,(aL[aM]):upper().."  ·  "..aN,8,"sub",12,0,400,20,{Font=ab,TextYAlignment=Enum.TextYAlignment.Center})
end

local function card(aM,aN,aO,aP,aQ)
local aR,aS=aM.UserId,aM==A
local aT=aS and 64 or 80
local aU=B.listen[aR]~=nil
local aV=fr(at,0,0,aG,aT,"row",0.85,8,"edge",1,0.55)
aV.Size,aV.LayoutOrder=UDim2.new(1,0,0,aT),aN
if aU then paint(aV:FindFirstChildOfClass"UIStroke","Color","accent");aV:FindFirstChildOfClass"UIStroke".Transparency=0.4 end
l.lit(aV)

local aW=new("ImageButton",{AutoButtonColor=false,Position=UDim2.fromOffset(12,(aT-52)/2),Size=UDim2.fromOffset(52,52),BorderSizePixel=0,BackgroundTransparency=0.9,
Image=thumb("AvatarHeadShot",aR,150),ImageTransparency=aO=="hidden"and 0.5 or 0},aV)
paint(aW,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(1,0)},aW)
local function open()n.openProfile(aM)end
aW.MouseButton1Click:Connect(open)
local aX=new("UIStroke",{Thickness=1.5,Transparency=0.55,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},aW)
paint(aX,"Color","accent")
local aY=aS and 14 or 12
local aZ=aO=="hidden"and(aP[aR]and"  ·  blocked"or"  ·  hidden")or(aO=="accounts"and"  ·  alt"or"")
copyable(aV,aM.DisplayName,hl(aM.DisplayName,aQ)..(aS and" (you)"or""),76,aY,aK-120,16,10,"text2",{Font=ab},open)
copyable(aV,aM.Name,hl("@"..aM.Name,aQ)..aZ,76,aY+18,aK-120,13,8,"sub",nil,open)

local a_={}
for K=1,4 do
local L=new("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.fromOffset(aK-30+(K-1)*5,aY+15),Size=UDim2.fromOffset(3,3),
BorderSizePixel=0,BackgroundTransparency=0.7},aV)
paint(L,"BackgroundColor3","accent")
new("UICorner",{CornerRadius=UDim.new(0,1)},L)
a_[K]=L
end
av[aR]={ring=aX,bars=a_,lvl=0,fr=aV,grp=aO}
if aS then
btn(aV,"Respawn",aK+2*(aH+aJ),(aT-aI)/2,aH,aI,"btnFill",ae,function()z.Run"reset"end)
return
end
local function cell(K,L,M,N,O)
return btn(aV,K,aK+L*(aH+aJ),M==1 and 12 or 44,aH,aI,N and"ctrlOn"or nil,N and ad or nil,O)
end
local K,L,M=B.viewing==aM,B.muted[aR]~=nil,z.isHidden(aR)
cell(K and"Unview"or"View",0,1,K,function()
z.Run(K and"unview"or("view "..aM.Name))
aw()
end)
cell("Go to",1,1,false,function()z.Run("goto "..aM.Name)end)
local N=cell("Add Friend",2,1,false,function()z.Run("friend "..aM.Name)end)
av[aR].fb=N
greyOut(N,au[aR])
cell(L and"Unmute"or"Mute",0,2,L,function()
z.setMuted(aR,not B.muted[aR])
aw()
end)
cell(aU and"Unlisten"or"Listen",1,2,aU,function()
local O=not B.listen[aR]
local P=O and B.muted[aR]~=nil
if P then z.setMuted(aR,false)end
local Q,R=z.setListen(aR,O)
if O and not Q then
if P then z.setMuted(aR,true)end
return z.notify(R,5)
end
aw(O)
end)
cell(M and"Unhide"or"Hide",2,2,M,function()
z.Run((z.isHidden(aR)and"unhide "or"hide ")..aM.Name)
aw()
end)
slider(aV,76,53,160,aR)
end


local function altRow(aM,aN)
local aO=fr(at,0,0,aG,56,"row",0.85,8,"edge",1,0.55)
aO.Size,aO.LayoutOrder=UDim2.new(1,0,0,56),aN
l.lit(aO)
local aP=new("ImageLabel",{Position=UDim2.fromOffset(12,6),Size=UDim2.fromOffset(44,44),BorderSizePixel=0,BackgroundTransparency=0.9,Image=thumb("AvatarHeadShot",aM.userId,150)},aO)
paint(aP,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(1,0)},aP)
txt(aO,(aM.displayName and aM.displayName~="")and aM.displayName or aM.name,10,"text2",68,10,220,16,{Font=ab})
txt(aO,"@"..aM.name.."  ·  other server",8,"sub",68,30,240,13)
btn(aO,"Join",aK+2*(aH+aJ),12,aH,aI,"primary",nil,function()
pcall(function()game:GetService"TeleportService":TeleportToPlaceInstance(aM.placeId,aM.jobId,A)end)
end)
end

function aw(aM)
l.plGen=(l.plGen or 0)+1
local aN,aO=l.plGen,{}
local aP=at.CanvasPosition
clear(at)
av={}
local aQ=ar.Text:lower()
local aR=blockedSet()
local aS={accounts={},listening={},friends={},players={},hidden={}}
local aT
for aU,aV in ipairs(l.Players:GetPlayers())do
if aQ==""or aV.Name:lower():find(aQ,1,true)or aV.DisplayName:lower():find(aQ,1,true)then
if aV==A then
aT=aV
else
local aW=aV.UserId
local aX=(B.alts and B.alts[aW])and"accounts"or B.listen[aW]and"listening"or((aR[aW]or z.isHidden(aW))and"hidden")or(au[aW]and"friends")or"players"
table.insert(aS[aX],aV)
end
end
end
for aU,aV in pairs(aS)do
sortList(aV)
end
local aU={}
do
local aV={}
for aW,aX in ipairs(l.Players:GetPlayers())do aV[aX.UserId]=true end
for aW,aX in pairs(B.alts or{})do
if not aV[aW]and(aQ==""or aX.name:lower():find(aQ,1,true)or(aX.displayName or""):lower():find(aQ,1,true))then aU[#aU+1]=aX end
end
table.sort(aU,function(aW,aX)return aW.name:lower()<aX.name:lower()end)
end
local aV,aW,aX=0,0,0
local function add(aY)aW=aW+(aX>0 and 6 or 0)+aY;aX=aX+1 end
if aT then aV=aV+1;add(64);local aY=aV;aO[#aO+1]=function()card(aT,aY,nil,aR,aQ)end end
for aY,aZ in ipairs{"accounts","listening","friends","players","hidden"}do
local a_=aS[aZ]
local K=aZ=="accounts"and aU or{}
if#a_+#K>0 then
aV=aV+1;add(20);header(aZ,#a_+#K,aV);ax[aZ]=aV
for L,M in ipairs(a_)do
aV=aV+1;add(80);local N=aV;aO[#aO+1]=function()card(M,N,aZ,aR,aQ)end
end
for L,M in ipairs(K)do
aV=aV+1;add(56);local N=aV;aO[#aO+1]=function()altRow(M,N)end
end
end
end
if aX==0 then
empty(at,"No players match.")
aW=56
end
at.CanvasSize=UDim2.fromOffset(0,aW+10)
at.CanvasPosition=aM==true and Vector2.zero or aP
n.busy("players",false)
if#aO>0 then
n.busy("players",#aO>8,"Players")
task.spawn(function()
for aY,aZ in ipairs(aO)do
if aN~=l.plGen or not l.alive then return end
pcall(aZ)
if aY%3==0 then task.wait()end
end
if aN==l.plGen then n.busy("players",false)end
end)
end
local aY=0
for aZ in pairs(B.listen)do aY=aY+1 end
as.Text=("%d players  ·  %d listening"):format(#l.Players:GetPlayers(),aY)
end


local aM,aN,aO={0.75,1,0.9,0.6},false,0
conn(z.RunService.Heartbeat,function(aP)
if not visible()then
if aN then aN=false;z.vcClear()end
return
end
aN=true
if(B.altsRev or 0)~=aO then aO=B.altsRev or 0;aw()end
ay=ay+aP
if(s.plSort=="Nearest"or s.plSort=="Farthest")and ay>=(tonumber(s.plPoll)or 1)then
ay=0
resort()
end
local aQ=os.clock()
for aR,aS in pairs(av)do
local aT=z.vcMeter(aR)
local aU=0
if aT then
local aV,aW=pcall(function()return aT.an.PeakLevel end)
if aV and aW then aU=math.clamp(math.sqrt(math.max(aW,0))*1.8,0,1)end
end
if aU<0.08 then aU=0 end
aS.lvl=aU>aS.lvl and aU or math.max(aU,aS.lvl-aP*2.2)
aS.ring.Thickness=1.5+aS.lvl*3.5
aS.ring.Transparency=0.55-aS.lvl*0.55
for aV,aW in ipairs(aS.bars)do
local aX=math.clamp(aS.lvl*aM[aV]*(1+0.25*math.sin(aQ*14+aV*1.7)),0,1)
aW.Size=UDim2.fromOffset(3,math.floor(3+11*aX))
aW.BackgroundTransparency=0.7-0.7*math.clamp(aS.lvl*1.5,0,1)
end
end
end)

n.plRender=function()if visible()then aw()end end
n.plSearch=function(aP)ar.Text=aP or""end
ar:GetPropertyChangedSignal"Text":Connect(function()aw()end)
al.Players=function()aA.Visible=false;fetchFriends(true);aw(true)end
am.Players=function()l.plGen=(l.plGen or 0)+1;n.busy("players",false);clear(at);av={};z.vcClear()end
conn(l.Players.PlayerAdded,function()if visible()then fetchFriends();aw()end end)
conn(l.Players.PlayerRemoving,function(aP)
if B.viewing==aP then z.Run"unview"end
task.defer(function()if visible()then aw()end end)
end)
end

do
local aq=aj.Servers
local ar=z.SRV
local as=input(aq,"Region (city, country or code)…",9,10,299,32,11)
as.Text=s.srvRegion or""

local at=txt(aq,"",9,"sub",ap.IW-216,46,207,26,{TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
local au=scroller(aq,0,80,ap.IW,ap.IH-80)
au.AutomaticCanvasSize=Enum.AutomaticSize.None
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},au)
new("UIPadding",{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,2),PaddingBottom=UDim.new(0,8)},au)
local function ago(av)local aw=math.floor((os.time()-av)/60);return aw<1 and"just now"or aw<60 and(aw.." min ago")or(math.floor(aw/60).." h ago")end
local av,aw,ax,ay,az={},false
local aA,aB,aC,aD,aE,aF=false,0,false
local aG
local function visible()return l.panelOpen and n.tab=="Servers"end
local function later()
if aw then return end
aw=true
task.delay(0.2,function()aw=false;if visible()then aG()end end)
end
function aG()
clear(au)
local aH=as.Text:lower():match"^%s*(.-)%s*$"
local aI={}
aB=0
for aJ,aK in ipairs(av)do
local aL=ar.region(aK.id)
if aL then aB=aB+1 end
if aH==""or(aL and ar.match(aK.id,aH))then aI[#aI+1]={s=aK,r=aL}end
end
local aJ,aK,aL=s.srvSort,s.srvDesc,os.time()
local function val(aM)
if aJ=="Players"then return aM.s.playing or 0 end
if aJ=="Region"then return aM.r and aM.r.label end
if aJ=="Age"then local aN=ar.byId[aM.s.id];return aN and aN.t and aL-aN.t end
return aM.s.ping
end
table.sort(aI,function(aM,aN)
local aO,aP=val(aM),val(aN)
if(aO==nil)~=(aP==nil)then return aO~=nil end
if aO~=aP then if aK then return aO>aP else return aO<aP end end
local aQ,aR=aM.s.ping or 9e9,aN.s.ping or 9e9
if aQ~=aR then return aQ<aR end
return aM.s.id<aN.s.id
end)
for aM,aN in ipairs(aI)do
local aO,aP=aN.s,aN.r
local aQ=fr(au,0,0,ap.IW-21,50,"row",0.85,8,"edge",1,0.55)
aQ.Size,aQ.LayoutOrder=UDim2.new(1,0,0,50),aM
l.lit(aQ)
local aR=ar.byId[aO.id]
txt(aQ,aP and(aP.label..(aR and aR.t and("  ·  scanned "..ago(aR.t))or""))or"Not scanned yet",10,aP and"text2"or"sub",14,7,330,16,{Font=ab})
txt(aQ,("%d/%d players  ·  %s  ·  %s"):format(aO.playing or 0,aO.maxPlayers or 0,aO.ping and("~"..math.floor(aO.ping*(s.mod.srvPingMult or 2)+0.5).." ms")or"ping ?",aO.fps and(math.floor(aO.fps+0.5).." fps")or"fps ?"),
8,"sub",14,26,330,13)
local aS=aO.id==game.JobId
local aT=ar.joining~=nil and ar.joining.id==aO.id
local aU=btn(aQ,aS and"Current"or(aT and"Cancel"or"Join"),ap.IW-21-12-82,12,82,26,(not aS)and(aT and"danger"or"primary")or nil,nil,function()
if ar.joining and ar.joining.id==aO.id then ar.cancelJoin()else ar.join(game.PlaceId,aO.id)end
end)
if aS then aU.Active=false;aU.TextTransparency=0.55 end
end
if#aI==0 then
empty(au,ax and("Server list failed: "..ax)or(#av==0 and(aA and"Loading servers..."or"No public servers found.")or"No scanned server matches. Press Scan regions."))
end
au.CanvasSize=UDim2.fromOffset(0,math.max(#aI,1)*54+10)
aE()
if ar.running()then aF()end
end

function aE()
local aH={}
if aA then aH[#aH+1]="refreshing list"end
if ar.running()then aH[#aH+1]="scanning regions "..((ar.okN or 0)+(ar.failN or 0))end
local aI=#aH>0 and(table.concat(aH," + ")..("."):rep(math.floor(os.clock()*2)%3+1).."  ·  ")or""
local aJ=0
for aK,aL in ipairs(av)do aJ=aJ+(aL.playing or 0)end
at.Text=aI..("%d servers (%d players)  ·  %d regions"):format(#av,aJ,aB)
if aD then aD.TextTransparency=aA and 0.55 or 0 end
end
function aF()
if aC then return end
aC=true
task.spawn(function()
n.busy("servers",true,"Servers")
while(aA or ar.running())and l.alive do n.busy("servers",true,"Servers");aE();task.wait(0.4)end
n.busy("servers",false)
aC=false
aE()
end)
end

local function refresh(aH)
if aA then return end
aA=true;aF()
task.spawn(function()
local aI={}
for aJ,aK in ipairs(av)do aI[aK.id]=true end
local aJ,aK,aL=pcall(ar.list,game.PlaceId,1)
if not aJ then aK,aL={},tostring(aK)end
aA=false
if#aK>0 then
av,ax=aK,nil
if aH then
local aM=0
for aN,aO in ipairs(aK)do if not aI[aO.id]then aM=aM+1 end end
z.notify(("Rescan: %d new server%s (%d total)"):format(aM,aM==1 and""or"s",#aK),4)
end
else
ax=aL
if aH then z.notify("Server list failed: "..tostring(aL),5)end
end
if visible()then aG()end
end)
end
local function startScan()
if#av==0 then return z.notify"No servers to scan yet"end
ay.Text="Stop"
local aH=ar.scan(game.PlaceId,av,function(aH)
if aH then later()else
ay.Text="Scan regions"
if ar.err then z.notify(ar.err,10)end
later()
end
end)
if aH then aF()else ay.Text="Scan regions"end
end
ay=btn(aq,"Scan regions",ap.IW-216,13,100,26,nil,nil,function()
if ar.running()then ar.stop=true;return end
startScan()
end)
aD=btn(aq,"Rescan",241,46,68,26,nil,nil,function()refresh(true)end)
btn(aq,"Join match",ap.IW-110,13,100,26,"primary",nil,function()
local aH=as.Text:lower():match"^%s*(.-)%s*$"
if aH==""then return z.notify"Type a region first (city, country or code)"end
z.Run("region "..aH)
end)
as:GetPropertyChangedSignal"Text":Connect(function()aG()end)
local aH={"Ping","Players","Region","Age"}
local aI
az=fr(aq,9,74,120,#aH*28+4,"ctrlOff",0,5,"edge",1,0.3)
az.ZIndex,az.Visible=20,false
for aJ,aK in ipairs(aH)do
btn(az,aK,2,2+(aJ-1)*28,116,26,nil,nil,function()
s.srvSort,az.Visible=aK,false
aI.Text="Sort: "..aK.."  v"
save();aG()
end)
end
aI=btn(aq,"Sort: "..tostring(s.srvSort).."  v",9,46,120,26,nil,nil,function()az.Visible=not az.Visible end)
btn(aq,s.srvDesc and"Descending"or"Ascending",135,46,100,26,nil,nil,function(aJ)
s.srvDesc=not s.srvDesc
aJ.Text=s.srvDesc and"Descending"or"Ascending"
save();aG()
end)
as.FocusLost:Connect(function()s.srvRegion=as.Text;save()end)
ar.onJoin=later
am.Servers=function()clear(au)end
al.Servers=function()
az.Visible=false
if not ar.shown then ar.shown=true;z.notify("Region cache: "..(ar.loaded or 0).." servers loaded from KLOSAD/servers.json",4)end
refresh();aG()
end
end


rest"PLAYERS+SERVERS"


do
local aq,ar=ap.IW,ap.IH
local as,at,au,av=16,180,212,44
local aw=aq-au-16
local ax={gen=0,open=false,friend={},price=z.AV.asset}
n.prof=ax
local ay={}
conn(l.Players.PlayerAdded,function(az)ay[az.UserId]=os.time()end)
local function prop(az,aA)local aB,aC=pcall(function()return az[aA]end);return aB and aC or nil end
local function comma(az)local aA=tostring(math.floor((tonumber(az)or 0)+0.5));return(aA:reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""))end
local function date(az,aA)local aB,aC=pcall(os.date,az,aA);return aB and type(aC)=="string"and aC or"?"end
local function blockedIds()
local az,aA=pcall(function()return z.StarterGui:GetCore"GetBlockedUserIds"end)
return az and type(aA)=="table"and aA or{}
end
local function copy(az,aA)
if not setclipboard then return z.notify("This executor cannot copy: "..az,6)end
pcall(setclipboard,az)
z.notify("Copied "..aA)
end
local function chip(az,aA,aB,aC)
local aD=new("TextLabel",{AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,20),BorderSizePixel=0,BackgroundTransparency=0.82,
Text=aA,Font=ab,TextSize=fs(8),LayoutOrder=aC},az)
paint(aD,"BackgroundColor3",aB)
paint(aD,"TextColor3",aB=="accent"and"accentText"or aB=="sub"and"text2"or aB)
new("UICorner",{CornerRadius=UDim.new(1,0)},aD)
new("UIPadding",{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9)},aD)
end


local az,aA,aB=aq+24,ar+56,44
local aC=new("CanvasGroup",{Name="Profile",Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=1,Visible=false,ZIndex=5},af)
local aD=new("Frame",{Name="ProfileWindow",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(az,aA),BorderSizePixel=0,Active=true},aC)
paint(aD,"BackgroundColor3","panel")
aD.BackgroundTransparency=1-s.opacity
new("UICorner",{CornerRadius=UDim.new(0,12)},aD)
local aE=new("UIStroke",{Thickness=1.5,Transparency=0.1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},aD)
paint(aE,"Color","accent")
local aF=new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(0.3,0.88),NumberSequenceKeypoint.new(0.7,0.88),NumberSequenceKeypoint.new(1,0)}},aE)
l.deco(aF)
ax.comet=l.TweenService:Create(aF,TweenInfo.new(7,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1),{Rotation=360})
n.profWin,n.profScale=aD,new("UIScale",{Scale=s.scale},aD)
l.spot(aD,az,aA,12,1,aD,function()return ax.open and not l.barOpen end)
fr(aD,14,0,az-28,2,"accent",0.7)
local aG=txt(aD,"",14,"text",22,9,200,26,{Font=ac,RichText=true,TextSize=21})
l.deco(new("UIGradient",{Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(165,165,178))},aG))
function ax.retitle()aG.Text='<font color="'..hex(l.accent)..'">&gt;</font>PROFILE'end
ax.retitle()
do
local aH=fr(aD,14,aB-1,az-28,1,"accent",0.8)
new("UIGradient",{Transparency=NumberSequence.new{NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(0.5,0),NumberSequenceKeypoint.new(1,1)}},aH)
l.deco(aH)
end
btn(aD,"×",az-46,8,34,28,"ghost",nil,function()n.closeProfile()end,13)

ax.pos=Vector2.new(0.5,0.5)
function ax.place(aH,aI)
local aJ=workspace.CurrentCamera.ViewportSize
local aK=UDim2.fromScale(ax.pos.X,ax.pos.Y+(aH or 0)/aJ.Y)
if aI then tw(aD,{Position=aK},0.3)else aD.Position=aK end
end
do
local aH=new("Frame",{Size=UDim2.fromOffset(az-50,aB-6),BackgroundTransparency=1},aD)
local aI,aJ,aK
aH.InputBegan:Connect(function(aL)
if aL.UserInputType==Enum.UserInputType.MouseButton1 or aL.UserInputType==Enum.UserInputType.Touch then aI,aJ,aK=true,aL.Position,ax.pos end
end)
conn(l.UserInputService.InputChanged,function(aL)
if aI and(aL.UserInputType==Enum.UserInputType.MouseMovement or aL.UserInputType==Enum.UserInputType.Touch)then
local aM=workspace.CurrentCamera.ViewportSize
local aN=aL.Position-aJ
ax.pos=Vector2.new(aK.X+aN.X/aM.X,aK.Y+aN.Y/aM.Y)
ax.place(0)
end
end)
conn(l.UserInputService.InputEnded,function(aL)
if aI and(aL.UserInputType==Enum.UserInputType.MouseButton1 or aL.UserInputType==Enum.UserInputType.Touch)then aI=false end
end)
end

ax.inner=fr(aD,12,aB,aq,ar,"glass",0.75,10,"edge",1,0.7)
ax.inner.ClipsDescendants=true

local aH=fr(aD,0,0,az,aA,"tabOff",0.45,9)
aH.ZIndex,aH.Active,aH.Visible=50,true,false
conn(l.RunService.Heartbeat,function()
local aI=ax.open==true and l.barOpen==true
if aH.Visible~=aI then aH.Visible=aI end
end)
function ax.show()
ax.retitle()
if not ax.placed then
ax.placed=true
ax.pos=Vector2.new(math.clamp(n.panelPos.X+0.04,0.2,0.8),math.clamp(n.panelPos.Y+0.03,0.2,0.8))
end
n.profScale.Scale=n.curScale()
l.profOpen=true
ax.place(18,false)
tw(aC,{GroupTransparency=0},0.16)
ax.place(0,true)
if s.anim~=0 then ax.comet:Play()end
n.syncMouse()
end
function ax.hideHook()
l.profOpen=false
pcall(function()ax.comet:Pause()end)
n.syncMouse()
end



local aI=new("CanvasGroup",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0},ax.inner)



local function build(aJ,aK)
clear(aI)
local aL,aM=aJ.UserId,aJ==A
local function live()return aK==ax.gen and ax.open and l.alive end
local function here()return aJ.Parent~=nil end
local aN={}


local aO=fr(aI,as,av,at,at,"row",0.85,ah.rPane)
new("ImageLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=thumb("Avatar",aL,420),ScaleType=Enum.ScaleType.Fit},aO)


local aP=new("ImageLabel",{Position=UDim2.fromOffset(au,av),Size=UDim2.fromOffset(52,52),BorderSizePixel=0,BackgroundTransparency=0.9,Image=thumb("AvatarHeadShot",aL,150)},aI)
paint(aP,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(1,0)},aP)
paint(new("UIStroke",{Thickness=1.5,Transparency=0.4},aP),"Color","accent")
txt(aI,aJ.DisplayName,15,"text",au+66,av+2,aw-66,24,{Font=ab,TextTruncate=Enum.TextTruncate.AtEnd})
txt(aI,"@"..aJ.Name,10,"sub",au+66,av+28,aw-66,16,{TextTruncate=Enum.TextTruncate.AtEnd})
local aQ=new("Frame",{Position=UDim2.fromOffset(au,av+62),Size=UDim2.fromOffset(aw,20),BackgroundTransparency=1},aI)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},aQ)
local aR=av+126
local aS=ar-aR-14
local aT,aU={},{}
local function showPane(aV)
for aW,aX in pairs(aT)do aX.Visible=aW==aV end
for aW,aX in pairs(aU)do setFill(aX,aW==aV and"ctrlOn"or"ctrlOff",ae)end
local aW=aN[aV]
if aW then aN[aV]=nil;task.spawn(aW)end
end
for aV,aW in ipairs{"Overview","Outfit","Friends"}do
aU[aW]=btn(aI,aW,au+(aV-1)*96,av+92,90,26,"ctrlOff",ae,function()showPane(aW)end)
aT[aW]=new("Frame",{Position=UDim2.fromOffset(au,aR),Size=UDim2.fromOffset(aw,aS),BackgroundTransparency=1,Visible=false},aI)
end


local aV,aW={},0
local function kv(aX,aY)
local aZ=aW*21
aW=aW+1
txt(aT.Overview,aX,9.5,"sub",0,aZ,128,21,{TextYAlignment=Enum.TextYAlignment.Center})
aV[aX]=txt(aT.Overview,aY,9.5,"text",128,aZ,aw-128,21,{TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
end
local aX=tonumber(prop(aJ,"AccountAge"))or 0
local aY=tonumber(prop(aJ,"FollowUserId"))or 0
local aZ=aY~=0 and l.Players:GetPlayerByUserId(aY)
local a_=ay[aL]
kv("User ID",tostring(aL))
kv("Account age",("%s days  ·  on Roblox since %s"):format(comma(aX),date("%b %Y",os.time()-aX*86400)))
kv("Membership",prop(aJ,"MembershipType")==Enum.MembershipType.Premium and"Premium"or"Standard")
kv("Verified badge",prop(aJ,"HasVerifiedBadge")and"Yes"or"No")
kv("Avatar value","checking...")
kv("Friends with you",aM and"-"or"checking...")
kv("Team","None")
kv("Distance","-")
kv("In this server",aM and"you"or a_ and("since "..date("%H:%M",a_))or"since before rOSAD started")
kv("Followed someone in",aY==0 and"No"or aZ and("@"..aZ.Name)or("user "..aY))
task.spawn(function()
local K,L=pcall(z.AV.value,aJ,true)
if not live()then return end
if not(K and L)then aV["Avatar value"].Text="unavailable (outfit not loaded)";return end
aV["Avatar value"].Text=("R$ %s  ·  %d of %d priced%s%s"):format(z.AV.comma(L.total),L.priced,L.n,(L.lim>0 and("  ·  %d limited at RAP"):format(L.lim)or"")..(L.other>0 and("  ·  %d off sale / no price"):format(L.other)or""),L.miss>0 and("  ·  %d unknown"):format(L.miss)or"")
end)
if not aM then
task.spawn(function()
local K,L=pcall(function()return A:IsFriendsWith(aL)end)
if K then ax.friend[aL]=L==true end
if live()then aV["Friends with you"].Text=K and(L and"Yes"or"No")or"unknown (Roblox did not answer)"end
end)
end


local K=txt(aT.Outfit,"Loading the outfit...",9.5,"sub",0,0,aw,20,{TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd})
local L=scroller(aT.Outfit,0,24,aw,aS-24)
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},L)
new("UIPadding",{PaddingRight=UDim.new(0,8)},L)
aN.Outfit=function()
local M,N={},{}
local function addId(O)O=tonumber(O);if O and O>0 and not N[O]then N[O]=true;M[#M+1]=O end end
local O,P=pcall(function()
local O=aJ.Character and aJ.Character:FindFirstChildOfClass"Humanoid"
if O then return O:GetAppliedDescription()end
return l.Players:GetHumanoidDescriptionFromUserId(aL)
end)
if O and P then
pcall(function()for Q,R in ipairs(P:GetAccessories(true))do addId(R.AssetId)end end)
for Q,R in ipairs{"Shirt","Pants","GraphicTShirt","Face","Head","Torso","LeftArm","RightArm","LeftLeg","RightLeg"}do pcall(function()addId(P[R])end)end
end
if#M==0 and o then
pcall(function()
local Q=o{Url=("https://avatar.roblox.com/v1/users/%d/currently-wearing"):format(aL),Method="GET"}
for R,S in ipairs(l.HttpService:JSONDecode(Q.Body).assetIds or{})do addId(S)end
end)
end
if not live()then return end
if#M==0 then K.Text="Outfit unavailable: Roblox returned no worn items";return end
local Q,R,S=0,0,0
local function sum()
K.Text=("Est. value R$ %s  ·  %d of %d items priced%s"):format(comma(Q),R,#M,S>0 and("  ·  %d off sale / limited"):format(S)or"")
end
for T,U in ipairs(M)do
local V=fr(L,0,0,aw-8,40,"row",0.85,ah.rCtrl)
V.Size,V.LayoutOrder=UDim2.new(1,0,0,40),T
new("ImageLabel",{Position=UDim2.fromOffset(6,4),Size=UDim2.fromOffset(32,32),BackgroundTransparency=1,Image=thumb("Asset",U,150)},V)
local W=txt(V,"Item "..U,9.5,"text",46,4,aw-160,16,{TextTruncate=Enum.TextTruncate.AtEnd})
local X=txt(V,"",8,"sub",46,21,aw-160,14,{TextTruncate=Enum.TextTruncate.AtEnd})
local Y=txt(V,"...",9.5,"text2",aw-110,0,94,40,{Font=ab,TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center})
task.spawn(function()
local Z=ax.price[U]
if not Z then
local _,a0=pcall(function()return l.MarketplaceService:GetProductInfo(U,Enum.InfoType.Asset)end)
if _ and type(a0)=="table"then Z=a0;ax.price[U]=a0 end
end
if not live()then return end
if not Z then Y.Text="unavailable";S=S+1;sum();return end
W.Text=tostring(Z.Name or("Item "..U))
X.Text=(type(Z.Creator)=="table"and Z.Creator.Name)and("by "..tostring(Z.Creator.Name))or""
local a0=Z.CollectiblesItemDetails
local _=Z.IsLimited or Z.IsLimitedUnique or(type(a0)=="table"and a0.IsLimited)
local a1=tonumber(Z.PriceInRobux)
if _ then
local a2=z.AV.limitedPrice(U,Z)
if a2 then Y.Text="R$ "..comma(a2).." (RAP)";Q=Q+a2;R=R+1
else Y.Text="Limited";S=S+1 end
elseif Z.IsForSale and a1 and a1>0 then Y.Text="R$ "..comma(a1);Q=Q+a1;R=R+1
elseif Z.IsForSale then Y.Text="Free";R=R+1
else Y.Text="Off sale";S=S+1 end
sum()
end)
end
sum()
end


local a0=txt(aT.Friends,"Loading friends...",9.5,"sub",0,0,aw,20,{TextYAlignment=Enum.TextYAlignment.Center})
local a1=scroller(aT.Friends,0,24,aw,aS-24)
new("UIGridLayout",{CellSize=UDim2.fromOffset(66,80),CellPadding=UDim2.fromOffset(6,6),SortOrder=Enum.SortOrder.LayoutOrder},a1)
aN.Friends=function()
local a2,M,N=pcall(function()
local a2=l.Players:GetFriendsAsync(aL)
return a2:GetCurrentPage(),not a2.IsFinished
end)
if not live()then return end
if not a2 or type(M)~="table"then a0.Text="Friends list unavailable (Roblox refused or it is private)";return end
local function inS(O)return l.Players:GetPlayerByUserId(O.Id)~=nil end
table.sort(M,function(O,P)
if inS(O)~=inS(P)then return inS(O)end
if(O.IsOnline==true)~=(P.IsOnline==true)then return O.IsOnline==true end
return tostring(O.Username):lower()<tostring(P.Username):lower()
end)
local O=0
for P,Q in ipairs(M)do
local R=inS(Q)
if R then O=O+1 end
local S=new("TextButton",{Text="",AutoButtonColor=false,BackgroundTransparency=1,LayoutOrder=P},a1)
local T=new("ImageLabel",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,4),Size=UDim2.fromOffset(46,46),BorderSizePixel=0,
BackgroundTransparency=0.9,Image=thumb("AvatarHeadShot",Q.Id,150),Interactable=false},S)
paint(T,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(1,0)},T)
paint(new("UIStroke",{Thickness=R and 2 or 1,Transparency=R and 0 or 0.7},T),"Color",R and"accent"or"edge")
local U=(Q.DisplayName and Q.DisplayName~="")and Q.DisplayName or Q.Username
txt(S,tostring(U),8,R and"accentText"or"text2",0,54,66,13,{TextXAlignment=Enum.TextXAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Interactable=false})
txt(S,R and"here"or(Q.IsOnline and"online"or""),7,"hint",0,67,66,11,{TextXAlignment=Enum.TextXAlignment.Center,Interactable=false})
S.MouseButton1Click:Connect(function()
local V=l.Players:GetPlayerByUserId(Q.Id)
if V then return n.openProfile(V)end
copy("https://www.roblox.com/users/"..Q.Id.."/profile","@"..tostring(Q.Username).."'s profile link (not in this server)")
end)
end
a0.Text=("%d%s friends  ·  %d in this server"):format(#M,N and"+"or"",O)
end


local function run(a2)z.Run(a2 .." "..aJ.Name)end
local a2={
{label=function()return B.viewing==aJ and"Unview"or"View"end,on=function()return B.viewing==aJ end,
run=function()if B.viewing==aJ then z.Run"unview"else run"view"end end},
{label=function()return B.listen[aL]and"Unlisten"or"Listen"end,on=function()return B.listen[aL]~=nil end,
run=function()
local a2=not B.listen[aL]
local M=a2 and B.muted[aL]~=nil
if M then z.setMuted(aL,false)end
local N,O=z.setListen(aL,a2)
if a2 and not N then
if M then z.setMuted(aL,true)end
z.notify(O,5)
end
end},

{label=function()return"Go to"end,run=function()run"goto"end},
{label=function()return ax.friend[aL]and"Friends"or"Add friend"end,en=function()return not ax.friend[aL]end,run=function()run"friend"end},
{label=function()return B.muted[aL]and"Unmute"or"Mute"end,on=function()return B.muted[aL]~=nil end,
run=function()z.setMuted(aL,not B.muted[aL])end},
{label=function()return z.isHidden(aL)and"Unhide"or"Hide"end,on=function()return z.isHidden(aL)end,
run=function()run(z.isHidden(aL)and"unhide"or"hide")end},
{label=function()return table.find(blockedIds(),aL)and"Unblock"or"Block"end,key="danger",
run=function()run(table.find(blockedIds(),aL)and"unblock"or"block")end},
{label=function()return"Inspect"end,any=true,
run=function()if not pcall(function()l.GuiService:InspectPlayerFromUserId(aL)end)then z.notify"This experience has the avatar inspect menu turned off"end end},
{label=function()return"Copy ID"end,any=true,run=function()copy(tostring(aL),"the user ID")end},
{label=function()return"Copy link"end,any=true,run=function()copy("https://www.roblox.com/users/"..aL.."/profile","the profile link")end},
}
for M,N in ipairs(a2)do
N.k=N.key
N.b=btn(aI,N.label(),as+((M-1)%2)*93,av+at+12+math.floor((M-1)/2)*32,87,26,N.key,nil,function()
N.run()
task.delay(0.1,function()
if live()then ax.refresh()end
if n.plRender then n.plRender()end
end)
end)
end


local M
function ax.refresh()
if not live()then return end
local N=here()and not aM
for O,P in ipairs(a2)do
P.b.Text=P.label()
local Q=(P.on and P.on())and"ctrlOn"or P.key
if Q~=P.k then P.k=Q;setFill(P.b,Q)end
local R=(P.any or N)and(not P.en or P.en())
if P.b.Active~=R then P.b.Active=R end
end
local O={}
local function add(P,Q)O[#O+1]={P,Q}end
if aM then add("You","accent")end
if B.alts and B.alts[aL]then add("Your alt","accent")end
if ax.friend[aL]then add("Friend","accent")end
if prop(aJ,"HasVerifiedBadge")then add("Verified","info")end
if prop(aJ,"MembershipType")==Enum.MembershipType.Premium then add("Premium","sub")end
if B.viewing==aJ then add("Viewing","accent")end
if B.listen[aL]then add("Listening","accent")end
if B.muted[aL]then add("Muted","danger")end
if z.isHidden(aL)then add("Hidden","danger")end
if table.find(blockedIds(),aL)then add("Blocked","danger")end
if not here()then add("Left the server","danger")end
local P=""
for Q,R in ipairs(O)do P=P..R[1].."|"end
if P~=M then
M=P
clear(aQ)
for Q,R in ipairs(O)do chip(aQ,R[1],R[2],Q)end
end
local Q,R=z.root(),aJ.Character and aJ.Character:FindFirstChild"HumanoidRootPart"
aV.Distance.Text=aM and"-"or not here()and"left the server"or(Q and R)and(comma((Q.Position-R.Position).Magnitude).." studs")or"not loaded (outside your streaming range)"
aV.Team.Text=aJ.Team and aJ.Team.Name or"None"
end
showPane"Overview"
ax.refresh()
task.spawn(function()
while live()do
task.wait(0.5)
ax.refresh()
end
end)
end

function n.openProfile(aJ)
if typeof(aJ)~="Instance"or not aJ.Parent then return z.notify"That player is not in this server"end

if ax.open and ax.p==aJ then return end
local aK=ax.open
ax.gen,ax.p,ax.open=ax.gen+1,aJ,true
build(aJ,ax.gen)
aC.Visible=true
if aK then
aI.GroupTransparency=1
tw(aI,{GroupTransparency=0},0.16)
else
aI.GroupTransparency=0
ax.show()
end
end
function n.closeProfile(aJ)
if not ax.open then return end
ax.open,ax.gen=false,ax.gen+1;ax.hideHook()
if aJ or s.anim==0 then aC.Visible,aC.GroupTransparency=false,1;return end
tw(aC,{GroupTransparency=1},0.16)
task.delay(dur(0.16)+0.02,function()if not ax.open then aC.Visible=false end end)
end

local aJ=n.selectTab
function n.selectTab(aK)

l.syncSwitches()
return aJ(aK)
end
end




n.lazy("Look and feel",function()
local aq=scroller(aj["Look and feel"],0,0,ap.IW,ap.IH)
aq.AutomaticCanvasSize,aq.CanvasSize=Enum.AutomaticSize.None,UDim2.fromOffset(0,462)
local ar=ap.IW-252
local function label(as,at,au)txt(aq,as,12,"text",at,au,ar-at-10,19)end
local function cols(as,at)local au={}for av=1,as do au[av]=ar+(av-1)*at end return au end
txt(aq,"Main",14,"text",21,14,214,23,{Font=ab})
label("Default theme",33,50)
seg(aq,48,{ar,ar+116},108,{{"Dark Mode","Dark"},{"Light Mode","Light"}},"theme")
label("UI Opacity",33,88)
seg(aq,86,cols(4,60),52,{{"20%",0.2},{"50%",0.5},{"80%",0.8},{"100%",1}},"opacity")
label("Glow Opacity",33,126)
seg(aq,124,cols(4,60),52,{{"0%",0},{"25%",25},{"50%",50},{"75%",75},{"100%",100}},"glow")
label("Accent Color",33,164)
local as=fr(aq,ar+37,162,30,25,"accent",0,3,"edge",1)
local at=input(aq,"#FFFF00",ar+74,162,104,25,9,"ctrlOff",ae,{Text=s.accent,TextXAlignment=Enum.TextXAlignment.Center})
local au
at.FocusLost:Connect(function()
local av=at.Text:upper()
if parseHex(av)then s.accent=av;save();n.apply()end
at.Text=s.accent
if au then au.load()end
end)

local function toColor(av,aw,ax)
local ay=(1-math.abs(2*ax-1))*aw
local az=ay*(1-math.abs((av/60)%2-1))
local aA,aB=ax-ay/2,math.floor(av/60)%6
local aC,aD,aE=ay,0,az
if aB==0 then aC,aD,aE=ay,az,0 elseif aB==1 then aC,aD,aE=az,ay,0 elseif aB==2 then aC,aD,aE=0,ay,az elseif aB==3 then aC,aD,aE=0,az,ay elseif aB==4 then aC,aD,aE=az,0,ay end
return Color3.new(aC+aA,aD+aA,aE+aA)
end
local function toHsl(av)
local aw,ax=math.max(av.R,av.G,av.B),math.min(av.R,av.G,av.B)
local ay,az=(aw+ax)/2,aw-ax
if az<1e-6 then return 0,0,ay end
local aA=az/(1-math.abs(2*ay-1))
local aB=aw==av.R and((av.G-av.B)/az)%6 or aw==av.G and(av.B-av.R)/az+2 or(av.R-av.G)/az+4
return aB*60,aA,ay
end
as.InputBegan:Connect(function(av)
if av.UserInputType~=Enum.UserInputType.MouseButton1 and av.UserInputType~=Enum.UserInputType.Touch then return end
if au then au.frame.Visible=not au.frame.Visible;if au.frame.Visible then au.load()end;return end
local aw,ax,ay=0,1,0.5
local az=fr(aq,ar-22,193,242,124,"panel",0,10,"edge",1,0.3)
az.ZIndex,az.Active=50,true
au={frame=az}
local aA,aB={},0
local function push(aC)
s.accent=hex(toColor(aw,ax,ay))
at.Text=s.accent
if aC then save();n.apply()elseif os.clock()-aB>0.06 then aB=os.clock();n.apply()end
end
local function paintTracks()
local aC={}
for aD=0,6 do aC[#aC+1]=ColorSequenceKeypoint.new(aD/6,toColor(aD*60,1,0.5))end
aA[1].grad.Color=ColorSequence.new(aC)
aA[2].grad.Color=ColorSequence.new(toColor(aw,0,ay),toColor(aw,1,ay))
aA[3].grad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,toColor(aw,ax,0)),ColorSequenceKeypoint.new(0.5,toColor(aw,ax,0.5)),ColorSequenceKeypoint.new(1,toColor(aw,ax,1))}
aA[1].set(aw/360);aA[2].set(ax);aA[3].set(ay)
end
for aC,aD in ipairs{{"H",360},{"S",100},{"L",100}}do
local aE=14+(aC-1)*36
txt(az,aD[1],10,"sub",14,aE-1,14,18,{Font=ab})
local aF=txt(az,"",9,"dim",190,aE-1,40,18,{TextXAlignment=Enum.TextXAlignment.Right})
local aG=new("Frame",{Position=UDim2.fromOffset(34,aE+2),Size=UDim2.fromOffset(150,12),BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1)},az)
new("UICorner",{CornerRadius=UDim.new(0,6)},aG)
local aH=new("UIGradient",{},aG)
local aI=new("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0,0,0.5,0),Size=UDim2.fromOffset(6,18),BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1)},aG)
new("UICorner",{CornerRadius=UDim.new(0,3)},aI)
new("UIStroke",{Thickness=1,Color=Color3.new(0,0,0),Transparency=0.4},aI)
local aJ={grad=aH}
function aJ.set(aK)aI.Position=UDim2.new(aK,0,0.5,0);aF.Text=aC==1 and(math.floor(aK*360+0.5).."°")or(math.floor(aK*100+0.5).."%")end
local aK=false
local function move(aL)
local aM=math.clamp((aL-aG.AbsolutePosition.X)/math.max(aG.AbsoluteSize.X,1),0,1)
if aC==1 then aw=aM*360 elseif aC==2 then ax=aM else ay=aM end
paintTracks();push(false)
end
aG.InputBegan:Connect(function(aL)
if aL.UserInputType==Enum.UserInputType.MouseButton1 or aL.UserInputType==Enum.UserInputType.Touch then aK=true;move(aL.Position.X)end
end)
conn(l.UserInputService.InputChanged,function(aL)
if aK and(aL.UserInputType==Enum.UserInputType.MouseMovement or aL.UserInputType==Enum.UserInputType.Touch)then move(aL.Position.X)end
end)
conn(l.UserInputService.InputEnded,function(aL)
if aK and(aL.UserInputType==Enum.UserInputType.MouseButton1 or aL.UserInputType==Enum.UserInputType.Touch)then aK=false;push(true)end
end)
aA[aC]=aJ
end
function au.load()aw,ax,ay=toHsl(parseHex(s.accent)or l.accent);paintTracks()end
au.load()

conn(l.UserInputService.InputBegan,function(aC)
if aC.UserInputType~=Enum.UserInputType.MouseButton1 or not az.Visible then return end
local aD=l.UserInputService:GetMouseLocation()
local function inside(aE)local aF,aG=aE.AbsolutePosition,aE.AbsoluteSize;return aD.X>=aF.X and aD.X<=aF.X+aG.X and aD.Y>=aF.Y and aD.Y<=aF.Y+aG.Y end
if not inside(az)and not inside(as)then az.Visible=false end
end)
end)
am["Look and feel"]=function()if au then au.frame.Visible=false end end
label("Animation Speed",33,202)
seg(aq,200,cols(4,60),52,{{"0.5x",0.5},{"1.0x",1},{"2.0x",2},{"none",0}},"anim")
label("UI Scaling",33,240)
seg(aq,238,cols(4,60),52,{{"70%",0.7},{"80%",0.8},{"90%",0.9},{"100%",1},{"110%",1.1},{"120%",1.2},{"130%",1.3},{"140%",1.4}},"scale")
fr(aq,17,272,ap.IW-34,1,"edge",0.6)
txt(aq,"Command Bar",14,"text",21,288,214,23,{Font=ab})
label("Max suggestion lines",33,326)
seg(aq,324,cols(3,80),72,{{"6",6},{"12",12},{"20",20}},"lines")
label("Blur Size",33,364)
seg(aq,362,cols(4,60),52,{{"0x",0},{"0.5x",0.5},{"1.0x",1},{"1.5x",1.5}},"blur")
label("Position",33,402)
seg(aq,400,cols(3,80),72,{{"Bottom","Bottom"},{"Center","Center"},{"Top","Top"}},"pos")
end)




n.lazy("Load scripts",function()
local aq=aj["Load scripts"]
local ar=input(aq,"Search scripts…",9,10,299,32,11)
local as=scroller(aq,0,56,ap.IW,ap.IH-56)
new("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},as)

local function ghInfo(at)
local au,av=at:match"github%.com/([^/]+)/([^/]+)/releases/latest/"
if au then return au.."/"..av.." @ latest release (unpinned)"end
local aw,ax,ay=at:match"github%.com/([^/]+)/([^/]+)/releases/download/([^/]+)/"
if aw then return aw.."/"..ax.." @ "..ay.." (release)"end
local az,aA,aB=at:match"raw%.githubusercontent%.com/([^/]+)/([^/]+)/([^/]+)/"
if not az then return at end
local aC=#aB>=40 and aB:match"^%x+$"~=nil
return az.."/"..aA.." @ "..(aC and aB:sub(1,7)or(aB.." (unpinned)"))
end

local function item(at,au,av,aw,ax,ay)
local az=fr(as,0,0,ap.IW,82,"row",0.9)
az.Size,az.LayoutOrder=UDim2.new(1,0,0,82),nx()
l.lit(az)
txt(az,(av and"🔒 "or"")..at,11,"text2",17,14,ap.IW-150,18,{Font=ab,TextTruncate=Enum.TextTruncate.AtEnd})
txt(az,au,8,"sub",22,38,ap.IW-150,28,{TextWrapped=true,TextTruncate=Enum.TextTruncate.AtEnd})
return btn(az,l.launched[ax]and"Relaunch"or aw,ap.IW-114,29,96,25,"btnFill",ae,function(aA)
if aA.Text=="Loading..."then return end
aA.Text="Loading..."
task.spawn(function()
local aB,aC=pcall(ay)
if not aB then z.notify(at..": "..tostring(aC),6)end
l.launched[ax]=aB or l.launched[ax]
aA.Text=l.launched[ax]and"Relaunch"or aw
end)
end)
end

local function render()
clear(as)
local at=ar.Text:lower()
local function show(au)return at==""or au:lower():find(at,1,true)end

for au,av in ipairs(g)do
local aw=(av.src:gsub("%-%-[^\n]*","")):match"%S"
if aw and show(av.name)then
item(av.name,av.desc,true,"Execute","b:"..av.name,function()
local ax=z.toolKey[av.name]
if ax then z.openTool(ax)else z.runSource(av.src,av.name)end
end)
end
end
if p and q then
pcall(makefolder,b);pcall(makefolder,b.."/scripts")
local au,av=pcall(listfiles,b.."/scripts")
local aw={}
for ax,ay in ipairs(au and av or{})do
local az=ay:match"([^/\\]+)$"
if az and(az:sub(-4)==".lua"or az:sub(-4)==".txt")then aw[#aw+1]={name=az,path=ay}end
end
table.sort(aw,function(ax,ay)return ax.name:lower()<ay.name:lower()end)
for ax,ay in ipairs(aw)do
if show(ay.name)then item(ay.name,"Local file: "..b.."/scripts",false,"Execute","l:"..ay.path,function()z.runSource(readfile(ay.path),ay.name)end)end
end
else
empty(as,"File access isn't available in this executor.")
end
for au,av in ipairs(h)do
if show(av.name)then
item(av.name,(av.desc and av.desc~=""and(av.desc.."  |  ")or"")..ghInfo(av.url),false,"Execute","g:"..av.url,function()
local aw=z.toolKey[av.name]
if aw then return z.openTool(aw)end
local ax,ay=z.fetch(av.url)
if ax then z.runSource(ax,av.name)else z.notify(av.name..": download failed ("..tostring(ay)..")")end
end)
end
end
end
ar:GetPropertyChangedSignal"Text":Connect(render)
al["Load scripts"]=render
am["Load scripts"]=function()clear(as)end
end)




n.lazy("Commands",function()
local aq=aj.Commands
local ar=input(aq,"Search commands, or what they do…",9,10,299,32,11)
local as=scroller(aq,0,56,ap.IW,ap.IH-56)
new("UIListLayout",{Padding=UDim.new(0,0),SortOrder=Enum.SortOrder.LayoutOrder},as)
local at={panel=1,cmds=1,ui=1,exit=1,reload=1,bind=1,unbind=1,alias=1,prefix=1,selftest=1,kill=1,["break"]=1,loop=1,unloop=1}
local function render()
clear(as)
local au=n.matches(ar.Text)
local av=0
for aw,ax in ipairs(au)do
av=av+1
local ay=fr(as,0,0,ap.IW,72,"row",0.9)
ay.Size,ay.LayoutOrder=UDim2.new(1,0,0,72),av
l.lit(ay)
local az={}
for aA,aB in ipairs(ax.names)do az[#az+1]=aB end
local aA=table.concat(az," / ")
txt(ay,aA,11,"text2",17,9,ap.IW-190,18,{Font=ab,TextTruncate=Enum.TextTruncate.AtEnd})
if ax.args~=""then txt(ay,ax.args,9,"dim",17,9,ap.IW-44,18,{TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center})end
txt(ay,ax.desc~=""and ax.desc or"-",8,"sub",17,31,ap.IW-44,22,{TextWrapped=true,TextTruncate=Enum.TextTruncate.AtEnd})
txt(ay,at[ax.canon]and"modifier: none"or("modifier: loop^"..ax.canon),8,"dim",17,55,ap.IW-44,12)
end
if av==0 then empty(as,"No command matches that.")end
end
ar:GetPropertyChangedSignal"Text":Connect(render)
al.Commands=render
am.Commands=function()clear(as)end
end)




local function flow(aq)
local ar=scroller(aj[aq],0,0,ap.IW,ap.IH)
new("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},ar)
new("UIPadding",{PaddingLeft=UDim.new(0,24),PaddingRight=UDim.new(0,24),PaddingTop=UDim.new(0,16),PaddingBottom=UDim.new(0,16)},ar)
return ar
end
local function fhdr(aq,ar)
n.tick()
local as=txt(aq,ar,14,"text",0,0,400,23,{LayoutOrder=nx(),Font=ab})
fr(as,-10,4,3,15,"accent",0,2)
return as
end

local function frow(aq,ar,as)
n.tick()
local at=new("Frame",{Size=UDim2.new(1,0,0,23),BackgroundTransparency=1,LayoutOrder=nx()},aq)
txt(at,ar,12,"text",12,2,math.max(60,ap.IW-72-as),19,{TextTruncate=Enum.TextTruncate.AtEnd})
return new("Frame",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,0,0),Size=UDim2.fromOffset(as,23),BackgroundTransparency=1},at)
end




n.lazy("Autostart",function()
local aq=flow"Autostart"
fhdr(aq,"Autostart")
seg(frow(aq,"Start these when rOSAD runs",102),0,{0,55},47,{{"On",true},{"Off",false}},"onExec",function()end,s.autostart)
local ar=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nx()},aq)
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},ar)
local as={builtin="Built-in",github="GitHub",["local"]="Local file",url="Link",cmd="Command"}

local at={{"Anti ear rape","antiearrape"},{"Auto rejoin on VC ban","arvc on"},{"Anti fling","antifling"},{"Anti sit","antisit"},
{"Anti void","antivoid"},{"Anti AFK","antiafk"},{"Anti teleport","antiteleport"},{"Anti knockback","antiknockback"},
{"Anti spam","antispam"},{"Anti freeze","antifreeze"}}
local au

local function add(av)
if av.kind=="cmd"and z.leaves(av.ref)then return z.notify"Leave / rejoin / hop commands can't be added to autostart"end
s.autostart.items[#s.autostart.items+1]={name=av.name,kind=av.kind,ref=av.ref,respawn=false}
save();au()
end
local function has(av,aw)
for ax,ay in ipairs(s.autostart.items)do
if ay.kind==av and ay.ref==aw then return true end
end
end
local function label(av)txt(ar,av,11,"sub",0,0,400,20,{LayoutOrder=nx()})end
local function card(av)
local aw=fr(ar,0,0,490,av,"row",0.9,4)
aw.Size,aw.LayoutOrder=UDim2.new(1,0,0,av),nx()
return aw
end

au=function()
clear(ar)
local av=s.autostart.items
label("Your autostart list ("..#av..")")
if#av==0 then txt(ar,"Nothing yet. Add a command or a script below.",10,"dim",0,0,400,20,{LayoutOrder=nx()})end
for aw,ax in ipairs(av)do
local ay=card(48)
txt(ay,ax.name,11,"text2",12,6,270,18,{Font=ab,TextTruncate=Enum.TextTruncate.AtEnd})
txt(ay,(as[ax.kind]or ax.kind)..((ax.kind=="url"or ax.kind=="cmd")and(": "..ax.ref)or""),8,"sub",12,27,270,14,{TextTruncate=Enum.TextTruncate.AtEnd})
local az=btn(ay,ax.respawn and"After reset: On"or"After reset: Off",ap.IW-238,12,100,23,"ctrlOff",ae,function(az)
ax.respawn=not ax.respawn
save()
az.Text=ax.respawn and"After reset: On"or"After reset: Off"
setFill(az,ax.respawn and"ctrlOn"or"ctrlOff",ax.respawn and ad or ae)
end)
if ax.respawn then setFill(az,"ctrlOn",ad)end
btn(ay,"Remove",ap.IW-132,12,76,23,"danger",nil,function()
table.remove(s.autostart.items,aw)
save();au()
end)
end

label"Add a command"
local aw=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nx()},ar)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Wraps=true,Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},aw)
for ax,ay in ipairs(at)do
if not has("cmd",ay[2])then
btn(aw,ay[1],0,0,#ay[1]*7+22,23,"btnFill",ae,function()add{name=ay[1],kind="cmd",ref=ay[2]}end).LayoutOrder=nx()
end
end
local ax=new("Frame",{Size=UDim2.new(1,0,0,23),BackgroundTransparency=1,LayoutOrder=nx()},ar)
local ay=input(ax,"any command, e.g. speed 30",0,0,0,23,9,"ctrlOff",ae)
ay.Parent.Size=UDim2.new(1,-112,0,23)
local az=btn(ax,"Add command",0,0,104,23,"primary",nil,function()
local az=((ay.Text:gsub("^%s*;","")):match"^%s*(.-)%s*$")
local aA=az:match"^(%S+)"
local aB=aA and z.Aliases[aA:lower()]
if not aB then return z.notify("Unknown command: "..tostring(aA or""))end
if aB=="arjvc"and az==aA then az=az.." on"end
if has("cmd",az)then return z.notify"Already in the list"end
add{name=";"..az,kind="cmd",ref=az}
end)
az.AnchorPoint=Vector2.new(1,0);az.Position=UDim2.new(1,0,0,0)

label"Add a script"
local aA=0
for aB,aC in ipairs(g)do
local aD=(aC.src:gsub("%-%-[^\n]*","")):match"%S"
if aD and not has("builtin",aC.name)then
aA=aA+1
local aE=card(34)
txt(aE,aC.name,10,"text2",12,8,380,18,{TextTruncate=Enum.TextTruncate.AtEnd})
btn(aE,"Add",ap.IW-138,5,82,23,"btnFill",ae,function()add{name=aC.name,kind="builtin",ref=aC.name}end)
end
end
if p and q then
local aB,aC=pcall(listfiles,b.."/scripts")
for aD,aE in ipairs(aB and aC or{})do
local aF=aE:match"([^/\\]+)$"
if aF and(aF:sub(-4)==".lua"or aF:sub(-4)==".txt")and not has("local",aE)then
aA=aA+1
local aG=card(34)
txt(aG,aF.."  (local file)",10,"text2",12,8,380,18,{TextTruncate=Enum.TextTruncate.AtEnd})
btn(aG,"Add",ap.IW-138,5,82,23,"btnFill",ae,function()add{name=aF,kind="local",ref=aE}end)
end
end
end
for aB,aC in ipairs(h)do
if not has("github",aC.name)then
aA=aA+1
local aD=card(34)
txt(aD,aC.name.."  (GitHub)",10,"text2",12,8,380,18,{TextTruncate=Enum.TextTruncate.AtEnd})
btn(aD,"Add",ap.IW-138,5,82,23,"btnFill",ae,function()add{name=aC.name,kind="github",ref=aC.name}end)
end
end
if aA==0 then txt(ar,"Everything available is already added.",10,"dim",0,0,400,20,{LayoutOrder=nx()})end

label"Or add by link"
local aB=new("Frame",{Size=UDim2.new(1,0,0,23),BackgroundTransparency=1,LayoutOrder=nx()},ar)
local aC=input(aB,"https://raw.githubusercontent.com/...",0,0,0,23,9,"ctrlOff",ae)
aC.Parent.Size=UDim2.new(1,-90,0,23)
local aD=btn(aB,"Add link",0,0,82,23,"primary",nil,function()
local aD=aC.Text:match"^%s*(.-)%s*$"
if not aD:match"^https?://"then return z.notify"That doesn't look like a link"end
add{name=aD:match"([^/]+)$"or aD,kind="url",ref=aD}
end)
aD.AnchorPoint=Vector2.new(1,0);aD.Position=UDim2.new(1,0,0,0)
end
al.Autostart=au
am.Autostart=function()clear(ar)end
end)



n.lazy("Keybinds",function()
local aq=flow"Keybinds"

local function keyTile(ar,as,at,au)
local av=fr(ar,as,0,math.floor((ap.IW-56)/2),54,"row",0.9,5,"edge",1,0.6)
txt(av,at,9,"dim",12,8,200,12,{Font=ab})
txt(av,"click, then press a key",9,"hint",130,28,106,14)
return btn(av,"",12,24,110,23,"ctrlOff",ae,function(aw)
if l.capBtn and l.capBtn~=aw and l.capBtn.Parent then setFill(l.capBtn,"ctrlOff",ae)end
l.capBtn=aw
aw.Text="press a key..."
setFill(aw,"ctrlOn",ad)
l.capture=function(ax)
setFill(aw,"ctrlOff",ae)
if ax~=Enum.KeyCode.Escape then s[au]=ax.Name;save()end
n.apply()
end
end,10)
end
fhdr(aq,"Hotkeys")
local ar=new("Frame",{Size=UDim2.new(1,0,0,54),BackgroundTransparency=1,LayoutOrder=nx()},aq)
local as,at=keyTile(ar,0,"COMMAND BAR","barKey"),keyTile(ar,math.floor((ap.IW-56)/2)+8,"PANEL","panelKey")

local function expName(au,av)
local aw=string.format("%d",au)
if au==game.GameId then return av(s.exp[aw]or game.Name)end
if s.exp[aw]then return av(s.exp[aw])end
task.spawn(function()
local ax=z.fetch("https://games.roblox.com/v1/games?universeIds="..aw)
local ay,az=pcall(function()return l.HttpService:JSONDecode(ax).data[1].name end)
if ay and type(az)=="string"and az~=""then
s.exp[aw]=az;save();av(az)
else
av(nil,ax==nil)
end
end)
end
fhdr(aq,"Keybind tabs")
local au=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nx()},aq)
new("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder},au)
local av


local function card(aw)
local ax=fr(aw,0,0,0,0,"row",0.9,5,"edge",1,0.7)
ax.Size,ax.AutomaticSize,ax.LayoutOrder=UDim2.new(1,0,0,0),Enum.AutomaticSize.Y,nx()
new("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},ax)
new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7)},ax)
return ax
end
local function line(aw)
return new("Frame",{Size=UDim2.new(1,0,0,23),BackgroundTransparency=1,LayoutOrder=nx()},aw)
end
local function rbtn(aw,ax,ay,az,aA)
local aB=btn(aw,ax,0,0,az,23,nil,nil,aA,10)
aB.AnchorPoint,aB.Position=Vector2.new(1,0),UDim2.new(1,-ay,0,0)
return aB
end
local aw=Enum.TextYAlignment.Center

local function renameRow(ax,ay)
local az=frow(au,"Tab name",180)
local aA=input(az,"tab name",0,0,180,23,9,"ctrlOff",ae,{Text=ax,TextXAlignment=Enum.TextXAlignment.Center})
aA.FocusLost:Connect(function()
if not aA.Parent then return end
local aB=aA.Text:match"^%s*(.-)%s*$":sub(1,20)
if aB~=""and aB~=ax then ay(aB);save();n.refreshKeys()else aA.Text=ax end
end)
end

function n.refreshKeys()
as.Text,at.Text="[ "..keyStr(s.barKey).." ]","[ "..keyStr(s.panelKey).." ]"
clear(au)
av=nil
local ax=z.kbTab()
if s.kbActive~="none"and s.kbActive~="default"and not ax then s.kbActive="default"end

local ay=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nx()},au)
new("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Wraps=true,Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder},ay)
local function tabBtn(az,aA)
local aB=s.kbActive==az
local aC=btn(ay,aA,0,0,math.max(44,#aA*7+20),23,aB and"ctrlOn"or"ctrlOff",aB and ad or ae,function()
s.kbActive=az;save();n.refreshKeys()
end)
aC.LayoutOrder=nx()
end
tabBtn("none","No Keybinds");tabBtn("default",s.kbDefName)
for az,aA in ipairs(s.kbTabs)do tabBtn(aA.id,aA.name)end
btn(ay,"+ New tab",0,0,76,23,nil,nil,function()
local az=1
local function taken()for aA,aB in ipairs(s.kbTabs)do if aB.name=="Tab "..az then return true end end end
while taken()do az=az+1 end
local aA={id=l.HttpService:GenerateGUID(false),name="Tab "..az,binds={},es=false}
s.kbTabs[#s.kbTabs+1]=aA
s.kbActive=aA.id;save();n.refreshKeys()
end,10).LayoutOrder=nx()

if s.kbActive=="none"then
txt(au,"Keybinds are off. Pick Default or a tab to use your binds.",10,"sub",0,0,440,22,{LayoutOrder=nx()})
return
end
if s.kbActive=="default"then
renameRow(s.kbDefName,function(az)s.kbDefName=az end)
txt(au,"Default tab: its binds work in every experience.",9,"dim",0,0,440,14,{LayoutOrder=nx()})
end
if ax then
renameRow(ax.name,function(az)ax.name=az end)
seg(frow(au,"Experience specific",102),0,{0,55},47,{{"On",true},{"Off",false}},"es",function()n.refreshKeys()end,ax)
if ax.es then
local az=frow(au,"Experience ID",250)
local aA=input(az,"experience id",0,0,140,23,9,"ctrlOff",ae,{Text=ax.exp and string.format("%d",ax.exp)or"",TextXAlignment=Enum.TextXAlignment.Center})
aA.FocusLost:Connect(function()
if not aA.Parent then return end
ax.exp=tonumber(aA.Text);save();n.refreshKeys()
end)
btn(az,"Use current",146,0,104,23,"btnFill",ae,function()ax.exp=game.GameId;save();n.refreshKeys()end)
local aB=txt(au,ax.exp and"Looking up experience..."or"Type an experience ID to see which game it is.",10,"sub",0,0,440,16,{LayoutOrder=nx(),TextTruncate=Enum.TextTruncate.AtEnd})
if ax.exp then
expName(ax.exp,function(aC,aD)
if not aB.Parent then return end
aB.Text=aC and("Experience: "..aC)or(aD and"Couldn't look the experience up (no connection)"or"No experience found with that ID")
end)
end
if ax.exp~=game.GameId then
txt(au,(ax.exp and"Inactive here: this tab only works in the experience above."or"Inactive here: no experience ID set."),9,"dim",0,0,440,16,{LayoutOrder=nx()})
end
end
btn(frow(au,"Delete this tab",76),"Delete",0,0,76,23,"danger",nil,function()
for az,aA in ipairs(s.kbTabs)do
if aA==ax then table.remove(s.kbTabs,az);break end
end
s.kbActive="default";save();n.refreshKeys()
end)
end

local az=z.bindTable()
local aA={}
for aB in pairs(az)do aA[#aA+1]=aB end
table.sort(aA)


local aB=card(au)
local aC=line(aB)
txt(aC,"Add a bind",11,"text2",0,0,80,23,{Font=ab,TextYAlignment=aw})
txt(aC,"click the key box, press a key, type a command",9,"dim",86,0,360,23,{TextYAlignment=aw})
local aD=line(aB)
btn(aD,"set key",0,0,96,23,"ctrlOff",ae,function(aE)
aE.Text="press a key..."
setFill(aE,"ctrlOn",ad)
local function cap(aF,aG)
if aF~=Enum.KeyCode.Escape then
if z.MODS[aF.Name]then l.capture=cap;return end
av=aG
end
aE.Text=av and keyStr(av)or"set key"
setFill(aE,av and"ctrlOn"or"ctrlOff",av and ad or ae)
end
l.capture=cap
end,10)
local aE=input(aD,"command, e.g. fly 80",102,0,0,23,9,"ctrlOff",ae)
aE.Parent.Size=UDim2.new(1,-160,1,0)
local function go()
if av and aE.Text:match"%S"then z.addBind(av,aE.Text)
else z.notify"Pick a key and type a command first"end
end
aE.FocusLost:Connect(function(aF)if aF then go()end end)
rbtn(aD,"+ Add",0,50,go)

fhdr(au,"Your binds ("..#aA..")")
if#aA==0 then txt(au,"Nothing here yet. Set a key above, type a command, hit Add.",10,"sub",0,0,440,22,{LayoutOrder=nx()})end
for aF,aG in ipairs(aA)do
local aH=z.bindList(aG)
local aI=#aH>1
local aJ=card(au)
local aK=line(aJ)
local aL=math.max(34,#keyStr(aG)*8+16)
btn(aK,keyStr(aG),0,0,aL,23,"ctrlOff",ae,function(aM)
setFill(aM,"ctrlOn",ad)
aM.Text="..."
local function cap(aN,aO)
if aN~=Enum.KeyCode.Escape then
if z.MODS[aN.Name]then l.capture=cap;return end
local aP=z.normKey(aO)
if aP and aP~=aG then
local aQ=z.bindList(aP)
for aR,aS in ipairs(z.bindList(aG))do aQ[#aQ+1]=aS end
z.storeBinds(aG,{})
return z.storeBinds(aP,aQ)
end
end
aM.Text=keyStr(aG)
setFill(aM,"ctrlOff",ae)
end
l.capture=cap
end,11)
txt(aK,(aI and#aH.." commands, one per press · "or"").."click to edit",9,"dim",aL+8,0,300,23,{TextYAlignment=aw})
rbtn(aK,"Remove",0,62,function()z.setBind(aG,nil)end)
for aM,aN in ipairs(aH)do
local aO=line(aJ)
if aI then txt(aO,tostring(aM),9,"dim",0,0,14,23,{TextYAlignment=aw})end
local aP=aI and 20 or 0
local aQ=input(aO,"command",aP,0,0,23,11,"inner",0.35,{Font=ac,Text=aN})
aQ.Parent.Size=UDim2.new(1,-(aP+(aI and 80 or 0)),1,0)
aQ.FocusLost:Connect(function()
if not aQ.Parent then return end
local aR=aQ.Text:match"^%s*(.-)%s*$"
if aR==""or aR==aN then aQ.Text=aN;return end
local aS=z.bindList(aG)
aS[aM]=aR
z.storeBinds(aG,aS)
end)
if aI then
rbtn(aO,"×",0,22,function()z.editBind(aG,aM,0)end)
if aM<#aH then rbtn(aO,"↓",26,22,function()z.editBind(aG,aM,1)end)end
if aM>1 then rbtn(aO,"↑",52,22,function()z.editBind(aG,aM,-1)end)end
end
end
local aM=line(aJ)
local aN=input(aM,aI and"+ add another command"or"+ add a 2nd command (they cycle on each press)",0,0,0,23,9,"ctrlOff",ae)
aN.Parent.Size=UDim2.new(1,-58,1,0)
local function go2()if aN.Text:match"%S"then z.addBind(aG,aN.Text)end end
aN.FocusLost:Connect(function(aO)if aO then go2()end end)
rbtn(aM,"+ Add",0,50,go2)
end
end
al.Keybinds=n.refreshKeys
am.Keybinds=function()
clear(au);av=nil
l.capture=nil
setFill(as,"ctrlOff",ae);setFill(at,"ctrlOff",ae)
end
end)




n.lazy("Module Cfg",function()
local aq=flow"Module Cfg"

local ar,as={}
local at,au=fhdr,frow
local function fhdr(av,aw)
local ax=at(av,aw)
as={key=aw:lower(),objs={ax}}
ar[#ar+1]=as
return ax
end
local function frow(av,aw,ax)
local ay=au(av,aw,ax)
if as then as.objs[#as.objs+1]=ay.Parent;as.key=as.key.." "..aw:lower()end
return ay
end
local av=new("Frame",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,LayoutOrder=nx()},aq)
local aw=input(av,"Search settings…",0,0,0,28,11)
aw.Parent.Size=UDim2.new(1,0,1,0)
aw:GetPropertyChangedSignal"Text":Connect(function()
local ax={}
for ay in aw.Text:lower():gmatch"%S+"do ax[#ax+1]=ay end
for ay,az in ipairs(ar)do
local aA=true
for aB,aC in ipairs(ax)do
if not az.key:find(aC,1,true)then aA=false;break end
end
for aB,aC in ipairs(az.objs)do aC.Visible=aA end
end
aq.CanvasPosition=Vector2.zero
end)
local ax=s.mod
local function numRow(ay,az)
local aA=frow(aq,ay,96)
local aB=input(aA,"",0,0,96,23,9,"ctrlOff",ae,{Text=tostring(ax[az]),TextXAlignment=Enum.TextXAlignment.Center})
aB.FocusLost:Connect(function()
local aC=tonumber(aB.Text)
if aC then ax[az]=aC;save();if z.onMod then z.onMod(az)end end
aB.Text=tostring(ax[az])
end)
end
local function strRow(ay,az)
local aA=frow(aq,ay,180)
local aB=input(aA,"",0,0,180,23,9,"ctrlOff",ae,{Text=tostring(ax[az]),TextXAlignment=Enum.TextXAlignment.Center})
aB.FocusLost:Connect(function()
if aB.Text:match"%S"and aB.Text~=ax[az]then ax[az]=aB.Text;save();z.reloadSpoofer()end
aB.Text=tostring(ax[az])
end)
end
local function togRow(ay,az)
seg(frow(aq,ay,102),0,{0,55},47,{{"On",true},{"Off",false}},az,function()if z.onMod then z.onMod(az)end end,ax)
end
local function optRow(ay,az,aA,aB)
local aC={}
for aD=1,#aA do aC[aD]=(aD-1)*(aB+8)end
seg(frow(aq,ay,#aA*(aB+8)-8),0,aC,aB,aA,az,function()if z.onMod then z.onMod(az)end end,ax)
end

local function hexRow(ay,az)
local aA=frow(aq,ay,96)
local aB=input(aA,"",0,0,96,23,9,"ctrlOff",ae,{Text=tostring(ax[az]),TextXAlignment=Enum.TextXAlignment.Center})
aB.FocusLost:Connect(function()
local aC=aB.Text:match"^%s*(.-)%s*$"
if not aC:match"^#"then aC="#"..aC end
if parseHex(aC)then ax[az]=aC:upper();save();if z.onMod then z.onMod(az)end end
aB.Text=tostring(ax[az])
end)
end

fhdr(aq,"Speed and fly")
numRow("Fly: default speed","flyDef");numRow("Fly: multiplier","flyMult")
numRow("Speed: default","speedDef");numRow("Speed: multiplier","speedMult")
numRow("Jump power: default","jpDef");numRow("Jump power: multiplier","jpMult")
numRow("Spin: default (rotations/s)","spinDef");numRow("Spin: multiplier","spinMult")
numRow("Float: stair height (studs)","floatStep")
fhdr(aq,"Freecam (;freecam / ;fc)")
numRow("Fly: default speed","fcDef");numRow("Look sensitivity (multiplier, 1 = normal)","fcSens")
fhdr(aq,"Spider (;spider)")

numRow("Wall height (studs, hook only taller walls, 0 = any)","spWall")
fhdr(aq,"Tpwalk")
optRow("Mode","tpMode",{{"Multiplier","Multiplier"},{"Additive","Additive"}},84)
numRow("Default amount","tpDef");numRow("Maximum (cap)","tpCap")
fhdr(aq,"Follow, backpack, baby")
numRow("Follow: default radius (studs)","followRadius")
togRow("Attach: match the target's speed","attachVel")
numRow("Attach: acceleration lead (seconds, 0 = off, try 0.05 to 0.15)","attachLead")
togRow("Attach: follow the target's root part (steadier when they speed up / stop)","attachRoot")
numRow("Backpack: distance","bpDist");numRow("Backpack: height","bpHeight")
numRow("Baby: distance","babyDist");numRow("Baby: height","babyHeight");numRow("Baby: rotation (degrees)","babyRot");numRow("Baby: lean back (degrees)","babyLean")
fhdr(aq,"Head attach (;heada / ;headattach)")
numRow("Distance (in front of the face)","headDist");numRow("Height above the head","headHeight");numRow("Side","headSide")
togRow("Sweep front / back","headSweep");numRow("Sweep amplitude (studs)","headSweepAmp");numRow("Sweep speed (radians/s)","headSweepSpeed")
fhdr(aq,"Back attach (;backa / ;backattach)")
numRow("Distance (behind the back)","backDist");numRow("Height","backHeight");numRow("Side","backSide")
togRow("Sweep front / back","backSweep");numRow("Sweep amplitude (studs)","backSweepAmp");numRow("Sweep speed (radians/s)","backSweepSpeed")
fhdr(aq,"Offense prediction (backpack, baby, headsit, heada, backa)")
togRow("Prediction (server sees you in sync)","predOn")
numRow("Prediction strength (1 = your ping)","predMult")
fhdr(aq,"Server position (;serverpos / ;unserverpos)")
togRow("Show server position","srvShow")
numRow("Auto hide within (studs, 0 to 5)","srvHide")
fhdr(aq,"ESP (;esp)")
togRow("Custom colour (off = team colour)","espCustom")
hexRow("Custom colour (hex)","espColor")
fhdr(aq,"Crosshair (;crosshair / ;removecrosshair)")
optRow("Mode","chStyle",{{"Cross","Cross"},{"T","T"},{"Dot","Dot"}},84)
numRow("Length","chLen");numRow("Gap","chGap");numRow("Thickness","chThick")
numRow("Outline thickness (0 = none)","chOutline");numRow("Outline opacity (0 to 1)","chOutlineAlpha")
hexRow("Colour (hex)","chColor")
togRow("Replace Roblox cursor (off = screen center)","chCursor")
fhdr(aq,"Notifications and display")
togRow("Activation notices","actOn")
optRow("Notice corner","actCorner",{{"TL","TL"},{"TR","TR"},{"BL","BL"},{"BR","BR"}},47)
optRow("Show FPS corner","fpsCorner",{{"TL","TL"},{"TR","TR"},{"BL","BL"},{"BR","BR"}},47)
fhdr(aq,"Ragdoll (;ragdoll)")
togRow("Ragdoll blocks game reset","ragdollBlock")
fhdr(aq,"Streamer mode")
strRow("Your name","streamMe");strRow("Other players (comma separated)","streamOthers")
fhdr(aq,"Placeholder1 (;placeholder1)")
numRow("Animation speed (1 = default)","ph1Mult")
fhdr(aq,"Server browser")
numRow("Ping shown = list ping x this (the list underreports)","srvPingMult")
fhdr(aq,"Defense")
togRow("Defense notifications","defNotify")
numRow("Anti fling: radius","afRadius");numRow("Anti fling: velocity threshold","afThreshold");numRow("Anti fling: restore time (s)","afRestore")
numRow("Anti teleport: min distance","atpMin");numRow("Anti knockback: max speed","akMax")
numRow("Anti void: height above destroy","avHeight")
numRow("Anti ear rape: threshold","aeThreshold");numRow("Anti ear rape: window (s)","aeDuration")
numRow("Anti afk: interval (s)","afkInterval");numRow("Anti spam: messages","spamCount")
al["Module Cfg"]=function()if n.layoutHud and B.active.showfps then n.layoutHud()end end
end)



n.lazy("Preferences",function()
local aq=flow"Preferences"
fhdr(aq,"General")
seg(frow(aq,"Notifications",102),0,{0,55},47,{{"On",true},{"Off",false}},"toasts")
seg(frow(aq,"Open command bar on start",102),0,{0,55},47,{{"On",true},{"Off",false}},"startBar")
seg(frow(aq,"Auto execute",102),0,{0,55},47,{{"On",true},{"Off",false}},"autoExec",function(ar)z.setAutoExec(ar)end)
seg(frow(aq,"Auto rejoin on VC ban",102),0,{0,55},47,{{"On",true},{"Off",false}},"avc",function(ar)z.setAvc(ar)end)
seg(frow(aq,"Command list: up to 3 columns",102),0,{0,55},47,{{"On",true},{"Off",false}},"sugCols")
fhdr(aq,"Voice")
if s.listenPad==-3 then s.listenPad=-6 end
seg(frow(aq,"Listen pad (attenuation)",168),0,{0,59,118},50,{{"0 dB",0},{"-6 dB",-6},{"-12 dB",-12}},"listenPad",function()z.applyListenPad()end)
fhdr(aq,"Server browser")
seg(frow(aq,"Max servers to scan",227),0,{0,59,118,177},50,{{"25",25},{"50",50},{"75",75},{"100",100}},"srvMax")
fhdr(aq,"Players tab")
seg(frow(aq,"Sort refresh, 0 = no delay",286),0,{0,59,118,177,236},50,{{"0",0},{"1",1},{"2",2},{"3",3},{"5",5}},"plPoll",function()end)
fhdr(aq,"User notifier")
seg(frow(aq,"Status refresh (seconds)",227),0,{0,59,118,177},50,{{"30",30},{"45",45},{"60",60},{"90",90}},"nuPoll")
local ar=new("Frame",{Size=UDim2.new(1,0,0,23),BackgroundTransparency=1,LayoutOrder=nx()},aq)
local as=input(ar,"username to watch (also ;notifyuser)…",0,0,330,23,11)
local function addNu()z.nuAdd(as.Text);as.Text=""end
btn(ar,"Add",336,0,60,23,"primary",nil,addNu)
as.FocusLost:Connect(function(at)if at then addNu()end end)
local at=new("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=nx()},aq)
new("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},at)
function n.refreshNu()
for au,av in ipairs(at:GetChildren())do if av:IsA"GuiObject"then av:Destroy()end end
if#s.notifyUsers==0 then
txt(new("Frame",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1},at),"none",11,"sub",12,0,300,20)
end
for au,av in ipairs(s.notifyUsers)do
local aw=z.nuInfo[av]or{}
local ax=fr(at,0,0,0,56,"row",0.85,8,"edge",1,0.55)
ax.Size,ax.LayoutOrder=UDim2.new(1,0,0,56),au
if aw.id then
local ay=new("ImageLabel",{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(40,40),BorderSizePixel=0,BackgroundTransparency=0.9,Image=thumb("AvatarHeadShot",aw.id,150)},ax)
paint(ay,"BackgroundColor3","row")
new("UICorner",{CornerRadius=UDim.new(1,0)},ay)
end
local ay,az=z.nuStatus(av)
txt(ax,aw.display or aw.user or av,11,"text2",58,5,330,16,{Font=ab,TextTruncate=Enum.TextTruncate.AtEnd})
txt(ax,"@"..(aw.user or av),8,"sub",58,21,330,12,{TextTruncate=Enum.TextTruncate.AtEnd})
local aA=new("Frame",{Position=UDim2.fromOffset(59,40),Size=UDim2.fromOffset(8,8),BorderSizePixel=0,BackgroundColor3=az},ax)
new("UICorner",{CornerRadius=UDim.new(1,0)},aA)
txt(ax,ay,9,"text",73,36,320,16,{TextTruncate=Enum.TextTruncate.AtEnd})
btn(ax,"Remove",ap.IW-134,16,70,23,"danger",nil,function()z.nuRemove(av)end)
end
end
n.refreshNu()
fhdr(aq,"System")
local au=new("Frame",{Size=UDim2.new(1,0,0,16),BackgroundTransparency=1,LayoutOrder=nx()},aq)
local av=new("Frame",{Position=UDim2.fromOffset(2,3),Size=UDim2.fromOffset(10,10),BorderSizePixel=0},au)
new("UICorner",{CornerRadius=UDim.new(1,0)},av)
local aw=txt(au,"",11,"text",18,0,400,16,{TextTruncate=Enum.TextTruncate.AtEnd})
local ax={}
for ay,az in ipairs{"cpu","gpu","ram","mem","ft","ping"}do ax[az]=txt(aq,"",11,"text",0,0,400,16,{LayoutOrder=nx(),TextTruncate=Enum.TextTruncate.AtEnd})end
local function refreshSys()
local ay=n.rel
local az=ay.sys
av.BackgroundColor3,av.Visible=ay.col[ay.s or"bad"],ay.s~=nil
aw.Text="Relay: "..(({ok="connected",warn="connected, rate limited",bad="errors / connection lost"})[ay.s or""]or"not connected").."   PID "..ay.pid
ax.cpu.Text="CPU: "..(az.cpu or"needs relay")
ax.gpu.Text="GPU: "..(az.gpu or"needs relay")
ax.ram.Text="RAM: "..(az.ram and(az.ram.." GB, "..az.load.."% used")or"needs relay")
local function v(aA,aB)local aC,aD=pcall(aA);return aC and tonumber(aD)and(("%.1f"):format(aD)..aB)or"-"end
ax.mem.Text="Roblox memory: "..v(function()return l.Stats:GetTotalMemoryUsageMb()end," MB")
ax.ft.Text="Frame time: CPU "..v(function()return l.Stats.PerformanceStats.CPU:GetValue()end," ms")..", GPU "..v(function()return l.Stats.PerformanceStats.GPU:GetValue()end," ms")
ax.ping.Text="Ping: "..v(function()return l.Stats.Network.ServerStatsItem["Data Ping"]:GetValue()end," ms")
end
task.spawn(function()
while l.alive do
if l.panelOpen and n.tab=="Preferences"then pcall(refreshSys)end
task.wait(2)
end
end)
fhdr(aq,"Active effects")
local ay=txt(aq,"none",11,"sub",0,0,400,20,{LayoutOrder=nx(),TextWrapped=true})
local az=new("Frame",{Size=UDim2.new(1,0,0,23),BackgroundTransparency=1,LayoutOrder=nx()},aq)
local function refresh()
local aA={}
for aB in pairs(B.active)do aA[#aA+1]=(B.who and B.who[aB])and(aB:sub(1,1):upper()..aB:sub(2)..": "..B.who[aB])or aB end
table.sort(aA)
ay.Text=#aA>0 and table.concat(aA,", ")or"none"
end
btn(az,"Reset all effects",0,0,120,23,"danger",nil,function()z.resetAll();refresh()end)
btn(az,"Unload panel",126,0,100,23,"danger",nil,function()n.unload()end)
txt(aq,"KL rOSAD v"..a,8,"dim",0,0,300,14,{LayoutOrder=nx()})
al.Preferences=function()refresh();n.refreshNu();pcall(refreshSys)end
end)



rest"PROFILE+PAGES"


function n.curScale()return s.scale end
function n.rescale()
local aq=n.curScale()
n.panelScale.Scale,n.barScale.Scale,n.toastScale.Scale,n.hudScale.Scale,n.popScale.Scale=aq,aq,aq,aq,aq
n.actScale.Scale=aq
if n.profScale then n.profScale.Scale=aq end
end



function n.syncShift()
local aq=l.ContextActionService
pcall(function()aq:UnbindAction"KLOSAD_Shift"end)
local ar={}
for as,at in ipairs{s.panelKey,s.barKey}do
if at=="RightShift"or at=="LeftShift"then ar[#ar+1]=Enum.KeyCode[at]end
end
if#ar>0 then
pcall(function()
aq:BindActionAtPriority("KLOSAD_Shift",function()return Enum.ContextActionResult.Sink end,false,Enum.ContextActionPriority.High.Value,table.unpack(ar))
end)
end
end

function n.apply()
n.syncShift()
l.accent=parseHex(s.accent)or l.accent
l.accentText=legible(l.accent,w[s.theme].panel)
applyTheme()
n.rescale()
n.panel.BackgroundTransparency=1-s.opacity

l.opK=math.clamp(tonumber(s.opacity)or 0.8,0.2,1)/0.8
local aq=n.panel:GetDescendants()
if n.profWin then
n.profWin.BackgroundTransparency=1-s.opacity
for ar,as in ipairs(n.profWin:GetDescendants())do aq[#aq+1]=as end
end
if n.prof and n.prof.retitle then n.prof.retitle()end
for ar,as in ipairs(aq)do
local at=as:GetAttribute"raw"
if at then
local au=l.opx(at)
as.BackgroundTransparency=au
if as:GetAttribute"base"~=nil then as:SetAttribute("base",au)end
end
end
if n.setGlow then n.setGlow()end
n.ambient()
n.title.Text='<font color="'..hex(l.accent)..'">&gt;</font>KL rOSAD'
n.box.PlaceholderText="[ "..keyStr(s.barKey).." ] enter or search a command…"
n.layoutBar()
if n.refreshKeys then n.refreshKeys()end
if l.barOpen then n.search()end

if l.panelOpen and al[n.tab]then al[n.tab]()end
z.bus.fire("look",{theme=s.theme,accent=l.accent,accentText=l.accentText,opacity=s.opacity,glow=s.glow,scale=s.scale,anim=s.anim})
end

conn(l.UserInputService.InputBegan,function(aq)
if aq.UserInputType~=Enum.UserInputType.Keyboard then return end
local ar=aq.KeyCode
if l.capture then
local as=l.capture
l.capture=nil
as(ar,z.keyName(ar))
return
end
if l.barOpen then
if ar==Enum.KeyCode.Escape then n.closeBar()
elseif ar==Enum.KeyCode.Tab then n.complete()
elseif ar==Enum.KeyCode.Space and(l.ghost or"")~=""then n.complete()
elseif ar==Enum.KeyCode.Down then n.hold(ar,function()n.move(1)end)
elseif ar==Enum.KeyCode.Up then n.hold(ar,function()n.move(-1)end)
elseif ar==Enum.KeyCode.Right then n.hold(ar,function()n.moveH(1)end)
elseif ar==Enum.KeyCode.Left then n.hold(ar,function()n.moveH(-1)end)end
return
end


if l.UserInputService:GetFocusedTextBox()then return end
if ar.Name==s.barKey then
n.openBar()
elseif ar.Name==s.panelKey then
n.setPanel(not l.panelOpen)
else
local as=z.activeBinds()
if as then z.fireBind(as,ar)end
end
end)

conn(workspace.CurrentCamera:GetPropertyChangedSignal"ViewportSize",function()
n.rescale()
n.layoutBar()
end)



do
local aq,ar,as=l.ContextActionService,false,false

l.spotDY=0
pcall(function()l.spotDY=l.GuiService:GetGuiInset().Y end)
conn(l.RunService.RenderStepped,function()
local at=(l.panelOpen or l.barOpen or l.profOpen)and l.UserInputService:GetMouseLocation()or nil
if not at then if as then return end;as=true else as=false end
local au=false
for av,aw in ipairs(l.spots)do
local ax=false
if at and aw.live()then
local ay,az=aw.area.AbsolutePosition,aw.area.AbsoluteSize
if at.X>=ay.X and at.X<=ay.X+az.X and at.Y>=ay.Y and at.Y<=ay.Y+az.Y then
ax=true
local aA=az.X/math.max(aw.area.Size.X.Offset,1)
aw.hold.Position=UDim2.fromOffset((at.X-ay.X)/aA,(at.Y-l.spotDY-ay.Y)/aA)
end
end
if aw.hold.Visible~=ax then aw.hold.Visible=ax end
au=au or ax
end
if au~=ar then
ar=au
if au then
pcall(aq.BindActionAtPriority,aq,"KLOSAD_Block",function(av,aw)


if aw==Enum.UserInputState.End or aw==Enum.UserInputState.Cancel then return Enum.ContextActionResult.Pass end
return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value,
Enum.UserInputType.MouseButton1,Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3,Enum.UserInputType.MouseWheel,Enum.UserInputType.Touch)
else
pcall(aq.UnbindAction,aq,"KLOSAD_Block")
end
end
end)
end

function n.unload()
l.alive=false
pcall(z.bus.fire,"unload")
pcall(z.resetAll)
pcall(function()
for aq,ar in pairs(B.saved.light or{})do z.Lighting[aq]=ar end
B.saved.light=nil
end)
pcall(function()l.ContextActionService:UnbindAction"KLOSAD_Shift"end)
pcall(function()l.ContextActionService:UnbindAction"KLOSAD_Block"end)
for aq in pairs(B.listen)do pcall(z.setListen,aq,false)end
for aq in pairs(B.vcVol or{})do pcall(z.setVoiceVol,aq,1)end
pcall(z.vcClear)
pcall(z.noStereo,false)
pcall(z.crosshair,false)
pcall(z.syncStop)
pcall(z.voidStop)
pcall(z.SRV.cancelJoin,true)
pcall(function()n.borderTween:Cancel()end)
pcall(function()n.glowTween:Cancel()end)
pcall(function()n.orbitTween:Cancel()end)
pcall(function()n.busyTween:Cancel()end)
for aq,ar in ipairs(l.cons)do pcall(function()ar:Disconnect()end)end
for aq in pairs(B.conns)do z.disconnect(aq)end
for aq in pairs(B.muted)do pcall(z.setMuted,aq,false)end
B.muted={}
if B.chat then B.chat.spam=false end
pcall(function()
if l.chatPrev then l.TextChatService.OnIncomingMessage=l.chatPrev.fn end
end)
pcall(z.baseplate,false)
pcall(n.closeProfile,true)
l.panelOpen,l.barOpen=false,false
n.syncMouse()
pcall(function()n.blur:Destroy()end)
pcall(function()af:Destroy()end)
if c.KLOSAD and c.KLOSAD.Unload==n.unload then c.KLOSAD=nil end
local aq=c.KLOSAD_ALL and table.find(c.KLOSAD_ALL,n.unload)
if aq then table.remove(c.KLOSAD_ALL,aq)end
end

n.apply()
do
local aq=z.kbTab()
if aq and aq.es and aq.exp~=game.GameId then s.kbActive="default"end
for ar,as in ipairs(s.kbTabs)do
if as.es and as.exp==game.GameId then s.kbActive=as.id;break end
end
end
n.selectTab"Home"
c.KLOSAD={Unload=n.unload,ctx=z,cfg=s,ui=n,S=l,version=a}
c.KLOSAD_BOOT=nil
c.KLOSAD_ALL=c.KLOSAD_ALL or{}
table.insert(c.KLOSAD_ALL,n.unload)
if not(p and q)then z.notify("Limited mode: this executor has no file access or loadstring.",5)end
n.welcome()
if s.startBar then task.defer(function()n.openBar()end)end
if s.autostart.onExec then task.delay(2,function()z.runAutostart"exec"end)end
warn("[KLOSAD] load run-work: "..table.concat(d.n,", ")..", ENTRY "..math.floor((os.clock()-d.last)*1000).."ms | wall "..math.floor((os.clock()-d.t0)*1000).."ms")
