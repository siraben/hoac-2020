{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE OverloadedStrings #-}

import Criterion.Main
import qualified Data.ByteString.Char8 as B
import qualified Data.Vector as V

solve :: B.ByteString -> Int
solve l = B.foldl' f 0 l
  where
    f n 'F' = 2 * n
    f n 'B' = 2 * n + 1
    f n 'L' = 2 * n
    f n 'R' = 2 * n + 1

-- (part1, part2)
genericSolve :: V.Vector B.ByteString -> (Int, Int)
genericSolve l = process (V.foldl' f init l)
  where
    -- min max sum
    init :: (Int, Int, Int)
    init = (maxBound, 0, 0)
    process (!a, !b, !c) = (b, (b * (b + 1) - a * (a - 1)) `div` 2 - c)
    f (!a, !b, !c) x = (min a n, max b n, c + n)
      where
        n = solve x

part1 :: V.Vector B.ByteString -> Int
part1 = fst . genericSolve

part2 :: V.Vector B.ByteString -> Int
part2 = snd . genericSolve

main = do
  let dayNumber = 5 :: Int
  let dayString = "day" <> show dayNumber
  let dayFilename = dayString <> ".txt"
  inp <- V.fromList . B.lines <$> B.readFile dayFilename
  print (part1 inp)
  print (part2 inp)
  defaultMain
    [ bgroup
        dayString
        [ bench "part1" $ whnf part1 inp,
          bench "part2" $ whnf part2 inp
        ]
    ]
