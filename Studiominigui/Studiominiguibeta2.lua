-- Block Editor Mini-Studio for Roblox (Client-side via KRNL)
-- Tính năng: Tạo/chọn block, Move/Rotate/Scale với Snap & Gizmo 3D, GUI điều khiển, phím tắt M/R/S

local Players       = game:GetService("Players")
local UserInput     = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local player        = Players.LocalPlayer
local mouse         = player:GetMouse()

-- SETTINGS
local DEFAULT_SNAP      = 1
local gizmoTransparency = 0.5

-- STATE
local createdBlocks     = {}
local selectedPart      = nil
local mode              = "Move"    -- "Move", "Rotate", "Scale"
local snap              = DEFAULT_SNAP

-- GIZMO SETUP
local moveHandles   = Instance.new("Handles",   player.PlayerGui)
local scaleHandles  = Instance.new("Handles",   player.PlayerGui)
local rotateHandles = Instance.new("ArcHandles",player.PlayerGui)

moveHandles.Style  = Enum.HandlesStyle.Movement
scaleHandles.Style = Enum.HandlesStyle.Resize
moveHandles.Color3   = Color3.new(1,0,0)
scaleHandles.Color3  = Color3.new(0,1,0)
rotateHandles.Color3 = Color3.new(0,0,1)
moveHandles.Transparency, scaleHandles.Transparency, rotateHandles.Transparency =
    gizmoTransparency, gizmoTransparency, gizmoTransparency

moveHandles.Visible, scaleHandles.Visible, rotateHandles.Visible = false, false, false

-- UTIL
local function round(v)
    return math.floor(v/snap + .5)*snap
end

-- SELECT / DESELECT
local function selectPart(part)
    selectedPart = part
    moveHandles.Adornee   = part
    scaleHandles.Adornee  = part
    rotateHandles.Adornee = part
end

local function deselect()
    selectedPart = nil
end

-- UPDATE GIZMO VISIBILITY
local function updateGizmo()
    moveHandles.Visible   = (mode=="Move"   and selectedPart~=nil)
    scaleHandles.Visible  = (mode=="Scale"  and selectedPart~=nil)
    rotateHandles.Visible = (mode=="Rotate" and selectedPart~=nil)
end

-- MODE SWITCH (phím tắt)
UserInput.InputBegan:Connect(function(i, gpe)
    if gpe or i.UserInputType~=Enum.UserInputType.Keyboard then return end
    if     i.KeyCode==Enum.KeyCode.M then mode="Move"
    elseif i.KeyCode==Enum.KeyCode.R then mode="Rotate"
    elseif i.KeyCode==Enum.KeyCode.S then mode="Scale"
    end
    updateGizmo()
end)

-- HANDLES EVENTS
moveHandles.MouseDrag:Connect(function(face, dist)
    if not selectedPart then return end
    local dir = Vector3.FromNormalId(face)
    local pos = selectedPart.Position + dir * round(dist)
    selectedPart.CFrame = CFrame.new(pos) * CFrame.Angles(0,selectedPart.Orientation.Y*math.pi/180,0)
end)

scaleHandles.MouseDrag:Connect(function(face, dist)
    if not selectedPart then return end
    local axis = Vector3.FromNormalId(face)
    local delta = axis * round(dist)
    local s = selectedPart.Size + delta
    -- adjust cframe so opposite face stays fixed
    local offset = axis * (delta/2)
    selectedPart.Size = Vector3.new(math.max(0.1,s.X),math.max(0.1,s.Y),math.max(0.1,s.Z))
    selectedPart.CFrame = selectedPart.CFrame * CFrame.new(offset)
end)

rotateHandles.MouseDrag:Connect(function(axis, ang, _)
    if not selectedPart then return end
    local vec = Vector3.FromAxis(axis) * ang
    -- ang in radians; snap angle if needed
    local deg = math.deg(ang)
    local snapped = math.rad(round(deg))
    selectedPart.CFrame = selectedPart.CFrame * CFrame.fromAxisAngle(vec.Unit, snapped)
end)

-- MOUSE SELECT
mouse.Button1Down:Connect(function()
    local t = mouse.Target
    if t and t:IsA("BasePart") and table.find(createdBlocks, t) then
        selectPart(t)
        updateGizmo()
    else
        deselect()
        updateGizmo()
    end
end)

-- CREATE GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "BlockEditorGUI"

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0.3,0,0.5,0)
main.Position = UDim2.new(0.05,0,0.25,0)
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.BackgroundTransparency = 0.3
main.Active = true
main.Draggable = true

local layout = Instance.new("UIListLayout", main)
layout.Padding = UDim.new(0,5)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeLabel(txt)
    local l=Instance.new("TextLabel",main)
    l.Size=UDim2.new(1,0,0,30); l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=Color3.new(1,1,1); l.TextScaled=true
    return l
end

local function makeButton(txt,cb)
    local b=Instance.new("TextButton",main)
    b.Size=UDim2.new(1,0,0,30); b.Text=txt; b.TextScaled=true
    b.BackgroundColor3=Color3.fromRGB(70,70,70)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function makeTextBox(plh, onEnd)
    local t=Instance.new("TextBox",main)
    t.Size=UDim2.new(1,0,0,30)
    t.PlaceholderText=plh; t.TextScaled=true
    t.ClearTextOnFocus=false
    t.FocusLost:Connect(onEnd)
    return t
end

makeLabel("SNAP (stud):")
local snapBox = makeTextBox(tostring(DEFAULT_SNAP), function()
    local v=tonumber(snapBox.Text)
    if v and v>0 then snap=v else snap=DEFAULT_SNAP end
    snapBox.Text=tostring(snap)
end)

makeLabel("Mode: "..mode)
makeButton("Create Block", function()
    local part=Instance.new("Part")
    part.Size=Vector3.new(4,4,4)
    part.Anchored=true; part.Parent=workspace
    part.CFrame=workspace.CurrentCamera.CFrame * CFrame.new(0,0,-10)
    createdBlocks[#createdBlocks+1]=part
end)
makeButton("Delete Selected", function()
    if selectedPart then
        for i,p in ipairs(createdBlocks) do
            if p==selectedPart then table.remove(createdBlocks,i) end
        end
        selectedPart:Destroy()
        deselect(); updateGizmo()
    end
end)
makeButton("Reset All", function()
    for _,p in ipairs(createdBlocks) do p:Destroy() end
    createdBlocks={}
    deselect(); updateGizmo()
end)

makeLabel("Hotkeys: M=Move R=Rotate S=Scale")

-- END OF SCRIPT
