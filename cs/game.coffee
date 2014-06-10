$ = document.getElementById.bind(document)
if not String::trimRight?
    String::trimRight = () ->
        this.replace(/\s+$/, '')

Function::trigger = (prop, getter, setter) ->
    Object.defineProperty @::, prop, 
        get: getter
        set: setter


PIXI.DisplayObjectContainer::calcwbounds = () ->
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

class Block extends PIXI.Graphics
    @pixel: PIXI.Texture.fromImage('img/pixel.png')
    constructor: (x, y, @width, @height, boxColor) ->
        super()#Block.pixel)
        @boxColor = boxColor
        console.log(x, y, @width, @height)
        @position.set(x, y)
        @hitArea = new PIXI.Rectangle(x, y, @width, @height)
    redraw: (lineColor) ->
        @clear()
        @beginFill(@boxColor)
        @lineStyle(1, lineColor || 0x222222)
        @drawRect(0, 0, @width - 1, @height - 1)
        @endFill()
    @trigger 'boxColor', () ->
        return @_boxColor
    , (val) ->
        @_boxColor = val
        @redraw()
    click: (right) ->
        if game.selected != null
            boxColor = game.selected.boxColor
            game.selected._boxColor = @boxColor if not right
            game.selected.redraw()
            @boxColor = boxColor
            game.selected = null
        else
            game.selected = @
            @redraw(0xff0000)
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

    update: () -> # a royal mess
        [ox, oy] = [@position.x, @position.y]
        cell = @game.level.containingCell(@)
        f = cell[0]
        @vy += @g
        @position.y += @vy
        if @position.y > @game.level.height
            @position.y = oy
            @onground = true if @vy > 0
            @vy = 0
        if f?
            celly = @game.level.containingCell(@)
            for c in celly
                if c not in cell
                    if c.boxColor != f.boxColor
                        @position.y = oy
                        @onground = true if @vy > 0
                        @vy = 0
        @position.x += @vx
        if @position.x < 0 or @position.x > @game.level.width
            @position.x = ox
            @vx = 0
            return
        return unless f?
        cellx = @game.level.containingCell(@)
        for c in cellx
            if c not in cell
                if c.boxColor != f.boxColor
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
        c = doc.calcwbounds()
        [x1, y1, x2, y2] = [c.x, c.y, c.x+c.width, c.y+c.height]
        _items = []
        for cell in @children
            b = cell.hitArea
            _items.push(cell) if b.contains(x1, y1) or b.contains(x2, y1) or b.contains(x1, y2) or b.contains(x2, y2)
        return _items
    cellForCoords: (x, y) ->
        for cell in @children
            b = cell.hitArea
            return cell if b.contains(x, y)

class Game
    @viewportSize: 512
    constructor: (el) ->
        @stage = new PIXI.Stage(0x222222)
        @renderer = PIXI.autoDetectRenderer(Game.viewportSize, Game.viewportSize, el)
        @scroller = new ScrollContainer(@stage)
        @level = new Level(@scroller)
        @player = new Player(@)
        @scroller.addChild(@player)
        @selected = null
        @animate(@)
        scope = @
        @renderer.view.addEventListener 'mouseup', (event) ->
            event.preventDefault()
            event = event || window.event
            bounds = scope.renderer.view.getBoundingClientRect()
            [elX, elY] = [event.clientX - bounds.left, event.clientY - bounds.top]
            [lx, ly] = [elX + scope.scroller.position.x, elY + scope.scroller.position.y]
            cell = scope.level.cellForCoords(lx, ly)
            cell.click(event.which == 3 or event.button == 2) if cell
            return false
        @renderer.view.addEventListener 'contextmenu', (event) ->
            event.preventDefault()
            return false


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
            scope.level.width = f[0].length * blocksize
            scope.level.height = f.length * blocksize
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
            scope.player.position.set(ex*64, scope.level.height - ey*64)
            return
        xhr.send()


document.addEventListener 'DOMContentLoaded', () ->
    window.game = new Game($('game'))
    game.loadLevel('level/0')
