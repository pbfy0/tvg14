// Generated by CoffeeScript 1.6.3
(function() {
  var $, Block, Exit, Game, GameStateManager, Level, Player, Viewport, constrain, preventDefault,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $ = document.getElementById.bind(document);

  if (String.prototype.trimRight == null) {
    String.prototype.trimRight = function() {
      return this.replace(/\s+$/, '');
    };
  }

  String.prototype.lpad = function(n, v) {
    if (v == null) {
      v = '0';
    }
    if (this.length > n) {
      return this;
    } else {
      return new Array(n - this.length + 1).join(v) + this;
    }
  };

  Object.prototype.chain = function(f) {
    var _this = this;
    return function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      f.apply(null, args);
      return _this;
    };
  };

  preventDefault = function(f) {
    var _wrap;
    _wrap = function(event) {
      event.preventDefault();
      f(event);
      return false;
    };
    return _wrap;
  };

  constrain = function(val, min, max) {
    if (val < min) {
      return min;
    } else if (val > max) {
      return max;
    } else {
      return val;
    }
  };

  Function.prototype.trigger = function(prop, getter, setter) {
    return Object.defineProperty(this.prototype, prop, {
      get: getter,
      set: setter
    });
  };

  PIXI.DisplayObjectContainer.prototype.calcwbounds = function() {
    var r;
    r = new PIXI.Rectangle;
    if (this.anchor != null) {
      r.x = this.position.x - this.anchor.x * this.width;
      r.y = this.position.y - this.anchor.y * this.height;
    } else {
      r.x = this.position.x;
      r.y = this.position.y;
    }
    r.width = this.width;
    r.height = this.height;
    return r;
  };

  Block = (function(_super) {
    __extends(Block, _super);

    function Block(x, y, width, height, boxColor) {
      this.width = width;
      this.height = height;
      Block.__super__.constructor.call(this);
      this.boxColor = boxColor;
      console.log(x, y, this.width, this.height);
      this.position.set(x, y);
      this.hitArea = new PIXI.Rectangle(x, y, this.width, this.height);
    }

    Block.prototype.redraw = function(lineColor) {
      this.clear();
      this.beginFill(this.boxColor);
      this.lineStyle(1, lineColor || 0x222222);
      this.drawRect(0, 0, this.width - 1, this.height - 1);
      return this.endFill();
    };

    Block.trigger('boxColor', function() {
      return this._boxColor;
    }, function(val) {
      this._boxColor = val;
      return this.redraw();
    });

    Block.prototype.click = function(right) {
      var boxColor;
      if (game.selected !== null) {
        boxColor = game.selected.boxColor;
        if (!right) {
          game.selected._boxColor = this.boxColor;
        }
        game.selected.redraw();
        this.boxColor = boxColor;
        return game.selected = null;
      } else {
        game.selected = this;
        return this.redraw(0xff0000);
      }
    };

    return Block;

  })(PIXI.Graphics);

  Player = (function(_super) {
    var _this = this;

    __extends(Player, _super);

    Player.animations = {};

    Player.loader = new PIXI.SpriteSheetLoader('img/player.json');

    Player.loader.addEventListener('loaded', function() {
      var a, ani_names, i, n, name;
      ani_names = {
        'stand': 0,
        'left': 91,
        'right': 91,
        'jump': 91,
        'jumpleft': 91,
        'jumpright': 91
      };
      for (name in ani_names) {
        n = ani_names[name];
        a = (function() {
          var _i, _results;
          _results = [];
          for (i = _i = 0; 0 <= n ? _i <= n : _i >= n; i = 0 <= n ? ++_i : --_i) {
            _results.push(PIXI.Texture.fromFrame("" + name + "_" + (String(i).lpad(2)) + ".png"));
          }
          return _results;
        })();
        Player.animations[name] = a;
      }
    });

    Player.loader.load();

    function Player(game) {
      this.game = game;
      Player.__super__.constructor.call(this, Player.animations.stand);
      this.loop = true;
      this.play();
      this.anchor.set(0, 1);
      this.vx = 0;
      this.vy = 0;
      this.g = 0.5;
      this.initKeys();
      this.onground = false;
    }

    Player.prototype.setAnimSet = function(name) {
      return this.textures = Player.animations[name];
    };

    Player.prototype.initKeys = function() {
      var _this = this;
      Mousetrap.bind(['a', 'left'], preventDefault(function() {
        return _this.vx = -2;
      }), 'keydown');
      Mousetrap.bind(['d', 'right'], preventDefault(function() {
        return _this.vx = 2;
      }), 'keydown');
      Mousetrap.bind(['a', 'd', 'left', 'right'], preventDefault(function() {
        return _this.vx = 0;
      }), 'keyup');
      return Mousetrap.bind(['w', 'up', 'space'], preventDefault(function() {
        if (_this.onground) {
          _this.vy = -10;
          return _this.onground = false;
        }
      }, 'keydown'));
    };

    Player.prototype.update = function() {
      var bounds, eb, x1, x2, y1, y2, _ref;
      this.updatePhysics();
      this.updateViewport();
      this.updateAnimate();
      if (this.game.level.exit == null) {
        return;
      }
      bounds = this.calcwbounds();
      _ref = [bounds.x, bounds.x + bounds.width, bounds.y, bounds.y + bounds.height], x1 = _ref[0], x2 = _ref[1], y1 = _ref[2], y2 = _ref[3];
      eb = this.game.level.exit.hitArea;
      if ((!this.game.level.exit.exited) && (eb.contains(x1, y1) || eb.contains(x2, y1) || eb.contains(x1, y2) || eb.contains(x2, y2))) {
        this.game.level.exit.exited = true;
        return this.game.level.loadn(++this.game.levelNumber);
      }
    };

    Player.prototype.updateAnimate = function() {
      var cset;
      cset = this.textures;
      switch (false) {
        case !(this.vx < 0):
          this.setAnimSet(this.onground ? 'left' : 'jumpleft');
          break;
        case this.vx !== 0:
          this.setAnimSet(this.onground ? 'stand' : 'jump');
          break;
        case !(this.vx > 0):
          this.setAnimSet(this.onground ? 'right' : 'jumpright');
      }
      if (this.textures !== cset) {
        return this.gotoAndPlay(0);
      }
    };

    Player.prototype.updateViewport = function() {
      var hd, lh, lw, sx, sy, vh, vw, wd, wx, wy, _ref;
      _ref = [this.position.x, this.position.y], wx = _ref[0], wy = _ref[1];
      vw = this.game.viewport.width;
      vh = this.game.viewport.height;
      lw = this.game.level.width;
      lh = this.game.level.height;
      wd = lw - vw;
      hd = lh - vh;
      sx = vw / 2 - wd / 2;
      sy = vh / 2 - hd / 2;
      this.game.viewport.position.x = wd > 0 ? constrain(sx - wx, -wd, 0) : wd / -2;
      return this.game.viewport.position.y = hd > 0 ? constrain(sy - wy, -hd, 0) : hd / -2;
    };

    Player.prototype.updatePhysics = function() {
      var c, cell, cellx, celly, f, ox, oy, _i, _j, _len, _len1, _ref;
      _ref = [this.position.x, this.position.y], ox = _ref[0], oy = _ref[1];
      cell = this.game.level.containingCell(this);
      f = cell[0];
      this.vy += this.g;
      this.position.y += this.vy;
      if (this.position.y > this.game.level.height) {
        this.position.y = oy;
        if (this.vy > 0) {
          this.onground = true;
        }
        this.vy = 0;
      }
      if (f != null) {
        celly = this.game.level.containingCell(this);
        for (_i = 0, _len = celly.length; _i < _len; _i++) {
          c = celly[_i];
          if (__indexOf.call(cell, c) < 0) {
            if (c.boxColor !== f.boxColor) {
              this.position.y = oy;
              if (this.vy > 0) {
                this.onground = true;
              }
              this.vy = 0;
            }
          }
        }
      }
      this.position.x += this.vx;
      if (this.position.x < 0 || this.position.x + this.width >= this.game.level.width) {
        this.position.x = ox;
        this.vx = 0;
        return;
      }
      if (f == null) {
        return;
      }
      cellx = this.game.level.containingCell(this);
      for (_j = 0, _len1 = cellx.length; _j < _len1; _j++) {
        c = cellx[_j];
        if (__indexOf.call(cell, c) < 0) {
          if (c.boxColor !== f.boxColor) {
            this.position.x = ox;
          }
        }
      }
    };

    return Player;

  }).call(this, PIXI.MovieClip);

  Exit = (function(_super) {
    __extends(Exit, _super);

    function Exit(game, x, y, dir, size) {
      var r;
      this.game = game;
      Exit.__super__.constructor.call(this);
      this.exited = false;
      this.beginFill(0xaaaa00);
      r = ((function() {
        switch (dir) {
          case 'l':
            return [0, 0, size / 3, size];
          case 't':
            return [0, 0, size, size / 3];
          case 'r':
            return [size * 2 / 3, 0, size / 3, size];
          case 'b':
            return [0, size * 2 / 3, size, size / 3];
          default:
            return [0, 0, size, size];
        }
      })());
      this.drawRect.apply(this, r);
      this.endFill();
      this.width = this.height = size;
      this.position.set(x, y);
      this.hitArea = new PIXI.Rectangle(r[0] + this.position.x, r[1] + this.position.y, r[2] + this.position.x, r[3] + this.position.y);
    }

    return Exit;

  })(PIXI.Graphics);

  Viewport = (function(_super) {
    __extends(Viewport, _super);

    function Viewport(game, width, height) {
      var _this = this;
      this.game = game;
      Viewport.__super__.constructor.call(this);
      window.addEventListener('resize', function() {
        _this.width = window.innerWidth;
        _this.height = window.innerHeight;
        return _this.game.player.updateViewport();
      });
      this.width = width;
      this.height = height;
    }

    return Viewport;

  })(PIXI.DisplayObjectContainer);

  Level = (function(_super) {
    __extends(Level, _super);

    function Level(game) {
      this.game = game;
      this.blocks = [];
      this.exit = void 0;
      Level.__super__.constructor.call(this);
    }

    Level.prototype.containingCell = function(doc) {
      var b, c, cell, x1, x2, y1, y2, _i, _items, _len, _ref, _ref1;
      c = doc.calcwbounds();
      _ref = [c.x, c.y, c.x + c.width, c.y + c.height], x1 = _ref[0], y1 = _ref[1], x2 = _ref[2], y2 = _ref[3];
      _items = [];
      _ref1 = this.blocks;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        cell = _ref1[_i];
        b = cell.hitArea;
        if (b.contains(x1, y1) || b.contains(x2, y1) || b.contains(x1, y2) || b.contains(x2, y2)) {
          _items.push(cell);
        }
      }
      return _items;
    };

    Level.prototype.cellForCoords = function(x, y) {
      var b, cell, _i, _items, _len, _ref;
      _items = [];
      _ref = this.blocks;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cell = _ref[_i];
        b = cell.hitArea;
        if (b.contains(x, y)) {
          _items.push(cell);
        }
      }
      return _items[_items.length - 1];
    };

    Level.prototype.load = function(fn) {
      var child, xhr, _i, _len, _ref,
        _this = this;
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        this.removeChild(this.children[0]);
      }
      this.blocks = [];
      this.game.renderer.render(this.game.stage);
      this.game.suspended = true;
      xhr = new XMLHttpRequest();
      xhr.open('GET', fn, true);
      xhr.addEventListener('load', function(event) {
        var block, blocksize, c, cc, char, chs, colors, ex, ey, f, h, l, m, parts, row, w, x, x2, xx, xy, y, y2, z, _j, _k, _l, _len1, _len2, _len3, _ref1, _ref2, _ref3;
        parts = xhr.responseText.replace(/\r\n/g, '\n').trimRight().split('\n\n');
        colors = {};
        blocksize = Number(parts[3] || 0) || 64;
        _ref1 = parts[0].split('\n');
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          row = _ref1[_j];
          _ref2 = row.split(' '), l = _ref2[0], c = _ref2[1];
          colors[l] = parseInt(c, 16);
        }
        f = parts[1].split('\n');
        cc = void 0;
        chs = {};
        _this.width = f[0].length * blocksize;
        _this.height = f.length * blocksize;
        for (y = _k = 0, _len2 = f.length; _k < _len2; y = ++_k) {
          row = f[y];
          for (x = _l = 0, _len3 = row.length; _l < _len3; x = ++_l) {
            char = row[x];
            if (chs[char]) {
              continue;
            }
            x2 = x;
            y2 = y;
            while (x2 < row.length && row[x2] === char) {
              x2++;
            }
            x2--;
            while (y2 < f.length && f[y2][x2] === char) {
              y2++;
            }
            y2--;
            chs[char] = true;
            w = x2 - x + 1;
            h = y2 - y + 1;
            block = new Block(x * blocksize, y * blocksize, w * blocksize, h * blocksize, colors[char] || 0);
            _this.addChild(block);
            _this.blocks.push(block);
          }
        }
        m = parts[2].split('\n');
        _ref3 = (function() {
          var _len4, _m, _ref3, _results;
          _ref3 = m[0].split(', ');
          _results = [];
          for (_m = 0, _len4 = _ref3.length; _m < _len4; _m++) {
            x = _ref3[_m];
            _results.push(Number(x));
          }
          return _results;
        })(), ex = _ref3[0], ey = _ref3[1];
        z = m[1].split(', ');
        xx = Number(z[0]);
        xy = Number(z[1]);
        _this.exit = new Exit(_this, xx * blocksize, _this.height - (xy + 1) * blocksize, z[2], blocksize);
        _this.addChild(_this.exit);
        _this.game.player.position.set(ex * blocksize, _this.height - ey * blocksize);
        _this.game.suspended = false;
      });
      return xhr.send();
    };

    Level.prototype.loadn = function(n) {
      if (n == null) {
        n = this.game.levelNumber;
      }
      return this.load('level/' + n);
    };

    return Level;

  })(PIXI.DisplayObjectContainer);

  GameStateManager = (function() {
    function GameStateManager(game) {
      this.game = game;
      this.titleScreen = PIXI.Sprite.fromImage('img/splash.png');
    }

    GameStateManager.prototype.load = function() {
      var _this = this;
      this.game.player.visible = false;
      this.game.level.loadn();
      this.game.stage.addChild(this.titleScreen);
      this.titleScreen.texture.baseTexture.source.addEventListener('load', function() {
        var x;
        x = function() {
          return _this.titleScreen.position.set((window.innerWidth - _this.titleScreen.width) / 2, (window.innerHeight - _this.titleScreen.height) / 2);
        };
        x();
        return window.addEventListener('resize', x);
      });
      return this.game.renderer.view.addEventListener('click', function() {
        _this.game.stage.removeChild(_this.titleScreen);
        _this.game.renderer.view.removeEventListener('click', arguments.callee);
        _this.game.player.visible = true;
        return _this.startGame(0);
      });
    };

    GameStateManager.prototype.startGame = function(n) {
      var _this = this;
      this.game.levelNumber = n;
      this.game.level.loadn();
      return window.addEventListener('beforeunload', function() {
        return localStorage.state = _this.game.levelNumber;
      });
    };

    return GameStateManager;

  })();

  Game = (function() {
    function Game(el) {
      var _this = this;
      this.stage = new PIXI.Stage(0x222222);
      this.renderer = PIXI.autoDetectRenderer(window.innerWidth, window.innerHeight, el);
      this.viewport = new Viewport(this, window.innerWidth, window.innerHeight);
      this.stage.addChild(this.viewport);
      this.level = new Level(this);
      this.levelNumber = 0;
      this.viewport.addChild(this.level);
      this.player = new Player(this);
      this.viewport.addChild(this.player);
      this.sm = new GameStateManager(this);
      this.sm.load();
      this.selected = null;
      this.suspended = false;
      this.animate(this);
      this.tick(this);
      this.renderer.view.addEventListener('mouseup', function(event) {
        var bounds, cell, elX, elY, rx, ry, _ref, _ref1;
        if (!_this.player.visible) {
          return;
        }
        event.preventDefault();
        event = event || window.event;
        bounds = _this.renderer.view.getBoundingClientRect();
        _ref = [event.clientX - bounds.left, event.clientY - bounds.top], elX = _ref[0], elY = _ref[1];
        _ref1 = [elX - _this.viewport.position.x, elY - _this.viewport.position.y], rx = _ref1[0], ry = _ref1[1];
        cell = _this.level.cellForCoords(rx, ry);
        if (cell) {
          cell.click(event.which === 3 || event.button === 2);
        }
        return false;
      });
      this.renderer.view.addEventListener('contextmenu', function(event) {
        event.preventDefault();
        return false;
      });
      window.addEventListener('resize', function(ev) {
        _this.renderer.resize(window.innerWidth, window.innerHeight);
        return console.log(ev);
      });
      document.addEventListener('scroll', function(ev) {
        return ev.preventDefault();
      });
    }

    Game.prototype.animate = function(scope) {
      requestAnimFrame(function() {
        return scope.animate(scope);
      });
      if (scope.suspended) {
        return;
      }
      return this.renderer.render(this.stage);
    };

    Game.prototype.tick = function(scope) {
      setTimeout((function() {
        return scope.tick(scope);
      }), 1000 / 60);
      if (scope.suspended) {
        return;
      }
      return scope.player.update();
    };

    return Game;

  })();

  Player.loader.addEventListener('loaded', function() {
    return window.game = new Game($('game'));
  });

}).call(this);
