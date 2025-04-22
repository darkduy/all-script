local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")
local camera = game.Workspace.CurrentCamera
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local playersService = game:GetService("Players")
local lightingService = game:GetService("Lighting") -- Used for potential Fullbright (not implemented yet)
local tweenService = game:GetService("TweenService") -- For smooth transitions if needed later

local flyEnabled = false
local noclipEnabled = false
local espEnabled = false
local godModeEnabled = false
local antiRagdollEnabled = false
local infiniteJumpEnabled = false

local flySpeed = 50 -- Default speed
local speedBurstMultiplier = 2.5 -- How much faster the burst is
local movementMode = "Camera" -- "Camera" or "World"

local originalWalkSpeed = humanoid.WalkSpeed
local originalJumpPower = humanoid.JumpPower
local originalHealth = humanoid.MaxHealth -- Store original max health
local originalAutoRotate = humanoid.AutoRotate

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
    TeleportCoords = {X = 0, Y = 100, Z = 0} -- Default teleport coords
}

-- Load settings (simple in-memory load)
local function loadSettings()
    -- In a real exploit, you would implement file reading here
    -- Example: local loadedData = readfile("LuaGeminiFlySettings.json")
    -- if loadedData then settings = JSON:decode(loadedData) end

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
    -- Example: writefile("LuaGeminiFlySettings.json", JSON:encode(settings))
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
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Ensure GUI is above 3D world, but ESP layer will be sibling

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 580) -- Increased size for better layout
frame.Position = UDim2.new(0.1, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Darker background
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(60, 60, 60)
frame.Draggable = true
frame.Parent = screenGui

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0.04, 0) -- Smaller title
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Text = "Lua Gemini v4"
titleLabel.Parent = frame

local tabsFrame = Instance.new("Frame") -- Frame to hold tab buttons
tabsFrame.Size = UDim2.new(1, 0, 0.05, 0) -- Smaller tabs
tabsFrame.Position = UDim2.new(0, 0, 0.04, 0)
tabsFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
tabsFrame.Parent = frame

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

local otherButton = Instance.new("TextButton") -- New tab for Other/Misc features
otherButton.Size = UDim2.new(1/3, 0, 1, 0)
otherButton.Position = UDim2.new(2/3, 0, 0, 0)
otherButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
otherButton.TextColor3 = Color3.fromRGB(200, 200, 200)
otherButton.TextSize = 14
otherButton.Font = Enum.Font.SourceSansBold
otherButton.Text = "Misc"
otherButton.Parent = tabsFrame


-- Content Pages
local featuresPage = Instance.new("ScrollingFrame") -- Use ScrollingFrame for features too
featuresPage.Size = UDim2.new(1, 0, 0.86, 0) -- Adjusted size
featuresPage.Position = UDim2.new(0, 0, 0.09, 0)
featuresPage.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
featuresPage.CanvasSize = UDim2.new(0, 0, 0, 0)
featuresPage.ScrollBarThickness = 6
featuresPage.BorderSizePixel = 0
featuresPage.Parent = frame
featuresPage.Visible = true

local playersPage = Instance.new("ScrollingFrame")
playersPage.Size = UDim2.new(1, 0, 0.86, 0) -- Adjusted size
playersPage.Position = UDim2.new(0, 0, 0.09, 0)
playersPage.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
playersPage.CanvasSize = UDim2.new(0, 0, 0, 0)
playersPage.ScrollBarThickness = 6
playersPage.BorderSizePixel = 0
playersPage.Parent = frame
playersPage.Visible = false

local otherPage = Instance.new("ScrollingFrame")
otherPage.Size = UDim2.new(1, 0, 0.86, 0) -- Adjusted size
otherPage.Position = UDim2.new(0, 0, 0.09, 0)
otherPage.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
otherPage.CanvasSize = UDim2.new(0, 0, 0, 0)
otherPage.ScrollBarThickness = 6
otherPage.BorderSizePixel = 0
otherPage.Parent = frame
otherPage.Visible = false


local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0.05, 0)
statusLabel.Position = UDim2.new(0, 0, 0.95, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.SourceSans
statusLabel.Text = "Status: Loading..."
statusLabel.Parent = frame

local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0.04, 0) -- Smaller info label
infoLabel.Position = UDim2.new(0, 0, 0.91, 0)
infoLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextSize = 10
infoLabel.TextWrapped = true
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Text = "W/S/A/D, Space/Ctrl. Hold Shift for Speed Burst. Click terrain to Teleport."
infoLabel.Parent = frame
infoLabel.Visible = true -- Keep visible

-- UI Layouts for pages
local featuresLayout = Instance.new("UIListLayout")
featuresLayout.FillDirection = Enum.FillDirection.Vertical
featuresLayout.SortOrder = Enum.SortOrder.LayoutOrder
featuresLayout.Padding = UDim.new(0, 5) -- Add spacing between items
featuresLayout.Parent = featuresPage

local playersLayout = Instance.new("UIListLayout")
playersLayout.FillDirection = Enum.FillDirection.Vertical
playersLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersLayout.Padding = UDim.new(0, 5) -- Add spacing between items
playersLayout.Parent = playersPage

local otherLayout = Instance.new("UIListLayout")
otherLayout.FillDirection = Enum.FillDirection.Vertical
otherLayout.SortOrder = Enum.SortOrder.LayoutOrder
otherLayout.Padding = UDim.new(0, 5) -- Add spacing between items
otherLayout.Parent = otherPage


-- Helper to create a control container frame
local function createControlContainer(parentFrame, heightScale, layoutOrder)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -10, heightScale, 0) -- Full width minus padding
    container.Position = UDim2.new(0, 5, 0, 0) -- Center with padding
    container.BackgroundColor3 = Color3.fromRGB(55, 55, 55) -- Slight contrast
    container.BorderSizePixel = 1
    container.BorderColor3 = Color3.fromRGB(65, 65, 65)
    container.LayoutOrder = layoutOrder
    container.Parent = parentFrame
    return container
end

-- Section Header Helper
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

local toggleFlyContainer = createControlContainer(featuresPage, 0, order); toggleFlyContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local toggleFlyButton = Instance.new("TextButton")
toggleFlyButton.Size = UDim2.new(1, 0, 1, 0)
toggleFlyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleFlyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleFlyButton.TextSize = 14
toggleFlyButton.Font = Enum.Font.SourceSansBold
toggleFlyButton.Text = "Enable Fly"
toggleFlyButton.Parent = toggleFlyContainer

local speedContainer = createControlContainer(featuresPage, 0, order); speedContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local speedLayout = Instance.new("UIListLayout")
speedLayout.FillDirection = Enum.FillDirection.Horizontal
speedLayout.VerticalAlignment = Enum.VerticalAlignment.Center
speedLayout.Padding = UDim.new(0, 5)
speedLayout.Parent = speedContainer

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
speedSlider.Maximum = 300 -- Maximum speed (increased range)
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

local toggleMovementModeContainer = createControlContainer(featuresPage, 0, order); toggleMovementModeContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
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

local walkSpeedContainer = createControlContainer(featuresPage, 0, order); walkSpeedContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local walkSpeedLayout = Instance.new("UIListLayout")
walkSpeedLayout.FillDirection = Enum.FillDirection.Horizontal
walkSpeedLayout.VerticalAlignment = Enum.VerticalAlignment.Center
walkSpeedLayout.Padding = UDim.new(0, 5)
walkSpeedLayout.Parent = walkSpeedContainer

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

local jumpPowerContainer = createControlContainer(featuresPage, 0, order); jumpPowerContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local jumpPowerLayout = Instance.new("UIListLayout")
jumpPowerLayout.FillDirection = Enum.FillDirection.Horizontal
jumpPowerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
jumpPowerLayout.Padding = UDim.new(0, 5)
jumpPowerLayout.Parent = jumpPowerContainer

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
jumpPowerSlider.Maximum = 300 -- Max typical jump power (increased range)
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

local toggleInfiniteJumpContainer = createControlContainer(featuresPage, 0, order); toggleInfiniteJumpContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local toggleInfiniteJumpButton = Instance.new("TextButton")
toggleInfiniteJumpButton.Size = UDim2.new(1, 0, 1, 0)
toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleInfiniteJumpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleInfiniteJumpButton.TextSize = 14
toggleInfiniteJumpButton.Font = Enum.Font.SourceSansBold
toggleInfiniteJumpButton.Text = "Enable Infinite Jump"
toggleInfiniteJumpButton.Parent = toggleInfiniteJumpContainer


-- Populate Combat / Survival Section
addSectionHeader(featuresPage, "Combat / Survival", order); order = order + 1

local toggleNoclipContainer = createControlContainer(featuresPage, 0, order); toggleNoclipContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local toggleNoclipButton = Instance.new("TextButton")
toggleNoclipButton.Size = UDim2.new(1, 0, 1, 0)
toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleNoclipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleNoclipButton.TextSize = 14
toggleNoclipButton.Font = Enum.Font.SourceSansBold
toggleNoclipButton.Text = "Enable Noclip"
toggleNoclipButton.Parent = toggleNoclipContainer

local toggleGodModeContainer = createControlContainer(featuresPage, 0, order); toggleGodModeContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local toggleGodModeButton = Instance.new("TextButton")
toggleGodModeButton.Size = UDim2.new(1, 0, 1, 0)
toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleGodModeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleGodModeButton.TextSize = 14
toggleGodModeButton.Font = Enum.Font.SourceSansBold
toggleGodModeButton.Text = "Enable God Mode (Client)"
toggleGodModeButton.Parent = toggleGodModeContainer

local toggleAntiRagdollContainer = createControlContainer(featuresPage, 0, order); toggleAntiRagdollContainer.Size = UDim2.new(1, -10, 0, 30); order = order + 1
local toggleAntiRagdollButton = Instance.new("TextButton")
toggleAntiRagdollButton.Size = UDim2.new(1, 0, 1, 0)
toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleAntiRagdollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleAntiRagdollButton.TextSize = 14
toggleAntiRagdollButton.Font = Enum.Font.SourceSansBold
toggleAntiRagdollButton.Text = "Enable Anti-Ragdoll (Client)"
toggleAntiRagdollButton.Parent = toggleAntiRagdollContainer

-- Populate Teleport to Coords Section
addSectionHeader(featuresPage, "Teleport to Coordinates", order); order = order + 1

local teleportCoordsContainer = createControlContainer(featuresPage, 0, order); teleportCoordsContainer.Size = UDim2.new(1, -10, 0, 60); order = order + 1 -- Larger container
local teleportCoordsLayout = Instance.new("UIListLayout")
teleportCoordsLayout.FillDirection = Enum.FillDirection.Vertical
teleportCoordsLayout.SortOrder = Enum.SortOrder.LayoutOrder
teleportCoordsLayout.Padding = UDim.new(0, 3)
teleportCoordsLayout.Parent = teleportCoordsContainer

local coordsInputFrame = Instance.new("Frame") -- Container for XYZ inputs
coordsInputFrame.Size = UDim2.new(1, 0, 0.5, 0)
coordsInputFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
coordsInputFrame.BorderSizePixel = 0
coordsInputFrame.Parent = teleportCoordsContainer

local coordsInputLayout = Instance.new("UIListLayout")
coordsInputLayout.FillDirection = Enum.FillDirection.Horizontal
coordsInputLayout.VerticalAlignment = Enum.VerticalAlignment.Center
coordsInputLayout.Padding = UDim.new(0, 5)
coordsInputLayout.Parent = coordsInputFrame

local coordXInput = Instance.new("TextBox")
coordXInput.Size = UDim2.new(1/3, -5, 1, 0) -- Adjusted size for 3 inputs
coordXInput.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
coordXInput.TextColor3 = Color3.fromRGB(255, 255, 255)
coordXInput.TextSize = 12
coordXInput.Font = Enum.Font.SourceSans
coordXInput.PlaceholderText = "X"
coordXInput.Text = tostring(settings.TeleportCoords.X) -- Load default/saved coord
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
teleportCoordsButton.Size = UDim2.new(1, 0, 0.45, 0) -- Slightly smaller than coords inputs frame
teleportCoordsButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
teleportCoordsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
teleportCoordsButton.TextSize = 14
teleportCoordsButton.Font = Enum.Font.SourceSansBold
teleportCoordsButton.Text = "Teleport to Coordinates"
teleportCoordsButton.Parent = teleportCoordsContainer


-- Update Features Page Canvas Size
featuresPage.CanvasSize = UDim2.new(0, 0, 0, featuresLayout.AbsoluteContentSize.Y + 10)


-- Populate Other Page
local otherOrder = 1
addSectionHeader(otherPage, "Visuals", otherOrder); otherOrder = otherOrder + 1

local toggleESPContainer = createControlContainer(otherPage, 0, otherOrder); toggleESPContainer.Size = UDim2.new(1, -10, 0, 30); otherOrder = otherOrder + 1
local toggleESPButton = Instance.new("TextButton")
toggleESPButton.Size = UDim2.new(1, 0, 1, 0)
toggleESPButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleESPButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleESPButton.TextSize = 14
toggleESPButton.Font = Enum.Font.SourceSansBold
toggleESPButton.Text = "Enable ESP"
toggleESPButton.Parent = toggleESPContainer


-- ESP Drawing Layer (Using Roblox UI as a placeholder)
local espGui = Instance.new("ScreenGui")
espGui.Name = "ESPGui"
espGui.Parent = player:WaitForChild("PlayerGui")
espGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- Ensure ESP is above other UI
espGui.DisplayOrder = 100 -- Higher DisplayOrder to draw on top


-- ESP Update Logic (Uses Stepped for rendering updates)
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


-- Update Other Page Canvas Size
otherPage.CanvasSize = UDim2.new(0, 0, 0, otherLayout.AbsoluteContentSize.Y + 10)


-- Populate Players Page
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
    local currentY = 0
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

-- Function to update the status label cleanly
local function updateStatus(message, color, duration)
     statusLabel.Text = "Status: " .. message
     statusLabel.TextColor3 = color
     if duration then
         delay(duration, function()
             -- Restore default status based on current toggles after delay
             local currentStatusText = "Status: Disabled"
             local currentStatusColor = Color3.fromRGB(255, 255, 255)
             local activeFeatures = {}
             if flyEnabled then table.insert(activeFeatures, "Fly (" .. movementMode .. ")") end
             if noclipEnabled then table.insert(activeFeatures, "Noclip") end
             if infiniteJumpEnabled then table.insert(activeFeatures, "Infinite Jump") end
             if godModeEnabled then table.insert(activeFeatures, "God Mode") end
             if antiRagdollEnabled then table.insert(activeFeatures, "Anti-Ragdoll") end
             if espEnabled then table.insert(activeFeatures, "ESP") end


             if #activeFeatures > 0 then
                 currentStatusText = "Status: " .. table.concat(activeFeatures, ", ")
                 currentStatusColor = Color3.fromRGB(50, 255, 50) -- Green for active features
             end

             statusLabel.Text = currentStatusText
             statusLabel.TextColor3 = currentStatusColor
         end)
     end
end


-- Enable/Disable Fly - Updated to use updateStatus
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

-- Toggle Noclip - Completed and updated to use updateStatus
local function toggleNoclip()
    noclipEnabled = not noclipEnabled
    for i, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            -- Toggle CanCollide for character parts
            part.CanCollide = not noclipEnabled
        end
    end

    if noclipEnabled then
        toggleNoclipButton.Text = "Disable Noclip"
        toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        updateStatus("Noclip Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleNoclipButton.Text = "Enable Noclip"
        toggleNoclipButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        updateStatus("Noclip Disabled", Color3.fromRGB(255, 255, 255)) -- Status will be updated by updateStatus delayed call if other features are active
    end
    saveSettings()
end

-- Toggle Movement Mode - Updated to handle status
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

-- Update Fly Speed from Input/Slider - Updated to handle status and saving
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
        -- Reset text/slider if invalid input
        speedInput.Text = tostring(math.floor(flySpeed))
        speedSlider.Value = flySpeed
        if not noStatusUpdate then
             updateStatus("Invalid Speed", Color3.fromRGB(255, 50, 50), 2)
        end
    end
end

-- Update WalkSpeed from Input/Slider
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
         walkSpeedInput.Text = tostring(math.floor(humanoid.WalkSpeed)) -- Reset to current value
         walkSpeedSlider.Value = humanoid.WalkSpeed
         if not noStatusUpdate then
              updateStatus("Invalid WalkSpeed", Color3.fromRGB(255, 50, 50), 2)
         end
     end
end

-- Update JumpPower from Input/Slider
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
         jumpPowerInput.Text = tostring(math.floor(humanoid.JumpPower)) -- Reset to current value
         jumpPowerSlider.Value = humanoid.JumpPower
         if not noStatusUpdate then
              updateStatus("Invalid JumpPower", Color3.fromRGB(255, 50, 50), 2)
         end
     end
end


-- Toggle Infinite Jump - Updated to handle status
local function toggleInfiniteJump()
    infiniteJumpEnabled = not infiniteJumpEnabled

    if infiniteJumpEnabled then
        toggleInfiniteJumpButton.Text = "Enable Infinite Jump"
        toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Connect the Jumping event
        connections.InfiniteJump = humanoid.Jumping:Connect(function()
            if infiniteJumpEnabled then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        updateStatus("Infinite Jump Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleInfiniteJumpButton.Text = "Disable Infinite Jump"
        toggleInfiniteJumpButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        -- Disconnect the Jumping event
        if connections.InfiniteJump then
            connections.InfiniteJump:Disconnect()
            connections.InfiniteJump = nil
        end
        updateStatus("Infinite Jump Disabled", Color3.fromRGB(255, 255, 255)) -- Status will be updated by updateStatus delayed call
    end
    saveSettings()
end

-- Toggle God Mode (Client-Side)
local function toggleGodMode()
    godModeEnabled = not godModeEnabled

    if godModeEnabled then
        toggleGodModeButton.Text = "Disable God Mode (Client)"
        toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Attempt to make humanoid invincible client-side
        -- WARNING: This is often ineffective in filtered games where the server handles damage.
        humanoid.MaxHealth = math.huge
        humanoid.Health = humanoid.MaxHealth
         updateStatus("God Mode Enabled (Client)", Color3.fromRGB(50, 255, 50))
         -- Client-side health changes might be reverted by server, loop needed if attempting to keep health high
         connections.GodMode = runService.Heartbeat:Connect(function()
             if godModeEnabled and humanoid.Health < humanoid.MaxHealth then
                 humanoid.Health = humanoid.MaxHealth
             end
         end)
    else
        toggleGodModeButton.Text = "Enable God Mode (Client)"
        toggleGodModeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        -- Reset health properties
        humanoid.MaxHealth = originalHealth
        humanoid.Health = originalHealth -- Reset health to original
         updateStatus("God Mode Disabled (Client)", Color3.fromRGB(255, 255, 255))
         if connections.GodMode then
             connections.GodMode:Disconnect()
             connections.GodMode = nil
         end
    end
    saveSettings()
end

-- Toggle Anti-Ragdoll (Client-Side)
local function toggleAntiRagdoll()
    antiRagdollEnabled = not antiRagdollEnabled

    if antiRagdollEnabled then
        toggleAntiRagdollButton.Text = "Disable Anti-Ragdoll (Client)"
        toggleAntiRagdollButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Attempt to prevent or quickly recover from ragdoll state
        -- WARNING: Effectiveness varies by game.
        connections.AntiRagdoll = humanoid.StateChanged:Connect(function(oldState, newState)
            if antiRagdollEnabled and (newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Dead) then
                delay(0.1, function() -- Add a small delay
                     if antiRagdollEnabled then -- Check again in case it was disabled during delay
                         humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                         -- If GettingUp isn't enough, sometimes changing to Running or Jumping works
                         -- humanoid:ChangeState(Enum.HumanoidStateType.Running)
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


-- Toggle ESP
local function toggleESP()
    espEnabled = not espEnabled

    if espEnabled then
        toggleESPButton.Text = "Disable ESP"
        toggleESPButton.BackgroundColor3 = Color3.fromRGB(50, 90, 50)
        -- Connect the Heartbeat event to update ESP visuals constantly
        connections.ESPUpdate = runService.Heartbeat:Connect(updateESP)
         updateStatus("ESP Enabled", Color3.fromRGB(50, 255, 50))
    else
        toggleESPButton.Text = "Enable ESP"
        toggleESPButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        -- Disconnect the update loop
        if connections.ESPUpdate then
            connections.ESPUpdate:Disconnect()
            connections.ESPUpdate = nil
        end
        updateESP() -- Call one last time to clean up visuals
         updateStatus("ESP Disabled", Color3.fromRGB(255, 255, 255)) -- Status will be updated by updateStatus delayed call
    end
    saveSettings()
end


-- Handle Teleport to Coords
local function teleportToCoords()
    local x = tonumber(coordXInput.Text)
    local y = tonumber(coordYInput.Text)
    local z = tonumber(coordZInput.Text)

    if x and y and z then
        -- Simple teleport, consider adding sanity checks or raycasting for safety
        rootPart.CFrame = CFrame.new(x, y + rootPart.Size.Y / 2 + 0.1, z) -- Add slight offset above target Y
        updateStatus("Teleported to " .. math.floor(x) .. ", " .. math.floor(y) .. ", " .. math.floor(z), Color3.fromRGB(50, 255, 255), 2)
        -- Save coords when successfully teleported
        settings.TeleportCoords = {X = x, Y = y, Z = z}
        saveSettings()
    else
        updateStatus("Invalid coordinates", Color3.fromRGB(255, 50, 50), 2)
    end
end


-- Handle Click Teleport (Clicking on terrain when fly is enabled)
local function handleClick(inputObject, gameProcessedEvent)
    if gameProcessedEvent or not flyEnabled or inputObject.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local mouse = player:GetMouse()
    local target = mouse.Target
    local hitPos = mouse.Hit.p

    -- Check if the target is part of the terrain or a baseplate/large static part
    if target and (target.Name == "Terrain" or (target:IsA("BasePart") and target.Anchored)) then
        -- Teleport slightly above the clicked position
        local teleportPosition = hitPos + Vector3.new(0, rootPart.Size.Y / 2 + 0.5, 0) -- Added a bit more offset
        rootPart.CFrame = CFrame.new(teleportPosition)
        updateStatus("Teleported to ground at " .. math.floor(hitPos.X) .. ", " .. math.floor(hitPos.Y) .. ", " .. math.floor(hitPos.Z), Color3.fromRGB(50, 255, 255), 2)
    end
end

-- Tab Functionality
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
guiConnections.toggleGodModeClick = toggleGodModeButton.MouseButton1Click:Connect(toggleGodMode)
guiConnections.toggleAntiRagdollClick = toggleAntiRagdollButton.MouseButton1Click:Connect(toggleAntiRagdoll)
guiConnections.toggleESPClick = toggleESPButton.MouseButton1Click:Connect(toggleESP)
guiConnections.teleportCoordsButtonClick = teleportCoordsButton.MouseButton1Click:Connect(teleportToCoords)


-- Slider and Input Sync for Fly Speed
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


-- Slider and Input Sync for WalkSpeed
guiConnections.walkSpeedSliderChanged = walkSpeedSlider.Changed:Connect(function()
    local newSpeed = walkSpeedSlider.Value
    humanoid.WalkSpeed = newSpeed
    walkSpeedInput.Text = tostring(math.floor(newSpeed))
    saveSettings()
end)
guiConnections.walkSpeedInputFocusLost = walkSpeedInput.FocusLost:Connect(updateWalkSpeed)
guiConnections.walkSpeedInputTextReturned = walkSpeedInput.TextReturned:Connect(updateWalkSpeed)


-- Slider and Input Sync for JumpPower
guiConnections.jumpPowerSliderChanged = jumpPowerSlider.Changed:Connect(function()
    local newPower = jumpPowerSlider.Value
    humanoid.JumpPower = newPower
    jumpPowerInput.Text = tostring(math.floor(newPower))
    saveSettings()
end)
guiConnections.jumpPowerInputFocusLost = jumpPowerInput.FocusLost:Connect(updateJumpPower)
guiConnections.jumpPowerInputTextReturned = jumpPowerInput.TextReturned:Connect(updateJumpPower)

-- Save teleport coords when input fields lose focus
guiConnections.coordXInputFocusLost = coordXInput.FocusLost:Connect(function() settings.TeleportCoords.X = tonumber(coordXInput.Text) or settings.TeleportCoords.X; saveSettings() end)
guiConnections.coordYInputFocusLost = coordYInput.FocusLost:Connect(function() settings.TeleportCoords.Y = tonumber(coordYInput.Text) or settings.TeleportCoords.Y; saveSettings() end)
guiConnections.coordZInputFocusLost = coordZInput.FocusLost:Connect(function() settings.TeleportCoords.Z = tonumber(coordZInput.Text) or settings.TeleportCoords.Z; saveSettings() end)


guiConnections.featuresTabClick = featuresButton.MouseButton1Click:Connect(function() showPage("Features") end)
guiConnections.playersTabClick = playersButton.MouseButton1Click:Connect(function() showPage("Players") end)
guiConnections.otherTabClick = otherButton.MouseButton1Click:Connect(function() showPage("Misc") end)


-- Connections (Input/Character/Players)
connections.MouseClick = userInputService.InputBegan:Connect(handleClick)

-- Update player list when a player is added or removed
playerListConnections.PlayerAdded = playersService.PlayerAdded:Connect(updatePlayerList)
playerListConnections.PlayerRemoving = playersService.PlayerRemoving:Connect(updatePlayerList)

-- Periodically update ESP even if ESP is enabled/disabled quickly
connections.ESPHeartbeat = runService.Heartbeat:Connect(updateESP)


-- Ensure character references are updated on respawn and states reapplied
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    -- Restore original speeds and auto rotate first in case they were modified by game scripts
    originalWalkSpeed = humanoid.WalkSpeed
    originalJumpPower = humanoid.JumpPower
    originalHealth = humanoid.MaxHealth
    originalAutoRotate = humanoid.AutoRotate

    -- Apply saved settings
    if noclipEnabled then
        delay(0.1, function()
            if character then -- Check if character still exists
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
         if connections.InfiniteJump then connections.InfiniteJump:Disconnect() end -- Disconnect old connection if any
         connections.InfiniteJump = humanoid.Jumping:Connect(function()
             if infiniteJumpEnabled then
                 humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
             end
         end)
    end

     if godModeEnabled then
         -- Reconnect God Mode heartbeat if it was enabled
         if connections.GodMode then connections.GodMode:Disconnect() end -- Disconnect old connection
          humanoid.MaxHealth = math.huge
         humanoid.Health = humanoid.MaxHealth
          connections.GodMode = runService.Heartbeat:Connect(function()
             if godModeEnabled and humanoid.Health < humanoid.MaxHealth then
                 humanoid.Health = humanoid.MaxHealth
             end
         end)
     end

    if antiRagdollEnabled then
         -- Reconnect Anti-Ragdoll if it was enabled
         if connections.AntiRagdoll then connections.AntiRagdoll:Disconnect() end -- Disconnect old connection
         connections.AntiRagdoll = humanoid.StateChanged:Connect(function(oldState, newState)
             if antiRagdollEnabled and (newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Dead) then
                 delay(0.1, function() -- Add a small delay
                      if antiRagdollEnabled and character and character.Parent then -- Check existence
                          humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                      end
                 end)
             end
         end)
    end


    -- Apply WalkSpeed and JumpPower from saved settings (via input boxes)
    -- We need to trigger the update logic here to sync slider/input and set humanoid property
    walkSpeedInput.Text = tostring(math.floor(settings.WalkSpeed))
    jumpPowerInput.Text = tostring(math.floor(settings.JumpPower))
    updateWalkSpeed(true) -- Update without status spam
    updateJumpPower(true)

    -- Apply Fly Speed from saved settings
    speedInput.Text = tostring(math.floor(settings.FlySpeed))
    updateFlySpeed(true) -- Update without status spam

    disableFly() -- Ensure fly is off on new character, this will also trigger a status update
end)

-- Clean up connections and visuals when the script stops
local function cleanup()
    disableFly() -- Ensure fly is off
    if infiniteJumpEnabled then toggleInfiniteJump() end -- Disable infinite jump
    if godModeEnabled then toggleGodMode() end -- Disable god mode
    if antiRagdollEnabled then toggleAntiRagdoll() end -- Disable anti-ragdoll
    if espEnabled then toggleESP() end -- Disable ESP and clean visuals

     -- Reset WalkSpeed and JumpPower to defaults before cleaning up
     if character and humanoid and originalWalkSpeed and originalJumpPower then
          humanoid.WalkSpeed = originalWalkSpeed
          humanoid.JumpPower = originalJumpPower
     end
     -- Restore original AutoRotate
     if humanoid and originalAutoRotate ~= nil then
         humanoid.AutoRotate = originalAutoRotate
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
flySpeed = settings.FlySpeed -- Ensure flySpeed variable is set

walkSpeedInput.Text = tostring(math.floor(settings.WalkSpeed))
walkSpeedSlider.Value = settings.WalkSpeed
humanoid.WalkSpeed = settings.WalkSpeed -- Apply immediately

jumpPowerInput.Text = tostring(math.floor(settings.JumpPower))
jumpPowerSlider.Value = settings.JumpPower
humanoid.JumpPower = settings.JumpPower -- Apply immediately

coordXInput.Text = tostring(settings.TeleportCoords.X) -- Load saved coords into input boxes
coordYInput.Text = tostring(settings.TeleportCoords.Y)
coordZInput.Text = tostring(settings.TeleportCoords.Z)


-- Enable features if they were saved as enabled
if settings.NoclipEnabled then toggleNoclip() end
if settings.InfiniteJumpEnabled then toggleInfiniteJump() end
if settings.GodModeEnabled then toggleGodMode() end
if settings.AntiRagdollEnabled then toggleAntiRagdoll() end
if settings.ESPEnabled then toggleESP() end -- Toggle ESP last to ensure other setups are done


-- Set mode button text based on loaded settings
toggleMovementModeButton.Text = "Mode: " .. movementMode

showPage("Features") -- Show features page by default
updateStatus("Loaded", Color3.fromRGB(255, 255, 255)) -- Initial status

-- Initial player list update
updatePlayerList()
