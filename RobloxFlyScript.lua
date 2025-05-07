local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")
local flying = false
local speed = 50
local sprintMultiplier = 1.5
local bodyVelocity = Instance.new("BodyVelocity")
local bodyGyro = Instance.new("BodyGyro")
bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
bodyGyro.MaxTorque = Vector3.new(9000, 1000, 9000)
bodyGyro.P = 12000
bodyGyro.D = 1500

-- Tạo GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 140, 0, 90)
Frame.Position = UDim2.new(0.5, -70, 0.5, -45)
Frame.BackgroundTransparency = 0.4
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 100, 0, 25)
ToggleButton.Position = UDim2.new(0.5, -50, 0, 10)
ToggleButton.Text = "Fly: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Parent = Frame

local SpeedSlider = Instance.new("TextBox")
SpeedSlider.Size = UDim2.new(0, 100, 0, 25)
SpeedSlider.Position = UDim2.new(0.5, -50, 0, 55)
SpeedSlider.Text = "50"
SpeedSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SpeedSlider.BackgroundTransparency = 0.5
SpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedSlider.Parent = Frame

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Position = UDim2.new(1, -25, 0, 5)
CloseButton.Text = "X"
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Parent = Frame

-- Hàm bật bay
local function startFlying()
    flying = true
    ToggleButton.Text = "Fly: ON"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    bodyVelocity.Parent = rootPart
    bodyGyro.Parent = rootPart
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    humanoid.PlatformStand = true -- Ngăn animation đi bộ
end

-- Hàm tắt bay
local function stopFlying()
    flying = false
    ToggleButton.Text = "Fly: OFF"
    ToggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = nil
    bodyGyro.Parent = nil
    humanoid.PlatformStand = false
end

-- Cập nhật tốc độ
SpeedSlider.FocusLost:Connect(function()
    local newSpeed = tonumber(SpeedSlider.Text)
    if newSpeed and newSpeed >= 1 and newSpeed <= 100 then
        speed = newSpeed
    else
        SpeedSlider.Text = tostring(speed)
    end
end)

-- Đóng/mở GUI
CloseButton.MouseButton1Click:Connect(function()
    Frame.Visible = not Frame.Visible
end)

-- Mở GUI bằng phím F
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F and not UserInputService:GetFocusedTextBox() then
        Frame.Visible = true
    end
end)

-- Bật/tắt bay
ToggleButton.MouseButton1Click:Connect(function()
    if flying then
        stopFlying()
    else
        startFlying()
    end
end)

-- Điều khiển bay
local keys = {
    [Enum.KeyCode.W] = Vector3.new(0, 0, -1),
    [Enum.KeyCode.S] = Vector3.new(0, 0, 1),
    [Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
    [Enum.KeyCode.D] = Vector3.new(1, 0, 0),
    [Enum.KeyCode.Space] = Vector3.new(0, 1, 0),
    [Enum.KeyCode.LeftControl] = Vector3.new(0, -1, 0)
}

local direction = Vector3.new(0, 0, 0)
local isSprinting = false

UserInputService.InputBegan:Connect(function(input)
    if flying and keys[input.KeyCode] then
        direction = direction + keys[input.KeyCode]
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if flying and keys[input.KeyCode] then
        direction = direction - keys[input.KeyCode]
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        isSprinting = false
    end
end)

-- Cập nhật chuyển động bay
RunService.RenderStepped:Connect(function()
    if flying then
        local camCFrame = camera.CFrame
        local moveDirection = rootPart.CFrame:VectorToWorldSpace(direction)
        local finalSpeed = speed * (isSprinting and sprintMultiplier or 1)
        
        -- Điều chỉnh góc nghiêng dựa trên hướng di chuyển
        local tilt = moveDirection.Z * -15 -- Nghiêng tối đa 15 độ
        local targetCFrame = camCFrame * CFrame.Angles(0, 0, math.rad(tilt))
        bodyGyro.CFrame = targetCFrame
        
        bodyVelocity.Velocity = moveDirection * finalSpeed
    end
end)

-- Xử lý tái sinh nhân vật
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid = character:WaitForChild("Humanoid")
    if flying then
        startFlying()
    end
end)
