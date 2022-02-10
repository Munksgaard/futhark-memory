-- LocVolCalib
-- ==
-- compiled input @ LocVolCalib-data/small.in
-- compiled input @ LocVolCalib-data/medium.in
-- compiled input @ LocVolCalib-data/large.in
-- compiled input @ LocVolCalib-data/huge.in

let initGrid (s0: f64) (alpha: f64) (nu: f64) (t: f64) (numX: i64) (numY: i64) (numT: i64)
  : (i32, i32, [numX]f64, [numY]f64, [numT]f64) =
  let logAlpha = f64.log alpha
  let myTimeline = map (\i -> t * f64.i64 i / (f64.i64 numT - 1.0)) (iota numT)
  let (stdX, stdY) = (20.0 * alpha * s0 * f64.sqrt(t),
                      10.0 * nu         * f64.sqrt(t))
  let (dx, dy) = (stdX / f64.i64 numX, stdY / f64.i64 numY)
  let (myXindex, myYindex) = (i32.f64 (s0 / dx), i32.i64 numY / 2)
  let myX = tabulate numX (\i -> f64.i64 i * dx - f64.i32 myXindex * dx + s0)
  let myY = tabulate numY (\i -> f64.i64 i * dy - f64.i32 myYindex * dy + logAlpha)
  in (myXindex, myYindex, myX, myY, myTimeline)

-- make the innermost dimension of the result of size 4 instead of 3?
let initOperator [n] (x: [n]f64): ([n][3]f64,[n][3]f64) =
  let dxu     = x[1] - x[0]
  let dx_low  = [[0.0, -1.0 / dxu, 1.0 / dxu]]
  let dxx_low = [[0.0, 0.0, 0.0]]
  let dx_mids = map (\i ->
                       let dxl = x[i] - x[i-1]
                       let dxu = x[i+1] - x[i]
                       in ([ -dxu/dxl/(dxl+dxu), (dxu/dxl - dxl/dxu)/(dxl+dxu),      dxl/dxu/(dxl+dxu) ],
                           [  2.0/dxl/(dxl+dxu), -2.0*(1.0/dxl + 1.0/dxu)/(dxl+dxu), 2.0/dxu/(dxl+dxu) ]))
                    (1...n-2)
  let (dx_mid, dxx_mid) = unzip dx_mids
  let dxl      = x[n-1] - x[n-2]
  let dx_high  = [[-1.0 / dxl, 1.0 / dxl, 0.0 ]]
  let dxx_high = [[0.0, 0.0, 0.0 ]]
  let dx     = dx_low ++ dx_mid ++ dx_high :> [n][3]f64
  let dxx    = dxx_low ++ dxx_mid ++ dxx_high :> [n][3]f64
  in  (dx, dxx)

let setPayoff [numX][numY] (strike: f64, myX: [numX]f64, _myY: [numY]f64): *[numY][numX]f64 =
  replicate numY (map (\xi -> f64.max (xi-strike) 0.0) myX)

-- Returns new myMuX, myVarX, myMuY, myVarY.
let updateParams [numX][numY]
                (myX:  [numX]f64, myY: [numY]f64,
                 tnow: f64, _alpha: f64, beta: f64, nu: f64)
  : ([numY][numX]f64, [numY][numX]f64, [numX][numY]f64, [numX][numY]f64) =
  let myMuY  = replicate numX (replicate numY 0.0)
  let myVarY = replicate numX (replicate numY (nu*nu))
  let myMuX  = replicate numY (replicate numX 0.0)
  let myVarX = map (\yj ->
                      map (\xi -> f64.exp(2.0*(beta*f64.log(xi) + yj - 0.5*nu*nu*tnow)))
                          myX)
                   myY
  in  ( myMuX, myVarX, myMuY, myVarY )

let tridagPar [n] (a:  [n]f64, b: [n]f64, c: [n]f64, y: [n]f64 ): *[n]f64 =
  #[unsafe]
  ----------------------------------------------------
  -- Recurrence 1: b[i] = b[i] - a[i]*c[i-1]/b[i-1] --
  --   solved by scan with 2x2 matrix mult operator --
  ----------------------------------------------------
  let b0   = b[0]
  let mats = map  (\i ->
                     if 0 < i
                     then (b[i], 0.0-a[i]*c[i-1], 1.0, 0.0)
                     else (1.0,  0.0,             0.0, 1.0))
                  (iota n)
  let scmt = scan (\(a0,a1,a2,a3) (b0,b1,b2,b3) ->
                     let value = 1.0/(a0*b0)
                     in ( (b0*a0 + b1*a2)*value,
                          (b0*a1 + b1*a3)*value,
                          (b2*a0 + b3*a2)*value,
                          (b2*a1 + b3*a3)*value))
                  (1.0,  0.0, 0.0, 1.0) mats
  let b    = map (\(t0,t1,t2,t3) ->
                    (t0*b0 + t1) / (t2*b0 + t3))
                 scmt
  ------------------------------------------------------
  -- Recurrence 2: y[i] = y[i] - (a[i]/b[i-1])*y[i-1] --
  --   solved by scan with linear func comp operator  --
  ------------------------------------------------------
  let y0   = y[0]
  let lfuns= map  (\i  ->
                     if 0 < i
                     then (y[i], 0.0-a[i]/b[i-1])
                     else (0.0,  1.0))
                  (iota n)
  let cfuns= scan (\(a: (f64,f64)) (b: (f64,f64)): (f64,f64)  ->
                     let (a0,a1) = a
                     let (b0,b1) = b
                     in ( b0 + b1*a0, a1*b1 ))
                  (0.0, 1.0) lfuns
  let y    = map (\(tup: (f64,f64)): f64  ->
                    let (a,b) = tup
                    in a + b*y0)
                 cfuns
  ------------------------------------------------------
  -- Recurrence 3: backward recurrence solved via     --
  --             scan with linear func comp operator  --
  ------------------------------------------------------
  let yn   = y[n-1]/b[n-1]
  let lfuns= map (\k  ->
                    let i = n-k-1
                    in  if   0 < k
                        then (y[i]/b[i], 0.0-c[i]/b[i])
                        else (0.0,       1.0))
                 (iota n)
  let cfuns= scan (\(a: (f64,f64)) (b: (f64,f64)): (f64,f64)  ->
                     let (a0,a1) = a
                     let (b0,b1) = b
                     in (b0 + b1*a0, a1*b1))
                  (0.0, 1.0) lfuns
  let y    = map (\(tup: (f64,f64)): f64  ->
                    let (a,b) = tup
                    in a + b*yn)
                 cfuns
  let y    = map (\i -> y[n-i-1]) (iota n)
  in y

let explicitMethod [m][n] (myD:    [m][3]f64,  myDD: [m][3]f64,
                           myMu:   [n][m]f64,  myVar: [n][m]f64,
                           result: [n][m]f64)
                  : *[n][m]f64 =
  -- 0 <= i < m AND 0 <= j < n
  map3 (\mu_row var_row result_row ->
          map5 (\dx dxx mu var j ->
                  let c1 = if 0 < j
                           then (mu*dx[0] + 0.5*var*dxx[0]) * #[unsafe] result_row[j-1]
                           else 0.0
                  let c3 = if j < (m-1)
                           then (mu*dx[2] + 0.5*var*dxx[2]) * #[unsafe] result_row[j+1]
                           else 0.0
                  let c2 =      (mu*dx[1] + 0.5*var*dxx[1]) * #[unsafe] result_row[j  ]
                  in  c1 + c2 + c3)
               myD myDD mu_row var_row (iota m))
       myMu myVar result

-- for implicitY: should be called with transpose(u) instead of u
let implicitMethod [n][m] (myD:  [m][3]f64,  myDD:  [m][3]f64,
                           myMu: [n][m]f64,  myVar: [n][m]f64,
                           u:   *[n][m]f64,  dtInv: f64)
                  : *[n][m]f64 =
  map3 (\mu_row var_row u_row  ->
          let (a,b,c) = unzip3 (map4 (\mu var d dd ->
                                        ( 0.0   - 0.5*(mu*d[0] + 0.5*var*dd[0])
                                        , dtInv - 0.5*(mu*d[1] + 0.5*var*dd[1])
                                        , 0.0   - 0.5*(mu*d[2] + 0.5*var*dd[2])))
                                     mu_row var_row myD myDD)
          in tridagPar( a, b, c, u_row ))
       myMu myVar u

let rollback
  [numX][numY]
  (tnow: f64, tnext: f64, myResult: [numY][numX]f64,
   myMuX: [numY][numX]f64, myDx: [numX][3]f64, myDxx: [numX][3]f64, myVarX: [numY][numX]f64,
   myMuY: [numX][numY]f64, myDy: [numY][3]f64, myDyy: [numY][3]f64, myVarY: [numX][numY]f64)
  : [numY][numX]f64 =
  let dtInv = 1.0/(tnext-tnow)
  -- explicitX
  let u = explicitMethod( myDx, myDxx, myMuX, myVarX, myResult )
  let u = map2 (map2 (\u_el res_el  -> dtInv*res_el + 0.5*u_el))
               u myResult
  -- explicitY
  let myResultTR = transpose(myResult)
  let v = explicitMethod(myDy, myDyy, myMuY, myVarY, myResultTR)
  let u = map2 (map2 (+)) u (transpose v)
  -- implicitX
  let u = implicitMethod( myDx, myDxx, myMuX, myVarX, u, dtInv )
  -- implicitY
  let y = map2 (\u_row v_row ->
                  map2 (\u_el v_el -> dtInv*u_el - 0.5*v_el) u_row v_row)
               (transpose u) v
  let myResultTR = implicitMethod( myDy, myDyy, myMuY, myVarY, y, dtInv )
  in transpose myResultTR

let value(numX: i64, numY: i64, numT: i64, s0: f64, strike: f64, t: f64, alpha: f64, nu: f64, beta: f64): f64 =
  let (myXindex, myYindex, myX, myY, myTimeline) =
    initGrid s0 alpha nu t numX numY numT
  let (myDx, myDxx) = initOperator(myX)
  let (myDy, myDyy) = initOperator(myY)
  let myResult = setPayoff(strike, myX, myY)
  let numT' = numT - 1
  let myTimeline_neighbours = reverse (zip (init myTimeline :> [numT']f64)
                                           (tail myTimeline :> [numT']f64))
  let myResult = loop (myResult) for (tnow,tnext) in myTimeline_neighbours do
                 let (myMuX, myVarX, myMuY, myVarY) =
                   updateParams(myX, myY, tnow, alpha, beta, nu)
                 let myResult = rollback(tnow, tnext, myResult,
                                         myMuX, myDx, myDxx, myVarX,
                                         myMuY, myDy, myDyy, myVarY)

                 in myResult
  in myResult[myYindex,myXindex]

let main (outer_loop_count: i32) (numX: i32) (numY: i32) (numT: i32)
         (s0: f64) (t: f64) (alpha: f64) (nu: f64) (beta: f64): []f64 =
  let strikes = map (\i -> 0.001*f64.i64 i) (iota (i64.i32 outer_loop_count))
  let res =
    #[incremental_flattening(only_inner)]
    map (\x -> value(i64.i32 numX, i64.i32 numY, i64.i32 numT, s0, x, t, alpha, nu, beta))
    strikes
  in res
