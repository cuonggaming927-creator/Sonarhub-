--// SONAR 🌙 HUB - SLAP TOWER UI
--// Speed + Infinity Jump
--// Made by bro 🤝
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local function ResetHumanoid()
    if not Humanoid then return end

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)

    Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    task.wait()

    Humanoid:ChangeState(Enum.HumanoidStateType.Running)
    task.wait()

    -- kick climbing engine
    Humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
    task.wait()
    Humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

-- SETTING
local Speed = 16
local SpeedStep = 4
local MinSpeed = 8
local MaxSpeed = 100
local InfinityJump = false
local JumpPower = 50
local JumpStep = 5
local MinJump = 30
local MaxJump = 150
local NoClip = false
local Fly = false
local FlySpeed = 2
local FlyConnection

-- APPLY SPEED
local function ApplySpeed()
    if Humanoid then
        Humanoid.WalkSpeed = Speed
    end
end

ApplySpeed()
-- APPLY JUMP
local function ApplyJump()
    if Humanoid then 
        Humanoid.UseJumpPower = true
        Humanoid.JumpPower = JumpPower
    end
end
ApplyJump()

-- NOCLIP

local NoclipConnection

local function SetCharacterCollision(state)
    if not Character then return end

    for _, v in pairs(Character:GetChildren()) do
        if v:IsA("BasePart") then
            -- GIỮ COLLISION CHO CHÂN ĐỂ ENGINE NHẬN ĐẤT
            if v.Name ~= "HumanoidRootPart"
            and not v.Name:lower():find("foot")
            and not v.Name:lower():find("leg") then
                v.CanCollide = not state
            end
        end
    end
end

local function SetNoclip(state)
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end

    if not Character then return end

    if state then
        NoclipConnection = RunService.Heartbeat:Connect(function()
            SetCharacterCollision(true)
        end)
    else
        SetCharacterCollision(false)
        ResetHumanoid()
    end
end
-- FLY
local FlyBV, FlyBG
local FlyMethod = nil -- "bv" or "cframe" or nil
local fallbackTimer = 0

local function cleanupFly()
    if FlyConnection then
        FlyConnection:Disconnect()
        FlyConnection = nil
    end
    if FlyBV then
        pcall(function() FlyBV:Destroy() end)
        FlyBV = nil
    end
    if FlyBG then
        pcall(function() FlyBG:Destroy() end)
        FlyBG = nil
    end
    FlyMethod = nil
    fallbackTimer = 0
end

local function SetFly(state)
    cleanupFly()

    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        warn("[Fly] Không tìm thấy HumanoidRootPart")
        return
    end

    if not state then
        warn("[Fly] Tắt fly")
        return
    end

    -- 1) Thử BodyVelocity + BodyGyro
    local successBV = pcall(function()
        FlyBV = Instance.new("BodyVelocity")
        FlyBV.Name = "SonarFlyBV"
        FlyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
        FlyBV.Velocity = Vector3.zero
        FlyBV.Parent = hrp

        FlyBG = Instance.new("BodyGyro")
        FlyBG.Name = "SonarFlyBG"
        FlyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
        FlyBG.CFrame = hrp.CFrame
        FlyBG.Parent = hrp
    end)

    if successBV and FlyBV and FlyBG then
        FlyMethod = "bv"
        warn("[Fly] Đang sử dụng BodyVelocity method")
    else
        warn("[Fly] Không thể tạo BodyVelocity/BodyGyro, sẽ dùng CFrame fallback")
        FlyMethod = "cframe"
    end

    -- Kết nối update (RenderStepped)
    local cam = workspace.CurrentCamera
    local lastTime = tick()
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not Character or not hrp or not Humanoid then
            cleanupFly()
            return
        end

        local now = tick()
        local dt = math.clamp(now - lastTime, 0, 0.1)
        lastTime = now

        local camCFrame = workspace.CurrentCamera and workspace.CurrentCamera.CFrame or hrp.CFrame
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir += camCFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= camCFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= camCFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir += camCFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += camCFrame.UpVector end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= camCFrame.UpVector end

        if FlyMethod == "bv" and FlyBV and FlyBG then
            -- scale lớn hơn 1 để có tốc độ thấy được; nhân với 50 để gần tương tự nhiều hub
            if dir.Magnitude > 0 then
                FlyBV.Velocity = dir.Unit * (FlySpeed * 50)
            else
                -- giữ 0 để dừng
                FlyBV.Velocity = Vector3.zero
            end
            FlyBG.CFrame = camCFrame

            -- kiểm tra nếu server/anti dập liên tục (với fallback timer)
            fallbackTimer = fallbackTimer + dt
            if fallbackTimer > 0.35 and (not FlyBV.Parent or FlyBV.Velocity.Magnitude < 0.001) then
                -- body bị dập/giết hoặc bị reset -> chuyển sang cframe fallback
                warn("[Fly] BodyVelocity có vẻ bị dập, chuyển sang CFrame fallback")
                FlyMethod = "cframe"
                -- destroy BV/BG (tao sẽ tạo lại fallback not using BV)
                if FlyBV then FlyBV:Destroy() FlyBV = nil end
                if FlyBG then FlyBG:Destroy() FlyBG = nil end
            end

        elseif FlyMethod == "cframe" then
            -- fallback: di chuyển bằng CFrame mỗi frame (không anchored)
            if dir.Magnitude > 0 then
                local move = dir.Unit * (FlySpeed * 10) * dt -- scale và nhân dt
                -- dùng CFrame bằng cách lerp để giảm giật
                local target = hrp.CFrame + move
                hrp.CFrame = hrp.CFrame:Lerp(target, 0.9)
            end
            -- nếu trong fallback mà game vẫn giết hrp movement thì in ra
            fallbackTimer = fallbackTimer + dt
            if fallbackTimer > 3 then
                -- sau 3s fallback vẫn chạy => báo cho user
                warn("[Fly] Đang chạy CFrame fallback (nếu vẫn không di chuyển có thể do anti-cheat của server).")
                fallbackTimer = 0
            end
        else
            -- không method -> thoát an toàn
            cleanupFly()
        end
    end)
end

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid") -- vẫn OK vì đã khai báo local phía trên
    task.wait(0.1)
    
    ApplySpeed()
    ApplyJump()
    SetNoclip(NoClip)
    
    InfinityJump = false
        
end)

-- REMOVE OLD GUI
pcall(function()
    game.CoreGui.SonarSlapHub:Destroy()
end)

-- GUI
local Gui = Instance.new("ScreenGui", game.CoreGui)
Gui.Name = "SonarSlapHub"
Gui.ResetOnSpawn = false

-- MAIN FRAME
local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.fromScale(0.35, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Color3.fromRGB(20,20,25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,18)
-- INNER FRAME (BACKGROUND XỊN)
local Inner = Instance.new("Frame", Main)
Inner.Size = UDim2.fromScale(0.94, 0.78)
Inner.Position = UDim2.fromScale(0.5, 0.58)
Inner.AnchorPoint = Vector2.new(0.5, 0.5)
Inner.BackgroundColor3 = Color3.fromRGB(24,24,30)
Inner.BorderSizePixel = 0
Inner.ClipsDescendants = true
Instance.new("UICorner", Inner).CornerRadius = UDim.new(0,16)
Main.ClipsDescendants = true
-- INNER STROKE (VIỀN NHẸ)
local InnerStroke = Instance.new("UIStroke", Inner)
InnerStroke.Thickness = 2
InnerStroke.Transparency = 0.6
InnerStroke.Color = Color3.fromRGB(160,110,255)
-- STROKE
local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 3
Stroke.Transparency = 0.3
Stroke.Color = Color3.fromRGB(180,120,255)
local InnerGradient = Instance.new("UIGradient", Inner)
InnerGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(28,28,36)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20,20,26))
}
InnerGradient.Rotation = 90
-- TOP BAR
local TopBar = Instance.new("Frame", Main)
TopBar.Size = UDim2.fromScale(1,0.18)
TopBar.BackgroundColor3 = Color3.fromRGB(140,80,255)
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0,18)

local Cover = Instance.new("Frame", TopBar)
Cover.Size = UDim2.fromScale(1,0.5)
Cover.Position = UDim2.fromScale(0,0.5)
Cover.BackgroundColor3 = TopBar.BackgroundColor3
Cover.BorderSizePixel = 0

-- TITLE
local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.fromScale(0.7,1)
Title.Position = UDim2.fromScale(0.06,0)
Title.BackgroundTransparency = 1
Title.Text = "sonar 🌙 hub"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.new(1,1,1)

-- MINIMIZE BUTTON
local MinBtn = Instance.new("TextButton", TopBar)
MinBtn.Size = UDim2.fromScale(0.14,0.6)
MinBtn.Position = UDim2.fromScale(0.83,0.2)
MinBtn.Text = "—"
MinBtn.Font = Enum.Font.GothamBlack
MinBtn.TextScaled = true
MinBtn.BackgroundColor3 = Color3.fromRGB(90,50,160)
MinBtn.TextColor3 = Color3.new(1,1,1)
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0,12)

-- CONTENT
local Content = Instance.new("ScrollingFrame", Inner)
Content.Position = UDim2.fromScale(0,0.03)
Content.Size = UDim2.fromScale(1,0.94)
Content.BackgroundTransparency = 1

local List = Instance.new("UIListLayout", Content)
List.Padding = UDim.new(0,12)
List.HorizontalAlignment = Enum.HorizontalAlignment.Center
List.VerticalAlignment = Enum.VerticalAlignment.Top

Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.ScrollBarImageTransparency = 1
Content.ScrollingDirection = Enum.ScrollingDirection.Y

-- NOCLIP BUTTON
local NoclipBtn = Instance.new("TextButton", Content)
NoclipBtn.Size = UDim2.fromScale(0.9, 0.18)
NoclipBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
NoclipBtn.Text = "Noclip : OFF"
NoclipBtn.Font = Enum.Font.GothamBold
NoclipBtn.TextSize = 14
NoclipBtn.TextColor3 = Color3.new(1,1,1)
NoclipBtn.BorderSizePixel = 0
Instance.new("UICorner", NoclipBtn).CornerRadius = UDim.new(0,10)

-- SPEED BAR (1 HÀNG)
local SpeedBar = Instance.new("Frame", Content)
SpeedBar.Size = UDim2.fromScale(0.9, 0.18)
SpeedBar.BackgroundColor3 = Color3.fromRGB(30,30,36)
SpeedBar.BorderSizePixel = 0
Instance.new("UICorner", SpeedBar).CornerRadius = UDim.new(0,12)

-- LAYOUT NGANG
local BarLayout = Instance.new("UIListLayout", SpeedBar)
BarLayout.FillDirection = Enum.FillDirection.Horizontal
BarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
BarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
BarLayout.Padding = UDim.new(0,10)

Instance.new("UIPadding", SpeedBar).PaddingLeft = UDim.new(0,12)
Instance.new("UIPadding", SpeedBar).PaddingRight = UDim.new(0,12)
local SpeedStroke = Instance.new("UIStroke", SpeedBar)
SpeedStroke.Thickness = 1.5
SpeedStroke.Transparency = 0.6
SpeedStroke.Color = Color3.fromRGB(120,90,200)
-- NÚT -
local MinusBtn = Instance.new("TextButton", SpeedBar)
MinusBtn.Size = UDim2.fromScale(0.22, 0.8)
MinusBtn.Text = "−"
MinusBtn.Font = Enum.Font.GothamBlack
MinusBtn.TextScaled = true
MinusBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
MinusBtn.TextColor3 = Color3.new(1,1,1)
MinusBtn.BorderSizePixel = 0
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0,10)
MinusBtn.TextStrokeTransparency = 0.4

-- TEXT SPEED
local SpeedLabel = Instance.new("TextLabel", SpeedBar)
SpeedLabel.Size = UDim2.fromScale(0.44, 0.7)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed: "..Speed
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 16
SpeedLabel.TextColor3 = Color3.fromRGB(230,230,230)
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Center
SpeedLabel.TextYAlignment = Enum.TextYAlignment.Center
-- NÚT +
local PlusBtn = Instance.new("TextButton", SpeedBar)
PlusBtn.Size = UDim2.fromScale(0.22, 0.8)
PlusBtn.Text = "+"
PlusBtn.Font = Enum.Font.GothamBlack
PlusBtn.TextScaled = true
PlusBtn.BackgroundColor3 = Color3.fromRGB(90,50,160)
PlusBtn.TextColor3 = Color3.new(1,1,1)
PlusBtn.BorderSizePixel = 0
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0,10)
PlusBtn.TextStrokeTransparency  = 0.4

NoclipBtn.MouseButton1Click:Connect(function()
    NoClip = not NoClip
    SetNoclip(NoClip)

    NoclipBtn.Text = "Noclip : " .. (NoClip and "ON" or "OFF")
    NoclipBtn.BackgroundColor3 = NoClip
        and Color3.fromRGB(90,50,160)
        or Color3.fromRGB(35,35,45)
end)
-- JUMP BAR (1 HÀNG)
local JumpBar = Instance.new("Frame", Content)
JumpBar.Size = UDim2.fromScale(0.9, 0.18)
JumpBar.BackgroundColor3 = Color3.fromRGB(30,30,36)
JumpBar.BorderSizePixel = 0
Instance.new("UICorner",JumpBar).CornerRadius = UDim.new(0,12)

-- LAYOUT NGANG
local JumpLayout = Instance.new("UIListLayout", JumpBar)
JumpLayout.FillDirection = Enum.FillDirection.Horizontal
JumpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
JumpLayout.VerticalAlignment = Enum.VerticalAlignment.Center
JumpLayout.Padding = UDim.new(0,10)

Instance.new("UIPadding", JumpBar).PaddingLeft = UDim.new(0,12)
Instance.new("UIPadding", JumpBar).PaddingRight = UDim.new(0,12)
local JumpStroke = Instance.new("UIStroke", JumpBar)
JumpStroke.Thickness = 1.5
JumpStroke.Transparency = 0.6
JumpStroke.Color = Color3.fromRGB(120,90,200)
-- NÚT -
local MinusJumpBtn = Instance.new("TextButton", JumpBar)
MinusJumpBtn.Size = UDim2.fromScale(0.22, 0.8)
MinusJumpBtn.Text = "−"
MinusJumpBtn.Font = Enum.Font.GothamBlack
MinusJumpBtn.TextScaled = true
MinusJumpBtn.BackgroundColor3 = Color3.fromRGB(40,40,50)
MinusJumpBtn.TextColor3 = Color3.new(1,1,1)
MinusJumpBtn.BorderSizePixel = 0
Instance.new("UICorner", MinusJumpBtn).CornerRadius = UDim.new(0,10)
MinusJumpBtn.TextStrokeTransparency = 0.4

-- TEXT JUMP
local JumpLabel = Instance.new("TextLabel", JumpBar)
JumpLabel.Size = UDim2.fromScale(0.44, 0.7)
JumpLabel.BackgroundTransparency = 1
JumpLabel.Text = "Jump: "..JumpPower
JumpLabel.Font = Enum.Font.GothamBold
JumpLabel.TextSize = 16
JumpLabel.TextColor3 = Color3.fromRGB(230,230,230)
JumpLabel.TextXAlignment = Enum.TextXAlignment.Center
JumpLabel.TextYAlignment = Enum.TextYAlignment.Center
-- NÚT +
local PlusJumpBtn = Instance.new("TextButton", JumpBar)
PlusJumpBtn.Size = UDim2.fromScale(0.22, 0.8)
PlusJumpBtn.Text = "+"
PlusJumpBtn.Font = Enum.Font.GothamBlack
PlusJumpBtn.TextScaled = true
PlusJumpBtn.BackgroundColor3 = Color3.fromRGB(90,50,160)
PlusJumpBtn.TextColor3 = Color3.new(1,1,1)
PlusJumpBtn.BorderSizePixel = 0
Instance.new("UICorner", PlusJumpBtn).CornerRadius = UDim.new(0,10)
PlusJumpBtn.TextStrokeTransparency  = 0.4


-- SPEED BUTTON LOGIC
MinusBtn.MouseButton1Click:Connect(function()
    Speed = math.clamp(Speed - SpeedStep, MinSpeed, MaxSpeed)
    ApplySpeed()
    SpeedLabel.Text = "Speed: "..Speed
end)

PlusBtn.MouseButton1Click:Connect(function()
    Speed = math.clamp(Speed + SpeedStep, MinSpeed, MaxSpeed)
    ApplySpeed()
    SpeedLabel.Text = "Speed: "..Speed
end)
-- JUMP LOGIC
MinusJumpBtn.MouseButton1Click:Connect(function()
    JumpPower = math.clamp(JumpPower - JumpStep, MinJump, MaxJump)
    ApplyJump()
    JumpLabel.Text = "Jump: "..JumpPower
end)

PlusJumpBtn.MouseButton1Click:Connect(function()
    JumpPower = math.clamp(JumpPower + JumpStep, MinJump, MaxJump)
    ApplyJump()
    JumpLabel.Text = "Jump: "..JumpPower
end)



-- INFINITY JUMP BUTTON
local JumpBtn = Instance.new("TextButton", Content)
JumpBtn.Size = UDim2.fromScale(0.9,0.18)
JumpBtn.BackgroundColor3 = Color3.fromRGB(30,30,36)
JumpBtn.Text = "Infinity Jump: OFF"
JumpBtn.Font = Enum.Font.GothamBold
JumpBtn.TextSize = 15
JumpBtn.TextColor3 = Color3.fromRGB(230,230,230)
JumpBtn.BorderSizePixel = 0
Instance.new("UICorner", JumpBtn).CornerRadius = UDim.new(0,12)

JumpBtn.MouseButton1Click:Connect(function()
    InfinityJump = not InfinityJump
    JumpBtn.Text = "Infinity Jump: "..(InfinityJump and "ON" or "OFF")
    JumpBtn.BackgroundColor3 = InfinityJump and Color3.fromRGB(90,50,160) or Color3.fromRGB(30,30,36)
end)
-- FLY BUTTON
local FlyBtn = Instance.new("TextButton", Content)
FlyBtn.Size = UDim2.fromScale(0.9, 0.18)
FlyBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
FlyBtn.Text = "Fly : OFF"
FlyBtn.Font = Enum.Font.GothamBold
FlyBtn.TextSize = 14
FlyBtn.TextColor3 = Color3.new(1,1,1)
FlyBtn.BorderSizePixel = 0
Instance.new("UICorner", FlyBtn).CornerRadius = UDim.new(0,10)

FlyBtn.MouseButton1Click:Connect(function()
    Fly = not Fly

if Fly and NoClip then
    NoClip = false
    SetNoclip(false)
    NoclipBtn.Text = "Noclip : OFF"
    NoclipBtn.BackgroundColor3 = Color3.fromRGB(35,35,45)
end

SetFly(Fly)

    FlyBtn.Text = "Fly : "..(Fly and "ON" or "OFF")
    FlyBtn.BackgroundColor3 = Fly
        and Color3.fromRGB(90,50,160)
        or Color3.fromRGB(35,35,45)
end)
-- MINI BUTTON 🌙
local Mini = Instance.new("TextButton", Gui)
Mini.Size = UDim2.fromScale(0.085,0.14)
Mini.Position = UDim2.fromScale(0.03,0.45)
Mini.Text = "🌙"
Mini.Font = Enum.Font.GothamBlack
Mini.TextScaled = true
Mini.BackgroundColor3 = Color3.fromRGB(120,70,200)
Mini.TextColor3 = Color3.new(1,1,1)
Mini.Visible = false
Mini.Active = true
Mini.Draggable = true
Mini.BorderSizePixel = 0
Instance.new("UICorner", Mini).CornerRadius = UDim.new(1,0)
Instance.new("UIAspectRatioConstraint", Mini).AspectRatio = 1

local MiniStroke = Instance.new("UIStroke", Mini)
MiniStroke.Thickness = 3

-- RAINBOW MINI ICON 🌙
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 0.3) % 1
    local color = Color3.fromHSV(hue, 1, 1)

    Mini.BackgroundColor3 = color
    MiniStroke.Color = color
end)

-- TOGGLE UI
MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Mini.Visible = true
end)

Mini.MouseButton1Click:Connect(function()
    Mini.Visible = false
    Main.Visible = true
end)

-- KEYBINDS
UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if input.KeyCode == Enum.KeyCode.Equals then
        Speed = math.clamp(Speed + SpeedStep, MinSpeed, MaxSpeed)
        ApplySpeed()
        SpeedLabel.Text = "Speed: "..Speed
    end

    if input.KeyCode == Enum.KeyCode.Minus then
        Speed = math.clamp(Speed - SpeedStep, MinSpeed, MaxSpeed)
        ApplySpeed()
        SpeedLabel.Text = "Speed: "..Speed
    end
end)

UIS.JumpRequest:Connect(function()
    if not InfinityJump or not Humanoid then return end

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end)




