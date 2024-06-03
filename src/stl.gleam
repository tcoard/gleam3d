import coordinate_logic.{apply_fn_3d, cross_product}
import custom_types.{type Coord3d, type Triangle3d}
import gleam/float.{to_string}
import gleam/list
import gleam/string

// TODO binary format stl

pub fn format(cross_prod: Coord3d, a: Coord3d, b: Coord3d, c: Coord3d) {
  // TODO round floats
  "facet normal "
  <> to_string(cross_prod.0)
  <> " "
  <> to_string(cross_prod.1)
  <> " "
  <> to_string(cross_prod.2)
  <> "\n  outer loop\n    vertex "
  <> to_string(a.0)
  <> " "
  <> to_string(a.1)
  <> " "
  <> to_string(a.2)
  <> "\n    vertex "
  <> to_string(b.0)
  <> " "
  <> to_string(b.1)
  <> " "
  <> to_string(b.2)
  <> "\n    vertex "
  <> to_string(c.0)
  <> " "
  <> to_string(c.1)
  <> " "
  <> to_string(c.2)
  <> "\n  endloop\nendfacet"
}

pub fn make(triangles: List(Triangle3d)) -> String {
  triangles
  |> list.map(fn(a_b_c) {
    let #(a, b, c) = a_b_c
    let cross_prod =
      cross_product(
        apply_fn_3d(float.subtract, b, a),
        apply_fn_3d(float.subtract, c, a),
      )
    format(cross_prod, a, b, c)
  })
  |> list.prepend("solid")
  |> list.append(["endsolid"])
  |> string.join("\n")
}
