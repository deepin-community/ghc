#!/bin/sh
set -ex

deploy() {
    git config --global user.email "builds@travis-ci.org"
    git config --global user.name "Travis CI User"
    git clone https://github.com/haskell/cabal-website.git cabal-website
    (cd cabal-website && git checkout --track -b gh-pages origin/gh-pages)
    rm -rf cabal-website/doc
    mkdir -p cabal-website/doc/html
    mv dist-newstyle/build/`uname -m`-$TRAVIS_OS_NAME/ghc-$GHCVER/Cabal-3.0.1.0/doc/html/Cabal \
       cabal-website/doc/html/Cabal
    (cd cabal-website && git add --all .)
    (cd cabal-website && \
            git commit --amend --reset-author -m "Deploy to GitHub ($(date)).")
    (cd cabal-website && \
            git push --force git@github.com:haskell/cabal-website.git \
                gh-pages:gh-pages)
}

if [ "x$TRAVIS_REPO_SLUG" = "xhaskell/cabal" \
                          -a "x$TRAVIS_PULL_REQUEST" = "xfalse" \
                          -a "x$TRAVIS_BRANCH" = "xmaster" \
                          -a "x$DEPLOY_DOCS" = "xYES" ]
then
    deploy
fi
