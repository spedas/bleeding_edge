;+
;FUNCTION: THM_EFI_GET_POTENTIAL, Vname
;
;           NOT FOR GENERAL USE. CALLED BY THM_EFI...
;           ONLY FOR ISOLATED PARTICLE OR WAVE BURSTS
;           NOT FOR ENTIRE ORBIT.
;
;PURPOSE:
;    Remove SC potential from axial signal.
;
;INPUT:
;    Vname           TPLOT name of voltages.
;
;KEYWORDS:
;
;HISTORY:
;   2009-03-30: REE. 
;-

pro thm_efi_get_potential, Vname, trange=trange

; CHECK Vname
IF size(/type,Vname) ne 7 then BEGIN
  print, 'THM_EFI_GET_POTENTIAL: VNAME must be a string. Exiting...'
  return
ENDIF

; GET DATA
get_data, Vname, data = data, dlim=dlim
sc = strmid(Vname,2,1)

; CHECK
IF size(/type,data) NE 8 then BEGIN
  print, 'THM_EFI_GET_POTENTIAL: Vname is not valid. Fetching...'
  thm_load_efi, probe=sc, datatype=['vap'], coord='dsl', trange=trange
  vname = 'th' + sc + '_vap'
  get_data, vname, data = data, dlim = dlim
  IF size(/type,data) NE 8 then BEGIN
    print, 'THM_EFI_GET_POTENTIAL: Cannot get Voltage data. Exiting...'
    return
  ENDIF
ENDIF

; CALCULATE POTENTIAL
vsc = (data.y(*,0) + data.y(*,1) + data.y(*,2) + data.y(*,3))/4
sc = strmid(Vname,2,1)
new_name = 'th' + sc + '_vsc'
data = {X: data.x, Y: vsc}
dlim = {SPEC: 0b, LOG: 0b, YSUBTITLE: '(V)', $
  DATA_ATT: dlim.data_att, COLORS: [0], $
  LABELS: ['V!DSC!N'], LABFLAG: dlim.labflag, $
  YTITLE: 'SC POTENTIAL'}
store_data, new_name(0), data=data, dlim=dlim

print, 'THM_EFI_GET_POTENTIAL: POTENTIAL STORED AS - ', new_name
return
end
