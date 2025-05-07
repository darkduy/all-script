-- Script Fly GUI Tối Ưu (LocalScript trong StarterPlayerScripts hoặc StarterGui)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Variables
local flyEnabled = false
local currentFlySpeed = 30 -- Tốc độ mặc định
local minFlySpeed = 1      -- Tốc độ tối thiểu
local maxFlySpeed = 100    -- Tốc độ tối đa
local isGuiVisible = true

local linearVelocity
local attachment0

-- Function tạo GUI
local function createFlyGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FlyScriptGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 230, 0, 160)
    mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BackgroundTransparency = 0.2
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(70, 70, 70)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Visible = isGuiVisible
    mainFrame.Parent = screenGui

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleLabel.BackgroundTransparency = 0.1
    titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    titleLabel.Text = "Fly Control v2.1" -- Cập nhật phiên bản nếu muốn
    titleLabel.Font = Enum.Font.SourceSansSemibold
    titleLabel.TextSize = 16
    titleLabel.Parent = mainFrame

    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 28, 0, 22)
    closeButton.Position = UDim2.new(1, -32, 0.5, -11)
    closeButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 14
    closeButton.Parent = titleLabel

    local flyToggleButton = Instance.new("TextButton")
    flyToggleButton.Name = "FlyToggleButton"
    flyToggleButton.Size = UDim2.new(0.85, 0, 0, 30)
    flyToggleButton.Position = UDim2.new(0.5, -flyToggleButton.AbsoluteSize.X / 2, 0, 45)
    flyToggleButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
    flyToggleButton.TextColor3 = Color3.fromRGB(225, 225, 225)
    flyToggleButton.Text = "Fly: TẮT"
    flyToggleButton.Font = Enum.Font.SourceSans
    flyToggleButton.TextSize = 16
    flyToggleButton.Parent = mainFrame

    local speedLabel = Instance.new("TextLabel")
    speedLabel.Name = "SpeedLabel"
    speedLabel.Size = UDim2.new(0.45, 0, 0, 25)
    speedLabel.Position = UDim2.new(0.075, 0, 0, 85)
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
    speedLabel.Text = "Tốc độ (" .. minFlySpeed .. "-" .. maxFlySpeed .. "):" -- Hiển thị rõ min-max
    speedLabel.Font = Enum.Font.SourceSans
    speedLabel.TextSize = 14 -- Cho nhỏ lại để vừa dòng
    speedLabel.TextXAlignment = Enum.TextXAlignment.Left
    speedLabel.Parent = mainFrame

    local speedInput = Instance.new("TextBox")
    speedInput.Name = "SpeedInput"
    speedInput.Size = UDim2.new(0.35, 0, 0, 25)
    speedInput.Position = UDim2.new(0.55, 0, 0, 85)
    speedInput.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    speedInput.TextColor3 = Color3.fromRGB(225, 225, 225)
    speedInput.Text = tostring(currentFlySpeed)
    speedInput.Font = Enum.Font.SourceSans
    speedInput.TextSize = 15
    speedInput.NumbersOnly = true
    speedInput.ClearTextOnFocus = false
    speedInput.Parent = mainFrame
    
    local paddingBottom = Instance.new("Frame")
    paddingBottom.Name = "PaddingBottom"
    paddingBottom.Size = UDim2.new(1,0,0,10)
    paddingBottom.Position = UDim2.new(0,0,1,-10)
    paddingBottom.BackgroundTransparency = 1
    paddingBottom.Parent = mainFrame

    local openGuiButton = Instance.new("TextButton")
    openGuiButton.Name = "OpenFlyGuiButton"
    openGuiButton.Size = UDim2.new(0, 100, 0, 30)
    openGuiButton.Position = UDim2.new(0, 10, 0, 10)
    openGuiButton.Text = "Mở Fly GUI"
    openGuiButton.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    openGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    openGuiButton.Font = Enum.Font.SourceSansBold
    openGuiButton.Visible = false
    openGuiButton.Parent = screenGui

    return screenGui, mainFrame, flyToggleButton, speedInput, closeButton, openGuiButton
end

local flyGuiScreen, flyMainFrame, flyToggleButton, speedInputBox, guiCloseButton, openFlyGuiButton = createFlyGui()

local function cleanupFlyState(humanoid, rootPart)
    if linearVelocity then
        linearVelocity:Destroy()
        linearVelocity = nil
    end
    if attachment0 then
        attachment0:Destroy()
        attachment0 = nil
    end
    if humanoid and humanoid.PlatformStand then
        humanoid.PlatformStand = false
    end
    if humanoid and not humanoid.AutoRotate then
        humanoid.AutoRotate = true
    end
end

local function toggleFly()
    flyEnabled = not flyEnabled
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local rootPart = char and char:FindFirstChild("HumanoidRootPart")

    if not humanoid or not rootPart then
        flyEnabled = false
        flyToggleButton.Text = "Fly: TẮT"
        flyToggleButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        return
    end

    if flyEnabled then
        flyToggleButton.Text = "Fly: BẬT"
        flyToggleButton.BackgroundColor3 = Color3.fromRGB(50, 180, 50)

        cleanupFlyState(humanoid, rootPart)

        attachment0 = Instance.new("Attachment")
        attachment0.Name = "FlyAttachment"
        attachment0.Parent = rootPart

        linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Name = "FlyLV"
        linearVelocity.Attachment0 = attachment0
        linearVelocity.MaxAxesForce = Vector3.new(math.huge, math.huge, math.huge)
        linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        linearVelocity.VectorVelocity = Vector3.new(0, 0, 0)
        linearVelocity.Parent = rootPart

        humanoid.PlatformStand = true
        humanoid.AutoRotate = false
    else
        flyToggleButton.Text = "Fly: TẮT"
        flyToggleButton.BackgroundColor3 = Color3.fromRGB(65, 65, 65)
        cleanupFlyState(humanoid, rootPart)
    end
end

local function toggleGuiVisibility()
    isGuiVisible = not isGuiVisible
    flyMainFrame.Visible = isGuiVisible
    openFlyGuiButton.Visible = not isGuiVisible
end

guiCloseButton.MouseButton1Click:Connect(toggleGuiVisibility)
openFlyGuiButton.MouseButton1Click:Connect(toggleGuiVisibility)
flyToggleButton.MouseButton1Click:Connect(toggleFly)

-- Function cập nhật tốc độ fly
local function updateFlySpeed(text)
    local num = tonumber(text)
    if num then
        -- Giới hạn tốc độ trong khoảng minFlySpeed và maxFlySpeed
        currentFlySpeed = math.clamp(num, minFlySpeed, maxFlySpeed)
        -- Cập nhật lại TextBox nếu giá trị nhập vào bị thay đổi (ví dụ: ngoài khoảng)
        if speedInputBox.Text ~= tostring(currentFlySpeed) then
            speedInputBox.Text = tostring(currentFlySpeed)
        end
    else
        -- Nếu người dùng nhập không phải số, đặt lại Text của TextBox về giá trị hợp lệ gần nhất
        speedInputBox.Text = tostring(currentFlySpeed)
    end
end

-- Cập nhật tốc độ khi TextBox mất focus (click ra ngoài hoặc nhấn Enter)
speedInputBox.FocusLost:Connect(function(enterPressed)
    updateFlySpeed(speedInputBox.Text)
end)

-- (Tùy chọn) Cập nhật tốc độ ngay khi nhấn Enter (ngoài việc FocusLost cũng xử lý)
speedInputBox.ReturnPressed:Connect(function()
    updateFlySpeed(speedInputBox.Text)
    speedInputBox:ReleaseFocus() -- Bỏ focus khỏi TextBox sau khi nhấn Enter
end)


local moveInputVector = Vector3.new(0,0,0)
local keyStates = {
    [Enum.KeyCode.W] = Vector3.new(0,0,-1),
    [Enum.KeyCode.S] = Vector3.new(0,0,1),
    [Enum.KeyCode.A] = Vector3.new(-1,0,0),
    [Enum.KeyCode.D] = Vector3.new(1,0,0),
    [Enum.KeyCode.Space] = Vector3.new(0,1,0),
    [Enum.KeyCode.LeftControl] = Vector3.new(0,-1,0),
    [Enum.KeyCode.C] = Vector3.new(0,-1,0),
}

local function processInput(input, gameProcessed, isBegan)
    if gameProcessed and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    if not flyEnabled then return end

    local vectorChange = keyStates[input.KeyCode]
    if vectorChange then
        if isBegan then
            moveInputVector = moveInputVector + vectorChange
        else
            moveInputVector = moveInputVector - vectorChange
        end
    end
end

UserInputService.InputBegan:Connect(function(input, gp) processInput(input, gp, true) end)
UserInputService.InputEnded:Connect(function(input, gp) processInput(input, gp, false) end)

RunService.Heartbeat:Connect(function(deltaTime)
    if not flyEnabled or not linearVelocity or not attachment0 or not attachment0.Parent then
        if linearVelocity then linearVelocity.VectorVelocity = Vector3.new(0,0,0) end
        return
    end

    local char = player.Character
    if not char then return end

    local camera = workspace.CurrentCamera
    if not camera then return end

    local finalMoveDirection = Vector3.new()

    if moveInputVector.Magnitude > 0.01 then
        local relativeMove = Vector3.new(moveInputVector.X, 0, moveInputVector.Z)
        local cameraLook = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
        local cameraRight = camera.CFrame.RightVector * Vector3.new(1, 0, 1)

        if relativeMove.Magnitude > 0.01 then
            finalMoveDirection = (cameraLook.Unit * relativeMove.Z) + (cameraRight.Unit * relativeMove.X)
        end
        
        finalMoveDirection = finalMoveDirection + Vector3.new(0, moveInputVector.Y, 0)

        if finalMoveDirection.Magnitude > 0.01 then
            linearVelocity.VectorVelocity = finalMoveDirection.Unit * currentFlySpeed
        else
            linearVelocity.VectorVelocity = Vector3.new(0,0,0)
        end
    else
        linearVelocity.VectorVelocity = Vector3.new(0,0,0)
    end
end)

flyGuiScreen.Destroying:Connect(function()
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    cleanupFlyState(humanoid, humanoid and humanoid.RootPart)
end)

player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid")
    local rootPart = char:WaitForChild("HumanoidRootPart")

    if flyEnabled then
        flyEnabled = false
        toggleFly()
    end
    
    for _, child in ipairs(rootPart:GetChildren()) do
        if child.Name == "FlyLV" or child.Name == "FlyAttachment" then
            child:Destroy()
        end
    end
    
    humanoid.PlatformStand = false
    humanoid.AutoRotate = true

    flyMainFrame.Visible = isGuiVisible
    openFlyGuiButton.Visible = not isGuiVisible
end)

print("Fly Script GUI (Optimized, Speed Control 1-100) loaded.")
