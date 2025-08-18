pro eva_sitl_copy_fomstr_update, prb
  compile_opt idl2
  ; Get FOMstr
  get_data, 'mms_stlm_fomstr', data = D, lim = lim, dl = dl
  s = lim.unix_fomstr_mod
  tfom = eva_sitl_tfom(s)

  ; a plain clean selection with no segment
  newSEGLENGTHS = 0l
  newSOURCEID = ' '
  newSTART = 0l
  newSTOP = 0l
  newFOM = 0.
  newDISCUSSION = ' '
  newISPENDING = 1l
  newOBSSET = 15b

  ; Scan all segments
  nmax = s.nsegs
  for n = 0, nmax - 1 do begin
    prb_selected = eva_obsset_byte2bitarray(s.obsset[n])
    SELECTED = prb_selected[prb - 1]
    if SELECTED then begin
      newSEGLENGTHS = [newSEGLENGTHS, s.seglengths[n]]
      newFOM = [newFOM, s.fom[n]]
      newSOURCEID = [newSOURCEID, s.sourceid[n]]
      newSTART = [newSTART, s.start[n]]
      newSTOP = [newSTOP, s.stop[n]]
      newDISCUSSION = [newDISCUSSION, s.discussion[n]]
      newOBSSET = [newOBSSET, s.obsset[n]]
    endif
  endfor

  ; update FOM structure
  nmax = n_elements(newFOM)
  newNsegs = nmax - 1
  if newNsegs ge 1 then begin
    str_element, /add, s, 'SEGLENGTHS', long(newSEGLENGTHS[1 : nmax - 1])
    str_element, /add, s, 'SOURCEID', newSOURCEID[1 : nmax - 1]
    str_element, /add, s, 'START', long(newSTART[1 : nmax - 1])
    str_element, /add, s, 'STOP', long(newSTOP[1 : nmax - 1])
    str_element, /add, s, 'FOM', float(newFOM[1 : nmax - 1])
    str_element, /add, s, 'NSEGS', long(newNsegs)
    str_element, /add, s, 'NBUFFS', long(total(newSEGLENGTHS[1 : nmax - 1]))
    str_element, /add, s, 'DISCUSSION', newDISCUSSION[1 : nmax - 1]
    str_element, /add, s, 'OBSSET', byte(newOBSSET[1 : nmax - 1])
    s = eva_sitl_strct_sort(s)
    D = eva_sitl_strct_read(s, tfom[0])
    sprb = strtrim(prb, 2)
    case sprb of
      '1': pcolor = 0 ; black
      '2': pcolor = 6 ; red
      '3': pcolor = 4 ; green
      '4': pcolor = 2 ; blue
      else: pcolor = 0
    endcase
    str_element, /add, dl, 'COLORS', pcolor
    store_data, 'mms' + sprb + '_stlm_fomstr', data = D, lim = lim, dl = dl ; update data points
    options, 'mms' + sprb + '_stlm_fomstr', 'ytitle', 'mms' + sprb + '!CFOM'
    options, 'mms' + sprb + '_stlm_fomstr', thick = 1.0
  endif
end

;+
; :NAME:
;   eva_sitl_copy_fomstr
;
; :PURPOSE:
;   To make a FOMstr tplot-varible for individuatl spacecraft.
;
; :INPUT:
;   None, but "mms_stlm_fomstr" must exists.
;
; :VERSION:
;   $LastChangedBy: moka $
;   $LastChangedDate: 2024-08-19 11:26:30 -0700 (Mon, 19 Aug 2024) $
;   $LastChangedRevision: 32794 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_copy_fomstr.pro $
;-
pro eva_sitl_copy_fomstr
  compile_opt idl2

  tn = tnames('mms_stlm_fomstr', ct)
  if (ct eq 0) then begin
    message, 'mms_stlm_fomstr not found (eva_sitl_copy_fomstr)'
  endif

  eva_sitl_copy_fomstr_update, 1
  eva_sitl_copy_fomstr_update, 2
  eva_sitl_copy_fomstr_update, 3
  eva_sitl_copy_fomstr_update, 4

  options, 'mms_stlm_fomstr', thick = 2.0
end