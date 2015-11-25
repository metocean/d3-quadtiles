# QuadTiles
Inspired and guided by the Automatic Projection Tiles tech demo from Jason Davies and the source code by the same name 'd3.quadTiles.js'. https://www.jasondavies.com/maps/tile/

This utility takes a d3 geo projection and using the projection's clipping rectangles returns an array of visible tiles. A maximum tile budget and max zoom level controls the quadtree descent. A full hierarchy of visible tiles at zoom levels starting from 0 until the zoom level reached is also returned.

Use this algorithm to efficiently calculate visible map tiles on any d3 geo map projection! Performs well even at high zoom levels.

```js
var d3 = require('d3');
var projection = d3.geo.orthographic()
  .precision(0.1)
  .clipAngle(90)
  .rotate([-150, 25])
  .scale(150)
  .translate([300, 240])
  .clipExtent([[0, 0], [600, 480]]);
var quadtiles = require('d3-quadtiles');
var quad = quadtiles(projection, { maxtiles: 32, maxzoom: 18 });
console.log(quad.zoom); // e.g. 6
console.log(quad.tiles); // e.g. [zoom6tile1, zoom6tile2, zoom6tile3..]
// quad.all is indexed by zoom level
console.log(quad.all); // e.g. [[zoom0tile1], [zoom1tile1, zoom1tile2], ...]
// tile = {
//   type: "Polygon",
//   key: [x, y, z], // tilespace coordinates
//   // points created as 10 points along each side of the tile starting top left and going right
//   // 40 points total
//   points: [[[lng, lat], [lng, lat], [lng, lat], ...]],
//   centroid: [lng, lat] // coordinates of centroid
// }
```
