$ = document.getElementById.bind(document)

PIXI.DisplayObjectContainer::bounds = () ->
    r = new PIXI.Rectangle
    r.x = @position.x - @anchor.x * @width
    r.y = @position.y - @anchor.y * @height
    r.width = @width
    r.height = @height
    return r

class Block extends PIXI.Sprite
    @pixel: PIXI.Texture.fromImage('img/pixel.bmp')
    constructor: (x, y, width, height, tint) ->
        super(Block.pixel)
        @anchor.set(0, 1)
        @width = width
        @height = height
        @tint = tint
        @position.set(x, y)
class Player extends PIXI.Sprite
    @texture = PIXI.Texture.fromImage('img/person.png')
    constructor: (@game) ->
        super(Player.texture)
        @anchor.set(0, 1)
        @vx = 0
        @vy = 0
        @g = 0.5
        @initKeys()
        @onground = false
    initKeys: () ->
        scope = @
        Mousetrap.bind(['a', 'left'], () -> scope.vx = -2)
        Mousetrap.bind(['d', 'right'], () -> scope.vx = 2)
        Mousetrap.bind(['a', 'd', 'left', 'right'], (() -> scope.vx = 0), 'keyup')
        Mousetrap.bind(['w', 'up'], () ->
            if scope.onground
                scope.vy = -10
                scope.onground = false
        )

    update: () ->
        [ox, oy] = [@position.x, @position.y]
        cell = @game.level.containingCell(@)
        @vy += @g if not @onground
        @position.x += @vx
        @position.y += @vy
        cell2 = @game.level.containingCell(@)
        if not cell2? or (cell != cell2 and cell.tint != cell2.tint)
            @position.y = oy
            @vy = 0
            @onground = true


class ScrollContainer extends PIXI.DisplayObjectContainer
    constructor: (parent) ->
        super()
        parent.addChild(@)
    setView: (x, y) ->
        @position.set(-x, -y)
    scroll: (dx=0, dy=0) ->
        @position.x -= dx
        @position.y -= dy

class Level extends PIXI.DisplayObjectContainer
    constructor: (parent) ->
        super()
        parent.addChild(@)
    containingCell: (doc) ->
        r = doc.bounds()
        [x1, y1, x2, y2] = [r.x, r.y, r.x+r.width, r.y+r.height]
        _items = []
        for cell in @children
            b = cell.bounds()
            _items.push(cell) if b.contains(x1, y1) and b.contains(x2, y1) and b.contains(x1, y2) and b.contains(x2, y2)

        _items
    

class Game
    @viewportSize: 512
    constructor: (el) ->
        @stage = new PIXI.Stage(0x222222)
        @renderer = PIXI.autoDetectRenderer(Game.viewportSize, Game.viewportSize, el)
        @scroller = new ScrollContainer(@stage)
        @level = new Level(@scroller)
        @player = new Player(@)
        @scroller.addChild(@player)
        @animate(@)
    animate: (scope) ->
        requestAnimFrame(() -> scope.animate(scope))
        scope.player.update()
        @renderer.render(@stage)
    
    loadLevel: (filename) ->
        for child in @level.children
            @level.removeChild(@level.children[0])
        
        scope = @
        xhr = new XMLHttpRequest()
        xhr.open('GET', filename, true)
        xhr.addEventListener 'load', (event) ->
            json = JSON.parse(xhr.responseText)
            blocks = json.blocks
            for el in blocks
                e2 = (64*x for x in el[0..3])
                block = new Block(e2[0], Game.viewportSize - e2[1], e2[2], e2[3], parseInt(el[4].substring(1), 16))
                scope.level.addChild(block)
            scope.player.position.set(json.entrance[0] * 64, Game.viewportSize - (json.entrance[1] * 64))

        xhr.send()

game = undefined

document.addEventListener 'DOMContentLoaded', () ->
    game = new Game($('game'))
