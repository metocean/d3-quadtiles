tiletolnglat = require 'tiletolnglat'
subdivideline = require 'subdivideline'
square = (x, y) -> [[x, y], [x + 1, y], [x + 1, y + 1], [x, y + 1]]

module.exports = d3.quadTiles = (projection, options) ->
  options ?= {}
  options.maxtiles ?= 16
  options.maxzoom ?= 18

  precision = projection.precision()
  extent = projection.clipExtent()
  # # Smaller extent for testing
  # dx = 0.25 * (extent[1][0] - extent[0][0])
  # dy = 0.25 * (extent[1][1] - extent[0][1])
  # checkextent = [
  #   [extent[0][0] + dx, extent[0][1] + dy]
  #   [extent[1][0] - dx, extent[1][1] - dy]
  # ]
  # projection.clipExtent checkextent

  visible = no

  stream = projection
    .precision 960
    .stream
      point: -> visible = yes
      lineStart: ->
      lineEnd: ->
      polygonStart: ->
      polygonEnd: ->

  isvisible = (x, y, z) ->
    p = square x, y
    coords = []
    visible = no
    stream.polygonStart()
    stream.lineStart()
    check = (i) ->
      o = tiletolnglat i[0], i[1], z
      stream.point o[0], o[1]
      coords.push o
    subdivideline p[0], p[1], 10, check
    subdivideline p[1], p[2], 10, check
    subdivideline p[2], p[3], 10, check
    subdivideline p[3], p[0], 10, check
    stream.lineEnd()
    stream.polygonEnd()
    return null if !visible
    coords

  projecttile = (x, y, z) ->
    p = square x, y
    coords = []
    check = (i) -> coords.push tiletolnglat i[0], i[1], z
    subdivideline p[0], p[1], 10, check
    subdivideline p[1], p[2], 10, check
    subdivideline p[2], p[3], 10, check
    subdivideline p[3], p[0], 10, check
    coords

  fin = no
  tiles = [[0, 0]]
  alltiles = []
  alltiles.push tiles
  zoom = 0

  dive = ->
    gen2tiles = []
    for gen1 in tiles
      for gen2 in square gen1[0] * 2, gen1[1] * 2
        continue unless isvisible gen2[0], gen2[1], zoom + 1
        gen2tiles.push gen2
    if gen2tiles.length > options.maxtiles
      fin = yes
      return
    tiles = gen2tiles
    alltiles.push gen2tiles
    zoom++

  dive() while !fin and zoom <= options.maxzoom

  tiles = tiles
    .map (tile) ->
      tile: tile
      coords: projecttile tile[0], tile[1], zoom
    .map (tile) ->
      type: 'Polygon'
      coordinates: [tile.coords]
      key: [tile.tile[0], tile.tile[1], zoom]
      centroid: tiletolnglat tile.tile[0] + 0.5, tile.tile[1] + 0.5, zoom

  # Reset precision
  projection.precision precision
  projection.clipExtent extent

  zoom: zoom
  tiles: tiles
  all: alltiles
