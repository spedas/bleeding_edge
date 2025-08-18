;
; This crib demonstrates basic work with tplot2cdf
; 
; $LastChangedBy: adrozdov $
; $LastChangedDate: 2023-04-17 13:40:06 -0700 (Mon, 17 Apr 2023) $
; $LastChangedRevision: 31759 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/examples/crib_tplot2cdf_basic.pro $

; clear variables
del_data,'*'

; Let's create a simple data set and save it in tplot variable
store_data,'array_variable',data={x:time_double('2001-01-01')+dindgen(120),y:dindgen(120)^2}

; To save cdf file tplot variable must have a CDF structure. 
; Keyword /default creates this structure automatically, but most of the fields are undefined.
print, "Saving tplot variable array_variable into example_array_variable.cdf file"  
tplot2cdf, filename='example_array_variable', tvars='array_variable', /default
print, "example_array_variable.cdf file is created"  
; Now you can use program like autoplot to read example_array_variable.cdf
stop

; Create fresh tplot variable
del_data,'*'
store_data,'array_variable',data={x:time_double('2001-01-01')+dindgen(120),y:dindgen(120)^2}

; CDF structure in tplot variable can be created manually using tplot_add_cdf_structure procedure
tplot_add_cdf_structure, 'array_variable'

; Now, let's extract tplot options (limits)
get_data, 'array_variable', limits=s
print, "Options of tplot variable array_variable include CDF structure:"
help, s, /struct

; tplot variable should have the following fields of CDF structure:
; CDF.VARS - field that describe the data (tplot y variable)
; CDF.DEPEND_0 - this field correspond to the time (tplot x variable);
; CDF.DEPEND_1 - supporting data (tplot v variable, it is not included into this tplot variable)
print, "CDF structure has several fields, that correspond to x, y (and v if defined):"
help, s.CDF, /struct

; To define the CDF attributes retrieve the structure that is stored in "attrptr" pointer
; DEPEND_0 correspond to x
cdf_x_attr_struct = *s.CDF.DEPEND_0.attrptr
; Following attributes can be defined:
; CATDESC, DISPLAY_TYPE ,FIELDNAM, LABLAXIS, UNITS (already defined for the time variable), VAR_TYPE
; FILLVAL, VALIDMIN, VALIDMAX, FORMAT are already defined based on the nature of the data (x variable)
print, "CDF structure has default (undefined) attributes of the x data:"
help, cdf_x_attr_struct, /structure

cdf_x_attr_struct.CATDESC = 'Time of the vector'
cdf_x_attr_struct.LABLAXIS = 'Time'
; Save the attributes of variable `x` in the CDF structure 
s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)

; VARS correspond to y
cdf_y_attr_struct = *s.CDF.VARS.attrptr
cdf_y_attr_struct.CATDESC = 'Array'
cdf_y_attr_struct.LABLAXIS = 'Array Value'
cdf_y_attr_struct.UNITS = 'arb. unit.'

; To add optional variable attribute, add new corresponding field to the structure using `str_element` procedure
; For example, adding coordinate system
str_element,cdf_y_attr_struct,'COORDINATE_SYSTEM','arb. coord. system.',/add

; Save the attributes of variable `y` in the CDF structure (assign the pointer)
s.CDF.VARS.attrptr = ptr_new(cdf_y_attr_struct)

; Save CDF structure into tplot variable
options,'array_variable','CDF', s.CDF

; Save cdf file
; Note, that /default keyword is now omitted
print, "Saving tplot variable array_variable with attributes into example_array_variable_w_attibutes.cdf file"  
tplot2cdf, filename='example_array_variable_w_attibutes', tvars='array_variable'
stop

; Modify tplot variable adding 2d y variable 
store_data,'array_variable',data={x:time_double('2001-01-01')+dindgen(120),y:dindgen(120,3)^2}  

; Because we y is 2d array, but supporting variable v is not defined, tplot_add_cdf_structure will automatically add it (as the index on the each column)
tplot_add_cdf_structure, 'array_variable'
get_data, 'array_variable', data=d, limits=s
print, "Tplot variable array_variable has v variable that was automatically created by tplot_add_cdf_structure procedure"
help, d, /struct

; Note, previously saved attributes are preserved
print, "Some previously defined attributes are not overwritten by tplot_add_cdf_structure"
help, *s.CDF.VARS.attrptr, /struct

; DEPEND_1 correspond to v
cdf_v_attr_struct = *s.CDF.DEPEND_1.attrptr
cdf_v_attr_struct.CATDESC = 'Array index'
cdf_v_attr_struct.LABLAXIS = 'Index'
cdf_v_attr_struct.UNITS = '#'
; add additional attributes, that were not automatically included in CDF attributes structure
str_element,cdf_v_attr_struct,'VAR_NOTES','Index of the array was automatically created by tplot_add_cdf_structure function',/add
s.CDF.DEPEND_1.attrptr = ptr_new(cdf_v_attr_struct)

; Save CDF structure into tplot variable
options,'array_variable','CDF', s.CDF

print, "Saving tplot variable array_variable with attributes and supporting variable v into example_array_variable_w_v.cdf file"  
tplot2cdf, filename='example_array_variable_w_v', tvars='array_variable'
stop

; Let's create additional data set, an example of a simple wave
time_sec_arr = indgen(600) / 10.0d
time_arr = time_double('2001-01-01') + time_sec_arr

omega = 1./10. * 2. * !pi ; 100 mHz
amp   = 1.

var = amp * sin(omega * time_sec_arr)

; Create a tplot variable 
store_data, 'mHz_sin_wave', data={x:time_arr,y:var}
; Add CDF structure
tplot_add_cdf_structure, 'mHz_sin_wave'

; Multiple tplot variables can be saved in cdf file
print, "Saving multiple tplot variables (array_variable and mHz_sin_wave) into example_array_variable_w_sin_wave.cdf file"  
tplot2cdf, filename='example_array_variable_w_sin_wave', tvars=['mHz_sin_wave', 'array_variable']
; Note, because 'mHz_sin_wave' and 'array_variable' have different time, Epoch and Epoch_1 will be created in the CDF file
stop

; Let's create a second wave using the same time series
var = amp * cos(omega * time_sec_arr)
store_data, 'mHz_cos_wave', data={x:time_arr,y:var}

; Add CDF structure
tplot_add_cdf_structure, 'mHz_cos_wave'

; Let's define the some attribute of the time variable.
get_data, 'mHz_cos_wave', limits=s
cdf_x_attr_struct = *s.CDF.DEPEND_0.attrptr

; Define the attribute and save it in tplot variable 
cdf_x_attr_struct.CATDESC = 'Time of the waves'
s.CDF.DEPEND_0.attrptr = ptr_new(cdf_x_attr_struct)
options,'mHz_cos_wave','CDF', s.CDF

; Since 'mHz_sin_wave' and 'mHz_cos_wave' are calculated using the same time variable, tplot2cdf will determine that and will save only one Epoch
; Since 'mHz_cos_wave' goes first in the list of tvars, the defined attributes of the Epoch will be taken from CDF structure of 'mHz_cos_wave'  
print, "Saving multiple tplot variables (mHz_sin_wave and mHz_sin_wave) that share the same time into example_cos_and_sin_wave.cdf file"
tplot2cdf, filename='example_cos_and_sin_wave', tvars=['mHz_cos_wave', 'mHz_sin_wave']

; Now let's add some general properties of the cdf file using /g_attributes keyword
general_structure = {PI_affiliation:'UCLA',Acknowledgment:'SPEDAS development team'}
print, "Saving multiple tplot variables and some general attributes of CDF file into example_cos_and_sin_wave_general.cdf file"
tplot2cdf, filename='example_cos_and_sin_wave_general', tvars=['mHz_cos_wave', 'mHz_sin_wave'], g_attributes=general_structure
stop

; Finally, let save compressed cdf file using 'compress' (compress_cdf) parameter 
; compress_cdf parameter correspond to SET_COMPRESSION parameter of CDF_COMPRESSION
; In this case GZIP compression is used
print, "Saving multiple tplot variables into gzip compressed example_cos_and_sin_wave_compressed.cdf file"
tplot2cdf, filename='example_cos_and_sin_wave_compressed', tvars=['mHz_cos_wave', 'mHz_sin_wave'], g_attributes=general_structure, compress=5

print, "End of the crib"
end