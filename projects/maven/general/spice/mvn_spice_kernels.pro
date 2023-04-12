;+
;NAME: MVN_SPICE_KERNELS
; function: mvn_spice_kernels(name)
;PURPOSE:
; Provides maven spice kernel filename of specified type
;  
;Typical CALLING SEQUENCE:
;  kernels=mvn_spice_kernel() 
;TYPICAL USAGE:
;INPUT:
;  string must be one of:    Not implemented yet.  currently retrieves ALL files
;KEYWORDS:
; LOAD:   Set keyword to also load file
; TRANGE:  Set keyword to UT timerange to provide range of needed files. 
; RECONSTRUCT: If set, then only kernels with reconstructed data (no predicts) are returned.
;OUTPUT:
; fully qualified kernel filename(s)
; 
;WARNING: Be very careful using this routine with the /LOAD keyword. It will change the loaded SPICE kernels that users typically assume are not being changed 
;PLEASE DO NOT USE this routine within general "LOAD" routines using the LOAD keyword. "LOAD" routines should assume that SPICE kernels are already loaded.
; 
;Author: Davin Larson  - January 2014
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-04-11 13:49:38 -0700 (Tue, 11 Apr 2023) $
; $LastChangedRevision: 31726 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/spice/mvn_spice_kernels.pro $
;-
function mvn_spice_kernels,names,trange=trange,all=all,load=load,reset=reset,verbose=verbose,source=source,valid_only=valid_only,sck=sck,clear=clear  $
  ,reconstruct=reconstruct,no_update=no_update,no_server=no_server,no_download=no_download,last_version=last_version

  ;common mvn_spice_kernels_com,   retrievetime,names_com,trange_com

  if spice_test() eq 0 then return,''
  retrievetime = systime(1)
  if n_elements(last_version) eq 0 then last_version =1

  tb = scope_traceback(/structure)
  this_dir = file_dirname(tb[n_elements(tb)-1].filename)+'/'   ; the directory this file resides in (determined at run time)

  naif = spice_file_source(valid_only=valid_only,verbose=verbose,last_version=last_version)
  ;   sprg = mvn_file_source()
  ;all=1
  if keyword_set(sck) then names = ['STD','SCK']
  if keyword_set(all) or not keyword_set(names) then names=['STD','SCK','FRM','IK','SPK','CK','CK_APP','CK_SWE']
  if keyword_set(reset) then kernels=0
  ct = systime(1)
  ;waittime = 10.                 ; search no more often than this number of seconds
  ;if 1 || ~keyword_set(kernels) || (ct - retrievetime) gt waittime then begin
  if ~keyword_set(source) then source = naif
  if keyword_set(no_download) or keyword_set(no_server) then source.no_server = 1
  dprint,dlevel=2,phelp=2,source
  kernels=''
  for i=0,n_elements(names)-1 do begin
     case strupcase(names[i]) of
        'STD':    begin
           append_array, kernels, spice_standard_kernels(source=source,/mars,no_update=no_update) ;  "Standard" kernels
        end
        ;swapped out file_retrieve calls for spd_download_plus for https access, 2017-01-30, jmm
        'CSS': append_array,kernels, spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/spk/comets/siding_spring_8-19-14.bsp', $
                                                  local_path = source.local_data_dir+'generic_kernels/spk/comets/', no_update = no_update, $
                                                  last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
        'LSK': append_array,kernels, spd_download_plus(remote_file = source.remote_data_dir+'generic_kernels/lsk/naif00??.tls', $
                                                  local_path = source.local_data_dir+'generic_kernels/lsk/', no_update = no_update, $
                                                  last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
        'SCK': append_array,kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/sclk/MVN_SCLKSCET.00???.tsc', $
                                                  local_path = source.local_data_dir+'MAVEN/kernels/sclk/', no_update = no_update, $
                                                  last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
        'FRM':    begin         ; Frame kernels
           if 0 then begin
              append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/fk/maven_v??.tf', $
                                                  local_path = source.local_data_dir+'MAVEN/kernels/fk/', no_update = no_update, $
                                                  last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
           endif else begin
              append_array, kernels, this_dir+'kernels/fk/maven_v11.tf'
           endelse
           append_array, kernels, this_dir+'kernels/fk/maven_misc.tf' ; Use this file to make temporary changes to the maven_v??.tf file
        end
        'IK':  begin          ; Instrument Kernels
        if 0 then begin
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_ant_v??.ti', $
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_euv_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_iuvs_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_lpw_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_mag_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_ngims_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_sep_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_static_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_swea_v??.ti',$
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
          append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ik/maven_swia_v??.ti', $
                                              local_path = source.local_data_dir+'MAVEN/kernels/ik/', no_update = no_update, $
                                              last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
        endif else begin
          append_array, kernels, this_dir+'kernels/ik/maven_ant_v10.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_euv_v10.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_iuvs_v10.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_lpw_v01.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_mag_v01.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_ngims_v10.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_sep_v12.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_static_v11.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_swea_v11.ti'
          append_array, kernels, this_dir+'kernels/ik/maven_swia_v10.ti'
        endelse
      end
      'SPK':  begin     ; Spacecraft position
         tr= timerange(trange)  ; + [-1,1] * 3600d*24
         if (tr[1] gt time_double('2013-11-18')) && (tr[0] le time_double('2014-09-23')) then begin
            append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/trj_c_131118-140923_rec_v?.bsp', $
                                                local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = no_update, $
                                                last_version = last_version, no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
         endif
;get 3 month time intervals
         ftimes = time_intervals(trange = ['2015-01-01', time_string(ct)], monthly_res = 3)
;prepend 2014-09-22, orbit insertion
         ftimes = [time_double('2014-09-22'), ftimes]
         nftimes = n_elements(ftimes)
         fstring = strmid(time_string(ftimes, tformat='YYYYMMDD'), 2)
         ffiles = 'MAVEN/kernels/spk/maven_orb_rec_'+fstring[0:nftimes-2]+'_'+fstring[1:*]+'_v?.bsp'
         for j = 0, nftimes-2 do begin
            if(tr[1] gt ftimes[j] && tr[0] le ftimes[j+1]) then begin 
               tmp_file = spd_download_plus(remote_file = source.remote_data_dir+ffiles[j], $
                                            local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = no_update, $
                                            no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
;There's a time lag (40 days or so) between the end time of a
;quarter and the appearance of the new file; so if tmp_file
;doesn't exist and j = nftimes-2, then replace it with the most recent file
               if(~keyword_set(tmp_file) && (j Eq nftimes-2)) then begin
                  if keyword_set(reconstruct) then begin
                     tmp_file = spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec.bsp', $
                                                  local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = 0, $
                                                  no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
                  endif else begin
                     tmp_file = [spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb.bsp', $
                                                   local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = 0, $
                                                   no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o), $
                                 spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec.bsp', $
                                                   local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = 0, $
                                                   no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)]
                  endelse
               endif
               append_array, kernels, tmp_file
            endif
         endfor
         if (tr[1] gt ftimes[nftimes-1] && tr[0] le time_double('2035-07-01')) then begin
            if keyword_set(reconstruct) then begin
               append_array,kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec.bsp', $
                                                       local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = 0, $
                                                       no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
            endif else begin
               append_array,kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb.bsp',$
                                                       local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = 0, $
                                                       no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
               append_array,kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/spk/maven_orb_rec.bsp',$
                                                       local_path = source.local_data_dir+'MAVEN/kernels/spk/', no_update = 0, $
                                                       no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
            endelse
         endif
      end
      'CK':  begin              ; Spacecraft Attitude  (CK)
        tr= timerange(trange)
        ; Get the Weekly files;
        att_weekly_format = 'MAVEN/kernels/ck/mvn_sc_rel_yyMMDD_??????_v??.bc'  ; use this line to get all files in time range
        att_weekly_kern = mvn_pfp_spd_download(att_weekly_format, source=source, trange=tr, daily_names=7, shift=4, /valid_only, /last_version)
        n_weekly = n_elements(att_weekly_kern) * keyword_set(att_weekly_kern)
        if n_weekly ge 1 then begin
          str = strmid(att_weekly_kern[n_weekly-1],/reverse_offset,12,6)
          tr[0] = time_double(str,tformat='yyMMDD') + 86400    ;
        endif
        ; Get Daily files to finish off
        att_daily_format = 'MAVEN/kernels/ck/mvn_sc_red_yyMMDD_v??.bc'  ; use this line to get all files in time range
        if tr[0] lt tr[1] then att_daily_kern = mvn_pfp_spd_download(att_daily_format, source=source, trange=tr, /valid_only, /daily_names, /last_version)
        n_daily = n_elements(att_daily_kern) * keyword_set(att_daily_kern)
        if n_daily ge 1 then begin
          str = strmid(att_daily_kern[n_daily-1],/reverse_offset,12,6)
          tr[0] = time_double(str,tformat='yyMMDD') + 86400+1   ;
        endif
        ; Daily quick files for most recent stuff
        if ~keyword_set(reconstruct) && (tr[0] le tr[1]) then begin
          att_quick_format = 'MAVEN/kernels/ck/mvn_sc_rec_yyMMDD_??????_v??.bc'  ; use this line to get all files in time range
          att_quick_kern = mvn_pfp_spd_download(att_quick_format, source=source, trange=tr, /daily_names, /last_version)    ;SC Attitude ???
        endif
        if keyword_set(att_quick_kern) then append_array, kernels, att_quick_kern
        if keyword_set(att_daily_kern) then append_array, kernels, att_daily_kern
        if keyword_set(att_weekly_kern) then append_array, kernels, att_weekly_kern
      end
      'CK_APP':  begin    ; APP Attitude (CK files)
        tr= timerange(trange)
        ; Start with the Weekly files;
        app_weekly_format = 'MAVEN/kernels/ck/mvn_app_rel_yyMMDD_??????_v??.bc'  ; use this line to get all files in time range
        app_weekly_kern = mvn_pfp_spd_download(app_weekly_format, source=source, trange=tr,daily_names=7,shift=4,/valid_only,/last_version)
        n_weekly = n_elements(app_weekly_kern) * keyword_set(app_weekly_kern)
        if n_weekly ge 1 then begin
          str = strmid(app_weekly_kern[n_weekly-1],/reverse_offset,12,6)
          tr[0] = time_double(str,tformat='yyMMDD') + 86400    ;
        endif
        ; Get Daily files to finish off
        app_daily_format = 'MAVEN/kernels/ck/mvn_app_red_yyMMDD_v??.bc'  ; use this line to get all files in time range
        if tr[0] lt tr[1] then app_daily_kern = mvn_pfp_spd_download(app_daily_format, source=source, trange=tr,/daily_names,/valid_only,/last_version)
        n_daily = n_elements(app_daily_kern) * keyword_set(app_daily_kern)
        if n_daily ge 1 then begin
          str = strmid(app_daily_kern[n_daily-1],/reverse_offset,12,6)
          tr[0] = time_double(str,tformat='yyMMDD') + 86400+1   ;
        endif
        ; Daily quick files for most recent stuff
        if ~keyword_set(reconstruct) && (tr[0] le tr[1]) then begin
          app_quick_format = 'MAVEN/kernels/ck/mvn_app_rec_yyMMDD_??????_v??.bc'  ; use this line to get all files in time range
          app_quick_kern = mvn_pfp_spd_download(app_quick_format, source=source, trange=tr+[-2,0]*86400L,/daily_names,/valid_only,/last_version)    ;SC Attitude ???
        endif
        if tr[1] lt time_double('14-10-9') then append_array,kernels, $
           spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/misc/app/mvn_app_nom_131118_141031_v1.bc', $
                             local_path = source.local_data_dir+'MAVEN/misc/app/', no_update = 0, $
                             no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
        if keyword_set(app_quick_kern) then append_array,kernels, app_quick_kern
        if keyword_set(app_daily_kern) then append_array,kernels, app_daily_kern
        if keyword_set(app_weekly_kern) then append_array,kernels, app_weekly_kern
        ;
        ;       tr= timerange(trange)
        ;
        ;
        ;       appformat = 'MAVEN/kernels/ck/mvn_app_rec_yyMMDD_*_v0?.bc'  ; use this line to get all files in time range
        ;       appkern = mvn_pfp_spd_download(appformat, source=source, trange=tr+[-2,1]*86400L,daily_names=1)   ;APP Attitude ???
        ;       append_array,kernels,  appkern  ;APP Attitude ???

      end
      'CK_SWE': append_array, kernels, spd_download_plus(remote_file = source.remote_data_dir+'MAVEN/kernels/ck/mvn_swea_nom_131118_300101_v??.bc',  $
                                                         local_path = source.local_data_dir+'MAVEN/kernels/ck/',no_update = 0, $
                                                         no_server = source.no_server, file_mode = '666'o, dir_mode = '777'o)
    endcase
  endfor
  ;    retrievetime = ct
  ;   kernels = file_search(kernels)
  ;endif

; Is the following code needed?  It converts linux forward slashes to windows backslashes.
;
;  if (strupcase(!version.os_family) eq 'WINDOWS') then begin
;    nker = n_elements(kernels)
;    for i=0,(nker-1) do $
;      kernels[i] = strjoin(strsplit(kernels[i], '/', /regex, /extract, /preserve_null), '\')
;  endif

  if keyword_set(clear) then cspice_kclear
  if keyword_set(load) then spice_kernel_load, kernels

  dprint,dlevel=2,verbose=verbose,'Time to retrieve SPICE kernels: '+strtrim(systime(1)-retrievetime,2)+ ' seconds'
  return,kernels

end
