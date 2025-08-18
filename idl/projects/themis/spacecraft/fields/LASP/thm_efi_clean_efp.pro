;+
; PRO: THM_EFI_CLEAN_EFP
;
; PURPOSE:
;    FIXES AXIAL, REMOVES SPIKES, SPINTONE, SC POTENTIAL, AND OTHER EFP ERRORS.
;
;   This routine is designed for general use. It will take EFP data in DSL as
;   input, clean up the data, and transform the data into FAC and GSM, and
;   return the cleaned EFP data in DSL, FAC, and GSM. If the data is gathered in
;   the dayside, set keyword /SUBSOLAR to use keyword defaults specifically for
;   dayside data.
;   
;   The routine can work on one-day long data, but if only a single particle
;   burst data is interesting, use the keyword TRANGE to specify the time range
;   of that burst can greatly reduce run time.
;
;   CAUTION: The input keyword ENAME is optional. When it is not specified,
;       ENAME is defaulted to 'thx_efp', where 'x' is probe name and should be
;       one of these: 'a', 'b', 'c', 'd', and 'e'. In this case, if the existed
;       'thx_efp' is not in DSL, the output will be wrong. So, make sure the
;       existed 'thx_efp' is in DSL, or specify ENAME to another tplot variable
;       which is EFP data in DSL.
;
;   NOTE: 1) Spike removal does not always work, so don't be surprised if there
;         still are spikes left on the data. Hopefully the spike issue can be
;         resolved in the future.
;         2) Merge can exhibit pathological behavior if B is near the spin plane.
;         spike removal does not always work.
;         3) Make sure thx_state_spinper is available! Best to set up for gsm.
;         Make sure timespan is set!!!!
;
; EXAMPLES:
;     For typical use, see thm_crib_cleanefp.pro and thm_crib_cleanefi.pro which
;     are typically located under TDAS_DIR/idl/themis/examples.
;
; INPUT:
;
; KEYWORDS (general):
;    probe      NEEDED: Program does only one sc at a time!
;    Ename      OPTIONAL: Valid TPLOT name for E, DEFAULT = 'thX_efp' (will
;               fetch)
;    Vname      OPTIONAL: Valid TPLOT name for E, DEFAULT = 'thX_vap' (will
;               fetch)
;    Bdslname   OPTIONAL, Valid TPLOT name for B, DEFAULT = 'thX_fgh_dsl'
;               (will fetch)
;    trange     OPTIONAL. Time range. 
;               USE TRANGE TO ISOLATE SINGLE PARTICLE BURST AND GREATLY
;               REDUCE RUN TIME!!!! 
;    subsolar   OPTIONAL. If set, defaults for subsolar region are used.
;               DEFAULT = TAIL
;    talk       OPTIONAL. Plots diagnostics. Can be fun. Slow. DEFAULT = 0
;    duration_threshold:  OPTIONAL. If the duration of a burst is less than
;               duration_threshold, it is skipped. DEFAULT = 15. 
;               In units of seconds.
;
; KEYWORDS (for output tplot variables):
;    Edslname   OPTIONAL: Name for the cleaned efp in DSL. 
;               DEFAULT = Ename + '_clean_dsl'
;    Egsmname   OPTIONAL: Name for the cleaned efp in DSL. 
;               DEFAULT = Ename + '_clean_gsm'
;    Efacname   OPTIONAL: Name for the cleaned efp in DSL. 
;               DEFAULT = Ename + '_clean_fac'
;
; KEYWORDS (Remove_SpinTone):
;    SpinRemove     If entered as 0, suppresses spintone removal. DEFAULT = 4
;                   (Spintone removed). The following are the behaviors for
;                   different values of SpinRemove.
;                   1: Only spintone, 2: Spintone and 2nd harm. 3: Spintone and
;                   4th harm.  4: Spintone, 2nd, and 4th harm.
;    SpinNsmooth    Activates median smoothing. # of half periods. Must be odd.
;                   DEFAULT = 19 for subsolar and 39 otherwise.
;    SpinPoly       Activates polyfit smoothing. Can be unstable if >9. DEFAULT
;                   = 0
; 
; KEYWORDS (Remove_Potential):
;    VscRemove      If entered as 0, suppresses potential removal. DEFAULT = 1
;                   (Potential removed.)
;    VscPole        Frequency to median smooth Vsc before applying to Ez.
;                   DEFAULT = 5.0 Hz
;    Vpoly          Actives polyfit of Ez to Vsc.  DEFAULT = 2 (5 /Subsolar)
;    Use_Electrons  (OBSOLETE) Kept for backward compatibility.
;    TeName         (OBSOLETE) Kept for backward compatibility.
;
; KEYWORDS (Remove_Spikes):
;    SpikeRemove    If entered as 0, suppresses spike removal. DEFAULT = 1
;                   (Spikes are removed.)
;    SpikeNwin      Number of points in spike search window. DFLT = 16
;    SpikeSig       Sigma of spikes. DFLT = 5 (Sometimes Sig = 6 works better)
;    SpikeSigmin    Minimun of sigma. DFLT = 0.01 mV/m. (Sometimes Sigmin = 0
;                   works better)
;    SpikeNfit      Number of points in the fit window. DFLT = 16
;    SpikeFit       If set, will do a Gaussian fit to Spikes. DFLT = 0
;
; KEYWORDS (Remove_Spin_Epoch):
;    EpochRemove    If set, removes all spin-epoch signals. DEFAULT = 0 (Not
;                   used.) Only useful for short stretches or if plasma
;                   condtitions are constant.
;
; KEYWORDS (Fix_Axial)
;    FixAxial       If entered as 0, suppresses axial fix. DEFAULT=1 (Axial is
;                   fixed.)
;    AxPoly         Forces polynomial fit of Ez-Eder of order AxPoly. DEFAULT=2
;                   (9 /SubSolar)
;    Merge          Merges Ederived with Eaxial.  DEFAULT = 0 No merging 
;                   (1 /Subsolar)
;                   1 - Abrupt merging. If Eder is avaliable Eder is used 
;                   (0 - Fmerge). Else Ez.
;                   2 - Soft merging. Bz/|B| is considered when merging.
;                   WARNING: MERGE=1 OR 2 CAN EXHIBIT PATHOLOGICAL BEHAVIOR IF
;                       MAGNETIC FIELD IS NEAR THE SPIN PLANE. PLEASE DOUBLE
;                       CHECK RESULTS IF USED. 
;    Fmerge         Frequency of crossover for merging Ederived with Eaxial. 
;                   DEFAULT = 5.0 Hz (/Subsolar). 
;    MergeRatio     Mimimum value of Bz/|B| to start merge (USED IF MERGE=2).
;                   DEFAULT = 0.05
;    MinBz          Needed to avoid divide by zero in Ederive. DEFAULT = 0.01 nT
;    MinRatio       Mimimum value of Bz/|B| to calculate Ederive. DEFAULT = 0.1
;                   (0.05 /Subsolar)
;
; KEYWORDS (B_Smooth)
;    BspinPoly      Activates polyfit smoothing. Can be unstable if >9. DEFAULT
;                   = 2. -1 suppresses.
;    Bsmooth        Activates B smoothing for fac rotation. DEFAULT = 11. 1 or
;                   less suppresses.
;
; HISTORY:
;   2013-06-20: JBT. Added deconvolution of sheath response.
;   2011-05-21: JBT. Added keyword DURATION_THRESHOLD.
;   2011-05-20: JBT. Fixed a bug that happens when the spin-tone removing fails.
;   2010-09-13: JBT. The default of FixAxial was changed to 0 (not to fix
;               axial E-field component).
;               Updated documents.
;   2010-04-08: JBT. Fixed some bugs.
;   2009-06-04: REE/JBT. Second Release.
;   2009-06-04: Jianbao Tao (JBT). The metadata (dlim.data_att) was improved.
;   2009-05-05: REE. First Release.
;-

function thm_efi_clean_efp_deconvol_inst_resp, E_array, srate, boom_type
; compile_opt idl2, hidden

Exf = E_array
nt_burst = n_elements(Exf)

fsample = srate
kernel_length = 512L
df = fsample / double(kernel_length)
f = dindgen(kernel_length)*df
f[kernel_length/2+1:*] -= double(kernel_length) * df

thm_comp_efi_response, boom_type, f, boom_resp, rsheath=5d6, /complex_response
; thm_comp_efi_response, 'SPB', f, SPB_resp, rsheath=5d6, /complex_response
; thm_comp_efi_response, 'AXB', f, AXB_resp, rsheath=5d6, /complex_response

E12_resp = 1 / boom_resp

; Transfer kernel into time domain: take inverse FFT and center
E12_resp = shift((fft(E12_resp,1)), kernel_length/2) / kernel_length

; De-convolve instrument responses.
b_length = 8 * kernel_length
while b_length gt nt_burst do b_length /= 2
; print, 'b_length = ', b_length

; Remove NaNs
indx = where(finite(Exf), nindx)
if nindx ne nt_burst then Exf = interpol(Exf[indx], t[indx], t)

;-- Zero-pad data to account for edge wrap
Exf = [Exf, fltarr(kernel_length/2)]

;-- Deconvolve transfer function
Exf = shift(blk_con(E12_resp, Exf, b_length=b_length),-kernel_length/2)

;-- Remove the padding
Exf = Exf[0:nt_burst-1]

return, Exf
end


;-------------------------------------------------------------------------------
pro thm_efi_clean_efp, probe=probe, Ename=Ename, Vname=Vname, $ ; GENERAL
        Bdslname=Bdslname, $                            ; GENERAL
        trange=trange, talk=talk, $                     ; GENERAL
        subsolar=subsolar, $                            ; GENERAL
        duration_threshold = duration_threshold, $      ; GENERAL
        Edslname = Edslname, Egsmname = Egsmname, $     ; OUTPUT NAME
        Efacname = Efacname, $                          ; OUTPUT NAME
        SpinNsmooth=SpinNsmooth, SpinPoly=SpinPoly, $   ; REMOVE_SPINTONE
        SpinRemove=SpinRemove, $                        ; REMOVE_SPINTONE
        VscPole=VscPole, Vpoly=Vpoly, $                 ; REMOVE_POTENTIAL
        VscRemove=VscRemove, $                          ; REMOVE_POTENTIAL
        use_electrons=use_electrons, TeName=TeName, $   ; REMOVE_POTENTIAL
        SpikeRemove=SpikeRemove, SpikeNwin=SpikeNwin, $ ; REMOVE_SPIKES
        SpikeSig=SpikeSig, SpikeSigmin=SpikeSigmin, $   ; REMOVE_SPIKES
        SpikeNfit=SpikeNfit, SpikeFit=SpikeFit, $       ; REMOVE_SPIKES
        EpochRemove=EpochRemove, $                      ; REMOVE_SPIN_EPOCH
        FixAxial=FixAxial, AxPoly=AxPoly, $             ; FIX_AXIAL
        Merge=Merge, FMerge=FMerge, $                   ; FIX_AXIAL
        MergeRatio=MergeRatio, $                        ; FIX_AXIAL
        MinBz=MinBz, MinRatio=MinRatio, $               ; FIX_AXIAL (E_DERIVE)
        BspinPoly=BspinPoly, Bsmooth=Bsmooth            ; B_SMOOTH

; # CHECK INPUTS - GET NEEDED DATA #
IF not keyword_set(probe) then BEGIN
  dprint, 'SC not set. Exiting...'
  return
ENDIF
sc = probe(0)

; CHECK FOR SUBSOLAR KEYWORD
IF keyword_set(subsolar) then BEGIN
  if n_elements(Vpoly) EQ 0         then Vpoly         = 4    ; REMOVE_POTENTIAL
  if n_elements(use_electrons) EQ 0 then use_electrons = 0    ; REMOVE_POTENTIAL
  if n_elements(Axpoly) EQ 0        then Axpoly        = 7      ; FIX_AXIAL
  if n_elements(Merge) EQ 0         then Merge         = 1      ; FIX_AXIAL
  if n_elements(MinRatio) EQ 0      then MinRatio      = 0.05d  ; FIX_AXIAL
  if n_elements(SpinNsmooth) EQ 0   then SpinNsmooth   = 19   ; REMOVE_SPINTONE
ENDIF

; SET TAIL DEFAULTS
if n_elements(SpinRemove) EQ 0  then SpinRemove  = 4      ; REMOVE_SPINTONE
if n_elements(SpinNsmooth) EQ 0 then SpinNsmooth = 39     ; REMOVE_SPINTONE
if n_elements(VscRemove) EQ 0   then VscRemove   = 1      ; REMOVE_POTENTIAL
if n_elements(VscPole) EQ 0     then VscPole     = 5.0d   ; REMOVE_POTENTIAL
if n_elements(Vpoly) EQ 0       then Vpoly       = 2      ; REMOVE_POTENTIAL
if n_elements(SpikeRemove) EQ 0 then SpikeRemove = 1      ; REMOVE_SPIKES
if n_elements(FixAxial) EQ 0    then FixAxial    = 0      ; FIX_AXIAL
if n_elements(Axpoly) EQ 0      then Axpoly      = 2      ; FIX_AXIAL
if keyword_set(merge)           then Fmerge      = 5.0d   ; FIX_AXIAL
if not keyword_set(merge)       then Fmerge      = 0      ; FIX_AXIAL
IF keyword_set(merge) then BEGIN
  if merge EQ 2 then softmerge=1
ENDIF
if n_elements(BspinPoly) EQ 0   then BspinPoly   = 2      ; B_SMOOTH
if n_elements(Bsmooth) EQ 0     then Bsmooth     = 11     ; B_SMOOTH
if n_elements(duration_threshold) eq 0 then duration_threshold = 15.

; CHECK FOR EFP DATA
if not keyword_set(Ename) then Ename = 'th' + sc + '_efp'
IF spd_check_tvar(Ename) then BEGIN                       ; added by JBT
  get_data, ename(0), data=E, dlim=elim                   ; added by JBT
  ; Check coordinates of Ename.
  if ~strcmp(elim.data_att.coord_sys, 'dsl', /fold) then begin
    dprint, Ename + ' is not in DSL. Exiting...'
    return
  endif
ENDIF ELSE BEGIN
  thm_load_efi, probe=sc, datatype=['efp', 'vap'], coord='dsl', trange=trange
  get_data, ename(0), data=E, dlim=elim
  IF size(/type,E) NE 8 then BEGIN
    dprint, 'Cannot get electric field data. Exiting...'
   return
  ENDIF
ENDELSE

; CHECK FOR VOLTAGES
if ~keyword_set(Vname) then Vname = 'th' + sc + '_vap'
if ~keyword_set(Vscname) then Vscname = 'th' + sc + '_vsc'
IF spd_check_tvar(Vscname) then BEGIN                          
  get_data, Vscname[0], data=Vsc                                  
ENDIF ELSE BEGIN                                               
  thm_efi_get_potential, Vname(0), trange=trange
  get_data, Vscname[0], data=Vsc
    IF size(/type,Vsc) NE 8 then BEGIN
      dprint, 'Cannot get SC potential. Exiting...'
    return
  ENDIF
ENDELSE

; CHECK FOR MAG DATA
if not keyword_set(Bdslname) then Bdslname = 'th' + sc + '_fgh_dsl'
IF spd_check_tvar(Bdslname) then BEGIN                         
  get_data, Bdslname(0), data=Bdsl, dlim=blim                  
ENDIF ELSE BEGIN                                               
  dprint, 'Mag data not stored in dsl. Fetching...'
  thm_load_fgm, probe=sc, datatype = ['fgh'], coord=['dsl'], trange=trange, $
      level = 2
  Bdslname = 'th' + sc + '_fgh_dsl'
  get_data, Bdslname(0), data=Bdsl, dlim=blim
  IF size(/type,Bdsl) NE 8 then BEGIN
    dprint, 'Cannot get MAG data. Exiting...'
    return
  ENDIF
ENDELSE

; CHECK FOR SPIN DATA
SpinName = 'th' + sc + '_state_spinper'                    
IF spd_check_tvar(Spinname) then BEGIN  
 get_data, SpinName[0], data=SpinPer                          
ENDIF ELSE BEGIN                                               
  thm_load_state, probe=sc, datatype='spinper'           
  get_data, SpinName[0], data=SpinPer   
  IF size(/type,SpinPer) NE 8 THEN BEGIN
    dprint, 'Cannot get spin period. Exiting...'
    return
  ENDIF
ENDELSE                                                  

; GET ELECTRON TEMPERATURE DATA 
;IF keyword_set(use_electrons) then BEGIN
;  if not keyword_set(TeName) then TeName = 'th' + sc + '_peeb_avgtemp'
;  IF spd_check_tvar(TeName) then BEGIN                          
;    get_data, TeName[0], data=peeb_t       
;  ENDIF ELSE BEGIN                                               
;    print, 'THM_EFI_CLEAN_EFP: Electron temperature data not stored. Fetching...'
;    thm_load_esa, probe=sc, datatype = 'peeb_avgtemp', level = 'l2', $
;      /get_support, trange = trange
;    TeName = 'th' + sc + '_peeb_avgtemp'
;    get_data, TeName[0], data=peeb_t
;    IF size(/type,peeb_t) NE 8 then BEGIN
;      print, 'THM_EFI_CLEAN_EFP: Cannot get electron temperature. Not using.'
;      use_electrons = 0
;    ENDIF
;  ENDELSE                                                  
;ENDIF
use_electrons = 0

; For making trange_clip work.
E = {x:E.x, y:E.y}
vsc = {x:vsc.x, y:vsc.y}
Bdsl = {x:Bdsl.x, y:Bdsl.y}

; CLIP DATA TO RANGE
IF keyword_set(trange) then BEGIN
   trange_clip, E, trange(0), trange(1), /data, BadClip=BadEclip
   trange_clip, Vsc, trange(0), trange(1), /data, BadClip=BadVclip
   trange_clip, Bdsl, trange(0), trange(1), /data, BadClip=BadBclip
   trange_clip, SpinPer, trange(0)-60.d, trange(1)+60.d, /data, BadClip=BadSclip
;  if size(/type,peeb_t) eq 8 then $
;     trange_clip, peeb_t, trange(0), trange(1), /data, BadClip=BadPclip
   IF (keyword_set(BadEclip) OR keyword_set(BadVclip) OR $
       keyword_set(BadBclip) OR $
       keyword_set(BadSclip) OR keyword_set(BadPclip) ) THEN BEGIN
     dprint, 'Problem with trange clip. Exiting...'
     dprint, '0=OK; 1=Problem. E:', BadEclip, 'V:', BadVclip, 'B:', $
        BadBclip, 'Spin:', BadSclip
     return
   ENDIF
ENDIF

; CREATE ARRAYS FOR OUTPUT
EderSave  = E.y(*,0) * 0

; ## IDENTIFY INDIVIDUAL PARTICLE BURSTS  ##
tE   = E.x
thm_lsp_find_burst, E, istart=bstart, iend=bend, nbursts=nbursts, mdt=mdt

; sample rate
srate = round(1d / median(tE[1:*] - tE)) + 0d
; print, 'srate = ', srate
; return
 
; START LOOP OVER INDIVIDUAL BURSTS
FOR ib=0L, nbursts-1 DO BEGIN
  dprint, 'BURST: ', ib+1, ' out of: ', nbursts

  ; BREAK OUT DATA
  t  = tE(bstart(ib):bend(ib))
  Ex = E.y(bstart(ib):bend(ib),0)
  Ey = E.y(bstart(ib):bend(ib),1)
  Ez = E.y(bstart(ib):bend(ib),2)
  Ttemp = [min(t)-mdt/2, max(t)+mdt/2]  
  
  ; CHECK THE TEMPORAL LENGTH OF THE BURST. IF IT IS SHORTER THAN 15 S, SKIP IT.
  blen  = tE[bend[ib]] - tE[bstart[ib]]
  dprint, 'burst temporal length = ', blen
  if blen lt duration_threshold then begin
      dprint, 'Burst #' + string(ib + 1, format='(I0)') + $
          ' is shorter than ' + string(duration_threshold, form = '(I0)') + $
          ' second ' + $
         'and is skipped from cleaning.'
      EderSave(bstart(ib):bend(ib))  = !values.d_nan
      continue
  endif

  ; Remove EFI boom response
  Ex = thm_efi_clean_efp_deconvol_inst_resp(Ex, srate, 'SPB')
  Ey = thm_efi_clean_efp_deconvol_inst_resp(Ey, srate, 'SPB')
  Ez = thm_efi_clean_efp_deconvol_inst_resp(Ez, srate, 'AXB')

  ; CALCULATE SPIN PERIOD
  ind = where( (SpinPer.x GE (Ttemp(0)-60.d)) AND $
    (SpinPer.x LE (Ttemp(1)+60.d)), nind)
  IF nind EQ 0 then BEGIN
    dprint, 'Spin period missing during burst. Exiting...'
    return
  ENDIF
  per = median(spinper.y(ind))
   
  ; GET SC POTENTIAL
  VscTemp = Vsc
  trange_clip, VscTemp, Ttemp(0), Ttemp(1), /data

  ; Remove spin tone in Vsc. If the removing fails, skip the removing.
  VscF   = thm_lsp_remove_spintone(VscTemp.x, VscTemp.y, per, $
      talk=talk, ns=SpinNsmooth, sp = spinpoly, fail = fail)
  if fail gt 0 then VscF = VscTemp.y

  VscF_old = VscF
  VscF   = thm_lsp_remove_spintone(VscTemp.x, VscF, per/2,    $
      talk=talk, ns=SpinNsmooth, sp = spinpoly, fail = fail)
  if fail gt 0 then VscF = VscF_old

  VscF_old = VscF
  VscF   = thm_lsp_remove_spintone(VscTemp.x, VscF, per/4,    $
      talk=talk, ns=SpinNsmooth, sp = spinpoly, fail = fail)
  if fail gt 0 then VscF = VscF_old

  ; REMOVE SPIN TONES FROM E
  IF keyword_set(SpinRemove) then BEGIN
    Exf = thm_lsp_remove_spintone(t, Ex, per,    $
        talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
    if fail gt 0 then Exf = Ex

    Eyf = thm_lsp_remove_spintone(t, Ey, per,    $
        talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
    if fail gt 0 then Eyf = Ey

    Ezf = thm_lsp_remove_spintone(t, Ez, per,    $
        talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
    if fail gt 0 then Ezf = Ez

    IF ( (SpinRemove EQ 2) OR (SpinRemove GE 4) ) then BEGIN
      Exf_old = Exf
      Exf = thm_lsp_remove_spintone(t, Exf, per/2, $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Exf = Exf_old
      
      Eyf_old = Eyf
      Eyf = thm_lsp_remove_spintone(t, Eyf, per/2, $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Eyf = Eyf_old

      Ezf_old = Ezf
      Ezf = thm_lsp_remove_spintone(t, Ezf, per/2, $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Ezf = Ezf_old
    ENDIF

    IF (SpinRemove GE 3) then BEGIN
      Exf_old = Exf
      Exf = thm_lsp_remove_spintone(t, Exf, per/4, $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Exf = Exf_old

      Eyf_old = Eyf
      Eyf = thm_lsp_remove_spintone(t, Eyf, per/4, $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Eyf = Eyf_old

      Ezf_old = Ezf
      Ezf = thm_lsp_remove_spintone(t, Ezf, per/4, $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Ezf = Ezf_old
    ENDIF
  ENDIF

  ; REMOVE POTENTIAL FROM Ez
  if keyword_set(VscRemove) then $
    Ezf = thm_lsp_remove_potential(t, Ezf, VscTemp.x, VscF, peeb_t=peeb_t, $
                                   VscPole=VscPole, Vpoly=Vpoly, talk=talk)

  ; REMOVE SPIKES
  IF keyword_set(SpikeRemove) then BEGIN
    thm_lsp_remove_spikes, t, Exf, Eyf, Ezf, per, Nwin=SpikeNwin, $
        SpikeSig=SpikeSig, Sigmin=SpikeSigmin, Nfit=SpikeNfit, Fit=SpikeFit, $
        talk=talk, diagnose=diagnose, wt=wt
  ENDIF
  
  ; REMOVE SPIN TONES FROM E
  IF keyword_set(SpinRemove) then BEGIN
    Exf_old = Exf
    Exf = thm_lsp_remove_spintone(t, Exf, per,    $
        talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
    if fail gt 0 then Exf = Exf_old

    Eyf_old = Eyf
    Eyf = thm_lsp_remove_spintone(t, Eyf, per,    $
        talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
    if fail gt 0 then Eyf = Eyf_old

    Ezf_old = Ezf
    Ezf = thm_lsp_remove_spintone(t, Ezf, per,    $
        talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
    if fail gt 0 then Ezf = Ezf_old

    IF ( (SpinRemove EQ 2) OR (SpinRemove GE 4) ) then BEGIN
      Exf_old = Exf
      Exf = thm_lsp_remove_spintone(t, Exf, per/2,    $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Exf = Exf_old

      Eyf_old = Eyf
      Eyf = thm_lsp_remove_spintone(t, Eyf, per/2,    $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Eyf = Eyf_old

      Ezf_old = Ezf
      Ezf = thm_lsp_remove_spintone(t, Ezf, per/2,    $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Ezf = Ezf_old

;       Exf = thm_lsp_remove_spintone(t, Exf, per/2, $
;           talk=talk, ns=SpinNsmooth, sp=spinpoly)
;       Eyf = thm_lsp_remove_spintone(t, Eyf, per/2, $
;           talk=talk, ns=SpinNsmooth, sp=spinpoly)
;       Ezf = thm_lsp_remove_spintone(t, Ezf, per/2, $
;           talk=talk, ns=SpinNsmooth, sp=spinpoly)
    ENDIF
    IF (SpinRemove GE 3) then BEGIN
      Exf_old = Exf
      Exf = thm_lsp_remove_spintone(t, Exf, per/4,    $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Exf = Exf_old

      Eyf_old = Eyf
      Eyf = thm_lsp_remove_spintone(t, Eyf, per/4,    $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Eyf = Eyf_old

      Ezf_old = Ezf
      Ezf = thm_lsp_remove_spintone(t, Ezf, per/4,    $
          talk=talk, ns=SpinNsmooth, sp=spinpoly, fail = fail)
      if fail gt 0 then Ezf = Ezf_old
;       Exf = thm_lsp_remove_spintone(t, Exf, per/4, $
;           talk=talk, ns=SpinNsmooth, sp=spinpoly)
;       Eyf = thm_lsp_remove_spintone(t, Eyf, per/4, $
;           talk=talk, ns=SpinNsmooth, sp=spinpoly)
;       Ezf = thm_lsp_remove_spintone(t, Ezf, per/4, $
;           talk=talk, ns=SpinNsmooth, sp=spinpoly)
    ENDIF
  ENDIF

  ; REMOVE EPOCH
  IF keyword_set(EpochRemove) then BEGIN
    Exf = thm_lsp_remove_spin_epoch(t, Exf, per, talk=talk)
    Eyf = thm_lsp_remove_spin_epoch(t, Eyf, per, talk=talk)
    Ezf = thm_lsp_remove_spin_epoch(t, Ezf, per, talk=talk)
  ENDIF

  Btemp = Bdsl

  ; FIT AXIAL TO EDERIVED
  IF keyword_set(FixAxial) then BEGIN
    Etemp = E
    trange_clip, Etemp, Ttemp(0), Ttemp(1), /data
    trange_clip, Btemp, Ttemp(0), Ttemp(1), /data
    Etemp.y(*,0) = Exf
    Etemp.y(*,1) = Eyf
    Etemp.y(*,2) = Ezf
    Eder = thm_lsp_derive_Ez(Etemp, Btemp, minBz=minBz, $
        minRat=MinRatio, ratio=ratio)
    Ezf  = thm_lsp_fix_axial(t, Ezf, Eder, talk=talk, $
        AxPoly=Axpoly, soft=softmerge,  $
        Fmerge=Fmerge, MergeRatio=MergeRatio, ratio=ratio)
    EderSave(bstart(ib):bend(ib))  = Eder
  ENDIF 
  
  ; SAVE E DATA
  E.y(bstart(ib):bend(ib),0)     = Exf
  E.y(bstart(ib):bend(ib),1)     = Eyf
  E.y(bstart(ib):bend(ib),2)     = Ezf

  ; FIX B SPINTONE
  magstart = value_locate(Bdsl.x, Btemp.x(0)+1.d-8)
  magstop  = magstart + n_elements(Btemp.x) - 1L
  IF BspinPoly GE 0 then BEGIN
;     Btemp.y(*,0) 
    tmp = thm_lsp_remove_spintone(Btemp.x, Btemp.y(*,0), per, $
        talk=talk, spinpoly=Bspinpoly, fail = fail)
    if fail eq 0 then Btemp.y[*, 0] = tmp

    tmp = thm_lsp_remove_spintone(Btemp.x, Btemp.y(*,1), per, $
        talk=talk, spinpoly=Bspinpoly, fail = fail)
    if fail eq 0 then Btemp.y[*, 1] = tmp

    tmp = thm_lsp_remove_spintone(Btemp.x, Btemp.y(*,2), per, $
        talk=talk, spinpoly=Bspinpoly, fail = fail)
    if fail eq 0 then Btemp.y[*, 2] = tmp

;     Btemp.y(*,0) = thm_lsp_remove_spintone(Btemp.x, Btemp.y(*,0), per, $
;         talk=talk, spinpoly=Bspinpoly)
;     Btemp.y(*,1) = thm_lsp_remove_spintone(Btemp.x, Btemp.y(*,1), per, $
;         talk=talk, spinpoly=Bspinpoly)
;     Btemp.y(*,2) = thm_lsp_remove_spintone(Btemp.x, Btemp.y(*,2), per, $
;         talk=talk, spinpoly=Bspinpoly)
  ENDIF
  
  ; SMOOTH B
  IF Bsmooth GT 1 THEN BEGIN
    Btemp.y(*,0) = smooth(Btemp.y(*,0), Bsmooth, /nan, /edge_trunc)
    Btemp.y(*,1) = smooth(Btemp.y(*,1), Bsmooth, /nan, /edge_trunc)
    Btemp.y(*,2) = smooth(Btemp.y(*,2), Bsmooth, /nan, /edge_trunc)
  ENDIF
  
  ; SAVE B DATA
  Bdsl.y(magstart:magstop, 0) =  Btemp.y(*,0)
  Bdsl.y(magstart:magstop, 1) =  Btemp.y(*,1)
  Bdsl.y(magstart:magstop, 2) =  Btemp.y(*,2)

ENDFOR
; ## END OF LOOP

; ### STORE DATA AS TPLOT VARIABLES

; add BAND to data_att -JBT
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
            BAND: 'DC - ~50 Hz'}   ; BAND - the freq band of the data

; STORE E DATA
if ~keyword_set(Edslname) then Edslname = Ename + '_clean_dsl'
ename2 = Edslname
dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '(mV/m)', $
  DATA_ATT: data_att, COLORS: elim.colors, $
  LABELS: ['Ex', 'Ey', 'Ez'], LABFLAG: elim.labflag, $
  YTITLE: 'E_DSL (th' + sc +')'}
store_data, ename2[0], data=E, dlim=dlim

; STORE B DATA
bname2 = Bdslname + '_smooth'
store_data, bname2[0], data=Bdsl, dlim=blim

; STORE Ederived DATA
if keyword_set(FixAxial) then begin
  Edername = ename + '_derived'
  Etemp = dblarr(n_elements(E.x),4)
  Etemp(*,0) = E.y(*,0)
  Etemp(*,1) = E.y(*,1)
  Etemp(*,2) = E.y(*,2)
  Etemp(*,3) = EderSave
  dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '(mV/m)', $
    DATA_ATT: data_att, COLORS: [elim.colors, 0], $
    LABELS: ['Ex', 'Ey', 'Ez', 'E!Dzder!N'], LABFLAG: elim.labflag, $
    YTITLE: 'E - ' + data_att.coord_sys}
  store_data, Edername[0], data={X:E.x, Y: Etemp, V: [1,2,3,4]}, dlim=dlim
endif

; #### COORDINATE TRANSFORMATIONS

; TRANSFORM TO GSM
if ~keyword_set(Egsmname) then Egsmname = Ename + '_clean_gsm'
thm_cotrans, ename2, egsmname, in_coord='dsl', out_coord='gsm'
get_data, egsmname[0], data = data
data_att.coord_sys = 'gsm'
dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '(mV/m)', $
  DATA_ATT: data_att, COLORS: elim.colors, $
  LABELS: ['Ex', 'Ey', 'Ez'], LABFLAG: elim.labflag, $
  YTITLE: 'E_GSM (th' + sc +')'}
store_data, egsmname[0], data = data, dlim = dlim

; GO TO FAC COORDINATES (JIANBAO)
if ~keyword_set(Efacname) then Efacname = Ename + '_clean_fac'
thm_lsp_clean_timestamp, bname2
thm_lsp_clean_timestamp, ename2
thm_fac_matrix_make, bname2, other_dim='zdsl', newname='th'+sc+'_fgh_fac_mat'
tvector_rotate, 'th'+sc+'_fgh_fac_mat', ename2, $
          newname=efacname, error=error
get_data, efacname[0], data = data
perp1 = 'E!DSP!N'
perp2 = 'E!Dperp!N'
para = 'E!D||!N'
data_att.coord_sys = 'fac: x in spin-plane'
dlim = {CDF: elim.cdf, SPEC: 0b, LOG: 0b, YSUBTITLE: '(mV/m)', $
  DATA_ATT: data_att, COLORS: elim.colors, $
  LABELS: [perp1, perp2, para], LABFLAG: elim.labflag, $
  YTITLE: 'E_FAC (th' + sc +')'}
store_data, efacname[0], data = data, dlim = dlim

; Clean up.
thx = 'th' + sc + '_'
store_data, [bname2[0], thx + 'fgh_fac_mat'], /del

end
