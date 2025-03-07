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
  var specialImageSize = minicardHeight;

  var toyComponentCardConfigs = [
    {
      title: "Doll",
      class: "doll",
      image: "../images/ToyComponents/doll.png",
      craft: {
        number: 3,
        points: 2,
      },
      floor: -2,
      playType: "normal",
      color: "#9B111E",
    },
    {
      title: "Kite",
      class: "kite",
      image: "../images/ToyComponents/kite.png",
      craft: {
        number: 3,
        points: 3,
      },
      floor: -3,
      playType: "normal",
      color: "#9B111E",
    },
    {
      title: "Robot",
      class: "robot",
      image: "../images/ToyComponents/robot.png",
      craft: {
        number: 3,
        points: 4,
      },
      floor: -4,
      playType: "normal",
      color: "#9B111E",
    },
    {
      title: "Radio",
      class: "radio",
      image: "../images/ToyComponents/radio.png",
      craft: {
        number: 4,
        points: 10,
      },
      floor: -6,
      playType: "challenge",
      color: "#228b22",
    },
    /*     {
                   title: "Matryoshka",
                   class: "matryoshka",
        image: "../images/ToyComponents/matryoshka.png",
                   craft: {
          number: 4,
          plus: true,
          pointsPerCard: 2,
        },
        floor: -6,
        playType: "challenge",
        color: "#228b22",
               },
    */
    {
      title: "Reindeer Poop",
      class: "poop",
      image: "../images/ToyComponents/poop.png",
      special: "No Crafting",
      floor: -7,
      playType: "special",
      color: "#593002",
    },
    {
      title: "Wrapping Paper",
      class: "wrappingPaper",
      image: "../images/ToyComponents/wrappingPaper.png",
      special: "x2",
      floor: -2,
      playType: "special",
      color: "#FFD700",
    },
    {
      title: "Elf Magic",
      class: "elfMagic",
      image: "../images/ToyComponents/elfMagic.png",
      specialImages: [
        "../images/ToyComponents/doll.png",
        "../images/ToyComponents/kite.png",
        "../images/ToyComponents/robot.png",
      ],
      specialImagesSeparator: "/",
      floor: -2,
      playType: "special",
      color: "#FFD700",
    },
    {
      title: "Broom",
      class: "broom",
      image: "../images/ToyComponents/broom.png",
      specialImages: [
        "../images/ToyComponents/floor.png",
        "../images/ToyComponents/rightArrow.png",
        "../images/ToyComponents/floor.png",
      ],
      floor: -2,
      playType: "special",
      color: "#FFD700",
    },
    /*
               {
                   title: "Gloves",
                   class: "gloves",
        image: "../images/ToyComponents/gloves.png",
        specialImages: [
          "../images/ToyComponents/floor.png",
          "../images/ToyComponents/rightArrow.png",
          "../images/ToyComponents/workbench.png",
        ],
        floor: -10,
        playType: "special",
        color: "#FFD700",
               },
               {
                   title: "Fruitcake",
                   class: "fruitcake",
        image: "../images/ToyComponents/fruitcake.png",
        specialImages: [
          "../images/ToyComponents/fruitcake.png",
          "../images/ToyComponents/doubleArrow.png",
          "card",
        ],
        floor: -10,
        playType: "special",
        color: "#FFD700",
               },*/
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
          ["toyComponentImage", toyComponentCardConfig.class, indexClass],
          "toyComponentImage"
        );

        if (toyComponentCardConfig.image) {
          domStyle.set(imageNode, {
            backgroundImage: `url(${toyComponentCardConfig.image})`,
          });
        }
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

    if (toyComponentCardConfig.special) {
      special = htmlUtils.addDiv(
        wrapper,
        ["special"],
        "special",
        toyComponentCardConfig.special
      );
    }

    if (toyComponentCardConfig.specialImages) {
      var imagesWrapper = htmlUtils.addDiv(
        wrapper,
        ["imagesWrapper"],
        "imagesWrapper"
      );
      var separator = toyComponentCardConfig.specialImagesSeparator
        ? toyComponentCardConfig.specialImagesSeparator
        : "&nbsp;";
      for (var i = 0; i < toyComponentCardConfig.specialImages.length; i++) {
        var specialImage = toyComponentCardConfig.specialImages[i];

        if (separator && i > 0) {
          htmlUtils.addDiv(
            imagesWrapper,
            ["specialImageSpacer"],
            "specialImageSpacer",
            separator
          );
        }

        if (specialImage == "card") {
          makeMinicard(imagesWrapper);
        } else {
          var image = htmlUtils.addImage(
            imagesWrapper,
            ["special_image"],
            "specialImage"
          );
          domStyle.set(image, {
            backgroundImage: `url(${specialImage})`,
            height: `${specialImageSize}px`,
            width: `${specialImageSize}px`,
          });
        }
      }
    }

    if (toyComponentCardConfig.floor) {
      var floorWrapper = htmlUtils.addDiv(
        wrapper,
        ["floorWrapper"],
        "floorWrapper"
      );
      htmlUtils.addImage(floorWrapper, ["floor"], "floor");
      htmlUtils.addDiv(
        floorWrapper,
        ["penalty"],
        "penalty",
        ` = ${toyComponentCardConfig.floor}`
      );
    }
  }

  function addToyComponentCardBack(parent, title, color) {
    var backNode = htmlUtils.addCard(parent, ["back", "toyComponent"], "back");

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
    classArray.push("toyComponent");
    classArray.push(toyComponentCardConfig.class);
    var cardFrontNode = cards.addCardFront(parent, classArray, id);

    var gradient = `radial-gradient(#ffffff 70%, ${toyComponentCardConfig.color})`;

    domStyle.set(cardFrontNode, {
      background: gradient,
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
