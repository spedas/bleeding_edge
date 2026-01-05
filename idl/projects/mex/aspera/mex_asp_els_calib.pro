;+
;
;PROCEDURE:       MEX_ASP_ELS_CALIB
;
;PURPOSE:         
;                 Reads MEX/ASPERA-3 (ELS) calibration table.
;
;INPUTS:          
;
;KEYWORDS:
;
;CREATED BY:      Takuya Hara on 2018-01-29.
;
;LAST MODIFICATION:
; $LastChangedBy: jwl $
; $LastChangedDate: 2026-01-01 12:17:28 -0800 (Thu, 01 Jan 2026) $
; $LastChangedRevision: 33942 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mex/aspera/mex_asp_els_calib.pro $
;
;-
PRO mex_asp_els_calib, data, verbose=verbose
  ldir = root_data_dir() + 'mex/aspera/els/calib/'
  file_mkdir2, ldir
     
  pdir = 'MEX-M-ASPERA3-2-EDR-ELS-V1.0/'
  rpath = 'https://archives.esac.esa.int/psa/ftp/MARS-EXPRESS/ASPERA-3/' + pdir + 'CALIB/'
  rfile = 'ELSSCIH_CAL.TAB'
  append_array, file, FILE_SEARCH(ldir, rfile, count=nfile)
  IF nfile EQ 0 THEN file[-1] = spd_download(remote_path=rpath, remote_file=rfile, local_path=ldir, ftp_connection_mode=0) 

  dprint, dlevel=2, verbose=verbose, 'Reading ' + file + '.'
  OPENR, unit, file, /get_lun
  data = STRARR(FILE_LINES(file))
  READF, unit, data
  FREE_LUN, unit

  FOR i=0, N_ELEMENTS(data)-1 DO append_array, calib, STRMID(data[i], 19)
  calib = STRSPLIT(calib, /extract)
  calib = calib.toarray()

  undefine, data
  
  kf   = DOUBLE(REFORM(calib[*, 0]))    ; k-factor
  er   = DOUBLE(REFORM(calib[*, 1:11])) ; relative efficiency cofficients
  ea   = DOUBLE(REFORM(calib[*, 12]))   ; absolute efficiency
  gf   = DOUBLE(REFORM(calib[*, 13]))   ; geometric factor (cm^2 sr)
  mt   = DOUBLE(REFORM(calib[*, 14]))   ; MCP transparency
  grid = DOUBLE(REFORM(calib[*, 15]))   ; grid transparency
  aa   = DOUBLE(REFORM(calib[*, 16]))   ; active anode ratio
  dt   = DOUBLE(REFORM(calib[*, 17]))   ; delta time
  re   = DOUBLE(REFORM(calib[*, 18]))   ; resolution
  sf   = DOUBLE(REFORM(calib[*, 19]))   ; scailing factor

  data = {kf: kf, er: er, ea: ea, gf: gf, mt: mt, grid: grid, aa: aa, dt: dt, re: re, sf: sf}
  RETURN
END
