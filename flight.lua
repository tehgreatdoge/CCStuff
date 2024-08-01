local modules = peripheral.wrap("back")
 
local uuid = "d7ac3e57-628a-44ac-b899-42d3ef3da175"
 
local flight = false
local isLaunching = false
local shootLaser = false
local launchFactor = 0.5
local function input()
    while true do
        local e,a,b,c= os.pullEvent()
        if e == "key" then
            if a == keys.g then
                flight = not flight
            end
            if a == keys.c and b == false then
                isLaunching = true
                launchFactor = 1
            end
            if a==keys.r then
                shootLaser = true
            end
        elseif e == "key_up" then
            if a == keys.c then
                isLaunching = false
            end
            if a==keys.r then
                shootLaser = false
            end
        end
    end
end
local function output()
    while true do
        if flight then
            modules.launch(-90,-90,0.162)
        else
            sleep(0.05)
        end
    end    
end
local function launch()
    while true do
        if isLaunching then
            local m = modules.getMetaOwner()
            modules.launch(m.yaw,m.pitch,launchFactor)
            launchFactor = math.min(4,launchFactor + 0.5)
        else
            sleep(0.05)
        end
    end
end
local function laser()
    while true do
        if shootLaser then
            local m = modules.getMetaOwner()
            modules.launch(m.yaw,m.pitch,launchFactor)
            m.fireLaser(m.yaw,m.pitch,5)
        else
            sleep(0.05)
        end
    end
end
local inv = modules.getInventory()
local cachedSlot = false
local function feed()
    while true do
        sleep(5)
        local data = modules.getMetaOwner()
        while data.food.hungry do
            local item
            if cachedSlot then
                local slotItem = inv.getItemDetail(cachedSlot)
                if slotItem and slotItem.name == "minecraft:carrot" then
                    item = cachedSlot
                else
                    cachedSlot = nil
                end
            end
            if not item then
                for slot, meta in pairs(inv.list()) do
                    if meta.name == "minecraft:carrot" then
                        print("Using food from slot " .. slot)
                        item = slot
                        cachedSlot = slot
                        break
                    end
                end
            end
            if item then
                inv.consume(item)
            else
                print("Cannot find food")
                break
            end
            data = modules.getMetaOwner()
        end
    end
end
 
parallel.waitForAny(input, output, launch, laser)
 
