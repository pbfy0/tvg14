
buf = new Uint8Array([0x42, 0x4d, 0x3a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x36, 0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00, 0x01, 0x00,
0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x18, 0x00,
0x00, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x13, 0x0b,
0x00, 0x00, 0x13, 0x0b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0x00])
textures = {}
textureForColor = (color) ->
    if not textures[color]?
        buf[54..56] = [color & 0xff, (color && 0xff00) >> 16, (color && 0xff0000) >> 32]
        b64string = btoa((String.fromCharCode(x) for x in buf).join(''))
        textures[color] = PIXI.Texture.fromImage('data:image/bmp;base64,' + b64string)
    return textures[color]

loadLevel = (stage, filename) ->
    xhr = new XMLHttpRequest()
    xhr.open('GET', filename, true)
    xhr.addEventListener('load', (event) ->
        json = JSON.parse(xhr.responseText)
        blocks = json.blocks
        for el in blocks
            texture = textureForColor(parseInt(el[4].substring(1), 16))
            sprite = new PIXI.Sprite(texture)
            [sprite.position.x, sprite.position.y, sprite.width, sprite.height] = el
            stage.addChild(sprite)
    )
    xhr.send()

document.addEventListener('DOMContentLoaded', () ->
    window.stage = new PIXI.Stage(0x222222)
    renderer = PIXI.autoDetectRenderer(512, 512)
    document.body.appendChild(renderer.view)
    texture = textureForColor(0x0000ff)
    window.sprite = new PIXI.Sprite(texture)
    sprite.width = sprite.height = 100
#    sprite.anchor.x = sprite.anchor.y = 0.5
    sprite.position.x = sprite.position.y = 200
    stage.addChild(sprite)
    animate = () ->
        requestAnimFrame(animate)
        renderer.render(stage)
    
    requestAnimFrame(animate)
)
