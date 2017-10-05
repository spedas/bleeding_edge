;+
; Function:    
;         netcdf_load_vars
;         
; Purpose:
;         Returns a structure with the data from netCDF files
;         
; Input:
;         ncfile: netCDF file(s) to load
;        
; Output:
;         An IDL structure with variables and (variable, global) attributes
;         loaded from the netCDF file
;         
; 
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-05-22 12:04:59 -0700 (Fri, 22 May 2015) $
; $LastChangedRevision: 17674 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/netCDF/netcdf_load_vars.pro $
;-

function netcdf_load_vars, ncfile
  for fileindex = 0, n_elements(ncfile)-1 do begin
    if file_test(ncfile[fileindex]) eq 0 then begin
        dprint, 'Invalid netCDF file found in netCDF_load_vars -- file not found: ' + ncfile[fileindex]
        if fileindex eq n_elements(ncfile)-1 then return, -1 else continue
    endif
    file = ncdf_open(ncfile[fileindex])
    inquire = ncdf_inquire(file)
    ; the number of dimensions defined in the netCDF file
    ndims = inquire.ndims
    ; the number of variables defined in the netCDF file
    nvars = inquire.nvars
    ; the number of global attributes defined in the netCDF file
    ngatts = inquire.ngatts
    ; the ID of the unlimited dimension, if there is one. this is likely to be 
    ; the dimension where the temporal data is stored
    id_unlimited_dim = inquire.recdim
    ; check that the data dimension is greater than zero
    dimensionid = ncdf_dimid(file, 'record')
    ncdf_diminq, file, dimensionid, name, size
    if size eq 0 then continue
    
    if size(netCDFi, /type) ne 8 then begin ; check that 'netCDFi' structure doesn't already exist
        ; structure to be returned with data from netCDF file
        netCDFi = { filename: ncfile[fileindex] }
    
        ; loop through and store the global attributes
        for j = 0, ngatts-1 do begin
            ; inquire about this global attribute
            attrName = ncdf_attname(file, j, /global)
            attrInq = ncdf_attinq(file, attrName, /global)
            ncdf_attget, file, attrName, val, /global
            ; val is returned in bytes, need to convert to a string
            if size(val, /type) eq 1 then valString = string(byte(val)) else valString = val
            if j eq 0 then begin
                ; create global attribute structure
                gattr = create_struct(attrName, valString)
            endif else begin
                ; add to the global attribute structure
                str_element, gattr, attrName, valString, /add_rep
            endelse
        endfor
        ; store global attributes in the netCDFi structure
        str_element, netCDFi, 'g_attributes', gattr, /add_rep
        
        ; store number of variables in the netCDFi structure
        str_element, netCDFi, 'nv', nvars, /add_rep

        ; loop through and store the variables
        for i = 0, nvars-1 do begin
            ; inquire about a variable
            varinq = ncdf_varinq(file, i)
    
            data = {name: varinq.name, datatype: varinq.datatype, ndims: varinq.ndims, natts: varinq.natts, dimids: varinq.dim}
            ; loop through the variable attributes
            undefine, var_str ;This needs to be reinitialized for each variable so that attributes are not retained, 2015-05-22, jmm
            for k = 0, varinq.natts-1 do begin
                var_attr_name = ncdf_attname(file, i, k)
                var_attr_inq = ncdf_attinq(file, i, var_attr_name)
                ncdf_attget, file, i, var_attr_name, attrval
                str_element, var_str, var_attr_name, string(byte(attrval)), /add_rep
            endfor
            ; get the data for this variable
            varsid = ncdf_varid(file,varinq.name) 
            ncdf_varget, file, varsid, value
            str_element, var_str, 'dataptr', ptr_new(value), /add_rep
            newdata = create_struct(data, var_str)
            if i eq 0 then begin
                vars = create_struct(newdata.name, newdata)
            endif else begin
                str_element, vars, newdata.name, newdata, /add_rep
            endelse
            str_element, netCDFi, 'vars', vars, /add_rep
        endfor
    endif else begin ; 'netCDFi' structure exists, add data from the next file to the current structure
        for i = 0, nvars-1 do begin
            varinq = ncdf_varinq(file, i)
            if tag_exist(netCDFi.vars, varinq.name) then begin
                olddata = *netCDFi.vars.(i).dataptr
                
                varsid = ncdf_varid(file,varinq.name) 
                ncdf_varget, file, varsid, value
                newdata = array_concat(value, olddata)
                ptr_free, netCDFi.vars.(i).dataptr
                netCDFi.vars.(i).dataptr = ptr_new(newdata)
                ;stop
            endif 
        endfor
        ;stop
    endelse
    ; close the netCDF file
    ncdf_close, file
  endfor
  return, netCDFi
end
