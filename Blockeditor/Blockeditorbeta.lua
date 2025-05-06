-- Tạo ScreenGui
local player = game.Players.LocalPlayer
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name = "BlockEditorGui"

-- Tạo Frame chính
local frame = Instance.new("Frame", screenGui)
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 250, 0, 350)
frame.Position = UDim2.new(0.5, -125, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
frame.Active = true
frame.Draggable = true

-- Tiêu đề
local title = Instance.new("TextLabel", frame)
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
title.Text = "Block Editor"
title.TextSize = 18
title.Font = Enum.Font.SourceSansBold

-- Nút tạo khối
local createButton = Instance.new("TextButton", frame)
createButton.Name = "CreateBlock"
createButton.Size = UDim2.new(0, 150, 0, 40)
createButton.Position = UDim2.new(0.5, -75, 0, 35)
createButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
createButton.Text = "Create Block"
createButton.TextSize = 16

local currentBlock = nil

-- Hàm tạo khối mới
local function createNewBlock()
    if currentBlock then currentBlock:Destroy() end
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    currentBlock = Instance.new("Part", workspace)
    currentBlock.Size = Vector3.new(4, 4, 4)
    currentBlock.Position = rootPart.Position + rootPart.CFrame.LookVector * 5 + Vector3.new(0, 5, 0)
    currentBlock.Anchored = true
    currentBlock.Color = Color3.fromRGB(255, 255, 255)
end
createButton.MouseButton1Click:Connect(createNewBlock)

-- Nhãn và TextBox cho kích thước
local sizeLabel = Instance.new("TextLabel", frame)
sizeLabel.Name = "SizeLabel"
sizeLabel.Size = UDim2.new(1, 0, 0, 20)
sizeLabel.Position = UDim2.new(0, 0, 0, 80)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Size (X, Y, Z):"
sizeLabel.TextSize = 14

local sizes = {"X", "Y", "Z"}
local sizeBoxes = {}
for i, axis in ipairs(sizes) do
    local box = Instance.new("TextBox", frame)
    box.Name = "Size" .. axis
    box.Size = UDim2.new(0, 50, 0, 25)
    box.Position = UDim2.new(0, 10 + (i-1)*60, 0, 105)
    box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    box.Text = "4"
    box.TextSize = 14
    sizeBoxes[axis] = box
end

-- Nút áp dụng kích thước
local applySizeButton = Instance.new("TextButton", frame)
applySizeButton.Name = "ApplySize"
applySizeButton.Size = UDim2.new(0, 80, 0, 25)
applySizeButton.Position = UDim2.new(0.5, -40, 0, 135)
applySizeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
applySizeButton.Text = "Apply"
applySizeButton.TextSize = 14

applySizeButton.MouseButton1Click:Connect(function()
    if currentBlock then
        local x = tonumber(sizeBoxes.X.Text) or 4
        local y = tonumber(sizeBoxes.Y.Text) or 4
        local z = tonumber(sizeBoxes.Z.Text) or 4
        currentBlock.Size = Vector3.new(math.max(0.1, x), math.max(0.1, y), math.max(0.1, z))
    end
end)

-- Nút xoay
local rotLabel = Instance.new("TextLabel", frame)
rotLabel.Name = "RotLabel"
rotLabel.Size = UDim2.new(1, 0, 0, 20)
rotLabel.Position = UDim2.new(0, 0, 0, 165)
rotLabel.BackgroundTransparency = 1
rotLabel.Text = "Rotate (90°):"
rotLabel.TextSize = 14

local rotButtons = {
    {Name="RotXPlus", Text="X+", X=10, Func=function() return CFrame.Angles(math.rad(90), 0, 0) end},
    {Name="RotXMinus", Text="X-", X=60, Func=function() return CFrame.Angles(math.rad(-90), 0, 0) end},
    {Name="RotYPlus", Text="Y+", X=110, Func=function() return CFrame.Angles(0, math.rad(90), 0) end},
    {Name="RotYMinus", Text="Y-", X=160, Func=function() return CFrame.Angles(0, math.rad(-90), 0) end},
    {Name="RotZPlus", Text="Z+", X=210, Func=function() return CFrame.Angles(0, 0, math.rad(90)) end},
}
for _, btn in ipairs(rotButtons) do
    local button = Instance.new("TextButton", frame)
    button.Name = btn.Name
    button.Size = UDim2.new(0, 40, 0, 25)
    button.Position = UDim2.new(0, btn.X, 0, 190)
    button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    button.Text = btn.Text
    button.TextSize = 12
    button.MouseButton1Click:Connect(function()
        if currentBlock then currentBlock.CFrame = currentBlock.CFrame * btn.Func() end
    end)
end

-- Nút màu
local colorLabel = Instance.new("TextLabel", frame)
colorLabel.Name = "ColorLabel"
colorLabel.Size = UDim2.new(1, 0, 0, 20)
colorLabel.Position = UDim2.new(0, 0, 0, 220)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "Color:"
colorLabel.TextSize = 14

local colors = {
    {Name="Red", Color=Color3.fromRGB(255, 0, 0), X=10},
    {Name="Green", Color=Color3.fromRGB(0, 255, 0), X=50},
    {Name="Blue", Color=Color3.fromRGB(0, 0, 255), X=90},
}
for _, clr in ipairs(colors) do
    local button = Instance.new("TextButton", frame)
    button.Name = "Color" .. clr.Name
    button.Size = UDim2.new(0, 30, 0, 25)
    button.Position = UDim2.new(0, clr.X, 0, 245)
    button.BackgroundColor3 = clr.Color
    button.Text = ""
    button.MouseButton1Click:Connect(function()
        if currentBlock then currentBlock.Color = clr.Color end
    end)
end

-- Nút di chuyển
local moveLabel = Instance.new("TextLabel", frame)
moveLabel.Name = "MoveLabel"
moveLabel.Size = UDim2.new(1, 0, 0, 20)
moveLabel.Position = UDim2.new(0, 0, 0, 275)
moveLabel.BackgroundTransparency = 1
moveLabel.Text = "Move (1 stud):"
moveLabel.TextSize = 14

local moveButtons = {
    {Name="MoveXPlus", Text="X+", X=10, Vec=Vector3.new(1, 0, 0)},
    {Name="MoveXMinus", Text="X-", X=60, Vec=Vector3.new(-1, 0, 0)},
    {Name="MoveYPlus", Text="Y+", X=110, Vec=Vector3.new(0, 1, 0)},
    {Name="MoveYMinus", Text="Y-", X=160, Vec=Vector3.new(0, -1, 0)},
    {Name="MoveZPlus", Text="Z+", X=210, Vec=Vector3.new(0, 0, 1)},
}
for _, btn in ipairs(moveButtons) do
    local button = Instance.new("TextButton", frame)
    button.Name = btn.Name
    button.Size = UDim2.new(0, 40, 0, 25)
    button.Position = UDim2.new(0, btn.X, 0, 300)
    button.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    button.Text = btn.Text
    button.TextSize = 12
    button.MouseButton1Click:Connect(function()
        if currentBlock then currentBlock.Position = currentBlock.Position + btn.Vec end
    end)
end
