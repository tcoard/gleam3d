import coordinate_logic.{add_z_axis, calc_outer_lines, line_width}
import custom_types.{
  type Direction1d, type Direction2d, type Path1d, type Path2d,
  East, L, North, R, South, West,
}
import gleam/int
import gleam/iterator
import gleam/list
import simplifile
import stl

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

pub fn main() {
  let n = 3
  let lines =
    iterator.iterate([R], fold_path)
    |> iterator.take(n)
    |> iterator.to_list
    |> list.reverse
    |> list.index_map(fn(curve, i) {
      curve
      |> one_dimension_to_2d
      |> calc_outer_lines
      |> list.map(add_z_axis(_, int.to_float(i) *. line_width))
    })
    // add straight line to beginning of list
    |> list.prepend(
      [North]
      |> calc_outer_lines
      |> list.map(add_z_axis(_, int.to_float(n) *. line_width)),
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

  let border =
    lines
    |> list.map(coordinate_logic.border)
    |> list.flatten

  planes
  |> list.append(plane_tops)
  |> list.append(border)
  |> stl.make
  |> simplifile.write(to: out_path)
}
