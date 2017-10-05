;+
; PRO asciidump_scan
;
; :Description:
;    Dump each scan data to each ascii file.
;
; :Params:
; tvars:  Name of tplot variable to be dumped. Only LOSV data (sd_???_vlos_?) is available.  
;
; :Keywords:
; dir: Directory path where the ascii files are created. (current directory is used unless dir is set) 
;
; :Examples:
;   asciidump_scan, 'sd_hok_vlos_1'
;   
; :History:
; 2014/01/06: Initial release
;
; :Author:
;   Tomo Hori (E-mail: horit at stelab.nagoya-u.ac.jp)
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2014-02-10 16:54:11 -0800 (Mon, 10 Feb 2014) $
; $LastChangedRevision: 14265 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/asciidump_scan.pro $
;-
pro asciidump_scan, tvars, dir=dir

  npar = n_params()
  if npar ne 1 then return  ;Exit unless only one argument is given.
  if strlen((tnames(tvars))[0]) lt 6 then return ;Exit if given tplot variable does not exist.
  
  ;Set the directory in which the dump files are generated.
  if ~keyword_set(dir) then dir = 'asciidump'
  if ~file_test(dir, /dir) then file_mkdir, dir
  cd, current=cwdir
  dirpath = filepath( dir, sub='', root_dir=cwdir )
  
  ;Get a scan structure of LOSV data
  tvar = tvars[0]
  scanarr = get_scan_struc_arr(tvar)
  dnum = n_elements(scanarr.x)
  
  ;Inisitalize the AACGM lib
  sd_init
  ts = time_struct( scanarr.x[0] )
  aacgmloadcoef, ts.year
  
  ;Variable names
  stn = strmid( strmid(tvar, 0,6), 3, 3 )
  prefix = 'sd_'+strlowcase(stn)+'_'
  suf = strmid(tvar, 0,1,/reverse)
  azmno_vn = prefix+'azim_no_'+suf
  ptbl_vn = prefix+ 'position_tbl_'+suf
  ctbl_vn = prefix+ 'positioncnt_tbl_'+suf
  
  ;Calculate the angle between the MLT direction and the beam direction.
  get_sd_vlshell, tvar, /angle_var
  angle_struc = get_scan_struc_arr( prefix+'mltdir-bmdir_angle_'+suf )
  
  ;Get the ionsopheric echo flag data
  iscat_flag_struc = get_scan_struc_arr( prefix+'echo_flag_'+suf )
  
  ;Get variable values
  get_data, azmno_vn, data=d
  azmno = d.y
  get_data, ptbl_vn, data= d
  ptbl = reform(d.y[0,*,*,*])
  get_data, ctbl_vn, data= d
  ctbl = reform(d.y[0,*,*,*])
  
  ;Number of range gate and beam
  nrang = n_elements(ctbl[*,0,0])
  azmmax = n_elements(ctbl[0,*,0] )
  
  glat = ctbl[*,*,1] & glon = ctbl[*,*,0]
  altarr = glat & altarr[*,*] = 400. ;[km]
  aacgmconvcoord, glat,glon,altarr, mlat,mlon,err,/TO_AACGM
  mlatarr = ( reform(mlat, 1,nrang,azmmax) )[ replicate(0,dnum), *, * ]
  mlonarr = ( reform(mlon, 1,nrang,azmmax) )[ replicate(0,dnum), *, * ]
  glatarr = ( reform(glat, 1,nrang,azmmax) )[ replicate(0,dnum), *, * ]
  glonarr = ( reform(glon, 1,nrang,azmmax) )[ replicate(0,dnum), *, * ]
  ts = time_struct(scanarr.x)
  year = ts.year
  yrsec = long( (ts.doy-1)*86400L + ts.sod )
  yeararr = long(mlonarr) & for i=0L,dnum-1 do yeararr[i,*,*]=year[i]
  yrsecarr = long(mlonarr) & for i=0L,dnum-1 do yrsecarr[i,*,*]=yrsec[i]
  mltarr = ( aacgmmlt( yeararr, yrsecarr, mlonarr ) + 24. ) mod 24.
  
  ;The loop for ascii-dumping the data for all time frames
  for n=0L, dnum-1 do begin
  
    time = scanarr.x[n]
    scan = reform( scanarr.y[n,*,*] )
    angle = reform( angle_struc.y[n,*,*] )
    glat = reform( glatarr[n,*,*] )
    glon = reform( glonarr[n,*,*] )
    mlat = reform( mlatarr[n,*,*] )
    mlt = reform( mltarr[n,*,*] )
    iscatflag = reform( iscat_flag_struc.y[n,*,*] )
    idx = where( abs(iscatflag) gt 1 or ~finite(iscatflag) ) & if idx[0] ne -1 then iscatflag[idx]=-1
    fn = tvar+'_'+time_string(time,tfor='YYYYMMDDhhmm')+'.dat'
    fpath = filepath( fn, sub='', root_dir=dirpath )
    openw, fp, fpath, /get_lun
    printf, fp, '# Radar code: ', stn
    printf, fp, '# Scan time (ave. time of beams for a scan): ', $
      time_string(time, tfor='YYYYMMDD hhmmss')
    printf, fp, '# iscat_flag  1:ionospheric echo,  0:ground scatter,  -1:no data'
    printf, fp, '###'
    printf, fp, '# beam  range_gate  LOSV[m/s]  iscat_flag  MLTdir-bmdir_angle[deg]  Glat[deg]  Glon[deg]  Mlat[deg]  MLT[hr]'
    for bm=0, n_elements(scan[0,*])-1 do begin
      for rg=0, n_elements(scan[*,0])-1 do begin
        printf, fp, bm, rg, scan[rg,bm], iscatflag[rg,bm], angle[rg,bm], glat[rg,bm], glon[rg,bm], $
          mlat[rg,bm], mlt[rg,bm], $
          format='(I2,1X,I3,1X,F7.1,1X,I2,1X,F7.2,1X,F5.1,1X,F6.1,1X,F5.1,1X,F5.2)'
      endfor
    endfor
    
    free_lun, fp
    
  endfor
  
  print, 'The ascii files have been generated in ',dirpath
  print, 'Program finished. '
  
  
  return
end
