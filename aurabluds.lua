-- 🔥 AURA BLUDS - Visible = Green | Hidden = Red + Wallcheck Aimbot
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Cam = workspace.CurrentCamera
local LP = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local Settings = {
    Aimbot = {
        Enabled = true,
        Smooth = 3,
        FOV = 160,
        ShowFOV = true,
        TargetPart = "Head",
        VisibilityCheck = true
    },
    ESP = {Boxes = true, Names = true, Skeleton = true}
}

local ESPTable = {}

local function IsVisible(target)
    if not Settings.Aimbot.VisibilityCheck then return true end
    local origin = Cam.CFrame.Position
    local direction = (target.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LP.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, raycastParams)
    if result then
        local hitChar = result.Instance:FindFirstAncestorWhichIsA("Model")
        return hitChar and hitChar == target.Parent
    end
    return true
end

local function CreateESP(plr)
    if plr == LP then return end

    local Box = Drawing.new("Square")
    Box.Thickness = 2
    Box.Filled = false
    Box.Visible = false

    local Name = Drawing.new("Text")
    Name.Size = 15
    Name.Center = true
    Name.Outline = true
    Name.Visible = false

    local Lines = {}
    ESPTable[plr] = {Box = Box, Name = Name, Lines = Lines}

    RS.RenderStepped:Connect(function()
        local Char = plr.Character
        if not Char or not Char:FindFirstChild("HumanoidRootPart") or not Char:FindFirstChild("Head") then
            Box.Visible = false
            Name.Visible = false
            for _, l in pairs(Lines) do l.Visible = false end
            return
        end

        local Root = Char.HumanoidRootPart
        local Head = Char.Head
        local RootPos = Cam:WorldToViewportPoint(Root.Position)
        local HeadPos = Cam:WorldToViewportPoint(Head.Position)

        if RootPos.Z > 0 then
            local isVisible = IsVisible(Head)  -- Check visibility every frame

            -- Dynamic Colors
            local boxColor = isVisible and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 50, 50)   -- Green / Red
            local nameColor = isVisible and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(255, 100, 100)
            local lineColor = isVisible and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 80, 80)

            local Height = (RootPos.Y - HeadPos.Y) * 2.8
            local Width = Height * 0.55

            Box.Size = Vector2.new(Width, Height)
            Box.Position = Vector2.new(RootPos.X - Width/2, HeadPos.Y - Height*0.15)
            Box.Color = boxColor
            Box.Visible = Settings.ESP.Boxes

            local Distance = math.floor((Cam.CFrame.Position - Root.Position).Magnitude)
            Name.Text = plr.Name .. " [" .. Distance .. "m]"
            Name.Position = Vector2.new(RootPos.X, HeadPos.Y - Height*0.45)
            Name.Color = nameColor
            Name.Visible = Settings.ESP.Names

            -- Skeleton
            if Settings.ESP.Skeleton then
                local function Line(a, b)
                    if not a or not b then return end
                    local key = tostring(a) .. tostring(b)
                    local l = Lines[key] or Drawing.new("Line")
                    l.Color = lineColor
                    l.Thickness = 1.8
                    local p1 = Cam:WorldToViewportPoint(a.Position)
                    local p2 = Cam:WorldToViewportPoint(b.Position)
                    l.From = Vector2.new(p1.X, p1.Y)
                    l.To = Vector2.new(p2.X, p2.Y)
                    l.Visible = true
                    Lines[key] = l
                end

                local Torso = Char:FindFirstChild("UpperTorso") or Char:FindFirstChild("Torso")
                local LA = Char:FindFirstChild("LeftUpperArm")
                local RA = Char:FindFirstChild("RightUpperArm")
                local LL = Char:FindFirstChild("LeftUpperLeg")
                local RL = Char:FindFirstChild("RightUpperLeg")

                if Head and Torso then Line(Head, Torso) end
                if Torso then
                    if LA then Line(Torso, LA) end
                    if RA then Line(Torso, RA) end
                    if LL then Line(Torso, LL) end
                    if RL then Line(Torso, RL) end
                end
            else
                for _, l in pairs(Lines) do l.Visible = false end
            end
        else
            Box.Visible = false
            Name.Visible = false
            for _, l in pairs(Lines) do l.Visible = false end
        end
    end)
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
Players.PlayerAdded:Connect(CreateESP)

-- FOV + Aimbot
local Circle = Drawing.new("Circle")
Circle.Color = Color3.fromRGB(255, 80, 120)
Circle.Thickness = 2
Circle.Filled = false

local function GetClosest()
    local best, d = nil, Settings.Aimbot.FOV
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local targetPart = p.Character:FindFirstChild(Settings.Aimbot.TargetPart) or p.Character:FindFirstChild("Head")
            if targetPart then
                local sp, vis = Cam:WorldToViewportPoint(targetPart.Position)
                if vis and IsVisible(targetPart) then
                    local dist = (Vector2.new(sp.X, sp.Y) - Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)).Magnitude
                    if dist < d then 
                        d = dist 
                        best = targetPart 
                    end
                end
            end
        end
    end
    return best
end

RS.RenderStepped:Connect(function()
    Circle.Position = Vector2.new(Cam.ViewportSize.X/2, Cam.ViewportSize.Y/2)
    Circle.Radius = Settings.Aimbot.FOV
    Circle.Visible = Settings.Aimbot.ShowFOV and Settings.Aimbot.Enabled

    if Settings.Aimbot.Enabled and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local t = GetClosest()
        if t then
            Cam.CFrame = Cam.CFrame:Lerp(CFrame.lookAt(Cam.CFrame.Position, t.Position), 1 / Settings.Aimbot.Smooth)
        end
    end
end)

-- Menu (Locked)
local SG = Instance.new("ScreenGui", LP.PlayerGui)
SG.Name = "AuraBluds"

local Main = Instance.new("Frame", SG)
Main.Size = UDim2.new(0, 520, 0, 520)
Main.Position = UDim2.new(0.5, -260, 0.5, -260)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = false

local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.new(1,0,0,40)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "AURA BLUDS - Green/Red ESP"
Title.TextColor3 = Color3.fromRGB(255, 60, 100)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold

local AimbotBtn = Instance.new("TextButton", TopBar)
AimbotBtn.Size = UDim2.new(0.5,0,1,0)
AimbotBtn.Position = UDim2.new(0,0,0,0)
AimbotBtn.Text = "Aimbot"
AimbotBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
AimbotBtn.TextColor3 = Color3.new(1,1,1)

local VisualsBtn = Instance.new("TextButton", TopBar)
VisualsBtn.Size = UDim2.new(0.5,0,1,0)
VisualsBtn.Position = UDim2.new(0.5,0,0,0)
VisualsBtn.Text = "Visuals"
VisualsBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
VisualsBtn.TextColor3 = Color3.new(1,1,1)

local AFrame = Instance.new("Frame", Main)
AFrame.Size = UDim2.new(1,0,1,-40)
AFrame.Position = UDim2.new(0,0,0,40)
AFrame.BackgroundColor3 = Color3.fromRGB(22,22,22)

local VFrame = Instance.new("Frame", Main)
VFrame.Size = UDim2.new(1,0,1,-40)
VFrame.Position = UDim2.new(0,0,0,40)
VFrame.BackgroundColor3 = Color3.fromRGB(22,22,22)
VFrame.Visible = false

local function CreateToggle(parent, y, text, default, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.Position = UDim2.new(0.05, 0, 0, y)
    btn.BackgroundColor3 = default and Color3.fromRGB(180, 40, 80) or Color3.fromRGB(50, 50, 50)
    btn.Text = " " .. text .. " " .. (default and "✔" or "✘")
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        default = not default
        btn.BackgroundColor3 = default and Color3.fromRGB(180, 40, 80) or Color3.fromRGB(50, 50, 50)
        btn.Text = " " .. text .. " " .. (default and "✔" or "✘")
        callback(default)
    end)
end

local function CreateSlider(parent, y, text, minVal, maxVal, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(0.9, 0, 0, 50)
    frame.Position = UDim2.new(0.05, 0, 0, y)
    frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    frame.Active = true
    frame.Draggable = false

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,0,0.5,0)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, -20, 0, 8)
    bar.Position = UDim2.new(0,10,0.6,0)
    bar.BackgroundColor3 = Color3.fromRGB(70,70,70)

    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.new(0,16,0,16)
    knob.Position = UDim2.new((default-minVal)/(maxVal-minVal), -4, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255,60,100)

    local dragging = false

    local function updateSlider(input)
        local barAbsPos = bar.AbsolutePosition.X
        local barWidth = bar.AbsoluteSize.X
        local percent = math.clamp((input.Position.X - barAbsPos) / barWidth, 0, 1)
        local value = math.floor(minVal + (maxVal - minVal) * percent)
        knob.Position = UDim2.new(percent, -4, 0.5, -8)
        label.Text = text .. ": " .. value
        callback(value)
    end

    knob.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateSlider(i)
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)

    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(i)
        end
    end)

    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then i:Cancel() end
    end)
end

CreateToggle(AFrame, 20, "Aimbot Enabled", true, function(v) Settings.Aimbot.Enabled = v end)
CreateToggle(AFrame, 65, "Show FOV Circle", true, function(v) Settings.Aimbot.ShowFOV = v end)
CreateToggle(AFrame, 110, "Visibility Check", true, function(v) Settings.Aimbot.VisibilityCheck = v end)

CreateSlider(AFrame, 155, "Smooth", 1, 20, Settings.Aimbot.Smooth, function(v)
    Settings.Aimbot.Smooth = v
end)

local targetY = 200
local targets = {"Head", "UpperTorso", "Torso", "HumanoidRootPart"}
for _, part in ipairs(targets) do
    local btn = Instance.new("TextButton", AFrame)
    btn.Size = UDim2.new(0.9,0,0,30)
    btn.Position = UDim2.new(0.05,0,0,targetY)
    btn.BackgroundColor3 = (part == Settings.Aimbot.TargetPart) and Color3.fromRGB(180,40,80) or Color3.fromRGB(50,50,50)
    btn.Text = "Target: " .. part
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        Settings.Aimbot.TargetPart = part
        for _, b in pairs(AFrame:GetChildren()) do
            if b:IsA("TextButton") and b.Text:find("Target:") then
                b.BackgroundColor3 = b.Text:find(part) and Color3.fromRGB(180,40,80) or Color3.fromRGB(50,50,50)
            end
        end
    end)
    targetY = targetY + 35
end

CreateToggle(VFrame, 20, "Boxes", true, function(v) Settings.ESP.Boxes = v end)
CreateToggle(VFrame, 65, "Names + Distance", true, function(v) Settings.ESP.Names = v end)
CreateToggle(VFrame, 110, "Skeleton", true, function(v) Settings.ESP.Skeleton = v end)

AimbotBtn.MouseButton1Click:Connect(function() AFrame.Visible = true VFrame.Visible = false end)
VisualsBtn.MouseButton1Click:Connect(function() AFrame.Visible = false VFrame.Visible = true end)

UIS.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

Main.Visible = true
print("🔥 AURA BLUDS - ESP is now Green (visible) / Red (behind walls). Enjoy.")
