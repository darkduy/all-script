-- LocalScript chạy qua executor (KRNL) cho Natural Disaster Survival
-- Hệ thống tạo và chỉnh sửa block như Roblox Studio với gizmo 3D và GUI snap

-- Services
local Players       = game:GetService("Players")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")

local player        = Players.LocalPlayer
local guiParent     = player:WaitForChild("PlayerGui")

-- State
local createdBlocks = {}
local selectedPart  = nil
local snapEnabled   = true
local snapValue     = 1        -- mặc định 1 stud
local guiVisible    = true

-- Gui
local screenGui = Instance.new("ScreenGui", guiParent)
screenGui.Name = "StudioMiniGUI"
screenGui.ResetOnSpawn = false

-- Main frame
local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0.25,0,0.4,0)
main.Position = UDim2.new(0.05,0,0.3,0)
main.BackgroundTransparency = 0.3
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.Active    = true
main.Draggable = true

-- Snap controls
local snapLabel = Instance.new("TextLabel", main)
snapLabel.Size  = UDim2.new(1,0,0,24)
snapLabel.Text  = "Snap: " .. snapValue .. " stud"
snapLabel.TextColor3 = Color3.new(1,1,1)
snapLabel.BackgroundTransparency = 1

local snapBox = Instance.new("TextBox", main)
snapBox.Size = UDim2.new(0.5,0,0,24)
snapBox.Position = UDim2.new(0.5,0,0,0)
snapBox.PlaceholderText = tostring(snapValue)
snapBox.Text = ""
snapBox.TextColor3 = Color3.new(1,1,1)
snapBox.BackgroundTransparency = 0.5

snapBox.FocusLost:Connect(function()
    local v = tonumber(snapBox.Text)
    if v and v > 0 then
        snapValue = v
        snapLabel.Text = "Snap: " .. snapValue .. " stud"
    end
end)

local snapToggle = Instance.new("TextButton", main)
snapToggle.Size = UDim2.new(1,0,0,24)
snapToggle.Position = UDim2.new(0,0,0,24)
snapToggle.Text = snapEnabled and "Snap: ON" or "Snap: OFF"
snapToggle.MouseButton1Click:Connect(function()
    snapEnabled = not snapEnabled
    snapToggle.Text = snapEnabled and "Snap: ON" or "Snap: OFF"
end)

-- Create / Select instructions
local instr = Instance.new("TextLabel", main)
instr.Size = UDim2.new(1,0,0,40)
instr.Position = UDim2.new(0,0,0,48)
instr.Text = "Click block to select, B to create new"
instr.TextWrapped = true
instr.BackgroundTransparency = 1
instr.TextColor3 = Color3.new(1,1,1)

-- Gizmo handles
local moveHandles, resizeHandles, rotateHandles

local function makeHandles()
    -- Move
    moveHandles = Instance.new("Handles")
    moveHandles.Style    = Enum.HandlesStyle.Movement
    moveHandles.Color3   = Color3.new(1,0.5,0.25)
    moveHandles.Adornee  = selectedPart
    moveHandles.Parent   = screenGui

    -- Resize
    resizeHandles = Instance.new("Handles")
    resizeHandles.Style   = Enum.HandlesStyle.Resize
    resizeHandles.Color3  = Color3.new(0.5,1,0.25)
    resizeHandles.Adornee = selectedPart
    resizeHandles.Parent  = screenGui

    -- Rotate
    rotateHandles = Instance.new("ArcHandles")
    rotateHandles.Color3   = Color3.new(0.25,0.5,1)
    rotateHandles.Adornee  = selectedPart
    rotateHandles.Parent   = screenGui
end

local function clearHandles()
    for _, h in ipairs({moveHandles, resizeHandles, rotateHandles}) do
        if h then h:Destroy() end
    end
    moveHandles, resizeHandles, rotateHandles = nil, nil, nil
end

-- Apply snap to value
local function applySnap(val)
    if snapEnabled then
        return math.floor(val/snapValue + 0.5)*snapValue
    else
        return val
    end
end

-- Handle drag events
local initCFrame, initSize

moveHandles         = nil
resizeHandles       = nil
rotateHandles       = nil

-- Selection
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local m = player:GetMouse()
        if m.Target and table.find(createdBlocks, m.Target) then
            -- select existing
            selectedPart = m.Target
            clearHandles()
            makeHandles()
        end
    elseif input.KeyCode == Enum.KeyCode.B then
        -- create new block
        local part = Instance.new("Part")
        part.Size     = Vector3.new(4,4,4)
        part.Color    = Color3.fromRGB(255,255,255)
        part.Anchored = true
        part.CFrame   = workspace.CurrentCamera.CFrame * CFrame.new(0,0,-10)
        part.Parent   = workspace
        table.insert(createdBlocks, part)
    end
end)

-- Move drag
if moveHandles then
    moveHandles.MouseButton1Down:Connect(function(face)
        initCFrame = selectedPart.CFrame
    end)
    moveHandles.MouseDrag:Connect(function(face, distance)
        local d = applySnap(distance)
        local delta = Vector3.FromNormalId(face) * d
        selectedPart.CFrame = initCFrame * CFrame.new(delta)
    end)
end

-- Resize drag
if resizeHandles then
    resizeHandles.MouseButton1Down:Connect(function(face)
        initCFrame = selectedPart.CFrame
        initSize   = selectedPart.Size
    end)
    resizeHandles.MouseDrag:Connect(function(face, distance)
        local d = applySnap(distance)
        local axis = Vector3.FromNormalId(face)
        local newSize = initSize + Vector3.new(
            axis.X * d,
            axis.Y * d,
            axis.Z * d
        )
        -- prevent negative size
        newSize = Vector3.new(
            math.max(0.1, newSize.X),
            math.max(0.1, newSize.Y),
            math.max(0.1, newSize.Z)
        )
        selectedPart.Size = newSize
        -- adjust CFrame to scale from face
        selectedPart.CFrame = initCFrame * CFrame.new(axis * d/2)
    end)
end

-- Rotate drag
if rotateHandles then
    rotateHandles.MouseButton1Down:Connect(function()
        initCFrame = selectedPart.CFrame
    end)
    rotateHandles.MouseDrag:Connect(function(axisEnum, relAngle)
        local angle = applySnap(math.deg(relAngle))
        local rad   = math.rad(angle)
        local axisV = Vector3.FromAxis(axisEnum)
        selectedPart.CFrame = initCFrame * CFrame.fromAxisAngle(axisV, rad)
    end)
end

-- Toggle GUI
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        guiVisible = not guiVisible
        main.Visible = guiVisible
        if moveHandles then moveHandles.Visible   = guiVisible end
        if resizeHandles then resizeHandles.Visible = guiVisible end
        if rotateHandles then rotateHandles.Visible = guiVisible end
    end
end)
