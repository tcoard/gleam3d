import coordinate_logic.{add_z_axis, calc_outer_lines, line_width}
import custom_types.{
  type Direction1d, type Direction2d, type Path1d, type Path2d, type Triangle3d,
  East, L, North, R, South, West,
}
import gleam/float
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/string
import simplifile

const out_path = "data/current.csv"

pub fn reverse_direction(d: Direction1d) -> Direction1d {
  case d {
    R -> L
    L -> R
  }
}

pub fn fold_path(path: Path1d) {
  list.concat([
    path,
    [R],
    list.reverse(path)
      |> list.map(reverse_direction),
  ])
}

pub fn one_dimension_to_int(d: Direction1d) -> Int {
  case d {
    R -> 1
    L -> -1
  }
}

pub fn int_to_dir(n: Int) -> Direction2d {
  case n {
    0 -> North
    1 -> East
    2 -> South
    3 -> West
    _ -> panic as "int_to_dir's input should be %4"
  }
}

pub fn one_dimension_to_2d(path: Path1d) -> Path2d {
  path
  |> list.map(one_dimension_to_int)
  |> list.fold([0], fn(acc, i) {
    let assert Ok(last) = list.first(acc)
    let assert Ok(next) = int.modulo(last + i, 4)
    // using modulo b/c dividend can be negative
    [next, ..acc]
  })
  |> list.map(int_to_dir)
  |> list.reverse
}

pub fn print_to_csv(triangles: List(Triangle3d)) {
  let assert Ok(_) =
    triangles
    |> list.map(fn(triangle) {
      let #(a, b, c) = triangle
      [a, b, c]
      |> list.map(fn(coord) {
        float.to_string(coord.0)
        <> ","
        <> float.to_string(coord.1)
        <> ","
        <> float.to_string(coord.2)
      })
      |> string.join("|")
    })
    |> string.join("\n")
    |> simplifile.write(to: out_path)
}

pub fn main() {
  let n = 7
  let lines =
    iterator.iterate([R], fold_path)
    |> iterator.take(n)
    |> iterator.to_list
    |> list.index_map(fn(curve, i) {
      curve
      |> one_dimension_to_2d
      |> calc_outer_lines
      |> list.map(add_z_axis(_, int.to_float(i) *. line_width))
    })
    |> list.prepend(
      [North]
      |> calc_outer_lines
      |> list.map(add_z_axis(_, int.to_float(-1) *. line_width)),
    )

  // todo only need to do for first and last line when done, but it might not
  // matter
  let planes =
    lines
    |> list.map(coordinate_logic.plane)
    |> list.flatten

  let plane_tops =
    lines
    |> list.map(fn(line) {
      line
      |> list.map(coordinate_logic.increase_z_axis(_, line_width))
      |> coordinate_logic.plane
    })
    |> list.flatten

  // let layer_connections =
  //   lines
  //   |> coordinate_logic.layer_connections
  let border =
    lines
    |> list.map(coordinate_logic.border)
    |> list.flatten

  planes
  |> list.append(plane_tops)
  |> list.append(border)
  // |> list.append(layer_connections)
  // |> io.debug
  |> print_to_csv
}
