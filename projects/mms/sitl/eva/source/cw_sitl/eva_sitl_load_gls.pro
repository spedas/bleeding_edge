;+
; NAME: EVA_SITL_LOAD_GLS
;
; PURPOSE: To load ground-loop selections (GLS) from SDC and creates
;          a tplot varialbe to be displayed with SPEDAS.
;
; INPUT
;   trange: time range
;   algo:   name of the GLS algorithm. This should be either scalar or vector of string variables.
;            
; EXAMPLE:
;   MMS> timespan,'2018-01-29', 1,/days
;   MMS> eva_sitl_load_gls, algo='mp-dl-unh'
;   MMS> tplot,['mms_soca_fomstr','mms_gls1_fomstr']
;
; $LastChangedBy: moka $
; $LastChangedDate: 2017-10-31 19:35:36 -0700 (Tue, 31 Oct 2017) $
; $LastChangedRevision: 24248 $
; $URL: svn+ssh://ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/eva.pro $
;
PRO eva_sitl_load_gls, trange=trange, algo=algo
  compile_opt idl2
  
  if undefined(trange) then trange=timerange()
  trange=timerange(trange)
  if undefined(algo) then begin
    algo = ['mp-dl-unh','none','none']
  endif
  
  
  mmax = n_elements(algo)
  for m=0,mmax-1 do begin
    if algo[m] ne 'none' then begin
      
      ;-------------
      ; Fetch
      ;-------------
      gls_name = 'gls_selections_'+algo[m]
      mms_get_gls_selections, gls_name, gls_files, pw_flag, pw_message, trange=trange
      glsstr = mms_read_gls_file(gls_files[0])
      if n_tags(glsstr) ge 4 then begin
        mms_get_abs_fom_files, local_flist, pw_flag, pw_message, trange=trange
        nmax = n_elements(local_flist)
        found = 0
        if nmax gt 0 then begin; if list exists
          for n=0,nmax-1 do begin; for each file
            restore,local_flist[n]; restore
            if FOMstr.VALID then begin; and check the validity
              found=1
              break; if found, break
            endif
          endfor; for each file
        endif
        
        ;-------------
        ; ABS 
        ;-------------
        mms_convert_fom_tai2unix, FOMstr, unix_FOMstr, start_string
        store_data,'mms_soca_fomstr',data = eva_sitl_strct_read(unix_FOMstr,start_string)
        options,tp,'ytitle','FOM'
        options,tp,'ysubtitle','(ABS)'
        options,tp,'unix_FOMStr_org',unix_FOMStr
        options,tp,'psym',0
        
        ;-------------
        ; GLS
        ;-------------
        Nsegs = n_elements(glsstr.FOM)
        SourceID = strarr(Nsegs)
        SourceID[0:*] = 'GLS:'+algo[m]
        START = lonarr(Nsegs)
        STOP  = lonarr(Nsegs)
        str_element,/add,unix_FOMstr,'NSEGS',Nsegs
        str_element,/add,unix_FOMstr,'SOURCEID',SourceID
        str_element,/add,unix_FOMstr,'FOM',glsstr.FOM
        str_element,/add,unix_FOMstr,'DISCUSSION',glsstr.COMMENT
        glstart = time_double(glsstr.START)
        glstop  = time_double(glsstr.STOP)
        for n=0,Nsegs-1 do begin
          result = min(unix_FOMstr.TIMESTAMPS - glstart[n],Nstart,/abs,/nan)
          result = min(unix_FOMstr.TIMESTAMPS - glstop[n], Nstop, /abs,/nan)
          START[n] = Nstart
          STOP[n]  = Nstop
        endfor
        str_element,/add,unix_FOMstr,'START',START
        str_element,/add,unix_FOMstr,'STOP',STOP
        sid = strtrim(string(m+1),2)
        tp = 'mms_gls'+sid+'_fomstr'
        store_data,tp,data = eva_sitl_strct_read(unix_FOMstr,start_string)
        options,tp,'ytitle','FOM'
        options,tp,'ysubtitle','(GLS'+sid+')'
        options,tp,'unix_FOMStr_org',unix_FOMStr
        options,tp,'psym',0
        options,tp,'constant',[50,100,150,200]
        options,tp,'yrange',[0,200]
      endif
    endif
  endfor
END