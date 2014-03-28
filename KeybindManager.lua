KeybindManager = {}
KeybindManager.name = "KeybindManager"
KeybindManager.command = "/kbm"
KeybindManager.version = "v0.0.1"
KeybindManager.variablesVersion = 1
KeybindManager.store = {}
KeybindManager.profileName = "kbm"

local debug = false
local layers, maxBindings

-- Called on initialization
KeybindManager.Initialize = function (eventCode, addOnName)
    if (addOnName ~= KeybindManager.name) then
        return
    end

    layers = GetNumActionLayers()
    maxBindings = GetMaxBindingsPerAction()

    SLASH_COMMANDS[KeybindManager.command] = KeybindManager.run
    KeybindManager.store = ZO_SavedVars:New("KeybindManager_SavedVariables", KeybindManager.variablesVersion, nil, nil, KeybindManager.profileName)
end

KeybindManager.run = function (extra)
    local intent, intentName, setName

    for k,v in string.gmatch(extra, "%S+") do
        if k == 1 then intent = v
        elseif k == 2 then setName = v end
    end

    if     (intent == "save")    then KeybindManager.save(setName)
    elseif (intent == "restore") then KeybindManager.restore(setName)
    elseif (intent == "delete")  then KeybindManager.delete(setName)
    elseif (intent == "debug")   then KeybindManager.debug()
    else KeybindManager.error()
    end
end

KeybindManager.delete = function (setName)
    if KeybindManager.store[setName] ~= nil then
        KeybindManager.store[setName] = nil
    end

    d("Deleted keys from store")
end

KeybindManager.restore = function (setName)
    if KeybindManager.store[setName] ~= nil then

        for _,layer in pairs(KeybindManager.store[setName]) do
            for _,category in pairs(KeybindManager.store[setName][layer]) do
                for _,action in pairs(KeybindManager.store[setName][layer][category]) do
                    for _,binding in pairs(KeybindManager.store[setName][layer][category][action]) do
                        local data = KeybindManager.store[setName][layer][category][action][binding]
                        BindKeyToAction(layer,category,action,binding,data["keyCode"],data["mod1"],data["mod2"],data["mod3"],data["mod4"]) -- This API method is possibly protected. Will CreateDefaultActionBind() work instead?
                    end
                end
            end
        end

        d("Loaded keys from store")
    else
        d("Unable to load keys")
    end
end

KeybindManager.save = function (setName)
    KeybindManager.store[setName] = {}

    for layer=1,layers do
        local layerName,categories = GetActionLayerInfo(layer)
        KeybindManager.store[setName][layerName] = KeybindManager.store[setName][layerName] or {}
        for category=1,categories do
            local categoryName,actions = GetActionLayerCategoryInfo(layer, category)
            KeybindManager.store[setName][layerName][categoryName] = KeybindManager.store[setName][layerName][categoryName] or {}
            for action=1,actions do
                local actionName,isRebindable,isHidden = GetActionInfo(layer, category, action)
                if (isRebindable == true) then
                    KeybindManager.store[setName][layerName][categoryName][actionName] = KeybindManager.store[setName][layerName][categoryName][actionName] or {}
                    for binding=1,maxBindings do
                        KeybindManager.store[setName][layerName][categoryName][actionName][binding] = KeybindManager.store[setName][layerName][categoryName][actionName][binding] or {}
                        local keyCode, mod1, mod2, mod3, mod4 = GetActionBindingInfo(layer, category, action, binding)
                        KeybindManager.store[setName][layerName][categoryName][actionName][binding] = {
                            ["keyCode"] = keyCode,
                            ["mod1"] = mod1,
                            ["mod2"] = mod2,
                            ["mod3"] = mod3,
                            ["mod4"] = mod4
                        }
                    end
                end
            end
        end
    end

    d("Saved keys to store")
end

-- Hook initialization onto the ADD_ON_LOADED event
EVENT_MANAGER:RegisterForEvent(KeybindManager.name, EVENT_ADD_ON_LOADED, KeybindManager.Initialize)
