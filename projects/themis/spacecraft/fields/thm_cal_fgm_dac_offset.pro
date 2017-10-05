;+
;procedure: thm_cal_fgm_dac_ffset
;
;Purpose:
;  Uses routine provided by Dragos Constanine to correct FGM offset from non-linearity of DAC(Digital Analog Converter)
;  Specific routine from Dragos: thm_fgm_find_shift_1p1c.pro
;  Calibration values from Dragos: thm_fgm_dac_corrections.dat
;  
;Inputs:
;
;  fgmdata: An Nx3 length array of fgm data in digital units.  fgmdata[*,0] = x,fgmdata[*,1] = y,fgmdata[*,2] = z
;  probe: The probe letter, as a string.
;  datatype: fgm data type can be (fgl,fge,fgh)
;  
;Outputs:
;  Mutates fgmdata in place.
;  error: Set to 1 if error occurs, 0 otherwise
;  
;Notes: This routine based largely upon routine fgm_correct_shift by Dragos Constantinescu
;  
;$LastChangedBy: nikos $
;$LastChangedDate: 2015-09-16 10:41:52 -0700 (Wed, 16 Sep 2015) $
;$LastChangedRevision: 18806 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_cal_fgm_dac_offset.pro $
;-
pro thm_cal_fgm_dac_offset,fgmdata,probe,datatype,error=error, calc_freq=calc_freq

  compile_opt idl2

  error = 1

  ;read parameters from file
  @thm_fgm_dac_corrections.dat
  
  dprint, dlevel=4,'Performing DAC offset correction probe: "' + probe + '" datatype: "' + datatype + '"'
  
  ;valid inputs
  probes = ['a','b','c','d','e']
  datatypes = ['fgl','fgh','fge']
  
  ;validate inputs
  pnum = where(strlowcase(probe) eq probes,c)
  
  if c ne 1 then begin
    dprint,'Error: Illegal probe:' + probe
    return
  endif
  
  dnum = where(strlowcase(datatype) eq datatypes,c)
  
  if c ne 1 then begin
    dprint,'WARNING: DAC offset conversion does not work on datatype: ' + datatype
    return
  endif
  
  dim = dimen(fgmdata)
  
  correction = dblarr(dim[0],3)
  
  for i = 0,2 do begin
  
    correction[*,i] = thm_fgm_find_shift_1p1c(fgmdata[*,i], threshold[pnum,i], $
                          th_slope[pnum,i], jump[pnum,i], datatype=datatypes[dnum], calc_freq=calc_freq, /fixed)     
  endfor
  
;  openw, 111, 'tmp_raw.dat'
;  printf, 111, transpose(fgmdata)
;  close, 111
  
  fgmdata += correction
  
;  openw, 112, 'tmp_dac.dat'
;  printf, 112, transpose(fgmdata)
;  close, 112

  
  
  error = 0

end
