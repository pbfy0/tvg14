$ = document.getElementById.bind(document)
if not String::trimRight?
    String::trimRight = () ->
        this.replace(/\s+$/, '')

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
    @pixel: PIXI.Texture.fromImage('img/pixel.png')
    constructor: (x, y, width, height, tint) ->
        super(Block.pixel)
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
            parts = xhr.responseText.trimRight().split('\n\n')
            colors = {}
            blocksize = Number(parts[3] or 0) or 64
            for row in parts[0].split('\n')
                [l, c] = row.split(' ')
                colors[l] = parseInt(c, 16)

            f = parts[1].split('\n')
            cc = undefined
            chs = {}
            for row, y in f
                for char, x in row
                    continue if chs[char]
                    x2 = x
                    y2 = y
                    while x2 < row.length and row[x2] == char
                        x2++
                    x2--
                    while y2 < f.length and f[y2][x2] == char
                        y2++
                    y2--
                    chs[char] = true
                    w = x2 - x + 1
                    h = y2 - y + 1
                    block = new Block(x*blocksize, y*blocksize, w*blocksize, h*blocksize, colors[char] or 0)
                    scope.level.addChild(block)
            
            m = parts[2].split('\n')
            [ex, ey] = (Number(x) for x in m[0].split(', '))
            [xx, xy] = (Number(x) for x in m[1].split(', '))
            scope.player.position.set(ex*64, Game.viewportSize - ey*64)

            return


#                block = new Block(el[0]*64, Game.viewportSize - el[1]*64, el[2]*64, el[3]*64, parseInt(el[4].substring(1), 16))
#                scope.level.addChild(block)
#            scope.player.position.set(json.entrance[0] * 64, Game.viewportSize - (json.entrance[1] * 64))

        xhr.send()


document.addEventListener 'DOMContentLoaded', () ->
    window.game = new Game($('game'))
    game.loadLevel('level/0')
