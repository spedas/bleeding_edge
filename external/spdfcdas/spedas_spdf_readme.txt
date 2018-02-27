*** 0. Description *** 

This directory contains three types of files:
- spdfcdas files (25 files)
- cdawlib files (9 files)
- files created by the SPEDAS team (4 files total)

Files in this directory are required by the SPEDAS spd_spdfCdawebChooser.pro.
Parts of the spdfCdawebChooser.pro file were used in spd_spdfCdawebChooser. 
File spdfCdawebChooser.pro was created by SPDF (and it should work when it is called directly).

In the following, we list the modifications we made to the original spdfcdas+cdawlib files. 


*** 1. spdfcdas file - 25 Files *** 

Release 1.7.10.37 of the CDAS Web Services IDL Library
<http://cdaweb.gsfc.nasa.gov/WebServices/REST/CdasIdlLibrary.html> 
that was deployed on January 23, 2018.

Local changes: 
Add the following to spdfcdawebchooser.pro: 
RESOLVE_ROUTINE, 'spd_cdawlib_virtual_funcs', /COMPILE_FULL_FILE
also, commended tvimage since there is already a SPEDAS function with this name


*** 2. spd_cdawlib file - 9 files (plus 3 files created by SPEDAS) *** 

Modified version of CDAWlib
release Jul 27, 2017
ftp://cdaweb.gsfc.nasa.gov/pub/software/cdawlib/source/


*** 3. CDWlib file modifications *** 

Modifications are the following:
a. Added the spd_cdawlib_ prefix in front of the file names and changed any caps to lowercase.
b. Changed the main function of each file to match the filename. 
c. Added an empty pro spd_cdawlib_virtual_funcs at the end of spd_cdawlib_virtual_funcs.pro and similarly to other files that do not contain a main function or pro.
b. Removed pro BREAK_MYSTRING from spd_cdawlib_read_mycdf.pro since there is already a separate file for this.

Add the following to spd_cdawlib_virtual_funcs.pro:
pro spd_cdawlib_virtual_funcs 
; do nothing
end


*** 4. Replace strings *** 

For all the above files (25+9) the following text was replaced
for all occurrences (when spd_cdawlib_ was not already present):

Before -> After
	
plotmaster    spd_cdawlib_plotmaster
read_mycdf    spd_cdawlib_read_mycdf
hsave_struct    spd_cdawlib_hsave_struct
list_mystruct    spd_cdawlib_list_mystruct
tagindex    spd_cdawlib_tagindex
break_mystring    spd_cdawlib_break_mystring
replace_bad_chars    spd_cdawlib_replace_bad_chars
virtual_funcs	spd_cdawlib_virtual_funcs
version    spd_cdawlib_version (with care, this is needed only in spdfcdawebchooser.pro, don't do a global replace)


*** 5. SPEDAS files *** 

Files created by SPEDAS:
spedas_spdf_readme.txt
spd_cdawlib_str_element.pro
spd_cdawlib.pro
spd_cdawlib_readme.txt

