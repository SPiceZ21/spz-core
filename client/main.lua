-- spz-core/client/main.lua

-- ── Resource Cleanup ──────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Mandatory client-side cleanup goes here
end)

-- ── Heartbeat ─────────────────────────────────────────────────────────────
-- Placeholder for future state verification
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
    end
end)
