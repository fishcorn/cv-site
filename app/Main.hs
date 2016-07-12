{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Data.Monoid (mappend)
import Hakyll

main :: IO ()
main =
  hakyll $ do
    match "images/*" $ do
      route idRoute
      compile copyFileCompiler

    match "css/*" $ do
      route idRoute
      compile compressCssCompiler

    match (fromList ["about.md", "contact.md"]) $ do
      route (setExtension "html")
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

    match "pubs/*" $ do
      route (setExtension "html")
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/pub.html" pubContext
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/default.html" pubContext
        >>= relativizeUrls

    match "posts/*" $ do
      route (setExtension "html")
      compile $ pandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postContext
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/default.html" postContext
        >>= relativizeUrls
        
    create ["publications.html"] $ do
      route idRoute
      compile $ do
        pubs <- recentFirst =<< loadAllSnapshots "pubs/*" "content"
        let archiveContext =
              listField "pubs" pubContext (return pubs) `mappend`
              constField "title" "Publications" `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/pub-list.html" archiveContext
          >>= loadAndApplyTemplate "templates/default.html" archiveContext
          >>= relativizeUrls

    create ["posts.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        let archiveContext =
              listField "posts" postContext (return posts) `mappend`
              constField "title" "Posts" `mappend`
              defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/post-list.html" archiveContext
          >>= loadAndApplyTemplate "templates/default.html" archiveContext
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        pubs <- recentFirst =<< loadAll "pubs/*"
        posts <- recentFirst =<< loadAll "posts/*"
        let indexContext =
              listField "pubs" pubContext (return pubs) `mappend`
              listField "posts" postContext (return posts) `mappend`
              constField "title" "Home" `mappend`
              defaultContext

        getResourceBody
          >>= applyAsTemplate indexContext
          >>= loadAndApplyTemplate "templates/default.html" indexContext
          >>= relativizeUrls

    match "templates/*" (compile templateCompiler)

    create ["atom.xml"] $ do
      route idRoute
      compile $ do
        posts <- fmap (take 10) . recentFirst
                   =<< loadAllSnapshots ("posts/*" .||. "pubs/*") "content"
        renderAtom feedConfiguration feedContext posts

    create ["rss.xml"] $ do
      route idRoute
      compile $ do
        posts <- fmap (take 10) . recentFirst
                   =<< loadAllSnapshots ("posts/*" .||. "pubs/*") "content"
        renderRss feedConfiguration feedContext posts

feedContext :: Context String
feedContext =
  postContext `mappend` bodyField "description"

pubContext :: Context String
pubContext =
  dateField "date" "%Y-%m" `mappend` defaultContext

postContext :: Context String
postContext =
  dateField "date" "%Y-%m-%d" `mappend` defaultContext

feedConfiguration :: FeedConfiguration
feedConfiguration =
  FeedConfiguration
    { feedTitle = "John Moeller"
    , feedDescription = "John Moeller (Updates)"
    , feedAuthorName = "John Moeller"
    , feedAuthorEmail = "spam@fishcorn.info"
    , feedRoot = ""
    }
