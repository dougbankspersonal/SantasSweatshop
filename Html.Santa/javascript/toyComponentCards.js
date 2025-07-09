/* Deprecated */

define([
  "javascript/gameInfo",
  "sharedJavascript/cards",
  "sharedJavascript/debugLog",
  "sharedJavascript/htmlUtils",
  "dojo/string",
  "dojo/dom-style",
  "dojo/domReady!",
], function (gameInfo, cards, debugLog, htmlUtils, string, domStyle) {
  // Constants
  var minicardWidth = 30;
  var minicardBorderWidth = 4;
  var minicardHeight = minicardWidth * 1.4;
  var whiteOutlineClass = "white_outline";

  var minicardCollectionWidth = minicardWidth * 3;
  var minicardCollectionHeight = minicardHeight + 2 * minicardBorderWidth;

  var specialBorderColor = "#FFD700";
  var basicBorderColor = "#000066";
  var radioBorderColor = "#006600";

  var CustomTypeText = "Text";
  var CustomTypePtsText = "PtsText";
  var CustomTypeImage = "Image";

  var specialCounts = [1, 2, 3, 3];

  var toyComponentCardConfigs = [
    {
      title: "Doll",
      class: "doll",
      craft: {
        number: 3,
        points: 2,
      },
      floor: -2,
      playType: "normal",
      color: "#C7CEFF",
      borderColor: basicBorderColor,
      counts: [13, 19, 25, 31],
    },
    {
      title: "Kite",
      class: "kite",
      craft: {
        number: 3,
        points: 3,
      },
      floor: -3,
      playType: "normal",
      color: "#6495ED",
      borderColor: basicBorderColor,
      counts: [10, 15, 19, 24],
    },
    {
      title: "Robot",
      class: "robot",
      craft: {
        number: 3,
        points: 4,
      },
      floor: -4,
      playType: "normal",
      color: "#000080",
      borderColor: basicBorderColor,
      counts: [7, 10, 13, 16],
    },
    {
      title: "Radio",
      class: "radio",
      craft: {
        number: 4,
        points: 8,
      },
      floor: -5,
      playType: "challenge",
      color: "#00aa00",
      borderColor: "radioBorderColor",
      counts: [5, 9, 9, 13],
    },
    {
      title: "Reindeer Poo",
      class: "poo",
      craft: {
        number: 0,
        points: 0,
      },
      floor: -5,
      playType: "special",
      color: "#886633",
      borderColor: "#593002",
      counts: specialCounts,
    },
    {
      title: "Wrapping Paper",
      class: "wrappingPaper",
      specialCustoms: [
        {
          type: CustomTypeText,
          text: "+",
        },
        {
          type: CustomTypeImage,
          imageClass: "package",
        },
        {
          type: CustomTypePtsText,
          points: 3,
        },
      ],
      playType: "special",
      color: "#FF8844",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "Elf Magic",
      class: "elfMagic",
      specialImageClasses: ["doll", "kite", "robot"],
      specialImagesSeparator: "/",
      playType: "special",
      color: "#FF8888",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "Broom",
      class: "broom",
      specialCustoms: [
        {
          type: CustomTypeImage,
          imageClass: "floor",
        },
        {
          type: CustomTypeImage,
          imageClass: "rightArrow",
        },
        {
          type: CustomTypeImage,
          imageClass: "noSymbol",
        },
      ],
      playType: "special",
      color: "#FFFF88",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "Gloves",
      class: "gloves",
      specialImageClasses: ["floor", "rightArrow", "desk"],
      playType: "special",
      color: "#FF4488",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "RC<br>Drone-Borg",
      class: "cyborg",
      imagesWrapperScale: 0.6,
      specialImageClasses: ["doll", "kite", "robot", "radio"],
      specialImagesSeparator: "+",
      specialCustoms: [
        {
          type: CustomTypePtsText,
          points: 5,
        },
      ],
      playType: "special",
      color: "#FF88FF",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "Fruitcake",
      class: "fruitcake",
      specialImageClasses: ["desk", "doubleArrow", "desk"],
      playType: "special",
      color: "#884444",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "Whistle",
      class: "whistle",
      playType: "special",
      craft: {
        number: 1,
        points: 4,
      },
      color: "#888844",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "Knife",
      class: "knife",
      specialImageClasses: ["handshake", "arrow"],
      playType: "special",
      color: "#884488",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
    {
      title: "Satin",
      class: "satin",
      specialCustoms: [
        {
          type: CustomTypeImage,
          imageClass: "doll",
        },
        {
          type: CustomTypePtsText,
          points: 1,
          plusSign: true,
        },
      ],
      playType: "special",
      color: "#FFCC44",
      borderColor: specialBorderColor,
      counts: specialCounts,
    },
  ];

  // Functions
  function maybeAddSpacer(parent, opt_index, opt_separator) {
    var separator = opt_separator ? opt_separator : "&nbsp;";

    if (separator && opt_index && opt_index > 0) {
      htmlUtils.addDiv(
        parent,
        ["special_image_spacer"],
        "specialImageSpacer",
        separator
      );
    }
  }

  function makeMinicard(parent) {
    var minicard = htmlUtils.addDiv(parent, ["minicard"], "minicard");
    domStyle.set(minicard, {
      height: `${minicardHeight}px`,
      width: `${minicardWidth}px`,
      border: `${minicardBorderWidth}px solid #000`,
    });
    return minicard;
  }

  // We already have a parent wrapper.
  // add in a "= n" node and a coin image.
  // Returns nothing.
  function insertSomethingEqualsPointsNode(
    parentNode,
    points,
    opt_pointsPrefix
  ) {
    console.assert(Number.isInteger(points), "Points must be an integer");
    var pointsString;
    var pointsPrefix = opt_pointsPrefix ? opt_pointsPrefix : "";
    if (points < 0) {
      pointsString = ` :&nbsp;<div class="negative">${pointsPrefix}${points}</div>`;
    } else {
      pointsString = ` : ${pointsPrefix}${points}`;
    }

    htmlUtils.addDiv(
      parentNode,
      ["colon_and_points"],
      "colonAndPoints",
      pointsString
    );

    htmlUtils.addImage(parentNode, ["coin", "dark_shadowed"], "coin");
  }

  function addNthSpecialImage(
    imagesWrapper,
    specialImageClass,
    opt_index,
    opt_separator
  ) {
    maybeAddSpacer(imagesWrapper, opt_index, opt_separator);

    if (specialImageClass == "card") {
      makeMinicard(imagesWrapper);
    } else {
      htmlUtils.addImage(
        imagesWrapper,
        ["special_image", specialImageClass, "dark_shadowed"],
        "specialImage"
      );
    }
  }

  function addNthSpecialCustom(parent, specialCustoms, index, opt_separator) {
    var specialCustom = specialCustoms[index];

    var classes = ["special_custom", "unbroken_row"];
    if (specialCustom.small) {
      classes.push("small");
    }

    var customNode = htmlUtils.addDiv(parent, classes, "specialCustom");
    if (specialCustom.type == CustomTypeText) {
      customNode.innerHTML = specialCustom.text;
    } else if (specialCustom.type == CustomTypePtsText) {
      insertSomethingEqualsPointsNode(
        customNode,
        specialCustom.points,
        specialCustom.plusSign ? "+" : ""
      );
    } else if (specialCustom.type == CustomTypeImage) {
      addNthSpecialImage(customNode, specialCustom.imageClass);
    }

    if (specialCustom.fontColor) {
      domStyle.set(customNode, "color", specialCustom.fontColor);
    }
  }

  function addSpecialImages(parent, toyComponentCardConfig) {
    var imagesWrapper = htmlUtils.addDiv(
      parent,
      ["images_wrapper"],
      "imagesWrapper"
    );

    if (toyComponentCardConfig.imagesWrapperScale) {
      domStyle.set(
        imagesWrapper,
        "transform",
        `scale(${toyComponentCardConfig.imagesWrapperScale})`
      );
    }

    for (
      var i = 0;
      i < toyComponentCardConfig.specialImageClasses.length;
      i++
    ) {
      addNthSpecialImage(
        imagesWrapper,
        toyComponentCardConfig.specialImageClasses[i],
        i,
        toyComponentCardConfig.specialImagesSeparator
      );
    }
  }

  function addPlayerIndicator(
    parent,
    toyComponentCardConfig,
    indexWithinConfig
  ) {
    var numPlayers = 2;
    var counts = toyComponentCardConfig.counts;
    debugLog.debugLog(
      "Cards",
      "Doug: addPlayerIndicator: indexWithinConfig = " + indexWithinConfig
    );
    for (var i = 0; i < counts.length; i++) {
      debugLog.debugLog("Cards", "Doug: addPlayerIndicator: i = " + i);
      debugLog.debugLog(
        "Cards",
        "Doug: addPlayerIndicator: counts[i] = " + counts[i]
      );
      if (indexWithinConfig >= counts[i]) {
        numPlayers++;
        debugLog.debugLog(
          "Cards",
          "Doug: addPlayerIndicator: numPlayers = " + numPlayers
        );
      }
    }

    console.assert(numPlayers >= 3, "numPlayers must be at least 3");

    var playerIndicatorNode = htmlUtils.addDiv(
      parent,
      ["player_indicator"],
      "playerIndicator"
    );
    htmlUtils.addImage(playerIndicatorNode, ["player"], "player");
    var maybePlus = numPlayers == gameInfo.maxPlayers ? "" : "+";
    htmlUtils.addDiv(
      playerIndicatorNode,
      ["player_count"],
      "playerCount",
      numPlayers.toString() + maybePlus
    );
    return playerIndicatorNode;
  }

  // A display if n fixed-sized cards in some fixed width.
  function addMiniCardCollection(parentNode, craftConfig) {
    var number = craftConfig.number;
    console.assert(number > 0, "Number must be defined");

    var cardCollectionNode = htmlUtils.addDiv(
      parentNode,
      ["card_collection"],
      "cardCollection"
    );

    domStyle.set(cardCollectionNode, {
      width: `${minicardCollectionWidth}px`,
      height: `${minicardCollectionHeight}px`,
    });

    var widthMinusPoofedCard =
      minicardCollectionWidth - minicardWidth - minicardBorderWidth * 2;
    var leftChunk = widthMinusPoofedCard / (number - 1);

    for (var i = 0; i < number; i++) {
      var minicardNode = makeMinicard(cardCollectionNode);
      var cardLeft = i * leftChunk;
      domStyle.set(minicardNode, {
        left: `${cardLeft}px`,
      });
    }

    return cardCollectionNode;
  }

  function addCardCorners(parent, cardClass) {
    if (cardClass == null || cardClass == undefined) {
      return;
    }

    var indexClass = "index0";
    htmlUtils.addImage(
      parent,
      [cardClass, whiteOutlineClass, "toy_component_image", indexClass],
      "toyComponentImage"
    );
  }

  function addCannotBeCraftedNode(parent) {
    var cannotBeCraftedNode = htmlUtils.addDiv(
      parent,
      ["cannot_be_crafted"],
      "cannotBeCrafted"
    );
    var deskNode = htmlUtils.addImage(
      cannotBeCraftedNode,
      ["desk", "dark_shadowed"],
      "desk"
    );
    htmlUtils.addImage(deskNode, ["noSymbol"], "noSymbol");
    return cannotBeCraftedNode;
  }

  function maybeAddStandardCraftngInfo(parentNode, toyComponentCardConfig) {
    var craftingNode = null;
    if (toyComponentCardConfig.craft) {
      var craftConfig = toyComponentCardConfig.craft;
      if (craftConfig.number > 0) {
        craftingNode = htmlUtils.addDiv(
          parentNode,
          ["craft_wrapper", "unbroken_row"],
          "craftWrapper"
        );
        addMiniCardCollection(craftingNode, craftConfig);
        insertSomethingEqualsPointsNode(craftingNode, craftConfig.points);
      } else {
        craftingNode = addCannotBeCraftedNode(parentNode);
      }
    }
    return craftingNode;
  }

  function maybeAddStandardFloorPenalty(parentNode, toyComponentCardConfig) {
    if (toyComponentCardConfig.floor) {
      var floorWrapperNode = htmlUtils.addDiv(
        parentNode,
        ["floor_wrapper", "unbroken_row"],
        "floorWrapper"
      );
      var floorImageNode = htmlUtils.addImage(
        floorWrapperNode,
        ["floor"],
        "floor"
      );
      insertSomethingEqualsPointsNode(
        floorWrapperNode,
        toyComponentCardConfig.floor
      );
    }
  }

  function addToyComponentFields(
    parent,
    toyComponentCardConfig,
    indexWithinConfig
  ) {
    // These are the toy icons in upper left and lower corer of card.
    addCardCorners(parent, toyComponentCardConfig.class);

    var counts = toyComponentCardConfig.counts;
    var minCount = counts[0];

    if (indexWithinConfig >= minCount) {
      addPlayerIndicator(parent, toyComponentCardConfig, indexWithinConfig);
    }

    var mainWrapper = htmlUtils.addDiv(parent, ["main_wrapper"], "mainWapper");
    if (toyComponentCardConfig.title) {
      var imageNode = htmlUtils.addDiv(mainWrapper, ["title"], "title");
      imageNode.innerHTML = toyComponentCardConfig.title;
    }

    maybeAddStandardCraftngInfo(mainWrapper, toyComponentCardConfig);

    if (toyComponentCardConfig.specialImageClasses) {
      addSpecialImages(mainWrapper, toyComponentCardConfig);
    }

    if (toyComponentCardConfig.specialCustoms) {
      var specialCustomsWrapper = htmlUtils.addDiv(
        mainWrapper,
        ["special_customs_wrapper", "unbroken_row"],
        "specialCustomsWrapper"
      );
      for (var i = 0; i < toyComponentCardConfig.specialCustoms.length; i++) {
        addNthSpecialCustom(
          specialCustomsWrapper,
          toyComponentCardConfig.specialCustoms,
          i
        );
      }
    }

    maybeAddStandardFloorPenalty(mainWrapper, toyComponentCardConfig);
  }

  function addToyComponentCardBack(parent, null_title, color) {
    var backNode = htmlUtils.addCard(parent, ["back", "toy_component"], "back");

    // Title should be null or undefined or whatever.
    console.assert(!null_title, "Title should be null for back card");

    cards.setCardSize(backNode);

    var insetNode = htmlUtils.addDiv(backNode, ["inset"], "inset");
    var gradient = string.substitute("radial-gradient(#ffffff 50%, ${color})", {
      color: color,
    });
    domStyle.set(insetNode, "background", gradient);

    htmlUtils.addImage(insetNode, ["santa"], "santa");

    return backNode;
  }

  function calculatePlayerBasedInstanceCount(toyComponentCardConfig) {
    switch (toyComponentCardConfig.playType) {
      case "normal":
        {
          var scale = -1.5 * toyComponentCardConfig.craft.points + 9;
          retVal = Math.ceil(scale * gameInfo.maxPlayers + 1);
        }
        break;
      case "challenge":
        {
          retVal = 4 * Math.ceil(gameInfo.maxPlayers / 2) + 2;
        }
        break;
      default:
        {
          retVal = Math.ceil(gameInfo.maxPlayers / 2);
        }
        break;
    }
    return retVal;
  }

  function addToyComponentCardFront(
    parent,
    toyComponentCardConfig,
    index,
    opt_indexWithinConfig
  ) {
    var indexWithinConfig =
      opt_indexWithinConfig !== undefined ? opt_indexWithinConfig : 0;

    var idElements = ["toyComponent", index.toString()];
    var id = idElements.join(".");

    var classArray = [];
    classArray.push("toy_component");
    classArray.push(toyComponentCardConfig.class);
    var cardFrontNode = cards.addCardFront(parent, classArray, id);

    var gradient = `radial-gradient(#ffffff 65%, ${toyComponentCardConfig.color})`;

    domStyle.set(cardFrontNode, {
      background: gradient,
      "border-color": toyComponentCardConfig.borderColor,
    });

    addToyComponentFields(
      cardFrontNode,
      toyComponentCardConfig,
      indexWithinConfig
    );
    return cardFrontNode;
  }

  function addCardFrontAtIndex(parent, index) {
    console.assert(parent, "parent is null");
    var toyComponentCardConfig = cards.getCardConfigFromIndex(
      toyComponentCardConfigs,
      index
    );
    var indexWithinConfig = cards.getIndexWithinConfig(
      toyComponentCardConfigs,
      index
    );

    debugLog.debugLog("Cards", "Doug: addCardFrontAtIndex: index = " + index);
    debugLog.debugLog(
      "Cards",
      "Doug: addCardFrontAtIndex: toyComponentCardConfigs = " +
        JSON.stringify(toyComponentCardConfigs)
    );

    debugLog.debugLog(
      "Cards",
      "Doug addCardFrontAtIndex toyComponentCardConfig = " +
        JSON.stringify(toyComponentCardConfig)
    );

    addToyComponentCardFront(
      parent,
      toyComponentCardConfig,
      index,
      indexWithinConfig
    );
  }

  // Use code to figure out how many of each card we need.
  for (toyComponentCardConfig of toyComponentCardConfigs) {
    debugLog.debugLog(
      "SantaCards",
      "Doug: toyComponentCardConfig = " + JSON.stringify(toyComponentCardConfig)
    );
    toyComponentCardConfig.count = calculatePlayerBasedInstanceCount(
      toyComponentCardConfig
    );
  }

  var _numToyComponentCards = 0;
  function getNumToyComponentCards() {
    // Wait until we're asked to calculate so system configs can be applied.
    if (_numToyComponentCards === 0) {
      _numToyComponentCards = cards.getNumCardsFromConfigs(
        toyComponentCardConfigs
      );
    }
    return _numToyComponentCards;
  }

  function getToyComponentCardConfigByTitle(title) {
    for (var i = 0; i < toyComponentCardConfigs.length; i++) {
      var toyComponentCardConfig = toyComponentCardConfigs[i];
      if (toyComponentCardConfig.title == title) {
        return toyComponentCardConfig;
      }
    }
    return null;
  }

  // This returned object becomes the defined value of this module
  return {
    getNumToyComponentCards: getNumToyComponentCards,
    addToyComponentCardFront: addToyComponentCardFront,
    addCardFrontAtIndex: addCardFrontAtIndex,
    addToyComponentCardBack: addToyComponentCardBack,
    getToyComponentCardConfigByTitle: getToyComponentCardConfigByTitle,

    toyComponentCardConfigs: toyComponentCardConfigs,
  };
});
