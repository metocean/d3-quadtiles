noop = ->

mercatorφ = (y) ->
  Math.atan(Math.exp(-y * Math.PI / 180)) * 360 / Math.PI - 90

module.exports = d3.quadTiles = (projection, zoom) ->
  tiles = []
  visible = null
  zoom = Math.max 0, zoom
  width = Math.pow 2, zoom
  step = Math.max .2, Math.min 1, zoom * .01
  precision = projection.precision()
  extent = projection.clipExtent()
  stream = projection
    .precision 960
    .stream
      point: -> visible = yes
      lineStart: noop
      lineEnd: noop
      polygonStart: noop
      polygonEnd: noop

  visit = (x1, y1, x2, y2) ->
    w = x2 - x1
    m1 = mercatorφ y1
    m2 = mercatorφ y2
    δ = step * w

    visible = no

    run = (a, b) ->
      return if visible
      x = a[0]
      y = a[1]
      if a[0] < b[0]
        if a[1] < b[1]
          while x <= b[0] and y <= b[1] and not visible
            stream.point x, y
            x += δ
            y += δ
        else
          while x <= b[0] and y >= b[1] and not visible
            stream.point x, y
            x += δ
            y -= δ
      else
        if a[1] < b[1]
          while x >= b[0] and y <= b[1] and not visible
            stream.point x, y
            x -= δ
            y += δ
        else
          while x >= b[0] and y >= b[1] and not visible
            stream.point x, y
            x -= δ
            y -= δ

    # 1 -- 2
    # |    |
    # |    |
    # 4 -- 3
    p1 = [x1, m1]
    p2 = [x2, m1]
    p3 = [x2, m2]
    p4 = [x1, m2]

    if !visible
      # search for clip region

      # 1 -- 2
      # |    |
      # |    |
      # 4 -- 3
      stream.polygonStart()
      stream.lineStart()
      run p1, p2
      run p2, p3
      run p3, p4
      run p4, p1
      stream.lineEnd()
      stream.polygonEnd()

    if !visible
      # 1 -- 2
      #   \  |
      #    \ |
      # 4    3
      stream.polygonStart()
      stream.lineStart()
      run p1, p2
      run p2, p3
      run p3, p1
      stream.lineEnd()
      stream.polygonEnd()

    if !visible
      # 1    2
      # | \
      # |  \
      # 4 -- 3
      stream.polygonStart()
      stream.lineStart()
      run p1, p3
      run p3, p4
      run p4, p1
      stream.lineEnd()
      stream.polygonEnd()

    if !visible
      #console.log "Rejecting #{(180 + x1) / 360 * width | 0}, #{(180 + y1) / 360 * width | 0}, #{Math.log2(360/w)}"
      return

    if w <= 360 / width
      tiles.push
        type: 'Polygon'
        coordinates: [
          []
            .concat(d3.range(x1, x2 + δ / 2, δ).map((x) -> [x, y1]))
            .concat([[x2, .5 * (y1 + y2)]])
            .concat(d3.range(x2, x1 - (δ / 2), -δ).map((x) -> [x, y2]))
            .concat([[x1, .5 * (y1 + y2)]])
            .concat([[x1, y1]]).map((d) -> [d[0], mercatorφ(d[1])])
        ]
        key: [
          (180 + x1) / 360 * width | 0
          (180 + y1) / 360 * width | 0
          Math.log2(360 / w)
        ]
        centroid: [
          .5 * (x1 + x2)
          mercatorφ(.5 * (y1 + y2))
        ]
    else
      #console.log "Descending #{(180 + x1) / 360 * width}, #{(180 + y1) / 360 * width}, #{Math.log2(360 / w)}"
      x = .5 * (x1 + x2)
      y = .5 * (y1 + y2)
      visit x1, y1, x, y
      visit x, y1, x2, y
      visit x1, y, x, y2
      visit x, y, x2, y2

  visit -180, -180, 180, 180
  projection.precision precision
  tiles