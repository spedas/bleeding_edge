;+
;NAME:
;thm_cal_file2offset
;PURPOSE: 
;searches for the current calibration in ASCII file
;takes calibration data that brackets the input time range. If the
;time range is beyond the end of the file, then returns the data at
;the end of the file.
;CALLING SEQUENCE:
;thm_cal_file2offset, probe, time_range
;INPUT:
;probe = 'a', 'b', 'c', 'd', or 'e'
;time_range = the data time range
;OUTPUT:
;utc_out = time output unix time, N values
;utcstr_out = time string output
;off_out = Calibration offsets in DSL coordinate, 3xN
;cal_out = Cal quaternion matrix, 9xN
;spinper_out = spin period, N
;bz_slope_intercept_out = only nonzero for probe e, and only after April 2023 anomaly
;KEYWORDS:
;cal_file_in: A full path to the calibration file, for testing
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

Pro thm_cal_file2offset, probe_in, time_range, utc_out, utcstr_out, off_out, $
                         cal_out, spinper_out, bz_slope_intercept_out, $
                         cal_file_in=cal_file_in, _extra=_extra      

  compile_opt idl2

  thm_init
  ;Initialze output variables
  utci=-1 & utcstr=-1 & offi=-1 & cali=-1 & spinperi=-1 & bz_slope_intercept=-1
  ;check for valid probe
  vprobes = ['a', 'b', 'c', 'd', 'e']
  probe = ssl_check_valid_name(strlowcase(probe_in), vprobes)
  If(~keyword_set(probe)) Then Begin
     dprint, dlevel=0, 'BAD PROBE INPUT'
     Return
  Endif
  ;Get file
  thx = 'th' + probe
  If(keyword_set(cal_file_in)) Then cal_file = cal_file_in Else Begin
     cal_relpathname = thx+'/l1/fgm/0000/'+thx+'_fgmcal.txt'
     cal_file = spd_download(remote_file=cal_relpathname, _extra=!themis)
  Endelse
  files = file_search(cal_file,count=fc)
  If(fc Eq 0) Then Begin
     dprint, dlevel=0, 'FGM cal file not found: '
     dprint, dlevel=0, cal_file
     dprint, dlevel=0, 'FGM data for probe '+probe+' cannot be calibrated.'
     Return
  Endif
  If(n_params() Lt 2) Then Begin  
     dprint, dlevel=0, 'Input needs at least, probe and time_range'
     dprint, dlevel=0,  'Usage: thm_cal_file2offset, probe, time_range, utc, utcstr, offset,$'
     dprint, dlevel=0,  '                            cal, spinper, bz_slope_intercept, $'
     dprint, dlevel=0,  '                            cal_file_in=cal_file_in'
     Return
  Endif


;read the calibration file
  DPRINT, dlevel=4, 'read calibration file:'
  DPRINT, dlevel=4, cal_file

  ncal=file_lines(cal_file)
  calstr=strarr(ncal)
  openr, 2, cal_file
  readf, 2, calstr
  close, 2
  ok_cal = where(calstr Ne '', ncal) ;jmm, 8-nov-2007, cal files have carriage returns at the end
  calstr = calstr[ok_cal]

;define variables
  spinperi=dblarr(ncal)
  offi=dblarr(ncal,3)
  cali=dblarr(ncal,9)
  utci='2006-01-01T00:00:00.000Z'
  utc=dblarr(ncal)
  utcStr=strarr(ncal)

;THEMIS E has two extra columns as of 2024-04-24
  bz_slope_intercept = dblarr(ncal, 2)

  For i=0,ncal-1 Do Begin
     split_result = strsplit(calstr[i], COUNT=lct, /EXTRACT)
     If(lct Lt 14) Then Begin
        msg = 'Error in FGM cal file. Line: ' + string(i) + ", File: " + cal_file
        dprint, dlevel=0, msg
        Return
     Endif Else If(lct Gt 16) Then Begin
        msg = 'Unexpected elements in FGM cal file. Consider updating software, Line: ' $
              + string(i) + ", File: " + cal_file
        dprint, dlevel=0, msg
     Endif
     utci=split_result[0]
     offi[i,*]=split_result[1:3]
     cali[i,*]=split_result[4:12]
     spinperi[i]=split_result[13]
     utcStr[i]=utci
;translate time information
     STRPUT, utci, '/', 10
     utc[i]=time_double(utci)
     If(probe Eq 'e' And lct Ge 16) Then Begin
        bz_slope_intercept[i,*] = split_result[14:15]
     Endif
  Endfor

;for probe e, use the last value for intercept with zero slope if needed, jmm, 2024-05-25
  If(probe Eq 'e') Then Begin
     bz_last_time = utc[ncal-1] ;last time for nonzero slope                                                                           
     bz_ext_intercept = bz_slope_intercept[ncal-1,0]
  Endif

  DPRINT, dlevel=4, 'done reading calibration file'
  DPRINT, dlevel=4, 'search calibration for selected time interval ...'
  calIndex=0
  compTime=utc[0]
  refTime0=time_double(time_range[0])
  reftime1=time_double(time_range[1])
  i0 = value_locate(utc, reftime0) > 0
  i1 = value_locate(utc, reftime1)
  If(i1 Lt ncal-1) Then i1 = i1+1
  If(i0 Eq i1) Then Begin
     istart = i0-1
     istop = i1
  Endif Else Begin
     istart = i0
     istop = i1
  Endelse

  DPRINT, dlevel=4,  'Select calibrations from:'
  FOR i=istart,istop DO BEGIN
     DPRINT, dlevel=4,  utcStr[i]
  ENDFOR

  utc_out = utc[istart:istop]
  utcstr_out = utcstr[istart:istop]
  off_out = offi[istart:istop, *]
  cal_out = cali[istart:istop, *]
  spinper_out = spinperi[istart:istop]
  bz_slope_intercept = bz_slope_intercept[istart:istop,*]

End
