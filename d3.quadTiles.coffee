noop = ->

mercatorφ = (y) ->
  Math.atan(Math.exp(-y * Math.PI / 180)) * 360 / Math.PI - 90

module.exports = d3.quadTiles = (projection, zoom) ->
  tiles = []
  invisible = null
  zoom = Math.max 0, zoom
  width = Math.pow 2, zoom
  step = Math.max .2, Math.min 1, zoom * .01
  precision = projection.precision()
  stream = projection
    .precision 960
    .stream
      point: -> invisible = no
      lineStart: noop
      lineEnd: noop
      polygonStart: noop
      polygonEnd: noop

  visit = (x1, y1, x2, y2) ->
    w = x2 - x1
    m1 = mercatorφ(y1)
    m2 = mercatorφ(y2)
    δ = step * w
    invisible = yes
    stream.polygonStart()
    stream.lineStart()
    for x in [x1...x2 + δ / 2] by δ
      break unless invisible
      stream.point x, m1
    for y in [m1...m2 + δ / 2] by δ
      break unless invisible
      stream.point x2, y
    for x in [x2...x1 - δ / 2] by -δ
      break unless invisible
      stream.point x, m2
    for y in [m2...m1 - δ / 2] by -δ
      break unless invisible
      stream.point x1, y
    stream.point x1, m1 if invisible
    stream.lineEnd()
    stream.polygonEnd()
    return if invisible
    if w <= 360 / width
      tiles.push
        type: 'Polygon'
        coordinates: [
          d3
            .range(x1, x2 + δ / 2, δ)
            .map((x) -> [x, y1])
            .concat([[x2, .5 * (y1 + y2)]])
            .concat(d3.range(x2, x1 - (δ / 2), -δ)
            .map((x) -> [x, y2]))
            .concat([[x1, .5 * (y1 + y2)]])
            .concat([[x1, y1]])
            .map((d) -> [d[0], mercatorφ(d[1])])
        ]
        key: [
          (180 + x1) / 360 * width | 0
          (180 + y1) / 360 * width | 0
          zoom
        ]
        centroid: [
          .5 * (x1 + x2)
          .5 * (m1 + m2)
        ]
    else
      x = .5 * (x1 + x2)
      y = .5 * (y1 + y2)
      visit x1, y1, x, y
      visit x, y1, x2, y
      visit x1, y, x, y2
      visit x, y, x2, y2

  visit -180, -180, 180, 180
  projection.precision precision
  tiles