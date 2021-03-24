;+
;Procedure MVN_MAG_LOAD
;Usage:
;  MVN_MAG_LOAD                            ; Load default
;  MVN_MAG_LOAD,'L1_FULL'                  ; load Full res sav files
;  MVN_MAG_LOAD,'L1_30SEC',trange=trange
;  MVN_MAG_LOAD,'L2_FULL'                  ; load Full res sav files
;  MVN_MAG_LOAD,'L2_30SEC',trange=trange
;
; Purpose:  Loads MAVEN mag data into tplot variables
;
; Author: Davin Larson and Roberto Livi
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-03-23 14:06:47 -0700 (Tue, 23 Mar 2021) $
; $LastChangedRevision: 29811 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_load.pro $

;-

;;1. ADD YTITLES SUCH AS:
;; options,'mvn_B_30sec',ytitle='L1 Mag Data (30sec)'


pro mvn_mag_load,format,$
                 trange        = trange,$
                 files         = files,$
                 download_only = download_only,$
                 tplot         = tplot_flag, $
                 format        = format_old, $
                 source        = source,$
                 verbose       = verbose,$
                 pathname      = pathname,$
                 data          = str_all,$
                 spice_frame   = spice_frame,$
                 timecrop      = timecrop,$
                 mag_product   = mag_product,$
                 sclk_ver      = sclk_ver, $
                 mag_frame     = mag_frame, $
                 l2only        = l2only
  

  dirr_l1='maven/data/sci/mag/l1/sav/'
  dirr_l2='maven/data/sci/mag/l2/sav/'

  ;;------------------------------------------------------
  ;; Check keywords
  if n_elements(tplot_flag) eq 0  then tplot_flag  = 1                
  if keyword_set(format_old)      then format      = format_old
  if size(format,/type) ne 7      then format      = 'L2_1SEC'
  if size(mag_product,/type) ne 7 then mag_product = 'MAG1'
  if size(mag_frame,/type) ne 7   then mag_frame   = 'pl'
  l1_ok = ~keyword_set(l2only)

  mag_frame = strlowcase(mag_frame[0])
  case mag_frame of
    'pl'  : frame = 'MAVEN_SPACECRAFT'
    'pc'  : frame = 'IAU_MARS'
    'ss'  : frame = 'MAVEN_SSO'
    else  : begin
              print, ' '
              print, '*****************************************'
              print, 'ERROR: Unrecognized MAG frame: ' + mag_frame
              print, 'Must be one of: pl, pc, or ss.'
              print, '*****************************************'
              print, ' '
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
               print, ' '
               print, '*****************************************'
               print, 'ERROR: Unrecognized MAG product: ' + mag_product
               print, 'Must be either MAG1 or MAG2.'
               print, '*****************************************'
               print, ' '
               return
             end
  endcase

; MAG structure tag names do not have a consistent format

  if (mag_frame eq 'pl') then ff = 'PL' else ff = ''
  xtag = mprod + '_B' + ff + '_X'
  ytag = mprod + '_B' + ff + '_Y'
  ztag = mprod + '_B' + ff + '_Z'

  sclk_ver = [-1]


  ;;------------------------------------------------------
  ;; Select format
  case strupcase(format) of      



     ;;;============================================
     ;;; LEVEL 2 DATA
     ;;;============================================

     ;;-------------------
     ;; Full Resolution
     'L2_FULL': begin
        pathname = dirr_l2+'full/YYYY/MM/mvn_mag_l2_'+mag_frame+'_full_YYYYMMDD.sav'
        ;;Check if files exist
        file_exist = mvn_pfp_file_retrieve($
                     pathname,$
                     trange = trange,$
                     /daily_names, /verbose)
        finfo=file_info(file_exist) 
        indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
        if nfiles eq 0 then begin
           print, ' '
           print, '*****************************************'
           print, 'L2_FULL files not available!'
           if (l1_ok) then begin
             print, 'Looking for L1_FULL files ...'
             print, '*****************************************'
             print, ' '
             goto, L1_FULL
           endif else begin
             print, 'L2ONLY is set --> ABORT!'
             print, '*****************************************'
             print, ' '
             return
           endelse
        endif
        files    = mvn_pfp_file_retrieve($
                   pathname,$
                   trange      = trange,$
                   source      = source,$
                   verbose     = verbose,$
                   /daily,$
                   /valid_only)
        nfiles   = n_elements(files) * keyword_set(files)
        if nfiles eq 0 || keyword_set(download_only) then break
        str_all=0
        ind=0
        for i = 0, nfiles-1 do begin
           file = files[i]
           dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
           restore,file,verbose= keyword_set(verbose) && verbose ge 3
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

        ;;-----------------------------------------
        ;; Crop save file according to trange
        if keyword_set(timecrop) then begin           
           if ~keyword_set(trange) then trange = timerange()
           pp = where(str_all.time ge trange[0] and $
                      str_all.time le trange[1],cc)
           if cc ne 0 then str_all=str_all[pp]
        endif

        ;;-----------------------------------------
        ;; Select data product to plot
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
        endif else stop, mag_product+' is not available.'
        str_all = 0
        str_all = str_temp
        str_temp = 0
        ;; frame = header.spice_frame                 
        ;; Not all files are consistent yet.
        ;; frame ='MAVEN_SPACECRAFT' ; this is now defined above


        ;;-----------------------------------------
        ;; TPLOT
        if keyword_set(tplot_flag) then begin
           store_data,'mvn_B_full',$
                      str_all.time,$
                      transpose(str_all.vec),$
                      dlimit={spice_frame:frame, sclk_ver:sclk_ver},$
                      limit={level:'L2'}
           options, 'mvn_B_full', ytitle='L2 [Full] Mag [nT]',/def
        endif




        if (size(spice_frame,/type) eq 7) then begin
           from_frame = frame
           to_frame   = mvn_frame_name(spice_frame[0], success=ok)
           if (ok) then begin
             utc        = time_string(str_all.time)
             new_vec    = spice_vector_rotate($
                          str_all.vec,$
                          utc,$
                          from_frame,$
                          to_frame,$
                          check_objects='MAVEN_SPACECRAFT')
             store_data,'mvn_B_full_'+to_frame,$
                        str_all.time,$
                        transpose(new_vec),$
                        dlimit={spice_frame:to_frame, sclk_ver:sclk_ver},$
                        limit={level:'L2'}
           endif
        endif
     end


     ;;-------------------------------
     ;; Level 2: 30 Second Resolution     
     'L2_30SEC': begin
        pathname = dirr_l2+'30sec/YYYY/MM/mvn_mag_l2_'+mag_frame+'_30sec_YYYYMMDD.sav'
        file_exist = mvn_pfp_file_retrieve($
                     pathname,$
                     trange = trange,$
                     /daily_names, /verbose)
        finfo=file_info(file_exist) 
        indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
        if nfiles eq 0 then begin
           print, ' '
           print, '*****************************************'
           print, 'L2_30SEC files not available!'
           if (l1_ok) then begin
             print, 'Looking for L1_30SEC files ...'
             print, '*****************************************'
             print, ' '
             goto, L1_30SEC
           endif else begin
             print, 'L2ONLY is set --> ABORT!'
             print, '*****************************************'
             print, ' '
             return
           endelse
        endif
        files    = mvn_pfp_file_retrieve($
                   pathname,$
                   /daily,$
                   trange=trange,$
                   source=source,$
                   verbose=verbose,$
                   /valid_only)
        nfiles   = n_elements(files) * keyword_set(files)
        if nfiles eq 0 ||  keyword_set(download_only) then break
        str_all=0
        ind=0
        for i = 0, nfiles-1 do begin
           file = files[i]
           dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
           restore,file,verbose= keyword_set(verbose) && verbose ge 3
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

        ;;-----------------------------------------
        ;; Crop save file according to trange
        if keyword_set(timecrop) then begin           
           if ~keyword_set(trange) then trange = timerange()
           pp = where(str_all.time ge trange[0] and $
                      str_all.time le trange[1],cc)
           if cc ne 0 then str_all=str_all[pp]
        endif

        ;;-----------------------------------------
        ;; Select data product to plot
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
        endif else stop, mag_product+' is not available.'
        str_all = 0
        str_all = str_temp
        str_temp = 0

        ;frame = header.spice_frame
        ;frame = 'MAVEN_SPACECRAFT' ; this is now defined above
        store_data,'mvn_B_30sec',$
                   str_all.time,$
                   transpose(str_all.vec),$
                   dlimit={spice_frame:frame, sclk_ver:sclk_ver},$
                   limit={level:'L2'}
        options, 'mvn_B_30sec', ytitle='L2 [30sec] Mag [nT]',/def
        if (size(spice_frame,/type) eq 7) then begin
           from_frame = frame
           to_frame   = mvn_frame_name(spice_frame[0], success=ok)
           if (ok) then begin
             utc=time_string(str_all.time)
             new_vec=spice_vector_rotate($
                     str_all.vec,$
                     utc,$
                     from_frame,$
                     to_frame,$
                     check_objects='MAVEN_SPACECRAFT')
             store_data,'mvn_B_30sec_'+to_frame,$
                        str_all.time,$
                        transpose(new_vec),$
                        dlimit={spice_frame:to_frame, sclk_ver:sclk_ver},$
                        limit={level:'L2'}
           endif
        endif
     end



     ;;-----------------------------
     ;; Level 2: 1 Second Resolution          
     'L2_1SEC': begin
        pathname = dirr_l2+'1sec/YYYY/MM/mvn_mag_l2_'+mag_frame+'_1sec_YYYYMMDD.sav'
        file_exist = mvn_pfp_file_retrieve($
                     pathname,$
                     trange = trange,$
                     /daily_names, /verbose)
        finfo=file_info(file_exist) 
        indx = where(finfo.exists, nfiles, comp=jndx, ncomp=n)
        if nfiles eq 0 then begin
           print, ' '
           print, '*****************************************'
           print, 'L2_1SEC files not available!'
           if (l1_ok) then begin
             print, 'Looking for L1_1SEC files ...'
             print, '*****************************************'
             print, ' '
             goto, L1_1SEC
           endif else begin
             print, 'L2ONLY is set --> ABORT!'
             print, '*****************************************'
             print, ' '
             return
           endelse
        endif
        files    = mvn_pfp_file_retrieve($
                   pathname,$
                   /daily,$
                   trange=trange,$
                   source=source,$
                   verbose=verbose,$
                   /valid_only)
        nfiles = n_elements(files) * keyword_set(files)
        if nfiles eq 0 || keyword_set(download_only) then break
        str_all=0
        ind=0
        for i = 0, nfiles-1 do begin
           file = files[i]
           dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
           restore,file,verbose= keyword_set(verbose) && verbose ge 3
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

        ;;-----------------------------------------
        ;; Crop save file according to trange
        if keyword_set(timecrop) then begin           
           if ~keyword_set(trange) then trange = timerange()
           pp = where(str_all.time ge trange[0] and $
                      str_all.time le trange[1],cc)
           if cc ne 0 then str_all=str_all[pp]
        endif

        ;;-----------------------------------------
        ;; Select data product to plot
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
        endif else stop, mag_product+' is not available.'
        str_all = 0
        str_all = str_temp
        str_temp = 0

        ;frame = header.spice_frame
        ;frame = 'MAVEN_SPACECRAFT' ; this is now defined above
        store_data,'mvn_B_1sec',$
                   str_all.time,$
                   transpose(str_all.vec),$
                   dlimit={spice_frame:frame, sclk_ver:sclk_ver},$
                   limit={level:'L2'}
        options, 'mvn_B_1sec', ytitle='L2 [1sec] Mag [nT]',/def
        if (size(spice_frame,/type) eq 7) then begin
           from_frame = frame
           to_frame   = mvn_frame_name(spice_frame[0], success=ok)
           if (ok) then begin
             utc=time_string(str_all.time)
             new_vec=spice_vector_rotate($
                     str_all.vec,$
                     utc,$
                     from_frame,$
                     to_frame,$
                     check_objects='MAVEN_SPACECRAFT')
             store_data,'mvn_B_1sec_'+to_frame,$
                        str_all.time,$
                        transpose(new_vec),$
                        dlimit={spice_frame:to_frame, sclk_ver:sclk_ver},$
                        limit={level:'L2'}
           endif
        endif
     end
     


     ;;---------------------------------------------------------------
     ;; Level 2: CDF
     'L2_CDF': begin
        pathname = 'maven/data/sci/mag/'+$
                   'l2_cdf/YYYY/MM/mvn_mag_ql_YYYYDOYpl_YYYYMMDD_v??_r??.cdf'
        files = mvn_pfp_file_retrieve($
                pathname,$
                /daily,$
                trange=trange,$
                source=source,$
                verbose=verbose,$
                files=files,$
                /last_version)
        cdf2tplot,files
     end
     
     

     ;;;============================================
     ;;; LEVEL 1 DATA
     ;;;============================================

     ;;-------------------
     ;; Full Resolution
     'L1_FULL': begin
        L1_FULL:
        print, ' '
        print, '*******************************************'
        print, 'WARNING: LEVEL 1 FORMAT'
        print, 'These data may not be used for publication.'
        print, '*******************************************'
        print, ' '
        pathname = dirr_l1+'full/YYYY/MM/mvn_mag_l1_'+mag_frame+'_full_YYYYMMDD.sav'
        files    = mvn_pfp_file_retrieve($
                   pathname,$
                   trange=trange,$
                   source=source,$
                   verbose=verbose,$
                   /daily,$
                   /valid_only)
        nfiles   = n_elements(files) * keyword_set(files)
        if nfiles eq 0 || keyword_set(download_only) then break
        str_all=0
        ind=0
        for i = 0, nfiles-1 do begin
           file = files[i]
           dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
           restore,file,verbose= keyword_set(verbose) && verbose ge 3
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

        ;;-----------------------------------------
        ;; Crop save file according to trange
        if keyword_set(timecrop) then begin           
           if ~keyword_set(trange) then trange = timerange()
           pp = where(str_all.time ge trange[0] and $
                      str_all.time le trange[1],cc)
           if cc ne 0 then str_all=str_all[pp]
        endif

        ;;-----------------------------------------
        ;; Check between new and old versions
        nn = n_elements(str_all.time)
        tags = tag_names(str_all)
        tx = (where(tags eq xtag,cc1))[0]
        ty = (where(tags eq ytag))[0]
        tz = (where(tags eq ztag))[0]
        pp2 = where(tag_names(str_all) eq 'VEC',cc2)
        if (cc1 ne 0) then begin
           str_temp = replicate({time:0d, vec:[0.,0.,0.],range:0.},nn)        
           str_temp.time = str_all.time
           str_temp.vec[0] = str_all.(tx)
           str_temp.vec[1] = str_all.(ty)
           str_temp.vec[2] = str_all.(tz)
           str_all = 0
           str_all = str_temp
           str_temp = 0
        endif 
        if cc1 eq 0 and cc2 eq 0 then begin
           print, 'L1 is not available.'
           return
        endif

        ;; frame = header.spice_frame                 
        ;;Not all files are consistent yet.
        ;; frame ='MAVEN_SPACECRAFT' ; this is now defined above
        if keyword_set(tplot_flag) then $
           store_data,'mvn_B_full',$
                      str_all.time,$
                      transpose(str_all.vec),$
                      dlimit = {spice_frame:frame, sclk_ver:sclk_ver},$
                      limit  = {level:'L1'}
        options, 'mvn_B_full', ytitle='L1 [Full] Mag [nT]',/def
        if (size(spice_frame,/type) eq 7) then begin
           from_frame = frame
           to_frame   = mvn_frame_name(spice_frame[0], success=ok)
           if (ok) then begin
             utc        = time_string(str_all.time)
             new_vec    = spice_vector_rotate($
                          str_all.vec,$
                          utc,$
                          from_frame,$
                          to_frame,$
                          check_objects='MAVEN_SPACECRAFT')
             store_data,'mvn_B_full_'+to_frame,$
                        str_all.time,$
                        transpose(new_vec),$
                        dlimit = {spice_frame:to_frame, sclk_ver:sclk_ver},$
                        limit  = {level:'L1'}
             options, 'mvn_B_full', ytitle='L1 [Full] Mag [nT]',/def
           endif
        endif
     end
     
     ;;-------------------------------
     ;; Level 1: 30 Second Resolution     
     'L1_30SEC': begin
        L1_30SEC:
        print, ' '
        print, '*******************************************'
        print, 'WARNING: LEVEL 1 FORMAT'
        print, 'These data may not be used for publication.'
        print, '*******************************************'
        print, ' '
        pathname = dirr_l1+'30sec/YYYY/MM/mvn_mag_l1_'+mag_frame+'_30sec_YYYYMMDD.sav'
        files    = mvn_pfp_file_retrieve($
                   pathname,$
                   /daily,$
                   trange=trange,$
                   source=source,$
                   verbose=verbose,$
                   /valid_only)
        nfiles   = n_elements(files) * keyword_set(files)
        if nfiles eq 0 ||  keyword_set(download_only) then break
        str_all=0
        ind=0
        for i = 0, nfiles-1 do begin
           file = files[i]
           dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
           restore,file,verbose= keyword_set(verbose) && verbose ge 3
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

        ;;-----------------------------------------
        ;; Crop save file according to trange
        if keyword_set(timecrop) then begin           
           if ~keyword_set(trange) then trange = timerange()
           pp = where(str_all.time ge trange[0] and $
                      str_all.time le trange[1],cc)
           if cc ne 0 then str_all=str_all[pp]
        endif

        ;;-----------------------------------------
        ;; Check between new and old versions
        nn = n_elements(str_all.time)
        tags = tag_names(str_all)
        tx = (where(tags eq xtag,cc1))[0]
        ty = (where(tags eq ytag))[0]
        tz = (where(tags eq ztag))[0]
        pp2 = where(tags eq 'VEC',cc2)
        if (cc1 ne 0) then begin
           str_temp = replicate({time:0d, vec:[0.,0.,0.],range:0.},nn)        
           str_temp.time = str_all.time
           str_temp.vec[0] = str_all.(tx)
           str_temp.vec[1] = str_all.(ty)
           str_temp.vec[2] = str_all.(tz)
           str_all = 0
           str_all = str_temp
           str_temp = 0
        endif 
        if cc1 eq 0 and cc2 eq 0 then begin
           print, 'L1 is not available.'
           return
        endif

        ;frame = header.spice_frame
        ;frame ='MAVEN_SPACECRAFT' ; this is now defined above
        store_data,'mvn_B_30sec',$
                   str_all.time,$
                   transpose(str_all.vec),$
                   dlimit = {spice_frame:frame, sclk_ver:sclk_ver},$
                   limit  = {level:'L1'}
        options, 'mvn_B_full', ytitle='L1 [30sec] Mag [nT]',/def
        ;store_data,'mvn_Brms_30sec',rms_all.time,transpose(rms_all.vec)
        if (size(spice_frame,/type) eq 7) then begin
           from_frame = frame
           to_frame   = mvn_frame_name(spice_frame[0], success=ok)
           if (ok) then begin
             utc=time_string(str_all.time)
             new_vec=spice_vector_rotate($
                     str_all.vec,$
                     utc,$
                     from_frame,$
                     to_frame,$
                     check_objects='MAVEN_SPACECRAFT')
             store_data,'mvn_B_30sec_'+to_frame,$
                        str_all.time,$
                        transpose(new_vec),$
                        dlimit = {spice_frame:to_frame, sclk_ver:sclk_ver},$
                        limit  = {level:'L1'}
             options, 'mvn_B_30sec', ytitle='L1 [30sec] Mag [nT]',/def
           endif
        endif
     end

     ;;-----------------------------
     ;; Level 1: 1 Second Resolution          
     'L1_1SEC': begin
        L1_1SEC:
        print, ' '
        print, '*******************************************'
        print, 'WARNING: LEVEL 1 FORMAT'
        print, 'These data may not be used for publication.'
        print, '*******************************************'
        print, ' '
        pathname = dirr_l1+'1sec/YYYY/MM/mvn_mag_l1_'+mag_frame+'_1sec_YYYYMMDD.sav'
        files    = mvn_pfp_file_retrieve($
                   pathname,$
                   /daily,$
                   trange=trange,$
                   source=source,$
                   verbose=verbose,$
                   /valid_only)
        nfiles = n_elements(files) * keyword_set(files)
        if nfiles eq 0 ||  keyword_set(download_only) then break
        str_all=0
        ind=0
        for i = 0, nfiles-1 do begin
           file = files[i]
           dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
           restore,file,verbose= keyword_set(verbose) && verbose ge 3
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

        ;;-----------------------------------------
        ;; Crop save file according to trange
        if keyword_set(timecrop) then begin           
           if ~keyword_set(trange) then trange = timerange()
           pp = where(str_all.time ge trange[0] and $
                      str_all.time le trange[1],cc)
           if cc ne 0 then str_all=str_all[pp]
        endif

        ;;-----------------------------------------
        ;; Check between new and old versions
        nn = n_elements(str_all.time)
        tags = tag_names(str_all)
        tx = (where(tags eq xtag,cc1))[0]
        ty = (where(tags eq ytag))[0]
        tz = (where(tags eq ztag))[0]
        pp2 = where(tag_names(str_all) eq 'VEC',cc2)
        if (cc1 ne 0) then begin
           str_temp = replicate({time:0d, vec:[0.,0.,0.],range:0.},nn)        
           str_temp.time = str_all.time
           str_temp.vec[0] = str_all.(tx)
           str_temp.vec[1] = str_all.(ty)
           str_temp.vec[2] = str_all.(tz)
           str_all = 0
           str_all = str_temp
           str_temp = 0
        endif 
        if cc1 eq 0 and cc2 eq 0 then begin
           print, 'L1 is not available.'
           return
        endif

        ;frame = header.spice_frame
        ;frame = 'MAVEN_SPACECRAFT' ; this is now defined above
        store_data,'mvn_B_1sec',$
                   str_all.time,$
                   transpose(str_all.vec),$
                   dlimit = {spice_frame:frame, sclk_ver:sclk_ver},$
                   limit  = {level:'L1'}
        options, 'mvn_B_1sec', ytitle='L1 [1sec] Mag [nT]',/def
        if (size(spice_frame,/type) eq 7) then begin
           from_frame = frame
           to_frame   = mvn_frame_name(spice_frame[0], success=ok)
           if (ok) then begin
             utc=time_string(str_all.time)
             new_vec=spice_vector_rotate($
                     str_all.vec,$
                     utc,$
                     from_frame,$
                     to_frame,$
                     check_objects='MAVEN_SPACECRAFT')
             store_data,'mvn_B_1sec_'+to_frame,$
                        str_all.time,$
                        transpose(new_vec),$
                        dlimit = {spice_frame:to_frame, sclk_ver:sclk_ver},$
                        limit  = {level:'L1'}
             options, 'mvn_B_1sec', ytitle='L1 [1sec] Mag [nT]',/def
           endif
        endif
     end
     
     



     ;;---------------------------------------------------------------
     ;; Old Full Resolution          
     ;; Older style save files. Bigger and  Slower to read in 
     'L1_SAV': begin   
        print, ' '
        print, '*******************************************'
        print, 'WARNING: LEVEL 1 FORMAT'
        print, 'These data may not be used for publication.'
        print, '*******************************************'
        print, ' '
        pathname = 'maven/data/sci/mag/'+$
                   'l1_sav/YYYY/MM/mvn_mag_ql_YYYY*DOYpl_YYYYMMDD_v??_r??.sav'
        files = mvn_pfp_file_retrieve($
                pathname,$
                /daily,$
                trange=trange,$
                source=source,$
                verbose=verbose,$
                /valid_only)
        s = {time:0d,vec:[0.,0.,0.]}
        str_all=0
        for i = 0, n_elements(files)-1 do begin
           file = files[i]
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
        store_data,'mvn_B',$
                   str_all.time,$
                   transpose(str_all.vec),$
                   dlimit={spice_frame:frame}
     end


     ;;---------------------------------------------------------------
     ;; Level 1: Read STS Files Directly    
     ;; Note: Can only read one file at a time.
     'L1_STS': begin
        print, ' '
        print, '*******************************************'
        print, 'WARNING: LEVEL 1 FORMAT'
        print, 'These data may not be used for publication.'
        print, '*******************************************'
        print, ' '
        pathname = 'maven/data/sci/mag/'+$ ;jmm, 2016-02-08
                   'l1/YYYY/MM/mvn_mag_ql_YYYY*DOYpl_YYYYMMDD_v??_r??.sts'
        files = mvn_pfp_file_retrieve($
                pathname,$
                /daily,$
                trange=trange,$
                source=source,$
                verbose=verbose,$
                files=files,$
                /last_version)
        if ~keyword_set(download_only) then $
           store_data,'mvn_B_sts',$
                      data=mvn_mag_sts_read(files[0]) 

     end














     ;;---------------------------------------------------------------
     ;; Nothing Found     
     else: begin
        dprint,format+'Not found.'
     end
     
  endcase
  
end






;;'http://sprg.ssl.berkeley.edu/data/'+$
;;'maven/data/sci/mag/l1/2014/11/mvn_mag_ql_2014d332pl_20141128_v00_r01.sts
