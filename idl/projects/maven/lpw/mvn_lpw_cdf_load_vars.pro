;+
;Function, cdfi = mvn_lpw_cdf_load_vars(file)
;
;Original routine from SSL Berkeley, with info below. Original routine edited by Chris Fowler from Oct 2013 onwards for use with
;the MAVEN lpw software. Routine is called from within mvn_lpw_cdf_cdf2tplot.pro, and is part of the software to load a tplot variable into 
;IDL memory from a saved CDF file.
;
;INPUTS:
; - file: the full string directory and filename of the CDF file to be loaded into IDL memory. This is input in mvn_lpw_cdf_cdf2tplot.pro.
;
;OUTPUTS:
; - A structure containing the tplot variable data.
;
;KEYWORDS:
; NOTE: I'm not sure if these work yet as they may not have been written in by SSL. They don't seem necessary for basic file loading.
; 
;EXAMPLE:
;cdfi = mvn_lpw_cdf_load_vars(file)
;
;#############
; Original routine notes:
;
; FUNCTION cdfi = cdf_load_vars(file)
; Keywords:
;   VARFORMAT = string or string array:  a string or string array (which may contain wildcard
;                         characters) that specifies the CDF variable names to load.  Use
;                          'VARFORMAT='*' to load all variables.
;   VARNAMES = named variable   ;output variable for variable names that were loaded.
;   SPDF_DEPENDENCIES :   Set to 1 to have SPDF defined dependent variables also loaded.
;   VAR_TYPE = string or string array;  Variables that have a VAR_TYPE matching these strings will
;                         be loaded.
;   CONVERT_INT1_TO_INT2  Set this keyword to convert signed one byte to signed 2 byte integers.
;                         This is useful because IDL does not have the equivalent of INT1   (bytes are unsigned)
;   RECORD: Specify the record index where you want to start reading.  By default, this option will read one record.
;   NUMBER_RECORDS: Specify the number of records that you want to read.  By default, this option will begin at record zero.
; 
; Note: Record & Number_Records can be used together to specify a range of records to be read.
;
; Author: Davin Larson - 2006
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-02-10 11:41:54 -0800 (Tue, 10 Feb 2015) $
; $LastChangedRevision: 16942 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/lpw/mvn_lpw_cdf_load_vars.pro $
;
; ###############
; ;
;  Version 1.0
;  ;140718 clean up for check out L. andersson
;-
function mvn_lpw_cdf_load_vars,files,varnames=vars,varformat=vars_fmt,info=info,verbose=verbose,all=all, $
    record=record,convert_int1_to_int2=convert_int1_to_int2, $
    spdf_dependencies=spdf_dependencies, $
    var_type=var_type, $
    no_attributes=no_attributes,$
    number_records=number_records

vb = keyword_set(verbose) ? verbose : 0
vars=''
info = 0
dprint,dlevel=4,verbose=verbose,'$Id: mvn_lpw_cdf_load_vars.pro 16942 2015-02-10 19:41:54Z jimm $'

on_ioerror, ferr
for fi=0,n_elements(files)-1 do begin
    if file_test(files[fi]) eq 0 then begin
        dprint,dlevel=1,verbose=verbose,'File not found: "'+files[fi]+'"'
        continue
    endif
    id=cdf_open(files[fi])
    if not keyword_set(info) then begin
        info = cdf_info(id,verbose=verbose) ;, convert_int1_to_int2=convert_int1_to_int2)
    endif  
    ; if there are no variables loaded
    if info.nv eq 0 or ~is_struct(info.vars) then begin
         dprint,verbose=verbose,'No valid variables in the CDF file!'
         return,info
    endif  
    
    if n_elements(spdf_dependencies) eq 0 then spdf_dependencies =1

    if not keyword_set(vars) then begin
        if keyword_set(all) then vars_fmt = '*'
        if keyword_set(vars_fmt) then vars = [vars, strfilter(info.vars.name,vars_fmt,delimiter=' ')]
        if keyword_set(var_type) then begin
            vtypes = strarr(info.nv)
            for v=0,info.nv-1 do begin
                vtypes[v] = cdf_var_atts(id,info.vars[v].num,zvar=info.vars[v].is_zvar,'VAR_TYPE',default='')
            endfor
            vars= [vars, info.vars[strfilter(vtypes,var_type,delimiter=' ',/index)].name]
        endif
        vars = vars[uniq(vars,sort(vars))]
        if n_elements(vars) le 1 then begin
            dprint,verbose=verbose,'No valid variables selected to load!'
            return,info
        endif else vars=vars[1:*]
        vars2=vars

;        if vb ge 4 then printdat,/pgmtrace,vars,width=200

        if keyword_set(spdf_dependencies) then begin  ; Get all the variable names that are dependents
            depnames = ''
            for i=0,n_elements(vars)-1 do begin
                vnum = where(vars[i] eq info.vars.name,nvnum)
                if nvnum eq 0 then message,'This should never happen, report error to D. Larson: davin@ssl.berkeley.edu'
                vi = info.vars[vnum]
                depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_TIME',default='')]   ;bpif vars[i] eq 'tha_fgl'
                depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_0',default='')]
                ndim = vi.ndimen
                for j=1,ndim do begin
                   depnames = [depnames, cdf_var_atts(id,vi.num,zvar=vi.is_zvar,'DEPEND_'+strtrim(j,2),default='')]
                endfor
            endfor
            if keyword_set(depnames) then depnames=depnames[[where(depnames)]]
            depnames = depnames[uniq(depnames,sort(depnames))]
            vars2 = [vars2,depnames]
            vars2 = vars2[uniq(vars2,sort(vars2))]
            vars2 = vars2[where(vars2)]
;            if vb ge 4 then printdat,/pgmtrace,depnames,width=200
       endif
    endif

    ;dprint,dlevel=2,verbose=verbose,'Loading file: "'+files[fi]+'"'   ;Don't want this to print every time
    for j=0,n_elements(vars2)-1 do begin
        w = (where( strcmp(info.vars.name, vars2[j]) , nw))[0]
        if nw ne 0 then begin
            vi = info.vars[w]
            dprint,verbose=verbose,dlevel=7,vi.name
;            if vb ge 9 then  wait,.2
;            if   vi.recvary or 1  then begin ;disabling logic that does nothing, pcruce@igpp.cula.edu
             q=!quiet & !quiet=1 & cdf_control,id,variable=vi.name,get_var_info=vinfo & !quiet=q
             
             ;adding logic to select the number of records that are loaded.  Helps for testing with large CDFs, can be used with the record= keyword
             if n_elements(number_records) ne 0 then begin
               numrec=number_records<(vinfo.maxrec+1)
             endif else begin
               if n_elements(record) ne 0 then begin
                 numrec=1<(vinfo.maxrec+1) 
               endif else begin
                 numrec = vinfo.maxrec+1
               endelse
             endelse
;                dprint,verbose=vb,dlevel=7,vi.name
;                if vb ge 9 then  wait,.2
;            endif else numrec = 0

            if numrec gt 0 then begin
                q = !quiet
                !quiet = keyword_set(convert_int1_to_int2)
                if n_elements(record) ne 0  then begin
                  value = 0 ;THIS line TO AVOID A CDF BUG IN CDF VERSION 3.1
                  cdf_varget,id,vi.name,value ,/string ,rec_start=record,rec_count=numrec
                endif else begin

                  if vi.is_zvar then begin
                    value = 0 ;THIS Line TO AVOID A CDF BUG IN CDF VERSION 3.1
                    cdf_varget,id,vi.name,value ,/string ,rec_count=numrec
                    ;CDF_varget,id,CDF_var,x,REC_COUNT=nrecs,zvariable = zvar,rec_start=rec_start
                  endif else begin

                    if 1 then begin     ; this cluge works but is not efficient!
                      vinq = cdf_varinq(id,vi.num,zvar=vi.is_zvar)
                      dimc = vinq.dimvar * info.inq.dim
                      dimw = where(dimc eq 0,c)
                      if c ne 0 then dimc[dimw] = 1  ;bpif vi.name eq 'ion_vel'
                    endif
                    value = 0   ;THIS Line TO AVOID A CDF BUG IN CDF VERSION 3.1
                    CDF_varget,id,vi.num,zvar=0,value,/string,COUNT=dimc,REC_COUNT=numrec  ;,rec_start=rec_start
                    value = reform(value,/overwrite)
                    dprint,phelp=2,dlevel=5,vi,dimc,value
                  endelse
                endelse
                !quiet = q
                if vi.recvary then begin
                    if (vi.ndimen ge 1 and n_elements(record) eq 0) then begin
                        if numrec eq 1 then begin
                            dprint,dlevel=3,'Warning: Single record! ',vi.name,vi.ndimen,vi.d
                            value = reform(/overwrite,value, [1,size(/dimensions,value)] )  ; Special case for variables with a single record
                        endif else begin
                            transshift = shift(indgen(vi.ndimen+1),1)
                            value=transpose(value,transshift)
                        endelse
                    endif else value = reform(value,/overwrite)
                    if not keyword_set(vi.dataptr) then  vi.dataptr = ptr_new(value,/no_copy)  $
                    else  *vi.dataptr = [*vi.dataptr,temporary(value)]
                endif else begin
                    if not keyword_set(vi.dataptr) then vi.dataptr = ptr_new(value,/no_copy)
                endelse
            endif
            if not keyword_set(vi.attrptr) then $
                vi.attrptr = ptr_new( cdf_var_atts(id,vi.name,convert_int1_to_int2=convert_int1_to_int2) )
            info.vars[w] = vi
        endif ;else  dprint,dlevel=1,verbose=verbose,'variable "'+vars2[j]+'" not found!'  ;Don't want this error message printing
    endfor
    cdf_close,id
endfor

if keyword_set(info) and keyword_set(convert_int1_to_int2) then begin
    w = where(info.vars.datatype eq 'CDF_INT1',nw)
    for i=0,nw-1 do begin
        v = info.vars[w[i]]
        if ptr_valid(v.dataptr) then begin
            dprint,dlevel=5,verbose=verbose,'Warning: Converting from INT1 to INT2 (',v.name ,')'
            val = *v.dataptr
            *v.dataptr = fix(val) - (val ge 128) * 256
        endif
    endfor
endif

return,info

ferr:
dprint,dlevel=0,"CDF FILE ERROR in: ",files[fi]
msg = !error_state.msg ;copy to keep system var from being mutated when MESSAGE is called
message, msg
return,0

end

