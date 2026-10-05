local K = MapModData.TheKingdoms
local DEBUG_KINGDOMS = false
function K.Log(category, message)
    if DEBUG_KINGDOMS then print('[' .. category .. '] ' .. tostring(message)) end
end
function K.Text(key, ...)
    return Locale.ConvertTextKey('TXT_KEY_KINGDOMS_' .. key, ...)
end
function K.Notify(pid, key, ...)
    local p = Players[pid]
    local message = K.Text(key, ...)
    if p and p:IsHuman() then
        p:AddNotification(NotificationTypes.NOTIFICATION_GENERIC, message, K.Text('TITLE'))
    end
    K.Log('KINGDOMS', message)
end
