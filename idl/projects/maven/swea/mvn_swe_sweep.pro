;+
;PROCEDURE:   mvn_swe_sweep
;PURPOSE:
;  Generates a SWEA sweep table exactly as done in flight software (same digital 
;  commands, same checksum).  This table is combined with calibration data to 
;  determine energy sweep and deflection angle.  This routine can be used to 
;  generate new tables for upload to non-volatile memory in the PFDPU or to SWEA
;  directly (via CDI).  It can also be used to create files for comparison with
;  PFDPU EEPROM memory dumps.
;
;  Nine pre-defined tables are provided via keyword TABNUM.  Tables 1-4 were only
;  used in cruise and have been obsolete since orbit insertion.  Tables 5 and 6 
;  were loaded into flight software during commissioning in October 2014.  Table 5
;  is used nearly all of the time.  Table 6 was used once a month until July 2018
;  to calibrate and monitor the low energy response.  Tables 7-9 are high cadence
;  tables at a single energy used during special observing sequences.
;
;KEYWORDS:
;       RESULT:       Named variable to hold result structure: analyzer, deflector,
;                     and V0 sweeps, energy/angle sweeps, energy resolution (dE/E)
;                     and geometric factor vs. energy.
;
;       TPLOT:        Create tplot variables, but do not plot them.
;
;       DOPLOT:       Plot Va, Vd, V0, E, dE/E, X, TH, and GFW for one 2-sec sweep.
;                     In a separate window, plot the deflection angle coverage as 
;                     a function of energy.  WARNING: this can alter the time range
;                     of your tplot window.  Use keyword TSTART to align the sweep
;                     variables with any other tplot variables.
;
;       TSTART:       Arbitrary start time for DOPLOT.  Default = 0 ('1970-01-01').
;
;       PROP:         Print the table properties: checksum, energy and angle ranges.
;
;       TABNUM:       Table number corresponding to predefined settings.  Currently,
;                     there are eight tables defined:
;
;                       1 : Xmax = 6., Vrange = [0.75, 750.], V0scale = 1., /old_def
;                           primary table for ATLO and Inner Cruise (first turnon)
;                             -64 < Elev < +66 ; 7 < E < 4650
;                              Chksum = 'CC'X
;
;                       2 : Xmax = 6., Vrange = [0.75, 375.], V0scale = 1., /old_def
;                           alternate table for ATLO and Inner Cruise (never used)
;                             -64 < Elev < +66 ; 7 < E < 2340
;                              Chksum = '1E'X
;
;                       3 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0., /old_def
;                           primary table for Outer Cruise
;                             -59 < Elev < +61 ; 3 < E < 4630
;                              Chksum = 'C0'X
;                              GSEOS svn rev 8360
;
;                       4 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1., /old_def
;                           alternate table for Outer Cruise
;                             -59 < Elev < +61 ; 3 < E < 4650
;                              Chksum = 'DE'X
;                              GSEOS svn rev 8361
;
;                       5 : Xmax = 5.5, Vrange = [3./Ka, 750.], V0scale = 0.
;                           primary table for Transition and Science
;                             -59 < Elev < +61 ; 3 < E < 4630
;                              Chksum = 'CC'X
;                              GSEOS svn rev 8481
;                              LUT = 0
;
;                       6 : Xmax = 5.5, Vrange = [2./Ka, 750.], V0scale = 1.
;                           alternate table for Transition and Science
;                             -59 < Elev < +61 ; 3 < E < 4650
;                              Chksum = '82'X
;                              GSEOS svn rev 8482
;                              LUT = 1
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
;                       9 : Xmax = 5.5, Erange = [125.,125.], V0scale = 0.
;                           Hires 32-Hz at 125 eV
;                             -59 < Elev < +61 ; E = 125
;                              Chksum = '00'X
;                              LUT = 1
;
;                     Otherwise, use the following keywords to define the sweep.
;
;       CHKSUM:       Use checksum to determine which table to use.  Currently,
;                     this only uniquely identifies tables 5 and 6.  All high
;                     cadence tables (7-9) have a checksum of zero.  The routine
;                     mvn_swe_getlut can use one of three different methods for
;                     determining the sweep table in use.
;
;       Xmax:         Maximum ratio of deflector voltage to analyzer voltage.
;                     (Controls maximum deflection angle.)  Default = 5.5
;
;       V0scale:      Scale factor for V0 (a number from 0 to 1).
;                         |V0| = E/2 < (25*V0scale) Volts
;                     Default = 0.
;
;       Vrange:       Voltage range of sweep (commanded).  Default = [0.75, 750.].
;
;       Erange:       Energy range of sweep (commanded).  Takes precendence over Vrange.
;                     This keyword allows one to set the energy range, correcting for
;                     V0, if necessary.  No default.
;
;       OLD_DEF:      Use the old method for sweeping the deflectors.  This is valid
;                     for ground tests, early cruise checkout (Dec 6-7, 2013), and
;                     outer cruise.
;
;       DUMPFILE:     Saves an ascii hex dump to this named file, for comparison with
;                     PFDPU EEPROM dump.
;
;       CMDFILE:      Set this to the full path and filename for an ascii command file
;                     for upload to the PFDPU.
;
;       MEMADDR:      PFDPU memory address to begin loading table.  Only used if
;                     FORMAT = 0 or 1.
;
;       SWEBUF:       SWEA SLUT buffer to load table to (0-7).  Only used if FORMAT = 2.
;
;       FORMAT:       Output sweep table in specified format:
;                        0 = old PFDPU format (bytes)
;                        1 = new PFDPU format (4-byte words)
;                        2 = SWEA native format (2-byte words)
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-07-14 11:40:53 -0700 (Thu, 14 Jul 2022) $
; $LastChangedRevision: 30933 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_sweep.pro $
;
;CREATED BY:	David L. Mitchell  2014-01-03
;FILE:  mvn_swe_sweep.pro
;-
pro mvn_swe_sweep, result=dat, prop=prop, doplot=doplot, tabnum=tabnum, Xmax=Xmax, $
                   V0scale=V0scale, Vrange=Vrange, Erange=Erange, old_def=old_def, $
                   chksum=chksum, V0tweak=V0tweak, dumpfile=dumpfile, cmdfile=cmdfile, $
                   memaddr=memaddr, swebuf=swebuf, format=format, tstart=tstart, tplot=tplot

  @mvn_swe_com

  if (size(swe_Ka,/type) ne 4) then swe_Ka = 6.17
  if (size(tabnum,/type) eq 0) then tabnum = 0
  if (size(chksum,/type) ne 0) then tabnum = mvn_swe_tabnum(chksum)
  if keyword_set(old_def) then old_def = 1 else old_def = 0
  if not keyword_set(V0tweak) then V0tweak = {gain:1.00, offset:0.}
  if not keyword_set(tstart) then tstart = 0D else tstart = (time_double(tstart))[0]
  doplot = keyword_set(doplot)
  if (doplot) then tplot = 1
  if not keyword_set(format) then format = 0
  if not keyword_set(swebuf) then swebuf = 0
  case format of
      0  : ; print, "Using old PFDPU format."
      1  : ; print, "Using new PFDPU format."
      2  : ; print, "Using SWEA format."
    else : begin
             print, "Unrecognized format: ", format
             return
           end
  endcase

  Ka = swe_Ka   ; analyzer constant

; Use predefined parameters, if possible

  case tabnum of
    0 : begin
          old_def = 0
          old_cal = 0
          comment = 'Custom table'
        end

    1 : begin
          Xmax = 6D
          V0scale = 1D
          Vrange = [0.75D, 750D]
          old_def = 1
          old_cal = 1
          comment = 'ATLO and Inner Cruise: SWIND (V0 on)'
        end

    2 : begin
          Xmax = 6D
          V0scale = 1D
          Vrange = [0.75D, 375D]
          old_def = 1
          old_cal = 1
          comment = 'ATLO and Inner Cruise: INTER (V0 on)'
        end

    3 : begin
          Xmax = 5.5D
          V0scale = 0D
          Vrange = [3D/Ka, 750D]
          old_def = 1
          old_cal = 0
          comment = 'Outer Cruise: SWIND (V0 off)'
        end

    4 : begin
          Xmax = 5.5D
          V0scale = 1D
          Vrange = [2D/Ka, 750D]
          old_def = 1
          old_cal = 0
          comment = 'Outer Cruise: INTER (V0 on)'
        end

    5 : begin
          Xmax = 5.5D
          V0scale = 0D
          Vrange = [3D/Ka, 750D]
          old_def = 0
          old_cal = 0
          comment = 'Transition and Science: SWIND (V0 off)'
        end

    6 : begin
          Xmax = 5.5D
          V0scale = 1D
          Vrange = [2D/Ka, 750D]
          old_def = 0
          old_cal = 0
          comment = 'Transition and Science: INTER (V0 on)'
        end

    7 : begin
          Xmax = 5.5D
          V0scale = 0D
          e200 = 199.05093D  ; energy bin 27 of table 5
          Erange = [e200,e200]
          old_def = 0
          old_cal = 0
          comment = 'Hires 32-Hz at 200 eV (V0 off)'
        end

    8 : begin
          Xmax = 5.5D
          V0scale = 0D
          e50 = 49.168077D   ; energy bin 39 of table 5
          Erange = [e50,e50]
          old_def = 0
          old_cal = 0
          comment = 'Hires 32-Hz at 50 eV (V0 off)'
        end

    9 : begin
          Xmax = 5.5D
          V0scale = 0D
          e125 = 124.89275D  ; energy bin 31 of table 5
          Erange = [e125,e125]
          old_def = 0
          old_cal = 0
          comment = 'Hires 32-Hz at 125 eV (V0 off)'
        end

    else : begin
             print,"Unrecognized table number: ",tabnum
             return
           end
  endcase

; Maximum value of Vd/Va (controls maximum deflection angle)

  if (size(Xmax,/type) eq 0) then maxdefx = 5.5D else maxdefx = double(Xmax)

; Control of V0 (affects energy resolution and geometric factor)
;   This keyword should be 0 or 1.  Intermediate values are not useful.

  if (size(V0scale,/type) eq 0) then V0scale = 0D else V0scale = double(V0scale)

; Sweep constants

  maxdac = 65536D
  nbins = 64                   ; number of energy bins
  nsteps = 28                  ; number of steps at each energy
  nwait = 4                    ; pause at beginning of each energy step
  nramp = (nsteps - nwait)/2   ; number of steps for each deflector

; HVPS gain factors for each of the surfaces

  Ga = 187.55D                  ; analyzer gain
  Gd1 = 936.72D                 ; deflector 1 gain
  Gd2 = 937.34D                 ; deflector 2 gain
  Gd = (Gd1 + Gd2)/2D
  G0 = 6.248D                   ; V0 gain

  if (old_cal) then begin       ; old values for tables 1 and 2 only
    Ka = 6.1D                   ; needed to exactly replicate FSW tables
    Ga = 187.60D
    Gd = 943.28D
    G0 = 6.249D
  endif

  Ca_max = 4D                   ; maximum analyzer control voltage
  Cd_max = 1.92D                ; maximum deflector control voltage
  C0_max = 4D                   ; maximum V0 control voltage

  Va_max = Ga*Ca_max            ; maximum inner hemisphere potential
  Vd_max = Gd*Cd_max            ; maximum deflector potential
  V0_max = G0*C0_max            ; maximum V0 potential (absolute value)  

; Gain on digital board output (resistor divider)

  Kd = 9.09D/7.32D
  Mdef = Ga/(Gd*Kd)

; Range of commanded analyzer voltages

  if keyword_set(Erange) then begin
    Erange = double(Erange)
    if (V0scale gt 0D) then kv0 = 1.5D else kv0 = 1D
    Va_low = min(Erange)/(kv0*Ka)
    Va_high = max(Erange)/Ka < Va_max
    Vrange = [Va_low, Va_high]
  endif

  if not keyword_set(Vrange) then Vrange = [0.75D, 750D] else Vrange = double(Vrange)
  Va_low = min(Vrange, max=Va_high)

  Emin = Ka*Va_low                  ; energy internal to the toroidal grids
  Emax = Ka*Va_high
  dlogE = alog(Emax/Emin)/double(nbins - 1)

; Generate Sweep Pattern
; Voltages

  Va = dblarr(nbins*nsteps)         ; analyzer
  Vd1 = Va                          ; deflector 1
  Vd2 = Va                          ; deflector 2
  V0 = Va                           ; V0

; Digital Commands

  CMD_ANLZ = lonarr(nbins*nsteps)   ; analyzer
  CMD_DEF1 = CMD_ANLZ               ; deflector 1
  CMD_DEF2 = CMD_ANLZ               ; deflector 2
  CMD_V0 = CMD_ANLZ                 ; V0

  for i=0,(nbins-1) do begin
    anlzn = sqrt(Emin/(Ca_max*Ka*Ga))*exp(double(nbins - 1 - i)*dlogE/2D)
    CMD_ANLZ[(nsteps*i):(nsteps*(i+1) - 1)] = long(maxdac*anlzn < (maxdac - 1D))
    Va[(nsteps*i):(nsteps*(i+1) - 1)] = Va_max*(anlzn*anlzn)

    v0n = V0scale*(Ka/2D)*(Ga/G0)*(anlzn*anlzn)
    CMD_V0[(nsteps*i):(nsteps*(i+1) - 1)] = long(maxdac*v0n < (maxdac - 1D))
    V0[(nsteps*i):(nsteps*(i+1) - 1)] = V0_max*v0n < V0_max
    
    Xmax = (Vd_max/Va_max)/(anlzn*anlzn) < maxdefx

    if (old_def) then dX = Xmax/double(nramp - 1)      $   ; ATLO and cruise
                 else dX = 2D*Xmax/double(2*nramp - 1)     ; transition and beyond

    X = reverse(Xmax - dX*dindgen(nramp))

    if (i mod 2) then begin
      k = nsteps*i
      for j=0,(nwait+nramp-1) do Vd1[k++] = 0D
      for j=0,(nramp-1) do begin
        defn = X[j]*Mdef
        CMD_DEF1[k] = long(maxdac*defn < (maxdac - 1D))
        Vd1[k] = X[j]*Va[nsteps*i]
        k++
      endfor

      k = nsteps*i
      for j=0,(nwait-1) do begin
        defn = Xmax*Mdef
        CMD_DEF2[k] = long(maxdac*defn < (maxdac - 1D))
        Vd2[k] = Xmax*Va[nsteps*i]
        k++
      endfor
      for j=0,(nramp-1) do begin
        defn = X[nramp - 1 - j]*Mdef
        CMD_DEF2[k] = long(maxdac*defn < (maxdac - 1D))
        Vd2[k] = X[nramp - 1 - j]*Va[nsteps*i]
        k++
      endfor
      for j=0,(nramp-1) do Vd2[k++] = 0D
    endif else begin
      k = nsteps*i
      for j=0,(nwait-1) do begin
        defn = Xmax*Mdef
        CMD_DEF1[k] = long(maxdac*defn < (maxdac - 1D))
        Vd1[k] = Xmax*Va[nsteps*i]
        k++
      endfor
      for j=0,(nramp-1) do begin
        defn = X[nramp - 1 - j]*Mdef
        CMD_DEF1[k] = long(maxdac*defn < (maxdac - 1D))
        Vd1[k] = X[nramp - 1 - j]*Va[nsteps*i]
        k++
      endfor
      for j=0,(nramp-1) do Vd1[k++] = 0D

      k = nsteps*i
      for j=0,(nwait+nramp-1) do Vd2[k++] = 0D
      for j=0,(nramp-1) do begin
        defn = X[j]*Mdef
        CMD_DEF2[k] = long(maxdac*defn < (maxdac - 1D))
        Vd2[k] = X[j]*Va[nsteps*i]
        k++
      endfor
    endelse
  endfor

; Calculate checksum

  msb = [CMD_ANLZ, CMD_DEF1, CMD_DEF2, CMD_V0]/256L
  lsb = [CMD_ANLZ, CMD_DEF1, CMD_DEF2, CMD_V0] mod 256L
  
  chksum = byte(total([msb,lsb],/int) mod 256L)

; Tweak V0 based on in-flight calibration (April 4, 2014).  This applies to
; V0 only; it does not change the command voltages (CMD_V0).

  V0 = V0*V0tweak.gain + V0tweak.offset

; Analyzer and deflector voltages are shifted by V0.  The inner toroidal grid,
; top cap, outer hemisphere, and exit grid are all set to V0.  That is, the
; entire instrument interior to the inner toroidal grid is referenced to V0.
; The optics of the instrument interior works as if the analyzer and deflector 
; voltages are unshifted.  Thus, to calculate deflection angle, use the 
; unshifted values of Va and Vd.  Deflection angle is a linear function of 
; X = Vd/Va, which was determined during final calibrations (March 2-6, 2013).

  X = (Vd1 - Vd2)/Va
  theta = -(10.888*X - 0.9046)

; The energy acceptance inside the instrument depends on the voltage across
; the hemispheres.  Both hemispheres are biased by V0, so take the unshifted 
; value of Va to calculate the energy acceptance inside the instrument.

  E_in = Va*Ka

; To get the energy of electrons before crossing the toroidal grids, shift
; by V0.  (The instrument is effectively measuring higher energy electrons than
; would be selected without V0.)  dE/E corresponds to the interior (lower) 
; energy, which improves the effective energy resolution.  (Note that V0 is
; negative, but this code uses the absolute value.)

  E = E_in + V0

  dE_E = (0.17*E_in)/E    ; effective energy resolution (FWHM)
                          ; = 0.17*f, as defined below

; The geometric factor is reduced when using V0 by the factor "gfw".  This is
; simply the conservation of phase space density between the inner and outer
; toroidal grids.

  f = 1./(1. + V0/E_in)
  gfw = f*f

; Generate the energy/angle array
; 16 azimuths x 6 elevations for each of 64 energies

  el = fltarr(448)  ; 7 deflections for each of 64 energy bins, first is discarded
  el_hi = el
  el_lo = el

  for i=0,447 do begin
    j = i*4
    el_hi[i] = theta[j]
    el_lo[i] = theta[j+3]
    el[i] = total(theta[j:(j+3)])
  endfor
  el = el/4.
  
  el = reform(el,7,64)
  el = el[1:6,*]
  
  el_hi = reform(el_hi,7,64)
  el_hi = el_hi[1:6,*]
  
  el_lo = reform(el_lo,7,64)
  el_lo = el_lo[1:6,*]
  
  for i=1,63,2 do begin
    el[*,i] = reverse(el[*,i])
    el_lo[*,i] = reverse(el_lo[*,i])
    el_hi[*,i] = reverse(el_hi[*,i])
  endfor

; Generate a time series

  if keyword_set(tplot) then begin
    dt = 1.95D/double(nbins*nsteps-1)
    t = tstart + dt*dindgen(nbins*nsteps)

    store_data,'Va',data={x:t, y:(Va-V0)}
    options,'Va','psym',10
    store_data,'Vd1',data={x:t, y:(Vd1-V0)}
    options,'Vd1','psym',10
    store_data,'Vd2',data={x:t, y:(Vd2-V0)}
    options,'Vd2','psym',10
    store_data,'V0',data={x:t, y:V0}
    options,'V0','psym',10

    store_data,'X',data={x:t, y:X}
    options,'X','psym',10
    ylim,'X',-6,6,0

    store_data,'theta',data={x:t, y:theta}
    options,'theta','psym',10
    ylim,'theta',-65,65,0

    store_data,'E',data={x:t, y:E}
    options,'E','psym',10
    ylim,'E',0,0,1

    store_data,'dE',data={x:t, y:dE_E}
    options,'dE','ytitle','dE/E'
    options,'dE','psym',10
    ylim,'dE',0.1,0.2,0
    
    store_data,'GFW',data={x:t, y:gfw}
    options,'GFW','psym',10
    ylim,'GFW',0,1.1,0

    pans = ['Va','Vd1','Vd2','V0','X','theta','E','dE','GFW']
    options,pans,'colors',4

    if (doplot) then begin
      timefit,tstart+[0D,2D]
      tplot,pans
    endif
  endif

; Calculate energy sampling

  indx = 28*indgen(64) + 4
  E = E[indx]
  dE_E = dE_E[indx]
  gfw = gfw[indx]
  E_in = E_in[indx]

  delta_E = (E - shift(E,-1))/sqrt(E*shift(E,-1))/dE_E
  delta_E[63] = delta_E[62]
  
  th = reform(theta,28,64)
  th = th[4:27,*]
  
  dat = {E:E, dE:dE_E, theta:el, th1:el_hi, th2:el_lo, gfw:gfw, $
         Va:Va, Vd1:Vd1, Vd2:Vd2, V0:V0, delta_E:delta_E, $
         cmd_anlz:cmd_anlz, cmd_def1:cmd_def1, cmd_def2:cmd_def2, $
         cmd_v0:cmd_v0, chksum:chksum, tabnum:tabnum, th:th, $
         E_in:E_in}

  if keyword_set(prop) then begin
    print,'Table number: ',tabnum,format='(a,i2)'
    print,'Checksum: ',chksum,format='(a,Z2.2," (hex)")'
    print,'Energy range: ',min(E),max(E),format='(a,f7.2," , ",F7.2)'
    print,'Angle  range: ',min(el_lo),max(el_hi),format='(a,f7.2," , ",F7.2)'
    print,comment
  endif

  if (doplot) then begin
    twin = !d.window
    win,/free,relative=twin,dx=10,/top
    pwin = !d.window

    plot_oi,dat.E,dat.theta[0,*],xrange=[1.,1.e4],yrange=[-70,70],/ysty,psym=-4, $
         xtitle='Energy (eV)', ytitle='Deflection Angle', charsize=1.4
    oplot,dat.E,dat.th1[0,*]
    oplot,dat.E,dat.th2[0,*]
    for i=1,5 do begin
      oplot,dat.E,dat.theta[i,*],psym=-4,color=i
      oplot,dat.E,dat.th1[i,*],color=i
      oplot,dat.E,dat.th2[i,*],color=i
    endfor

    wset,twin
  endif
  
  if (size(dumpfile,/type) eq 7) then begin
    openw, lun, dumpfile, /get_lun
    
    msb = cmd_def2 / 256
    lsb = cmd_def2 mod 256
    for i=0,223 do begin
      for j=i*8,i*8+7 do printf,lun,msb[j],lsb[j],format='(z2.2," ",z2.2," ",$)'
      printf,lun,''
    endfor
    
    msb = cmd_def1 / 256
    lsb = cmd_def1 mod 256
    for i=0,223 do begin
      for j=i*8,i*8+7 do printf,lun,msb[j],lsb[j],format='(z2.2," ",z2.2," ",$)'
      printf,lun,''
    endfor
    
    msb = cmd_anlz / 256
    lsb = cmd_anlz mod 256
    for i=0,223 do begin
      for j=i*8,i*8+7 do printf,lun,msb[j],lsb[j],format='(z2.2," ",z2.2," ",$)'
      printf,lun,''
    endfor
    
    msb = cmd_v0 / 256
    lsb = cmd_v0 mod 256
    for i=0,223 do begin
      for j=i*8,i*8+7 do printf,lun,msb[j],lsb[j],format='(z2.2," ",z2.2," ",$)'
      printf,lun,''
    endfor

    free_lun,lun

  endif
  
  if (size(cmdfile,/type) eq 7) then begin
    if not keyword_set(memaddr) then memaddr = '0'XL

    nswp = 1792            ; number of time steps
    nbytes = nswp*4*2      ; time steps x surfaces x bytes-per-setting
    cmd = bytarr(nbytes)
    even = 2*indgen(nswp)  ; big endian
    odd = even + 1

    cmd[even] = cmd_def2 / 256
    cmd[odd]  = cmd_def2 mod 256
    even += 2*nswp
    odd += 2*nswp
    cmd[even] = cmd_def1 / 256
    cmd[odd]  = cmd_def1 mod 256
    even += 2*nswp
    odd += 2*nswp
    cmd[even] = cmd_anlz / 256
    cmd[odd]  = cmd_anlz mod 256
    even += 2*nswp
    odd += 2*nswp
    cmd[even] = cmd_v0 / 256
    cmd[odd]  = cmd_v0 mod 256

    case format of
      0 : cmd = strtrim(string(cmd, format='(i)'),2)
      1 : begin
            cmd = string(cmd, format='(z2.2)')
            cword = strarr(nbytes/4)
            for i=0,(nbytes-1),4 do cword[i/4] = '0x' + cmd[i] + cmd[i+1] + cmd[i+2] + cmd[i+3]
            cmd = cword
          end
      2 : begin
            cmd = string(cmd, format='(z2.2)')
            cword = strarr(nbytes/2)
            for i=0,(nbytes-1),2 do cword[i/2] = '0x' + cmd[i] + cmd[i+1]
            cmd = cword
          end
      else : begin
               print, "This is impossible!"
               return
             end
    endcase

    openw, lun, cmdfile, /get_lun

      if (format lt 2) then begin
        printf,lun,"from MAVEN import *"
        printf,lun,"from fswutil import *"
        printf,lun,"import maven_log"
        printf,lun,"log = maven_log.log()"
        printf,lun,"from __main__ import *"
        printf,lun,"cmd = maven_cmd()"
        printf,lun,""
        printf,lun,"def main():"
        printf,lun,""
        printf,lun,"    LOAD_EEPROM_START(112)"
        j = 0
        nload = nbytes/128
        for i=0,(nload-1) do begin
          if (format eq 1) then begin
            head = 'pfdpu_load(0x' + string(memaddr,format='(z6.6)') + ',"'
            tail = '")'
            printf,lun,head,cmd[j:(j+31)],tail,format='(4x,a,31(a,","),a,a)'
            j += 32
          endif else begin
            head = 'pfdpu_load(0x' + string(memaddr,format='(z6.6)') + ',['
            tail = '])'
            printf,lun,head,cmd[j:(j+127)],tail,format='(4x,a,127(a,", "),a,a)'
            j += 128
          endelse
          printf,lun,"    sleep(0.5)"
          memaddr += 128  ; byte address, not word address
        endfor

        nleft = nbytes mod 128
        if (nleft gt 0) then begin
          if (format eq 1) then begin
            k = nleft/4 - 1
            fmt = '(4x,a,' + strtrim(string(k),2) + '(a,","),a,a)'
            head = 'pfdpu_load(0x' + string(memaddr,format='(z6.6)') + ',"'
            tail = '")'
            printf,lun,head,cmd[j:(j+k)],tail,format=fmt
          endif else begin
            k = nleft - 1
            fmt = '(4x,a,' + strtrim(string(k),2) + '(a,", "),a,a)'
            head = 'pfdpu_load(0x' + string(memaddr,format='(z6.6)') + ',['
            tail = '])'
            printf,lun,head,cmd[j:(j+k)],tail,format=fmt
          endelse
          printf,lun,"    sleep(0.5)"
        endif

        printf,lun,"    LOAD_EEPROM_END()"

      endif else begin
        swebuf = strtrim(string(swebuf,format='(i)'),2)
        printf,lun,"cmd.SWE_SSCTL(0)"
        printf,lun,"time.sleep(0.1)"
        nload = nbytes/8
        for j=0,3 do begin
          addr = string(2048*j,format='("0x",z4.4)')  ; word address, not byte address
          printf,lun,"cmd.SWE_LUTPTR(" + swebuf + "," + addr + ")"
          printf,lun,"time.sleep(0.1)"
          for i=0,(nload-1) do begin
            printf,lun,"cmd.SWE_LUTDAT(" + cmd[i + nswp*j] + ")"
            printf,lun,"time.sleep(0.1)"
          endfor
        endfor
      endelse

    free_lun,lun
  endif

  return

end
