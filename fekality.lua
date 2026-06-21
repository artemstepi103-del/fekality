-- ==================== FEKALITY KEY SYSTEM ====================
-- Ключи (инвайты) берутся с твоего сайта (файл invites.txt).
-- Админка пишет туда коды, скрипт их читает. Отозвал — скрипт перестаёт работать.
local INVITES_URL   = "https://raw.githubusercontent.com/USER/REPO/main/invites.txt" -- <-- ПОМЕНЯЙ
local LIFETIME_DAYS = 30   -- сколько дней действует ключ (0 = навсегда)
-- =============================================================

local _Players  = game:GetService("Players")
local _HttpServ = game:GetService("HttpService")
local _LP       = _Players.LocalPlayer

local KEY_FILE   = "fekality_key.json"
local _isfile    = isfile   or function() return false end
local _readfile  = readfile or function() return "" end
local _writefile = writefile or function() end
local _setclip   = setclipboard or toclipboard or function() end

local function _hwid()
    local ok, r = pcall(function() return gethwid and gethwid() end)
    if ok and r and r ~= "" then return tostring(r) end
    ok, r = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok and r and r ~= "" then return tostring(r) end
    return "uid_" .. tostring(_LP.UserId)
end

local function _httpGet(url)
    url = url .. (url:find("?") and "&" or "?") .. "t=" .. tostring(os.time()) -- cache-bust
    local req = (syn and syn.request) or (http and http.request) or http_request or request or (fluxus and fluxus.request)
    if req then
        local ok, res = pcall(req, { Url = url, Method = "GET" })
        if ok and res and (res.StatusCode == 200 or res.Body) then return res.Body end
    end
    local ok, body = pcall(function() return game:HttpGet(url, true) end)
    if ok and body then return body end
    ok, body = pcall(function() return _HttpServ:GetAsync(url) end)
    if ok and body then return body end
    return nil
end

local function _parseInvites(text)
    local set = {}
    if not text then return set end
    for line in tostring(text):gmatch("[^\r\n]+") do
        local s = line:gsub("^%s+", ""):gsub("%s+$", "")
        if s ~= "" and s:sub(1,1) ~= "#" then
            local code = s:match("^[^|;,]+") or s
            code = code:gsub("%s+$", ""):upper()
            if code ~= "" then set[code] = true end
        end
    end
    return set
end

local function _enc(t) local ok,r=pcall(function() return _HttpServ:JSONEncode(t) end); return ok and r or "{}" end
local function _dec(s) if not s or s=="" then return nil end local ok,r=pcall(function() return _HttpServ:JSONDecode(s) end); return ok and r or nil end
local function _save(code, hwid, expiresAt)
    pcall(_writefile, KEY_FILE, _enc({ code=code, hwid=hwid, expiresAt=expiresAt, savedAt=os.time() }))
end
local function _load()
    if not _isfile(KEY_FILE) then return nil end
    local s; pcall(function() s=_readfile(KEY_FILE) end)
    return _dec(s)
end

local _hwidNow  = _hwid()
local _keyOK    = false
local _validSet = _parseInvites(_httpGet(INVITES_URL))

-- ---------- Auto-login (re-checks revocation each launch) ----------
do
    local saved = _load()
    if saved and saved.code and saved.hwid == _hwidNow then
        if _validSet[string.upper(saved.code)] then
            if (not saved.expiresAt) or (saved.expiresAt > os.time()) then
                _keyOK = true
            end
        end
    end
end

-- ---------- Prompt ----------
if not _keyOK then
    local sg = Instance.new("ScreenGui")
    sg.Name = "FekalityKeyPrompt"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 999999
    sg.Parent = (gethui and gethui()) or _LP:WaitForChild("PlayerGui")

    local dim = Instance.new("Frame", sg)
    dim.Size = UDim2.fromScale(1,1); dim.BackgroundColor3 = Color3.new(0,0,0); dim.BackgroundTransparency = 0.35; dim.BorderSizePixel = 0

    local card = Instance.new("Frame", sg)
    card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5); card.Size = UDim2.fromOffset(400, 360)
    card.BackgroundColor3 = Color3.fromRGB(19,19,28); card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card); stroke.Color = Color3.fromRGB(95,179,255); stroke.Thickness = 1; stroke.Transparency = 0.4

    local function lbl(x,y,w,h,text,size,color,font,align)
        local t = Instance.new("TextLabel", card)
        t.Position = UDim2.fromOffset(x,y); t.Size = UDim2.fromOffset(w,h); t.BackgroundTransparency = 1
        t.Font = font or Enum.Font.Gotham; t.TextSize = size or 12; t.TextColor3 = color or Color3.fromRGB(220,220,230)
        t.Text = text; t.TextXAlignment = align or Enum.TextXAlignment.Left; return t
    end

    lbl(0, 28, 400, 32, "FEKALITY", 28, Color3.fromRGB(95,179,255), Enum.Font.GothamBlack, Enum.TextXAlignment.Center)
    lbl(0, 62, 400, 18, "Введи инвайт-код", 12, Color3.fromRGB(140,140,160), Enum.Font.Gotham, Enum.TextXAlignment.Center)

    lbl(20, 100, 200, 14, "ВАШ HWID", 10, Color3.fromRGB(140,140,160), Enum.Font.GothamBold)
    local hwidBox = Instance.new("TextLabel", card)
    hwidBox.Position = UDim2.fromOffset(20,118); hwidBox.Size = UDim2.fromOffset(290,30)
    hwidBox.BackgroundColor3 = Color3.fromRGB(26,26,38); hwidBox.BorderSizePixel = 0
    hwidBox.Font = Enum.Font.Code; hwidBox.TextSize = 11; hwidBox.TextColor3 = Color3.fromRGB(255,255,255)
    hwidBox.Text = "  " .. _hwidNow; hwidBox.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", hwidBox).CornerRadius = UDim.new(0,6)

    local copyBtn = Instance.new("TextButton", card)
    copyBtn.Position = UDim2.fromOffset(316,118); copyBtn.Size = UDim2.fromOffset(64,30)
    copyBtn.BackgroundColor3 = Color3.fromRGB(36,36,52); copyBtn.BorderSizePixel = 0
    copyBtn.Font = Enum.Font.GothamBold; copyBtn.TextSize = 11; copyBtn.TextColor3 = Color3.fromRGB(255,255,255)
    copyBtn.Text = "копир"; copyBtn.AutoButtonColor = false
    Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,6)
    copyBtn.MouseButton1Click:Connect(function()
        pcall(_setclip, _hwidNow); copyBtn.Text = "✓"
        task.delay(1, function() if copyBtn.Parent then copyBtn.Text = "копир" end end)
    end)

    lbl(20, 162, 200, 14, "ИНВАЙТ-КОД", 10, Color3.fromRGB(140,140,160), Enum.Font.GothamBold)
    local codeBox = Instance.new("TextBox", card)
    codeBox.Position = UDim2.fromOffset(20,180); codeBox.Size = UDim2.fromOffset(360,46)
    codeBox.BackgroundColor3 = Color3.fromRGB(26,26,38); codeBox.BorderSizePixel = 0
    codeBox.Font = Enum.Font.Code; codeBox.TextSize = 16; codeBox.TextColor3 = Color3.fromRGB(255,255,255)
    codeBox.PlaceholderText = "FKL-XXXX-XXXX-XXXX"; codeBox.PlaceholderColor3 = Color3.fromRGB(80,80,100)
    codeBox.Text = ""; codeBox.ClearTextOnFocus = false; codeBox.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0,8)

    local status = Instance.new("TextLabel", card)
    status.Position = UDim2.fromOffset(20,234); status.Size = UDim2.fromOffset(360,32)
    status.BackgroundTransparency = 1; status.Font = Enum.Font.Gotham; status.TextSize = 12
    status.TextColor3 = Color3.fromRGB(140,140,160); status.TextWrapped = true; status.Text = ""

    local btn = Instance.new("TextButton", card)
    btn.Position = UDim2.fromOffset(20,274); btn.Size = UDim2.fromOffset(360,44)
    btn.BackgroundColor3 = Color3.fromRGB(95,179,255); btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 14; btn.TextColor3 = Color3.fromRGB(10,10,15)
    btn.Text = "АКТИВИРОВАТЬ"; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,10)

    local busy = false
    btn.MouseButton1Click:Connect(function()
        if busy then return end; busy = true
        local code = string.upper((codeBox.Text or ""):gsub("%s+",""))
        if code == "" then status.TextColor3=Color3.fromRGB(255,82,82); status.Text="Введи код"; busy=false; return end
        -- refresh list in case admin just added it
        _validSet = _parseInvites(_httpGet(INVITES_URL))
        if not _validSet[code] then status.TextColor3=Color3.fromRGB(255,82,82); status.Text="Неверный или отозванный код"; busy=false; return end
        local exp = nil
        if LIFETIME_DAYS and LIFETIME_DAYS > 0 then exp = os.time() + LIFETIME_DAYS*86400 end
        _save(code, _hwidNow, exp)
        _keyOK = true
        status.TextColor3 = Color3.fromRGB(61,220,151); status.Text = "Активирован!"
        task.wait(0.4); sg:Destroy()
    end)

    while sg.Parent and not _keyOK do task.wait(0.1) end
    if sg.Parent then sg:Destroy() end
end

if not _keyOK then return end
-- ==================== END KEY SYSTEM ====================


-- ============ KEY SYSTEM (hashed; v2) ============
-- В этом файле ключей НЕТ — только их SHA256-хеши.
-- Кто получит скрипт не сможет вытащить ключи отсюда.
-- Как добавить ключ: посчитай sha256("твой_ключ") и добавь хеш в
--   VALID_KEY_HASHES ниже либо в файл по KEY_LIST_URL (один хеш на строку).

local _b32=bit32
local _band,_bor,_bxor,_bnot,_rsh,_lsh=_b32.band,_b32.bor,_b32.bxor,_b32.bnot,_b32.rshift,_b32.lshift
local _K={0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2}
local function _rr(x,n) return _bor(_rsh(x,n),_lsh(x,32-n))%0x100000000 end
local function _sha256(msg)
    local len=#msg
    local extra=(-(len+9))%64
    msg=msg.."\128"..string.rep("\0",extra)
    local lb=len*8
    for i=1,8 do msg=msg..string.char(_band(_rsh(lb,(8-i)*8),0xff)) end
    local H={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
    for i=1,#msg,64 do
        local W={}
        for j=0,15 do
            local p=i+j*4
            W[j+1]=_lsh(string.byte(msg,p),24)+_lsh(string.byte(msg,p+1),16)+_lsh(string.byte(msg,p+2),8)+string.byte(msg,p+3)
        end
        for j=17,64 do
            local s0=_bxor(_rr(W[j-15],7),_rr(W[j-15],18),_rsh(W[j-15],3))
            local s1=_bxor(_rr(W[j-2],17),_rr(W[j-2],19),_rsh(W[j-2],10))
            W[j]=(W[j-16]+s0+W[j-7]+s1)%0x100000000
        end
        local a,b,c,d,e,f,g,h=H[1],H[2],H[3],H[4],H[5],H[6],H[7],H[8]
        for j=1,64 do
            local S1=_bxor(_rr(e,6),_rr(e,11),_rr(e,25))
            local ch=_bxor(_band(e,f),_band(_bnot(e),g))
            local t1=(h+S1+ch+_K[j]+W[j])%0x100000000
            local S0=_bxor(_rr(a,2),_rr(a,13),_rr(a,22))
            local mj=_bxor(_band(a,b),_band(a,c),_band(b,c))
            local t2=(S0+mj)%0x100000000
            h=g; g=f; f=e; e=(d+t1)%0x100000000; d=c; c=b; b=a; a=(t1+t2)%0x100000000
        end
        H[1]=(H[1]+a)%0x100000000; H[2]=(H[2]+b)%0x100000000
        H[3]=(H[3]+c)%0x100000000; H[4]=(H[4]+d)%0x100000000
        H[5]=(H[5]+e)%0x100000000; H[6]=(H[6]+f)%0x100000000
        H[7]=(H[7]+g)%0x100000000; H[8]=(H[8]+h)%0x100000000
    end
    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x",H[1],H[2],H[3],H[4],H[5],H[6],H[7],H[8])
end

-- Key system removed.


local ok_ui, Fatality = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/4lpaca-pin/Fatality/refs/heads/main/src/source.luau"))()
end)
if not ok_ui or not Fatality then warn("[Fekality] Fatality failed: "..tostring(Fatality)); return end
local Notifier; pcall(function() Notifier = Fatality:CreateNotifier() end)
pcall(function() Fatality:Loader({ Name = "Fekality", Duration = 2 }) end)

local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Workspace=game:GetService("Workspace")
local RunService=game:GetService("RunService")
local MPS=game:GetService("MarketplaceService")
local LP=Players.LocalPlayer
local Camera=Workspace.CurrentCamera
local PG=LP:WaitForChild("PlayerGui")

-- ============ Nickname privacy (v3: replaces LP nick text with "Скрыто") ============
-- GUI не выключается. Находим TextLabel/TextButton, чей Text == LP.Name или LP.DisplayName,
-- и подменяем текст. Оригинал кешируется для отката по тогглу.
local NICK = { Hide = true, FakeText = "Скрыто" }
-- ============ Rainbow LP nametag (uses game's own NickMode attribute) ============
-- Игра сама рисует радужный ник если LocalPlayer имеет атрибут NickMode="Rainbow".
-- Мы просто устанавливаем этот атрибут + вотчдог на случай если сервер сбросит.
local RNICK = { On = false }
local _rnickOrigMode
local _rnickOrigShimmer
local function _applyRainbow()
    if not LP then return end
    if RNICK.On then
        if _rnickOrigMode == nil then
            _rnickOrigMode    = LP:GetAttribute("NickMode")
            _rnickOrigShimmer = LP:GetAttribute("NickShimmer")
        end
        pcall(function()
            LP:SetAttribute("NickMode", "Rainbow")
            LP:SetAttribute("NickShimmer", true)
        end)
    else
        -- Force back to Normal regardless of stale captured state.
        pcall(function()
            LP:SetAttribute("NickMode",    "Normal")
            LP:SetAttribute("NickShimmer", false)
        end)
        _rnickOrigMode = nil
        _rnickOrigShimmer = nil
        -- Re-assert after the game rebuilds, in case something races.
        task.delay(0.25, function()
            if not RNICK.On and LP and LP:GetAttribute("NickMode") == "Rainbow" then
                pcall(function()
                    LP:SetAttribute("NickMode", "Normal")
                    LP:SetAttribute("NickShimmer", false)
                end)
            end
        end)
    end
end
-- Вотчдог: если игра сбросит NickMode или респавнит с другим режимом — переустанавливаем.
task.spawn(function()
    while true do
        task.wait(1.0)
        if RNICK.On and LP and LP:GetAttribute("NickMode") ~= "Rainbow" then
            pcall(function()
                LP:SetAttribute("NickMode", "Rainbow")
                LP:SetAttribute("NickShimmer", true)
            end)
        end
    end
end)
LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    if RNICK.On then _applyRainbow() end
end)
-- ============ CustomNick pin (drives game's own buildLocalTag during rebuilds) ============
local function _pinCustomNick()
    if not LP then return end
    pcall(function()
        if NICK and NICK.Hide then
            LP:SetAttribute("CustomNick", NICK.FakeText or "Скрыто")
        else
            -- restore empty so game falls back to DisplayName/Name
            LP:SetAttribute("CustomNick", "")
        end
    end)
end
-- Watchdog: if game/server clears CustomNick while Hide is on, push it back.
task.spawn(function()
    while true do
        task.wait(1.0)
        if NICK and NICK.Hide and LP then
            local cur = LP:GetAttribute("CustomNick")
            if cur ~= (NICK.FakeText or "Скрыто") then
                _pinCustomNick()
            end
        end
    end
end)
-- Hook NickMode changes (Rainbow toggle triggers rebuild) -- repin nick + reinject badges.
LP:GetAttributeChangedSignal("NickMode"):Connect(function()
    task.wait(0.15)
    _pinCustomNick()
    if _applyBadgesNow then _applyBadgesNow() end
end)
-- =====================================================================================

-- pin CustomNick at startup so initial rebuild already shows Скрыто
task.defer(function() pcall(_pinCustomNick) end)

-- ==============================================================================

-- ============ Fake nametag badges (Developer/YouTube/TikTok/Moderator/AvatarCreator/Verify) ============
-- Игровой LocalResellerNameTag.MainContainer.BadgeRow -- вставляем туда ImageLabel'ы с asset-id'л из игры.
local BADGE_ICONS = {
    Developer     = "rbxassetid://10885640682",
    YouTube       = "rbxassetid://1275974017",
    TikTok        = "rbxassetid://137014429261024",
    Moderator     = "rbxassetid://9209424449",
    AvatarCreator = "rbxassetid://11955919597",
    Verify        = "rbxassetid://138018675655074",
}
local BADGE_ORDER = { "Developer", "YouTube", "TikTok", "Moderator", "AvatarCreator", "Verify" }
local BADGES = {
    Developer=false, YouTube=false, TikTok=false,
    Moderator=false, AvatarCreator=false, Verify=false,
}

local function _clearFakeBadges(row)
    if not row then return end
    for _, c in ipairs(row:GetChildren()) do
        if c:IsA("ImageLabel") and tostring(c.Name):sub(1, 8) == "FekIcon_" then
            pcall(function() c:Destroy() end)
        end
    end
end

local function _injectBadges(bb)
    if not bb or not bb.Parent then return end
    if not bb:IsA("BillboardGui") then return end
    local main = bb:FindFirstChild("MainContainer")
    if not main then return end

    local active = {}
    for _, name in ipairs(BADGE_ORDER) do
        if BADGES[name] then table.insert(active, name) end
    end

    local row = main:FindFirstChild("BadgeRow")
    if #active == 0 then
        if row then _clearFakeBadges(row) end
        return
    end

    if not row then
        row = Instance.new("Frame")
        row.Name = "BadgeRow"
        row.BackgroundTransparency = 1
        row.LayoutOrder = 1
        row.Size = UDim2.fromOffset(#active * 16 + math.max(#active - 1, 0) * 3 + 4, 18)
        local lay = Instance.new("UIListLayout")
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
        lay.VerticalAlignment = Enum.VerticalAlignment.Center
        lay.Padding = UDim.new(0, 3)
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        lay.Parent = row
        row.Parent = main
    end

    _clearFakeBadges(row)
    for i, name in ipairs(active) do
        -- skip if game's real icon for this badge already exists
        if not row:FindFirstChild("Icon_" .. name) then
            local img = Instance.new("ImageLabel")
            img.Name = "FekIcon_" .. name
            img.BackgroundTransparency = 1
            img.Size = UDim2.fromOffset(16, 16)
            img.Image = BADGE_ICONS[name] or ""
            img.ScaleType = Enum.ScaleType.Fit
            img.LayoutOrder = -1000 + i
            img.Parent = row
        end
    end

    local total = 0
    for _, c in ipairs(row:GetChildren()) do if c:IsA("ImageLabel") then total = total + 1 end end
    if total > 0 then
        row.Size = UDim2.fromOffset(total * 16 + math.max(total - 1, 0) * 3 + 4, 18)
    end
end

local function _applyBadgesNow()
    local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 5)
    if not pg then return end
    local bb = pg:FindFirstChild("LocalResellerNameTag")
    if bb then _injectBadges(bb) end
end

-- watch for the BillboardGui being (re)created (game rebuilds it on attribute change / respawn)
LP:WaitForChild("PlayerGui").ChildAdded:Connect(function(c)
    if c.Name == "LocalResellerNameTag" then
        task.wait(0.1)
        _injectBadges(c)
    end
end)

-- watchdog: keeps fake icons present if game wipes BadgeRow
task.spawn(function()
    while true do
        task.wait(2.0)
        local any = false
        for _, v in pairs(BADGES) do if v then any = true; break end end
        if any then _applyBadgesNow() end
    end
end)
-- =====================================================================================


local _origText = {}  -- map: TextLabel -> original text
local _nickConns = {} -- per-label .Changed connections (to defend against game rewriting it)

local function _isNickLabel(c)
    if not (c:IsA("TextLabel") or c:IsA("TextButton")) then return false end
    local t = tostring(c.Text or "")
    if t == "" then return false end
    if t == NICK.FakeText then return false end  -- already patched by us
    local n  = LP.Name or ""
    local dn = LP.DisplayName or ""
    if n  ~= "" and (t == n  or t:find(n,  1, true)) then return true end
    if dn ~= "" and (t == dn or t:find(dn, 1, true)) then return true end
    return false
end

local _origBillOffset = {}
local _origBillSize   = {}

local function _findAncestorBillboard(c)
    local p = c.Parent
    while p and p ~= game do
        if p:IsA("BillboardGui") then return p end
        p = p.Parent
    end
    return nil
end

local function _reposBillboard(bb)
    if not bb then return end
    if _origBillOffset[bb] == nil then _origBillOffset[bb] = bb.StudsOffset end
    if _origBillSize[bb]   == nil then _origBillSize[bb]   = bb.Size end
    pcall(function()
        bb.StudsOffset = Vector3.new(0, 2.5, 0)
        local s = bb.Size
        local newH = (s.Y.Offset > 0 and math.min(s.Y.Offset, 32)) or 24
        bb.Size = UDim2.new(s.X.Scale, s.X.Offset, 0, newH)
    end)
end

local function _patchLabel(c)
    if _origText[c] == nil then _origText[c] = c.Text end
    pcall(function() c.Text = NICK.FakeText end)
    local bb = _findAncestorBillboard(c)
    if bb then _reposBillboard(bb) end
    -- self-healing: if game overwrites the text back to the nick, re-replace
    if not _nickConns[c] then
        _nickConns[c] = c:GetPropertyChangedSignal("Text"):Connect(function()
            if not NICK.Hide then return end
            local cur = tostring(c.Text or "")
            if cur ~= NICK.FakeText then
                if _isNickLabel(c) then
                    _origText[c] = cur
                    pcall(function() c.Text = NICK.FakeText end)
                end
            end
        end)
    end
end

local function _scanRoot(root)
    if not root then return end
    local ok, kids = pcall(function() return root:GetDescendants() end)
    if not ok or not kids then return end
    for _, d in ipairs(kids) do
        if _isNickLabel(d) then _patchLabel(d) end
    end
end

local function applyNickHide()
    if NICK.Hide then
        _scanRoot(LP.Character)
        _scanRoot(PG)
        -- defer workspace scan to a background task so script load doesn't freeze
        task.spawn(function() task.wait(0.05); _scanRoot(workspace) end)
    else
        for lbl, orig in pairs(_origText) do
            if lbl and lbl.Parent then pcall(function() lbl.Text = orig end) end
            _origText[lbl] = nil
        end
        for lbl, conn in pairs(_nickConns) do
            pcall(function() conn:Disconnect() end)
            _nickConns[lbl] = nil
        end
        for bb, off in pairs(_origBillOffset) do
            if bb and bb.Parent then pcall(function() bb.StudsOffset = off end) end
            _origBillOffset[bb] = nil
        end
        for bb, sz in pairs(_origBillSize) do
            if bb and bb.Parent then pcall(function() bb.Size = sz end) end
            _origBillSize[bb] = nil
        end
    end
end

-- periodic re-scan: ONLY the character tree (small, cheap). Workspace is huge —
-- scanning it on a timer freezes the game. New workspace descendants are caught
-- by the DescendantAdded watcher below instead.
task.spawn(function()
    while true do
        task.wait(3.0)
        if NICK.Hide then
            local char = LP.Character
            if char then _scanRoot(char) end
        end
    end
end)

-- live watcher: scan new descendants in workspace (covers respawn / new player GUIs)
-- DescendantAdded watcher with cheap class filter up-front.
-- Roblox fires this for EVERY part/mesh added to workspace; doing IsA twice in a
-- row before any task.wait is critical to avoid stalls during streaming.
local _nickQueue = {}
workspace.DescendantAdded:Connect(function(d)
    if not NICK.Hide then return end
    local cn = d.ClassName
    if cn ~= "TextLabel" and cn ~= "TextButton" then return end
    table.insert(_nickQueue, d)
end)
-- queue drainer: processes batches off the hot path
task.spawn(function()
    while true do
        task.wait(0.5)
        if NICK.Hide and #_nickQueue > 0 then
            local batch = _nickQueue; _nickQueue = {}
            for _, d in ipairs(batch) do
                if d and d.Parent and _isNickLabel(d) then _patchLabel(d) end
            end
        elseif #_nickQueue > 200 then
            -- safety: drop if it grew huge while disabled
            _nickQueue = {}
        end
    end
end)

applyNickHide()
task.delay(0.5, applyNickHide)
task.delay(1.5, applyNickHide)
LP.CharacterAdded:Connect(function()
    task.wait(0.3)
    applyNickHide()
    task.delay(0.6, applyNickHide)
end)


local LEG_COLOR=Color3.new(1,0.705882,0)
local COLOR_TOL=0.1
local function isLegColor(c)
    return math.abs(c.R-LEG_COLOR.R)<COLOR_TOL
       and math.abs(c.G-LEG_COLOR.G)<COLOR_TOL
       and math.abs(c.B-LEG_COLOR.B)<COLOR_TOL
end

local function looksLikeUuid(s)
    -- Reject hex-UUID-style names like E2D70A60-BBEF-4581-A4A4-E0D8C1EE8B85
    -- или с подчёркиваниями. Обычные названия проходят нетронутыми.
    if not s or #s < 12 then return false end
    -- 8-4-4-4-12 hex с - или _
    if s:match("^%x%x%x%x%x%x%x%x[%-_]%x%x%x%x[%-_]%x%x%x%x[%-_]%x%x%x%x[%-_]%x%x%x%x%x%x%x%x%x%x%x%x$") then
        return true
    end
    -- 5 блоков hex через - или _
    if s:match("^%x+[%-_]%x+[%-_]%x+[%-_]%x+[%-_]%x+$") then return true end
    -- 3+ блока hex и всё в хекс-диапазоне + разделители
    if s:match("^%x+[%-_]%x+[%-_]%x+") and not s:match("[g-zG-Z]") then return true end
    return false
end

local S={On=false,Chrome=true,FontSize=12,BoxWidth=320,MaxDist=180,MaxVisible=25,
    Transparency=0.45,Search="",MatchOnly=false,
    PickedColor=Color3.fromRGB(255,215,0),Color=Color3.fromRGB(255,215,0)}
local TAGS={}
local CONNS={}
local nameCache={}
local pendingQueue={}
local ITEM_DB={[1352050969]="Белая футболка",[6174845177]="Черная футболка",[114724377]="Серая футболка",[6877956799]="Граффити футболка",[6384915788]="Drip футболка",[12001043365]="Золотая цепь",[18662896578]="Яндекс Доставка Футболка",[73216590459166]="AmiriKing",[7798271981]="Пижака чигура",[7798302571]="Штаны чигура",[8425198358]="Черные джинсы",[9367316394]="Синие джинсы",[15617408766]="Рваные джинсы",[18391376326]="Designer джинсы",[124139147116818]="Cav Empt Свитшот Черный",[3652598277]="Cav Empt Chemical Engineering",[2944205656]="Cav Empt Зип-Худи",[2887711548]="Cav Empt Футболка Spring Delivery",[3244925440]="Cav Empt Свитшот Symptom Heavy",[297942903]="Cav Empt Бомбер",[132771012378737]="Cav Empt Свитшот Черный v2",[914784455]="Cav Empt Свитшот FW 17",[322189906]="Cav Empt Not Impossible Crewneck",[1002344605]="Cav Empt MD Document Crewneck",[18280893525]="Cav Empt Joker",[139626993726125]="Cav Empt Свитшот Серый",[18694595667]="Amiri Футболка Черная",[89306530816863]="Amiri Футболка Черная2",[113811400216537]="Amiri Худи Зеленое",[128351870809134]="Amiri Футболка Paint",[6004029876]="Haliky Худи",[6676412081]="Haliky Gang Bears",[17303641875]="Nike x Stussy",[12820715433]="Nike Черная",[11554103603]="Nike Tech",[4746292577]="Nike Hoodie",[11554264756]="Nike Tech Blue",[8801995627]="Nike Tech Dark Light Blue",[15501893721]="Nike Tech Dark Blue",[7397565263]="Nike Tech Windrunner Black",[75749441655962]="redvetements",[6982632122]="Nike Шорты",[11410851476]="Nike Tech Pants",[14343129826]="Nike Air Pants",[12757775222]="Nike Tech Blue",[87630874548849]="Gallery Dept Lanvin",[11725889271]="Gallery Dept Футболка Черная",[13835053077]="Gallery Dept Футболка Белая",[79423109019674]="Gallery Dept Свитшот Синий",[125540636897982]="Gallery Dept Футболка Синяя",[118666889439649]="Gallery Dept Свитшот Коричневый",[71091220191588]="Gallery Dept Лонгслив",[86921710360798]="Gallery Dept Красный Зип-Худи",[101869006032601]="Gallery Dept Футболка",[101110457561961]="Gallery Dept Футболка Зеленая",[140022990256816]="Gallery Dept Худи Зеленое",[100168311309116]="Gallery Dept Футболка Шамана",[13974345356]="Gallery Dept Спортивки Черные",[12792854135]="Gallery Dept Спортивки Серые",[93556375284974]="Gallery Dept Спортивки Голубой",[99632820598737]="Gallery Dept Спортивки Розовая",[128614066781001]="Gallery Dept Спортивки Бежевые",[112068921354030]="Gallery Dept Спортивки Серые v2",[3131452093]="BAPE Camo",[94733728494733]="BAPE Shark",[4695588521]="Black Milo Shark Tee",[2783959084]="BAPE Tiger Red",[836376693]="BAPE x Stussy",[4843433327]="BAPE Yellow Camo Shark",[3052304894]="BAPE Tiger Camo",[107348845353432]="Bape Tiger Зеленый/Оранжевый",[132534299493006]="BAPE Tiger Диолетовый",[96225370149582]="BAPE Panda Диолетовый камуфляж",[79138012674866]="BAPE Dubai Camo Shark Белый",[74566614556041]="BAPE Tiger Colors Черный",[127813886164608]="BAPE Зеленый/Оранжевый Tiger Белый",[84803613886580]="BAPE Holographic Tiger Черная",[85037105009809]="BAPE Red Panda",[120028188529902]="BAPE Shark Диолетовая",[105402915829012]="BAPE Футболка",[1329266704]="BAPE Full Zip Shark",[4947216628]="BAPE Camo Штаны",[72015381801594]="BAPE Tiger Штаны Синие",[137022318888712]="BAPE Tiger Штаны Красные",[131922684973046]="BAPE Tiger Штаны Темно-Зелен",[99313817373559]="BAPE Tiger Штаны Диолетовые",[15059936417]="BAPE Hellstar",[121948527526959]="Gutta Longsleeve Pink Blue",[129923898671032]="Gutta Opiu Tee",[73257106599901]="Gutta Hoodie Black",[87059217590619]="Gutta Zip-Hoodie",[131637613314592]="Gutta Coffee Longsleeve",[75730721795242]="Gutta Black-White Longsleeve",[103809820683913]="Gutta Opiu Black",[86664943903751]="Gutta Raiders Camo shirt",[75621017852847]="Gutta Opiy Shirt",[70895461143874]="Gutta Snake Year",[125787142138788]="Gutta Opiu White",[81243747834531]="Gutta Classic White Longsleeve",[129051289938686]="NeNet Свитшот",[134937339779999]="NeNet Футболка Черная",[126688679972643]="NeNet Свитшот Синий",[9930373240]="NeNet Футболка Диолетовая",[118840925833484]="NeNet Футболка Серая",[83631847906705]="NeNet Футболка Белая v2",[12089573241]="NeNet Футболка Белая",[15015469155]="NeNet Футболка Черная v2",[124013704220310]="NeNet Свитшот Черный",[70880619395363]="Nenet Штаны",[16452154247]="HBA Морф",[93422277147402]="HBA Creepy Свитшот",[71222633992816]="HBA Рубашка",[101719618368646]="HBA Face Свитшот",[16579558789]="HBA Aphex Свитшот",[18588070468]="HBA Зип-Худи",[18588053395]="HBA Face Шорты",[1499082681]="Supreme Box Logo",[3463183841]="Supreme Свитшот",[431730384]="Supreme x ASAP",[1103783724]="Bape x Supreme",[7092331508]="Supreme Pants",[13444831702]="Supreme x BB",[438195463]="Гоша Рубчинский x Fila",[5809785846]="Гоша Рубчинский Flag",[15706847548]="Гоша Рубчинский x Rassvet",[87503337904060]="Гоша Рубчинский Fila Yellow LS",[5487023113]="Гоша Рубчинский Враг Свитер Черный",[4909082176]="Гоша Рубчинский Футбол",[15311273900]="Гоша Рубчинский X Kappa Свитер",[9545499629]="Гоша Рубчинский Свитер Синий",[560325377]="Гоша Рубчинский Худи ColorBrick",[576444465]="Гоша Рубчинский Camo Спаси С��храни",[436720176]="Гоша Рубчинский X Thrasher",[4996937439]="Гоша Рубчинский Zip Красный/Синий",[2118764687]="Гоша Рубчинский Вдруг Красный",[1435177629]="Гоша Рубчинский Белая Футболка",[772695241]="Гоша Рубчинский Зеленый Свитер",[607550981]="Гоша ��убчинский Спорт Куртка Russian",[1162019947]="Гоша Рубчинский x Kappa Винтаж",[5549063618]="Гоша Рубчинский Свитер Желтый",[14578854678]="Гоша Рубчинский Гибридный",[5972477579]="Гоша Рубчинский Рождественский",[107248336623941]="Гоша Рубчинский Вдруг Друг",[98305906232207]="Гоша Рубчинский Флаги",[1824185908]="Гоша Рубчинский x Kappa",[15056443139]="Гоша Рубчинский Base",[11796928325]="Гоша Рубчинский Рождество",[884721414]="Гоша Рубчинский x Kappa",[14182270450]="Burberry Classic",[14961358306]="Burberry London",[15903662503]="Polo Burberry",[16218939509]="Burberry Штаны",[13868676222]="Burberry x Bape",[4464224771]="Off-White Черная",[111494454911134]="Off-White Белая Футболка",[6071739662]="Off-White Virgil Abloh Красный",[3224293759]="Off-White Зеленый",[1213373791]="Off-White Camo",[590131471]="Off-White Бежевая",[2474144253]="Off-White MonoLisa",[2744313464]="Off-White Синяя",[2518177916]="Off-White Свитер",[15084872864]="Off-White Черная Футболка v2",[4809072541]="Off-White Белая Футболка v2",[138024345748614]="Off-White Белая Футболка v3",[85991896636316]="Palm Angels",[6274614487]="Palm Angels Свитшот Голубой",[15161522231]="Palm Angels Zip Классик",[15616127684]="Palm Angels Zip Серая",[12257396304]="Palm Angels Футболка Bear",[127026922296813]="Palm Angels Фут��олка v2",[11511640247]="Palm Angels Футболка v3",[126190832806951]="Palm Angels Zip Красная",[5973979386]="Palm Angels Zip",[7724732726]="Palm Angels Bear",[5611331869]="Palm Angels Flame",[6501833600]="Palm Angels Zip Цветок",[7205233886]="Palm Angels Zip Кислотный",[89385145596759]="Palm Angels Zip Диолетовый",[18660217283]="Palm Angels Классик",[10468675783]="Palm Angels Серые",[88741221455613]="Palm Angels x Raf Blue Red",[9084664827]="Palm Angels Диолетовые",[123772691907841]="Comme des Garcons Рубашка",[14582695300]="Comme des Garcons Футболка",[8128676575]="Comme des Garcons Футболка Camo Love",[11602203772]="Comme des Garcons Свитшот Серый",[5699364090]="Comme des Garcons Лонгслив Белый-Черный",[81585264094038]="Comme des Garcons Play Футболка Черная",[2098915079]="Comme des Garcons Футболка Love Белая",[15121388536]="Comme des Garcons Футболка Черная",[1074658737]="Comme des Garcons Синий Зип-Худи",[1079296706]="Comme des Garcons Футболка Белый-Красный",[962194504]="Comme des Garcons Лонгслив Белый-Синий",[5575894980]="Comme des Garcons Camo Футболка",[116168634401177]="Comme des Garcons X Rolling Stones Футболка",[16388179108]="Stone Island Default",[13948309746]="Stone Island Termo Longsleave",[1315352916]="Stone Island Свитшот",[87509417534862]="Stone Island Zip-Hoodie",[14840856758]="Stone Island Orange",[14984408119]="Stone Island Pink",[117161695009647]="Stone Island Off Day Blue",[97856390601463]="Stone Island Red Hoodie Off Dye",[119767338320263]="Stone Island Comfort Tech Purple",[12624379885]="Stone Island Turtleneck",[7249098507]="Stone Island Urban Black Yellow",[8462301101]="Stone Island Desert Camo",[8631651981]="Stone Island Desert Camo Jacket",[8631755151]="Stone Island WATRO-TC Jacket",[13778721268]="Stone Island Skin Touch Purple",[132959748946564]="Stone Island Shadow Tiger Camo",[139421353405484]="Stone Island Reflective",[118064352416891]="Stone Island Comfort Tech Blue",[120903225671360]="Stone Island Comfort Tech Red",[139017627542362]="Stone Island x Supreme Белые",[13876916079]="Stone Island x Supreme",[8631671234]="Stone Island Big Loom Camo-Tc",[15177463566]="Stone Island Default",[120383454886093]="Stone Island Joggers",[13781107752]="Stone Island Gray Pants",[831537199]="Stone Island Navy",[8631687945]="Stone Island Desert Camo",[8631779037]="Stone Island WATRO-TC",[13779001426]="Stone Island Purple Skin Touch",[108047896837515]="Stone Island x Supreme White",[84913974138865]="Stone Island x Supreme",[8631708424]="Stone Island Big Loom Camo-Tc",[16974592422]="CP.Company Blue Hoodie",[125295721091210]="CP.Company Rose",[82077729005226]="CP.Company Blue Puffer Jacket",[78185107533537]="CP.Company DD Shell Red",[97526151621254]="CP.Company Teal Jumper",[131336649441063]="CP.Company Navy Windbreaker",[113247621156859]="CP.Company Black Windbreaker",[14077919304]="CP.Company Свитшот",[87883117918210]="CP.Company Noir Default",[100997096188512]="CP.Company DD Shell Green",[139627508845654]="CP.Company DD Shell Beige",[95337445087298]="CP.Company DD Shell Noir",[99737839478071]="CP.Company Cardigan Black",[81270251381720]="CP.Company Orange Майка",[15783597851]="CP.Company Crewneck",[134908184079208]="CP.Company Carbone Noir",[74448709325820]="CP.Company Blanc Майка",[13476230890]="CP.Company Short Yellow",[15783604661]="CP.Company Gray Pants",[14050651166]="CP.Company Blue Pants",[6664977420]="CP.Company Default Pants",[16974632408]="CP.Company Orange Pants",[78683849537161]="Racer WorldWide Свитшот Красный",[118245234493513]="Racer WorldWide Леопардовый Зип-Худи",[11831115149]="Racer WorldWide Свитшот",[8633623320]="Racer WorldWide Свитер В Полоску",[99497707297997]="Racer WorldWide Куртка из Овечьи Шкуры",[97197585182330]="Racer WorldWide ЛонгСлив Катя Кищук",[75548914998494]="Racer Worldwide Металлик Спортивные Штаны",[124377088956183]="Racer Worldwide Светлые Джинсы",[82685608298333]="Racer Worldwide Спортивные Штаны",[138030819896058]="Racer Worldwide Трансформ Зип Джинсы",[137788979820718]="Yohji Yamamoto Свитшот",[6046174032]="Yohji Yamamoto Ys for Men AW2001 Godzilla",[14484000414]="Yohji Yamamoto Rei Ayanami Evangelion Button up",[86114857882709]="Yohji Yamamoto Свитшот Avant Garde",[115386784245524]="Yohji Yamamoto Зеленая Куртка",[131596879156451]="Yohji Yamamoto Свитшот Кожанка",[10515393675]="Yohji Yamamoto Свитшот Spider Knit",[4794620897]="Yohji Yamamoto AW 2001 Godzilla Свитшот",[4895301337]="Yohji Yamamoto Heroes Leather Байкерская Куртка",[5166805206]="Yohji Yamamoto Свитшот Skull",[7023449511]="Yohji Yamamoto Свитшот Зеленый",[130582847343989]="Yohji Yamamoto Свитшот Supreme",[90420982954859]="Yohji Yamamoto Куртка Темно-Синяя",[14606133245]="Yohji Yamamoto Спортивная Куртка Poison",[8826223539]="Yohji Yamamoto Свитшот Smoke",[129487569430492]="Yohji Yamamoto J-PT Иллюстрация",[89357762722807]="Yohji Yamamoto Project Футболка",[132752004376816]="Yohji Yamamoto Куртка Красная",[18606916311]="Yohji Yamamoto Брюки",[71399636217265]="SS04 Yohji Yamamoto Y-3 x 3S Spotted Джинсы",[5680301087]="Gucci Tiger Tracksuit",[1518645608]="Gucci Tiger Hoodie",[5469366412]="Gucci Polo Shake",[2672925839]="Gucci Sweatshirt Tiger",[6181344251]="Gucci Star Sweater",[1081054870]="Gucci Coco Capitan",[5023083383]="Gucci Lamb",[956388277]="Gucci LOVE",[2464334422]="Gucci Logo Tee",[3370349046]="Gucci X Tee",[2109554081]="Gucci x LV Jacket",[126913643075376]="Gucci Blind For Love Hoodie",[1083553649]="Gucci Sweatshirt Planet",[5634486976]="Gucci shorts x Blue Lubz",[134853942496739]="Zapatillas Gucci X Amiri",[135386999852550]="LV Shirts",[5836356644]="LV x TNF",[5226567379]="Supreme x LV",[1565502112]="Supreme x Bape x LV",[15292591748]="LV Jeans",[967030317]="LV Balmains",[124231377168467]="Balenciaga Logo Print Tee",[102510983142980]="Balenciaga x Fortnite",[11386091941]="Balenciaga Logo",[10890916980]="Balenciaga Campaign",[3138759121]="Balenciaga x Gucci",[12774350601]="Balenciaga GAMER",[16648632315]="Balenciaga GAMER Denim Jacket",[17750429143]="Balenciaga GAMER Bomber",[5314403333]="Balenciaga Jean Jacket X Gosha",[17747885612]="Balenciaga X Under Armor",[15453420630]="Balenciaga Speed Runner Hoodie",[137408844484403]="Balenciaga 3B Sports Deutsche Bahn",[3785693796]="Balenciaga Grey Jumper",[16648534764]="Balenciaga Resort 2023",[13676876569]="Balenciaga Distressed Hoodie",[2074367265]="TH Hoodie X Balenciaga x RAF",[98869180278083]="Balenciaga Tokyo Cut",[82170977556685]="Balenciaga Nasa Bomber Jacket",[86463016923018]="Balenciaga Hoodie Alien",[85720763562074]="Balenciaga Runway Polo Hoodie",[15825720946]="Balenciaga Logo Print Hoodie Blue",[133873637543203]="Balenciaga Red Crimson Windbreaker",[18813584989]="Balenciaga Reversible Bomber Jacket",[88020456613700]="Balenciaga Tiger",[4590342423]="Balenciaga Paris Moon Sweater",[125248485368695]="Balenciaga Paris",[16662225397]="Balenciaga Runway",[122599601118964]="Balenciaga Jeans",[109107120274465]="Balenciaga Under Armor",[93824635464666]="Balenciaga Grey Skater Sweatpants",[124975585838444]="Balenciaga Blue Skater Sweatpants",[15732426819]="Balenciaga Red Skater Sweatpants",[84116395504704]="Balenciaga Leather",[14072460187]="Balenciaga Gamer Jeans",[97665782669251]="Balenciaga NASA",[92750199062144]="Rick Owens Zip",[82934586126898]="Rick Owens Футболка",[15422438906]="Rick Owens DRKSHDW",[98599150857223]="Rick Owens Джинсовая",[136218865674437]="Rick Owens Джинсовая Черная",[77234120970244]="Rick Owens Джинсовая Синяя",[8573407398]="Rick Owens x Moncler",[71424043928165]="Rick Owens Джинсовая Красная",[130104280419383]="Rick Owens Джинсовая Желтая",[121618494628389]="Rick Owens Зип Джинсовая Розовая",[83255075167663]="Rick Owens Футболка Vamp",[8502567669]="Rick Owens Runway",[14220615409]="Rick Owens Штаны",[18477705722]="Rick Owens Джинсы",[12517077399]="Rick Drkshdw Pants",[89501380293235]="Rick Owens Джинсы Зип",[85545557857293]="Rick Owens Штаны X Champion",[84825703583648]="Rick Owens Джинсы Розовые",[101535348409637]="Rick Leather",[134619700442692]="Chrome Hearts Tee Black",[10322816406]="Chrome Hearts Rainbow Cross",[6678207951]="Chrome Hearts Gray Sweater",[99324171797960]="Chrome Hearts Red Shirt",[16919855258]="Chrome Hearts Multi-Colour Hoodie",[96585015209179]="Chrome Hearts T Logo USA Hoodie",[6198234501]="Chrome Hearts Zip Up Black",[18968804462]="Chrome Hearts Grunge",[72762590768448]="Chrome Hearts Camo Matty",[5944585429]="Chrome Hearts x Off-White Hoodie",[90915822594460]="Chrome Hearts Black Pink LS",[12852126150]="Chrome Hearts Miami Hoodie",[7369775838]="Chrome Hearts x LV Jacket",[18428381654]="Chrome Hearts Matty Boy Space",[11454813848]="Chrome Hearts Yellow Hoodie",[126863028392369]="Chrome Hearts Matty Boy Sweatshirt",[14127820316]="Chrome Hearts Cyan",[116987323218059]="Chrome Hearts Rainbow Sweatshirt",[15705156210]="Chrome Hearts Blue",[6447552174]="Chrome Hearts Cyan Alt",[90412503682792]="Chrome Hearts Cross Patch Dog",[18400219191]="Chrome Hearts Zip Up Hoodie Black",[73657715280895]="Chrome Hearts Tee",[16582495088]="Chrome Hearts Basic Tee",[7381767636]="Chrome Hearts Orange Sweater",[77430172245334]="Chrome Hearts Red & Green Sweater",[92049531048374]="Chrome Hearts Sweats Black",[16430470279]="Chrome Hearts Multi Color Cargos",[14502536751]="Chrome Hearts Logo White",[85305185315542]="Chrome Hearts Rolling Stones",[79285824675024]="Chrome Hearts Ryft Davis",[122714934882673]="Chrome Hearts Grey Jeans",[10946069869]="Chrome Hearts Pink-Black Jeans",[15696366780]="Chrome Hearts Jeans",[7136404058]="Chrome Hearts Blue Jeans",[7548737358]="Chrome Hearts Orange Pants",[15167783027]="Chrome Hearts Red Jeans",[16733661152]="Chrome Hearts Gray Denim Jeans",[7902431231]="Chrome Hearts Blue Jeans Chrome",[7248675954]="Chrome Hearts X LV Jeans",[9026168986]="Chrome Hearts Red And Blue",[80707179561942]="Moncler White Polo",[10793538519]="Moncler Black Polo",[8171196077]="Moncler Yellow Mini Puffer",[11998504162]="Moncler Big Logo",[3163582983]="Moncler Black Full Sleeve",[8162777342]="Moncler Vest Orange",[5960853118]="Moncler Orange Jacket",[5964807969]="Moncler Black Jacket Alt",[8162975494]="Moncler Yellow Puffer",[6722978612]="Moncler Green Jacket",[6488586232]="Moncler Vest Classic",[5341316038]="Moncler Gray Sweater",[6142390595]="Moncler Gray Vest",[6488509571]="Moncler Red Tracksuit",[4831711976]="Moncler TriColor Windbreaker",[6488495469]="Moncler Puffer Logo",[9375216039]="Moncler Black Jacket",[6455447834]="Moncler Red Puffer",[15338842173]="Moncler Black Tapered Tracksuit",[8446274549]="Moncler Parka Coat",[5964876806]="Moncler x Palm Angels Red Zip",[8165648360]="Moncler x Palm Angels Jacket",[6505230129]="Moncler Blue Zip-Up",[9384199616]="Moncler Blue Coat",[6787299892]="Moncler Maroon Jacket",[6505230940]="Moncler Green Zip-up",[3689506876]="Moncler Multi Colored Jacket",[13876237691]="Moncler x Palm Angels Black",[12636365073]="Moncler X PA Blue Tracksuit Top",[12621049095]="Moncler X PA Forest Green Top",[6455445003]="Moncler Purple Bubble Jacket",[14396989921]="Moncler x PA Puffer Jacket",[5029449227]="Moncler Striped Technical",[11674658234]="Moncler Spider",[11484662835]="Moncler x PA Kelsey Puffer Blue",[13429337035]="Moncler x PA Fiber Light Puffer",[11382056477]="Moncler Tech Pants",[80212103951429]="Moncler Classic Pants",[5459824253]="Moncler X PA Trackpants",[12621050787]="Moncler X PA Forest Green Bot",[105198371812252]="ERD Белый Лонг",[124798507529638]="ERD Destroyed Hoodie",[76738452087604]="ERD Лонгслив",[102885674981104]="ERD Голубой Лонгслив",[128216714278616]="ERD Bully Худи",[120196252098729]="ERD Красная Джинсовая",[98881995294054]="ERD Archive Худи Красный",[122273528955293]="ERD Archive Лонгслив",[137773512709519]="ERD Потёртые Джинсы v1",[83641705983017]="ERD Потёртые Джинсы v2",[74573745510706]="ERD x Rick Owens Джинсы",[102019726797995]="ERD Красные Джинсы",[15570425245]="Raf Simons Hoodie",[75216977300015]="Raf Simons Brian Calvin Beer Girl",[125655994023355]="Raf Simons Christiane F Tees AW18",[76516442021518]="Raf Simons Поло Красное",[91498176431445]="Raf Simons Black Christiane F AW18",[125538194046026]="Raf Simons Красный Лонгслив",[122313792956641]="Raf Simons Brian Calvin Beer Girl Tee",[102589072483955]="Raf Simons Худи Серый",[86995497093030]="Raf Simons Бомбер Белый",[140534031809179]="Raf Simons Красный Лонгслив v2",[10443560347]="Raf Simons AW01 Runway",[95423048146621]="Raf Simons SS10 Sterling Ruby Shirt",[131319439176543]="Raf Simons Replicant Черный",[124039750585318]="Raf Simons Ozweego 2 Khaki Gold",[87554525526000]="Raf Simons Ozweego Metallic Pink",[112685667527061]="Raf Simons Ozweego 3 Black Scarlett",[116642119535875]="Raf Simons Antei Purple",[72101896533425]="Raf Simons Ozweego 3 Bunny Cream",[76698897803837]="Raf Simons Ultrasceptre Black",[84478752542723]="Raf Simons Ozweego 2 Yellow Navy",[105222831634134]="Raf Simons Ozweego 2 Gray Green",[109462627025831]="Raf Simons Ozweego Replicant Green",[70728690346102]="Raf Simons Ozweego 2 Blue Red Lucora",[131686044597910]="Raf Simons Ozweego Replicant Brown",[101604148293803]="Raf Simons Pharaxus Green Black",[120612391944120]="Raf Simons 2-CB GHB Patchwork",[125293782853552]="Raf Simons LSD White",[75354435184240]="Raf Simons Cylon 21 Red",[18632819241]="Number(N)ine Коричневое Худи",[18632881209]="Number(N)ine Серое Худи",[105478169140045]="Number(N)ine Shield Серое Худи",[128716647842609]="Number(N)ine Красный Лонгслив",[14885532636]="Number(N)ine Футболка",[12274864979]="Number(N)ine Черный Лонгслив",[81231921426493]="Number(N)ine Zip Jacket",[99950858190570]="Number(N)ine Серая Zip Jacket",[17573405272]="Number(N)ine Серый Лонгслив",[81895753471926]="Number(N)ine Shield Черное Худи",[18323948106]="Number(N)ine Черные Джинсы",[102839033215257]="Number(N)ine Потёртые Джинсы",[12014837061]="1017 ALYX 9SM Свитшот",[116739608201251]="1017 ALYX 9SM Рубашка",[16949566103]="1017 ALYX 9SM Куртка Зип",[14307549017]="1017 ALYX 9SM x Moncler Свитшот",[10253718453]="1017 ALYX 9SM Свитшот Красный",[13607073567]="1017 ALYX 9SM Футболка Белая",[95060430454867]="Vetements Лонгслив",[18983373539]="Vetements Худи",[17508312490]="Vetements Anarchy",[11290616980]="Vetements Бомбе���� Полиция",[107557100704001]="Vetements Худи v2",[89790335131378]="Vetements Бомбер Зеленый",[80547880319610]="Vetements Футболка Оранжевая",[77439910826532]="Vetements Бомбер Тёмно-Зеленый",[134508752165617]="Vetements Бомбер",[81560105275312]="Vetements Худи Черное",[128389783148999]="Vetements Зип-Худи",[117766762488194]="Vetements Бомбер Красный",[90919421530654]="Vetements Футболка Polizei",[99150978070886]="Vetements Лонгслив Темно-Синий",[91606294899206]="Vetements Лонгслив Черный",[77220484371723]="Vetements Clothing Green",[86185820213136]="Vetements Vamp Футболка",[4552458072]="Vetements Antwerp Тёмно-Красное",[18720565335]="Vetements Antwerp Красный",[124697147814478]="Vetements Antwerpen Белая v1",[75624653597148]="Vetements 204 Hyoma Raf Reconstructed",[15564674144]="Vetements Antwerpen Белая v2",[87891411586632]="Vetements Джинсы Потёртые",[132566833184808]="Vetements Спортивки Белые",[80693415563613]="Vetements Спортивки Черные",[126970846706113]="Vetements Синие-Джинсы Потёртые",[18270211852]="Maison Margiela Свитер",[108337687172395]="Maison Margiela Лонгслив Белая",[138263043704514]="Maison Margiela Лонгслив Черная",[122468912421457]="Maison Margiela Куртка из Ремней",[73388686842934]="Maison Margiela Зеленый Лонгслив",[135517402543302]="Maison Margiela Рубашка",[137990594447175]="Maison Margiela Женская Меховая Куртка",[81765716375958]="Maison Margiela Темные Джинсы",[104326582321744]="Maison Margiela Светлые Джинсы",[6763195401]="Goyard Зеленая Футболка",[907988303]="Goyard Классическая Футболка",[6131796962]="Goyard Классическая Футболка v2",[1226570804]="Goyard Джинсы",[993568649]="Goyard Джинсы v2",[18370037060]="Dior Футболка",[101488585369119]="Dior Лонгслив",[18147277043]="Dior Свитшот",[122763783050786]="Dior Худи",[118344538644973]="Dior Свитер",[85583075418361]="Dior Зип Худи",[10371714775]="Dior Зип",[139013853108228]="Dior Джинсы",[90433833342790]="Dior Шорты",[105804105689619]="Femboy свитшот",[72870106856318]="Femboy штаны",[14141451141]="Delivery Kaif Рюкзак"}
local ITEM_PRICES={[1352050969]=1500,[6174845177]=2000,[114724377]=2000,[6877956799]=4000,[6384915788]=13000,[12001043365]=23500,[18662896578]=63500,[73216590459166]=17000,[7798271981]=63500,[7798302571]=76500,[8425198358]=2000,[9367316394]=500,[15617408766]=4000,[18391376326]=12500,[124139147116818]=14000,[3652598277]=26000,[2944205656]=16500,[2887711548]=34000,[3244925440]=63500,[297942903]=67000,[132771012378737]=21500,[914784455]=63500,[322189906]=63500,[1002344605]=63500,[18280893525]=63500,[139626993726125]=21000,[18694595667]=10000,[89306530816863]=1000,[113811400216537]=4500,[128351870809134]=4000,[6004029876]=63500,[6676412081]=63500,[17303641875]=3500,[12820715433]=1000,[11554103603]=10500,[4746292577]=5000,[11554264756]=18000,[8801995627]=63500,[15501893721]=63500,[7397565263]=63500,[75749441655962]=77500,[6982632122]=1500,[11410851476]=8500,[14343129826]=8000,[12757775222]=20000,[87630874548849]=63500,[11725889271]=16000,[13835053077]=16500,[79423109019674]=69500,[125540636897982]=18000,[118666889439649]=79500,[71091220191588]=21000,[86921710360798]=41500,[101869006032601]=20000,[101110457561961]=16500,[140022990256816]=63500,[100168311309116]=63500,[13974345356]=14000,[12792854135]=14000,[93556375284974]=14500,[99632820598737]=11500,[128614066781001]=15000,[112068921354030]=27500,[3131452093]=11500,[94733728494733]=9500,[4695588521]=8500,[2783959084]=19000,[836376693]=19000,[4843433327]=66500,[3052304894]=74000,[107348845353432]=25500,[132534299493006]=20500,[96225370149582]=25000,[79138012674866]=26000,[74566614556041]=25500,[127813886164608]=27000,[84803613886580]=27500,[85037105009809]=63500,[120028188529902]=22500,[105402915829012]=14000,[1329266704]=70000,[4947216628]=13500,[72015381801594]=63500,[137022318888712]=77000,[131922684973046]=63500,[99313817373559]=67000,[15059936417]=17500,[121948527526959]=5500,[129923898671032]=5000,[73257106599901]=13000,[87059217590619]=11500,[131637613314592]=3000,[75730721795242]=13000,[103809820683913]=5500,[86664943903751]=69500,[75621017852847]=63500,[70895461143874]=63500,[125787142138788]=500,[81243747834531]=4500,[129051289938686]=24500,[134937339779999]=7500,[126688679972643]=22500,[9930373240]=63500,[118840925833484]=63500,[83631847906705]=23000,[12089573241]=13000,[15015469155]=7500,[124013704220310]=18000,[70880619395363]=8500,[16452154247]=23500,[93422277147402]=69000,[71222633992816]=63500,[101719618368646]=24000,[16579558789]=25500,[18588070468]=25500,[18588053395]=20500,[1499082681]=14500,[3463183841]=23500,[431730384]=22500,[1103783724]=63500,[7092331508]=12000,[13444831702]=63500,[438195463]=11500,[5809785846]=21500,[15706847548]=63500,[87503337904060]=63500,[5487023113]=43500,[4909082176]=17000,[15311273900]=63500,[9545499629]=38500,[560325377]=63500,[576444465]=63500,[436720176]=63500,[4996937439]=67500,[2118764687]=52500,[1435177629]=18000,[772695241]=63500,[607550981]=69000,[1162019947]=76500,[5549063618]=32500,[14578854678]=63500,[5972477579]=63500,[107248336623941]=63500,[98305906232207]=63500,[1824185908]=79500,[15056443139]=8500,[11796928325]=72500,[884721414]=63500,[14182270450]=9000,[14961358306]=27500,[15903662503]=74500,[16218939509]=7500,[13868676222]=79000,[4464224771]=25000,[111494454911134]=21000,[6071739662]=63500,[3224293759]=63500,[1213373791]=79500,[590131471]=63500,[2474144253]=75000,[2744313464]=25000,[2518177916]=63500,[15084872864]=51000,[4809072541]=56500,[138024345748614]=47000,[85991896636316]=7500,[6274614487]=69000,[15161522231]=27000,[15616127684]=22500,[12257396304]=23000,[127026922296813]=39000,[11511640247]=40000,[126190832806951]=71000,[5973979386]=17500,[7724732726]=17000,[5611331869]=63500,[6501833600]=63500,[7205233886]=70000,[89385145596759]=63500,[18660217283]=12000,[10468675783]=14500,[88741221455613]=63500,[9084664827]=63500,[123772691907841]=63500,[14582695300]=7500,[8128676575]=63500,[11602203772]=25000,[5699364090]=21000,[81585264094038]=51500,[2098915079]=53000,[15121388536]=66000,[1074658737]=67000,[1079296706]=55000,[962194504]=55500,[5575894980]=18500,[116168634401177]=63500,[16388179108]=10000,[13948309746]=19500,[1315352916]=11500,[87509417534862]=63500,[14840856758]=40000,[14984408119]=38500,[117161695009647]=63500,[97856390601463]=63500,[119767338320263]=63500,[12624379885]=63500,[7249098507]=63500,[8462301101]=63500,[8631651981]=63500,[8631755151]=63500,[13778721268]=75500,[132959748946564]=63500,[139421353405484]=64000,[118064352416891]=63500,[120903225671360]=63500,[139017627542362]=75500,[13876916079]=68500,[8631671234]=78500,[15177463566]=13500,[120383454886093]=10000,[13781107752]=27500,[831537199]=50500,[8631687945]=63500,[8631779037]=63500,[13779001426]=63500,[108047896837515]=63500,[84913974138865]=73500,[8631708424]=66000,[16974592422]=14000,[125295721091210]=10500,[82077729005226]=63500,[78185107533537]=63500,[97526151621254]=67000,[131336649441063]=63500,[113247621156859]=79500,[14077919304]=15000,[87883117918210]=19500,[100997096188512]=67000,[139627508845654]=63500,[95337445087298]=18000,[99737839478071]=41000,[81270251381720]=25000,[15783597851]=62000,[134908184079208]=63500,[74448709325820]=23500,[13476230890]=9500,[15783604661]=15000,[14050651166]=14000,[6664977420]=7500,[16974632408]=73000,[78683849537161]=12500,[118245234493513]=66000,[11831115149]=11500,[8633623320]=24000,[99497707297997]=63500,[97197585182330]=63500,[75548914998494]=63500,[124377088956183]=63500,[82685608298333]=63500,[138030819896058]=65000,[137788979820718]=26500,[6046174032]=63500,[14484000414]=63500,[86114857882709]=63500,[115386784245524]=63500,[131596879156451]=63500,[10515393675]=63500,[4794620897]=63500,[4895301337]=63500,[5166805206]=63500,[7023449511]=24500,[130582847343989]=69500,[90420982954859]=63500,[14606133245]=20000,[8826223539]=77000,[129487569430492]=63500,[89357762722807]=63500,[132752004376816]=70000,[18606916311]=74000,[71399636217265]=63500,[5680301087]=67500,[1518645608]=63500,[5469366412]=37000,[2672925839]=19000,[6181344251]=50500,[1081054870]=63500,[5023083383]=21000,[956388277]=20500,[2464334422]=17000,[3370349046]=61500,[2109554081]=63500,[126913643075376]=63500,[1083553649]=62000,[5634486976]=21500,[134853942496739]=63500,[135386999852550]=22500,[5836356644]=70000,[5226567379]=63500,[1565502112]=63500,[15292591748]=21500,[967030317]=41000,[124231377168467]=16500,[102510983142980]=44500,[11386091941]=27000,[10890916980]=79000,[3138759121]=76500,[12774350601]=75000,[16648632315]=79500,[17750429143]=63500,[5314403333]=77000,[17747885612]=60500,[15453420630]=41500,[137408844484403]=63500,[3785693796]=48000,[16648534764]=63500,[13676876569]=33000,[2074367265]=63500,[98869180278083]=64000,[82170977556685]=63500,[86463016923018]=77500,[85720763562074]=63500,[15825720946]=34500,[133873637543203]=63500,[18813584989]=63500,[88020456613700]=27000,[4590342423]=30500,[125248485368695]=79000,[16662225397]=72000,[122599601118964]=56000,[109107120274465]=55500,[93824635464666]=39500,[124975585838444]=56500,[15732426819]=42000,[84116395504704]=63500,[14072460187]=63500,[97665782669251]=72500,[92750199062144]=7500,[82934586126898]=27500,[15422438906]=18000,[98599150857223]=22000,[136218865674437]=16000,[77234120970244]=18000,[8573407398]=66000,[71424043928165]=56000,[130104280419383]=66000,[121618494628389]=63500,[83255075167663]=79500,[8502567669]=77500,[14220615409]=13000,[18477705722]=11500,[12517077399]=26500,[89501380293235]=18500,[85545557857293]=19000,[84825703583648]=33500,[101535348409637]=73500,[134619700442692]=17000,[10322816406]=40000,[6678207951]=54500,[99324171797960]=34500,[16919855258]=63500,[96585015209179]=77500,[6198234501]=40500,[18968804462]=55000,[72762590768448]=75500,[5944585429]=63500,[90915822594460]=63500,[12852126150]=63500,[7369775838]=63500,[18428381654]=63500,[11454813848]=65000,[126863028392369]=63500,[14127820316]=68000,[116987323218059]=48500,[15705156210]=27500,[6447552174]=53000,[90412503682792]=63500,[18400219191]=31000,[73657715280895]=36000,[16582495088]=43500,[7381767636]=50000,[77430172245334]=53000,[92049531048374]=74500,[16430470279]=71500,[14502536751]=16500,[85305185315542]=76000,[79285824675024]=70000,[122714934882673]=63000,[10946069869]=31000,[15696366780]=33000,[7136404058]=41500,[7548737358]=66500,[15167783027]=59500,[16733661152]=56500,[7902431231]=53000,[7248675954]=61000,[9026168986]=68500,[80707179561942]=16000,[10793538519]=23000,[8171196077]=19000,[11998504162]=16500,[3163582983]=27500,[8162777342]=25000,[5960853118]=20500,[5964807969]=27000,[8162975494]=19500,[6722978612]=22500,[6488586232]=36500,[5341316038]=39000,[6142390595]=48000,[6488509571]=60000,[4831711976]=45500,[6488495469]=45500,[9375216039]=58500,[6455447834]=48500,[15338842173]=65500,[8446274549]=63500,[5964876806]=63500,[8165648360]=65000,[6505230129]=63500,[9384199616]=63500,[6787299892]=63500,[6505230940]=63500,[3689506876]=63500,[13876237691]=63500,[12636365073]=63500,[12621049095]=76500,[6455445003]=63500,[14396989921]=63500,[5029449227]=78500,[11674658234]=63500,[11484662835]=63500,[13429337035]=63500,[11382056477]=24000,[80212103951429]=26500,[5459824253]=63500,[12621050787]=78500,[105198371812252]=67000,[124798507529638]=39500,[76738452087604]=79500,[102885674981104]=63500,[128216714278616]=75500,[120196252098729]=63500,[98881995294054]=73500,[122273528955293]=63500,[137773512709519]=74500,[83641705983017]=62500,[74573745510706]=63500,[102019726797995]=74500,[15570425245]=44000,[75216977300015]=70500,[125655994023355]=63500,[76516442021518]=53500,[91498176431445]=63500,[125538194046026]=63500,[122313792956641]=63500,[102589072483955]=73500,[86995497093030]=63500,[140534031809179]=65000,[10443560347]=63500,[95423048146621]=63500,[131319439176543]=70500,[124039750585318]=70000,[87554525526000]=50500,[112685667527061]=39000,[116642119535875]=70000,[72101896533425]=54500,[76698897803837]=36500,[84478752542723]=31500,[105222831634134]=49500,[109462627025831]=63500,[70728690346102]=30500,[131686044597910]=63500,[101604148293803]=63500,[120612391944120]=74500,[125293782853552]=63500,[75354435184240]=55500,[18632819241]=76500,[18632881209]=38500,[105478169140045]=49000,[128716647842609]=41000,[14885532636]=65000,[12274864979]=49500,[81231921426493]=63500,[99950858190570]=63500,[17573405272]=63500,[81895753471926]=69500,[18323948106]=61500,[102839033215257]=55500,[12014837061]=28000,[116739608201251]=19000,[16949566103]=63500,[14307549017]=21000,[10253718453]=20000,[13607073567]=19500,[95060430454867]=16500,[18983373539]=27500,[17508312490]=63500,[11290616980]=71000,[107557100704001]=19000,[89790335131378]=63500,[80547880319610]=74000,[77439910826532]=63500,[134508752165617]=74500,[81560105275312]=18000,[128389783148999]=63500,[117766762488194]=63500,[90919421530654]=58500,[99150978070886]=26000,[91606294899206]=21500,[77220484371723]=73000,[86185820213136]=24000,[4552458072]=63500,[18720565335]=71000,[124697147814478]=63500,[75624653597148]=64500,[15564674144]=43000,[87891411586632]=73500,[132566833184808]=31000,[80693415563613]=57500,[126970846706113]=70000,[18270211852]=25500,[108337687172395]=20000,[138263043704514]=24500,[122468912421457]=72000,[73388686842934]=78500,[135517402543302]=79500,[137990594447175]=70500,[81765716375958]=74500,[104326582321744]=20500,[6763195401]=63500,[907988303]=20500,[6131796962]=22000,[1226570804]=24500,[993568649]=22000,[18370037060]=49500,[101488585369119]=68000,[18147277043]=44000,[122763783050786]=54000,[118344538644973]=31500,[85583075418361]=71000,[10371714775]=37500,[139013853108228]=67000,[90433833342790]=63500,[105804105689619]=80000,[72870106856318]=63500,[14141451141]=63500}


local function extractId(t) if not t then return end return tonumber(tostring(t):match("(%d+)")) end
local function getId(model)
    if not model then return end
    local sh=model:FindFirstChildWhichIsA("Shirt",true)
    if sh then local id=extractId(sh.ShirtTemplate); if id then return id end end
    local pa=model:FindFirstChildWhichIsA("Pants",true)
    if pa then local id=extractId(pa.PantsTemplate); if id then return id end end
end

-- shared resolver worker: drains pendingQueue
local resolverActive=0
local function spawnResolver()
    if resolverActive>=6 then return end
    resolverActive=resolverActive+1
    task.spawn(function()
        while true do
            local id=table.remove(pendingQueue,1)
            if not id then break end
            local ok,info=pcall(function() return MPS:GetProductInfo(id,Enum.InfoType.Asset) end)
            if ok and info and info.Name and info.Name~="" and not looksLikeUuid(info.Name) then
                nameCache[id]=info.Name
            else nameCache[id]=false end
        end
        resolverActive=resolverActive-1
    end)
end
local function queueResolve(id)
    if not id then return end
    if nameCache[id]~=nil then return end
    -- check local DB first — instant, no marketplace call needed
    local dbName=ITEM_DB[id]
    if dbName then nameCache[id]=dbName return end
    nameCache[id]="PENDING"
    table.insert(pendingQueue,id)
    spawnResolver()
end

local function preloadAllNames()
    for _,zone in ipairs(Workspace:GetChildren()) do
        if zone.Name:match("^Shop_ShopZone_") then
            local items=zone:FindFirstChild("ItemSlots")
            if items then
                for _,slot in ipairs(items:GetChildren()) do
                    if slot.Name:match("^Slot_") then
                        queueResolve(getId(slot:FindFirstChild("Mannequin") or slot))
                    end
                end
            end
        end
    end
end

local function chromeColor(t)
    local TAU=6.2831853
    local r=0.86+0.14*math.sin(t)
    local g=0.86+0.14*math.sin(t+TAU/3)
    local b=0.86+0.14*math.sin(t+2*TAU/3)
    return Color3.new(math.clamp(r,0,1),math.clamp(g,0,1),math.clamp(b,0,1))
end

local function makeTag(adornee,source)
    local bb=Instance.new("BillboardGui")
    bb.Name="GC_ESP" bb.AlwaysOnTop=true bb.LightInfluence=0
    bb.Size=UDim2.fromOffset(S.BoxWidth,26)
    bb.StudsOffset=Vector3.new(0,3.2,0)
    bb.MaxDistance=math.huge bb.Adornee=adornee
    local frame=Instance.new("Frame",bb)
    frame.Size=UDim2.fromScale(1,1) frame.BackgroundColor3=Color3.new(0,0,0)
    frame.BackgroundTransparency=0.45 frame.BorderSizePixel=0
    local cr=Instance.new("UICorner",frame); cr.CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",frame)
    stroke.Color=LEG_COLOR stroke.Thickness=1.2
    local nm=Instance.new("TextLabel",frame)
    nm.Size=UDim2.new(1,-6,1,0) nm.Position=UDim2.fromOffset(3,0)
    nm.BackgroundTransparency=1 nm.TextColor3=LEG_COLOR
    nm.Font=Enum.Font.GothamBold nm.TextSize=S.FontSize
    nm.TextXAlignment=Enum.TextXAlignment.Center nm.Text=""
    bb.Enabled=false bb.Parent=PG
    return {Gui=bb,Frame=frame,Stroke=stroke,NM=nm,
        Adornee=adornee,AssetId=nil,Source=source,RawName=nil,Resolved=false}
end

local function removeKey(k) local t=TAGS[k] if not t then return end if t.Gui then t.Gui:Destroy() end TAGS[k]=nil end
local function clearAll() for k in pairs(TAGS) do removeKey(k) end end

local function tagShop(slot)
    if TAGS[slot] then return false end
    local hl=slot:FindFirstChild("ItemHighlight",true) or slot:FindFirstChildWhichIsA("Highlight",true)
    if not hl or not isLegColor(hl.OutlineColor) then return false end
    local manny=slot:FindFirstChild("Mannequin")
    if not manny then return false end
    local hasCloth=manny:FindFirstChildWhichIsA("Shirt",true) or manny:FindFirstChildWhichIsA("Pants",true)
    if not hasCloth then return false end
    local part=manny.PrimaryPart or manny:FindFirstChildWhichIsA("BasePart")
        or hl.Adornee or slot:FindFirstChildWhichIsA("BasePart",true) or slot
    if not part then return false end
    local id=getId(manny)
    local tag=makeTag(part,"shop") tag.AssetId=id
    queueResolve(id)
    TAGS[slot]=tag return true
end

local function tagFloor(model)
    if TAGS[model] then return false end
    local ba=model:FindFirstChild("BillboardAnchor") if not ba then return false end
    local isLeg=false
    for _,d in ipairs(ba:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text and d.Text:lower():find("legend") then
            isLeg=true break end
    end
    if not isLeg then return false end
    local id=getId(model)
    if not id then return false end
    local tag=makeTag(ba,"floor") tag.AssetId=id
    queueResolve(id)
    TAGS[model]=tag return true
end

local function scanAll()
    local n=0
    for _,zone in ipairs(Workspace:GetChildren()) do
        if zone.Name:match("^Shop_ShopZone_") then
            local items=zone:FindFirstChild("ItemSlots")
            if items then
                for i,slot in ipairs(items:GetChildren()) do
                    if slot.Name:match("^Slot_") and tagShop(slot) then n=n+1 end
                    if (i%80)==0 then task.wait() end
                end
            end
        end
    end
    local dr=Workspace:FindFirstChild("DroppedItems")
    if dr then
        for _,m in ipairs(dr:GetChildren()) do
            if m:IsA("Model") and not Players:GetPlayerFromCharacter(m) and tagFloor(m) then n=n+1 end
        end
    end
    return n
end

local function unbind() for _,c in ipairs(CONNS) do c:Disconnect() end CONNS={} end
local function bindLive()
    local function bindDr(dr)
        table.insert(CONNS,dr.ChildAdded:Connect(function(c)
            if not S.On or not c:IsA("Model") then return end
            task.wait(0.3) tagFloor(c)
        end))
        table.insert(CONNS,dr.ChildRemoved:Connect(function(c) removeKey(c) end))
    end
    local dr=Workspace:FindFirstChild("DroppedItems")
    if dr then bindDr(dr) end
    table.insert(CONNS,Workspace.ChildAdded:Connect(function(c)
        if c.Name=="DroppedItems" then bindDr(c) end
    end))
end

local function getPlayerPos()
    local ch=LP.Character
    if ch then local hrp=ch:FindFirstChild("HumanoidRootPart") if hrp then return hrp.Position end end
    return Camera.CFrame.Position
end

--==================== HUD (отключён — без плавающей менюшки) ====================--

local renderConn
local function startRender()
    if renderConn then return end
    renderConn=RunService.RenderStepped:Connect(function()
        if not S.On then return end
        if S.Chrome then S.Color=chromeColor(tick()*0.9)
        else S.Color=S.PickedColor end

        local pos=getPlayerPos()
        local list={}
        local searchLow=S.Search:lower()
        local hasSearch=#searchLow>0

        for _,t in pairs(TAGS) do
            -- lazy resolve
            if t.AssetId and not t.Resolved then
                local n=nameCache[t.AssetId]
                if n==nil then queueResolve(t.AssetId)
                elseif type(n)=="string" and n~="PENDING" then t.Resolved=true t.RawName=n
                elseif n==false then t.Resolved=true end
            end
            -- match check
            local matched=false
            if hasSearch and t.RawName and t.RawName:lower():find(searchLow,1,true) then matched=true end
            t._matched=matched

            local d=999999 local show=true
            if t.Adornee and t.Adornee.Parent then
                d=(t.Adornee.Position-pos).Magnitude
                if d>S.MaxDist and not matched then show=false end
            else show=false end
            if hasSearch and S.MatchOnly and not matched then show=false end
            if show then t._d=d table.insert(list,t)
            elseif t.Gui then t.Gui.Enabled=false end
        end

        -- sort: matches first, then by distance
        table.sort(list, function(a,b)
            if a._matched~=b._matched then return a._matched end
            return a._d<b._d
        end)

        local cap=math.min(#list,S.MaxVisible)
        for i,t in ipairs(list) do
            -- always show matches even past cap
            if (i<=cap or t._matched) and t.Gui then
                t.Gui.Enabled=true
                local nm=t.RawName or "\xe2\x80\xa6"
                if #nm>34 then nm=nm:sub(1,33).."\xe2\x80\xa6" end
                local prefix=""
                if t._matched then prefix="\xe2\x96\xb6 " end
                local priceStr=""
                if t.AssetId and ITEM_PRICES[t.AssetId] then
                    priceStr=" - $"..tostring(ITEM_PRICES[t.AssetId])
                end
                t.NM.Text=prefix..nm..priceStr
                t.NM.TextSize=S.FontSize
                if t._matched then
                    t.NM.TextColor3=Color3.fromRGB(0,255,140)
                    t.Stroke.Color=Color3.fromRGB(0,255,140)
                    t.Stroke.Thickness=2.2
                else
                    t.NM.TextColor3=S.Color
                    t.Stroke.Color=S.Color
                    t.Stroke.Thickness=1.2
                end
                t.Gui.Size=UDim2.fromOffset(S.BoxWidth,26)
                t.Frame.BackgroundTransparency=S.Transparency
            elseif t.Gui then t.Gui.Enabled=false end
        end
    end)
end
local function stopRender()
    if renderConn then renderConn:Disconnect() renderConn=nil end
    for _,t in pairs(TAGS) do if t.Gui then t.Gui.Enabled=false end end
end

local function start() S.On=true bindLive() startRender() scanAll() end
local function stop() S.On=false unbind() stopRender() clearAll() end
local function refresh() if not S.On then return end clearAll() scanAll() end




--==================== HvH ANTI-AIM (fun / visual) ====================--
-- Чистый визуал. Сервер в Роблоксе хитрег держит сам, от урона не спасёт.
local HVH = {
    On=false,
    YawIdx=1,         -- 1=Off 2=Static 3=Spin 4=Jitter 5=Random 6=Sway
    PitchIdx=1,       -- 1=Off 2=Up(Fake-Down) 3=Down 4=Zero 5=Fake(alt)
    StaticYaw=180,
    SpinSpeed=720,    -- deg/sec
    JitterAmt=180,
    Tilt=0,           -- deg
    Desync=false,     -- попытка визуального рассинхрона верх/низ
    BackTrack=false,  -- перс смотрит против движения
    FakeWalk=false,   -- жёст ходьбы в покое
}
local YAW_MODES = {"Off","Static","Spin","Jitter","Random","Sway"}
local PITCH_MODES = {"Off","Up","Down","Zero","Fake"}

local hvhConn, hvhCharAdded
local hvhStartTick = 0
local lastJitter = 1
local lastFakePitch = 1
local walkAnimTrack
local _savedC0 = {}        -- [Motor6D] = original C0 (for Desync restore)
local _savedAutoRotate

local function getChar()
    local c = LP.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    return c, hrp, hum
end

local function computeYaw(elapsed)
    local mode = YAW_MODES[HVH.YawIdx] or "Off"
    if mode == "Off" then return nil end
    if mode == "Static" then return math.rad(HVH.StaticYaw) end
    if mode == "Spin" then return math.rad((HVH.SpinSpeed * elapsed) % 360) end
    if mode == "Jitter" then
        local phase = math.floor(elapsed*15) % 2
        lastJitter = (phase == 0) and 1 or -1
        return math.rad(HVH.JitterAmt * lastJitter)
    end
    if mode == "Random" then
        if math.floor(elapsed*8) % 1 == 0 then end -- noop
        return math.rad(math.random(-180, 180))
    end
    if mode == "Sway" then
        return math.rad(math.sin(elapsed*3) * 180)
    end
    return nil
end

local function computePitch(elapsed)
    local mode = PITCH_MODES[HVH.PitchIdx] or "Off"
    if mode == "Off" then return 0 end
    if mode == "Up" then return math.rad(-89) end       -- в Roblox положительный X опускает нос вниз, инвертим
    if mode == "Down" then return math.rad(89) end
    if mode == "Zero" then return 0 end
    if mode == "Fake" then
        local phase = math.floor(elapsed*3) % 2
        return math.rad(phase == 0 and -89 or 89)
    end
    return 0
end

local function applyHvhChar()
    local c,_,hum = getChar()
    if not c then return end
    if _savedAutoRotate == nil then _savedAutoRotate = hum.AutoRotate end
    -- AutoRotate теперь управляется динамически в render loop
end

local function _restoreWaists()
    for waist, c0 in pairs(_savedC0) do
        if waist and waist.Parent then
            pcall(function() waist.C0 = c0 end)
        end
    end
    _savedC0 = {}
end

local function startHvh()
    if hvhConn then return end
    HVH.On = true
    hvhStartTick = tick()
    applyHvhChar()
    hvhCharAdded = LP.CharacterAdded:Connect(function()
        task.wait(0.4)
        _savedC0 = {}
        _savedAutoRotate = nil
        applyHvhChar()
    end)
    hvhConn = RunService.RenderStepped:Connect(function(dt)
        if not HVH.On then return end
        local c, hrp, hum = getChar()
        if not c then return end

        local elapsed = tick() - hvhStartTick
        local yaw = computeYaw(elapsed)
        local pitch = computePitch(elapsed)
        local tilt = math.rad(HVH.Tilt or 0)
        local needsForcedYaw = (yaw ~= nil) or HVH.BackTrack

        -- AutoRotate: off ТОЛЬКО когда насильно крутим yaw
        if needsForcedYaw then
            if hum.AutoRotate then hum.AutoRotate = false end
        else
            if not hum.AutoRotate then hum.AutoRotate = true end
        end

        -- BackTrack: если движемся — развернём на 180 от MoveDirection
        if HVH.BackTrack then
            local md = hum.MoveDirection
            if md.Magnitude > 0.1 then
                local angle = math.atan2(-md.X, -md.Z) -- look opposite
                yaw = (yaw or 0) + angle
            end
        end

        if yaw or pitch ~= 0 or tilt ~= 0 then
            local pos = hrp.Position
            local baseYaw = yaw or select(2, hrp.CFrame:ToOrientation())
            hrp.CFrame = CFrame.new(pos) * CFrame.Angles(pitch, baseYaw, tilt)
        end

        -- Desync: крутим верхнюю часть через Waist Motor6D (абсолютно, от saved C0)
        local torso = c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
        local waist = torso and (torso:FindFirstChild("Waist") or torso:FindFirstChild("Neck"))
        if waist and waist:IsA("Motor6D") then
            if HVH.Desync then
                if not _savedC0[waist] then _savedC0[waist] = waist.C0 end
                local off = math.sin(elapsed*8) * math.rad(45)
                waist.C0 = _savedC0[waist] * CFrame.Angles(0, off, 0)
            else
                if _savedC0[waist] then
                    pcall(function() waist.C0 = _savedC0[waist] end)
                    _savedC0[waist] = nil
                end
            end
        end
    end)
end

local function stopHvh()
    HVH.On = false
    if hvhConn then hvhConn:Disconnect() hvhConn = nil end
    if hvhCharAdded then hvhCharAdded:Disconnect() hvhCharAdded = nil end
    _restoreWaists()
    local _,_,hum = getChar()
    if hum then
        hum.AutoRotate = (_savedAutoRotate ~= nil) and _savedAutoRotate or true
    end
    _savedAutoRotate = nil
end

local function cycleYaw()
    HVH.YawIdx = HVH.YawIdx % #YAW_MODES + 1
    return YAW_MODES[HVH.YawIdx]
end
local function cyclePitch()
    HVH.PitchIdx = HVH.PitchIdx % #PITCH_MODES + 1
    return PITCH_MODES[HVH.PitchIdx]
end

-- FUN PRESETS: однокнопочные выборы как в менюхах CS2
local function presetFun()
    HVH.YawIdx = 4; HVH.JitterAmt = 180
    HVH.PitchIdx = 5
    HVH.Tilt = 0
    HVH.BackTrack = true
    HVH.Desync = true
end
local function presetSpin()
    HVH.YawIdx = 3; HVH.SpinSpeed = 1440
    HVH.PitchIdx = 2
    HVH.Tilt = 0
    HVH.BackTrack = false
    HVH.Desync = false
end
local function presetLegit()
    HVH.YawIdx = 2; HVH.StaticYaw = 180
    HVH.PitchIdx = 4
    HVH.Tilt = 0
    HVH.BackTrack = false
    HVH.Desync = false
end
local function presetRetard()
    HVH.YawIdx = 5
    HVH.PitchIdx = 5
    HVH.Tilt = 45
    HVH.BackTrack = true
    HVH.Desync = true
end
--==================== END HvH ====================--


--==================== HvH ESP (CS:GO style, Drawing API)  v2 clean ====================--
local HESP = {
    On=false,
    Skeleton=false,
    ChamsColor=Color3.fromRGB(255,60,60), -- legacy name; used as global ESP color (box/tracer/HP outline)
    Watermark=false,
    HitMarker=false,
    SpecList=false,
    HealthBar=false,
    Tracers=false,
    TracerOrigin="Bottom", -- Bottom | Mouse | Top
    MaxDist=2000,
}

-- runtime state
local hespConn         -- RenderStepped connection
local hespPlrRem       -- PlayerRemoving connection (single, owned)
local drawMap   = {}   -- [Player] = {box,boxOutline,name,dist,hpBg,hp,snap,skel={...}}
local hitLines  = {}
local watermark, watermarkBg
local specTexts = {}
local lastHpMap = {}
local lastHitTick = 0

-- fps avg (no Wait() inside render loop!)
local _fpsLast, _fpsAvg = tick(), 60

local R15_BONES = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local R6_BONES = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local SKEL_SLOTS = 14  -- enough for R15

local function getBones(char)
    if char:FindFirstChild("UpperTorso") then return R15_BONES, #R15_BONES end
    if char:FindFirstChild("Torso")      then return R6_BONES,  #R6_BONES  end
    return nil, 0
end

local hasDrawing = (typeof and typeof(Drawing) == "table") or (type(Drawing) == "table" or type(Drawing) == "userdata")

local function safeNew(kind, props)
    if not hasDrawing then return nil end
    local ok, d = pcall(Drawing.new, kind)
    if not ok or not d then return nil end
    for k,v in pairs(props) do pcall(function() d[k] = v end) end
    return d
end

local function safeRemove(obj)
    if obj then pcall(function() obj:Remove() end) end
end
local function safeHide(obj)
    if obj then pcall(function() obj.Visible = false end) end
end

-- ---------------- per-player drawing object pool ----------------
local function acquire(plr)
    local d = drawMap[plr]
    if d then return d end
    d = {}
    d.boxOutline = safeNew("Square", {Thickness=3, Color=Color3.new(0,0,0),  Filled=false, Transparency=1, Visible=false, ZIndex=1})
    d.box        = safeNew("Square", {Thickness=1, Color=Color3.fromRGB(255,255,255), Filled=false, Transparency=1, Visible=false, ZIndex=2})
    d.hpBg       = safeNew("Square", {Thickness=0, Color=Color3.new(0,0,0),  Filled=true,  Transparency=1, Visible=false, ZIndex=1})
    d.hp         = safeNew("Square", {Thickness=0, Color=Color3.fromRGB(0,255,0), Filled=true, Transparency=1, Visible=false, ZIndex=2})
    d.name       = safeNew("Text",   {Size=13, Center=true,  Outline=true, Color=Color3.new(1,1,1), OutlineColor=Color3.new(0,0,0), Visible=false, Font=2, ZIndex=3})
    d.dist       = safeNew("Text",   {Size=12, Center=true,  Outline=true, Color=Color3.fromRGB(220,220,220), OutlineColor=Color3.new(0,0,0), Visible=false, Font=2, ZIndex=3})
    d.snap       = safeNew("Line",   {Thickness=1, Color=Color3.new(1,1,1), Transparency=1, Visible=false, ZIndex=1})
    d.skel = {}
    for i=1,SKEL_SLOTS do
        d.skel[i] = safeNew("Line", {Thickness=1, Color=Color3.new(1,1,1), Transparency=1, Visible=false, ZIndex=2})
    end
    drawMap[plr] = d
    return d
end

local function hideAll(d)
    if not d then return end
    safeHide(d.box); safeHide(d.boxOutline)
    safeHide(d.hpBg); safeHide(d.hp)
    safeHide(d.name); safeHide(d.dist); safeHide(d.snap)
    for i=1,#d.skel do safeHide(d.skel[i]) end
end

local function release(plr)
    local d = drawMap[plr]
    if d then
        safeRemove(d.box); safeRemove(d.boxOutline)
        safeRemove(d.hpBg); safeRemove(d.hp)
        safeRemove(d.name); safeRemove(d.dist); safeRemove(d.snap)
        for i=1,#d.skel do safeRemove(d.skel[i]) end
        drawMap[plr] = nil
    end
    lastHpMap[plr] = nil
end

local function hpColor(pct)
    pct = math.clamp(pct, 0, 1)
    if pct > 0.5 then
        return Color3.fromRGB(math.floor((1-pct)*2*255), 255, 0)
    end
    return Color3.fromRGB(255, math.floor(pct*2*255), 0)
end

-- ---------------- bbox жёстко якорен к HumanoidRootPart ----------------
-- НИКОГДА не используем char:GetBoundingBox() — в играх вроде TSUM персонажи
-- имеют прикреплённые эффекты/ауры/оружие на 100+ студов, и центр bbox
-- уезжает далеко от реального игрока → бокс растягивается на пол-экрана. HRP всегда
-- в центре хуманоида, не зависит от аксессуаров.
local function getScreenBox(char, hrp)
    -- Build a WORLD-AXIS-ALIGNED bbox around HRP center.
    -- Using cf:ToWorldSpace with local offsets rotates the box with the character
    -- and makes a lying/tilted rig project to a hugely-stretched 2D rect. World-axis
    -- offsets keep the bbox stable regardless of character orientation.
    local center = hrp.Position
    local isR15  = char:FindFirstChild("UpperTorso") ~= nil
    local size   = isR15 and Vector3.new(4, 6, 2.5) or Vector3.new(4, 5, 2.5)
    local sx, sy, sz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5

    local vp = Camera.ViewportSize
    -- Hard distance guards: too close = projection explodes; too far = irrelevant.
    local dist = (Camera.CFrame.Position - center).Magnitude
    if dist < 3 then return nil end

    local minX, minY =  math.huge,  math.huge
    local maxX, maxY = -math.huge, -math.huge

    -- Require ALL 8 corners to be safely in front of the camera (Z >= 5 studs).
    -- This avoids the partial-behind-camera projection blow-up that produces the
    -- half-screen floating box.
    for ix = -1, 1, 2 do for iy = -1, 1, 2 do for iz = -1, 1, 2 do
        local world = center + Vector3.new(sx*ix, sy*iy, sz*iz)
        local pt = Camera:WorldToViewportPoint(world)
        if pt.Z < 5 then return nil end
        if pt.X < minX then minX = pt.X end
        if pt.X > maxX then maxX = pt.X end
        if pt.Y < minY then minY = pt.Y end
        if pt.Y > maxY then maxY = pt.Y end
    end end end

    local w = maxX - minX
    local h = maxY - minY
    if w <= 0 or h <= 0 then return nil end

    -- HARD CAPS: a humanoid bbox can never be larger than the screen itself.
    -- These catch any pathological projection that slipped past the Z guard.
    if h > vp.Y * 0.85 then return nil end
    if w > vp.X * 0.55 then return nil end

    -- Expected on-screen height from FOV. Real bbox shouldn't exceed 2.2x expected.
    local fovRad    = math.rad(Camera.FieldOfView or 70)
    local expectedH = (size.Y * vp.Y) / (2 * dist * math.tan(fovRad * 0.5))
    if expectedH > 0 and h > expectedH * 2.2 then return nil end
    if expectedH > 0 and w > expectedH * 2.2 then return nil end

    -- Reject entirely-off-screen boxes early.
    if maxX < 0 or minX > vp.X then return nil end
    if maxY < 0 or minY > vp.Y then return nil end

    -- Clamp to viewport (no negative coords, no overflow). Drawing API handles partials.
    minX = math.max(0, math.floor(minX))
    minY = math.max(0, math.floor(minY))
    maxX = math.min(vp.X, math.ceil(maxX))
    maxY = math.min(vp.Y, math.ceil(maxY))
    return minX, minY, maxX, maxY
end

-- ---------------- watermark ----------------
local function ensureWatermark()
    if watermark then return end
    watermarkBg = safeNew("Square", {Thickness=0, Color=Color3.new(0,0,0), Filled=true, Transparency=0.55, Visible=false, ZIndex=998})
    watermark   = safeNew("Text",   {Size=13, Center=false, Outline=true, Color=Color3.new(1,1,1), OutlineColor=Color3.new(0,0,0), Font=2, Visible=false, ZIndex=999})
end

local function updateWatermark(dt)
    if not watermark then return end
    -- moving avg FPS without yielding
    if dt and dt > 0 then
        _fpsAvg = _fpsAvg * 0.9 + (1/dt) * 0.1
    end
    local ping = 0
    pcall(function()
        local s = Stats and Stats.Network and Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
        if s then ping = math.floor(s:GetValue()) end
    end)
    local _wmNick = (NICK and NICK.Hide and NICK.FakeText) or LP.Name or "?"
    local txt = string.format("Fekality  |  %s  |  %d fps  |  %d ms", _wmNick, math.floor(_fpsAvg), ping)
    watermark.Text = txt
    local bounds = watermark.TextBounds
    if not bounds or bounds.X == 0 then bounds = Vector2.new(#txt * 7, 14) end
    local vp = Camera.ViewportSize
    local pad = 6
    local x = vp.X - bounds.X - pad*2 - 10
    watermark.Position = Vector2.new(x + pad, 10 + pad)
    watermark.Color    = HESP.ChamsColor
    watermark.Visible  = true
    if watermarkBg then
        watermarkBg.Size = Vector2.new(bounds.X + pad*2, bounds.Y + pad*2)
        watermarkBg.Position = Vector2.new(x, 10)
        watermarkBg.Visible = true
    end
end

-- ---------------- hit marker ----------------
local function ensureHitMarker()
    if #hitLines > 0 then return end
    for i=1,4 do
        hitLines[i] = safeNew("Line", {Thickness=2, Color=Color3.fromRGB(255,255,255), Transparency=1, Visible=false, ZIndex=997})
    end
end

local function flashHit() lastHitTick = tick() end

local function updateHitMarker()
    local alive = tick() - lastHitTick
    if alive < 0 or alive > 0.35 then
        for i=1,#hitLines do safeHide(hitLines[i]) end
        return
    end
    local m = UIS:GetMouseLocation()
    local cx, cy = m.X, m.Y
    local s, g = 6, 2
    local trans = math.clamp(1 - alive/0.35, 0, 1)
    local cfg = {
        {Vector2.new(cx-s-g, cy-s-g), Vector2.new(cx-g,   cy-g)},
        {Vector2.new(cx+g,   cy-g),   Vector2.new(cx+s+g, cy-s-g)},
        {Vector2.new(cx-s-g, cy+s+g), Vector2.new(cx-g,   cy+g)},
        {Vector2.new(cx+g,   cy+g),   Vector2.new(cx+s+g, cy+s+g)},
    }
    for i,l in ipairs(hitLines) do
        if l then
            l.From, l.To = cfg[i][1], cfg[i][2]
            l.Transparency = trans
            l.Visible = true
        end
    end
end

-- ---------------- spectator / player list ----------------
-- Roblox не даёт API "кто спекает" (Camera локальный). Поэтому показываем
-- список всех игроков с индикаторами: ● ALIVE / ● DEAD / ● LOBBY (= вероятный спек).
local specHeader
local function updateSpecList()
    local rows = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch  = p.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local status, col
            if not ch then
                status, col = "LOBBY", Color3.fromRGB(180,180,180)
            elseif (not hum) or hum.Health <= 0 then
                status, col = "DEAD",  Color3.fromRGB(255,80,80)
            else
                status, col = "ALIVE", Color3.fromRGB(120,255,120)
            end
            rows[#rows+1] = { name = p.Name, status = status, color = col }
        end
    end

    if not specHeader then
        specHeader = safeNew("Text", {Size=13, Center=false, Outline=true, Color=Color3.new(1,1,1), OutlineColor=Color3.new(0,0,0), Font=2, Visible=false, ZIndex=997})
    end

    while #specTexts < #rows do
        specTexts[#specTexts+1] = safeNew("Text", {Size=12, Center=false, Outline=true, Color=Color3.new(1,1,1), OutlineColor=Color3.new(0,0,0), Font=2, Visible=false, ZIndex=996})
    end

    local vp = Camera.ViewportSize
    local rightX = vp.X - 180   -- фиксированная анкор-позиция справа (не зависим от TextBounds)
    if rightX < 50 then rightX = 50 end
    local y = 80

    if specHeader then
        specHeader.Text = string.format("Players (%d)", #rows)
        specHeader.Position = Vector2.new(rightX, y)
        specHeader.Color = HESP.ChamsColor
        specHeader.Visible = true
        y = y + 18
    end

    for i,t in ipairs(specTexts) do
        if i <= #rows and t then
            local r = rows[i]
            t.Text = string.format("[%s] %s", r.status, r.name)
            t.Position = Vector2.new(rightX, y)
            t.Color = r.color
            t.Visible = true
            y = y + 15
        elseif t then
            t.Visible = false
        end
    end
end

local function hideSpecList()
    if specHeader then specHeader.Visible = false end
    for i=1,#specTexts do safeHide(specTexts[i]) end
end

-- ---------------- per-player update (all in pcall at caller) ----------------
local function updatePlayer(plr, lpRoot)
    local d = drawMap[plr] or acquire(plr)
    if not d or not d.box then return end

    local char = plr.Character
    if not char or not char.Parent then
        hideAll(d); return
    end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local hrp  = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if (not hum) or (hum.Health <= 0) or (not hrp) then
        hideAll(d); return
    end

    -- hit-detection proxy
    local prev = lastHpMap[plr]
    if prev and hum.Health < prev - 0.5 and HESP.HitMarker then flashHit() end
    lastHpMap[plr] = hum.Health

    -- distance gate
    local dist = lpRoot and (lpRoot.Position - hrp.Position).Magnitude or 0
    if dist > HESP.MaxDist then
        hideAll(d); return
    end

    local minX, minY, maxX, maxY = getScreenBox(char, hrp)
    if not minX then hideAll(d); return end
    local w = maxX - minX
    local h = maxY - minY
    if w < 2 or h < 2 then hideAll(d); return end

    -- clamp drawing rect into screen with margin so Drawing API doesn't choke
    local vp = Camera.ViewportSize
    local clX = math.max(-20, math.min(minX, vp.X + 20))
    local clY = math.max(-20, math.min(minY, vp.Y + 20))
    local clW = math.max(2, math.min(w, vp.X + 40))
    local clH = math.max(2, math.min(h, vp.Y + 40))

    -- 2D box
    d.boxOutline.Size     = Vector2.new(clW, clH)
    d.boxOutline.Position = Vector2.new(clX, clY)
    d.boxOutline.Visible  = true
    d.box.Size            = Vector2.new(clW, clH)
    d.box.Position        = Vector2.new(clX, clY)
    d.box.Color           = HESP.ChamsColor
    d.box.Visible         = true

    -- name
    local nm = plr.DisplayName
    if nm == nil or nm == "" then nm = plr.Name end
    d.name.Text     = nm
    d.name.Position = Vector2.new(clX + clW*0.5, clY - 16)
    d.name.Visible  = true

    -- distance
    local dTxt
    if dist >= 1000 then dTxt = string.format("[%.1fk]", dist/1000)
    else dTxt = string.format("[%dm]", math.floor(dist)) end
    d.dist.Text     = dTxt
    d.dist.Position = Vector2.new(clX + clW*0.5, clY + clH + 2)
    d.dist.Visible  = true

    -- hp bar
    if HESP.HealthBar then
        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bw = 3
        d.hpBg.Size     = Vector2.new(bw+2, clH+2)
        d.hpBg.Position = Vector2.new(clX - bw - 5, clY - 1)
        d.hpBg.Visible  = true
        d.hp.Size       = Vector2.new(bw, clH * pct)
        d.hp.Position   = Vector2.new(clX - bw - 4, clY + clH*(1-pct))
        d.hp.Color      = hpColor(pct)
        d.hp.Visible    = true
    else
        d.hpBg.Visible = false
        d.hp.Visible   = false
    end

    -- tracer
    if HESP.Tracers then
        local ox, oy
        if HESP.TracerOrigin == "Top" then
            ox, oy = vp.X*0.5, 0
        elseif HESP.TracerOrigin == "Mouse" then
            local m = UIS:GetMouseLocation(); ox, oy = m.X, m.Y
        else
            ox, oy = vp.X*0.5, vp.Y
        end
        d.snap.From    = Vector2.new(ox, oy)
        d.snap.To      = Vector2.new(clX + clW*0.5, clY + clH)
        d.snap.Color   = HESP.ChamsColor
        d.snap.Visible = true
    else
        d.snap.Visible = false
    end

    -- skeleton
    if HESP.Skeleton then
        local bones, cnt = getBones(char)
        if bones then
            for i=1,SKEL_SLOTS do d.skel[i].Visible = false end
            for i=1,cnt do
                local a = char:FindFirstChild(bones[i][1])
                local b = char:FindFirstChild(bones[i][2])
                local ln = d.skel[i]
                if a and b and ln then
                    local ap = Camera:WorldToViewportPoint(a.Position)
                    local bp = Camera:WorldToViewportPoint(b.Position)
                    if ap.Z > 0 and bp.Z > 0 then
                        ln.From = Vector2.new(ap.X, ap.Y)
                        ln.To   = Vector2.new(bp.X, bp.Y)
                        ln.Visible = true
                    else
                        ln.Visible = false
                    end
                end
            end
        end
    else
        for i=1,SKEL_SLOTS do d.skel[i].Visible = false end
    end
end

-- ---------------- start / stop ----------------
local function stopHesp()
    HESP.On = false
    if hespConn   then hespConn:Disconnect();   hespConn   = nil end
    if hespPlrRem then hespPlrRem:Disconnect(); hespPlrRem = nil end
    for plr,_ in pairs(drawMap)  do release(plr) end
    drawMap, lastHpMap = {}, {}
    if watermark   then safeRemove(watermark);   watermark   = nil end
    if watermarkBg then safeRemove(watermarkBg); watermarkBg = nil end
    for i=1,#hitLines  do safeRemove(hitLines[i]) end ; hitLines  = {}
    for i=1,#specTexts do safeRemove(specTexts[i]) end ; specTexts = {}
    if specHeader then safeRemove(specHeader); specHeader = nil end
end

local function startHesp()
    if hespConn then return end
    if not hasDrawing then
        warn("[Fekality] Drawing API not available on this executor — ESP disabled.")
        return
    end
    HESP.On = true
    _fpsLast = tick()

    hespPlrRem = Players.PlayerRemoving:Connect(function(p) release(p) end)

    hespConn = RunService.RenderStepped:Connect(function(dt)
        if not HESP.On then return end
        local now = tick()
        if dt == nil or dt <= 0 then dt = math.max(now - _fpsLast, 1/240) end
        _fpsLast = now

        -- cached local-player root
        local lpChar = LP.Character
        local lpRoot = lpChar and (lpChar:FindFirstChild("HumanoidRootPart") or lpChar:FindFirstChild("Torso"))

        for _,plr in ipairs(Players:GetPlayers()) do
            if plr ~= LP then
                local ok, err = pcall(updatePlayer, plr, lpRoot)
                if not ok then
                    -- never let one bad player kill the whole loop
                    -- (silently swallow; release on PlayerRemoving will clean up)
                end
            end
        end

        if HESP.Watermark then ensureWatermark(); pcall(updateWatermark, dt)
        else
            if watermark   then watermark.Visible   = false end
            if watermarkBg then watermarkBg.Visible = false end
        end

        if HESP.HitMarker then ensureHitMarker(); pcall(updateHitMarker)
        else for i=1,#hitLines do safeHide(hitLines[i]) end end

        if HESP.SpecList then pcall(updateSpecList) else hideSpecList() end
    end)
end
--==================== END HvH ESP ====================--

task.spawn(preloadAllNames)


--==================== draggable helper ====================--
local function makeDraggable(handle, target)
    local dragging,dragStart,startPos=false,nil,nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1
        or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true dragStart=input.Position startPos=target.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement
        or input.UserInputType==Enum.UserInputType.Touch then
            local d=input.Position-dragStart
            target.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                                     startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end
--==================== Fatality UI ====================--
local _TextSvc = game:GetService("TextService")
local Window = Fatality.new({ Name = "Fekality", Expire = "never" })

-- ===== title fit fix =====
task.spawn(function()
    local CG = (gethui and gethui()) or game:GetService("CoreGui")
    local target = "Fekality"
    local done = false
    for _ = 1, 30 do
        if done then return end
        task.wait(0.1)
        local ok, desc = pcall(function() return CG:GetDescendants() end)
        if ok and desc then
            for _, d in ipairs(desc) do
                if d:IsA("TextLabel") and d.Text == target then
                    pcall(function()
                        d.TextScaled       = false
                        d.TextTruncate     = Enum.TextTruncate.None
                        d.TextWrapped      = false
                        d.ClipsDescendants = false
                        d.TextXAlignment   = Enum.TextXAlignment.Left
                        if d.Parent and d.Parent:IsA("GuiObject") then
                            d.Size = UDim2.new(1, -4, d.Size.Y.Scale, d.Size.Y.Offset)
                        end
                        local maxW = math.max(d.AbsoluteSize.X, 110)
                        local startSz = (d.TextSize and d.TextSize > 0) and d.TextSize or 14
                        for sz = startSz, 8, -1 do
                            d.TextSize = sz
                            local ok2, b = pcall(function()
                                return _TextSvc:GetTextSize(target, sz, d.Font, Vector2.new(9999, 9999))
                            end)
                            if ok2 and b and b.X <= maxW - 4 then break end
                        end
                    end)
                    done = true
                    break
                end
            end
        end
    end
end)
if Notifier then
    pcall(function()
        Notifier:Notify({ Title = "Fekality", Content = "loaded for "..LP.Name, Icon = "check" })
    end)
end

local EspMenu    = Window:AddMenu({ Name = "ESP",    Icon = "eye"      })
local SearchMenu = Window:AddMenu({ Name = "SEARCH", Icon = "search"   })
local LookMenu   = Window:AddMenu({ Name = "LOOK",   Icon = "target"   })
local HvhMenu    = Window:AddMenu({ Name = "HVH",    Icon = "skull"    })
local InfoMenu   = Window:AddMenu({ Name = "INFO",   Icon = "info"     })

-- ============ ESP tab ============
local MainSec    = EspMenu:AddSection({ Name = "MAIN",    Position = "left"   })
local RangeSec   = EspMenu:AddSection({ Name = "RANGE",   Position = "center" })
local ActionsSec = EspMenu:AddSection({ Name = "ACTIONS", Position = "right"  })

MainSec:AddToggle({ Name = "Enable ESP", Default = false,
    Callback = function(v) if v then start() else stop() end end })

RangeSec:AddSlider({ Name = "Max distance", Min = 30, Max = 500, Default = 180, Type = " m",
    Callback = function(v) S.MaxDist = math.floor(v) end })
RangeSec:AddSlider({ Name = "Max labels", Min = 3, Max = 80, Default = 25,
    Callback = function(v) S.MaxVisible = math.floor(v) end })

ActionsSec:AddButton({ Name = "Rescan", Callback = refresh })
ActionsSec:AddButton({ Name = "Unload", Callback = function()
    stop()
    for _,g in ipairs(PG:GetChildren()) do if g.Name == "GC_ESP" then g:Destroy() end end
end })

-- ============ SEARCH tab ============
local SearchSec = SearchMenu:AddSection({ Name = "FIND ITEM", Position = "left" })
SearchSec:AddToggle({ Name = "Show only matches", Default = false,
    Callback = function(v) S.MatchOnly = v end })

-- preset filter list — quick categories instead of free-text
SearchSec:AddDropdown({
    Name = "Filter",
    Values = { "", "balenciaga", "gucci", "prada", "chanel", "dior", "louis", "rick", "raf", "yeezy" },
    Default = "",
    Callback = function(v) S.Search = v or "" end,
})

-- ============ LOOK tab ============
local LookSec  = LookMenu:AddSection({ Name = "BOX",   Position = "left"   })
local ColorSec = LookMenu:AddSection({ Name = "COLOR", Position = "center" })

LookSec:AddSlider({ Name = "Box width", Min = 80, Max = 260, Default = 130, Type = " px",
    Callback = function(v) S.BoxWidth = math.floor(v) end })
LookSec:AddSlider({ Name = "Font size", Min = 9, Max = 22, Default = 12, Type = " px",
    Callback = function(v) S.FontSize = math.floor(v) end })
LookSec:AddSlider({ Name = "Transparency", Min = 0, Max = 100, Default = 45, Type = "%",
    Callback = function(v) S.Transparency = v/100 end })

ColorSec:AddToggle({ Name = "Chrome shimmer", Default = true,
    Callback = function(v) S.Chrome = v end })
ColorSec:AddColorPicker({ Name = "Custom color", Default = Color3.fromRGB(255,215,0),
    Callback = function(c) S.PickedColor = c end })

-- ============ HVH tab ============
local HvhMain    = HvhMenu:AddSection({ Name = "ANTI-AIM", Position = "left"   })
local HespSec    = HvhMenu:AddSection({ Name = "ESP",      Position = "center" })
local TracerSec  = HvhMenu:AddSection({ Name = "TRACERS",  Position = "right"  })
local HvhPresets = HvhMenu:AddSection({ Name = "PRESETS",  Position = "right"  })

HvhMain:AddToggle({ Name = "Enable HvH", Default = false, Risky = true,
    Callback = function(v) if v then startHvh() else stopHvh() end end })

HvhMain:AddDropdown({ Name = "Yaw mode", Values = YAW_MODES, Default = "Off",
    Callback = function(v)
        for i,m in ipairs(YAW_MODES) do if m == v then HVH.YawIdx = i break end end
    end })
HvhMain:AddDropdown({ Name = "Pitch mode", Values = PITCH_MODES, Default = "Off",
    Callback = function(v)
        for i,m in ipairs(PITCH_MODES) do if m == v then HVH.PitchIdx = i break end end
    end })

HvhMain:AddSlider({ Name = "Static Yaw", Min = -180, Max = 180, Default = 180, Type = "°",
    Callback = function(v) HVH.StaticYaw = v end })
HvhMain:AddSlider({ Name = "Spin Speed", Min = 90, Max = 3600, Default = 720, Type = "°/s",
    Callback = function(v) HVH.SpinSpeed = v end })
HvhMain:AddSlider({ Name = "Jitter Amount", Min = 10, Max = 180, Default = 180, Type = "°",
    Callback = function(v) HVH.JitterAmt = v end })
HvhMain:AddSlider({ Name = "Body Tilt", Min = -90, Max = 90, Default = 0, Type = "°",
    Callback = function(v) HVH.Tilt = v end })
HvhMain:AddToggle({ Name = "Desync (upper)", Default = false,
    Callback = function(v) HVH.Desync = v end })
HvhMain:AddToggle({ Name = "BackTrack walk", Default = false,
    Callback = function(v) HVH.BackTrack = v end })

HespSec:AddToggle({ Name = "Enable HvH ESP", Default = false,
    Callback = function(v) if v then startHesp() else stopHesp() end end })
HespSec:AddToggle({ Name = "Skeleton", Default = false,
    Callback = function(v) HESP.Skeleton = v end })
HespSec:AddColorPicker({ Name = "ESP color", Default = Color3.fromRGB(255,60,60),
    Callback = function(c) HESP.ChamsColor = c end })
HespSec:AddToggle({ Name = "Health bars", Default = false,
    Callback = function(v) HESP.HealthBar = v end })
HespSec:AddToggle({ Name = "Hit marker", Default = false,
    Callback = function(v) HESP.HitMarker = v end })
HespSec:AddToggle({ Name = "Watermark", Default = false,
    Callback = function(v) HESP.Watermark = v end })
HespSec:AddToggle({ Name = "Spectator list", Default = false,
    Callback = function(v) HESP.SpecList = v end })
HespSec:AddSlider({ Name = "Max distance", Min = 50, Max = 5000, Default = 2000, Type = " studs",
    Callback = function(v) HESP.MaxDist = v end })

TracerSec:AddToggle({ Name = "Enable tracers", Default = false,
    Callback = function(v) HESP.Tracers = v end })
TracerSec:AddDropdown({ Name = "Origin", Values = { "Bottom", "Top", "Mouse" }, Default = "Bottom",
    Callback = function(v) HESP.TracerOrigin = v end })

HvhPresets:AddButton({ Name = "Legit",   Callback = function() presetLegit()   end })
HvhPresets:AddButton({ Name = "Spin",    Callback = function() presetSpin()    end })
HvhPresets:AddButton({ Name = "Fun",     Callback = function() presetFun()     end })
HvhPresets:AddButton({ Name = "Retard",  Callback = function() presetRetard()  end })

-- ============ INFO tab ============
local PrivacySec = InfoMenu:AddSection({ Name = "PRIVACY", Position = "left" })
PrivacySec:AddToggle({ Name = "Hide nickname", Default = true,
    Callback = function(v) NICK.Hide = v; applyNickHide(); _pinCustomNick() end })
PrivacySec:AddToggle({ Name = "Rainbow nametag", Default = false,
    Callback = function(v) RNICK.On = v; _applyRainbow(); task.delay(0.2, function() _pinCustomNick(); if _applyBadgesNow then _applyBadgesNow() end end) end })

local BadgesSec = InfoMenu:AddSection({ Name = "FAKE BADGES", Position = "right" })
BadgesSec:AddToggle({ Name = "Developer",      Default = false,
    Callback = function(v) BADGES.Developer = v;     _applyBadgesNow() end })
BadgesSec:AddToggle({ Name = "YouTube",        Default = false,
    Callback = function(v) BADGES.YouTube = v;       _applyBadgesNow() end })
BadgesSec:AddToggle({ Name = "TikTok",         Default = false,
    Callback = function(v) BADGES.TikTok = v;        _applyBadgesNow() end })
BadgesSec:AddToggle({ Name = "Moderator",      Default = false,
    Callback = function(v) BADGES.Moderator = v;     _applyBadgesNow() end })
BadgesSec:AddToggle({ Name = "AvatarCreator",  Default = false,
    Callback = function(v) BADGES.AvatarCreator = v; _applyBadgesNow() end })
BadgesSec:AddToggle({ Name = "Verify",         Default = false,
    Callback = function(v) BADGES.Verify = v;        _applyBadgesNow() end })

local AboutSec = InfoMenu:AddSection({ Name = "ABOUT", Position = "center" })
AboutSec:AddButton({ Name = "Fekality v7.6", Callback = function()
    if Notifier then pcall(function()
        Notifier:Notify({ Title = "Fekality", Content = "v4.5 · Fatality UI", Icon = "info" })
    end) end
end })
