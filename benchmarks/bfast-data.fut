-- | Program for generating various "random" datasets for bfast
--
-- The values for "(M, N, n, nanfreq)" are given as input, where "M" denotes the
-- number of pixels, "N" denotes the timeseries length, "n" denotes the length
-- of the training set, and "nanfreq" denotes the frequency of NAN values in the
-- image.
--
-- For example, something similar to sahara dataset can be generated with the
-- arguments: 67968i64 414i64 1i32 0.25f64
--
-- This code is adapted from
-- https://github.com/diku-dk/futhark-kdd19/blob/bc6726faa3c7061fa2a94c86e94bfdf545deb5f3/bfast-futhark/data/gen-datasets/gen-data.fut

import "lib/github.com/diku-dk/cpprandom/random"

module bfast_data (I: integral) (R: real): {
  type real = R.t
  type int = I.t

  val gen: (M: i64) -> (N: i64) -> (n: int) -> (nanfreq: real) ->
               (int, int, int, real, real, real, [N]i32, [M][N]real)
} = {

  type real = R.t
  type int = I.t

  module distf = uniform_real_distribution R minstd_rand
  module disti = uniform_int_distribution  I minstd_rand

let gen (M: i64) (N: i64) (n: int) (nanfreq: real) :
         (int, int, int, real, real, real, [N]i32, [M][N]real) =
  let trend = I.i32 1
  let k     = I.i32 3
  let freq  = R.f32 12 -- for peru, 365f32 for sahara
  let hfrac = R.f32 0.25
  let lam   = R.f64 1.736126

  -- for simplicity take the mapping indices from 1..N
  let mappingindices = iota N
                       |> map (+1)
                       |> map i32.i64
  let rngi = minstd_rand.rng_from_seed [246]

  -- initialize the image
  let image = replicate M (replicate N R.nan)
  let (image, _) =
    loop (image, rngi) for i < M do
        -- init the floating-point seed.
        let rngf     = minstd_rand.rng_from_seed [123 + i32.i64 i]
        let rngf_nan = minstd_rand.rng_from_seed [369 + i32.i64 i]
        -- compute the break point.
        let (rngi, b0) = disti.rand (I.i32 1, I.(i64 N - n - i32 1)) rngi
        let break = I.(to_i64 <| b0 + n)
        -- fill in the time-series up to the breaking point with
        -- values in interval (4000, 8000) describing raining forests.
        let (image, rngf, rngf_nan) =
            loop (image, rngf, rngf_nan) for j < break do
                let (rngf_nan, q) = distf.rand (R.f32 0, R.f32 1) rngf_nan in
                if q R.< nanfreq then (image, rngf, rngf_nan)
                else let (rngf, x) = distf.rand (R.f32 4000, R.f32 8000) rngf
                     let image[i,j] = x
                     in  (image, rngf, rngf_nan)
        -- fill in the points after the break.
        let (image, _rngf, _rngf_nan) =
            loop (image, rngf, rngf_nan) for j0 < N-break do
                let (rngf_nan, q) = distf.rand (R.f32 0, R.f32 1) rngf_nan in
                if q R.< nanfreq then (image, rngf, rngf_nan)
                else let j = j0 + break
                     let (rngf, x) = distf.rand (R.f32 0, R.f32 5000) rngf
                     let image[i,j] = x
                     in  (image, rngf, rngf_nan)
        in  (image, rngi)
  in (trend, k, n, freq, hfrac, lam, mappingindices, image)
}
