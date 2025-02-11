--[[
global.lua
global logic and values.
]]

--[[
Globals
constants and variables.
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

-- Twiddles for alternate game play.
-- Last card hidden.
local hideLastCard = false
-- Variable season length
local variableSeasonLength = false

-- For each card type we have a "sourceDeck" of cards.
-- They all have tag "sourceDeck".
-- We will collect the GUIDs for these decks here, indexed by card type.
local cardTypeToSourceDeckGUID = {}

local maxPlayers = 4

-- Set up card distribution: we build the deck differently based on the
-- number of players.
local cardDistributionByNumPlayers = {}
local maxCardCount = 0

-- Storage
local scoresByPlayerColor = {}

-- Status
local creatingGameDeck = false

-- Times
local standardWaitSec = 0.5

-- Deck creation times.
local waitAfterCardCloneSec = 0.07
local waitAfterDeckFlipSec = 1
local waitAfterDeckShuffleSec = 1

-- Deal times.
local waitAfterDealtCardFlipSec = 0.2
local waitAfterDealtCardMoveSec = 0.1

-- Positions
local rowWidth = 20
local columnHeight = 3.5
local dealYOffset = 1.5
local hideYPos = -5
local numSeasons = 4

local deckZPos = (numSeasons/2 * columnHeight) + columnHeight

-- Is a game running?
local gameIsRunning = false

-- Deck
local gameDeckGUID = nil
local numCardsInGameDeck = nil

-- tags
local gameDeckTag = "gameDeck"
local sourceCardTag = "sourceCard"
local sourceDeckTag = "sourceDeck"
local importedDeckTag = "importedDeck"
local importedCardTag = "importedCard"

-- Xml stuff
-- The XML from the global.XML file.
local pristineXml = nil

-- For the final tally sheet.
-- Has a title row across the top.
-- Then a column of labels, then columns of input fields for each player.
local finalTallyTitleRowHeight = 50
local finalTallyStandardRowHeight = 30
local finalTallyLabelColumnWidth = 150
local finalTallyStandardColumnWidth = 200

local finalTallyTitleRowColor = "#ddffff"
local finalTallyPlayerRowColor = "#cccccc"
local finalTallyEvenRowColor = "#aacccc"
local finalTallyOddRowColor = "#aaaacc"
local finalTallySumRowColor = "#cccccc"

-- Button stuff.
local buttonFeaturesById = {
    SetupButton = {
        enabledWhenRunning = false,
        enabledR = 1,
        enabledB = 1,
        enabledG = 1,
    },
    CleanupButton = {
        enabledWhenRunning = true,
        enabledR = 1,
        enabledB = 1,
        enabledG = 1,
    },
    ToggleBidsPanelButton = {
        enabledWhenRunning = true,
        enabledR = 1,
        enabledB = 1,
        enabledG = 1,
    },
    ToggleFinalTallyPanelButton = {
        enabledWhenRunning = true,
        enabledR = 1,
        enabledB = 1,
        enabledG = 1,
    },
    BidButton = {
        enabledWhenRunning = true,
        enabledR = 0.8,
        enabledB = 0.8,
        enabledG = 1,
    },
}
local cachedButtonAttributes = {}
local disabledButtonAlpha = 0.3

--[[
Functions: Utilities
Nice for any/all game.
FIXME: how to refactor?
]]
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

local function getTableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function getPlayerCount()
    local seatedPlayerColors = getSeatedPlayers()

    -- FIXME(dbanks) : if just one player pretend there are N
    if #seatedPlayerColors == 1 then
        return 4
    end

    return #seatedPlayerColors
end

-- Wait this long, call then given function, then call the callback.
local function runAfterWaitThenCallback(waitSec, runFunc, callbackFunc)
    Wait.time(function()
        runFunc()
        callbackFunc()
    end, waitSec)
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

-- Dump to console util.
local function dump(blob, opt_params)
    local params = opt_params or {}
    local indent = params.indent or ""
    local recursive = true
    if params.nonRecursive then
        recursive = false
    end

    if type(blob) ~= "table" then
        print("Doug: blob is not a table!")
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

-- enable/disable a button.
local function cacheButtonAttributes()
    for buttonId, value in pairs(buttonFeaturesById) do
        local attributes = {}
        attributes.onClick = UI.getAttribute(buttonId, "onClick")
        cachedButtonAttributes[buttonId] = attributes
    end
end

local function setButtonEnabled(buttonId, enabled)
    local attributes = cachedButtonAttributes[buttonId]
    local features = buttonFeaturesById[buttonId]
    if enabled then
        UI.setAttribute(buttonId, "color", "rgb(" .. features.enabledR .. "," .. features.enabledG .. "," .. features.enabledB .. ")")
        UI.setAttribute(buttonId, "onClick", attributes.onClick)
    else
        UI.setAttribute(buttonId, "color", "rgba(" .. features.enabledR .. "," .. features.enabledG .. "," .. features.enabledB .. ", " .. disabledButtonAlpha .. ")")
        UI.setAttribute(buttonId, "onClick", "")
    end
end

--[[
Get/set score info.
]]
local function getStoredScore(playerColor, inputCellName)
    if scoresByPlayerColor[playerColor] == nil then
        scoresByPlayerColor[playerColor] = {}
    end
    if scoresByPlayerColor[playerColor][inputCellName] == nil then
        scoresByPlayerColor[playerColor][inputCellName] = 0
    end
    return scoresByPlayerColor[playerColor][inputCellName]
end

local function setStoredScore(playerColor, inputCellName, score)
    if scoresByPlayerColor[playerColor] == nil then
        scoresByPlayerColor[playerColor] = {}
    end
    scoresByPlayerColor[playerColor][inputCellName] = score
end

local function cleanupScoresForPlayer(playerColor)
    scoresByPlayerColor[playerColor] = {}
end


--[[
Deck shortcuts.
]]
local function resetDeck(deckGUID)
    local deck = getObjectFromGUID(deckGUID)
    deck.reset()
end

local function shuffleDeck(deckGUID)
    local deck = getObjectFromGUID(deckGUID)
    deck.randomize()
end

local function flipDeck(deckGUID)
    local deck = getObjectFromGUID(deckGUID)
    deck.flip()
end

--[[--------------------------

UI functions

]] ---------------------------
--[[
Generic UI utilities.
I'd love to get these into a separate file, not sure how to do that.
]]

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

-- Create an XML node with provided params.
local function makeXmlNode(tag, attributes)
    local xmlNode = {
        tag = tag,
        attributes = attributes,
        children = {},
    }
    return xmlNode
end

--[[
Utilities for a table layout.
]]
-- The element for nth row of a table has id "Row_n".
local function makeRowId(rowIndex)
    return "Row_" .. rowIndex
end

-- elements in the row i, column j cell of a table have id <element type>_i_j.
local function makeId(prefix, rowIndex, columnIndex)
    return prefix .. "_" .. rowIndex .. "_" .. columnIndex
end

-- given the index of a row and some custom row class, make that row.
local function makeXmlRow(rowIndex, rowClass, rowHeight)
    local rowId = makeRowId(rowIndex)
    local xmlRow = makeXmlNode("Row", {
        id = rowId,
        class = rowClass,
        preferredHeight=tostring(rowHeight),
    })
    return xmlRow
end

--[[
Utilities to make various types of nodes
]]
-- A node that just holds text.
local function makeXmlText(textId, text, classPrefix)
    local xmlText = makeXmlNode("Text", {
        class = classPrefix .. "TextClass",
        id = textId,
        text = text,
    })

    return xmlText
end

-- A cell in a table that holds text.  Custom class.
local function makeXmlTextCell(rowIndex, columnIndex, cellText, classPrefix)
    local cellId = makeId("Cell", rowIndex, columnIndex)
    local textId = makeId("Text", rowIndex, columnIndex)

    local xmlCell = makeXmlNode("Cell", {
        class = classPrefix .. "CellClass",
        id = cellId,
    })
    local xmlText = makeXmlText(textId, cellText, classPrefix)
    safeAddToXmlChildren(xmlCell, xmlText)
    return xmlCell
end

-- A cell in a table that holds text.  Class "Label".
local function makeXmlLabelCell(rowIndex, columnIndex, cellText)
    local xmlLabelCell = makeXmlTextCell(rowIndex, columnIndex, cellText, "Label")
    return xmlLabelCell
end

-- A cell in a table that holds text.  Class "PlayerName".
local function makeXmlPlayerNameCell(rowIndex, columnIndex, cellText)
    local xmlPlayerNameCell = makeXmlTextCell(rowIndex, columnIndex, cellText, "PlayerName")
    return xmlPlayerNameCell
end

-- A cell in a table that holds text.  Class "Sum".
local function makeXmlSumCell(rowIndex, columnIndex, cellText)
    local xmlSumCell = makeXmlTextCell(rowIndex, columnIndex, cellText, "Sum")
    return xmlSumCell
end

-- Cell in a table for an input widget.
local function makeXmlInputCell(rowIndex, columnIndex, seatedPlayerColor)
    local cellId = makeId("Cell", rowIndex, columnIndex)
    local inputId = makeId("Input", rowIndex, columnIndex)

    local xmlCell = makeXmlNode("Cell", {
        class = "InputCellClass",
        id = cellId,
        color = seatedPlayerColor,
    })
    dump(xmlCell)

    local inputCellNames = getInputCellNames()
    local scoreForCellNumber = getStoredScore(seatedPlayerColor, inputCellNames[rowIndex])

    local xmlInput = makeXmlNode("InputField", {
        class = "InputClass",
        id = inputId,
        text = tostring(scoreForCellNumber),
        onEndEdit = "updateScore",
    })
    safeAddToXmlChildren(xmlCell, xmlInput)

    xmlInput.attributes.width = tostring(finalTallyStandardColumnWidth/2)
    xmlInput.attributes.height = tostring(finalTallyStandardRowHeight)

    return xmlCell
end

-- Row in a table that holds the title of the table.
local function makeTitleRow(numSeatedPlayerObjects)
    local xmlRow = makeXmlRow("title", "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color  = finalTallyTitleRowColor,
    })

    -- Label cell.
    local xmlLabelCell = makeXmlLabelCell(0, 0, "Final Tally")
    safeAddToXmlAttributes(xmlLabelCell, {
        columnSpan = tostring(numSeatedPlayerObjects + 1),
    })

    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    return xmlRow
end

-- Row in table with label column plus columns for each player.
local function makePlayerRow(rowIndex, seatedPlayerObjects)
    local xmlRow = makeXmlRow(rowIndex, "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color  = finalTallyPlayerRowColor,
    })

    -- Label cell.
    local xmlLabelCell = makeXmlLabelCell(rowIndex, 0, "Player Name")
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    -- One cell for each player: fill with player name.
    for columnIndex, seatedPlayer in pairs(seatedPlayerObjects) do
        local xmlPlayerNameCell = makeXmlPlayerNameCell(rowIndex, columnIndex, seatedPlayer.steam_name)
        safeAddToXmlChildren(xmlRow, xmlPlayerNameCell)
    end
    return xmlRow
end

-- Row in a table with a label, then input cells, one for each player.
local function makeNthInputRow(rowIndex, rowLabel, seatedPlayerObjects)
    local rowColor
    if rowIndex % 2 == 0 then
        rowColor = finalTallyEvenRowColor
    else
        rowColor = finalTallyOddRowColor
    end
    local xmlRow = makeXmlRow(rowIndex, "InputRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color=rowColor,
    })

    -- Label cell.
    local xmlLabelCell = makeXmlLabelCell(rowIndex, 0, rowLabel)
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    -- One cell for each player: fill with input widget.
    for columnIndex, seatedPlayerObject in pairs(seatedPlayerObjects) do
        local xmlInputCell = makeXmlInputCell(rowIndex, columnIndex, seatedPlayerObject.color)
        safeAddToXmlChildren(xmlRow, xmlInputCell)
    end
    return xmlRow
end

-- Row in a table that sums all the inputs from the rows above.
local function makeSumRow(rowIndex, numSeatedPlayerObjects)
    local xmlRow = makeXmlRow(rowIndex, "TextRowClass")
    safeAddToXmlAttributes(xmlRow, {
        color  = finalTallySumRowColor,
    })

    -- Label cell.
    local xmlLabelCell = makeXmlLabelCell(rowIndex, 0, "Total")
    safeAddToXmlChildren(xmlRow, xmlLabelCell)

    -- One cell for each player: fill with zeros.
    for columnIndex = 1, numSeatedPlayerObjects do
        local xmlSumCell = makeXmlSumCell(rowIndex, columnIndex, "0")
        safeAddToXmlChildren(xmlRow, xmlSumCell)
    end
    return xmlRow
end

-- Split a string like foo_<i>_<j> and return i, j
local function getRowAndColumn(textString)
    local pieces = mysplit(textString, "_")
    local rowIndex = tonumber(pieces[2])
    local columnIndex = tonumber(pieces[3])
    return rowIndex, columnIndex
end

--[[
Application-specific UI functions.
]]
local function updateButtons()
    for buttonId, buttonFeatures in pairs(buttonFeaturesById) do
        local enabled
        if gameIsRunning then
            enabled = buttonFeatures.enabledWhenRunning
        else
            enabled = not buttonFeatures.enabledWhenRunning
        end
        setButtonEnabled(buttonId, enabled)
    end
end

local function setupUI()
    cacheButtonAttributes()
    updateButtons()
end

function updateXmlForFinalTally(moddedXml)
    local panel = findXmlNodeWithID(moddedXml, "FinalTallyPanel")

    local seatedPlayerObjects = getSeatedPlayerObjects()
    local numSeatedPlayerObjects = #seatedPlayerObjects

    local panelWidth = finalTallyLabelColumnWidth + finalTallyStandardColumnWidth * numSeatedPlayerObjects
    local panelHeight = finalTallyTitleRowHeight + finalTallyStandardRowHeight * (#inputCellNames + 2)

    safeAddToXmlAttributes(panel, {
        height = tostring(panelHeight),
        width = tostring(panelWidth),
        offsetXY = "-50 0",
    })

    -- Column widths: width of label column then one std width for each player.
    local columnWidths = tostring(finalTallyLabelColumnWidth)
    for _ = 1, numSeatedPlayerObjects do
        columnWidths = columnWidths .. " " .. tostring(finalTallyStandardColumnWidth)
    end

    local xmlTableLayout = makeXmlNode("TableLayout", {
        class = "FinalTallyTableLayoutClass",
        id = "FinalTallyTableLayout",
        columnWidths = columnWidths,
        ignoreLayout="true",
    })
    safeAddToXmlChildren(panel, xmlTableLayout)

    local xmlRow = makeTitleRow(numSeatedPlayerObjects)
    safeAddToXmlAttributes(xmlRow, {
        preferredHeight = tostring(finalTallyTitleRowHeight),
    })
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    xmlRow = makePlayerRow(0, seatedPlayerObjects)
    safeAddToXmlChildren(xmlTableLayout, xmlRow)

    for index, inputCellName in pairs(inputCellNames) do
        xmlRow = makeNthInputRow(index, inputCellName, seatedPlayerObjects)
        safeAddToXmlChildren(xmlTableLayout, xmlRow)
    end

    xmlRow = makeSumRow(#inputCellNames + 1, numSeatedPlayerObjects)
    safeAddToXmlChildren(xmlTableLayout, xmlRow)
end

function updateXml()
    local moddedXml = UI.GetXmlTable()

    moddedXml = updateXmlForFinalTally(moddedXml)

    UI.setXmlTable(moddedXml)
end

--[[
Functions for laying out the cards for a round.
]]
-- Place next card from given deck.
local function placeCardWhichMayChangeDeck(deck, numRows, rowIndex, columnIndex, cardsToDeal, callback, opt_options)
    local options = opt_options or {}

    local flip
    if options.hideLastCard and rowIndex == cardsToDeal then
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
        options.cardTwiddleCallback(card, columnIndex)
    else
        card.addTag("dealtCard")
    end


    -- Where do we want card to move to, and what rotation?
    local xPos = -rowWidth/2 + (rowWidth / (cardsToDeal - 1)) * (columnIndex-1)
    local zPos = ((numRows-1)/2 * columnHeight) - (columnHeight * (rowIndex-1))

    local position = Vector(xPos, dealYOffset, zPos)

    runAfterWaitThenCallback(waitAfterDealtCardFlipSec, function()
        card.setPositionSmooth(position)
    end, function()
        callback(updatedDeck)
    end)
end

-- Recursive step to lay out the next card.
-- Indices are one-based.
local function recursivePlaceNextCard(deck, numRows, rowIndex, columnIndex, cardsToDeal, callback, opt_options)
    -- Exit case.
    if columnIndex > cardsToDeal then
        callback(1)
        return
    end

    placeCardWhichMayChangeDeck(deck, numRows, rowIndex, columnIndex, cardsToDeal, function(updatedDeck)
        -- Wait a bit then deal the next card.
        Wait.time(function()
            columnIndex = columnIndex + 1
            recursivePlaceNextCard(updatedDeck, numRows, rowIndex, columnIndex, cardsToDeal, callback, opt_options)
        end, waitAfterDealtCardMoveSec)
    end, opt_options)
end

local function placeCardsForSeason(seasonIndex, callback)
    -- How many to deal?
    local cardsThisSeason = math.floor(numCardsInGameDeck / numSeasons)

    if variableSeasonLength then
        local playerCount = getPlayerCount()
        if seasonIndex == 1 then
            cardsThisSeason = cardsThisSeason - playerCount
        elseif seasonIndex == numSeasons then
            cardsThisSeason = cardsThisSeason + playerCount
        end
    end

    local deck = getObjectFromGUID(deckGUID)

    if not deck then
        callback(0)
        return
    end

    recursivePlaceNextCard(deck, numSeasons, seasonIndex, 1, cardsThisSeason, function()
        -- All done dealing this row.  Do the next one.
        placeCardsForSeason(seasonIndex + 1, callback)
    end, {
        hideLastCard = hideLastCard,
    })
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
    print("Doug: hideSourceDecks")
    for _, deckGUID in pairs(cardTypeToSourceDeckGUID) do
        local sourceDeck = getObjectFromGUID(deckGUID)
        print("Doug: hideSourceDecks deckGUID = ", deckGUID)
        print("Doug: hideSourceDecks sourceDeck = ", sourceDeck)
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
    local cloneDecks = getObjectsWithTag("cloneTag")
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
        print("Doug: error, did not find exactly one gameDeck: got ", #decks)
        callback(nil)
    end
end

-- We have a description of a source deck and the number of cards we want to take from it.
-- We will:
-- 1. Clone the source deck (so we don't have to put cards back later).
-- 2. Grab cards from the clone and add to source deck.
local function cloneSourceDeckAndAddCardsToGameDeck(sourceDeckWithNumCards)
    local sourceDeck = sourceDeckWithNumCards.sourceDeck
    local numCards = sourceDeckWithNumCards.numCards

    -- OK this is pretty weaksauce but here we are.
    -- If we take card from the actual source deck, we have to put them back when
    -- game is over, which is a headache.
    -- If source deck is not pre-existing, I have to clone a gang of cards each time we reset game,
    -- which makes irritating boop noise.
    -- So what if I clone the whole deck, takes cards from there, then destroy clones?
    print("Doug: sourceDeck = ", sourceDeck)
    local cloneOfSourceDeck = sourceDeck.clone()
    local sourceDeckPosition = sourceDeck.getPosition()
    local cloneDeckPosition = sourceDeckPosition
    cloneDeckPosition.y = cloneDeckPosition.y + hideYPos
    cloneOfSourceDeck.setPosition(cloneDeckPosition)

    -- Clarify tags.
    cloneOfSourceDeck.removeTag(sourceDeckTag)
    cloneOfSourceDeck.addTag("cloneTag")

    -- Grab this many cards from cloned deck.
    local takenObject
    if numCards == 1 then
        local result = safeTakeFromDeck(cloneOfSourceDeck)
        print("Doug: result = ", result)
        takenObject = result.card
        cloneOfSourceDeck = result.deck
    else
        local splitDecks = cloneOfSourceDeck.cut(numCards)
        takenObject = splitDecks[2]
    end

    -- No longer a clone:, this is part of gameDeck.
    takenObject.removeTag("cloneTag")
    takenObject.addTag(gameDeckTag)
    -- Not locked...
    takenObject.setLock(false)
    -- Place well above the middle of table: it will drop onto any cards previously
    -- placed and join to add to new deck.
    takenObject.setPosition({0, 2, deckZPos})
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
        -- Shuffle.
        Wait.time(function()
            shuffleDeck(deckGUID)
            Wait.time(function()
                callback()
            end, waitAfterDeckShuffleSec)
        end, waitAfterDeckFlipSec)
    end)
end

local function recursivePlaceCardsForSeason(seasonIndex, callback)
    -- Handle the end case: we are done.
    if seasonIndex > numSeasons then
        callback()
        return
    end

    -- Deal the cards for this season.
    placeCardsForSeason(seasonIndex, function()
        -- Wait a bit and repeat for the next season.
        Wait.time(function()
            -- That season is resolved: increment.
            seasonIndex = seasonIndex + 1
            recursivePlaceCardsForSeason(seasonIndex, callback)
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
    creatingGameDeck = false
    -- Flip and shuffle the deck.
    flipAndShuffleDeck(gameDeckGUID, function()
        -- Deal out all the seasons.
        recursivePlaceCardsForSeason(1, function()
            -- Done dealing for all seasons...
        end)
    end)

    -- Done creating the deck.
    creatingGameDeck = false
end

-- Given the number of players and the card decks are using this game, get array of
-- {sourceDeck, numCards} pairs describing all the cards we will be using to build
-- the main game deck.
local function getSourceDecksWithNumCards()
    -- Count the players.
    local playerCount = getPlayerCount()

    -- Use that to index into table: how many for each type of card.
    local cardDistribution = cardDistributionByNumPlayers[playerCount]

    -- Make the cards.
    local sourceDecksWithNumCards = {}
    for cardType, numCards in pairs(cardDistribution) do
        print("Doug: cardType = ", cardType)
        print("Doug: numCards = ", numCards)
        local sourceDeckGUID = cardTypeToSourceDeckGUID[cardType]
        print("Doug: sourceDeckGUID = ", sourceDeckGUID)
        local sourceDeck = getObjectFromGUID(sourceDeckGUID)
        print("Doug: sourceDeck = ", sourceDeck)

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
    print("Doug: fillInCardTypeToSourceDeckGUID 001")
    cardTypeToSourceDeckGUID = {}
    local sourceDecks = getObjectsWithTag(sourceDeckTag)
    if not sourceDecks then
        print(("Doug: fillInCardTypeToSourceDeckGUID sourceDecks is nil"))
    end
    if #sourceDecks == 0 then
        print(("Doug: fillInCardTypeToSourceDeckGUID sourceDecks is empty"))
    end
    for _, cardType in pairs(cardTypes) do
        for _, sourceDeck in pairs(sourceDecks) do
            if sourceDeck.getName() == cardType then
                cardTypeToSourceDeckGUID[cardType] = sourceDeck.getGUID()
                print("Doug: fillInCardTypeToSourceDeckGUID cardType = ", cardType)
                print("Doug: fillInCardTypeToSourceDeckGUID sourceDeck.getGUID() = ", sourceDeck.getGUID())
            end
        end
    end
end

--[[
Called by coroutines. These cannot be local functions.
]]
-- Top level function that builds the game deck.
function createGameDeckAndDealSeasons()
    -- Non-reentrant.
    if creatingGameDeck then
        return 1
    end

    creatingGameDeck = true

    local sourceDecksWithNumCards = getSourceDecksWithNumCards()

    gameDeckGUID = nil

    recursiveGetCardsFromNextSourceDeck(sourceDecksWithNumCards, 1, onGameDeckCreated)

    return 1
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

    -- Reset stored scores.
    local seatedPlayerColors = getSeatedPlayers()
    for playerColor, _ in pairs(seatedPlayerColors) do
        cleanupScoresForPlayer(playerColor)
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
        print("Doug: error, expected 0 or 1 imported decks, got ", #importedDecks)
        return nil
    end
    if #importedDecks == 1 then
        return importedDecks[1]
    end

    print("Doug: error, expected 0 or 1 imported decks, got ", #importedDecks)
    return nil
end

local function makeDecksFromImportedCards(callback)
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

    callback()
end

local function maybeMakeSourceDecksFromImportedDeck(callback)
    -- If source decks already exist, we are done.
    local sourceDecks = getObjectsWithTag(sourceDeckTag)
    if sourceDecks and #sourceDecks > 0 then
        callback()
        return
    end

    local importedDeck = getImportedDeck()
    if not importedDeck then
        return
    end
    local importedCardCount = importedDeck.getQuantity()

    -- place cards from imported deck.
    recursivePlaceNextCard(importedDeck, 1, 1, 1, importedCardCount, function()
        Wait.time(function()
            -- All the cards are out.
            -- Make decks out of them.
            makeDecksFromImportedCards(callback)
        end, 1)
    end, {
        cardTwiddleCallback = function(importedCard, index)
            -- set tag on new card.
            importedCard.addTag(importedCardTag)
            importedCard.setName(orderedCardTypes[index + 1])
        end,
    })

end

--[[
Functions called by system events.
]]
-- The onLoad event is called after the game save finishes loading.
function onLoad()
    --[[
    -- Fill in some derived global tables/variables.
    fillInCardDistributionByNumPlayers()
    setMaxCardCount()

    -- Keep a clean copy around for when we reset.
    pristineXml = UI.GetXmlTable();

    -- Do UI Setup
    setupUI()

    maybeMakeSourceDecksFromImportedDeck(function()
        Wait.time(function()
            fillInCardTypeToSourceDeckGUID()
            confirmCardNames()
        end, standardWaitSec * 2)
    end)
    ]]
end

-- The onUpdate event is called once per frame.
function onUpdate()
    --[[ print('onUpdate loop!') --]]
end

function onPlayerChangeColor(color)
end

function onPlayerDisconnect(player)
    cleanupScoresForPlayer(player.color)
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

--[[
Functions called from global.xml
]]
function toggleFinalTally()
    local finalTallyActiveValue = UI.getAttribute("FinalTallyPanel", "active")
    if finalTallyActiveValue == "true" then
        UI.hide("FinalTallyPanel")
    else
        -- reset XML to base.
        UI.setXmlTable(pristineXml)

        -- rebuild the page based on current number of players and all.
        updateXml()
        UI.show("FinalTallyPanel")
    end
end

function setup(clickedPlayer)
    -- If already running, no-op.
    if gameIsRunning then
        return
    end
    gameIsRunning = true

    hideSourceDecks()

    -- Cleanup old spawns.
    cleanupOldGame()

    -- update visibility/text
    updateButtons()

    Wait.time(function()
        startLuaCoroutine(Global, "createGameDeckAndDealSeasons")
    end, standardWaitSec * 2)
end

function cleanup()
    -- If not already running, no-op.
    if not gameIsRunning then
        return
    end
    gameIsRunning = false

    cleanupOldGame()
    -- update visibility/text
    updateButtons()
end


function showBids()
    print("Doug: showBids 001")
end
