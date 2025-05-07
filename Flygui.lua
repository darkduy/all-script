--// Fly Script for Executor (Roblox)  
--// Supports GUI drag, auto-hide, speed +/- buttons, dynamic speed label, auto-stop on death

local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local CoreGui    = (gethui and gethui()) or game:GetService("CoreGui")

local player      = Players.LocalPlayer
local char, hrp, humanoid

--// Update character refs on spawn
local function setupCharacter(c)
    char     = c
    hrp      = c:WaitForChild("HumanoidRootPart")
    humanoid = c:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()  -- auto-stop on death
        if flying then stopFly() end
    end)
end
if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

--// Remove old GUI
if CoreGui:FindFirstChild("FlyGui") then
    CoreGui.FlyGui:Destroy()
end

--// Create GUI
local gui   = Instance.new("ScreenGui", CoreGui)
gui.Name    = "FlyGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size              = UDim2.new(0,200,0,120)
frame.Position          = UDim2.new(0,100,0,100)
frame.BackgroundColor3  = Color3.fromRGB(40,40,40)
frame.BackgroundTransparency = 0.3
frame.Active            = true
frame.Draggable         = true

-- Toggle Button
local toggle = Instance.new("TextButton", frame)
toggle.Size            = UDim2.new(1,-20,0,30)
toggle.Position        = UDim2.new(0,10,0,10)
toggle.Text            = "Fly: OFF"
toggle.BackgroundColor3= Color3.fromRGB(80,80,80)
toggle.TextColor3      = Color3.new(1,1,1)

-- Speed Label
local speedLabel = Instance.new("TextLabel", frame)
speedLabel.Size             = UDim2.new(1,-20,0,20)
speedLabel.Position         = UDim2.new(0,10,0,45)
speedLabel.Text             = "Speed: 50"
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3       = Color3.new(1,1,1)

-- + / - Buttons
local incBtn = Instance.new("TextButton", frame)
incBtn.Size           = UDim2.new(0.5,-15,0,30)
incBtn.Position       = UDim2.new(0,10,0,70)
incBtn.Text           = "+"
incBtn.BackgroundColor3 = Color3.fromRGB(70,130,70)
incBtn.TextColor3     = Color3.new(1,1,1)

local decBtn = Instance.new("TextButton", frame)
decBtn.Size           = UDim2.new(0.5,-15,0,30)
decBtn.Position       = UDim2.new(0.5,5,0,70)
decBtn.Text           = "-"
decBtn.BackgroundColor3 = Color3.fromRGB(130,70,70)
decBtn.TextColor3     = Color3.new(1,1,1)

--// Fly vars & functions
local flying = false
local speed  = 50
local bv, bg, conn

local function updateSpeed(v)
    speed = math.clamp(v, 1, 100)
    speedLabel.Text = "Speed: "..speed
end

local function startFly()
    if not hrp or flying or (humanoid and humanoid.Health<=0) then return end
    flying = true; toggle.Text="Fly: ON"
    -- Body movers
    bv = Instance.new("BodyVelocity", hrp)
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bg = Instance.new("BodyGyro", hrp)
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4

    conn = RS.RenderStepped:Connect(function()
        local cam    = workspace.CurrentCamera
        local dir    = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end

        bv.Velocity = (dir.Magnitude>0 and dir.Unit*speed) or Vector3.zero
        bg.CFrame   = cam.CFrame
    end)
end

local function stopFly()
    flying = false; toggle.Text="Fly: OFF"
    if conn then conn:Disconnect(); conn=nil end
    if bv  then bv:Destroy(); bv=nil end
    if bg  then bg:Destroy(); bg=nil end
end

--// Connections
toggle.MouseButton1Click:Connect(function()
    if flying then stopFly() else startFly() end
end)
incBtn.MouseButton1Click:Connect(function() updateSpeed(speed+5) end)
decBtn.MouseButton1Click:Connect(function() updateSpeed(speed-5) end)

-- Auto-hide GUI after 5s idle
local lastInput = tick()
local hidden = false
local function mark() lastInput = tick() end
gui.InputBegan:Connect(mark)
UIS.InputBegan:Connect(mark)
task.spawn(function()
    while true do
        if tick()-lastInput>5 then
            if not hidden then frame.Visible=false; hidden=true end
        else
            if hidden then frame.Visible=true; hidden=false end
        end
        task.wait(1)
    end
end)
