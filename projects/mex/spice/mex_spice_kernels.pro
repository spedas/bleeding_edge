;+
;
;FUNCTION:        MEX_SPICE_KERNELS
;
;PURPOSE:
;                 Provides MEX spice kernel filenames of specified types.
;
;INPUTS:          String array of kernel names to load.
;
;OUTPUTS:         Qualified kernel file name(s).
;
;KEYWORDS:       
;
;     LOAD:       Sets keyword to also load kernel files.
;
;   TRANGE:       Sets keyword to UT time range to provide range
;                 of needed files.
;
;NOTE:            This routine imitates 'mvn_spice_kernels'.
; 
;CREATED BY:      Takuya Hara on 2015-04-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2022-06-24 14:39:41 -0700 (Fri, 24 Jun 2022) $
; $LastChangedRevision: 30883 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/spice/mex_spice_kernels.pro $
;
;-
FUNCTION mex_spice_kernels, names, trange=trange, all=all, load=load,       $ 
                            reset=reset, verbose=verbose, source=source,    $
                            valid_only=valid_only, sck=sck, clear=clear,    $
                            no_update=no_update, last_version=last_version, $
                            no_download=no_download, no_server=no_server

  IF spice_test() EQ 0 THEN RETURN, ''
  
  IF N_ELEMENTS(last_version) EQ 0 THEN last_version = 1
  naif = spice_file_source(verbose=verbose, last_version=last_version, /preserve_mtime, valid_only=valid_only)
  
  IF KEYWORD_SET(sck) THEN names = ['STD', 'SCK']
  IF KEYWORD_SET(all) OR ~KEYWORD_SET(names) THEN $
     names = ['STD', 'SCK', 'FRM', 'IK', 'SPK', 'CK']
  IF KEYWORD_SET(reset) THEN kernels = 0

  IF ~KEYWORD_SET(source) THEN source = naif
  IF KEYWORD_SET(no_download) OR KEYWORD_SET(no_server) THEN source.no_server = 1
  IF KEYWORD_SET(verbose) THEN source.verbose = verbose
  
  tr = timerange(trange)
  time = time_intervals(trange=tr, /monthly)
  time = time_struct(time)  
  months = time.month + 12 * (time.year - 1970)
  months = minmax(months) + [-1, 2]     ; -1 & +2 month buffers
  time = REPLICATE(time_struct(0.d0), 2)
  time.month = months
  time = time_double(time)

  mk = spice_mk_read('MEX/kernels/mk/MEX_OPS.TM', remote=source.remote_data_dir, success=success)
  kernels = ''

  IF (success) THEN BEGIN
     other = WHERE((mk.contains('/ck/') EQ 0) AND (mk.contains('/spk/') EQ 0), nother)
     IF nother GT 0 THEN append_array, kernels, mk[other]
     
     wc = WHERE(mk.contains('/ck/') EQ 1, nc)
     IF nc GT 0 THEN BEGIN
        w = WHERE((mk[wc]).contains('MEX_SA') EQ 1, nw, comp=v, ncomp=nv)
        IF nv GT 0 THEN append_array, kernels, mk[wc[v]]
        IF nw GT 0 THEN BEGIN
           ck = FILE_BASENAME(mk[wc[w]])

           fname = time_intervals(tformat='MEX_SA_YYYY_', trange=tr, /yearly)
           FOR i=0, N_ELEMENTS(fname)-1 DO BEGIN
              bc = WHERE(ck.contains(fname[i]) EQ 1, nbc)
              IF nbc GT 0 THEN append_array, kernels, mk[wc[w[bc]]]
           ENDFOR

           fname = time_intervals(tformat='MEX_SA_yyMM01_', trange=tr, /monthly)
           FOR i=0, N_ELEMENTS(fname)-1 DO BEGIN
              bc = WHERE(ck.contains(fname[i]) EQ 1, nbc)
              IF nbc GT 0 THEN append_array, kernels, mk[wc[w[bc]]]
           ENDFOR
        ENDIF 
     ENDIF
     
     wsp = WHERE(mk.contains('/spk/') EQ 1, nsp)
     IF nsp GT 0 THEN BEGIN
        spk = mk[wsp]
        w = WHERE(spk.contains('ORMF_T19_') EQ 0, nw)
        IF nw GT 0 THEN spk = spk[w]
        w = WHERE(spk.contains('ORMM_T19_') EQ 1, nw, comp=v, ncomp=nv)
        IF nv GT 0 THEN append_array, kernels, spk[v]
        IF nw GT 0 THEN BEGIN
           fname = 'ORMM_T19_' + time_intervals(tformat='yyMM', trange=tr, /monthly)
           FOR i=0, N_ELEMENTS(fname)-1 DO BEGIN
              bsp = WHERE((spk[w]).contains(fname[i]) EQ 1, nbsp)
              IF nbsp GT 0 THEN append_array, kernels, spk[w[bsp]]
           ENDFOR
        ENDIF 
     ENDIF
     kernels = spd_download_plus(remote_file=kernels, local_file=kernels.replace(source.remote_data_dir, source.local_data_dir), $
                                 no_update=no_update, last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
  ENDIF ELSE BEGIN
     FOR i=0, N_ELEMENTS(names)-1 DO BEGIN
        CASE STRUPCASE(names[i]) OF
           'STD': $
              append_array, kernels, spice_standard_kernels(source=source, /mars, no_update=no_update)
           'LSK': $
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'generic_kernels/lsk/naif00??.tls', $
                                                       local_path=source.local_data_dir+'generic_kernels/lsk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
           'SCK': $             ; Spacecraft time
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/sclk/MEX_*_STEP.TSC', $
                                                       local_path=source.local_data_dir+'MEX/kernels/sclk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
           'FRM': BEGIN         ; Frame kernels
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/fk/MEX_V*.TF', $
                                                       local_path=source.local_data_dir+'MEX/kernels/fk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/fk/RSSD0002.TF', $
                                                       local_path=source.local_data_dir+'MEX/kernels/fk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
           END 
           'IK': $              ; Instrument kernels
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/ik/MEX_ASPERA_V*.TI', $
                                                       local_path=source.local_data_dir+'MEX/kernels/ik/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
           'SPK': BEGIN         ; Spacecraft position              
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/spk/MAR033_2000-2025.BSP', $
                                                       local_path=source.local_data_dir+'MEX/kernels/spk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/spk/MAR033_HRSC_V*BSP', $
                                                       local_path=source.local_data_dir+'MEX/kernels/spk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/spk/MEX_ASPERA_STRUCT_V*BSP', $
                                                       local_path=source.local_data_dir+'MEX/kernels/spk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              
              IF MAX(tr) LT time_double('2003-12-25/03:00') THEN BEGIN ; Cruise ephemeris kernel
                 append_array, kernels, spd_download_plus(remote_file=source.remote_date_dir+'MEX/kernels/spk/ORHM_*.BSP', $
                                                          local_path=source.local_data_dir+'MEX/kernels/spk/', no_update=no_update, $
                                                          last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              ENDIF
              
              spformat = 'kernels/spk/ORMM__'
              spfile = spformat + time_intervals(trange=time, /daily_res, tformat='yyMMDD') + '*_*.BSP'
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/'+spfile, $
                                                       local_path=source.local_data_dir+'MEX/kernels/spk/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
           END 
           'CK': BEGIN
              cfile = 'kernels/ck/ATNM_PTR*_' + time_intervals(trange=time, /daily_res, tformat='yyMMDD') + '*_*.BC'
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/'+cfile, $
                                                       local_path=source.local_data_dir+'MEX/kernels/ck/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              
              cfile = 'kernels/ck/ATNM_MEASURED_' + time_intervals(trange=time, /yearly_res, tformat='yy') + '*.BC'
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/'+cfile, $
                                                       local_path=source.local_data_dir+'MEX/kernels/ck/', no_update=no_update, $
                                                       no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/ck/ATNM_P0*_*.BC', $
                                                       local_path=source.local_data_dir+'MEX/kernels/ck/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/ck/ATNM_RECONSTITUTED_*.BC', $
                                                       local_path=source.local_data_dir+'MEX/kernels/ck/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
              append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'MEX/kernels/ck/MEX_ASPERA_SAF*.BC', $
                                                       local_path=source.local_data_dir+'MEX/kernels/ck/', no_update=no_update, $
                                                       last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
           END 
           ELSE: dprint, STRUPCASE(names[i]) + ' has not been adopted yet.', dlevel=1, verbose=verbose
        ENDCASE 
     ENDFOR 
  ENDELSE
  
  IF keyword_set(clear) THEN cspice_kclear
  IF keyword_set(load) THEN spice_kernel_load, kernels, info=info, maxiv=10000
  
  w = WHERE(info.type EQ 'CK', nw)
  IF nw GT 0 THEN BEGIN
     ck = info[w].filename
     ck = ck[UNIQ(ck)]
     FOR i=0, N_ELEMENTS(ck)-1 DO BEGIN
        v = WHERE(STRMATCH(info.filename, ck[i]) EQ 1)
        time = minmax(time_double(info[v].trange))
        IF (time[0] GT tr[1]) OR (time[1] LT tr[0]) THEN append_array, ck_unload, ck[i] ELSE append_array, ck_load, ck[i]
        append_array, ck_time, TRANSPOSE(time)
        undefine, v, time
     ENDFOR 

     IF SIZE(ck_load, /type) NE 0 THEN BEGIN
        v = WHERE(STRMATCH(ck_load, '*MEASURED*') EQ 1, nv)
        IF nv GT 0 THEN BEGIN
           w = WHERE(STRMATCH(ck_load, '*ATNM_PTR*') EQ 1, nw)
           FOR i=0, nv-1 DO BEGIN
              km = WHERE(ck EQ ck_load[v[i]])
              FOR j=0, nw-1 DO BEGIN
                 kp = WHERE(ck EQ ck_load[w[j]])
                 IF ck_time[kp, 0] GE ck_time[km, 0] AND ck_time[kp, 1] LE ck_time[km, 1] THEN append_array, ck_unload, ck_load[w[j]]
              ENDFOR 
           ENDFOR 
        ENDIF 
     ENDIF 
     
     IF SIZE(ck_unload, /type) NE 0 THEN spice_kernel_load, ck_unload, /unload, maxiv=10000
  ENDIF

  RETURN, kernels
END 
