;+
;
;PROCEDURE:       MEX_ORBIT_NUM
;
;PURPOSE:         Loads the data structure that contains orbit info.
;                 w.r.t. each MEX orbit from SPICE/kernels.
;
;INPUTS:          None.
;
;KEYWORDS:
;
;      DATA:      Returns the data structure.
;
;      TIME:      Rerurns the data structure whose format is identical
;                 to the IDL save file which I made manually. 
;
;PREDICTIVE:      If set, loading the long-term predictive orbit info file.
;
;CREATED BY:      Takuya Hara on 2017-04-12.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2023-11-09 16:57:40 -0800 (Thu, 09 Nov 2023) $
; $LastChangedRevision: 32227 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/spice/mex_orbit_num.pro $
;
;-
PRO mex_orbit_num, verbose=verbose, data=data, time=time, orbnum=orbnum, predictive=predictive
  COMMON mex_orbit_num_com, mex_orbit_num_data, mex_orbit_num_time, mex_orbit_num_file

  IF KEYWORD_SET(predictive) THEN rfile = 'ORMF_*.ORB' ELSE rfile = 'ORMM_MERGED_*.ORB'
  
  IF SIZE(mex_orbit_num_data, /type) EQ 8 THEN BEGIN
     data  = mex_orbit_num_data
     times = mex_orbit_num_time
  ENDIF ELSE BEGIN
     source = spice_file_source(verbose=verbose, /last_version, /valid_only)
     file = spd_download_plus(remote_file=source.remote_data_dir + 'MEX/kernels/orbnum/' + rfile, $
                              local_path=source.local_data_dir + 'MEX/kernels/orbnum/', no_server=0, /last_version, /valid_only, $
                              file_mode='666'o, dir_mode='777'o)

     IF file EQ '' THEN RETURN
     mex_orbit_num_file = file
     OPENR, unit, file, /get_lun
     adata = STRARR(FILE_LINES(file))
     READF, unit, adata
     FREE_LUN, unit

     adata = adata[2:-2]
     adata = STRSPLIT(adata, ' ', /extract)
     adata = TRANSPOSE(adata.toarray())

     nan = !values.f_nan
     dnan = !values.d_nan
     dformat = {orbit: 1L, peri_time: dnan, peri_met: dnan,  apo_time: dnan,  $
                sol_lon: nan, sol_lat: nan,  sc_lon: nan, sc_lat: nan,  alt: nan, $
                inc: nan, ecc: nan, lon_node: nan, arg_per: nan, sol_dist: dnan, semi_axis: dnan}
     
     ndat = N_ELEMENTS(adata[0, *])
     data = REPLICATE(dformat, ndat)
     times = DBLARR(4, ndat)

     data.orbit     = LONG(REFORM(adata[0, *]))
     data.peri_time = time_double(STRJOIN(adata[1:4, *], '-'), tformat='YYYY-MTH-DD-hh:mm:ss')
     data.peri_met  = DOUBLE(REFORM(STRMID(adata[5, *], 2)))
     data.apo_time  = time_double(STRJOIN(adata[6:9, *], '-'), tformat='YYYY-MTH-DD-hh:mm:ss')
     data.sol_lon   = FLOAT(REFORM(adata[10, *]))
     data.sol_lat   = FLOAT(REFORM(adata[11, *]))
     data.sc_lon    = FLOAT(REFORM(adata[12, *]))
     data.sc_lat    = FLOAT(REFORM(adata[13, *]))
     data.alt       = FLOAT(REFORM(adata[14, *]))
     data.inc       = FLOAT(REFORM(adata[15, *]))
     data.ecc       = FLOAT(REFORM(adata[16, *]))
     data.lon_node  = FLOAT(REFORM(adata[17, *]))
     data.arg_per   = FLOAT(REFORM(adata[18, *]))
     data.sol_dist  = DOUBLE(REFORM(adata[19, *]))
     data.semi_axis = DOUBLE(REFORM(adata[20, *]))

     mex_orbit_num_data = data
     
     times[0, *] = data.orbit
     times[1, 1:*] = data[0:ndat-2].apo_time
     times[2, *] = data.apo_time
     times[3, *] = data.peri_time
     
     mex_orbit_num_time = times
  ENDELSE
  
  IF ~undefined(time) THEN orbnum = INTERP(DOUBLE(mex_orbit_num_data.orbit), mex_orbit_num_data.peri_time, time_double(time)) ELSE time = times
  IF ~undefined(orbnum) THEN time = INTERP(mex_orbit_num_data.peri_time, DOUBLE(mex_orbit_num_data.orbit), DOUBLE(orbnum))
  
  RETURN
END
