;+
;Procedure MVN_MAG_LOAD
;Usage:
;  MVN_MAG_LOAD                            ; Load default
;  MVN_MAG_LOAD,'L1_FULL'                  ; load Full res sav files
;  MVN_MAG_LOAD,'L2_30SEC',trange=trange
;
; Purpose: Loads MAVEN mag data into tplot variables
;
; Author: Davin Larson and Roberto Livi
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-03-23 14:45:46 -0700 (Sun, 23 Mar 2025) $
; $LastChangedRevision: 33197 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_load.pro $
;-

pro mvn_mag_load,format,trange=trange,files=files,download_only=download_only,tplot=tplot_flag,$
  format=format_old,source=source,verbose=verbose,pathname=pathname,data=str_all,spice_frame=spice_frame,$
  timecrop=timecrop,mag_product=mag_product,sclk_ver=sclk_ver,mag_frame=mag_frame,l2only=l2only, $
  onesec=onesec

  if n_elements(tplot_flag) eq 0  then tplot_flag  = 1
  if keyword_set(format_old)      then format      = format_old
  if size(format,/type) ne 7      then format      = 'L2_1SEC'
  if size(mag_product,/type) ne 7 then mag_product = 'MAG1'
  if size(mag_frame,/type) ne 7   then mag_frame   = 'pl'
  if keyword_set(onesec)          then onesec      = '1s' else onesec = ''  ; STS files only
  l1_ok = ~keyword_set(l2only)

  mag_frame = strlowcase(mag_frame[0])
  case mag_frame of
    'pl'  : frame = 'MAVEN_SPACECRAFT'
    'pc'  : frame = 'IAU_MARS'
    'ss'  : frame = 'MAVEN_SSO'
    else  : begin
      dprint, '*****************************************'
      dprint, 'ERROR: Unrecognized MAG frame: ' + mag_frame
      dprint, 'Must be one of: pl, pc, or ss.'
      dprint, '*****************************************'
      return
    end
  endcase

  mag_product = strupcase(mag_product[0])
  case mag_product of
    'MAG1' : mprod = 'OB'
    'MAG2' : mprod = 'IB'
    'OB'   : mprod = 'OB'
    'IB'   : mprod = 'IB'
    else   : begin
      dprint, '*****************************************'
      dprint, 'ERROR: Unrecognized MAG product: ' + mag_product
      dprint, 'Must be either MAG1 or MAG2.'
      dprint, '*****************************************'
      return
    end
  endcase

  ; MAG structure tag names do not have a consistent format
  if (mag_frame eq 'pl') then ff = 'PL' else ff = ''
  xtag = mprod + '_B' + ff + '_X'
  ytag = mprod + '_B' + ff + '_Y'
  ztag = mprod + '_B' + ff + '_Z'

  sclk_ver = [-1]
  level=strlowcase(strmid(format,0,2))
  if level eq 'l1' then begin
    dprint, '*******************************************'
    dprint, 'WARNING: LEVEL 1 FORMAT'
    dprint, 'These data may not be used for publication.'
    dprint, '*******************************************'
  endif

  res=strlowcase(strmid(format,3))
  if (res eq 'full') || (res eq '1sec') || (res eq '30sec') then format='SAV'

  case strupcase(format) of
    'SAV': begin
      pathname = 'maven/data/sci/mag/'+level+'/sav/'+res+'/YYYY/MM/mvn_mag_'+level+'_'+mag_frame+'_'+res+'_YYYYMMDD.sav'
      files=mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,files=files,/last_version,/valid_only)
      if (files[0] eq '') && (level eq 'l2') then begin
        dprint, 'L2 files not available!'
        if (l1_ok) then begin
          dprint, 'Looking for L1 files...'
          mvn_mag_load,'l1_'+res,trange=trange,files=files,download_only=download_only,tplot=tplot_flag,$
            format=format_old,source=source,verbose=verbose,pathname=pathname,data=str_all,spice_frame=spice_frame,$
            timecrop=timecrop,mag_product=mag_product,sclk_ver=sclk_ver,mag_frame=mag_frame,l2only=l2only
          return
        endif else begin
          dprint, 'L2ONLY is set --> ABORT!'
          return
        endelse
      endif
      if (files[0] eq '') then begin
        dprint, 'L1 files not available!'
        return
      endif
      str_all=0
      ind=0
      for i=0,n_elements(files)-1 do begin
        file=files[i]
        dprint,dlevel=2,verbose=verbose,'Restoring '+file_info_string(file)
        restore,file,verbose=keyword_set(verbose) && verbose ge 3
        append_array,str_all,data,index=ind
        str_element, header, 'spice_list', spice_list, success=ok
        if (ok) then begin
          j = (where(strmatch(spice_list,'*SCLK*') eq 1, cnt))[0]
          if (cnt gt 0) then begin
            words = strsplit(spice_list[j],' ',/extract)
            j = (where(strmatch(words,'*SCLK*') eq 1, cnt))[0]
            if (cnt gt 0) then begin
              words = strsplit(words[j],'.',/extract)
              sclk_ver = [sclk_ver, fix(words[1])]
            endif
          endif
        endif
      endfor
      append_array,str_all,index=ind
      if (n_elements(sclk_ver) gt 1) then sclk_ver = sclk_ver[1:*]

      ;; Crop save file according to trange
      if keyword_set(timecrop) then begin
        if ~keyword_set(trange) then trange = timerange()
        pp = where(str_all.time ge trange[0] and $
          str_all.time le trange[1],cc)
        if cc ne 0 then str_all=str_all[pp]
      endif

      ;; Select data product to plot
      if level eq 'l2' then begin
        nn = n_elements(str_all.time)
        str_temp = replicate({time:0d, vec:[0.,0.,0.],range:0.},nn)
        tags = tag_names(str_all)
        tx = (where(tags eq xtag,cc1))[0]
        ty = (where(tags eq ytag))[0]
        tz = (where(tags eq ztag))[0]
        str_temp.time = str_all.time
        if (cc1 ne 0) then begin
          str_temp.vec[0] = str_all.(tx)
          str_temp.vec[1] = str_all.(ty)
          str_temp.vec[2] = str_all.(tz)
        endif else message,mag_product+' is not available.'
        str_all = 0
        str_all = str_temp
        str_temp = 0
      endif

      if keyword_set(tplot_flag) then store_data,'mvn_B_'+res,str_all.time,transpose(str_all.vec),dlimit={spice_frame:frame}
      options,/def,'mvn_B_'+res,sclk_ver=sclk_ver,level=level,labflag=-1,labels=['Bx','By','Bz'],colors='bgr',ysubtitle=level+' '+mprod+' '+mag_frame+' [nT]'
      if (size(spice_frame,/type) eq 7) then begin
        from_frame = frame
        to_frame   = mvn_frame_name(spice_frame[0], success=ok)
        if (ok) then begin
          ;utc=time_string(str_all.time)
          utc=str_all.time
          new_vec=spice_vector_rotate(str_all.vec,utc,from_frame,to_frame,check_objects='MAVEN_SPACECRAFT')
          store_data,'mvn_B_'+res+'_'+to_frame,str_all.time,transpose(new_vec),dlimit={spice_frame:to_frame}
          options,/def,'mvn_B_'+res+'_'+to_frame,sclk_ver=sclk_ver,level=level,labflag=-1,labels=['Bx','By','Bz'],colors='bgr',ysubtitle=level+' [nT]'
        endif
      endif
    end

    ;; Level 1: CDF
    'L1_CDF': begin
      pathname = 'maven/data/sci/mag/l1_cdf/YYYY/MM/mvn_mag_ql_YYYY*DOYpl_YYYYMMDD_v??_r??.cdf'
      files=mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,files=files,/last_version,/valid_only)
      cdf2tplot,files
    end

    ;; Older style Full Resolution save files. Bigger and  Slower to read in
    'L1_SAV': begin
      pathname = 'maven/data/sci/mag/l1_sav/YYYY/MM/mvn_mag_ql_YYYY*DOYpl_YYYYMMDD_v??_r??.sav'
      files=mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,files=files,/last_version,/valid_only)
      s = {time:0d,vec:[0.,0.,0.]}
      str_all=0
      for i = 0, n_elements(files)-1 do begin
        file = files[i]
        dprint,dlevel=2,verbose=verbose,'Restoring '+file_info_string(file)
        restore,file,/verbose
        nt = n_elements(data.time.sec)
        time = replicate(time_struct(0.),nt)
        time.year = data.time.year
        time.month= 1
        time.date =  data.time.doy
        time.hour = data.time.hour
        time.min  = data.time.min
        time.sec  = data.time.sec
        time.fsec = data.time.msec/1000d
        strs = replicate(s,nt)
        strs.time = time_double(time)
        strs.vec[0] = data.ob_bpl.x
        strs.vec[1] = data.ob_bpl.y
        strs.vec[2] = data.ob_bpl.z
        append_array,str_all,strs,index=ind
      endfor
      append_array,str_all,index=ind
      frame = data.frame
      frame ='maven_spacecraft'
      if ~keyword_set(download_only) then store_data,'mvn_B_sav',str_all.time,transpose(str_all.vec),dlimit={spice_frame:frame}
      options,/def,'mvn_B_sav',level=level,labflag=-1,labels=['Bx','By','Bz'],colors='bgr',ysubtitle=level+' [nT]'
    end

    ;; Note: Can only Read STS Files Directly one file at a time.
    'L1_STS': begin
      pathname = 'maven/data/sci/mag/l1/YYYY/MM/mvn_mag_ql_YYYY*DOYpl_YYYYMMDD_v??_r??.sts'
      files=mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,files=files,/last_version,/valid_only)
      dprint,dlevel=2,verbose=verbose,'Reading '+file_info_string(files[0])
      data=mvn_mag_sts_read(files[0])
      if ~keyword_set(download_only) then store_data,'mvn_B_sts_L1',data.time,transpose(data.vec)
      options,/def,'mvn_B_sts_L1',level=level,labflag=-1,labels=['Bx','By','Bz'],colors='bgr',ysubtitle='[nT]'
    end

    'L2_STS': begin
      pathname = 'maven/data/sci/mag/l2/YYYY/MM/mvn_mag_l2_YYYYDOYpl' + onesec + '_YYYYMMDD_v??_r??.sts'
      files=mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,files=files,/last_version,/valid_only)
      dprint,dlevel=2,verbose=verbose,'Reading '+file_info_string(files[0])
      str_all=mvn_mag_sts_read(files[0])
      nn = n_elements(str_all.time)
      str_temp = replicate({time:0d, vec:[0.,0.,0.],range:0.},nn)
      tags = tag_names(str_all)
      tx = (where(tags eq xtag,cc1))[0]
      ty = (where(tags eq ytag))[0]
      tz = (where(tags eq ztag))[0]
      str_temp.time = str_all.time
      if (cc1 ne 0) then begin
        str_temp.vec[0] = str_all.(tx)
        str_temp.vec[1] = str_all.(ty)
        str_temp.vec[2] = str_all.(tz)
      endif else message,mag_product+' is not available.'
      str_all = 0
      str_all = str_temp
      str_temp = 0
      if ~keyword_set(download_only) then store_data,'mvn_B_sts_L2',str_all.time,transpose(str_all.vec)
      options,/def,'mvn_B_sts_L2',level=level,labflag=-1,labels=['Bx','By','Bz'],colors='bgr',ysubtitle='[nT]', $
                                  spice_frame='MAVEN_SPACECRAFT'
    end

    else: dprint,format+' Not found.'

  endcase

end