To use the functions external/IDL_GEOPACK
you will need to install Haje Korth's
IDL wrapper for N.A. Tsyganenko's magnetic
fields model package.

To do this you must:
#1 Download the IDL geopack for your 
architecture from:
http://ampere.jhuapl.edu/code/idl_geopack.html
or from the themis site:
http://themis.ssl.berkeley.edu/software.shtml

#2 Unzip the package to any directory

#3 Copy the binary and the dlm file from the package
you just unzipped into your idl dlm directory. Note: This
may require assistance from your system administrator, if
your IDL installation is centrally managed.


The dlm file will be named:
idl_geopack.dlm
The binary will be named:
idl_geopack.{extension}
{extension} will vary from
OS to OS
on windows it will be called:
idl_geopack.dll
on linux and unix it will be called:
idl_geopack.so

Your idl dlm directory will vary depending
on where you installed IDL
but it can be found by typing:
print,!DLM_PATH
in an IDL terminal

It is preferable to install the DLM files under the IDL 
installation directory, but if that is not possible, there 
is a workaround.  On startup, IDL reads an environment 
variable called "IDL_DLM_PATH", and uses the directories 
specified there to locate DLM files, similar to how the 
IDL_PATH variable determines where to look for .pro files.
So if IDL_DLM_PATH is set to "/home/jwl/my_dlm_files:<IDL_DEFAULT>",
IDL will look for DLM files in /home/jwl/my_dlm_files first, 
then the IDL installation directories.  Windows users can use 
the control panel to edit the environment variables to add an
appropriate value for IDL_DLM_PATH.  Linux, MacOs, and Solaris users 
can put the appropriate "setenv" command in their startup files.


#4 after the files are copied just restart your idl
session and idl should automatically detect the geopack 
functions.

The boolean function igp_test()
in the external/IDL_GEOPACK tests to
be sure the package is in place.
Typing
print,igp_test()
will check that it is installed correctly

or you can type: 
geopack_help
in IDL to test as well.
