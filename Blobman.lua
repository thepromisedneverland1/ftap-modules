local LocalCreatureControl = {}

function LocalCreatureControl.Start()
    local RunService = game:GetService("RunService")
    local ContextActionService = game:GetService("ContextActionService")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PhysicsService = game:GetService("PhysicsService")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    if not player then return end

    local plotItems = workspace:FindFirstChild("PlotItems")
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then return end

    local seatPart = humanoid.SeatPart
    if not seatPart or not seatPart.Parent then return end

    local root = seatPart.Parent
    if not root.Name:find("Blobman") then return end

    local grabEvents = ReplicatedStorage:FindFirstChild("GrabEvents")
    if not grabEvents then return end

    local destroyLine = grabEvents:FindFirstChild("DestroyGrabLine")
    local endGrab = grabEvents:FindFirstChild("EndGrabEarly")
    local setOwner = grabEvents:FindFirstChild("SetNetworkOwner")

    local seatScript = root:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not seatScript then return end

    local creatureGrab = seatScript:FindFirstChild("CreatureGrab")
    local creatureDrop = seatScript:FindFirstChild("CreatureDrop")
    if not creatureGrab or not creatureDrop then return end

    local animations = root:FindFirstChild("BlobmanAnimations")
    local relayAnim = animations and animations:FindFirstChild("RelayClientAnimation")

    local humanoidCreature = root:FindFirstChild("HumanoidCreature")
    local hrp = root:FindFirstChild("HumanoidRootPart")
    local leftDetector = root:FindFirstChild("LeftDetector")
    local rightDetector = root:FindFirstChild("RightDetector")
    if not (humanoidCreature and hrp and leftDetector and rightDetector) then return end

    local leftWeld = leftDetector:FindFirstChild("LeftWeld")
    local rightWeld = rightDetector:FindFirstChild("RightWeld")
    local rightAlignOri = rightDetector:FindFirstChild("RightAlignOrientation")
    if not (leftWeld and rightWeld) then return end

    local animator = humanoidCreature:FindFirstChild("Animator")
    local clientAnims = root:FindFirstChild("ClientAnimations")
    if not (animator and clientAnims) then return end

    local leftGrabAnim = clientAnims:FindFirstChild("LeftGrabAnimation")
    local leftTossAnim = clientAnims:FindFirstChild("LeftTossAnimation")
    local rightGrabAnim = clientAnims:FindFirstChild("RightGrabAnimation")
    local rightTossAnim = clientAnims:FindFirstChild("RightTossAnimation")
    if not (leftGrabAnim and leftTossAnim and rightGrabAnim and rightTossAnim) then return end

    local leftGrabTrack = animator:LoadAnimation(leftGrabAnim)
    local leftTossTrack = animator:LoadAnimation(leftTossAnim)
    local rightGrabTrack = animator:LoadAnimation(rightGrabAnim)
    local rightTossTrack = animator:LoadAnimation(rightTossAnim)

    local leftList, rightList = {}, {}
    local leftAttach, rightAttach
    local leftGrabbing, rightGrabbing = false, false
    local leftTouchActive, rightTouchActive = false, false

    local function restoreCollision(list)
        for _, entry in ipairs(list) do
            if entry.part and entry.part.Parent then
                entry.part.CollisionGroup = entry.group
            end
        end
        table.clear(list)
    end

    local function setNoGrabCollision(list, model)
        if not model then return end
        for _, p in ipairs(model:GetChildren()) do
            if p:IsA("BasePart") then
                table.insert(list, { part = p, group = p.CollisionGroup })
                PhysicsService:SetPartCollisionGroup(p, "NoGrab")
            end
        end
    end

    local function toss(obj)
        if not obj or not obj.Parent or not obj.Parent:IsA("Model") then return end
        local mass = 0
        for _, p in ipairs(obj.Parent:GetChildren()) do
            if p:IsA("BasePart") then
                p.Massless = false
                mass = mass + p.Mass
            end
        end
        if mass <= 0 then return end
        local look = workspace.CurrentCamera.CFrame.LookVector
        local vel = look * (1250 / mass) + look * 15
        if vel.Magnitude > 300 then vel = look * 300
        elseif vel.Magnitude < 200 then vel = look * 200 end
        for _, p in ipairs(obj.Parent:GetChildren()) do
            if p:IsA("BasePart") then p.Velocity = vel end
        end
    end

    local function drop(weld)
        if not weld or not weld.Attachment0 then return end
        local attached = weld.Attachment0.Parent
        if weld == leftWeld then
            restoreCollision(leftList)
            leftAttach = nil
        elseif weld == rightWeld then
            restoreCollision(rightList)
            rightAttach = nil
            if rightAlignOri then rightAlignOri.Attachment0 = nil end
        end
        if creatureDrop then creatureDrop:FireServer(weld) end
        weld.Attachment0 = nil
        if destroyLine and attached then destroyLine:FireServer(attached) end
    end

    local function attach(touched, weld)
        if not touched or not touched.Parent then return end
        local targetHrp = touched.Parent:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return end
        local rootAtt = targetHrp:FindFirstChild("RootAttachment")
        if not rootAtt then return end
        local already = (leftWeld.Attachment0 == rootAtt) or (rightWeld.Attachment0 == rootAtt)
        if already then return end
        if setOwner then setOwner:FireServer(targetHrp, workspace.CurrentCamera.CFrame) end
        task.wait(0.05)
        if creatureGrab then creatureGrab:FireServer(weld.Parent, targetHrp, weld) end
        if weld == leftWeld then
            setNoGrabCollision(leftList, targetHrp.Parent)
        else
            setNoGrabCollision(rightList, targetHrp.Parent)
        end
    end

    local function grabAction(action, state)
        if state ~= Enum.UserInputState.Begin then return end
        if action == "LeftGrab" and not leftGrabbing then
            if leftWeld.Attachment0 == nil then
                leftGrabbing = true
                table.clear(leftList)
                leftDetector.CanTouch = true
                leftGrabTrack:Play()
                if relayAnim then relayAnim:FireServer(leftGrabTrack.Name, true) end
                leftGrabTrack.Stopped:Wait()
                task.wait(0.1)
                restoreCollision(leftList)
                leftDetector.CanTouch = false
                leftTouchActive = false
                leftGrabbing = false
            else
                leftGrabbing = true
                leftTossTrack:Play()
                if relayAnim then relayAnim:FireServer(leftTossTrack.Name, true) end
                leftTossTrack:GetMarkerReachedSignal("Release"):Wait()
                local attached = leftWeld.Attachment0 and leftWeld.Attachment0.Parent
                drop(leftWeld)
                if attached then toss(attached) end
                leftGrabbing = false
            end
        elseif action == "RightGrab" and not rightGrabbing then
            if rightWeld.Attachment0 == nil then
                rightGrabbing = true
                table.clear(rightList)
                rightDetector.CanTouch = true
                rightGrabTrack:Play()
                if relayAnim then relayAnim:FireServer(rightGrabTrack.Name, true) end
                rightGrabTrack.Stopped:Wait()
                task.wait(0.1)
                restoreCollision(rightList)
                rightDetector.CanTouch = false
                rightTouchActive = false
                rightGrabbing = false
            else
                rightGrabbing = true
                rightTossTrack:Play()
                if relayAnim then relayAnim:FireServer(rightTossTrack.Name, true) end
                rightTossTrack:GetMarkerReachedSignal("Release"):Wait()
                local attached = rightWeld.Attachment0 and rightWeld.Attachment0.Parent
                drop(rightWeld)
                if attached then toss(attached) end
                rightGrabbing = false
            end
        end
    end

    local function onTouchedLeft(hit)
        if leftTouchActive or not hit or not hit.Parent then return end
        local victim = hit.Parent:FindFirstChild("Humanoid") or hit.Parent:FindFirstChild("Pet")
        if not victim or victim.Health <= 0 then return end
        if hit:IsDescendantOf(plotItems) then return end
        local targetHrp = victim.Parent:FindFirstChild("HumanoidRootPart")
        local rootAtt = targetHrp and targetHrp:FindFirstChild("RootAttachment")
        if not rootAtt then return end
        leftAttach = rootAtt
        leftTouchActive = true
        attach(hit, leftWeld)
        leftGrabTrack:Stop()
        if relayAnim then relayAnim:FireServer(leftGrabTrack.Name, false) end
    end

    local function onTouchedRight(hit)
        if rightTouchActive or not hit or not hit.Parent then return end
        local victim = hit.Parent:FindFirstChild("Humanoid") or hit.Parent:FindFirstChild("Pet")
        if not victim or victim.Health <= 0 then return end
        if hit:IsDescendantOf(plotItems) then return end
        local targetHrp = victim.Parent:FindFirstChild("HumanoidRootPart")
        local rootAtt = targetHrp and targetHrp:FindFirstChild("RootAttachment")
        if not rootAtt then return end
        rightAttach = rootAtt
        rightTouchActive = true
        attach(hit, rightWeld)
        rightGrabTrack:Stop()
        if relayAnim then relayAnim:FireServer(rightGrabTrack.Name, false) end
    end

    local connections = {}

    table.insert(connections, leftDetector.Touched:Connect(onTouchedLeft))
    table.insert(connections, rightDetector.Touched:Connect(onTouchedRight))

    if endGrab then
        table.insert(connections, endGrab.OnClientEvent:Connect(function(attached)
            if not attached then return end
            if leftWeld.Attachment0 and (attached == leftWeld.Attachment0.Parent or attached:IsDescendantOf(leftWeld.Attachment0.Parent.Parent)) then
                drop(leftWeld)
            elseif rightWeld.Attachment0 and (attached == rightWeld.Attachment0.Parent or attached:IsDescendantOf(rightWeld.Attachment0.Parent.Parent)) then
                drop(rightWeld)
            end
        end))
    end

    local playerModule = player.PlayerScripts:FindFirstChild("PlayerModule")
    local controls
    if playerModule then
        local ok, mod = pcall(require, playerModule)
        if ok and mod then controls = mod:GetControls() end
    end

    table.insert(connections, RunService.Heartbeat:Connect(function()
        if not controls or not humanoidCreature.Parent or not hrp.Parent then return end
        local mv = controls:GetMoveVector()
        if mv.X == 0 and mv.Z == 0 then
            humanoidCreature.WalkToPoint = hrp.Position
        else
            local look = workspace.CurrentCamera.CFrame.LookVector
            local angle = math.atan2(look.X, look.Z) + math.atan2(-mv.X, -mv.Z)
            humanoidCreature.WalkToPoint = hrp.Position + Vector3.new(math.sin(angle) * 10, 0, math.cos(angle) * 10)
        end
    end))

    table.insert(connections, RunService.RenderStepped:Connect(function()
        if not hrp.Parent or not humanoidCreature.Parent or not humanoid.Parent then return end
        local velocity
        pcall(function()
            velocity = hrp.Velocity
        end)
        if not velocity then return end
        if velocity.Magnitude > 5 and humanoidCreature.FloorMaterial ~= Enum.Material.Air then
            local rootPart = humanoidCreature:FindFirstChild("RootPart")
            if not rootPart then return end
            local creatureVel = rootPart.Velocity
            local t = tick()
            local amp = math.abs(math.sin(t * 7)) / 3
            local tilt = math.sin(t * 7) / 24
            local speedRatio = math.min(1, creatureVel.Magnitude / humanoidCreature.WalkSpeed)
            local offset = Vector3.new(0, amp, 0) * speedRatio
            local tiltCF = workspace.CurrentCamera.CFrame * CFrame.Angles(0, 0, tilt * speedRatio)
            humanoid.CameraOffset = humanoid.CameraOffset:Lerp(offset, 0.25)
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(tiltCF, 0.25)
        else
            humanoid.CameraOffset = humanoid.CameraOffset * 0.75
        end
    end))

    local function cleanup()
        for _, conn in ipairs(connections) do
            if typeof(conn) == "RBXScriptConnection" then
                pcall(function() conn:Disconnect() end)
            end
        end
        table.clear(connections)
        pcall(function()
            ContextActionService:UnbindAction("LeftGrab")
            ContextActionService:UnbindAction("RightGrab")
        end)
        if rightWeld and rightWeld.Attachment0 then drop(rightWeld) end
        if leftWeld and leftWeld.Attachment0 then drop(leftWeld) end
        if humanoid and humanoid.Parent then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end

    pcall(function()
        ContextActionService:BindAction("LeftGrab", grabAction, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonL2)
        ContextActionService:BindAction("RightGrab", grabAction, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonR2)
    end)

    table.insert(connections, seatPart:GetPropertyChangedSignal("Occupant"):Connect(function()
        if not seatPart.Occupant then
            cleanup()
        end
    end))

    table.insert(connections, seatPart.AncestryChanged:Connect(function()
        if not seatPart:IsDescendantOf(workspace) then
            cleanup()
        end
    end))

    if humanoid and humanoid.Parent then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    end
end

return LocalCreatureControl
