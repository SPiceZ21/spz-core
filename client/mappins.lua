-- client/mappins.lua — spawn points (garages) as pins for the TAB hub's map.
exports('GetMapPins', function()
    local pins = {}
    for i, s in ipairs((Config.Spawn and Config.Spawn.Spawns) or {}) do
        pins[#pins + 1] = {
            id = 'spawn:' .. i, kind = 'garage', label = s.label or ('Spawn ' .. i), sub = 'Garage · spawn point',
            x = s.coords.x, y = s.coords.y, z = s.coords.z,
            info = { { 'Use', 'Spawn here from the play menu' } },
        }
    end
    return pins
end)
