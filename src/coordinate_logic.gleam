import gleam/string
import gleam/io
import gleam/int
import gleam/float
import gleam/list
import custom_types.{
  type Coord2d, type Coord3d, type Direction2d, type Line2d, type Path1d,
  type Path2d, type Triangle3d, type Vec2d, East, End, L, North, R, South, Start,
  West, type Line3d
}

// must be smaller than 1 because of rounding logic
pub const line_width = 0.4

pub const line_length = 10.0

pub fn outer_line_vecs(path: Path2d, is_left is_left: Bool) -> List(Vec2d) {
  // TODO combine the logic so this funcion is less messy
  let sign = case is_left {
    True -> -1.0
    False -> 1.0
  }
  let delta = sign *. line_width /. 2.0
  path
  |> list.window_by_2
  |> list.fold([#(delta, -1.0 *. float.absolute_value(delta))], fn(acc, a_b) {
    let assert Ok(prev_pos) = list.first(acc)
    let #(a, b) = a_b
    case a {
      North | South -> {
        let y = case a {
          // nested alternative patterns like #(North | South, East) are not
          // currently possible
          North -> 1.0
          South -> -1.0
          _ -> panic
        }
        let y_delta = case b {
          East -> -1.0 *. delta
          West -> delta
          _ ->
            case a {
              North -> float.absolute_value(delta)
              South -> -1.0 *. float.absolute_value(delta)
              _ -> panic
            }
        }
        // TODO for end
        [
          #(prev_pos.0, int.to_float(float.round(prev_pos.1)) +. y +. y_delta),
          ..acc
        ]
      }
      East | West -> {
        let x = case a {
          // nested alternative patterns like #(North | South, East) are not
          // currently possible
          East -> 1.0
          West -> -1.0
          _ -> panic
        }
        let x_delta = case b {
          North -> delta
          South -> -1.0 *. delta
          _ ->
            case a {
              East -> float.absolute_value(delta)
              West -> -1.0 *. float.absolute_value(delta)
              _ -> panic
            }
        }
        // TODO for end
        [
          #(int.to_float(float.round(prev_pos.0)) +. x +. x_delta, prev_pos.1),
          ..acc
        ]
      }
      _ -> acc
    }
  })
  |> list.reverse
}

// pub fn calc_outer_lines(path: Path2d) -> #(Line2d, Line2d) {
//   let path =
//     path
//     |> list.prepend(Start)
//     |> list.append([End])
//   let line = outer_line_vecs(path, _)
//   #(line(True), line(False))
// }
//
pub fn calc_outer_lines(path: Path2d) -> Line2d {
  let path =
    path
    |> list.prepend(Start)
    |> list.append([End])
  let line = outer_line_vecs(path, _)
  // line(True)
  // |> list.append(list.reverse(line(False)))
  list.zip(line(True), line(False))
  |> list.map(fn(coords) { [coords.0, coords.1] })
  |> list.flatten
}

// pub fn border(line: Line2d) -> List(Triangle3d) {
//   let assert Ok(first) = list.first(line)
//   line
//   |> list.append([first])
//   |> list.window_by_2
//   |> list.map(fn(coords) {
//     [
//       #(
//         add_z_axis(coords.0, 0.0),
//         add_z_axis(coords.1, 0.0),
//         add_z_axis(coords.1, line_width),
//       ),
//       #(
//         add_z_axis(coords.0, 0.0),
//         add_z_axis(coords.0, line_width),
//         add_z_axis(coords.1, line_width),
//       ),
//     ]
//   })
//   |> list.flatten
// }
//

pub fn border(lines: List(Line3d)) -> List(Triangle3d) {
  lines
  |> list.window_by_2
  |> list.map(fn(a_b) {
    let #(a, b) = a_b
    io.debug(a)
    //make func pop get first two
    let #(one, two, line) = case a {
      [one, two, ..line] -> #(one, two, line)
      _ -> panic
    }
    let assert Ok([first, ..line]) = a
  })
  [#(#(0.0,0.0,0.0), #(0.0,0.0,0.0), #(0.0,0.0,0.0))]
  // |> list.window_by_2
  // |> list.map(fn(lines) {
  //   list.zip(lines.0, list.sized_chunk(lines.1, 2))
  //   |> list.map(fn(a_chunk2) {
  //     let #(a, chunk2) = a_chunk2
  //     case chunk2 {
  //       [b, c] -> #(a, b, c)
  //       _ -> panic
  //     }
  //   })
  // })
  // |> list.flatten
}

// pub fn plane(line: Line2d, z: Float) -> List(Triangle3d) {
//   line
//   |> list.window(by: 4)
//   |> list.map(fn(coords4) {
//     coords4
//     |> list.window(3)
//     |> list.map(fn(coords3) {
//       case coords3 {
//         [a, b, c] -> #(add_z_axis(a, z), add_z_axis(b, z), add_z_axis(c, z))
//         _ -> panic
//       }
//     })
//   })
//   |> list.flatten
// }
pub fn plane(line: Line3d) -> List(Triangle3d) {
  line
  |> list.window(by: 4)
  |> list.map(fn(coords4) {
    coords4
    |> list.window(3)
    |> list.map(fn(coords3) {
      case coords3 {
        [a, b, c] -> #(a, b, c)
        _ -> panic
      }
    })
  })
  |> list.flatten
}

pub fn add_z_axis(coord: Coord2d, z: Float) -> Coord3d {
  // todo make partial function? function capture or curry2?
  #(coord.0, coord.1, z)
}

pub fn calc_triangle_coord(
  bisect1: #(Coord2d, Coord2d),
  bisect2: #(Coord2d, Coord2d),
) -> List(Triangle3d) {
  //height
  // (doing both faces even though it is redundant)
  // let #(a, b) = bisect1
  // let #(c, d) = bisect2
  // let aaa = { bisect1.0 }.0

  [bisect1.0, bisect1.1, bisect2.1, bisect2.0, bisect1.0]
  |> list.window_by_2
  |> list.map(fn(coords) {
    [
      #(
        add_z_axis(coords.0, 0.0),
        add_z_axis(coords.1, 0.0),
        add_z_axis(coords.1, line_width),
      ),
      #(
        add_z_axis(coords.0, 0.0),
        add_z_axis(coords.0, line_width),
        add_z_axis(coords.1, line_width),
      ),
    ]
  })
  |> list.flatten
  |> list.append(
    //flat planes
    [
      #(
        add_z_axis(bisect1.0, 0.0),
        add_z_axis(bisect1.1, 0.0),
        add_z_axis(bisect2.1, 0.0),
      ),
      #(
        add_z_axis(bisect1.0, line_width),
        add_z_axis(bisect1.1, line_width),
        add_z_axis(bisect2.1, line_width),
      ),
      #(
        add_z_axis(bisect1.0, 0.0),
        add_z_axis(bisect2.0, 0.0),
        add_z_axis(bisect2.1, 0.0),
      ),
      #(
        add_z_axis(bisect1.0, line_width),
        add_z_axis(bisect2.0, line_width),
        add_z_axis(bisect2.1, line_width),
      ),
    ],
  )
}
