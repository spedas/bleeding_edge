FUNCTION sppeva_load_wind, param, perror
  compile_opt idl2

  ;-------------
  ; CATCH ERROR
  ;-------------
  catch, error_status; !ERROR_STATE is set
  if error_status ne 0 then begin
    ;catch, /cancel; Disable the catch system
    eva_error_message, error_status
    msg = [!Error_State.MSG,' ','...EVA will igonore this error.']
    if ~keyword_set(no_gui) then begin
      ok = dialog_message(msg,/center,/error)
    endif
    message, /reset; Clear !ERROR_STATE
    return, pcode
  endif

  ;------------
  ; MFI
  ;------------  
  pcode=1000
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'wi_h0_mfi_*') and (cp eq 0))then begin
    wi_mfi_load, datatype = 'h0'
    options, 'wi_h0_mfi_B3GSE', constant=0, labflag=-1
  endif

  ;-------------
  ; 3DP PM
  ;-------------
  pcode=1001
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'wi_3dp_pm_*') and (cp eq 0))then begin
    wi_3dp_load,datatype='pm'; spin resolution ion data:    (please note that the 3DP densities are too low)
    options,'wi_3dp_pm_P_VELS',constant=0,labflag=-1,labels=['Vx','Vy','Vz'],colors=[2,4,6]
  endif

  ;-------------
  ; 3DP ELPD
  ;-------------
  pcode=1002
  ip=where(perror eq pcode,cp)
  if(strmatch(param,'wi_3dp_elpd_*') and (cp eq 0))then begin
    wi_3dp_load,datatype='elpd_old'; electron pitch angle distributions
    ;reduce_pads,'wi_3dp_elpd_FLUX',1,5,5      ; Reduces 3d data to 2d spectrogram (5th energy step)
  endif
  
  return, -1
END
