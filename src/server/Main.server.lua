-- JUNKSTORM! first-playable server prototype
-- Everything that changes coins, loot, upgrades, or storm outcomes lives here.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local random = Random.new()
local sessions = {}
local stormHits = {}

local notify = Instance.new("RemoteEvent")
notify.Name = "JunkstormNotice"
notify.Parent = ReplicatedStorage

local previousWorld = workspace:FindFirstChild("JunkstormWorld")
if previousWorld then previousWorld:Destroy() end

local world = Instance.new("Folder")
world.Name = "JunkstormWorld"
world.Parent = workspace

Lighting.ClockTime = 14.5
Lighting.Brightness = 2
Lighting.OutdoorAmbient = Color3.fromRGB(155, 182, 201)

local function makePart(name, size, cf, color, material, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cf
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.Anchored = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent or world
    return part
end

local function sign(part, text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "Label"
    billboard.Adornee = part
    billboard.Size = UDim2.fromOffset(220, 58)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 85
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    label.TextStrokeColor3 = Color3.fromRGB(16, 25, 40)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = billboard
end

local function addPrompt(part, action, object)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = action
    prompt.ObjectText = object
    prompt.MaxActivationDistance = 10
    prompt.HoldDuration = 0.1
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = part
    return prompt
end

-- A complete beginner-friendly island, generated entirely from code.
local water = makePart("Blue Ocean", Vector3.new(480, 1, 480),
    CFrame.new(0, -4.1, 0), Color3.fromRGB(56, 174, 232), Enum.Material.Glass)
water.Transparency = 0.16
local island = makePart("Island", Vector3.new(190, 4, 268),
    CFrame.new(0, -2.2, 0), Color3.fromRGB(74, 181, 113), Enum.Material.Grass)

local safePad = makePart("SAFE ZONE", Vector3.new(92, 0.8, 72),
    CFrame.new(0, 0.25, -89), Color3.fromRGB(69, 206, 129), Enum.Material.Neon)
safePad.Transparency = 0.3
safePad.CanCollide = false

local basePlatform = makePart("Base Walkway", Vector3.new(62, 0.45, 26),
    CFrame.new(0, 0.12, -92), Color3.fromRGB(41, 77, 101), Enum.Material.SmoothPlastic)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Base Spawn"
spawn.Size = Vector3.new(13, 1, 13)
spawn.CFrame = CFrame.new(0, 1.1, -108)
spawn.Anchored = true
spawn.Neutral = true
spawn.Enabled = true
spawn.Duration = 0
spawn.Color = Color3.fromRGB(78, 221, 175)
spawn.Material = Enum.Material.Neon
spawn.Parent = world

local sellPart = makePart("SELL Station", Vector3.new(10, 4.4, 9),
    CFrame.new(-27, 2.7, -89), Color3.fromRGB(249, 192, 66), Enum.Material.SmoothPlastic)
sign(sellPart, "SELL LOOT", Color3.fromRGB(255, 242, 122))
local sellPrompt = addPrompt(sellPart, "Sell bag", "Sell your finds")

local upgradePart = makePart("UPGRADE Station", Vector3.new(10, 4.4, 9),
    CFrame.new(27, 2.7, -89), Color3.fromRGB(128, 134, 255), Enum.Material.SmoothPlastic)
sign(upgradePart, "UPGRADE BAG", Color3.fromRGB(197, 209, 255))
local upgradePrompt = addPrompt(upgradePart, "Upgrade", "More backpack slots")

local stormWall = makePart("Moving Storm", Vector3.new(188, 35, 5),
    CFrame.new(0, 18, 134), Color3.fromRGB(151, 76, 248), Enum.Material.Neon)
stormWall.CanCollide = false
stormWall.Transparency = 1

-- Scattered rocks and trees create landmarks without requiring external assets.
for i = 1, 28 do
    local x = random:NextNumber(-82, 82)
    local z = random:NextNumber(-33, 125)
    local height = random:NextNumber(4, 9)
    local trunk = makePart("Island Tree Trunk", Vector3.new(2.4, height, 2.4),
        CFrame.new(x, height / 2, z), Color3.fromRGB(126, 86, 71), Enum.Material.Wood)
    trunk.CanCollide = false
    local canopy = makePart("Island Tree Canopy", Vector3.new(8.5, 8.5, 8.5),
        CFrame.new(x, height + 2, z), Color3.fromRGB(30, 143 + random:NextInteger(0, 55), 99), Enum.Material.Grass)
    canopy.Shape = Enum.PartType.Ball
    canopy.CanCollide = false
end

local function warn(player, message)
    if player and player.Parent == Players then
        notify:FireClient(player, message)
    end
end

local function capacityOf(state)
    return Config.StartingCapacity + (state.Level - 1) * Config.CapacityPerUpgrade
end

local function upgradeCost(state)
    if state.Level >= Config.MaxBagLevel then return -1 end
    return Config.UpgradeBaseCost * state.Level
end

local function sync(player)
    local state = sessions[player]
    if not state then return end
    player:SetAttribute("Coins", state.Coins)
    player:SetAttribute("BagUsed", #state.Bag)
    player:SetAttribute("BagCapacity", capacityOf(state))
    player:SetAttribute("BagLevel", state.Level)
    player:SetAttribute("NextUpgradeCost", upgradeCost(state))
    local leaderstats = player:FindFirstChild("leaderstats")
    local coinsValue = leaderstats and leaderstats:FindFirstChild("Coins")
    if coinsValue then coinsValue.Value = state.Coins end
end

local function validInteraction(player, part)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    return root ~= nil and hum ~= nil and hum.Health > 0
        and (root.Position - part.Position).Magnitude <= 14
end

local function onPlayerAdded(player)
    sessions[player] = { Coins = 0, Level = 1, Bag = {} }
    local board = Instance.new("Folder")
    board.Name = "leaderstats"
    board.Parent = player
    local value = Instance.new("IntValue")
    value.Name = "Coins"
    value.Parent = board
    sync(player)
    warn(player, "Grab glowing junk, then sell it at the yellow station!")
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    sessions[player] = nil
    stormHits[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

sellPrompt.Triggered:Connect(function(player)
    local state = sessions[player]
    if not state or not validInteraction(player, sellPart) then return end
    if #state.Bag == 0 then
        warn(player, "Your bag is empty. Go find some junk!")
        return
    end

    local total = 0
    for _, item in ipairs(state.Bag) do total += item.value end
    state.Coins += total
    table.clear(state.Bag)
    sync(player)
    warn(player, "Sold your haul for " .. total .. " coins!")
end)

upgradePrompt.Triggered:Connect(function(player)
    local state = sessions[player]
    if not state or not validInteraction(player, upgradePart) then return end
    local cost = upgradeCost(state)
    if cost < 0 then
        warn(player, "Your backpack is already fully upgraded!")
    elseif state.Coins < cost then
        warn(player, "Need " .. (cost - state.Coins) .. " more coins.")
    else
        state.Coins -= cost
        state.Level += 1
        sync(player)
        warn(player, "Backpack upgraded! Capacity: " .. capacityOf(state))
    end
end)

local lootPositions = {}
for i = 1, Config.LootSlots do
    lootPositions[i] = Vector3.new(random:NextNumber(-69, 69), 2.2, random:NextNumber(-28, 119))
end

local function pickItem()
    local sum = 0
    for _, item in ipairs(Config.Items) do sum += item.weight end
    local roll = random:NextNumber(0, sum)
    for _, item in ipairs(Config.Items) do
        roll -= item.weight
        if roll <= 0 then return item end
    end
    return Config.Items[#Config.Items]
end

local function spawnLoot(slot)
    if not world.Parent then return end
    local itemData = pickItem()
    local itemPart = makePart(itemData.name, Vector3.new(3.5, 3.5, 3.5),
        CFrame.new(lootPositions[slot]), itemData.color, Enum.Material.Neon)
    itemPart.Shape = Enum.PartType.Ball
    itemPart.CanCollide = false
    sign(itemPart, itemData.name .. "\n" .. itemData.value .. " coins", itemData.color)
    local prompt = addPrompt(itemPart, "Grab", itemData.name)

    prompt.Triggered:Connect(function(player)
        local state = sessions[player]
        if not state or itemPart:GetAttribute("Taken") or not validInteraction(player, itemPart) then return end
        if #state.Bag >= capacityOf(state) then
            warn(player, "Bag full! Return to base and sell your loot.")
            return
        end
        itemPart:SetAttribute("Taken", true)
        prompt.Enabled = false
        table.insert(state.Bag, itemData)
        sync(player)
        warn(player, "Collected " .. itemData.name .. " (+" .. itemData.value .. " value)")
        itemPart:Destroy()
        task.delay(Config.LootRespawnSeconds, function()
            spawnLoot(slot)
        end)
    end)
end

for i = 1, Config.LootSlots do spawnLoot(i) end

local function inSafeZone(position)
    local relative = safePad.CFrame:PointToObjectSpace(position)
    return math.abs(relative.X) <= safePad.Size.X / 2
        and math.abs(relative.Z) <= safePad.Size.Z / 2
        and math.abs(relative.Y) < 35
end

local function phase(name, duration)
    ReplicatedStorage:SetAttribute("StormPhase", name)
    for remaining = duration, 1, -1 do
        ReplicatedStorage:SetAttribute("StormTimeLeft", remaining)
        task.wait(1)
    end
    ReplicatedStorage:SetAttribute("StormTimeLeft", 0)
end

ReplicatedStorage:SetAttribute("StormPhase", "Starting")
ReplicatedStorage:SetAttribute("StormTimeLeft", 0)

task.spawn(function()
    while true do
        phase("SCAVENGE", Config.ScavengeSeconds)
        phase("WARNING", Config.WarningSeconds)

        table.clear(stormHits)
        ReplicatedStorage:SetAttribute("StormPhase", "STORM")
        stormWall.Transparency = 0.45
        local steps = Config.StormSeconds * 10

        for step = 0, steps do
            local fraction = step / steps
            local frontZ = 133 - fraction * 183
            stormWall.CFrame = CFrame.new(0, 18, frontZ)
            ReplicatedStorage:SetAttribute("StormTimeLeft",
                math.max(0, math.ceil(Config.StormSeconds * (1 - fraction))))

            for player, state in pairs(sessions) do
                if not stormHits[player] then
                    local character = player.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                    if root and humanoid and humanoid.Health > 0
                        and root.Position.Z >= frontZ
                        and not inSafeZone(root.Position) then
                        stormHits[player] = true
                        local lost = #state.Bag
                        table.clear(state.Bag)
                        sync(player)
                        root.CFrame = CFrame.new(0, 6, -108)
                        warn(player, lost > 0
                            and ("Storm caught you! Lost " .. lost .. " unbanked items.")
                            or "Storm caught you! You made it back with no loot to lose.")
                    end
                end
            end
            task.wait(0.1)
        end

        stormWall.Transparency = 1
        stormWall.CFrame = CFrame.new(0, 18, 134)
        phase("RECOVERY", Config.RecoverySeconds)
    end
end)
