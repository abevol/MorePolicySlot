-- MorePolicySlot
-- Author: abevol
-- DateCreated: 2/8/2025 10:32:09 AM
---@diagnostic disable: undefined-global
----------------------------------------------------------------

include("Common.lua")
include("Hook.lua")

-- 常量定义 ----------------------------------------------------

local ControlPaths = {
    GOVERNMENT_SCREEN = "/InGame/Screens/GovernmentScreen",
    CONFIRM_BUTTON    = "/InGame/Screens/GovernmentScreen/[2]/[1]/MainContainer/AlphaAnim/RowAnim/PolicyTabStack/PoliciesContainer/ConfirmPolicies"
}

-- 函数定义 ----------------------------------------------------

function OnGovernmentScreenShown()
    local confirmButton = FindFirstControl(ControlPaths.CONFIRM_BUTTON)
    if confirmButton then
        confirmButton:SetDisabled(false)
        confirmButton:RegisterMouseEnterCallback(function ()
            confirmButton:SetDisabled(false)
        end)
    else
        print("[ERROR] ConfirmButton not found!")
    end
end

local function OverridePolicyConfirmation()
    local governmentScreen = ContextPtr:LookUpControl(ControlPaths.GOVERNMENT_SCREEN)
    if governmentScreen then
        governmentScreen:RegisterWhenShown(OnGovernmentScreenShown)
    else
        print("[ERROR] GovernmentScreen not found!")
    end
end

local function OnLoadGameViewStateDone()
    if Game.GetLocalPlayer() ~= -1 then
        OverridePolicyConfirmation()
    end
end

-- 事件注册 ----------------------------------------------------

Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone)

print("[MOD] MorePolicySlot Loaded!")
