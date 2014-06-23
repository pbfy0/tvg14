$ = document.getElementById.bind(document)
if not String::trimRight?
    String::trimRight = ->
        @replace(/\s+$/, '')
Object::chain = (f) ->
    return (args...) =>
        f(args...)
        return @

preventDefault = (f) ->
    _wrap = (event) ->
        event.preventDefault()
        f(event)
        return false
    return _wrap
constrain = (val, min, max) ->
    if val < min then min else if val > max then max else val

Function::trigger = (prop, getter, setter) ->
    Object.defineProperty @::, prop,
        get: getter
        set: setter


PIXI.DisplayObjectContainer::calcwbounds = ->
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
    @trigger 'boxColor', ->
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
    initKeys: ->
        Mousetrap.bind(['a', 'left'], (preventDefault => @vx = -2), 'keydown')
        Mousetrap.bind(['d', 'right'], (preventDefault => @vx = 2), 'keydown')
        Mousetrap.bind(['a', 'd', 'left', 'right'], (preventDefault => @vx = 0), 'keyup')
        Mousetrap.bind(['w', 'up', 'space'], preventDefault =>
            if @onground
                @vy = -10
                @onground = false
        , 'keydown')

    update: ->
        @updatePhysics()
        @updateViewport()
        return if not @game.level.exit?
        bounds = @calcwbounds()
        [x1, x2, y1, y2] = [bounds.x, bounds.x+bounds.width, bounds.y, bounds.y+bounds.height]
        eb = @game.level.exit.hitArea
        if (not @game.level.exit.exited) and (eb.contains(x1, y1) or eb.contains(x2, y1) or eb.contains(x1, y2) or eb.contains(x2, y2))
            @game.level.exit.exited = true
            @game.level.loadn(++@game.levelNumber)
            
    updateViewport: ->
        [wx, wy] = [@position.x, @position.y]
        vw = @game.viewport.width
        vh = @game.viewport.height
        lw = @game.level.width
        lh = @game.level.height
        sx = (vw - (lw - vw)) / 2
        sy = (vh - (lh - vh)) / 2
        if wx > sx and wx < (vw + (lw - vw)) / 2
            @game.viewport.position.x = sx - @position.x
        if wy > sy and wy < (vh + (lh - vh)) / 2
            @game.viewport.position.y = sy - @position.y
        #@game.viewport.setView(@position.x, @position.y)
        
    updatePhysics: -> # a royal mess
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
        if @position.x < 0 or @position.x + @width >= @game.level.width
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
class Exit extends PIXI.Graphics
    constructor: (@game, dir, size) ->
        super()
        @exited = false
        @beginFill(0xaaaa00)
        r = (switch dir
            when 'l' then [0, 0, size/3, size]
            when 't' then [0, 0, size, size/3]
            when 'r' then [size*2/3, 0, size, size]
            when 'b' then [0, size*2/3, size, size]
            else [0, 0, size, size]
        )
        @drawRect(r...)
        @endFill()
        @width = @height = size
        @hitArea = new PIXI.Rectangle(r[0] + @position.x, r[1] + @position.y, r[2] + @position.x, r[3] + @position.y)


class Viewport extends PIXI.DisplayObjectContainer
    constructor: (@game, width, height) ->
        super()
        window.addEventListener 'resize', =>
            @width = window.innerWidth
            @height = window.innerHeight
            @game.player.updateViewport()
        @width = width
        @height = height

class Level extends PIXI.DisplayObjectContainer
    constructor: (@game) ->
        @blocks = []
        @exit = undefined
        super()
    containingCell: (doc) ->
        c = doc.calcwbounds()
        [x1, y1, x2, y2] = [c.x, c.y, c.x+c.width, c.y+c.height]
        _items = []
        for cell in @blocks
            b = cell.hitArea
            _items.push(cell) if b.contains(x1, y1) or b.contains(x2, y1) or b.contains(x1, y2) or b.contains(x2, y2)
        return _items
    cellForCoords: (x, y) ->
        _items = []
        for cell in @blocks
            b = cell.hitArea
            _items.push(cell) if b.contains(x, y)
        return _items[_items.length - 1]
    load: (fn) ->
        for child in @children
            @removeChild(@children[0])
        @blocks = []
        @game.player.visible = false
        @game.renderer.render(@game.stage)
        @game.suspended = true
        
        xhr = new XMLHttpRequest()
        xhr.open('GET', fn, true)
        xhr.addEventListener 'load', (event) =>
            parts = xhr.responseText.trimRight().split('\n\n')
            colors = {}
            blocksize = Number(parts[3] or 0) or 64
            for row in parts[0].split('\n')
                [l, c] = row.split(' ')
                colors[l] = parseInt(c, 16)

            f = parts[1].split('\n')
            cc = undefined
            chs = {}
            @width = f[0].length * blocksize
            @height = f.length * blocksize
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
                    @addChild(block)
                    @blocks.push(block)
            
            m = parts[2].split('\n')
            [ex, ey] = (Number(x) for x in m[0].split(', '))
            z = m[1].split(', ')
            xx = Number(z[0])
            xy = Number(z[1])
            @exit = new Exit(@, z[2], blocksize)
            @exit.position.set(xx*blocksize, @height - xy*blocksize)
            @addChild(@exit)
            @game.player.position.set(ex*blocksize, @height - ey*blocksize)
            @game.viewport.position.y = @game.viewport.height - @height
            @game.player.visible = true
            @game.suspended = false
            return
        xhr.send()
    loadn: (n=@game.levelNumber) ->
        @load('level/' + n)

class GameStateManager
    constructor: (@game) ->
        @titleScreen = PIXI.Sprite.fromImage('img/splash.png')
    load: ->
        s = localStorage.state
        if s?
            @game.levelNumber = s
            @game.level.loadn()
        else
            @game.level.loadn()
            @game.stage.addChild(@titleScreen)
            @game.renderer.view.addEventListener 'click', =>
                @game.stage.removeChild(@titleScreen)
                @game.renderer.view.removeEventListener 'click', arguments.callee
                window.addEventListener 'beforeunload', =>
                    localStorage.state = @game.levelNumber
class Game
    constructor: (el) ->
        @stage = new PIXI.Stage(0x222222)
        @renderer = PIXI.autoDetectRenderer(window.innerWidth, window.innerHeight, el)
        @viewport = new Viewport(@, window.innerWidth, window.innerHeight)
        @stage.addChild(@viewport)
        @level = new Level(@)
        @levelNumber = 0
        @viewport.addChild(@level)
        @player = new Player(@)
        @viewport.addChild(@player)
        @sm = new GameStateManager(@)
        @sm.load()
        @selected = null
        @suspended = false
        @animate(@)
        @tick(@)
        @renderer.view.addEventListener 'mouseup', (event) =>
            event.preventDefault()
            event = event || window.event
            bounds = @renderer.view.getBoundingClientRect()
            [elX, elY] = [event.clientX - bounds.left, event.clientY - bounds.top]
            [rx, ry] = [elX - @viewport.position.x, elY - @viewport.position.y]
            cell = @level.cellForCoords(rx, ry)
            cell.click(event.which == 3 or event.button == 2) if cell
            return false
        @renderer.view.addEventListener 'contextmenu', (event) ->
            event.preventDefault()
            return false
        window.addEventListener 'resize', (ev) =>
            @renderer.resize(window.innerWidth, window.innerHeight)
            console.log(ev)
        document.addEventListener 'scroll', (ev) ->
            ev.preventDefault()

    animate: (scope) ->
        requestAnimFrame(-> scope.animate(scope))
        return if scope.suspended
        @renderer.render(@stage)
    tick: (scope) ->
        setTimeout((-> scope.tick(scope)), 1000/60)
        return if scope.suspended
        scope.player.update()

document.addEventListener 'DOMContentLoaded', ->
    window.game = new Game($('game'))