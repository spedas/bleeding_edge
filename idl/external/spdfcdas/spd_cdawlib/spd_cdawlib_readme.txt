Files in this directory were adapted (forked) from NASA's CDAWlib.
They are needed by spdfCdawebChooser (created by SPDF) and spd_ui_spdfcdawebchooser (SPEDAS).
The reason that these files were modified is that the scripts that create the SPEDAS executables 
need to be able to directly compile and include these files and this wasn't possible with the original CDAWlib files. 
File spd_cdawlib.pro was created by SPEDAS in order to easily compile these files. 

The original CDAWlib can be obtained from http://spdf.gsfc.nasa.gov/CDAWlib.html.

Files (9) copied from CDAWlib:
plotmaster    spd_cdawlib_plotmaster (*)
read_mycdf    spd_cdawlib_read_mycdf (*)
hsave_struct    spd_cdawlib_hsave_struct
list_mystruct    spd_cdawlib_list_mystruct
tagindex    spd_cdawlib_tagindex
break_mystring    spd_cdawlib_break_mystring
replace_bad_chars    spd_cdawlib_replace_bad_chars
virtual_funcs	spd_cdawlib_virtual_funcs (*)
version    spd_cdawlib_version (*) 

Files (3) created by SPEDAS:
spd_cdawlib_str_element.pro
spd_cdawlib.pro
spd_cdawlib_readme.txt

(*) Files that were updated in September, 2017.

