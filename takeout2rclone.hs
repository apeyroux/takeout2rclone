#! /usr/bin/env nix-shell
#! nix-shell -i runghc -p "ghc.withPackages (p: [ p.shelly ])"

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}

import           Data.List
import qualified Data.Text as T
import           Shelly
import           System.Environment

default (T.Text)

type RclonePath = T.Text

pushToRclone :: RclonePath -> [Shelly.FilePath] -> Sh ()
pushToRclone rp = mapM_ $ \tgz -> do
  withTmpDir $ \tmpd -> do
                 echo $ "untar " <> toTextIgnore tgz <> " in " <> toTextIgnore tmpd
                 run_ "tar" ["-zxvf", (toTextIgnore tgz), "-C", (toTextIgnore tmpd)]
                 echo $ "rclone to " <> rp
                 -- run_ "rclone" ["copy", "-v", "--exclude", "*.json", (toTextIgnore $ tmpd </> "Takeout/"), rp]
                 run_ "rclone" ["copy", (toTextIgnore $ tmpd </> "Takeout/"), rp]

main :: IO ()
main = do
  args <- getArgs
  case args of
    [takeout, rclonep] -> do
      shelly $ silently $ do
        findWhen (\f -> return $ isInfixOf "takeout-" (T.unpack $ toTextIgnore f)) (fromText $ T.pack takeout) >>= return . sort >>= pushToRclone (T.pack rclonep)
    _ -> usage
  where
    usage = putStrLn "usage: takeout2rclone [takeout archive directory] [rclone path]"
