{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
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
import Control.Applicative
import Data.IntMap (IntMap)
import qualified Data.IntMap as IM

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

-- -- Start working down here
-- part1, part2 :: _ -> Int
-- part1 i = undefined
-- part2 i = undefined

-- (m,t,s)
-- m: maps each number to the last turn it was spoken, and time before that
-- t: current turn
--                    l1   l2, where l1 most recent
-- s: most recently spoken
type State = (IntMap (Int,Int), Int)

emp = (mempty, 0)

_1 (a,b,c) = a
_2 (a,b,c) = b
_3 (a,b,c) = c

insShift n m t = IM.insert n (case m IM.!? n of
                                Nothing -> (t,0)
                                Just (a,b) -> (t,b)) m
--    new state and number spoken
-- update the state to contain the spoken number
step :: State -> Int -> (State,Int)
step (m,t) n = if n `IM.notMember` m
               then -- hasn't been spoken before
                 let (l1,l2) = m IM.! 0 -- look up 0 data
                 in
                   -- also set that 
                 (((IM.insert n (t,0) m), t + 1),0)
               else
                 -- otherwise it has been, so take diff
                 let (l1,l2) = m IM.! n
                     res = if l2 == 0 then t-l1 else l1-l2
                 in
                   case m IM.!? res of
                     Nothing -> ((IM.insert n (t,l1) m,t+1),res)
                     Just (l1,l2) -> ((IM.insert res (t,l1) m,t+1),res)
                   

iterN :: (a -> a) -> Int -> a -> a
iterN f = go
  where
    go 0 x = x
    go n x = go (n - 1) (f x)

b = iterN iter
startingState :: [Int] -> (State,Int)
startingState l' = ((arr,n+1), last l')
  where
    l = init l'
    n = length l
    arr = (IM.fromList (zip l (zip [1..n] (repeat 0))) )
iter :: (State,Int) -> (State,Int)
iter = uncurry step

-- f list turn number
--
naive (l@(x:xs)) = if length (take 2 hist) < 2 then 0:l else res:l
  where
    hist = findIndices (== x) l
    -- most recent time spoken
    res = hist !! 1 - hist !! 0
    l' = a ++ filter (/= x) b
      where
        (a,b) = splitAt (1 + (hist !! 1)) l

part1 inp' = head (iterN naive (2020 - length inp) inp)
  where
    inp = reverse inp'

data Dat = One Int | Two Int Int deriving Show
type S = (IntMap Dat, Int)

-- push :: Dat -> Int -> Dat
push n (One i) = Two n i
push n (Two a _) = Two n a
pushM n Nothing = One n
pushM n (Just x) = push n x

initState l = (IM.fromList (zip l (One <$> [1..n])), length l)
  where
     n = length l
naive2 :: S -> Int -> (S,Int)
naive2 (m,t) n = if fromMaybe 0 (len <$> hist) < 2
                 then ((IM.insert 0 (case (m IM.!? 0) of
                                       Nothing -> One (t + 1)
                                       Just n -> push (t + 1) n
                                       ) m, t+1),0)
                 else ((IM.insert res (pushM (t+1) (m IM.!? res)) m,t+1),res)
  where
    len (One _) = 1
    len (Two _ _) = 2
    hist = IM.lookup n m
    ext (Two a b) = a - b
    hist' = fromJust hist
    res = ext hist'
    -- most recent time spoken
    -- res = hist !! 1 - hist !! 0

part2 inp = snd (iterN (uncurry naive2) ((30000000 - length inp)) (initState inp,0))

main = do
  let dayNumber = 15
  let dayString = "day" <> show dayNumber
  let dayFilename = dayString <> ".txt"
  -- inp <- lines <$> readFile dayFilename
  --print (take 10 inp)
  let inp = [0,13,1,16,6,17]
  print (part1 inp)
  print (part2 inp)
  print ()
  -- print (part1 inp)
  -- print (part2 inp)
  -- defaultMain
  --   [ bgroup
  --       dayString
  --       [ bench "part1" $ whnf part1 inp,
  --         bench "part2" $ whnf part2 inp
  --       ]
  --   ]
