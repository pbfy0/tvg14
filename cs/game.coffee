$ = document.getElementById.bind(document)
if not String::trimRight?
    String::trimRight = ->
        @replace(/\s+$/, '')
String::lpad = (n, v='0') ->
    if @length > n then @ else new Array(n-@length+1).join(v) + @
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

PIXI.Texture::setFrame = (@frame) ->
    @width = @frame.width
    @height = @frame.height
    @updateFrame = true
    PIXI.Texture.frameUpdates.push(@)

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
    constructor: (x, y, @width, @height, boxColor, @locked=false) ->
        super()#Block.pixel)
        @boxColor = boxColor
        console.log(x, y, @width, @height)
        @position.set(x, y)
        @hitArea = new PIXI.Rectangle(x, y, @width, @height)
    redraw: (lineColor) ->
        @clear()
        @beginFill(@boxColor)
        @lineStyle(1, if @locked then 0x0000ff else lineColor || 0x222222)
        @drawRect(0, 0, @width - 1, @height - 1)
        @endFill()
    @trigger 'boxColor', ->
        return @_boxColor
    , (val) ->
        @_boxColor = val
        @redraw()
    click: (right) ->
        return if @locked
        if game.selected != null
            boxColor = game.selected.boxColor
            game.selected._boxColor = @boxColor if not right
            game.selected.redraw()
            @boxColor = boxColor
            game.selected = null
        else
            game.selected = @
            @redraw(0xff0000)
class Player extends PIXI.MovieClip
    #@texture = PIXI.Texture.fromImage('img/person.png')
    @animations = {}
    @loader = new PIXI.SpriteSheetLoader('img/player.json')
    @loader.addEventListener 'loaded', =>
        ani_names = {'stand': 0, 'left': 91, 'right': 91, 'jump': 91, 'jumpleft': 91, 'jumpright': 91}
        for name, n of ani_names
            a = (PIXI.Texture.fromFrame("#{name}_#{String(i).lpad(2)}.png") for i in [0..n])
            @animations[name] = a
        return
    @loader.load()
    constructor: (@game) ->
        super(Player.animations.stand)
        @loop = true
        @play()
        @anchor.set(0, 1)
        @vx = 0
        @vy = 0
        @g = 0.5
        @initKeys()
        @onground = false
    setAnimSet: (name) ->
        @textures = Player.animations[name]
    initKeys: ->
        Mousetrap.bind(['a', 'left'], (preventDefault =>
            @vx = -2
        ), 'keydown')
        Mousetrap.bind(['d', 'right'], (preventDefault =>
            @vx = 2
        ), 'keydown')
        Mousetrap.bind(['a', 'd', 'left', 'right'], (preventDefault =>
            @vx = 0
        ), 'keyup')
        Mousetrap.bind(['w', 'up', 'space'], preventDefault =>
            if @onground
                @vy = -10
                @onground = false
        , 'keydown')

    update: ->
        @updatePhysics()
        @updateViewport()
        @updateAnimate()
        return if not @game.level.exit?
        bounds = @calcwbounds()
        [x1, x2, y1, y2] = [bounds.x, bounds.x+bounds.width, bounds.y, bounds.y+bounds.height]
        eb = @game.level.exit.hitArea
        if (not @game.level.exit.exited) and (eb.contains(x1, y1) or eb.contains(x2, y1) or eb.contains(x1, y2) or eb.contains(x2, y2))
            @game.level.exit.exited = true
            if ++@game.levelNumber > 4
                @game.win()
            else
                @game.level.loadn()
    updateAnimate: ->
        cset = @textures
        if @vx < 0 then @setAnimSet(if @onground then 'left' else 'jumpleft')
        else if @vx == 0 and not @onground then @setAnimSet('jump')
        else if @vx > 0 then @setAnimSet(if @onground then 'right' else 'jumpright')
        @playing = not (@vx == 0 and @onground)
        if @textures != cset then @gotoAndPlay(0)
    updateViewport: ->
        [wx, wy] = [@position.x, @position.y]
        vw = @game.viewport.width
        vh = @game.viewport.height
        lw = @game.level.width
        lh = @game.level.height
        wd = lw - vw
        hd = lh - vh
        sx = vw/2 - wd / 2#(vw - (lw - vw)) / 2
        sy = vh/2 - hd / 2#(vh - (lh - vh)) / 2
        @game.viewport.position.x = if wd > 0 then constrain(sx - wx, -wd, 0) else wd / -2
        @game.viewport.position.y = if hd > 0 then constrain(sy - wy, -hd, 0) else hd / -2
        #if wy > sy and wy < (vh + (lh - vh)) / 2
        #    @game.viewport.position.y = sy - @position.y
        #@game.viewport.setView(@position.x, @position.y)
        
    updatePhysics: -> # a royal mess
        [ox, oy] = [@position.x, @position.y]
        cell = @game.level.containingCell(@)
        f = cell[0]
        @vy += @g
        @position.y += @vy
        if @position.y > @game.level.height or @position.y - @height < 0
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
class Exit extends PIXI.Sprite
    @texture = PIXI.Texture.fromImage('img/circuit.png')
    constructor: (@game, x, y, dir) ->
        super(Exit.texture)
        @width = @height = 64
        @exited = false
        @position.set(x, y)
        @hitArea = new PIXI.Rectangle(x, y, 64, 64)

class Ending extends PIXI.DisplayObjectContainer
    constructor: (@game) ->
        super()
        @width = 500
        @height = 100
        win = new PIXI.Text('You win', {font: 'bold 100px Arial'})
        win.position.set((@game.renderer.width - @width) / 2, 50)
        @addChild(win)


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
        @game.selected = null
        for child in @children
            @removeChild(@children[0])
        @blocks = []
        @game.renderer.render(@game.stage)
        @game.suspended = true
        
        xhr = new XMLHttpRequest()
        xhr.open('GET', fn, true)
        xhr.addEventListener 'load', (event) =>
            parts = xhr.responseText.replace(/\r\n/g, '\n').trimRight().split('\n\n')
            colors = {}
            locked = {}
            blocksize = Number(parts[3] or 0) or 64
            for row in parts[0].split('\n')
                [l, c, lo] = row.split(' ')
                colors[l] = parseInt(c, 16)
                locked[l] = lo == 'l'
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
                    block = new Block(x*blocksize, y*blocksize, w*blocksize, h*blocksize, colors[char] or 0, locked[char])
                    @addChild(block)
                    @blocks.push(block)
            
            m = parts[2].split('\n')
            [ex, ey] = (Number(x) for x in m[0].split(', '))
            z = m[1].split(', ')
            xx = Number(z[0])
            xy = Number(z[1])
            @exit = new Exit(@, xx*blocksize, @height - (xy+1)*blocksize, z[2], blocksize)
            @addChild(@exit)
            @game.player.position.set(ex*blocksize, @height - ey*blocksize)
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
            @startGame(s)
        else
            @game.player.visible = false
            @game.level.loadn()
            @game.stage.addChild(@titleScreen)
            @titleScreen.texture.baseTexture.source.addEventListener 'load', =>
                x = => @titleScreen.position.set((window.innerWidth - @titleScreen.width) / 2, (window.innerHeight - @titleScreen.height) / 2)
                x()
                window.addEventListener 'resize', x
            @game.renderer.view.addEventListener 'click', =>
                @game.stage.removeChild(@titleScreen)
                @game.renderer.view.removeEventListener 'click', arguments.callee
                @game.player.visible = true
                @startGame(0)
    startGame: (n) ->
        @game.levelNumber = n
        @game.level.loadn()
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
            return unless @player.visible
            event.preventDefault()
            event = event || window.event
            bounds = @renderer.view.getBoundingClientRect()
            [elX, elY] = [event.clientX - bounds.left, event.clientY - bounds.top]
            [rx, ry] = [elX - @viewport.position.x, elY - @viewport.position.y]
            cell = @level.cellForCoords(rx, ry)
            cell.click() if cell #event.which == 3 or event.button == 2) if cell
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
    
    win: ->
        for i in @stage.children
            @stage.removeChild(@stage.children[0])
        @ending = new Ending(@)
        @stage.addChild(@ending)

Player.loader.addEventListener 'loaded', ->
    window.game = new Game($('game'))