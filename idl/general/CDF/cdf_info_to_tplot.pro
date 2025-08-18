;+
; This is a new routine that needs further testing, development, and enhancements.
; PROCEDURE:  cdf2tplot, cdfi
; Purpose:  Creates TPLOT variables from a CDF structure (obtained from "CDF_LOAD_VAR")
; This routine will only work well if the underlying CDF file follows the SPDF standard.
;
; Written by Davin Larson
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2024-07-09 11:03:46 -0700 (Tue, 09 Jul 2024) $
; $LastChangedRevision: 32730 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/cdf_info_to_tplot.pro $
;-
pro cdf_info_to_tplot,cdfi,varnames,loadnames=loadnames,  $
  prefix=prefix,midfix=midfix,midpos=midpos,suffix=suffix,newname=newname,  $
  all=all, $
  force_epoch=force_epoch, $
  verbose=verbose,get_support_data=get_support_data,  $
  tplotnames=tplotnames,$
  load_labels=load_labels,$ ;copy labels from labl_ptr_1 in attributes into dlimits
  smex_epoch=smex_epoch ;if set, variables called "epoch" and "time" are seconds from 1968-05-24, not CDF epoch
  ;resolve labels implemented as keyword to preserve backwards compatibility

  dprint,verbose=verbose,dlevel=4,'$Id: cdf_info_to_tplot.pro 32730 2024-07-09 18:03:46Z jimm $'
    tplotnames=''
  vbs = keyword_set(verbose) ? verbose : 0


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
    if(ptr_valid(v.attrptr) && keyword_set(*v.attrptr)) then begin
      attr = *v.attrptr
    endif else begin             ;fix for IDL 6.4.1
      attr = 0 & undefine, attr ;undefined attr will default out of struct_value
    endelse
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
    units = struct_value(attr,'units',default='')
    if units eq ' ' then units=''
    if strcmp(v.datatype,'CDF_TIME_TT2000',/fold_case) then begin
      defsysv,'!CDF_LEAP_SECONDS',exists=exists

      if ~keyword_set(exists) then begin
        cdf_leap_second_init
        defsysv,'!CDF_LEAP_SECONDS',exists=exists
        ;fatal error
        if ~keyword_set(exists) then message,'Error. !CDF_LEAP_SECONDS, must be defined to convert CDFs with TT2000 times.'
      endif

      w = where(*v.dataptr eq fillval,nw) ;fillval for TT2000 is supposed to be -9223372036854775808
      *(v.dataptr) =time_double(*(v.dataptr),/tt2000)     ; convert to UNIX_time but without leap seconds
      if nw gt 0 then (*v.dataptr)[w] = !values.d_nan ;since TT2000 fillval is not recognized by time_double
      v.datatype = 'CDF_S1970'
      v.type =5 ;Double-precision (no longer LONG64)

      if !CDF_LEAP_SECONDS.preserve_tt2000 then begin
        *(v.dataptr) =add_tt2000_offset(*v.dataptr)   ; convert to UNIX epoch, but leave the offset in.
      endif

      continue

    endif

    if (strcmp( v.name, 'Epoch',5, /fold_case) && keyword_set(smex_epoch)) then begin
      *(v.dataptr) = *(v.dataptr) + time_double('1968-05-24')     ; convert to UNIX_time
      v.datatype = 'CDF_S1970'
      continue
    endif

    if (strcmp( v.name, 'Time',4, /fold_case) && keyword_set(smex_epoch)) then begin
      *(v.dataptr) = *(v.dataptr) + time_double('1968-05-24')     ; convert to UNIX_time
      v.datatype = 'CDF_S1970'
      continue
    endif

    if (strcmp(v.datatype,'CDF_EPOCH',/fold_case) || strcmp(v.datatype,'CDF_EPOCH16',/fold_case) || (strcmp( v.name , 'Epoch',5, /fold_case) && (v.datatype ne 'CDF_S1970')))  then begin
      *(v.dataptr) =time_double(/epoch, *(v.dataptr) )     ; convert to UNIX_time
      v.datatype = 'CDF_S1970'
      continue
    endif

    if (v.type eq 4 or v.type eq 5) then begin
      if finite(fillval) and keyword_set(v.dataptr) then begin
        w = where(*v.dataptr eq fillval,nw)
        if nw gt 0 then (*v.dataptr)[w] = !values.f_nan
      endif
    endif

    ;   plottable_data = strcmp( var_type , 'data',/fold_case)

    ;   if keyword_set(get_support_data) then plottable_data or= strcmp( var_type, 'support',7,/fold_case)

    plottable_data= total(/preserve,v.name eq varnames) ne 0
    plottable_data = plottable_data and v.recvary

    if plottable_data eq 0 then begin
      dprint,dlevel=6,verbose=verbose,'Skipping variable: "'+v.name+'" ('+var_type+')'
      continue
    endif

    j = (where(strcmp(cdfi.vars.name, depend_0, /fold_case),nj))[0]
    ;Fix for WIND data files, which have depend_0 = Epoch, but no data in
    ;the variable, jmm, 2019-08-16
    if nj gt 0 && ptr_valid(cdfi.vars[j].dataptr) then tvar = cdfi.vars[j] else begin
      ;    if nj gt 0 then tvar = cdfi.vars[j]  else  begin
      j = (where(strcmp(cdfi.vars.name, depend_time, /fold_case),nj))[0]
      if nj gt 0 && ptr_valid(cdfi.vars[j].dataptr) then tvar = cdfi.vars[j] else nj = 0
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

    spec = strcmp(display_type,'spectrogram',/fold_case)
    ylog = strcmp(scaletyp,'log',3,/fold_case)
    zlog = ylog and spec
    if zlog then ylog = 0b

    if ptr_valid(tvar.dataptr) && ptr_valid(v.dataptr) then begin

      if size(/n_dimens,*v.dataptr) ne v.ndimen +1 then begin    ; Cluge for (lost) trailing dimension of 1
        ;in rare circumstances, var_2 may not exist here, jmm, 17-mar-2009,
        ;          var_1 = var_2        ;bpif  v.name eq 'thb_sir_001'
        if(keyword_set(var_2)) then var_1 = var_2 else var_1 = 0 ;bpif  v.name eq 'thb_sir_001'
        var_2 = 0
      endif
      
      ; Issue a warning if correponsded depend_n is emtpy      
      for dpn=0,size(/n_dimens,*v.dataptr)-1 do begin
      case dpn of
        0: if depend_0 eq '' then  dprint,verbose=verbose,dlevel=6,'Warning: depend_0 is empty'        
        1: if depend_1 eq '' then  dprint,verbose=verbose,dlevel=6,'Warning: depend_1 is empty'
        2: if depend_2 eq '' then  dprint,verbose=verbose,dlevel=6,'Warning: depend_2 is empty'
        3: if depend_3 eq '' then  dprint,verbose=verbose,dlevel=6,'Warning: depend_3 is empty'
        4: if depend_4 eq '' then  dprint,verbose=verbose,dlevel=6,'Warning: depend_4 is empty'
;;       adrozdov: The following method is icompatable with virtual machene and old version of IDL:
;;       egrimes: the call to string() crashes for IDL 8.5.1; commented out 9 Oct 2020 
;        depend_str = string(dpn, format="depend_%d")
;        eres = execute("res = " + depend_str + " eq ''")
;        if res then dprint,verbose=verbose,dlevel=6,'Warning: ' + depend_str + ' is empty'
      endcase
      endfor      
       


      
      cdfstuff={filename:cdfi.filename,gatt:cdfi.g_attributes,vname:v.name,vatt:keyword_set(attr)?attr:0}
      if keyword_set(var_1) && isa(*var_1.dataptr,/string) then var_1=0     ; check for weird string input
      if keyword_set(var_2) then data = {x:tvar.dataptr,y:v.dataptr,v1:var_1.dataptr, v2:var_2.dataptr} $
      else if keyword_set(var_1) then begin
        ylog=strcmp(struct_value(*var_1.attrptr,'scaletyp',def='linear'),'log',3,/fold_case)
        yunits = struct_value(*var_1.attrptr,'units',default='')
        data = {x:tvar.dataptr,y:v.dataptr, v:var_1.dataptr}
      endif else data = {x:tvar.dataptr,y:v.dataptr}

      dlimit = {cdf:cdfstuff,spec:spec,ylog:ylog,zlog:zlog}
      if keyword_set(units) then begin
        if spec && keyword_set(var_1) && var_1.recvary then begin
          str_element,/add,dlimit,'ztitle','['+units+']'
          if keyword_set(yunits) then str_element,/add,dlimit,'ysubtitle','['+yunits+']'
        endif else str_element,/add,dlimit,'ysubtitle','['+units+']'
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
    endif
    var_1=0
    var_2=0
    var_3=0
    var_4=0
  endfor

end

