tiletolnglat = (x, y, z) ->
  n = Math.PI - 2 * Math.PI * y / Math.pow(2, z)
  [
    x / Math.pow(2, z) * 360 - 180
    180 / Math.PI * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n)))
  ]

subdivide = (a, b, n, f) ->
  x = a[0]
  dx = if a[0] is b[0] then 0 else b[0] - a[0]
  y = a[1]
  dy = if a[1] is b[1] then 0 else b[1] - a[1]
  for i in [0...n].map((i) -> i / n)
    f([x + i * dx,y + i * dy]) is true

square = (x, y) ->
  [[x, y], [x + 1, y], [x + 1, y + 1], [x, y + 1]]

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

  projecttile = (x, y, z) ->
    p = square x, y

    coords = []
    visible = no
    stream.polygonStart()
    stream.lineStart()
    check = (i) ->
      o = tiletolnglat i[0], i[1], z
      stream.point o[0], o[1]
      coords.push o
    subdivide p[0], p[1], 10, check
    subdivide p[1], p[2], 10, check
    subdivide p[2], p[3], 10, check
    subdivide p[3], p[0], 10, check
    stream.lineEnd()
    stream.polygonEnd()

    return null if !visible
    return coords

  fin = no
  tiles = [{ tile: [0, 0], coords: projecttile 0, 0, 0 }]
  zoom = 0

  dive = ->
    nexttiles = []
    for gen1 in tiles
      for gen2 in square gen1.tile[0] * 2, gen1.tile[1] * 2
        coords = projecttile gen2[0], gen2[1], zoom + 1
        continue if !coords?
        nexttiles.push tile: gen2, coords: coords
    if nexttiles.length > options.maxtiles
      fin = yes
      return
    tiles = nexttiles
    zoom++

  dive() while !fin and zoom <= options.maxzoom

  tiles = tiles.map (tile) ->
    type: 'Polygon'
    coordinates: [tile.coords]
    key: [tile.tile[0], tile.tile[1], zoom]
    centroid: tiletolnglat tile.tile[0] + 0.5, tile.tile[1] + 0.5, zoom

  # Reset precision
  projection.precision precision
  projection.clipExtent extent

  zoom: zoom
  tiles: tiles
