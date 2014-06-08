$ = document.getElementById.bind(document)

class Block extends PIXI.Sprite
    @pixel: PIXI.Texture.fromImage('img/pixel.bmp')
    constructor: (x, y, width, height, tint) ->
        super(Block.pixel)
        @width = width
        @height = height
        @tint = tint
        @position.set(x, y)

class ScrollContainer extends PIXI.DisplayObjectContainer
    constructor: (stage) ->
        super()
        @stage = stage
        @stage.addChild(@)
    setView: (x, y) ->
        @position.set(-x, -y)
    scroll: (dx=0, dy=0) ->
        @position.x -= dx
        @position.y -= dy

class Game
    @viewportSize: 512
    constructor: (el) ->
        @stage = new PIXI.Stage(0x222222)
        @renderer = PIXI.autoDetectRenderer(Game.viewportSize, Game.viewportSize, el)
#        @renderer.view.width = @renderer.view.height = @viewportSize
        @scroller = new ScrollContainer(@stage)
        @stage.addChild(@scroller)
        @level = new PIXI.DisplayObjectContainer()
        @scroller.addChild(@level)
        @animate(@)
    animate: (scope) ->
        requestAnimFrame(() -> scope.animate(scope))
        @renderer.render(@stage)
    
    loadLevel: (filename) ->
        for child in @level.children
            level.removeChild(child)
        
        scope = @
        xhr = new XMLHttpRequest()
        xhr.open('GET', filename, true)
        xhr.addEventListener 'load', (event) ->
            json = JSON.parse(xhr.responseText)
            blocks = json.blocks
            for el in blocks
                block = new Block(el[0], el[1], el[2], el[3], parseInt(el[4].substring(1), 16))
                scope.level.addChild(block)

        xhr.send()

game = undefined

document.addEventListener 'DOMContentLoaded', () ->
    game = new Game($('game'))
