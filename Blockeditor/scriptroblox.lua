-- Tải Rayfield Interface Suite
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()

-- Tạo Window
local Window = Rayfield:CreateWindow({
    Name = "Block Editor",
    LoadingTitle = "Block Editor for Natural Disaster Survival",
    LoadingSubtitle = "by xAI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BlockEditorConfig",
        FileName = "BlockEditor"
    }
})

-- Tab chính
local MainTab = Window:CreateTab("Main", 4483362458) -- Icon ID cho tab

-- Biến lưu trữ khối hiện tại
local player = game.Players.LocalPlayer
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

-- Nút tạo khối
MainTab:CreateButton({
    Name = "Create Block",
    Callback = createNewBlock
})

-- Phần chỉnh sửa kích thước
MainTab:CreateSection("Size")
local sizeX, sizeY, sizeZ = 4, 4, 4
MainTab:CreateInput({
    Name = "Size X",
    PlaceholderText = "4",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        sizeX = tonumber(value) or 4
    end
})
MainTab:CreateInput({
    Name = "Size Y",
    PlaceholderText = "4",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        sizeY = tonumber(value) or 4
    end
})
MainTab:CreateInput({
    Name = "Size Z",
    PlaceholderText = "4",
    RemoveTextAfterFocusLost = false,
    Callback = function(value)
        sizeZ = tonumber(value) or 4
    end
})
MainTab:CreateButton({
    Name = "Apply Size",
    Callback = function()
        if currentBlock then
            currentBlock.Size = Vector3.new(math.max(0.1, sizeX), math.max(0.1, sizeY), math.max(0.1, sizeZ))
        end
    end
})

-- Phần xoay
MainTab:CreateSection("Rotate (90°)")
local rotButtons = {
    {Name="Rotate X +90°", Func=function() return CFrame.Angles(math.rad(90), 0, 0) end},
    {Name="Rotate X -90°", Func=function() return CFrame.Angles(math.rad(-90), 0, 0) end},
    {Name="Rotate Y +90°", Func=function() return CFrame.Angles(0, math.rad(90), 0) end},
    {Name="Rotate Y -90°", Func=function() return CFrame.Angles(0, math.rad(-90), 0) end},
    {Name="Rotate Z +90°", Func=function() return CFrame.Angles(0, 0, math.rad(90)) end},
    {Name="Rotate Z -90°", Func=function() return CFrame.Angles(0, 0, math.rad(-90)) end},
}
for _, btn in ipairs(rotButtons) do
    MainTab:CreateButton({
        Name = btn.Name,
        Callback = function()
            if currentBlock then currentBlock.CFrame = currentBlock.CFrame * btn.Func() end
        end
    })
end

-- Phần màu sắc
MainTab:CreateSection("Color")
local colors = {
    {Name="Red", Color=Color3.fromRGB(255, 0, 0)},
    {Name="Green", Color=Color3.fromRGB(0, 255, 0)},
    {Name="Blue", Color=Color3.fromRGB(0, 0, 255)},
}
for _, clr in ipairs(colors) do
    MainTab:CreateButton({
        Name = "Set " .. clr.Name,
        Callback = function()
            if currentBlock then currentBlock.Color = clr.Color end
        end
    })
end

-- Phần di chuyển
MainTab:CreateSection("Move (1 stud)")
local moveButtons = {
    {Name="Move X +1", Vec=Vector3.new(1, 0, 0)},
    {Name="Move X -1", Vec=Vector3.new(-1, 0, 0)},
    {Name="Move Y +1", Vec=Vector3.new(0, 1, 0)},
    {Name="Move Y -1", Vec=Vector3.new(0, -1, 0)},
    {Name="Move Z +1", Vec=Vector3.new(0, 0, 1)},
    {Name="Move Z -1", Vec=Vector3.new(0, 0, -1)},
}
for _, btn in ipairs(moveButtons) do
    MainTab:CreateButton({
        Name = btn.Name,
        Callback = function()
            if currentBlock then currentBlock.Position = currentBlock.Position + btn.Vec end
        end
    })
end

-- Thông báo khởi tạo
Rayfield:Notify({
    Title = "Block Editor Loaded",
    Content = "Use the GUI to create and edit blocks!",
    Duration = 5,
    Image = 4483362458
})