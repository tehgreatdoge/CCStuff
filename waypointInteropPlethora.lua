local recorder = peripheral.find("manipulator")
--[[ 
xaero-waypoint:Home Base:H:-2433:63:-415:6:false:0:Internal-overworld-waypoints
xaero-waypoint:Doge Base:D:609:64:-42:12:false:0:Internal-overworld-waypoints
xaero-waypoint:Portal:P:-299:67:-85:5:false:0:Internal-the-nether-waypoints
xaero-waypoint:Temple of Ra:T:-263:156:-239:6:false:0:Internal-dim%sgjourney$abydos-waypoints

[name:"Death 22:24:07 02-08-2024", x:480, y:60, z:1000, dim:minecraft:the_nether]
 ]]
local function xaerosDimensionToResourceLocation(dimensionThing)
    if dimensionThing == "Internal-overworld-waypoints" then
        return "minecraft:overworld"
    elseif dimensionThing == "Internal-the-nether-waypoints" then
        return "minecraft:the_nether"
    elseif dimensionThing == "Internal-the-end-waypoints" then
        return "minecraft:the_end"
    end
    local mod, dim = string.match(dimensionThing, "Internal%-dim%%([%w_]+)$([%w_]+)-waypoints")
    if mod and dim then
        return mod .. ":" .. dim
    end
    return "minecraft:overworld"
end
local function resourceLocationToXaerosDimension(location)
    if location == "minecraft:overworld" then
        return "Internal-overworld-waypoints"
    elseif location == "minecraft:the_nether" then
        return "Internal-the-nether-waypoints"
    elseif location == "minecraft:the_end" then
        return "Internal-the-end-waypoints"
    else
        local mod,dim = string.match(location, "([%w_]+):(%w_+)")
        return "Internal-dim%"..mod.."$"..dim.."-waypoints"
    end
end
local Waypoint = {}
Waypoint.__index = Waypoint

function Waypoint.new(name, coords, dimension)
    local newWaypoint = {}
    newWaypoint.name = name
    newWaypoint.coords = coords
    newWaypoint.dimension = dimension
    setmetatable(newWaypoint, Waypoint)
    return newWaypoint
end
function Waypoint:toJourneymap()
    local output = "["
    output = output..'name:"'..string.gsub(self.name,'"', "") .. '",'
    output = output.."x:"..self.coords[1] .. ","
    output = output.."y:"..self.coords[2] .. ","
    output = output.."z:"..self.coords[3] .. ","
    output = output.."dim:"..self.dimension .. "]"
    return output
end
function Waypoint:toXaeros()
    local output = "xaero-waypoint:"
    output = output..string.gsub(self.name,':', "")..":"
    output = output..string.sub(self.name,1,1)..":"
    output = output..self.coords[1] ..":"
    output = output..self.coords[2] ..":"
    output = output..self.coords[3] ..":"
    output = output.."20" .. ":"
    output = output.."false"..":"
    output = output.."0" ..":"
    output = output..resourceLocationToXaerosDimension(self.dimension)
    return output
end
function Waypoint.getFromMessage(message)
    local x = Waypoint.fromXaeros(message)
    local j = Waypoint.findJourneymap(message)
    return {j, x}
end
function Waypoint.fromXaeros(input)
    if (not string.sub(input,15) == "xaero-waypoint:") then
        return {}
    end
    local body = string.sub(input,16)
    local count = 1
    local name, letter, x, y, z, mystery, mystery2,mystery3, dimensionThing = string.match(body,"([^:]-):([^:]-):([^:]-):([^:]-):([^:]-):([^:]-):([^:]-):([^:]-):([^:]+)")
    if dimensionThing == nil then
        return {}
    end
    return {{1,Waypoint.new(name, {x,y,z}, xaerosDimensionToResourceLocation(dimensionThing))}}
end
function Waypoint.findJourneymap(message)
    local outputs = {}
    for index, match in string.gmatch(message, "()(%b[])") do
        match = string.sub(match, 2, -2)
        local values = {}
        local success = true
        local currentKey = ""
        local currentToken = ""
        local state = 0 --name, valueseek, string, number, commaseek
        for char in string.gmatch(match, ".") do
            if (state == 0) then
                if char == ":" then
                    if string.len(currentToken) == 0 then
                        success = false
                        break
                    end
                    currentKey = currentToken
                    currentToken = ""
                    state = 1
                else
                    if char ~= " " then
                        currentToken = currentToken .. char
                    end
                end
            elseif state == 1 then
                if string.find(char, "[%d%-]") then
                    currentToken = char
                    state = 3
                elseif string.find(char, '"') then
                    state = 2
                elseif string.find(char, "[%a_]") then
                    currentToken = char
                    state = 5
                end
            elseif state == 2 then
                if char == '"' then
                    values[currentKey] = currentToken
                    currentToken = ""
                    currentKey = ""
                    state = 4
                else
                    currentToken = currentToken..char
                end
            elseif state == 3 then
                if char == " " then
                    if not tonumber(currentToken) then
                        success = false
                        break
                    end
                    values[currentKey] = tonumber(currentToken)
                    currentToken = ""
                    currentKey = ""
                    state = 4
                elseif char == ","  then
                    if not tonumber(currentToken) then
                        success = false
                        break
                    end
                    values[currentKey] = tonumber(currentToken)
                    currentToken = ""
                    currentKey = ""
                    state = 0
                else
                    currentToken = currentToken .. char
                end
            elseif state == 4 then
                if char == "," then
                    state = 0
                elseif char ~= " " then
                    success = false
                    break
                end
            elseif state == 5 then
                if char == "," then
                    values[currentKey] = currentToken
                    currentToken = ""
                    currentKey = ""
                    state = 0
                elseif char == " " then
                    values[currentKey] = currentToken
                    currentToken = ""
                    currentKey = ""
                    state = 4
                elseif string.find(char,"[%a_:]") then
                    currentToken = currentToken .. char
                else
                    success = false
                    break
                end
            end
        end
        if state == 0 then
            success = false
        elseif state == 1 then
            success = false
        elseif state == 2 then
            success = false
        elseif state == 3 then
            if tonumber(currentToken) then
                values[currentKey] = tonumber(currentToken)
            end
        elseif state == 5 then
            values[currentKey] = currentToken
        end
        if type(values.x) ~= "number" then
            success = false
        end
        if type(values.z) ~= "number" then
            success = false
        end
        if values[y] and type(values.y) ~= "number" then
            success = false
        end
        if success then
            table.insert(outputs, {index, Waypoint.new(tostring(values.name or ""), {values.x, values.y or 64, values.z}, tostring(values.dim or "minecraft:overworld"))})
        end
    end
    return outputs
end
while true do
    local event, user, message, uuid = os.pullEvent("chat_message")
    local types = Waypoint.getFromMessage(message)
    local message = ""
    for k,v in pairs(types[2]) do
        message = message.. v[2]:toJourneymap()
    end
    for k,v in pairs(types[1]) do
        message = message.. v[2]:toXaeros()
    end
    if string.len(message) > 0 then
        print(user, message)
        recorder.say("WaypointInteropBot: "..message)
    end
end
