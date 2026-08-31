--[[
    Natrix Script Hub
    Single card, black hole bg + grain, no top/bottom bar.
    Detects PlaceId -> shows loading -> injects script.
]]

-- Services.
local playersService = game:GetService("Players")
local tweenService   = game:GetService("TweenService")
local coreGui        = game:GetService("CoreGui")

local localPlayer = playersService.LocalPlayer

-- Constants.
local BG_IMAGE_ID    = "rbxassetid://134736124666311"
local BG_IMAGE_COLOR = Color3.fromRGB(85, 85, 85)
local WINDOW_W       = 300
local WINDOW_H       = 160
local BASE_URL       = "https://raw.githubusercontent.com/ntxcrim69/NatrixST/refs/heads/main/"

-- Design system.
local THEME = {
    Background      = Color3.fromRGB(5,   5,   5),
    Surface         = Color3.fromRGB(12,  12,  12),
    SurfaceElevated = Color3.fromRGB(18,  18,  18),
    Stroke          = Color3.fromRGB(45,  45,  45),
    Accent          = Color3.fromRGB(255, 255, 255),
    Text            = Color3.fromRGB(255, 255, 255),
    SubText         = Color3.fromRGB(160, 160, 160),
    Danger          = Color3.fromRGB(255, 55,  55),
}

-- Game registry: [PlaceId] = { name, file }
local GAMES = {
    [5233782396]     = { name = "Creatures of Sonaria",    file = "CreaturesOfSonaria.lua" },
}

-- ─── Helpers ────────────────────────────────────────────────────────────────

local function tween(obj, props, dur)
    local t = tweenService:Create(obj, TweenInfo.new(dur or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 4)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke")
    s.Color           = color or THEME.Stroke
    s.Thickness       = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = parent
    return s
end

-- Black hole bg + grain on the single card panel.
local function addPanelBg(panel)
    panel.ClipsDescendants = true

    local bg = Instance.new("ImageLabel")
    bg.Size               = UDim2.new(1, 0, 1, 0)
    bg.BackgroundTransparency = 1
    bg.Image              = BG_IMAGE_ID
    bg.ImageColor3        = BG_IMAGE_COLOR
    bg.ImageTransparency  = 0
    bg.ScaleType          = Enum.ScaleType.Crop
    bg.ZIndex             = panel.ZIndex
    bg.Parent             = panel
    corner(bg, 6)

    local grain = Instance.new("ImageLabel")
    grain.Size                  = UDim2.new(1, 0, 1, 0)
    grain.BackgroundTransparency = 1
    grain.ScaleType             = Enum.ScaleType.Tile
    grain.TileSize              = UDim2.new(0, 64, 0, 64)
    grain.ZIndex                = panel.ZIndex
    grain.Parent                = panel

    pcall(function()
        local ei = Instance.new("EditableImage")
        ei.Size = Vector2.new(64, 64)
        local px = table.create(64 * 64 * 4)
        for i = 0, 64 * 64 - 1 do
            local v = math.random()
            px[i*4+1] = v; px[i*4+2] = v; px[i*4+3] = v; px[i*4+4] = v * 0.07
        end
        ei:WritePixels(Vector2.zero, Vector2.new(64, 64), px)
        ei.Parent = grain
    end)
end

-- ─── Build GUI ──────────────────────────────────────────────────────────────

if coreGui:FindFirstChild("NatrixHub") then
    coreGui:FindFirstChild("NatrixHub"):Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "NatrixHub"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
pcall(function() screenGui.Parent = (gethui and gethui()) or coreGui end)
if not screenGui.Parent then screenGui.Parent = localPlayer:WaitForChild("PlayerGui") end

-- Entry canvas for fade + slide.
local entryCanvas = Instance.new("CanvasGroup")
entryCanvas.Size                  = UDim2.new(1, 0, 1, 0)
entryCanvas.BackgroundTransparency = 1
entryCanvas.GroupTransparency     = 1
entryCanvas.ZIndex                = 1
entryCanvas.Parent                = screenGui

-- Outer container.
local outerContainer = Instance.new("Frame")
outerContainer.Name                   = "OuterContainer"
outerContainer.Size                   = UDim2.new(0, WINDOW_W, 0, WINDOW_H)
outerContainer.Position               = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2 + 14)
outerContainer.BackgroundTransparency = 1
outerContainer.ZIndex                 = 1
outerContainer.Parent                 = entryCanvas

-- Single card (no top/bottom bar, full panel is the card).
local card = Instance.new("Frame")
card.Name             = "Card"
card.Size             = UDim2.new(1, 0, 1, 0)
card.BackgroundColor3 = THEME.Background
card.BorderSizePixel  = 0
card.ZIndex           = 2
card.Parent           = outerContainer
corner(card, 6)
stroke(card, THEME.Stroke)
addPanelBg(card)

-- Drag the card directly.
local dragging, dragInput, dragStart, startPos
card.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = outerContainer.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
card.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        outerContainer.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Inner padding frame.
local inner = Instance.new("Frame")
inner.Size                  = UDim2.new(1, -32, 1, -28)
inner.Position              = UDim2.new(0, 16, 0, 14)
inner.BackgroundTransparency = 1
inner.ZIndex                = 3
inner.Parent                = card

-- Title label.
local titleLabel = Instance.new("TextLabel")
titleLabel.Text           = "Natrix Hub"
titleLabel.Font           = Enum.Font.GothamBold
titleLabel.TextSize       = 14
titleLabel.TextColor3     = THEME.Text
titleLabel.BackgroundTransparency = 1
titleLabel.Size           = UDim2.new(1, -20, 0, 18)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex         = 4
titleLabel.Parent         = inner

-- Game name label.
local gameNameLabel = Instance.new("TextLabel")
gameNameLabel.Text           = "Detecting game..."
gameNameLabel.Font           = Enum.Font.GothamBold
gameNameLabel.TextSize       = 12
gameNameLabel.TextColor3     = THEME.SubText
gameNameLabel.BackgroundTransparency = 1
gameNameLabel.Size           = UDim2.new(1, 0, 0, 15)
gameNameLabel.Position       = UDim2.new(0, 0, 0, 22)
gameNameLabel.TextXAlignment = Enum.TextXAlignment.Left
gameNameLabel.ZIndex         = 4
gameNameLabel.Parent         = inner

-- Thin divider.
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(1, 0, 0, 1)
divider.Position         = UDim2.new(0, 0, 0, 46)
divider.BackgroundColor3 = THEME.Stroke
divider.BorderSizePixel  = 0
divider.ZIndex           = 4
divider.Parent           = inner

-- Status label.
local subLabel = Instance.new("TextLabel")
subLabel.Text           = "Please wait..."
subLabel.Font           = Enum.Font.Gotham
subLabel.TextSize       = 11
subLabel.TextColor3     = THEME.SubText
subLabel.BackgroundTransparency = 1
subLabel.Size           = UDim2.new(1, 0, 0, 14)
subLabel.Position       = UDim2.new(0, 0, 0, 56)
subLabel.TextXAlignment = Enum.TextXAlignment.Left
subLabel.ZIndex         = 4
subLabel.Parent         = inner

-- Progress track.
local progressTrack = Instance.new("Frame")
progressTrack.Size             = UDim2.new(1, 0, 0, 3)
progressTrack.Position         = UDim2.new(0, 0, 0, 78)
progressTrack.BackgroundColor3 = THEME.SurfaceElevated
progressTrack.BorderSizePixel  = 0
progressTrack.ZIndex           = 4
progressTrack.Parent           = inner
corner(progressTrack, 2)
stroke(progressTrack, THEME.Stroke)

local progressFill = Instance.new("Frame")
progressFill.Size             = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = THEME.Accent
progressFill.BorderSizePixel  = 0
progressFill.ZIndex           = 5
progressFill.Parent           = progressTrack
corner(progressFill, 2)

-- Animated dots.
local dotsRow = Instance.new("Frame")
dotsRow.Size                  = UDim2.new(0, 34, 0, 6)
dotsRow.Position              = UDim2.new(0, 0, 0, 96)
dotsRow.BackgroundTransparency = 1
dotsRow.ZIndex                = 4
dotsRow.Parent                = inner

local dots = {}
for i = 1, 3 do
    local dot = Instance.new("Frame")
    dot.Size             = UDim2.new(0, 5, 0, 5)
    dot.Position         = UDim2.new(0, (i-1)*11, 0.5, -2)
    dot.BackgroundColor3 = THEME.SubText
    dot.BorderSizePixel  = 0
    dot.ZIndex           = 5
    dot.Parent           = dotsRow
    corner(dot, 3)
    dots[i] = dot
end

-- ─── Entry animation ────────────────────────────────────────────────────────

tween(entryCanvas, { GroupTransparency = 0 }, 0.3)
tween(outerContainer, { Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2) }, 0.35)

-- ─── Dot pulse ──────────────────────────────────────────────────────────────

local dotsAlive = true
task.spawn(function()
    local idx = 1
    while dotsAlive do
        for i, dot in ipairs(dots) do
            tween(dot, {
                BackgroundColor3 = (i == idx) and THEME.Accent or THEME.SubText,
                Size             = (i == idx) and UDim2.new(0, 6, 0, 6) or UDim2.new(0, 5, 0, 5),
            }, 0.15)
        end
        idx = (idx % 3) + 1
        task.wait(0.36)
    end
end)

-- ─── Helpers ────────────────────────────────────────────────────────────────

local function setProgress(frac, statusText)
    tween(progressFill, { Size = UDim2.new(math.clamp(frac, 0, 1), 0, 1, 0) }, 0.3)
    if statusText then subLabel.Text = statusText end
end

local function smoothDismiss(onDone)
    dotsAlive = false
    tween(outerContainer, { Position = UDim2.new(0.5, -WINDOW_W/2, 0.5, -WINDOW_H/2 + 14) }, 0.25)
    tween(entryCanvas, { GroupTransparency = 1 }, 0.25).Completed:Connect(function()
        screenGui:Destroy()
        if onDone then task.spawn(onDone) end
    end)
end

-- ─── Main loading logic ─────────────────────────────────────────────────────

task.spawn(function()
    task.wait(0.45)

    local placeId  = game.PlaceId
    local gameInfo = GAMES[placeId]

    setProgress(0.12, "Identifying game...")
    task.wait(0.5)

    if not gameInfo then
        gameNameLabel.Text       = "Unsupported Game"
        gameNameLabel.TextColor3 = THEME.Danger
        setProgress(1, "PlaceId " .. tostring(placeId) .. " not registered.")
        task.wait(3)
        smoothDismiss()
        return
    end

    gameNameLabel.Text       = gameInfo.name
    gameNameLabel.TextColor3 = THEME.Accent
    setProgress(0.3, "Waiting for game to load...")
    task.wait(0.3)

    if not game:IsLoaded() then game.Loaded:Wait() end

    setProgress(0.52, "Fetching script...")
    task.wait(0.25)

    local scriptSource
    local ok, err = pcall(function()
        scriptSource = request({ Url = BASE_URL .. gameInfo.file, Method = "GET" }).Body
    end)

    if not ok or not scriptSource or #scriptSource < 10 then
        gameNameLabel.TextColor3 = THEME.Danger
        setProgress(1, "Download failed.")
        task.wait(3)
        smoothDismiss()
        return
    end

    setProgress(0.75, "Compiling...")
    task.wait(0.2)

    local chunk, compileErr = loadstring(scriptSource)
    if not chunk then
        gameNameLabel.TextColor3 = THEME.Danger
        setProgress(1, "Compile error.")
        task.wait(3)
        smoothDismiss()
        return
    end

    setProgress(1, "Injecting " .. gameInfo.name .. "...")
    task.wait(0.5)

    smoothDismiss(function()
        local runOk, runErr = pcall(chunk)
        if not runOk then warn("[NatrixHub] " .. tostring(runErr)) end
    end)
end)
