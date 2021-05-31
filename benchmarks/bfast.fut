-- BFAST-irregular: version handling obscured observations (e.g., clouds)

-- ==
-- entry: bfast_f32
-- script input { gen_bfast_data_32 67968i64 414i64 1i32 0.25f32 }
-- script input { gen_bfast_data_32 111556i64 235i64 1i32 0.25f32 }
-- script input { gen_bfast_data_32 589824i64 327i64 1i32 0.25f32 }

-- ==
-- entry: bfast_f64
-- script input { gen_bfast_data_64 67968i64 414i64 1i32 0.25f64 }
-- script input { gen_bfast_data_32 111556i64 235i64 1i32 0.25f64 }
-- script input { gen_bfast_data_32 589824i64 327i64 1i32 0.25f64 }


import "lib/github.com/diku-dk/sorts/insertion_sort"
import "bfast-data"

module bfast_data_32 = bfast_data i32 f32
module bfast_data_64 = bfast_data i32 f64

entry gen_bfast_data_32 = bfast_data_32.gen
entry gen_bfast_data_64 = bfast_data_64.gen


module gen_bfast (R: real) : {
  type real = R.t

  val compute [N][m]:
    (trend: i32) -> (k: i32) -> (n: i32) -> (freq: real) -> (hfrac: real)
    -> (lam: real) -> (mappingindices : [N]i32) -> (images : [m][N]real)
    -> ([m]i32, [m]i32, [m]real)
} = {

  type real = R.t

  let iota32 (x: i64) : []i32 =
    iota x |> map i32.i64

  let iota3232: (i32 -> []i32) =
    iota32 <-< i64.i32

  let logplus (x: real) : real =
    R.(if x > (exp <| f32 1)
       then log x else R.f32 1)

  let adjustValInds [N] (n : i32) (ns : i32) (Ns : i32) (val_inds : [N]i32) (ind: i32) : i32 =
    if ind < Ns - ns then val_inds[ind + ns] - n else -1

  let filterPadWithKeys [n] 't
           (p : (t -> bool))
           (dummy : t)
           (arr : [n]t) : (i32, [n]t, [n]i32) =
  let tfs = map (\a -> if p a then 1i64 else 0i64) arr
  let isT = scan (+) 0i64 tfs
  let i   = last isT |> i32.i64
  let inds= map2 (\a iT -> if p a then iT - 1 else -1i64) arr isT
  let rs  = scatter (replicate n dummy) inds arr
  let ks  = scatter (replicate n 0i32) inds (iota32 n)
  in (i, rs, ks)

  -- | builds the X matrices; first result dimensions of size 2*k+2
  let mkX_with_trend [N] (k2p2: i64) (f: real) (mappingindices: [N]i32): [k2p2][N]real =
    map (\ i ->
           map (\ind ->
                  if i == 0 then R.f32 1
                  else if i == 1 then R.i32 ind
                  else let (i', j') = (R.i64 (i / 2), R.i32 ind)
                       let angle = R.(R.f32 2 * pi * i' * j' / f)
                       in  if i % 2 == 0 then R.sin angle
                           else R.cos angle
               ) mappingindices
        ) (iota k2p2)

  let mkX_no_trend [N] (k2p2m1: i64) (f: real) (mappingindices: [N]i32): [k2p2m1][N]real =
    map (\ i ->
           map (\ind ->
                  if i == 0 then R.f32 1
                  else let i = i + 1
                       let (i', j') = (R.i32 (i / 2), R.i32 ind)
                       let angle = R.(R.f32 2 * pi * i' * j' / f)
                       in
                       if i % 2 == 0 then R.sin angle
                       else R.cos angle
               ) mappingindices
        ) (iota32 k2p2m1)

  -- Adapted matrix inversion so that it goes well with intra-block parallelism
  let gauss_jordan [nm] (n:i32) (m:i32) (A: *[nm]real): [nm]real =
    loop A for i < n do
    let v1 = A[i64.i32 i]
    let A' = map (\ind -> let (k, j) = (ind / m, ind % m)
                          in if R.(v1 == R.f32 0.0) then A[i64.i32 (k * m + j)] else
                             let x = A[i64.i32 j] R./ v1 in
                             if k < n - 1  -- Ap case
                             then A[i64.i32 ((k + 1) * m + j)] R.- A[i64.i32((k + 1) * m + i)] R.* x
                             else x        -- irow case
                 ) (map i32.i64 (iota nm))
    in  scatter A (iota nm) A'

  let mat_inv [n0] (A: [n0][n0]real): [n0][n0]real =
    let n  = i32.i64 n0
    let m  = 2 * n
    let nm = 2 * n0 * n0
    -- Pad the matrix with the identity matrix.
    let Ap = map (\ind -> let (i, j) = (ind / m, ind % m)
                          in  if j < n then A[i,j]
                              else if j == n + i
                              then R.i32 1
                              else R.i32 0
                 ) (iota32 nm)
    let Ap'  = gauss_jordan n m Ap
    let Ap'' = unflatten n0 (i64.i32 m) Ap'
    -- Drop the identity matrix at the front
    in Ap''[0:n0, n0:(2 * n0)] :> [n0][n0]real

  --------------------------------------------------
  --------------------------------------------------

  let dotprod [n] (xs: [n]real) (ys: [n]real): real =
    reduce (R.+) (R.f32 0.0) <| map2 (R.*) xs ys

  let matvecmul_row [n][m] (xss: [n][m]real) (ys: [m]real) =
    map (dotprod ys) xss

  let dotprod_filt [n] (vct: [n]real) (xs: [n]real) (ys: [n]real) : real =
    R.sum (map3 R.(\v x y -> x * y * if isnan v then R.f32 0.0 else R.f32 1.0) vct xs ys)

  let matvecmul_row_filt [n][m] (xss: [n][m]real) (ys: [m]real) =
    map R.(\xs -> map2 (\x y -> if isnan y then R.f32 0 else x*y) xs ys |> sum) xss

  let matmul_filt [n][p][m] (xss: [n][p]real) (yss: [p][m]real) (vct: [p]real) : [n][m]real =
    map (\xs -> map (dotprod_filt vct xs) (transpose yss)) xss


  -- implementation is in this entry point the outer map is distributed directly
  let mainFun [m][N] (trend: i32) (k: i32) (n: i32) (freq: real)
                  (hfrac: real) (lam: real)
                  (mappingindices : [N]i32)
                  (images : [m][N]real) =

  -- 1. make interpolation matrix
  let n64 = i64.i32 n
  let k2p2 = 2 * k + 2
  let k2p2' = if trend > 0 then k2p2 else k2p2-1
  let X = (if trend > 0
           then mkX_with_trend (i64.i32 k2p2') freq mappingindices
           else mkX_no_trend (i64.i32 k2p2') freq mappingindices)
          |> intrinsics.opaque

  -- PERFORMANCE BUG: instead of `let Xt = copy (transpose X)`
  --   we need to write the following ugly thing to force manifestation:
  let zero = R.i64 <| (N * N + 2 * N + 1) / (N + 1) - N - 1
  let Xt  = intrinsics.opaque <| map (map (R.+ zero)) (copy (transpose X))

  let Xh  = X[:,:n64]
  let Xth = Xt[:n64,:]
  let Yh  = images[:,:n64]

  -- 2. mat-mat multiplication
  let Xsqr = intrinsics.opaque <| map (matmul_filt Xh Xth) Yh

  -- 3. matrix inversion
  let Xinv = intrinsics.opaque <| map mat_inv Xsqr

  -- 4. several matrix-vector multiplication
  let beta0  = map (matvecmul_row_filt Xh) Yh   -- [m][2k+2]
               |> intrinsics.opaque

  let beta   = map2 matvecmul_row Xinv beta0    -- [m][2k+2]
               |> intrinsics.opaque -- ^ requires transposition of Xinv
                                    --   unless all parallelism is exploited

  let y_preds= map (matvecmul_row Xt) beta      -- [m][N]
               |> intrinsics.opaque -- ^ requires transposition of Xt (small)
                                    --   can be eliminated by passing
                                    --   (transpose X) instead of Xt

  -- 5. filter etc.
  let (Nss, y_errors, val_indss) = intrinsics.opaque <| unzip3 <|
                                   map2 (\y y_pred ->
                                           let y_error_all = map2 R.(\ye yep -> if !(isnan ye)
                                                                                then ye - yep
                                                                                else nan
                                                                    ) y y_pred
                                           in filterPadWithKeys (\y -> !(R.isnan y)) R.nan y_error_all
                                        ) images y_preds

  -- 6. ns and sigma (can be fused with above)
  let (hs, nss, sigmas) = intrinsics.opaque <| unzip3 <|
                          map2 (\yh y_error ->
                                  let ns    = map (\ye -> if !(R.isnan ye) then 1 else 0) yh
                                              |> reduce (+) 0
                                  let sigma = map (\i -> if i < ns then y_error[i] else R.f32 0.0) (iota3232 n)
                                              |> map R.(\a -> a * a)
                                              |> reduce (R.+) (R.f32 0.0)
                                  let sigma = R.sqrt (sigma R./ (R.i32 (ns - k2p2)))
                                  let h     = i32.i64 <| R.to_i64 <| R.i32 ns R.* hfrac
                                  in  (h, ns, sigma)
                               ) Yh y_errors

  -- 7. moving sums first and bounds:
  let hmax = reduce_comm (i32.max) 0 hs
  let MO_fsts = zip3 y_errors nss hs
                |> map (\(y_error, ns, h) ->
                          map (\i -> if i < h
                                     then y_error[i + ns - h + 1]
                                     else (R.f32 0.0)
                              ) (iota3232 hmax)
                          |> reduce (R.+) (R.f32 0.0)
                       ) |> intrinsics.opaque

  let BOUND = map (\q -> let time = mappingindices[n + q]
let tmp  = logplus (R.i32 time R./ R.i32 mappingindices[n - 1])
in  lam R.* (R.sqrt tmp)
                  ) (iota32 (N-n64))

  -- 8. error magnitude computation:
  let magnitudes =
    zip3 Nss nss y_errors
    |> map (\(Ns, ns, y_error) ->
              map (\i -> if i < Ns - ns && !(R.isnan y_error[ns + i])
                         then y_error[ns + i]
                         else R.inf
                  )
                  (iota32 (N - n64))
    -- sort
    |> insertion_sort (R.<=)
    -- extract median
    |> (\xs -> let i = (Ns - ns) / 2
               let j = i - 1
               in if Ns == ns then
                    R.f32 0
                  else if (Ns - ns) % 2 == 0 then
                         R.((xs[j] + xs[i]) / f32 2)
                  else xs[i])
           )
    |> intrinsics.opaque

  -- 9. moving sums computation:
  let (MOs, MOs_NN, breaks, means) =
    zip (zip4 Nss nss sigmas hs)
        (zip3 MO_fsts y_errors val_indss)
    |> map (\ ( (Ns,ns,sigma, h), (MO_fst,y_error,val_inds) ) ->
              let MO' = map (\j -> if j >= Ns - ns then R.f32 0.0
                                  else if j == 0 then MO_fst
                                  else y_error[ns + j] R.- y_error[ns - h + j]
                           )
                           (iota32 (N - n64))
                       |> scan (R.+) (R.f32 0.0)
                       |> map R.(\mo -> mo / (sigma * (sqrt (i32 ns))))
              let (is_break, fst_break) =
                map3 (\mo' b j -> if j < Ns - ns && !(R.isnan mo')
                                  then ( R.abs mo' R.> b, j )
                                  else ( false, j )
                     ) MO' BOUND (iota32 (N - n64))
                |> reduce (\(b1, i1) (b2, i2) ->
                             if b1 then (b1, i1)
                             else if b2 then (b2, i2)
                             else (b1, i1))
                          (false, -1)
              let mean = map2 (\x j -> if j < Ns - ns then x else R.f32 0.0 )
                              MO'
                              (iota32 (N - n64))
                         |> reduce (R.+) (R.f32 0.0)
                         |> (\x -> if (Ns - ns) == 0 then R.f32 0 else x R./ (R.i32 (Ns - ns)))
              let fst_break' = if !is_break then -1
                               else adjustValInds n ns Ns val_inds fst_break
              let fst_break' = if ns <=5 || Ns-ns <= 5 then -2 else fst_break'
              -- The computation of MO'' should be moved just after MO' to make bounds consistent
              let val_inds' = map (adjustValInds n ns Ns val_inds) (iota32 (N - n64))
              let MO'' = scatter (replicate (N - n64) R.nan) (map i64.i32 val_inds') MO'
              in (MO'', MO', fst_break', mean)
           )
    |> unzip4

  in (MO_fsts, Nss, nss, sigmas, MOs, MOs_NN, BOUND, breaks, means, magnitudes, y_errors, y_preds)

  let compute [m][N] (trend: i32) (k: i32) (n: i32) (freq: real)
                  (hfrac: real) (lam: real)
                  (mappingindices : [N]i32)
                  (images : [m][N]real) =
  let (_, Nss, _, _, _, _, _, breaks, means, _, _, _) =
    mainFun trend k n freq hfrac lam mappingindices images
  in (Nss, breaks, means)

}

module bfast_f32_m = gen_bfast f32
module bfast_f64_m = gen_bfast f64

entry bfast_f32 = bfast_f32_m.compute
entry bfast_f64 = bfast_f64_m.compute
