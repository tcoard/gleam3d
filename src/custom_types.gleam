pub type Direction1d {
  R
  L
}

pub type Path1d =
  List(Direction1d)

pub type Path2d =
  List(Direction2d)

pub type Coord2d =
  #(Float, Float)

pub type Vec2d =
  #(Float, Float)

pub type Coord3d =
  #(Float, Float, Float)

pub type Line2d =
  List(Coord2d)

pub type Line3d =
  List(Coord3d)

pub type Triangle3d =
  #(Coord3d, Coord3d, Coord3d)

pub type Direction2d {
  North
  East
  South
  West
  Start
  End
}
