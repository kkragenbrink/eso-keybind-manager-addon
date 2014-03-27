KeybindManager = {}
KeybindManager.name = "KeybindManager"
KeybindManager.command = "/kbm"
KeybindManager.version = "v0.0.1"
KeybindManager.variablesVersion = 1
KeybindManager.store = {}
KeybindManager.profileName = "kbm"

local debug = false

-- Called on initialization
KeybindManager.Initialize = function (eventCode, addOnName)
    if (addOnName ~= KeybindManager.name) then
        return
    end

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
        for _,v in KeybindManager.store[setName] do
            BindKeyToAction(layerIndex, categoryIndex, actionIndex, bindingIndex, v[0], v[1], v[2], v[3], v[4])
        end
        d("Loaded keys from store")
    else
        d("Unable to load keys")
    end
end

KeybindManager.save = function (setName)
    KeybindManager.store[setName] = {}

    for _,v in actions do
        KeybindManager.store[v] = GetActionBindingInfo(layerIndex, categorIndex, actionIndex, bindingIndex)
    end

    d("Saved keys to store")
end

-- Hook initialization onto the ADD_ON_LOADED event
EVENT_MANAGER:RegisterForEvent(KeybindManager.name, EVENT_ADD_ON_LOADED, KeybindManager.Initialize)
