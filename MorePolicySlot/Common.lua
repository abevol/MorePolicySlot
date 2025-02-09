-- Common
-- Author: abevol
-- DateCreated: 2/8/2025 10:32:09 AM
---@diagnostic disable: undefined-global
----------------------------------------------------------------

function PrintTable(t, indent)
    indent = indent or ""
    if type(t) == "table" then
        for key, value in pairs(t) do
            if type(value) == "table" then
                print(indent.. tostring(key).. ":")
                PrintTable(value, indent.. "  ")
            else
                print(indent.. tostring(key).. ": ".. tostring(value))
            end
        end
    else
        -- 如果传入的参数不是 table 类型，直接打印
        print(indent..  tostring(t))
    end
end

-- 控件树打印函数 XML 版
-- 参数说明：
-- control    : 起始控件实例
-- maxDepth   : 最大打印深度（可选，默认无限制）
function PrintControlTreeXML(control, maxDepth)
    -- XML生成核心逻辑
    local xmlBuffer = {}
    local indentStack = {""}  -- 缩进缓存

    local function BuildXMLNode(node, depth)
        if not node or (maxDepth and depth > maxDepth) then return end

        -- 获取控件信息
        local id = node:GetID()
        if not id or id == "" then
            id = "UnnamedControl"
        end
        local children = node:GetChildren()
        local childCount = #children

        -- 生成XML标签
        local indent = indentStack[depth+1] or string.rep("  ", depth)
        table.insert(xmlBuffer, string.format('%s<%s Children="%d">',
            indent, id, childCount))

        -- 处理子节点
        if not maxDepth or depth < maxDepth then
            indentStack[depth+2] = indent .. "  "  -- 预缓存下级缩进
            for _, child in ipairs(children) do
                BuildXMLNode(child, depth + 1)
            end
        end

        table.insert(xmlBuffer, string.format('%s</%s>', indent, id))
    end

    -- 执行构建
    if control and control.GetChildren then
        table.insert(xmlBuffer, '<?xml version="1.0" encoding="UTF-8"?>')
        BuildXMLNode(control, 0)
    else
        table.insert(xmlBuffer, "<!-- Invalid control -->")
    end

    -- 一次性输出
    print("PrintControlTreeXML:\n" .. table.concat(xmlBuffer, "\n"))
end

-- 查找控件
-- 支持通配符*和数组操作符[]
function FindControls(path)
    local segments = {}
    for segment in path:gmatch("[^/]+") do
        table.insert(segments, segment)
    end

    -- 获取根控件
    local rootControl = ContextPtr:LookUpControl("/" .. segments[1])
    if not rootControl then
        return nil
    end

    local currentContexts = {rootControl}  -- 使用表来存储当前上下文
    for i = 2, #segments do
        local segment = segments[i]
        local nextContexts = {}
        for _, currentContext in ipairs(currentContexts) do
            if segment == "*" then
                -- 处理通配符，获取当前上下文的所有子控件
                local controls = currentContext:GetChildren()
                if #controls == 0 then
                    return nil
                end
                for _, control in ipairs(controls) do
                    table.insert(nextContexts, control)
                end
            elseif segment:find("%[%d+%]") then
                -- 处理数组操作符，提取索引
                local index = tonumber(segment:match("%[(%d+)%]"))
                local controls = currentContext:GetChildren()
                if index > #controls then
                    return nil
                end
                table.insert(nextContexts, controls[index])
            else
                -- 处理具体的控件ID
                local controls = currentContext:GetChildren()
                local found = false
                for _, control in ipairs(controls) do
                    if control:GetID() == segment then
                        table.insert(nextContexts, control)
                        found = true
                        break
                    end
                end
                if not found then
                    return nil
                end
            end
        end
        currentContexts = nextContexts  -- 更新当前上下文
    end
    return currentContexts
end

-- 查找控件
-- 支持通配符*和数组操作符[]
function FindFirstControl(path)
    local controls = FindControls(path)
    return controls and controls[1] or nil
end

-- 控件查找函数
-- 参数：rootControl, searchText, maxDepth
-- 返回：匹配控件列表 { { control, path, depth }, ... }
function FindControlsByText(rootControl, searchText, maxDepth)
    local matches = {}
    local searchLower = string.lower(searchText)

    local function ScanControl(control, currentPath, depth)
        if not control or (maxDepth and depth > maxDepth) then return end

        -- 获取控件ID（安全处理nil值）
        local controlId = control:GetID() or ""
        local controlLower = string.lower(controlId)

        -- 构建完整路径
        local newPath = currentPath .. "/" .. controlId

        -- 检查匹配
        if string.find(controlLower, searchLower) then
            table.insert(matches, {
                control = control,
                path = newPath:sub(2),  -- 移除开头的"/"
                depth = depth
            })
        end

        -- 递归搜索子控件
        for _, child in ipairs(control:GetChildren()) do
            ScanControl(child, newPath, depth + 1)
        end
    end

    if rootControl and rootControl.GetChildren then
        ScanControl(rootControl, "", 0)
    end

    return matches
end

-- 控件打印函数
-- 参数：rootControl, searchText, maxDepth
function PrintControlsByText(rootControl, searchText, maxDepth)
    local matches = FindControlsByText(rootControl, searchText, maxDepth)
    local output = string.format("\n===== 找到 %d 个匹配 '%s' 的控件 =====\n", #matches, searchText)
    for i, match in ipairs(matches) do
        output = output .. string.format("%d. [深度:%d] %s\n", i, match.depth, match.path)
    end
    output = output .. "==================================="
    print(output)
end

function SetControlVisible(controlPath, isVisible)
    -- 获取控件
    local control = FindFirstControl(controlPath)

    -- 如果控件存在，则设置其可见性
    if control then
        control:SetHide(not isVisible)
    else
        print("控件未找到: " .. controlPath)
    end
end

function ToggleControlVisible(controlPath)
    -- 获取控件
    local control = FindFirstControl(controlPath)

    -- 如果控件存在，则切换其可见性
    if control then
        -- 如果控件当前隐藏，则显示它；如果当前显示，则隐藏它
        control:SetHide(not control:IsHidden())
    else
        print("控件未找到: " .. controlPath)
    end
end

-- ToggleControlVisible("/InGame/Screens/GovernmentScreen")
-- PrintControlTreeXML(ContextPtr:LookUpControl("/InGame/Screens/GovernmentScreen"), 5)
-- PrintControlsByText(ContextPtr:LookUpControl("/InGame/Screens/GovernmentScreen"), "button", 20)
-- print(tostring(#FindControls("/InGame/Screens/GovernmentScreen/*")))
