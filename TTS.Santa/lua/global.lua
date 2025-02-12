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
local hideLastCard = false
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
local waitAfterDeckFlipSec = 1
local waitAfterDeckShuffleSec = 1
local waitAfterDealtCardFlipSec = 0.2
local waitAfterDealtCardMoveSec = 0.1
local waitOnPrivateStateChange = 0.1

local handleInputWaitSec = 0.1

-- Positions
local cardRowWidth = 20
local cardColumnHeight = 3.5
local dealtCardYOffset = 1.5
local hideYPos = -5

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
local bidInputPanelIdPrefix = "BidInputPanel"

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
local setAndSubmitBidButtonId = "SetAndSubmitBidButton"

-- Mapping buttons to details about when enabled and color.
local bottomButtonIds = {
    setupButtonId,
    cleanupButtonId,
    toggleBiddingOpenButtonId,
    toggleBidsPanelButtonId,
    toggleFinalTallyPanelButtonId,
    setAndSubmitBidButtonId,
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
    _callbacks = {},
    _callbackEnqueued = false,
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
    local card = deck.takeObject()
    if deck.remainder ~= nil then
        deck = deck.remainder
    end
    if card == nil then
        return {card = deck, deck = nil}
    end
    return {card = card, deck = deck}
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

-- Shortcut to shuffle a deck by GUID.
local function shuffleDeck(deckGUID)
    local deck = getObjectFromGUID(deckGUID)
    if deck then
        deck.randomize()
        return true
    end
    return false
end

-- Shortcut to flip a deck by GUID.
local function flipDeck(deckGUID)
    local deck = getObjectFromGUID(deckGUID)
    if deck then
        deck.flip()
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
    return _privateState[stateName]
end

local function setPrivateState(stateName, value, opt_onAllCallbackCalled)
    -- Not allowed to use nil values.
    if value == nil then
        print("Error: setting nil state with stateName = ", stateName)
        return false
    end

    if _privateState[stateName] == nil then
        print("Error: setting invalid state with stateName = ", stateName)
        -- Nothing changed.
        return false
    end

    if _privateState[stateName] == value then
        -- Nothing changed.
        return false
    end
    _privateState[stateName] = value

    -- If a bunch of things change at once we don't want to blast our listeners.
    -- Iff there's not a callback enqueued, enqueue one.
    if _privateState._callbackEnqueued then
        return true
    end

    _privateState._callbackEnqueued = true
    Wait.time(function()
        for _, callback in pairs(_privateState._callbacks) do
            callback()
        end
        _privateState._callbackEnqueued  = false
        if opt_onAllCallbackCalled then
            opt_onAllCallbackCalled()
        end
    end, waitOnPrivateStateChange)

end

local function addStateChangedCallbackAndReturnCallbackId(callback)
    local id = _privateState._callbackIdGen
    _privateState.callbackIdGen = _privateState._callbackIdGen + 1

    _privateState._callbacks[id] = callback
    return id
end

local function removeStateChangedCallback(callbackId)
    if not _privateState._callbacks[callbackId] then
        print("Error: called removeStateChangedCallback with invalid callbackId = ", callbackId)
        return
    end
    _privateState._callbacks[callbackId] = nil
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
    setPrivateState("typedScoresByPlayerColor", tsbpc)
end

local function cleanupTypedScoresForPlayer(playerColor)
    local tsbpc = getPrivateState("typedScoresByPlayerColor")
    tsbpc[playerColor] = {}
    setPrivateState("typedScoresByPlayerColor", tsbpc)
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
        print("inputIdPrefix is nil!!! rowIndex = ", rowIndex, " columnIndex = ", columnIndex)
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
    },
    [toggleFinalTallyPanelButtonId] = {
        t = "Hide Scoring",
        f = "Show Scoring",
    },
    [setAndSubmitBidButtonId] = {
        t = "Submit bid",
        f = "Set bid",
    },
}

local function getBottomButtonRgb(buttonId)
    if buttonId == setAndSubmitBidButtonId then
        return {
            r = 0.8,
            g = 0.8,
            b = 1,
        }
    else
        return {
            r = 1,
            g = 1,
            b = 1,
        }
    end
end

-- Decide what the button's text should be based on current state and
-- set text accordingly.
-- State is digested into "condition".
-- If "condition" is true we use the 't' variant, else the 'f'.
-- If there's a buttonTextConditionFunction, we call that to get the value of "condition".
-- Otherwise it turns on buttonEnabled.
local function updateButtonText(buttonId, buttonEnabled)
    local buttonTextVariants = buttonTextVariantsByButtonId[buttonId]

    -- Not all buttons have varying text.
    if not buttonTextVariants then
        return
    end

    local finalCondition = false
    if buttonTextVariants.buttonTextConditionFunction then
        finalCondition = buttonTextVariants.buttonTextConditionFunction()
    else
        if buttonEnabled then
            finalCondition = buttonEnabled
        end
    end

    if finalCondition then
        UI.setAttribute(buttonId, "text", buttonTextVariants.t)
    else
        UI.setAttribute(buttonId, "text", buttonTextVariants.f)
    end
end

local function isBottomButtonEnabled(buttonId)
    local lad = getPrivateState("loadingAllDone")
    if not lad then
        return false
    end

    local gir = getPrivateState("gameIsRunning")
    if not gir then
        if buttonId == setupButtonId then
            return true
        else
            return false
        end
    end

    -- So game is running.
    if buttonId == setupButtonId then
        return false
    end

    -- Game is running.
    -- Deal with special cases.
    -- Users can't submit bids unless bidding is open.
    if buttonId == setAndSubmitBidButtonId then
        local bio = getPrivateState("biddingIsOpen")
        -- Enabled iff bidding is open.
        return bio
    end

    -- Host cannot show bids while bidding is open.
    if buttonId == setAndSubmitBidButtonId then
        local bio = getPrivateState("biddingIsOpen")
        -- Enabled iff bidding is closed.
        return not bio
    end

    return true
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
local function createFinalTallyPanel(currentXml)
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

    setPrivateState("bidDetailsByPlayerColor", bdbpc)
end

local function cleanupBidDetailsForPlayer(playerColor)
    local bdbpc = getPrivateState("bidDetailsByPlayerColor")
    bdbpc[playerColor] = {}
    setPrivateState("bidDetailsByPlayerColor", bdbpc)
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

-- Make bid view inside given XML.
-- Currently just a stub.
-- Fill it in.
-- Returns the modified XML BUT KEEP IN MIND the argument passed in is being modified itself.
-- Like returning is just kinda for clarity/convenience.
local function createBidViewPanel(currentXml)
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

local function makeBidInputPanelIdForPlayer(color)
    return bidInputPanelIdPrefix .. "_" .. color
end

-- add a bidInputPanel custom to this player.
local function createBidInputPanel(currentXml, seatedPlayerObject)
    local panelId = makeBidInputPanelIdForPlayer(seatedPlayerObject.color)

    -- Keep track of this.
    allPanelIdsSet[panelId] = true

    -- Make a panel with this id.
    -- FIXME(dbanks): should be "false" always.
    local active
    if seatedPlayerObject.color == "White" then
        active = "true"
    else
        active = "false"
    end

    local panelWidth = tableLabelCellWidth + tableContentCellWidth * #bidDetailTypes
    local panelHeight = tableTitleRowHeight + tableStandardRowHeight * 2

    local panel = makeXmlNode("Panel", {
        class = "PanelClass",
        id = panelId,
        active = active,
        height = tostring(panelHeight),
        width = tostring(panelWidth),
        offsetXY = tostring(bidInputPanelStartXPos) .. " " .. tostring(bidInputPanelStartYPos),
        --- Visible only to the owning player.
        visibility = seatedPlayerObject.color,
    })
    safeAddToXmlChildren(currentXml, panel)

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

--[[
Functions for laying out the cards for a round.
]]
-- Place next card from given deck.
local function placeCardWhichMayChangeDeck(deck, layoutDetails, cardPlacement, callback, opt_options)
    local options = opt_options or {}

    local flip
    if hideLastCard and cardPlacement.rowIndex == layoutDetails.cardsThisRow then
        flip = false
    else
        flip = true
    end

    local result = safeTakeFromDeck(deck)
    local updatedDeck = result.deck
    local card = result.card

    if flip then
        card.flip()
    end

    if options.cardTwiddleCallback then
        options.cardTwiddleCallback(card, cardPlacement.columnIndex)
    else
        card.addTag("dealtCard")
    end


    -- Where do we want card to move to, and what rotation?
    local xPos = -cardRowWidth/2 + (cardRowWidth / (layoutDetails.cardsThisRow - 1)) * (cardPlacement.columnIndex-1)
    local zPos = ((layoutDetails.numRows-1)/2 * cardColumnHeight) - (cardColumnHeight * (cardPlacement.rowIndex-1))

    local position = Vector(xPos, dealtCardYOffset, zPos)

    runAfterWaitThenCallback(waitAfterDealtCardFlipSec, function()
        card.setPositionSmooth(position)
    end, function()
        callback(updatedDeck)
    end)
end

-- Recursive step to lay out the next card.
-- Indices are one-based.
local function recursivePlaceNextCard(deck, layoutDetails, cardPlacement, onAllCardsPlaced, opt_options)
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

local function placeCardsForSeason(deck, seasonIndex, callback)
    print("placeCardsForSeason seasonIndex = ", seasonIndex)
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
    print("placeCardsForSeason cardsThisSeason = ", cardsThisSeason)

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

local function confirmCardNames()
    for cardType, sourceDeckGUID in pairs(cardTypeToSourceDeckGUID) do
        local sourceDeck = getObjectFromGUID(sourceDeckGUID)
        local expectCardName = cardType
        local objects = sourceDeck.getObjects()
        for _, card in pairs(objects) do
            if card.name ~= expectCardName then
                break
            end
        end
    end
end

--[[
Local functions for creation of the game deck.
]]
-- Move the source card decks offscreen
local function hideSourceDecks()
    for _, deckGUID in pairs(cardTypeToSourceDeckGUID) do
        local sourceDeck = getObjectFromGUID(deckGUID)
        local position = sourceDeck.getPosition()
        position.y = hideYPos
        sourceDeck.setPosition(position)
        sourceDeck.setLock(true)
    end
end

-- We have build the main game deck.  Cleanup any mess, find the main deck, and pass it back
-- thru the callback.
local function cleanupClonesAndPassBackGameDeck(callback)
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
        callback(gameDeck)
    else
        print("Error, did not find exactly one gameDeck: got ", #decks)
        callback(nil)
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

    -- OK this is pretty weaksauce but here we are.
    -- If we take card from the actual source deck, we have to put them back when
    -- game is over, which is a headache.
    -- If source deck is not pre-existing, I have to clone a gang of cards each time we reset game,
    -- which makes irritating boop noise.
    -- So I clone the whole deck, pull cards from clone, and later (outside this function) destroy the clone.
    local cloneOfSourceDeck = sourceDeck.clone()
    local sourceDeckPosition = sourceDeck.getPosition()
    local cloneDeckPosition = sourceDeckPosition
    cloneDeckPosition.y = cloneDeckPosition.y + hideYPos
    cloneOfSourceDeck.setPosition(cloneDeckPosition)

    -- Clarify tags.
    cloneOfSourceDeck.removeTag(sourceDeckTag)
    cloneOfSourceDeck.addTag(cloneTag)

    -- Grab this many cards from cloned deck.
    local takenObject
    if numCards == 1 then
        local result = safeTakeFromDeck(cloneOfSourceDeck)
        takenObject = result.card
        cloneOfSourceDeck = result.deck
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
end

-- We have a description of which source decks we are using and how many from each deck to build
-- the game deck.
local function recursiveGetCardsFromNextSourceDeck(sourceDecksWithNumCards, sourceDeckIndex, finalCallback)
    -- Handle the end case: we are done.
    if sourceDeckIndex > #sourceDecksWithNumCards then
        Wait.time(function()
            cleanupClonesAndPassBackGameDeck(finalCallback)
        end, standardWaitSec)
        return
    end

    local sourceDeckWithNumCards = sourceDecksWithNumCards[sourceDeckIndex]
    cloneSourceDeckAndAddCardsToGameDeck(sourceDeckWithNumCards)
    -- That source deck is resolved: increment.
    sourceDeckIndex = sourceDeckIndex + 1
    -- Wait a bit and repeat for the next deck.
    Wait.time(function()
        recursiveGetCardsFromNextSourceDeck(sourceDecksWithNumCards, sourceDeckIndex, finalCallback)
    end, waitAfterCardCloneSec)
end

local flipAndShuffleDeck = function(deckGUID, callback)
    -- Flip the deck
    runAfterWaitThenCallback(standardWaitSec, function()
        flipDeck(deckGUID)
    end, function()
        runAfterWaitThenCallback(waitAfterDeckFlipSec, function()
            shuffleDeck(deckGUID)
        end, function()
            Wait.time(function()
                callback()
            end, waitAfterDeckShuffleSec)
        end)
    end)
end

local function recursivePlaceCardsForSeason(deck, seasonIndex, callback)
    -- Handle the end case: we are done.
    if seasonIndex > numSeasons then
        callback()
        return
    end

    -- Deal the cards for this season.
    placeCardsForSeason(deck, seasonIndex, function(updatedDeck)
        -- Wait a bit and repeat for the next season.
        Wait.time(function()
            -- That season is resolved: increment.
            seasonIndex = seasonIndex + 1
            recursivePlaceCardsForSeason(updatedDeck, seasonIndex, callback)
        end, waitAfterDealtCardMoveSec)
    end)
end

-- This will be called once the game deck has been created.
local function onGameDeckCreated(gameDeck)
    if not gameDeck then
        -- Uh oh.
        return
    end

    -- Tweak some values...
    -- Update the name and tags.
    gameDeck.setName("GameDeck")

    -- Remember some values...
    gameDeckGUID = gameDeck.getGUID()
    numCardsInGameDeck = gameDeck.getQuantity()

    -- Done creating the deck.
    setPrivateState("creatingGameDeck", false)
    -- Flip and shuffle the deck.
    flipAndShuffleDeck(gameDeckGUID, function()
        -- Deal out all the seasons.
        local deck = getObjectFromGUID(gameDeckGUID)
        recursivePlaceCardsForSeason(deck, 1, function()
            -- Done dealing for all seasons...
        end)
    end)

    -- Done creating the deck.
    setPrivateState("creatingGameDeck", false)
end

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

--[[
Functions called once the game is loaded.
]]
local function fillInCardTypeToSourceDeckGUID()
    cardTypeToSourceDeckGUID = {}
    local sourceDecks = getObjectsWithTag(sourceDeckTag)
    if not sourceDecks then
        print(("fillInCardTypeToSourceDeckGUID: sourceDecks is nil"))
        return
    end
    if #sourceDecks == 0 then
        print(("fillInCardTypeToSourceDeckGUID: sourceDecks is empty"))
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

--[[
Setup/cleanup functions.
]]
local function cleanupOldGame()
    -- Reset XML to pristine.
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

--[[
Functions to init global tables/variables.
]]
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

local function maybeMakeSourceDecksFromImportedDeck(onSourceDecksCreated)
    -- If source decks already exist, we are done.
    local sourceDecks = getObjectsWithTag(sourceDeckTag)
    if sourceDecks and #sourceDecks > 0 then
        onSourceDecksCreated()
        return
    end

    local importedDeck = getImportedDeck()
    if not importedDeck then
        return
    end
    local importedCardCount = importedDeck.getQuantity()

    local function onAllCardsPlaced(_)
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

    recursivePlaceNextCard(importedDeck, layoutDetails, cardPlacement, onAllCardsPlaced, {
        cardTwiddleCallback = cardTwiddleCallback,
    })
end

--[[--------------------------

Functions
Top level for building and updating XML.

]] ---------------------------
 local function createScriptingBasedUI()
     -- Set XML to pristine.
    UI.setXmlTable(pristineXml)

    local currentXML = UI.GetXmlTable()
    local updatedXML
    -- Build the XML for the final tally panel.
    updatedXML = createFinalTallyPanel(currentXML)
    -- Build the XML for the view-all-bids panel.
    updatedXML = createBidViewPanel(updatedXML)

    -- One bid input panel per player.
    local seatedPlayerObjects = getSeatedPlayerObjects()
    for _, seatedPlayerObject in pairs(seatedPlayerObjects) do
        updatedXML = createBidInputPanel(updatedXML, seatedPlayerObject)
    end

    -- Set the XML.
    UI.setXmlTable(updatedXML)
end

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
    updateButtonText(buttonId, isVisible)
    return isVisible
end

--[[--------------------------

Functions
Called by state machine when state changes.

]] ---------------------------
local function updateBottomButtonBasedOnState(buttonId)
    -- Enable or disable the button.
    local buttonEnabled = isBottomButtonEnabled(buttonId)
    setBottomButtonEnabled(buttonId, buttonEnabled)

    -- Make sure text is up to date too.
    updateButtonText(buttonId, buttonEnabled)
end

local function maybeHidePanel(panelId)
    -- If we are not running, all panels are hidden.
    local gir = getPrivateState("gameIsRunning")
    if not gir then
        UI.hide(panelId)
    end

    -- If bidding open, you can't see bid view panel.
    local bio = getPrivateState("biddingIsOpen")
    if bio and panelId == bidViewPanelId then
        UI.hide(panelId)
    end

    -- If bidding is not open you can't see bid input panels.
    if not bio and string.find(panelId, bidInputPanelIdPrefix) then
        UI.hide(panelId)
    end
end

-- State has changed.
-- We may want to update the UI accordingly.
local function updateUIBasedOnCurrentState()
    -- For each bottom button:
    -- update enabled.
    -- update text strings.
    for _, buttonId in pairs(bottomButtonIds) do
        updateBottomButtonBasedOnState(buttonId)
    end

    -- State changes may force panels to hide.
    for panelId, _ in pairs(allPanelIdsSet) do
        maybeHidePanel(panelId)
    end
end

--[[--------------------------

Functions
Called by system events.

]] ---------------------------
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

--[[--------------------------

Functions
Called by system events.

]] ---------------------------
 -- The onLoad event is called after the game save finishes loading.
function onLoad()
    -- Init state.
    declareValidState("typedScoresByPlayerColor", {})
    declareValidState("bidDetailsByPlayerColor", {})
    declareValidState("creatingGameDeck", false)
    declareValidState("gameIsRunning", false)
    declareValidState("loadingAllDone", false)
    declareValidState("biddingIsOpen", false)

    -- Listen for changes to private state.
    addStateChangedCallbackAndReturnCallbackId(updateUIBasedOnCurrentState)

    -- Fill in some derived global tables/variables.
    fillInCardDistributionByNumPlayers()
    setMaxCardCount()

    -- Do UI Setup
    configureBottomButtonLayout()
    updateUIBasedOnCurrentState()

    -- Do I have too wait a second here fo rthings to apply?
    Wait.time(function()
        -- Waited to get pristine XML...
        -- Keep a clean copy around for when we reset.
        pristineXml = UI.GetXmlTable();

        local function onSourceDecksCreated()
            Wait.time(function()
                fillInCardTypeToSourceDeckGUID()
                confirmCardNames()
                setPrivateState("loadingAllDone", true)
            end, standardWaitSec * 2)
        end

        maybeMakeSourceDecksFromImportedDeck(onSourceDecksCreated)
    end, 2)
end

-- The onUpdate event is called once per frame.
function onUpdate()
    --[[ print('onUpdate loop!') --]]
end

function onPlayerChangeColor(color)
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
Helpers for updating buttons enabled, button text, panel visibility.

]] ---------------------------

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

    local gir = getPrivateState("gameIsRunning")
    -- If already running, no-op.
    if gir then
        return
    end

    setPrivateState("gameIsRunning", true, function()
        hideSourceDecks()

        -- Cleanup old spawns.
        cleanupOldGame()

        -- build all the code-driven XML.
        createScriptingBasedUI()

        --[[
        Wait.time(function()
            startLuaCoroutine(Global, "createGameDeckAndDealSeasons")
        end, standardWaitSec * 2)
    ]]
    end)
end

function cleanup()
    if not isBottomButtonEnabled(cleanupButtonId) then
        return
    end

    -- If not already running, no-op.
    local gir = getPrivateState("gameIsRunning")
    if not gir then
        return
    end

    setPrivateState("gameIsRunning", false, function()
        cleanupOldGame()
    end)
end

function toggleBiddingOpen()
    if not isBottomButtonEnabled(toggleBiddingOpenButtonId) then
        return
    end

    local bio = getPrivateState("biddingIsOpen")
    setPrivateState("biddingIsOpen", not bio)
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

function toggleBidInputPanel(clickedPlayer)
    if not isBottomButtonEnabled(setAndSubmitBidButtonId) then
        return
    end

    -- We have a bid panel for each player: we are showing just the one belonging to this fellow.
    local color = clickedPlayer.color
    local bidInputPanelId = makeBidInputPanelIdForPlayer(color)
    togglePanelVisibilityWithButtonNameUpdate(bidInputPanelId, setAndSubmitBidButtonId)
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

--[[--------------------------

Functions
Called by coroutines. These cannot be local functions.
Note any called-by-coroutine needs to return 0 or 1 to talk about success.

]] ---------------------------
function createGameDeckAndDealSeasons()
    -- Non-reentrant.
    local cgd = getPrivateState("creatingGameDeck")
    if cgd then
        return 1
    end

    setPrivateState("creatingGameDeck", true, function()
        local sourceDecksWithNumCards = getSourceDecksWithNumCards()
        gameDeckGUID = nil
        recursiveGetCardsFromNextSourceDeck(sourceDecksWithNumCards, 1, onGameDeckCreated)
    end)

    return 1
end
