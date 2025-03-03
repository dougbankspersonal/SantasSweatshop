/* Deprecated */

define([
  "javascript/gameInfo",
  "javascript/gameUtils",
  "sharedJavascript/cards",
  "sharedJavascript/debugLog",
  "dojo/string",
  "dojo/dom-style",
  "dojo/domReady!",
], function (gameInfo, gameUtils, cards, debugLog, string, domStyle) {
  var minicardWidth = 30;
  var minicardHeight = minicardWidth * 1.4;

  function makeMinicard(parent) {
    var minicard = gameUtils.addDiv(parent, ["minicard"], "minicard");
    domStyle.set(minicard, {
      height: `${minicardHeight}px`,
      width: `${minicardWidth}px`,
    });
    return minicard;
  }

  function addToyComponentDesc(parent, toyComponentCardConfig) {
    var wrapper = gameUtils.addDiv(parent, ["wrapper"], "wrapper");
    if (toyComponentCardConfig.title) {
      var imageNode = gameUtils.addDiv(wrapper, ["title"], "title");
      imageNode.innerHTML = toyComponentCardConfig.title;
    }
    if (toyComponentCardConfig.class) {
      for (var i = 0; i < 4; i++) {
        var indexClass = "index" + i;
        var imageNode = gameUtils.addImage(
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
      gameUtils.addDiv(wrapper, ["craftWrapper"], "craftWrapper", text);
    }

    if (toyComponentCardConfig.special) {
      special = gameUtils.addDiv(
        wrapper,
        ["special"],
        "special",
        toyComponentCardConfig.special
      );
    }

    if (toyComponentCardConfig.specialImages) {
      var imagesWrapper = gameUtils.addDiv(
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
          gameUtils.addDiv(
            imagesWrapper,
            ["specialImageSpacer"],
            "specialImageSpacer",
            separator
          );
        }

        if (specialImage == "card") {
          makeMinicard(imagesWrapper);
        } else {
          var image = gameUtils.addImage(
            imagesWrapper,
            ["specialImage"],
            "specialImage"
          );
          domStyle.set(image, {
            backgroundImage: `url(${specialImage})`,
          });
        }
      }
    }

    if (toyComponentCardConfig.floor) {
      var floorWrapper = gameUtils.addDiv(
        wrapper,
        ["floorWrapper"],
        "floorWrapper"
      );
      gameUtils.addImage(floorWrapper, ["floor"], "floor");
      gameUtils.addDiv(
        floorWrapper,
        ["penalty"],
        "penalty",
        ` = ${toyComponentCardConfig.floor}`
      );
    }
  }

  function addToyComponentCard(parent, toyComponentCardConfig, idHelper) {
    debugLog.debugLog(
      "Cards",
      "Doug addToyComponentCard toyComponentCardConfig = " +
        JSON.stringify(toyComponentCardConfig)
    );
    var idElements = ["toyComponent", idHelper.toString()];
    var id = idElements.join(".");
    var classArray = [];
    classArray.push("toyComponent");
    classArray.push(toyComponentCardConfig.class);
    var node = cards.addCardFront(parent, classArray, id);

    var gradient = `radial-gradient(#ffffff 70%, ${toyComponentCardConfig.color})`;
    domStyle.set(node, {
      background: gradient,
    });

    addToyComponentDesc(node, toyComponentCardConfig);
    return node;
  }

  function addBack(parent, title, color) {
    var configs = gameUtils.getConfigs();
    var node = gameUtils.addCard(parent, ["back", "toyComponent"], "back");

    cards.setCardSize(node, configs);

    var innerNode = gameUtils.addDiv(node, ["inset"], "inset");
    var gradient = string.substitute("radial-gradient(#ffffff 50%, ${color})", {
      color: color,
    });
    domStyle.set(innerNode, "background", gradient);

    gameUtils.addImage(innerNode, ["santa"], "santa");

    var title = gameUtils.addDiv(
      innerNode,
      ["cardBackTitle"],
      "cardBackTitle",
      title
    );
    var style = {};
    style["font-size"] = configs.bigCards
      ? `${gameUtils.bigCardBackFontSize}px`
      : `${gameUtils.cardBackFontSize}px`;
    domStyle.set(title, style);

    return node;
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

  // This returned object becomes the defined value of this module
  return {
    addToyComponentCard: addToyComponentCard,
    addBack: addBack,
    calculatePlayerBasedInstanceCount: calculatePlayerBasedInstanceCount,
  };
});
