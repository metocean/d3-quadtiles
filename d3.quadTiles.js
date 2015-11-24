// Generated by CoffeeScript 1.9.2
var square, subdivideline, tiletolnglat;

tiletolnglat = require('tiletolnglat');

subdivideline = require('subdivideline');

square = function(x, y) {
  return [[x, y], [x + 1, y], [x + 1, y + 1], [x, y + 1]];
};

module.exports = d3.quadTiles = function(projection, options) {
  var alltiles, dive, extent, fin, isvisible, precision, projecttile, stream, tiles, visible, zoom;
  if (options == null) {
    options = {};
  }
  if (options.maxtiles == null) {
    options.maxtiles = 16;
  }
  if (options.maxzoom == null) {
    options.maxzoom = 18;
  }
  precision = projection.precision();
  extent = projection.clipExtent();
  visible = false;
  stream = projection.precision(960).stream({
    point: function() {
      return visible = true;
    },
    lineStart: function() {},
    lineEnd: function() {},
    polygonStart: function() {},
    polygonEnd: function() {}
  });
  isvisible = function(x, y, z) {
    var check, coords, p;
    p = square(x, y);
    coords = [];
    visible = false;
    stream.polygonStart();
    stream.lineStart();
    check = function(i) {
      var o;
      o = tiletolnglat(i[0], i[1], z);
      stream.point(o[0], o[1]);
      return coords.push(o);
    };
    subdivideline(p[0], p[1], 10, check);
    subdivideline(p[1], p[2], 10, check);
    subdivideline(p[2], p[3], 10, check);
    subdivideline(p[3], p[0], 10, check);
    stream.lineEnd();
    stream.polygonEnd();
    if (!visible) {
      return null;
    }
    return coords;
  };
  projecttile = function(x, y, z) {
    var check, coords, p;
    p = square(x, y);
    coords = [];
    check = function(i) {
      return coords.push(tiletolnglat(i[0], i[1], z));
    };
    subdivideline(p[0], p[1], 10, check);
    subdivideline(p[1], p[2], 10, check);
    subdivideline(p[2], p[3], 10, check);
    subdivideline(p[3], p[0], 10, check);
    return coords;
  };
  fin = false;
  tiles = [[0, 0]];
  alltiles = [];
  alltiles.push(tiles);
  zoom = 0;
  dive = function() {
    var gen1, gen2, gen2tiles, j, k, len, len1, ref;
    gen2tiles = [];
    for (j = 0, len = tiles.length; j < len; j++) {
      gen1 = tiles[j];
      ref = square(gen1[0] * 2, gen1[1] * 2);
      for (k = 0, len1 = ref.length; k < len1; k++) {
        gen2 = ref[k];
        if (!isvisible(gen2[0], gen2[1], zoom + 1)) {
          continue;
        }
        gen2tiles.push(gen2);
      }
    }
    if (gen2tiles.length > options.maxtiles) {
      fin = true;
      return;
    }
    tiles = gen2tiles;
    alltiles.push(gen2tiles);
    return zoom++;
  };
  while (!fin && zoom <= options.maxzoom) {
    dive();
  }
  tiles = tiles.map(function(tile) {
    return {
      tile: tile,
      coords: projecttile(tile[0], tile[1], zoom)
    };
  }).map(function(tile) {
    return {
      type: 'Polygon',
      coordinates: [tile.coords],
      key: [tile.tile[0], tile.tile[1], zoom],
      centroid: tiletolnglat(tile.tile[0] + 0.5, tile.tile[1] + 0.5, zoom)
    };
  });
  projection.precision(precision);
  projection.clipExtent(extent);
  return {
    zoom: zoom,
    tiles: tiles,
    all: alltiles
  };
};
