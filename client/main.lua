local ESX = exports['es_extended']:getSharedObject()
local lib = exports.ox_lib

local starbucksItems = {
    {label = 'Zrób Kawę', item = 'coffee', anim = 'PROP_HUMAN_BBQ'},
    {label = 'Zrób Ciasto', item = 'cake', anim = 'PROP_HUMAN_BBQ'},
    {label = 'Weź pusty kubek', item = 'empty_cup'}
}

local function makeItem(item, anim)
    TaskStartScenarioInPlace(PlayerPedId(), anim, 0, true)
    Wait(5000)
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('starbucks:makeItem', item)
end

local function giveItem(item, anim)
    TaskStartScenarioInPlace(PlayerPedId(), anim, 0, true)
    Wait(10)
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('starbucks:giveItem', item)
end

local function removeItem(item, anim)
    TaskStartScenarioInPlace(PlayerPedId(), anim, 0, true)
    Wait(100)
    ClearPedTasks(PlayerPedId())
    TriggerServerEvent('starbucks:removeItem', item)
end

CreateThread(function()
    exports.ox_target:addSphereZone({
        coords = vec3(0,0,0),
        radius = 1.5,
        debug = false,
        options = (function()
            local options = {}
            for _, v in pairs(starbucksItems) do
                table.insert(options, {
                    icon = "fa-solid fa-mug-hot",
                    label = v.label,
                    onSelect = function()
                        makeItem(v.item, v.anim)
                    end
                })
            end
            return options
        end)()
    })

    exports.ox_target:addSphereZone({
        coords = vec3(-1195.25, -893.85, 13.99),
        radius = 1.5,
        debug = false,
        options = {
            {
                icon = "fa-solid fa-receipt",
                label = "Wystaw rachunek",
                onSelect = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer ~= -1 and closestDistance < 3.0 then
                        local input = lib.inputDialog('Rachunek', {
                            {type = 'number', label = 'Kwota', default = 100}
                        })
                        if input and tonumber(input[1]) then
                            TriggerServerEvent('starbucks:billPlayer', GetPlayerServerId(closestPlayer), tonumber(input[1]))
                        else
                            ESX.ShowNotification('Wprowadź poprawną kwotę')
                        end
                    else
                        ESX.ShowNotification('Brak gracza w pobliżu')
                    end
                end
            }
        }
    })
end)

RegisterNetEvent('starbucks:payBill', function(amount)
    if type(amount) ~= "number" or amount <= 0 then
        ESX.ShowNotification('Niepoprawna kwota')
        return
    end

    lib.registerContext({
        id = 'pay_bill_ctx',
        title = 'Otrzymałeś rachunek',
        options = {
            {
                title = ('Zapłać $%d'):format(amount),
                onSelect = function()
                    TriggerServerEvent('starbucks:payBillConfirm', amount)
                    ESX.ShowNotification('Zapłaciłeś $' .. amount)
                end
            },
            {
                title = 'Anuluj',
                onSelect = function()
                    lib.hideContext()
                end
            }
        }
    })

    lib.showContext('pay_bill_ctx')
end)

CreateThread(function()
    exports.ox_target:addSphereZone({
    name = 'starbucks_make_coffee',
    coords = vec3(263.0658, -820.5704, 29.4378),
    radius = 1.0,
    debug = false,
    options = {
        {
            name = 'make_coffee',
            icon = 'fa-solid fa-mug-hot',
            label = 'Zrób kawę',
            onSelect = function()
                local playerData = ESX.GetPlayerData()
                if playerData and playerData.job and playerData.job.name == 'starbucks' then
                    -- zapytanie do serwera, czy gracz ma pusty kubek
                    ESX.TriggerServerCallback('starbucks:hasItem', function(hasItem)
                        if hasItem then
                            removeItem('empty_cup')
                            makeItem('coffee', 'PROP_HUMAN_BBQ')
                        else
                            ESX.ShowNotification('Potrzebujesz pustego kubka, aby zrobić kawę')
                        end
                    end, 'empty_cup')
                else
                    ESX.ShowNotification('Nie jesteś zatrudniony w tej pracy')
                end
            end   
        }
    }
})

     exports.ox_target:addSphereZone({
        name = 'starbucks_take_cup',
        coords = vec3(265.2755, -821.3865, 29.4378),
        radius = 1.0,
        debug = false,
        options = {
            {
                name = 'take_cup',
                label = 'Weź pusty kubek',
                onSelect = function()
                    local playerData = ESX.GetPlayerData()
                    if playerData and playerData.job and playerData.job.name == 'starbucks' then
                        giveItem('empty_cup')
                    else
                        ESX.ShowNotification('Nie jesteś zatrudniony w tej pracy')
                    end
                end
            }
        }
    })

    exports.ox_target:addSphereZone({
        name = 'starbucks_make_cake',
        coords = vec3(260.7395, -822.0260, 29.4378),
        radius = 1.0,
        debug = false,
        options = {
            {
                name = 'make_cake',
                icon = 'fa-solid fa-birthday-cake',
                label = 'Zrób ciasto',
                onSelect = function()
                    local playerData = ESX.GetPlayerData()
                    if playerData and playerData.job and playerData.job.name == 'starbucks' then
                        makeItem('cake', 'PROP_HUMAN_BBQ')
                    else
                        ESX.ShowNotification('Nie jesteś zatrudniony w tej pracy')
                    end
                end
            }
        }
    })

    exports.ox_target:addSphereZone({
        name = 'starbucks_bill_customer',
        coords = vec3(264.0209, -823.1702, 29.4378),
        radius = 1.0,
        debug = false,
        options = {
            {
                name = 'bill_customer',
                icon = 'fa-solid fa-cash-register',
                label = 'Wystaw rachunek',
                onSelect = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer ~= -1 and closestDistance < 3.0 then
                        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'bill_dialog', {
                            title = 'Kwota do zapłaty',
                        }, function(data, menu)
                            local amount = tonumber(data.value)
                            if amount then
                                TriggerServerEvent('starbucks:billPlayer', GetPlayerServerId(closestPlayer), amount)
                            else
                                ESX.ShowNotification('Wprowadź poprawną kwotę')
                            end
                            menu.close()
                        end, function(data, menu)
                            menu.close()
                        end)
                    else
                        ESX.ShowNotification('Brak gracza w pobliżu')
                    end
                end,
            }
        }
    })
end)

CreateThread(function()
    local blipData = Config.Starbucks.Starbucks.Blip
    local blip = AddBlipForCoord(blipData.coords)
    SetBlipSprite(blip, blipData.sprite)
    SetBlipScale(blip, blipData.scale)
    SetBlipColour(blip, blipData.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Starbucks")
    EndTextCommandSetBlipName(blip)
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, travel in pairs(Config.Starbucks.Starbucks.FastTravels) do
            local dist = #(coords - travel.From)

            if dist < 10.0 then
                -- Marker
                DrawMarker(travel.Marker.type, travel.From.x, travel.From.y, travel.From.z,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    travel.Marker.x, travel.Marker.y, travel.Marker.z,
                    travel.Marker.r, travel.Marker.g, travel.Marker.b, travel.Marker.a, false, true, 2, travel.Marker.rotate, false, false, false)

                -- Prompt + teleport
                if dist < 1.5 then
                    ESX.ShowHelpNotification("Naciśnij ~INPUT_CONTEXT~ aby wejść na górę")
                    if IsControlJustReleased(0, 38) then -- E
                        DoScreenFadeOut(500)
                        Wait(500)
                        SetEntityCoords(ped, travel.To.coords.x, travel.To.coords.y, travel.To.coords.z)
                        SetEntityHeading(ped, travel.To.heading)
                        Wait(500)
                        DoScreenFadeIn(500)
                    end
                end
            end
        end
    end
end)