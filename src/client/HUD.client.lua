-- JUNKSTORM! client-side HUD. Server owns the economy and storm logic.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local noticeEvent = ReplicatedStorage:WaitForChild("JunkstormNotice")

local gui = Instance.new("ScreenGui")
gui.Name = "JunkstormHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local scale = Instance.new("UIScale")
scale.Parent = gui

local function refreshScale()
    local camera = workspace.CurrentCamera
    if camera then
        scale.Scale = math.clamp(camera.ViewportSize.X / 900, 0.7, 1)
    end
end
refreshScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(refreshScale)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(refreshScale)
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
end

local function label(parent, text, position, size, font, color, alignment)
    local l = Instance.new("TextLabel")
    l.Name = "Info"
    l.BackgroundTransparency = 1
    l.Position = position
    l.Size = size
    l.Font = font or Enum.Font.Gotham
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(245, 252, 255)
    l.TextSize = 19
    l.TextXAlignment = alignment or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local panel = Instance.new("Frame")
panel.Name = "InventoryPanel"
panel.Position = UDim2.fromOffset(18, 20)
panel.Size = UDim2.fromOffset(294, 188)
panel.BackgroundColor3 = Color3.fromRGB(20, 36, 57)
panel.BackgroundTransparency = 0.07
panel.Parent = gui
corner(panel, 16)

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(66, 173, 204)
panelStroke.Thickness = 2
panelStroke.Transparency = 0.2
panelStroke.Parent = panel

local title = label(panel, "JUNKSTORM!", UDim2.fromOffset(16, 10),
    UDim2.fromOffset(267, 32), Enum.Font.GothamBlack, Color3.fromRGB(113, 237, 219))
title.TextSize = 28

local subtitle = label(panel, "GRAB  •  ESCAPE  •  UPGRADE", UDim2.fromOffset(17, 45),
    UDim2.fromOffset(273, 17), Enum.Font.GothamBold, Color3.fromRGB(169, 187, 205))
subtitle.TextSize = 12

local coins = label(panel, "COINS  0", UDim2.fromOffset(17, 72),
    UDim2.fromOffset(260, 29), Enum.Font.GothamBold, Color3.fromRGB(255, 212, 107))
coins.TextSize = 22

local bag = label(panel, "BAG  0 / 3", UDim2.fromOffset(17, 108),
    UDim2.fromOffset(260, 25), Enum.Font.GothamBold)
bag.TextSize = 20

local upgrade = label(panel, "Next bag upgrade: 60 coins", UDim2.fromOffset(17, 146),
    UDim2.fromOffset(267, 27), Enum.Font.Gotham, Color3.fromRGB(180, 215, 244))
upgrade.TextSize = 16

local timerPanel = Instance.new("Frame")
timerPanel.Name = "StormStatus"
timerPanel.AnchorPoint = Vector2.new(0.5, 0)
timerPanel.Position = UDim2.new(0.5, 0, 0, 20)
timerPanel.Size = UDim2.fromOffset(286, 82)
timerPanel.BackgroundColor3 = Color3.fromRGB(29, 41, 70)
timerPanel.Parent = gui
corner(timerPanel, 16)

local status = label(timerPanel, "PREPARING", UDim2.fromOffset(8, 10),
    UDim2.fromOffset(270, 26), Enum.Font.GothamBlack,
    Color3.fromRGB(103, 236, 192), Enum.TextXAlignment.Center)
status.TextSize = 24

local countdown = label(timerPanel, "Loading round...", UDim2.fromOffset(8, 42),
    UDim2.fromOffset(270, 24), Enum.Font.GothamBold,
    Color3.fromRGB(229, 236, 252), Enum.TextXAlignment.Center)
countdown.TextSize = 18

local hint = label(gui, "Grab glowing loot  •  Sell at YELLOW  •  Upgrade at PURPLE",
    UDim2.new(0, 18, 1, -46), UDim2.fromOffset(680, 30),
    Enum.Font.GothamBold, Color3.fromRGB(242, 251, 253))
hint.TextSize = 15
hint.TextStrokeTransparency = 0.1

local toast = Instance.new("TextLabel")
toast.Name = "Notice"
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -62)
toast.Size = UDim2.fromOffset(380, 55)
toast.BackgroundColor3 = Color3.fromRGB(20, 39, 61)
toast.BackgroundTransparency = 0.06
toast.TextColor3 = Color3.fromRGB(244, 250, 255)
toast.Font = Enum.Font.GothamBold
toast.TextSize = 18
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
corner(toast, 12)

local function updateStats()
    local money = player:GetAttribute("Coins") or 0
    local used = player:GetAttribute("BagUsed") or 0
    local capacity = player:GetAttribute("BagCapacity") or 3
    local nextCost = player:GetAttribute("NextUpgradeCost") or 60
    coins.Text = "COINS  " .. tostring(money)
    bag.Text = "BAG  " .. tostring(used) .. " / " .. tostring(capacity)
    bag.TextColor3 = used >= capacity and Color3.fromRGB(255, 170, 130)
        or Color3.fromRGB(245, 252, 255)
    upgrade.Text = nextCost < 0 and "BACKPACK MAXED!"
        or ("Next bag upgrade: " .. tostring(nextCost) .. " coins")
end

for _, attr in ipairs({"Coins", "BagUsed", "BagCapacity", "BagLevel", "NextUpgradeCost"}) do
    player:GetAttributeChangedSignal(attr):Connect(updateStats)
end
updateStats()

local function updateStorm()
    local phase = ReplicatedStorage:GetAttribute("StormPhase") or "STARTING"
    local seconds = ReplicatedStorage:GetAttribute("StormTimeLeft") or 0
    local colors = {
        SCAVENGE = Color3.fromRGB(116, 241, 166),
        WARNING = Color3.fromRGB(255, 202, 94),
        STORM = Color3.fromRGB(254, 112, 174),
        RECOVERY = Color3.fromRGB(140, 204, 255),
    }
    status.Text = phase
    status.TextColor3 = colors[phase] or Color3.fromRGB(211, 229, 252)
    if phase == "STORM" then
        countdown.Text = "GET TO THE GREEN SAFE ZONE!  " .. seconds .. "s"
        countdown.TextSize = 15
    elseif phase == "WARNING" then
        countdown.Text = "STORM IN " .. seconds .. "s"
        countdown.TextSize = 19
    elseif phase == "SCAVENGE" then
        countdown.Text = "Scavenge: " .. seconds .. "s remaining"
        countdown.TextSize = 18
    else
        countdown.Text = "Next round: " .. seconds .. "s"
        countdown.TextSize = 18
    end
end

ReplicatedStorage:GetAttributeChangedSignal("StormPhase"):Connect(updateStorm)
ReplicatedStorage:GetAttributeChangedSignal("StormTimeLeft"):Connect(updateStorm)
updateStorm()

local latestNotice = 0
noticeEvent.OnClientEvent:Connect(function(message)
    latestNotice += 1
    local mine = latestNotice
    toast.Text = tostring(message)
    toast.Visible = true
    task.delay(3, function()
        if mine == latestNotice and toast.Parent then toast.Visible = false end
    end)
end)
