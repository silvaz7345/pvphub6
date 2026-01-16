--// SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--// CONFIG
local AimlockEnabled = false
local ESPEnabled = false

local AimPart = "Head"
local AimRadius = 250
local Smoothness = 0.15
local AimKey = Enum.KeyCode.E

local Tracers = {}
local Boxes = {}

--// FUNÇÕES ÚTEIS
local function IsValidTarget(plr)
    if plr == LocalPlayer then return false end
    if plr.Team == LocalPlayer.Team then return false end
    if not plr.Character then return false end

    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local part = plr.Character:FindFirstChild(AimPart)

    if not hum or hum.Health <= 0 then return false end
    if not part then return false end

    return true
end

--// AIMLOCK
local function GetClosestPlayer()
    local closest, shortest = nil, AimRadius

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character[AimPart].Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if dist < shortest then
                    shortest = dist
                    closest = plr
                end
            end
        end
    end

    return closest
end

--// ESP TRACER
local function CreateTracer(plr)
    local line = Drawing.new("Line")
    line.Thickness = 2
    line.Color = Color3.fromRGB(0,255,0)
    line.Visible = false
    Tracers[plr] = line
end

local function UpdateTracers()
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            if not Tracers[plr] then
                CreateTracer(plr)
            end

            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local size = Camera.ViewportSize
                    Tracers[plr].From = Vector2.new(size.X/2, size.Y)
                    Tracers[plr].To = Vector2.new(pos.X, pos.Y)
                    Tracers[plr].Visible = true
                else
                    Tracers[plr].Visible = false
                end
            end
        elseif Tracers[plr] then
            Tracers[plr].Visible = false
        end
    end
end

--// ESP BOX
local function CreateBox(plr)
    Boxes[plr] = {}
    for i = 1,4 do
        local line = Drawing.new("Line")
        line.Thickness = 2
        line.Color = Color3.fromRGB(0,255,0)
        line.Visible = false
        table.insert(Boxes[plr], line)
    end
end

local function UpdateBoxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTarget(plr) then
            if not Boxes[plr] then
                CreateBox(plr)
            end

            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local scale = math.clamp(1 / (pos.Z / 60), 0.6, 2)
                    local w, h = 40 * scale, 60 * scale

                    local tl = Vector2.new(pos.X - w/2, pos.Y - h/2)
                    local tr = Vector2.new(pos.X + w/2, pos.Y - h/2)
                    local bl = Vector2.new(pos.X - w/2, pos.Y + h/2)
                    local br = Vector2.new(pos.X + w/2, pos.Y + h/2)

                    local b = Boxes[plr]
                    b[1].From, b[1].To = tl, tr
                    b[2].From, b[2].To = tr, br
                    b[3].From, b[3].To = br, bl
                    b[4].From, b[4].To = bl, tl

                    for _, l in ipairs(b) do l.Visible = true end
                else
                    for _, l in ipairs(Boxes[plr]) do l.Visible = false end
                end
            end
        elseif Boxes[plr] then
            for _, l in ipairs(Boxes[plr]) do l.Visible = false end
        end
    end
end

--// LIMPEZA
Players.PlayerRemoving:Connect(function(plr)
    if Tracers[plr] then
        Tracers[plr]:Remove()
        Tracers[plr] = nil
    end
    if Boxes[plr] then
        for _, l in ipairs(Boxes[plr]) do l:Remove() end
        Boxes[plr] = nil
    end
end)

--// INPUT AIMLOCK
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == AimKey then
        AimlockEnabled = not AimlockEnabled
    end
end)

--// LOOP PRINCIPAL
RunService.RenderStepped:Connect(function()
    if AimlockEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestPlayer()
        if target then
            local pos = target.Character[AimPart].Position
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, pos),
                Smoothness
            )
        end
    end

    if ESPEnabled then
        UpdateTracers()
        UpdateBoxes()
    end
end)

--// TOGGLES RÁPIDOS (opcional)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F then
        ESPEnabled = not ESPEnabled
    end
end)
