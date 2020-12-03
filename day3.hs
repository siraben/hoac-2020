import Data.List (foldl')
import qualified Data.Text as T
import qualified Data.Text.IO as TIO

part1 :: [T.Text] -> Int
part1 = solveGeneric 3

-- Solve for right r down 1
solveGeneric :: Int -> [T.Text] -> Int
solveGeneric r = fst . foldl' f (0, r) . tail
  where
    -- (number of #s, col counter)
    f (hs, cc) l = (hs + if l `T.index` cc == '#' then 1 else 0, (cc + r) `mod` 31)

part2 :: [T.Text] -> Int
part2 i = product ((`solveGeneric` i) <$> [1, 3, 5, 7]) * foo
  where
    foo = fst (foldl' g (0, 1) (tail (fst (foldr f ([], True) i))))
    f x (l, b) = (if b then x : l else l, not b)
    g (hs, cc) l = (hs + if l `T.index` cc == '#' then 1 else 0, (cc + 1) `mod` 31)

main = do
  inp <- T.lines <$> TIO.readFile "day3.txt"
  print (part1 inp)
  print (part2 inp)
