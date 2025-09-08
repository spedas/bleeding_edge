;+
; PRO: THM_EFI_CLEAN_EFW
;
; PURPOSE:
;    FIXES HF, REMOVES SPIKES, AND LOW FREQUENCY.
;
;   This routine is designed for general use. It will take EFW data in
;   DSL as input, clean up the data, and transform the data into FAC, and return
;   the cleaned EFP data in DSL/FAC.
;
;   The routine can work on one-day long data, but if only a single particle
;   burst data is interesting, use the keyword TRANGE to specify the time range
;   of that burst can greatly reduce run time.
;
;   NOTE: 1) Spike removal does not always work, so don't be surprised if there
;         still are spikes left on the data. Hopefully the spike issue can be
;         resolved in the future.
;         2) Make sure thx_state_spinper is available! Best to set up for gsm.
;         Make sure timespan is set!!!!
;
; EXAMPLES:
;     For typical use, see thm_crib_cleanefw.pro and thm_crib_cleanefi.pro which
;     are typically located under TDAS_DIR/idl/themis/examples.
;
; INPUT:
;
; KEYWORDS (general):
;    probe          NEEDED: Program does only one sc at a time!
;    Ename          OPTIONAL: Valid TPLOT name for E WAVE, DEFAULT = 'thX_efw'
;                   (will fetch)
;    Bdslname       OPTIONAL, Valid TPLOT name for B, DEFAULT = 'thX_fgh_dsl'
;                   (will fetch)
;    trange         OPTIONAL. Time range.
;                   USE TRANGE TO ISOLATE SINGLE PARTICLE BURST AND GREATLY
;                   REDUCE RUN TIME!!!!
;    talk           OPTIONAL. Plots diagnostics. Can be fun. Slow. DEFAULT = 0
;    EfpName        OPTIONAL: Valid TPLOT name for EFP, DEFAULT = 'thX_efp'
;                   (will fetch)
;                   EFP is used to find spike positions.
;    status         OPTIONAL: A named variable to return the exiting status. If
;                    exit successfully, status = 0, otherwise status = 1
;    EFWHEDACNAME   OPTIONAL: Valid TPLOT name for the AC-coupled E-field header info
;                   DEFAULT = 'thX_efw_hed_ac'
;
; KEYWORDS (Filter):
;    FPole          (OBSOLETE) Kept for backward compatibility.
;
; KEYWORDS (for output tplot variables):
;    Edslname   OPTIONAL: Name for the cleaned efp in DSL.
;               DEFAULT = Ename + '_clean_dsl'
;    Efacname   OPTIONAL: Name for the cleaned efp in DSL.
;               DEFAULT = Ename + '_clean_fac'
;
; KEYWORDS (Remove_Spikes):
;    SpikeRemove    If entered as 0, suppresses spike removal.
;                   DEFAULT = 1 (Spikes are removed.)
;    SpikeNwin      Number of points in spike search window. DFLT = 16
;    SpikeSig       Sigma of spikes. DFLT = 5
;                   (Sometimes Sig = 6 works better)
;    SpikeSigmin    Minimun of sigma. DFLT = 0.01 mV/m.
;                   (Sometimes Sigmin = 0 works better)
;    SpikeNfit      Number of points in the fit window. DFLT = 16
;    SpikeFit       If set, will do a Gaussian fit to Spikes. DFLT = 0
;
; HISTORY:
;   2009-05-06: REE. First Release.
;   2009-06-04: Jianbao Tao (JBT), CU/LASP.
;               The metadata (dlim.data_att) is modified properly.
;   2009-06-17: JBT, CU/LASP.
;               Keyword STATUS added.
;   2010-04-08: JBT, CU/LASP.
;               The high-pass filter is changed from an FFT filter to an
;               FIR filter. Some modification is made to be compatible with
;               two different sample rates 8192 Hz and 16384 Hz.
;   2010-09-13: JBT, CU/LASP.
;               Cleaned up documents.
;               Added keyword dt in calling thm_efi_fix_freq_and_phase.
;   2012-07-26: JBT, SSL, UC Berkeley.
;               1. Incorporated C. Cully's calibration for
;                     1) Plasma-probe coupling
;                     2) Anti-aliasing Bessel filter
;                     3) ADC response
;                     4) DFB response
;   2012-08-30: CMC, University of Calgary.
;               Fixed problems with AC-coupled data sampled at < 16 ksps
;
; VERSION:
;
; $LastChangedBy $
; $LastChangedDate $
; $LastChangedRevision $
; $URL $
;
;-

pro thm_efi_clean_efw, probe=probe, Ename=Ename, Bdslname=Bdslname, $
        trange=trange, talk=talk, EfpName=EfpName, $       ; GENERAL
        FPole=FPole, $                                     ; FILTER
        EFWHEDACNAME=efwhedacname, $                    ; optional name for AC header info
        Edslname = Edslname, $                          ; OUTPUT NAME
        Efacname = Efacname, $                          ; OUTPUT NAME
        SpikeRemove=SpikeRemove, SpikeNwin=SpikeNwin, $    ; REMOVE_SPIKES
        SpikeSig=SpikeSig, SpikeSigmin=SpikeSigmin, $      ; REMOVE_SPIKES
        SpikeNfit=SpikeNfit, SpikeFit=SpikeFit, $          ; REMOVE_SPIKES
        diagnose=diagnose, wt=wt, $                        ; Programmer's use
        status = status

compile_opt idl2

status = 0

; # CHECK INPUTS - GET NEEDED DATA #
IF not keyword_set(probe) then BEGIN
  print, 'THM_EFI_CLEAN_EFW: SC not set. Exiting...'
  status = 1
  return
ENDIF
sc = probe[0]

; LOAD STATE
thm_load_state, probe = probe, /get_support, trange=trange

; SETDEFAULTS
if n_elements(FPole) EQ 0       then FPole       = 5.0D   ; FILTER
if n_elements(SpikeRemove) EQ 0 then SpikeRemove = 1      ; REMOVE_SPIKES
;if n_elements(SpikeNfit) EQ 0   then SpikeNfit   = 400L   ; REMOVE_SPIKES

; CHECK FOR EFW DATA
if not keyword_set(Ename) then Ename = 'th' + sc + '_efw'
IF spd_check_tvar(Ename) then BEGIN
  get_data, ename[0], data=E, dlim=elim
  if ~strcmp(elim.data_att.coord_sys, 'dsl', /fold) then begin
    print, 'THM_EFI_CLEAN_EFW: ' + ename[0] + ' is not in DSL. Exiting...'
    return
  endif
ENDIF ELSE BEGIN
  thm_load_efi, probe=sc, datatype=['efw', 'vaw'], coord='dsl', trange=trange, /get_support_data
  Ename = 'th' + sc + '_efw'
  get_data, ename[0], data=E, dlim=elim
  IF size(/type,E) NE 8 then BEGIN
    print, 'THM_EFI_CLEAN_EFW: Cannot get electric field data. Exiting...'
    status = 1
   return
  ENDIF
ENDELSE




; CHECK FOR MAG DATA
if not keyword_set(Bdslname) then Bdslname = 'th' + sc + '_fgh_dsl'
IF spd_check_tvar(Bdslname) then BEGIN
  get_data, Bdslname[0], data=Bdsl, dlim=blim
ENDIF ELSE BEGIN
  print, 'THM_EFI_CLEAN_EFP: Mag data not stored in dsl. Fetching...'
  thm_load_fgm, probe=sc, datatype = ['fgh'], coord=['dsl'], trange=trange, $
      level = 2
  Bdslname = 'th' + sc + '_fgh_dsl'
  get_data, Bdslname[0], data=Bdsl, dlim=blim
  IF size(/type,Bdsl) NE 8 then BEGIN
    print, 'THM_EFI_CLEAN_EFW: Cannot get MAG data. Exiting...'
    status = 1
    return
  ENDIF
ENDELSE
Bdsl = {x:Bdsl.x, y:Bdsl.y}

; CHECK FOR SPIN DATA
SpinName = 'th' + sc + '_state_spinper'
IF spd_check_tvar(Spinname) then BEGIN
 get_data, SpinName, data=SpinPer
ENDIF ELSE BEGIN
  thm_load_state, probe=sc, datatype='spinper'
  get_data, SpinName, data=SpinPer
  IF size(/type,SpinPer) NE 8 THEN BEGIN
    print, 'THM_EFI_CLEAN_EFW: Cannot get spin period. Exiting...'
    status = 1
    return
  ENDIF
ENDELSE

; GET EFP DATA FOR SPIKE FINDER
IF keyword_set(SpikeRemove) then BEGIN
  if not keyword_set(EfpName) then EfpName = 'th' + sc + '_efp'
  IF spd_check_tvar(EfpName) then BEGIN
    get_data, EfpName[0], data=Efp, dlim = tmpdlim
    if ~strcmp(tmpdlim.data_att.coord_sys, 'dsl', /fold) then begin
      print, 'THM_EFI_CLEAN_EFW: ' + Efpname[0] + ' is not in DSL. Exiting...'
      return
    endif
  ENDIF ELSE BEGIN
    thm_load_efi, probe=sc, datatype=['efp', 'vap'], coord='dsl', trange=trange, /get_support_data
    get_data, EfpName[0], data=Efp
    IF size(/type,Efp) NE 8 then BEGIN
      print, 'THM_EFI_CLEAN_EFW: Cannot get EFP data. Spikes cannot be removed.'
      SpikeRemove = 0
    ENDIF
  ENDELSE
ENDIF

; CLIP DATA TO RANGE
IF keyword_set(trange) then BEGIN
   trange_clip, E, trange[0], trange[1], /data, BadClip=BadEclip
   trange_clip, Bdsl, trange[0], trange[1], /data, BadClip=BadBclip
   trange_clip, SpinPer, trange[0]-60.d, trange[1]+60.d, /data, BadClip=BadSclip
   IF (keyword_set(BadEclip) OR keyword_set(BadBclip) OR keyword_set(BadSclip) ) THEN BEGIN
     print, 'THM_EFI_CLEAN_EFW: Problem with trange clip. Exiting...'
     print, '0=OK; 1=Problem. E:', BadEclip, 'B:', BadBclip, 'Spin:', BadSclip
     status = 1
     return
   ENDIF
ENDIF

; MAKE ARRAY FOR FAC STORAGE
E = {x:E.x, y:E.y}
Efac = E

; ## IDENTIFY INDIVIDUAL WAVE BURSTS  ##
tE   = E.x
thm_lsp_find_burst, E, istart=bstart, iend=bend, nbursts=nbursts, mdt=mdt
srate = 1. / mdt
if n_elements(SpikeNfit) EQ 0   then begin
   if abs(srate-8192.) lt 10 then SpikeNfit   = 400L
   if abs(srate-16384.) lt 10 then SpikeNfit   = 800L
endif

; CHECK FOR EFW HEADER TPLOT HANDLE KEYWORD SETTING
test  = (size(efwhedacname,/type) ne 7) or (not keyword_set(efwhedacname))
if (test[0]) then efwhacname = 'th'+sc[0]+'_efw_hed_ac' else efwhacname = efwhedacname[0]
; Flag for AC/DC coupled (needed for deconvolving instrument response)
get_data,efwhacname[0],data=efw_ac
if (size(efw_ac,/type) ne 8) then begin
  message,'No efw header info TPLOT handle found --> exiting prematurely',/continue,/informational
  status = 1
  return
endif
;get_data,'th'+sc+'_efw_hed_ac',data=efw_ac
if total(efw_ac.y ne efw_ac.y[0]) ne 0 then begin
  print,'THM_EFI_CLEAN_EFW: Error: EFW data switches coupling (AC/DC) during the requested interval.'
  print,'                   Please split this interval at ',time_string(efw_ac.x[min(where(efw_ac.y ne efw_ac.y[0]))])
  print,'                   and reprocess as separate intervals. Exiting...'
  status = 1
  return
endif
efw_ac=efw_ac.y[0]

; Setup kernel for deconvolving EFI response that includes
;   plasma-probe response
;   anti-aliasing filter response
;   ADC interleaving timing
;   DFB digital filter response
fsample = srate
kernel_length = 1024L
df = fsample / double(kernel_length)
f = dindgen(kernel_length)*df
f[kernel_length/2+1:*] -= double(kernel_length) * df
thm_comp_efi_response, 'SPB', f, SPB_resp, rsheath=5d6, /complex_response
thm_comp_efi_response, 'AXB', f, AXB_resp, rsheath=5d6, /complex_response
if efw_ac then begin
  E12_resp =thm_adc_resp('E12AC',f)
;   E12_resp = 1 / (SPB_resp * thm_eac_filter_resp(f) $
;                            * thm_adc_resp('E12AC',f) $
;                            * thm_dfb_dig_filter_resp(f, fsample,/EAC))
;   E34_resp = 1 / (SPB_resp * thm_eac_filter_resp(f) $
;                            * thm_adc_resp('E34AC',f) $
;                            * thm_dfb_dig_filter_resp(f, fsample,/EAC))
;   E56_resp = 1 / (AXB_resp * thm_eac_filter_resp(f) $
;                            * thm_adc_resp('E56AC',f) $
;                            * thm_dfb_dig_filter_resp(f, fsample,/EAC))
  E12_resp = 1 / (SPB_resp * thm_eac_filter_resp(f) $
                           * thm_adc_resp('E12AC',f) $
                           * thm_dfb_dig_filter_resp(f, fsample))
  E34_resp = 1 / (SPB_resp * thm_eac_filter_resp(f) $
                           * thm_adc_resp('E34AC',f) $
                           * thm_dfb_dig_filter_resp(f, fsample))
  E56_resp = 1 / (AXB_resp * thm_eac_filter_resp(f) $
                           * thm_adc_resp('E56AC',f) $
                           * thm_dfb_dig_filter_resp(f, fsample))
  E12_resp[0] = 0
  E34_resp[0] = 0
  E56_resp[0] = 0
endif else begin
  E12_resp = 1 / (SPB_resp * bessel_filter_resp(f,4096,4) $
    * thm_adc_resp('E12DC',f) * thm_dfb_dig_filter_resp(f, fsample))
  E34_resp = 1 / (SPB_resp * bessel_filter_resp(f,4096,4) $
    * thm_adc_resp('E34DC',f) * thm_dfb_dig_filter_resp(f, fsample))
  E56_resp = 1 / (AXB_resp * bessel_filter_resp(f,4096,4) $
    * thm_adc_resp('E56DC',f) * thm_dfb_dig_filter_resp(f, fsample))
endelse

; Transfer kernel into time domain: take inverse FFT and center
E12_resp = shift((fft(E12_resp,1)), kernel_length/2) / kernel_length
E34_resp = shift((fft(E34_resp,1)), kernel_length/2) / kernel_length
E56_resp = shift((fft(E56_resp,1)), kernel_length/2) / kernel_length

; START LOOP OVER INDIVIDUAL BURSTS
FOR ib=0L, nbursts-1 DO BEGIN

  ; BREAK OUT DATA
  t  = tE[bstart[ib]:bend[ib]]
  Ex = E.y[bstart[ib]:bend[ib],0]
  Ey = E.y[bstart[ib]:bend[ib],1]
  Ez = E.y[bstart[ib]:bend[ib],2]
  Ttemp = [min(t)-mdt/2, max(t)+mdt/2]
  nt_burst = n_elements(t)

  print, ''
  print, 'BURST: ', string(ib+1,form='(I0)'), ' out of: ', $
    string(nbursts,form='(I0)'), '; sample rate: ', $
    string(srate, form='(I0)'), '; burst data points: ', $
    string(nt_burst, form='(I0)')
  print, ''

  if nt_burst lt kernel_length then begin
     Efac.y[bstart[ib]:bend[ib],0]    = !values.d_nan
     Efac.y[bstart[ib]:bend[ib],1]    = !values.d_nan
     Efac.y[bstart[ib]:bend[ib],2]    = !values.d_nan
     print, 'Burst too short. Skipping...'
     print, ''
     continue
   endif

  ; Check NaNs
  indx = where(finite(Ex), nindx)
  indy = where(finite(Ey), nindy)
  indz = where(finite(Ez), nindz)
  if nindx le nt_burst/2. or nindy le nt_burst/2. or nindz le nt_burst/2. $
    then begin
    Efac.y[bstart[ib]:bend[ib],0]    = !values.d_nan
    Efac.y[bstart[ib]:bend[ib],1]    = !values.d_nan
    Efac.y[bstart[ib]:bend[ib],2]    = !values.d_nan
    print, 'Too many NaNs in the burst. Skipping...'
    continue
  endif
  if nindx le nt_burst then Ex = interpol(Ex[indx], t[indx], t)
  if nindy le nt_burst then Ey = interpol(Ey[indy], t[indy], t)
  if nindz le nt_burst then Ez = interpol(Ez[indz], t[indz], t)

  ; Minimize offset   - by JBT
  Ex = Ex - median(Ex)
  Ey = Ey - median(Ey)
  Ez = Ez - median(Ez)


  ; CALCULATE SPIN PERIOD
  ind = where( (SpinPer.x GE (Ttemp[0]-60.d)) AND $
    (SpinPer.x LE (Ttemp[1]+60.d)), nind)
  IF nind EQ 0 then BEGIN
    print, 'THM_EFI_CLEAN_EFW: Spin period missing during burst. Exiting...'
    status = 1
    return
  ENDIF
  per = median(spinper.y[ind])

  ; DO HIGH-PASS ON E
  if keyword_set(talk) then print, 'HIGH-PASS FILTER'
  Exf = thm_lsp_filter_highpass(Ex, mdt, freqlow=flow)
  Eyf = thm_lsp_filter_highpass(Ey, mdt, freqlow=flow)
  Ezf = thm_lsp_filter_highpass(Ez, mdt, freqlow=flow)

  ; REMOVE SPIKES
  IF keyword_set(SpikeRemove) then BEGIN
    thm_lsp_remove_spikes, t, Exf, Eyf, Ezf, per, Efp=Efp, Nwin=SpikeNwin, $
        SpikeSig=SpikeSig, Sigmin=SpikeSigmin, Nfit=SpikeNfit, Fit=SpikeFit, $
        talk=talk, diagnose=diagnose, wt=wt
  ENDIF

;   ; FIX FREQUENCY AND PAHSE
;   Exf = thm_efi_fix_freq_and_phase(Exf, dt = mdt)
;   Eyf = thm_efi_fix_freq_and_phase(Eyf, dt = mdt)
;   Ezf = thm_efi_fix_freq_and_phase(Ezf, dt = mdt,/ax)

  ; De-convolve instrument responses.
  b_length = 8 * kernel_length
  while b_length gt nt_burst do b_length /= 2
  print, 'b_length = ', b_length

  ; Remove NaNs
  indx = where(finite(Exf), nindx)
  indy = where(finite(Eyf), nindy)
  indz = where(finite(Ezf), nindz)
  if nindx ne nt_burst then Exf = interpol(Exf[indx], t[indx], t)
  if nindy ne nt_burst then Eyf = interpol(Eyf[indy], t[indy], t)
  if nindz ne nt_burst then Ezf = interpol(Ezf[indz], t[indz], t)

  ;-- Zero-pad data to account for edge wrap
  Exf = [Exf, fltarr(kernel_length/2)]
  Eyf = [Eyf, fltarr(kernel_length/2)]
  Ezf = [Ezf, fltarr(kernel_length/2)]

  ;-- Deconvolve transfer function, replace too-short bursts with NaN, jmm, 2025-09-04
  If(b_length Gt n_elements(e12_resp) And b_length Lt n_elements(exf)) Then Begin
     Exf = shift(blk_con(E12_resp, Exf, b_length=b_length),-kernel_length/2)
  Endif Else Exf[*] = !values.f_nan
  If(b_length Gt n_elements(e34_resp) And b_length Lt n_elements(eyf)) Then Begin
     Eyf = shift(blk_con(E34_resp, Eyf, b_length=b_length),-kernel_length/2)
  Endif Else Eyf[*] = !values.f_nan
  If(b_length Gt n_elements(e56_resp) And b_length Lt n_elements(ezf)) Then Begin
     Ezf = shift(blk_con(E56_resp, Ezf, b_length=b_length),-kernel_length/2)
  Endif Else Ezf[*] = !values.f_nan

  ;-- Remove the padding
  Exf = Exf[0:nt_burst-1]
  Eyf = Eyf[0:nt_burst-1]
  Ezf = Ezf[0:nt_burst-1]

  ; SAVE E DATA
  E.y[bstart[ib]:bend[ib],0]    = Exf
  E.y[bstart[ib]:bend[ib],1]    = Eyf
  E.y[bstart[ib]:bend[ib],2]    = Ezf

  ; Transform data into FAC.
  Eclip = E
  trange_clip, Eclip, Ttemp[0], Ttemp[1], /data
  store_data, 'Eclip', data=Eclip, dlim=elim

  ; CLIP MAGNETOMETER DATA
  Bclip = Bdsl
  trange_clip, Bclip, Ttemp[0]-3.d, Ttemp[1]+3.d, /data, badclip=badclip
  if keyword_set(badclip) then begin
     Efac.y[bstart[ib]:bend[ib],0]    = !values.d_nan
     Efac.y[bstart[ib]:bend[ib],1]    = !values.d_nan
     Efac.y[bstart[ib]:bend[ib],2]    = !values.d_nan
     continue
  endif

  store_data, 'Bclip', data=Bclip, dlim=blim
  nsmpts = 11  ; smooth points
  if n_elements(Bclip.x) le nsmpts then nsmpts = n_elements(data.x)/2
  nsmpts >= 1
  tsmooth2, 'Bclip', nsmpts, newname='Bclip'

  ; GO TO FAC COORDINATES (JIANBAO)
  thm_lsp_clean_timestamp, 'Bclip'
  thm_lsp_clean_timestamp, 'Eclip'
  thm_fac_matrix_make, 'Bclip', other_dim='zdsl', $
             newname='th'+sc+'_fgh_fac_mat'
  tvector_rotate, 'th'+sc+'_fgh_fac_mat', 'Eclip', $
          newname='Eclip', error=error

  ; GET ECLIP AND SAVE
  get_data, 'Eclip', data = Eclip
  Efac.y[bstart[ib]:bend[ib],0]    = Eclip.y[*,0]
  Efac.y[bstart[ib]:bend[ib],1]    = Eclip.y[*,1]
  Efac.y[bstart[ib]:bend[ib],2]    = Eclip.y[*,2]
ENDFOR
; ## END OF LOOP

; STORE E DATA
; add BAND to data_att -JBT
flow = floor((flow + 2.5)/5.) * 5.
if abs(srate-8192.) lt 10 then bandmsg = '~' + string(flow, format='(I0)') + $
         ' Hz -- ~3.3 kHz'
if abs(srate-16384.) lt 10 then bandmsg = '~' + string(flow, format='(I0)') + $
         ' Hz -- ~6.6 kHz'
data_att = {DATA_TYPE: elim.data_att.DATA_TYPE, $
            COORD_SYS: elim.data_att.COORD_SYS, $
            UNITS: elim.data_att.UNITS, $
            CAL_PAR_TIME: elim.data_att.CAL_PAR_TIME, $
            OFFSET: elim.data_att.OFFSET, $
            EDC_GAIN: elim.data_att.EDC_GAIN, $
            EAC_GAIN: elim.data_att.EAC_GAIN, $
            BOOM_LENGTH: elim.data_att.BOOM_LENGTH, $
            BOOM_SHORTING_FACTOR: elim.data_att.BOOM_SHORTING_FACTOR, $
            DSC_OFFSET: elim.data_att.DSC_OFFSET, $
            BAND: bandmsg}
                     ; BAND - the freq band of the data

if ~keyword_set(Edslname) then Edslname = Ename + '_clean_dsl'
ename2 = Edslname
dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '[mV/m]', $
  DATA_ATT: data_att, COLORS: elim.colors, $
  LABELS: ['Ex', 'Ey', 'Ez'], LABFLAG: 1, $
  YTITLE: 'E_DSL (th' + sc +')'}
store_data, ename2[0], data=E, dlim=dlim

; STORE FAC DATA
if ~keyword_set(Efacname) then Efacname = Ename + '_clean_fac'
perp1 = 'E!DSP!N'
perp2 = 'E!Dperp!N'
para = 'E!D||!N'
data_att.coord_sys = 'fac: x in spin-plane'
dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '[mV/m]', $
  DATA_ATT: data_att, COLORS: elim.colors, $
  LABELS: [perp1, perp2, para], LABFLAG: 1, $
  YTITLE: 'E_FAC (th' + sc +')'}
store_data, efacname[0], data=Efac, dlim=dlim

; Clean up.
thx = 'th' + sc + '_'
store_data, ['Eclip', 'Bclip', thx + 'fgh_fac_mat'], /delete
end

