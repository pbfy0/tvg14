$ = document.getElementById.bind(document)

PIXI.DisplayObjectContainer::bounds = () ->
    r = new PIXI.Rectangle
    if @anchor?
        r.x = @position.x - @anchor.x * @width
        r.y = @position.y - @anchor.y * @height
    else
        r.x = @position.x
        r.y = @position.y
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
        f = cell[0]
        @vy += @g
        @position.y += @vy
        if @position.y > Game.viewportSize
            @position.y = oy
            @onground = true if @vy > 0
            @vy = 0
        return unless f?
        celly = @game.level.containingCell(@)
        for c in celly
            if c not in cell
                if c.tint != f.tint
                    @position.y = oy
                    @onground = true if @vy > 0
                    @vy = 0
        @position.x += @vx
        cellx = @game.level.containingCell(@)
        for c in cellx
            if c not in cell
                if c.tint != f.tint
                    @position.x = ox
        return


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
            _items.push(cell) if b.contains(x1, y1) or b.contains(x2, y1) or b.contains(x1, y2) or b.contains(x2, y2)

        return _items
    

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
                block = new Block(el[0]*64, Game.viewportSize - el[1]*64, el[2]*64, el[3]*64, parseInt(el[4].substring(1), 16))
                scope.level.addChild(block)
            scope.player.position.set(json.entrance[0] * 64, Game.viewportSize - (json.entrance[1] * 64))

        xhr.send()

game = undefined

document.addEventListener 'DOMContentLoaded', () ->
    game = new Game($('game'))
