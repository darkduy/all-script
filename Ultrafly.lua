--[[
    Ultra Fly Script for Roblox Executors
    Features:
    - Smooth flying with adjustable speed (1-100)
    - Toggleable GUI (F9 to show/hide)
    - Noclip option
    - Camera-relative movement
    - Optimized for performance
    - Works with most executors
--]]

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Local Player
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
end)

-- Configuration
local Config = {
    DefaultSpeed = 50,
    MinSpeed = 1,
    MaxSpeed = 100,
    Acceleration = 0.2,
    Noclip = true,
    ToggleKey = Enum.KeyCode.F,
    GUIKey = Enum.KeyCode.F9,
    Controls = {
        Forward = Enum.KeyCode.W,
        Backward = Enum.KeyCode.S,
        Left = Enum.KeyCode.A,
        Right = Enum.KeyCode.D,
        Up = Enum.KeyCode.Space,
        Down = Enum.KeyCode.LeftShift
    }
}

-- State
local FlyEnabled = false
local CurrentSpeed = Config.DefaultSpeed
local TargetSpeed = Config.DefaultSpeed
local BodyVelocity, BodyGyro

-- Create flying parts
local function CreateFlyParts()
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    
    local RootPart = Character.HumanoidRootPart
    
    -- Remove existing parts
    if BodyVelocity then BodyVelocity:Destroy() end
    if BodyGyro then BodyGyro:Destroy() end
    
    -- Create BodyGyro for stability
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.Name = "FlyGyro"
    BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    BodyGyro.P = 10000
    BodyGyro.D = 500
    BodyGyro.CFrame = RootPart.CFrame
    BodyGyro.Parent = RootPart
    
    -- Create BodyVelocity for movement
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.Name = "FlyVelocity"
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.Velocity = Vector3.new()
    BodyVelocity.Parent = RootPart
    
    -- Enable noclip if configured
    if Config.Noclip then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

-- Create the GUI
local function CreateFlyGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FlyGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 200, 0, 160)
    MainFrame.Position = UDim2.new(0.5, -100, 0.7, -80)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Title.BackgroundTransparency = 0.5
    Title.Text = "Fly Controls"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    -- Toggle Button
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleButton"
    ToggleBtn.Size = UDim2.new(0.9, 0, 0, 30)
    ToggleBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.Text = "Enable Fly"
    ToggleBtn.Font = Enum.Font.SourceSansSemibold
    ToggleBtn.TextSize = 16
    ToggleBtn.Parent = MainFrame

    -- Speed Slider
    local SpeedSlider = Instance.new("Slider")
    SpeedSlider.Name = "SpeedSlider"
    SpeedSlider.Size = UDim2.new(0.9, 0, 0, 20)
    SpeedSlider.Position = UDim2.new(0.05, 0, 0.45, 0)
    SpeedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    SpeedSlider.MinValue = Config.MinSpeed
    SpeedSlider.MaxValue = Config.MaxSpeed
    SpeedSlider.Value = Config.DefaultSpeed
    SpeedSlider.Parent = MainFrame

    -- Speed Label
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Name = "SpeedLabel"
    SpeedLabel.Size = UDim2.new(0.9, 0, 0, 20)
    SpeedLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "Speed: " .. Config.DefaultSpeed
    SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpeedLabel.Font = Enum.Font.SourceSans
    SpeedLabel.TextSize = 14
    SpeedLabel.Parent = MainFrame

    -- Noclip Toggle
    local NoclipToggle = Instance.new("TextButton")
    NoclipToggle.Name = "NoclipToggle"
    NoclipToggle.Size = UDim2.new(0.9, 0, 0, 25)
    NoclipToggle.Position = UDim2.new(0.05, 0, 0.65, 0)
    NoclipToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    NoclipToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    NoclipToggle.Text = "Noclip: " .. (Config.Noclip and "ON" or "OFF")
    NoclipToggle.Font = Enum.Font.SourceSans
    NoclipToggle.TextSize = 14
    NoclipToggle.Parent = MainFrame

    -- Keybinds Info
    local Keybinds = Instance.new("TextLabel")
    Keybinds.Name = "Keybinds"
    Keybinds.Size = UDim2.new(0.9, 0, 0, 30)
    Keybinds.Position = UDim2.new(0.05, 0, 0.85, 0)
    Keybinds.BackgroundTransparency = 1
    Keybinds.Text = "F: Toggle Fly | F9: Hide GUI"
    Keybinds.TextColor3 = Color3.fromRGB(200, 200, 200)
    Keybinds.Font = Enum.Font.SourceSans
    Keybinds.TextSize = 12
    Keybinds.Parent = MainFrame

    -- Connect GUI events
    ToggleBtn.MouseButton1Click:Connect(function()
        FlyEnabled = not FlyEnabled
        ToggleBtn.Text = FlyEnabled and "Disable Fly" or "Enable Fly"
        
        if FlyEnabled then
            CreateFlyParts()
        else
            if BodyVelocity then BodyVelocity:Destroy() end
            if BodyGyro then BodyGyro:Destroy() end
        end
    end)

    SpeedSlider.Changed:Connect(function()
        TargetSpeed = SpeedSlider.Value
        SpeedLabel.Text = "Speed: " .. math.floor(TargetSpeed)
    end)

    NoclipToggle.MouseButton1Click:Connect(function()
        Config.Noclip = not Config.Noclip
        NoclipToggle.Text = "Noclip: " .. (Config.Noclip and "ON" or "OFF")
        if FlyEnabled then
            CreateFlyParts() -- Reinitialize with new noclip setting
        end
    end)

    -- Toggle GUI visibility
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Config.GUIKey and not gameProcessed then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    return ScreenGui
end

-- Main fly function
local function FlyUpdate(dt)
    if not FlyEnabled or not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    
    -- Smooth speed adjustment
    if math.abs(CurrentSpeed - TargetSpeed) > 0.1 then
        CurrentSpeed = CurrentSpeed + (TargetSpeed - CurrentSpeed) * Config.Acceleration * dt * 20
    else
        CurrentSpeed = TargetSpeed
    end
    
    -- Get camera direction
    local Camera = workspace.CurrentCamera
    local CF = Camera and Camera.CFrame or CFrame.new()
    
    -- Calculate movement direction
    local Direction = Vector3.new()
    
    if UIS:GetFocusedTextBox() == nil then
        if UIS:IsKeyDown(Config.Controls.Forward) then
            Direction = Direction + CF.LookVector
        end
        if UIS:IsKeyDown(Config.Controls.Backward) then
            Direction = Direction - CF.LookVector
        end
        if UIS:IsKeyDown(Config.Controls.Left) then
            Direction = Direction - CF.RightVector
        end
        if UIS:IsKeyDown(Config.Controls.Right) then
            Direction = Direction + CF.RightVector
        end
        if UIS:IsKeyDown(Config.Controls.Up) then
            Direction = Direction + Vector3.new(0, 1, 0)
        end
        if UIS:IsKeyDown(Config.Controls.Down) then
            Direction = Direction - Vector3.new(0, 1, 0)
        end
    end
    
    -- Apply movement
    if BodyGyro and BodyVelocity then
        -- Update orientation
        BodyGyro.CFrame = CF
        
        -- Normalize and apply speed
        if Direction.Magnitude > 0 then
            Direction = Direction.Unit * CurrentSpeed
        end
        
        BodyVelocity.Velocity = Direction
    end
end

-- Initialize
local function Init()
    -- Create GUI
    local GUI = CreateFlyGUI()
    
    -- Toggle fly with hotkey
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Config.ToggleKey and not gameProcessed then
            FlyEnabled = not FlyEnabled
            if FlyEnabled then
                CreateFlyParts()
            else
                if BodyVelocity then BodyVelocity:Destroy() end
                if BodyGyro then BodyGyro:Destroy() end
            end
        end
    end)
    
    -- Run fly update
    RunService.Heartbeat:Connect(FlyUpdate)
    
    -- Cleanup
    Player.CharacterRemoving:Connect(function()
        if BodyVelocity then BodyVelocity:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
    end)
    
    GUI.Destroying:Connect(function()
        if BodyVelocity then BodyVelocity:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
    end)
end

-- Start the script
Init()
