--[[
global.lua
global logic and values.
]]

--[[--------------------------

Globals
constants and variables.

]] ---------------------------

--[[
Enums
]]
-- Flagged debug system.
-- Keep these alphabetized.
local activeDebugTags = {
    BidInputPanel = false,
    ButtonConfiguration = false,
    GameDeckPlacement = true,
    PanelVisibility = false,
    SourceDeckCreation = false,
    StateMachine = false,
    Timing = false,
    UIStateResponse = false,
    XMLTableBuilding = false,
}

local appStates = {
    Null = "Null",
    Loaded = "Loaded",
    CreatedSourceDecks = "CreatedSourceDecks",
    SetupRunning = "SetupRunning",
    CreatedAndDealtGameDeck = "CreatedAndDealtGameDeck",
    GameRunning = "GameRunning",
    CleanupRunning = "CleanupRunning",
}

local playerColors = {
    "White",
    "Brown",
    "Red",
    "Orange",
    "Yellow",
    "Green",
    "Teal",
    "Blue",
    "Purple",
    "Pink",
}

-- Enum of different deck and card types.
local cardTypes = {
    doll = "doll",
    kite = "kite",
    robot = "robot",
    radio = "radio",
    poop = "poop",
    wrapping = "wrapping",
    broom = "broom",
    magic = "magic",
}

local orderedCardTypes = {
    cardTypes.doll,
    cardTypes.kite,
    cardTypes.robot,
    cardTypes.radio,
    cardTypes.poop,
    cardTypes.wrapping,
    cardTypes.broom,
    cardTypes.magic,
}

--[[
Twiddles for alternate game play.
]]
-- Last card hidden.
local hideLastCard = true
-- Variable season length
local variableSeasonLength = false

--[[
Meta game info.
]]
local maxPlayers = 4
local numSeasons = 4

--[[
For card management & setup:

Right when the game loads we are in one of two states:

A) There's just n cards, exactly one of each type, in a deck.
That deck has tag importedDeckTag.
No other metadata associated with the cards.

    If that's the case, we want to:
    1) Spread the cards out.
    2) Assign a name to each card based on the card type.  This is based
    on the assumption that the order of the cards matches orderedCardTypes.
    3) Create n copies of each card, so now we have <num card types> separate
    decks, one for each type, each with n copies of that card.
    4) Remove importedDeckTag from those decks/cards, add sourceCardTag to each card and sourceDeckTag to each deck.
    5) Physically hide the decks (like under the table).

Or,
B) We've already done all of A: we just have the <num card types> decks with sourceDeckTag
hidden under the table.

From there, when it's time to create the game deck, we look at the number of players, and tells us how many cards of each
type we need from the source decks.

* If we just pulled cards from the source deck, we'd have to put them back later, kind of error-prone upkeep.
* If we just had a single card in each souce deck and cloned the number of copies we need, TTS gets slow and
* fart and makes an irritating boop boop noise for each clone.
* So, we make the source decks big, then we clone the whole source deck (one clone), deal cards from cloned
  deck into game deck, then destroy anything left in cloned decks.
]]
-- A map from the card type enum to the GUID of the corresponding source deck
-- containing n copies of that card.
local cardTypeToSourceDeckGUID = {}


-- Card into based on num players:
-- cardDistributionByNumPlayers maps number of players to a distribution.
-- distribution maps card type to number of instances of that card in final game deck.
-- So one entry might be like:
-- cardDistributionByNumPlayers[4]["doll"] = 25
-- (In a 4 player game there are 25 instances of the "doll" card in the game deck).
local cardDistributionByNumPlayers = {}
-- Across all "numPlayers", across all card types, what's the biggest number in
-- cardDistributionByNumPlayers?  In other words, what's the most copies of given card we could
-- ever need?
local maxCardCount = 0

-- Times
local standardWaitSec = 0.5
local waitAfterCardCloneSec = 0.07
local waitAfterDeckShuffleSec = 1
local waitAfterDealtCardFlipSec = 0.2
local waitAfterDealtCardMoveSec = 0.1
local waitOnPrivateStateChange = 0.1

local handleInputWaitSec = 0.1

-- Positions
local cardRowWidth = 20
local cardColumnHeight = 3.5
local dealtCardBaseYPos = 1.5
local dealtCardDeltaYPos = 0.1
local hiddenDeckYPos = -5

local finalTallyPanelStartXPos = -50
local finalTallyPanelStartYPos = 0
local bidViewPanelStartXPos = -100
local bidViewPanelStartYPos = 50
local bidInputPanelStartXPos = -200
local bidInputPanelStartYPos = -50

local gameDeckZPos = (numSeasons/2 * cardColumnHeight) + cardColumnHeight

-- Deck info.
local gameDeckGUID = nil
local numCardsInGameDeck = nil

-- TTS object tags
-- See above: we may start with just one deck with one instance of each card:
-- That is the importedDeck, each card is importedCard.
local importedDeckTag = "importedDeck"
local importedCardTag = "importedCard"
-- We make a bunch of copies of each imported card, so for each card type we
-- have a deck of n cards.
-- These are source decks, the cards inside are source cards.
local sourceCardTag = "sourceCard"
local sourceDeckTag = "sourceDeck"
-- When creating game deck, we we clone the source deck and deal out of there: these are clones.
local cloneTag = "clone"
-- The final deck used for the game. These can be safely deleted when we are done with a game.
local gameDeckTag = "gameDeck"

--[[
-- Xml
]]
-- The XML from the global.XML file.
local pristineXml = nil

-- Ids, text for XML.
local finalTallyPanelId = "FinalTallyPanel"
local bidViewPanelId = "BidViewPanel"
local bidInputPanelIdPrefix = "BidInputPanel_"

-- Map from panelId to true.
-- We have to add ids for bid input panels later when they are created (one per player).
local allPanelIdsSet = {
    [finalTallyPanelId] = true,
    [bidViewPanelId] = true,
}

-- Note these are used for both Name and ID generation.
local scoreInputCellNames = {
    "Winter",
    "Spring",
    "Summer",
    "Fall",
    "Toys",
    "Floor",
}

local bidDetailTypes = {
    "Cards",
    "Tiebreaker",
}

-- XML sizes.
local tableTitleRowHeight = 50
local tableStandardRowHeight = 30
local tableLabelCellWidth = 150
local tableContentCellWidth = 200

local bottomButtonWidth = 200
local bottomButtonHeight = 30
local bottomButtonSpacing = 30

-- XML colors.
local finalTallyTitleRowColor = "#ddffff"
local finalTallyPlayerRowColor = "#cccccc"
local evenRowColor = "#aacccc"
local oddRowColor = "#aaaacc"
local finalTallySumRowColor = "#cccccc"

-- ID prefixes for things in table.
local rowIdPrefix = "Row"
local cellIdPrefix = "Cell"
local textIdPrefix = "Text"

local setupButtonId = "SetupButtonId"
local cleanupButtonId = "CleanupButtonId"
local toggleBiddingOpenButtonId = "ToggleBiddingOpenButtonId"
local toggleBidsPanelButtonId = "ToggleBidsViewPanelButtonId"
local toggleFinalTallyPanelButtonId = "ToggleFinalTallyPanelButtonId"

-- Mapping buttons to details about when enabled and color.
local bottomButtonIds = {
    setupButtonId,
    cleanupButtonId,
    toggleBiddingOpenButtonId,
    toggleBidsPanelButtonId,
    toggleFinalTallyPanelButtonId,
}

local bottomRowIds = {
    "BottomButtonRow1",
    "BottomButtonRow2",
}

local bottomButtonTableLayoutId = "BottomButtonTableLayout"
local bottomButtonPanelId = "BottomButtonPanel"

local maxBottomButtonsPerRow = 5

local disabledButtonAlpha = 0.3

local finalTallySumRowIndex = nil

-- "State" in the Rodux sense: these are core truths that determine everything
-- else.
-- I will try to enforce a roduxy pattern here: this is all kindn "private": to
-- modify you call a function, that function pings interested watchers.
local _privateState = {
    _callbackIdGen = 1,

    _uiCallbacks = {},
    _uiCallbackEnqueued = false,

    _stateModCallbacks = {},
}


--[[--------------------------

Functions
Lua Utilities
Useful for any lua project.

]] ---------------------------
local function getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- String split util.
local function mysplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Recursive dump a table to console.
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

local function debugPrint(debugTag, ...)
    if activeDebugTags[debugTag] then
        print(debugTag .. ": ", ...)
    end
end

--[[--------------------------

Functions
Non-UI TTS Lua Utilities
Useful for any tts project.

]] ---------------------------
 -- Table has cells, cell has one or more elements.
 -- All elements in cell have id of the form:
 -- <cellElementIdPrefix>_<rowNumber>_<columnNumber>
 -- Get those pieces out.
local function splitCellElementId(cellElementId)
    local pieces = mysplit(cellElementId, "_")
    local cellElementIdPrefix = pieces[1]
    local rowIndex = tonumber(pieces[2])
    local columnIndex = tonumber(pieces[3])
    return cellElementIdPrefix, rowIndex, columnIndex
end

-- Make an id for some element in the row i, column j cell in table.
-- rowIndex and columnIndex should be 1 or higher (lua is 1-indexed)
local function makeCellElementId(cellElementIdPrefix, rowIndex, columnIndex)
    if rowIndex < 1 then
        return nil
    end
    if columnIndex < 1 then
        return nil
    end
    return cellElementIdPrefix .. "_" .. rowIndex .. "_" .. columnIndex
end

-- Wait this long, call then given function, then call the callback.
local function runAfterWaitThenCallback(waitSec, runFunc, callbackFunc)
    Wait.time(function()
        runFunc()
        callbackFunc()
    end, waitSec)
end

local function makeMockSeatedPlayerObject(index)
    local names = {
        "Alice",
        "Charlie",
        "Bob",
    }
    local colors = {
        "Red",
        "Blue",
        "Green",
    }
    return {
        color = colors[index],
        steam_name = names[index],
        seated = true,
    }
end

local function getSeatedPlayerObjects()
    -- Array of Player instances.
    local allPlayers = Player.getPlayers()
    -- Array of colors of Seated Players.
    local seatedPlayerColors = getSeatedPlayers()

    -- Array of Seated Player instances.
    -- Fill it in.
    -- Along the way figure out which player is the clicker.
    local seatedPlayerObjects = {}
    for _, seatedPlayerColor in pairs(seatedPlayerColors) do
        for _, player in pairs(allPlayers) do
            if player.color == seatedPlayerColor then
                table.insert(seatedPlayerObjects, player)
            end
        end
    end

    -- FIXME(dbanks)
    -- A mock for development:
    -- If there's just one, pretend there are 4.
    if #seatedPlayerObjects == 1 then
        for i = 1, 3 do
            table.insert(seatedPlayerObjects, makeMockSeatedPlayerObject(i))
        end
    end
    return seatedPlayerObjects
end

-- Take a card from the deck.
-- Returns a table with card and the deck: in TTS taking the second to last
-- card from deck actually creates a new object for the remaining deck, a "deck" with one card).
local function safeTakeFromDeck(deck)
    debugPrint("SourceDeckCreation", "Doug: safeTakeFromDeck: deck = ", deck.name)
    local card = deck.takeObject()
    debugPrint("SourceDeckCreation", "Doug: safeTakeFromDeck after takeObject: card = ", card)
    debugPrint("SourceDeckCreation", "Doug: safeTakeFromDeck after takeObject: deck = ", deck)
    if deck.remainder ~= nil then
        debugPrint("SourceDeckCreation", "Doug: safeTakeFromDeck: deck.remainder = ", deck.remainder)
        deck = deck.remainder
    end
    if card == nil then
        debugPrint("SourceDeckCreation", "Doug: safeTakeFromDeck: card is nil")
        return {card = deck, deck = nil}
    else
        debugPrint("SourceDeckCreation", "Doug: safeTakeFromDeck: card is ", card)
        debugPrint("SourceDeckCreation", "Doug: safeTakeFromDeck: deck is ", deck)
        return {card = card, deck = deck}
    end
end

-- How many seated players?
local function getSeatedPlayerCount()
    local seatedPlayerObjects = getSeatedPlayerObjects()
    return #seatedPlayerObjects
end

-- Shortcut to reset a deck by GUID.
local function resetDeck(deckGUID)
    local deck = getObjectFromGUID(deckGUID)
    if deck then
        deck.reset()
        return true
    end
    return false
end

--[[--------------------------

Functions
State machine fu.
Generally useful.

]] ---------------------------
local function declareValidState(stateName, initValue)
    _privateState[stateName] = initValue
end

local function getPrivateState(stateName)
    if _privateState[stateName] == nil then
        debugPrint("StateMachine", "Error: getting invalid state with stateName = ", stateName)
        assert(false, "Error: getting invalid state with stateName = " .. stateName)
        return nil
    end
    return _privateState[stateName]
end

-- Write updates into the store.
-- stateName: key for state being changed.
-- value: value for the key.
-- opt_onRegisteredCallbacksCalled: optional arg.  Once the state change has finished
-- pinging all UI-related listners, this callback will be hit.
local function setPrivateState(stateDictionary, opt_onRegisteredCallbacksCalled)
    if stateDictionary.appState then
        debugPrint("StateMachine", "Doug: called setPrivateState")
        if activeDebugTags.StateMachine then
            dump(stateDictionary)
        end
    end

    local somethingChanged = false
    for k, v in pairs(stateDictionary) do
        if _privateState[k] == nil then
            debugPrint("StateMachine", "Error: setting invalid state with k = ", k)
            assert(false, "Error: setting invalid state with k = " .. k)
            return false
        end

        -- Not allowed to use nil values.
        if v == nil then
            debugPrint("StateMachine", "Error: setting nil state with k = ", k)
            assert(false, "Error: setting nil state with k = " .. k)
            return false
        end

        if _privateState[k] ~= v then
            _privateState[k] = v
            somethingChanged = true
        end
    end

    if not somethingChanged then
        -- no-op:
        if opt_onRegisteredCallbacksCalled then
            opt_onRegisteredCallbacksCalled()
        end
        return
    end

    -- allow for derived state mods.
    for _, stateModCallback in pairs(_privateState._stateModCallbacks) do
        _privateState = stateModCallback(_privateState)
    end

    -- It is very likely that a gang of state changes happen in a flurry.
    -- We don't want or need to trigger UI updates for each little change:
    -- Better to call at the end of the flurry.
    -- So:
    -- 1. We wait a bit before hitting UI callbacks.
    -- 2. We mark that we're gonna hit the callbacks.  If that mark is set, we don't need
    --    to enqueue more callbacks.
    -- 3. When callbacks finally fire we unset the mark.
    if _privateState._uiCallbackEnqueued then
        return true
    end
    _privateState._uiCallbackEnqueued = true

    Wait.time(function()
        --- Hit all the callbacks.
        for _, uiCallback in pairs(_privateState._uiCallbacks) do
            uiCallback(_privateState)
        end

        _privateState._uiCallbackEnqueued  = false
        if opt_onRegisteredCallbacksCalled then
            opt_onRegisteredCallbacksCalled()
        end
    end, waitOnPrivateStateChange)

end

local function addStateChangedStateModCallback(stateModCallback)
    local id = _privateState._callbackIdGen
    _privateState.callbackIdGen = _privateState._callbackIdGen + 1

    _privateState._stateModCallbacks[id] = stateModCallback
    return id
end

local function addStateChangedUIModCallback(uiCallback)
    local id = _privateState._callbackIdGen
    _privateState.callbackIdGen = _privateState._callbackIdGen + 1

    _privateState._uiCallbacks[id] = uiCallback
    return id
end

local function removeStateChangedUIModCallback(callbackId)
    if not _privateState._uiCallbacks[callbackId] then
        debugPrint("StateMachine", "Error: called removeStateChangedUIModCallback with invalid callbackId = ", callbackId)
        return
    end
    _privateState._uiCallbacks[callbackId] = nil
end

local function removeStateChangedStateModCallback(callbackId)
    if not _privateState._stateModCallbacks[callbackId] then
        debugPrint("StateMachine", "Error: called removeStateChangedStateModCallback with invalid callbackId = ", callbackId)
        return
    end
    _privateState._stateModCallbacks[callbackId] = nil
end


--[[
Many games have the following notion:
  * each player collects points.
  * there are different ways players can get points (e.g. in Settlers there's settlements, cities, longest road, production cards, etc.)
  * Total score is sum of points from each category.
So we have a generalized notion of this:
typedScoresByPlayerColor is indexed by player color.
Values are maps from "point type" to "points of that type for that player".
]]
local function getTypedScoreByPlayerColor(playerColor, scoreInputCellName)
    local tsbpc = getPrivateState("typedScoresByPlayerColor")

    if not tsbpc then
        return 0
    end

    if not tsbpc[playerColor] then
        return 0
    end

    if not tsbpc[playerColor][scoreInputCellName] then
        return 0
    end

    return tsbpc[playerColor][scoreInputCellName]
end

local function setTypedScoreByPlayerColor(playerColor, scoreInputCellName, score)
    local tsbpc = getPrivateState("typedScoresByPlayerColor")
    if tsbpc[playerColor] == nil then
        tsbpc[playerColor] = {}
    end
    tsbpc[playerColor][scoreInputCellName] = score
    setPrivateState({typedScoresByPlayerColor = tsbpc})
end

local function cleanupTypedScoresForPlayer(playerColor)
    local tsbpc = getPrivateState("typedScoresByPlayerColor")
    tsbpc[playerColor] = {}
    setPrivateState({typedScoresByPlayerColor = tsbpc})
end

local function getTotalScoreForPlayer(playerColor)
    local tsbpc = getPrivateState("typedScoresByPlayerColor")
    local total = 0
    if tsbpc then
        if tsbpc[playerColor] then
            for _, score in pairs(tsbpc[playerColor]) do
                total = total + score
            end
        end
    end
    return total
end

--[[--------------------------

Functions
UI TTS Lua Utilities
Useful for any tts project.

]] ---------------------------
-- Given an XML node, find the child with the given id.
-- Params can set whether or not this is recursive.
local function findXmlNodeWithID(parentXmlNode, nodeId, opt_params)
    local params = opt_params or {}
    local recursive = true
    if params.nonRecursive then
        recursive = false
    end
    for _, childXmlNode in pairs(parentXmlNode) do
        for key, value in pairs(childXmlNode) do
            if key == "attributes" then
                for attributeKey, attributeValue in pairs(value) do
                    if attributeKey == "id" and attributeValue == nodeId then
                        return childXmlNode
                    end
                end
            end
            -- FIXME(dbanks): not sure this is correct but maybe no one is calliing it?
            if recursive then
                if key == "children" then
                    local result = findXmlNodeWithID(value, nodeId, params)
                    if result then
                        return result
                    end
                end
            end
        end
    end

    return nil
end

-- Add the given key value pairs to the given XML node.
local function safeAddToXmlAttributes(xmlNode, attributes)
    if xmlNode and attributes then
        if xmlNode.attributes == nil then
            xmlNode.attributes = {}
        end
        for key, value in pairs(attributes) do
            xmlNode.attributes[key] = value
        end
    end
end

-- Add one node as a child of the other.
local function safeAddToXmlChildren(xmlParent, xmlChild)
    if xmlParent and xmlChild then
        if xmlParent.children == nil then
            xmlParent.children = {}
        end
        table.insert(xmlParent.children, xmlChild)
    end
end

-- remove all existing children.
local function removeXmlChildren(xmlParent)
    if xmlParent then
        xmlParent.children = {}
    end
end

-- Create an XML node with provided params.
local function makeXmlNode(tag, attributes)
    local xmlNode = {
        tag = tag,
        attributes = attributes,
        children = {},
    }
    return xmlNode
end

-- Generate an ID for a row.
-- "Row_n" for n = row index.
-- This is lua so rows are 1-indexed.
local function makeRowId(rowIndex)
    if rowIndex < 1 then
        return nil
    end
    return rowIdPrefix  .. "_" .. tostring(rowIndex)
end

-- Make row at given index of table.
-- It will take a class.
local function makeXmlRow(rowIndex, rowClass)
    local rowId = makeRowId(rowIndex)
    local xmlRow = makeXmlNode("Row", {
        id = rowId,
        class = rowClass,
        preferredHeight=tostring(tableStandardRowHeight),
    })
    return xmlRow
end

-- Make a text node with given id, text, and class.
local function makeXmlText(textId, text, class)
    local xmlText = makeXmlNode("Text", {
        class = class,
        id = textId,
        text = text,
    })

    return xmlText
end

-- Make a cell in a table.
-- That cell just holds text.
local function makeXmlTextCell(rowIndex, columnIndex, cellText, cellClass, textClass)
    local cellId = makeCellElementId(cellIdPrefix, rowIndex, columnIndex)
    local textId = makeCellElementId(textIdPrefix, rowIndex, columnIndex)

    local xmlCell = makeXmlNode("Cell", {
        class = cellClass,
        id = cellId,
    })
    local xmlText = makeXmlText(textId, cellText, textClass)
    safeAddToXmlChildren(xmlCell, xmlText)
    return xmlCell
end

-- Make a cell in a table containing an input widget.
-- When content is changed, trigger the onEditEdit function.
local function makeXmlInputCell(inputIdPrefix, rowIndex, columnIndex, initValue, onEndEdit)
    -- inputIdPrefix should never be nil.
    if inputIdPrefix == nil then
        debugPrint("XMLTableBuilding", "inputIdPrefix is nil!!! rowIndex = ", rowIndex, " columnIndex = ", columnIndex)
        return nil
    end

    local cellId = makeCellElementId(cellIdPrefix, rowIndex, columnIndex)
    local inputId = makeCellElementId(inputIdPrefix, rowIndex, columnIndex)

    local xmlCell = makeXmlNode("Cell", {
        class = "InputCellClass",
        id = cellId,
        width = tableContentCellWidth,
    })

    local xmlInput = makeXmlNode("InputField", {
        class = "InputClass",
        id = inputId,
        text = initValue,
        onEndEdit = onEndEdit,
        width = tableContentCellWidth/2,
        height = tableStandardRowHeight,
    })
    safeAddToXmlChildren(xmlCell, xmlInput)

    return xmlCell
end

--[[--------------------------

Functions
Worry about the set of bottom buttons.

]] ---------------------------
 -- Button config.
 -- For each button ID:
 -- If there's an "enabled" function, we call that to see if button is
 -- enabled or not.
 -- If there's t/f text, the button may change its text:
 --    If there's a "useTrueText" function, we call that to see if we should use the "t" text.
 --    If there's a panelId, use the "t" text if panel is visible.
 local bottomButtonConfigsByButtonId = {
    [setupButtonId] = {
        isEnabled = function()
            debugPrint("ButtonConfiguration", "Doug: setupButtonId: isEnabled")
            local appState = getPrivateState("appState")
            debugPrint("ButtonConfiguration", "Doug: setupButtonId: appState = ", appState)
            return appState == appStates.CreatedSourceDecks
        end,
    },
    [cleanupButtonId] = {
        isEnabled = function()
            local appState = getPrivateState("appState")
            return appState == appStates.GameRunning
        end,
    },
    [toggleBiddingOpenButtonId] = {
        isEnabled = function()
            local appState = getPrivateState("appState")
            return appState == appStates.GameRunning
        end,
        t = "Close Bidding",
        f = "Open Bidding",
        buttonTextConditionFunction = function()
            local bio = getPrivateState("biddingIsOpen")
            return bio
        end,
    },
    [toggleBidsPanelButtonId] = {
        isEnabled = function()
            -- Not allowed if bidding is open.
            local bio = getPrivateState("biddingIsOpen")
            if bio then
                return false
            end
            local appState = getPrivateState("appState")
            return appState == appStates.GameRunning
        end,
        t = "Hide Bids",
        f = "Show Bids",
        panelId = bidViewPanelId,
    },
    [toggleFinalTallyPanelButtonId] = {
        isEnabled = function()
            local appState = getPrivateState("appState")
            return appState == appStates.GameRunning
        end,
        t = "Hide Scoring",
        f = "Show Scoring",
        panelId = finalTallyPanelId,
    },
}

 -- Interpretation:
 -- This button has two possible text values, "true" and "false".
 -- If there's a buttonTextConditionFunction, run the function:
 -- use "t" text if function returns true.
 -- If there's a panelId, use the "t" text if the panel is active.
 local buttonTextVariantsByButtonId = {
    [toggleBiddingOpenButtonId] = {
        t = "Close Bidding",
        f = "Open Bidding",
        buttonTextConditionFunction = function()
            local bio = getPrivateState("biddingIsOpen")
            return bio
        end,
    },
    [toggleBidsPanelButtonId] = {
        t = "Hide Bids",
        f = "Show Bids",
        panelId = bidViewPanelId,
    },
    [toggleFinalTallyPanelButtonId] = {
        t = "Hide Scoring",
        f = "Show Scoring",
        panelId = finalTallyPanelId,
    },
}

local function getBottomButtonRgb(buttonId)
    return {
        r = 1,
        g = 1,
        b = 1,
    }
end

-- Decide what the button's text should be based on current state and
-- set text accordingly.
-- State is digested into "condition".
-- If "condition" is true we use the 't' variant, else the 'f'.
-- WE SHOULD ONLY LOOK AT STATE TO DETERMINE TEXT, not other UI truths.
local function updateButtonText(buttonId)
    debugPrint("ButtonConfiguration", "Doug: updateButtonText: buttonId = ", buttonId, " buttonEnabled = ", buttonEnabled)
    local buttonTextVariants = buttonTextVariantsByButtonId[buttonId]

    -- Not all buttons have varying text.
    if not buttonTextVariants then
        return
        debugPrint("ButtonConfiguration", "Doug: updateButtonText: 001")
    end

    local useTrueText = false
    -- If there's a condition function, use that.
    if buttonTextVariants.buttonTextConditionFunction then
        useTrueText = buttonTextVariants.buttonTextConditionFunction()
        debugPrint("ButtonConfiguration", "Doug: updateButtonText: 002 finalCondition = ", useTrueText)
    elseif buttonTextVariants.panelId then
        -- If panel is open, use the true text.
        local useTrueText = UI.getAttribute(buttonTextVariants.panelId, "active")
    end

    if useTrueText then
        UI.setAttribute(buttonId, "text", buttonTextVariants.t)
    else
        UI.setAttribute(buttonId, "text", buttonTextVariants.f)
    end
end

local function isBottomButtonEnabled(buttonId)
    -- Just ask the config beast.
    local buttonConfig = bottomButtonConfigsByButtonId[buttonId]
    assert(buttonConfig, "Missing buttonConfig for buttonId = " .. buttonId)
    assert(buttonConfig.isEnabled, "Missing buttonConfig.isEnabled for buttonId = " .. buttonId)
    return buttonConfig.isEnabled()
end

-- Changes the color, adds/removes an on-click function.
local function setBottomButtonEnabled(buttonId, enabled)
    local buttonRgb = getBottomButtonRgb(buttonId)
    local color
    if enabled then
        color = "rgb(" .. buttonRgb.r .. "," ..  buttonRgb.g .. "," ..  buttonRgb.b .. ")"
    else
        color = "rgba(" ..  buttonRgb.r .. "," ..  buttonRgb.g .. "," ..  buttonRgb.b .. ", " .. disabledButtonAlpha .. ")"
    end
    UI.setAttribute(buttonId, "color",  color)
end

--[[--------------------------

Functions
UI functions to create a score sheet:
-- Top row is just title, whatever is passed in".
-- Second row has a label cell "Player Name", then one cell for each player, containing player name.
-- Nth row after that: label cell saying what kind of points these are, then an input cell for each player so you
-- can record their points in this category.
-- Final row has label "Total", then a cell for the sum of all the points categories for each player.
--
-- So in a game with Tom, Dick, and Harry, where you can get get points for kills and money and lose points
-- for waste, the table would be:
--
--             Kill-Fest: final scores
-- PlayerName     Tom      Dick     Harry
-- Kills          10       3        9
-- Money          2        13       0
-- Waste          -3       -4       -5
-- Total          9        12       4
--
]] ---------------------------

 -- We have an element in a cell, cell is in table in panel.
 -- That element has info about a certain player.
 -- The element has id:
 -- <prefix>_<rowNumber>_<columnNumber>
 -- Where row and column say where the cell is in table.
--
 -- There's even more info packed into the prefix: <panelPrefix>.<playerColor>.<valueDescriptor>
 -- * panelPrefix indicates the panel.
 -- * playerColor is the color of player in question.
 -- * valueDescriptor describes what type of data within the panel we are dealing with.
 --
 -- Examples:
 -- A panel where a player can enter a low and a high bid: the cell prefix might be:
 --   BidPanel.White.LowBid
 -- Or a score sheet where we are recording the number of points a player gained from
 -- gold: the cell prefix might be
 --   ScorePanel.White.GoldPoints
local function makeCellElementIdPrefx(panelPrefix, playerColor, valueDescriptor)
    return panelPrefix .. "." .. playerColor .. "." .. valueDescriptor
end

-- Inverse of the above, pick it into constituent parts.
local function splitCellElementIdPrefix(cellElementIdPrefix)
    local pieces = mysplit(cellElementIdPrefix, ".")
    local panelPrefix = pieces[1]
    local playerColor = pieces[2]
    local valueDescriptor = pieces[3]
    return panelPrefix, playerColor, valueDescriptor
end

-- Make a row in a table that holds the title of the table.
-- Note that this row contains just one cell that spans all columns.
local function makeTitleRow(numColumns, rowIndex, title)
    local xmlRow = makeXmlRow(rowIndex, "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color  = finalTallyTitleRowColor,
        preferredHeight = tostring(tableTitleRowHeight),
    })

    -- It's one very wide label cell.
    local xmlLabelCell = makeXmlTextCell(rowIndex, 1, title, "LabelCell", "LabelText")
    safeAddToXmlAttributes(xmlLabelCell, {
        columnSpan = tostring(numColumns),
    })

    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    return xmlRow
end

-- Make a row in a table.
-- Label: "Player Name".
-- Other cells: name of one of the players.
local function makePlayerRow(rowIndex, seatedPlayerObjects)
    local xmlRow = makeXmlRow(rowIndex, "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color = finalTallyPlayerRowColor,
    })

    -- Label cell.
    local xmlLabelCell = makeXmlTextCell(rowIndex, 1, "Player Name", "LabelCell", "LabelText")
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    -- One cell for each player: fill with player name.
    for columnIndex, seatedPlayer in pairs(seatedPlayerObjects) do
        local xmlPlayerNameCell = makeXmlTextCell(rowIndex, columnIndex + 1, seatedPlayer.steam_name, "HeaderCell", "HeaderText")
        safeAddToXmlChildren(xmlRow, xmlPlayerNameCell)
    end
    return xmlRow
end

-- Make a row in a table.
-- This row holds one input field for each player.
-- First cell: <some arbitrary label>.
-- Other cells: input fields.
local function makeNthInputRow(rowIndex, inputIndex, rowLabel, seatedPlayerObjects)
    local rowColor
    if rowIndex % 2 == 0 then
        rowColor = evenRowColor
    else
        rowColor = oddRowColor
    end
    local xmlRow = makeXmlRow(rowIndex, "InputRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color=rowColor,
    })

    -- Label cell.
    local columnIndex = 1
    local xmlLabelCell = makeXmlTextCell(rowIndex, columnIndex, rowLabel, "LabelCell", "LabelText")
    columnIndex = columnIndex + 1
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    local scoreInputCellName = scoreInputCellNames[inputIndex]
    -- One cell for each player: fill with input widget.
    for _, seatedPlayerObject in pairs(seatedPlayerObjects) do
        local scoreForCellNumber = getTypedScoreByPlayerColor(seatedPlayerObject.color, scoreInputCellName)
        local inputIdPrefix = makeCellElementIdPrefx("ScoreInput", seatedPlayerObject.color, scoreInputCellName)
        local xmlInputCell = makeXmlInputCell(inputIdPrefix, rowIndex, columnIndex, tostring(scoreForCellNumber), "onScoreInputCellUpdated")
        columnIndex = columnIndex + 1
        safeAddToXmlChildren(xmlRow, xmlInputCell)
    end
    return xmlRow
end

-- Make a row in a table.
-- This row holds a sum of all the input fields in the column above.
-- First cell: "Total".
-- Other cells: total score, one per player.
local function makeSumRow(rowIndex, seatedPlayerObjects)
    local xmlRow = makeXmlRow(rowIndex, "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color  = finalTallySumRowColor,
    })

    -- Label cell.
    local columnIndex = 1
    local xmlLabelCell = makeXmlTextCell(rowIndex, columnIndex, "Total", "LabelCell", "LabelText")
    columnIndex = columnIndex + 1
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    -- One cell for each player: fill with zeros.
    for _, seatedPlayerObject in pairs(seatedPlayerObjects) do
        local scoreForPlayer = getTotalScoreForPlayer(seatedPlayerObject.color)
        local xmlSumCell = makeXmlTextCell(rowIndex, columnIndex, tostring(scoreForPlayer), "SumCell", "SumText")
        columnIndex = columnIndex + 1
        safeAddToXmlChildren(xmlRow, xmlSumCell)
    end
    return xmlRow
end

-- Find the XML bit for the final tally panel.
-- It's just a stub in the XML file.
-- Fill it in.
-- Note it returns the final/updated XML.
local function fillInFinalTallyPanel(currentXml)
    local panel = findXmlNodeWithID(currentXml, finalTallyPanelId)

    -- Remove any existing kids.
    removeXmlChildren(panel)

    local seatedPlayerObjects = getSeatedPlayerObjects()
    local numSeatedPlayerObjects = #seatedPlayerObjects

    local panelWidth = tableLabelCellWidth + tableContentCellWidth * numSeatedPlayerObjects
    local panelHeight = tableTitleRowHeight + tableStandardRowHeight * (#scoreInputCellNames + 2)

    safeAddToXmlAttributes(panel, {
        height = tostring(panelHeight),
        width = tostring(panelWidth),
        offsetXY = tostring(finalTallyPanelStartXPos) .. " " .. tostring(finalTallyPanelStartYPos),
    })

    -- Column widths: width of label column then one std width for each player.
    local columnWidths = tostring(tableLabelCellWidth)
    for _ = 1, numSeatedPlayerObjects do
        columnWidths = columnWidths .. " " .. tostring(tableContentCellWidth)
    end

    local xmlTableLayout = makeXmlNode("TableLayout", {
        class = "TableLayoutClass",
        id = "FinalTallyTableLayout",
        columnWidths = columnWidths,
        ignoreLayout="true",
    })
    safeAddToXmlChildren(panel, xmlTableLayout)

    local numColumns = numSeatedPlayerObjects + 1
    local rowIndex = 1
    local xmlRow = makeTitleRow(numColumns, rowIndex, "Score Sheet")
    rowIndex = rowIndex + 1
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    xmlRow = makePlayerRow(rowIndex, seatedPlayerObjects)
    rowIndex = rowIndex + 1
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    for scoreInputCellIndex, scoreInputCellName in pairs(scoreInputCellNames) do
        xmlRow = makeNthInputRow(rowIndex, scoreInputCellIndex, scoreInputCellName, seatedPlayerObjects)
        rowIndex = rowIndex + 1
        safeAddToXmlChildren(xmlTableLayout, xmlRow)
    end

    xmlRow = makeSumRow(rowIndex, seatedPlayerObjects)

    -- Remember this row index.
    finalTallySumRowIndex = rowIndex
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    return currentXml
end

--[[--------------------------

Functions
Storing and retrieving bid defails.

]] ---------------------------
local function getBidDetailByPlayerColor(playerColor, bidDetailType)
    local bdbpc = getPrivateState("bidDetailsByPlayerColor")

    if not bdbpc then
        return 0
    end

    if not bdbpc[playerColor] then
        return 0
    end

    if not bdbpc[playerColor][bidDetailType] then
        return 0
    end

    return bdbpc[playerColor][bidDetailType]
end

local function setBidDetailByPlayerColor(playerColor, bidDetailType, number)
    local bdbpc = getPrivateState("bidDetailsByPlayerColor")
    if bdbpc[playerColor] == nil then
        bdbpc[playerColor] = {}
    end
    bdbpc[playerColor][bidDetailType] = number

    setPrivateState({bidDetailsByPlayerColor = bdbpc})
end

local function cleanupBidDetailsForPlayer(playerColor)
    local bdbpc = getPrivateState("bidDetailsByPlayerColor")
    bdbpc[playerColor] = {}
    setPrivateState({bidDetailsByPlayerColor = bdbpc})
end

--[[--------------------------

Functions
Making the view-of-all-bids

]] ---------------------------
-- Make a row in a table.
-- Label: None
-- Other cells: one for each bid type.
local function makeBidTypeRow(rowIndex)
    local xmlRow = makeXmlRow(rowIndex, "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color = finalTallyPlayerRowColor,
    })

    -- Label cell.
    local columnIndex = 1
    local xmlLabelCell = makeXmlTextCell(rowIndex, 1, "", "LabelCell", "LabelText")
    columnIndex = columnIndex + 1
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    -- One cell for each bid type:
    for _, bidDetailType in pairs(bidDetailTypes) do
        local xmlPlayerNameCell = makeXmlTextCell(rowIndex, columnIndex, bidDetailType, "HeaderCell", "HeaderText")
        columnIndex = columnIndex + 1
        safeAddToXmlChildren(xmlRow, xmlPlayerNameCell)
    end
    return xmlRow
end

-- Row in a table with a label (player name) and that player's bid info.
local function makePlayerBidInfoRow(rowIndex, seatedPlayerObject)
    local rowColor
    if rowIndex % 2 == 0 then
        rowColor = evenRowColor
    else
        rowColor = oddRowColor
    end

    local xmlRow = makeXmlRow(rowIndex, "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color=rowColor,
    })

    -- Label cell.
    local columnIndex = 1
    local xmlLabelCell = makeXmlTextCell(rowIndex, columnIndex, seatedPlayerObject.steam_name, "LabelCell", "LabelText")
    columnIndex = columnIndex + 1
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    -- One cell for each player: fill with input widget.
    for _, bidDetailType in pairs(bidDetailTypes) do
        local bidDetail = getBidDetailByPlayerColor(seatedPlayerObject.color, bidDetailType)
        local xmlInputCell = makeXmlTextCell(rowIndex, columnIndex, tostring(bidDetail), "BidDetailCell", "BidDetailText")
        columnIndex = columnIndex + 1
        safeAddToXmlChildren(xmlRow, xmlInputCell)
    end
    return xmlRow
end

-- Find the XML bit for the "here's all the bids" panel.
-- It's just a stub in the XML file.
-- Fill it in.
-- Note it returns the final/updated XML.
local function fillInBidViewPanel(currentXml)
    local panel = findXmlNodeWithID(currentXml, bidViewPanelId)
    -- Remove any existing kids.
    removeXmlChildren(panel)

    local seatedPlayerObjects = getSeatedPlayerObjects()
    local numSeatedPlayerObjects = #seatedPlayerObjects

    local panelWidth = tableLabelCellWidth + tableContentCellWidth * #bidDetailTypes
    local panelHeight = tableTitleRowHeight + tableStandardRowHeight * (numSeatedPlayerObjects + 1)

    safeAddToXmlAttributes(panel, {
        height = tostring(panelHeight),
        width = tostring(panelWidth),
        offsetXY = tostring(bidViewPanelStartXPos) .. " " .. tostring(bidViewPanelStartYPos),
    })

    -- Column widths: width of label column then one std width for bid detail type.
    local columnWidths = tostring(tableLabelCellWidth)
    for _ = 1, #bidDetailTypes do
        columnWidths = columnWidths .. " " .. tostring(tableContentCellWidth)
    end

    local xmlTableLayout = makeXmlNode("TableLayout", {
        class = "TableLayoutClass",
        id = "BidViewTableLayout",
        columnWidths = columnWidths,
        ignoreLayout="true",
    })
    safeAddToXmlChildren(panel, xmlTableLayout)

    local numColumns = #bidDetailTypes + 1
    local rowIndex = 1
    local xmlRow = makeTitleRow(numColumns, rowIndex, "Player Bids")
    rowIndex = rowIndex + 1
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    xmlRow = makeBidTypeRow(rowIndex)
    rowIndex = rowIndex + 1
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    for _, seatedPlayerObject in pairs(seatedPlayerObjects) do
        xmlRow = makePlayerBidInfoRow(rowIndex, seatedPlayerObject)
        rowIndex = rowIndex + 1
        safeAddToXmlChildren(xmlTableLayout, xmlRow)
    end

    return currentXml
end

--[[--------------------------

Functions
Making the panels where players input bid info.
Note panels, plural: one for each player.
I am very confused/frustrated with how to make local UI work in this system.

]] ---------------------------
local function makeBidInputPanelIdForPlayer(color)
    return bidInputPanelIdPrefix .. color
end

local function makeBidInputRow(rowIndex, seatedPlayerObject)
    local xmlRow = makeXmlRow(rowIndex, "InputRowClass")

    -- One cell for each bid detail type.
    local columnIndex = 1
    for _, bidDetailType in pairs(bidDetailTypes) do
        local bidForCell = getBidDetailByPlayerColor(seatedPlayerObject.color, bidDetailType)
        local inputIdPrefix = makeCellElementIdPrefx("BidInput", seatedPlayerObject.color, bidDetailType)
        local xmlInputCell = makeXmlInputCell(inputIdPrefix, rowIndex, columnIndex, tostring(bidForCell), "onBidInputCellUpdated")
        columnIndex = columnIndex + 1
        safeAddToXmlChildren(xmlRow, xmlInputCell)
    end
    return xmlRow
end

-- Find the XML bit for the "player X can input his bid" panel.
-- It's just a stub in the XML file.
-- Fill it in.
-- Note it returns the final/updated XML.
local function fillInBidInputPanelForPlayer(currentXml, seatedPlayerObject)
    local panelId = makeBidInputPanelIdForPlayer(seatedPlayerObject.color)

    -- Keep track of this.
    allPanelIdsSet[panelId] = true

    -- Get the panel with this id.
    local panel = findXmlNodeWithID(currentXml, bidViewPanelId)
    -- Remove any existing kids.
    removeXmlChildren(panel)

    local panelWidth = tableLabelCellWidth + tableContentCellWidth * #bidDetailTypes
    local panelHeight = tableTitleRowHeight + tableStandardRowHeight * 2

    safeAddToXmlAttributes(panel, {
        height = tostring(panelHeight),
        width = tostring(panelWidth),
        offsetXY = tostring(bidInputPanelStartXPos) .. " " .. tostring(bidInputPanelStartYPos),
        -- visible only to this player.
        visibility = seatedPlayerObject.color,
    })

    -- Column widths: width of label column then one std width bid detail type.
    local columnWidths = tostring(tableLabelCellWidth)
    for _ = 1, #bidDetailTypes do
        columnWidths = columnWidths .. " " .. tostring(tableContentCellWidth)
    end

    local xmlTableLayout = makeXmlNode("TableLayout", {
        class = "TableLayoutClass",
        id = "BidInputTableLayout",
        columnWidths = columnWidths,
        ignoreLayout="true",
    })
    safeAddToXmlChildren(panel, xmlTableLayout)

    local numColumns = #bidDetailTypes
    local rowIndex = 1
    local xmlRow = makeTitleRow(numColumns, rowIndex, seatedPlayerObject.steam_name .. ": Input your bid")
    rowIndex = rowIndex + 1
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    xmlRow = makeBidTypeRow(rowIndex)
    rowIndex = rowIndex + 1
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    xmlRow = makeBidInputRow(rowIndex, seatedPlayerObject)
    rowIndex = rowIndex + 1
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    return currentXml
end

--[[--------------------------

Functions
Create the game deck.
Flip and shuffle it.

]] ---------------------------
-- Given the number of players and the card decks are using this game, get array of
-- {sourceDeck, numCards} pairs describing all the cards we will be using to build
-- the main game deck.
local function getSourceDecksWithNumCards()
    -- Count the players.
    local playerCount = getSeatedPlayerCount()

    -- Use that to index into table: how many for each type of card.
    local cardDistribution = cardDistributionByNumPlayers[playerCount]

    -- Make the cards.
    local sourceDecksWithNumCards = {}
    for cardType, numCards in pairs(cardDistribution) do
        local sourceDeckGUID = cardTypeToSourceDeckGUID[cardType]
        local sourceDeck = getObjectFromGUID(sourceDeckGUID)

        local sourceDeckWithNumCards = {
            sourceDeck = sourceDeck,
            numCards = numCards,
        }
        table.insert(sourceDecksWithNumCards, sourceDeckWithNumCards)
    end
    return sourceDecksWithNumCards
end

-- We have build the main game deck.  Cleanup any mess, find the main deck, and pass it back
-- thru the callback.
local function cleanupClonesAndPassBackGameDeck(onGameDeckPrepped)
    -- First, nuke all the cloned decks.
    local cloneDecks = getObjectsWithTag(cloneTag)
    for _, cloneDeck in pairs(cloneDecks) do
        cloneDeck.destruct()
    end

    -- Find the game deck we created, pass it through the final callback.
    local decks = getObjectsWithTag(gameDeckTag)
    -- Should be exactly one.
    if #decks == 1 then
        local gameDeck = decks[1]
        onGameDeckPrepped(gameDeck)
    else
        print("Doug: Error, did not find exactly one gameDeck: got ", #decks)
        onGameDeckPrepped(nil)
    end
end

-- We have a description of a source deck and the number of cards we want to take from it.
-- We will:
-- 1. Clone the source deck (so we don't have to put cards back later).
-- 2. Grab cards from the clone and add to source deck.
-- Later, it will be the callers responsibility to destroy any clones created here.
local function cloneSourceDeckAndAddCardsToGameDeck(sourceDeckWithNumCards)
    local sourceDeck = sourceDeckWithNumCards.sourceDeck
    local numCards = sourceDeckWithNumCards.numCards

    if not sourceDeck then
        debugPrint("SourceDeckCreation", "Doug: cloneSourceDeckAndAddCardsToGameDeck: sourceDeck is missing, early out")
        return false
    end

    -- OK this is pretty weaksauce but here we are.
    -- If we take card from the actual source deck, we have to put them back when
    -- game is over, which is a headache.
    -- If source deck is not pre-existing, I have to clone a gang of cards each time we reset game,
    -- which makes irritating boop noise.
    -- So I clone the whole deck, pull cards from clone, and later (outside this function) destroy the clone.
    local cloneOfSourceDeck = sourceDeck.clone()
    local sourceDeckPosition = sourceDeck.getPosition()
    local cloneDeckPosition = sourceDeckPosition
    cloneDeckPosition.y = cloneDeckPosition.y + hiddenDeckYPos
    cloneOfSourceDeck.setPosition(cloneDeckPosition)

    -- Clarify tags.
    cloneOfSourceDeck.removeTag(sourceDeckTag)
    cloneOfSourceDeck.addTag(cloneTag)

    -- Grab this many cards from cloned deck.
    local takenObject
    if numCards == 1 then
        debugPrint("SourceDeckCreation", "Doug: cloneSourceDeckAndAddCardsToGameDeck: deck = ", cloneOfSourceDeck)
        local result = safeTakeFromDeck(cloneOfSourceDeck)
        takenObject = result.card
        cloneOfSourceDeck = result.deck
        debugPrint("SourceDeckCreation", "Doug: cloneSourceDeckAndAddCardsToGameDeck: takenObject = ", takenObject)
        debugPrint("SourceDeckCreation", "Doug: cloneSourceDeckAndAddCardsToGameDeck: cloneOfSourceDeck = ", cloneOfSourceDeck)

    else
        local splitDecks = cloneOfSourceDeck.cut(numCards)
        takenObject = splitDecks[2]
    end

    -- No longer a clone:, this is part of gameDeck.
    takenObject.removeTag(cloneTag)
    takenObject.addTag(gameDeckTag)
    -- Not locked...
    takenObject.setLock(false)
    -- Place well above the middle of table: it will drop onto any cards previously
    -- placed and join to add to new deck.
    takenObject.setPosition({0, 2, gameDeckZPos})
    takenObject.setRotation({0, 180, 0})
    return true
end

-- We have a description of which source decks we are using and how many from each deck to build
-- the game deck.
local function recursiveGetCardsFromNextSourceDeck(sourceDecksWithNumCards, sourceDeckIndex, onGameDeckPrepped)
    -- Handle the end case: we are done.
    if sourceDeckIndex > #sourceDecksWithNumCards then
        Wait.time(function()
            cleanupClonesAndPassBackGameDeck(onGameDeckPrepped)
        end, standardWaitSec)
        return
    end

    local sourceDeckWithNumCards = sourceDecksWithNumCards[sourceDeckIndex]
    cloneSourceDeckAndAddCardsToGameDeck(sourceDeckWithNumCards)
    -- That source deck is resolved: increment.
    sourceDeckIndex = sourceDeckIndex + 1
    -- Wait a bit and repeat for the next deck.
    Wait.time(function()
        recursiveGetCardsFromNextSourceDeck(sourceDecksWithNumCards, sourceDeckIndex, onGameDeckPrepped)
    end, waitAfterCardCloneSec)
end

local function flipAndShuffleDeck(gameDeck, onFlippedAndShuffled)
    -- Flip the deck
    Wait.time(function()
        gameDeck.flip()
        gameDeck.randomize()
        onFlippedAndShuffled()
    end, waitAfterDeckShuffleSec)
end

local function createFlipAndShuffleGameDeck(onGameDeckPrepped)
    -- Only valid to move here from SetupRunning state.
    local appState = getPrivateState("appState")
    if appState ~= appStates.SetupRunning then
        assert(false, "Invalid state transition in createGameDeckAndDealSeasons from " .. appState)
        return 1
    end

    local sourceDecksWithNumCards = getSourceDecksWithNumCards()
    gameDeckGUID = nil
    recursiveGetCardsFromNextSourceDeck(sourceDecksWithNumCards, 1, function(gameDeck)
        assert(gameDeck, "finalGameDeckChecksAndTwiddles: gameDeck is nil")
        if not gameDeck then
            return
        end

        -- Tweak some values...
        -- Update the name
        gameDeck.setName("GameDeck")
        -- Remember some values...
        gameDeckGUID = gameDeck.getGUID()
        numCardsInGameDeck = gameDeck.getQuantity()

        -- Flip and shuffle.
        flipAndShuffleDeck(gameDeck, function()
            onGameDeckPrepped(gameDeck)
        end)
    end)
end

--[[--------------------------

Functions
Generic util for drawing cards from a deck and laying them out in a line.

]] ---------------------------
-- Place next card from given deck.
local function placeCardWhichMayChangeDeck(deck, layoutDetails, cardPlacement, onCardPlaced, opt_options)
    debugPrint("SourceDeckCreation", "Doug: placeCardWhichMayChangeDeck: deck = ", deck)

    local options = opt_options or {}

    local flip
    if hideLastCard and cardPlacement.columnIndex == 1 then
        flip = false
    else
        flip = true
    end
    debugPrint("GameDeckPlacement", "Doug: placeCardWhichMayChangeDeck: flip = ", flip)

    local result = safeTakeFromDeck(deck)

    local updatedDeck = result.deck
    local card = result.card
    debugPrint("SourceDeckCreation", "Doug: placeCardWhichMayChangeDeck: card = ", card)
    debugPrint("SourceDeckCreation", "Doug: placeCardWhichMayChangeDeck: updatedDeck = ", updatedDeck)
    if options.cardTwiddleCallback then
        options.cardTwiddleCallback(card, cardPlacement.columnIndex)
    else
        card.addTag("dealtCard")
    end

    -- Where do we want card to move to, and what rotation?
    -- A bit of trickery here.
    -- If we lay cards out left to right, in order, the nth card is hidden under N+1 card.  Only last card is fully visible.
    -- Nicer to have the first card fully visible.
    -- So when "columnIndex" is 1, we are actually going to go right to left instead of left to
    -- right, so that the last card placed is on the far left and fully visible.
    -- Normally the first card has columnIndex 1 and the last has columnIndex cardsThisRow.
    -- We need to rejigger that.
    -- Also: we want the cards to layer nicely so as column index does up we give a little pop to
    -- the y value.
    local mockColumnIndex = layoutDetails.cardsThisRow - cardPlacement.columnIndex + 1
    local xPos = -cardRowWidth/2 + (cardRowWidth / (layoutDetails.cardsThisRow - 1)) * (mockColumnIndex-1)
    local yPos = dealtCardBaseYPos + (cardPlacement.columnIndex - 1) * dealtCardDeltaYPos
    local zPos = ((layoutDetails.numRows-1)/2 * cardColumnHeight) - (cardColumnHeight * (cardPlacement.rowIndex-1))

    local pos = Vector(xPos, yPos, zPos)

    local zRot = 180
    if flip then
        zRot = 0
    end
    local rot = Vector(0, 180, zRot)

    runAfterWaitThenCallback(waitAfterDealtCardFlipSec, function()
        card.setRotation(rot)
        card.setPosition(pos)
    end, function()
        onCardPlaced(updatedDeck)
    end)
end

-- Recursive step to lay out the next card.
-- Indices are one-based.
local function recursivePlaceNextCard(deck, layoutDetails, cardPlacement, onAllCardsPlaced, opt_options)
    debugPrint("SourceDeckCreation", "Doug: recursivePlaceNextCard: deck = ", deck)
    -- Exit case.
    if cardPlacement.columnIndex > layoutDetails.cardsThisRow then
        onAllCardsPlaced(deck)
        return
    end

    local function onCardPlaced(updatedDeck)
        -- Wait a bit then deal the next card.
        Wait.time(function()
            cardPlacement.columnIndex = cardPlacement.columnIndex + 1
            recursivePlaceNextCard(updatedDeck, layoutDetails, cardPlacement, onAllCardsPlaced, opt_options)
        end, waitAfterDealtCardMoveSec)
    end

    placeCardWhichMayChangeDeck(deck, layoutDetails, cardPlacement, onCardPlaced, opt_options)
end

--[[--------------------------

Functions
Deal all the seasons from the game deck.

]] ---------------------------
local function placeCardsForSeason(deck, seasonIndex, callback)
    debugPrint("GameDeckPlacement", "placeCardsForSeason seasonIndex = ", seasonIndex)
    -- How many to deal?
    local cardsThisSeason = math.floor(numCardsInGameDeck / numSeasons)

    if variableSeasonLength then
        local playerCount = getSeatedPlayerCount()
        if seasonIndex == 1 then
            cardsThisSeason = cardsThisSeason - playerCount
        elseif seasonIndex == numSeasons then
            cardsThisSeason = cardsThisSeason + playerCount
        end
    end
    debugPrint("GameDeckPlacement", "placeCardsForSeason cardsThisSeason = ", cardsThisSeason)

    if not deck then
        callback(deck)
        return
    end

    local layoutDetails = {
        numRows = numSeasons,
        cardsThisRow = cardsThisSeason,
    }
    local cardPlacement = {
        rowIndex = seasonIndex,
        columnIndex = 1,
    }
    recursivePlaceNextCard(deck, layoutDetails, cardPlacement, callback)
end

local function recursivePlaceCardsForSeason(gameDeck, seasonIndex, onAllGameDeckCardsDealt)
    -- Handle the end case: we are done.
    if seasonIndex > numSeasons then
        onAllGameDeckCardsDealt(gameDeck)
        return
    end

    -- Deal the cards for this season.
    placeCardsForSeason(gameDeck, seasonIndex, function(updatedDeck)
        -- Wait a bit and repeat for the next season.
        Wait.time(function()
            -- That season is resolved: increment.
            seasonIndex = seasonIndex + 1
            recursivePlaceCardsForSeason(updatedDeck, seasonIndex, onAllGameDeckCardsDealt)
        end, waitAfterDealtCardMoveSec)
    end)
end

-- Called once all game deck cards are dealt: setup is now done.
local function onAllGameDeckCardsDealt()
    -- Game is now all set up, ready to play.
    setPrivateState({appState = appStates.GameRunning})
end

local function dealAllSeasons(gameDeck)
    recursivePlaceCardsForSeason(gameDeck, 1, onAllGameDeckCardsDealt)
end

--[[--------------------------

Functions
onLoad helpers.

]] ---------------------------
local function fillInCardDistributionByNumPlayers()
    for i = 1, maxPlayers do
        if not cardDistributionByNumPlayers[i] then
            cardDistributionByNumPlayers[i] = {}
        end
        cardDistributionByNumPlayers[i][cardTypes.doll] = 6 * i + 1
        cardDistributionByNumPlayers[i][cardTypes.kite] = math.ceil(4.5 * i) + 1
        cardDistributionByNumPlayers[i][cardTypes.robot] = 3 * i + 1

        cardDistributionByNumPlayers[i][cardTypes.radio] = 2 * i + 2

        cardDistributionByNumPlayers[i][cardTypes.poop] = math.floor(i/2)
        cardDistributionByNumPlayers[i][cardTypes.wrapping] = math.floor(i/2)
        cardDistributionByNumPlayers[i][cardTypes.magic] = math.floor(i/2)
        cardDistributionByNumPlayers[i][cardTypes.broom] = math.floor(i/2)
    end
end

local function setMaxCardCount()
    for i  = 1, maxPlayers do
        local cardDistribution = cardDistributionByNumPlayers[i]
        for _, count in pairs(cardDistribution) do
            if count > maxCardCount then
                maxCardCount = count
            end
        end
    end
end

local function configureBottomButtonLayout()
    -- Set bottom button table attributes.
    local rowWidth = maxBottomButtonsPerRow * bottomButtonWidth + (maxBottomButtonsPerRow - 1) * bottomButtonSpacing
    local tableHeight = (bottomButtonHeight + bottomButtonSpacing) * 2
    UI.setAttributes(bottomButtonPanelId, {
        width = tostring(rowWidth),
        height = tostring(tableHeight),
    })

    -- Set bottom button table layout attributes.
    UI.setAttributes(bottomButtonTableLayoutId, {
        width = tostring(rowWidth),
        height = tostring(tableHeight),
        cellSpacing = tostring(bottomButtonSpacing),
    })

    -- Set bottom button row attributes.
    for _, rowId in pairs(bottomRowIds) do
        UI.setAttributes(rowId, {
            preferredHeight = tostring(bottomButtonHeight),
            preferredWidth = tostring(rowWidth),
        })
    end

    -- Set all the bottom button attributes.
    for _, buttonId in pairs(bottomButtonIds) do
        UI.setAttributes(buttonId, {
            width = tostring(bottomButtonWidth),
            height = tostring(bottomButtonHeight),
        })
    end
end

local function fillInCardTypeToSourceDeckGUID()
    cardTypeToSourceDeckGUID = {}
    local sourceDecks = getObjectsWithTag(sourceDeckTag)
    if not sourceDecks then
        debugPrint("SourceDeckCreation", "Doug: fillInCardTypeToSourceDeckGUID: sourceDecks is nil")
        return
    end
    if #sourceDecks == 0 then
        debugPrint("SourceDeckCreation", "Doug: fillInCardTypeToSourceDeckGUID: sourceDecks is empty")
        return
    end
    for _, cardType in pairs(cardTypes) do
        for _, sourceDeck in pairs(sourceDecks) do
            if sourceDeck.getName() == cardType then
                cardTypeToSourceDeckGUID[cardType] = sourceDeck.getGUID()
            end
        end
    end
end

local function confirmCardNames()
    for cardType, sourceDeckGUID in pairs(cardTypeToSourceDeckGUID) do
        local sourceDeck = getObjectFromGUID(sourceDeckGUID)
        local expectCardName = cardType
        local objects = sourceDeck.getObjects()
        for _, card in pairs(objects) do
            assert(card.name == expectCardName,
                "Doug: Error, card name mismatch: got " .. card.name .. " expected " .. expectCardName)
        end
    end
end

local function maybeMakeSourceDecksFromImportedDeck(onSourceDecksCreated)
    debugPrint("SourceDeckCreation", "Doug: maybeMakeSourceDecksFromImportedDeck")
    -- If source decks already exist, we are done.
    local sourceDecks = getObjectsWithTag(sourceDeckTag)
    if sourceDecks and #sourceDecks > 0 then
        debugPrint("SourceDeckCreation", "Doug: maybeMakeSourceDecksFromImportedDeck: source decks already exist.")
        onSourceDecksCreated()
        return
    end

    local importedDeck = getImportedDeck()
    if not importedDeck then
        debugPrint("SourceDeckCreation", "Doug: maybeMakeSourceDecksFromImportedDeck: no imported deck.")
        return
    end
    local importedCardCount = importedDeck.getQuantity()

    local function onAllImportedDeckCardsPlaced(_)
        debugPrint("SourceDeckCreation", "Doug: onAllImportedDeckCardsPlaced")
        Wait.time(function()
            -- All the cards are out.
            -- Make decks out of them.
            makeDecksFromImportedCards(onSourceDecksCreated)
        end, 1)
    end

    local function cardTwiddleCallback(importedCard, index)
        -- set tag on new card.
        importedCard.addTag(importedCardTag)
        importedCard.setName(orderedCardTypes[index])
    end

    -- place cards from imported deck.
    local layoutDetails = {
        numRows = 1,
        cardsThisRow = importedCardCount,
    }
    local cardPlacement = {
        rowIndex = 1,
        columnIndex = 1,
    }

    debugPrint("SourceDeckCreation", "Doug: maybeMakeSourceDecksFromImportedDeck callling recursivePlaceNextCard")
    recursivePlaceNextCard(importedDeck, layoutDetails, cardPlacement, onAllImportedDeckCardsPlaced, {
        cardTwiddleCallback = cardTwiddleCallback,
    })
end

--[[
Functions for creating the source deck
]]
local function getImportedDeck()
    local importedDecks = getObjectsWithTag(importedDeckTag)
    if #importedDecks > 1 then
        print("Error, expected 1 imported deck. got ", #importedDecks)
        return nil
    end
    if #importedDecks == 1 then
        return importedDecks[1]
    end
    return nil
end

local function makeDecksFromImportedCards(onSourceDecksCreated)
    local importedCards = getObjectsWithTag(importedCardTag)

    for _, importedCard in pairs(importedCards) do
        local cardType = importedCard.getName()
        importedCard.setName(cardType)
        importedCard.addTag(sourceCardTag)
        importedCard.removeTag(importedCardTag)

        importedCard.setName(cardType)

        local clonedCardPos = importedCard.getPosition()
        clonedCardPos.y = clonedCardPos.y + 1

        for _ = 1, maxCardCount-1 do
            local clonedCard = importedCard.clone()
            clonedCard.setName(cardType)
            clonedCard.setPosition(clonedCardPos)
            clonedCard.addTag(sourceCardTag)
            clonedCard.removeTag(importedCardTag)
        end
    end

    onSourceDecksCreated()
end

--[[--------------------------

Functions
Top level for building and updating XML.

]] ---------------------------
-- Toggle panel on/off.
-- Return true iff panel is visible.
local function togglePanelVisibility(panelId)
    local panelActive = UI.getAttribute(panelId, "active")
    if panelActive == "true" then
        UI.hide(panelId)
        return false
    else
        UI.show(panelId)
        return true
    end
end

-- Toggle panel on/off.
-- Update button depending on whether toggle is on or off.
-- Return true iff panel is visible.
local function togglePanelVisibilityWithButtonNameUpdate(panelId, buttonId)
    local isVisible = togglePanelVisibility(panelId)
    debugPrint("BidInputPanel", "Doug: togglePanelVisibilityWithButtonNameUpdate: panelId = ", panelId, " isVisible = ", isVisible)
    updateButtonText(buttonId)
    return isVisible
end

--[[--------------------------

Functions
Called by state machine when state changes.

]] ---------------------------
-- Look at rodux state.
-- From that determine whether thsis button should be enabled or not.
-- Set the button enabled state.
-- Update the text accordingly.
local function updateBottomButtonBasedOnState(buttonId)
    debugPrint("ButtonConfiguration", "Doug: updateBottomButtonBasedOnState: buttonId = ", buttonId)

    -- Enable or disable the button.
    local buttonEnabled = isBottomButtonEnabled(buttonId)
    debugPrint("ButtonConfiguration", "Doug: updateBottomButtonBasedOnState: buttonEnabled = ", buttonEnabled)
    setBottomButtonEnabled(buttonId, buttonEnabled)

    -- Make sure text is up to date too.
    updateButtonText(buttonId)
end

-- We have some panel.
-- Check rodux state to see if it should be forced to invisible.
-- If should be invisible, make it so.
local function updatePanelVisibility(panelId)
    debugPrint("PanelVisibility", "Doug: updatePanelVisibility: panelId = ", panelId)
    local currentXML = UI.GetXmlTable()

    debugPrint("PanelVisibility", "Doug: currentXML = ")

    local panel = findXmlNodeWithID(currentXML, panelId)
    -- This should exist.
    assert(panel ~= nil, "Panel missing: panelId = " .. panelId)

    -- If we are not running, any panel should be hidden.
    local appState = getPrivateState("appState")
    if not appState ~= appStates.GameRunning then
        debugPrint("PanelVisibility", "Doug: not running: panel is invisible")
        UI.hide(panelId)
        return
    end

    -- If bidding open, you can't see bid view panel.
    -- Also, all bid input panels are visible.
    local bio = getPrivateState("biddingIsOpen")
    if bio then
        if panelId == bidViewPanelId then
            debugPrint("PanelVisibility", "Doug: bidding open: bidViewPanelId invisible")
            UI.hide(panelId)
        elseif string.find(panelId, bidInputPanelIdPrefix) then
            debugPrint("PanelVisibility", "Doug: bidding open: bidInputPanel visible: " .. panelId)
            UI.show(panelId)
        end
    else
        -- If bidding is not open you can't see bid input panels.
        if string.find(panelId, bidInputPanelIdPrefix) then
            debugPrint("PanelVisibility", "Doug: bidding closed: bidInputPanel invisible: " .. panelId)
            UI.hide(panelId)
        end
    end
end

-- State has changed.
-- If any derived state should change as a result, get that and send it back.
local function updateDerivedState(state)
    -- Handle any cases of "if state X changes then state Y must also change".
    -- If game is not running...
    if state["gameIsRunning"] == false then
        -- ...then bidding is not open.
        state["biddingIsOpen"] = false
    end
    return state
end

-- State has changed.
-- We may want to update the UI accordingly.
local function updateUIBasedOnCurrentState()
    debugPrint("ButtonConfiguration", "Doug: updateUIBasedOnCurrentState")
    -- State changes may force panels to show or hide.
    for panelId, _ in pairs(allPanelIdsSet) do
        updatePanelVisibility(panelId)
    end

    -- For each bottom button, we might need to change enabled state
    -- and/or text.
    -- We do this after a wait so that the panels open/closed can settle, since
    -- that may affect button text.
    Wait.time(function()
        for _, buttonId in pairs(bottomButtonIds) do
            updateBottomButtonBasedOnState(buttonId)
        end
    end, standardWaitSec)
end

--[[--------------------------

Functions
Helpers for setup and cleanup.

]] ---------------------------
-- Move the source card decks offscreen
local function hideSourceDecks()
    for _, deckGUID in pairs(cardTypeToSourceDeckGUID) do
        local sourceDeck = getObjectFromGUID(deckGUID)
        local position = sourceDeck.getPosition()
        position.y = hiddenDeckYPos
        sourceDeck.setPosition(position)
        sourceDeck.setLock(true)
    end
end

local function cleanupOldGame()
    -- Reset XML to pristine.
    debugPrint("XMLTableBuilding", "Doug: cleanupOldGame: resetting XML")
    UI.setXmlTable(pristineXml)

    -- Kill the game deck.  Kill any card that was dealt.
    if gameDeckGUID then
        local gameDeck = getObjectFromGUID(gameDeckGUID)
        gameDeck.destruct()
        gameDeckGUID = nil

        local dealtCards = getObjectsWithTag("dealtCard")
        for _, dealtCard in pairs(dealtCards) do
            dealtCard.destruct()
        end
    end

    -- Reset storage.
    local seatedPlayerObjects = getSeatedPlayerObjects()
    for _, seatedPlayerObject in pairs(seatedPlayerObjects) do
        cleanupTypedScoresForPlayer(seatedPlayerObject.color)
        cleanupBidDetailsForPlayer(seatedPlayerObject.color)
    end
end

local function createScriptingBasedUI()
   local currentXML = UI.GetXmlTable()
   local updatedXML

   -- Build the XML for the final tally panel.
   updatedXML = fillInFinalTallyPanel(currentXML)

   -- Build the XML for the view-all-bids panel.
   updatedXML = fillInBidViewPanel(updatedXML)

   -- One bid input panel per player.
   local seatedPlayerObjects = getSeatedPlayerObjects()
   for _, seatedPlayerObject in pairs(seatedPlayerObjects) do
       updatedXML = fillInBidInputPanelForPlayer(updatedXML, seatedPlayerObject)
   end

   -- Set the XML.
   debugPrint("XMLTableBuilding", "Doug: createScriptingBasedUI: setting XML")
   UI.setXmlTable(updatedXML)
end

--[[--------------------------

Functions
Called by system events.

]] ---------------------------
 -- The onLoad event is called after the game save finishes loading.
local function debugPrintTime(message)
    local time = os.date("%H:%M:%S")
    debugPrint("Timing", "Doug: " .. time .. ": " .. message)
end

 function onLoad()
    debugPrintTime("declaringValidStates")
    -- Init state.
    declareValidState("typedScoresByPlayerColor", {})
    declareValidState("bidDetailsByPlayerColor", {})
    declareValidState("creatingGameDeck", false)
    declareValidState("gameIsRunning", false)
    declareValidState("appState", appStates.Null)
    declareValidState("setupIsRunning", false)
    declareValidState("biddingIsOpen", false)

    debugPrintTime("adding state callbacks")
    -- Listen for changes to private state: call this to change dependent state.
    addStateChangedStateModCallback(updateDerivedState)

    -- Listen for changes to private state: call this for UI fallout.
    addStateChangedUIModCallback(updateUIBasedOnCurrentState)

    debugPrintTime("count stuff")
    -- Fill in some derived global tables/variables.
    fillInCardDistributionByNumPlayers()
    setMaxCardCount()

    -- Do I have too wait a second here for things to apply?
    Wait.time(function()
        debugPrintTime("getting XML")

        -- XML in file is pretty basic/useless.
        -- We have to fill in a lot of details:
        -- 1. Configure the bottom buttons.
        -- 2. Fill in the "I'm submitting my bid" panels.
        -- 3. Fill in the final tally panel.
        -- 4. Fill in the "here's the bids" panel.
        -- Item 1 can be done right away: buttons are always the same.
        -- The others all change based on number/color/name of players: we have
        -- to create those on startup.

        -- So:
        -- First we are going to make the buttons.
        configureBottomButtonLayout()

        -- Unfortunately it takes a bit for new XML to "settle".
        Wait.time(function()
            -- Now we cache a notion of "pristine" XML: at game end
            -- we reset to this.
            pristineXml = UI.GetXmlTable();

            -- Now we can update the UI based on current state.
            updateUIBasedOnCurrentState()

            debugPrintTime("making source decks")
            local function onSourceDecksCreated()
                debugPrintTime("source decks created.")
                Wait.time(function()
                    debugPrintTime("source decks created: waited.")
                    fillInCardTypeToSourceDeckGUID()
                    confirmCardNames()
                    debugPrint("StateMachine", "Doug: setting appState to CreatedSourceDecks")
                    setPrivateState({appState = appStates.CreatedSourceDecks})
                end, standardWaitSec)
            end

            -- FIXME(dbanks)
            -- Remove the if.
            if true then
                maybeMakeSourceDecksFromImportedDeck(onSourceDecksCreated)
            else
                onSourceDecksCreated()
            end

        end, standardWaitSec)
    end, standardWaitSec)
end

function onPlayerDisconnect(player)
    cleanupTypedScoresForPlayer(player.color)
    cleanupBidDetailsForPlayer(player.color)
end

function onObjectEnterContainer(container, object)
    -- If object has sourceCardTag, then make sure the container has the sourceDeckTag and same
    -- name.
    if object.hasTag(sourceCardTag) then
        if container.getName() == "" then
            container.setName(object.getName())
            container.setTags({sourceDeckTag})
        end
    end
end

--[[--------------------------

Functions
Called from global.xml

]] ---------------------------
--[[
Bottom button "onClick" handlers.
Note they all have to do some standard worrying about whether we really want to do this.
]]
function setup(clickedPlayer)
    if not isBottomButtonEnabled(setupButtonId) then
        return
    end

    local appState = getPrivateState("appState")
    if appState ~= appStates.CreatedSourceDecks then
        return
    end

    setPrivateState(
        {
            appState = appStates.SetupRunning,
        }, function()
            hideSourceDecks()

            -- Cleanup old spawns.
            cleanupOldGame()

            -- build all the code-driven XML.
            createScriptingBasedUI()

            Wait.time(function()
                createFlipAndShuffleGameDeck(dealAllSeasons)
            end, standardWaitSec * 2)
        end)
end

function cleanup()
    if not isBottomButtonEnabled(cleanupButtonId) then
        return
    end

    -- If not already running, no-op.
    local appState = getPrivateState("appState")
    if not appState == appStates.GameRunning then
        return
    end

    setPrivateState(
        {
            appState = appStates.CleanupRunning,
        }, function()
        cleanupOldGame()
        -- We are now back to the state where source decks are ready, game deck gone, etc.
        setPrivateState({appState = appStates.CreatedSourceDecks})
    end)
end

function toggleBiddingOpen()
    if not isBottomButtonEnabled(toggleBiddingOpenButtonId) then
        return
    end

    local bio = getPrivateState("biddingIsOpen")
    print("Doug: toggleBiddingIsOpen: bio = ", bio)
    setPrivateState({biddingIsOpen = not bio})
end

function toggleBidViewPanel()
    if not isBottomButtonEnabled(toggleBidsPanelButtonId) then
        return
    end

    togglePanelVisibilityWithButtonNameUpdate(bidViewPanelId, toggleBidsPanelButtonId)
end

function toggleFinalTallyPanel()
    if not isBottomButtonEnabled(toggleFinalTallyPanelButtonId) then
        return
    end

    togglePanelVisibilityWithButtonNameUpdate(finalTallyPanelId, toggleFinalTallyPanelButtonId)
end

--[[
Input cell handlers.
]]
function onBidInputCellUpdated(player, textValue, cellInputElementId)
    -- Someone wrote a big into their bid panel.
    -- Make sure the value is written into the input widget (???)
    UI.setAttribute(cellInputElementId, "text", textValue)
    -- After things settle, write bid into internal storage.
    Wait.time(function()
        -- This id should be of the form:
        -- BidInput.<PlayerColor>.<bidDetailType>_<rowIndex>_<columnIndex>
        -- Get out color, bidDetailType, rowIndex, columnIndex.
        local cellElementIdPrefix, _, _ = splitCellElementId(cellInputElementId)
        local _, seatedPlayerColor, bidDetailType = splitCellElementIdPrefix(cellElementIdPrefix)

        -- What player color are we dealing with?
        -- Sanity check: these panels are only visible to owning player.
        if player.color ~= seatedPlayerColor then
            print("Error: onBidInputCellUpdated player color does not match seated player color")
            return
        end

        local bidValue = tonumber(textValue)
        setBidDetailByPlayerColor(seatedPlayerColor, bidDetailType, bidValue)
    end, handleInputWaitSec)

end

function onScoreInputCellUpdated(_, textValue, cellInputElementId)
    -- Make sure the value is written into the input widget (???)
    UI.setAttribute(cellInputElementId, "text", textValue)
    -- After things settle, write score into internal storage and update the sum.
    Wait.time(function()
        -- This id should be of the form:
        -- ScoreInput.<PlayerColor>.<scoreInputCellName>_<rowIndex>_<columnIndex>
        -- Get out color, rowIndex, columnIndex.
        local cellElementIdPrefix, _, columnIndex = splitCellElementId(cellInputElementId)
        local _, seatedPlayerColor, scoreInputCellName = splitCellElementIdPrefix(cellElementIdPrefix)

        local scoreChange = tonumber(textValue)
        setTypedScoreByPlayerColor(seatedPlayerColor, scoreInputCellName, scoreChange)

        -- Get total for the player.
        local totalScoreForPlayer = getTotalScoreForPlayer(seatedPlayerColor)

        local sumId = makeCellElementId(textIdPrefix, finalTallySumRowIndex, columnIndex)
        UI.setAttribute(sumId, "text", tostring(totalScoreForPlayer))
    end, handleInputWaitSec)
end
