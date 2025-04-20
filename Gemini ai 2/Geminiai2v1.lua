-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Biến cấu hình (có thể được đưa vào GUI sau này)
local AutoFarmEnabled = false
local FarmSpeed = 1 -- Thời gian chờ giữa các lần farm (giây)
local FarmRange = 50 -- Phạm vi tìm kiếm Bonds (studs)
local FarmRemoteEvent = nil -- Chúng ta sẽ cần xác định RemoteEvent này

-- Hàm tìm Bonds trong phạm vi
local function findNearestBond()
    local nearestBond = nil
    local minDistance = FarmRange

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart.Position

    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and string.find(obj.Name, "Bond") then -- Tìm kiếm đối tượng có tên chứa "Bond"
            local bondHRP = obj:FindFirstChild("HumanoidRootPart")
            if bondHRP then
                local distance = (humanoidRootPart - bondHRP.Position).Magnitude
                if distance < minDistance then
                    nearestBond = obj
                    minDistance = distance
                end
            end
        end
    end
    return nearestBond
end

-- Hàm tương tác với Bond
local function interactWithBond(bond)
    if FarmRemoteEvent and bond then
        FarmRemoteEvent:FireServer(bond) -- Gửi RemoteEvent đến server để tương tác
        print("Đã tương tác với:", bond.Name)
    end
end

-- Vòng lặp auto farm
RunService.Heartbeat:Connect(function()
    if AutoFarmEnabled then
        local nearestBond = findNearestBond()
        if nearestBond then
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and hrp then
                local distanceToBond = (hrp.Position - nearestBond.HumanoidRootPart.Position).Magnitude
                if distanceToBond > 5 then -- Di chuyển đến gần Bond (ví dụ: trong phạm vi 5 studs)
                    humanoid:MoveTo(nearestBond.HumanoidRootPart.Position)
                else
                    interactWithBond(nearestBond)
                    wait(FarmSpeed) -- Chờ trước khi tìm Bond tiếp theo
                end
            end
        end
    end
end)

-- Bật/tắt Auto Farm (chúng ta sẽ cần một cách để thay đổi giá trị này, ví dụ qua GUI)
function setAutoFarm(enabled)
    AutoFarmEnabled = enabled
    print("Auto Farm:", enabled)
end

-- Giả sử chúng ta có một RemoteEvent tên là "FarmBondRemote" trong ReplicatedStorage
FarmRemoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("FarmBondRemote")
if not FarmRemoteEvent then
    warn("Không tìm thấy RemoteEvent 'FarmBondRemote' trong ReplicatedStorage!")
end

-- Để bật auto farm, bạn có thể gọi:
-- setAutoFarm(true)

-- Để tắt auto farm, bạn có thể gọi:
-- setAutoFarm(false)
