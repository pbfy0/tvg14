// Generated by CoffeeScript 1.6.3
(function() {
  var $, Block, Game, Level, Player, Viewport, constrain, preventDefault,
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

  Object.prototype.chain = function(f) {
    var scope;
    scope = this;
    return function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      f.apply(null, args);
      return scope;
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
    __extends(Player, _super);

    Player.texture = PIXI.Texture.fromImage('img/person.png');

    function Player(game) {
      this.game = game;
      Player.__super__.constructor.call(this, Player.texture);
      this.anchor.set(0, 1);
      this.vx = 0;
      this.vy = 0;
      this.g = 0.5;
      this.initKeys();
      this.onground = false;
    }

    Player.prototype.initKeys = function() {
      var scope;
      scope = this;
      Mousetrap.bind(['a', 'left'], preventDefault(function() {
        return scope.vx = -2;
      }), 'keydown');
      Mousetrap.bind(['d', 'right'], preventDefault(function() {
        return scope.vx = 2;
      }), 'keydown');
      Mousetrap.bind(['a', 'd', 'left', 'right'], preventDefault(function() {
        return scope.vx = 0;
      }), 'keyup');
      return Mousetrap.bind(['w', 'up', 'space'], preventDefault(function() {
        if (scope.onground) {
          scope.vy = -10;
          return scope.onground = false;
        }
      }, 'keydown'));
    };

    Player.prototype.update = function() {
      this.updatePhysics();
      return this.updateViewport();
    };

    Player.prototype.updateViewport = function() {
      var lh, lw, sx, sy, vh, vw, wx, wy, _ref;
      _ref = [this.position.x, this.position.y], wx = _ref[0], wy = _ref[1];
      vw = this.game.viewport.width;
      vh = this.game.viewport.height;
      lw = this.game.level.width;
      lh = this.game.level.height;
      sx = (vw - (lw - vw)) / 2;
      sy = (vh - (lh - vh)) / 2;
      if (wx > sx && wx < (vw + (lw - vw)) / 2) {
        this.game.viewport.position.x = sx - this.position.x;
      }
      if (wy > sy && wy < (vh + (lh - vh)) / 2) {
        return this.game.viewport.position.y = sy - this.position.y;
      }
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

  })(PIXI.Sprite);

  Viewport = (function(_super) {
    __extends(Viewport, _super);

    function Viewport(game, width, height) {
      this.game = game;
      Viewport.__super__.constructor.call(this);
      this.width = width;
      this.height = height;
    }

    Viewport.trigger('width', function() {
      return this._width;
    }, function(v) {
      this._width = v;
      return this.game.renderer.resize(this.width, this.height);
    });

    Viewport.trigger('height', function() {
      return this._height;
    }, function(v) {
      this._height = v;
      return this.game.renderer.resize(this.width, this.height);
    });

    return Viewport;

  })(PIXI.DisplayObjectContainer);

  Level = (function(_super) {
    __extends(Level, _super);

    function Level(game) {
      this.game = game;
      Level.__super__.constructor.call(this);
    }

    Level.prototype.containingCell = function(doc) {
      var b, c, cell, x1, x2, y1, y2, _i, _items, _len, _ref, _ref1;
      c = doc.calcwbounds();
      _ref = [c.x, c.y, c.x + c.width, c.y + c.height], x1 = _ref[0], y1 = _ref[1], x2 = _ref[2], y2 = _ref[3];
      _items = [];
      _ref1 = this.children;
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
      var b, cell, _i, _len, _ref;
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cell = _ref[_i];
        b = cell.hitArea;
        if (b.contains(x, y)) {
          return cell;
        }
      }
    };

    Level.prototype.load = function(fn) {
      var child, scope, xhr, _i, _len, _ref;
      _ref = this.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        this.removeChild(this.level.children[0]);
      }
      scope = this;
      xhr = new XMLHttpRequest();
      xhr.open('GET', fn, true);
      xhr.addEventListener('load', function(event) {
        var block, blocksize, c, cc, char, chs, colors, ex, ey, f, h, l, m, parts, row, w, x, x2, xx, xy, y, y2, _j, _k, _l, _len1, _len2, _len3, _ref1, _ref2, _ref3, _ref4;
        parts = xhr.responseText.trimRight().split('\n\n');
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
        scope.width = f[0].length * blocksize;
        scope.height = f.length * blocksize;
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
            scope.addChild(block);
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
        _ref4 = (function() {
          var _len4, _m, _ref4, _results;
          _ref4 = m[1].split(', ');
          _results = [];
          for (_m = 0, _len4 = _ref4.length; _m < _len4; _m++) {
            x = _ref4[_m];
            _results.push(Number(x));
          }
          return _results;
        })(), xx = _ref4[0], xy = _ref4[1];
        scope.game.player.position.set(ex * blocksize, scope.height - ey * blocksize);
        scope.game.viewport.position.y = scope.game.viewport.height - scope.height;
      });
      return xhr.send();
    };

    return Level;

  })(PIXI.DisplayObjectContainer);

  Game = (function() {
    function Game(el) {
      var scope;
      this.stage = new PIXI.Stage(0x222222);
      this.renderer = new PIXI.WebGLRenderer(0, 0, el);
      this.viewport = new Viewport(this, window.innerWidth, window.innerHeight);
      this.stage.addChild(this.viewport);
      this.level = new Level(this);
      this.viewport.addChild(this.level);
      this.player = new Player(this);
      this.viewport.addChild(this.player);
      this.selected = null;
      this.animate(this);
      this.tick(this);
      scope = this;
      this.renderer.view.addEventListener('mouseup', function(event) {
        var bounds, cell, elX, elY, rx, ry, _ref, _ref1;
        event.preventDefault();
        event = event || window.event;
        bounds = scope.renderer.view.getBoundingClientRect();
        _ref = [event.clientX - bounds.left, event.clientY - bounds.top], elX = _ref[0], elY = _ref[1];
        _ref1 = [elX - scope.viewport.position.x, elY - scope.viewport.position.y], rx = _ref1[0], ry = _ref1[1];
        cell = scope.level.cellForCoords(rx, ry);
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
        scope.viewport._height = window.innerHeight;
        scope.viewport.position.y = scope.viewport.height - scope.level.height;
        scope.viewport._width = window.innerWidth;
        scope.viewport.height = window.innerHeight;
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
      return this.renderer.render(this.stage);
    };

    Game.prototype.tick = function(scope) {
      setTimeout((function() {
        return scope.tick(scope);
      }), 1000 / 60);
      return scope.player.update();
    };

    return Game;

  })();

  document.addEventListener('DOMContentLoaded', function() {
    window.game = new Game($('game'));
    return game.level.load('level/0');
  });

}).call(this);
