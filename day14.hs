{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# OPTIONS_GHC -Wno-partial-type-signatures -fdefer-typed-holes -fno-warn-unused-imports #-}

import Criterion.Main
import Data.Bifunctor
import Data.Bits
import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as B
import Data.Char
import Data.Foldable
import Data.Function
import qualified Data.Graph as G
import Data.IntSet (IntSet)
import qualified Data.IntSet as IS
import Data.List
import Data.Map (Map)
import qualified Data.Map as M
import Data.Maybe
import Data.Set (Set)
import qualified Data.Set as S
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Vector (Vector)
import qualified Data.Vector as V
import Control.Monad
import qualified Text.ParserCombinators.ReadP as P
import Data.IntMap (IntMap)
import qualified Data.IntMap as IM
import Control.Applicative
import Data.Bits

-- Slow splitOn for prototyping
splitOn :: String -> String -> [String]
splitOn sep s = T.unpack <$> T.splitOn (T.pack sep) (T.pack s)

-- ByteString splitOn
splitOn' :: B.ByteString -> B.ByteString -> [B.ByteString]
splitOn' del bs = go bs
  where
    n = B.length del
    go bs = case B.breakSubstring del bs of
      (ls, rest) ->
        if B.null rest
          then ls : mempty
          else ls : splitOn' del (B.drop n rest)

-- Useful functions
findFirst :: Foldable f => (a -> Bool) -> f a -> a
findFirst f = fromJust . find f

slidingWindows :: Int -> [Int] -> [[Int]]
slidingWindows n l = take n <$> tails l

-- | Compute the average of the elements of a container.
avg :: (Integral c, Foldable t) => t c -> c
avg = uncurry div . foldl' (\(s, l) x -> (x + s, succ l)) (0, 0)

swap (a, b) = (b, a)

dup a = (a, a)

-- | Count the number of items in a container where the predicate is true.
countTrue :: Foldable f => (a -> Bool) -> f a -> Int
countTrue p = length . filter p . toList

-- | Build a frequency map
freqs :: (Foldable f, Ord a) => f a -> Map a Int
freqs = M.fromListWith (+) . map (,1) . toList

-- | map a function over elems satisfying a predicate
mapIf p f = foldl' (\xs x -> if p x then f x : xs else x : xs) []

-- | Set the element at index @n@ to @x@
setAt n x = (\(l, r) -> l ++ x : tail r) . splitAt n

-- | Like @findIndices@ but also return the element found for each index
findIndicesElem :: Foldable t => (a -> Bool) -> t a -> [(a, Int)]
findIndicesElem p = fst . foldl' go ([], 0 :: Int)
  where
    go (l, n) x
      | p x = ((x, n) : l, n + 1)
      | otherwise = (l, n + 1)

-- | Perturb a list's elements satisfying a predicate with a function
pertubationsBy :: (a -> Bool) -> (a -> a) -> [a] -> [[a]]
pertubationsBy p f l = [setAt n (f x) l | (x, n) <- findIndicesElem p l]

-- | Unconditional pertubation
pertubations :: (a -> a) -> [a] -> [[a]]
pertubations = pertubationsBy (const True)

-- | Generate all the segments of a list, O(n^2)
segs :: [a] -> [[a]]
segs = concatMap tails . inits

-- | Repeat a function until you get the same result twice.
fixedPoint :: Eq a => (a -> a) -> a -> a
fixedPoint f = go
  where
    go !x
        | x == y    = x
        | otherwise = go y
      where
        y = f x

-- Start working down here
part1, part2 :: _ -> Int
part1 i = undefined
part2 i = undefined

data L = Mask String | Ass Int Int deriving Show
parseLine = mem <|> mask
  where
    mask = P.string "mask = " *> (Mask <$> (P.manyTill (P.char 'X' <|> P.char '1' <|> P.char '0') (P.char '\n')))
    mem  = do
      P.string "mem["
      l <- P.readS_to_P reads
      P.string "] = "
      r <- P.readS_to_P reads
      P.char '\n'
      pure (Ass l r)

type S = (String, IntMap Int)
ev :: S -> L -> S
ev (m,arr) (Mask s) = (s, arr)
ev (m,arr) (Ass l r) = (m, IM.insert l val arr)
  where
    val = ref m r

ref :: String -> Int -> Int
ref l = foldl' g id l'
  where
    l' = zip [0..] (reverse l)
    g f (n,'X') = f
    g f (n,'0') = (\x -> f (clearBit x n))
    g f (n,'1') = (\x -> f (setBit x n))

b True = '1'
b False = '0'

ref2 :: String -> Int -> [Int]
ref2 l = foldl' g pure l'
  where
    l' = zip [0..] (reverse l)
    g f (n,'X') = (\x -> f =<< [setBit x n,clearBit x n])
    g f (n,'0') = f
    g f (n,'1') = (\x -> f (setBit x n))

-- foldInsert :: IntMap a -> [(Int,a)] -> IntMap a
foldInsert m [] = m
foldInsert m ((l,r):b) = foldInsert (IM.insert l r m) b

-- ev2 :: S -> L -> S
ev2 (m,arr) (Mask s) = (s, arr)
ev2 (m,arr) (Ass l r) = (m, foldInsert arr vals)
  where
    vals = [(loc, r) | loc <- ref2 m l]

main = do
  let dayNumber = 14 :: Int
  let dayString = "day" <> show dayNumber
  let dayFilename = dayString <> ".txt"
  inp <- readFile dayFilename
  let (dat,_) = (last (P.readP_to_S (P.many parseLine) inp))
  let (_,res) = foldl' ev (mempty,mempty) dat
  print (sum (IM.elems res))
  let (_,res2) = foldl' ev2 (mempty,mempty) dat
  print (sum (IM.elems res2))
  print ()
  -- print (take 10 inp)
  -- print (part1 inp)
  -- print (part2 inp)
  -- defaultMain
  --   [ bgroup
  --       dayString
  --       [ bench "part1" $ whnf part1 inp,
  --         bench "part2" $ whnf part2 inp
  --       ]
  --   ]
