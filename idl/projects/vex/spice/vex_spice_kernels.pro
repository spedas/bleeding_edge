;+
;
;FUNCTION:        VEX_SPICE_KERNELS
;
;PURPOSE:         
;                 Provides VEX spice kernel filenames of specified types.
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
;NOTE:            This routine imitates 'mvn_spice_kernels' and 'mex_spice_kernels'.
; 
;CREATED BY:      Takuya Hara on 2016-07-12.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2019-10-08 07:47:37 -0700 (Tue, 08 Oct 2019) $
; $LastChangedRevision: 27829 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/vex/spice/vex_spice_kernels.pro $
;
;-
FUNCTION vex_spice_kernels, names, trange=trange, all=all, load=load,       $ 
                            reset=reset, verbose=verbose, source=source,    $
                            valid_only=valid_only, sck=sck, clear=clear,    $
                            no_update=no_update, last_version=last_version, $
                            no_download=no_download, no_server=no_server

  IF spice_test() EQ 0 THEN RETURN, ''

  IF N_ELEMENTS(last_version) EQ 0 THEN last_version = 1
  naif = spice_file_source(verbose=verbose, valid_only=valid_only, last_version=last_version, /preserve_mtime)
  
  IF KEYWORD_SET(sck) THEN names = ['STD', 'SCK']
  IF KEYWORD_SET(all) OR ~KEYWORD_SET(names) THEN $
     names = ['STD', 'SCK', 'FRM', 'IK', 'SPK', 'CK']
  IF KEYWORD_SET(reset) THEN kernels = 0

  tr = timerange(trange)
  time = time_intervals(trange=tr, /monthly)
  time = time_struct(time)
  months = time.month + 12 * (time.year - 1970)
  months = minmax(months) + [-1, 2]     ; -1 & +2 month buffers
  time = REPLICATE(time_struct(0.d0), 2)
  time.month = months
  time = time_double(time)

  IF ~KEYWORD_SET(source) THEN source = naif
  IF KEYWORD_SET(no_download) OR KEYWORD_SET(no_server) THEN source.no_server = 1
  IF KEYWORD_SET(verbose) THEN source.verbose = verbose
  kernels = ''

  FOR i=0, N_ELEMENTS(names)-1 DO BEGIN
     CASE STRUPCASE(names[i]) OF
        'STD': $
           append_array, kernels, spice_standard_kernels(source=source, no_update=no_update)
        
        'LSK': append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'generic_kernels/lsk/naif00??.tls', $
                                                        local_path=source.local_data_dir+'generic_kernels/lsk/', no_update=no_update, $
                                                        last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
        'SCK': $                ; Spacecraft time
           append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'VEX/kernels/sclk/VEX_*_STEP.TSC', $
                                                    local_path=source.local_data_dir+'VEX/kernels/sclk/', no_update=no_update, $
                                                    last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
        'FRM': BEGIN            ; Frame kernels
           append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'VEX/kernels/fk/VEX_V*.TF', $
                                                    local_path=source.local_data_dir+'VEX/kernels/fk/', no_update=no_update, $
                                                    last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
           append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'VEX/kernels/fk/RSSD0002.TF', $
                                                    local_path=source.local_data_dir+'VEX/kernels/fk/', no_update=no_update, $
                                                    last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
        END 
        'IK': $                 ; Instrument kernels
           append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir+'VEX/kernels/ik/VEX_ASPERA*_V*.TI', $
                                                    local_path=source.local_data_dir+'VEX/kernels/ik/', no_update=no_update, $
                                                    last_version=last_version, no_server=source.no_server, file_mode='666'o, dir_mode='777'o)
 
        'SPK': BEGIN            ; Spacecraft position
           spfile = 'kernels/spk/ORVV__' + time_intervals(trange=time, /daily_res, tformat='yyMMDD') + '*_*.BSP'
           append_array, kernels, spd_download_plus(remote_file=source.remote_data_dir + 'VEX/' + spfile, /valid_only, $ 
                                                    local_path=source.local_data_dir + 'VEX/kernels/spk/', no_update=no_update, $
                                                    no_server=source.no_server, file_mode='666'o, dir_mode='777'o, last_version=last_version)

        END 
        'CK': BEGIN
           cfile = 'kernels/ck/ATPV_P*_' + time_intervals(trange=time, /daily_res, tformat='yyMMDD') + '_*.BC'
           ck = spd_download(remote_file=source.remote_data_dir + 'VEX/' + cfile, /valid_only, $ 
                             local_path=source.local_data_dir + 'VEX/kernels/ck/', no_update=no_update, $
                             no_server=source.no_server, file_mode='666'o, dir_mode='777'o, last_version=last_version)
           w = WHERE(STRPOS(ck, '*') EQ -1, nw)
           IF nw GT 0 THEN append_array, kernels, ck[w]
        END 
        ELSE: dprint, STRUPCASE(names[i]) + ' has not been adopted yet.', dlevel=1, verbose=verbose
     ENDCASE 
  ENDFOR
  
  IF keyword_set(clear) THEN cspice_kclear
  IF keyword_set(load) THEN spice_kernel_load, kernels
  RETURN, kernels
END 
