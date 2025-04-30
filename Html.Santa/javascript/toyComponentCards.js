/* Deprecated */

define([
  "javascript/gameInfo",
  "sharedJavascript/cards",
  "sharedJavascript/debugLog",
  "sharedJavascript/genericMeasurements",
  "sharedJavascript/htmlUtils",
  "sharedJavascript/systemConfigs",
  "dojo/string",
  "dojo/dom-style",
  "dojo/domReady!",
], function (
  gameInfo,
  cards,
  debugLog,
  genericMeasurements,
  htmlUtils,
  systemConfigs,
  string,
  domStyle
) {
  // Constants
  var minicardWidth = 30;
  var minicardHeight = minicardWidth * 1.4;
  var whiteOutlineClass = "white_outline";

  var specialBorderColor = "#FFD700";
  var basicBorderColor = "#000066";
  var radioBorderColor = "#006600";

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
    },
    {
      title: "Radio",
      class: "radio",
      craft: {
        number: 4,
        points: 10,
      },
      floor: -6,
      playType: "challenge",
      color: "#00aa00",
      borderColor: "radioBorderColor",
    },
    /*     {
                   title: "Matryoshka",
                   class: "matryoshka",
                   craft: {
          number: 4,
          plus: true,
          pointsPerCard: 2,
        },
        floor: -6,
        playType: "challenge",
        borderColor:  "#228b22",
               },
    */
    {
      title: "Reindeer Poop",
      class: "poop",
      special: "No Crafting",
      floor: -7,
      playType: "special",
      color: "#886633",
      borderColor: "#593002",
    },
    {
      title: "Wrapping Paper",
      class: "wrappingPaper",
      special: "x2 pts",
      playType: "special",
      color: "#FF8844",
      borderColor: specialBorderColor,
    },
    {
      title: "Elf Magic",
      class: "elfMagic",
      specialImageClasses: ["doll", "kite", "robot"],
      specialImagesSeparator: "/",
      playType: "special",
      color: "#FF8888",
      borderColor: specialBorderColor,
    },
    {
      title: "Broom",
      class: "broom",
      specialImageClasses: ["floor", "rightArrow", "floor"],
      playType: "special",
      color: "#FFFF88",
      borderColor: specialBorderColor,
    },
    {
      title: "Gloves",
      class: "gloves",
      specialImageClasses: ["floor", "rightArrow", "card"],
      playType: "special",
      color: "#FF4488",
      borderColor: specialBorderColor,
    },
    {
      title: "RC Drone-Borg",
      class: "cyborg",
      specialImageClasses: ["doll", "kite", "robot", "radio"],
      special: "5 pts",
      playType: "special",
      color: "#FF88FF",
      borderColor: specialBorderColor,
    },
    {
      title: "Fruitcake",
      class: "fruitcake",
      specialImageClasses: ["card", "doubleArrow", "card"],
      playType: "special",
      color: "#884444",
      borderColor: specialBorderColor,
    },
    {
      title: "Whistle",
      class: "whistle",
      playType: "special",
      special: "4 pts",
      color: "#888844",
      borderColor: specialBorderColor,
    },
    {
      title: "Knife",
      class: "knife",
      specialImageClasses: ["handshake", "arrow"],
      playType: "special",
      color: "#884488",
      borderColor: specialBorderColor,
    },
    {
      title: "Satin",
      class: "satin",
      specialImageClasses: ["doll", "plus_one_pt"],
      playType: "special",
      color: "#FFCC44",
      borderColor: specialBorderColor,
    },
  ];

  // Functions
  function makeMinicard(parent) {
    var minicard = htmlUtils.addDiv(parent, ["minicard"], "minicard");
    domStyle.set(minicard, {
      height: `${minicardHeight}px`,
      width: `${minicardWidth}px`,
    });
    return minicard;
  }

  function addToyComponentFields(parent, toyComponentCardConfig) {
    var wrapper = htmlUtils.addDiv(parent, ["wrapper"], "wrapper");
    if (toyComponentCardConfig.title) {
      var imageNode = htmlUtils.addDiv(wrapper, ["title"], "title");
      imageNode.innerHTML = toyComponentCardConfig.title;
    }
    if (toyComponentCardConfig.class) {
      for (var i = 0; i < 4; i++) {
        var indexClass = "index" + i;
        var imageNode = htmlUtils.addImage(
          parent,
          [
            whiteOutlineClass,
            "toy_component_image",
            toyComponentCardConfig.class,
            indexClass,
          ],
          "toyComponentImage"
        );
      }
    }

    if (toyComponentCardConfig.craft) {
      var number = toyComponentCardConfig.craft.number;
      var points = toyComponentCardConfig.craft.points;
      var pointsPerCard = toyComponentCardConfig.craft.pointsPerCard;
      var plus = toyComponentCardConfig.craft.plus;

      var leftSide;
      var rightSide;
      if (number) {
        if (plus) {
          leftSide = `x ${number}+`;
        } else {
          leftSide = `x ${number}`;
        }
      }

      if (points) {
        rightSide = `${points} <div class="points">pts.</div>`;
      } else if (pointsPerCard) {
        rightSide = `${pointsPerCard} <div class="points">pts./Card</div>`;
      }

      var text = `${leftSide} = ${rightSide}`;
      htmlUtils.addDiv(wrapper, ["craftWrapper"], "craftWrapper", text);
    }

    if (toyComponentCardConfig.specialImageClasses) {
      var imagesWrapper = htmlUtils.addDiv(
        wrapper,
        ["imagesWrapper"],
        "imagesWrapper"
      );
      var separator = toyComponentCardConfig.specialImagesSeparator
        ? toyComponentCardConfig.specialImagesSeparator
        : "&nbsp;";
      for (
        var i = 0;
        i < toyComponentCardConfig.specialImageClasses.length;
        i++
      ) {
        var specialImageClass = toyComponentCardConfig.specialImageClasses[i];

        if (separator && i > 0) {
          htmlUtils.addDiv(
            imagesWrapper,
            ["specialImageSpacer"],
            "specialImageSpacer",
            separator
          );
        }

        if (specialImageClass == "card") {
          makeMinicard(imagesWrapper);
        } else {
          var image = htmlUtils.addImage(
            imagesWrapper,
            [whiteOutlineClass, "special_image", specialImageClass],
            "specialImage"
          );
        }
      }
    }

    if (toyComponentCardConfig.special) {
      special = htmlUtils.addDiv(
        wrapper,
        ["special"],
        "special",
        toyComponentCardConfig.special
      );
    }

    if (toyComponentCardConfig.floor) {
      var floorWrapper = htmlUtils.addDiv(
        wrapper,
        ["floorWrapper"],
        "floorWrapper"
      );
      htmlUtils.addImage(floorWrapper, ["floor", whiteOutlineClass], "floor");
      htmlUtils.addDiv(
        floorWrapper,
        ["penalty"],
        "penalty",
        ` = ${toyComponentCardConfig.floor}`
      );
    }
  }

  function addToyComponentCardBack(parent, title, color) {
    var backNode = htmlUtils.addCard(parent, ["back", "toy_component"], "back");

    cards.setCardSize(backNode);

    var insetNode = htmlUtils.addDiv(backNode, ["inset"], "inset");
    var gradient = string.substitute("radial-gradient(#ffffff 50%, ${color})", {
      color: color,
    });
    domStyle.set(insetNode, "background", gradient);

    htmlUtils.addImage(insetNode, ["santa"], "santa");

    var title = htmlUtils.addDiv(
      insetNode,
      ["cardBackTitle"],
      "cardBackTitle",
      title
    );
    var style = {};
    var sc = systemConfigs.getSystemConfigs();

    style["font-size"] = sc.smallCards
      ? `${genericMeasurements.cardBackFontSize}px`
      : `${genericMeasurements.bigCardBackFontSize}px`;
    domStyle.set(title, style);

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

  function addCardFrontUsingConfigAndIndex(
    parent,
    toyComponentCardConfig,
    index
  ) {
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

    addToyComponentFields(cardFrontNode, toyComponentCardConfig);
    return cardFrontNode;
  }

  function addCardFrontAtIndex(parent, index) {
    var toyComponentCardConfig = cards.getCardConfigFromIndex(
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

    addCardFrontUsingConfigAndIndex(parent, toyComponentCardConfig, index);
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
    console.log("Doug: getting numToyComponentCards");
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
    addCardFrontUsingConfigAndIndex: addCardFrontUsingConfigAndIndex,
    addCardFrontAtIndex: addCardFrontAtIndex,
    addToyComponentCardBack: addToyComponentCardBack,
    getToyComponentCardConfigByTitle: getToyComponentCardConfigByTitle,

    toyComponentCardConfigs: toyComponentCardConfigs,
  };
});
