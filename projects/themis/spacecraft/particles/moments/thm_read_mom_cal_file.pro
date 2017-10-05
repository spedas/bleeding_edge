;+
;NAME:
; thm_read_mom_cal_file
;PURPOSE:
; reads in the text version of the MOM cal
; file. tha_l1_mom_cal_v02.txt.
; Note that the cal file for THEMIS A is used for the data for all
; probes.
;CALLING SEQUENCE:
; caldata = thm_read_mom_cal_file(probe=probe)
;INPUT:
; all via keyword
;OUTPUT:
; caldata = a structure containing scalings for normal (mom_scale) and
;           solar wind (mom_scale_sw1) modes. Also contains a single
;           value used for scaling the spacecraft potential
;           (scpot_scale)
;KEYWORDS:
; probe = in here in case somebody decides to create a separate file
;         for each probe.
; cal_file = the name of the calibration file, output so that
;            thm_load_mom message doesn't crash
;HISTORY:
; 4-Oct-2010, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-27 11:26:29 -0700 (Mon, 27 Apr 2015) $
; $LastChangedRevision: 17433 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_read_mom_cal_file.pro $
;-
Function thm_read_mom_cal_file, cal_file = cal_file, probe = probe

  thm_init                      ;to be sure that !themis is defined
  caldata = -1
  thx = 'th'+probe
  calsource =  !themis
  calsource.ignore_filesize =  1
  cal_relpathname =  thx+'/l1/mom/0000/'+thx+'_l1_mom_cal_v03.txt'
  cal_file =  spd_download(remote_file=cal_relpathname,  _extra = calsource)
  If(file_test(cal_file)) Then Begin
    nlines = file_lines(cal_file)
    arrx = strarr(nlines)
    openr, unit, cal_file, /get_lun
    readf, unit, arrx
    free_lun, unit
    lll = where(strmid(arrx, 0, 1) Ne '#', nlll) ;get rid of comments
    If(nlll Eq 0) Then message, 'Bad moment cal file: ' + cal_file
    arrx = arrx[lll]
    nlines2 = (nlll-1)/2        ;should be 13
    mom_scale = dblarr(nlines2, 4)
    mom_scale_sw1 = mom_scale
    For j = 0, nlines2-1 Do Begin
      mom_scale[j, *] = double(strsplit(arrx[j], /extract))
      mom_scale_sw1[j, *] = double(strsplit(arrx[j+nlines2], /extract))
    Endfor
    scpot_scale = float(arrx[nlll-1])
    caldata = {mom_scale:mom_scale, mom_scale_sw1:mom_scale_sw1, $
               scpot_scale:scpot_scale}
  Endif Else message, 'No moment cal file: ' + cal_relpathname
  ;endelse
  Return, caldata
End


