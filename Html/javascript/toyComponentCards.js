/* Deprecated */

define([
	'dojo/string',
	'javascript/gameUtils',
	'javascript/cards',
	'dojo/dom-style',
	'dojo/domReady!',
], function(string, gameUtils, cards, domStyle) {

    var minicardWidth = 30
    var minicardHeight = minicardWidth * 1.4
    var minicardMargin = minicardWidth/2

    function makeMinicard(parent) {
        var minicard = gameUtils.addDiv(parent, ["minicard"], "minicard")
        domStyle.set(minicard, {
            height: `${minicardHeight}px`,
            width: `${minicardWidth}px`,
        })
        return minicard
    }

    function addToyComponentDesc(parent, config) {
        var wrapper = gameUtils.addDiv(parent, ["wrapper"], "wrapper")
        if (config.title) {
            var imageNode = gameUtils.addDiv(wrapper, ["title"], "title")
            imageNode.innerHTML = config.title
        }
        if (config.class) {
            for (var i = 0; i < 4; i++) {
                var indexClass = "index" + i
                var imageNode = gameUtils.addImage(parent, ["toyComponentImage", config.class, indexClass], "toyComponentImage")

                if (config.image) {
                    domStyle.set(imageNode, {
                        backgroundImage: `url(${config.image})`,
                    })
                }
            }
        }

        if (config.craft) {
            var number = config.craft.number
            var points = config.craft.points
            var pointsPerCard = config.craft.pointsPerCard
            var plus = config.craft.plus

            var leftSide
            var rightSide
            if (number) {
                if (plus) {
                    leftSide = `x ${number}+`
                } else {
                    leftSide = `x ${number}`
                }
            }

            if (points) {
                rightSide = `${points} <div class="points">pts.</div>`
            } else if (pointsPerCard) {
                rightSide = `${pointsPerCard} <div class="points">pts./Card</div>`
            }

            var text = `${leftSide} = ${rightSide}`

            var craftWrapper = gameUtils.addDiv(wrapper, ["craftWrapper"], "craftWrapper", text)
        }

        if (config.special) {
            special = gameUtils.addDiv(wrapper, ["special"], "special", config.special)
        }

        if (config.specialImages) {
            var imagesWrapper = gameUtils.addDiv(wrapper, ["imagesWrapper"], "imagesWrapper")
            var separator = config.specialImagesSeparator ? config.specialImagesSeparator : "&nbsp;"
            for (var i = 0; i < config.specialImages.length; i++) {
                var specialImage = config.specialImages[i]

                if (separator && i > 0) {
                    gameUtils.addDiv(imagesWrapper, ["specialImageSpacer"], "specialImageSpacer", separator)
                }

                if (specialImage == "card") {
                    makeMinicard(imagesWrapper)
                } else {
                    var image = gameUtils.addImage(imagesWrapper, ["specialImage"], "specialImage")
                    domStyle.set(image, {
                        backgroundImage: `url(${specialImage})`,
                    })
                }
            }
        }

        if (config.floor) {
            var floorWrapper = gameUtils.addDiv(wrapper, ["floorWrapper"], "floorWrapper")
            gameUtils.addImage(floorWrapper, ["floor"], "floor")
            gameUtils.addDiv(floorWrapper, ["penalty"], "penalty", ` = ${config.floor}`)
        }
    }

    function addToyComponentCard(parent, index, ttsCards, configs) {
        var config
        var originalIndex = index
        for (var i = 0; i < configs.length; i++) {
            var numberPerPlayer = getCountOfCard(ttsCards, configs[i])
            if (numberPerPlayer > index) {
                config = configs[i]
                break
            }
            else
            {
                index -= numberPerPlayer
            }
        }

        var idElements = [
            "toyComponent",
            originalIndex.toString(),
        ]
        var id = idElements.join(".")
        var classArray = []
        classArray.push("toyComponent")
        classArray.push(config.class)
        var node = cards.addCardFront(parent, classArray, id)

        var gradient = `radial-gradient(#ffffff 70%, ${config.color})`
        domStyle.set(node, {
            background: gradient,
        })

        addToyComponentDesc(node, config)
        return node
    }

    function addBack(parent, title, color, opt_configs) {
		var configs = opt_configs ? opt_configs : {}
		var node = gameUtils.addCard(parent, ["back", "toyComponent"], "back")

		cards.setCardSize(node, configs)

		var innerNode = gameUtils.addDiv(node, ["inset"], "inset")
		var gradient = string.substitute('radial-gradient(#ffffff 50%, ${color})', {
			color: color,
		})
		domStyle.set(innerNode, "background", gradient)

        gameUtils.addImage(innerNode, ["santa"], "santa")

		var title = gameUtils.addDiv(innerNode, ["cardTitle"], "cardTitle", title)
		var style = {}
		style["font-size"] = configs.bigCards ? `${gameUtils.bigCardBackFontSize}px`: `${gameUtils.cardBackFontSize}px`
		domStyle.set(title, style)

		return node
    }

    function getCountOfCard(ttsCards, config) {
        if (ttsCards) {
            return 1
        }
        var maxPlayers = 8
        var retVal
        switch(config.playType) {
            case "normal":
                {
                    var scale = -1.5 * config.craft.points + 9
                    retVal = scale * maxPlayers + 1
                }
                break
            case "challenge":
                {
                    retVal = 4 * Math.floor(maxPlayers/2) + 2
                }
                break
            default:
                {
                    retVal = Math.ceil(maxPlayers/2)
                }
                break
        }

        console.log("Doug: config.class = ", config.class)
        console.log("Doug: retVal = ", retVal)
        return retVal
    }

    // This returned object becomes the defined value of this module
    return {
		addToyComponentCard: addToyComponentCard,
        addBack: addBack,
        getCountOfCard: getCountOfCard,
	};
});