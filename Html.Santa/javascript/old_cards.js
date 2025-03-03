define([
  "dojo/string",
  "dojo/dom",
  "dojo/dom-style",
  "javascript/gameUtils",
  "sharedJavascript/debugLog",
  "dojo/domReady!",
], function (string, dom, domStyle, gameUtils, debugLog) {
  var adjustedPageWidth =
    gameUtils.printedPagePortraitWidth - 2 * gameUtils.pageWidthPadding;
  var adjustedPageHeight =
    gameUtils.printedPagePortraitHeight - 2 * gameUtils.pageHeightPadding;
  var cardFitHorizontally = Math.floor(adjustedPageWidth / gameUtils.cardWidth);
  var cardFitVertically = Math.floor(adjustedPageHeight / gameUtils.cardHeight);

  var bigCardFitHorizontally = Math.floor(
    adjustedPageWidth / gameUtils.bigCardWidth
  );
  var bigCardFitVertically = Math.floor(
    adjustedPageHeight / gameUtils.bigCardHeight
  );

  var defaultCardsPerPage = cardFitHorizontally * cardFitVertically;
  var bigCardsPerPage = bigCardFitHorizontally * bigCardFitVertically;
  var ttsCardsPerPage = 70;

  function setCardSize(node) {
    var sc = gameUtils.getSystemConfigs();
    debugLog.debugLog("Cards", "Doug: setCardSize: sc = " + JSON.stringify(sc));
    if (sc.bigCards) {
      debugLog.debugLog(
        "Cards",
        "Doug: using bigCardWidth = " + String(gameUtils.bigCardWidth)
      );
      domStyle.set(node, {
        width: `${gameUtils.bigCardWidth}px`,
        height: `${gameUtils.bigCardHeight}px`,
      });
    } else {
      debugLog.debugLog(
        "Cards",
        "Doug: using width = " + String(gameUtils.width)
      );
      domStyle.set(node, {
        width: `${gameUtils.cardWidth}px`,
        height: `${gameUtils.cardHeight}px`,
      });
    }
  }

  function addCardBack(parent, title, color) {
    var node = gameUtils.addCard(parent, ["back"], "back");

    setCardSize(node);

    var innerNode = gameUtils.addDiv(node, ["inset"], "inset");
    var otherColor = gameUtils.blendHexColors(color, "#ffffff");
    var gradient = string.substitute("radial-gradient(${color1}, ${color2})", {
      color1: otherColor,
      color2: color,
    });
    domStyle.set(innerNode, "background", gradient);
    var title = gameUtils.addDiv(innerNode, ["title"], "title", title);
    var style = {};
    style["font-size"] = configs.bigCards
      ? `${gameUtils.bigCardBackFontSize}px`
      : `${gameUtils.cardBackFontSize}px`;
    domStyle.set(title, style);

    return node;
  }

  function addCardFront(parent, classArray, id) {
    classArray.push("front");
    var node = gameUtils.addCard(parent, classArray, id);
    setCardSize(node);

    return node;
  }

  function addCards(title, color, numCards, contentCallback) {
    var bodyNode = dom.byId("body");
    var sc = systemConfigs.getSystemConfigs();

    var pageOfFronts;
    var pageOfBacks;

    var cardsPerPage;
    if (sc.cardsPerPage) {
      cardsPerPage = sc.cardsPerPage;
    } else {
      cardsPerPage = defaultCardsPerPage;
    }

    var addBackFunction;
    if (sc.addBackOverride) {
      addBackFunction = sc.addBackOverride;
    } else {
      addBackFunction = addCardBack;
    }

    var shouldAddBacks = !sc.skipBacks;

    if (sc.separateBacks) {
      for (let i = 0; i < numCards; i++) {
        var timeForNewPage = i % cardsPerPage;
        if (timeForNewPage == 0) {
          pageOfFronts = gameUtils.addPageOfItems(bodyNode);
        }
        contentCallback(pageOfFronts, i);
      }

      if (shouldAddBacks) {
        for (let i = 0; i < numCards; i++) {
          var timeForNewPage = i % cardsPerPage;
          if (timeForNewPage == 0) {
            pageOfBacks = gameUtils.addPageOfItems(bodyNode, ["back"]);
          }
          addBackFunction(pageOfBacks, title, color);
        }
      }
    } else {
      for (let i = 0; i < numCards; i++) {
        var timeForNewPage = i % cardsPerPage;
        if (timeForNewPage == 0) {
          pageOfFronts = gameUtils.addPageOfItems(bodyNode);
          if (shouldAddBacks) {
            pageOfBacks = gameUtils.addPageOfItems(bodyNode, ["back"]);
          }
        }
        contentCallback(pageOfFronts, i);
        if (shouldAddBacks) {
          addBackFunction(pageOfBacks, title, color);
        }
      }
    }
  }

  function getInstanceCountFromConfig(cardConfigs, index) {
    var configs = gameUtils.getConfigs();
    if (configs.singleCardInstance) {
      // TTS is dumb, needs at least 12 cards.
      if (cardConfigs.length < 12 && index == 0) {
        return 12 - (cardConfigs.length - 1);
      } else {
        return 1;
      }
    } else {
      return cardConfigs[index].count;
    }
  }

  function getNumCardsFromConfigs(cardConfigs) {
    var numCards = 0;
    for (var i = 0; i < cardConfigs.length; i++) {
      numCards = numCards + cardConfigs[i].instanceCount;
    }
    return numCards;
  }

  function getCardConfigFromIndex(configs, index) {
    for (var i = 0; i < configs.length; i++) {
      console.assert(configs[i].instanceCount > 0);
      if (index < configs[i].instanceCount) {
        return configs[i];
      }
      index -= configs[i].instanceCount;
    }
    return null;
  }

  // This returned object becomes the defined value of this module
  return {
    addCardFront: addCardFront,
    addCards: addCards,
    setCardSize: setCardSize,
    getNumCardsFromConfigs: getNumCardsFromConfigs,
    getCardConfigFromIndex: getCardConfigFromIndex,
    getInstanceCountFromConfig: getInstanceCountFromConfig,

    bigCardsPerPage: bigCardsPerPage,
    ttsCardsPerPage: ttsCardsPerPage,
  };
});
