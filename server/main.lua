RegisterServerEvent('rpx-stables:server:BuyHorse', function(price, model, names)
    local src = source
    local Player = RPX.GetPlayer(src)
    if (Player.money.cash < price) then
        TriggerClientEvent('RPX:Notify', src, 'You don\'t have enough cash!', 'error')
        return
    end
    MySQL.insert('INSERT INTO player_horses(citizenid, name, horse, components, active) VALUES(@citizenid, @name, @horse, @components, @active)', {
        ['@citizenid'] = Player.citizenid,
        ['@name'] = names,
        ['@horse'] = model,
        ['@components'] = json.encode({}),
        ['@active'] = false,
    })
    Player.RemoveMoney('cash', price)
    TriggerClientEvent('RPX:Notify', src, 'You have successfully bought a horse', 'success')
end)

RegisterServerEvent('rpx-stables:server:SetHoresActive', function(id)
	local src = source
	local Player = RPX.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.citizenid, true})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { true, id, Player.citizenid })
end)

RegisterServerEvent('rpx-stables:server:SetHoresUnActive', function(id)
	local src = source
	local Player = RPX.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.citizenid, false})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, id, Player.citizenid })
end)

RegisterServerEvent('rpx-stables:server:DelHores', function(data)
    local src = source
    local Player = RPX.GetPlayer(src)
    local modelHorse = nil
    local horseid = data.horseid
    local player_horses = MySQL.query.await('SELECT * FROM player_horses WHERE id = @id AND `citizenid` = @citizenid', {
        ['@id'] = horseid,
        ['@citizenid'] = Player.citizenid
    })
    for i = 1, #player_horses do
        if tonumber(player_horses[i].id) == tonumber(horseid) then
            modelHorse = player_horses[i].horse
            MySQL.update('DELETE FROM player_horses WHERE id = ? AND citizenid = ?', { data.horseid, Player.citizenid })
        end
    end
    for k,v in pairs(Config.BoxZones) do
        for j,n in pairs(v) do
            if n.model == modelHorse then
                local sellprice = n.price * 0.5
                Player.AddMoney('cash', sellprice)
                TriggerClientEvent('RPX:Notify', src, 'Successfully Sell your horses price: '..sellprice, 'success')
            end
        end
    end
end)

lib.callback.register('rpx-stables:server:GetHorse', function(source)
	local src = source
	local Player = RPX.GetPlayer(src)
    local callback = nil
	local GetHorse = {}
	local horses = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid', { ['@citizenid'] = Player.citizenid })
	if horses[1] ~= nil then callback = horses end
    return callback
end)

lib.callback.register('rpx-stables:server:GetActiveHorse', function(source)
    local src = source
    local Player = RPX.GetPlayer(src)
    local cid = Player.citizenid
    local callback = false
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', {
        ['@citizenid'] = cid,
        ['@active'] = 1
    })
    if result[1] then callback = result[1] end
    return callback
end)
