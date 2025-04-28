local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = game.Workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local playersService = game:GetService("Players")
local lightingService = game:GetService("Lighting") -- For potential Fullbright
local tweenService = game:GetService("TweenService") -- For smooth transitions

local flyEnabled = false
local noclipEnabled = false
local espEnabled = false
local godModeEnabled = false
local antiRagdollEnabled = false
local infiniteJumpEnabled = false
local fullbrightEnabled = false
local highJumpEnabled = false -- New toggle
local bhopEnabled = false -- New toggle

local flySpeed = 50 -- Default speed
local speedBurstMultiplier = 2.5 -- Default multiplier
local movementMode = "Camera" -- "Camera" or "World"

local originalWalkSpeed = humanoid.WalkSpeed
local originalJumpPower = humanoid.JumpPower
local originalHealth = humanoid.MaxHealth -- Store original max health
local originalAutoRotate = humanoid.AutoRotate
local originalAmbient = lightingService.Ambient -- Store original lighting
local originalOutdoorAmbient = lightingService.OutdoorAmbient

local highJumpPower = 100 -- Default power for High Jump (adjust as needed)

-- Store settings (simple in-memory store for this script instance)
local settings = {
    FlySpeed = flySpeed,
    NoclipEnabled = false,
    MovementMode = movementMode,
    WalkSpeed = originalWalkSpeed,
    JumpPower = originalJumpPower,
    InfiniteJumpEnabled = false,
    ESPEnabled = false,
    GodModeEnabled = false,
    AntiRagdollEnabled = false,
    FullbrightEnabled = false,
    HighJumpEnabled = false, -- New setting
    BhopEnabled = false, -- New setting
    SpeedBurstMultiplier = speedBurstMultiplier, -- New setting
    TeleportCoords = {X = 0, Y = 100, Z = 0},
    TeleportObjectName = ""
}

-- Load settings (simple in-memory load)
local function loadSettings()
    -- Implement file reading here for true persistence.
    -- Example: local loadedData = readfile("LuaGeminiFlySettings.json")
    -- if loadedData then settings = JSON:decode(loadedData) end

    flySpeed = settings.FlySpeed
    noclipEnabled = settings.NoclipEnabled
    movementMode = settings.MovementMode
    infiniteJumpEnabled = settings.InfiniteJumpEnabled
    espEnabled = settings.ESPEnabled
    godModeEnabled = settings.GodModeEnabled
    antiRagdollEnabled = settings.AntiRagdollEnabled
    fullbrightEnabled = settings.FullbrightEnabled
    highJumpEnabled = settings.HighJumpEnabled
    bhopEnabled = settings.BhopEnabled
    speedBurstMultiplier = settings.SpeedBurstMultiplier
    -- WalkSpeed, JumpPower, TeleportCoords, TeleportObjectName loaded below into GUI/variables
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
    settings.FullbrightEnabled = fullbrightEnabled
    settings.HighJumpEnabled = highJumpEnabled
    settings.BhopEnabled = bhopEnabled
    settings.SpeedBurstMultiplier = speedBurstMultiplier
    settings.TeleportCoords = {X = tonumber(coordXInput.Text) or settings.TeleportCoords.X, Y = tonumber(coordYInput.Text) or settings.TeleportCoords.Y, Z = tonumber(coordZInput.Text) or settings.TeleportCoords.Z}
    settings.TeleportObjectName = objectNameInput.Text
    -- Implement file writing here.
    -- print("Settings saved:", settings)
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
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Ensure GUI is above 3D world

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 680) -- Increased size again
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Darker background
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.Draggable = true
frame.Parent = screenGui

local titleBarFrame = Instance.new("Frame") -- Frame for title and buttons
titleBarFrame.Size = UDim2.new(1, 0, 0.035, 0)
titleBarFrame.Position = UDim2.new(0, 0, 0, 0)
titleBarFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleBarFrame.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.8, 0, 1, 0) -- Takes most of the width
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Text = " Lua Gemini v5" -- Updated title
titleLabel.Parent = titleBarFrame

local minimizeButton = Instance.new("TextButton")
minimizeButton.Size = UDim2.new(0.1, 0, 1, 0) -- Fixed size relative to title bar
minimizeButton.Position = UDim2.new(0.8, 0, 0, 0)
minimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeButton.TextSize = 18
minimizeButton.Font = Enum.Font.SourceSansBold
minimizeButton.Text = "-"
minimizeButton.Parent = titleBarFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0.1, 0, 1, 0)
closeButton.Position = UDim2.new(0.9, 0, 0, 0)
closeButton.BackgroundColor3 = Color3.fromRGB(90, 50, 50) -- Reddish for close
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.SourceSansBold
closeButton.Text = "X"
closeButton.Parent = titleBarFrame


local tabsFrame = Instance.new("Frame") -- Frame to hold tab buttons
tabsFrame.Size = UDim2.new(1, 0, 0.05, 0) -- Smaller tabs
tabsFrame.Position = UDim2.new(0, 0, 0.035, 0)
tabsFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
tabsFrame.Parent = frame

-- Tab Buttons (Same as before)
local featuresButton = Instance.new("TextButton")
featuresButton.Size = UDim2.new(1/3, 0, 1, 0)
featuresButton.Position = UDim2.new(0, 0, 0, 0)
featuresButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80) -- Highlighted
featuresButton.TextColor3 = Color3.fromRGB(255, 255, 255)
featuresButton.TextSize = 14
featuresButton.Font = Enum.Font.SourceSansBold
featuresButton.Text = "Features"
featuresButton.Parent = tabsFrame

local playersButton = Instance.new("TextButton")
playersButton.Size = UDim2.new(1/3, 0, 1, 0)
playersButton.Position = UDim2.new(1/3, 0, 0, 0)
playersButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
playersButton.TextColor3 = Color3.fromRGB(200, 200, 200)
playersButton.TextSize = 14
playersButton.Font = Enum.Font.SourceSansBold
playersButton.Text = "Players"
playersButton.Parent = tabsFrame

local otherButton = Instance.new("TextButton")
otherButton.Size = UDim2.new(1/3, 0, 1, 0)
otherButton.Position = UDim2.new(2/3, 0, 0, 0)
otherButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
otherButton.TextColor3 = Color3.fromRGB(200, 200, 200)
otherButton.TextSize = 14
otherButton.Font = Enum.Font.SourceSansBold
otherButton.Text = "Misc"
otherButton.Parent = tabsFrame


-- Content Pages (ScrollingFrames) - Position adjusted below tabs
local featuresPage = Instance.new("ScrollingFrame")
featuresPage.Size = UDim2.new(1, 0, 0.875, 0)
featuresPage.Position = UDim2.new(0, 0, 0.085, 0) -- Position below tabs
featuresPage.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
featuresPage.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated by layout
featuresPage.ScrollBarThickness = 6
featuresPage.BorderSizePixel = 0
featuresPage.Parent = frame
featuresPage.Visible = true

local playersPage = Instance.new("ScrollingFrame")
playersPage.Size = UDim2.new(1, 0, 0.875, 0)
playersPage.Position = UDim2.new(0, 0, 0.085, 0)
playersPage.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
playersPage.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated by layout
playersPage.ScrollBarThickness = 6
playersPage.BorderSizePixel = 0
playersPage.Parent = frame
playersPage.Visible = false

local otherPage = Instance.new("ScrollingFrame")
otherPage.Size = UDim2.new(1, 0, 0.875, 0)
otherPage.Position = UDim2.new(0, 0, 0.085, 0)
otherPage.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
otherPage.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated by layout
otherPage.ScrollBarThickness = 6
otherPage.BorderSizePixel = 0
otherPage.Parent = frame
otherPage.Visible = false


-- Status Label - Position adjusted below content pages
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.04, 0)
statusLabel.Position = UDim2.new(0, 0, 0.96, 0) -- Position below content
statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Text = "Status: Loading..."
statusLabel.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0.04, 0) -- Smaller info label
infoLabel.Position = UDim2.new(0, 0, 0.92, 0) -- Position above status
infoLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextSize = 10
infoLabel.TextWrapped = true
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Text = "W/S/A/D, Space/Ctrl. Hold Shift for Speed Burst. Click terrain to Teleport."
infoLabel.Parent = frame
infoLabel.Visible = true -- Keep visible

-- UI Layouts for pages (Same as before)
local featuresLayout = Instance.new("UIListLayout")
featuresLayout.FillDirection = Enum.FillDirection.Vertical
featuresLayout.SortOrder = Enum.SortOrder.LayoutOrder
featuresLayout.Padding = UDim.new(0, 5)
featuresLayout.Parent = featuresPage

local playersLayout = Instance.new("UIListLayout")
playersLayout.FillDirection = Enum.FillDirection.Vertical
playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersLayout.Padding = UDim.new(0, 5)
playersLayout.Parent = playersPage

local otherLayout = Instance.new("UIListLayout")
otherLayout.FillDirection = Enum.FillDirection.Vertical
otherLayout.SortOrder = Enum.SortOrder.LayoutOrder
otherLayout.Padding = UDim.new(0, 5)
otherLayout.Parent = otherPage


-- Helper to create a control container frame using UILayout (Same as before)
local function createControlContainer(parentFrame, heightOffset, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, 0, heightOffset) -- Full width minus padding, fixed height
    container.BackgroundColor3 = Color3.fromRGB(55, 55, 55) -- Slight contrast
    container.BorderSizePixel = 1
    container.BorderColor3 = Color3.fromRGB(65, 65, 65)
    container.LayoutOrder = layoutOrder
    container.Parent = parentFrame

    local innerLayout = Instance.new("UIListLayout")
    innerLayout.FillDirection = Enum.FillDirection.Horizontal -- Default horizontal
    innerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    innerLayout.Padding = UDim.new(0, 5)
    innerLayout.Parent = container

    return container, innerLayout -- Return both container and its layout
end

-- Section Header Helper (Same as before)
local function addSectionHeader(parentFrame, text, layoutOrder)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 20) -- Fixed height
    header.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    header.TextColor3 = Color3.fromRGB(255, 255, 255)
    header.TextSize = 14
    header.Font = Enum.Font.SourceSansBold
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = " " .. text -- Add space for padding
    header.LayoutOrder = layoutOrder
    header.Parent = parentFrame
    return header
end

-- Populate Features Page
local order = 1

-- Fly Controls Section
addSectionHeader(featuresPage, "Fly Controls", order); order = order + 1

local toggleFlyContainer, toggleFlyLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local toggleFlyButton = Instance.new("TextButton")
toggleFlyButton.Size = UDim2.new(1, 0, 1, 0)
toggleFlyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleFlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleFlyButton.TextSize = 14
toggleFlyButton.Font = Enum.Font.SourceSansBold
toggleFlyButton.Text = "Enable Fly"
toggleFlyButton.Parent = toggleFlyContainer

local speedContainer, speedLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.3, 0, 1, 0)
speedLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 12
speedLabel.Font = Enum.Font.SourceSans
speedLabel.Text = "Fly Speed:"
speedLabel.Parent = speedContainer

local speedSlider = Instance.new("Slider")
speedSlider.Size = UDim2.new(0.45, 0, 1, 0)
speedSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedSlider.BorderColor3 = Color3.fromRGB(90, 90, 90)
speedSlider.Minimum = 10 -- Minimum speed
speedSlider.Maximum = 300 -- Maximum speed
speedSlider.Value = flySpeed
speedSlider.Parent = speedContainer

local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0.2, 0, 1, 0)
speedInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.TextSize = 12
speedInput.Font = Enum.Font.SourceSans
speedInput.Text = tostring(math.floor(flySpeed))
speedInput.ClearTextOnFocus = false
speedInput.Parent = speedContainer

local speedMultiplierContainer, speedMultiplierLayout = createControlContainer(featuresPage, 30, order); order = order + 1 -- New input for multiplier
local speedMultiplierLabel = Instance.new("TextLabel")
speedMultiplierLabel.Size = UDim2.new(0.55, 0, 1, 0)
speedMultiplierLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedMultiplierLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedMultiplierLabel.TextSize = 12
speedMultiplierLabel.Font = Enum.Font.SourceSans
speedMultiplierLabel.Text = "Speed Burst Multiplier:"
speedMultiplierLabel.Parent = speedMultiplierContainer

local speedMultiplierInput = Instance.new("TextBox")
speedMultiplierInput.Size = UDim2.new(0.4, 0, 1, 0)
speedMultiplierInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
speedMultiplierInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedMultiplierInput.TextSize = 12
speedMultiplierInput.Font = Enum.Font.SourceSans
speedMultiplierInput.Text = tostring(speedBurstMultiplier)
speedMultiplierInput.ClearTextOnFocus = false
speedMultiplierInput.Parent = speedMultiplierContainer

local toggleMovementModeContainer, toggleMovementModeLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local toggleMovementModeButton = Instance.new("TextButton")
toggleMovementModeButton.Size = UDim2.new(1, 0, 1, 0)
toggleMovementModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleMovementModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleMovementModeButton.TextSize = 14
toggleMovementModeButton.Font = Enum.Font.SourceSansBold
toggleMovementModeButton.Text = "Mode: Camera"
toggleMovementModeButton.Parent = toggleMovementModeContainer

-- Movement Controls Section
addSectionHeader(featuresPage, "Movement Controls", order); order = order + 1

local walkSpeedContainer, walkSpeedLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local walkSpeedLabel = Instance.new("TextLabel")
walkSpeedLabel.Size = UDim2.new(0.3, 0, 1, 0)
walkSpeedLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
walkSpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
walkSpeedLabel.TextSize = 12
walkSpeedLabel.Font = Enum.Font.SourceSans
walkSpeedLabel.Text = "WalkSpeed:"
walkSpeedLabel.Parent = walkSpeedContainer

local walkSpeedSlider = Instance.new("Slider")
walkSpeedSlider.Size = UDim2.new(0.45, 0, 1, 0)
walkSpeedSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
walkSpeedSlider.BorderColor3 = Color3.fromRGB(90, 90, 90)
walkSpeedSlider.Minimum = 0
walkSpeedSlider.Maximum = 100 -- Max typical walk speed
walkSpeedSlider.Value = originalWalkSpeed
walkSpeedSlider.Parent = walkSpeedContainer

local walkSpeedInput = Instance.new("TextBox")
walkSpeedInput.Size = UDim2.new(0.2, 0, 1, 0)
walkSpeedInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
walkSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
walkSpeedInput.TextSize = 12
walkSpeedInput.Font = Enum.Font.SourceSans
walkSpeedInput.Text = tostring(math.floor(originalWalkSpeed))
walkSpeedInput.ClearTextOnFocus = false
walkSpeedInput.Parent = walkSpeedContainer

local jumpPowerContainer, jumpPowerLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local jumpPowerLabel = Instance.new("TextLabel")
jumpPowerLabel.Size = UDim2.new(0.3, 0, 1, 0)
jumpPowerLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
jumpPowerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
jumpPowerLabel.TextSize = 12
jumpPowerLabel.Font = Enum.Font.SourceSans
jumpPowerLabel.Text = "JumpPower:"
jumpPowerLabel.Parent = jumpPowerContainer

local jumpPowerSlider = Instance.new("Slider")
jumpPowerSlider.Size = UDim2.new(0.45, 0, 1, 0)
jumpPowerSlider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
jumpPowerSlider.BorderColor3 = Color3.fromRGB(90, 90, 90)
jumpPowerSlider.Minimum = 0
jumpPowerSlider.Maximum = 300 -- Max typical jump power
jumpPowerSlider.Value = originalJumpPower
jumpPowerSlider.Parent = jumpPowerContainer

local jumpPowerInput = Instance.new("TextBox")
jumpPowerInput.Size = UDim2.new(0.2, 0, 1, 0)
jumpPowerInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
jumpPowerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
jumpPowerInput.TextSize = 12
jumpPowerInput.Font = Enum.Font.SourceSans
jumpPowerInput.Text = tostring(math.floor(originalJumpPower))
jumpPowerInput.ClearTextOnFocus = false
jumpPowerInput.Parent = jumpPowerContainer

local toggleInfiniteJumpContainer, toggleInfiniteJumpLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local toggleInfiniteJumpButton = Instance.new("TextButton")
toggleInfiniteJumpButton.Size = UDim2.new(1, 0, 1, 0)
toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleInfiniteJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleInfiniteJumpButton.TextSize = 14
toggleInfiniteJumpButton.Font = Enum.Font.SourceSansBold
toggleInfiniteJumpButton.Text = "Enable Infinite Jump"
toggleInfiniteJumpButton.Parent = toggleInfiniteJumpContainer

local toggleHighJumpContainer, toggleHighJumpLayout = createControlContainer(featuresPage, 30, order); order = order + 1 -- New High Jump toggle
local toggleHighJumpButton = Instance.new("TextButton")
toggleHighJumpButton.Size = UDim2.new(1, 0, 1, 0)
toggleHighJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleHighJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleHighJumpButton.TextSize = 14
toggleHighJumpButton.Font = Enum.Font.SourceSansBold
toggleHighJumpButton.Text = "Enable High Jump"
toggleHighJumpButton.Parent = toggleHighJumpContainer

local toggleBhopContainer, toggleBhopLayout = createControlContainer(featuresPage, 30, order); order = order + 1 -- New Bhop toggle
local toggleBhopButton = Instance.new("TextButton")
toggleBhopButton.Size = UDim2.new(1, 0, 1, 0)
toggleBhopButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleBhopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBhopButton.TextSize = 14
toggleBhopButton.Font = Enum.Font.SourceSansBold
toggleBhopButton.Text = "Enable Bhop"
toggleBhopButton.Parent = toggleBhopContainer


-- Combat / Survival Section
addSectionHeader(featuresPage, "Combat / Survival (Client-Side)", order); order = order + 1

local toggleNoclipContainer, toggleNoclipLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local toggleNoclipButton = Instance.new("TextButton")
toggleNoclipButton.Size = UDim2.new(1, 0, 1, 0)
toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleNoclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleNoclipButton.TextSize = 14
toggleNoclipButton.Font = Enum.Font.SourceSansBold
toggleNoclipButton.Text = "Enable Noclip"
toggleNoclipButton.Parent = toggleNoclipContainer

local toggleGodModeContainer, toggleGodModeLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local toggleGodModeButton = Instance.new("TextButton")
toggleGodModeButton.Size = UDim2.new(1, 0, 1, 0)
toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleGodModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleGodModeButton.TextSize = 14
toggleGodModeButton.Font = Enum.Font.SourceSansBold
toggleGodModeButton.Text = "Enable God Mode (Client)"
toggleGodModeButton.Parent = toggleGodModeContainer

local toggleAntiRagdollContainer, toggleAntiRagdollLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local toggleAntiRagdollButton = Instance.new("TextButton")
toggleAntiRagdollButton.Size = UDim2.new(1, 0, 1, 0)
toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleAntiRagdollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleAntiRagdollButton.TextSize = 14
toggleAntiRagdollButton.Font = Enum.Font.SourceSansBold
toggleAntiRagdollButton.Text = "Enable Anti-Ragdoll (Client)"
toggleAntiRagdollButton.Parent = toggleAntiRagdollContainer

-- Teleport Controls Section
addSectionHeader(featuresPage, "Teleport Controls", order); order = order + 1

local teleportCoordsContainer, teleportCoordsLayout = createControlContainer(featuresPage, 60, order); order = order + 1
teleportCoordsLayout.FillDirection = Enum.FillDirection.Vertical
teleportCoordsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
teleportCoordsLayout.Padding = UDim.new(0, 3)

local coordLabel = Instance.new("TextLabel")
coordLabel.Size = UDim2.new(1, 0, 0, 15)
coordLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
coordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
coordLabel.TextSize = 11
coordLabel.Font = Enum.Font.SourceSans
coordLabel.TextXAlignment = Enum.TextXAlignment.Left
coordLabel.Text = " Coordinates (X, Y, Z):"
coordLabel.Parent = teleportCoordsContainer

local coordsInputFrame = Instance.new("Frame") -- Container for XYZ inputs
coordsInputFrame.Size = UDim2.new(1, 0, 0.4, 0)
coordsInputFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
coordsInputFrame.BorderSizePixel = 0
coordsInputFrame.Parent = teleportCoordsContainer

local coordsInputLayout = Instance.new("UIListLayout")
coordsInputLayout.FillDirection = Enum.FillDirection.Horizontal
coordsInputLayout.VerticalAlignment = Enum.VerticalAlignment.Center
coordsInputLayout.Padding = UDim.new(0, 5)
coordsInputLayout.Parent = coordsInputFrame

local coordXInput = Instance.new("TextBox")
coordXInput.Size = UDim2.new(1/3, -5, 1, 0)
coordXInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
coordXInput.TextColor3 = Color3.fromRGB(255, 255, 255)
coordXInput.TextSize = 12
coordXInput.Font = Enum.Font.SourceSans
coordXInput.PlaceholderText = "X"
coordXInput.Text = tostring(settings.TeleportCoords.X)
coordXInput.ClearTextOnFocus = false
coordXInput.Parent = coordsInputFrame

local coordYInput = Instance.new("TextBox")
coordYInput.Size = UDim2.new(1/3, -5, 1, 0)
coordYInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
coordYInput.TextColor3 = Color3.fromRGB(255, 255, 255)
coordYInput.TextSize = 12
coordYInput.Font = Enum.Font.SourceSans
coordYInput.PlaceholderText = "Y"
coordYInput.Text = tostring(settings.TeleportCoords.Y)
coordYInput.ClearTextOnFocus = false
coordYInput.Parent = coordsInputFrame

local coordZInput = Instance.new("TextBox")
coordZInput.Size = UDim2.new(1/3, -5, 1, 0)
coordZInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
coordZInput.TextColor3 = Color3.fromRGB(255, 255, 255)
coordZInput.TextSize = 12
coordZInput.Font = Enum.Font.SourceSans
coordZInput.PlaceholderText = "Z"
coordZInput.Text = tostring(settings.TeleportCoords.Z)
coordZInput.ClearTextOnFocus = false
coordZInput.Parent = coordsInputFrame

local teleportCoordsButton = Instance.new("TextButton")
teleportCoordsButton.Size = UDim2.new(1, 0, 0.45, 0)
teleportCoordsButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
teleportCoordsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportCoordsButton.TextSize = 14
teleportCoordsButton.Font = Enum.Font.SourceSansBold
teleportCoordsButton.Text = "Teleport to Coordinates"
teleportCoordsButton.Parent = teleportCoordsContainer

local teleportCrosshairContainer, teleportCrosshairLayout = createControlContainer(featuresPage, 30, order); order = order + 1
local teleportCrosshairButton = Instance.new("TextButton")
teleportCrosshairButton.Size = UDim2.new(1, 0, 1, 0)
teleportCrosshairButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
teleportCrosshairButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportCrosshairButton.TextSize = 14
teleportCrosshairButton.Font = Enum.Font.SourceSansBold
teleportCrosshairButton.Text = "Teleport to Crosshair"
teleportCrosshairButton.Parent = teleportCrosshairContainer


local teleportObjectContainer, teleportObjectLayout = createControlContainer(featuresPage, 60, order); order = order + 1
teleportObjectLayout.FillDirection = Enum.FillDirection.Vertical
teleportObjectLayout.VerticalAlignment = Enum.VerticalAlignment.Top
teleportObjectLayout.Padding = UDim.new(0, 3)

local objectNameLabel = Instance.new("TextLabel")
objectNameLabel.Size = UDim2.new(1, 0, 0, 15)
objectNameLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
objectNameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
objectNameLabel.TextSize = 11
objectNameLabel.Font = Enum.Font.SourceSans
objectNameLabel.TextXAlignment = Enum.TextXAlignment.Left
objectNameLabel.Text = " Object Name:"
objectNameLabel.Parent = teleportObjectContainer

local objectNameInput = Instance.new("TextBox")
objectNameInput.Size = UDim2.new(1, 0, 0.4, 0)
objectNameInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
objectNameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
objectNameInput.TextSize = 12
objectNameInput.Font = Enum.Font.SourceSans
objectNameInput.PlaceholderText = "Enter Object Name"
objectNameInput.Text = settings.TeleportObjectName
objectNameInput.ClearTextOnFocus = false
objectNameInput.Parent = teleportObjectContainer

local teleportObjectButton = Instance.new("TextButton")
teleportObjectButton.Size = UDim2.new(1, 0, 0.45, 0)
teleportObjectButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
teleportObjectButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportObjectButton.TextSize = 14
teleportObjectButton.Font = Enum.Font.SourceSansBold
teleportObjectButton.Text = "Teleport to Object"
teleportObjectButton.Parent = teleportObjectContainer


-- Update Features Page Canvas Size based on layout content
featuresPage.CanvasSize = UDim2.new(0, 0, 0, featuresLayout.AbsoluteContentSize.Y + 10)


-- Populate Other Page
local otherOrder = 1
addSectionHeader(otherPage, "Visuals", otherOrder); otherOrder = otherOrder + 1

local toggleESPContainer, toggleESPLayout = createControlContainer(otherPage, 30, otherOrder); otherOrder = otherOrder + 1
local toggleESPButton = Instance.new("TextButton")
toggleESPButton.Size = UDim2.new(1, 0, 1, 0)
toggleESPButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleESPButton.TextSize = 14
toggleESPButton.Font = Enum.Font.SourceSansBold
toggleESPButton.Text = "Enable ESP"
toggleESPButton.Parent = toggleESPContainer

local toggleFullbrightContainer, toggleFullbrightLayout = createControlContainer(otherPage, 30, otherOrder); otherOrder = otherOrder + 1
local toggleFullbrightButton = Instance.new("TextButton")
toggleFullbrightButton.Size = UDim2.new(1, 0, 1, 0)
toggleFullbrightButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleFullbrightButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleFullbrightButton.TextSize = 14
toggleFullbrightButton.Font = Enum.Font.SourceSansBold
toggleFullbrightButton.Text = "Enable Fullbright"
toggleFullbrightButton.Parent = toggleFullbrightContainer


-- Explanation of ESP limitations
local espExplanationLabel = Instance.new("TextLabel")
espExplanationLabel.Size = UDim2.new(1, -20, 0, 80) -- Fixed height for text
espExplanationLabel.Position = UDim2.new(0, 10, 0, otherLayout.AbsoluteContentSize.Y + 10) -- Position below last control + padding
espExplanationLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espExplanationLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
espExplanationLabel.TextSize = 12
espExplanationLabel.Font = Enum.Font.SourceSans
espExplanationLabel.TextWrapped = true
espExplanationLabel.TextXAlignment = Enum.TextXAlignment.Left
espExplanationLabel.Text = "ESP using UI is basic & may not see through walls reliably or be performant. Truly effective ESP needs exploit drawing functions (varies by executor)."
espExplanationLabel.Parent = otherPage


-- Update Other Page Canvas Size based on layout content + explanation label
otherPage.CanvasSize = UDim2.new(0, 0, 0, otherLayout.AbsoluteContentSize.Y + espExplanationLabel.Size.Y.Offset + 20)


-- ESP Drawing Layer (Using Roblox UI as a placeholder)
local espGui = Instance.new("ScreenGui")
espGui.Name = "ESPGui"
espGui.Parent = player:WaitForChild("PlayerGui")
espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Ensure ESP is above other UI
espGui.DisplayOrder = 100 -- Higher DisplayOrder to draw on top


-- ESP Update Logic (Uses Heartbeat for rendering updates - client-side)
local function updateESP()
    -- Clean up visuals for players who left or are no longer valid
    local playersInGame = {}
    for _, p in pairs(playersService:GetPlayers()) do
        playersInGame[p.Name] = true
    end

    for targetName, visuals in pairs(espVisuals) do
        if not playersInGame[targetName] or not playersService:FindFirstChild(targetName) or not playersService[targetName].Character or not playersService[targetName].Character:FindFirstChild("HumanoidRootPart") then
            if visuals.Box and visuals.Box.Parent then visuals.Box:Destroy() end
            if visuals.NameLabel and visuals.NameLabel.Parent then visuals.NameLabel:Destroy() end
            espVisuals[targetName] = nil
        end
    end

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
                box.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red box
                box.BackgroundTransparency = 0.8
                box.BorderSizePixel = 1
                box.BorderColor3 = Color3.fromRGB(255, 255, 255)
                box.ZIndex = 2

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = targetPlayer.Name .. "Name"
                nameLabel.Size = UDim2.new(1, 0, 0, 20) -- Full width of box, fixed height
                nameLabel.Position = UDim2.new(0, 0, 1, 0) -- Below the box
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 12
                nameLabel.Font = Enum.Font.SourceSansBold
                nameLabel.BackgroundTransparency = 1
                nameLabel.ZIndex = 2

                box.Parent = espGui
                nameLabel.Parent = box -- Parent name label to box for easy positioning

                espVisuals[targetPlayer.Name] = {Box = box, NameLabel = nameLabel}
            end

            local visuals = espVisuals[targetPlayer.Name]

            if isOnScreen then
                -- Position and scale the box based on distance
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
        elseif espVisuals[targetPlayer.Name] then
             -- Clean up visuals if the player is now ourselves or invalid
             if espVisuals[targetPlayer.Name].Box and espVisuals[targetPlayer.Name].Box.Parent then espVisuals[targetPlayer.Name].Box:Destroy() end
            if espVisuals[targetPlayer.Name].NameLabel and espVisuals[targetPlayer.Name].NameLabel.Parent then espVisuals[targetPlayer.Name].NameLabel:Destroy() end
            espVisuals[targetPlayer.Name] = nil
        end
    end
end


-- Populate Players Page (Same as before)
local playerButtonTemplate = Instance.new("TextButton")
playerButtonTemplate.Size = UDim2.new(1, -10, 0, 30) -- Full width minus padding, fixed height
playerButtonTemplate.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
playerButtonTemplate.TextColor3 = Color3.fromRGB(255, 255, 255)
playerButtonTemplate.TextSize = 14
playerButtonTemplate.Font = Enum.Font.SourceSansBold
playerButtonTemplate.TextXAlignment = Enum.TextXAlignment.Left
playerButtonTemplate.BorderSizePixel = 0


local function createPlayerButton(targetPlayer)
    local button = playerButtonTemplate:Clone()
    button.Name = targetPlayer.Name .. "Button"
    button.Text = targetPlayer.Name

    guiConnections[button] = button.MouseButton1Click:Connect(function()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = targetPlayer.Character.HumanoidRootPart
            -- Teleport slightly above the target player
            rootPart.CFrame = targetRoot.CFrame + Vector3.new(0, 5, 0)
            updateStatus("Teleported to " .. targetPlayer.Name, Color3.fromRGB(50, 255, 255), 2) -- Use updated status function
        else
            updateStatus("Player not found or not spawned!", Color3.fromRGB(255, 50, 50), 2) -- Use updated status function
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
    local currentY = 0 -- Not needed with UIListLayout, but useful for CanvasSize calculation
    local playerCount = 0

    for _, p in pairs(players) do
        if p ~= player then -- Don't add ourselves to the list
            local button = createPlayerButton(p)
            button.Parent = playersPage -- UIListLayout will handle positioning
            currentY += button.Size.Y.Offset + playersLayout.Padding.Offset
            playerCount += 1
        end
    end

    -- Update CanvasSize
    playersPage.CanvasSize = UDim2.new(0, 0, 0, currentY)
    updateStatus("Player list updated (" .. playerCount .. " other players)", Color3.fromRGB(50, 255, 255), 2) -- Use updated status function
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

-- Function to update the status label cleanly (Same as before)
local statusResetTimer = nil
local function updateStatus(message, color, duration)
     -- Cancel previous reset timer if it exists
     if statusResetTimer then
         task.cancel(statusResetTimer)
     end

     statusLabel.Text = "Status: " .. message
     statusLabel.TextColor3 = color

     if duration then
         statusResetTimer = task.delay(duration, function()
             -- Restore default status based on current toggles after delay
             local activeFeatures = {}
             if flyEnabled then table.insert(activeFeatures, "Fly (" .. movementMode .. ")") end
             if noclipEnabled then table.insert(activeFeatures, "Noclip") end
             if infiniteJumpEnabled then table.insert(activeFeatures, "Infinite Jump") end
             if highJumpEnabled then table.insert(activeFeatures, "High Jump") end -- Add High Jump status
             if bhopEnabled then table.insert(activeFeatures, "Bhop") end -- Add Bhop status
             if godModeEnabled then table.insert(activeFeatures, "God Mode") end
             if antiRagdollEnabled then table.insert(activeFeatures, "Anti-Ragdoll") end
             if espEnabled then table.insert(activeFeatures, "ESP") end
             if fullbrightEnabled then table.insert(activeFeatures, "Fullbright") end


             if #activeFeatures > 0 then
                 statusLabel.Text = "Status: " .. table.concat(activeFeatures, ", ")
                 currentStatusColor = Color3.fromRGB(50, 255, 50) -- Green for active features
             else
                  statusLabel.Text = "Status: Disabled"
                  currentStatusColor = Color3.fromRGB(255, 255, 255)
             end
              statusLabel.TextColor3 = currentStatusColor -- Apply color
         end)
     end
end


-- Enable/Disable Fly (Same as before, uses updateStatus)
local function enableFly()
    if flyEnabled then return end
    flyEnabled = true
    humanoid.PlatformStand = true
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    originalAutoRotate = humanoid.AutoRotate -- Save original auto rotate
    humanoid.AutoRotate = false -- Disable auto rotate for better fly control

    connections.Stepped = runService.Stepped:Connect(updateFlyMovement)

    toggleFlyButton.Text = "Disable Fly"
    toggleFlyButton.BackgroundColor3 = Color3.fromRGB(90, 50, 50)
    updateStatus("Fly Enabled (" .. movementMode .. ")", Color3.fromRGB(50, 255, 50))
    saveSettings()
end

local function disableFly()
    if not flyEnabled then return end
    flyEnabled = false
    humanoid.PlatformStand = false
    humanoid.AutoRotate = originalAutoRotate -- Restore auto rotate
    -- Reset WalkSpeed and JumpPower to whatever the inputs currently show
    updateWalkSpeed(true) -- Update without status spam
    updateJumpPower(true)

    if connections.Stepped then
        connections.Stepped:Disconnect()
        connections.Stepped = nil
    end

    toggleFlyButton.Text = "Enable Fly"
    toggleFlyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    updateStatus("Fly Disabled", Color3.fromRGB(255, 255, 255)) -- Status will be updated by updateStatus delayed call if other features are active
    saveSettings()
end

-- Toggle Noclip (Same as before, uses updateStatus)
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    if character then -- Check if character exists
        for i, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = not noclipEnabled
            end
        end
    end

    if noclipEnabled then
        toggleNoclipButton.Text = "Disable Noclip"
        toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        updateStatus("Noclip Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleNoclipButton.Text = "Enable Noclip"
        toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        updateStatus("Noclip Disabled", Color3.fromRGB(255, 255, 255))
    end
    saveSettings()
end

-- Toggle Movement Mode (Same as before, uses updateStatus)
local function toggleMovementMode()
    if movementMode == "Camera" then
        movementMode = "World"
        toggleMovementModeButton.Text = "Mode: World"
    else
        movementMode = "Camera"
        toggleMovementModeButton.Text = "Mode: Camera"
    end
    if flyEnabled then
         updateStatus("Fly Enabled (" .. movementMode .. ")", Color3.fromRGB(50, 255, 50))
    end
    saveSettings()
end

-- Update Fly Speed from Input/Slider (Same as before, uses updateStatus)
local function updateFlySpeed(noStatusUpdate)
    local newSpeed = tonumber(speedInput.Text)
    if newSpeed and newSpeed >= speedSlider.Minimum and newSpeed <= speedSlider.Maximum then
        flySpeed = newSpeed
        speedSlider.Value = flySpeed -- Keep slider in sync
        if not noStatusUpdate then
             updateStatus("Fly Speed updated to " .. math.floor(flySpeed), Color3.fromRGB(50, 255, 255), 2)
        end
        saveSettings()
    else
        speedInput.Text = tostring(math.floor(flySpeed))
        speedSlider.Value = flySpeed
        if not noStatusUpdate then
             updateStatus("Invalid Speed", Color3.fromRGB(255, 50, 50), 2)
        end
    end
end

-- Update Speed Burst Multiplier from Input
local function updateSpeedMultiplier()
    local newMultiplier = tonumber(speedMultiplierInput.Text)
    if newMultiplier and newMultiplier > 0 then
        speedBurstMultiplier = newMultiplier
        updateStatus("Speed Multiplier updated to " .. speedBurstMultiplier, Color3.fromRGB(50, 255, 255), 2)
        saveSettings()
    else
        speedMultiplierInput.Text = tostring(speedBurstMultiplier)
         updateStatus("Invalid Multiplier", Color3.fromRGB(255, 50, 50), 2)
    end
end

-- Update WalkSpeed from Input/Slider (Same as before, uses updateStatus)
local function updateWalkSpeed(noStatusUpdate)
     local newSpeed = tonumber(walkSpeedInput.Text)
     if newSpeed and newSpeed >= walkSpeedSlider.Minimum and newSpeed <= walkSpeedSlider.Maximum then
         humanoid.WalkSpeed = newSpeed
         walkSpeedSlider.Value = newSpeed -- Keep slider in sync
         if not noStatusUpdate then
              updateStatus("WalkSpeed updated to " .. math.floor(humanoid.WalkSpeed), Color3.fromRGB(50, 255, 255), 2)
         end
         saveSettings()
     else
         walkSpeedInput.Text = tostring(math.floor(humanoid.WalkSpeed))
         walkSpeedSlider.Value = humanoid.WalkSpeed
         if not noStatusUpdate then
              updateStatus("Invalid WalkSpeed", Color3.fromRGB(255, 50, 50), 2)
         end
     end
end

-- Update JumpPower from Input/Slider (Same as before, uses updateStatus)
local function updateJumpPower(noStatusUpdate)
     local newPower = tonumber(jumpPowerInput.Text)
     if newPower and newPower >= jumpPowerSlider.Minimum and newPower <= jumpPowerSlider.Maximum then
         humanoid.JumpPower = newPower
         jumpPowerSlider.Value = newPower -- Keep slider in sync
         if not noStatusUpdate then
              updateStatus("JumpPower updated to " .. math.floor(humanoid.JumpPower), Color3.fromRGB(50, 255, 255), 2)
         end
         saveSettings()
     else
         jumpPowerInput.Text = tostring(math.floor(humanoid.JumpPower))
         jumpPowerSlider.Value = humanoid.JumpPower
         if not noStatusUpdate then
              updateStatus("Invalid JumpPower", Color3.fromRGB(255, 50, 50), 2)
         end
     end
end


-- Toggle Infinite Jump (Same as before, uses updateStatus)
local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled

    if infiniteJumpEnabled then
        toggleInfiniteJumpButton.Text = "Enable Infinite Jump"
        toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        connections.InfiniteJump = humanoid.Jumping:Connect(function()
            if infiniteJumpEnabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        updateStatus("Infinite Jump Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleInfiniteJumpButton.Text = "Disable Infinite Jump"
        toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        if connections.InfiniteJump then
            connections.InfiniteJump:Disconnect()
            connections.InfiniteJump = nil
        end
        updateStatus("Infinite Jump Disabled", Color3.fromRGB(255, 255, 255))
    end
    saveSettings()
end

-- Toggle High Jump
local function toggleHighJump()
    highJumpEnabled = not highJumpEnabled

    if highJumpEnabled then
        toggleHighJumpButton.Text = "Disable High Jump"
        toggleHighJumpButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Note: High Jump modifies JumpPower when activated, need to restore later
        updateStatus("High Jump Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleHighJumpButton.Text = "Enable High Jump"
        toggleHighJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
         -- Restore JumpPower to what the input shows if fly is not enabled
         if not flyEnabled then
             updateJumpPower(true)
         end
        updateStatus("High Jump Disabled", Color3.fromRGB(255, 255, 255))
    end
    saveSettings()
end

-- Toggle Bhop
local function toggleBhop()
    bhopEnabled = not bhopEnabled

    if bhopEnabled then
        toggleBhopButton.Text = "Disable Bhop"
        toggleBhopButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Connect StateChanged to detect landing
        connections.Bhop = humanoid.StateChanged:Connect(function(oldState, newState)
            -- Check if landing from falling or jumping and bhop is enabled
            if bhopEnabled and (oldState == Enum.HumanoidStateType.Freefall or oldState == Enum.HumanoidStateType.Jumping) and newState == Enum.HumanoidStateType.Landed then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping) -- Trigger jump
            end
        end)
        updateStatus("Bhop Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleBhopButton.Text = "Disable Bhop"
        toggleBhopButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        if connections.Bhop then
            connections.Bhop:Disconnect()
            connections.Bhop = nil
        end
        updateStatus("Bhop Disabled", Color3.fromRGB(255, 255, 255))
    end
    saveSettings()
end


-- Toggle God Mode (Client-Side) (Same as before, uses updateStatus)
local function toggleGodMode()
    godModeEnabled = not godModeEnabled

    if godModeEnabled then
        toggleGodModeButton.Text = "Disable God Mode (Client)"
        toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        humanoid.MaxHealth = math.huge
        humanoid.Health = humanoid.MaxHealth
         updateStatus("God Mode Enabled (Client)", Color3.fromRGB(50, 255, 50))
         connections.GodMode = runService.Heartbeat:Connect(function()
             if godModeEnabled and humanoid.Health < humanoid.MaxHealth then
                 humanoid.Health = humanoid.MaxHealth
             end
         end)
    else
        toggleGodModeButton.Text = "Enable God Mode (Client)"
        toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        humanoid.MaxHealth = originalHealth
        humanoid.Health = originalHealth
         updateStatus("God Mode Disabled (Client)", Color3.fromRGB(255, 255, 255))
         if connections.GodMode then
             connections.GodMode:Disconnect()
             connections.GodMode = nil
         end
    end
    saveSettings()
end

-- Toggle Anti-Ragdoll (Client-Side) (Same as before, uses updateStatus)
local function toggleAntiRagdoll()
    antiRagdollEnabled = not antiRagdollEnabled

    if antiRagdollEnabled then
        toggleAntiRagdollButton.Text = "Disable Anti-Ragdoll (Client)"
        toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        connections.AntiRagdoll = humanoid.StateChanged:Connect(function(oldState, newState)
            if antiRagdollEnabled and (newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Dead) then
                task.delay(0.1, function()
                     if antiRagdollEnabled and character and character.Parent then
                         humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                     end
                end)
            end
        end)
         updateStatus("Anti-Ragdoll Enabled (Client)", Color3.fromRGB(50, 255, 50))
    else
        toggleAntiRagdollButton.Text = "Enable Anti-Ragdoll (Client)"
        toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        if connections.AntiRagdoll then
            connections.AntiRagdoll:Disconnect()
            connections.AntiRagdoll = nil
        end
        updateStatus("Anti-Ragdoll Disabled (Client)", Color3.fromRGB(255, 255, 255))
    end
    saveSettings()
end


-- Toggle ESP (Same as before, uses updateStatus)
local function toggleESP()
    espEnabled = not espEnabled

    if espEnabled then
        toggleESPButton.Text = "Disable ESP"
        toggleESPButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        updateStatus("ESP Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleESPButton.Text = "Enable ESP"
        toggleESPButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        updateESP() -- Call one last time to clean up visuals immediately
        updateStatus("ESP Disabled", Color3.fromRGB(255, 255, 255))
    end
    saveSettings()
end

-- Toggle Fullbright (Same as before, uses updateStatus)
local function toggleFullbright()
    fullbrightEnabled = not fullbrightEnabled

    if fullbrightEnabled then
        toggleFullbrightButton.Text = "Disable Fullbright"
        toggleFullbrightButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        lightingService.Ambient = Color3.fromRGB(255, 255, 255)
        lightingService.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
         updateStatus("Fullbright Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleFullbrightButton.Text = "Enable Fullbright"
        toggleFullbrightButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        lightingService.Ambient = originalAmbient
        lightingService.OutdoorAmbient = originalOutdoorAmbient
        updateStatus("Fullbright Disabled", Color3.fromRGB(255, 255, 255))
    end
    saveSettings()
end


-- Handle Teleport to Coords (Same as before, uses updateStatus and saving)
local function teleportToCoords()
    local x = tonumber(coordXInput.Text)
    local y = tonumber(coordYInput.Text)
    local z = tonumber(coordZInput.Text)

    if x and y and z then
        rootPart.CFrame = CFrame.new(x, y + rootPart.Size.Y / 2 + 0.1, z)
        updateStatus("Teleported to " .. math.floor(x) .. ", " .. math.floor(y) .. ", " .. math.floor(z), Color3.fromRGB(50, 255, 255), 2)
        settings.TeleportCoords = {X = x, Y = y, Z = z}
        saveSettings()
    else
        updateStatus("Invalid coordinates", Color3.fromRGB(255, 50, 50), 2)
    end
}

-- Handle Teleport to Crosshair (Same as before, uses updateStatus)
local function teleportToCrosshair()
     local mouse = player:GetMouse()
     local target = mouse.Target
     local hitPos = mouse.Hit.p

     if target then
         local teleportPosition = hitPos + Vector3.new(0, rootPart.Size.Y / 2 + 0.5, 0)
         rootPart.CFrame = CFrame.new(teleportPosition)
         updateStatus("Teleported to crosshair at " .. math.floor(hitPos.X) .. ", " .. math.floor(hitPos.Y) .. ", " .. math.floor(hitPos.Z), Color3.fromRGB(50, 255, 255), 2)
     else
         updateStatus("No target found under crosshair!", Color3.fromRGB(255, 50, 50), 2)
     end
end

-- Handle Teleport to Object by Name (Same as before, uses updateStatus and saving)
local function teleportToObject()
     local objectName = objectNameInput.Text
     if objectName and string.len(objectName) > 0 then
         local targetObject = game.Workspace:FindFirstChild(objectName, true)

         if targetObject and targetObject:IsA("BasePart") then
              local teleportPosition = targetObject.Position + Vector3.new(0, targetObject.Size.Y / 2 + rootPart.Size.Y / 2 + 0.5, 0)
             rootPart.CFrame = CFrame.new(teleportPosition)
             updateStatus("Teleported to object '" .. objectName .. "'", Color3.fromRGB(50, 255, 255), 2)
             settings.TeleportObjectName = objectName
             saveSettings()
         elseif targetObject and targetObject:IsA("Model") and targetObject:FindFirstChild("PrimaryPart") then
              local primaryPart = targetObject.PrimaryPart
              local teleportPosition = primaryPart.Position + Vector3.new(0, primaryPart.Size.Y / 2 + rootPart.Size.Y / 2 + 0.5, 0)
             rootPart.CFrame = CFrame.new(teleportPosition)
              updateStatus("Teleported to model '" .. objectName .. "'", Color3.fromRGB(50, 255, 255), 2)
              settings.TeleportObjectName = objectName
             saveSettings()
         else
             updateStatus("Object '" .. objectName .. "' not found or is not a teleport target!", Color3.fromRGB(255, 50, 50), 2)
         end
     else
         updateStatus("Please enter an object name!", Color3.fromRGB(255, 50, 50), 2)
     end
end


-- Handle Click Teleport (Clicking on terrain when fly is enabled) (Same as before, uses updateStatus)
local function handleClick(inputObject, gameProcessedEvent)
    if gameProcessedEvent or not flyEnabled or inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local mouse = player:GetMouse()
    local target = mouse.Target
    local hitPos = mouse.Hit.p

    if target and (target.Name == "Terrain" or (target:IsA("BasePart") and target.Anchored)) then
        local teleportPosition = hitPos + Vector3.new(0, rootPart.Size.Y / 2 + 0.5, 0)
        rootPart.CFrame = CFrame.new(teleportPosition)
        updateStatus("Teleported to ground at " .. math.floor(hitPos.X) .. ", " .. math.floor(hitPos.Y) .. ", " .. math.floor(hitPos.Z), Color3.fromRGB(50, 255, 255), 2)
    end
end

-- Tab Functionality (Same as before)
local function showPage(pageName)
    featuresPage.Visible = (pageName == "Features")
    playersPage.Visible = (pageName == "Players")
    otherPage.Visible = (pageName == "Misc")

    featuresButton.BackgroundColor3 = (pageName == "Features") and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
    featuresButton.TextColor3 = (pageName == "Features") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)

    playersButton.BackgroundColor3 = (pageName == "Players") and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
    playersButton.TextColor3 = (pageName == "Players") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)

    otherButton.BackgroundColor3 = (pageName == "Misc") and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(60, 60, 60)
    otherButton.TextColor3 = (pageName == "Misc") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)

    if pageName == "Players" then
        updatePlayerList() -- Update list whenever the tab is opened
    end
     -- Update CanvasSize for the displayed page
    if featuresPage.Visible then featuresPage.CanvasSize = UDim2.new(0, 0, 0, featuresLayout.AbsoluteContentSize.Y + 10) end
    if playersPage.Visible then playersPage.CanvasSize = UDim2.new(0, 0, 0, playersLayout.AbsoluteContentSize.Y + 10) end -- Recalculate after list update
    if otherPage.Visible then otherPage.CanvasSize = UDim2.new(0, 0, 0, otherLayout.AbsoluteContentSize.Y + espExplanationLabel.Size.Y.Offset + 20) end -- Include explanation label height
end

-- GUI Minimize/Restore Logic
local originalFrameSize = frame.Size
local minimized = false

local function toggleMinimize()
    minimized = not minimized

    if minimized then
        -- Hide all content except title bar and tabs
        featuresPage.Visible = false
        playersPage.Visible = false
        otherPage.Visible = false
        statusLabel.Visible = false
        infoLabel.Visible = false
        frame.Size = UDim2.new(originalFrameSize.X.Scale, originalFrameSize.X.Offset, titleBarFrame.Size.Y.Scale + tabsFrame.Size.Y.Scale, titleBarFrame.Size.Y.Offset + tabsFrame.Size.Y.Offset)
        minimizeButton.Text = "+" -- Change text to plus
    else
        -- Restore size and show active page
        frame.Size = originalFrameSize
        statusLabel.Visible = true
        infoLabel.Visible = true
        showPage(currentActivePage) -- Show the last active page
        minimizeButton.Text = "-" -- Change text to minus
    end
end

-- GUI Close Logic
local function closeGui()
    -- Instead of destroying, just hide for quick reopening
    screenGui.Enabled = false
     -- Clean up features that need disconnecting when GUI is not active? (Less critical if cleanup handles script end)
     -- OR rely solely on script cleanup on disable/game end. Let's rely on cleanup for now.
end

-- Initial page tracker
local currentActivePage = "Features" -- Default page

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
guiConnections.toggleHighJumpClick = toggleHighJumpButton.MouseButton1Click:Connect(toggleHighJump) -- New connection
guiConnections.toggleBhopClick = toggleBhopButton.MouseButton1Click:Connect(toggleBhop) -- New connection
guiConnections.toggleGodModeClick = toggleGodModeButton.MouseButton1Click:Connect(toggleGodMode)
guiConnections.toggleAntiRagdollClick = toggleAntiRagdollButton.MouseButton1Click:Connect(toggleAntiRagdoll)
guiConnections.toggleESPClick = toggleESPButton.MouseButton1Click:Connect(toggleESP)
guiConnections.toggleFullbrightClick = toggleFullbrightButton.MouseButton1Click:Connect(toggleFullbright)
guiConnections.teleportCoordsButtonClick = teleportCoordsButton.MouseButton1Click:Connect(teleportToCoords)
guiConnections.teleportCrosshairButtonClick = teleportCrosshairButton.MouseButton1Click:Connect(teleportToCrosshair)
guiConnections.teleportObjectButtonClick = teleportObjectButton.MouseButton1Click:Connect(teleportToObject)

guiConnections.minimizeButtonClick = minimizeButton.MouseButton1Click:Connect(toggleMinimize) -- Minimize connection
guiConnections.closeButtonClick = closeButton.MouseButton1Click:Connect(closeGui) -- Close connection


-- Slider and Input Sync for Fly Speed (Same as before)
guiConnections.speedSliderChanged = speedSlider.Changed:Connect(function()
    flySpeed = speedSlider.Value
    speedInput.Text = tostring(math.floor(flySpeed))
    saveSettings()
end)
guiConnections.speedInputFocusLost = speedInput.FocusLost:Connect(function()
    updateFlySpeed()
end)
guiConnections.speedInputTextReturned = speedInput.TextReturned:Connect(function()
    updateFlySpeed()
end)

-- Input Sync for Speed Burst Multiplier
guiConnections.speedMultiplierInputFocusLost = speedMultiplierInput.FocusLost:Connect(updateSpeedMultiplier)
guiConnections.speedMultiplierInputTextReturned = speedMultiplierInput.TextReturned:Connect(updateSpeedMultiplier)


-- Slider and Input Sync for WalkSpeed (Same as before)
guiConnections.walkSpeedSliderChanged = walkSpeedSlider.Changed:Connect(function()
    local newSpeed = walkSpeedSlider.Value
    humanoid.WalkSpeed = newSpeed
    walkSpeedInput.Text = tostring(math.floor(newSpeed))
    saveSettings()
end)
guiConnections.walkSpeedInputFocusLost = walkSpeedInput.FocusLost:Connect(updateWalkSpeed)
guiConnections.walkSpeedInputTextReturned = walkSpeedInput.TextReturned:Connect(updateWalkSpeed)


-- Slider and Input Sync for JumpPower (Same as before)
guiConnections.jumpPowerSliderChanged = jumpPowerSlider.Changed:Connect(function()
    local newPower = jumpPowerSlider.Value
    humanoid.JumpPower = newPower
    jumpPowerInput.Text = tostring(math.floor(newPower))
    saveSettings()
end)
guiConnections.jumpPowerInputFocusLost = jumpPowerInput.FocusLost:Connect(updateJumpPower)
guiConnections.jumpPowerInputTextReturned = jumpPowerInput.TextReturned:Connect(updateJumpPower)

-- Save teleport coords/object name when input fields lose focus (Same as before)
guiConnections.coordXInputFocusLost = coordXInput.FocusLost:Connect(function() settings.TeleportCoords.X = tonumber(coordXInput.Text) or settings.TeleportCoords.X; saveSettings() end)
guiConnections.coordYInputFocusLost = coordYInput.FocusLost:Connect(function() settings.TeleportCoords.Y = tonumber(coordYInput.Text) or settings.TeleportCoords.Y; saveSettings() end)
guiConnections.coordZInputFocusLost = coordZInput.FocusLost:Connect(function() settings.TeleportCoords.Z = tonumber(coordZInput.Text) or settings.TeleportCoords.Z; saveSettings() end)
guiConnections.objectNameInputFocusLost = objectNameInput.FocusLost:Connect(function() settings.TeleportObjectName = objectNameInput.Text; saveSettings() end)


guiConnections.featuresTabClick = featuresButton.MouseButton1Click:Connect(function() currentActivePage = "Features"; showPage("Features") end) -- Update active page
guiConnections.playersTabClick = playersButton.MouseButton1Click:Connect(function() currentActivePage = "Players"; showPage("Players") end) -- Update active page
guiConnections.otherTabClick = otherButton.MouseButton1Click:Connect(function() currentActivePage = "Misc"; showPage("Misc") end) -- Update active page


-- Connections (Input/Character/Players/Rendering)
connections.MouseClick = userInputService.InputBegan:Connect(handleClick)

-- Connect InputBegan for High Jump activation (Spacebar)
connections.HighJumpInput = userInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
    if gameProcessedEvent or not highJumpEnabled or flyEnabled then return end -- Don't interfere if game is processing or fly is enabled

    if inputObject.KeyCode == Enum.KeyCode.Space then
        if humanoid.FloorMaterial ~= Enum.Material.Air then -- Only High Jump if on ground
             local originalJumpPower = humanoid.JumpPower -- Save current JumpPower
             humanoid.JumpPower = highJumpPower -- Set to High Jump power
             humanoid:ChangeState(Enum.HumanoidStateType.Jumping) -- Trigger jump
             -- Need to reset JumpPower after the jump state is entered
             task.delay(0.1, function() -- Small delay to allow jump state to register
                  if not flyEnabled and not infiniteJumpEnabled then -- Only reset if not flying or infinite jumping
                      humanoid.JumpPower = originalJumpPower -- Restore original JumpPower
                      -- Ensure JumpPower is set back to what the input shows if different
                      updateJumpPower(true) -- Update without status spam
                  end
             end)
         end
    end
end)


-- Update player list when a player is added or removed
playerListConnections.PlayerAdded = playersService.PlayerAdded:Connect(updatePlayerList)
playerListConnections.PlayerRemoving = playersService.PlayerRemoving:Connect(updatePlayerList)

-- Keep ESP update loop always connected for cleanup, function checks espEnabled
connections.ESPHeartbeat = runService.Heartbeat:Connect(updateESP)


-- Ensure character references are updated on respawn and states reapplied
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    -- Restore original properties first in case they were modified by game scripts
    originalWalkSpeed = humanoid.WalkSpeed
    originalJumpPower = humanoid.JumpPower
    originalHealth = humanoid.MaxHealth
    originalAutoRotate = humanoid.AutoRotate
     originalAmbient = lightingService.Ambient
     originalOutdoorAmbient = lightingService.OutdoorAmbient


    -- Apply saved settings by calling the toggle functions or updating properties
    if noclipEnabled then toggleNoclip() else toggleNoclipButton.Text = "Enable Noclip"; toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end
    if infiniteJumpEnabled then toggleInfiniteJump() else toggleInfiniteJumpButton.Text = "Enable Infinite Jump"; toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end
     if highJumpEnabled then toggleHighJump() else toggleHighJumpButton.Text = "Enable High Jump"; toggleHighJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end -- Apply High Jump state
     if bhopEnabled then toggleBhop() else toggleBhopButton.Text = "Enable Bhop"; toggleBhopButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end -- Apply Bhop state

    if godModeEnabled then toggleGodMode() else toggleGodModeButton.Text = "Enable God Mode (Client)"; toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70); humanoid.MaxHealth = originalHealth; humanoid.Health = originalHealth end
    if antiRagdollEnabled then toggleAntiRagdoll() else toggleAntiRagdollButton.Text = "Enable Anti-Ragdoll (Client)"; toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end
    if fullbrightEnabled then toggleFullbright() else toggleFullbrightButton.Text = "Enable Fullbright"; toggleFullbrightButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70); lightingService.Ambient = originalAmbient; lightingService.OutdoorAmbient = originalOutdoorAmbient end
    if espEnabled then toggleESPButton.Text = "Disable ESP"; toggleESPButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50) else toggleESPButton.Text = "Enable ESP"; toggleESPButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70) end


    -- Apply WalkSpeed, JumpPower, Fly Speed, Speed Multiplier from saved settings
    speedInput.Text = tostring(math.floor(settings.FlySpeed))
    speedSlider.Value = settings.FlySpeed
    flySpeed = settings.FlySpeed

    speedMultiplierInput.Text = tostring(settings.SpeedBurstMultiplier) -- Load speed multiplier
    speedBurstMultiplier = settings.SpeedBurstMultiplier

    walkSpeedInput.Text = tostring(math.floor(settings.WalkSpeed))
    walkSpeedSlider.Value = settings.WalkSpeed
    humanoid.WalkSpeed = settings.WalkSpeed

    jumpPowerInput.Text = tostring(math.floor(settings.JumpPower))
    jumpPowerSlider.Value = settings.JumpPower
    humanoid.JumpPower = settings.JumpPower

    -- Load saved coords and object name into input boxes
    coordXInput.Text = tostring(settings.TeleportCoords.X)
    coordYInput.Text = tostring(settings.TeleportCoords.Y)
    coordZInput.Text = tostring(settings.TeleportCoords.Z)
    objectNameInput.Text = settings.TeleportObjectName


    -- Reset Fly state
    disableFly() -- Ensure fly is off on new character, this will also trigger a status update
end)

-- Clean up connections and visuals when the script stops
local function cleanup()
    -- Disable all features first
    if flyEnabled then disableFly() end
    if infiniteJumpEnabled then toggleInfiniteJump() end
    if highJumpEnabled then toggleHighJump() end -- Disable High Jump
    if bhopEnabled then toggleBhop() end -- Disable Bhop
    if godModeEnabled then toggleGodMode() end
    if antiRagdollEnabled then toggleAntiRagdoll() end
    if fullbrightEnabled then toggleFullbright() end
    if espEnabled then toggleESP() end

     -- Reset WalkSpeed and JumpPower to defaults before cleaning up
     if character and humanoid and originalWalkSpeed and originalJumpPower then
          humanoid.WalkSpeed = originalWalkSpeed
          humanoid.JumpPower = originalJumpPower
     end
     -- Restore original AutoRotate
     if humanoid and originalAutoRotate ~= nil then
         humanoid.AutoRotate = originalAutoRotate
     end
     -- Restore original lighting
     if lightingService and originalAmbient and originalOutdoorAmbient then
         lightingService.Ambient = originalAmbient
         lightingService.OutdoorAmbient = originalOutdoorAmbient
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
     -- Cancel the status reset timer if active
     if statusResetTimer then
         task.cancel(statusResetTimer)
         statusResetTimer = nil
     end


     -- Clean up ESP visuals just in case
     for targetName, visuals in pairs(espVisuals) do
         if visuals.Box and visuals.Box.Parent then visuals.Box:Destroy() end
        if visuals.NameLabel and visuals.NameLabel.Parent then visuals.NameLabel:Destroy() end
        espVisuals[targetName] = nil
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
loadSettings() -- Load initial settings into the 'settings' table

-- Apply loaded settings to GUI elements and game properties
speedInput.Text = tostring(math.floor(settings.FlySpeed))
speedSlider.Value = settings.FlySpeed
flySpeed = settings.FlySpeed

speedMultiplierInput.Text = tostring(settings.SpeedBurstMultiplier) -- Load multiplier value
speedBurstMultiplier = settings.SpeedBurstMultiplier -- Set variable

walkSpeedInput.Text = tostring(math.floor(settings.WalkSpeed))
walkSpeedSlider.Value = settings.WalkSpeed
humanoid.WalkSpeed = settings.WalkSpeed

jumpPowerInput.Text = tostring(math.floor(settings.JumpPower))
jumpPowerSlider.Value = settings.JumpPower
humanoid.JumpPower = settings.JumpPower

coordXInput.Text = tostring(settings.TeleportCoords.X)
coordYInput.Text = tostring(settings.TeleportCoords.Y)
coordZInput.Text = tostring(settings.TeleportCoords.Z)
objectNameInput.Text = settings.TeleportObjectName


-- Enable features if they were saved as enabled (by calling toggle functions)
if settings.NoclipEnabled then toggleNoclip() end
if settings.InfiniteJumpEnabled then toggleInfiniteJump() end
if settings.HighJumpEnabled then toggleHighJump() end -- Enable High Jump if saved
if settings.BhopEnabled then toggleBhop() end -- Enable Bhop if saved
if settings.GodModeEnabled then toggleGodMode() end
if settings.AntiRagdollEnabled then toggleAntiRagdoll() end
if settings.FullbrightEnabled then toggleFullbright() end
if settings.ESPEnabled then toggleESP() end


-- Set mode button text based on loaded settings
toggleMovementModeButton.Text = "Mode: " .. movementMode

showPage(currentActivePage) -- Show the last active page (defaults to Features)
updateStatus("Loaded", Color3.fromRGB(255, 255, 255)) -- Initial status

-- Initial player list update
updatePlayerList()

-- Connect InputBegan globally to toggle GUI visibility (e.g., using RightShift)
-- WARNING: Choose a key that doesn't interfere with game controls. RightShift is often safe.
connections.ToggleGui = userInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
    if gameProcessedEvent then return end
    if inputObject.KeyCode == Enum.KeyCode.RightShift then -- Or your preferred key
        screenGui.Enabled = not screenGui.Enabled
    end
end)
