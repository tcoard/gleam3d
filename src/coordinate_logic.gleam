import custom_types.{
  type Coord2d, type Coord3d, type Direction2d, type Line2d, type Line3d,
  type Path2d, type Triangle3d, type Vec2d, East, End, North, South, Start, West,
}
import gleam/float
import gleam/int
import gleam/list

// must be smaller than 1 because of rounding logic
pub const line_width = 0.4

pub const line_length = 1.0

pub fn calc_x(curr: Direction2d) -> Float {
  case curr {
    North | South -> 0.0
    East -> 1.0
    West -> -1.0
    _ -> 0.0
  }
}

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

pub fn rectangle(a, b, c, d) {
  [#(a, b, c), #(b, c, d)]
}

pub fn connect_layers(
  curr: Line3d,
  next: Line3d,
  acc: List(Triangle3d),
) -> List(Triangle3d) {
  case curr, next {
    [curr1, curr2, curr3, ..curr_rest],
      [next1, next2, next3, next4, ..next_rest]
    -> {
      let acc = [
        #(curr1, curr3, next1),
        #(curr3, next1, next3),
        #(curr1, curr3, next2),
        #(curr3, next2, next4),
        ..acc
      ]
      connect_layers(
        [curr2, curr3, ..curr_rest],
        [next3, next4, ..next_rest],
        acc,
      )
    }
    [curr1, curr2], [next1, next2] -> [
      #(curr1, curr2, next1),
      #(curr2, next1, next2),
      ..acc
    ]
    _, _ -> panic
  }
}

pub fn layer_connections(lines: List(Line3d)) -> List(Triangle3d) {
  lines
  |> list.window_by_2
  |> list.map(fn(curr_next) {
    let #(curr, next) = curr_next
    //make func pop get first two
    case curr_next {
      #([curr1, curr2, ..], [next1, next2, ..]) ->
        connect_layers(curr, next, [
          #(curr1, curr2, next1),
          #(curr2, next1, next2),
        ])
      _ -> panic
    }
  })
  |> list.flatten
}

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

pub fn border(line: Line3d) -> List(Triangle3d) {
  let assert Ok(first) = list.first(line)
  let assert Ok(last) = list.last(line)
  line
  |> list.prepend(first)
  |> list.append([last])
  |> list.window(3)
  |> list.map(fn(coords) {
    case coords {
      [a, _, b] -> {
        let a_prime = increase_z_axis(a, line_width)
        let b_prime = increase_z_axis(b, line_width)
        rectangle(a, a_prime, b, b_prime)
      }
      _ -> panic
    }
  })
  |> list.flatten
}

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

pub fn apply_fn_3d(
  f: fn(Float, Float) -> Float,
  a: Coord3d,
  b: Coord3d,
) -> Coord3d {
  #(f(a.0, b.0), f(a.1, b.1), f(a.2, b.2))
}

pub fn cross_product(a: Coord3d, b: Coord3d) -> #(Float, Float, Float) {
  #(
    a.1 *. b.2 -. a.2 *. b.1,
    a.2 *. b.0 -. a.0 *. b.2,
    a.0 *. b.1 -. a.1 *. b.0,
  )
}

pub fn increase_z_axis(coord: Coord3d, z: Float) -> Coord3d {
  // todo make partial function? function capture or curry2?
  #(coord.0, coord.1, coord.2 +. z)
}
