// Generated by CoffeeScript 1.7.1
(function() {
  var $, Block, Game, Level, Player, ScrollContainer,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  $ = document.getElementById.bind(document);

  if (String.prototype.trimRight == null) {
    String.prototype.trimRight = function() {
      return this.replace(/\s+$/, '');
    };
  }

  PIXI.DisplayObjectContainer.prototype.bounds = function() {
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

    Block.pixel = PIXI.Texture.fromImage('img/pixel.png');

    function Block(x, y, width, height, tint) {
      Block.__super__.constructor.call(this, Block.pixel);
      this.width = width;
      this.height = height;
      this.tint = tint;
      this.position.set(x, y);
    }

    return Block;

  })(PIXI.Sprite);

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
      Mousetrap.bind(['a', 'left'], function() {
        return scope.vx = -2;
      });
      Mousetrap.bind(['d', 'right'], function() {
        return scope.vx = 2;
      });
      Mousetrap.bind(['a', 'd', 'left', 'right'], (function() {
        return scope.vx = 0;
      }), 'keyup');
      return Mousetrap.bind(['w', 'up'], function() {
        if (scope.onground) {
          scope.vy = -10;
          return scope.onground = false;
        }
      });
    };

    Player.prototype.update = function() {
      var c, cell, cellx, celly, f, ox, oy, _i, _j, _len, _len1, _ref;
      _ref = [this.position.x, this.position.y], ox = _ref[0], oy = _ref[1];
      cell = this.game.level.containingCell(this);
      f = cell[0];
      this.vy += this.g;
      this.position.y += this.vy;
      if (this.position.y > Game.viewportSize) {
        this.position.y = oy;
        if (this.vy > 0) {
          this.onground = true;
        }
        this.vy = 0;
      }
      if (f == null) {
        return;
      }
      celly = this.game.level.containingCell(this);
      for (_i = 0, _len = celly.length; _i < _len; _i++) {
        c = celly[_i];
        if (__indexOf.call(cell, c) < 0) {
          if (c.tint !== f.tint) {
            this.position.y = oy;
            if (this.vy > 0) {
              this.onground = true;
            }
            this.vy = 0;
          }
        }
      }
      this.position.x += this.vx;
      cellx = this.game.level.containingCell(this);
      for (_j = 0, _len1 = cellx.length; _j < _len1; _j++) {
        c = cellx[_j];
        if (__indexOf.call(cell, c) < 0) {
          if (c.tint !== f.tint) {
            this.position.x = ox;
          }
        }
      }
    };

    return Player;

  })(PIXI.Sprite);

  ScrollContainer = (function(_super) {
    __extends(ScrollContainer, _super);

    function ScrollContainer(parent) {
      ScrollContainer.__super__.constructor.call(this);
      parent.addChild(this);
    }

    ScrollContainer.prototype.setView = function(x, y) {
      return this.position.set(-x, -y);
    };

    ScrollContainer.prototype.scroll = function(dx, dy) {
      if (dx == null) {
        dx = 0;
      }
      if (dy == null) {
        dy = 0;
      }
      this.position.x -= dx;
      return this.position.y -= dy;
    };

    return ScrollContainer;

  })(PIXI.DisplayObjectContainer);

  Level = (function(_super) {
    __extends(Level, _super);

    function Level(parent) {
      Level.__super__.constructor.call(this);
      parent.addChild(this);
    }

    Level.prototype.containingCell = function(doc) {
      var b, cell, r, x1, x2, y1, y2, _i, _items, _len, _ref, _ref1;
      r = doc.bounds();
      _ref = [r.x, r.y, r.x + r.width, r.y + r.height], x1 = _ref[0], y1 = _ref[1], x2 = _ref[2], y2 = _ref[3];
      _items = [];
      _ref1 = this.children;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        cell = _ref1[_i];
        b = cell.bounds();
        if (b.contains(x1, y1) || b.contains(x2, y1) || b.contains(x1, y2) || b.contains(x2, y2)) {
          _items.push(cell);
        }
      }
      return _items;
    };

    return Level;

  })(PIXI.DisplayObjectContainer);

  Game = (function() {
    Game.viewportSize = 512;

    function Game(el) {
      this.stage = new PIXI.Stage(0x222222);
      this.renderer = PIXI.autoDetectRenderer(Game.viewportSize, Game.viewportSize, el);
      this.scroller = new ScrollContainer(this.stage);
      this.level = new Level(this.scroller);
      this.player = new Player(this);
      this.scroller.addChild(this.player);
      this.animate(this);
    }

    Game.prototype.animate = function(scope) {
      requestAnimFrame(function() {
        return scope.animate(scope);
      });
      scope.player.update();
      return this.renderer.render(this.stage);
    };

    Game.prototype.loadLevel = function(filename) {
      var child, scope, xhr, _i, _len, _ref;
      _ref = this.level.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        this.level.removeChild(this.level.children[0]);
      }
      scope = this;
      xhr = new XMLHttpRequest();
      xhr.open('GET', filename, true);
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
            scope.level.addChild(block);
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
        scope.player.position.set(ex * 64, Game.viewportSize - ey * 64);
      });
      return xhr.send();
    };

    return Game;

  })();

  document.addEventListener('DOMContentLoaded', function() {
    window.game = new Game($('game'));
    return game.loadLevel('level/0');
  });

}).call(this);
