-- Parallel blocked LU-decomposition.
--
-- ==
-- compiled script input { generate 2048i64 }
-- compiled script input { generate 4096i64 }
-- compiled script input { generate 8192i64 }
-- compiled script input { generate 16384i64 }

module lud_input = import "lud-input"

entry generate = lud_input.main

let dotprod [n] (a: [n]f64) (b: [n]f64): f64 =
  map2 (*) a b
       |> reduce (+) 0

let lud_diagonal [b] (a: [b][b]f64): *[b][b]f64 =
  map1 (\mat ->
          let mat = copy mat
          in loop (mat: *[b][b]f64) for i < b-1 do
             let col = map (\j -> if j > i then
                                    #[unsafe] (mat[j,i] - (dotprod mat[j,:i] mat[:i,i])) / mat[i,i]
                                  else
                                    mat[j,i])
                           (iota b)
            let mat[:,i] = col

            let row = map (\j -> if j > i then
                                   mat[i+1, j] - (dotprod mat[:i+1, j] mat[i+1, :i+1])
                                 else
                                   mat[i+1, j])
                          (iota b)
            let mat[i+1] = row

            in mat
       ) (unflatten (opaque 1) b a)
       |> head

let lud_perimeter_upper [m][b] (diag: [b][b]f64, a0s: [m][b][b]f64): *[m][b][b]f64 =
    let a1s = map (\ (x: [b][b]f64): [b][b]f64  -> transpose(x)) a0s in
    let a2s =
        map  (\a1: [b][b]f64  ->
              map  (\row0: [b]f64  ->   -- Upper
                    loop row = copy row0 for i < b do
                    let sum = (loop sum=0.0f64 for k < i do sum + diag[i,k] * row[k])
                    let row[i] = row[i] - sum
                    in  row
                   ) a1
             ) a1s
    in map (\x: [b][b]f64 -> transpose(x)) a2s

let lud_perimeter_lower [b][m] (diag: [b][b]f64, mat: [m][b][b]f64): *[m][b][b]f64 =
  map (\blk: [b][b]f64  ->
        map  (\ (row0: [b]f64): *[b]f64  ->   -- Lower
                loop row = copy row0 for j < b do
                        let sum = loop sum=0.0f64 for k < j do
                            sum + diag[k,j] * row[k]
                        let row[j] = (row[j] - sum) / diag[j,j]
                        in  row
            ) blk
      ) mat

let lud_internal [m][b] (top_per: [m][b][b]f64, lft_per: [m][b][b]f64, mat_slice: [m][m][b][b]f64 ): *[m][m][b][b]f64 =
  let top_slice = map transpose top_per in
  map (\(mat_arr: [m][b][b]f64, lft: [b][b]f64): [m][b][b]f64  ->
        map (\ (mat_blk: [b][b]f64, top: [b][b]f64): [b][b]f64  ->
                map  (\ (mat_row: [b]f64, lft_row: [b]f64): [b]f64  ->
                        map  (\(mat_el, top_row)  ->
                                let prods = map2 (*) lft_row top_row
                                let sum   = f64.sum prods
                                in mat_el - sum
                             ) (zip (mat_row) top)
                    ) (zip (mat_blk) lft )
           ) (zip (mat_arr) (top_slice) )
     ) (zip (mat_slice) (lft_per) )

let block_size: i64 = 32

let pad_to [n] 'a (m: i64) (x: a) (arr: [n]a) : [m]a =
  arr ++ replicate (m - n) x :> [m]a

let main [m] (mat: [m][m]f64): [m][m]f64 =
    let b = block_size
    let num_blocks = (m+b-1) / b -- rounding up
    let n = b * num_blocks
    -- Maybe pad the input to be a multiple of the block size.
    let padding = n - m
    let mat = if padding != 0
              then map (pad_to n 0) mat ++
                   replicate padding (replicate n 0f64)
              else mat :> [n][n]f64
    ---- transform matrix in [n/b,n/b,b,b] block ----
    ---- versions for upper and lower parts      ----
    ---- the blocks of the lower part            ----
    let matb =
        map  (\i_b: [num_blocks][b][b]f64  ->
                map  (\j_b: [b][b]f64  ->
                        map (\i: [b]f64  ->
                                map  (\j: f64  ->
                                        #[unsafe] mat[i_b*b+i, j_b*b + j]
                                    ) (iota(b) )
                           ) (iota(b) )
                    ) (iota(num_blocks) )
            ) (iota(num_blocks) )

    let matb = loop(matb) for step < ((n / b) - 1) do
        -- 1. compute the current diagonal block
        let diag = lud_diagonal(matb[step,step]) in
        let matb[step,step] = diag

        -- 2. compute the top  perimeter
        let row_slice = matb[step,step+1:num_blocks]
        let top_per_irreg = lud_perimeter_upper(diag, row_slice)
        let matb[step, step+1:num_blocks] = top_per_irreg

        -- 3. compute the left perimeter and update matrix
        let col_slice = matb[step+1:num_blocks,step]
        let lft_per_irreg = lud_perimeter_lower(diag, col_slice)
        let matb[step+1:num_blocks, step] = lft_per_irreg

        -- 4. compute the internal blocks
        let inner_slice = matb[step+1:num_blocks,step+1:num_blocks]
        let internal = lud_internal(top_per_irreg, lft_per_irreg, inner_slice)
        let matb[step+1:num_blocks, step+1:num_blocks] = internal

        -- 5. update matrix in place
        in matb

    let last_step = (n / b) - 1 in
    let matb[last_step,last_step] =
            lud_diagonal( matb[last_step, last_step] )

    let ret_padded = map (\i_ind  ->
                          map  (\j_ind  ->
                                let (ii, jj) = (i_ind/b, j_ind/b)
                                let ( i,  j) = (i_ind - ii*b, j_ind - jj*b)
                                in  #[unsafe] matb[ii,jj,i,j]
                               ) (iota n)
                         ) (iota n)
    in take m (map (take m) ret_padded)
