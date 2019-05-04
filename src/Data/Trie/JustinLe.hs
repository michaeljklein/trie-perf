{-# language DeriveFunctor #-}
module Data.Trie.JustinLe (Trie, lookup, fromList, singleton) where

import Data.Fix (Fix(..), cata, ana)
import qualified Data.Map as M
import Prelude hiding (lookup)

{- | from 
https://blog.jle.im/entry/tries-with-recursion-schemes.html
-}



data TrieF k v x = TF (Maybe v) (M.Map k x) deriving (Functor, Show)

newtype Trie k v = Trie { unTrie :: Fix (TrieF k v) } deriving (Show)

cataTrie :: (TrieF k v a -> a) -> Trie k v -> a
cataTrie phi t = cata phi (unTrie t)
anaTrie :: (a -> TrieF k v a) -> a -> Trie k v
anaTrie psi z = Trie $ ana psi z


lookup :: Ord k => [k] -> Trie k v -> Maybe v
lookup ks t = cataTrie lookupAlg t ks

lookupAlg :: Ord k => TrieF k v ([k] -> Maybe v) -> ([k] -> Maybe v)
lookupAlg (TF v looks) kss = case kss of
  [] -> v
  k:ks -> case M.lookup k looks of
    Nothing -> Nothing
    Just lf -> lf ks



fromList :: (Ord k) => [([k], v)] -> Trie k v
fromList = fromMap . M.fromList

fromMap :: Ord k => M.Map [k] v -> Trie k v
fromMap = anaTrie fromMapCo

fromMapCo :: Ord k => M.Map [k] a -> TrieF k a (M.Map [k] a)
fromMapCo mp =
  TF (M.lookup [] mp)
     (M.fromListWith M.union [(k, M.singleton ks v) | (k:ks, v) <- M.toList mp] )



singleton :: v -> [k] -> Trie k v
singleton v = anaTrie (singletonCo v) 

singletonCo :: v -> [k] -> TrieF k v [k]
singletonCo v = sCoalg where
  sCoalg []     = TF (Just v) M.empty
  sCoalg (k:ks) = TF Nothing (M.singleton k ks)
