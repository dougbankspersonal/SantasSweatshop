define([
  "dojo/dom",
  "dojo/dom-construct",
  "dojo/dom-style",
  "dojo/query",
  "javascript/rowTypes",
  "javascript/versionDetails",
  "sharedJavascript/debugLog",
  "sharedJavascript/systemConfigs",
  "dojo/domReady!",
], function (
  dom,
  domConstruct,
  domStyle,
  query,
  rowTypes,
  versionDetails,
  debugLog,
  systemConfigs
) {
  var pixelsPerInch = 300;
  var pageNumber = 0;
  var cardNumber = 0;

  var pageOfItemsContentsPaddingPx = 10;

  var sidebarWidth = 360;
  var standardBorderWidth = 2;

  // Slots, elements, tiles.
  var slotWidth = 180;

  var elementHeight = slotWidth - 20;
  var elementWidth = elementHeight;

  var conveyorTileOnBoardLeftMargin = 20;
  var conveyorTileOnBoardTopMargin = 10;

  var dieWidth = 150;
  var dieHeight = dieWidth;
  var dieColulmnsAcross = 3;

  // For a tile, it lays across two side by side slots:
  //
  // Slots: +------a------+------a------+
  // Tile : +-c-+---------b---------+-c-+
  // Where a is slotWidth, b is conveyorTileWidth, and c is conveyorTileOnBoardLeftMargin.
  // So...
  var conveyorTileWidth = 2 * (slotWidth - conveyorTileOnBoardLeftMargin);
  var conveyorTileHeight =
    rowTypes.standardRowHeight - 2 * conveyorTileOnBoardTopMargin;

  // So we have this:
  // +------a------+------a------+
  // +-c-+---------b---------+-c-+
  // where b is the width of a tile, and c is conveyorTileOnBoardLeftMargin.
  // There's also a margin:
  var conveyorTileBorder = 2;

  // Border on both sides: the space inside the tile is actually this big:
  var conveyorTileInnerWidth = conveyorTileWidth - 2 * conveyorTileBorder;

  // So if belt elements are children of the tile div, what is the position that'd
  // put the belt in the center of a slot?
  var beltCenterOffsetInConveyorTile =
    slotWidth / 2 - conveyorTileOnBoardLeftMargin - conveyorTileBorder;

  var printedPagePortraitWidth = 816;
  var printedPagePortraitHeight = 1056;
  var printedPageLandscapeWidth = printedPagePortraitHeight;
  var printedPageLandscapeHeight = printedPagePortraitWidth;
  var pagePadding = 10;

  // Cards.
  var smallCardWidth = slotWidth - 20;
  var smallCardHeight = 1.4 * smallCardWidth;
  var smallCardBackFontSize = smallCardWidth * 0.2;
  var cardBorderWidth = 5;

  var cardWidth = 1.4 * smallCardWidth;
  var cardHeight = 1.4 * smallCardHeight;
  var cardBackFontSize = cardWidth * 0.2;

  var ttsSmallCardPageWidth = 10 * smallCardWidth;
  var ttsCardPageWidth = 10 * cardWidth;

  var boxesRowMarginTop = 5;

  var nutTypeAlmond = "Almond";
  var nutTypeCashew = "Cashew";
  var nutTypePeanut = "Peanut";
  var nutTypePistachio = "Pistachio";

  var nutTypes = [
    nutTypeAlmond,
    nutTypeCashew,
    nutTypePeanut,
    nutTypePistachio,
  ];

  var starImage = "images/Markers/Star.png";
  var salterImage = "images/Markers/Salter.png";
  var squirrelImage = "images/Markers/Squirrel.png";

  var saltedTypes = ["Salted", "Unsalted"];

  var roastedTypes = ["Roasted", "Raw"];

  var saltedTypeImages = [
    "images/NutProps/Salted.Y.png",
    "images/NutProps/Salted.N.png",
  ];
  var roastedTypeImages = [
    "images/NutProps/Roasted.Y.png",
    "images/NutProps/Roasted.N.png",
  ];

  var wildImage = "images/Order/Order.Wild.png";

  function addDiv(parent, classArray, id, opt_innerHTML = "") {
    console.assert(parent, "parent is null");
    var classes = classArray.join(" ");
    var node = domConstruct.create(
      "div",
      {
        innerHTML: opt_innerHTML,
        className: classes,
        id: id,
      },
      parent
    );
    return node;
  }

  function addStandardBorder(node) {
    domStyle.set(node, {
      border: standardBorderWidth + "px solid black",
    });
  }

  function isString(value) {
    return typeof value === "string";
  }

  function extendOptClassArray(opt_classArray, newClassOrClasses) {
    debugLog.debugLog(
      "ScoringTrack",
      "extendOptClassArray: opt_classArray == " + opt_classArray
    );
    debugLog.debugLog(
      "ScoringTrack",
      "extendOptClassArray: newClassOrClasses == " + newClassOrClasses
    );
    var classArray = opt_classArray ? opt_classArray : [];
    console.assert(
      typeof classArray === "object",
      "classArray is not an object"
    );
    if (isString(newClassOrClasses)) {
      classArray.push(newClassOrClasses);
      return classArray;
    } else {
      // must be an array
      var newClassArray = classArray.concat(newClassOrClasses);
      return newClassArray;
    }
  }

  function getSlotId(rowIndex, columnIndex) {
    var idPieces = ["slot", rowIndex.toString(), columnIndex.toString()];
    return idPieces.join("_");
  }

  function getRowId(rowIndex) {
    var idPieces = ["row", rowIndex.toString()];
    return idPieces.join("_");
  }

  function getElementId(columnIndex) {
    var elementId = "element_".concat(columnIndex.toString());
    return elementId;
  }

  function getElementFromRow(rowNode, columnIndex) {
    var elementId = getElementId(columnIndex);
    var elementNodes = query(`#${elementId}`, rowNode);
    return elementNodes[0];
  }

  function addImage(parent, classArray, id, opt_image) {
    console.assert(classArray != null, "classArray is null");
    console.assert(parent, "parent is null");
    if (!opt_image) {
      classArray.unshift("pseudo_image");
    }
    var classes = classArray.join(" ");
    var props = {
      innerHTML: "",
      className: classes,
      id: id,
    };
    var node;
    if (opt_image) {
      props.src = opt_image;
      node = domConstruct.create("img", props, parent);
    } else {
      node = domConstruct.create("div", props, parent);
    }
    return node;
  }

  function getPageWidth(configs) {
    if (configs.demoBoard) {
      var demoBoardWidth =
        sidebarWidth +
        versionDetails.getTotalNumColumns() * slotWidth +
        2 * standardBorderWidth;
      return demoBoardWidth;
    }
    if (configs.landscape) {
      return printedPageLandscapeWidth;
    }

    if (configs.ttsCards) {
      if (configs.smallCards) {
        return ttsSmallCardPageWidth;
      } else {
        return ttsCardPageWidth;
      }
    }

    if (configs.ttsDie) {
      return dieColulmnsAcross * dieWidth;
    }

    return printedPagePortraitWidth;
  }

  var getPageHeight = function () {
    var sc = systemConfigs.getSystemConfigs();
    if (sc.landscape) {
      return printedPageLandscapeHeight;
    }
    if (sc.demoBoard) {
      var orderedRowTypes = versionDetails.getOrderedRowTypes();
      var numRows = orderedRowTypes.length;
      var lastRowType = orderedRowTypes[numRows - 1];
      if (lastRowType == rowTypes.RowTypes.Boxes) {
        var numNonOrderRows = numRows - 1;
        return (
          2 * standardBorderWidth +
          numNonOrderRows * rowTypes.standardRowHeight +
          boxesRowMarginTop +
          cardBorderWidth +
          smallCardHeight +
          cardBorderWidth
        );
      } else {
        return numRows * rowTypes.standardRowHeight;
      }
    }
    return null;
  };

  function addPageOfItems(parent, opt_classArray) {
    var sc = systemConfigs.getSystemConfigs();
    console.assert(parent, "parent is null");
    var classArray = extendOptClassArray(opt_classArray, "pageOfItems");
    var pageId = "pageOfItems_".concat(pageNumber.toString());
    pageNumber++;

    if (sc.demoBoard) {
      classArray.push("demoBoard");
    }

    var pageOfItems = addDiv(parent, classArray, pageId);
    if (sc.ttsCards || sc.ttsDie) {
      domStyle.set(pageOfItems, {
        display: "inline-block",
      });
    }

    var pageOfItemsContents = addDiv(
      pageOfItems,
      ["pageOfItemsContents"],
      "pageOfItemsContents"
    );

    var width = getPageWidth(sc);
    var height = getPageHeight(sc);

    if (sc.ttsCards || sc.ttsDie) {
      domStyle.set(pageOfItemsContents, {
        position: "relative",
        top: "0px",
        left: "0px",
        display: "inline-block",
        "text-align": "left",
      });
    } else {
      domStyle.set(pageOfItemsContents, {
        padding: pageOfItemsContentsPaddingPx + "px",
      });
    }

    domStyle.set(pageOfItemsContents, {
      width: width + "px",
    });

    if (height !== null) {
      domStyle.set(pageOfItemsContents, {
        height: height + "px",
      });
    }
    return pageOfItemsContents;
  }

  function addRow(parent, opt_classArray, rowIndex) {
    var sc = systemConfigs.getSystemConfigs();
    console.assert(parent, "parent is null");
    var classArray = extendOptClassArray(opt_classArray, "row");
    if (sc.demoBoard) {
      classArray.push("demoBoard");
    }
    var rowId = getRowId(rowIndex);
    var row = addDiv(parent, classArray, rowId);
    return row;
  }

  function addCard(parent, opt_classArray, opt_id) {
    var sc = systemConfigs.getSystemConfigs();
    console.assert(parent, "parent is null");
    var classArray = extendOptClassArray(opt_classArray, "card");
    if (sc.demoBoard) {
      classArray.push("demoBoard");
    }
    var cardId;
    if (opt_id) {
      cardId = opt_id;
    } else {
      cardId = "card.".concat(cardNumber.toString());
      cardNumber++;
    }
    var node = addDiv(parent, classArray, cardId);
    if (sc.ttsCards) {
      domStyle.set(node, {
        "margin-bottom": "0px",
        "margin-right": "0px",
      });
    }
    domStyle.set(node, {
      border: `${cardBorderWidth}px solid #000`,
    });
    return node;
  }

  // Function to convert hexadecimal color to RGB
  function hexToRgb(hex) {
    var r = parseInt(hex.substring(1, 3), 16);
    var g = parseInt(hex.substring(3, 5), 16);
    var b = parseInt(hex.substring(5, 7), 16);
    return [r, g, b];
  }

  // Function to convert RGB color to hexadecimal
  function rgbToHex(r, g, b) {
    return "#" + componentToHex(r) + componentToHex(g) + componentToHex(b);
  }

  function componentToHex(c) {
    var hex = c.toString(16);
    return hex.length == 1 ? "0" + hex : hex;
  }

  function blendHexColors(color1, color2) {
    // Parse hexadecimal color strings into arrays of RGB values
    var rgb1 = hexToRgb(color1);
    var rgb2 = hexToRgb(color2);

    // Calculate the blended RGB values
    var blendedRgb = [
      Math.round((rgb1[0] + rgb2[0]) / 2),
      Math.round((rgb1[1] + rgb2[1]) / 2),
      Math.round((rgb1[2] + rgb2[2]) / 2),
    ];

    // Convert blended RGB values to hexadecimal format
    var blendedHex = rgbToHex(blendedRgb[0], blendedRgb[1], blendedRgb[2]);

    return blendedHex;
  }

  function getRandomInt(max) {
    return Math.floor(Math.random() * max);
  }

  function seededRandom(seed) {
    let currentSeed = seed;

    // Simple linear congruential generator (LCG)
    return function () {
      currentSeed = (currentSeed * 9301 + 49297) % 233280;
      return currentSeed / 233280;
    };
  }

  const tiltRandom = seededRandom(234232443);
  function addQuasiRandomTilt(node, minTilt, maxTilt) {
    var zeroToOneRandom = tiltRandom();
    var tilt = minTilt + zeroToOneRandom * (maxTilt - minTilt);
    domStyle.set(node, {
      transform: `rotate(${tilt}deg)`,
    });
  }

  var cardSlotOutlineHeight = 4;

  var beltSegmentZIndex = 1000000;
  var beltZIndex = 2;
  var elementZIndex = beltZIndex + 1;
  var markerZIndex = elementZIndex + 1;
  var conveyorTileZIndex = markerZIndex + 1;
  var arrowZIndex = conveyorTileZIndex + 1;

  var beltSegmentsPerRow = 8;
  var beltSegmentOffset = rowTypes.standardRowHeight / beltSegmentsPerRow;
  var beltSegmentHeight = beltSegmentOffset + 2;
  var beltSegmentWidth = 40;

  function getIndexForFirstRowType(orderedRowTypes, thisRowType) {
    for (var i = 0; i < orderedRowTypes.length; i++) {
      var rowType = orderedRowTypes[i];
      if (rowType == thisRowType) {
        return i;
      }
    }
    return null;
  }

  function getSlot(rowIndex, columnIndex) {
    var slotId = getSlotId(rowIndex, columnIndex);
    return dom.byId(slotId);
  }

  // This returned object becomes the defined value of this module
  return {
    slotWidth: slotWidth,
    standardBorderWidth: standardBorderWidth,
    beltCenterOffsetInConveyorTile: beltCenterOffsetInConveyorTile,
    elementHeight: elementHeight,
    elementWidth: elementWidth,
    arrowWidth: elementWidth / 2,
    arrowHeight: elementHeight / 2,
    elementTopAndBottomMargin: (rowTypes.standardRowHeight - elementHeight) / 2,
    elementLeftAndRightMargin: (slotWidth - elementWidth) / 2,
    conveyorTileWidth: conveyorTileWidth,
    conveyorTileHeight: conveyorTileHeight,
    conveyorTileBorder: conveyorTileBorder,
    conveyorTileInnerWidth: conveyorTileInnerWidth,
    beltSegmentZIndex: beltSegmentZIndex,
    beltSegmentsPerRow: beltSegmentsPerRow,
    beltSegmentOffset: beltSegmentOffset,
    beltSegmentHeight: beltSegmentHeight,
    beltSegmentWidth: beltSegmentWidth,

    nutTypeAlmond: nutTypeAlmond,
    nutTypeCashew: nutTypeCashew,
    nutTypePeanut: nutTypePeanut,
    nutTypePistachio: nutTypePistachio,

    smallCardHeight: smallCardHeight,
    smallCardWidth: smallCardWidth,
    smallCardBackFontSize: smallCardBackFontSize,

    cardHeight: cardHeight,
    cardWidth: cardWidth,
    cardBackFontSize: cardBackFontSize,

    nutTypes: nutTypes,
    starImage: starImage,
    salterImage: salterImage,
    squirrelImage: squirrelImage,

    saltedTypes: saltedTypes,
    numSaltedTypes: saltedTypes.length,
    saltedTypeImages: saltedTypeImages,

    roastedTypes: roastedTypes,
    numRoastedTypes: roastedTypes.length,
    roastedTypeImages: roastedTypeImages,

    wildImage: wildImage,
    boxesRowMarginTop: boxesRowMarginTop,
    cardSlotOutlineHeight: cardSlotOutlineHeight,
    elementZIndex: elementZIndex,
    markerZIndex: markerZIndex,
    arrowZIndex: arrowZIndex,
    conveyorTileZIndex: conveyorTileZIndex,
    beltZIndex: beltZIndex,
    conveyorTileOnBoardLeftMargin: conveyorTileOnBoardLeftMargin,
    conveyorTileOnBoardTopMargin: conveyorTileOnBoardTopMargin,
    sidebarWidth: sidebarWidth,
    printedPagePortraitWidth: printedPagePortraitWidth,
    printedPagePortraitHeight: printedPagePortraitHeight,
    printedPageLandscapeWidth: printedPageLandscapeWidth,
    printedPageLandscapeHeight: printedPageLandscapeHeight,
    dieWidth: dieWidth,
    dieHeight: dieHeight,
    pagePadding: pagePadding,
    pixelsPerInch: pixelsPerInch,
    cardBorderWidth: cardBorderWidth,

    addDiv: addDiv,
    addImage: addImage,
    addPageOfItems: addPageOfItems,
    addRow: addRow,
    addCard: addCard,
    blendHexColors: blendHexColors,
    getRandomInt: getRandomInt,
    getIndexForFirstRowType: getIndexForFirstRowType,
    getSlot: getSlot,
    extendOptClassArray: extendOptClassArray,
    getSlotId: getSlotId,
    getRowId: getRowId,
    getElementId: getElementId,
    getElementFromRow: getElementFromRow,
    addStandardBorder: addStandardBorder,
    seededRandom: seededRandom,
    addQuasiRandomTilt: addQuasiRandomTilt,
  };
});
