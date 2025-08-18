;+
;PROCEDURE:   mvn_swe_calib
;PURPOSE:
;  Maintains SWEA calibration factors in a common block (mvn_swe_com).
;
;USAGE:
;  mvn_swe_calib
;
;INPUTS:
;
;KEYWORDS:
;       TABNUM:       Table number (1-8) corresponding to predefined settings:
;
;                       1 : Xmax = 6., Vrange = [0.75, 750.], V0scale = 1., /old_def
;                           primary table for ATLO and Inner Cruise (first turnon)
;                             -64 < Elev < +66 ; 7 < E < 4650
;                              Chksum = 'CC'X
;                              LUT = 0
;
;                       2 : Xmax = 6., Vrange = [0.75, 375.], V0scale = 1., /old_def
;                           alternate table for ATLO and Inner Cruise (never used)
;                             -64 < Elev < +66 ; 7 < E < 2340
;                              Chksum = '1E'X
;                              LUT = 1
;
;                       3 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0., /old_def
;                           primary table for Outer Cruise
;                             -59 < Elev < +61 ; 3 < E < 4630
;                              Chksum = 'C0'X
;                              LUT = 0
;                              GSEOS svn rev 8360
;
;                       4 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1., /old_def
;                           alternate table for Outer Cruise
;                             -59 < Elev < +61 ; 3 < E < 4650
;                              Chksum = 'DE'X
;                              LUT = 1
;                              GSEOS svn rev 8361
;
;                       5 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0.
;                           primary table for Transition and Science
;                             -59 < Elev < +61 ; 3 < E < 4630
;                              Chksum = 'CC'X
;                              LUT = 0
;                              GSEOS svn rev 8481
;
;                       6 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1.
;                           alternate table for Transition and Science
;                             -59 < Elev < +61 ; 3 < E < 4650
;                              Chksum = '82'X
;                              LUT = 1
;                              GSEOS svn rev 8482
;
;                       7 : Xmax = 5.5, Erange = [200.,200.], V0scale = 0.
;                           Hires 32-Hz at 200 eV
;                             -59 < Elev < +61 ; E = 200
;                              Chksum = '00'X
;                              LUT = 2
;
;                       8 : Xmax = 5.5, Erange = [50.,50.], V0scale = 0.
;                           Hires 32-Hz at 50 eV
;                             -59 < Elev < +61 ; E = 50
;                              Chksum = '00'X
;                              LUT = 3
;
;                     Passed to mvn_swe_sweep.pro.
;
;       CHKSUM:       Specify the sweep table by its checksum.  See above.
;                     This only works for table numbers > 3.  Warning: Checksums
;                     for tables 7 and 8 are the same, so using checksums to 
;                     specify sweep tables is now ambiguous.  See mvn_swe_getlut,
;                     which resolves this ambiguity with housekeeping sweep
;                     voltage readbacks and provides a more robust method of 
;                     determining which LUT is in use at any time.
;
;       SETCAL:       Structure holding calibration factors to modify.  Structure can
;                     have any combination of tags, which are recognized with case-
;                     folded minimum matching (leading "swe_" is optional):
;
;                       {swe_Ka       : 6.17      , $   ; analyzer constant
;                        swe_G        : 0.009/16. , $   ; nominal geometric factor
;                        swe_Ke       : 2.8       , $   ; electron suppression constant
;                        swe_dead     : 1.0e-6    , $   ; deadtime per preamp
;                        swe_min_dtc  : 0.25      , $   ; max 4x deadtime correction
;                        swe_paralyze : 0            }  ; use non-paralyzable deadtime
;
;                     Any other tags are ignored.
;
;       DEFAULT:      Reset calibration factors to the default values (see above).
;
;       LIST:         List the current calibration constants.
;
;       SILENT:       Shhh.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-23 15:45:10 -0700 (Fri, 23 May 2025) $
; $LastChangedRevision: 33325 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_calib.pro $
;
;CREATED BY:    David L. Mitchell  03-29-13
;FILE: mvn_swe_calib.pro
;-
pro mvn_swe_calib, tabnum=tabnum, chksum=chksum, setcal=setcal, default=default, list=list, silent=silent

  @mvn_swe_com

; Set the SWEA Ground Software Version

  mvn_swe_version = 5  ; DLM, 2024-01-09

; Initialize

  blab = ~keyword_set(silent)

  if (size(swe_hsk_str,/type) ne 8) then mvn_swe_init

  if (keyword_set(default) or (size(swe_G,/type) eq 0)) then begin
    if (blab) then print, "Initializing SWEA constants"
    swe_Ka       = 6.17       ; analyzer constant (1.4% variation around azim)
    swe_G        = 0.009/16.  ; nominal geometric factor per anode (IRAP)
    swe_Ke       = 2.80       ; nominal value, see mvn_swe_esuppress.pro
    swe_dead     = 1.0e-6     ; deadtime for one MCP-Anode-Preamp chain (in-flight)
    swe_min_dtc  = 0.25       ; max 4x deadtime correction
    swe_paralyze = 0          ; use non-paralyzable deadtime model

    swe_G *= 0.7              ; SWIA recalibration released 2022-03-30
  endif

; Process SETCAL structure

  if (size(setcal,/type) eq 8) then begin
    ftag = tag_names(setcal)
    stag = ftag
    i = where(strcmp(ftag, 'swe_', 4, /fold), count)
    if (count gt 0) then stag[i] = strmid(ftag[i],4)
    tlist = ['Ka','G','Ke','dead','min_dtc','paralyze']
    mlist = ['analyzer constant','geometric factor per anode','electron suppression constant', $
             'deadtime','minimum deadtime correction','paralyzable deadtime']
    mlist = 'Setting ' + mlist + ': '
    for j=0,(n_elements(ftag)-1) do begin
      i = strmatch(tlist, stag[j]+'*', /fold)
      case (total(i)) of
         0   : print, "Calibration parameter not recognized: ", ftag[j]
         1   : begin
                 k = (where(i eq 1))[0]
                 ok = execute('swe_' + tlist[k] + ' = setcal.(j)',0,1)
                 if (ok) then print, mlist[k], setcal.(j) $
                         else print, "Error setting calibration parameter: ", ftag[j]
               end
        else : print, "Calibration parameter ambiguous: ", ftag[j]
      endcase
    endfor
    return
  endif

; Find the first valid LUT
;   chksum =   0B means SWEA has just powered on or is using
;                 sweep table 7 or 8.
;   chksum = 255B means SWEA is loading tables

  ok = 0

  if (not ok) then begin
    if keyword_set(tabnum) then begin
      if ((tabnum ge 0) and (tabnum le 8)) then begin
        swe_active_tabnum = tabnum
        if (size(swe_hsk,/type) ne 8) then begin
          tplot_options, get=topt
          swe_hsk = replicate(swe_hsk_str,2)
          swe_hsk.time = topt.trange_full
          swe_hsk.chksum = mvn_swe_tabnum(tabnum,/inverse)
          swe_tabnum = swe_active_tabnum
        endif
        ok = 1
      endif
    endif
  endif

  if (not ok) then begin
    if keyword_set(chksum) then begin
      tabnum = mvn_swe_tabnum(chksum)
      swe_active_tabnum = tabnum
      if (size(swe_hsk,/type) ne 8) then begin
        tplot_options, get=topt
        swe_hsk = replicate(swe_hsk_str,2)
        swe_hsk.time = topt.trange_full
        swe_hsk.chksum = mvn_swe_tabnum(tabnum,/inverse)
        swe_tabnum = swe_active_tabnum
      endif
      if (tabnum ne 0) then ok = 1
    endif
  endif

  if (not ok) then begin
    if (size(swe_hsk,/type) eq 8) then begin
      nhsk = n_elements(swe_hsk)
      lutnum = swe_hsk.ssctl      ; active LUT number
      swe_chksum = bytarr(nhsk)   ; checksum of active LUT
    
      for i=0L,(nhsk-1L) do swe_chksum[i] = swe_hsk[i].chksum[lutnum[i] < 3]
      indx = where(lutnum gt 3, count)
      if (count gt 0L) then swe_chksum[indx] = 'FF'XB  ; table load during turn-on
    
      indx = where((swe_chksum gt 0B) and (swe_chksum lt 255B), count)
      if (count gt 0L) then begin
        tabnum = mvn_swe_tabnum(swe_chksum[indx[0]])
        swe_active_tabnum = tabnum
        if (tabnum ne 0) then ok = 1
      endif
    endif else print,"No SWEA housekeeping."
  endif

  if (not ok) then begin
    print,"No valid table number or checksum."
    print,"Cannot determine calibration factors."
    return
  endif

  if (blab) then print, tabnum, mvn_swe_tabnum(tabnum,/inverse), format='("LUT: ",i2.2,3x,"Checksum: ",Z2.2)'

; Integration time per energy/angle bin prior to summing bins.
; There are 7 deflection bins for each of 64 energy bins spanning
; 1.95 sec.  The first deflection bin is for settling and is
; discarded.

  swe_duty = (1.95D/2D)*(6D/7D)  ; duty cycle (fraction of time counts are accumulated)
  swe_integ_t = 1.95D/(7D*64D)   ; integration time per energy/deflector bin

; Energy Sweep

; Generate initial sweep table (can change dynamically with V0 system)

  mvn_swe_sweep, tabnum=tabnum, result=swp

; Energy Sweep
 
  swe_swp = fltarr(64,3)         ; energy for group=0,1,2

  swe_swp[*,0] = swp.e
  for i=0,31 do swe_swp[(2*i):(2*i+1),1] = sqrt(swe_swp[(2*i),0] * swe_swp[(2*i+1),0])
  for i=0,15 do swe_swp[(4*i):(4*i+3),2] = sqrt(swe_swp[(4*i),1] * swe_swp[(4*i+3),1])

  energy = swe_swp[*,0]
  denergy = energy
  denergy[0] = abs(energy[0] - energy[1])
  for i=1,62 do denergy[i] = abs(energy[i-1] - energy[i+1])/2.
  denergy[63] = abs(energy[62] - energy[63])

  swe_energy  = energy
  swe_denergy = denergy

  swe_Ein = swp.E_in             ; energy interior to the toroidal grids

; Energy Resolution (dE/E, FWHM), which can be a function of elevation, 
; so this array has an additional dimension.  Calibrations show that the
; variation with elevation is modest (< 1% from +55 to -30 deg, increasing
; to 4% at -45 deg).
  
  swe_de = fltarr(6,64,3)        ; energy resolution for group=0,1,2
  
  for i=0,5 do swe_de[i,*,0] = swp.de * swp.e

  for i=0,31 do begin
    swe_de[*,(2*i),1] = (swe_swp[(2*i),0]   + swe_de[*,(2*i),0]/2.) - $
                        (swe_swp[(2*i+1),0] - swe_de[*,(2*i+1),0]/2.)
    swe_de[*,(2*i+1),1] = swe_de[*,(2*i),1]
  endfor

  for i=0,15 do begin
    swe_de[*,(4*i),2] = (swe_swp[(4*i),0]   + swe_de[*,(4*i),0]/2.) - $
                        (swe_swp[(4*i+3),0] - swe_de[*,(4*i+3),0]/2.)
    for j=1,3 do swe_de[*,(4*i+j),2] = swe_de[*,(4*i),2]
  endfor

; Deflection Angle

  swe_el = fltarr(6,64,3)        ; 6 el bins per energy step for group=0,1,2
  
  swe_el[*,*,0] = swp.theta
  for i=0,31 do begin
    swe_el[*,(2*i),1] = (swe_el[*,(2*i),0] + swe_el[*,(2*i+1),0])/2.
    swe_el[*,(2*i+1),1] = swe_el[*,(2*i),1]
  endfor

  for i=0,15 do begin
    swe_el[*,(4*i),2] = (swe_el[*,(4*i),1] + swe_el[*,(4*i+3),1])/2.
    for j=1,3 do swe_el[*,(4*i+j),2] = swe_el[*,(4*i),2]
  endfor

; Deflection Angle Range

  swe_del = fltarr(6,64,3)            ; 6 del bins per energy step for group=0,1,2

  for j=0,2 do for i=0,63 do swe_del[*,i,j] = median(swe_el[*,i,j] - shift(swe_el[*,i,j],1))

; Azimuth Angle and Range

  swe_az = 11.25 + 22.5*findgen(16)   ; azimuth bins in SWEA science coord.
  swe_daz = replicate(22.5,16)        ; nominal widths

; Pitch angle mapping lookup table

  mvn_swe_padlut, lut=lut, dlat=22.5  ; table used in flight software
  swe_padlut = lut

; FOV map (unit vectors pointing to each solid angle element)

  mvn_swe_fovmap, patch_size=15, /reset

; Geometric Factor
;   Simulations give a geometric factor of 0.03 (ignoring grids, posts, MCP 
;   efficiency, scattering, and fringing fields).
;
;      posts          : 0.8  (7 deg per post * 8 posts)
;      entrance grid  : 0.7  (for both grids combined)
;      exit grid      : 0.9
;      MCP Efficiency : 0.7  (nominal, energy dependent)
;    -------------------------
;      product        : 0.35
;
;   Total estimated geometric factor from simulations: 0.03 * 0.35 = 0.01
;
;   The measured geometric factor is 0.009 (IRAP calibration).  When using V0,
;   deceleration of the incoming electrons effectively reduces the geometric
;   factor in an energy dependent manner (see mvn_swe_sweep for details).
;   This geometric factor includes the absolute MCP efficiency, since it is 
;   based on analyzer measurements in a calibrated beam.  This geometric factor
;   does not take into account cross calibration with SWIA, STATIC, and LPW.

  swe_gf = replicate(!values.f_nan,64,3)  ; per anode (cm2-ster-eV/eV)

; Simple implementation of electron suppression correction (for debugging).
; For normal processing (mvn_swe_esuppress), this should be commented out.

; dg = exp(-(swe_Ke/swe_Ein)^2.)
  dg = 1.

; Put it together.  First term is constant geometric factor with V0 
; disabled.  Second term is correction factor when V0 is enabled, based
; on electrostatic optics and conservation of phase space density.

  swe_gf[*,0] = swe_G*swp.gfw*dg
  for i=0,31 do swe_gf[(2*i):(2*i+1),1] = (swe_gf[(2*i),0] + swe_gf[(2*i+1),0])/2.
  for i=0,15 do swe_gf[(4*i):(4*i+3),2] = (swe_gf[(4*i),1] + swe_gf[(4*i+3),1])/2.

; Initialize deadtime correction

  dtc = swe_deadtime(1.,/init)

; Correction factor from cross calibration with SWIA in the solar wind.  This
; factor changes whenever an MCP bias adjustment is made, and it also drifts
; with time as the MCP gain changes.  The times of bias adjustments are recorded
; in mvn_swe_config.  The function mvn_swe_crosscal() now supercedes the variable
; swe_crosscal.  The variable swe_cc_switch controls whether or not the cross
; calibration correction is applied.  Default is to apply the correction.

  if (size(swe_cc_switch,/type) eq 0) then swe_cc_switch = 1

; Correction for electron suppression at low energies, based on monthly in-flight
; calibrations.  Note that the suppression factor is based on energies internal
; to the toroidal grids (swe_Ein).  The correction factor is time dependent.  The
; function mvn_swe_esuppress calculates the constant Ke, which is used to calculate
; the suppression correction: exp(-(Ke/E_in)^2.).

  if (size(swe_es_switch,/type) eq 0) then swe_es_switch = 1

; Add a dimension for relative variation among the 16 anodes.  This variation is
; dominated by the MCP efficiency, but I include the same dimension here for ease
; of calculation later.

  swe_gf = replicate(1.,16) # reform(swe_gf,64*3)
  swe_gf = transpose(reform(swe_gf,16,64,3),[1,0,2])

; Relative MCP efficiency
;   Note that absolute efficiency is incorporated into IRAP geometric factor.
;   The efficiency is energy dependent, peaking at around 300 eV, then falling 
;   gradually with increasing energy.  For SWEA, electrons are accelerated from 
;   the analyzer exit grid (V0) to the top of the MCP stack (+300 V).  If one
;   uses the electron energy before entering the instrument (E), then the effect
;   of V0 cancels, so the energy of an electron when it strikes the top of the 
;   MCP stack is E + 300.
;
;   The following is from Goruganthu & Wilson (Rev. Sci. Instr. 55, 2030, 1984), 
;   which fits experimental data up to 2 keV to within 2%.  (There is a typo in
;   Equation 4 of that paper.)  I extrapolate from 2 to 4.6 keV.

  alpha = 1.35
  Tmax = 2.283
  Emax = 325.
  k = 2.2

  Vbias = 300.                   ; pre-acceleration for SWEA
  Erat = (swe_swp + Vbias)/Emax  ; effect of V0 cancels when using swe_swp
  arg = Tmax*(Erat^alpha) < 80.  ; avoid underflow

  delta = (Erat^(1. - alpha))*(1. - exp(-arg))/(1. - exp(-Tmax))
  swe_mcp_eff = (1. - exp(-k*delta))/(1. - exp(-k))

; IRAP geometric factor was calibrated at 1.4 keV, so scale the MCP efficiency 
; to unity at that energy.

  Erat = (1400. + Vbias)/Emax
  delta = (Erat^(1. - alpha))*(1. - exp(-Tmax*(Erat^alpha)))/(1. - exp(-Tmax))
  eff0 = (1. - exp(-k*delta))/(1. - exp(-k))
  
  swe_mcp_eff = swe_mcp_eff/eff0

; Now include variation of MCP efficiency with anode.  This is from a rotation
; scan at 1 keV performed on 2013-02-27.  This is expected to change gradually
; in flight, with discrete jumps when the MCP HV is adjusted.
  
  swe_rgf = [0.86321, 1.09728, 1.04393, 0.88254, 0.95927, 1.07825, $
             1.07699, 0.93499, 1.04213, 1.12928, 1.11343, 0.94783, $
             0.87957, 0.96588, 1.00358, 0.98184                     ]

  swe_mcp_eff = swe_rgf # reform(swe_mcp_eff,64*3)
  swe_mcp_eff = transpose(reform(swe_mcp_eff,16,64,3),[1,0,2])

; Analyzer elevation response (from IRAP calibrations, averaged over the six
; elevation bins).  Normalization: mean(swe_dgf) = 1.  Note that rotation
; scans at different yaws in the large SSL vacuum chamber confirm behavior of
; this sort.
;
;  p = { a0 :  5.417775771d-03, $
;        a1 :  1.911692997d-05, $
;        a2 :  1.067720924d-06, $
;        a3 : -2.341636265d-08, $
;        a4 : -4.758984454d-10, $
;        a5 :  3.831231544e-12   }
;
;  theta = findgen(131) - 65.
;  dgf = polycurve(theta,par=p)
;  swe_dgf = fltarr(6,64,3)
;  
;  th_min = swp.th1 < swp.th2
;  th_max = swp.th1 > swp.th2
; 
;  for i=0,5 do begin
;    for j=0,63 do begin
;      indx = where((theta ge th_min[i,j]) and (theta le th_max[i,j]))
;      swe_dgf[i,j,0] = mean(dgf[indx])
;    endfor
;  endfor
;
;  The following is from in-flight calibrations assuming gyrotropy in 
;  the plasma frame.  The assumption is that the angular sensitivity can
;  be separated into azimuth and elevation terms that are multiplied
;  together.
;
;  dgf = [0.922951, 1.18653, 1.11294, 1.02737, 0.923664, 0.826548]
;  swe_dgf = reform((dgf # replicate(1.,64*3)),6,64,3)
;
;  Average over energy bins for group = 1,2
;
;  for i=0,31 do begin
;    swe_dgf[*,(2*i),1] = (swe_dgf[*,(2*i),0] + swe_dgf[*,(2*i+1),0])/2.
;    swe_dgf[*,(2*i+1),1] = swe_dgf[*,(2*i),1]
;  endfor
;
;  for i=0,15 do begin
;    swe_dgf[*,(4*i),2] = (swe_dgf[*,(4*i),1] + swe_dgf[*,(4*i+3),1])/2.
;    for j=1,3 do swe_dgf[*,(4*i+j),2] = swe_dgf[*,(4*i),2]
;  endfor
;
; Normalize: mean(swe_dgf[*,i,j]) = 1.
;
;  for i=0,63 do begin
;    for j=0,2 do begin
;      swe_dgf[*,i,j] = swe_dgf[*,i,j]/mean(swe_dgf[*,i,j])
;    endfor
;  endfor
;  
;  swe_dgf = transpose(swe_dgf,[1,0,2])

  swe_dgf = replicate(1., 64, 6, 3)  ; Don't use deflector-based correction

; Corrections for individual solid angle bins based on in-flight calibrations
; (see mvn_swe_fovcal).  This method corrects for sensitivity variations in 
; azimuth and elevation independently.  This includes edge effects at the 
; maximum and minimum deflection angles, and partial spacecraft blockage.
; Fully blocked bins have a sensitivity of unity, but these are masked (see 
; next section).  Note that sensitivity variations in azimuth are relative to
; the ground calibration contained in swe_rgf, above.

  if (size(swe_ff_state,/type) eq 0) then swe_ff_state = 1

; Spacecraft blockage mask (~27% of sky, deployed boom, approximate)
;   Complete blockage: 0,  1,  2,  3, 17, 18  (masked)
;   Partial blockage: 14, 15, 16, 31          (masked)
;   Partial blockage:  4, 19, 20, 30          (compensated with flatfield)

  swe_sc_mask = replicate(1B, 96, 2)  ; 96 solid angle bins, 2 boom states
  
  swe_sc_mask[0:31,0] = 0B                                    ; stowed boom
; swe_sc_mask[[0,1,2,3,4,14,15,16,17,18,19,20,30,31],1] = 0B  ; deployed boom, aggressive
  swe_sc_mask[[0,1,2,3,  14,15,16,17,18,         31],1] = 0B  ; deployed boom

; Electron rest mass

  c = 2.99792458D5               ; velocity of light [km/s]
  mass_e = (5.10998910D5)/(c*c)  ; electron rest mass [eV/(km/s)^2]

  if keyword_set(list) then begin
    print, "  analyzer constant  = ", swe_Ka, format='(a,f5.2)'
    print, "  geometric factor   = ", swe_G*16., format='(a,e9.2)'
    print, "  elec. suppression  = ", swe_Ke, format='(a,f5.2)'
    print, "  deadtime per anode = ", swe_dead, format='(a,e9.2)'
    print, "  max deadtime corr. = ", 1./swe_min_dtc, format='(a,f5.2)'
    print, ""
    dmodel = ['non-',''] + 'paralyzable'
    onoff = ['off','on']
    print, "  deadtime model     =  " + dmodel[swe_paralyze]
    print, "  swe-swi crosscal   =  " + onoff[swe_cc_switch]
    print, "  e- suppr. corr.    =  " + onoff[swe_es_switch]
    print, "  angular calib.     =  " + onoff[swe_ff_state]
  endif

  return

end
