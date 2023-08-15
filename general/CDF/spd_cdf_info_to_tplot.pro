;+
; This is a new routine that needs further testing, development, and enhancements.
; PROCEDURE:  spd_cdf_info_to_tplot, cdfi
; Purpose:  Creates TPLOT variables from a CDF structure (obtained from "CDF_LOAD_VAR")
; This routine will only work well if the underlying CDF file follows the SPDF standard.
;
;Keywords:
;   /TT2000              ; Keep TT200 time in unsigned long format
;
; Written by Davin Larson
;   Forked from MMS, 04/09/2018, adrozdov
;   According to ISTP/IACG guidelines "Epoch" should be the first variable in each CDF data set.
;   https://spdf.gsfc.nasa.gov/istp_guide/variables.html#Epoch
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2023-08-14 17:59:53 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 32000 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/spd_cdf_info_to_tplot.pro $
;-
pro spd_cdf_info_to_tplot,cdfi,varnames,loadnames=loadnames, non_record_varying=non_record_varying, tt2000=tt2000,$
        prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname,  $
        all=all, $
        force_epoch=force_epoch, $
        verbose=verbose,get_support_data=get_support_data,  $
        tplotnames=tplotnames,$
        center_measurement=center_measurement, $ ; if set, and the CDF contains the variables delta_plus_var and delta_minus_var on the Epoch
                                     ; variable, this routine will shift the timestamps so that each measurement time
                                     ; is in the middle of the data interval for consistency with other instruments; this is 
                                     ; mostly for FPI - the delta +/- is [10,0] sec for the SITL data product or 
                                     ; [0.03, 0] sec for a DES burst product
        load_labels=load_labels ;copy labels from labl_ptr_1 in attributes into dlimits
                                      ;resolve labels implemented as keyword to preserve backwards compatibility

dprint,verbose=verbose,dlevel=4,'$Id: spd_cdf_info_to_tplot.pro 32000 2023-08-15 00:59:53Z jwl $'
tplotnames=''
vbs = keyword_set(verbose) ? verbose : 0

dplus_var = ''
dminus_var = ''
time_plus_offset = 0d
time_minus_offset = 0d
centered_on_load = 0b

if size(cdfi,/type) ne 8 then begin
    dprint,dlevel=1,verbose=verbose,'Must provide a CDF structure'
    return
endif

if keyword_set(all) or n_elements(varnames) eq 0 then varnames=cdfi.vars.name

nv = cdfi.nv

for i=0,nv-1 do begin
   v=cdfi.vars[i]
   if vbs ge 6 then dprint,verbose=verbose,dlevel=6,v.name
   if ptr_valid(v.dataptr) eq 0 then begin
       dprint,dlevel=5,verbose=verbose,'Invalid data pointer for ',v.name
       continue
   endif
   attr = *v.attrptr
   var_type = struct_value(attr,'var_type',def='')
   depend_time = struct_value(attr,'depend_time',def='time')
   depend_0 = struct_value(attr,'depend_0',def='Epoch')
   depend_1 = struct_value(attr,'depend_1',def='')
   depend_2 = struct_value(attr,'depend_2',def='')
   depend_3 = struct_value(attr,'depend_3',def='')
   depend_4 = struct_value(attr,'depend_4',def='')
   display_type = struct_value(attr,'display_type',def='time_series')
   scaletyp = struct_value(attr,'scaletyp',def='linear')
   fillval = struct_value(attr,'fillval',def=!values.f_nan)
   fieldnam = struct_value(attr,'fieldnam',def=v.name)

   if strcmp(v.datatype,'CDF_TIME_TT2000',/fold_case) and ~keyword_set(TT2000) then begin
      defsysv,'!CDF_LEAP_SECONDS',exists=exists
  
      if ~keyword_set(exists) then begin
        cdf_leap_second_init
        defsysv,'!CDF_LEAP_SECONDS',exists=exists
        ;fatal error
        if ~keyword_set(exists) then message,'Error. !CDF_LEAP_SECONDS, must be defined to convert CDFs with TT2000 times.'
     endif
     
    *(v.dataptr) =time_double(*(v.dataptr),/tt2000)     ; convert to UNIX_time but without leap seconds
    cdfi.vars[i].datatype = 'CDF_S1970'
     
     if !CDF_LEAP_SECONDS.preserve_tt2000 then begin
       *(v.dataptr) =add_tt2000_offset(*v.dataptr)   ; convert to UNIX epoch, but leave the offset in.
     endif 
     
     ; adjust the epoch to the center of the accumulation interval
     if keyword_set(center_measurement) then begin
         centered_on_load = 1b
         dplus_var = struct_value(*v.attrptr, 'DELTA_PLUS_VAR', def='')
         dminus_var = struct_value(*v.attrptr, 'DELTA_MINUS_VAR', def='')
         ; check for DELTA_PLUS_VAR and DELTA_MINUS_VAR
         ; on the Epoch variable
         if dplus_var ne '' then begin
           j = (where(strcmp(cdfi.vars.name, dplus_var,/fold_case),nj))[0]
           if nj gt 0 then epoch_plus_var = cdfi.vars[j]
           ; get the distance from the center of the interval
           if ptr_valid(epoch_plus_var.dataptr) && ptr_valid(epoch_plus_var.attrptr) then begin
               time_plus_offset = *epoch_plus_var.dataptr
               ; need to convert the offset to seconds
               str_element, (*epoch_plus_var.attrptr), 'SI_CONVERSION', si_conversion_plus
               if undefined(si_conversion_plus) then begin
                   str_element, (*epoch_plus_var.attrptr), 'SI_CONV', si_conversion_plus
                   if undefined(si_conversion_plus) then si_conversion_plus = 1
               endif
               conv_factor = (strsplit(si_conversion_plus, '>', /extract))[0]
               if strtrim(conv_factor) ne '' then time_plus_offset = time_plus_offset*double(conv_factor)
           endif
         endif
         if dminus_var ne '' then begin
           j = (where(strcmp(cdfi.vars.name, dminus_var,/fold_case),nj))[0]
           if nj gt 0 then epoch_minus_var = cdfi.vars[j]
           if ptr_valid(epoch_minus_var.dataptr) && ptr_valid(epoch_minus_var.attrptr) then begin
               time_minus_offset = *epoch_minus_var.dataptr
               ; need to convert the offset to seconds
               str_element, (*epoch_minus_var.attrptr), 'SI_CONVERSION', si_conversion_minus
               if undefined(si_conversion_minus) then begin
                   str_element, (*epoch_minus_var.attrptr), 'SI_CONV', si_conversion_minus
                   if undefined(si_conversion_minus) then si_conversion_minus = 1
               endif

               conv_factor = (strsplit(si_conversion_minus, '>', /extract))[0]
               if strtrim(conv_factor) ne '' then time_minus_offset = time_minus_offset*double(conv_factor)
           endif
         endif
         *(v.dataptr) = *(v.dataptr)+(time_plus_offset-time_minus_offset)/2.
     endif
     
     continue
     
   endif 
   
   if strcmp(v.datatype,'CDF_TIME_TT2000',/fold_case) then begin
   ; TT2000 time and TT2000 keyword are specifyed
   ; No modification of the loaded data is needed
   ; *(v.dataptr) = *(v.dataptr)
   cdfi.vars[i].datatype = 'CDF_TIME_TT2000'
   endif else if (strcmp(v.datatype,'CDF_EPOCH',/fold_case) || strcmp(v.datatype,'CDF_EPOCH16',/fold_case) || (strcmp( v.name , 'Epoch',5, /fold_case) && (v.datatype ne 'CDF_S1970')))  then begin
       *(v.dataptr) =time_double(/epoch, *(v.dataptr) )     ; convert to UNIX_time
       cdfi.vars[i].datatype = 'CDF_S1970'
       continue
   endif

   if finite(fillval) and keyword_set(v.dataptr) and (v.type eq 4 or v.type eq 5) then begin
       w = where(*v.dataptr eq fillval,nw)
       if nw gt 0 then (*v.dataptr)[w] = !values.f_nan
   endif

;   plottable_data = strcmp( var_type , 'data',/fold_case)

;   if keyword_set(get_support_data) then plottable_data or= strcmp( var_type, 'support',7,/fold_case)

   plottable_data= total(/preserve,v.name eq varnames) ne 0
   
   ;if keyword_set(non_record_varying) then plottable_data = plottable_data else plottable_data = plottable_data and v.recvary
   ;plottable_data = plottable_data and v.recvary

   if plottable_data eq 0 then begin
      dprint,dlevel=6,verbose=verbose,'Skipping variable: "'+v.name+'" ('+var_type+')'
      continue
   endif

   j = (where(strcmp(cdfi.vars.name , depend_time,/fold_case),nj))[0]
   if nj gt 0 then tvar = cdfi.vars[j]  else  begin
     j = (where(strcmp(cdfi.vars.name ,depend_0,/fold_case),nj))[0]
     if nj gt 0 then tvar = cdfi.vars[j]
   endelse

   if nj eq 0 then begin
      dprint,verbose=verbose,dlevel=6,'Skipping variable: "'+v.name+'" ('+var_type+')'
      continue
   endif

   j = (where(strcmp(cdfi.vars.name , depend_1,/fold_case),nj))[0]
   if nj gt 0 then var_1 = cdfi.vars[j]

   j = (where(strcmp(cdfi.vars.name , depend_2,/fold_case),nj))[0]
   if nj gt 0 then var_2 = cdfi.vars[j]

   j = (where(strcmp(cdfi.vars.name , depend_3,/fold_case),nj))[0]
   if nj gt 0 then var_3 = cdfi.vars[j]

   j = (where(strcmp(cdfi.vars.name , depend_4,/fold_case),nj))[0]
   if nj gt 0 then var_4 = cdfi.vars[j]

   ; Check for extra leading size-1 dimensions and remove them when processing depend_n attributes.  This can happen 
   ; if a depend_n variable is marked as record-variant.  We avoid modifying the data array in place, on the off chance
   ; that it's somehow referenced as both plottable data and metadata, so a single metadata variable may generate multiplt
   ; warnings each time it's encountered.
   
   if keyword_set(var_1) then begin
      vdim=size(*var_1.dataptr,/dimensions)
      if (n_elements(vdim) gt 1) and (vdim[0] eq 1) then begin
        nel=n_elements(*var_1.dataptr)
        depend1_dataptr = ptr_new(reform(*var_1.dataptr,nel))
        dprint,verbose=verbose,dlevel=2,'Removed size-1 leading dimension from DEPEND_1 attribute ',depend_1,' of data variable ',cdfi.vars[i].name
        endif else depend1_dataptr=var_1.dataptr      
   endif

   if keyword_set(var_2) then begin
     vdim=size(*var_2.dataptr,/dimensions)
     if (n_elements(vdim) gt 1) and (vdim[0] eq 1) then begin
       nel=n_elements(*var_2.dataptr)
       depend2_dataptr = ptr_new(reform(*var_2.dataptr,nel))
       dprint,verbose=verbose,dlevel=2,'Removed size-1 leading dimension from DEPEND_2 attribute ',depend_2,' of data variable ',cdfi.vars[i].name
     endif else depend2_dataptr=var_2.dataptr
   endif

   if keyword_set(var_3) then begin
     vdim=size(*var_3.dataptr,/dimensions)
     if (n_elements(vdim) gt 1) and (vdim[0] eq 1) then begin
       nel=n_elements(*var_3.dataptr)
       depend3_dataptr = ptr_new(reform(*var_3.dataptr,nel))
       dprint,verbose=verbose,dlevel=2,'Removed size-1 leading dimension from DEPEND_3 attribute ',depend_3,' of data variable ',cdfi.vars[i].name
     endif else depend3_dataptr=var_3.dataptr
   endif
    
   spec = strcmp(display_type,'spectrogram',/fold_case)
   log  = strcmp(scaletyp,'log',3,/fold_case)
   
   if ptr_valid(tvar.dataptr) and ptr_valid(v.dataptr) then begin

     if v.recvary eq 0 then begin
       ; Note that v.numrec will likely be set to -1 by spd_mms_cdf_load_vars if the variable is non-record-variant
       ; This seems to happen for quite a few MMS and Cluster variables.
       dprint,dlevel=1,verbose=verbose,'Warning: Variable '+v.name+' is marked non-record-varying, but has a time variable. Record counts may be mismatched.'
     endif

     if size(/n_dimens,*v.dataptr) ne v.ndimen +1 then begin    
      ; Cluge for (lost) trailing dimension of 1
      ;in rare circumstances, var_2 may not exist here, jmm, 17-mar-2009,
      ;          var_1 = var_2        ;bpif  v.name eq 'thb_sir_001'
      ;    if(keyword_set(var_2)) then var_1 = var_2 else var_1 = 0 ;bpif  v.name eq 'thb_sir_001'
      ;    var_2 = 0

      ;   Revised 2020-12-08 by JWL
      ;   Reform the data array to the expected dimensions in case a size-1 dimension gets dropped.  This can happen
      ;   if a CDF has a single sample for that variable, but is marked "non-record-variant".   Simply zeroing var_2
      ;   can result in a crash later in this routine.

          current_dimens=size(*v.dataptr,/dimen)
          time_count=n_elements(*tvar.dataptr)        
          if current_dimens[0] eq time_count then begin
            dprint,verbose=verbose,dlevel=1,'Warning: unexpected data array dimensions for variable '+v.name
            dprint,verbose=verbose,dlevel=1,'Expected '+string(v.ndimen) +' dimensions plus time'
            dprint,verbose=verbose,dlevel=1,'Got '+string(n_elements(current_dimens))+' dimensions: ',current_dimens
            dprint,verbose=verbose,dlevel=1,'Time count matches leading data dimension, reforming to restore size 1 trailing dimension'
            ; It might be better to set new_dimens by looking at v.d
            new_dimens = [current_dimens, 1]
            *v.dataptr = reform(*v.dataptr, new_dimens,/overwrite)
          endif else begin
            dprint,verbose=verbose,dlevel=1,'Time dimension seems to be missing, ignoring mismatch and continuing'
          endelse
     endif
     
      ; Issue a warning if correponsded depend_n is emtpy      
      for dpn=0,size(/n_dimens,*v.dataptr)-1 do begin
      case dpn of
        0: if depend_0 eq '' then  begin
              dprint,verbose=verbose,dlevel=1,'Warning: depend_0 for variable '+v.name+' is empty'   
           endif     
        1: if depend_1 eq '' then  begin
              dprint,verbose=verbose,dlevel=1,'Warning: depend_1 for variable '+v.name+' is empty'
           endif
        2: if depend_2 eq '' then  begin
              dprint,verbose=verbose,dlevel=1,'Warning: depend_2 for variable '+v.name+' is empty'
           endif
        3: if depend_3 eq '' then  begin
              dprint,verbose=verbose,dlevel=1,'Warning: depend_3 for variable '+v.name+' is empty'
           endif
        4: if depend_4 eq '' then  begin
              dprint,verbose=verbose,dlevel=1,'Warning: depend_4 for variable '+v.name+' is empty'
           endif
      endcase
      endfor 

     cdfstuff={filename:cdfi.filename,gatt:cdfi.g_attributes,vname:v.name,vatt:attr}
     units = struct_value(attr,'units',default='')
     ; If units not set, look for indirection via units_ptr attribute
     unit_ptr = struct_value(attr,'unit_ptr',default='')
     if ~keyword_set(units) and keyword_set(unit_ptr) then begin
       units_idx = where(cdfi.vars.name eq unit_ptr,c)
       if c eq 1 then begin
         if ptr_valid(cdfi.vars[units_idx].dataptr) then begin
           ; str_element,/add,cdfstuff.vatt,'units',*cdfi.vars[units_idx].dataptr         
           units=*cdfi.vars[units_idx].dataptr
         endif
       endif
     endif

     ; Handle cases where DEPEND_N is defined, but DEPEND_M M<N is undefined.  This can sometimes happen in
     ; complex-valued spectra, where one dimension is 'real' vs 'imaginary', but the data provider has omitted
     ; the DEPEND_N attribute for that dimension.
     
     if keyword_set(var_3) and ~keyword_set(var_2) and ~keyword_set(var_1) then begin
       data = {x:tvar.dataptr,y:v.dataptr, v3:depend3_dataptr}
     endif else begin
       ; kludge to support new FPI qd[ie]s-moms files, with depend_2 set but depend_1 not set
       if keyword_set(var_2) and ~keyword_set(var_1) then begin
         data = {x:tvar.dataptr,y:v.dataptr, v2:depend2_dataptr}
       endif else begin
         if keyword_set(var_3) then data = {x:tvar.dataptr,y:v.dataptr,v1:depend1_dataptr, v2:depend2_dataptr, v3:depend3_dataptr} $
         else if keyword_set(var_2) then data = {x:tvar.dataptr,y:v.dataptr,v1:depend1_dataptr, v2:depend2_dataptr} $
         else if keyword_set(var_1) then data = {x:tvar.dataptr,y:v.dataptr, v:depend1_dataptr}  $
         else data = {x:tvar.dataptr,y:v.dataptr}
       endelse
     endelse
     
     ; coordinate system support; loads from the COORDINATE_SYSTEM variable attribute (CDF_CHAR)
     coord_sys =  struct_value(attr,'coordinate_system',default='')
     if ~undefined(coord_sys) then coord_sys = strlowcase((strsplit(coord_sys, '>', /extract))[0])

     if centered_on_load eq 1b then begin
       dlimit = {cdf:cdfstuff,spec:spec,log:log,data_att:{coord_sys:coord_sys, units:units}, centered_on_load: centered_on_load}
     endif else dlimit = {cdf:cdfstuff,spec:spec,log:log,data_att:{coord_sys:coord_sys,units:units}}
     
     if keyword_set(units) then begin
      if n_elements(units) eq 1 then begin
        units_str='['+units+']'
      endif else begin
        units_str='['
        for ui=0, n_elements(units)-1 do begin
          units_str=units_str+' '+units[ui] 
        endfor
        units_str=units_str+' ]'
      endelse
      str_element,/add,dlimit,'ysubtitle',units_str
     endif
     
     if keyword_set(load_labels) then begin
       labl_ptr_1 = struct_value(attr,'labl_ptr_1',default='')
       if keyword_set(labl_ptr_1) then begin
         labl_idx = where(cdfi.vars.name eq labl_ptr_1,c)
         if c eq 1 then begin
           if ptr_valid(cdfi.vars[labl_idx].dataptr) then begin
             str_element,/add,dlimit,'labels',*cdfi.vars[labl_idx].dataptr
           endif
         endif
       endif
     endif
     
     tn = v.name
;     if keyword_set(newname) then begin;;  bug here
;        tn = newname[i]
;     endif
     if keyword_set(midfix) then begin
        if size(/type,midpos) eq 7 then str_replace,tn,midpos,midfix    $
        else    tn = strmid(tn,0,midpos) + midfix + strmid(tn,midpos)
     endif
     if keyword_set(prefix) then tn = prefix+tn
     if keyword_set(suffix) then tn = tn+suffix
     store_data,tn,data=data,dlimit=dlimit, verbose=verbose
     tplotnames = keyword_set(tplotnames) ? [tplotnames,tn] : tn
   endif else begin   ; either the time variable, or data variable, or both, are empty.  Not necessarily a warning.
     if ~ptr_valid(tvar.dataptr) and ptr_valid(v.dataptr) and ~strmatch(v.name,'th*_time') then begin
       ;  Data pointer is valid, time is not.  This is normal for THEMIS timestamp variables (referenced by a DEPEND_TIME attribute
       ;  somewhere else), which have a DEPEND_0 pointing to some flavor of CDF_EPOCH that virtual, and therefore empty here.  
       ;  That's OK and we don't want to warn about it.  However, if it doesn't match the naming convention for THEMIS times, 
       ;  something is wrong and a warning should be issued.  JWL 2020-12-11
       dprint,dlevel=1,verbose=verbose,'Warning: empty time variable '+tvar.name+' for '+v.name+', skipping.'
     endif
   endelse
   var_1=0
   var_2=0
   var_3=0
   var_4=0
endfor

end

