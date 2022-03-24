-- Code and comments based on
-- https://github.com/kkushagra/rodinia/blob/master/openmp/nw
--
-- ==
-- compiled random input { 64i64 10i32 [4198401]i32 [4198401]i32 }
-- compiled random input { 64i64 10i32 [67125249]i32 [67125249]i32 }
-- compiled random input { 64i64 10i32 [268468225]i32 [268468225]i32 }
-- compiled random input { 64i64 10i32 [1073807361]i32 [1073807361]i32 }

import "intrinsics"

let mkVal [bp1][b] (y:i32) (x:i32) (pen:i32) (block:[bp1][bp1]i32) (ref:[b][b]i32) : i32 =
  #[unsafe]
  i32.max (block[y, x - 1] - pen) (block[y - 1, x] - pen)
  |> i32.max (block[y - 1, x - 1] + ref[y - 1, x - 1])

let process_block [b][bp1]
                  (penalty: i32)
                  (above: [bp1]i32)
                  (left: [b]i32)
                  (ref: [b][b]i32): *[b][b]i32 =
  let block = assert (b + 1 == bp1) (tabulate_2d bp1 bp1 (\_ _ -> 0))
  let block[0, 0:] = above
  let block[1:, 0] = left

  -- Process the first half (anti-diagonally) of the block
  let block =
    loop block for m < b do
       let inds =
            tabulate b (\tx ->
                          if tx > m then (-1, -1)
                          else let ind_x = i32.i64 (tx + 1)
                               let ind_y = i32.i64 (m - tx + 1)
                               in (i64.i32 ind_y, i64.i32 ind_x))
        let vals =
            -- tabulate over the m'th anti-diagonal before the middle
            tabulate b
                     (\tx ->
                        if tx > m then 0
                        else let ind_x = i32.i64 (tx + 1)
                             let ind_y = i32.i64 (m - tx + 1)
                             let v = mkVal ind_y ind_x penalty block ref
                             in v)
        in scatter_2d block inds vals

  -- Process the second half (anti-diagonally) of the block
  let block = loop block for m < b-1 do
        let m = b - 2 - m
        let inds = tabulate b (\tx ->  (
                    if tx > m then (-1, -1)
                    else let ind_x = i32.i64 (tx + b - m)
                         let ind_y = i32.i64 (b - tx)
                         in  ((i64.i32 ind_y, i64.i32 ind_x)) )
                )
        let vals =
            -- tabulate over the m'th anti-diagonal after the middle
            tabulate b (\tx ->  (
                    if tx > m then (0)
                    else let ind_x = i32.i64 (tx + b - m)
                         let ind_y = i32.i64 (b - tx)
                         let v = mkVal ind_y ind_x penalty block ref
                         in  v ))
        in scatter_2d block inds vals

  in block[1:, 1:] :> *[b][b]i32

def main [n]
         (block_size: i64)
         (penalty: i32)
         (input: *[n]i32)
         (refs: [n]i32)
         : *[n]i32 =
  let row_length = i64.f64 <| f64.sqrt <| f64.i64 n
  let num_blocks = assert ((row_length - 1) % block_size == 0) ((row_length - 1) / block_size)
  let bp1 = assert (row_length > 3) (assert (2 * block_size < row_length) (block_size + 1))

  let input =
    loop input for i < num_blocks do
    let ip1 = i + 1
    let v =
      #[incremental_flattening(only_intra)]
      map3 (process_block penalty)
      (flat_index_2d input (i * block_size)
                     ip1 (row_length * block_size - block_size)
                     bp1 1)
      (flat_index_2d input (row_length + i * block_size)
                     ip1 (row_length * block_size - block_size)
                     block_size row_length)
      (flat_index_3d refs (row_length + 1 + i * block_size)
                     ip1 (row_length * block_size - block_size)
                     block_size row_length
                     block_size 1i64)
    in flat_update_3d
         input
         (row_length + 1 + i * block_size)
         (row_length * block_size - block_size)
         (row_length)
         1
         v

  let input =
    loop input for i < num_blocks - 1 do
    let v =
      #[incremental_flattening(only_intra)]
      map3 (process_block penalty)
      (flat_index_2d input (((i + 1) * block_size + 1) * row_length - block_size - 1)
                     (num_blocks - i - 1) (row_length * block_size - block_size)
                     bp1 1i64)
      (flat_index_2d input (((i + 1) * block_size + 1) * row_length - block_size - 1 + row_length)
                     (num_blocks - i - 1) (row_length * block_size - block_size)
                     block_size row_length)
      (flat_index_3d refs (((i + 1) * block_size + 2) * row_length - block_size)
                     (num_blocks - i - 1) (row_length * block_size - block_size)
                     block_size row_length
                     block_size 1i64)
    in flat_update_3d
         input
         (((i + 1) * block_size + 2) * row_length - block_size)
         (row_length * block_size - block_size)
         (row_length)
         1
         v

  in input
