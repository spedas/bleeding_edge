#!/bin/csh
# runs the mgunit-based unit tests for the sdc tools
# run this script from the test_tools directory

if (! -e run_idl_tests.pro) then
  echo 'Run from sdc/test_tools directory where run_idl_tests.pro is found'
  exit 1
endif

# /code/tim_luna/mgunit/src:+/code/tim_luna/mglib/src:
setenv IDL_PATH '<IDL_DEFAULT>:+..'

# run the tests
idl <<EOF
  run_idl_tests, VERBOSE=1
  exit
EOF

# clean up test downloads
rm -f *.cdf *.V?? sitl_*.sav

