0.10.10.1 – June 2020

 * Fix off-by-one infinite loop in primMapByteStringBounded ([#203])
 * Don't perform unaligned writes when it isn't known to be safe ([#133])
 * Improve the performance of sconcat for lazy and strict bytestrings ([#142])
 * Document inadvertent 0.10.6.0 behaviour change in findSubstrings
 * Fix benchmark builds ([#52])
 * Documentation fixes
 * Test fixes

[#52]: https://github.com/haskell/bytestring/issues/52
[#133]: https://github.com/haskell/bytestring/pull/133
[#142]: https://github.com/haskell/bytestring/pull/142
[#203]: https://github.com/haskell/bytestring/issues/203

0.10.10.0 July 2019 <duncan+haskell@dcoutts.me.uk> July 2019

 * Build with GHC 8.8, and tests with QC 2.10+
 * Add conversions between ShortByteString and CString (#126)
 * Documentation fixes (#65, #118, #144, #150, #152, #172)
 * Resolve potential copyright issue with test data (#165)

0.10.8.2 Duncan Coutts <duncan@community.haskell.org> Feb 2017

 * Make readFile work for files with no size like /dev/null
 * Extend the cases in which concat and toStrict can avoid copying data
 * Fix building with ghc-7.0
 * Minor documentation improvements
 * Internal code cleanups

0.10.8.1 Duncan Coutts <duncan@community.haskell.org> May 2016

 * Fix Builder output on big-endian architectures
 * Fix building with ghc-7.6 and older

0.10.8.0 Duncan Coutts <duncan@community.haskell.org> May 2016

 * Use Rabin-Karp substring search for `breakSubstring` and `findSubstring`
 * Improve the performance of `partition` for lazy and strict bytestrings
 * Added `stripPrefix` and `stripSuffix` for lazy and strict bytestrings
 * Fix building with ghc 8.0 & base 4.9 (Semigroup etc)

0.10.6.0 Duncan Coutts <duncan@community.haskell.org> Mar 2015

 * Rename inlinePerformIO so people don't misuse it
 * Fix a corner case in unfoldrN
 * Export isSuffixOf from D.B.Lazy.Char8
 * Add D.B.Lazy.elemIndexEnd
 * Fix readFile for files with incorrectly reported file size
 * Fix for builder performance with ghc 7.10
 * Fix building with ghc 6.12

0.10.4.1 Duncan Coutts <duncan@community.haskell.org> Nov 2014

 * Fix integer overflow in concatenation functions
 * Fix strictness of lazy bytestring foldl'
 * Numerous minor documentation fixes
 * Various testsuite improvements
