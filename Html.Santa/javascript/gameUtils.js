define([
  "dojo/dom",
  "dojo/dom-construct",
  "dojo/dom-style",
  "dojo/query",
  "sharedJavascript/debugLog",
  "sharedJavascript/genericMeasurements",
  "sharedJavascript/systemConfigs",
  "dojo/domReady!",
], function (
  dom,
  domConstruct,
  domStyle,
  query,
  debugLog,
  genericMeasurements,
  systemConfigs
) {
  var pixelsPerInch = 300;
  var pageNumber = 0;
  var cardNumber = 0;

  var pageOfItemsContentsPaddingPx = 10;

  // Cards.
  var smallCardWidth = 160;
  var smallCardHeight = 1.4 * smallCardWidth;
  var smallCardBackFontSize = smallCardWidth * 0.2;
  var cardBorderWidth = 5;

  var cardWidth = 1.4 * smallCardWidth;
  var cardHeight = 1.4 * smallCardHeight;
  var cardBackFontSize = cardWidth * 0.2;

  var boxesRowMarginTop = 5;

  var starImage = "images/Markers/Star.png";

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
      border: genericMeasurements.standardBorderWidth + "px solid black",
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

  const tiltRandom = seededRandom(234232443);
  function addQuasiRandomTilt(node, minTilt, maxTilt) {
    var zeroToOneRandom = tiltRandom();
    var tilt = minTilt + zeroToOneRandom * (maxTilt - minTilt);
    domStyle.set(node, {
      transform: `rotate(${tilt}deg)`,
    });
  }

  var cardSlotOutlineHeight = 4;

  function getSlot(rowIndex, columnIndex) {
    var slotId = getSlotId(rowIndex, columnIndex);
    return dom.byId(slotId);
  }

  // This returned object becomes the defined value of this module
  return {
    smallCardHeight: smallCardHeight,
    smallCardWidth: smallCardWidth,
    smallCardBackFontSize: smallCardBackFontSize,

    cardHeight: cardHeight,
    cardWidth: cardWidth,
    cardBackFontSize: cardBackFontSize,

    boxesRowMarginTop: boxesRowMarginTop,
    cardSlotOutlineHeight: cardSlotOutlineHeight,
    pixelsPerInch: pixelsPerInch,
    cardBorderWidth: cardBorderWidth,

    addDiv: addDiv,
    addImage: addImage,
    addRow: addRow,
    addCard: addCard,
    blendHexColors: blendHexColors,
    getSlot: getSlot,
    extendOptClassArray: extendOptClassArray,
    getSlotId: getSlotId,
    getRowId: getRowId,
    addStandardBorder: addStandardBorder,
    addQuasiRandomTilt: addQuasiRandomTilt,
  };
});
