local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = game.Workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local playersService = game:GetService("Players")
local lightingService = game:GetService("Lighting") -- Used for ESP Fullbright potential

local flyEnabled = false
local noclipEnabled = false
local espEnabled = false
local godModeEnabled = false
local antiRagdollEnabled = false
local infiniteJumpEnabled = false

local flySpeed = 50 -- Default speed
local speedBurstMultiplier = 3 -- How much faster the burst is
local movementMode = "Camera" -- "Camera" or "World"

local originalWalkSpeed = humanoid.WalkSpeed
local originalJumpPower = humanoid.JumpPower
local originalHealth = humanoid.MaxHealth -- Store original max health

-- Store settings (simple in-memory store)
local settings = {
    FlySpeed = flySpeed,
    NoclipEnabled = false,
    MovementMode = movementMode,
    WalkSpeed = originalWalkSpeed,
    JumpPower = originalJumpPower,
    InfiniteJumpEnabled = false,
    ESPEnabled = false,
    GodModeEnabled = false, -- Initial state off
    AntiRagdollEnabled = false, -- Initial state off
    TeleportCoords = {X = 0, Y = 100, Z = 0} -- Default teleport coords
}

-- Load settings (simple in-memory load)
local function loadSettings()
    -- In a real exploit, you might read from a file here.
    flySpeed = settings.FlySpeed
    noclipEnabled = settings.NoclipEnabled
    movementMode = settings.MovementMode
    infiniteJumpEnabled = settings.InfiniteJumpEnabled
    espEnabled = settings.ESPEnabled
    godModeEnabled = settings.GodModeEnabled
    antiRagdollEnabled = settings.AntiRagdollEnabled
    -- WalkSpeed, JumpPower, TeleportCoords are loaded below into GUI/variables
end

-- Save settings (simple in-memory save)
local function saveSettings()
    settings.FlySpeed = flySpeed
    settings.NoclipEnabled = noclipEnabled
    settings.MovementMode = movementMode
    settings.WalkSpeed = humanoid.WalkSpeed -- Save current active speed
    settings.JumpPower = humanoid.JumpPower -- Save current active jump power
    settings.InfiniteJumpEnabled = infiniteJumpEnabled
    settings.ESPEnabled = espEnabled
    settings.GodModeEnabled = godModeEnabled
    settings.AntiRagdollEnabled = antiRagdollEnabled
    -- TeleportCoords are saved from input fields when teleporting or focus is lost
    -- In a real exploit, you would write these to a file here.
end

-- Store connections
local connections = {}
local guiConnections = {}
local playerListConnections = {}
local espVisuals = {} -- Store ESP elements for each player

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LuaGeminiFlyGui"
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Ensure ESP GUI is above others

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 250, 0, 550) -- Increased size
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
frame.Draggable = true
frame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.05, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 16
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Text = "Lua Gemini v4"
titleLabel.Parent = frame

local tabsFrame = Instance.new("Frame") -- Frame to hold tab buttons
tabsFrame.Size = UDim2.new(1, 0, 0.08, 0)
tabsFrame.Position = UDim2.new(0, 0, 0.05, 0)
tabsFrame.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
tabsFrame.Parent = frame

local featuresButton = Instance.new("TextButton")
featuresButton.Size = UDim2.new(1/3, 0, 1, 0)
featuresButton.Position = UDim2.new(0, 0, 0, 0)
featuresButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
featuresButton.TextColor3 = Color3.fromRGB(255, 255, 255)
featuresButton.TextSize = 14
featuresButton.Font = Enum.Font.SourceSansBold
featuresButton.Text = "Features"
featuresButton.Parent = tabsFrame

local playersButton = Instance.new("TextButton")
playersButton.Size = UDim2.new(1/3, 0, 1, 0)
playersButton.Position = UDim2.new(1/3, 0, 0, 0)
playersButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
playersButton.TextColor3 = Color3.fromRGB(200, 200, 200)
playersButton.TextSize = 14
playersButton.Font = Enum.Font.SourceSansBold
playersButton.Text = "Players"
playersButton.Parent = tabsFrame

local otherButton = Instance.new("TextButton") -- New tab for Other/Misc features
otherButton.Size = UDim2.new(1/3, 0, 1, 0)
otherButton.Position = UDim2.new(2/3, 0, 0, 0)
otherButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
otherButton.TextColor3 = Color3.fromRGB(200, 200, 200)
otherButton.TextSize = 14
otherButton.Font = Enum.Font.SourceSansBold
otherButton.Text = "Misc"
otherButton.Parent = tabsFrame


local featuresPage = Instance.new("ScrollingFrame") -- Use ScrollingFrame for features too
featuresPage.Size = UDim2.new(1, 0, 0.8, 0)
featuresPage.Position = UDim2.new(0, 0, 0.13, 0)
featuresPage.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
featuresPage.CanvasSize = UDim2.new(0, 0, 0, 0)
featuresPage.ScrollBarThickness = 6
featuresPage.Parent = frame
featuresPage.Visible = true

local playersPage = Instance.new("ScrollingFrame")
playersPage.Size = UDim2.new(1, 0, 0.8, 0)
playersPage.Position = UDim2.new(0, 0, 0.13, 0)
playersPage.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
playersPage.CanvasSize = UDim2.new(0, 0, 0, 0)
playersPage.ScrollBarThickness = 6
playersPage.Parent = frame
playersPage.Visible = false

local otherPage = Instance.new("ScrollingFrame")
otherPage.Size = UDim2.new(1, 0, 0.8, 0)
otherPage.Position = UDim2.new(0, 0, 0.13, 0)
otherPage.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
otherPage.CanvasSize = UDim2.new(0, 0, 0, 0)
otherPage.ScrollBarThickness = 6
otherPage.Parent = frame
otherPage.Visible = false


local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.05, 0)
statusLabel.Position = UDim2.new(0, 0, 0.95, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Text = "Status: Loading..."
statusLabel.Parent = frame


-- Helper to add controls to a ScrollingFrame page
local function addControl(parentFrame, control, height, xPos, yPos, xSize, ySize)
     control.Size = UDim2.new(xSize or 0.9, 0, ySize or height, 0)
     control.Position = UDim2.new(xPos or 0.05, 0, yPos or 0, 0)
     control.Parent = parentFrame
     return control
end

-- Section Header Helper
local function addSectionHeader(parentFrame, text, yOffset)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 20) -- Fixed height
    header.Position = UDim2.new(0, 0, 0, yOffset)
    header.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 14
    header.Font = Enum.Font.SourceSansBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = " " .. text -- Add space for padding
    header.Parent = parentFrame
    return header.Size.Y.Offset
end


-- Populate Features Page
local featureY = 10 -- Initial vertical offset
local paddingY = 5

-- Fly Controls Section
featureY += addSectionHeader(featuresPage, "Fly Controls", featureY) + paddingY

local toggleFlyButton = addControl(featuresPage, Instance.new("TextButton"), 0, featureY = featureY)
toggleFlyButton.Size = UDim2.new(0.9, 0, 0, 30)
toggleFlyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleFlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleFlyButton.TextSize = 14
toggleFlyButton.Font = Enum.Font.SourceSansBold
toggleFlyButton.Text = "Enable Fly"
featureY += toggleFlyButton.Size.Y.Offset + paddingY

local speedLabel = addControl(featuresPage, Instance.new("TextLabel"), 0, 0.05, featureY, 0.4, 25)
speedLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.SourceSans
speedLabel.Text = "Fly Speed:"

local speedInput = addControl(featuresPage, Instance.new("TextBox"), 0, 0.5, featureY, 0.45, 25)
speedInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.TextSize = 12
speedInput.Font = Enum.Font.SourceSans
speedInput.Text = tostring(flySpeed)
speedInput.ClearTextOnFocus = false
featureY += speedInput.Size.Y.Offset + paddingY

local toggleMovementModeButton = addControl(featuresPage, Instance.new("TextButton"), 0, featureY = featureY)
toggleMovementModeButton.Size = UDim2.new(0.9, 0, 0, 30)
toggleMovementModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleMovementModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleMovementModeButton.TextSize = 14
toggleMovementModeButton.Font = Enum.Font.SourceSansBold
toggleMovementModeButton.Text = "Mode: Camera"
featureY += toggleMovementModeButton.Size.Y.Offset + paddingY

-- Movement Controls Section
featureY += addSectionHeader(featuresPage, "Movement Controls", featureY) + paddingY

local walkSpeedLabel = addControl(featuresPage, Instance.new("TextLabel"), 0, 0.05, featureY, 0.4, 25)
walkSpeedLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
walkSpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
walkSpeedLabel.TextSize = 12
walkSpeedLabel.Font = Enum.Font.SourceSans
walkSpeedLabel.Text = "WalkSpeed:"

local walkSpeedInput = addControl(featuresPage, Instance.new("TextBox"), 0, 0.5, featureY, 0.45, 25)
walkSpeedInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
walkSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
walkSpeedInput.TextSize = 12
walkSpeedInput.Font = Enum.Font.SourceSans
walkSpeedInput.Text = tostring(originalWalkSpeed)
walkSpeedInput.ClearTextOnFocus = false
featureY += walkSpeedInput.Size.Y.Offset + paddingY

local jumpPowerLabel = addControl(featuresPage, Instance.new("TextLabel"), 0, 0.05, featureY, 0.4, 25)
jumpPowerLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
jumpPowerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
jumpPowerLabel.TextSize = 12
jumpPowerLabel.Font = Enum.Font.SourceSans
jumpPowerLabel.Text = "JumpPower:"

local jumpPowerInput = addControl(featuresPage, Instance.new("TextBox"), 0, 0.5, featureY, 0.45, 25)
jumpPowerInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
jumpPowerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpPowerInput.TextSize = 12
jumpPowerInput.Font = Enum.Font.SourceSans
jumpPowerInput.Text = tostring(originalJumpPower)
jumpPowerInput.ClearTextOnFocus = false
featureY += jumpPowerInput.Size.Y.Offset + paddingY

local toggleInfiniteJumpButton = addControl(featuresPage, Instance.new("TextButton"), 0, featureY = featureY)
toggleInfiniteJumpButton.Size = UDim2.new(0.9, 0, 0, 30)
toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleInfiniteJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleInfiniteJumpButton.TextSize = 14
toggleInfiniteJumpButton.Font = Enum.Font.SourceSansBold
toggleInfiniteJumpButton.Text = "Enable Infinite Jump"
featureY += toggleInfiniteJumpButton.Size.Y.Offset + paddingY

-- Combat/Survival Section
featureY += addSectionHeader(featuresPage, "Combat / Survival", featureY) + paddingY

local toggleNoclipButton = addControl(featuresPage, Instance.new("TextButton"), 0, featureY = featureY)
toggleNoclipButton.Size = UDim2.new(0.9, 0, 0, 30)
toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleNoclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleNoclipButton.TextSize = 14
toggleNoclipButton.Font = Enum.Font.SourceSansBold
toggleNoclipButton.Text = "Enable Noclip"
featureY += toggleNoclipButton.Size.Y.Offset + paddingY

local toggleGodModeButton = addControl(featuresPage, Instance.new("TextButton"), 0, featureY = featureY)
toggleGodModeButton.Size = UDim2.new(0.9, 0, 0, 30)
toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleGodModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleGodModeButton.TextSize = 14
toggleGodModeButton.Font = Enum.Font.SourceSansBold
toggleGodModeButton.Text = "Enable God Mode (Client)"
featureY += toggleGodModeButton.Size.Y.Offset + paddingY

local toggleAntiRagdollButton = addControl(featuresPage, Instance.new("TextButton"), 0, featureY = featureY)
toggleAntiRagdollButton.Size = UDim2.new(0.9, 0, 0, 30)
toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleAntiRagdollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleAntiRagdollButton.TextSize = 14
toggleAntiRagdollButton.Font = Enum.Font.SourceSansBold
toggleAntiRagdollButton.Text = "Enable Anti-Ragdoll (Client)"
featureY += toggleAntiRagdollButton.Size.Y.Offset + paddingY


-- Teleport to Coords Section
featureY += addSectionHeader(featuresPage, "Teleport to Coordinates", featureY) + paddingY

local coordLabel = addControl(featuresPage, Instance.new("TextLabel"), 0, 0.05, featureY, 0.9, 20)
coordLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
coordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
coordLabel.TextSize = 12
coordLabel.Font = Enum.Font.SourceSans
coordLabel.Text = "X:          Y:          Z:"
featureY += coordLabel.Size.Y.Offset + paddingY

local coordXInput = addControl(featuresPage, Instance.new("TextBox"), 0, 0.05, featureY, 0.28, 25)
coordXInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
coordXInput.TextColor3 = Color3.fromRGB(255, 255, 255)
coordXInput.TextSize = 12
coordXInput.Font = Enum.Font.SourceSans
coordXInput.Text = tostring(settings.TeleportCoords.X)
coordXInput.ClearTextOnFocus = false

local coordYInput = addControl(featuresPage, Instance.new("TextBox"), 0, 0.36, featureY, 0.28, 25)
coordYInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
coordYInput.TextColor3 = Color3.fromRGB(255, 255, 255)
coordYInput.TextSize = 12
coordYInput.Font = Enum.Font.SourceSans
coordYInput.Text = tostring(settings.TeleportCoords.Y)
coordYInput.ClearTextOnFocus = false

local coordZInput = addControl(featuresPage, Instance.new("TextBox"), 0, 0.67, featureY, 0.28, 25)
coordZInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
coordZInput.TextColor3 = Color3.fromRGB(255, 255, 255)
coordZInput.TextSize = 12
coordZInput.Font = Enum.Font.SourceSans
coordZInput.Text = tostring(settings.TeleportCoords.Z)
coordZInput.ClearTextOnFocus = false
featureY += coordXInput.Size.Y.Offset + paddingY

local teleportCoordsButton = addControl(featuresPage, Instance.new("TextButton"), 0, featureY = featureY)
teleportCoordsButton.Size = UDim2.new(0.9, 0, 0, 30)
teleportCoordsButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
teleportCoordsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportCoordsButton.TextSize = 14
teleportCoordsButton.Font = Enum.Font.SourceSansBold
teleportCoordsButton.Text = "Teleport to Coordinates"
featureY += teleportCoordsButton.Size.Y.Offset + paddingY

-- Update Features Page Canvas Size
featuresPage.CanvasSize = UDim2.new(0, 0, 0, featureY + 10) -- Add some padding at the bottom


-- Populate Other Page
local otherY = 10
otherY += addSectionHeader(otherPage, "Visuals", otherY) + paddingY

local toggleESPButton = addControl(otherPage, Instance.new("TextButton"), 0, otherY = otherY)
toggleESPButton.Size = UDim2.new(0.9, 0, 0, 30)
toggleESPButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleESPButton.TextSize = 14
toggleESPButton.Font = Enum.Font.SourceSansBold
toggleESPButton.Text = "Enable ESP"
otherY += toggleESPButton.Size.Y.Offset + paddingY

-- ESP Drawing Layer
local espGui = Instance.new("ScreenGui")
espGui.Name = "ESPGui"
espGui.Parent = player:WaitForChild("PlayerGui")
espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Ensure ESP is above other UI


-- ESP Update Logic
local function updateESP()
    if not espEnabled then
        -- Clean up all visuals if ESP is disabled
        for targetName, visuals in pairs(espVisuals) do
            if visuals.Box and visuals.Box.Parent then visuals.Box:Destroy() end
            if visuals.NameLabel and visuals.NameLabel.Parent then visuals.NameLabel:Destroy() end
            espVisuals[targetName] = nil
        end
        return
    end

    for _, targetPlayer in pairs(playersService:GetPlayers()) do
        if targetPlayer ~= player and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local root = targetPlayer.Character.HumanoidRootPart
            local screenPoint, isOnScreen = camera:WorldToScreenPoint(root.Position)

            -- Get or create visuals for this player
            if not espVisuals[targetPlayer.Name] then
                local box = Instance.new("Frame")
                box.Name = targetPlayer.Name .. "Box"
                box.Size = UDim2.new(0, 50, 0, 70) -- Adjust size as needed
                box.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red box
                box.BackgroundTransparency = 0.8
                box.BorderSizePixel = 1
                box.BorderColor3 = Color3.fromRGB(255, 255, 255)
                box.ZIndex = 2 -- Ensure it's visible

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = targetPlayer.Name .. "Name"
                nameLabel.Size = UDim2.new(1, 0, 0, 20) -- Full width of box, fixed height
                nameLabel.Position = UDim2.new(0, 0, 1, 0) -- Below the box
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 12
                nameLabel.Font = Enum.Font.SourceSansBold
                nameLabel.Text = targetPlayer.Name
                nameLabel.BackgroundTransparency = 1
                nameLabel.ZIndex = 2

                box.Parent = espGui
                nameLabel.Parent = box -- Parent name label to box for easy positioning

                espVisuals[targetPlayer.Name] = {Box = box, NameLabel = nameLabel}
            end

            local visuals = espVisuals[targetPlayer.Name]

            if isOnScreen then
                -- Position and scale the box based on distance (optional but better)
                local distance = (root.Position - camera.CFrame.Position).Magnitude
                local scaleFactor = math.clamp(100 / distance, 0.5, 3) -- Scale down with distance, min 0.5x, max 3x
                local boxSizeX = 50 * scaleFactor
                local boxSizeY = 70 * scaleFactor

                visuals.Box.Size = UDim2.new(0, boxSizeX, 0, boxSizeY)
                visuals.Box.Position = UDim2.new(0, screenPoint.X - boxSizeX / 2, 0, screenPoint.Y - boxSizeY / 2) -- Center the box

                visuals.NameLabel.Text = targetPlayer.Name .. " (" .. math.floor(distance) .. "m)" -- Add distance to name
                visuals.Box.Visible = true
            else
                visuals.Box.Visible = false -- Hide if off screen
            end

             -- Clean up visuals for players who left
             if not playersService:FindFirstChild(targetPlayer.Name) or not targetPlayer.Character then
                 if visuals.Box and visuals.Box.Parent then visuals.Box:Destroy() end
                 if visuals.NameLabel and visuals.NameLabel.Parent then visuals.NameLabel:Destroy() end
                 espVisuals[targetPlayer.Name] = nil
             end

        else
            -- Clean up visuals for this player if they no longer exist or are us
             if espVisuals[targetPlayer.Name] then
                 if espVisuals[targetPlayer.Name].Box and espVisuals[targetPlayer.Name].Box.Parent then espVisuals[targetPlayer.Name].Box:Destroy() end
                 if espVisuals[targetPlayer.Name].NameLabel and espVisuals[targetPlayer.Name].NameLabel.Parent then espVisuals[targetPlayer.Name].NameLabel:Destroy() end
                 espVisuals[targetPlayer.Name] = nil
             end
        end
    end
end

-- Update Other Page Canvas Size
otherPage.CanvasSize = UDim2.new(0, 0, 0, otherY + 10)


-- Populate Players Page (Same as before, just ensure parent is playersPage)
local playerButtonTemplate = Instance.new("TextButton")
playerButtonTemplate.Size = UDim2.new(1, -10, 0, 30) -- Full width minus padding, fixed height
playerButtonTemplate.Position = UDim2.new(0, 5, 0, 0) -- Center with padding
playerButtonTemplate.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
playerButtonTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
playerButtonTemplate.TextSize = 14
playerButtonTemplate.Font = Enum.Font.SourceSansBold
playerButtonTemplate.TextXAlignment = Enum.TextXAlignment.Left
playerButtonTemplate.BorderSizePixel = 0

local playerButtonHeight = playerButtonTemplate.Size.Y.Offset + 5 -- Height including spacing

local function createPlayerButton(targetPlayer)
    local button = playerButtonTemplate:Clone()
    button.Name = targetPlayer.Name .. "Button"
    button.Text = targetPlayer.Name

    guiConnections[button] = button.MouseButton1Click:Connect(function()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            -- Teleport slightly above the target player
            rootPart.CFrame = targetRoot.CFrame + Vector3.new(0, 5, 0)
            statusLabel.Text = "Status: Teleported to " .. targetPlayer.Name
            statusLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
             delay(2, function() -- Reset status after a delay
                 local currentStatusText = "Status: Disabled"
                 local currentStatusColor = Color3.fromRGB(255, 255, 255)
                 if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 statusLabel.Text = currentStatusText
                 statusLabel.TextColor3 = currentStatusColor
            end)
        else
            statusLabel.Text = "Status: Player not found or not spawned!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
             delay(2, function() -- Reset status after a delay
                 local currentStatusText = "Status: Disabled"
                 local currentStatusColor = Color3.fromRGB(255, 255, 255)
                 if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
                 statusLabel.Text = currentStatusText
                 statusLabel.TextColor3 = currentStatusColor
            end)
        end
    end)

    return button
end

local function updatePlayerList()
    -- Clear existing buttons and connections
    for _, child in pairs(playersPage:GetChildren()) do
        if child:IsA("TextButton") and guiConnections[child] then
            if guiConnections[child].Connected then
                 guiConnections[child]:Disconnect()
            end
            guiConnections[child] = nil -- Remove from table
            child:Destroy()
        end
    end

    local players = playersService:GetPlayers()
    local currentY = 0
    local playerCount = 0

    for _, p in pairs(players) do
        if p ~= player then -- Don't add ourselves to the list
            local button = createPlayerButton(p)
            button.Position = UDim2.new(0, 5, 0, currentY)
            button.Parent = playersPage
            currentY += playerButtonHeight
            playerCount += 1
        end
    end

    -- Update CanvasSize
    playersPage.CanvasSize = UDim2.new(0, 0, 0, currentY)
     statusLabel.Text = "Status: Player list updated (" .. playerCount .. " other players)"
     statusLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
      delay(2, function() -- Reset status after a delay
          local currentStatusText = "Status: Disabled"
          local currentStatusColor = Color3.fromRGB(255, 255, 255)
          if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
          if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
          if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
          if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
          if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
          statusLabel.Text = currentStatusText
          statusLabel.TextColor3 = currentStatusColor
      end)
end


-- Fly Movement Logic (using CFrame) - Same as before
local function updateFlyMovement(dt)
    if not flyEnabled or not rootPart then return end

    local moveDirection = Vector3.new(0, 0, 0)

    local currentSpeed = flySpeed
    if userInputService:IsKeyDown(Enum.KeyCode.LeftShift) or userInputService:IsKeyDown(Enum.KeyCode.RightShift) then
        currentSpeed *= speedBurstMultiplier
    end

    if movementMode == "Camera" then
        local cameraCFrame = camera.CFrame
        local lookVector = cameraCFrame.LookVector * Vector3.new(1, 0, 1)
        local rightVector = cameraCFrame.RightVector * Vector3.new(1, 0, 1)

        if lookVector.Magnitude > 0 then lookVector = lookVector.Unit end
        if rightVector.Magnitude > 0 then rightVector = rightVector.Unit end

        if userInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection += lookVector
        end
        if userInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection -= lookVector
        end
        if userInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection -= rightVector
        end
        if userInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection += rightVector
        end
        if userInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection += Vector3.new(0, 1, 0)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) or userInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            moveDirection -= Vector3.new(0, 1, 0)
        end

    elseif movementMode == "World" then
        if userInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection += Vector3.new(0, 0, -1)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection += Vector3.new(0, 0, 1)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection += Vector3.new(-1, 0, 0)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection += Vector3.new(1, 0, 0)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection += Vector3.new(0, 1, 0)
        end
        if userInputService:IsKeyDown(Enum.KeyCode.LeftControl) or userInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            moveDirection -= Vector3.new(0, 1, 0)
        end
    end

    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit
    end

    local currentPosition = rootPart.CFrame.Position
    local newPosition = currentPosition + moveDirection * currentSpeed * dt

    rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(newPosition), math.min(1, dt * 20))

    if movementMode == "Camera" then
         local uprightCFrame = CFrame.new(rootPart.Position) * CFrame.fromMatrix(Vector3.new(0, 0, 0), camera.CFrame.RightVector * Vector3.new(1,0,1).Unit, Vector3.new(0, 1, 0))
         rootPart.CFrame = uprightCFrame
    end
end

-- Enable/Disable Fly - Updated to handle status and saving
local function enableFly()
    if flyEnabled then return end
    flyEnabled = true
    humanoid.PlatformStand = true
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0

    connections.Stepped = runService.Stepped:Connect(updateFlyMovement)

    toggleFlyButton.Text = "Disable Fly"
    toggleFlyButton.BackgroundColor3 = Color3.fromRGB(90, 50, 50)
    infoLabel.Visible = true -- Keep info label visible in features page
    statusLabel.Text = "Status: Fly Enabled (" .. movementMode .. ")"
    statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    saveSettings()
end

local function disableFly()
    if not flyEnabled then return end
    flyEnabled = false
    humanoid.PlatformStand = false
    -- Reset WalkSpeed and JumpPower to whatever the inputs currently show
    updateWalkSpeed()
    updateJumpPower()

    if connections.Stepped then
        connections.Stepped:Disconnect()
        connections.Stepped = nil
    end

    toggleFlyButton.Text = "Enable Fly"
    toggleFlyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
     statusLabel.Text = (noclipEnabled and "Status: Noclip Enabled" or (infiniteJumpEnabled and "Status: Infinite Jump Enabled" or (godModeEnabled and "Status: God Mode Enabled" or (antiRagdollEnabled and "Status: Anti-Ragdoll Enabled" or "Status: Disabled"))))
     statusLabel.TextColor3 = (noclipEnabled or infiniteJumpEnabled or godModeEnabled or antiRagdollEnabled) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)
    saveSettings()
end

-- Toggle Noclip - Updated to handle status and saving
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    for i, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = not noclipEnabled
        end
    end

    if noclipEnabled then
        toggleNoclipButton.Text = "Disable Noclip"
        toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        statusLabel.Text = "Status: Noclip Enabled" .. (flyEnabled and " (Fly Enabled)" or "") .. (infiniteJumpEnabled and " (Infinite Jump Enabled)" or "") .. (godModeEnabled and " (God Mode Enabled)" or "") .. (antiRagdollEnabled and " (Anti-Ragdoll Enabled)" or "")
        statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    else
        toggleNoclipButton.Text = "Enable Noclip"
        toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
         statusLabel.Text = (flyEnabled and "Status: Fly Enabled (" .. movementMode .. ")" or (infiniteJumpEnabled and "Status: Infinite Jump Enabled" or (godModeEnabled and "Status: God Mode Enabled" or (antiRagdollEnabled and "Status: Anti-Ragdoll Enabled" or "Status: Disabled"))))
         statusLabel.TextColor3 = (flyEnabled or infiniteJumpEnabled or godModeEnabled or antiRagdollEnabled) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)
    end
    saveSettings()
end

-- Toggle ESP - New Function
local function toggleESP()
    espEnabled = not espEnabled

    if espEnabled then
        toggleESPButton.Text = "Disable ESP"
        toggleESPButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        connections.RenderSteppedESP = runService.RenderStepped:Connect(updateESP)
        statusLabel.Text = "Status: ESP Enabled" .. (flyEnabled and " (Fly Enabled)" or "") .. (noclipEnabled and " (Noclip Enabled)" or "") .. (infiniteJumpEnabled and " (Infinite Jump Enabled)" or "") .. (godModeEnabled and " (God Mode Enabled)" or "") .. (antiRagdollEnabled and " (Anti-Ragdoll Enabled)" or "")
         statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)

         -- Optional: Enable Fullbright client-side (may not work/be filtered)
         -- lightingService.Ambient = Color3.fromRGB(255, 255, 255)
         -- lightingService.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    else
        toggleESPButton.Text = "Enable ESP"
        toggleESPButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
         if connections.RenderSteppedESP then
             connections.RenderSteppedESP:Disconnect()
             connections.RenderSteppedESP = nil
         end
         -- Clean up all visuals
         updateESP()
         statusLabel.Text = (flyEnabled and "Status: Fly Enabled (" .. movementMode .. ")" or (noclipEnabled and "Status: Noclip Enabled" or (infiniteJumpEnabled and "Status: Infinite Jump Enabled" or (godModeEnabled and "Status: God Mode Enabled" or (antiRagdollEnabled and "Status: Anti-Ragdoll Enabled" or "Status: Disabled")))))
         statusLabel.TextColor3 = (flyEnabled or infiniteJumpEnabled or godModeEnabled or antiRagdollEnabled) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)

          -- Optional: Reset Lighting
         -- lightingService.Ambient = Color3.fromRGB(0, 0, 0) -- Or original ambient
         -- lightingService.OutdoorAmbient = Color3.fromRGB(0, 0, 0) -- Or original outdoor ambient
    end
    saveSettings()
end


-- Toggle God Mode (Client-side attempt) - New Function
local function toggleGodMode()
    godModeEnabled = not godModeEnabled

    if godModeEnabled then
        toggleGodModeButton.Text = "Disable God Mode (Client)"
        toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Attempt to set health very high and disable health script (if it exists client-side)
         humanoid.Health = humanoid.MaxHealth + 1000 -- Set health above max
         if humanoid:FindFirstChild("Health") then
             humanoid.Health.Disabled = true -- Try disabling default health script
         end
         -- Continuously set health if it changes (might be server-side override)
         connections.HealthChanged = humanoid.HealthChanged:Connect(function(health)
             if godModeEnabled and health < humanoid.MaxHealth then
                  humanoid.Health = humanoid.MaxHealth + 1000
             end
         end)

         statusLabel.Text = "Status: God Mode Enabled (Client)" .. (flyEnabled and " (Fly Enabled)" or "") .. (noclipEnabled and " (Noclip Enabled)" or "") .. (infiniteJumpEnabled and " (Infinite Jump Enabled)" or "") .. (antiRagdollEnabled and " (Anti-Ragdoll Enabled)" or "")
        statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    else
        toggleGodModeButton.Text = "Enable God Mode (Client)"
        toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        -- Reset health to max and re-enable health script
         humanoid.Health = originalHealth or 100 -- Reset to original max health or default 100
         if humanoid:FindFirstChild("Health") then
              humanoid.Health.Disabled = false
         end
         if connections.HealthChanged then
              connections.HealthChanged:Disconnect()
              connections.HealthChanged = nil
         end

         statusLabel.Text = (flyEnabled and "Status: Fly Enabled (" .. movementMode .. ")" or (noclipEnabled and "Status: Noclip Enabled" or (infiniteJumpEnabled and "Status: Infinite Jump Enabled" or (antiRagdollEnabled and "Status: Anti-Ragdoll Enabled" or "Status: Disabled"))))
         statusLabel.TextColor3 = (flyEnabled or infiniteJumpEnabled or noclipEnabled or antiRagdollEnabled) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)
    end
    saveSettings()
end

-- Toggle Anti-Ragdoll (Client-side attempt) - New Function
local function toggleAntiRagdoll()
    antiRagdollEnabled = not antiRagdollEnabled

    if antiRagdollEnabled then
        toggleAntiRagdollButton.Text = "Disable Anti-Ragdoll (Client)"
        toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Constantly try to set PlatformStand or Sit (can be detected)
        connections.AntiRagdoll = runService.Stepped:Connect(function()
            if antiRagdollEnabled and humanoid.Sit == false and humanoid.PlatformStand == false then
                -- Try setting to Sit or PlatformStand
                -- humanoid.Sit = true
                 humanoid.PlatformStand = true -- Using PlatformStand as it's used for fly anyway
            end
        end)

         statusLabel.Text = "Status: Anti-Ragdoll Enabled (Client)" .. (flyEnabled and " (Fly Enabled)" or "") .. (noclipEnabled and " (Noclip Enabled)" or "") .. (infiniteJumpEnabled and " (Infinite Jump Enabled)" or "") .. (godModeEnabled and " (God Mode Enabled)" or "")
        statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    else
        toggleAntiRagdollButton.Text = "Enable Anti-Ragdoll (Client)"
        toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        if connections.AntiRagdoll then
            connections.AntiRagdoll:Disconnect()
            connections.AntiRagdoll = nil
        end
         -- Ensure PlatformStand is reset if not flying
         if not flyEnabled then
             humanoid.PlatformStand = false
         end

         statusLabel.Text = (flyEnabled and "Status: Fly Enabled (" .. movementMode .. ")" or (noclipEnabled and "Status: Noclip Enabled" or (infiniteJumpEnabled and "Status: Infinite Jump Enabled" or (godModeEnabled and "Status: God Mode Enabled" or "Status: Disabled"))))
         statusLabel.TextColor3 = (flyEnabled or infiniteJumpEnabled or noclipEnabled or godModeEnabled) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)
    end
    saveSettings()
end


-- Toggle Movement Mode - Updated to handle status and saving
local function toggleMovementMode()
    if movementMode == "Camera" then
        movementMode = "World"
        toggleMovementModeButton.Text = "Mode: World"
    else
        movementMode = "Camera"
        toggleMovementModeButton.Text = "Mode: Camera"
    end
    if flyEnabled then
         statusLabel.Text = "Status: Fly Enabled (" .. movementMode .. ")" .. (noclipEnabled and ", Noclip" or "") .. (infiniteJumpEnabled and ", Infinite Jump" or "") .. (godModeEnabled and ", God Mode" or "") .. (antiRagdollEnabled and ", Anti-Ragdoll" or "")
    end
    saveSettings()
end

-- Update Speed from Input - Updated to handle status and saving
local function updateSpeed()
    local newSpeed = tonumber(speedInput.Text)
    if newSpeed and newSpeed > 0 then
        flySpeed = newSpeed
         statusLabel.Text = "Status: Fly Speed updated to " .. flySpeed
         statusLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
          delay(2, function()
             local currentStatusText = "Status: Disabled"
             local currentStatusColor = Color3.fromRGB(255, 255, 255)
             if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             statusLabel.Text = currentStatusText
             statusLabel.TextColor3 = currentStatusColor
         end)
         saveSettings()
    else
        speedInput.Text = tostring(flySpeed)
         statusLabel.Text = "Status: Invalid Speed"
         statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
          delay(2, function()
               local currentStatusText = "Status: Disabled"
              local currentStatusColor = Color3.fromRGB(255, 255, 255)
              if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              statusLabel.Text = currentStatusText
              statusLabel.TextColor3 = currentStatusColor
          end)
    end
end

-- Update WalkSpeed from Input - Updated to handle status and saving
local function updateWalkSpeed()
     local newSpeed = tonumber(walkSpeedInput.Text)
     if newSpeed and newSpeed >= 0 then
         originalWalkSpeed = newSpeed -- Also update original in case of reset
         humanoid.WalkSpeed = newSpeed
          statusLabel.Text = "Status: WalkSpeed updated to " .. humanoid.WalkSpeed
          statusLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
           delay(2, function()
              local currentStatusText = "Status: Disabled"
              local currentStatusColor = Color3.fromRGB(255, 255, 255)
              if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              statusLabel.Text = currentStatusText
              statusLabel.TextColor3 = currentStatusColor
           end)
         saveSettings()
     else
         walkSpeedInput.Text = tostring(humanoid.WalkSpeed) -- Reset to current value
          statusLabel.Text = "Status: Invalid WalkSpeed"
          statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
           delay(2, function()
               local currentStatusText = "Status: Disabled"
              local currentStatusColor = Color3.fromRGB(255, 255, 255)
              if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              statusLabel.Text = currentStatusText
              statusLabel.TextColor3 = currentStatusColor
           end)
     end
end

-- Update JumpPower from Input - Updated to handle status and saving
local function updateJumpPower()
     local newPower = tonumber(jumpPowerInput.Text)
     if newPower and newPower >= 0 then
          originalJumpPower = newPower -- Also update original
         humanoid.JumpPower = newPower
          statusLabel.Text = "Status: JumpPower updated to " .. humanoid.JumpPower
          statusLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
           delay(2, function()
              local currentStatusText = "Status: Disabled"
              local currentStatusColor = Color3.fromRGB(255, 255, 255)
              if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              statusLabel.Text = currentStatusText
              statusLabel.TextColor3 = currentStatusColor
           end)
         saveSettings()
     else
         jumpPowerInput.Text = tostring(humanoid.JumpPower) -- Reset to current value
          statusLabel.Text = "Status: Invalid JumpPower"
          statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
           delay(2, function()
              local currentStatusText = "Status: Disabled"
              local currentStatusColor = Color3.fromRGB(255, 255, 255)
              if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
              statusLabel.Text = currentStatusText
              statusLabel.TextColor3 = currentStatusColor
           end)
     end
end

-- Toggle Infinite Jump - Updated to handle status and saving
local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled

    if infiniteJumpEnabled then
        toggleInfiniteJumpButton.Text = "Disable Infinite Jump"
        toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        connections.InfiniteJump = humanoid.Jumping:Connect(function()
            if infiniteJumpEnabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
         statusLabel.Text = "Status: Infinite Jump Enabled" .. (flyEnabled and " (Fly Enabled)" or "") .. (noclipEnabled and " (Noclip Enabled)" or "") .. (godModeEnabled and " (God Mode Enabled)" or "") .. (antiRagdollEnabled and " (Anti-Ragdoll Enabled)" or "")
        statusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
    else
        toggleInfiniteJumpButton.Text = "Enable Infinite Jump"
        toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        if connections.InfiniteJump then
            connections.InfiniteJump:Disconnect()
            connections.InfiniteJump = nil
        end
         statusLabel.Text = (flyEnabled and "Status: Fly Enabled (" .. movementMode .. ")" or (noclipEnabled and "Status: Noclip Enabled" or (godModeEnabled and "Status: God Mode Enabled" or (antiRagdollEnabled and "Status: Anti-Ragdoll Enabled" or "Status: Disabled"))))
         statusLabel.TextColor3 = (flyEnabled or noclipEnabled or godModeEnabled or antiRagdollEnabled) and Color3.fromRGB(50, 255, 50) or Color3.fromRGB(255, 255, 255)
    end
    saveSettings()
end

-- Teleport to Coordinates - New Function
local function teleportToCoords()
    local x = tonumber(coordXInput.Text)
    local y = tonumber(coordYInput.Text)
    local z = tonumber(coordZInput.Text)

    if x and y and z then
        rootPart.CFrame = CFrame.new(x, y, z)
         settings.TeleportCoords = {X = x, Y = y, Z = z} -- Save entered coords
         statusLabel.Text = "Status: Teleported to [" .. x .. ", " .. y .. ", " .. z .. "]"
         statusLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
          delay(2, function()
             local currentStatusText = "Status: Disabled"
             local currentStatusColor = Color3.fromRGB(255, 255, 255)
             if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             statusLabel.Text = currentStatusText
             statusLabel.TextColor3 = currentStatusColor
         end)
         saveSettings()
    else
         statusLabel.Text = "Status: Invalid Coordinates!"
         statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
          delay(2, function()
              local currentStatusText = "Status: Disabled"
             local currentStatusColor = Color3.fromRGB(255, 255, 255)
             if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             statusLabel.Text = currentStatusText
             statusLabel.TextColor3 = currentStatusColor
         end)
    end
end

-- Handle Click Teleport (Clicking on terrain when fly is enabled) - Same as before
local function handleClick(inputObject, gameProcessedEvent)
    if gameProcessedEvent or not flyEnabled or inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local mouse = player:GetMouse()
    local target = mouse.Target
    local hitPos = mouse.Hit.p

    -- Check if the target is part of the terrain or a baseplate/large static part
    if target and (target.Name == "Terrain" or target:IsA("BasePart") and target.Anchored) then
        -- Teleport slightly above the clicked position
        local teleportPosition = hitPos + Vector3.new(0, rootPart.Size.Y / 2 + 0.5, 0)
        rootPart.CFrame = CFrame.new(teleportPosition)
        statusLabel.Text = "Status: Teleported to ground"
         statusLabel.TextColor3 = Color3.fromRGB(50, 255, 255)
         delay(2, function()
             local currentStatusText = "Status: Disabled"
             local currentStatusColor = Color3.fromRGB(255, 255, 255)
             if flyEnabled then currentStatusText = "Status: Fly Enabled (" .. movementMode .. ")"; currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if noclipEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Noclip Enabled" or currentStatusText .. ", Noclip"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if infiniteJumpEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Infinite Jump Enabled" or currentStatusText .. ", Infinite Jump"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if godModeEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: God Mode Enabled" or currentStatusText .. ", God Mode"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             if antiRagdollEnabled then currentStatusText = (currentStatusText == "Status: Disabled" and "Status: Anti-Ragdoll Enabled" or currentStatusText .. ", Anti-Ragdoll"); currentStatusColor = Color3.fromRGB(50, 255, 50) end
             statusLabel.Text = currentStatusText
             statusLabel.TextColor3 = currentStatusColor
         end)
    end
end

-- Tab Functionality
local function showPage(pageName)
    featuresPage.Visible = (pageName == "Features")
    playersPage.Visible = (pageName == "Players")
    otherPage.Visible = (pageName == "Misc")

    featuresButton.BackgroundColor3 = (pageName == "Features") and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(70, 70, 70)
    featuresButton.TextColor3 = (pageName == "Features") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)

    playersButton.BackgroundColor3 = (pageName == "Players") and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(70, 70, 70)
    playersButton.TextColor3 = (pageName == "Players") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)

    otherButton.BackgroundColor3 = (pageName == "Misc") and Color3.fromRGB(90, 90, 90) or Color3.fromRGB(70, 70, 70)
    otherButton.TextColor3 = (pageName == "Misc") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)


    if pageName == "Players" then
        updatePlayerList() -- Update list whenever the tab is opened
    end
end


-- Connections (GUI)
guiConnections.toggleFlyClick = toggleFlyButton.MouseButton1Click:Connect(function()
    if flyEnabled then
        disableFly()
    else
        enableFly()
    end
end)

guiConnections.toggleNoclipClick = toggleNoclipButton.MouseButton1Click:Connect(toggleNoclip)
guiConnections.toggleMovementModeClick = toggleMovementModeButton.MouseButton1Click:Connect(toggleMovementMode)
guiConnections.toggleInfiniteJumpClick = toggleInfiniteJumpButton.MouseButton1Click:Connect(toggleInfiniteJump)
guiConnections.toggleESPClick = toggleESPButton.MouseButton1Click:Connect(toggleESP)
guiConnections.toggleGodModeClick = toggleGodModeButton.MouseButton1Click:Connect(toggleGodMode)
guiConnections.toggleAntiRagdollClick = toggleAntiRagdollButton.MouseButton1Click:Connect(toggleAntiRagdoll)
guiConnections.teleportCoordsClick = teleportCoordsButton.MouseButton1Click:Connect(teleportToCoords)


guiConnections.speedInputFocusLost = speedInput.FocusLost:Connect(updateSpeed)
guiConnections.speedInputTextReturned = speedInput.TextReturned:Connect(updateSpeed)

guiConnections.walkSpeedInputFocusLost = walkSpeedInput.FocusLost:Connect(updateWalkSpeed)
guiConnections.walkSpeedInputTextReturned = walkSpeedInput.TextReturned:Connect(updateWalkSpeed)

guiConnections.jumpPowerInputFocusLost = jumpPowerInput.FocusLost:Connect(updateJumpPower)
guiConnections.jumpPowerInputTextReturned = jumpPowerInput.TextReturned:Connect(updateJumpPower)

guiConnections.coordXInputFocusLost = coordXInput.FocusLost:Connect(saveSettings) -- Save coords when focus lost
guiConnections.coordYInputFocusLost = coordYInput.FocusLost:Connect(saveSettings)
guiConnections.coordZInputFocusLost = coordZInput.FocusLost:Connect(saveSettings)
guiConnections.coordXInputTextReturned = coordXInput.TextReturned:Connect(teleportToCoords) -- Teleport on Enter
guiConnections.coordYInputTextReturned = coordYInput.TextReturned:Connect(teleportToCoords)
guiConnections.coordZInputTextReturned = coordZInput.TextReturned:Connect(teleportToCoords)


guiConnections.featuresTabClick = featuresButton.MouseButton1Click:Connect(function() showPage("Features") end)
guiConnections.playersTabClick = playersButton.MouseButton1Click:Connect(function() showPage("Players") end)
guiConnections.otherTabClick = otherButton.MouseButton1Click:Connect(function() showPage("Misc") end)


-- Connections (Input/Character/Players)
connections.MouseClick = userInputService.InputBegan:Connect(handleClick)

-- Update player list when a player is added or removed
playerListConnections.PlayerAdded = playersService.PlayerAdded:Connect(updatePlayerList)
playerListConnections.PlayerRemoving = playersService.PlayerRemoving:Connect(updatePlayerList)


-- Ensure character references are updated on respawn and states reapplied
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    -- Store original max health for God Mode reset
    originalHealth = humanoid.MaxHealth

    -- Restore original speeds first in case they were modified by game scripts
    originalWalkSpeed = humanoid.WalkSpeed
    originalJumpPower = humanoid.JumpPower

    -- Apply saved settings states
    if noclipEnabled then
        delay(0.1, function()
            if character then -- Check if character still exists after delay
                 for i, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end
    if infiniteJumpEnabled then
         -- Reconnect infinite jump if it was enabled
         connections.InfiniteJump = humanoid.Jumping:Connect(function()
             if infiniteJumpEnabled then
                 humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
             end
         end)
    end
    if godModeEnabled then
         -- Re-apply God Mode effects
          humanoid.Health = humanoid.MaxHealth + 1000
          if humanoid:FindFirstChild("Health") then
              humanoid.Health.Disabled = true
          end
          connections.HealthChanged = humanoid.HealthChanged:Connect(function(health)
              if godModeEnabled and health < humanoid.MaxHealth then
                   humanoid.Health = humanoid.MaxHealth + 1000
              end
          end)
    end
     if antiRagdollEnabled then
         -- Reconnect Anti-Ragdoll
         connections.AntiRagdoll = runService.Stepped:Connect(function()
             if antiRagdollEnabled and humanoid.Sit == false and humanoid.PlatformStand == false then
                  humanoid.PlatformStand = true
             end
         end)
     end


    -- Apply WalkSpeed and JumpPower from input boxes
    updateWalkSpeed()
    updateJumpPower()

    disableFly() -- Ensure fly is off on new character
end)

-- Clean up connections when the script stops (optional, but good practice)
local function cleanup()
    disableFly() -- Ensure fly is off
    if infiniteJumpEnabled then toggleInfiniteJump() end -- Disable infinite jump
    if espEnabled then toggleESP() end -- Disable ESP and clean visuals
    if godModeEnabled then toggleGodMode() end -- Disable God Mode and reset health/script
    if antiRagdollEnabled then toggleAntiRagdoll() end -- Disable Anti-Ragdoll

     -- Reset WalkSpeed and JumpPower to defaults before cleaning up
     if character and humanoid then
          humanoid.WalkSpeed = originalWalkSpeed
          humanoid.JumpPower = originalJumpPower
          humanoid.Health = originalHealth
     end

    -- Disconnect all connections
    for name, conn in pairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
        connections[name] = nil
    end
     for name, conn in pairs(guiConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
        guiConnections[name] = nil
    end
     for name, conn in pairs(playerListConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
        playerListConnections[name] = nil
    end


     -- Remove GUIs
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
     if espGui and espGui.Parent then
        espGui:Destroy()
    end
end

-- Listen for the script being disabled or the game ending
script.AncestryChanged:Connect(function()
    if not script:IsDescendantOf(game) then
        cleanup()
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == player then
        cleanup()
    end
end)

-- Initial setup
loadSettings() -- Load initial settings
updateSpeed() -- Apply loaded speed to the input box (and flySpeed variable)
updateWalkSpeed() -- Apply loaded WalkSpeed to the humanoid and input box
updateJumpPower() -- Apply loaded JumpPower to the humanoid and input box

-- Apply initial states based on loaded settings
if noclipEnabled then toggleNoclip() end -- Call toggle function to set button state and apply effect
if infiniteJumpEnabled then toggleInfiniteJump() end
if espEnabled then toggleESP() end
if godModeEnabled then toggleGodMode() end
if antiRagdollEnabled then toggleAntiRagdoll() end

-- Set initial movement mode button text
toggleMovementModeButton.Text = "Mode: " .. movementMode

showPage("Features") -- Show features page by default
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

-- Initial player list update (after GUI is ready)
delay(0.5, updatePlayerList) -- Give the GUI a moment to render
