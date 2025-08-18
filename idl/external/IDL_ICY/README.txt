To use the functions external/IDL_ICY
you will need to install NAIF/JPL's
IDL wrapper for SPICE.

To do this you must:
#1 Download the icy.zip or icy.tar.Z file for your 
architecture from:
http://naif.jpl.nasa.gov/naif/toolkit_IDL.html

#2 Uncompress the package to any directory

#3 Copy the binary and the dlm file from the package
you just unzipped into your idl dlm directory. These
will be found the lib directory.


The dlm file will be named:
icy.dlm
The binary will be named:
icy.{extension}
{extension} will vary from
OS to OS
on windows it will be called:
icy.dll
on linux, unix and MacOS it will be called:
icy.so

Your idl dlm directory will vary depending
on where you installed IDL
but it can be found by typing:
print,!DLM_PATH
in an IDL terminal

#4 after the files are copied just restart your idl
session and idl should automatically detect the icy 
functions.

The boolean function icy_test()
in the external/IDL_ICY tests to
be sure the package is in place.
Typing
print,icy_test()
will check that it is installed correctly.
