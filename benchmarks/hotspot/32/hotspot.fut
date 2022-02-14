-- Code and comments based on
-- https://github.com/kkushagra/rodinia/blob/master/openmp/hotspot/hotspot_openmp.cpp
--
-- ==
-- tags { futhark-c futhark-opencl }
-- compiled input @ data/64.in
-- output @ data/64.out
--
-- input @ data/512.in
-- output @ data/512.out
--
-- input @ data/1024.in
-- output @ data/1024.out

-- Maximum power density possible (say 300W for a 10mm x 10mm chip)
let max_pd: f32 = 3.0e6

-- Required precision in degrees
let precision: f32 = 0.001

let spec_heat_si: f32 = 1.75e6

let k_si: f32 = 100.0

-- Capacitance fitting factor
let factor_chip: f32 = 0.5

-- Chip parameters
let t_chip: f32 = 0.0005
let chip_height: f32 = 0.016
let chip_width: f32 = 0.016

-- Ambient temperature assuming no package at all
let amb_temp: f32 = 80.0

-- Transient solver driver routine: simply converts the heat transfer
-- differential equations to difference equations and solves the
-- difference equations by iterating.
--
-- Returns a new 'temp' array.
let compute_tran_temp [row][col]
                       (num_iterations: i32) (temp: [row][col]f32) (power: [row][col]f32): [row][col]f32 =
  let grid_height = chip_height / f32.i64(row)
  let grid_width = chip_width / f32.i64(col)
  let cap = factor_chip * spec_heat_si * t_chip * grid_width * grid_height
  let rx = grid_width / (2 * k_si * t_chip * grid_height)
  let ry = grid_height / (2 * k_si * t_chip * grid_width)
  let rz = t_chip / (k_si * grid_height * grid_width)
  let max_slope = max_pd / (factor_chip * t_chip * spec_heat_si)
  let step = precision / max_slope
  let col_m_2 = col-2
  let row_m_2 = row-2
  in loop temp for _i < num_iterations do
     let corners = tabulate 4 (\i -> (temp[0, 1] - temp[0,0]) / rx + (temp[1, 0] - temp[0,0]) / ry)
     -- let corner1 = (temp[0, 1] - temp[0,0]) / rx + (temp[1, 0] - temp[0,0]) / ry
     -- let corner2 = (temp[0, col-2] - temp[0, col-1]) / rx + (temp[1,col-1] - temp[0, col-1]) / ry
     -- let corner3 = (temp[row-1, col-2] - temp[row-1, col-1]) / rx + (temp[row-2,col-1] - temp[row-1, col-1]) / ry
     -- let corner4 = (temp[row-1, col-2] - temp[row-1, 0]) / rx + (temp[row-2,0] - temp[row-1, 0]) / ry
     let edge1 = map4 (\el right left above -> (right + left - 2 * el) / rx + (above - el) / ry)
                                 (temp[0, 1:col-1] :> [col_m_2]f32)
                                 (temp[0, 0:col-2] :> [col_m_2]f32)
                                 (temp[0, 2:col-0] :> [col_m_2]f32)
                                 (temp[1, 1:col-1] :> [col_m_2]f32)
     let edge2 = map4 (\el above below right -> (right - el) / rx + (above + below - 2 * el) / ry)
                                     (temp[1:row-1, col-1] :> [row_m_2]f32)
                                     (temp[0:row-2, col-1] :> [row_m_2]f32)
                                     (temp[2:row-0, col-1] :> [row_m_2]f32)
                                     (temp[1:row-1, col-2] :> [row_m_2]f32)
     let edge3 = map4 (\el right left above -> (right + left - 2 * el) / rx + (above - el) / ry)
                      (temp[row-1, 1:col-1] :> [col_m_2]f32)
                      (temp[row-1, 0:col-2] :> [col_m_2]f32)
                      (temp[row-1, 2:col-0] :> [col_m_2]f32)
                      (temp[row-2, 1:col-1] :> [col_m_2]f32)
     let edge4 = map4 (\el above below right -> (right - el) / rx + (above + below - 2 * el) / ry)
                                 (temp[1:row-1, 0] :> [row_m_2]f32)
                                 (temp[0:row-2, 0] :> [row_m_2]f32)
                                 (temp[2:row-0, 0] :> [row_m_2]f32)
                                 (temp[1:row-1, 1] :> [row_m_2]f32)
     let internal = tabulate_2d (row-2) (col-2)
                                (\r c -> let r = r + 1
                                         let c = c + 1
                                         in (temp[r, c+1] + temp[r, c-1] - 2 * temp[r, c]) / rx +
                                            (temp[r+1, c] + temp[r-1, c] - 2 * temp[r, c]) / ry)
                                :> [row_m_2][col_m_2]f32
     in concat_to row
                  [concat_to col corners[0:1] (concat edge1 corners[1:2])]
                  (concat (map3 (\e4 i e2 -> concat_to col [e4] (concat i [e2])) edge4 internal edge2)
                          [concat_to col corners[3:4] (concat edge3 corners[2:3])])
        |> map3 (map3 (\t pow el -> t + (step / cap) * (pow + (el + (amb_temp - t) / rz)))) temp power

let main [row][col] (num_iterations: i32) (temp: [row][col]f32) (power: [row][col]f32): [][]f32 =
  compute_tran_temp num_iterations temp power
