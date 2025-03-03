define([
  "dojo/dom",
  "dojo/dom-construct",
  "dojo/dom-style",
  "dojo/query",
  "sharedJavascript/debugLog",
  "dojo/domReady!",
], function (dom, domConstruct, domStyle, query, debugLog) {
  var pixelsPerInch = 300;
  var pageNumber = 0;
  var cardNumber = 0;

  var sideBarWidth = 360;
  var standardBorderWidth = 2;

  // Slots, elements, cross tiles.
  var slotWidth = 180;

  var standardRowHeight = 180;
  var boxesRowHeight = standardRowHeight * 0.5;
  var elementHeight = slotWidth - 20;
  var elementWidth = elementHeight;

  var crossTileOnBoardLeftMargin = 20;
  var crossTileOnBoardTopMargin = 10;

  var dieWidth = 150;
  var dieHeight = dieWidth;
  var dieColulmnsAcross = 3;

  // For a cross tile, it lays across two side by side slots:
  //
  // Slots: +------a------+------a------+
  // Tile : +-c-+---------b---------+-c-+
  // Where a is slotWidth, b is crossTileWidth, and c is crossTileOnBoardLeftMargin.
  // So...
  var crossTileWidth = 2 * (slotWidth - crossTileOnBoardLeftMargin);
  var crossTileHeight = standardRowHeight - 2 * crossTileOnBoardTopMargin;

  // So we have this:
  // +------a------+------a------+
  // +-c-+---------b---------+-c-+
  // where b is the width of a cross tile, and c is crossTileOnBoardLeftMargin.
  // There's also a margin:
  var crossTileBorder = 2;

  // Border on both sides: the space inside the cross tile is actually this big:
  var crossTileInnerWidth = crossTileWidth - 2 * crossTileBorder;

  // So if belt elements are children of the cross tile div, what is the position that'd
  // put the belt in the center of a slot?
  var beltCenterOffsetInTile =
    slotWidth / 2 - crossTileOnBoardLeftMargin - crossTileBorder;

  var printedPagePortraitWidth = 816;
  var printedPagePortraitHeight = 1056;
  var printedPageLandscapeWidth = printedPagePortraitHeight;
  var printedPageLandscapeHeight = printedPagePortraitWidth;
  var pageWidthPadding = 10;
  var pageHeightPadding = 20;

  // Cards.
  var cardWidth = slotWidth - 20;
  var cardHeight = Math.floor(1.4 * cardWidth);
  var cardBackFontSize = Math.floor(cardWidth * 0.2);
  var cardBorderWidth = 5;

  var bigCardWidth = Math.floor(1.4 * cardWidth);
  var bigCardHeight = Math.floor(1.4 * cardHeight);
  var bigCardBackFontSize = Math.floor(bigCardWidth * 0.2);

  var ttsCardPageWidth = 10 * cardWidth;
  var ttsBigCardPageWidth = 10 * bigCardWidth;
  var nullPageWidth = "nullPageWidth";

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

  var starImage = "images/Markers/Simple.Star.png";
  var salterImage = "images/Markers/Simple.Salter.png";
  var squirrelImage = "images/Markers/Simple.Squirrel.png";

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
    var classArray = opt_classArray ? opt_classArray : [];
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

  function addImage(parent, opt_classArray, id, opt_image) {
    var classArray = opt_classArray ? opt_classArray : [];
    if (!opt_image) {
      classArray.unshift("pseudoImage");
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
    if (configs.pageWidth) {
      return configs.pageWidth;
    } else if (configs.nullPageWidth) {
      return null;
    } else {
      return printedPagePortraitWidth;
    }
  }

  var getPageHeight = function () {
    if (configs.landscape) {
      return printedPageLandscapeHeight;
    }
    return null;
  };

  function addPageOfItems(parent, opt_classArray) {
    var classArray = extendOptClassArray(opt_classArray, "pageOfItems");
    var pageId = "pageOfItems_".concat(pageNumber.toString());
    pageNumber++;

    var configs = getConfigs();
    var pageOfItems = addDiv(parent, classArray, pageId);
    debugLog.debugLog(
      "Cards",
      `addPageOfItems configs = ${JSON.stringify(configs)}`
    );
    if (configs.pageOfItemsIsInlineBlock) {
      domStyle.set(pageOfItems, {
        display: "inline-block",
      });
    }

    var pageOfItemsContents = addDiv(
      pageOfItems,
      ["pageOfItemsContents"],
      "pageOfItemsContents"
    );

    var pageWidth = getPageWidth(configs);
    var pagehHeight = getPageHeight(configs);

    if (configs.skipPadding) {
      domStyle.set(pageOfItemsContents, {
        position: "relative",
        top: "0px",
        left: "0px",
        display: "inline-block",
        "text-align": "left",
      });
    } else {
      domStyle.set(pageOfItemsContents, {
        "padding-left": pageWidthPadding + "px",
        "padding-right": pageWidthPadding + "px",
        "padding-top": pageHeightPadding + "px",
        "padding-bottom": pageHeightPadding + "px",
      });
    }

    if (configs.pageWidth == nullPageWidth) {
      domStyle.set(pageOfItemsContents, {
        "white-space": "nowrap",
      });
    }

    if (pageWidth !== null) {
      domStyle.set(pageOfItemsContents, {
        width: pageWidth + "px",
      });
    }

    if (pagehHeight !== null) {
      domStyle.set(pageOfItemsContents, {
        height: pagehHeight + "px",
      });
    }
    return pageOfItemsContents;
  }

  function addRow(parent, opt_classArray, rowIndex) {
    var classArray = extendOptClassArray(opt_classArray, "row");
    var rowId = getRowId(rowIndex);
    var row = addDiv(parent, classArray, rowId);
    addStandardBorder(row);
    return row;
  }

  function addCard(parent, opt_classArray, opt_id) {
    var classArray = extendOptClassArray(opt_classArray, "card");
    var cardId;
    if (opt_id) {
      cardId = opt_id;
    } else {
      cardId = "card.".concat(cardNumber.toString());
      cardNumber++;
    }
    var node = addDiv(parent, classArray, cardId);
    if (configs.skipPadding) {
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
  var crossTileZIndex = markerZIndex + 1;
  var arrowZIndex = crossTileZIndex + 1;

  var beltSegmentsPerRow = 8;
  var beltSegmentOffset = standardRowHeight / beltSegmentsPerRow;
  var beltSegmentHeight = beltSegmentOffset + 2;
  var beltSegmentWidth = 40;

  function getSlot(rowIndex, columnIndex) {
    var slotId = getSlotId(rowIndex, columnIndex);
    return dom.byId(slotId);
  }

  // This returned object becomes the defined value of this module
  return {
    slotWidth: slotWidth,
    standardBorderWidth: standardBorderWidth,
    beltCenterOffsetInTile: beltCenterOffsetInTile,
    standardRowHeight: standardRowHeight,
    boxesRowHeight: boxesRowHeight,
    elementHeight: elementHeight,
    elementWidth: elementWidth,
    arrowWidth: elementWidth / 2,
    arrowHeight: elementHeight / 2,
    elementTopAndBottomMargin: (standardRowHeight - elementHeight) / 2,
    elementLeftAndRightMargin: (slotWidth - elementWidth) / 2,
    crossTileWidth: crossTileWidth,
    crossTileHeight: crossTileHeight,
    crossTileBorder: crossTileBorder,
    crossTileInnerWidth: crossTileInnerWidth,
    beltSegmentZIndex: beltSegmentZIndex,
    beltSegmentsPerRow: beltSegmentsPerRow,
    beltSegmentOffset: beltSegmentOffset,
    beltSegmentHeight: beltSegmentHeight,
    beltSegmentWidth: beltSegmentWidth,

    nutTypeAlmond: nutTypeAlmond,
    nutTypeCashew: nutTypeCashew,
    nutTypePeanut: nutTypePeanut,
    nutTypePistachio: nutTypePistachio,

    cardHeight: cardHeight,
    cardWidth: cardWidth,
    cardBackFontSize: cardBackFontSize,

    bigCardHeight: bigCardHeight,
    bigCardWidth: bigCardWidth,
    bigCardBackFontSize: bigCardBackFontSize,

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
    crossTileZIndex: crossTileZIndex,
    beltZIndex: beltZIndex,
    crossTileOnBoardLeftMargin: crossTileOnBoardLeftMargin,
    crossTileOnBoardTopMargin: crossTileOnBoardTopMargin,
    sideBarWidth: sideBarWidth,
    printedPagePortraitWidth: printedPagePortraitWidth,
    printedPagePortraitHeight: printedPagePortraitHeight,
    printedPageLandscapeWidth: printedPageLandscapeWidth,
    printedPageLandscapeHeight: printedPageLandscapeHeight,
    dieWidth: dieWidth,
    dieHeight: dieHeight,
    pageWidthPadding: pageWidthPadding,
    pageHeightPadding: pageHeightPadding,
    pixelsPerInch: pixelsPerInch,
    ttsBigCardPageWidth: ttsBigCardPageWidth,
    nullPageWidth: nullPageWidth,
    ttsCardPageWidth: ttsCardPageWidth,
    dieColulmnsAcross: dieColulmnsAcross,
    dieWidth: dieWidth,

    addDiv: addDiv,
    addImage: addImage,
    addPageOfItems: addPageOfItems,
    addRow: addRow,
    addCard: addCard,
    blendHexColors: blendHexColors,
    getRandomInt: getRandomInt,
    seededRandom: seededRandom,
    addQuasiRandomTilt: addQuasiRandomTilt,
    getSlot: getSlot,
    extendOptClassArray: extendOptClassArray,
    getSlotId: getSlotId,
    getRowId: getRowId,
    getElementId: getElementId,
    getElementFromRow: getElementFromRow,
    addStandardBorder: addStandardBorder,
  };
});
