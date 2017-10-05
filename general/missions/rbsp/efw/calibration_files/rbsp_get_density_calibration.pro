;+
; NAME: rbsp_get_density_calibration
; SYNTAX: rbsp_get_density_calibration,'a'
; PURPOSE: Returns a structure with the RBSP density calibrations. 
; INPUT: 
; OUTPUT: Fit parameters for calculating density from RBSPa spacecraft
; potential "v". Form is A*exp(B*v) + C*exp(D*v)
; KEYWORDS: 
; HISTORY: Written by AWB at the UMN, May, 2015
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2016-05-12 12:20:43 -0700 (Thu, 12 May 2016) $
;   $LastChangedRevision: 21062 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/calibration_files/rbsp_get_density_calibration.pro $
;-


function rbsp_get_density_calibration,sc


  rbsp_efw_init
  cal_file = 'rbsp'+sc+'_density_calibrations.txt'

  ;; Extract folder with density calibrations
  filepath = routine_filepath()
  ending = strmid(filepath,31,/reverse_offset)
  goo = strpos(filepath,ending)
  filepath = strmid(filepath,0,goo)



  ;; get path for calibration file
  openr,lun,filepath + cal_file,/get_lun
  jnk = ''
  for i=0,3 do readf,lun,jnk

  i=0L
  vals = ''
  while not eof(lun) do begin   $
     readf,lun,jnk  & $
     vals = [vals,jnk] & $
     i++
  endwhile
  close,lun
  free_lun,lun

  nelem = n_elements(vals)
  vals = vals[1:nelem-1]

  ;;define variables to be read in
  t0 = strarr(nelem)
  t1 = strarr(nelem)
  bp = strarr(nelem)
  A = fltarr(nelem)
  B = fltarr(nelem)
  C = fltarr(nelem)
  D = fltarr(nelem)

  for i=0L,n_elements(vals)-1 do begin   ;$ 
     tmp = strsplit(vals[i],/extract)   ;& $
     t0[i] = tmp[0]   ;& $
     t1[i] = tmp[1]   ;& $
     bp[i] = tmp[2]   ;& $
     A[i] = float(tmp[3])   ;& $
     B[i] = float(tmp[4])   ;& $
     C[i] = float(tmp[5])   ;& $
     D[i] = float(tmp[6])
  endfor


  return,{t0:t0,t1:t1,bp:bp,A:A,B:B,C:C,D:D}

end


