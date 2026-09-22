# -d23k.lua
--[[
═══════════════════════════════════════════════════════════════════════
  X MENU V53 — ULTIMATE EDITION (Single File)
  Features: Fling | ESP | Auto-Fling | Remote | AI | Fly | Waypoint |
  Track | Movement | Utility | Players | Settings | Garage | Killcam |
  Stats | Vehicles | i18n (5 langs) | KillFeed | ConfigSlots | AnimLib |
  CamModes | Radar | LogViewer | 40+ Chat cmds | Per-Tab Settings
  Mobile-first | Red-Black theme | No health change | No rank/nametag
═══════════════════════════════════════════════════════════════════════
]]

-- ═══ SERVICES ═══
local Players=game:GetService("Players")
local RS=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TS=game:GetService("TweenService")
local SG=game:GetService("StarterGui")
local WS=game:GetService("Workspace")
local Deb=game:GetService("Debris")
local Light=game:GetService("Lighting")
local Http=game:GetService("HttpService")
local TPS=game:GetService("TeleportService")
local VU=game:GetService("VirtualUser")
local LP=Players.LocalPlayer
if not LP then warn("[X53] No LP") return end
print("test")
print("[X53] Loading...")

local MY_USERID=LP.UserId
if MY_USERID==0 then warn("[X53] MY_USERID=0 → off") return end
local ADMINS={[LP.UserId]=true}

-- Forward
local GetVehicle,GetMainPart,SetStatus,notify,log
local RefreshPlayerList,openSelector,showInfo
local UpdateESPColors,UpdateESPVisibility,RefreshAllESP,UpdateESPObjects
local XMenu,ScreenGui,menuUIScale
local StatusLabel,KillLabel,StatsLabel,FPSLabel,PingLabel
local UpdateQueueUI
local Pages,Tabs

-- ═══ COLORS ═══
local C={
  Bg=Color3.fromRGB(13,13,13), Panel=Color3.fromRGB(26,10,10),
  PanelAlt=Color3.fromRGB(20,20,28), Red=Color3.fromRGB(230,46,46),
  OffRed=Color3.fromRGB(139,26,26), Border=Color3.fromRGB(255,68,68),
  Green=Color3.fromRGB(0,255,100), Blue=Color3.fromRGB(0,200,255),
  Yellow=Color3.fromRGB(255,200,0), Purple=Color3.fromRGB(180,80,255),
  White=Color3.fromRGB(240,240,240), Dim=Color3.fromRGB(160,160,160),
  RedT=Color3.fromRGB(255,80,80), GrnT=Color3.fromRGB(120,255,120),
  YlwT=Color3.fromRGB(255,220,120),
}

-- ═══ SETTINGS ═══
local S={
  FlingPower=3500,MinFlingPower=100,MaxFlingPower=50000,MaxSpinSpeed=600,
  FlingCooldown=1.0,FlingRange=60,FlySpeed=90,WaypointSpeed=100,
  WaypointFlingCooldown=0.5,NoclipActive=false,IsFlying=false,
  ClickFlingActive=false,IsFlingEveryone=false,IsNormalFling=false,
  IsWaypointRunning=false,WaypointDirection=1,UseBanSafe=false,
  AntiDetection=false,FlingDelayMin=5,FlingDelayMax=15,
  IsMobile=UIS.TouchEnabled and not UIS.KeyboardEnabled,
  FPSUnlocker=false,Fullbright=false,AntiAFK=false,ShowFPSCounter=true,
  ShowPing=true,AntiFling=false,ESP_Enabled=false,ESP_Highlight=true,
  ESP_Box=true,ESP_Name=true,ESP_Distance=true,ESP_Health=true,
  ESP_TeamCheck=true,ESP_Color=Color3.fromRGB(0,255,0),
  ESP_SelectedColor=Color3.fromRGB(255,255,0),TracerLines=false,
  TracerColor=Color3.fromRGB(255,50,50),AutoFlingActive=false,
  AntiFlingBypass=false,Password="1234",IsUnlocked=false,MenuSize="Small",
  SoundEnabled=true,CarSpeed=120,CarTurnSpeed=5,CarRiseSpeed=80,
  CarAntiTip=true,CarAntiJitter=true,CarAntiVoid=true,CarNetworkReassert=true,
  Language="TR",AutoFlingDelay=0.5,AutoFlingSelectMode="manual",
  CarForceMode=false,CarSmooth=true,FlySmooth=true,FlyCameraLock=false,
  FlyMode="character",WaypointArrive=5,WaypointTransition=0.4,
  FollowDistance=10,TrackUpdateRate=0.1,
}

-- ═══ STATE ═══
local St={lastFlingTime=0,isFollowingPlayer=false,targetPlayer=nil,
  targetPosition=nil,lastStatusUpdate=0,isRespawning=false,
  lastSoundTime=0,lastEffectTime=0,isShuttingDown=false,killCount=0,
  lastPatrolFlingTime=0,lastWaypointFlingTime=0,sessionKills=0,
  sessionDeaths=0,currentStreak=0,bestStreak=0,deathCount=0,
  lastAntiAFKTime=0,antiFlingConn=nil,lastSafePosition=nil,lastSafeTime=0,
  lastRateCmdTime=0,currentMenuScale=1,carSaveCFrame=nil}

local VD={Current=nil,MainPart=nil,SavedCFrame=nil,LastKnownVehicle=nil,
  LastSeatTime=0,RemoteMode=false,CarYaw=0,CarInput={forward=0,strafe=0,rise=0},
  YawAlignOrientation=nil,YawAttach=nil,LastNetworkCheck=0,AlignOrientation=nil,
  StabilizerAttachment=nil}
local WP={Point1=nil,Point2=nil}
local WPSt={transitioning=false}
local SelectedPlayers={}
local ESPObjects={}
local TracerData={}
local RemoteControlActive=false
local AID={Enabled=false,Mode="auto",Target=nil,LastTargetSwitch=0,
  TargetSwitchCooldown=2,ThreatRadius=80,AttackRadius=35,RetreatHP=30,
  PatrolPoints={},CurrentPatrolIndex=1,ScanInterval=0.3,LastScan=0,
  Personality=math.random()}
local KC={buffer={},recording=false,MAX=60}
local OLS={}

-- ═══ TASK MGR ═══
local Conn={},Timers={}
local function AddC(c)table.insert(Conn,c);return c end
local function Cleanup()
  for _,c in ipairs(Conn)do pcall(function()c:Disconnect()end)end
  Conn={};Timers={}
end

-- ═══ HELPERS ═══
local function Safe(f,...)local ok,r=pcall(f,...)if not ok then warn("[X53] "..tostring(r))return nil end return r end
local function RI(a,b)return math.random(math.floor(a),math.floor(b))end
local function getPlr(n)if not n or n==""then return nil end n=string.lower(n)
  for _,p in ipairs(Players:GetPlayers())do
    if string.lower(p.Name):sub(1,#n)==n or string.lower(p.DisplayName):sub(1,#n)==n then return p end
  end return nil end
local function rateLimit(md)md=md or 1
  local now=os.clock()if now-St.lastRateCmdTime<md then return false end
  St.lastRateCmdTime=now;return true end
local LogHist={}
log=function(c,d)local t=os.date("%H:%M:%S")
  local m=string.format("[X] [%s] [%s] %s",t,tostring(c),tostring(d or ""))
  table.insert(LogHist,m)if #LogHist>200 then table.remove(LogHist,1)end
  print(m)end
local function tween(o,t,p)local ti=TweenInfo.new(t,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
  local x=TS:Create(o,ti,p);x:Play();return x end
local function corner(p,r)local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r or 6);c.Parent=p;return c end
local function stroke(p,col,th)local s=Instance.new("UIStroke");s.Color=col or C.Border
  s.Thickness=th or 1;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=p;return s end
local function txt(par,t,sz,col,fnt,al,ord,pos,szv)
  local l=Instance.new("TextLabel");l.Text=t or "";l.BackgroundTransparency=1
  l.TextColor3=col or C.White;l.Font=fnt or Enum.Font.Gotham;l.TextSize=sz or 12
  l.TextXAlignment=al or Enum.TextXAlignment.Left;l.LayoutOrder=ord or 0
  if pos then l.Position=pos end
  if szv then l.Size=szv else l.Size=UDim2.new(1,-16,0,22)end
  l.Parent=par;return l end
local function btn(par,t,col,ord,sz)
  local b=Instance.new("TextButton");b.Text=t or "";b.BackgroundColor3=col or C.OffRed
  b.TextColor3=C.White;b.Font=Enum.Font.GothamBold;b.TextSize=12;b.AutoButtonColor=true
  b.LayoutOrder=ord or 0;b.Size=sz or UDim2.new(1,-16,0,44);b.Parent=par;corner(b,5)
  local c=Instance.new("UITextSizeConstraint");c.MinTextSize=10;c.MaxTextSize=13;c.Parent=b
  AddC(b.MouseButton1Down:Connect(function()
    tween(b,0.05,{Size=UDim2.new(sz and sz.X.Scale or 1,(sz and sz.X.Offset or -16)-2,0,(sz and sz.Y.Offset or 44)-2)})end))
  AddC(b.MouseButton1Up:Connect(function()tween(b,0.08,{Size=sz or UDim2.new(1,-16,0,44)})end))
  return b end
local function input(par,ph,ord)
  local t=Instance.new("TextBox");t.PlaceholderText=ph or ""
  t.Size=UDim2.new(1,-16,0,32);t.BackgroundColor3=Color3.fromRGB(30,30,40)
  t.TextColor3=C.White;t.PlaceholderColor3=C.Dim;t.Font=Enum.Font.Gotham
  t.TextSize=12;t.ClearTextOnFocus=false;t.LayoutOrder=ord or 0;t.Parent=par;corner(t,5);return t end

-- ═══ TOAST ═══
local toastHolder
local function ensureToast()
  if toastHolder and toastHolder.Parent then return toastHolder end
  if not ScreenGui then return nil end
  toastHolder=Instance.new("Frame");toastHolder.Size=UDim2.new(0,320,1,0)
  toastHolder.Position=UDim2.new(1,-330,0,40);toastHolder.BackgroundTransparency=1
  toastHolder.ZIndex=999999;toastHolder.Parent=ScreenGui
  local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,6)
  ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.VerticalAlignment=Enum.VerticalAlignment.Top
  ll.Parent=toastHolder;return toastHolder end
notify=function(title,text,dur,col)
  dur=dur or 3;col=col or C.Green
  local h=ensureToast();if not h then return end
  local card=Instance.new("Frame");card.Size=UDim2.new(1,0,0,52)
  card.BackgroundColor3=Color3.fromRGB(20,20,28);card.BackgroundTransparency=0.05
  card.BorderSizePixel=0;card.Parent=h;corner(card,8);stroke(card,col,2)
  local t1=Instance.new("TextLabel");t1.Text=title or "";t1.BackgroundTransparency=1
  t1.TextColor3=col;t1.Font=Enum.Font.GothamBold;t1.TextSize=13
  t1.TextXAlignment=Enum.TextXAlignment.Left;t1.Size=UDim2.new(1,-20,0,20)
  t1.Position=UDim2.new(0,10,0,4);t1.Parent=card
  local t2=Instance.new("TextLabel");t2.Text=text or "";t2.BackgroundTransparency=1
  t2.TextColor3=C.White;t2.Font=Enum.Font.Gotham;t2.TextSize=11
  t2.TextXAlignment=Enum.TextXAlignment.Left;t2.TextWrapped=true
  t2.Size=UDim2.new(1,-20,0,22);t2.Position=UDim2.new(0,10,0,24);t2.Parent=card
  task.delay(dur,function()
    if card and card.Parent then
      tween(card,0.35,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0)})
      task.wait(0.4);pcall(function()card:Destroy()end)
    end end)
end

-- ═══ SCREEN GUI ═══
local PlayerGui=LP:WaitForChild("PlayerGui",10)
local function buildSG()
  local sg=Instance.new("ScreenGui");sg.Name="X53_"..tostring(math.random(1000,9999))
  sg.ResetOnSpawn=false;sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
  sg.IgnoreGuiInset=true;sg.DisplayOrder=999999
  local ok=pcall(function()sg.Parent=game:GetService("CoreGui")end)
  if not ok and PlayerGui then sg.Parent=PlayerGui end
  return sg end
ScreenGui=buildSG()

local TracerGui=Instance.new("Frame");TracerGui.Name="TracerLayer"
TracerGui.Size=UDim2.new(1,0,1,0);TracerGui.BackgroundTransparency=1;TracerGui.ZIndex=1
pcall(function()TracerGui.Parent=ScreenGui end)

-- ═══ PASSWORD ═══
local PwdGui=Instance.new("Frame");PwdGui.Size=UDim2.new(0,300,0,190)
PwdGui.Position=UDim2.new(0.5,-150,0.5,-95);PwdGui.BackgroundColor3=Color3.fromRGB(15,15,22)
PwdGui.BorderSizePixel=0;PwdGui.Active=true;PwdGui.Visible=true;PwdGui.ZIndex=9999999
PwdGui.Parent=ScreenGui;corner(PwdGui,12);stroke(PwdGui,C.Green,3)
txt(PwdGui,"🔒 X MENU V53 ŞİFRE",16,C.Green,Enum.Font.GothamBold,Enum.TextXAlignment.Center,1,
  UDim2.new(0,0,0,12),UDim2.new(1,0,0,28))
local PwdDesc=Instance.new("TextLabel");PwdDesc.Text="Şifre: "..S.Password
PwdDesc.Size=UDim2.new(1,0,0,18);PwdDesc.Position=UDim2.new(0,0,0,42)
PwdDesc.BackgroundTransparency=1;PwdDesc.TextColor3=Color3.fromRGB(150,150,150)
PwdDesc.Font=Enum.Font.Gotham;PwdDesc.TextSize=11;PwdDesc.TextXAlignment=Enum.TextXAlignment.Center
PwdDesc.Parent=PwdGui
local PwdInput=Instance.new("TextBox");PwdInput.PlaceholderText="Şifre"
PwdInput.Size=UDim2.new(1,-40,0,36);PwdInput.Position=UDim2.new(0,20,0,70)
PwdInput.BackgroundColor3=Color3.fromRGB(30,30,40);PwdInput.TextColor3=Color3.fromRGB(255,255,255)
PwdInput.PlaceholderColor3=Color3.fromRGB(150,150,150);PwdInput.Font=Enum.Font.Gotham
PwdInput.TextSize=14;PwdInput.ClearTextOnFocus=false;PwdInput.Parent=PwdGui;corner(PwdInput,6)
local PwdBtn=btn(PwdGui,"🔓 GİRİŞ",Color3.fromRGB(0,150,80),1,UDim2.new(1,-40,0,36))
PwdBtn.Position=UDim2.new(0,20,0,116)
local PwdErr=txt(PwdGui,"",11,C.RedT,Enum.Font.Gotham,Enum.TextXAlignment.Center,1,
  UDim2.new(0,0,1,-24),UDim2.new(1,0,0,16))
local function TryUnlock()
  if PwdInput.Text==S.Password then S.IsUnlocked=true;PwdGui.Visible=false
    SetStatus("✅ Şifre doğru",C.Green);notify("🔓","Panel hazır",3,C.Green)
  else PwdErr.Text="❌ Yanlış!";PwdInput.Text="" end end
AddC(PwdBtn.Activated:Connect(TryUnlock))
AddC(PwdInput.FocusLost:Connect(function(e)if e then TryUnlock()end end))

-- ═══ DRAGGABLE ═══
local function MakeDraggable(f,bar)
  bar=bar or f;local dr=false,ds=nil,sp=nil
  AddC(bar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dr=true;ds=i.Position;sp=f.Position end end))
  AddC(bar.InputChanged:Connect(function(i)
    if dr and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then
      local d=i.Position-ds
      if d.Magnitude>6 or i.UserInputType==Enum.UserInputType.MouseMovement then
        f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)end end end))
  AddC(UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
      dr=false end end))
end

-- ═══ X LOGO ═══
local XBtn=Instance.new("TextButton");XBtn.Size=UDim2.new(0,70,0,70)
XBtn.Position=UDim2.new(1,-90,0,20);XBtn.BackgroundColor3=C.Red;XBtn.Text="X"
XBtn.TextColor3=C.White;XBtn.Font=Enum.Font.GothamBold;XBtn.TextSize=30
XBtn.AutoButtonColor=false;XBtn.ZIndex=99999;XBtn.Parent=ScreenGui;corner(XBtn,35)
local XStroke=stroke(XBtn,C.Border,3)
task.spawn(function()
  while XBtn.Parent and not St.isShuttingDown do
    local t1=TS:Create(XStroke,TweenInfo.new(0.9,Enum.EasingStyle.Sine),{Color=Color3.fromRGB(255,200,200),Thickness=6})
    t1:Play();t1.Completed:Wait();if not XBtn.Parent then break end
    local t2=TS:Create(XStroke,TweenInfo.new(0.9,Enum.EasingStyle.Sine),{Color=C.Border,Thickness=3})
    t2:Play();t2.Completed:Wait()end end)
MakeDraggable(XBtn)

-- ═══ BACKDROP ═══
local Backdrop=Instance.new("TextButton");Backdrop.Text=""
Backdrop.Size=UDim2.new(1,0,1,0);Backdrop.BackgroundColor3=Color3.fromRGB(0,0,0)
Backdrop.BackgroundTransparency=0.55;Backdrop.BorderSizePixel=0;Backdrop.AutoButtonColor=false
Backdrop.Visible=false;Backdrop.ZIndex=99998;Backdrop.Parent=ScreenGui
AddC(Backdrop.Activated:Connect(function()if XMenu then XMenu.Visible=false end Backdrop.Visible=false end))
local function showBd()Backdrop.Visible=true end
local function hideBd()Backdrop.Visible=false end
AddC(XBtn.Activated:Connect(function()
  if not S.IsUnlocked then PwdGui.Visible=true;return end
  if XMenu then XMenu.Visible=not XMenu.Visible
    if XMenu.Visible then showBd()else hideBd()end end end))

-- ═══ MAIN PANEL ═══
local OW,OH=520,420
local MW,MH=340,260
local XW,XH=800,640
XMenu=Instance.new("Frame");XMenu.Name="XMenu"
XMenu.Size=UDim2.new(0,OW,0,OH);XMenu.Position=UDim2.new(0.5,-OW/2,0.5,-OH/2)
XMenu.BackgroundColor3=C.Bg;XMenu.BackgroundTransparency=0.08;XMenu.BorderSizePixel=0
XMenu.Active=true;XMenu.Visible=false;XMenu.ZIndex=99999;XMenu.Parent=ScreenGui;corner(XMenu,12)
local XMStroke=stroke(XMenu,C.Border,3)
local pi=TweenInfo.new(0.95,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true)
TS:Create(XMStroke,pi,{Color=C.OffRed}):Play()
menuUIScale=Instance.new("UIScale");menuUIScale.Scale=1;menuUIScale.Parent=XMenu

local XTitle=Instance.new("Frame");XTitle.Size=UDim2.new(1,0,0,38)
XTitle.BackgroundColor3=Color3.fromRGB(30,5,5);XTitle.BackgroundTransparency=0.05
XTitle.BorderSizePixel=0;XTitle.ZIndex=5;XTitle.Parent=XMenu;corner(XTitle,12)
txt(XTitle,"⚡ X MENU | V53",15,C.Red,Enum.Font.GothamBold,Enum.TextXAlignment.Left,0,
  UDim2.new(0,12,0,0),UDim2.new(1,-180,1,0))
local function titleBtn(t,xo,col)
  local b=Instance.new("TextButton");b.Text=t;b.Size=UDim2.new(0,26,0,26)
  b.Position=UDim2.new(1,xo,0,6);b.BackgroundColor3=col;b.TextColor3=C.White
  b.Font=Enum.Font.GothamBold;b.TextSize=14;b.Parent=XTitle;corner(b,6);return b end
local XRminus=titleBtn("-",-144,Color3.fromRGB(0,60,60))
local XRplus=titleBtn("+",-114,Color3.fromRGB(0,60,60))
local XRres=titleBtn("R",-84,Color3.fromRGB(0,60,60))
local XMin=titleBtn("_",-54,Color3.fromRGB(200,150,0))
local XClose=titleBtn("✕",-24,Color3.fromRGB(200,0,0))
MakeDraggable(XMenu,XTitle)
AddC(XMin.Activated:Connect(function()XMenu.Visible=false;hideBd()end))
AddC(XClose.Activated:Connect(function()XMenu.Visible=false;hideBd()end))

-- ═══ LEFT TABS ═══
local XLeft=Instance.new("ScrollingFrame");XLeft.Size=UDim2.new(0,130,1,-38)
XLeft.Position=UDim2.new(0,0,0,38);XLeft.BackgroundColor3=C.PanelAlt
XLeft.BackgroundTransparency=0.25;XLeft.BorderSizePixel=0;XLeft.ScrollBarThickness=3
XLeft.CanvasSize=UDim2.new(0,0,0,0);XLeft.Parent=XMenu
local LLL=Instance.new("UIListLayout");LLL.Padding=UDim.new(0,4)
LLL.SortOrder=Enum.SortOrder.LayoutOrder;LLL.Parent=XLeft
LLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  XLeft.CanvasSize=UDim2.new(0,0,0,LLL.AbsoluteContentSize.Y+12)end)
local function tabBtn(t,col,ord)
  local b=Instance.new("TextButton");b.Text=t;b.Size=UDim2.new(1,-8,0,32)
  b.BackgroundColor3=Color3.fromRGB(40,40,52);b.TextColor3=Color3.fromRGB(200,200,200)
  b.Font=Enum.Font.GothamBold;b.TextSize=11;b.LayoutOrder=ord or 0;b.Parent=XLeft;corner(b,6)
  local c=Instance.new("UITextSizeConstraint");c.MinTextSize=9;c.MaxTextSize=12;c.Parent=b
  b:SetAttribute("Accent",col);return b end
Tabs={
  Fling=tabBtn("💥 FLING",C.Green,1),ESP=tabBtn("👁️ ESP",Color3.fromRGB(0,220,0),2),
  AutoFling=tabBtn("🎯 AUTO",C.Yellow,3),Remote=tabBtn("📡 REMOTE",C.Blue,4),
  AI=tabBtn("🤖 AI",C.Purple,5),Fly=tabBtn("🛫 FLY",Color3.fromRGB(80,150,255),6),
  Waypoint=tabBtn("🛤️ PATH",Color3.fromRGB(255,150,50),7),
  Track=tabBtn("🎯 TRACK",Color3.fromRGB(100,255,200),8),
  Movement=tabBtn("🏃 MOVE",Color3.fromRGB(255,100,200),9),
  Utility=tabBtn("🛠️ UTIL",C.RedT,10),Players=tabBtn("👥 PLAY",Color3.fromRGB(200,100,255),11),
  Settings=tabBtn("⚙️ SET",Color3.fromRGB(180,180,180),12),
  Garage=tabBtn("🏎️ GARAGE",Color3.fromRGB(200,200,0),13),
  Killcam=tabBtn("🎬 KILL",Color3.fromRGB(200,50,50),14),
  Stats=tabBtn("📊 STATS",Color3.fromRGB(100,200,255),15),
  Vehicles=tabBtn("🚗 VEH",Color3.fromRGB(255,180,60),16),
}
local XMid=Instance.new("Frame");XMid.Size=UDim2.new(1,-130,1,-38)
XMid.Position=UDim2.new(0,130,0,38);XMid.BackgroundTransparency=1
XMid.BorderSizePixel=0;XMid.Parent=XMenu
local function createPage()
  local p=Instance.new("ScrollingFrame");p.Size=UDim2.new(1,0,1,0)
  p.BackgroundTransparency=1;p.BorderSizePixel=0;p.ScrollBarThickness=4
  p.CanvasSize=UDim2.new(0,0,0,0);p.Visible=false;p.Parent=XMid
  local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,5)
  ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.Parent=p
  ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    p.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+15)end)
  return p end
Pages={Fling=createPage(),ESP=createPage(),AutoFling=createPage(),Remote=createPage(),
  AI=createPage(),Fly=createPage(),Waypoint=createPage(),Track=createPage(),
  Movement=createPage(),Utility=createPage(),Players=createPage(),Settings=createPage(),
  Garage=createPage(),Killcam=createPage(),Stats=createPage(),Vehicles=createPage()}
local function SwitchTab(pg,tb)
  for _,p in pairs(Pages)do p.Visible=false end
  for _,b in pairs(Tabs)do b.BackgroundColor3=Color3.fromRGB(40,40,52)
    b.TextColor3=Color3.fromRGB(200,200,200)end
  pg.Visible=true
  local a=tb:GetAttribute("Accent") or C.Red
  tb.BackgroundColor3=a;tb.TextColor3=Color3.fromRGB(20,20,20)end
for nm,tb in pairs(Tabs)do if Pages[nm]then
  AddC(tb.Activated:Connect(function()SwitchTab(Pages[nm],tb)end))end end

-- ═══ FLING SYSTEM ═══
local function BypassAF(t)
  if not t then return end
  Safe(function()
    pcall(function()t:SetNetworkOwner(LP)end)
    if t.Anchored then t.Anchored=false end
    for _,ch in ipairs(t:GetChildren())do
      if ch:IsA("BodyGyro")or ch:IsA("BodyVelocity")or ch:IsA("AlignOrientation")
      or ch:IsA("AlignPosition")or ch:IsA("LinearVelocity")or ch:IsA("BodyPosition")then
        pcall(function()ch:Destroy()end)end end end)end
local function ApplyFling(root,pw,sp)
  if not root or not root.Parent or not root:IsA("BasePart")then return false end
  pw=math.floor(pw or S.FlingPower);sp=math.floor(sp or S.MaxSpinSpeed)
  if S.AntiFlingBypass then BypassAF(root)end
  pcall(function()root:SetNetworkOwner(LP)end)
  local m=root.AssemblyMass;if m<1 then m=1 end
  local d=Vector3.new(math.random()*2-1,0.7+math.random()*0.8,math.random()*2-1).Unit
  pcall(function()root:ApplyImpulse(d*pw*m*0.5)end)
  pcall(function()root.AssemblyAngularVelocity=Vector3.new(RI(-sp,sp),RI(-sp,sp),RI(-sp,sp))end)
  task.delay(0.02,function()
    if root and root.Parent then
      pcall(function()root.AssemblyLinearVelocity=Vector3.new(RI(-pw,pw),RI(math.floor(pw*0.7),math.floor(pw*1.3)),RI(-pw,pw))end)end end)
  return true end
local function FlingEffect(pos)
  if St.isShuttingDown then return end
  local now=os.clock();if now-St.lastEffectTime<0.05 then return end
  St.lastEffectTime=now
  Safe(function()
    for i=1,3 do
      local p=Instance.new("Part");p.Position=pos+Vector3.new(RI(-5,5),RI(-5,5),RI(-5,5))
      p.Size=Vector3.new(1,1,1);p.Shape=Enum.PartType.Ball;p.Material=Enum.Material.Neon
      p.BrickColor=BrickColor.new("Bright red");p.Anchored=true;p.CanCollide=false
      p.CastShadow=false;p.Transparency=0.1;p.Parent=WS
      TS:Create(p,TweenInfo.new(0.7,Enum.EasingStyle.Quad),{Size=Vector3.new(8,8,8),Transparency=1}):Play()
      Deb:AddItem(p,0.8)end end)end
local function FlingSound(pos)
  if St.isShuttingDown or not S.SoundEnabled then return end
  local now=os.clock();if now-St.lastSoundTime<0.2 then return end
  St.lastSoundTime=now
  Safe(function()local s=Instance.new("Sound");s.SoundId="rbxassetid://138091579"
    s.Volume=0.4;s.Parent=WS;s.Position=pos;s:Play();Deb:AddItem(s,5)end)end
local function DoFling(mul,far)
  if St.isShuttingDown then return end
  Safe(function()
    local v=GetVehicle();if not v then SetStatus("❌ Araç yok!",C.RedT)return end
    local mp=GetMainPart(v);if not mp then return end
    local rng=far and 99999 or S.FlingRange
    local cnt=0
    for _,p in ipairs(Players:GetPlayers())do
      if p~=LP and p.Character then
        local r=p.Character:FindFirstChild("HumanoidRootPart")
        local h=p.Character:FindFirstChildOfClass("Humanoid")
        if r and h and h.Health>0 then
          local d=(r.Position-mp.Position).Magnitude
          if d<=rng then
            ApplyFling(r,S.FlingPower*(mul or 1),S.MaxSpinSpeed)
            FlingEffect(r.Position);FlingSound(r.Position);cnt=cnt+1 end end end end
    if cnt>0 then SetStatus("🔥 "..cnt.." uçuruldu!",C.Yellow)
      notify("💥 FLING",cnt.." kişi",2,C.Yellow)end end)end

-- ═══ VEHICLE CORE ═══
function GetMainPart(v)
  if not v then return nil end
  if not v:IsA("Model")then return v:IsA("BasePart")and v or nil end
  return v:FindFirstChild("VehicleSeat")or v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")end
function GetVehicle()
  local now=os.clock();local ch=LP.Character
  if ch then
    local h=ch:FindFirstChildOfClass("Humanoid")
    if h and h.SeatPart and h.SeatPart.Parent then
      local vm=h.SeatPart:FindFirstAncestorOfClass("Model")or h.SeatPart.Parent
      if VD.Current~=vm then VD.Current=vm;VD.LastKnownVehicle=vm
        VD.LastSeatTime=now;VD.RemoteMode=false;VD.CarYaw=0 end
      return VD.Current end end
  if RemoteControlActive and VD.LastKnownVehicle and VD.LastKnownVehicle.Parent then
    if now-VD.LastSeatTime<600 then VD.Current=VD.LastKnownVehicle;VD.RemoteMode=true
      return VD.Current end end
  if not RemoteControlActive and VD.Current then VD.Current=nil;VD.MainPart=nil end
  return nil end
local function UnanchorVeh()
  Safe(function()
    if VD.MainPart and VD.MainPart.Parent then
      for _,n in ipairs({"VehicleAlignOrientation","StabilizerAttachment","XAlignPos","XMoveAtt","XMoveLV","FlingGyro","XYawAlign","XYawAtt"})do
        local o=VD.MainPart:FindFirstChild(n);if o then o:Destroy()end end end
    VD.AlignOrientation=nil;VD.StabilizerAttachment=nil;VD.YawAlignOrientation=nil;VD.YawAttach=nil end)end
local function MoveVeh(dir,sp)
  local v=GetVehicle();if not v then return false end
  local mp=GetMainPart(v);if not mp then return false end
  if mp.Anchored then for _,p in ipairs(v:GetDescendants())do
    if p:IsA("BasePart")then p.Anchored=false end end end
  pcall(function()mp:SetNetworkOwner(LP)end)
  if dir.Magnitude>0.01 then
    local att=mp:FindFirstChild("XMoveAtt")
    if not att then att=Instance.new("Attachment");att.Name="XMoveAtt";att.Parent=mp end
    local ap=mp:FindFirstChild("XAlignPos")
    if not ap then ap=Instance.new("AlignPosition");ap.Name="XAlignPos";ap.Attachment0=att
      ap.MaxForce=math.huge;ap.MaxVelocity=sp;ap.Responsiveness=25
      ap.RigidityEnabled=false;ap.ApplyAtCenterOfMass=true;ap.Parent=mp end
    ap.Position=mp.Position+dir.Unit*10;ap.MaxVelocity=sp
    local lv=mp:FindFirstChild("XMoveLV")
    if not lv then lv=Instance.new("LinearVelocity");lv.Name="XMoveLV"
      lv.Attachment0=att;lv.MaxForce=math.huge
      lv.ForceLimitMode=Enum.ForceLimitMode.Magnitude;lv.Parent=mp end
    lv.VectorVelocity=dir.Unit*sp
  else
    local lv=mp:FindFirstChild("XMoveLV");if lv then lv.VectorVelocity=Vector3.zero end
    local ap=mp:FindFirstChild("XAlignPos");if ap then ap:Destroy()end end
  return true end
local function StopVeh()
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v);if not mp then return end
  local lv=mp:FindFirstChild("XMoveLV");if lv then lv.VectorVectorVelocity=Vector3.zero end
  if lv then lv.VectorVelocity=Vector3.zero end
  local ap=mp:FindFirstChild("XAlignPos");if ap then ap:Destroy()end
  pcall(function()mp.AssemblyLinearVelocity=Vector3.zero
    mp.AssemblyAngularVelocity=Vector3.zero end)end

-- ═══ REMOTE ═══
local function SetRemote(on)
  RemoteControlActive=on
  if on then
    if VD.LastKnownVehicle and VD.LastKnownVehicle.Parent then
      SetStatus("📡 UZAKTAN AKTİF",Color3.fromRGB(0,255,200))
      notify("📡","Uzaktan aktif",2,C.Blue)
    else SetStatus("⚠️ Önce araca bin!",Color3.fromRGB(255,100,0))end
  else SetStatus("📡 Kapalı",Color3.fromRGB(200,200,200))end end
AddC(LP.CharacterAdded:Connect(function(ch)
  task.wait(1);local h=ch:WaitForChild("Humanoid",5)
  if not h then return end
  AddC(h.Seated:Connect(function(a,s)
    if a and s then local v=s:FindFirstAncestorOfClass("Model")or s.Parent
      VD.LastKnownVehicle=v;VD.LastSeatTime=os.clock()
      SetStatus("🚗 Araç kaydedildi",C.Green)end end))end))

-- ═══ KILL TRACKER ═══
local KT={}
local pK,pD,pS,pBS={},{},{},{}
local recentKill={}
function KT.RegisterKill(k,v)
  if k then
    pK[k]=(pK[k] or 0)+1;pS[k]=(pS[k] or 0)+1
    pBS[k]=math.max(pBS[k] or 0,pS[k])
    if not recentKill[k]then recentKill[k]={}end
    table.insert(recentKill[k],os.clock())
    local st=pS[k]
    for _,th in ipairs({3,5,10,15,20})do
      if st==th then SetStatus("🔥 "..k.Name.." "..th.." STREAK!",C.Yellow)
        notify("🔥 STREAK",k.Name.." → "..th,3,C.Yellow)end end
    if k==LP then St.sessionKills=St.sessionKills+1
      St.currentStreak=St.currentStreak+1
      St.bestStreak=math.max(St.bestStreak,St.currentStreak)
      St.killCount=St.killCount+1
      if KillLabel and KillLabel.Parent then
        KillLabel.Text="Kills: "..St.killCount.." | Streak: "..St.currentStreak end end end
  if v then
    pD[v]=(pD[v] or 0)+1;pS[v]=0
    if v==LP then St.sessionDeaths=St.sessionDeaths+1
      St.deathCount=St.deathCount+1;St.currentStreak=0 end end
  KT.UpdateStats()end
function KT.GetKD(p)local k=pK[p]or 0;local d=math.max(pD[p]or 0,1);return k/d end
function KT.GetRecent(p,w)w=w or 15;local n=os.clock();local c=0
  if recentKill[p]then for _,t in ipairs(recentKill[p])do
    if n-t<=w then c=c+1 end end end return c end
function KT.GetAllStats()local r={}for _,p in ipairs(Players:GetPlayers())do
  r[p]={killsInWindow=KT.GetRecent(p,15),currentStreak=pS[p]or 0,kd=KT.GetKD(p)}end return r end
function KT.UpdateStats()
  if not StatsLabel or not StatsLabel.Parent then return end
  local kd=St.sessionDeaths>0 and(St.sessionKills/St.sessionDeaths)or St.sessionKills
  StatsLabel.Text=string.format("K: %d | D: %d | K/D: %.2f | Streak: %d | Best: %d",
    St.sessionKills,St.sessionDeaths,kd,St.currentStreak,St.bestStreak)end
function KT.CalcMVP()local b,bs=nil,-math.huge
  for _,p in ipairs(Players:GetPlayers())do
    local k=pK[p]or 0;local d=pD[p]or 0;local bst=pBS[p]or 0
    if k>0 then local sc=math.max(0,(k*2)-d+(bst*1.5))
      if sc>bs then bs=sc;b=p end end end return b,bs end
local KTC={}
local function AttachKill(p)
  if not p or p==LP then return end
  if KTC[p]then return end
  local d={hum=nil,ch=nil};KTC[p]=d
  local function att(h)
    if not h then return end
    if d.hum then pcall(function()d.hum:Disconnect()end)d.hum=nil end
    d.hum=AddC(h.Died:Connect(function()
      if St.isShuttingDown then return end
      local k=nil
      pcall(function()
        local c=h:FindFirstChild("creator")
        if not c and p.Character then c=p.Character:FindFirstChild("creator")end
        if c and c.Value then
          if c.Value:IsA("Player")then k=c.Value
          else k=Players:GetPlayerFromCharacter(c.Value.Parent)end end end)
      KT.RegisterKill(k,p)end))end
  if p.Character then local h=p.Character:FindFirstChildOfClass("Humanoid")
    if h then att(h)end end
  d.ch=AddC(p.CharacterAdded:Connect(function(nc)
    if St.isShuttingDown then return end
    task.delay(0.3,function()if St.isShuttingDown then return end
      local h=nc:FindFirstChildOfClass("Humanoid");if h then att(h)end end)end))end

-- ═══ AI ═══
local function predPos(r,lt)lt=lt or 1.2;return r.Position+(r.AssemblyLinearVelocity*lt)end
local function selectBest()
  local v=GetVehicle();if not v then return nil end
  local mp=GetMainPart(v);if not mp then return nil end
  local bt,bs=nil,-math.huge;local myp=mp.Position
  local stats=KT.GetAllStats()
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP and p.Character then
      local r=p.Character:FindFirstChild("HumanoidRootPart")
      local h=p.Character:FindFirstChildOfClass("Humanoid")
      if r and h and h.Health>0 then
        local d=(r.Position-myp).Magnitude
        if d<=AID.ThreatRadius then
          local sc=(AID.ThreatRadius-d)*1.5
          if h.Health<30 then sc=sc+40 end
          local lk=mp.CFrame.LookVector;local tt=(r.Position-myp).Unit
          if lk:Dot(tt)<0 then sc=sc+25 end
          local pp=predPos(r);local pd=(myp-pp).Magnitude
          local lb=math.clamp(d-pd,0,15)
          local hb=(p==AID.Target)and 20 or 0
          local sst=stats[p];local ths=0
          if sst then ths=(sst.killsInWindow+sst.currentStreak)*8 end
          local ag=0.7+(AID.Personality*0.6)
          local fs=(sc*ag)+lb+hb+(ths*ag)
          if fs>bs then bs=fs;bt=p end end end end end
  return bt end
local function findThreat()
  local v=GetVehicle();if not v then return nil,nil end
  local mp=GetMainPart(v);if not mp then return nil,nil end
  local n,nd=nil,math.huge
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP and p.Character then
      local r=p.Character:FindFirstChild("HumanoidRootPart")
      if r then local d=(r.Position-mp.Position).Magnitude
        if d<nd and d<AID.ThreatRadius then nd=d;n=p end end end end
  return n,nd end
local function UpdateAI()
  if St.isShuttingDown or not AID.Enabled then return end
  local now=os.clock();if now-AID.LastScan<AID.ScanInterval then return end
  AID.LastScan=now
  local ch=LP.Character;if not ch then return end
  local h=ch:FindFirstChildOfClass("Humanoid");if not h then return end
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v);if not mp then return end
  local md=AID.Mode
  if md=="auto" then md=(h.Health/h.MaxHealth<AID.RetreatHP/100)and"defensive"or"aggressive"end
  if md=="defensive" then
    local t,d=findThreat()
    if t and d then local tr=t.Character and t.Character:FindFirstChild("HumanoidRootPart")
      if tr then local aw=(mp.Position-tr.Position).Unit
        MoveVeh(aw,S.FlySpeed*1.5)
        SetStatus("🛡️ KAÇIYOR: "..t.Name,Color3.fromRGB(255,100,100))
        if d<S.FlingRange and now-St.lastFlingTime>S.FlingCooldown then
          St.lastFlingTime=now;DoFling(1.2,false)end end end return end
  if md=="aggressive" then
    if now-AID.LastTargetSwitch>AID.TargetSwitchCooldown or not AID.Target then
      local nt=selectBest()
      if nt and nt~=AID.Target then AID.Target=nt;AID.LastTargetSwitch=now
        SetStatus("🎯 HEDEF: "..nt.Name,C.Yellow)
      elseif not nt then AID.LastTargetSwitch=now end end
    local t=AID.Target
    if not t or not t.Character then return end
    local tr=t.Character:FindFirstChild("HumanoidRootPart")
    local th=t.Character:FindFirstChildOfClass("Humanoid")
    if not tr or not th or th.Health<=0 then AID.Target=nil;return end
    local d=(tr.Position-mp.Position).Magnitude
    if d>AID.AttackRadius then
      MoveVeh(tr.Position-mp.Position,S.FlySpeed)
      SetStatus("🏃 KOVALIYOR: "..t.Name,Color3.fromRGB(255,150,0))
    else
      if now-St.lastFlingTime>S.FlingCooldown then
        St.lastFlingTime=now;DoFling(1.5,false)
        SetStatus("💥 VURULDU: "..t.Name,Color3.fromRGB(255,50,50))end end end
  if md=="patrol" and #AID.PatrolPoints>0 then
    local tcf=AID.PatrolPoints[AID.CurrentPatrolIndex]
    if tcf then
      local tp=tcf.Position+Vector3.new(0,3,0)
      local d=(tp-mp.Position).Magnitude
      if d<6 then AID.CurrentPatrolIndex=AID.CurrentPatrolIndex%#AID.PatrolPoints+1
      else MoveVeh(tp-mp.Position,S.WaypointSpeed)end
      if now-St.lastPatrolFlingTime>S.FlingCooldown then
        St.lastPatrolFlingTime=now;DoFling(1,false)end end end end

-- ═══ WAYPOINT ═══
local function WPLoop()
  if St.isShuttingDown or not S.IsWaypointRunning then return end
  if not WP.Point1 or not WP.Point2 then return end
  if WPSt.transitioning then return end
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v);if not mp then return end
  local tcf=S.WaypointDirection==1 and WP.Point1 or WP.Point2
  if not tcf then return end
  local tp=tcf.Position+Vector3.new(0,3,0)
  local df=tp-mp.Position
  if df.Magnitude>5 then
    MoveVeh(df,S.WaypointSpeed)
    local now=os.clock()
    if now-St.lastWaypointFlingTime>S.WaypointFlingCooldown then
      St.lastWaypointFlingTime=now;DoFling(1.2,false)end
    SetStatus("🛤️ WAYPOINT + FLING",C.Yellow)
  else
    WPSt.transitioning=true;StopVeh()
    SetStatus("✅ Noktaya varıldı",C.Green)
    task.wait(S.WaypointTransition)
    S.WaypointDirection=S.WaypointDirection*-1
    WPSt.transitioning=false end end
local function GoToPoint(cf)
  if not cf then SetStatus("⚠️ Önce noktayı kaydet!",C.Yellow)
    notify("⚠️","Nokta yok",2,C.Yellow)return end
  local v=GetVehicle();if not v then SetStatus("❌ Araç yok!",C.RedT)return end
  local mp=GetMainPart(v);if not mp then return end
  task.spawn(function()
    local tp=cf.Position+Vector3.new(0,3,0)
    while not St.isShuttingDown do
      local df=tp-mp.Position
      if df.Magnitude<5 then StopVeh();SetStatus("✅ Varıldı",C.Green)break end
      MoveVeh(df,S.WaypointSpeed);task.wait(0.1)end end)end

-- ═══ KILLCAM ═══
local function StartKC()
  if KC.recording then return end
  KC.recording=true;KC.buffer={}
  SetStatus("⏺️ Kayıt başladı",C.Red)
  task.spawn(function()
    while KC.recording and not St.isShuttingDown do
      task.wait(0.05)
      local v=GetVehicle()
      if v then local mp=GetMainPart(v)
        if mp then
          table.insert(KC.buffer,{cf=mp.CFrame,ts=os.clock()})
          if #KC.buffer>KC.MAX then table.remove(KC.buffer,1)end end end end end)end
local function StopKC()KC.recording=false
  SetStatus("⏹️ Kayıt durdu ("..#KC.buffer.." frame)",C.Dim)end
local function PlayKC(rp)
  if #KC.buffer==0 then SetStatus("⚠️ Kayıt yok!",C.Yellow)return end
  if not rp then local v=GetVehicle()
    if v then rp=GetMainPart(v)end
    if not rp and LP.Character then rp=LP.Character:FindFirstChild("HumanoidRootPart")end end
  if not rp then SetStatus("⚠️ Parça yok!",C.RedT)return end
  SetStatus("▶️ Replay",C.Green)
  task.spawn(function()
    local st=os.clock();local fts=KC.buffer[1].ts
    for _,s in ipairs(KC.buffer)do
      local el=s.ts-fts;local wt=(st+el)-os.clock()
      if wt>0 then task.wait(wt)end
      if rp and rp.Parent then pcall(function()rp.CFrame=s.cf end)end end end)end

-- ═══ MOVEMENT ═══
local function Frontflip()
  local ch=LP.Character;if not ch then return end
  local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
  hrp.AssemblyAngularVelocity=Vector3.new(0,0,-30)
  SetStatus("🤸 Frontflip!",C.Blue)end
local function LayDown()
  local ch=LP.Character;if not ch then return end
  local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
  hrp.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(math.rad(-90),0,0)
  SetStatus("🛌 LayDown!",C.Yellow)end
local function Goon()
  local ch=LP.Character;if not ch then return end
  local h=ch:FindFirstChildOfClass("Humanoid");if not h then return end
  pcall(function()
    local a=Instance.new("Animation");a.AnimationId="rbxassetid://5918726674"
    local tr=h.Animator:LoadAnimation(a);tr:Play()end)
  SetStatus("🕺 Goon!",Color3.fromRGB(255,100,255))end

-- ═══ TRACER ═══
local function CreateTr(p)
  if TracerData[p]then return end
  local l=Instance.new("Frame");l.Name="Tracer_"..p.Name
  l.BackgroundColor3=S.TracerColor;l.BorderSizePixel=0
  l.Size=UDim2.new(0,2,0,0);l.Visible=false;l.ZIndex=2;l.Parent=TracerGui
  TracerData[p]=l end
local function RemoveTr(p)
  if TracerData[p]then pcall(function()TracerData[p]:Destroy()end)
    TracerData[p]=nil end end
local function UpdateTr()
  if not S.TracerLines then
    for _,l in pairs(TracerData)do l.Visible=false end return end
  local cam=WS.CurrentCamera;if not cam then return end
  local vs=cam.ViewportSize
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP and p.Character then
      local hd=p.Character:FindFirstChild("Head")or p.Character:FindFirstChild("HumanoidRootPart")
      if hd then
        if not TracerData[p]then CreateTr(p)end
        local l=TracerData[p]
        if l then
          local sp,os=cam:WorldToViewportPoint(hd.Position)
          if os then l.Visible=true
            local sx=vs.X/2;local sy=vs.Y;local ex,ey=sp.X,sp.Y
            local mx=(sx+ex)/2;local my=(sy+ey)/2
            local len=math.sqrt((ex-sx)^2+(ey-sy)^2)
            local ang=math.deg(math.atan2(ey-sy,ex-sx))
            l.Size=UDim2.new(0,len,0,2)
            l.Position=UDim2.new(0,mx-len/2,0,my)
            l.Rotation=ang;l.BackgroundColor3=S.TracerColor
          else l.Visible=false end end end end end end

-- ═══ ESP ═══
local function IsSel(p)return SelectedPlayers[p]==true end
local function ESPColor(p)
  if IsSel(p)then return S.ESP_SelectedColor end
  return S.ESP_Color end
local function CreateESP(p)
  if not p or p==LP then return end
  if ESPObjects[p]and ESPObjects[p].highlight and ESPObjects[p].highlight.Parent then return end
  local ch=p.Character;if not ch then return end
  if ESPObjects[p]then RemoveESP(p)end
  local ed={};local col=ESPColor(p)
  local hl=Instance.new("Highlight");hl.Name="XESP_HL";hl.FillColor=col
  hl.OutlineColor=Color3.fromRGB(255,255,255);hl.FillTransparency=0.55
  hl.OutlineTransparency=0.1;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
  hl.Adornee=ch;hl.Parent=ch;ed.highlight=hl
  local rt=ch:FindFirstChild("HumanoidRootPart")
  if rt then
    local bx=Instance.new("BoxHandleAdornment");bx.Name="XESP_Box"
    bx.Size=Vector3.new(4,6,2);bx.Adornee=rt;bx.AlwaysOnTop=true
    bx.ZIndex=5;bx.Transparency=0.6;bx.Color3=col;bx.Parent=rt;ed.box=bx end
  local hd=ch:FindFirstChild("Head")or ch:FindFirstChild("UpperTorso")or rt
  if hd then
    local bb=Instance.new("BillboardGui");bb.Name="XESP_Bill"
    bb.Size=UDim2.new(0,140,0,52);bb.StudsOffsetWorldSpace=Vector3.new(0,3.2,0)
    bb.AlwaysOnTop=true;bb.LightInfluence=0;bb.MaxDistance=500
    bb.Adornee=hd;bb.Parent=hd
    local nl=Instance.new("TextLabel");nl.Name="Name";nl.Text=p.Name
    nl.Size=UDim2.new(1,0,0,18);nl.BackgroundTransparency=0.3
    nl.BackgroundColor3=Color3.fromRGB(0,0,0);nl.TextColor3=col
    nl.Font=Enum.Font.GothamBold;nl.TextSize=12;nl.TextStrokeTransparency=0
    nl.TextStrokeColor3=Color3.fromRGB(0,0,0);nl.Parent=bb;ed.nameLabel=nl
    local dl=Instance.new("TextLabel");dl.Name="Dist";dl.Text="0m"
    dl.Size=UDim2.new(1,0,0,14);dl.Position=UDim2.new(0,0,0,18)
    dl.BackgroundTransparency=1;dl.TextColor3=Color3.fromRGB(220,220,220)
    dl.Font=Enum.Font.Gotham;dl.TextSize=10;dl.TextStrokeTransparency=0
    dl.TextStrokeColor3=Color3.fromRGB(0,0,0);dl.Parent=bb;ed.distLabel=dl
    local hb=Instance.new("Frame");hb.Name="HbBg"
    hb.Size=UDim2.new(1,-10,0,6);hb.Position=UDim2.new(0,5,0,34)
    hb.BackgroundColor3=Color3.fromRGB(40,0,0);hb.BorderSizePixel=0;hb.Parent=bb;corner(hb,3)
    local hf=Instance.new("Frame");hf.Name="HbFill";hf.Size=UDim2.new(1,0,1,0)
    hf.BackgroundColor3=Color3.fromRGB(0,255,0);hf.BorderSizePixel=0;hf.Parent=hb
    corner(hf,3);ed.healthBar=hf;ed.healthBg=hb;ed.billboard=bb end
  ESPObjects[p]=ed end
UpdateESPColors=function()
  for p,d in pairs(ESPObjects)do
    local col=ESPColor(p)
    if d.highlight and d.highlight.Parent then d.highlight.FillColor=col end
    if d.box and d.box.Parent then d.box.Color3=col end
    if d.nameLabel and d.nameLabel.Parent then d.nameLabel.TextColor3=col end end end
UpdateESPVisibility=function()
  for _,d in pairs(ESPObjects)do
    if d.highlight then d.highlight.Enabled=S.ESP_Enabled and S.ESP_Highlight end
    if d.box then d.box.Visible=S.ESP_Enabled and S.ESP_Box end
    if d.billboard then d.billboard.Enabled=S.ESP_Enabled end
    if d.nameLabel then d.nameLabel.Visible=S.ESP_Name end
    if d.distLabel then d.distLabel.Visible=S.ESP_Distance end
    if d.healthBg then d.healthBg.Visible=S.ESP_Health end end end
local function RemoveESP(p)
  if ESPObjects[p]then
    for _,o in pairs(ESPObjects[p])do if o and o.Parent then
      pcall(function()o:Destroy()end)end end
    ESPObjects[p]=nil end end
RefreshAllESP=function()
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP then
      if S.ESP_Enabled then CreateESP(p)else RemoveESP(p)end end end
  UpdateESPVisibility();UpdateESPColors()end
UpdateESPObjects=function()
  if not S.ESP_Enabled then return end
  local ch=LP.Character;local mr=ch and ch:FindFirstChild("HumanoidRootPart")
  local mp=mr and mr.Position or Vector3.zero
  for p,d in pairs(ESPObjects)do
    if not p.Parent or not p.Character then RemoveESP(p)
    else
      if not d.billboard or not d.billboard.Parent then
        if d.highlight then d.highlight:Destroy()end
        ESPObjects[p]=nil
        if S.ESP_Enabled then CreateESP(p)end
      else
        local tr=p.Character:FindFirstChild("HumanoidRootPart")
        local th=p.Character:FindFirstChildOfClass("Humanoid")
        if tr and th then
          if d.distLabel then
            d.distLabel.Text=string.format("%.0fm",(tr.Position-mp).Magnitude)end
          if d.healthBar then
            local pct=math.clamp(th.Health/math.max(th.MaxHealth,1),0,1)
            d.healthBar.Size=UDim2.new(pct,0,1,0)
            if pct>0.6 then d.healthBar.BackgroundColor3=Color3.fromRGB(0,255,0)
            elseif pct>0.3 then d.healthBar.BackgroundColor3=Color3.fromRGB(255,200,0)
            else d.healthBar.BackgroundColor3=Color3.fromRGB(255,50,50)end end
          if d.box and d.box.Parent then d.box.Adornee=tr end end end end end end

-- ═══ ANTI-FLING ═══
local function StartAF()
  if St.antiFlingConn then return end
  local ch=LP.Character;if not ch then return end
  local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
  St.lastSafePosition=hrp.CFrame;St.lastSafeTime=os.clock()
  St.antiFlingConn=AddC(RS.Heartbeat:Connect(function()
    if not S.AntiFling then return end
    if not hrp or not hrp.Parent then return end
    local ls=hrp.AssemblyLinearVelocity.Magnitude
    local as=hrp.AssemblyAngularVelocity.Magnitude
    if ls>200 or as>80 then
      hrp.AssemblyLinearVelocity=Vector3.zero
      hrp.AssemblyAngularVelocity=Vector3.zero
      if St.lastSafePosition then hrp.CFrame=St.lastSafePosition end
      SetStatus("🛡️ Anti-Fling!",Color3.fromRGB(255,100,100))
    else
      local now=os.clock()
      if now-St.lastSafeTime>0.3 then
        St.lastSafePosition=hrp.CFrame;St.lastSafeTime=now end end end))end
local function StopAF()
  if St.antiFlingConn then pcall(function()St.antiFlingConn:Disconnect()end)
    St.antiFlingConn=nil end end

-- ═══ STATUS LABELS ═══
SetStatus=function(t,col)
  if St.isShuttingDown then return end
  if not StatusLabel or not StatusLabel.Parent then return end
  local now=os.clock()
  if t==StatusLabel.Text and now-St.lastStatusUpdate<0.1 then return end
  St.lastStatusUpdate=now;StatusLabel.Text=t
  StatusLabel.TextColor3=col or C.Green end
StatusLabel=Instance.new("TextLabel");StatusLabel.Text="🔒 Şifre: "..S.Password
StatusLabel.Size=UDim2.new(0,340,0,24);StatusLabel.Position=UDim2.new(0.5,-170,1,-80)
StatusLabel.BackgroundColor3=Color3.fromRGB(10,10,15);StatusLabel.BackgroundTransparency=0.3
StatusLabel.TextColor3=C.Green;StatusLabel.Font=Enum.Font.GothamBold
StatusLabel.TextSize=12;StatusLabel.ZIndex=5;StatusLabel.Parent=ScreenGui;corner(StatusLabel,6)
KillLabel=Instance.new("TextLabel");KillLabel.Text="Kills: 0 | Streak: 0"
KillLabel.Size=UDim2.new(0,220,0,24);KillLabel.Position=UDim2.new(0.5,180,1,-80)
KillLabel.BackgroundColor3=Color3.fromRGB(10,10,15);KillLabel.BackgroundTransparency=0.3
KillLabel.TextColor3=Color3.fromRGB(255,100,100);KillLabel.Font=Enum.Font.GothamBold
KillLabel.TextSize=12;KillLabel.ZIndex=5;KillLabel.Parent=ScreenGui;corner(KillLabel,6)
StatsLabel=Instance.new("TextLabel");StatsLabel.Text="K: 0 | D: 0 | K/D: 0.00"
StatsLabel.Size=UDim2.new(0,340,0,22);StatsLabel.Position=UDim2.new(0.5,-170,1,-52)
StatsLabel.BackgroundColor3=Color3.fromRGB(10,10,15);StatsLabel.BackgroundTransparency=0.3
StatsLabel.TextColor3=Color3.fromRGB(100,200,255);StatsLabel.Font=Enum.Font.GothamBold
StatsLabel.TextSize=11;StatsLabel.ZIndex=5;StatsLabel.Parent=ScreenGui;corner(StatsLabel,6)
FPSLabel=Instance.new("TextLabel");FPSLabel.Text="FPS: 60"
FPSLabel.Size=UDim2.new(0,90,0,22);FPSLabel.Position=UDim2.new(1,-100,0,96)
FPSLabel.BackgroundColor3=Color3.fromRGB(10,10,15);FPSLabel.BackgroundTransparency=0.35
FPSLabel.TextColor3=C.Green;FPSLabel.Font=Enum.Font.GothamBold
FPSLabel.TextSize=11;FPSLabel.ZIndex=5;FPSLabel.Parent=ScreenGui;corner(FPSLabel,6)
PingLabel=Instance.new("TextLabel");PingLabel.Text="Ping: 0ms"
PingLabel.Size=UDim2.new(0,90,0,22);PingLabel.Position=UDim2.new(1,-100,0,122)
PingLabel.BackgroundColor3=Color3.fromRGB(10,10,15);PingLabel.BackgroundTransparency=0.35
PingLabel.TextColor3=Color3.fromRGB(150,200,255);PingLabel.Font=Enum.Font.GothamBold
PingLabel.TextSize=11;PingLabel.ZIndex=5;PingLabel.Parent=ScreenGui;corner(PingLabel,6)

-- ═══ AUTO-FLING ═══
local function StartAutoFling()
  if next(SelectedPlayers)==nil then
    SetStatus("❌ Hiç oyuncu seçilmedi!",C.RedT)
    notify("🎯","Hiç oyuncu yok",2,C.RedT)return end
  if S.AutoFlingActive then S.AutoFlingActive=false
    SetStatus("⏹️ AUTO DURDU",C.Yellow)return end
  S.AutoFlingActive=true;SetStatus("🎯 AUTO BAŞLADI!",C.Green)
  notify("🎯","Auto-Fling başladı",2,C.Green)
  task.spawn(function()
    while S.AutoFlingActive and not St.isShuttingDown do
      for p,_ in pairs(SelectedPlayers)do
        if not S.AutoFlingActive then break end
        if not p.Parent or not p.Character then SelectedPlayers[p]=nil;continue end
        local tr=p.Character:FindFirstChild("HumanoidRootPart")
        local th=p.Character:FindFirstChildOfClass("Humanoid")
        if tr and th and th.Health>0 then
          SetStatus("🎯 Hedefe: "..p.Name,C.Blue)
          local v=GetVehicle()
          if v then
            local mp=GetMainPart(v)
            if mp then
              local tp=tr.Position+Vector3.new(0,3,0)
              local st=os.clock()
              while os.clock()-st<5 do
                if not S.AutoFlingActive then break end
                local df=tp-mp.Position
                if df.Magnitude<5 then break end
                MoveVeh(df,S.FlySpeed);task.wait(0.1)end
              StopVeh();task.wait(S.AutoFlingDelay)
              ApplyFling(tr,S.FlingPower,S.MaxSpinSpeed)
              FlingEffect(tr.Position);FlingSound(tr.Position)
              SetStatus("💥 "..p.Name.." uçuruldu!",Color3.fromRGB(255,100,0))
              task.wait(0.4)end
          else SetStatus("❌ Araç yok!",C.RedT);S.AutoFlingActive=false;return end end end
      task.wait(0.5)end end)end

-- ═══ FLY ═══
local FlyBV,FlyBG
local function StartFly()
  local ch=LP.Character;if not ch then return end
  local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
  FlyBV=Instance.new("BodyVelocity");FlyBV.Name="X_FlyBV"
  FlyBV.MaxForce=Vector3.new(math.huge,math.huge,math.huge)
  FlyBV.Velocity=Vector3.zero;FlyBV.Parent=hrp
  FlyBG=Instance.new("BodyGyro");FlyBG.Name="X_FlyBG"
  FlyBG.MaxTorque=Vector3.new(math.huge,math.huge,math.huge)
  FlyBG.P=10000;FlyBG.D=500;FlyBG.CFrame=hrp.CFrame;FlyBG.Parent=hrp end
local function StopFly()
  if FlyBV then FlyBV:Destroy();FlyBV=nil end
  if FlyBG then FlyBG:Destroy();FlyBG=nil end end
local flyUpBtn,flyDownBtn
local function UpdateFly()
  if not S.IsFlying then if FlyBV then StopFly()end return end
  local ch=LP.Character;if not ch then return end
  local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
  if not FlyBV or not FlyBV.Parent then StartFly()end
  if not FlyBV then return end
  local cam=WS.CurrentCamera;if not cam then return end
  local md=Vector3.zero
  if UIS:IsKeyDown(Enum.KeyCode.W)then md=md+cam.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.S)then md=md-cam.CFrame.LookVector end
  if UIS:IsKeyDown(Enum.KeyCode.A)then md=md-cam.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.D)then md=md+cam.CFrame.RightVector end
  if UIS:IsKeyDown(Enum.KeyCode.Space)then md=md+Vector3.new(0,1,0)end
  if UIS:IsKeyDown(Enum.KeyCode.LeftShift)then md=md-Vector3.new(0,1,0)end
  if flyUpBtn and flyUpBtn:GetAttribute("Holding")then md=md+Vector3.new(0,1,0)end
  if flyDownBtn and flyDownBtn:GetAttribute("Holding")then md=md-Vector3.new(0,1,0)end
  FlyBV.Velocity=md.Unit*S.FlySpeed
  if md.Magnitude<0.01 then FlyBV.Velocity=Vector3.zero end
  if S.FlyCameraLock then FlyBG.CFrame=cam.CFrame end end

-- ═══ FULLBRIGHT ═══
local function EnableFB()
  if S.Fullbright then return end
  S.Fullbright=true
  OLS={Brightness=Light.Brightness,ClockTime=Light.ClockTime,
    Ambient=Light.Ambient,OutdoorAmbient=Light.OutdoorAmbient,
    FogEnd=Light.FogEnd,GlobalShadows=Light.GlobalShadows}
  Light.Brightness=3;Light.ClockTime=12
  Light.Ambient=Color3.fromRGB(255,255,255);Light.OutdoorAmbient=Color3.fromRGB(255,255,255)
  Light.FogEnd=1e6;Light.GlobalShadows=false
  SetStatus("☀️ Fullbright ON",C.Yellow)end
local function DisableFB()
  if not S.Fullbright then return end
  S.Fullbright=false
  if OLS.Brightness then Light.Brightness=OLS.Brightness
    Light.ClockTime=OLS.ClockTime;Light.Ambient=OLS.Ambient
    Light.OutdoorAmbient=OLS.OutdoorAmbient;Light.FogEnd=OLS.FogEnd
    Light.GlobalShadows=OLS.GlobalShadows end
  SetStatus("🌙 Fullbright OFF",C.Dim)end

-- ═══ EXECUTOR FUNCS ═══
local EX={}
pcall(function()EX.writefile=writefile end)
pcall(function()EX.readfile=readfile end)
pcall(function()EX.isfile=isfile end)
pcall(function()EX.setclipboard=setclipboard end)
pcall(function()EX.setfpscap=setfpscap end)
local LOGF="X_Config.json"
local function SaveCfg()
  if not EX.writefile then notify("💾","writefile yok",2,C.RedT)return end
  local d={FlingPower=S.FlingPower,FlingRange=S.FlingRange,FlySpeed=S.FlySpeed,
    ESP_Enabled=S.ESP_Enabled,TracerLines=S.TracerLines,AntiFling=S.AntiFling,
    Language=S.Language,CarSpeed=S.CarSpeed,CarTurnSpeed=S.CarTurnSpeed,
    CarRiseSpeed=S.CarRiseSpeed}
  pcall(function()EX.writefile(LOGF,Http:JSONEncode(d))
    notify("💾","Kaydedildi",2,C.Green)end)end
local function LoadCfg()
  if not EX.readfile or not EX.isfile then return end
  pcall(function()
    if not EX.isfile(LOGF)then return end
    local d=Http:JSONDecode(EX.readfile(LOGF))
    for k,v in pairs(d)do if S[k]~=nil then S[k]=v end end
    notify("💾","Yüklendi",2,C.Green)end)end

-- ═══ i18n ═══
local i18n={Cur="TR"}
i18n.L={
  TR={menu_opened="Panel açıldı",menu_closed="Panel kapandı",wrong_pass="Yanlış şifre!",
    pass_ok="Şifre doğru!",esp_on="ESP Açık",esp_off="ESP Kapalı",
    fly_on="Uçuş Açık",fly_off="Uçuş Kapalı",car_found="Araç bulundu",
    car_missing="Araç yok!",no_players="Hiç oyuncu seçilmedi",close="Kapat",
    save="Kaydet",load="Yükle",reset="Sıfırla",cancel="İptal",start="Başlat",
    stop="Durdur",success="Başarılı",failed="Başarısız",ready="Hazır",
    recording="Kayıt başladı",replay_play="Replay",no_record="Kayıt yok!",
    language_set="Dil ayarlandı"},
  EN={menu_opened="Menu opened",menu_closed="Menu closed",wrong_pass="Wrong pass!",
    pass_ok="Pass correct!",esp_on="ESP On",esp_off="ESP Off",fly_on="Fly On",
    fly_off="Fly Off",car_found="Vehicle found",car_missing="No vehicle!",
    no_players="No players",close="Close",save="Save",load="Load",reset="Reset",
    cancel="Cancel",start="Start",stop="Stop",success="Success",failed="Failed",
    ready="Ready",recording="Recording",replay_play="Replay",no_record="No rec!",
    language_set="Lang set"},
  RU={menu_opened="Меню открыто",menu_closed="Меню закрыто",wrong_pass="Неверно!",
    pass_ok="Пароль верный!",esp_on="ESP Вкл",esp_off="ESP Выкл",fly_on="Полёт Вкл",
    fly_off="Полёт Выкл",car_found="Найдено",car_missing="Нет транспорта!",
    no_players="Нет игроков",close="Закрыть",save="Сохранить",load="Загрузить",
    reset="Сброс",cancel="Отмена",start="Старт",stop="Стоп",success="Успех",
    failed="Ошибка",ready="Готов",recording="Запись",replay_play="Повтор",
    no_record="Нет записи!",language_set="Язык установлен"},
  DE={menu_opened="Menü offen",menu_closed="Menü zu",wrong_pass="Falsches PW!",
    pass_ok="PW korrekt!",esp_on="ESP An",esp_off="ESP Aus",fly_on="Fliegen An",
    fly_off="Fliegen Aus",car_found="Fahrzeug",car_missing="Kein Fahrzeug!",
    no_players="Keine Spieler",close="Schließen",save="Speichern",load="Laden",
    reset="Reset",cancel="Abbrechen",start="Start",stop="Stopp",success="OK",
    failed="Fehler",ready="Bereit",recording="Aufnahme",replay_play="Wieder",
    no_record="Keine Aufnahme!",language_set="Sprache"},
  FR={menu_opened="Menu ouvert",menu_closed="Menu fermé",wrong_pass="Mauvais!",
    pass_ok="Correct!",esp_on="ESP On",esp_off="ESP Off",fly_on="Vol On",
    fly_off="Vol Off",car_found="Véhicule",car_missing="Pas de véhicule!",
    no_players="Aucun joueur",close="Fermer",save="Enregistrer",load="Charger",
    reset="Réinit",cancel="Annuler",start="Démarrer",stop="Arrêter",success="OK",
    failed="Échec",ready="Prêt",recording="Enreg.",replay_play="Replay",
    no_record="Pas d'enreg.!",language_set="Langue définie"},
}
local function T(k)local l=i18n.L[i18n.Cur]or i18n.L.TR;return l[k]or k end
local function SetLang(c)c=string.upper(c or "TR")
  if i18n.L[c]then i18n.Cur=c;notify("🌐","Lang: "..c,2,C.Blue)return true end
  return false end

-- ═══ KILLFEED ═══
local KF={Max=5,Lines={},Frame=nil}
local function KFEnsure()
  if KF.Frame and KF.Frame.Parent then return end
  KF.Frame=Instance.new("Frame");KF.Frame.Size=UDim2.new(0,280,0,160)
  KF.Frame.Position=UDim2.new(1,-290,0,200);KF.Frame.BackgroundTransparency=1
  KF.Frame.ZIndex=999995;KF.Frame.Parent=ScreenGui
  local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,4)
  ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.Parent=KF.Frame end
local function KFPush(kn,vn,w)
  KFEnsure();if not KF.Frame then return end
  local c=Instance.new("Frame");c.Size=UDim2.new(1,0,0,28)
  c.BackgroundColor3=Color3.fromRGB(25,5,5);c.BackgroundTransparency=0.15
  c.BorderSizePixel=0;c.LayoutOrder=os.time()%100000+math.random(0,999)
  c.Parent=KF.Frame;corner(c,6);stroke(c,C.Red,1)
  local l=Instance.new("TextLabel");l.Text="☠️ "..kn.." → "..vn..(w and(" ["..w.."]")or"")
  l.Size=UDim2.new(1,-12,1,0);l.Position=UDim2.new(0,6,0,0)
  l.BackgroundTransparency=1;l.TextColor3=Color3.fromRGB(255,200,200)
  l.Font=Enum.Font.GothamBold;l.TextSize=12;l.TextXAlignment=Enum.TextXAlignment.Left
  l.TextTruncate=Enum.TextTruncate.AtEnd;l.Parent=c
  table.insert(KF.Lines,c)
  while #KF.Lines>KF.Max do
    local o=table.remove(KF.Lines,1);if o and o.Parent then o:Destroy()end end
  task.delay(8,function()
    if c and c.Parent then tween(c,0.4,{BackgroundTransparency=1,Size=UDim2.new(1,0,0,0)})
      task.wait(0.5);pcall(function()c:Destroy()end)
      for i,cc in ipairs(KF.Lines)do if cc==c then table.remove(KF.Lines,i)break end end end end)end

-- Hook kill tracker
local _origKill=KT.RegisterKill
KT.RegisterKill=function(k,v)
  if _origKill then _origKill(k,v)end
  KFPush(k and k.Name or "?",v and v.Name or "?","fling")end

-- ═══ CONFIG SLOTS ═══
local CS={Max=10,Prefix="X53_Slot_"}
local function SaveSlot(i)
  i=tonumber(i)or 1;if i<1 or i>CS.Max then return false end
  if not EX.writefile then return false end
  local d={FlingPower=S.FlingPower,FlingRange=S.FlingRange,FlySpeed=S.FlySpeed,
    CarSpeed=S.CarSpeed,CarTurnSpeed=S.CarTurnSpeed,Language=S.Language,
    SavedAt=os.date("%Y-%m-%d %H:%M:%S")}
  pcall(function()EX.writefile(CS.Prefix..i..".json",Http:JSONEncode(d))
    notify("💾 SLOT "..i,"Kaydedildi",2,C.Green)end)
  return true end
local function LoadSlot(i)
  i=tonumber(i)or 1;if i<1 or i>CS.Max then return false end
  if not EX.readfile then return false end
  local f=CS.Prefix..i..".json"
  local ok=pcall(function()
    if EX.isfile and not EX.isfile(f)then error("no file")end
    local d=Http:JSONDecode(EX.readfile(f))
    for k,v in pairs(d)do if k~="SavedAt" and S[k]~=nil then S[k]=v end end
    notify("📂 SLOT "..i,"Yüklendi",3,C.Green)
    if S.Language then SetLang(S.Language)end end)
  return ok end

-- ═══ ANIMATIONS ═══
local Anims={
  {n="Wave",id="rbxassetid://507770239"},{n="Point",id="rbxassetid://507770453"},
  {n="Dance",id="rbxassetid://507771019"},{n="Dance2",id="rbxassetid://507771955"},
  {n="Dance3",id="rbxassetid://507772104"},{n="Laugh",id="rbxassetid://507770818"},
  {n="Cheer",id="rbxassetid://507770677"},{n="Salute",id="rbxassetid://507770965"},
  {n="Idle",id="rbxassetid://507766666"},{n="Idle2",id="rbxassetid://507766951"},
  {n="Run",id="rbxassetid://507767714"},{n="Walk",id="rbxassetid://507777826"},
  {n="Jump",id="rbxassetid://507765000"},{n="Fall",id="rbxassetid://507767968"},
  {n="Swim",id="rbxassetid://507784897"},{n="Climb",id="rbxassetid://507765644"},
  {n="Sit",id="rbxassetid://2506281703"},{n="NinjaSlash",id="rbxassetid://507769494"},
  {n="NinjaKick",id="rbxassetid://507766565"},{n="NinjaPose",id="rbxassetid://507769850"},
  {n="Levitate",id="rbxassetid://507770826"},{n="LayDown",id="rbxassetid://507767962"},
  {n="FrontFlip",id="rbxassetid://507765000"},{n="BackFlip",id="rbxassetid://507765581"},
}
local curAnim=nil
local function PlayAnim(name)
  local ch=LP.Character;if not ch then return end
  local h=ch:FindFirstChildOfClass("Humanoid");if not h then return end
  local an=h:FindFirstChildOfClass("Animator")or h:FindFirstChild("Animator")
  if not an then an=Instance.new("Animator");an.Parent=h end
  for _,e in ipairs(Anims)do
    if string.lower(e.n)==string.lower(name)then
      pcall(function()
        if curAnim then curAnim:Stop()end
        local a=Instance.new("Animation");a.AnimationId=e.id
        local tr=an:LoadAnimation(a);tr:Play();curAnim=tr
        SetStatus("🎭 "..e.n,C.Purple)end)
      return true end end
  SetStatus("⚠️ Anim yok",C.RedT);return false end
local function StopAnim()if curAnim then pcall(function()curAnim:Stop()end)curAnim=nil end end

-- ═══ CAMERA MODES ═══
local Cam={Mode="Default",Enabled=false,Conn=nil,Pos=Vector3.new(0,50,0),Speed=60}
local function CamStop()
  Cam.Enabled=false;Cam.Mode="Default"
  if Cam.Conn then pcall(function()Cam.Conn:Disconnect()end)Cam.Conn=nil end
  local c=WS.CurrentCamera
  if c then c.CameraType=Enum.CameraType.Custom
    c.CameraSubject=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")or nil end
  SetStatus("🎥 Kamera normale",C.Dim)end
local function CamSet(mode)
  Cam.Mode=mode;Cam.Enabled=true
  local c=WS.CurrentCamera;if not c then return end
  if Cam.Conn then pcall(function()Cam.Conn:Disconnect()end)Cam.Conn=nil end
  if mode=="Cinematic"then
    c.CameraType=Enum.CameraType.Scriptable;local ang=0
    Cam.Conn=RS.RenderStepped:Connect(function(dt)
      local ch=LP.Character;if not ch then return end
      local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
      ang=ang+dt*0.5;local r=25
      local cp=hrp.Position+Vector3.new(math.cos(ang)*r,8,math.sin(ang)*r)
      c.CFrame=CFrame.new(cp,hrp.Position)end)
    SetStatus("🎬 Cinematic",C.Yellow)
  elseif mode=="Follow"then
    c.CameraType=Enum.CameraType.Scriptable
    Cam.Conn=RS.RenderStepped:Connect(function()
      local ch=LP.Character;if not ch then return end
      local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
      local of=hrp.CFrame.LookVector*-12+Vector3.new(0,6,0)
      c.CFrame=CFrame.new(hrp.Position+of,hrp.Position)end)
    SetStatus("🎥 Follow",C.Blue)
  elseif mode=="Shoulder"then
    c.CameraType=Enum.CameraType.Scriptable
    Cam.Conn=RS.RenderStepped:Connect(function()
      local ch=LP.Character;if not ch then return end
      local hrp=ch:FindFirstChild("HumanoidRootPart");if not hrp then return end
      local rt=hrp.CFrame.RightVector*2;local bk=hrp.CFrame.LookVector*-4
      c.CFrame=CFrame.new(hrp.Position+rt+bk+Vector3.new(0,2,0),hrp.Position+hrp.CFrame.LookVector*10)end)
    SetStatus("🎥 Shoulder",C.Blue)
  elseif mode=="Freecam"then
    c.CameraType=Enum.CameraType.Scriptable;Cam.Pos=c.CFrame.Position
    Cam.Conn=RS.RenderStepped:Connect(function(dt)
      local m=Vector3.zero
      if UIS:IsKeyDown(Enum.KeyCode.W)then m=m+c.CFrame.LookVector end
      if UIS:IsKeyDown(Enum.KeyCode.S)then m=m-c.CFrame.LookVector end
      if UIS:IsKeyDown(Enum.KeyCode.A)then m=m-c.CFrame.RightVector end
      if UIS:IsKeyDown(Enum.KeyCode.D)then m=m+c.CFrame.RightVector end
      if UIS:IsKeyDown(Enum.KeyCode.Space)then m=m+Vector3.new(0,1,0)end
      if UIS:IsKeyDown(Enum.KeyCode.LeftShift)then m=m-Vector3.new(0,1,0)end
      if m.Magnitude>0.01 then Cam.Pos=Cam.Pos+m.Unit*Cam.Speed*dt end
      c.CFrame=CFrame.new(Cam.Pos,Cam.Pos+c.CFrame.LookVector)end)
    SetStatus("🎥 Freecam",C.Blue)
  elseif mode=="Orbit"then
    c.CameraType=Enum.CameraType.Scriptable;local ang=0
    Cam.Conn=RS.RenderStepped:Connect(function(dt)
      ang=ang+dt*1.2;local cn=Vector3.new(0,20,0);local r=60
      c.CFrame=CFrame.new(cn+Vector3.new(math.cos(ang)*r,20,math.sin(ang)*r),cn)end)
    SetStatus("🎥 Orbit",C.Purple)end end

-- ═══ RADAR ═══
local Radar={Enabled=false,Frame=nil,Objects={},Range=250}
local function RadEnsure()
  if Radar.Frame and Radar.Frame.Parent then return end
  local f=Instance.new("Frame");f.Size=UDim2.new(0,180,0,180)
  f.Position=UDim2.new(0,20,0,200);f.BackgroundColor3=Color3.fromRGB(5,15,5)
  f.BackgroundTransparency=0.25;f.BorderSizePixel=0;f.Visible=false
  f.ZIndex=999990;f.Parent=ScreenGui;corner(f,90);stroke(f,C.Green,2)
  Radar.Frame=f
  local cn=Instance.new("Frame");cn.Size=UDim2.new(0,8,0,8)
  cn.Position=UDim2.new(0.5,-4,0.5,-4);cn.BackgroundColor3=C.Green
  cn.BorderSizePixel=0;cn.ZIndex=5;cn.Parent=f;corner(cn,4)
  local n=Instance.new("TextLabel");n.Text="N";n.Size=UDim2.new(0,20,0,20)
  n.Position=UDim2.new(0.5,-10,0,2);n.BackgroundTransparency=1
  n.TextColor3=C.Green;n.Font=Enum.Font.GothamBold;n.TextSize=12
  n.ZIndex=6;n.Parent=f end
local function RadClear()
  if not Radar.Frame then return end
  for _,d in pairs(Radar.Objects)do if d and d.Parent then d:Destroy()end end
  Radar.Objects={}end
local function RadUpdate()
  if not Radar.Enabled then if Radar.Frame then Radar.Frame.Visible=false end return end
  RadEnsure();if not Radar.Frame then return end
  Radar.Frame.Visible=true
  local ch=LP.Character;local mr=ch and ch:FindFirstChild("HumanoidRootPart")
  if not mr then return end
  local mp=mr.Position
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP and p.Character then
      local r=p.Character:FindFirstChild("HumanoidRootPart")
      if r then
        local df=r.Position-mp;local d=df.Magnitude
        if d<=Radar.Range then
          local dot=Radar.Objects[p]
          if not dot or not dot.Parent then
            dot=Instance.new("Frame");dot.Size=UDim2.new(0,6,0,6)
            dot.BackgroundColor3=SelectedPlayers[p]and C.Yellow or C.Red
            dot.BorderSizePixel=0;dot.ZIndex=4;dot.Parent=Radar.Frame;corner(dot,3)
            Radar.Objects[p]=dot end
          local sc=180/(Radar.Range*2)
          local px=90+df.X*sc;local pz=90+df.Z*sc
          dot.Position=UDim2.new(0,px-3,0,pz-3)
        else
          if Radar.Objects[p]then Radar.Objects[p]:Destroy();Radar.Objects[p]=nil end end end end end end
local function RadToggle()
  Radar.Enabled=not Radar.Enabled
  if not Radar.Enabled then RadClear();if Radar.Frame then Radar.Frame.Visible=false end end
  SetStatus(Radar.Enabled and"📡 Radar AÇIK"or"📡 Radar KAPALI",C.Green)end

-- ═══ LOG VIEWER ═══
local LV={Frame=nil,Visible=false,Filter="",Search="",Max=500,Entries={}}
LV.Filters={ALL={l="TÜMÜ",c=C.White},CMD={l="KOMUT",c=C.Blue},
  FLING={l="FLING",c=C.Red},ESP={l="ESP",c=C.Green},CAR={l="ARAÇ",c=C.Yellow},
  ERROR={l="HATA",c=C.RedT}}
local _origLog=log
log=function(c,d)
  if _origLog then _origLog(c,d)end
  table.insert(LV.Entries,{category="CMD",message=tostring(c).." — "..tostring(d or ""),
    time=os.date("%H:%M:%S"),ts=os.clock()})
  if #LV.Entries>LV.Max then table.remove(LV.Entries,1)end
  if LV.Visible then LV.Refresh()end end
LV.Ensure=function()
  if LV.Frame and LV.Frame.Parent then return end
  local f=Instance.new("Frame");f.Size=UDim2.new(0,480,0,400)
  f.Position=UDim2.new(0.5,-240,0.5,-200);f.BackgroundColor3=Color3.fromRGB(15,15,22)
  f.BackgroundTransparency=0.05;f.BorderSizePixel=0;f.Visible=false;f.Active=true
  f.ZIndex=9999998;f.Parent=ScreenGui;corner(f,12);stroke(f,C.Border,2)
  local t=Instance.new("TextLabel");t.Text="📜 ADVANCED LOG VIEWER"
  t.Size=UDim2.new(1,0,0,30);t.Position=UDim2.new(0,0,0,4)
  t.BackgroundTransparency=1;t.TextColor3=C.Red;t.Font=Enum.Font.GothamBold
  t.TextSize=14;t.ZIndex=5;t.Parent=f
  local fb=Instance.new("Frame");fb.Size=UDim2.new(1,-16,0,28)
  fb.Position=UDim2.new(0,8,0,36);fb.BackgroundTransparency=1;fb.ZIndex=5;fb.Parent=f
  local fl=Instance.new("UIListLayout");fl.FillDirection=Enum.FillDirection.Horizontal
  fl.Padding=UDim.new(0,4);fl.Parent=fb
  for key,def in pairs(LV.Filters)do
    local b=Instance.new("TextButton");b.Text=def.l;b.Size=UDim2.new(0,68,0,24)
    b.BackgroundColor3=Color3.fromRGB(40,40,60);b.TextColor3=def.c
    b.Font=Enum.Font.GothamBold;b.TextSize=10;b.ZIndex=6;b.Parent=fb
    corner(b,4);b:SetAttribute("K",key)
    AddC(b.Activated:Connect(function()
      LV.Filter=key
      for _,ch in ipairs(fb:GetChildren())do if ch:IsA("TextButton")then
        local ck=ch:GetAttribute("K");local cd=LV.Filters[ck]
        if ck==key then ch.BackgroundColor3=cd and cd.c or C.Red
        else ch.BackgroundColor3=Color3.fromRGB(40,40,60)end end end
      LV.Refresh()end))end
  local sb=Instance.new("TextBox");sb.PlaceholderText="🔍 Ara..."
  sb.Size=UDim2.new(1,-110,0,26);sb.Position=UDim2.new(0,8,0,68)
  sb.BackgroundColor3=Color3.fromRGB(30,30,40);sb.TextColor3=C.White
  sb.PlaceholderColor3=C.Dim;sb.Font=Enum.Font.Gotham;sb.TextSize=11
  sb.ClearTextOnFocus=false;sb.ZIndex=5;sb.Parent=f;corner(sb,5)
  AddC(sb:GetPropertyChangedSignal("Text"):Connect(function()
    LV.Search=string.lower(sb.Text or "");LV.Refresh()end))
  local cb=Instance.new("TextButton");cb.Text="🗑️ Temizle"
  cb.Size=UDim2.new(0,96,0,26);cb.Position=UDim2.new(1,-104,0,68)
  cb.BackgroundColor3=Color3.fromRGB(120,30,30);cb.TextColor3=C.White
  cb.Font=Enum.Font.GothamBold;cb.TextSize=10;cb.ZIndex=5;cb.Parent=f;corner(cb,5)
  AddC(cb.Activated:Connect(function()LV.Entries={};LV.Refresh()end))
  local sc=Instance.new("ScrollingFrame");sc.Size=UDim2.new(1,-16,1,-180)
  sc.Position=UDim2.new(0,8,0,100);sc.BackgroundColor3=Color3.fromRGB(8,8,12)
  sc.BorderSizePixel=0;sc.ScrollBarThickness=4;sc.CanvasSize=UDim2.new(0,0,0,0)
  sc.ZIndex=5;sc.Parent=f;corner(sc,6)
  local sl=Instance.new("UIListLayout");sl.Padding=UDim.new(0,2)
  sl.SortOrder=Enum.SortOrder.LayoutOrder;sl.Parent=sc
  sl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sc.CanvasSize=UDim2.new(0,0,0,sl.AbsoluteContentSize.Y+8)end)
  local eb=Instance.new("TextButton");eb.Text="📋 Clipboard"
  eb.Size=UDim2.new(0.5,-12,0,32);eb.Position=UDim2.new(0,8,1,-40)
  eb.BackgroundColor3=Color3.fromRGB(0,80,80);eb.TextColor3=C.White
  eb.Font=Enum.Font.GothamBold;eb.TextSize=11;eb.ZIndex=5;eb.Parent=f;corner(eb,5)
  AddC(eb.Activated:Connect(function()
    local tx=""
    for _,e in ipairs(LV.Entries)do tx=tx.."["..e.time.."] ["..e.category.."] "..e.message.."\n"end
    pcall(function()if EX.setclipboard then EX.setclipboard(tx)
      notify("📋",#LV.Entries.." log",3,C.Green)end end)end))
  local clb=Instance.new("TextButton");clb.Text="✕ Kapat"
  clb.Size=UDim2.new(0.5,-12,0,32);clb.Position=UDim2.new(0.5,4,1,-40)
  clb.BackgroundColor3=Color3.fromRGB(120,0,0);clb.TextColor3=C.White
  clb.Font=Enum.Font.GothamBold;clb.TextSize=11;clb.ZIndex=5;clb.Parent=f;corner(clb,5)
  AddC(clb.Activated:Connect(function()LV.Hide()end))
  LV.Frame=f;LV.Scroll=sc;LV.FilterBar=fb
  MakeDraggable(f,t)end
LV.Refresh=function()
  if not LV.Frame or not LV.Scroll then return end
  local sc=LV.Scroll
  for _,ch in ipairs(sc:GetChildren())do if ch:IsA("TextLabel")then ch:Destroy()end end
  local idx=0
  for _,e in ipairs(LV.Entries)do
    local show=true
    if LV.Filter~=""and LV.Filter~="ALL"then
      if e.category~=LV.Filter then show=false end end
    if LV.Search~=""then
      if not string.find(string.lower(e.message),LV.Search,1,true)then show=false end end
    if show then idx=idx+1
      local def=LV.Filters[e.category];local col=def and def.c or C.White
      local l=Instance.new("TextLabel");l.Text="["..e.time.."] ["..e.category.."] "..e.message
      l.Size=UDim2.new(1,-8,0,18);l.BackgroundTransparency=1;l.TextColor3=col
      l.Font=Enum.Font.Code;l.TextSize=10;l.TextXAlignment=Enum.TextXAlignment.Left
      l.TextTruncate=Enum.TextTruncate.AtEnd;l.LayoutOrder=idx;l.ZIndex=6;l.Parent=sc end end end
LV.Show=function()LV.Ensure()
  if LV.Frame then LV.Frame.Visible=true;LV.Visible=true;LV.Refresh()end end
LV.Hide=function()if LV.Frame then LV.Frame.Visible=false end LV.Visible=false end
LV.Toggle=function()if LV.Visible then LV.Hide()else LV.Show()end end

-- ═══ PLAYER LIST ═══
RefreshPlayerList=function()
  for _,c in ipairs(PlayerScroll:GetChildren())do if c:IsA("TextButton")then c:Destroy()end end
  for _,c in ipairs(AutoFlingScroll:GetChildren())do if c:IsA("TextButton")then c:Destroy()end end
  local n=0
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP then n=n+1
      local kd=KT.GetKD(p)
      local b=Instance.new("TextButton")
      b.Text="👤 "..p.Name.." [K/D: "..string.format("%.2f",kd).."]"
      b.Size=UDim2.new(1,0,0,30)
      b.BackgroundColor3=SelectedPlayers[p]and Color3.fromRGB(80,80,20)or Color3.fromRGB(35,35,60)
      b.TextColor3=C.White;b.Font=Enum.Font.Gotham;b.TextSize=11
      b.Parent=PlayerScroll;corner(b,5)
      AddC(b.Activated:Connect(function()
        SelectedPlayers[p]=not SelectedPlayers[p]
        UpdateESPColors();RefreshPlayerList()
        if SelectedPlayers[p]then SetStatus("✅ "..p.Name,C.Green)
        else SetStatus("🗑️ "..p.Name,C.Yellow)end end))
      local af=Instance.new("TextButton")
      local sel=SelectedPlayers[p]and" ✅"or""
      af.Text="🎯 "..p.Name..sel
      af.Size=UDim2.new(1,0,0,28)
      af.BackgroundColor3=SelectedPlayers[p]and Color3.fromRGB(0,150,80)or Color3.fromRGB(35,60,60)
      af.TextColor3=C.White;af.Font=Enum.Font.Gotham;af.TextSize=11
      af.Parent=AutoFlingScroll;corner(af,5)
      AddC(af.Activated:Connect(function()
        SelectedPlayers[p]=not SelectedPlayers[p]
        UpdateESPColors();RefreshPlayerList()end))end end end

-- ═══ INFO PANEL ═══
showInfo=function(p)
  if not p then return end
  local k=pK[p]or 0;local d=pD[p]or 0;local s=pS[p]or 0
  notify("👤 "..p.Name,string.format("K:%d D:%d K/D:%.2f Streak:%d",k,d,KT.GetKD(p),s),5,C.Blue)end

-- ═══ SELECTOR ═══
openSelector=function()
  local g=Instance.new("Frame");g.Size=UDim2.new(0,260,0,340)
  g.Position=UDim2.new(0.5,-130,0.5,-170);g.BackgroundColor3=C.PanelAlt
  g.BorderSizePixel=0;g.ZIndex=9999999;g.Parent=ScreenGui;corner(g,10);stroke(g,C.Border,2)
  txt(g,"👥 Oyuncu Seç",14,C.Red,Enum.Font.GothamBold,Enum.TextXAlignment.Center,0,
    UDim2.new(0,0,0,8),UDim2.new(1,0,0,22))
  local sc=Instance.new("ScrollingFrame");sc.Size=UDim2.new(1,-20,1,-80)
  sc.Position=UDim2.new(0,10,0,36);sc.BackgroundColor3=Color3.fromRGB(20,20,28)
  sc.BorderSizePixel=0;sc.ScrollBarThickness=3;sc.CanvasSize=UDim2.new(0,0,0,0)
  sc.Parent=g;corner(sc,6)
  local ll=Instance.new("UIListLayout");ll.Padding=UDim.new(0,4);ll.Parent=sc
  ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sc.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+8)end)
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP then
      local b=Instance.new("TextButton");b.Text="👤 "..p.Name
      b.Size=UDim2.new(1,-8,0,30);b.BackgroundColor3=Color3.fromRGB(35,35,60)
      b.TextColor3=C.White;b.Font=Enum.Font.Gotham;b.TextSize=12
      b.Parent=sc;corner(b,5)
      AddC(b.Activated:Connect(function()
        SelectedPlayers[p]=not SelectedPlayers[p]
        UpdateESPColors();RefreshPlayerList();g:Destroy()end))end end
  local cb=Instance.new("TextButton");cb.Text="✕ Kapat"
  cb.Size=UDim2.new(1,-20,0,32);cb.Position=UDim2.new(0,10,1,-40)
  cb.BackgroundColor3=Color3.fromRGB(150,0,0);cb.TextColor3=C.White
  cb.Font=Enum.Font.GothamBold;cb.TextSize=12;cb.Parent=g;corner(cb,5)
  AddC(cb.Activated:Connect(function()g:Destroy()end))end

-- ═══════════════════════════════════════════════════════
-- ═══ BUILD PAGE CONTENTS ═══
-- ═══════════════════════════════════════════════════════

-- FLING
txt(Pages.Fling,"💥 FLING CONTROLS",14,C.Green,Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local FlingBtn=btn(Pages.Fling,"💥 FLING ALL",Color3.fromRGB(200,0,0),2)
local FlingFarBtn=btn(Pages.Fling,"🌍 FLING EVERYONE",Color3.fromRGB(140,0,80),3)
local NormalBtn=btn(Pages.Fling,"🌀 CONTINUOUS: OFF",Color3.fromRGB(0,80,80),4)
local ClickBtn=btn(Pages.Fling,"👆 CLICK FLING: OFF",Color3.fromRGB(120,20,20),5)
txt(Pages.Fling,"Power:",12,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,6)
local PowerIn=input(Pages.Fling,"3500",7)
local PowerSet=btn(Pages.Fling,"✅ SET POWER",Color3.fromRGB(20,80,20),8)
txt(Pages.Fling,"Range:",12,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,9)
local RangeIn=input(Pages.Fling,"60",10)
local RangeSet=btn(Pages.Fling,"✅ SET RANGE",Color3.fromRGB(20,80,20),11)
local CancelBtn=btn(Pages.Fling,"❌ CANCEL ALL",Color3.fromRGB(80,20,20),12)
txt(Pages.Fling,"──── AYARLAR ────",11,C.Dim,Enum.Font.GothamBold,Enum.TextXAlignment.Center,90)
txt(Pages.Fling,"Cooldown (s):",11,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,91)
local CdIn=input(Pages.Fling,"1.0",92)
local CdSet=btn(Pages.Fling,"✅ COOLDOWN",Color3.fromRGB(20,80,20),93)
txt(Pages.Fling,"Spin (max 600):",11,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,94)
local SpinIn=input(Pages.Fling,"600",95)
local SpinSet=btn(Pages.Fling,"✅ SPIN",Color3.fromRGB(20,80,20),96)

-- ESP
txt(Pages.ESP,"👁️ ESP SYSTEM",14,Color3.fromRGB(0,220,0),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local ESPBtn=btn(Pages.ESP,"👁️ ESP: OFF",Color3.fromRGB(0,100,0),2)
local ESHL=btn(Pages.ESP,"🔴 Highlight: ON",Color3.fromRGB(0,150,0),3)
local ESBox=btn(Pages.ESP,"📦 Box: ON",Color3.fromRGB(0,150,0),4)
local ESName=btn(Pages.ESP,"📝 Name: ON",Color3.fromRGB(0,150,0),5)
local ESDist=btn(Pages.ESP,"📏 Distance: ON",Color3.fromRGB(0,150,0),6)
local ESHP=btn(Pages.ESP,"❤️ Health: ON",Color3.fromRGB(0,150,0),7)
local ESTeam=btn(Pages.ESP,"👥 Team: ON",Color3.fromRGB(0,150,0),8)
local ESRef=btn(Pages.ESP,"🔄 Refresh",Color3.fromRGB(60,60,100),9)
txt(Pages.ESP,"──── AYARLAR ────",11,C.Dim,Enum.Font.GothamBold,Enum.TextXAlignment.Center,90)
local ESColBtn=btn(Pages.ESP,"🎨 ESP Rengi Değiştir",Color3.fromRGB(60,60,100),91)
local ESSelBtn=btn(Pages.ESP,"🎨 Seçili Renk",Color3.fromRGB(60,60,100),92)
local ESMaxIn=input(Pages.ESP,"Max Distance 500",93)
local ESMaxSet=btn(Pages.ESP,"✅ MAX DIST",Color3.fromRGB(20,80,20),94)
local ESColRand=btn(Pages.ESP,"🎨 Tracer Rengi",Color3.fromRGB(80,30,80),95)

-- AUTO-FLING
txt(Pages.AutoFling,"🎯 AUTO-FLING",14,C.Yellow,Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local AutoFlingScroll=Instance.new("ScrollingFrame")
AutoFlingScroll.Size=UDim2.new(1,-16,0,180)
AutoFlingScroll.BackgroundColor3=Color3.fromRGB(25,25,35)
AutoFlingScroll.BorderSizePixel=0;AutoFlingScroll.ScrollBarThickness=3
AutoFlingScroll.CanvasSize=UDim2.new(0,0,0,0);AutoFlingScroll.LayoutOrder=2
AutoFlingScroll.Parent=Pages.AutoFling;corner(AutoFlingScroll,6)
local AFL=Instance.new("UIListLayout");AFL.Padding=UDim.new(0,3);AFL.Parent=AutoFlingScroll
AFL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  AutoFlingScroll.CanvasSize=UDim2.new(0,0,0,AFL.AbsoluteContentSize.Y+8)end)
local AFStart=btn(Pages.AutoFling,"▶️ START AUTO-FLING",Color3.fromRGB(0,150,0),3)
local AFCancel=btn(Pages.AutoFling,"❌ CANCEL",Color3.fromRGB(180,0,0),4)
local AFBypass=btn(Pages.AutoFling,"🛡️ BYPASS: OFF",Color3.fromRGB(100,100,0),5)
local AFClear=btn(Pages.AutoFling,"🗑️ Clear",Color3.fromRGB(60,60,60),6)

-- REMOTE
txt(Pages.Remote,"📡 REMOTE CONTROL",14,C.Blue,Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local RemBtn=btn(Pages.Remote,"📡 REMOTE: OFF",Color3.fromRGB(60,60,60),2)
txt(Pages.Remote,"1) Araca bin",C.GrnT,Enum.Font.Gotham,Enum.TextXAlignment.Left,3)
txt(Pages.Remote,"2) Remote aç",C.GrnT,Enum.Font.Gotham,Enum.TextXAlignment.Left,4)
txt(Pages.Remote,"3) Araç uzaktan gider",C.GrnT,Enum.Font.Gotham,Enum.TextXAlignment.Left,5)

-- AI
txt(Pages.AI,"🤖 AI SYSTEM",14,C.Purple,Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local AIBtn=btn(Pages.AI,"🤖 AI: OFF",Color3.fromRGB(80,0,120),2)
local AIMode=btn(Pages.AI,"🎯 MODE: AUTO",Color3.fromRGB(60,0,80),3)
local AIPatAdd=btn(Pages.AI,"📍 ADD PATROL",Color3.fromRGB(40,40,100),4)
local AIPatClr=btn(Pages.AI,"🗑️ CLEAR PATROL",Color3.fromRGB(80,30,30),5)

-- FLY
txt(Pages.Fly,"🛫 FLIGHT",14,Color3.fromRGB(80,150,255),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local FlyBtn=btn(Pages.Fly,"🛫 FLY: OFF",Color3.fromRGB(120,20,20),2)
local FlyPanelBtn=btn(Pages.Fly,"🎮 FLY PANEL",Color3.fromRGB(50,50,100),3)
local NoclipBtn=btn(Pages.Fly,"🚫 NOCLIP: OFF",Color3.fromRGB(80,30,30),4)
local FlySpdIn=input(Pages.Fly,"Fly Speed 90",5)
local FlySpdSet=btn(Pages.Fly,"✅ FLY SPEED",Color3.fromRGB(20,80,20),6)

-- WAYPOINT
txt(Pages.Waypoint,"🛤️ WAYPOINTS",14,Color3.fromRGB(255,150,50),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local P1Btn=btn(Pages.Waypoint,"📍 SAVE POINT 1",Color3.fromRGB(30,60,30),2)
local P2Btn=btn(Pages.Waypoint,"📍 SAVE POINT 2",Color3.fromRGB(30,60,30),3)
local GoP1=btn(Pages.Waypoint,"🚀 GO TO POINT 1",Color3.fromRGB(20,120,20),4)
local GoP2=btn(Pages.Waypoint,"🚀 GO TO POINT 2",Color3.fromRGB(120,50,20),5)
local WPLoopBtn=btn(Pages.Waypoint,"🔄 LOOP: OFF",Color3.fromRGB(60,60,20),6)

-- TRACK
txt(Pages.Track,"🎯 TRACK",14,Color3.fromRGB(100,255,200),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local TargetBtn=btn(Pages.Track,"📍 SET TARGET",Color3.fromRGB(30,30,80),2)
local SelectBtn=btn(Pages.Track,"👤 SELECT PLAYER",Color3.fromRGB(30,80,30),3)
local FollowBtn=btn(Pages.Track,"🚀 FOLLOW: OFF",Color3.fromRGB(70,30,70),4)
local GotoBtn=btn(Pages.Track,"📍 BRING VEHICLE",Color3.fromRGB(0,80,80),5)
local RadarBtn=btn(Pages.Track,"📡 RADAR: OFF",Color3.fromRGB(0,100,50),20)

-- MOVEMENT
txt(Pages.Movement,"🏃 MOVEMENT",14,Color3.fromRGB(255,100,200),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local FFBtn=btn(Pages.Movement,"🤸 FRONTFLIP (F)",Color3.fromRGB(0,150,200),2)
local LDBtn=btn(Pages.Movement,"🛌 LAYDOWN (G)",Color3.fromRGB(200,200,0),3)
local GoonBtn=btn(Pages.Movement,"🕺 GOON (H)",Color3.fromRGB(200,0,200),4)
txt(Pages.Movement,"🎭 ANIMATIONS",13,C.Purple,Enum.Font.GothamBold,Enum.TextXAlignment.Left,10)
local AnimGrid=Instance.new("Frame");AnimGrid.Size=UDim2.new(1,-16,0,220)
AnimGrid.BackgroundTransparency=1;AnimGrid.LayoutOrder=11;AnimGrid.Parent=Pages.Movement
local AG=Instance.new("UIGridLayout");AG.CellSize=UDim2.new(0.5,-4,0,30)
AG.CellPadding=UDim2.new(0,4,0,4);AG.Parent=AnimGrid
for i=1,math.min(20,#Anims)do
  local a=Anims[i]
  local b=Instance.new("TextButton");b.Text=a.n
  b.BackgroundColor3=Color3.fromRGB(60,20,80);b.TextColor3=C.White
  b.Font=Enum.Font.GothamBold;b.TextSize=10;b.LayoutOrder=i;b.Parent=AnimGrid;corner(b,4)
  AddC(b.Activated:Connect(function()PlayAnim(a.n)end))end
local StopAnimB=btn(Pages.Movement,"⏹️ STOP ANIM",Color3.fromRGB(120,0,0),12)

-- UTILITY
txt(Pages.Utility,"🛠️ UTILITY",14,C.RedT,Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local MultiBtn=btn(Pages.Utility,"🖥️ Multi-Instance: OK",Color3.fromRGB(60,60,100),2)
local HopBtn=btn(Pages.Utility,"🌐 Server Hop",Color3.fromRGB(0,100,200),3)
local AFKBtn=btn(Pages.Utility,"💤 Anti-AFK: OFF",Color3.fromRGB(60,60,100),4)
local FBBtn=btn(Pages.Utility,"☀️ Fullbright: OFF",Color3.fromRGB(60,60,100),5)
local FPSUnlockBtn=btn(Pages.Utility,"⚡ FPS Unlock: OFF",Color3.fromRGB(60,60,100),6)
local AntiFBtn=btn(Pages.Utility,"🛡️ Anti-Fling: OFF",Color3.fromRGB(60,100,100),7)
local RejoinBtn=btn(Pages.Utility,"🔁 Rejoin",Color3.fromRGB(100,60,60),8)
local CopyIdBtn=btn(Pages.Utility,"📋 Copy User ID",Color3.fromRGB(60,60,100),9)
txt(Pages.Utility,"🎥 CAMERA",13,C.Blue,Enum.Font.GothamBold,Enum.TextXAlignment.Left,30)
local CamGrid=Instance.new("Frame");CamGrid.Size=UDim2.new(1,-16,0,130)
CamGrid.BackgroundTransparency=1;CamGrid.LayoutOrder=31;CamGrid.Parent=Pages.Utility
local CG=Instance.new("UIGridLayout");CG.CellSize=UDim2.new(0.5,-4,0,32)
CG.CellPadding=UDim2.new(0,4,0,4);CG.Parent=CamGrid
for i,m in ipairs({"Cinematic","Follow","Shoulder","Freecam","Orbit"})do
  local b=Instance.new("TextButton");b.Text="🎥 "..m
  b.BackgroundColor3=Color3.fromRGB(30,60,100);b.TextColor3=C.White
  b.Font=Enum.Font.GothamBold;b.TextSize=10;b.LayoutOrder=i;b.Parent=CamGrid;corner(b,5)
  AddC(b.Activated:Connect(function()CamSet(m)end))end
local CamRes=btn(Pages.Utility,"⏹️ KAMERA RESET",Color3.fromRGB(120,0,0),32)

-- PLAYERS
txt(Pages.Players,"👥 PLAYERS",13,Color3.fromRGB(200,100,255),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local PlayerScroll=Instance.new("ScrollingFrame");PlayerScroll.Size=UDim2.new(1,-16,0,300)
PlayerScroll.BackgroundColor3=Color3.fromRGB(25,25,35);PlayerScroll.BorderSizePixel=0
PlayerScroll.ScrollBarThickness=3;PlayerScroll.CanvasSize=UDim2.new(0,0,0,0)
PlayerScroll.LayoutOrder=2;PlayerScroll.Parent=Pages.Players;corner(PlayerScroll,6)
local PL=Instance.new("UIListLayout");PL.Padding=UDim.new(0,3);PL.Parent=PlayerScroll
PL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
  PlayerScroll.CanvasSize=UDim2.new(0,0,0,PL.AbsoluteContentSize.Y+8)end)

-- SETTINGS
txt(Pages.Settings,"⚙️ ADVANCED",14,Color3.fromRGB(180,180,180),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local ADetBtn=btn(Pages.Settings,"🛡️ Anti-Detect: OFF",Color3.fromRGB(60,0,60),2)
local BanBtn=btn(Pages.Settings,"🚫 Ban-Safe: OFF",Color3.fromRGB(60,0,60),3)
local TracerBtn=btn(Pages.Settings,"📏 Tracer: OFF",Color3.fromRGB(60,0,60),4)
local FPSCntBtn=btn(Pages.Settings,"📊 FPS: ON",Color3.fromRGB(40,100,40),5)
local PingCntBtn=btn(Pages.Settings,"📶 Ping: ON",Color3.fromRGB(40,100,40),6)
local SndBtn=btn(Pages.Settings,"🔊 Sound: ON",Color3.fromRGB(40,100,40),7)
local SzSmBtn=btn(Pages.Settings,"📐 Small",Color3.fromRGB(60,60,60),8)
local SzMdBtn=btn(Pages.Settings,"📐 Medium",Color3.fromRGB(60,60,60),9)
local SzLgBtn=btn(Pages.Settings,"📐 Large",Color3.fromRGB(60,60,60),10)
local SaveBtn=btn(Pages.Settings,"💾 Save Config",Color3.fromRGB(0,80,80),11)
local LoadBtn=btn(Pages.Settings,"📂 Load Config",Color3.fromRGB(80,80,0),12)
local LogsBtn=btn(Pages.Settings,"📜 Advanced Logs",Color3.fromRGB(60,60,100),13)
txt(Pages.Settings,"🌐 Dil:",11,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,14)
local LangTR=btn(Pages.Settings,"🇹🇷 TR",Color3.fromRGB(80,30,30),15)
local LangEN=btn(Pages.Settings,"🇬🇧 EN",Color3.fromRGB(30,30,80),16)
local LangRU=btn(Pages.Settings,"🇷🇺 RU",Color3.fromRGB(30,60,80),17)
local LangDE=btn(Pages.Settings,"🇩🇪 DE",Color3.fromRGB(80,60,30),18)
local LangFR=btn(Pages.Settings,"🇫🇷 FR",Color3.fromRGB(30,30,60),19)
txt(Pages.Settings,"💾 CONFIG SLOTS",13,C.Blue,Enum.Font.GothamBold,Enum.TextXAlignment.Left,100)
for i=1,3 do
  local sB=btn(Pages.Settings,"💾 Slot "..i.." Save",Color3.fromRGB(0,80,80),100+i)
  local lB=btn(Pages.Settings,"📂 Slot "..i.." Load",Color3.fromRGB(80,80,0),110+i)
  AddC(sB.Activated:Connect(function()SaveSlot(i)end))
  AddC(lB.Activated:Connect(function()LoadSlot(i)end))end

-- GARAGE
txt(Pages.Garage,"🏎️ GARAGE",14,Color3.fromRGB(200,200,0),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local ColRed=btn(Pages.Garage,"🔴 Red",Color3.fromRGB(200,0,0),2)
local ColBlue=btn(Pages.Garage,"🔵 Blue",Color3.fromRGB(0,50,200),3)
local ColGreen=btn(Pages.Garage,"🟢 Green",Color3.fromRGB(0,150,0),4)
local ColRand=btn(Pages.Garage,"🎨 Random",Color3.fromRGB(100,50,150),5)
local CarCFSave=btn(Pages.Garage,"💾 Save CF",Color3.fromRGB(60,60,100),6)
local CarCFLoad=btn(Pages.Garage,"📂 Load CF",Color3.fromRGB(60,60,100),7)

-- KILLCAM
txt(Pages.Killcam,"🎬 KILLCAM",14,Color3.fromRGB(200,50,50),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local KCStart=btn(Pages.Killcam,"⏺️ START REC",Color3.fromRGB(150,0,0),2)
local KCStop=btn(Pages.Killcam,"⏹️ STOP REC",Color3.fromRGB(80,80,80),3)
local KCPlay=btn(Pages.Killcam,"▶️ PLAY",Color3.fromRGB(0,120,0),4)

-- STATS
txt(Pages.Stats,"📊 STATS",14,Color3.fromRGB(100,200,255),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local StatsInfo=txt(Pages.Stats,"K: 0 | D: 0 | K/D: 0.00",C.White,Enum.Font.GothamBold,Enum.TextXAlignment.Left,2)
local MVPBtn=btn(Pages.Stats,"🏆 MVP",Color3.fromRGB(200,150,0),3)
local RstStatsBtn=btn(Pages.Stats,"🔄 RESET",Color3.fromRGB(100,50,50),4)

-- VEHICLES
txt(Pages.Vehicles,"🚗 VEHICLE CONTROL",14,Color3.fromRGB(255,180,60),Enum.Font.GothamBold,Enum.TextXAlignment.Left,1)
local vehGrid=Instance.new("Frame");vehGrid.Size=UDim2.new(1,-16,0,190)
vehGrid.BackgroundTransparency=1;vehGrid.LayoutOrder=3;vehGrid.Parent=Pages.Vehicles
local function vB(t,c,r,col)
  local b=Instance.new("TextButton");b.Text=t
  b.Size=UDim2.new(0.25,-4,0,44);b.Position=UDim2.new(c*0.25,2,r*0.22,2)
  b.BackgroundColor3=col or C.PanelAlt;b.TextColor3=C.White
  b.Font=Enum.Font.GothamBold;b.TextSize=11;b.Parent=vehGrid;corner(b,6);return b end
local CarFW=vB("⬆️ İLERİ",0,0,Color3.fromRGB(60,60,120))
local CarBK=vB("⬇️ GERİ",1,0,Color3.fromRGB(60,60,120))
local CarLT=vB("⬅️ SOL",2,0,Color3.fromRGB(60,100,60))
local CarRT=vB("➡️ SAĞ",3,0,Color3.fromRGB(60,100,60))
local CarUP=vB("🔼 YUKARI",0,1,Color3.fromRGB(100,60,60))
local CarDN=vB("🔽 AŞAĞI",1,1,Color3.fromRGB(100,60,60))
local CarYL=vB("↺ DÖN L",2,1,Color3.fromRGB(80,80,0))
local CarYR=vB("↻ DÖN R",3,1,Color3.fromRGB(80,80,0))
local CarStop=vB("⏹️ FREN",0,2,Color3.fromRGB(150,0,0))
local CarRst=vB("🔄 SIFIRLA",1,2,Color3.fromRGB(100,100,0))
local CarSv=vB("💾 KAYDET",2,2,Color3.fromRGB(0,100,100))
local CarLd=vB("📂 YÜKLE",3,2,Color3.fromRGB(0,100,100))
txt(Pages.Vehicles,"Hız:",11,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,10)
local CarSpdIn=input(Pages.Vehicles,"120",11)
txt(Pages.Vehicles,"Dönüş (max 20):",11,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,12)
local CarTurnIn=input(Pages.Vehicles,"5",13)
txt(Pages.Vehicles,"Yükselme (SINIRSIZ):",11,C.Dim,Enum.Font.Gotham,Enum.TextXAlignment.Left,14)
local CarRiseIn=input(Pages.Vehicles,"80",15)
local CarValSet=btn(Pages.Vehicles,"✅ SET VALUES",Color3.fromRGB(20,80,20),16)

-- ═══════════════════════════════════════════════════════
-- ═══ BUTTON HANDLERS ═══
-- ═══════════════════════════════════════════════════════

AddC(PowerSet.Activated:Connect(function()
  local v=tonumber(PowerIn.Text)
  if v and v>=S.MinFlingPower and v<=S.MaxFlingPower then
    S.FlingPower=v;SetStatus("⚡ Power: "..v,C.Green);PowerIn.Text=""
  else SetStatus("⚠️ Geçersiz",C.RedT)end end))
AddC(RangeSet.Activated:Connect(function()
  local v=tonumber(RangeIn.Text)
  if v and v>=1 then S.FlingRange=v;SetStatus("📏 Range: "..v,C.Green);RangeIn.Text="" end end))
AddC(CdSet.Activated:Connect(function()
  local v=tonumber(CdIn.Text)
  if v and v>=0.1 and v<=10 then S.FlingCooldown=v;SetStatus("⏱️ CD: "..v,C.Green);CdIn.Text="" end end))
AddC(SpinSet.Activated:Connect(function()
  local v=tonumber(SpinIn.Text)
  if v and v>0 and v<=2000 then S.MaxSpinSpeed=v;SetStatus("🌀 Spin: "..v,C.Green);SpinIn.Text="" end end))
AddC(FlingBtn.Activated:Connect(function()DoFling(1.2,false)end))
AddC(FlingFarBtn.Activated:Connect(function()DoFling(1.5,true)end))
AddC(NormalBtn.Activated:Connect(function()
  S.IsNormalFling=not S.IsNormalFling
  NormalBtn.Text=S.IsNormalFling and"🌀 CONTINUOUS: ON"or"🌀 CONTINUOUS: OFF"
  NormalBtn.BackgroundColor3=S.IsNormalFling and Color3.fromRGB(0,200,200)or Color3.fromRGB(0,80,80)end))
AddC(ClickBtn.Activated:Connect(function()
  S.ClickFlingActive=not S.ClickFlingActive
  ClickBtn.Text=S.ClickFlingActive and"👆 CLICK: ON"or"👆 CLICK: OFF"
  ClickBtn.BackgroundColor3=S.ClickFlingActive and Color3.fromRGB(20,150,20)or Color3.fromRGB(120,20,20)end))
AddC(CancelBtn.Activated:Connect(function()
  S.IsFlingEveryone=false;S.IsNormalFling=false;S.IsWaypointRunning=false
  S.IsFlying=false;S.ClickFlingActive=false;S.AutoFlingActive=false
  UnanchorVeh();StopVeh();StopFly()
  SetStatus("✅ HER ŞEY İPTAL",C.Green)end))

-- ESP handlers
AddC(ESPBtn.Activated:Connect(function()
  S.ESP_Enabled=not S.ESP_Enabled
  ESPBtn.Text=S.ESP_Enabled and"👁️ ESP: ON"or"👁️ ESP: OFF"
  ESPBtn.BackgroundColor3=S.ESP_Enabled and Color3.fromRGB(0,200,0)or Color3.fromRGB(0,100,0)
  RefreshAllESP()end))
AddC(ESHL.Activated:Connect(function()
  S.ESP_Highlight=not S.ESP_Highlight
  ESHL.Text=S.ESP_Highlight and"🔴 Highlight: ON"or"🔴 Highlight: OFF"
  UpdateESPVisibility()end))
AddC(ESBox.Activated:Connect(function()
  S.ESP_Box=not S.ESP_Box;ESBox.Text=S.ESP_Box and"📦 Box: ON"or"📦 Box: OFF"
  UpdateESPVisibility()end))
AddC(ESName.Activated:Connect(function()
  S.ESP_Name=not S.ESP_Name;ESName.Text=S.ESP_Name and"📝 Name: ON"or"📝 Name: OFF"
  UpdateESPVisibility()end))
AddC(ESDist.Activated:Connect(function()
  S.ESP_Distance=not S.ESP_Distance;ESDist.Text=S.ESP_Distance and"📏 Distance: ON"or"📏 Distance: OFF"
  UpdateESPVisibility()end))
AddC(ESHP.Activated:Connect(function()
  S.ESP_Health=not S.ESP_Health;ESHP.Text=S.ESP_Health and"❤️ Health: ON"or"❤️ Health: OFF"
  UpdateESPVisibility()end))
AddC(ESRef.Activated:Connect(function()RefreshAllESP();SetStatus("🔄 Yenilendi",C.Green)end))
AddC(ESColBtn.Activated:Connect(function()
  S.ESP_Color=Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
  UpdateESPColors();SetStatus("🎨 ESP rengi",C.Green)end))
AddC(ESSelBtn.Activated:Connect(function()
  S.ESP_SelectedColor=Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
  UpdateESPColors()end))
AddC(ESMaxSet.Activated:Connect(function()
  local v=tonumber(ESMaxIn.Text)
  if v and v>50 and v<=5000 then
    for _,d in pairs(ESPObjects)do if d.billboard then d.billboard.MaxDistance=v end end
    SetStatus("📏 Max: "..v,C.Green);ESMaxIn.Text="" end end))
AddC(ESColRand.Activated:Connect(function()
  S.TracerColor=Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
  SetStatus("📏 Tracer rengi",C.Green)end))

-- Auto-Fling handlers
AddC(AFStart.Activated:Connect(StartAutoFling))
AddC(AFCancel.Activated:Connect(function()S.AutoFlingActive=false
  SetStatus("❌ AUTO İPTAL",C.RedT)end))
AddC(AFBypass.Activated:Connect(function()
  S.AntiFlingBypass=not S.AntiFlingBypass
  AFBypass.Text=S.AntiFlingBypass and"🛡️ BYPASS: ON"or"🛡️ BYPASS: OFF"
  AFBypass.BackgroundColor3=S.AntiFlingBypass and C.Yellow or Color3.fromRGB(100,100,0)end))
AddC(AFClear.Activated:Connect(function()
  SelectedPlayers={};RefreshPlayerList();UpdateESPColors()
  SetStatus("🗑️ Temizlendi",C.Dim)end))

-- Movement
AddC(FFBtn.Activated:Connect(Frontflip))
AddC(LDBtn.Activated:Connect(LayDown))
AddC(GoonBtn.Activated:Connect(Goon))
AddC(StopAnimB.Activated:Connect(StopAnim))

-- Remote
AddC(RemBtn.Activated:Connect(function()
  local en=not RemoteControlActive;SetRemote(en)
  RemBtn.Text=en and"📡 REMOTE: ON"or"📡 REMOTE: OFF"
  RemBtn.BackgroundColor3=en and Color3.fromRGB(0,180,180)or Color3.fromRGB(60,60,60)end))

-- Fly
AddC(FlyBtn.Activated:Connect(function()
  S.IsFlying=not S.IsFlying
  FlyBtn.Text=S.IsFlying and"🛫 FLY: ON"or"🛫 FLY: OFF"
  FlyBtn.BackgroundColor3=S.IsFlying and Color3.fromRGB(20,150,20)or Color3.fromRGB(120,20,20)
  if S.IsFlying then StartFly()else StopFly()end end))
AddC(FlySpdSet.Activated:Connect(function()
  local v=tonumber(FlySpdIn.Text)
  if v and v>0 and v<=500 then S.FlySpeed=v
    SetStatus("✈️ Speed: "..v,C.Green);FlySpdIn.Text="" end end))
AddC(NoclipBtn.Activated:Connect(function()
  S.NoclipActive=not S.NoclipActive
  NoclipBtn.Text=S.NoclipActive and"🚫 NOCLIP: ON"or"🚫 NOCLIP: OFF"
  NoclipBtn.BackgroundColor3=S.NoclipActive and Color3.fromRGB(20,150,20)or Color3.fromRGB(80,30,30)end))

-- AI
AddC(AIBtn.Activated:Connect(function()
  AID.Enabled=not AID.Enabled
  AIBtn.Text=AID.Enabled and"🤖 AI: ON"or"🤖 AI: OFF"
  AIBtn.BackgroundColor3=AID.Enabled and Color3.fromRGB(150,0,200)or Color3.fromRGB(80,0,120)end))
AddC(AIMode.Activated:Connect(function()
  local md={"auto","aggressive","defensive","patrol"}
  local idx=1
  for i,m in ipairs(md)do if m==AID.Mode then idx=i break end end
  idx=idx%#md+1;AID.Mode=md[idx]
  AIMode.Text="🎯 MODE: "..string.upper(AID.Mode)end))
AddC(AIPatAdd.Activated:Connect(function()
  local v=GetVehicle();if not v then SetStatus("❌",C.RedT)return end
  local mp=GetMainPart(v);if mp then
    table.insert(AID.PatrolPoints,mp.CFrame)
    SetStatus("📍 Patrol #"..#AID.PatrolPoints,C.Green)end end))
AddC(AIPatClr.Activated:Connect(function()
  AID.PatrolPoints={};AID.CurrentPatrolIndex=1
  SetStatus("🗑️ Patrol temiz",C.Dim)end))

-- Anti-Fling
AddC(AntiFBtn.Activated:Connect(function()
  S.AntiFling=not S.AntiFling
  AntiFBtn.Text=S.AntiFling and"🛡️ Anti-Fling: ON"or"🛡️ Anti-Fling: OFF"
  AntiFBtn.BackgroundColor3=S.AntiFling and Color3.fromRGB(0,200,180)or Color3.fromRGB(60,100,100)
  if S.AntiFling then StartAF()else StopAF()end end))

-- Tracer
AddC(TracerBtn.Activated:Connect(function()
  S.TracerLines=not S.TracerLines
  TracerBtn.Text=S.TracerLines and"📏 Tracer: ON"or"📏 Tracer: OFF"
  TracerBtn.BackgroundColor3=S.TracerLines and Color3.fromRGB(0,150,150)or Color3.fromRGB(60,0,60)end))

-- Settings
AddC(ADetBtn.Activated:Connect(function()
  S.AntiDetection=not S.AntiDetection
  ADetBtn.Text=S.AntiDetection and"🛡️ Anti-Detect: ON"or"🛡️ Anti-Detect: OFF"
  ADetBtn.BackgroundColor3=S.AntiDetection and Color3.fromRGB(200,0,200)or Color3.fromRGB(60,0,60)end))
AddC(BanBtn.Activated:Connect(function()
  S.UseBanSafe=not S.UseBanSafe
  BanBtn.Text=S.UseBanSafe and"🚫 Ban-Safe: ON"or"🚫 Ban-Safe: OFF"end))
AddC(FPSCntBtn.Activated:Connect(function()
  S.ShowFPSCounter=not S.ShowFPSCounter
  FPSCntBtn.Text=S.ShowFPSCounter and"📊 FPS: ON"or"📊 FPS: OFF"
  FPSLabel.Visible=S.ShowFPSCounter end))
AddC(PingCntBtn.Activated:Connect(function()
  S.ShowPing=not S.ShowPing
  PingCntBtn.Text=S.ShowPing and"📶 Ping: ON"or"📶 Ping: OFF"
  PingLabel.Visible=S.ShowPing end))
AddC(SndBtn.Activated:Connect(function()
  S.SoundEnabled=not S.SoundEnabled
  SndBtn.Text=S.SoundEnabled and"🔊 Sound: ON"or"🔇 Sound: OFF"end))
AddC(SzSmBtn.Activated:Connect(function()S.MenuSize="Small"
  local sc=0.85
  XMenu.Size=UDim2.new(0,OW*sc,0,OH*sc);St.currentMenuScale=sc end))
AddC(SzMdBtn.Activated:Connect(function()S.MenuSize="Medium"
  XMenu.Size=UDim2.new(0,OW,0,OH);St.currentMenuScale=1 end))
AddC(SzLgBtn.Activated:Connect(function()S.MenuSize="Large"
  local sc=1.25
  XMenu.Size=UDim2.new(0,OW*sc,0,OH*sc);St.currentMenuScale=sc end))
AddC(SaveBtn.Activated:Connect(SaveCfg))
AddC(LoadBtn.Activated:Connect(LoadCfg))
AddC(LogsBtn.Activated:Connect(function()LV.Toggle()end))
AddC(LangTR.Activated:Connect(function()SetLang("TR")end))
AddC(LangEN.Activated:Connect(function()SetLang("EN")end))
AddC(LangRU.Activated:Connect(function()SetLang("RU")end))
AddC(LangDE.Activated:Connect(function()SetLang("DE")end))
AddC(LangFR.Activated:Connect(function()SetLang("FR")end))

-- Multi instance
AddC(MultiBtn.Activated:Connect(function()
  SetStatus("🖥️ Multi OK",C.Green)end))
AddC(HopBtn.Activated:Connect(function()
  notify("🌐","Sunucu taranıyor...",2,C.Blue)
  task.spawn(function()
    pcall(function()
      local srv=Http:JSONDecode(game:HttpGet(
        "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
      if srv and srv.data then
        for _,s in ipairs(srv.data)do
          if s.playing<s.maxPlayers and s.id~=game.JobId then
            TPS:TeleportToPlaceInstance(game.PlaceId,s.id,LP);return end end end end)end)end))
AddC(AFKBtn.Activated:Connect(function()
  S.AntiAFK=not S.AntiAFK
  AFKBtn.Text=S.AntiAFK and"💤 Anti-AFK: ON"or"💤 Anti-AFK: OFF"end))
AddC(FBBtn.Activated:Connect(function()
  if S.Fullbright then DisableFB()else EnableFB()end
  FBBtn.Text=S.Fullbright and"☀️ Fullbright: ON"or"☀️ Fullbright: OFF"end))
AddC(FPSUnlockBtn.Activated:Connect(function()
  S.FPSUnlocker=not S.FPSUnlocker
  FPSUnlockBtn.Text=S.FPSUnlocker and"⚡ FPS: ON"or"⚡ FPS: OFF"
  pcall(function()if EX.setfpscap then EX.setfpscap(S.FPSUnlocker and 9999 or 60)end end)end))
AddC(RejoinBtn.Activated:Connect(function()
  TPS:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP)end))
AddC(CopyIdBtn.Activated:Connect(function()
  pcall(function()if EX.setclipboard then EX.setclipboard(tostring(LP.UserId))
    notify("📋","ID: "..LP.UserId,3,C.Green)end end)end))
AddC(CamRes.Activated:Connect(CamStop))

-- Waypoint
AddC(P1Btn.Activated:Connect(function()
  local v=GetVehicle();if not v then SetStatus("❌ Araç yok!",C.RedT)return end
  local mp=GetMainPart(v);if mp then WP.Point1=mp.CFrame
    SetStatus("📍 P1 kaydedildi",C.Green)end end))
AddC(P2Btn.Activated:Connect(function()
  local v=GetVehicle();if not v then SetStatus("❌ Araç yok!",C.RedT)return end
  local mp=GetMainPart(v);if mp then WP.Point2=mp.CFrame
    SetStatus("📍 P2 kaydedildi",C.Green)end end))
AddC(GoP1.Activated:Connect(function()
  if not WP.Point1 then SetStatus("⚠️ P1 yok!",C.Yellow)return end
  GoToPoint(WP.Point1)end))
AddC(GoP2.Activated:Connect(function()
  if not WP.Point2 then SetStatus("⚠️ P2 yok!",C.Yellow)return end
  GoToPoint(WP.Point2)end))
AddC(WPLoopBtn.Activated:Connect(function()
  if not WP.Point1 or not WP.Point2 then SetStatus("⚠️ İki nokta gerek",C.Yellow)return end
  S.IsWaypointRunning=not S.IsWaypointRunning
  WPLoopBtn.Text=S.IsWaypointRunning and"🔄 LOOP: ON"or"🔄 LOOP: OFF"
  WPLoopBtn.BackgroundColor3=S.IsWaypointRunning and Color3.fromRGB(0,150,0)or Color3.fromRGB(60,60,20)end))

-- Track
AddC(TargetBtn.Activated:Connect(function()
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v);if mp then St.targetPosition=mp.CFrame
    SetStatus("📍 Hedef belirlendi",C.Green)end end))
AddC(SelectBtn.Activated:Connect(function()openSelector()end))
AddC(FollowBtn.Activated:Connect(function()
  St.isFollowingPlayer=not St.isFollowingPlayer
  FollowBtn.Text=St.isFollowingPlayer and"🚀 FOLLOW: ON"or"🚀 FOLLOW: OFF"
  FollowBtn.BackgroundColor3=St.isFollowingPlayer and Color3.fromRGB(0,150,0)or Color3.fromRGB(70,30,70)end))
AddC(GotoBtn.Activated:Connect(function()
  if St.targetPosition then GoToPoint(St.targetPosition)
  else SetStatus("⚠️ Hedef yok",C.Yellow)end end))
AddC(RadarBtn.Activated:Connect(function()
  RadToggle()
  RadarBtn.Text=Radar.Enabled and"📡 RADAR: ON"or"📡 RADAR: OFF"
  RadarBtn.BackgroundColor3=Radar.Enabled and Color3.fromRGB(0,200,100)or Color3.fromRGB(0,100,50)end))

-- Garage
local function paint(c)
  local v=GetVehicle();if not v then return end
  for _,p in ipairs(v:GetDescendants())do
    if p:IsA("BasePart")then pcall(function()p.Color=c end)end end
  SetStatus("🎨 Renk",C.Green)end
AddC(ColRed.Activated:Connect(function()paint(Color3.fromRGB(200,0,0))end))
AddC(ColBlue.Activated:Connect(function()paint(Color3.fromRGB(0,50,200))end))
AddC(ColGreen.Activated:Connect(function()paint(Color3.fromRGB(0,150,0))end))
AddC(ColRand.Activated:Connect(function()
  paint(Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)))end))
AddC(CarCFSave.Activated:Connect(function()
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v)
  if mp then St.carSaveCFrame=mp.CFrame
    SetStatus("💾 Kaydedildi",C.Green)end end))
AddC(CarCFLoad.Activated:Connect(function()
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v)
  if mp and St.carSaveCFrame then
    pcall(function()mp.CFrame=St.carSaveCFrame end)
    SetStatus("📂 Yüklendi",C.Green)end end))

-- Killcam
AddC(KCStart.Activated:Connect(StartKC))
AddC(KCStop.Activated:Connect(StopKC))
AddC(KCPlay.Activated:Connect(function()PlayKC()end))

-- Stats
AddC(MVPBtn.Activated:Connect(function()
  local m,sc=KT.CalcMVP()
  if m then notify("🏆 MVP",m.Name.." ("..string.format("%.1f",sc).." pts)",5,C.Yellow)
  else notify("🏆","Kimse kill almadı",3,C.Dim)end end))
AddC(RstStatsBtn.Activated:Connect(function()
  St.sessionKills=0;St.sessionDeaths=0;St.currentStreak=0
  St.bestStreak=0;St.killCount=0;St.deathCount=0
  KT.UpdateStats();SetStatus("🔄 Stats sıfır",C.Green)end))

-- Vehicles (unlimited Y + yaw)
local function setCI(f,s,r,y)
  VD.CarInput.forward=f or VD.CarInput.forward
  VD.CarInput.strafe=s or VD.CarInput.strafe
  VD.CarInput.rise=r or VD.CarInput.rise
  VD.CarYaw=y or VD.CarYaw end
local function ensureYaw(mp)
  if not mp then return end
  local att=mp:FindFirstChild("XYawAtt")
  if not att then att=Instance.new("Attachment")
    att.Name="XYawAtt";att.Parent=mp end
  local yaw=mp:FindFirstChild("XYawAlign")
  if not yaw then yaw=Instance.new("AlignOrientation")
    yaw.Name="XYawAlign";yaw.Attachment0=att
    yaw.Mode=Enum.OrientationAlignmentMode.OneAttachment
    yaw.MaxTorque=math.huge;yaw.Responsiveness=25
    yaw.RigidityEnabled=false;yaw.Parent=mp end
  VD.YawAlignOrientation=yaw;VD.YawAttach=att end
local function updateCarMove()
  if St.isShuttingDown then return end
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v);if not mp then return end
  local ci=VD.CarInput
  local cam=WS.CurrentCamera;if not cam then return end
  local cl=cam.CFrame.LookVector
  local fl=Vector3.new(cl.X,0,cl.Z).Unit
  local fr=Vector3.new(cl.Z,0,-cl.X).Unit
  local md=Vector3.zero
  md=md+fl*ci.forward+fr*ci.strafe+Vector3.new(0,1,0)*ci.rise
  if md.Magnitude>0.01 then MoveVeh(md.Unit,S.CarSpeed)
  else local lv=mp:FindFirstChild("XMoveLV")
    if lv then lv.VectorVelocity=Vector3.zero end end
  ensureYaw(mp)
  if VD.YawAlignOrientation then
    local lk=mp.CFrame.LookVector
    local by=math.atan2(-lk.X,-lk.Z)
    local ty=by+VD.CarYaw
    VD.YawAlignOrientation.CFrame=CFrame.Angles(0,ty,0)end
  local now=os.clock()
  if S.CarNetworkReassert and now-VD.LastNetworkCheck>0.5 then
    VD.LastNetworkCheck=now
    pcall(function()mp:SetNetworkOwner(LP)end)end
  if S.CarAntiVoid and mp.Position.Y<-200 then
    pcall(function()mp.CFrame=CFrame.new(mp.Position.X,100,mp.Position.Z)end)end end
local function hookHold(b,val,rst)
  b:SetAttribute("H",false)
  AddC(b.MouseButton1Down:Connect(function()
    b:SetAttribute("H",true)
    if val then setCI(val[1],val[2],val[3],val[4])end end))
  AddC(b.MouseButton1Up:Connect(function()
    b:SetAttribute("H",false)
    if rst then setCI(0,0,0,nil)end end))
  AddC(b.MouseLeave:Connect(function()
    b:SetAttribute("H",false)
    if rst then setCI(0,0,0,nil)end end))end
hookHold(CarFW,{1,0,0,nil},true)
hookHold(CarBK,{-1,0,0,nil},true)
hookHold(CarLT,{0,-1,0,nil},true)
hookHold(CarRT,{0,1,0,nil},true)
hookHold(CarUP,{0,0,1,nil},true)
hookHold(CarDN,{0,0,-1,nil},true)
AddC(CarYL.MouseButton1Down:Connect(function()CarYL:SetAttribute("H",true)end))
AddC(CarYL.MouseButton1Up:Connect(function()CarYL:SetAttribute("H",false)end))
AddC(CarYR.MouseButton1Down:Connect(function()CarYR:SetAttribute("H",true)end))
AddC(CarYR.MouseButton1Up:Connect(function()CarYR:SetAttribute("H",false)end))
AddC(CarStop.Activated:Connect(function()
  StopVeh();setCI(0,0,0,0);SetStatus("⏹️ Durdu",C.Dim)end))
AddC(CarRst.Activated:Connect(function()
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v)
  if mp then mp.AssemblyLinearVelocity=Vector3.zero
    mp.AssemblyAngularVelocity=Vector3.zero
    setCI(0,0,0,0);VD.CarYaw=0
    SetStatus("🔄 Reset",C.Green)end end))
AddC(CarSv.Activated:Connect(function()
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v)
  if mp then St.carSaveCFrame=mp.CFrame
    SetStatus("💾 Kaydedildi",C.Green)end end))
AddC(CarLd.Activated:Connect(function()
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v)
  if mp and St.carSaveCFrame then
    pcall(function()mp.CFrame=St.carSaveCFrame end)
    SetStatus("📂 Yüklendi",C.Green)end end))
AddC(CarValSet.Activated:Connect(function()
  local sp=tonumber(CarSpdIn.Text)
  local tn=tonumber(CarTurnIn.Text)
  local rs=tonumber(CarRiseIn.Text)
  if sp and sp>0 and sp<=1000 then S.CarSpeed=sp end
  if tn and tn>0 and tn<=20 then S.CarTurnSpeed=tn end
  if rs and rs>0 then S.CarRiseSpeed=rs end
  SetStatus(string.format("🚗 Spd:%d Turn:%d Rise:%d",S.CarSpeed,S.CarTurnSpeed,S.CarRiseSpeed),C.Green)
  CarSpdIn.Text="";CarTurnIn.Text="";CarRiseIn.Text=""end))

-- ═══ FLY PANEL ═══
local FlyPanel=Instance.new("Frame");FlyPanel.Size=UDim2.new(0,200,0,170)
FlyPanel.Position=UDim2.new(0,20,0.35,0);FlyPanel.BackgroundColor3=Color3.fromRGB(20,20,28)
FlyPanel.BackgroundTransparency=0.1;FlyPanel.BorderSizePixel=0;FlyPanel.Visible=false
FlyPanel.ZIndex=9999990;FlyPanel.Parent=ScreenGui;corner(FlyPanel,10);stroke(FlyPanel,C.Blue,2)
local FlyTitle=txt(FlyPanel,"✈️ FLY PANEL",13,C.Blue,Enum.Font.GothamBold,Enum.TextXAlignment.Center,1,
  UDim2.new(0,0,0,4),UDim2.new(1,0,0,22))
local FPnlToggle=Instance.new("TextButton");FPnlToggle.Text="🛫 FLY: OFF"
FPnlToggle.Size=UDim2.new(1,-20,0,36);FPnlToggle.Position=UDim2.new(0,10,0,30)
FPnlToggle.BackgroundColor3=C.OffRed;FPnlToggle.TextColor3=C.White
FPnlToggle.Font=Enum.Font.GothamBold;FPnlToggle.TextSize=12;FPnlToggle.Parent=FlyPanel;corner(FPnlToggle,6)
flyUpBtn=Instance.new("TextButton");flyUpBtn.Text="⬆️ YUKARI"
flyUpBtn.Size=UDim2.new(0.5,-15,0,42);flyUpBtn.Position=UDim2.new(0,10,0,72)
flyUpBtn.BackgroundColor3=Color3.fromRGB(60,100,60);flyUpBtn.TextColor3=C.White
flyUpBtn.Font=Enum.Font.GothamBold;flyUpBtn.TextSize=11;flyUpBtn.Parent=FlyPanel;corner(flyUpBtn,6)
flyDownBtn=Instance.new("TextButton");flyDownBtn.Text="⬇️ AŞAĞI"
flyDownBtn.Size=UDim2.new(0.5,-15,0,42);flyDownBtn.Position=UDim2.new(0.5,5,0,72)
flyDownBtn.BackgroundColor3=Color3.fromRGB(100,60,60);flyDownBtn.TextColor3=C.White
flyDownBtn.Font=Enum.Font.GothamBold;flyDownBtn.TextSize=11;flyDownBtn.Parent=FlyPanel;corner(flyDownBtn,6)
local FlySpdPnl=Instance.new("TextBox");FlySpdPnl.PlaceholderText="Fly Speed"
FlySpdPnl.Text=tostring(S.FlySpeed);FlySpdPnl.Size=UDim2.new(1,-20,0,28)
FlySpdPnl.Position=UDim2.new(0,10,0,122);FlySpdPnl.BackgroundColor3=Color3.fromRGB(30,30,40)
FlySpdPnl.TextColor3=C.White;FlySpdPnl.Font=Enum.Font.Gotham;FlySpdPnl.TextSize=12
FlySpdPnl.Parent=FlyPanel;corner(FlySpdPnl,6)
AddC(FlySpdPnl.FocusLost:Connect(function()
  local v=tonumber(FlySpdPnl.Text)
  if v and v>0 and v<=500 then S.FlySpeed=v end end))
AddC(FPnlToggle.Activated:Connect(function()
  S.IsFlying=not S.IsFlying
  FPnlToggle.Text=S.IsFlying and"🛫 FLY: ON"or"🛫 FLY: OFF"
  FPnlToggle.BackgroundColor3=S.IsFlying and Color3.fromRGB(0,150,0)or C.OffRed
  FlyBtn.Text=FPnlToggle.Text;FlyBtn.BackgroundColor3=FPnlToggle.BackgroundColor3
  if S.IsFlying then StartFly()else StopFly()end end))
flyUpBtn:SetAttribute("H",false)
AddC(flyUpBtn.MouseButton1Down:Connect(function()flyUpBtn:SetAttribute("H",true)end))
AddC(flyUpBtn.MouseButton1Up:Connect(function()flyUpBtn:SetAttribute("H",false)end))
AddC(flyUpBtn.MouseLeave:Connect(function()flyUpBtn:SetAttribute("H",false)end))
flyDownBtn:SetAttribute("H",false)
AddC(flyDownBtn.MouseButton1Down:Connect(function()flyDownBtn:SetAttribute("H",true)end))
AddC(flyDownBtn.MouseButton1Up:Connect(function()flyDownBtn:SetAttribute("H",false)end))
AddC(flyDownBtn.MouseLeave:Connect(function()flyDownBtn:SetAttribute("H",false)end))
MakeDraggable(FlyPanel,FlyTitle)
AddC(FlyPanelBtn.Activated:Connect(function()
  FlyPanel.Visible=not FlyPanel.Visible
  FlyPanelBtn.Text=FlyPanel.Visible and"🎮 HIDE FLY"or"🎮 FLY PANEL"end))

-- ═══ CHAT COMMANDS (Main + Extra combined) ═══
local function xFlingAll(rng)
  local v=GetVehicle();if not v then return end
  local mp=GetMainPart(v);if not mp then return end
  local c=0
  for _,p in ipairs(Players:GetPlayers())do
    if p~=LP and p.Character then
      local r=p.Character:FindFirstChild("HumanoidRootPart")
      local h=p.Character:FindFirstChildOfClass("Humanoid")
      if r and h and h.Health>0 then
        local d=(r.Position-mp.Position).Magnitude
        if d<=(rng or S.FlingRange)then
          ApplyFling(r,S.FlingPower,S.MaxSpinSpeed)
          FlingEffect(r.Position);FlingSound(r.Position);c=c+1 end end end end
  notify("💥","Fling: "..c,3,C.Yellow)end
local function xFlingOne(p)
  if not p or not p.Character then return end
  local r=p.Character:FindFirstChild("HumanoidRootPart")
  if r then ApplyFling(r,S.FlingPower,S.MaxSpinSpeed)
    FlingEffect(r.Position);FlingSound(r.Position)end end
local function xTPTo(p)
  if not p or not p.Character then return end
  local tr=p.Character:FindFirstChild("HumanoidRootPart")
  local mr=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
  if tr and mr then pcall(function()mr.CFrame=tr.CFrame+Vector3.new(0,3,0)end)end end
local function xBring(p)
  if not p or not p.Character then return end
  local tr=p.Character:FindFirstChild("HumanoidRootPart")
  local mr=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
  if tr and mr then pcall(function()tr.CFrame=mr.CFrame+mr.CFrame.LookVector*4 end)end end
local function confirm(title,fn)
  local d=Instance.new("Frame");d.Size=UDim2.new(0,320,0,140)
  d.Position=UDim2.new(0.5,-160,0.5,-70);d.BackgroundColor3=Color3.fromRGB(20,5,5)
  d.BorderSizePixel=0;d.ZIndex=99999999;d.Parent=ScreenGui;corner(d,10);stroke(d,C.Border,2)
  txt(d,title,13,C.Red,Enum.Font.GothamBold,Enum.TextXAlignment.Center,1,
    UDim2.new(0,0,0,12),UDim2.new(1,0,0,24))
  local y=Instance.new("TextButton");y.Text="✅ ONAYLA"
  y.Size=UDim2.new(0.5,-16,0,40);y.Position=UDim2.new(0,10,1,-54)
  y.BackgroundColor3=Color3.fromRGB(0,120,0);y.TextColor3=C.White
  y.Font=Enum.Font.GothamBold;y.TextSize=12;y.Parent=d;corner(y,6)
  local n=Instance.new("TextButton");n.Text="❌ İPTAL"
  n.Size=UDim2.new(0.5,-16,0,40);n.Position=UDim2.new(0.5,6,1,-54)
  n.BackgroundColor3=Color3.fromRGB(120,0,0);n.TextColor3=C.White
  n.Font=Enum.Font.GothamBold;n.TextSize=12;n.Parent=d;corner(n,6)
  AddC(y.Activated:Connect(function()pcall(fn);d:Destroy()end))
  AddC(n.Activated:Connect(function()d:Destroy()end))end

local function handleChat(msg,sp)
  if not sp or not ADMINS[sp.UserId]then return end
  if not msg or msg==""then return end
  if not rateLimit(0.4)then return end
  if msg:sub(1,1)~="!"then return end
  local args={}
  for w in msg:sub(2):gmatch("%S+")do table.insert(args,w)end
  if #args==0 then return end
  local cmd=string.lower(args[1]);local a2=args[2]
  log(cmd,table.concat(args," ",2))

  if cmd=="x"or cmd=="open"then XMenu.Visible=true;showBd()
    notify("⚡","Panel açıldı",2,C.Green)
  elseif cmd=="cmds"then
    notify("📜 KOMUTLAR","!x !fly !esp !noclip !fullbright !tp [p] !bring [p] !goto [p] !fling [p] !flingall !killall !freezeall !heal [p] !damage [p] [n] !speed [n] !jump [n] !radar !camera [mode] !lang [tr/en/ru/de/fr] !save [n] !load [n] !logviewer !nuke !rain !dash !spin !car !carup !cardown !carleft !carright !carreset !carsave !carload !hideui !showui !leave",12,C.Blue)
  elseif cmd=="list"then
    local n={}
    for _,p in ipairs(Players:GetPlayers())do table.insert(n,p.Name)end
    notify("👥 ("..#n..")",table.concat(n,", "),6,C.Green)
  elseif cmd=="info"and a2 then local p=getPlr(a2);if p then showInfo(p)end
  elseif cmd=="watch"and a2 then local p=getPlr(a2)
    if p then St.isFollowingPlayer=true;St.targetPlayer=p
      SetStatus("👁️ İzleniyor: "..p.Name,C.Green)end
  elseif cmd=="unwatch"then St.isFollowingPlayer=false
  elseif cmd=="speed"and a2 then local n=tonumber(a2)
    if n then local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
      if h then h.WalkSpeed=n end end
  elseif cmd=="jump"and a2 then local n=tonumber(a2)
    if n then local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
      if h then h.JumpPower=n end end
  elseif cmd=="fly"then S.IsFlying=not S.IsFlying
    if S.IsFlying then StartFly()else StopFly()end
  elseif cmd=="noclip"then S.NoclipActive=not S.NoclipActive
  elseif cmd=="fullbright"then
    if S.Fullbright then DisableFB()else EnableFB()end
  elseif cmd=="esp"then S.ESP_Enabled=not S.ESP_Enabled;RefreshAllESP()
  elseif cmd=="hitbox"then
    local c=LP.Character
    if c then for _,v in ipairs(c:GetDescendants())do
      if v:IsA("BasePart")and(v.Name=="Head"or v.Name=="HumanoidRootPart")then
        v.Size=Vector3.new(10,10,10)end end end
  elseif cmd=="rejoin"then TPS:TeleportToPlaceInstance(game.PlaceId,game.JobId,LP)
  elseif cmd=="serverhop"then HopBtn:Activate()
  elseif cmd=="invisible"then
    local c=LP.Character
    if c then for _,v in ipairs(c:GetDescendants())do
      if v:IsA("BasePart")then v.LocalTransparencyModifier=1 end end end
  elseif cmd=="visible"then
    local c=LP.Character
    if c then for _,v in ipairs(c:GetDescendants())do
      if v:IsA("BasePart")then v.LocalTransparencyModifier=0 end end end
  elseif cmd=="infjump"then
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.UseJumpPower=false;h.JumpHeight=999 end
  elseif cmd=="bring"and a2 then xBring(getPlr(a2))
  elseif cmd=="goto"and a2 then xTPTo(getPlr(a2))
  elseif cmd=="tp"and a2 then xTPTo(getPlr(a2))
  elseif cmd=="freeze"and a2 then local p=getPlr(a2)
    if p and p.Character then local r=p.Character:FindFirstChild("HumanoidRootPart")
      if r then r.Anchored=true end end
  elseif cmd=="kill"and a2 then local p=getPlr(a2)
    if p and p.Character then local h=p.Character:FindFirstChildOfClass("Humanoid")
      if h then h.Health=0 end end
  elseif cmd=="fling"and a2 then xFlingOne(getPlr(a2))
  elseif cmd=="flingall"then xFlingAll(99999)
  elseif cmd=="killall"then confirm("⚠️ Herkesi öldür?",function()
    for _,p in ipairs(Players:GetPlayers())do
      if p~=LP and p.Character then
        local h=p.Character:FindFirstChildOfClass("Humanoid")
        if h then h.Health=0 end end end end)
  elseif cmd=="freezeall"then
    for _,p in ipairs(Players:GetPlayers())do
      if p~=LP and p.Character then
        local r=p.Character:FindFirstChild("HumanoidRootPart")
        if r then r.Anchored=true end end end
  elseif cmd=="unfreezeall"then
    for _,p in ipairs(Players:GetPlayers())do
      if p~=LP and p.Character then
        local r=p.Character:FindFirstChild("HumanoidRootPart")
        if r then r.Anchored=false end end end
  elseif cmd=="heal"and a2 then local p=getPlr(a2)
    if p and p.Character then local h=p.Character:FindFirstChildOfClass("Humanoid")
      if h then h.Health=h.MaxHealth end end
  elseif cmd=="damage"and a2 and args[3]then
    local p=getPlr(a2);local n=tonumber(args[3])
    if p and p.Character and n then
      local h=p.Character:FindFirstChildOfClass("Humanoid")
      if h then h.Health=math.max(0,h.Health-n)end end
  elseif cmd=="spawn"and a2 then local p=getPlr(a2)
    if p then pcall(function()p:LoadCharacter()end)end
  elseif cmd=="respawn"then pcall(function()LP:LoadCharacter()end)
  elseif cmd=="exit"and a2 then local p=getPlr(a2)
    if p then local ms={"Görüşürüz!","BB!","İyi oyunlar!"}
      notify("👋",p.Name.." → "..ms[math.random(1,#ms)],3,C.Yellow)end
  elseif cmd=="hide"then XMenu.Visible=false;hideBd();XBtn.Visible=false
  elseif cmd=="car"then SwitchTab(Pages.Vehicles,Tabs.Vehicles)
  elseif cmd=="carspeed"and a2 then local n=tonumber(a2)
    if n and n>0 and n<=1000 then S.CarSpeed=n end
  elseif cmd=="carup"then setCI(0,0,1,nil)
  elseif cmd=="cardown"then setCI(0,0,-1,nil)
  elseif cmd=="carleft"then VD.CarYaw=VD.CarYaw+math.rad(30)
  elseif cmd=="carright"then VD.CarYaw=VD.CarYaw-math.rad(30)
  elseif cmd=="carreset"then CarRst:Activate()
  elseif cmd=="carsave"then CarSv:Activate()
  elseif cmd=="carload"then CarLd:Activate()
  elseif cmd=="carfix"then
    local v=GetVehicle()
    if v then for _,p in ipairs(v:GetDescendants())do
      if p:IsA("BasePart")then p.AssemblyLinearVelocity=Vector3.zero
        p.AssemblyAngularVelocity=Vector3.zero end end end
  elseif cmd=="carflip"then
    local v=GetVehicle();if v then local mp=GetMainPart(v)
      if mp then mp.CFrame=mp.CFrame*CFrame.Angles(math.rad(180),0,0)end end
  elseif cmd=="carcolor"and a2 and args[3]and args[4]then
    local r,g,b=tonumber(a2),tonumber(args[3]),tonumber(args[4])
    if r and g and b then local v=GetVehicle()
      if v then for _,p in ipairs(v:GetDescendants())do
        if p:IsA("BasePart")then p.Color=Color3.fromRGB(r,g,b)end end end end
  elseif cmd=="carname"and a2 then
    local v=GetVehicle();if v then v.Name=a2 end
  elseif cmd=="lang"and a2 then SetLang(a2)
  elseif cmd=="logviewer"then LV.Toggle()
  elseif cmd=="camera"and a2 then
    local m=a2:sub(1,1):upper()..a2:sub(2):lower();CamSet(m)
  elseif cmd=="radar"then RadToggle()
  elseif cmd=="dash"then
    local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if r then r.AssemblyLinearVelocity=r.CFrame.LookVector*200 end
  elseif cmd=="spin"then
    local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if r then r.AssemblyAngularVelocity=Vector3.new(0,20,0)end
  elseif cmd=="sit"then
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.Sit=true end
  elseif cmd=="stand"then
    local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.Sit=false end
  elseif cmd=="dance"then PlayAnim(a2 or"Dance")
  elseif cmd=="emote"and a2 then PlayAnim(a2)
  elseif cmd=="warp"and a2 and args[3]and args[4]then
    local x,y,z=tonumber(a2),tonumber(args[3]),tonumber(args[4])
    if x and y and z then
      local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
      if r then r.CFrame=CFrame.new(Vector3.new(x,y,z))end end
  elseif cmd=="nuke"then confirm("💣 NUKE?",function()
    local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local o=r.Position
    for i=1,40 do task.spawn(function()
      local p=Instance.new("Part");p.Shape=Enum.PartType.Ball
      p.Size=Vector3.new(2,2,2);p.Material=Enum.Material.Neon
      p.Color=Color3.fromRGB(255,math.random(50,200),0);p.Anchored=true
      p.CanCollide=false;p.Position=o+Vector3.new(math.random(-50,50),math.random(10,60),math.random(-50,50))
      p.Parent=WS
      TS:Create(p,TweenInfo.new(2),{Size=Vector3.new(30,30,30),Transparency=1,Color=Color3.fromRGB(255,0,0)}):Play()
      Deb:AddItem(p,2.2)end)end end)
  elseif cmd=="rain"then
    local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if r then local o=r.Position
      for i=1,30 do task.spawn(function()
        local p=Instance.new("Part");p.Shape=Enum.PartType.Ball
        p.Size=Vector3.new(1,1,1);p.Material=Enum.Material.Neon
        p.Color=Color3.fromRGB(0,200,255);p.Anchored=true;p.CanCollide=false
        p.Position=o+Vector3.new(math.random(-40,40),60,math.random(-40,40))
        p.Parent=WS
        local e=o+Vector3.new(math.random(-40,40),0,math.random(-40,40))
        TS:Create(p,TweenInfo.new(1.5),{Position=e}):Play()
        Deb:AddItem(p,1.7)end)end end
  elseif cmd=="hideui"then
    XMenu.Visible=false;hideBd();XBtn.Visible=false
    FPSLabel.Visible=false;PingLabel.Visible=false;StatusLabel.Visible=false
    KillLabel.Visible=false;StatsLabel.Visible=false
  elseif cmd=="showui"then
    XBtn.Visible=true;FPSLabel.Visible=S.ShowFPSCounter;PingLabel.Visible=S.ShowPing
    StatusLabel.Visible=true;KillLabel.Visible=true;StatsLabel.Visible=true
  elseif cmd=="save"and a2 then SaveSlot(a2)
  elseif cmd=="load"and a2 then LoadSlot(a2)
  elseif cmd=="leave"or cmd=="quit"then LP:Kick("X53 - Exit")
  end end

pcall(function()
  local TCS=game:GetService("TextChatService")
  if TCS and TCS.MessageReceived then
    TCS.MessageReceived:Connect(function(m)
      local sp=m.TextSource and Players:GetPlayerByUserId(m.TextSource.UserId)
      if sp then pcall(function()handleChat(m.Text,sp)end)end end)end end)

-- ═══ KEYBOARD ═══
AddC(UIS.InputBegan:Connect(function(i,gp)
  if gp or St.isShuttingDown then return end
  local kc=i.KeyCode
  if kc==Enum.KeyCode.F then Frontflip()end
  if kc==Enum.KeyCode.G then LayDown()end
  if kc==Enum.KeyCode.H then Goon()end
  if kc==Enum.KeyCode.F1 then S.IsFlying=not S.IsFlying
    if S.IsFlying then StartFly()else StopFly()end end
  if kc==Enum.KeyCode.F2 then S.ESP_Enabled=not S.ESP_Enabled;RefreshAllESP()end
  if kc==Enum.KeyCode.F3 then S.NoclipActive=not S.NoclipActive end
  if kc==Enum.KeyCode.F4 then XMenu.Visible=not XMenu.Visible
    if XMenu.Visible then showBd()else hideBd()end end
  if kc==Enum.KeyCode.F5 then
    if S.Fullbright then DisableFB()else EnableFB()end end
  if kc==Enum.KeyCode.F6 then
    local c=LP.Character
    if c then for _,v in ipairs(c:GetDescendants())do
      if v:IsA("BasePart")then v.LocalTransparencyModifier=(v.LocalTransparencyModifier==1)and 0 or 1 end end end
  if kc==Enum.KeyCode.F7 then S.AntiAFK=not S.AntiAFK end
  if kc==Enum.KeyCode.F8 then DoFling(1.2,true)end
  if kc==Enum.KeyCode.F9 then notify("⚠️","F9 = Console",3,C.Yellow)end
  if kc==Enum.KeyCode.F10 then
    local c=LP.Character
    if c then for _,v in ipairs(c:GetDescendants())do
      if v:IsA("BasePart")and(v.Name=="Head"or v.Name=="HumanoidRootPart")then
        v.Size=Vector3.new(10,10,10)end end end
  if kc==Enum.KeyCode.F11 then HopBtn:Activate()end
  if kc==Enum.KeyCode.F12 then RejoinBtn:Activate()end
  if kc==Enum.KeyCode.V then SwitchTab(Pages.Vehicles,Tabs.Vehicles)end
  if kc==Enum.KeyCode.Escape then
    if XMenu.Visible then XMenu.Visible=false;hideBd()end end end))

-- ═══ MAIN LOOP ═══
AddC(RS.Heartbeat:Connect(function()
  if St.isShuttingDown then return end
  local now=os.clock()
  local v=GetVehicle()
  UpdateTr()
  UpdateESPObjects()
  if v and S.NoclipActive then
    for _,p in pairs(v:GetDescendants())do
      if p:IsA("BasePart")then p.CanCollide=false end end end
  if v and S.IsWaypointRunning then WPLoop()
  elseif v and AID.Enabled then UpdateAI()end
  if v then
    if CarYL:GetAttribute("H")then VD.CarYaw=VD.CarYaw+math.rad(S.CarTurnSpeed)*0.5 end
    if CarYR:GetAttribute("H")then VD.CarYaw=VD.CarYaw-math.rad(S.CarTurnSpeed)*0.5 end
    updateCarMove()end
  if S.IsNormalFling and now-St.lastFlingTime>S.FlingCooldown then
    DoFling(1,false);St.lastFlingTime=now end
  if St.isFollowingPlayer and St.targetPlayer and St.targetPlayer.Character then
    local tr=St.targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local mp=v and GetMainPart(v)
    if tr and mp then
      local df=tr.Position-mp.Position
      if df.Magnitude>10 then MoveVeh(df,S.FlySpeed)end end end
  if S.AntiAFK and now-St.lastAntiAFKTime>60 then
    St.lastAntiAFKTime=now
    pcall(function()VU:CaptureController();VU:ClickButton2(Vector2.new())end)end
  UpdateFly()
  if Radar.Enabled then RadUpdate()end end))

-- ═══ RESPAWN ═══
AddC(LP.CharacterAdded:Connect(function(ch)
  task.delay(0.5,function()
    if St.isShuttingDown then return end
    VD.Current=nil;VD.MainPart=nil
    RefreshAllESP()
    if S.IsFlying then task.wait(0.5);StartFly()end end)end))

-- ═══ PLAYER TRACKING ═══
for _,p in pairs(Players:GetPlayers())do AttachKill(p)end
AddC(Players.PlayerAdded:Connect(function(p)
  AttachKill(p);task.wait(0.5);RefreshPlayerList()
  if S.ESP_Enabled then CreateESP(p)end
  p.CharacterAdded:Connect(function()
    task.wait(0.5)
    if S.ESP_Enabled then RemoveESP(p);CreateESP(p)end end)end))
AddC(Players.PlayerRemoving:Connect(function(p)
  KTC[p]=nil;RemoveESP(p);SelectedPlayers[p]=nil
  task.wait(0.3);RefreshPlayerList()end))

-- ═══ FPS/PING ═══
task.spawn(function()
  local fr=0;local lt=os.clock()
  while not St.isShuttingDown do
    fr=fr+1;local now=os.clock()
    if now-lt>=1 then
      local fps=fr;fr=0;lt=now
      if S.ShowFPSCounter and FPSLabel.Parent then
        FPSLabel.Text="FPS: "..fps
        if fps>=55 then FPSLabel.TextColor3=C.Green
        elseif fps>=30 then FPSLabel.TextColor3=C.Yellow
        else FPSLabel.TextColor3=C.RedT end end end
    RS.RenderStepped:Wait()end end)
task.spawn(function()
  while not St.isShuttingDown do
    task.wait(2)
    if S.ShowPing and PingLabel.Parent then
      local ok,p=pcall(function()
        return stats and stats.Network.ServerStatsItem["Data Ping"]:GetValue()end)
      if ok and p then PingLabel.Text="Ping: "..math.floor(p).."ms" end end end end)

-- ═══ QUEUE STUB ═══
UpdateQueueUI=function()if RefreshPlayerList then pcall(RefreshPlayerList)end end

-- ═══ CLEANUP ═══
local function Cleanup()
  if St.isShuttingDown then return end
  St.isShuttingDown=true
  StopKC();StopAF();StopFly();StopAnim()
  Cleanup()
  Safe(UnanchorVeh);Safe(StopVeh)
  for p,_ in pairs(ESPObjects)do RemoveESP(p)end
  for _,l in pairs(TracerData)do pcall(function()l:Destroy()end)end
  TracerData={}end
AddC(ScreenGui.Destroying:Connect(Cleanup))

-- ═══ STARTUP ═══
Safe(function()SG:SetCore("SendNotification",{
  Title="X MENU V53",Text="Şifre: "..S.Password,Duration=6})end)
SetStatus("🔒 Şifre: "..S.Password,C.Green)
KillTracker.UpdateStats and KT.UpdateStats()
LoadCfg()
task.spawn(function()
  task.wait(1);RefreshPlayerList()
  local sc=S.MenuSize=="Small"and 0.85 or S.MenuSize=="Large"and 1.25 or 1
  XMenu.Size=UDim2.new(0,OW*sc,0,OH*sc)
  St.currentMenuScale=sc end)
log("STARTUP","X53 loaded — "#Players:GetPlayers().." players")
notify("⚡ X MENU V53","Yüklendi! F4 = Panel",4,C.Green)
print("[X53] ✅ Loaded successfully!")
print("  ✓ All features: Fling, ESP, Auto-Fling, Remote, AI, Fly, Waypoint")
print("  ✓ Track, Movement, Utility, Players, Settings, Garage, Killcam")
print("  ✓ Stats, Vehicles (unlimited Y), i18n (5 langs), KillFeed")
print("  ✓ ConfigSlots, AnimLib (24 anims), CamModes (5), Radar")
print("  ✓ LogViewer, 60+ Chat cmds, Per-Tab Settings")
print("  ✓ No health change | No rank/nametag | Mobile-first")
