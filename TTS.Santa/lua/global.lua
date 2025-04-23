--[[
global.lua
global logic and values.
]]
--[[--------------------------

Globals
constants and variables.

]]
---------------------------
local waitForDrawToFinishSec = 0.5

--[[--------------------------

Functions
Called by system events.

]]
---------------------------

local function dump(blob, opt_params)
  local params = opt_params or {}
  local indent = params.indent or ""
  local recursive = true
  if params.nonRecursive then
      recursive = false
  end

  if type(blob) ~= "table" then
      print("In dump: blob is not a table!")
      print("In dump: blob = ", blob)
      return
  end

  local newParams = {}
  newParams.indent = indent .. "  "
  newParams.nonRecursive = false
  for key, value in pairs(blob) do
      local prefix = indent .. key .. " = "
      print(prefix, value)
      if recursive and type(value) == "table" then
          dump(value, newParams)
      end
  end
end


local notecardGuidToZoneGuidsHoldingNotecard = {}
local allColors = {"White", "Red", "Blue", "Green", "Yellow", "Orange", "Brown", "Teal", "Purple", "Pink"}

function subtractColor(colorsArray, colorToRemove)
  local newColorsArray = {}
  for _, color in ipairs(colorsArray) do
    if color ~= colorToRemove then
      table.insert(newColorsArray, color)
    end
  end
  return newColorsArray
end


-- Whenever a card leaves a deck, give it the same tags as that deck
function onObjectEnterZone(zone, object)
  print("Doug: onObjectEnterZone 001")
  if not (zone.type == "Hand" and object.type == "Notecard") then
    print("Doug: onObjectEnterZone 002")
    return
  end

  print("Doug: onObjectEnterZone 003")
  -- This notecard entered this zone.  Record that in map of notecard GUID to Zones Its In.
  local zoneGuidsHoldingNotecard = notecardGuidToZoneGuidsHoldingNotecard[object.guid]
  if zoneGuidsHoldingNotecard == nil then
    zoneGuidsHoldingNotecard = {}
  end
  zoneGuidsHoldingNotecard[zone.guid] = true
  notecardGuidToZoneGuidsHoldingNotecard[object.guid] = zoneGuidsHoldingNotecard
  print("Doug: onObjectEnterZone 004.4")

  -- Wait a bit to update GUI.
  Wait.time(function()
    -- Things may change during the wait.
    local zoneGuidsHoldingNotecard = notecardGuidToZoneGuidsHoldingNotecard[object.guid]
    if zoneGuidsHoldingNotecard == nil then
      print("Doug: onObjectEnterZone 005.6")
      return
    end
    print("Doug: onObjectEnterZone 006")
    local isStillInZone = zoneGuidsHoldingNotecard[zone.guid]
    if not isStillInZone then
      print("Doug: onObjectEnterZone 007")
      return
    end
    -- make the card invisible to everyone but the owner of the zone.
    print("Doug: onObjectEnterZone 008")
    dump(object)

    local holdingColor = zone.getData()["FogColor"]
    print("Doug: holdingColor = ", holdingColor)

    local allOtherColors = subtractColor(allColors, holdingColor)
    print("Doug: allOtherColors = ", allOtherColors)

    object.setInvisibleTo(allOtherColors)

    -- What is the rotation?
    print("Doug: onObjectEnterZone 010")
    local rotation = object.getRotation()
    print("Doug: onObjectEnterZone rotation = " .. rotation[1] .. ", " .. rotation[2] .. ", " .. rotation[3])
    object.setRotationSmooth({0, 0, 0}, false, true)
  end, waitForDrawToFinishSec)
end

function onObjectLeaveZone(zone, object)
  print("Doug: onObjectLeaveZone 001")
  if not (zone.type == "Hand" and object.type == "Notecard") then
    print("Doug: onObjectLeaveZone 002")
    return
  end

  print("Doug: onObjectLeaveZone 003")
  -- This notecard is leaving this zone. Update map of notecard GUID to Zones Its In.
  local zoneGuidsHoldingNotecard = notecardGuidToZoneGuidsHoldingNotecard[object.guid]
  if zoneGuidsHoldingNotecard ~= nil then
    zoneGuidsHoldingNotecard[zone.guid] = false
    notecardGuidToZoneGuidsHoldingNotecard[object.guid] = zoneGuidsHoldingNotecard
  end
  print("Doug: onObjectLeaveZone 005")

  -- Wait a bit to update GUI.
  Wait.time(function()
    print("Doug: onObjectLeaveZone 006")
    -- Things may change during the wait: if not still gone, skip it.
    local zoneGuidsHoldingNotecard = notecardGuidToZoneGuidsHoldingNotecard[object.guid]
    if zoneGuidsHoldingNotecard ~= nil then
      print("Doug: onObjectLeaveZone 007")
      local isBackInZone = zoneGuidsHoldingNotecard[zone.guid]
      if isBackInZone then
        print("Doug: onObjectLeaveZone 008")
        return
      end
    end
    print("Doug: onObjectLeaveZone 009")
    -- make the card visible to everyone.
    print("Doug: onObjectLeaveZone 010")
    object.setInvisibleTo({})
  end, waitForDrawToFinishSec)
end
