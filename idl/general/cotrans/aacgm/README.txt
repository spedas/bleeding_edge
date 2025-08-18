                           AACGM (IDL Version)
                           ===================

                               R.J.Barnes


This version of the AACGM library is pure IDL implementation that should be
platform independent for most users. Heavy users of AACGM might like to 
consider using either the C or Fortran versions of the Library which will
give considerably better performance.

Installation
------------

Once the archive is unpacked, a directory called aacgm will be created. This 
contains the IDL program files and a further sub-directory called "coef", which
contains the ASCII coefficient files for the library. 
The three IDL program files are:

aacgmidl.pro   - The actual AACGM library
cnvtime.pro    - Two sub-routines to convert time representations.
default.pro    - The default co-efficients used by the library (Year 2000).

Running the code
----------------

Start IDL and pre-compile the library:

.run aacgmidl.pro
.run cnvtime.pro

The AACGM library provides two key routines; CNV_AACGM, to convert to and from AACGM co-ordinates, and CALC_MLT for calculating magnetic local time.

Calling CNV_AACGM requires an input latitude,longitude and height. The 
proedure returns an output latitude,longitude,radius and a possible error flag:

inlat=80.0
inlon=120.0
height=150.0
cnv_aacgm, inlat, inlon, height, outlat,outlon,r,error
print, outlat,outlon,r,error

To convert back from geomagnetic to geographic co-ordinates use the geo 
keyword:

cnv_aacgm, inlat, inlon, height, outlat,outlon,r,error,/geo

If you need to change the coefficients for a different year, use the
LOAD_COEF routine:

load_coef,"aacgm_coeffs1990.asc"

The CALC_MLT function requires an input time and longitude and returns
the decimal magnetic local time. The input time is specified in terms
of the year and the seconds past the start of the year. The CNVTIME function
contained in "cnvtime.pro", simplifies this conversion:

mlon=175.0
yrsec=cnvtime(2000,08,30,10,30,0)
mlt=calc_mlt(2000,yrsec,mlon)
print, 2000,yrsec,mlt,175.0

Note: cosd and sind were commented out in this copy of aacgm to avoid duplicate routines (lphilpott 25-june-2012)







