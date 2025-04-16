-- Dịch vụ cần thiết
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Biến trạng thái
local autoAttackEnabled = false
local autoFarmEnabled = false

-- Tạo GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoFarmGUI"
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Khung chính của GUI
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
mainFrame.AnchorPoint = Vector2.new(0, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.Parent = screenGui

-- Tiêu đề
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0.25, 0)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "Auto Farm Control"
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

-- Nút Bật/Tắt Tự động Tấn công
local autoAttackButton = Instance.new("TextButton")
autoAttackButton.Name = "AutoAttackButton"
autoAttackButton.Size = UDim2.new(0.9, 0, 0.3, 0)
autoAttackButton.Position = UDim2.new(0.05, 0, 0.3, 0)
autoAttackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoAttackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoAttackButton.Text = "Bật Tự động Tấn công"
autoAttackButton.Font = Enum.Font.SourceSans
autoAttackButton.TextSize = 14
autoAttackButton.Parent = mainFrame

-- Nút Bật/Tắt Tự động Thu thập
local autoFarmButton = Instance.new("TextButton")
autoFarmButton.Name = "AutoFarmButton"
autoFarmButton.Size = UDim2.new(0.9, 0, 0.3, 0)
autoFarmButton.Position = UDim2.new(0.05, 0, 0.65, 0)
autoFarmButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
autoFarmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
autoFarmButton.Text = "Bật Tự động Thu thập"
autoFarmButton.Font = Enum.Font.SourceSans
autoFarmButton.TextSize = 14
autoFarmButton.Parent = mainFrame

-- Hàm xử lý khi nút Tự động Tấn công được nhấn
autoAttackButton.MouseButton1Click:Connect(function()
    autoAttackEnabled = not autoAttackEnabled
    if autoAttackEnabled then
        autoAttackButton.Text = "Tắt Tự động Tấn công"
        autoAttackButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100) -- Màu xanh lá cây khi bật
    else
        autoAttackButton.Text = "Bật Tự động Tấn công"
        autoAttackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
    print("Tự động tấn công:", autoAttackEnabled)
end)

-- Hàm xử lý khi nút Tự động Thu thập được nhấn
autoFarmButton.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    if autoFarmEnabled then
        autoFarmButton.Text = "Tắt Tự động Thu thập"
        autoFarmButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100) -- Màu xanh lá cây khi bật
    else
        autoFarmButton.Text = "Bật Tự động Thu thập"
        autoFarmButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
    print("Tự động thu thập:", autoFarmEnabled)
end)

-- Hàm để tìm kiếm quái vật gần nhất (giữ nguyên từ trước)
local function findNearestMonster()
    local nearestMonster = nil
    local minDistance = math.huge
    local playerCharacter = Players.LocalPlayer.Character
    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local playerPosition = playerCharacter.HumanoidRootPart.Position
    local monsterNameKeywords = {"Zombie", "Slime", "Bandit"}
    for _, object in pairs(Workspace:GetChildren()) do
        if object:IsA("Model") and object:FindFirstChild("Humanoid") then
            for _, keyword in pairs(monsterNameKeywords) do
                if string.find(object.Name, keyword) then
                    local monsterPosition = object.PrimaryPart.Position
                    local distance = (playerPosition - monsterPosition).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        nearestMonster = object
                    end
                    break
                end
            end
        end
    end
    return nearestMonster
end

-- Hàm để tìm kiếm tài nguyên gần nhất (chúng ta sẽ cần thông tin về tên hoặc loại tài nguyên)
local function findNearestResource()
    local nearestResource = nil
    local minDistance = math.huge
    local playerCharacter = Players.LocalPlayer.Character
    if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local playerPosition = playerCharacter.HumanoidRootPart.Position
    local resourceNameKeywords = {"Ore", "Plant", "Loot"} -- Ví dụ: các từ khóa trong tên tài nguyên
    for _, object in pairs(Workspace:GetChildren()) do
        -- Chúng ta cần một cách để xác định tài nguyên. Có thể dựa vào tên, lớp hoặc một thuộc tính nào đó.
        -- Ví dụ: kiểm tra tên có chứa từ khóa và đối tượng có phải là một Part hoặc Model không.
        if (object:IsA("Part") or object:IsA("Model")) then
            for _, keyword in pairs(resourceNameKeywords) do
                if string.find(object.Name, keyword) then
                    local resourcePosition = object.Position -- Hoặc object.PrimaryPart.Position nếu là Model
                    local distance = (playerPosition - resourcePosition).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        nearestResource = object
                    end
                    break
                end
            end
        end
    end
    return nearestResource
end

-- Vòng lặp chính
while true do
    wait(0.1) -- Giảm thời gian chờ để phản hồi nhanh hơn

    if autoAttackEnabled then
        local nearestMonster = findNearestMonster()
        if nearestMonster then
            print("Đang tấn công:", nearestMonster.Name)
            -- Thêm logic tấn công ở đây (chúng ta cần biết cách tấn công trong Dead Rail)
        end
    end

    if autoFarmEnabled then
        local nearestResource = findNearestResource()
        if nearestResource then
            print("Đang thu thập:", nearestResource.Name)
            -- Thêm logic thu thập tài nguyên ở đây (chúng ta cần biết cách thu thập trong Dead Rail)
        end
    end
end
