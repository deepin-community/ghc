#!/bin/sh

# ATTENTION! Before editing this file, maybe you can make a
# separate script to do your test?  We don't want individual
# Travis builds to take too long (they time out at 50min and
# it's generally unpleasant if the build takes that long.)
# If you make a separate matrix entry in .travis.yml it can
# be run in parallel.

# NB: the '|| exit $?' workaround is required on old broken versions of bash
# that ship with OS X. See https://github.com/haskell/cabal/pull/3624 and
# http://stackoverflow.com/questions/14970663/why-doesnt-bash-flag-e-exit-when-a-subshell-fails

. ./travis-common.sh

# --hide-successes uses terminal control characters which mess up
# Travis's log viewer.  So just print them all!
TEST_OPTIONS=""

# To be enabled temporarily when you need to pre-populate the Travis
# cache to avoid timeout.
#SKIP_TESTS=YES

# ---------------------------------------------------------------------
# Parse options
# ---------------------------------------------------------------------

usage() {
    echo -e -n "Usage: `basename $0`\n-j  jobs\n"
}

jobs="-j1"
while getopts ":hj:" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        j)
            jobs="-j$OPTARG"
            ;;
        :)
            # Argument-less -j
            if [ "$OPTARG" = "j" ]; then
                jobs="-j"
            fi
            ;;
        \?)
            echo "Invalid option: $OPTARG"
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Do not try to use -j with GHC older than 7.8
case $GHCVER in
    7.4*|7.6*)
        jobs=""
        ;;
    *)
        ;;
esac

# ---------------------------------------------------------------------
# Update the Cabal index
# ---------------------------------------------------------------------

timed cabal update

# ---------------------------------------------------------------------
# Install executables if necessary
# ---------------------------------------------------------------------

# TODO: we need v2-install -z
(cd /tmp && timed cabal v2-install $jobs happy --overwrite-policy=always)

# ---------------------------------------------------------------------
# Setup our local project
# ---------------------------------------------------------------------

make cabal-install-monolithic
if [ "x$CABAL_LIB_ONLY" = "xYES" ]; then
    cp cabal.project.libonly cabal.project
fi
cp cabal.project.local.travis cabal.project.local

# ---------------------------------------------------------------------
# Cabal
# ---------------------------------------------------------------------

# Needed to work around some bugs in nix-local-build code.
export CABAL_BUILDDIR="${CABAL_BDIR}"

if [ "x$CABAL_INSTALL_ONLY" != "xYES" ] ; then
    # We're doing a full build and test of Cabal

    # NB: Best to do everything for a single package together as it's
    # more efficient (since new-build will uselessly try to rebuild
    # Cabal otherwise).
    timed cabal new-build $jobs Cabal Cabal:unit-tests Cabal:check-tests Cabal:parser-tests Cabal:hackage-tests --enable-tests

    # Run haddock.
    if [ "$TRAVIS_OS_NAME" = "linux" ]; then
        # TODO: use new-haddock?
        (cd Cabal && timed cabal act-as-setup --build-type=Simple -- haddock --builddir=${CABAL_BDIR}) || exit $?
    fi

    # Check for package warnings
    (cd Cabal && timed cabal check) || exit $?
fi

unset CABAL_BUILDDIR

# Build and run the package tests

export CABAL_BUILDDIR="${CABAL_TESTSUITE_BDIR}"

# NB: We always build this test runner, because it is used
# both by Cabal and cabal-install
timed cabal new-build $jobs cabal-testsuite:cabal-tests

if [ "x$SKIP_TESTS" != "xYES" ]; then
   (cd cabal-testsuite && timed ${CABAL_TESTSUITE_BDIR}/build/cabal-tests/cabal-tests --builddir=${CABAL_TESTSUITE_BDIR} -j3 $TEST_OPTIONS) || exit $?
fi

# Redo the package tests with different versions of GHC
if [ "x$TEST_OTHER_VERSIONS" = "xYES" ]; then
    (cd cabal-testsuite && timed ${CABAL_TESTSUITE_BDIR}/build/cabal-tests/cabal-tests --builddir=${CABAL_TESTSUITE_BDIR} $TEST_OPTIONS --with-ghc="/opt/ghc/7.0.4/bin/ghc")
    (cd cabal-testsuite && timed ${CABAL_TESTSUITE_BDIR}/build/cabal-tests/cabal-tests --builddir=${CABAL_TESTSUITE_BDIR} $TEST_OPTIONS --with-ghc="/opt/ghc/7.2.2/bin/ghc")
    (cd cabal-testsuite && timed ${CABAL_TESTSUITE_BDIR}/build/cabal-tests/cabal-tests --builddir=${CABAL_TESTSUITE_BDIR} $TEST_OPTIONS --with-ghc="/opt/ghc/head/bin/ghc")
fi

unset CABAL_BUILDDIR

if [ "x$CABAL_LIB_ONLY" = "xYES" ]; then
    # If this fails, we WANT to fail, because the tests will not be running then
    (timed ./travis/upload.sh) || exit $?
    exit 0;
fi

# ---------------------------------------------------------------------
# cabal-install
# ---------------------------------------------------------------------

# Needed to work around some bugs in nix-local-build code.
export CABAL_BUILDDIR="${CABAL_INSTALL_BDIR}"

if [ "x$DEBUG_EXPENSIVE_ASSERTIONS" = "xYES" ]; then
    CABAL_INSTALL_FLAGS=-fdebug-expensive-assertions
fi

# NB: For Travis, we do a *monolithic* build, which means all the
# test suites are baked into the cabal binary
timed cabal new-build $jobs $CABAL_INSTALL_FLAGS cabal-install:cabal

# TODO: we need v2-install -z
(cd /tmp && timed cabal new-install $jobs hackage-repo-tool --overwrite-policy=always)

if [ "x$SKIP_TESTS" = "xYES" ]; then
   exit 1;
fi

# Tests need this
timed ${CABAL_INSTALL_EXE} update

# Big tests
(cd cabal-testsuite && timed ${CABAL_TESTSUITE_BDIR}/build/cabal-tests/cabal-tests --builddir=${CABAL_TESTSUITE_BDIR} -j3 --skip-setup-tests --with-cabal ${CABAL_INSTALL_EXE} --with-hackage-repo-tool hackage-repo-tool $TEST_OPTIONS) || exit $?

# Cabal check
# TODO: remove -main-is and re-enable me.
# (cd cabal-install && timed cabal check) || exit $?

if [ "x$TEST_SOLVER_BENCHMARKS" = "xYES" ]; then
    timed cabal new-build $jobs solver-benchmarks:hackage-benchmark solver-benchmarks:unit-tests
    timed ${SOLVER_BENCHMARKS_BDIR}/t/unit-tests/build/unit-tests/unit-tests $TEST_OPTIONS
fi

# Haddock
# TODO: >= 8.4.3 would be nicer
if [ "$TRAVIS_OS_NAME" = "linux" -a "$GHCVER" == "8.4.4" ]; then
    timed cabal new-haddock cabal-install
fi

unset CABAL_BUILDDIR

# Check what we got
${CABAL_INSTALL_EXE} --version

# If this fails, we WANT to fail, because the tests will not be running then
(timed ./travis/upload.sh) || exit $?
