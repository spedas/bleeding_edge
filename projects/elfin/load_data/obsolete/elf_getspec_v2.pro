;
; Performs pitch angle determination and generation of energy and pitch angle spectra
; Including precipitating and trapped spectra separately. EPDI can be treated similarly, but not done yet
; Regularize keyword performs rebinning of data on regular sector centers starting at zero (rel.to the time
; of dBzdt 0 crossing which corresponds to Pitch Angle = 90 deg and Spin Phase angle = 0 deg.).
; If the data has already been collected at regular sectors there is no need to perform this.
;
; elb can be done similarly but the code has not been generalized to either a or b yet. But this is straightforward.
;
; The routine assumes that the position, attitude and particle data type it needs
; from the appropriate spacecraft (e.g., ela_pef_nflux and 'ela_att_gei', 'ela_pos_gei') have been loaded already!!!!!
; It also assumes the user has the ability to run T89 routine (.dlm, .dll have been included in their distribution)!!!
;
pro elf_getspec_v2,regularize=regularize,energies=userenergies,dSect2add=userdSectr2add,dSpinPh2add=userdPhAng2add, $
  type=usertype,LCpartol2use=userLCpartol,LCpertol2use=userLCpertol,get3Dspec=get3Dspec, no_download=no_download, $
  probe=probe
  ;
  ;
  ; INPUTS
  ;
  ; userenergies is an [Nusrergiesx2] array of Emin,Emax energies to use for pitch-angle spectra
  ;
  ; example:
  ;
  ; elf_getspec,energies=[[50.,160.],[160.,345.],[345.,900.],[900.,7000.]],/regularize ; gives same results as:
  ; elf_getspec,/regularize
  ;
  ; dSect2add is number of sectors to add to sectnum to bring 0 sector closer to dBzdt zero crossing time
  ; dSpinPh2add is number of degrees (can be floating point) to add on top of sectors (+/- 11) for the same reason
  ; type is the type of data to process (cps, nflux...)
  ; LCpartol2use (deg) is losscone tolerance in the parallel (or antiparallel) direction (restricing it by this in para, anti spectra)
  ;     (default is half the field of view, +FOVo2=11deg, which is making the loss/antiloss cone smaller by this amount (cleaner))
  ; LCpertol2use (deg) is same but in the perp direction (restricting it to closer to 90deg). So negative val means opening it.
  ;     (default is to open the perp direction by FOVo2, not restricting it, so negative value)
  ;
  ; OUTPUTS
  ;
  ; Note: numchannels is the number of pitch angle spectrograms one per user-defined energy "channel" to be produced
  ;       Max_numchannels is the maximum possible number of energies available by the raw data
  ;       nhalfspinsavailable = number of half-spins in the time selected, each constituting a single pitch angle spectrum
  ;       nspinsectors = number of sectors in a spin. This is 2* the number of independent spin phases or pitch angles per half-spin
  ;                typically this is 16 or 8 spin phases or pitch angles per half-spin.
  ;                However for plotting purposes 2 angles are added for spin phases with NaNs as values, and
  ;                1 angle is added for pitch angles (a repeat of the next value) to show complete and symmetric pitchangle coverage
  ;
  ; POTENTIAL TPLOT VARIABLES THAT CAN BE PRODUCED (BUT CANNOT BE DIRECTLY PLOTTED AS THEY ARE 3DIMENSIONAL) WITH KEYWORD get3Dspec
  ;
  ; 'ela_pef_pa_spec'              : this is nhalfspinsavailable x nspinsectors/2 x numchannels  ; 3D array no sectors added
  ; 'ela_pef_pa_reg_spec'          : if regularized keyword present same dimensions as above
  ; 'ela_pxf_pa_spec2plot'         : this adds 2 sectors on either side for plotting purposes ( dim = nhalfspinsavailable x (2+nspinsectors/2) x numchannels
  ; 'ela_pef_pa_reg_spec2plot'     : same but for regularized, only adds 1 sector, 180, since it starts from 0 (or adds 0 if it starts from 180) so 1+nspinsectors/2
  ; 'ela_pef_pa_spec2plot_full'    : same as 'ela_pef_pa_spec2plot' but for the full energy complement, so dim = nhalfspinsavailable x 2+nspinsectors/2 x Max_numchannels
  ; 'ela_pef_pa_reg_spec2plot_full': same as 'ela_pef_pa_reg_spec2plot' but for Max_numchannels, so dim = nhalfspinsavailable x 1+nspinsectors/2 x Max_numchannels
  ;
  ; ESSENTIAL TPLOT VARIABLES THAT ARE BEIND PRODUCED AND CAN BE PLOTTED AS SPECTROGRAMS
  ;
  ; 'ela_pef_lossconedeg'          : the losscone in the direction going down (0-90 or 90-180 depending on hemisphere)
  ; 'ela_pef_antilossconedeg'      : its supplementary (180-losscone)
  ; 'ela_pef_pa_spec2plot_ch?'     : numchannels pitch angle spectrograms for ? channel
  ; 'ela_pef_pa_reg_spec2plot_ch?' : numchannels regularized pitch angle spectrograms for ? channel
  ; 'ela_pef_pa_spec2plot_ch?LC' and 'ela_pef_pa_reg_spec2plot_ch?LC: same as above but pseudovariables, including losscone/antilosscone overplotted
  ;
  ; 'ela_pef_en_spec2plot_omni/para/perp/anti': energy spectra averaged over phase space within pitch angle range specified nhalfspinsavailable x Max_numchannels
  ; 'ela_pef_en_reg_spec2plot_omni/para/perp/anti': same as above but obtained from regularized versions of the pitch angle spectra
  ;
  ;
  ; note that dPhAng2add more than +/- 11 does not work. You have to add sectors rather than increase dPhAng2add
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if keyword_set(userdSectr2add) then dSectr2add=userdSectr2add else $
    dSectr2add=1       ; Here specify default # of sectors to add
  if keyword_set(userdPhAng2add) then dPhAng2add=userdPhAng2add else $
    dPhAng2add=01.0    ; Here specify default # of degrees to add in addition to the sectors
  if keyword_set(usertype) then mytype=usertype else $
    mytype='nflux'     ; Here specify default data type to act on
  FOVo2=11.          ; Field of View divided by 2 (deg)
  if keyword_set(userLCpartol) then LCfatol=userLCpartol else $
    LCfatol=FOVo2 ; in field aligned, fa, direction (para or anti)
  if keyword_set(userLCpertol) then LCfptol=userLCpartol else $
    LCfptol=-FOVo2 ; in field perp, fp, direction
  if keyword_set(no_download) then no_download=1 else no_download=0
  if ~keyword_set(probe) then probe='a' else probe=probe
  ;
  ; THESE "ELA" and "PEF" STRINGS IN THE FEW LINES BELOW CAN BE CAST INTO USER-SPECIFIED SC (A/B) AND PRODUCT (PEF/PIF) IN THE FUTURE
  ;
  ; ensure attitude is at same resolution as position
  ;
  mysc=probe
  eori='e'
  mystring='el'+mysc+'_p'+eori+'f_'
  ;
  pival=double(!PI)
  ;
  copy_data,'el'+mysc+'_att_gei','elx_att_gei'
  copy_data,'el'+mysc+'_pos_gei','elx_pos_gei'
  tinterpol_mxn,'elx_att_gei','elx_pos_gei'
  tnormalize,'elx_att_gei_interp',newname='elx_att_gei'
  ;
  copy_data,mystring+mytype,'elx_pxf'; DEFAULT UNITS ARE NFLUX; CODE ASSUMES TYPE EXISTS!; COPY INTO GENERIC VARIABLE TO AVOID CLASHES
  copy_data,mystring+'sectnum','elx_pxf_sectnum'; COPY INTO GENERIC VARIABLE TO AVOID CLASHES
  copy_data,mystring+'spinper','elx_pxf_spinper'; COPY INTO GENERIC VARIABLE TO AVOID CLASHES
  get_data,'elx_pxf',data=elx_pxf,dlim=mypxfdata_dlim,lim=mypxfdata_lim
  elx_pxf.v=[50.0000,      80.0000,      120.000,      160.000,      210.000, $
    270.000,      345.000,      430.000,      630.000,      900.000, $
    1300.00,      1800.00,      2500.00,      3350.00,      4150.00,      5800.00] ; these are the low energy bounds
  get_data,'elx_pxf_sectnum',data=elx_pxf_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; shift PEF times to the right by 1 sector, make 1st point a NaN, all times now represent mid-points!!!!
  ; The reason is that the actual FGS cross-correlation shows that the DBZDT zero crossing is exactly
  ; in the middle between sector nspinsectors-1 and sector 0, meaning there is no need for any other time-shift rel.to.FGM
  ; CORRECT UNITS IN PLOT, AND ENERGY BINS
  ;
  ; First redefine energies in structure to be middle of energy width. In the future this will be corrected in CDFs.
  Emins=elx_pxf.v
  Max_numchannels = n_elements(elx_pxf.v) ; this is 16
  Emaxs=(Emins[1:Max_numchannels-1])
  ; last channel is integral, add it anyway
  dEoflast=(Emaxs[Max_numchannels-2]-Emins[Max_numchannels-2])
  Emaxs=[Emaxs,Emins[Max_numchannels-1]+dEoflast] ; last channel's, max energy not representative, use same dE/E as previous
  Emids=(Emaxs+Emins)/2.
  elx_pxf.v=Emids
  ;
  ; Next define the energies to plot pitch angle spectra for
  ;
  if keyword_set(userenergies) then begin
    ; use user-specified energy ranges if provided
    MinE_values=userenergies[*,0]
    MaxE_values=userenergies[*,0]
    numchannels = n_elements(MinE_values)
    MinE_channels=make_array(numchannels,/long)
    MaxE_channels=make_array(numchannels,/long)
    for jthchan=0,numchannels-1 do begin
      iEchannels2use = where(elx_pxf.v ge MinE_values[jthchan] and elx_pxf.v lt MaxE_values[jthchan],jEchannels2use)
      MinE_channels[jthchan]=min(iEchannels2use)
      MaxE_channels[jthchan]=max(iEchannels2use)
    endfor
  endif else begin
    ; else go with default values
    MinE_channels = [0, 3, 6, 9]
    numchannels = n_elements(MinE_channels)
    if numchannels gt 1 then $
      MaxE_channels = [MinE_channels[1:numchannels-1]-1,Max_numchannels-1] else $
      MaxE_channels = MinE_channels+1
  endelse
  ;
  nsectors=n_elements(elx_pxf.x)
  nspinsectors=n_elements(reform(elx_pxf.y[0,*]))
  if dSectr2add gt 0 then begin
    xra=make_array(nsectors-dSectr2add,/index,/long)
    elx_pxf.y[dSectr2add:nsectors-1,*]=elx_pxf.y[xra,*]
    elx_pxf.y[0:dSectr2add-1,*]=!VALUES.F_NaN
    store_data,'elx_pxf',data={x:elx_pxf.x,y:elx_pxf.y,v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim ; you can save a NaN!
  endif

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; extrapolate on the left and right to [0,...nspinsectors-1], degap the data
  tres,'elx_pxf_sectnum',dt_sectnum
  elx_pxf_sectnum_new=elx_pxf_sectnum.y
  elx_pxf_sectnum_new_times = elx_pxf_sectnum.x
  if elx_pxf_sectnum.y[0] gt 0 then begin
    elx_pxf_sectnum_new = [0., elx_pxf_sectnum.y]
    elx_pxf_sectnum_new_times = [elx_pxf_sectnum.x[0] - elx_pxf_sectnum.y[0]*dt_sectnum, elx_pxf_sectnum_new_times]
  endif
  if elx_pxf_sectnum.y[n_elements(elx_pxf_sectnum.y)-1] lt (nspinsectors-1) then begin
    elx_pxf_sectnum_new = [elx_pxf_sectnum_new, float(nspinsectors-1)]
    elx_pxf_sectnum_new_times = $
      [elx_pxf_sectnum_new_times , elx_pxf_sectnum_new_times[n_elements(elx_pxf_sectnum_new_times)-1] + (float(nspinsectors-1)-elx_pxf_sectnum.y[n_elements(elx_pxf_sectnum.y)-1])*dt_sectnum]
  endif
  ;
  store_data,'elx_pxf_sectnum',data={x:elx_pxf_sectnum_new_times,y:elx_pxf_sectnum_new},dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  tdegap,'elx_pxf_sectnum',dt=dt_sectnum,/over
  tdeflag,'elx_pxf_sectnum','linear',/over
  ;
  get_data,'elx_pxf_sectnum',data=elx_pxf_sectnum ; now pad middle gaps!
  ksectra=make_array(n_elements(elx_pxf_sectnum.x)-1,/index,/long)
  dts=(elx_pxf_sectnum.x[ksectra+1]-elx_pxf_sectnum.x[ksectra])
  dsectordt=(elx_pxf_sectnum.y[ksectra+1]-elx_pxf_sectnum.y[ksectra])/dts
  ianygaps=where((dsectordt lt 0.75*median(dsectordt) and (dsectordt gt -0.5*float(-1)/dt_sectnum)),janygaps) ; slope below 0.75*nspinsectors/(nspinsectors*dt_sectnum) when a spin gap exists (gives <0.5), force it to median
  if janygaps gt 0 then dsectordt[ianygaps]=median(dsectordt)
  dsectordt=[dsectordt[0],dsectordt]
  dts=[0,dts]
  tol=0.25*median(dts)
  mysectornumpadded=long(total(dsectordt*dts,/cumulative) + elx_pxf_sectnum.y[0]+tol) mod nspinsectors
  mysectornewtimes=(total(dts,/cumulative) + elx_pxf_sectnum.x[0])
  store_data,'elx_pxf_sectnum',data={x:mysectornewtimes,y:float(mysectornumpadded)},dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;
  ; now pad the rest of the quantities
  get_data,'elx_pxf_spinper',data=elx_pxf_spinper,dlim=myspinperdata_dlim,lim=myspinperdata_lim ; this preserved the original times
  store_data,'elx_pxf_times',data={x:elx_pxf_spinper.x,y:elx_pxf_spinper.x-elx_pxf_spinper.x[0]} ; this is to track gaps
  tinterpol_mxn,'elx_pxf_times','elx_pxf_sectnum',/nearest_neighbor,/NAN_EXTRAPOLATE,/over ; middle gaps are have constant values after interpolation, side pads are NaNs themselves
  get_data,'elx_pxf_times',data=elx_pxf_times
  xra=make_array(n_elements(elx_pxf_times.x)-1,/index,/long)
  iany=where(elx_pxf_times.y[xra+1]-elx_pxf_times.y[xra] lt 1.e-6, jany) ; takes care of middle gaps
  inans=where(FINITE(elx_pxf_times.y,/NaN),jnans) ; identifies side pads
  ;
  tinterpol_mxn,'elx_pxf','elx_pxf_sectnum',/over
  get_data,'elx_pxf',data=elx_pxf,dlim=mypxfdata_dlim,lim=mypxfdata_lim
  if jnans gt 0 then elx_pxf.y[inans,*]=!VALUES.F_NaN
  if jany gt 0 then elx_pxf.y[iany,*]=!VALUES.F_NaN
  store_data,'elx_pxf',data={x:elx_pxf.x,y:elx_pxf.y,v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  ;
  tinterpol_mxn,'elx_pxf_spinper','elx_pxf_sectnum',/overwrite ; linearly interpolated, this you keep
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;
  ; Extrapolation and degapping completed!!! Now start viewing
  ;
  get_data,'elx_pxf',data=elx_pxf,dlim=mypxfdata_dlim,lim=mypxfdata_lim
  get_data,'elx_pxf_spinper',data=elx_pxf_spinper,dlim=myspinperdata_dlim,lim=myspinperdata_lim
  get_data,'elx_pxf_sectnum',data=elx_pxf_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;
  nsectors=n_elements(elx_pxf.x)
  xra=make_array(nsectors-1,/index,/long)
  dts=elx_pxf.x[xra+1]-elx_pxf.x[xra]
  ddts=[0,dts-median(dts)]
  store_data,'ddts',data={x:elx_pxf.x,y:ddts}
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;
  ; now assign spin phase (rel. to ascending Bz zero crossing) and pitch angle to each sector
  ;
  lastzero=[xra,nsectors]-long(elx_pxf_sectnum.y+0.5)
  ianynegs=where(lastzero lt 0,janynegs)
  ;
  if janynegs gt 0 then lastzero[ianynegs]=lastzero[ianynegs(janynegs-1)+1]
  ; BELOW, actual phase to be shifted by addl. 4.5deg (0.05msec in time)
  ; note that at the present time (8/13/2019) it is thought that a 1 sector offset plus a time delay should be used to correct the flux spinphases
  ; the 1 sector offset matches the sector 0 determination between PEF and sectnum in the CDFs
  ; this makes the sector numbers closer to the collection center times, but if intent was to denote the start times, then
  ;       both PEF and secnum should be additionally shifted to the left by 0.5 sectors (0.137 sec). Additionally the cross-correlation with the DBZDT
  ;       reveals an additional 0.2 sectors shift to the right (0.050 sec or 4.5deg) which would make the center spin phases not centered around 0 and 180. (not applied here).
  ; SO EXPERIMEMENT WITH THIS BY CHECKING THE REMAINING ASYMMETRY OF THE PITCH ANGLE DISTRIBUTION IN RESPONSE
  ; TO A SPIN PHASE SHIFT THAT REPRESENTS THE AFOREMENTIONED TIME SHIFT. TRY DIFFERENT dPhAng2add FOR DIFFERENT SPIN RATES
  ; TO DETERMINE IF THIS IS A CONSTANT TIME OR HOW TO rMODEL AS FUNCTION OF SPIN PERIOD. BY SHIFTING THE SPINPHASE OF THE
  ; SECTOR TO THE RIGHT YOU DECLARE THAT THE SECTOR CENTERS HAVE LARGER PHASES AND ARE ASYMMETRIC W/R/T THE ZERO CROSSING (AND 90DEG PA).
  ; OR EQUIVALENTLY THAT THE TIMES ARE INCORRECT BY THE SAME AMOUNT AND THE DATA WAS TAKEN LATER THAN DECLARED IN THEIR TIMES.
  spinphase180=(dPhAng2add+float(elx_pxf_sectnum.x-elx_pxf_sectnum.x[lastzero]+0.5*elx_pxf_spinper.y/float(nspinsectors))*360./elx_pxf_spinper.y) mod 360.
  spinphase=spinphase180*!PI/180. ; in radians corresponds to the center of the sector
  store_data,'spinphase',data={x:elx_pxf_sectnum.x,y:spinphase} ; just to see...
  store_data,'spinphasedeg',data={x:elx_pxf_sectnum.x,y:spinphase*180./!PI} ; just to see...
  ylim,"spinphasedeg",0.,360.,0.
  options,'spinphasedeg','databar',180.
  options,'ddts','databar',{yval:[0.], color:[6], linestyle:2}
  ;
  ; Before you compute Pitch Angles, regularize spinphase distribution if requested
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;
  threeones=[1,1,1]
  cotrans,'elx_pos_gei','elx_pos_gse',/GEI2GSE
  cotrans,'elx_pos_gse','elx_pos_gsm',/GSE2GSM

  get_data, 'elx_pos_gsm', data=datgsm, dlimits=dl, limits=l
  gsm_dur=(datgsm.x[n_elements(datgsm.x)-1]-datgsm.x[0])/60.
  if gsm_dur GT 100. then begin
    store_data, 'elx_pos_gsm_mins', data={x: datgsm.x[0:*:60], y: datgsm.y[0:*:60,*]}, dlimits=dl, limits=l
    tt89,'elx_pos_gsm_mins',/igrf_only,newname='elx_bt89_gsm_mins',period=1.
    ; interpolate the minute-by-minute data back to the full array
    get_data,'elx_bt89_gsm_mins',data=gsm_mins
    store_data,'elx_bt89_gsm',data={x: datgsm.x, y: interp(gsm_mins.y[*,*], gsm_mins.x, datgsm.x)}
    ; clean up the temporary data
    del_data, '*_mins'
  endif else begin
    tt89,'elx_pos_gsm',/igrf_only,newname='elx_bt89_gsm',period=1.
  endelse

  cotrans,'elx_pos_gsm','elx_pos_sm',/GSM2SM ; <-- use SM geophysical coordinates plus Despun Spacecraft coord's with Lvec (DSL)
  cotrans,'elx_bt89_gsm','elx_bt89_sm',/GSM2SM ; Bfield in same coords as well
  cotrans,'elx_att_gei','elx_att_gse',/GEI2GSE
  cotrans,'elx_att_gse','elx_att_gsm',/GSE2GSM
  cotrans,'elx_att_gsm','elx_att_sm',/GSM2SM ; attitude in SM
  ;
  calc,' "elx_bt89_sm_par" = (total("elx_bt89_sm"*"elx_att_sm",2)#threeones)*"elx_att_sm" '
  tvectot,"elx_bt89_sm_par",newname="elx_bt89_sm_part"
  ;
  calc,' "elx_bt89_sm_per" = "elx_bt89_sm"-"elx_bt89_sm_par" '
  tvectot,"elx_bt89_sm_per",newname="elx_bt89_sm_pert"
  ;
  tinterpol_mxn,'elx_bt89_sm','elx_pxf' ; interpolate Bt89SM
  tinterpol_mxn,'elx_att_sm','elx_pxf' ; interpolate attitude
  calc,' "elx_att_sm_interp" = "elx_att_sm_interp" / (total("elx_att_sm_interp"^2,2)#threeones) ' ; now for sure normalized!
  get_data,'elx_att_sm_interp',data=elx_att_sm_interp,dlim=myattdlim,lim=myattlim
  ;
  tcrossp, "elx_bt89_sm_interp", 'elx_att_sm_interp',newname="elx_bt89_sm_interp_0xdir" ; not normalized to one yet!
  calc,' "elx_bt89_sm_interp_0xdir" = "elx_bt89_sm_interp_0xdir"  / (sqrt(total("elx_bt89_sm_interp_0xdir"^2,2))#threeones) ' ; now also normalized!
  tcrossp,"elx_att_sm_interp","elx_bt89_sm_interp_0xdir",newname="elx_bt89_sm_interp_bspinplanedir" ; already normalized!
  ; Now you have DSL system vectors in SM coordinates. Can form transformation matrix from DSL to SM. It's columns are the DSL unit vectors in SM.
  ; Rotation of elx_bt89_sm_0xdir vector about DSLz by spinphase angle is sector center unit direction in space in DSL coordinates.
  ; Then rotation of that direction from DSL to SM coordinates is the direction we need to use to compute pitch angle relxtive to Bfield in SM coords.
  ; Note that it is the opposite of that direction we need, as it is the particle motion direction (not the detector direction) that defines pitch angle.
  ; Here detector spinphase = 0 means 90degPA; det. spinphase = 90 means part.direction =270 and particle PA = 180 if B is on spin plane
  ; DSL rot matrix about Z is: [[cos(ph),-sin(ph),0],[sin(ph),cos(ph),0],[0,0,1]] but in IDL's majority column convention requires the transpose.
  ; However, this transposition it taken care of internally with tvector_rotate, so you can use that instead!
  rotaboutdslz=[[[cos(spinphase)],[-sin(spinphase)],[0*spinphase]],[[sin(spinphase)],[cos(spinphase)],[0*spinphase]],[[0.*spinphase],[0.*spinphase],[1.+0.*spinphase]]]
  get_data,'elx_bt89_sm_interp_0xdir',data=DSLX ; in SM coord's
  get_data,'elx_bt89_sm_interp_bspinplanedir',data=DSLY ; in SM coord's
  get_data,'elx_att_sm_interp',data=DSLZ ; in SM coord's
  rotDSL2SM = [[[DSLX.y[*,0]],[DSLX.y[*,1]],[DSLX.y[*,2]]],[[DSLY.y[*,0]],[DSLY.y[*,1]],[DSLY.y[*,2]]],[[DSLZ.y[*,0]],[DSLZ.y[*,1]],[DSLZ.y[*,2]]]]
  ; rotate unit vector [1,0,0] by spinphase about DSLZ, then into SM
  unitXvec2rot=[[1.+0.*spinphase],[0.*spinphase],[0.*spinphase]]
  store_data,'unitXvec2rot',data={x:elx_pxf.x,y:unitXvec2rot},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
  store_data,'rotaboutdslz',data={x:elx_pxf.x,y:rotaboutdslz},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
  store_data,'rotDSL2SM',data={x:elx_pxf.x,y:rotDSL2SM},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
  ;
  tvector_rotate,'rotaboutdslz','unitXvec2rot',newname='sectordir_dsl'; says SM but OK
  tvector_rotate,'rotDSL2SM','sectordir_dsl',newname='sectordir_sm' ;
  calc,' "elx_pxf_sm_interp_partdir"= - "sectordir_sm" '
  ;
  calc,' "elx_pxf_pa" = arccos(total("elx_pxf_sm_interp_partdir" * "elx_bt89_sm_interp",2) / sqrt(total("elx_bt89_sm_interp"^2,2))) *180./pival '
  ylim,"elx_pxf_pa",0.,180.,0.
  ylim,"spinphasedeg",-5.,365.,0.
  options,'elx_pxf_pa','databar',90.
  options,'spinphasedeg','databar',180.
  ;
  ; Now plot PA spectrum for a given energy or range of energies
  ; Since the datapoints and sectors are contiguous and divisible by nspinsectors (e.g. 16)
  ; you can fit them completely in an integer number of spins.
  ; Since any spin covers twice the accessible Pitch Angles
  ; you create two points per spin in a new array and populate
  ; it with the neighboring counts/fluxes.
  ;
  ; Note that Bz ascending zero is when part PA is minumum (closest to 0).
  ; This is NOT sector 0, but between sectors 3 and 4.
  ;
  nspins=nsectors/nspinsectors
  npitchangles=2*nspins
  elx_pxf_val=make_array(nsectors,numchannels,/double)
  ;stop
  if (mytype eq 'nflux' or mytype eq 'eflux' ) then $
    for jthchan=0,numchannels-1 do $
    elx_pxf_val[*,jthchan]=(elx_pxf.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]] # $
    (Emaxs[MinE_channels[jthchan]:MaxE_channels[jthchan]]-Emins[MinE_channels[jthchan]:MaxE_channels[jthchan]])) / $
    total(Emaxs[MinE_channels[jthchan]:MaxE_channels[jthchan]]-Emins[MinE_channels[jthchan]:MaxE_channels[jthchan]]) ; MULTIPLIED BY ENERGY WIDTH AND THEN DIVIDED BY BROAD CHANNEL ENERGY
  if (mytype eq 'raw' or mytype eq 'cps' ) then $
    for jthchan=0,numchannels-1 do $
    elx_pxf_val[*,jthchan]=total(elx_pxf.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]],2) ; JUST SUMMED
  elx_pxf_val_full = elx_pxf.y ; this array contains all angles and energies (in that order, same as val), to be used to compute energy spectra
  ;
  get_data,'elx_pxf_pa',data=elx_pxf_pa
  store_data,'elx_pxf_val',data={x:elx_pxf.x,y:elx_pxf_val}
  store_data,'elx_pxf_val_full',data={x:elx_pxf.x,y:elx_pxf_val_full,v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim ; contains all angles and energies
  ylim,'elx_pxf_val*',1,1,1
  ;stop
  ;
  if keyword_set(regularize) then begin
    ; While the original data (flux, counts) in "elx_pxf" were kept intact, at their recorded times
    ; which are the same as in "elx_pxf_sectnum", "elx_pxf_spinper" (also intact), the
    ; angles in "spinphase", "spinphasedeg", and "elx_pxf_pa"
    ; were changed to reflect the correct timing of the data collections. Generally
    ; these angles do not fall at even distances from zero-crossings (centered or edged).
    ;
    ; The "regularize" keyword interpolates the flux to correspond to regular times, when the
    ; sector centers were exactly at regular distances from the zero-crossings (centered).
    ; Obviously the sector center phases are regular too, and require recalculation that is
    ; also done here. For reference the original data are also output for plotting, retained
    ; in their standard arrays and variables (overhead is low).
    ;
    ; First, perform quadratic interpolation on log(flux) or log(counts) at regular spinphase angles,
    ; CENTERED at 0. ... 90. ... 180. ... 270. ... etc, and create an interpolated angular spectrum
    ; which presumably has bins centered exactly at 90. deg, min and max deg pitch angles.
    ; In lieu of changing the collection times, or increasing the time resolution,
    ; this is the best one can do with the data collected, as a quadratic fit should
    ; be able to capture the peak flux at 90deg.
    ;
    ; Create new array of times centered at 0, 22.5, 45., ... deg spinphase
    ; Multiply sectnum (0:nspinsectors-1) with 360./nspinsectors to create the regularized phases (regspinphase180, or "regspinphasedeg").
    ; Then create the times corresponding to those phases by differencing the
    ; true spinphase (spinphase180) and the regularized phases (regspinphase180, or "regspinphasedeg") and cast it in
    ; terms of a time difference as: (diff/360)*spinper, then subtract it from from the times to
    ; get the new times where the flux value is needed. Then tinterpol_mxn to get the new flux at
    ; those times as a quadratic interpolation.
    ;
    ; zero count strategy: set the zero flux or counts to 0.1 count level, then interpolate in log10 space,
    ; then in regular flux or count space set back to zero those points that are below 1 count level
    ; The 1 count/sector level must be shown in the data in units the data is (also g-factor and efficiency)
    ;
    valof1count=make_array(numchannels,/double)
    for jthchan=0,numchannels-1 do begin
      ionecountflux=where(elx_pxf_val[*,jthchan] gt 0,jonecountflux) ; No longer need for cps - to be replaced below.
      if jonecountflux gt 0 then valof1count[jthchan]=min(elx_pxf_val(ionecountflux)) else valof1count[jthchan]=0.
    endfor
    if mytype eq 'cps' then valof1count[*]=1/(average(elx_pxf_spinper.y)/nspinsectors); For cps you know 1 count/sect regardless of energy! Done below!
    valof0count=0.1*valof1count ; set zero counts or flux to this
    value2check=0.2*valof1count ; check if below this after interpolation then set to zero
    ; same but for Max_numchannels
    valof1count_full=make_array(Max_numchannels,/double)
    for jthchan=0,Max_numchannels-1 do begin
      ionecountflux=where(elx_pxf_val_full[*,jthchan] gt 0,jonecountflux)
      if jonecountflux gt 0 then valof1count_full[jthchan]=min(elx_pxf_val_full(ionecountflux)) else valof1count_full[jthchan]=0.
    endfor
    valof0count_full=0.1*valof1count_full ; set zero counts or flux to this
    value2check_full=0.2*valof1count_full ; check if below this after interpolation then set to zero
    ;----
    regspinphase180=elx_pxf_sectnum.y*22.5 ; in degrees
    regspinphase=regspinphase180*!PI/180.
    regtimes=elx_pxf_sectnum.x-((spinphase180-regspinphase180)/360.)*elx_pxf_spinper.y
    store_data,'regspinphasedeg',data={x:regtimes,y:regspinphase180}
    options,'regspinphasedeg',colors=['r'],linestyle=2 ; just to see...
    store_data,'spinphases',data='spinphasedeg regspinphasedeg' ; just to see...
    ra2interpol=alog10(elx_pxf_val)
    for jthchan=0,numchannels-1 do begin
      iinfinity=where(FINITE(ra2interpol[*,jthchan],/INFINITY,sign=-1),jinfinity) ; this finds the zeros (alog10(0)=-infinity)
      if jinfinity gt 0 then ra2interpol[iinfinity,jthchan]=alog10(valof0count[jthchan]); 0 count level ; !VALUES.F_NaN ; or other... set the value of zero flux to zero log or to NaN?
    endfor
    tinterpol_mxn,{x:elx_pxf.x,y:ra2interpol},regtimes,out=rainterpolated,/quadratic
    elx_pxf_val_reg = rainterpolated
    for jthchan=0,numchannels-1 do begin
      izerocounts=where(10^rainterpolated.y[*,jthchan] lt value2check[jthchan], jzerocounts)
      elx_pxf_val_reg.y[*,jthchan]=10^(rainterpolated.y[*,jthchan])
      if jzerocounts gt 0 then elx_pxf_val_reg.y[izerocounts,jthchan]=0.
    endfor
    ; same but for Max_numchannels
    ra2interpol_full=alog10(elx_pxf_val_full)
    for jthchan=0,Max_numchannels-1 do begin
      iinfinity=where(FINITE(ra2interpol_full[*,jthchan],/INFINITY,sign=-1),jinfinity) ; this finds the zeros (alog10(0)=-infinity)
      if jinfinity gt 0 then ra2interpol_full[iinfinity,jthchan]=alog10(valof0count_full[jthchan]); 0 count level ; !VALUES.F_NaN ; or other... set the value of zero flux to zero log or to NaN?
    endfor
    tinterpol_mxn,{x:elx_pxf.x,y:ra2interpol_full},regtimes,out=rainterpolated_full,/quadratic
    elx_pxf_val_reg_full = rainterpolated_full
    for jthchan=0,Max_numchannels-1 do begin
      izerocounts=where(10^rainterpolated_full.y[*,jthchan] lt value2check_full[jthchan], jzerocounts)
      elx_pxf_val_reg_full.y[*,jthchan]=10^(rainterpolated_full.y[*,jthchan])
      if jzerocounts gt 0 then elx_pxf_val_reg_full.y[izerocounts,jthchan]=0.
    endfor
    ;----
    store_data,'elx_pxf_val_reg',data={x:elx_pxf_val_reg.x,y:elx_pxf_val_reg.y} ; regtimes is identical to rainterpolated.x and elx_pxf_val_reg.x
    store_data,'elx_pxf_val_reg_full',data={x:elx_pxf_val_reg.x,y:elx_pxf_val_reg_full.y} ; regtimes is identical to rainterpolated.x and elx_pxf_val_reg.x
    options,'elx_pxf_val',colors=['0'],psym=-1 ; just to see...
    options,'elx_pxf_val_reg',colors=['r'],linestyle=2,psym=-1 ; just to see...
    options,'elx_pxf_val_reg',colors=['r'],linestyle=0,psym=-1 ; just to see...
    store_data,'elx_pxf_vals',data='elx_pxf_val elx_pxf_val_reg' ; NOTE elx_pxf_val_full is same as elx_pxf_val but for all energies! Practically identical to elx_pxf
    ylim,'elx_pxf_val*',2.e1,1e6,1
    ;
    ; only update what needs to be updated for the regularized angles below:
    regrotaboutdslz=[[[cos(regspinphase)],[-sin(regspinphase)],[0*regspinphase]],[[sin(regspinphase)],[cos(regspinphase)],[0*regspinphase]],[[0.*regspinphase],[0.*regspinphase],[1.+0.*regspinphase]]]
    store_data,'regrotaboutdslz',data={x:elx_pxf_val_reg.x,y:regrotaboutdslz},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
    store_data,'regunitXvec2rot',data={x:elx_pxf_val_reg.x,y:unitXvec2rot},dlim=myattdlim,lim=myattlim ; unitXvec2rot is just a unit vector along X (along detector in spinning coord sys)
    tvector_rotate,'regrotaboutdslz','regunitXvec2rot',newname='regsectordir_dsl',/vector_skip_nonmonotonic ; matrix rotation times are same as unit vector X times here
    tvector_rotate,'rotDSL2SM','regsectordir_dsl',newname='regsectordir_sm',/vector_skip_nonmonotonic ; matrix times differ from vector but OK, because Bfield, att in DSL ~ same (dont change in SM 1/2 sector)
    calc,' "elx_pxf_sm_interp_reg_partdir"= - "regsectordir_sm" '
    ; again, below we did not recompute the "elx_bt89_sm_interp" at the reg.sector times because in SM the Bfield does not change much along track in a fraction of a sector ~137msec, ~1km distance
    calc,' "elx_pxf_pa_reg" = arccos(total("elx_pxf_sm_interp_reg_partdir" * "elx_bt89_sm_interp",2) / sqrt(total("elx_bt89_sm_interp"^2,2))) *180./pival '
    ylim,"elx_pxf_pa_reg",0.,180.,0.
    store_data,'elx_pxf_pas',data='elx_pxf_pa elx_pxf_pa_reg' ; note that elx_pxf_val_full has same pas as elx_pxf_val
    ylim,"regspinphasedeg spinphases",-5.,365.,0.
    ylim,"elx_pxf_pas elx_pxf_pa*",-5.,185.,0.
    options,'elx_pxf_pa*','databar',90.
    options,'spinphases regspinphasedeg','databar',180.
    options,'elx_pxf_pa',colors=['0'],linestyle=0,psym=-1 ; just to see...
    options,'elx_pxf_pa_reg',colors=['r'],linestyle=2,psym=-1 ; just to see...
    ;
  endif
  ;stop
  ;
  Tspin=average(elx_pxf_spinper.y)
  ipasorted=sort(elx_pxf_pa.y[0:nspinsectors-1])
  istartAscnd=max(elx_pxf_sectnum.y[ipasorted[0:1]])
  if abs(ipasorted[0]-ipasorted[1]) ge 2 then istartAscnd=min(elx_pxf_sectnum.y[ipasorted[0:1]])
  istartDscnd=max(elx_pxf_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]])
  if abs(ipasorted[nspinsectors-2]-ipasorted[nspinsectors-1]) ge 2 then istartDscnd=min(elx_pxf_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]])
  istartAscnds=where(abs(elx_pxf_sectnum.y-elx_pxf_sectnum.y[istartAscnd]) lt 0.1)
  istartDscnds=where(abs(elx_pxf_sectnum.y-elx_pxf_sectnum.y[istartDscnd]) lt 0.1)
  tstartAscnds=elx_pxf_sectnum.x[istartAscnds]
  tstartDscnds=elx_pxf_sectnum.x[istartDscnds]
  ;
  ; repeat for regularized times
  if keyword_set(regularize) then begin
    tstartregAscnds=elx_pxf_val_reg.x[istartAscnds]
    tstartregDscnds=elx_pxf_val_reg.x[istartDscnds]
  endif
  ;
  if tstartAscnds[0] lt tstartDscnds[0] then begin ; add a half period on the left as a precautionsince there is a chance that hanging sectors exist (not been accounted for yet)
    tstartDscnds=[tstartDscnds[0]-Tspin,tstartDscnds]
    if keyword_set(regularize) then tstartregDscnds=[tstartregDscnds[0]-Tspin,tstartregDscnds]
  endif else begin
    tstartAscnds=[tstartAscnds[0]-Tspin,tstartAscnds]
    if keyword_set(regularize) then tstartregAscnds=[tstartregAscnds[0]-Tspin,tstartregAscnds]
  endelse
  nstartAscnds=n_elements(tstartAscnds)
  nstartDscnds=n_elements(tstartDscnds)
  nstartregAscnds=n_elements(tstartregAscnds)
  nstartregDscnds=n_elements(tstartregDscnds)
  ;
  if tstartDscnds[nstartDscnds-1] lt tstartAscnds[nstartAscnds-1] then begin ; add a half period on the right as a precautionsince chances are there are hanging ectors (not been accounted for yet)
    tstartDscnds=[tstartDscnds,tstartDscnds[nstartDscnds-1]+Tspin]
    if keyword_set(regularize) then tstartregDscnds=[tstartregDscnds,tstartregDscnds[nstartregDscnds-1]+Tspin]
  endif else begin
    tstartAscnds=[tstartAscnds,tstartAscnds[nstartAscnds-1]+Tspin]
    if keyword_set(regularize) then tstartregAscnds=[tstartregAscnds,tstartregAscnds[nstartregAscnds-1]+Tspin]
  endelse
  nstartAscnds=n_elements(tstartAscnds)
  nstartDscnds=n_elements(tstartDscnds)
  nstartregAscnds=n_elements(tstartregAscnds)
  nstartregDscnds=n_elements(tstartregDscnds)
  ;
  npxftimes=nstartAscnds+nstartDscnds
  elx_pxf_starttimes=[tstartAscnds,tstartDscnds]
  elx_pxf_starttimes=elx_pxf_starttimes[sort(elx_pxf_starttimes)]
  iindx=make_array(npxftimes-1,/index,/long)
  elx_pxf_endtimes=elx_pxf_starttimes
  elx_pxf_endtimes[iindx]=elx_pxf_starttimes[iindx+1]
  elx_pxf_dts=elx_pxf_endtimes-elx_pxf_starttimes
  elx_pxf_dts[npxftimes-1]=elx_pxf_dts[npxftimes-2]
  elx_pxf_endtimes[npxftimes-1]=elx_pxf_endtimes[npxftimes-2]+elx_pxf_dts[npxftimes-2]
  ;now subtract a half-sector from each start and each end,
  ;shifting to the start/end of data collection not sector center
  elx_pxf_starttimes=elx_pxf_starttimes-elx_pxf_dts/(float(nspinsectors)/2.)/2.
  elx_pxf_endtimes=elx_pxf_endtimes-elx_pxf_dts/(float(nspinsectors)/2.)/2.
  ; define centertimes of pxf angle-energy collection, before regularizing
  elx_pxf_centertimes=(elx_pxf_starttimes+elx_pxf_endtimes)/2.
  if keyword_set(regularize) then begin
    npxfregtimes=nstartregAscnds+nstartregDscnds
    elx_pxf_reg_starttimes=[tstartregAscnds,tstartregDscnds]
    elx_pxf_reg_starttimes=elx_pxf_reg_starttimes[sort(elx_pxf_reg_starttimes)]
    iregindx=make_array(npxfregtimes-1,/index,/long)
    elx_pxf_reg_endtimes=elx_pxf_reg_starttimes
    elx_pxf_reg_endtimes[iregindx]=elx_pxf_reg_starttimes[iregindx+1]
    elx_pxf_reg_dts=elx_pxf_reg_endtimes-elx_pxf_reg_starttimes
    elx_pxf_reg_dts[npxfregtimes-1]=elx_pxf_reg_dts[npxfregtimes-2]
    elx_pxf_reg_endtimes[npxfregtimes-1]=elx_pxf_reg_endtimes[npxfregtimes-2]+elx_pxf_reg_dts[npxfregtimes-2]
    ;now subtract a half-sector from each start and each end,
    ;shifting to the start/end of data collection not sector center
    elx_pxf_reg_starttimes=elx_pxf_reg_starttimes-elx_pxf_reg_dts/(float(nspinsectors)/2.)/2.
    elx_pxf_reg_endtimes=elx_pxf_reg_endtimes-elx_pxf_reg_dts/(float(nspinsectors)/2.)/2.
    ; define centertimes of pxf angle-energy collection, before regularizing
    elx_pxf_reg_centertimes=(elx_pxf_reg_starttimes+elx_pxf_reg_endtimes)/2.
  endif
  ;
  ; find the first starttime of a full PA range that contains any data (Ascnd or Descnd), add integer # of halfspins
  istart2reform=min(istartAscnd,istartDscnd)
  nhalfspinsavailable=long((nsectors-(istart2reform+1))/(nspinsectors/2.))
  ifinis2reform=(nspinsectors/2)*nhalfspinsavailable+istart2reform-1 ; exact # of half-spins (full PA ranges)
  elx_pxf_pa_spec=make_array(nhalfspinsavailable,(nspinsectors/2),numchannels,/double)
  elx_pxf_pa_spec_full=make_array(nhalfspinsavailable,(nspinsectors/2),Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
  for jthchan=0,numchannels-1 do elx_pxf_pa_spec[*,*,jthchan]=transpose(reform(elx_pxf_val[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
  for jthchan=0,Max_numchannels-1 do elx_pxf_pa_spec_full[*,*,jthchan]=transpose(reform(elx_pxf_val_full[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
  elx_pxf_pa_spec_times=transpose(reform(elx_pxf_pa.x[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))
  elx_pxf_pa_spec_times=total(elx_pxf_pa_spec_times,2)/(nspinsectors/2.) ; these are midpoints anyway, no need for the ones above
  elx_pxf_pa_spec_pas=transpose(reform(elx_pxf_pa.y[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))
  if keyword_set(get3Dspec) then store_data,mystring+'pa_spec',data={x:elx_pxf_pa_spec_times, y:elx_pxf_pa_spec, v:elx_pxf_pa_spec_pas}
  ;
  ; if regularize keyword is present then repeat for regularized sectors (though they should be identical)

  if keyword_set(regularize) then begin
    get_data,'elx_pxf_pa_reg',data=elx_pxf_pa_reg
    ;if n_elements(elx_pxf_pa_reg.x) LE ifinis2reform then ifinis2reform=n_elements(elx_pxf_pa_reg.x)-1
    elx_pxf_pa_reg_spec=make_array(nhalfspinsavailable,(nspinsectors/2),numchannels,/double)
    elx_pxf_pa_reg_spec_full=make_array(nhalfspinsavailable,(nspinsectors/2),Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
    for jthchan=0,numchannels-1 do elx_pxf_pa_reg_spec[*,*,jthchan]=transpose(reform(elx_pxf_val_reg.y[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
    for jthchan=0,Max_numchannels-1 do elx_pxf_pa_reg_spec_full[*,*,jthchan]=transpose(reform(elx_pxf_val_reg_full.y[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
    elx_pxf_pa_reg_spec_times=transpose(reform(elx_pxf_pa_reg.x[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))
    elx_pxf_pa_reg_spec_times=total(elx_pxf_pa_reg_spec_times[*,1:nspinsectors/2-1],2)/((nspinsectors/2.)-1.) ; these are not midpoints now unless you add one at the end or remove first (total=7)!!!
    elx_pxf_pa_reg_spec_pas=transpose(reform(elx_pxf_pa_reg.y[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))
    if keyword_set(get3Dspec) then store_data,mystring+'pa_reg_spec',data={x:elx_pxf_pa_reg_spec_times, y:elx_pxf_pa_reg_spec, v:elx_pxf_pa_reg_spec_pas}
  endif
  ;
  ; ADD EXTRA ANGLE BINS FOR ALL elx_pxf_pa_spec, elx_pxf_pa_spec_full and elx_pxf_pa_reg_spec !!!
  ; WHEN BIN CENTERS ARE NOT REGULARIZED, THEN SPEDAS CUTS OFF HALF OF THE BIN WHICH MAKES THEM APPEAR HALF-WIDTH. ADD ONE ON EACH SIDE (ADD 2 PER PITCH ANGLE DISTRIBUTION)
  ; WHEN BIN CENTERS ARE REGULARIZED (SPIN PHASES: [0,180]) THEN THE ASCENDING DISTRIBUTION IS MISSING THE 180 BIN, AND THE DESCENDING THE 0 BIN, SO ADD THEM (ADD 1 PER PITCH ANGLE DISTRIBUTION)
  ;
  elx_pxf_pa_spec2plot=make_array(nhalfspinsavailable,(nspinsectors/2)+2,numchannels,/double)
  for jthchan=0,numchannels-1 do elx_pxf_pa_spec2plot[*,*,jthchan]=transpose([transpose(elx_pxf_pa_spec[*,0,jthchan]*!VALUES.F_NaN),transpose(elx_pxf_pa_spec[*,*,jthchan]),transpose(elx_pxf_pa_spec[*,(nspinsectors/2)-1,jthchan]*!VALUES.F_NaN)])
  deltapafirst=(elx_pxf_pa_spec_pas[*,1]-elx_pxf_pa_spec_pas[*,0])
  deltapalast=(elx_pxf_pa_spec_pas[*,(nspinsectors/2)-1]-elx_pxf_pa_spec_pas[*,(nspinsectors/2)-2])
  elx_pxf_pa_spec_pas2plot=transpose([transpose(elx_pxf_pa_spec_pas[*,0]-deltapafirst),transpose(elx_pxf_pa_spec_pas),transpose(elx_pxf_pa_spec_pas[*,(nspinsectors/2)-1]+deltapalast)])
  if keyword_set(get3Dspec) then store_data,mystring+'pa_spec2plot',data={x:elx_pxf_pa_spec_times, y:elx_pxf_pa_spec2plot, v:elx_pxf_pa_spec_pas2plot}
  elx_pxf_pa_spec2plot_full=make_array(nhalfspinsavailable,(nspinsectors/2)+2,Max_numchannels,/double)
  for jthchan=0,Max_numchannels-1 do elx_pxf_pa_spec2plot_full[*,*,jthchan]=transpose([transpose(elx_pxf_pa_spec_full[*,0,jthchan]*!VALUES.F_NaN),transpose(elx_pxf_pa_spec_full[*,*,jthchan]),transpose(elx_pxf_pa_spec_full[*,(nspinsectors/2)-1,jthchan]*!VALUES.F_NaN)])
  if keyword_set(get3Dspec) then store_data,mystring+'pa_spec2plot_full',data={x:elx_pxf_pa_spec_times, y:elx_pxf_pa_spec2plot_full, v:elx_pxf_pa_spec_pas2plot}
  if keyword_set(regularize) then begin
    xra=make_array(n_elements(elx_pxf_pa_reg_spec_times)-1,/index,/long)
    elx_pxf_pa_reg_spec2plot=make_array(n_elements(elx_pxf_pa_reg_spec_times),(nspinsectors/2)+1,numchannels,/double)
    elx_pxf_pa_reg_spec_pas2plot=make_array(n_elements(elx_pxf_pa_reg_spec_times),(nspinsectors/2)+1,/double)
    for jthchan=0,numchannels-1 do elx_pxf_pa_reg_spec2plot[xra,*,jthchan]=transpose([transpose(elx_pxf_pa_reg_spec[xra,*,jthchan]),transpose(elx_pxf_pa_spec[xra+1,0,jthchan])])
    elx_pxf_pa_reg_spec2plot[n_elements(elx_pxf_pa_reg_spec_times)-1,*]=transpose([transpose(elx_pxf_pa_reg_spec[n_elements(elx_pxf_pa_reg_spec_times)-1,*]),elx_pxf_pa_spec[0,0]*!VALUES.F_NaN])
    elx_pxf_pa_reg_spec_pas2plot[xra,*]=transpose([transpose(elx_pxf_pa_reg_spec_pas[xra,*]),transpose(elx_pxf_pa_reg_spec_pas[xra+1,0])])
    elx_pxf_pa_reg_spec_pas2plot[n_elements(elx_pxf_pa_reg_spec_times)-1,*]=transpose([transpose(elx_pxf_pa_reg_spec_pas[n_elements(elx_pxf_pa_reg_spec_times)-1,*]),elx_pxf_pa_reg_spec_pas[n_elements(elx_pxf_pa_reg_spec_times)-2,0]])
    if keyword_set(get3Dspec) then store_data,mystring+'pa_reg_spec2plot',data={x:elx_pxf_pa_reg_spec_times, y:elx_pxf_pa_reg_spec2plot, v:elx_pxf_pa_reg_spec_pas2plot}
    elx_pxf_pa_reg_spec2plot_full=make_array(nhalfspinsavailable,(nspinsectors/2)+1,Max_numchannels,/double)
    for jthchan=0,Max_numchannels-1 do elx_pxf_pa_reg_spec2plot_full[xra,*,jthchan]=transpose([transpose(elx_pxf_pa_reg_spec_full[xra,*,jthchan]),transpose(elx_pxf_pa_reg_spec_full[xra+1,0,jthchan])])
    if keyword_set(get3Dspec) then store_data,mystring+'pa_reg_spec2plot_full',data={x:elx_pxf_pa_reg_spec_times, y:elx_pxf_pa_reg_spec2plot_full, v:elx_pxf_pa_reg_spec_pas2plot}
  endif
  ;
  ; Now make as many channel plots as initially desired, except put them in separate tplot variables to be plotted (either regularized or not)
  ;
  for jthchan=0,numchannels-1 do begin
    str2exec="store_data,'"+mystring+"pa_spec2plot_ch"+strtrim(string(jthchan),2)+ $
      "',data={x:elx_pxf_pa_spec_times, y:elx_pxf_pa_spec2plot[*,*,"+strtrim(string(jthchan),2)+"], v:elx_pxf_pa_spec_pas2plot}"
    dummy=execute(str2exec)
  endfor
  if keyword_set(regularize) then begin
    for jthchan=0,numchannels-1 do begin
      str2exec="store_data,'"+mystring+"pa_reg_spec2plot_ch"+strtrim(string(jthchan),2)+ $
        "',data={x:elx_pxf_pa_reg_spec_times, y:elx_pxf_pa_reg_spec2plot[*,*,"+strtrim(string(jthchan),2)+"], v:elx_pxf_pa_reg_spec_pas2plot}"
      dummy=execute(str2exec)
    endfor
  endif
  ;
  options,'el?_p?f_pa*spec2plot*',spec=1
  ylim,'el?_p?f_pa*spec2plot*',0,180.
  zlim,'el?_p?f_pa*spec2plot*',1,1,1
  options,'el?_p?f_pa*spec2plot*','databar',90.
  ;
  ; Now get loss cone
  tinterpol_mxn,'elx_pos_gsm',elx_pxf_pa_spec_times
  get_data, 'elx_pos_gsm_interp', data=datgsm_interp, dlimits=dl, limits=l
;  gsm_dur=(datgsm_interp.x[n_elements(datgsm_interp.x)-1]-datgsm_interp.x[0])/60.
;  if gsm_dur GT 100. then begin
;    store_data, 'elx_pos_gsm_mins_interp', data={x: datgsm_interp.x[0:*:60], y: datgsm_interp.y[0:*:60,*]}, dlimits=dl, limits=l
;    tt89,'elx_pos_gsm_mins_interp',/igrf_only,newname='elx_bt89_gsm_mins_interp',period=1.
;    ; interpolate the minute-by-minute data back to the full array
;    get_data,'elx_bt89_gsm_mins_interp',data=gsm_mins_interp
;    store_data,'elx_bt89_gsm_interp',data={x: datgsm_interp.x, y: interp(gsm_mins_interp.y[*,*], gsm_mins_interp.x, datgsm_interp.x)}
;    ; clean up the temporary data
;    del_data, '*_mins'
;  endif else begin
    tt89,'elx_pos_gsm_interp',/igrf_only,newname='elx_bt89_gsm_interp',period=1.
;  endelse

  calc,' "radial_pos_gsm_vector"="elx_pos_gsm_interp"/ (sqrt(total("elx_pos_gsm_interp"^2,2))#threeones) '
  calc,' "radial_B_gsm_vector"=total("elx_bt89_gsm_interp"*"radial_pos_gsm_vector",2) '
  get_data,"radial_B_gsm_vector",data=radial_B_gsm_vector
  i2south=where(radial_B_gsm_vector.y gt 0,j2south)
  idir=radial_B_gsm_vector.y*0.+1 ; when Br<0 the direction is 2north and loss cone is 0-90 deg. If Br>0 then idir=-1. and loss cone is 90-180.

  get_data, 'elx_pos_gsm_interp', data=datgsm_interp, dlimits=dl, limits=l
;  gsm_dur=(datgsm_interp.x[n_elements(datgsm_interp.x)-1]-datgsm_interp.x[0])/60.
;  if gsm_dur GT 100. then begin
;    store_data, 'elx_pos_gsm_mins_interp', data={x: datgsm_interp.x[0:*:60], y: datgsm_interp.y[0:*:60,*]}, dlimits=dl, limits=l
;    ttrace2iono,'elx_pos_gsm_mins_interp',newname='elx_ifoot_gsm_mins',/km ; to north by default can be changed if needed
;    ; interpolate the minute-by-minute data back to the full array
;    get_data,'elx_ifoot_gsm_mins',data=gsm_mins_interp
;    store_data,'elx_ifoot_gsm_interp',data={x: datgsm_interp.x, y: interp(gsm_mins_interp.y[*,*], gsm_mins_interp.x, datgsm_interp.x)}
;    ; clean up the temporary data
;    del_data, '*_mins'
;  endif else begin
    ttrace2iono,'elx_pos_gsm_interp',newname='elx_ifoot_gsm',/km ; to north by default can be changed if needed
;  endelse

  get_data,'elx_pos_gsm_interp',data=elx_pos_gsm_interp
  if j2south gt 0 then begin
    idir[i2south]=-1.
    store_data,'elx_pos_gsm_interp_2ionosouth',data={x:elx_pos_gsm_interp.x[i2south],y:elx_pos_gsm_interp.y[i2south,*]}
;    gsm_dur=(elx_pos_gsm_interp.x[n_elements(elx_pos_gsm_interp.x)-1]-elx_pos_gsm_interp.x[0])/60.
;    if gsm_dur GT 100. then begin
;      get_data, 'elx_pos_gsm_interp_2ionosouth', data=elx_pos_gsm_interp_2ionosouth, dlimits=dl, limits=l
;      store_data, 'elx_pos_gsm_interp_2ionosouth_mins', data={x: elx_pos_gsm_interp_2ionosouth.x[0:*:60], y: elx_pos_gsm_interp_2ionosouth.y[0:*:60,*]}, dlimits=dl, limits=l
;      ttrace2iono,'elx_pos_gsm_interp_2ionosouth_mins',newname='elx_ifoot_gsm_2ionosouth_mins',/km,/SOUTH
;      get_data,'elx_ifoot_gsm_2ionosouth_mins',data=ifoot_mins_interp
;      store_data,'elx_ifoot_gsm_2ionosouth',data={x: elx_pos_gsm_interp.x, y: interp(ifoot_mins_interp.y[*,*], ifoot_mins_interp.x, elx_pos_gsm_interp.x)}
      ; clean up the temporary data
;      del_data, '*_mins'
;    endif else begin
      ttrace2iono,'elx_pos_gsm_interp_2ionosouth',newname='elx_ifoot_gsm_2ionosouth',/km,/SOUTH
;    endelse
    get_data,'elx_ifoot_gsm_2ionosouth',data=elx_ifoot_gsm_2ionosouth,dlim=myifoot_dlim,lim=myifoot_lim
    get_data,'elx_ifoot_gsm',data=elx_ifoot_gsm,dlim=myifoot_dlim,lim=myifoot_lim
    elx_ifoot_gsm.y[i2south,*]=elx_ifoot_gsm_2ionosouth.y[i2south,*]
    store_data,'elx_ifoot_gsm',data={x:elx_ifoot_gsm.x,y:elx_ifoot_gsm.y},dlim=myifoot_dlim,lim=myifoot_lim
  endif

  get_data,'elx_ifoot_gsm',data=elx_ifoot_gsm, dlimits=dl, limits=l
;  gsm_dur=(elx_ifoot_gsm.x[n_elements(elx_ifoot_gsm.x)-1]-elx_ifoot_gsm.x[0])/60.
;  if gsm_dur GT 100. then begin
;    store_data, 'elx_ifoot_gsm_mins', data={x: elx_ifoot_gsm.x[0:*:60], y: elx_ifoot_gsm.y[0:*:60,*]}, dlimits=dl, limits=l
;    tt89,'elx_ifoot_gsm_mins',/igrf_only,newname='elx_ifoot_bt89_gsm_interp_mins',period=1.
;    get_data,'elx_ifoot_bt89_gsm_interp_mins',data=ifoot_bt89_gsm_interp_mins, dlimits=dl, limits=l
;    store_data,'elx_ifoot_bt89_gsm_interp',data={x: elx_ifoot_gsm.x, y: interp(ifoot_bt89_gsm_interp_mins.y[*,*], ifoot_bt89_gsm_interp_mins.x, elx_ifoot_gsm.x)}
;    ; clean up the temporary data
;    del_data, '*_mins'
;  endif else begin
    tt89,'elx_ifoot_gsm',/igrf_only,newname='elx_ifoot_bt89_gsm_interp',period=1.
;  endelse
  tvectot,'elx_bt89_gsm_interp',tot='elx_igrf_Btot'
  calc,' "onearray" = "elx_igrf_Btot"/"elx_igrf_Btot" ' ; contains the value of 1.
  tvectot,'elx_ifoot_bt89_gsm_interp',tot='elx_ifoot_igrf_Btot'
  calc,' "lossconedeg" = 180.*arcsin(sqrt("elx_igrf_Btot"/"elx_ifoot_igrf_Btot"))/pival '
  calc,' "lossconedeg" = "lossconedeg"*(idir+1)/2.+(180.*"onearray"-"lossconedeg")*((1.-idir)/2.) '
  calc,' "antilossconedeg" = 180.*"onearray"-"lossconedeg" '
  store_data,'losscones',data='lossconedeg antilossconedeg'
  copy_data,'lossconedeg',mystring+'losscone'
  copy_data,'antilossconedeg',mystring+'antilosscone'
  options,'*losscone*',colors=['0'],linestyle=0,thick=1
  options,'*antilosscone*',colors=['0'],linestyle=2,thick=1
  ylim,'*losscone*',0,180.
  options,'*losscone*','databar',90.
  options, '*losscone*', 'spec',0
  options,'*losscone*','tplot_routine','mplot'

  ;
  for jthchan=0,numchannels-1 do begin
    str2exec="store_data,'"+mystring+"pa_spec2plot_ch"+strtrim(string(jthchan),2)+"LC',data='"+mystring+"pa_spec2plot_ch"+$
      strtrim(string(jthchan),2)+" "+mystring+"losscone "+mystring+"antilosscone'"
    dummy=execute(str2exec)
  endfor
  if keyword_set(regularize) then begin
    for jthchan=0,numchannels-1 do begin
      str2exec="store_data,'"+mystring+"pa_reg_spec2plot_ch"+strtrim(string(jthchan),2)+"LC',data='"+mystring+"pa_reg_spec2plot_ch"+$
        strtrim(string(jthchan),2)+" "+mystring+"losscone "+mystring+"antilosscone'"
      dummy=execute(str2exec)
    endfor
  endif
  ;
  ylim,'el?_p?f_pa*spec2plot* *losscone* el?_p?f_pa*spec2plot_ch?LC',0,180.
  ;
  ;
  ; Now make energy spectra: Omni, Para, Perp, Anti
  ; Para and Anti check when theta is less that losscone+tolerance, where LCfatol tolerance=FOVo2=11deg and LCfptol=-FOVo2 unless user-specified
  ; Omni halfs tres (1/2 Tspin)  but includes one more sector along, and one more opposite the Bfield, such that all times have both para and anti sectors.
  ; In the following the deltagyro is not included in domega (same in the numerator and denominator integrals: Int(f*domega) and Int(domega) ), give 2*pi which cancels
  elx_pxf_en_spec2plot_domega=make_array(nhalfspinsavailable,(nspinsectors/2)+2,/double) ; same for all energies
  elx_pxf_en_spec2plot_domega[*,*]=(2.*!PI/nspinsectors)*sin(!PI*elx_pxf_pa_spec_pas2plot[*,*]/180.)
  elx_pxf_en_spec2plot_domega1d=reform(elx_pxf_en_spec2plot_domega,nhalfspinsavailable*((nspinsectors/2)+2))
  i1d=make_array(nhalfspinsavailable*(nspinsectors/2)+2,/index,/long)
  izeropas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) lt 360./nspinsectors/2) or $
    (reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) gt 180.-360./nspinsectors/2), jzeropas)
  if jzeropas gt 0 then elx_pxf_en_spec2plot_domega1d[izeropas]=(!PI/nspinsectors)*sin(!PI/nspinsectors) ; in degrees, that's pa = dpa = 22.5/2 = 11.25 for 16 sectors
  elx_pxf_en_spec2plot_domega=reform(elx_pxf_en_spec2plot_domega1d,nhalfspinsavailable,(nspinsectors/2)+2)
  elx_pxf_en_spec2plot_allowable=make_array(nhalfspinsavailable,(nspinsectors/2)+2,/double,value=!VALUES.F_NaN) ; same for all energies
  elx_pxf_en_spec2plot_omni=make_array(nhalfspinsavailable,Max_numchannels,/double)
  elx_pxf_en_spec2plot_para=make_array(nhalfspinsavailable,Max_numchannels,/double)
  elx_pxf_en_spec2plot_anti=make_array(nhalfspinsavailable,Max_numchannels,/double)
  elx_pxf_en_spec2plot_perp=make_array(nhalfspinsavailable,Max_numchannels,/double)
  for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_omni[*,jthchan]= $
    total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)],2,/NaN)/ $
    total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  store_data,mystring+'en_spec2plot_omni',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_spec2plot_omni, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  calc,' "paraedgedeg" = 180.*arcsin(sqrt("elx_igrf_Btot"/"elx_ifoot_igrf_Btot"))/pival '
  get_data,"paraedgedeg",data=paraedgedeg
  arrayofones=make_array((nspinsectors/2)+2,/double,value=1.)
  iparapas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) lt -LCfatol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))), jparapas)
  if jparapas gt 0 then begin
    elx_pxf_en_spec2plot_allowable[iparapas]=1.
    elx_pxf_en_spec2plot_allowable=reform(elx_pxf_en_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+2)
  endif
  for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_para[*,jthchan]= $
    total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
    total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  store_data,mystring+'en_spec2plot_para',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_spec2plot_para, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  iantipas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) gt 180.+LCfatol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))), jantipas)
  if jantipas gt 0 then begin
    elx_pxf_en_spec2plot_allowable[iantipas]=1.
    elx_pxf_en_spec2plot_allowable=reform(elx_pxf_en_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+2)
  endif
  for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_anti[*,jthchan]= $
    total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
    total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  store_data,mystring+'en_spec2plot_anti',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_spec2plot_anti, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  iperppas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) lt 180.-LCfatol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))) and $
    (reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) gt +LCfatol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))), jperppas)
  if jperppas gt 0 then begin
    elx_pxf_en_spec2plot_allowable[iperppas]=1.
    elx_pxf_en_spec2plot_allowable=reform(elx_pxf_en_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+2)
  endif
  for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_perp[*,jthchan]= $
    total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
    total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  store_data,mystring+'en_spec2plot_perp',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_spec2plot_perp, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  ;
  if keyword_set(regularize) then begin
    elx_pxf_en_reg_spec2plot_domega=make_array(nhalfspinsavailable,(nspinsectors/2)+1,/double) ; same for all energies
    elx_pxf_en_reg_spec2plot_domega[*,*]=(2.*!PI/nspinsectors)*sin(!PI*elx_pxf_pa_reg_spec_pas2plot[*,*]/180.)
    elx_pxf_en_reg_spec2plot_domega1d=reform(elx_pxf_en_reg_spec2plot_domega,nhalfspinsavailable*((nspinsectors/2)+1))
    i1d=make_array(nhalfspinsavailable*(nspinsectors/2)+1,/index,/long)
    izeropas=where((reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) lt 360./nspinsectors/2) or $
      (reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) gt 180.-360./nspinsectors/2), jzeropas)
    if jzeropas gt 0 then elx_pxf_en_reg_spec2plot_domega1d[izeropas]=(!PI/nspinsectors)*sin(!PI/nspinsectors) ; in degrees, that's pa = dpa = 22.5/2 = 11.25 for 16 sectors
    elx_pxf_en_reg_spec2plot_domega=reform(elx_pxf_en_reg_spec2plot_domega1d,nhalfspinsavailable,(nspinsectors/2)+1)
    elx_pxf_en_reg_spec2plot_allowable=make_array(nhalfspinsavailable,(nspinsectors/2)+1,/double,value=!VALUES.F_NaN) ; same for all energies
    elx_pxf_en_reg_spec2plot_omni=make_array(nhalfspinsavailable,Max_numchannels,/double)
    elx_pxf_en_reg_spec2plot_para=make_array(nhalfspinsavailable,Max_numchannels,/double)
    elx_pxf_en_reg_spec2plot_anti=make_array(nhalfspinsavailable,Max_numchannels,/double)
    elx_pxf_en_reg_spec2plot_perp=make_array(nhalfspinsavailable,Max_numchannels,/double)
    for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_omni[*,jthchan]= $
      total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_spec2plot_domega[*,0:(nspinsectors/2)],2,/NaN) ; IGNORE SECTORS WITH NaNs
    store_data,mystring+'en_reg_spec2plot_omni',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_omni, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    arrayofones=make_array((nspinsectors/2)+1,/double,value=1.)
    iparapas=where((reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) lt -LCfatol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))), jparapas)
    if jparapas gt 0 then begin
      elx_pxf_en_reg_spec2plot_allowable[iparapas]=1.
      elx_pxf_en_reg_spec2plot_allowable=reform(elx_pxf_en_reg_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+1)
    endif
    for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_para[*,jthchan]= $
      total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
    store_data,mystring+'en_reg_spec2plot_para',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_para, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    iantipas=where((reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) gt 180.+LCfatol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))), jantipas)
    if jantipas gt 0 then begin
      elx_pxf_en_reg_spec2plot_allowable[iantipas]=1.
      elx_pxf_en_reg_spec2plot_allowable=reform(elx_pxf_en_reg_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+1)
    endif
    for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_anti[*,jthchan]= $
      total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
    store_data,mystring+'en_reg_spec2plot_anti',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_anti, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    iperppas=where((reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) lt 180.-LCfatol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))) and $
      (reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) gt +LCfatol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))), jperppas)
    if jperppas gt 0 then begin
      elx_pxf_en_reg_spec2plot_allowable[iperppas]=1.
      elx_pxf_en_reg_spec2plot_allowable=reform(elx_pxf_en_reg_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+1)
    endif
    for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_perp[*,jthchan]= $
      total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
    store_data,mystring+'en_reg_spec2plot_perp',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_perp, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  endif
  ;
  options,'el?_p?f_en*spec*',spec=1
  mincps=1/(average(elx_pxf_spinper.y)/nspinsectors) ; in case you need it in the future
  zlim,'el?_p?f_en*spec*',1,1,1
  ylim,'el?_p?f_en*spec*',55.,6800.,1
  ;
  ;
  ;
end
