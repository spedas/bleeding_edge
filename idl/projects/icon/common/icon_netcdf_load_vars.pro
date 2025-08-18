;+
;NAME:
;   icon_netcdf_load_vars
;
;PURPOSE:
;   Returns a structure with the data from netCDF files
;
;KEYWORDS:
;   ncfile: netCDF file(s) to load
;
;OUTPUT:
;   An IDL structure with variables and (variable, global) attributes
;       loaded from the netCDF file
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2019-02-20 14:03:40 -0800 (Wed, 20 Feb 2019) $
;$LastChangedRevision: 26661 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/common/icon_netcdf_load_vars.pro $
;
;-------------------------------------------------------------------

function icon_netcdf_load_vars, ncfile

  for fileindex = 0, n_elements(ncfile)-1 do begin

    ; handle possible loading errors
    catch, errstats
    if errstats ne 0 then begin
      dprint, dlevel=1, 'Error in icon_netcdf_load_vars: ', !ERROR_STATE.MSG
      catch, /cancel
      continue
    endif

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
    ;;;dimensionid = ncdf_dimid(file, 'record')
    dimensionid = ncdf_dimid(file, 'EPOCH')
    if(dimensionid eq -1) then dimensionid = ncdf_dimid(file,'Epoch')
    if(dimensionid eq -1) then dimensionid = ncdf_dimid(file,'epoch')

    if(dimensionid eq 0) then dimensionid = 1

    dims = {dimid:0,name:'',size:0l}
    ;    gdims = replicate(dims,ndims)

    ;ncdf_diminq, file, dimensionid, name, size
    ;    if size eq 0 then continue

    if size(netCDFi, /type) ne 8 then begin ; check that 'netCDFi' structure doesn't already exist
      ; structure to be returned with data from netCDF file
      netCDFi = { filename: ncfile[fileindex] }
      unqi_size = []
      replace_size = []
      replace_with = []
      ll = -1
      for d = 0,ndims-1 do begin
        ncdf_diminq,file,d,name,size
        uniq_size_test = where(unqi_size eq size,/null)
        if(uniq_size_test eq !NULL ) then begin
          unqi_size = [unqi_size,size]
          dims.dimid = d
          dims.name = name
          dims.size = size
          str_element,gdims,name,dims,/add_rep
          ll += 1
        endif
        replace_size = [replace_size,d]
        if(uniq_size_test eq !NULL) then replace_with = [replace_with,ll] else replace_with = [replace_with,uniq_size_test]

      endfor
      replaced = [[replace_size],[replace_with]]
      ;            stop
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

      str_element,netCDFi, 'dims',gdims,/add_rep

      ; loop through and store the variables
      for i = 0, nvars-1 do begin
        ; inquire about a variable
        varinq = ncdf_varinq(file, i)
        ;        if(varinq.name eq 'ICON_L0_MIGHTI_A_Image_ROI_Pixels') then stop
        var_str = {}
        ;;;    IF(varinq.name eq 'ROWS' || varinq.name eq 'EPOCH') then stop
        
        ; Fix mighti spectrograms
        myndims = varinq.ndims
        display_type = NCDF_ATTINQ( file, i , 'Display_Type')
        if display_type.datatype ne 'UNKNOWN' then begin
          NCDF_ATTget, file, i , 'Display_Type', myatt
          if myatt eq 'spectrogram' then begin
            myndims = 2
          endif
        endif           
        
        data = {name: varinq.name, datatype: varinq.datatype, ndims: myndims, natts: varinq.natts}
        ; loop through the variable attributes
        for k = 0, varinq.natts-1 do begin

          var_attr_name = ncdf_attname(file, i, k)

          var_attr_inq = ncdf_attinq(file, i, var_attr_name)
          ncdf_attget, file, i, var_attr_name, attrval
          ;;;str_element, var_str, var_attr_name, string(byte(attrval)), /add_rep
          str_element, var_str, var_attr_name, attrval, /add_rep

        endfor

        ; get the data for this variable
        varsid = ncdf_varid(file,varinq.name)
        ncdf_varget, file, varsid, value
        str_element, var_str, 'dataptr', ptr_new(value), /add_rep
        newdata = create_struct(data, var_str)
        ;                stop
        icon_check_att,newdata,gdims,varinq.dim,replaced
        ;        icon_dimension_fix_var,newdata,gdims,varinq.dim,replaced,n_elements(ncfile)
        if i eq 0 then begin
          vars = create_struct(newdata.name, newdata)
        endif else begin
          str_element, vars, newdata.name, newdata, /add_rep
        endelse

        str_element, netCDFi, 'vars', vars, /add_rep
        flg_dim_miss = 0
        If(i eq nvars-1) then begin
          for nv=0,n_tags(gdims)-1 do begin
            ;            stop
            ; dim_exist = tag_exist(vars,gdims.(nv).name)
            ; SOME FILES HAVE VARIAVLES THAT HAVE - IN THEM.  THESE BREAK THE CODE.  THE LIKE BELOW
            ; GETS RID OF BOTH _ AND - AND COMPARES THE REMAINING STRING TO SEE IF THE DIMENSION HAS
            ; BEEN DEFINED AS A VARIALBE.

            dim_exist = where(strsplit(tag_names(vars),'_-',/extract) eq strupcase(strsplit(gdims.(nv).name,'_-',/extract)),/NULL)

            if(dim_exist eq !NULL) then begin
              flg_dim_miss += 1
              print,'adding missing dimension variables'
              ;              stop
              dim_add = {name:gdims.(nv).name,dataptr:ptr_new(dindgen(gdims.(nv).size))}
              str_element,vars,gdims.(nv).name,dim_add,/add_rep
              str_element,netcdfi,'vars',vars,/add_rep
            endif
          endfor
          if(flg_dim_miss ne 0 ) then netcdfi.nv = nvars + flg_dim_miss
        endif
      endfor

    endif else begin ; 'netCDFi' structure exists, add data from the next file to the current structure
      newsize = -1
      for i = 0, nvars-1 do begin
        varinq = ncdf_varinq(file, i)

        ; handle possible loading errors
        catch, errvar
        if errvar ne 0 then begin
          dprint, dlevel=1, 'Error in icon_netcdf_load_vars: ', !ERROR_STATE.MSG, varinq.name
          catch, /cancel
          continue
        endif

        ;;;MIGHTI HAS "-" IN THE NAME OF VARIALBLES WHICH MESSES UP IDL AND THE TAG_EXIST DOESN'T WORK
        ;;;THIS IS COMMENTED OUT TO WORK AROUND THIS ISSUE BUT NEED TO BE FIXED
        ;;;  if tag_exist(netCDFi.vars, varinq.name) then begin
        olddata = *netCDFi.vars.(i).dataptr
        varsid = ncdf_varid(file,varinq.name)
        ncdf_varget, file, varsid, value

        ; Concatenate arrays
        d_old = size(olddata, /N_DIMENSIONS)
        d_new = size(value, /N_DIMENSIONS)
        
        ; Fix mighti spectrograms
        display_type = NCDF_ATTINQ( file, i , 'Display_Type')
        if display_type.datatype ne 'UNKNOWN' then begin
          NCDF_ATTget, file, i , 'Display_Type', myatt
          if myatt eq 'spectrogram' then begin
            d_new = 2
          endif
        endif
        
        if (d_old eq d_new) or (abs(d_old - d_new) eq 1) then begin
          newdata = []
          if varinq.ndims eq 1 then begin
            newdata = [olddata, value]
            newsize = n_elements(newdata)
          endif else if varinq.ndims eq 2 then begin
            d2_old = size(olddata, /DIMENSIONS)
            d2_new = size(value, /DIMENSIONS)
            if d2_old[0] eq d2_new[0] then begin
              newdata = [[olddata], [value]]
              d2_c = size(newdata, /DIMENSIONS)
              newsize = d2_c[1]
            endif
          endif else if varinq.ndims eq 3 then begin
            d3_old = size(olddata, /DIMENSIONS)
            d3_new = size(value, /DIMENSIONS)
            if (d3_old[0] eq d3_new[0]) and (d3_old[1] eq d3_new[1]) then begin
              newdata = [[[olddata]], [[value]]]
              d3_c = size(newdata, /DIMENSIONS)
              newsize = d3_c[2]
            endif
          endif else begin
            print, 'Error in icon_netcdf_load_vars: Could not concatenate days, variable:', varinq.name
          endelse

          ptr_free, netCDFi.vars.(i).dataptr
          netCDFi.vars.(i).dataptr = ptr_new(newdata)
          oldsize = netCDFi.dims.(0).(2)
          if newsize gt oldsize then netCDFi.dims.(0).(2) = newsize
        endif

      endfor
      ; if newsize ne -1 then netCDFi.vars.epoch.size = newsize
    endelse
    ; close the netCDF file

    ncdf_close, file
  endfor

  icon_dimension_fix, netcdfi

  return, netCDFi
end