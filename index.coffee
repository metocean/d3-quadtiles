d3 = require 'd3'

tiletolnglat = require 'tiletolnglat'
subdivideline = require 'subdivideline'
square = (x, y) -> [[x, y], [x + 1, y], [x + 1, y + 1], [x, y + 1]]

# Calculate 40 screen coordinates for the boundary of the tile
# 10 points along each side
projecttile = (x, y, z) ->
  p = square x, y
  coords = []
  calc = (i) -> coords.push tiletolnglat i[0], i[1], z
  subdivideline p[0], p[1], 10, calc
  subdivideline p[1], p[2], 10, calc
  subdivideline p[2], p[3], 10, calc
  subdivideline p[3], p[0], 10, calc
  coords

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

  # Somewhat unobvious global used for visibility checking
  visible = no

  # Geometry stream used for visibility checking
  stream = projection
    .precision 960
    .stream
      point: -> visible = yes
      lineStart: ->
      lineEnd: ->
      polygonStart: ->
      polygonEnd: ->

  # Check the visibility of a tile x, y, z
  # true = visible, false = not visible
  isvisible = (x, y, z) ->
    p = square x, y
    visible = no
    stream.polygonStart()
    stream.lineStart()
    check = (i) ->
      o = tiletolnglat i[0], i[1], z
      stream.point o[0], o[1]
    subdivideline p[0], p[1], 10, check
    subdivideline p[1], p[2], 10, check
    subdivideline p[2], p[3], 10, check
    subdivideline p[3], p[0], 10, check
    stream.lineEnd()
    stream.polygonEnd()
    visible

  fin = no
  currenttiles = [[0, 0]]
  alltiles = []
  alltiles.push currenttiles
  zoom = 0

  # Perform one zoom level pass
  dive = ->
    nexttiles = []
    for gen1 in currenttiles
      for gen2 in square gen1[0] * 2, gen1[1] * 2
        continue unless isvisible gen2[0], gen2[1], zoom + 1
        nexttiles.push gen2
    if nexttiles.length > options.maxtiles
      fin = yes
      return
    currenttiles = nexttiles
    alltiles.push nexttiles
    zoom++

  # Depth first parsing of zoom depths
  dive() while !fin and zoom <= options.maxzoom

  # Build the geojson tile format
  alltiles = alltiles.map (tiles, z) -> tiles.map (tile) ->
    type: 'Polygon'
    key: [tile[0], tile[1], z]
    coordinates: [projecttile tile[0], tile[1], z]
    centroid: tiletolnglat tile[0] + 0.5, tile[1] + 0.5, z

  # Reset precision
  projection.precision precision
  projection.clipExtent extent

  zoom: zoom
  tiles: alltiles[zoom]
  all: alltiles
