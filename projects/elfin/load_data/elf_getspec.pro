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
; V: 2021-03-27 added keyword inpacketonly to prevent use of out-of-packet sectors (best for when spins were summed)
; V: 2021-03-26 added capability for summed spins esp. for IBO [spreads the sectors over the spins that summation took place]
; V: 2021-02-13 added showsplitspins keyword
; V: 2020-11-17 added fulspn_spec_full when keyword fullspin and get3Dspec are both set (product was inadvertently omitted before)
; V: 2020-11-28 added keyword enerbins to fix that no energy info in elx_p?f.v when type='raw' so non-standard ch0, ch1, etc bombed
; Vassilis: 2020-09-13: now also outputs sector limits on pitch-angle values (one per sector). These are
; passed in tplot quantities elx_pxf_pa_spec_pa_vals and ela_pef_pa_fulspn_spec_pa_vals 
; that hold Nx8x6 or NxMx6 values (N=number of times, M=number of sectors - twice as many for full spin than for halfspin - and 
; 6 are the output values). The 6 values are fullmin, halfmin, center, halfmax, fullmax, spinphase, where spinphase 
; is the sector spin phase from which you can obtain other useful things such as optimal pitch-angle (if B were on spin plane). 
; Version: v7_wIBO_collection_expanded3 (3/29/2021)
;
pro elf_getspec,regularize=regularize,energies=userenergies,enerbins=userenerbins,dSect2add=userdSectr2add,dSpinPh2add=userdPhAng2add, $
  type=usertype,LCpartol2use=userLCpartol,LCpertol2use=userLCpertol,get3Dspec=get3Dspec, no_download=no_download, $
  probe=probe,species=myspecies,only_loss_cone=only_loss_cone,nodegaps=nonansingaps,delsplitspins=delsplitspins,quadratic=myquadfit, $
  fullspin=fullspin,starton=userstarton,timesortpas=timesortpas,datatype=mydatatype, inpacketonly=usepacketonly, nspinsinsum=my_nspinsinsum
  ;
  ;
  ; INPUTS
  ;
  ; inpacketonly: keyword when >0 (e.g.+1, set, in-packet-only) forces the sectors of an individual packet to be re-arranged into pitch-angles,
  ;               even when they may not be monotonic in time. This is good for summed spins (where time-ordering is lost anyway
  ;               within the packet. This option is useful for both fullspin and halfspin choices over summation so it is the default.
  ;               When <0 (e.g., set to -1) it forces contiguous packets to contribute to the pitch-angle collections, which is the
  ;               nominal and desired behavior when packets are continuous and not summed. Then, for no-summing, assuming no gaps,
  ;               the sectors are monotonic in time even across packet boundaries and this option (-1, out-of-packet) is the preferred
  ;               because it provides the best time-resolution and least time aliasing.
  ;               Default: If spinsinsum=1 then inpacketonly=-1; if spinsinsum>1 then inpacketonly=+1.
  ;               The user can force inpacketonly independently of spinsinsum, but if keyword has not been set then the default prevails.
  ;               Note that this keyword can be applied to all collections (summed or not, IBO or OBO) and can also benefit non-summed
  ;               collections (not the default) when there are many gaps: in that case, rather than throwing away many partial spins on
  ;               either side of the many gaps, you can keep all the spins at the expense of increased aliasing on one of the half-spins.
  ;               This option (+1, even for no-summing) is also not unreasonable (though this is not the default) when using full-spin,
  ;               at spin-resolution when many gaps exist because the extra aliasing (= few sectors + spin period) is only a little more than
  ;               when sectors on either end of the spin are lumped together (the max aliasing approaches the spin period for those sectors).
  ; userenergies is an [Nusrergiesx2] array of Emin,Emax energies to use for pitch-angle spectra
  ; userenerbins is same as userenergies but does it by bin number and has PRIORITY over energies...
  ;      userenerbins is required for type='raw' and non-standard definitions of E-boundaries, but optional for other types
  ;      for example:
  ;      elf_getspec,energies=[[50.,160.],[160.,345.],[345.,900.],[900.,7000.]],/regularize ; gives same results as:
  ;      elf_getspec,/regularize ; and same as
  ;      elf_getspec,enerbins=[[0,2],[3,5],[6,8],[9,15]],/regularize ; 
  ; species is 'e' or 'i' (default is 'e')
  ; datatype is 'pef', 'pif', 'pes' or other... default is 'pef' and over-writes species!!!
  ; dSect2add is number of sectors to add to sectnum to bring 0 sector closer to dBzdt zero crossing time
  ; dSpinPh2add is number of degrees (can be floating point) to add on top of sectors (+/- 11) for the same reason
  ; type is the type of data to process (cps, nflux...)
  ; LCpartol2use (deg) is losscone tolerance in the parallel (or antiparallel) direction (restricing it by this in para, anti spectra)
  ;     (default is half the field of view plus sector width, +FOVo2=11deg, which is making the loss/antiloss cone smaller by this amount (cleaner))
  ; LCpertol2use (deg) is same but in the perp direction (restricting it to closer to 90deg). So a negative value means opening it.
  ;     (default is to open the perp direction by FOVo2, not restricting it, so default is a negative value; when user specifies positive value that increases perp view!)
  ; nodegaps is a keyword that (if set) prevents the program from forcing two additional time points per gap filled with NaNs (in spectra and losscone angles)
  ;     (default behavior is to place 2 NaNs in each gap for plotting purposes, for each ESSENTIAL tplot variable output, listed below).
  ;     It treats gaps exactly the same way, whether split-spin sectors have been inserted or not (if inserted, there'll be 2 gaps for every one).
  ; delsplitspins keyword removes previously inserted full-spin-data during any gap whose collection was split, partially before and partially after the gap.
  ;     Due to the large gap duration, the values of this rogue split spin were obtained at times that can be far apart (begin and end times of the gap).
  ;     The above aliased-data spin is assigned the average time of the spin sector data, a non-standard t-res time closest to the spin portion with the largest # of sectors
  ;     The default is to include this splitspin (delsplitspins=0). Use delsplitspins=1 to delete split spins and thus avoid the inclusion of
  ;     incorrect/aliased sectors in these rogue spins, which result in bogus directional flux ratios (very badly time-aliased).
  ; quadratic is a keyword that applies to the regularized spectra: it changes the default behavior of interpolation in time
  ;     from linear to quadratic. The linear interpolation results in fewer jumps at low counts but underestimates 90deg peaks 
  ;     in flux (because the collections were made away from 90). The quadratic does a better job in fitting the 90deg peaks
  ;     but is jumpy at low counts and results in both under and over-estimates there, causing undue pixellation (not too bad).
  ;     So when there is a need to capture the full 90deg flux to better than 20% use quadratic but ignore the jumpiness at low
  ;     counts in para/anti as well as higher energies
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
  ; ESSENTIAL TPLOT VARIABLES THAT ARE BEIND PRODUCED AND CAN BE PLOTTED AS SPECTROGRAMS OR LINE PLOTS
  ;
  ; 'ela_pef_lossconedeg'          : the losscone in the direction going down (0-90 or 90-180 depending on hemisphere)
  ; 'ela_pef_antilossconedeg'      : its supplementary (180-losscone)
  ; 'ela_pef_pa_spec2plot_ch?'     : numchannels pitch angle spectrograms for ? channel
  ; 'ela_pef_pa_reg_spec2plot_ch?' : numchannels regularized pitch angle spectrograms for ? channel
  ; 'ela_pef_pa_spec2plot_ch?LC' and 'ela_pef_pa_reg_spec2plot_ch?LC: same as above but pseudovariables, including losscone/antilosscone overplotted
  ; 'ela_pef_pa_spec_pa_vals'      : pitch angles at full-width and half-width min/max and cntr of sector plus spin phase for reference (fmin,hmin,cntr,hmax,fmax,phi) supplements "v" quant's above
  ;
  ; 'ela_pef_en_spec2plot_omni/para/perp/anti': energy spectra averaged over phase space within pitch angle range specified nhalfspinsavailable x Max_numchannels
  ; 'ela_pef_en_reg_spec2plot_omni/para/perp/anti': same as above but obtained from regularized versions of the pitch angle spectra
  ;
  ;
  ; note that dPhAng2add more than +/- 11 does not work. You have to add sectors rather than increase dPhAng2add
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if ~keyword_set(my_nspinsinsum) then my_nspinsinsum=1
;  if ~keyword_set(usepacketonly) then if my_nspinsinsum eq 1 then usepacketonly=-1 else usepacketonly=+1 ; in the future to be time-dependent
  if ~keyword_set(usepacketonly) then begin
    ianysummed=where(my_nspinsinsum gt 1, janysummed)
    if janysummed gt 0 then usepacketonly=+1 else usepacketonly=-1
  endif

;  if total(my_nspinsinsum) GT 1. then usepacketonly=+1 else usepacketonly=-1
  if keyword_set(no_download) then no_download=1 else no_download=0
  if ~keyword_set(probe) then probe='a' else probe=probe
  if ~keyword_set(myspecies) then begin
    eori='e' 
  endif else begin
    eori=myspecies
  endelse
  mydataprod='p'+eori+'f' ; if nothing is set the 'pef'
  if keyword_set(mydatatype) then begin ; if datatype is set then it has priority
    mydataprod=mydatatype
    ;eori=strmid('pef',1,1)
    eori = strmid(mydatatype,1,1)  ; change default behavior when dataype if already set
  endif
  if keyword_set(usertype) then mytype=usertype else $
    mytype='nflux'     ; Here specify default data type to act on
  FOVo2=11.          ; Field of View divided by 2 (deg)
  ;
  ; THESE "ELA" and "PEF" STRINGS IN THE FEW LINES BELOW CAN BE CAST INTO USER-SPECIFIED SC (A/B) AND PRODUCT (PEF/PIF) IN THE FUTURE
  ;
  ; ensure attitude is at same resolution as position
  ;
  mysc=probe
  mystring='el'+mysc+'_p'+eori+'f_'
  case mytype of
    'raw': one_count=1. ; approximate, independent of energy
    'cps': one_count=5. ; approximate, independent of energy
    'eflux': one_count=7.e3; by visual inspection of the data roughly const across energies
    'nflux': one_count=1.e2 ; energy dependent, this corresponds to lowest energies
  endcase
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
  copy_data,mystring+'spinper','elx_pxf_spinper'; COPY INTO GENERIC VARIABLE TO AVOID CLASHES. NOTE THIS IS IN SECONDS NOT 80Hz TICKS
  get_data,'elx_pxf',data=elx_pxf,dlim=mypxfdata_dlim,lim=mypxfdata_lim
  get_data,'elx_pxf_sectnum',data=elx_pxf_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  get_data,'elx_pxf_spinper',data=elx_pxf_spinper,dlim=myspinperdata,lim=myspinperdata_lim
  nsectors=n_elements(elx_pxf.x)
  nspinsectors=long(max(elx_pxf_sectnum.y)+1)
  tcor=(my_nspinsinsum-1.)*(elx_pxf_spinper.y/nspinsectors)*(float(elx_pxf_sectnum.y)-float(nspinsectors)/2.+0.5) ; spread in time
  elx_pxf.x=elx_pxf.x+tcor ; here correct (spread) sectors to full accumulation interval
  elx_pxf_sectnum.x=elx_pxf_sectnum.x+tcor ; (spread) sectors to full accumulation interval
  elx_pxf_spinper.x=elx_pxf_spinper.x+tcor ; (spread) sectors to full accumulation interval
;  elx_pxf_spinper.y=my_nspinsinsum*elx_pxf_spinper.y ; from now on all points will assume this is the new "effective" spin period
  store_data,'elx_pxf',data=elx_pxf,dlim=mypxfdata_dlim,lim=mypxfdata_lim
  store_data,'elx_pxf_sectnum',data=elx_pxf_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  store_data,'elx_pxf_spinper',data=elx_pxf_spinper,dlim=myspinperdata,lim=myspinperdata_lim
  mypxforigarray=reform(elx_pxf.y,nsectors*nspinsectors)
  ianynegpxfs=where(mypxforigarray lt 0.,janynegpxfs) ; eliminate negative values from raw data -- these should not be there!
  if janynegpxfs gt 0 then mypxforigarray[ianynegpxfs]=0.
  elx_pxf.y=reform(mypxforigarray,nsectors,nspinsectors)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; shift PEF times to the right by 1 sector, make 1st point a NaN, all times now represent mid-points!!!!
  ; The reason is that the actual FGS cross-correlation shows that the DBZDT zero crossing is exactly
  ; in the middle between sector nspinsectors-1 and sector 0, meaning there is no need for any other time-shift rel.to.FGM
  ; CORRECT UNITS IN PLOT, AND ENERGY BINS
  ;
  Max_numchannels = n_elements(elx_pxf.v) ; this is 16 (nominally)
  ;
  if mytype ne 'raw' then begin; you can define energy bin mins and maxs if you need them (used further only when type is not 'raw')
    Emids=elx_pxf.v
    Emins=elx_pxf.v
    Emaxs=elx_pxf.v
    Emins[Max_numchannels-1]=5800. ; keV, fixed Emin of uppermost channel
    for j=0,Max_numchannels-2 do Emins[Max_numchannels-2-j]= $
        10^(2*alog10(Emids[Max_numchannels-2-j])-alog10(Emins[Max_numchannels-2-j+1]))
    Emaxs[Max_numchannels-1]=Emids[Max_numchannels-1]+(Emids[Max_numchannels-1]-Emins[Max_numchannels-1])
    for j=0,Max_numchannels-2 do Emaxs[j]=Emins[j+1]
  endif
  ;
  ; Next define the energies to plot pitch angle spectra for
  ;
  if keyword_set(userenergies) and keyword_set(userenerbins) then begin
    print,'***********************************************************************************************'
    print,'WARNING: Both keywords: energies= , and enerbins= have been SET. enerbins takes precedence !!!!'
    print,'***********************************************************************************************'
  endif
  if mytype eq 'raw' and keyword_set(userenergies) and ~keyword_set(userenerbins) then $
    stop,'ERROR: When using type="raw" you cannot request special energy channels using energies=..., you must use enerbins=... keyword !!!!'
  if keyword_set(userenergies) and ~keyword_set(userenerbins) then begin ; use user-specified energy ranges if provided
    MinE_values=userenergies[0,*]
    MaxE_values=userenergies[1,*] ; <-- corrected this
    numchannels = n_elements(MinE_values)
    MinE_channels=make_array(numchannels,/long)
    MaxE_channels=make_array(numchannels,/long)
    for jthchan=0,numchannels-1 do begin
      iEchannels2use = where(elx_pxf.v ge MinE_values[jthchan] and elx_pxf.v lt MaxE_values[jthchan],jEchannels2use)
      MinE_channels[jthchan]=min(iEchannels2use)
      MaxE_channels[jthchan]=max(iEchannels2use)
    endfor
  endif
  if keyword_set(userenerbins) then begin ; userenerbins overwrites userenergies if both are set!!
    MinE_channels = userenerbins[0,*]
    numchannels = n_elements(MinE_channels)
    MaxE_channels = userenerbins[1,*]
  endif
  if ~keyword_set(userenergies)  and ~keyword_set(userenerbins) then begin ; if neither set, then use default val's
    MinE_channels = [0, 3, 6, 9]
    numchannels = n_elements(MinE_channels)
    if numchannels gt 1 then $
      MaxE_channels = [MinE_channels[1:numchannels-1]-1,Max_numchannels-1] else $
      MaxE_channels = MinE_channels+1
  endif
  ;
  phasedelay = elf_find_phase_delay(probe=probe, instrument='epd'+eori, trange=[elx_pxf.x[0],elx_pxf.x[-1]]) ; get the applicable phase delays 
  if ~undefined(userdSectr2add) && finite(userdSectr2add) then dSectr2add=userdSectr2add else $
    dSectr2add=phasedelay.DSECT2ADD    ; Here specify default # of sectors to add
  if ~undefined(userdPhAng2add) && finite(userdPhAng2add) then dPhAng2add=userdPhAng2add else $
    dPhAng2add=phasedelay.DPHANG2ADD   ; Here specify default # of degrees to add in addition to the sectors
  if dSectr2add ne 0 then begin
    xra=make_array(nsectors-dSectr2add,/index,/long)
    if dSectr2add gt 0 then begin ; shift forward
      elx_pxf.y[dSectr2add:nsectors-1,*]=elx_pxf.y[xra,*]
      elx_pxf.y[0:dSectr2add-1,*]=!VALUES.F_NaN
    endif else begin ; shift backward
      elx_pxf.y[xra,*]=elx_pxf.y[xra+abs(dSectr2add),*]
      elx_pxf.y[dSectr2add:nsectors-1,*]=!VALUES.F_NaN
    endelse
  endif
  store_data,'elx_pxf',data={x:elx_pxf.x,y:elx_pxf.y,v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim ; you can save a NaN!
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; extrapolate on the left and right to [0,...nspinsectors-1]
  dt_sectnum_left=median(elx_pxf_sectnum.x[1:nspinsectors-1]-elx_pxf_sectnum.x[0:nspinsectors-2]) ; median dt of first spin's sectors
  dt_sectnum_rite=median(elx_pxf_sectnum.x[nsectors-nspinsectors+1:nsectors-1]-elx_pxf_sectnum.x[nsectors-nspinsectors:nsectors-2]) ; median of last spin's sectors
  elx_pxf_sectnum_new=elx_pxf_sectnum.y
  elx_pxf_sectnum_new_times = elx_pxf_sectnum.x
  if elx_pxf_sectnum.y[0] gt 0 then begin
    npadsleft=elx_pxf_sectnum.y[0]
    rapadleft=make_array(npadsleft,/index,/int)
    elx_pxf_sectnum_new = [rapadleft, elx_pxf_sectnum.y]
    elx_pxf_sectnum_new_times = [elx_pxf_sectnum.x[0] - (elx_pxf_sectnum.y[0]-rapadleft)*dt_sectnum_left, elx_pxf_sectnum_new_times]
  endif
  if elx_pxf_sectnum.y[n_elements(elx_pxf_sectnum.y)-1] lt (nspinsectors-1) then begin
    npadsright=(nspinsectors-1)-elx_pxf_sectnum.y[n_elements(elx_pxf_sectnum.y)-1]
    rapadright=make_array(npadsright,/index,/int)
    elx_pxf_sectnum_new = [elx_pxf_sectnum_new, elx_pxf_sectnum.y[n_elements(elx_pxf_sectnum.y)-1]+rapadright+1]
    elx_pxf_sectnum_new_times = $
      [elx_pxf_sectnum_new_times , elx_pxf_sectnum_new_times[n_elements(elx_pxf_sectnum.y)-1] + (rapadright+1)*dt_sectnum_rite]
  endif
  store_data,'elx_pxf_sectnum',data={x:elx_pxf_sectnum_new_times,y:elx_pxf_sectnum_new},dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;
  tinterpol_mxn,'elx_pxf','elx_pxf_sectnum',/REPEAT_EXTRAPOLATE,/over
  tinterpol_mxn,'elx_pxf_spinper','elx_pxf_sectnum',/REPEAT_EXTRAPOLATE,/overwrite ; linearly interpolated, this you keep
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
  igapends=where(ddts gt 3*median(dts),jgaps) ; gap is more than 4x the median sector duration or 4/16 of a spin
  igapbegins=igapends-1
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
  ; TO DETERMINE IF THIS IS A CONSTANT TIME OR HOW TO MODEL AS FUNCTION OF SPIN PERIOD. BY SHIFTING THE SPINPHASE OF THE
  ; SECTOR TO THE RIGHT YOU DECLARE THAT THE SECTOR CENTERS HAVE LARGER PHASES AND ARE ASYMMETRIC W/R/T THE ZERO CROSSING (AND 90DEG PA).
  ; OR EQUIVALENTLY THAT THE TIMES ARE INCORRECT BY THE SAME AMOUNT AND THE DATA WAS TAKEN LATER THAN DECLARED IN THEIR TIMES.
  ; this has been changed to account for summing by using my_nspinsinsum
  spinphase180=((dPhAng2add+float(elx_pxf_sectnum.x-elx_pxf_sectnum.x[lastzero]+0.5*my_nspinsinsum*elx_pxf_spinper.y/float(nspinsectors))*360./my_nspinsinsum/elx_pxf_spinper.y)+360.) mod 360. ; <-- CORRECTED added 360 (negative values remained negative before)
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
  ;
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
  ; now also compute vertices of geometric and accumulation time opening angles.
  ; In the elevation direction the opening angle is just the maximum geometric angle.
  ; In the azimuthal direction the half-width is the sum of 1/2 geom and 1/2 accum angle.
  ; Same procedure as above but no need to recompute rotation matrix. Create a mesh of
  ; vertices and centers, 5x9 points, find min/max pa for each mesh at each time.
  dphgeom=FOVo2*2. ; full geom. width in phi (in deg)
  dthgeom=FOVo2*2. ; full geom. width in theta
  dphsect=360./nspinsectors ; full accum. width (in phi): 22.5deg for 16sectors/spin
  meshths=(90.-((make_array(5,/index,/float)-2.)/2.)*(dthgeom/2.))#make_array(9,/float,value=1.)*!PI/180. ; for each sector, 5 elevations x 9 repeats
  meshphs=make_array(5,/float,value=1.)#(((make_array(9,/index,/float)-4.)/4.)*((dphgeom+dphsect)/2.))*!PI/180. ; for each sector 5 repeats x 9 azimuths
  unitmesh2rot=reform([[reform(sin(meshths)*cos(meshphs),5*9)],[reform(sin(meshths)*sin(meshphs),5*9)],[reform(cos(meshths),5*9)]],5*9*3)
  unitmesh2rot=transpose(reform(transpose(reform([1.+0.*spinphase]#unitmesh2rot,n_elements(spinphase),5*9,3)),3,n_elements(spinphase)*5*9))
  ; 1/2 FOV to the left limit of sector and 1/2 to the right of limit were covered only infinitesimal time, whereas exact limits of sector 100% time;
  ; Here mark 50% accumulation-time angle as half-max point, that is dictated by FOV. For infinitesimally narrow FOV full and half-max points identical.
  if dphsect ge dphgeom then halfwidth=dphsect/2 else halfwidth=dphgeom/2. ; always the largest of the two determines 50% point (due to accum. time or acceptance angle).
  ihalfmeshind=where(abs(reform(meshphs,5*9)*180./!PI) le 1.001*halfwidth,jhalfmeshind) ; 0.1% is for overcoming any numerical resolution error
  icntrmeshind=where((abs(reform(meshphs,5*9)*180./!PI) le 1.e-5*(dphgeom+dphsect)) and (abs(reform(meshths*180./!PI-90.,5*9)) le  1.e-5*dthgeom),jcntrmeshind) ; this finds the center (zero) point of the mesh
  ; to invert operation and get back angles do: my3Darray=reform(transpose(unitmesh2rot),3,5*9,n_elements(spinphase)) ; <--- this gives back (Ntimes,5*9,3) array!
  meshtimes=reform(transpose(elx_pxf.x#make_array(5*9,/double,value=1.)),n_elements(spinphase)*5*9)
  store_data,'unitmesh2rot',data={x:meshtimes,y:unitmesh2rot},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
  tinterpol_mxn,'rotaboutdslz','unitmesh2rot',newname='rotaboutdslz_4mesh'
  tinterpol_mxn,'rotDSL2SM','unitmesh2rot',newname='rotDSL2SM_4mesh'
  tvector_rotate,'rotaboutdslz_4mesh','unitmesh2rot',newname='meshdir_dsl'; says SM but OK
  tvector_rotate,'rotDSL2SM_4mesh','meshdir_dsl',newname='meshdir_sm' ;
  calc,' "elx_pxf_sm_mesh_dir"= - "meshdir_sm" '
  ;
  tinterpol_mxn,'elx_bt89_sm_interp','unitmesh2rot',newname='elx_bt89_sm_mesh_interp'
  ;
  calc,' "elx_pxf_mesh_pa" = arccos(total("elx_pxf_sm_mesh_dir" * "elx_bt89_sm_mesh_interp",2) / sqrt(total("elx_bt89_sm_mesh_interp"^2,2))) *180./pival '
  get_data,'elx_pxf_mesh_pa',data=elx_pxf_mesh_pa
  ;elx_pxf_mesh_pa_times=reform(elx_pxf_mesh_pa.x,5*9,n_elements(spinphase)) ; just to check this equals elx_pxf_pa.x, no need
  elx_pxf_mesh_pa_times=elx_pxf.x
  meshtimera=reform(elx_pxf_mesh_pa.y,5*9,n_elements(spinphase))
  elx_pxf_mesh_pa_fmin=min(meshtimera,dim=1,max=elx_pxf_mesh_pa_fmax)
  elx_pxf_mesh_pa_hmin=min(meshtimera[ihalfmeshind,*],dim=1,max=elx_pxf_mesh_pa_hmax)
  elx_pxf_mesh_pa_cntr=reform(meshtimera[icntrmeshind,*],n_elements(spinphase))
  elx_pxf_mesh_pa_vals=[[elx_pxf_mesh_pa_fmin],[elx_pxf_mesh_pa_hmin],[elx_pxf_mesh_pa_cntr],[elx_pxf_mesh_pa_hmax],[elx_pxf_mesh_pa_fmax],[spinphase180]]
  store_data,'elx_pxf_mesh_pa_vals',data={x:elx_pxf_mesh_pa_times,y:elx_pxf_mesh_pa_vals} ; fmin,hmin,cntr,hmax,fmax in degrees at each sector time
  ylim,"elx_pxf_mesh_pa*",0.,180.,0.
  options,'elx_pxf_pa*','databar',90.
  ;stop
  ;
  ; Now plot PA spectrum for a given energy or range of energies
  ; Since the datapoints and sectors are contiguous and divisible by nspinsectors (e.g. 16)
  ; you can fit them completely in an integer number of spins.
  ; Since any spin covers twice the accessible Pitch Angles
  ; you create two points per spin in a new array and populate
  ; it with the neighboring counts/fluxes.
  ;
  ; Note that Bz ascending zero is when part PA is minumum (closest to 0).
  ; This is NOT sector 0, but somewhere around sectors 3 and 4.
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
    elx_pxf_val[*,jthchan]=total(elx_pxf.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]],2) ; JUST SUMMED OVER ENERGY
  elx_pxf_val_full = elx_pxf.y ; this array contains all angles and energies (in that order, same as val), to be used to compute energy spectra
  ;
  get_data,'elx_pxf_pa',data=elx_pxf_pa
  store_data,'elx_pxf_val',data={x:elx_pxf.x,y:elx_pxf_val}
  store_data,'elx_pxf_val_full',data={x:elx_pxf.x,y:elx_pxf_val_full,v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim ; contains all angles and energies
  ylim,'elx_pxf_val*',1,1,1
  ;stop
  ;
  if keyword_set(regularize) then begin
    regspinphase180=elx_pxf_sectnum.y*22.5 ; in degrees
    regspinphase=regspinphase180*!PI/180.
    regtimes=elx_pxf_sectnum.x-((spinphase180-regspinphase180)/360.)*my_nspinsinsum*elx_pxf_spinper.y
    store_data,'regspinphasedeg',data={x:regtimes,y:regspinphase180}
    options,'regspinphasedeg',colors=['r'],linestyle=2 ; just to see...
    store_data,'spinphases',data='spinphasedeg regspinphasedeg' ; just to see...
    ra2interpol=alog10(elx_pxf_val*10.+1.) ; shifts up by 1 (eliminates zeros) after multiply by 10. -- cps, nflux, eflux are all higher than 1 anyway.
    if keyword_set(myquadfit) then $
    tinterpol_mxn,{x:elx_pxf.x,y:ra2interpol},regtimes,out=rainterpolated,/quadratic $
    else tinterpol_mxn,{x:elx_pxf.x,y:ra2interpol},regtimes,out=rainterpolated ; default is linear fit
    elx_pxf_val_reg = rainterpolated
    elx_pxf_val_reg.y = (10^rainterpolated.y -1.)/10.
    mypxfregarray=reform(elx_pxf_val_reg.y,nsectors*numchannels)
    ianynegpxfs=where(mypxfregarray lt 0.,janynegpxfs) ; eliminate negative values from reg data -- these should not be there!
    if janynegpxfs gt 0 then mypxfregarray[ianynegpxfs]=0.
    elx_pxf_val_reg.y=reform(mypxfregarray,nsectors,numchannels)
    ; same but for Max_numchannels
    ra2interpol_full=alog10(elx_pxf_val_full*10.+1) ; A zero becomes =0; a 1 becomes ~1; a 10 becomes ~2 etc. Min cps ~5cps (one count per sector) so 1cps as good as ~0.
    if keyword_set(myquadfit) then $
    tinterpol_mxn,{x:elx_pxf.x,y:ra2interpol_full},regtimes,out=rainterpolated_full,/quadratic $
    else tinterpol_mxn,{x:elx_pxf.x,y:ra2interpol_full},regtimes,out=rainterpolated_full ; default is linear fit
    elx_pxf_val_reg_full = rainterpolated_full
    elx_pxf_val_reg_full.y = (10^rainterpolated_full.y -1.)/10.
    mypxfregarray_full=reform(elx_pxf_val_reg_full.y,nsectors*Max_numchannels)
    ianynegpxfs_full=where(mypxfregarray_full lt 0.,janynegpxfs_full) ; eliminate negative values from reg data -- these should not be there!
    if janynegpxfs_full gt 0 then mypxfregarray_full[ianynegpxfs_full]=0.
    elx_pxf_val_reg_full.y=reform(mypxfregarray_full,nsectors,Max_numchannels)
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
    tvector_rotate,'regrotaboutdslz','regunitXvec2rot',newname='regsectordir_dsl';,/vector_skip_nonmonotonic ; matrix rotation times are same as unit vector X times here; commended out as no chance of ever happening
    tvector_rotate,'rotDSL2SM','regsectordir_dsl',newname='regsectordir_sm';,/vector_skip_nonmonotonic ; matrix times differ from vector but OK, because Bfield, att in DSL ~ same (dont change in SM 1/2 sector); commended out as no chance of ever happening
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
    ;Latest issue, but can continue to run if using batch procedure error handler
    ;stop ; disagreement b/w times in 'elx_pxf_sm_interp_reg_partdir' and 'elx_bt89_sm_interp'
  endif
  ;stop
  ;
  Tspineff=average(my_nspinsinsum*elx_pxf_spinper.y)
  ipasorted=sort(elx_pxf_pa.y[0:nspinsectors-1])
  istartAscnd=max(elx_pxf_sectnum.y[ipasorted[0:1]])
  if abs(ipasorted[0]-ipasorted[1]) ge 2 then istartAscnd=min(elx_pxf_sectnum.y[ipasorted[0:1]])
  istartDscnd=max(elx_pxf_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]])
  if abs(ipasorted[nspinsectors-2]-ipasorted[nspinsectors-1]) ge 2 then istartDscnd=min(elx_pxf_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]])
  istartAscnds=where(abs(elx_pxf_sectnum.y-elx_pxf_sectnum.y[istartAscnd]) lt 0.1)
  istartDscnds=where(abs(elx_pxf_sectnum.y-elx_pxf_sectnum.y[istartDscnd]) lt 0.1)
  tstartAscnds=elx_pxf_sectnum.x[istartAscnds]
  tstartDscnds=elx_pxf_sectnum.x[istartDscnds]
  ;now get a map of sectors to make them fall within packet (this will make time run backwards but that's OK); Use it in assigning values and center times later
  imapinpckt=make_array(nsectors,/long,/index)
  usepcktidx=where(my_nspinsinsum GT 1,usepcktcnt)
  if usepcktcnt gt 0 and istartAscnd gt 0 then begin
    nsect2mapinpckt = istartAscnd
    usepckt_imapinpckt=make_array(usepcktcnt,/long,/index)
    for jthsect2mapinpckt=0,nsect2mapinpckt-1 do imapinpckt[istartDscnds[usepckt_imapinpckt]+(nspinsectors/2.)+jthsect2mapinpckt]=imapinpckt[istartDscnds[usepckt_imapinpckt]-(nspinsectors/2.)+jthsect2mapinpckt]
;    for jthsect2mapinpckt=0,nsect2mapinpckt-1 do usepckt_imapinpckt[istartDscnds+(nspinsectors/2.)+jthsect2mapinpckt]=usepckt_imapinpckt[istartDscnds-(nspinsectors/2.)+jthsect2mapinpckt]
;    imapinpckt[usepcktidx]=usepckt_imapinpckt
  endif
  inegs=where(imapinpckt lt 0, jnegs)
  if jnegs gt 0 then imapinpckt[inegs]=imapinpckt[inegs]+nspinsectors ; first packet, if incompletely introduced, reverts to standard map (outside packet) 
  ;
  ; repeat for regularized times
  if keyword_set(regularize) then begin
    tstartregAscnds=elx_pxf_val_reg.x[istartAscnds]
    tstartregDscnds=elx_pxf_val_reg.x[istartDscnds]
  endif
  ;
  if tstartAscnds[0] lt tstartDscnds[0] then begin ; add a half period on the left as a precaution since there is a chance that hanging sectors exist (not been accounted for yet)
    tstartDscnds=[tstartDscnds[0]-Tspineff,tstartDscnds]
    if keyword_set(regularize) then tstartregDscnds=[tstartregDscnds[0]-Tspineff,tstartregDscnds]
  endif else begin
    tstartAscnds=[tstartAscnds[0]-Tspineff,tstartAscnds]
    if keyword_set(regularize) then tstartregAscnds=[tstartregAscnds[0]-Tspineff,tstartregAscnds]
  endelse
  nstartAscnds=n_elements(tstartAscnds)
  nstartDscnds=n_elements(tstartDscnds)
  nstartregAscnds=n_elements(tstartregAscnds)
  nstartregDscnds=n_elements(tstartregDscnds)
  ;
  if tstartDscnds[nstartDscnds-1] lt tstartAscnds[nstartAscnds-1] then begin ; add a half period on the right as a precaution since chances are there are hanging sectors (not been accounted for yet)
    tstartDscnds=[tstartDscnds,tstartDscnds[nstartDscnds-1]+Tspineff]
    if keyword_set(regularize) then tstartregDscnds=[tstartregDscnds,tstartregDscnds[nstartregDscnds-1]+Tspineff]
  endif else begin
    tstartAscnds=[tstartAscnds,tstartAscnds[nstartAscnds-1]+Tspineff]
    if keyword_set(regularize) then tstartregAscnds=[tstartregAscnds,tstartregAscnds[nstartregAscnds-1]+Tspineff]
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
  ; note: first and last PARTIAL sectors are lost (not plotted) and gaps show (if requested) as a point at the average sectortime
  istart2reform=min([istartAscnd,istartDscnd])
  nhalfspinsavailable=long((nsectors-(istart2reform+1))/(nspinsectors/2.))
  ifinis2reform=(nspinsectors/2)*nhalfspinsavailable+istart2reform-1 ; exact # of half-spins (full PA ranges)
  elx_pxf_pa_spec=make_array(nhalfspinsavailable,(nspinsectors/2),numchannels,/double)
  elx_pxf_pa_spec_full=make_array(nhalfspinsavailable,(nspinsectors/2),Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
  for jthchan=0,numchannels-1 do elx_pxf_pa_spec[*,*,jthchan]=transpose(reform(elx_pxf_val[imapinpckt[istart2reform:ifinis2reform],jthchan],(nspinsectors/2),nhalfspinsavailable))
  for jthchan=0,Max_numchannels-1 do elx_pxf_pa_spec_full[*,*,jthchan]=transpose(reform(elx_pxf_val_full[imapinpckt[istart2reform:ifinis2reform],jthchan],(nspinsectors/2),nhalfspinsavailable))

  if usepacketonly gt 0 then begin ; here correct times of half-spins to be within packet
    centercorr=float(((elx_pxf_sectnum.y-istart2reform+nspinsectors) mod nspinsectors)/(nspinsectors/2)) ; zero for ascending and one for descending
    ishiftleft=where(centercorr lt 0.5, jshiftleft)
    ishiftrite=where(centercorr gt 0.5, jshiftrite)
    myshiftarrayleft= istart2reform*my_nspinsinsum*elx_pxf_spinper.y/nspinsectors
    myshiftarrayrite=-istart2reform*my_nspinsinsum*elx_pxf_spinper.y/nspinsectors
    if jshiftleft gt 0 then centercorr[ishiftleft] =  myshiftarrayleft[ishiftleft] ; all shift by istart2reform sector widths left
    if jshiftrite gt 0 then centercorr[ishiftrite] =  myshiftarrayrite[ishiftrite] ; all shift by istart2reform sector widths right
  endif else begin
    centercorr= 0. * elx_pxf_sectnum.y ; just 0.
  endelse
  elx_pxf_pa_spec_times=transpose(reform(elx_pxf_pa.x[imapinpckt[istart2reform:ifinis2reform]]+centercorr[imapinpckt[istart2reform:ifinis2reform]],(nspinsectors/2),nhalfspinsavailable)) ; change times 2 stay in packet if required
  elx_pxf_pa_spec_times=total(elx_pxf_pa_spec_times,2)/(nspinsectors/2.) ; these are time averages
  elx_pxf_pa_spec_pas=transpose(reform(elx_pxf_pa.y[imapinpckt[istart2reform:ifinis2reform]],(nspinsectors/2),nhalfspinsavailable))
  elx_pxf_pa_spec_pa_vals_temp=transpose(reform(elx_pxf_mesh_pa_vals[imapinpckt[istart2reform:ifinis2reform],*],(nspinsectors/2),nhalfspinsavailable,6)) ; 6xNhalfspinsxNhalfsectors, 6=fmin,hmin,cntr,hmax,fmax,spinphases
  elx_pxf_pa_spec_pa_vals = make_array(nhalfspinsavailable,(nspinsectors/2),6,/double)
  for jvals=0,5 do elx_pxf_pa_spec_pa_vals[*,*,jvals]=elx_pxf_pa_spec_pa_vals_temp[jvals,*,*]
  if keyword_set(get3Dspec) then store_data,mystring+'pa_spec',data={x:elx_pxf_pa_spec_times, y:elx_pxf_pa_spec, v:elx_pxf_pa_spec_pas}
  if keyword_set(get3Dspec) then store_data,mystring+'pa_spec_pa_vals',data={x:elx_pxf_pa_spec_times, y:elx_pxf_pa_spec_pa_vals} ; no extra angles for these (not intended for angle spectra, just line plots)
  ;
  ; if regularize keyword is present then repeat for regularized sectors (though they should be identical)
  if keyword_set(regularize) then begin
    get_data,'elx_pxf_pa_reg',data=elx_pxf_pa_reg
    elx_pxf_pa_reg_spec=make_array(nhalfspinsavailable,(nspinsectors/2),numchannels,/double)
    elx_pxf_pa_reg_spec_full=make_array(nhalfspinsavailable,(nspinsectors/2),Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
    for jthchan=0,numchannels-1 do elx_pxf_pa_reg_spec[*,*,jthchan]=transpose(reform(elx_pxf_val_reg.y[imapinpckt[istart2reform:ifinis2reform],jthchan],(nspinsectors/2),nhalfspinsavailable))
    for jthchan=0,Max_numchannels-1 do elx_pxf_pa_reg_spec_full[*,*,jthchan]=transpose(reform(elx_pxf_val_reg_full.y[imapinpckt[istart2reform:ifinis2reform],jthchan],(nspinsectors/2),nhalfspinsavailable))
    elx_pxf_pa_reg_spec_times=elx_pxf_pa_spec_times
    elx_pxf_pa_reg_spec_pas=transpose(reform(elx_pxf_pa_reg.y[imapinpckt[istart2reform:ifinis2reform]],(nspinsectors/2),nhalfspinsavailable))
    if keyword_set(get3Dspec) then store_data,mystring+'pa_reg_spec',data={x:elx_pxf_pa_reg_spec_times, y:elx_pxf_pa_reg_spec, v:elx_pxf_pa_reg_spec_pas}
  endif
  ;
  ; if fullspin keyword is present then ALSO create full spin distributions (twice the angles half the times)
  ; Example: atest=make_array(5,2,3,/float,/index); btest=transpose(reform(transpose(atest[0:3,*,*]),3,4,2)); times have halfed; pas have doubled
  if keyword_set(fullspin) then begin
    ifirsthalfspin=0L
    if keyword_set(userstarton) then begin ; here check if start half-spin is ascending or descending else leave as is (min sector)
      case userstarton of
        'ascend': if istart2reform ne istartAscnd then ifirsthalfspin=1L ; not 0
        'descend': if istart2reform ne istartDscnd then ifirsthalfspin=1L ; not 0
        else: ; 'Case must be "ascend" or "descend", ignoring... it is now first available'
      endcase
    endif
    nfullspinsavailable=(nhalfspinsavailable-ifirsthalfspin)/2L
    elx_pxf_pa_fulspn_spec=make_array(nfullspinsavailable,nspinsectors,numchannels,/double)
    elx_pxf_pa_fulspn_spec_full=make_array(nfullspinsavailable,nspinsectors,Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
    elx_pxf_pa_fulspn_spec=transpose(reform(transpose(elx_pxf_pa_spec[ifirsthalfspin:ifirsthalfspin+nfullspinsavailable*2L-1,*,*]),numchannels,nspinsectors,nfullspinsavailable))
    elx_pxf_pa_fulspn_spec_full=transpose(reform(transpose(elx_pxf_pa_spec_full[ifirsthalfspin:ifirsthalfspin+nfullspinsavailable*2L-1,*,*]),Max_numchannels,nspinsectors,nfullspinsavailable))
    elx_pxf_pa_fulspn_spec_pa_vals = make_array(nfullspinsavailable,nspinsectors,6,/double)
;    stop
    ispins=make_array(nfullspinsavailable,/index,/long) ; the time of fulspn determination works for case of inpacketonly as well
    elx_pxf_pa_fulspn_spec_times=(elx_pxf_pa_spec_times[ifirsthalfspin+2*ispins]+elx_pxf_pa_spec_times[ifirsthalfspin+2*ispins+1])/2. ; this is also average of sectortimes
    elx_pxf_pa_fulspn_spec_pas=transpose(reform(transpose(elx_pxf_pa_spec_pas[ifirsthalfspin:ifirsthalfspin+nfullspinsavailable*2L-1,*]),nspinsectors,nfullspinsavailable))
    elx_pxf_pa_fulspn_spec_pa_vals=transpose(reform(transpose(elx_pxf_pa_spec_pa_vals[ifirsthalfspin:ifirsthalfspin+nfullspinsavailable*2L-1,*,*]),6,nspinsectors,nfullspinsavailable))
    ;
    ; By default, sort by pitch angle within each spin, else leave sorted by time (the latter case does not make sense if you used keyword inpacketonly)
    ; Here first perform sorting anyway, then sort final arrays if you need to (below), 
    ; or use only for regularization if you need to (further below), or neither if neither is needed
    ; If timesortpas is set, and regularization is requested then sorting is still needed
    if keyword_set(regularize) or ~keyword_set(timesortpas) then begin ; sort is needed only in this case
      elx_pxf_pa_fulspn_spec_pas_temp=elx_pxf_pa_fulspn_spec_pas
      elx_pxf_pa_fulspn_spec_temp=elx_pxf_pa_fulspn_spec
      elx_pxf_pa_fulspn_spec_pa_vals_temp=elx_pxf_pa_fulspn_spec_pa_vals
      elx_pxf_pa_fulspn_spec_full_temp=elx_pxf_pa_fulspn_spec_full
      for jspin=0,nfullspinsavailable-1 do begin
        ipasorted=sort(elx_pxf_pa_fulspn_spec_pas[jspin,*])
        elx_pxf_pa_fulspn_spec_pas_temp[jspin,*]=elx_pxf_pa_fulspn_spec_pas[jspin,ipasorted]
        elx_pxf_pa_fulspn_spec_temp[jspin,*,*]=elx_pxf_pa_fulspn_spec[jspin,ipasorted,*]
        elx_pxf_pa_fulspn_spec_pa_vals_temp[jspin,*,*]=elx_pxf_pa_fulspn_spec_pa_vals[jspin,ipasorted,*]
        elx_pxf_pa_fulspn_spec_full_temp[jspin,*,*]=elx_pxf_pa_fulspn_spec_full[jspin,ipasorted,*]
      endfor
      if ~keyword_set(timesortpas) then begin ; default is sorting pas (with or without regularization)
        elx_pxf_pa_fulspn_spec_pas=elx_pxf_pa_fulspn_spec_pas_temp
        elx_pxf_pa_fulspn_spec=elx_pxf_pa_fulspn_spec_temp
        elx_pxf_pa_fulspn_spec_pa_vals=elx_pxf_pa_fulspn_spec_pa_vals_temp
        elx_pxf_pa_fulspn_spec_full=elx_pxf_pa_fulspn_spec_full_temp
      endif
    ;
      if keyword_set(regularize) then begin ; within full spin resolution products the regularization is applied in pitch angle, not in time
        elx_pxf_pa_reg_fulspn_spec=make_array(nfullspinsavailable,nspinsectors+1,numchannels,/double)
        elx_pxf_pa_reg_fulspn_spec_full=make_array(nfullspinsavailable,nspinsectors+1,Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
        elx_pxf_pa_reg_fulspn_spec_times=elx_pxf_pa_fulspn_spec_times
        elx_pxf_pa_reg_fulspn_spec_pas=transpose(reform(transpose(elx_pxf_pa_reg_spec_pas[ifirsthalfspin:ifirsthalfspin+nfullspinsavailable*2L-1,*]),nspinsectors,nfullspinsavailable))
        irevbin=[0,nspinsectors-indgen(nspinsectors-1)-1]
        elx_pxf_pa_reg_fulspn_spec_pas=(elx_pxf_pa_reg_fulspn_spec_pas+elx_pxf_pa_reg_fulspn_spec_pas[*,irevbin])/2. ; nspinsectors/2+1 unique values from min to max possible
        elx_pxf_pa_reg_fulspn_spec_pas=elx_pxf_pa_reg_fulspn_spec_pas[*,0:nspinsectors/2] ; redefined as [nfullspinsavailable x nspinsectors/2 +1] array
        imidvals=indgen(nspinsectors/2)
        elx_pxf_pa_reg_fulspn_spec_pasmivals=(elx_pxf_pa_reg_fulspn_spec_pas[*,imidvals+1]+elx_pxf_pa_reg_fulspn_spec_pas[*,imidvals])/2. ; got midvals
        idouble=indgen(nspinsectors+1)/2
        elx_pxf_pa_reg_fulspn_spec_pas=elx_pxf_pa_reg_fulspn_spec_pas[*,idouble] ; increased the elements to nspinsectors+1, and values to every other
        elx_pxf_pa_reg_fulspn_spec_pas[*,imidvals*2+1]=elx_pxf_pa_reg_fulspn_spec_pasmivals[*,imidvals] ; these are the original spinphase angles plus midvals, to be used to fit at
        ;
        ; now fit log(flux) vs pa
        ;
        elx_pxf_pa_fulspn_spec2fit=reform(elx_pxf_pa_fulspn_spec_temp,nfullspinsavailable*nspinsectors*numchannels)
        elx_pxf_pa_fulspn_spec_full2fit=reform(elx_pxf_pa_fulspn_spec_full_temp,nfullspinsavailable*nspinsectors*Max_numchannels)
        elx_pxf_pa_fulspn_spec_err=1./sqrt(1.+elx_pxf_pa_fulspn_spec2fit/one_count) ; this is deltafoverf ~ (1/sqrt(Ncounts+1)) and d(lnf) not d(alog10f)
        elx_pxf_pa_fulspn_spec_full_err=1./sqrt(1.+elx_pxf_pa_fulspn_spec_full2fit/one_count) ; this is deltafoverf ~ (1/sqrt(Ncounts+1)) and d(lnf) not d(alog10f)
        izerovals=where(elx_pxf_pa_fulspn_spec2fit le 0.,jzerovals) ; first for energy averaged
        if jzerovals gt 0 then elx_pxf_pa_fulspn_spec2fit[izerovals]=one_count/3./2. ; just to have something non-zero make it half a count (error remains equiv. to 0cnts df/f~1.)
        izerovals=where(elx_pxf_pa_fulspn_spec_full2fit le 0.,jzerovals) ; next for full
        if jzerovals gt 0 then elx_pxf_pa_fulspn_spec_full2fit[izerovals]=one_count/2. ; just to have something non-zero make it half a count (error remains equiv. to 0cnts df/f~1.)
        elx_pxf_pa_fulspn_spec2fit=reform(alog10(elx_pxf_pa_fulspn_spec2fit),nfullspinsavailable,nspinsectors,numchannels)
        elx_pxf_pa_fulspn_spec_err=reform(elx_pxf_pa_fulspn_spec_err,nfullspinsavailable,nspinsectors,numchannels) ; D(alog10f) = D(lnf)/ln(10)= ~D(lnf)/2.5= err/2.5 but error is relative so dont do it
        elx_pxf_pa_fulspn_spec_full2fit=reform(alog10(elx_pxf_pa_fulspn_spec_full2fit),nfullspinsavailable,nspinsectors,Max_numchannels)
        elx_pxf_pa_fulspn_spec_full_err=reform(elx_pxf_pa_fulspn_spec_full_err,nfullspinsavailable,nspinsectors,Max_numchannels) ; D(alog10f) = D(lnf)/ln(10)= ~D(lnf)/2.5= err/2.5 but error is relative so dont do it
        ;
        ; find indices for each pa (from the center of the time interval, nfullspinsavailable/2, should be good enough for all)
        ipa2fitmins=make_array(nspinsectors+1,/long)
        ipa2fitmaxs=make_array(nspinsectors+1,/long)
        ipa2fitmins[0:2]=0
        ipa2fitmaxs[0:2]=4
        ipa2fitmins[nspinsectors-2:nspinsectors]=nspinsectors-5
        ipa2fitmaxs[nspinsectors-2:nspinsectors]=nspinsectors-1
        for jth2fit=3,nspinsectors-3 do begin
          iany2fit=where(abs(elx_pxf_pa_reg_fulspn_spec_pas[nfullspinsavailable/2,jth2fit]-elx_pxf_pa_fulspn_spec_pas_temp[nfullspinsavailable/2,*]) le 22.5,jany2fit)
          ipa2fitmins[jth2fit]=min(iany2fit)
          ipa2fitmaxs[jth2fit]=max(iany2fit)
        endfor
        ; now perform fits
        mypolyorder=2
        for ithspin=0,nfullspinsavailable-1 do begin
          for ithchan=0,numchannels-1 do begin
            for ithsect=0,nspinsectors do begin
             mycoeffs=poly_fit(elx_pxf_pa_fulspn_spec_pas_temp[ithspin,ipa2fitmins[ithsect]:ipa2fitmaxs[ithsect]], $
                               elx_pxf_pa_fulspn_spec2fit[ithspin,ipa2fitmins[ithsect]:ipa2fitmaxs[ithsect],ithchan], mypolyorder, $
                               measure_errors=elx_pxf_pa_fulspn_spec_err[ithspin,ipa2fitmins[ithsect]:ipa2fitmaxs[ithsect],ithchan],/double)
             elx_pxf_pa_reg_fulspn_spec[ithspin,ithsect,ithchan]=10^poly(elx_pxf_pa_reg_fulspn_spec_pas[ithspin,ithsect],mycoeffs)
            endfor
          endfor
        endfor
        ; now for full
        mypolyorder=2
        for ithspin=0,nfullspinsavailable-1 do begin
          for ithchan=0,Max_numchannels-1 do begin
            for ithsect=0,nspinsectors do begin
              mycoeffs=poly_fit(elx_pxf_pa_fulspn_spec_pas_temp[ithspin,ipa2fitmins[ithsect]:ipa2fitmaxs[ithsect]], $
                elx_pxf_pa_fulspn_spec_full2fit[ithspin,ipa2fitmins[ithsect]:ipa2fitmaxs[ithsect],ithchan], mypolyorder, $
                measure_errors=elx_pxf_pa_fulspn_spec_full_err[ithspin,ipa2fitmins[ithsect]:ipa2fitmaxs[ithsect],ithchan],/double)
              elx_pxf_pa_reg_fulspn_spec_full[ithspin,ithsect,ithchan]=10^poly(elx_pxf_pa_reg_fulspn_spec_pas[ithspin,ithsect],mycoeffs)
            endfor
          endfor
        endfor
        ; no need for further processing of these, store'm
        store_data,mystring+'pa_reg_fulspn_spec',data={x:elx_pxf_pa_reg_fulspn_spec_times, y:elx_pxf_pa_reg_fulspn_spec, v:elx_pxf_pa_reg_fulspn_spec_pas}
        if keyword_set(get3Dspec) then store_data,mystring+'pa_reg_fulspn_spec_full',data={x:elx_pxf_pa_reg_fulspn_spec_times, y:elx_pxf_pa_reg_fulspn_spec_full, v:elx_pxf_pa_reg_fulspn_spec_pas}
      endif
    endif
    ; no need for further processing of these, store'm
    store_data,mystring+'pa_fulspn_spec_pa_vals',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_pa_fulspn_spec_pa_vals} ; no extra angle padding (only intended for line plots)
    if keyword_set(get3Dspec) then store_data,mystring+'pa_fulspn_spec_full',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_pa_fulspn_spec_full, v:elx_pxf_pa_fulspn_spec_pas}
   ;
  endif
  ;stop
  ;
  ; ADD EXTRA ANGLE BINS FOR ALL elx_pxf_pa_spec, elx_pxf_pa_spec_full and elx_pxf_pa_reg_spec, elx_pxf_pa_reg_spec_full !!!
  ; ALSO ADD EXTRA ANGLE BINS FOR elx_pxf_pa_fulspn_spec, elx_pxf_pa_fulspn_spec_full but NO NEED FOR timesorted equiv's, or elx_pxf_pa_reg_fulspn_spec or elx_pxf_pa_reg_fulspn_spec_full !!!
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
  ;
  if keyword_set(fullspin) then begin ; process and store fulspn arrays and tplot var's
    if ~keyword_set(timesortpas) then begin ; if not timesorted then add side bins
      elx_pxf_pa_fulspn_spec2plot=make_array(nfullspinsavailable,nspinsectors+2,numchannels,/double)
      for jthchan=0,numchannels-1 do elx_pxf_pa_fulspn_spec2plot[*,*,jthchan]=transpose([transpose(elx_pxf_pa_fulspn_spec[*,0,jthchan]*!VALUES.F_NaN),transpose(elx_pxf_pa_fulspn_spec[*,*,jthchan]),transpose(elx_pxf_pa_fulspn_spec[*,nspinsectors-1,jthchan]*!VALUES.F_NaN)])
      deltapafirst=(elx_pxf_pa_fulspn_spec_pas[*,1]-elx_pxf_pa_fulspn_spec_pas[*,0])
      deltapalast=(elx_pxf_pa_fulspn_spec_pas[*,nspinsectors-1]-elx_pxf_pa_fulspn_spec_pas[*,nspinsectors-2])
      elx_pxf_pa_fulspn_spec_pas2plot=transpose([transpose(elx_pxf_pa_fulspn_spec_pas[*,0]-deltapafirst),transpose(elx_pxf_pa_fulspn_spec_pas),transpose(elx_pxf_pa_fulspn_spec_pas[*,nspinsectors-1]+deltapalast)])
      elx_pxf_pa_fulspn_spec2plot_full=make_array(nfullspinsavailable,nspinsectors+2,Max_numchannels,/double)
      for jthchan=0,Max_numchannels-1 do elx_pxf_pa_fulspn_spec2plot_full[*,*,jthchan]=transpose([transpose(elx_pxf_pa_fulspn_spec_full[*,0,jthchan]*!VALUES.F_NaN),transpose(elx_pxf_pa_fulspn_spec_full[*,*,jthchan]),transpose(elx_pxf_pa_fulspn_spec_full[*,(nspinsectors/2)-1,jthchan]*!VALUES.F_NaN)])
    endif
    if keyword_set(get3Dspec) then store_data,mystring+'pa_fulspn_spec2plot',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_pa_fulspn_spec2plot, v:elx_pxf_pa_fulspn_spec_pas2plot}
    if keyword_set(get3Dspec) then store_data,mystring+'pa_fulspn_spec2plot_full',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_pa_fulspn_spec2plot_full, v:elx_pxf_pa_fulspn_spec_pas2plot}
  endif
  ;
  if keyword_set(regularize) then begin
    xra=make_array(n_elements(elx_pxf_pa_reg_spec_times)-1,/index,/long)
    elx_pxf_pa_reg_spec2plot=make_array(n_elements(elx_pxf_pa_reg_spec_times),(nspinsectors/2)+1,numchannels,/double)
    elx_pxf_pa_reg_spec_pas2plot=make_array(n_elements(elx_pxf_pa_reg_spec_times),(nspinsectors/2)+1,/double)
    for jthchan=0,numchannels-1 do elx_pxf_pa_reg_spec2plot[xra,*,jthchan]=transpose([transpose(elx_pxf_pa_reg_spec[xra,*,jthchan]),transpose(elx_pxf_pa_reg_spec[xra+1,0,jthchan])])
    for jthchan=0,numchannels-1 do elx_pxf_pa_reg_spec2plot[n_elements(elx_pxf_pa_reg_spec_times)-1,*,jthchan]=transpose([transpose(elx_pxf_pa_reg_spec[n_elements(elx_pxf_pa_reg_spec_times)-1,*,jthchan]),elx_pxf_pa_spec[0,0,jthchan]*!VALUES.F_NaN])
    elx_pxf_pa_reg_spec_pas2plot[xra,*]=transpose([transpose(elx_pxf_pa_reg_spec_pas[xra,*]),transpose(elx_pxf_pa_reg_spec_pas[xra+1,0])])
    elx_pxf_pa_reg_spec_pas2plot[n_elements(elx_pxf_pa_reg_spec_times)-1,*]=transpose([transpose(elx_pxf_pa_reg_spec_pas[n_elements(elx_pxf_pa_reg_spec_times)-1,*]),elx_pxf_pa_reg_spec_pas[n_elements(elx_pxf_pa_reg_spec_times)-2,0]])
    if keyword_set(get3Dspec) then store_data,mystring+'pa_reg_spec2plot',data={x:elx_pxf_pa_reg_spec_times, y:elx_pxf_pa_reg_spec2plot, v:elx_pxf_pa_reg_spec_pas2plot}
    elx_pxf_pa_reg_spec2plot_full=make_array(nhalfspinsavailable,(nspinsectors/2)+1,Max_numchannels,/double)
    for jthchan=0,Max_numchannels-1 do elx_pxf_pa_reg_spec2plot_full[xra,*,jthchan]=transpose([transpose(elx_pxf_pa_reg_spec_full[xra,*,jthchan]),transpose(elx_pxf_pa_reg_spec_full[xra+1,0,jthchan])])
    for jthchan=0,Max_numchannels-1 do elx_pxf_pa_reg_spec2plot_full[n_elements(elx_pxf_pa_reg_spec_times)-1,*,jthchan]=transpose([transpose(elx_pxf_pa_reg_spec_full[n_elements(elx_pxf_pa_reg_spec_times)-1,*,jthchan]),elx_pxf_pa_reg_spec_full[0,0,jthchan]*!VALUES.F_NaN])
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
  if keyword_set(fullspin) then begin
    for jthchan=0,numchannels-1 do begin
      str2exec="store_data,'"+mystring+"pa_fulspn_spec2plot_ch"+strtrim(string(jthchan),2)+ $
        "',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_pa_fulspn_spec2plot[*,*,"+strtrim(string(jthchan),2)+"], v:elx_pxf_pa_fulspn_spec_pas2plot}"
      dummy=execute(str2exec)
    endfor
    if keyword_set(regularize) then begin
      for jthchan=0,numchannels-1 do begin
        str2exec="store_data,'"+mystring+"pa_reg_fulspn_spec2plot_ch"+strtrim(string(jthchan),2)+ $
          "',data={x:elx_pxf_pa_reg_fulspn_spec_times, y:elx_pxf_pa_reg_fulspn_spec[*,*,"+strtrim(string(jthchan),2)+"], v:elx_pxf_pa_reg_fulspn_spec_pas}"
        dummy=execute(str2exec)
      endfor
    endif
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
  if keyword_set(only_loss_cone) then begin ;CHANGED 1/13
    store_data, 'elx_pos_gsm_mins_interp', data={x: datgsm_interp.x[0:*:60], y: datgsm_interp.y[0:*:60,*]}, dlimits=dl, limits=l
    tt89,'elx_pos_gsm_mins_interp',/igrf_only,newname='elx_bt89_gsm_mins_interp',period=1.
    ; interpolate the minute-by-minute data back to the full array
    get_data,'elx_bt89_gsm_mins_interp',data=gsm_mins_interp
    store_data,'elx_bt89_gsm_interp',data={x: datgsm_interp.x, y: interp(gsm_mins_interp.y[*,*], gsm_mins_interp.x, datgsm_interp.x)}
    ; clean up the temporary data
    del_data, '*_mins'
  endif else begin
    tt89,'elx_pos_gsm_interp',/igrf_only,newname='elx_bt89_gsm_interp',period=1.
  endelse
  ;
  calc,' "radial_pos_gsm_vector"="elx_pos_gsm_interp"/ (sqrt(total("elx_pos_gsm_interp"^2,2))#threeones) '
  calc,' "radial_B_gsm_vector"=total("elx_bt89_gsm_interp"*"radial_pos_gsm_vector",2) '
  get_data,"radial_B_gsm_vector",data=radial_B_gsm_vector
  i2south=where(radial_B_gsm_vector.y gt 0,j2south)
  idir=radial_B_gsm_vector.y*0.+1 ; when Br<0 the direction is 2north and loss cone is 0-90 deg. If Br>0 then idir=-1. and loss cone is 90-180.
  ;
  get_data, 'elx_pos_gsm_interp', data=datgsm_interp, dlimits=dl, limits=l
;  gsm_dur=(datgsm_interp.x[n_elements(datgsm_interp.x)-1]-datgsm_interp.x[0])/60.
;  if gsm_dur GT 100. then begin
  if keyword_set(only_loss_cone) then begin ;CHANGED 1/13
    store_data, 'elx_pos_gsm_mins_interp', data={x: datgsm_interp.x[0:*:60], y: datgsm_interp.y[0:*:60,*]}, dlimits=dl, limits=l
    ttrace2iono,'elx_pos_gsm_mins_interp',newname='elx_ifoot_gsm_mins',/km ; to north by default can be changed if needed
    ; interpolate the minute-by-minute data back to the full array
    get_data,'elx_ifoot_gsm_mins',data=gsm_mins_interp
    store_data,'elx_ifoot_gsm',data={x: datgsm_interp.x, y: interp(gsm_mins_interp.y[*,*], gsm_mins_interp.x, datgsm_interp.x)}
    ;store_data,'elx_ifoot_gsm_interp',data={x: datgsm_interp.x, y: interp(gsm_mins_interp.y[*,*], gsm_mins_interp.x, datgsm_interp.x)}
    ; clean up the temporary data
    del_data, '*_mins'
  endif else begin
    ttrace2iono,'elx_pos_gsm_interp',newname='elx_ifoot_gsm',/km ; to north by default can be changed if needed
  endelse
  ;
  get_data,'elx_pos_gsm_interp',data=elx_pos_gsm_interp
  if j2south gt 0 then begin
    idir[i2south]=-1.
    store_data,'elx_pos_gsm_interp_2ionosouth',data={x:elx_pos_gsm_interp.x[i2south],y:elx_pos_gsm_interp.y[i2south,*]}
;    gsm_dur=(elx_pos_gsm_interp.x[n_elements(elx_pos_gsm_interp.x)-1]-elx_pos_gsm_interp.x[0])/60.
;    if gsm_dur GT 100. then begin
    if keyword_set(only_loss_cone) then begin ;CHANGED 1/13
      get_data, 'elx_pos_gsm_interp_2ionosouth', data=elx_pos_gsm_interp_2ionosouth, dlimits=dl, limits=l
      store_data, 'elx_pos_gsm_interp_2ionosouth_mins', data={x: elx_pos_gsm_interp_2ionosouth.x[0:*:60], y: elx_pos_gsm_interp_2ionosouth.y[0:*:60,*]}, dlimits=dl, limits=l
      ttrace2iono,'elx_pos_gsm_interp_2ionosouth_mins',newname='elx_ifoot_gsm_2ionosouth_mins',/km,/SOUTH
      get_data,'elx_ifoot_gsm_2ionosouth_mins',data=ifoot_mins_interp
      store_data,'elx_ifoot_gsm_2ionosouth',data={x: elx_pos_gsm_interp.x, y: interp(ifoot_mins_interp.y[*,*], ifoot_mins_interp.x, elx_pos_gsm_interp.x)}
      ; clean up the temporary data
      del_data, '*_mins'
    endif else begin
      ttrace2iono,'elx_pos_gsm_interp_2ionosouth',newname='elx_ifoot_gsm_2ionosouth',/km,/SOUTH
    endelse
    get_data,'elx_ifoot_gsm_2ionosouth',data=elx_ifoot_gsm_2ionosouth,dlim=myifoot_dlim,lim=myifoot_lim
    get_data,'elx_ifoot_gsm',data=elx_ifoot_gsm,dlim=myifoot_dlim,lim=myifoot_lim
    elx_ifoot_gsm.y[i2south,*]=elx_ifoot_gsm_2ionosouth.y[i2south,*]
    store_data,'elx_ifoot_gsm',data={x:elx_ifoot_gsm.x,y:elx_ifoot_gsm.y},dlim=myifoot_dlim,lim=myifoot_lim
  endif
  ;
  get_data,'elx_ifoot_gsm',data=elx_ifoot_gsm, dlimits=dl, limits=l ;elx_ifoot_gsm is too short
;  gsm_dur=(elx_ifoot_gsm.x[n_elements(elx_ifoot_gsm.x)-1]-elx_ifoot_gsm.x[0])/60.
;  if gsm_dur GT 100. then begin
  if keyword_set(only_loss_cone) then begin ;CHANGED 1/13 (error stems from here, elx_ifoot_bt89_gsm_interp)
    store_data, 'elx_ifoot_gsm_mins', data={x: elx_ifoot_gsm.x[0:*:60], y: elx_ifoot_gsm.y[0:*:60,*]}, dlimits=dl, limits=l
    tt89,'elx_ifoot_gsm_mins',/igrf_only,newname='elx_ifoot_bt89_gsm_interp_mins',period=1.
    get_data,'elx_ifoot_bt89_gsm_interp_mins',data=ifoot_bt89_gsm_interp_mins, dlimits=dl, limits=l
    store_data,'elx_ifoot_bt89_gsm_interp',data={x: elx_ifoot_gsm.x, y: interp(ifoot_bt89_gsm_interp_mins.y[*,*], ifoot_bt89_gsm_interp_mins.x, elx_ifoot_gsm.x)}
    ; clean up the temporary data
    del_data, '*_mins'
  endif else begin
    tt89,'elx_ifoot_gsm',/igrf_only,newname='elx_ifoot_bt89_gsm_interp',period=1.
  endelse
  tvectot,'elx_bt89_gsm_interp',tot='elx_igrf_Btot'
  calc,' "onearray" = "elx_igrf_Btot"/"elx_igrf_Btot" ' ; contains the value of 1.
  tvectot,'elx_ifoot_bt89_gsm_interp',tot='elx_ifoot_igrf_Btot'
  calc,' "lossconedeg" = 180.*arcsin(sqrt("elx_igrf_Btot"/"elx_ifoot_igrf_Btot"))/pival '
  calc,' "lossconedeg" = "lossconedeg"*(idir+1)/2.+(180.*"onearray"-"lossconedeg")*((1.-idir)/2.) '
  calc,' "antilossconedeg" = 180.*"onearray"-"lossconedeg" '
  store_data,'losscones',data='lossconedeg antilossconedeg'
  copy_data,'lossconedeg',mystring+'losscone'
  copy_data,'antilossconedeg',mystring+'antilosscone'
  options,'*losscone*',linestyle=0,thick=1
  options,'*antilosscone*',linestyle=2,thick=1
;  options,'*losscone*',colors=['0'],linestyle=0,thick=1
;  options,'*antilosscone*',colors=['0'],linestyle=2,thick=1
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
  if keyword_set(fullspin) then begin
    for jthchan=0,numchannels-1 do begin
      str2exec="store_data,'"+mystring+"pa_fulspn_spec2plot_ch"+strtrim(string(jthchan),2)+"LC',data='"+mystring+"pa_fulspn_spec2plot_ch"+$
        strtrim(string(jthchan),2)+" "+mystring+"losscone "+mystring+"antilosscone'"
      dummy=execute(str2exec)
    endfor
    if keyword_set(regularize) then begin
      for jthchan=0,numchannels-1 do begin
        str2exec="store_data,'"+mystring+"pa_reg_fulspn_spec2plot_ch"+strtrim(string(jthchan),2)+"LC',data='"+mystring+"pa_reg_fulspn_spec2plot_ch"+$
          strtrim(string(jthchan),2)+" "+mystring+"losscone "+mystring+"antilosscone'"
        dummy=execute(str2exec)
      endfor
    endif
  endif
  ;
  ylim,'el?_p?f_pa*spec2plot* *losscone* el?_p?f_pa*spec2plot_ch?LC',0,180.
  ;
  ; Now make energy spectra: Omni, Para, Perp, Anti
  ; Para and Anti: check when theta less that losscone+tolerance, where LCfatol tolerance=FOVo2+SectWidth/2 and LCfptol=FOVo2 unless user-specified
  ; Omni halfs tres (1/2 Tspineff)  but includes one more sector along, and one more opposite the Bfield, such that all times have both para and anti sectors.
  ; In the following the deltagyro is not included in domega (same in the numerator and denominator integrals: Int(f*domega) and Int(domega) ), give 2*pi which cancels
  SectWidtho2 = dphsect/2.
  if keyword_set(userLCpartol) then LCfatol=userLCpartol else LCfatol=FOVo2+SectWidtho2
  if keyword_set(userLCpertol) then LCfptol=userLCpertol else LCfptol=-FOVo2 ; in field perp, fp, direction -- default opens the fov in perp dir.
  ;
  elx_pxf_en_spec2plot_domega=make_array(nhalfspinsavailable,(nspinsectors/2)+2,/double) ; same for all energies
  elx_pxf_en_spec2plot_domega[*,*]=(2.*!PI/nspinsectors)*sin(!PI*elx_pxf_pa_spec_pas2plot[*,*]/180.)
  elx_pxf_en_spec2plot_domega1d=reform(elx_pxf_en_spec2plot_domega,nhalfspinsavailable*((nspinsectors/2)+2))
  i1d=make_array(nhalfspinsavailable*(nspinsectors/2)+2,/index,/long)
  izeropas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) lt 360./nspinsectors/2) or $
    (reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) gt 180.-360./nspinsectors/2), jzeropas)
  if jzeropas gt 0 then elx_pxf_en_spec2plot_domega1d[izeropas]=(!PI/nspinsectors)*sin(!PI/nspinsectors) ; in degrees, that's pa = dpa = 22.5/2 = 11.25 for 16 sectors
  elx_pxf_en_spec2plot_domega=reform(elx_pxf_en_spec2plot_domega1d,nhalfspinsavailable,(nspinsectors/2)+2)
  elx_pxf_en_spec2plot_allowable=make_array(nhalfspinsavailable*((nspinsectors/2)+2),/double,value=!VALUES.F_NaN) ; same for all energies
  elx_pxf_en_spec2plot_omni=make_array(nhalfspinsavailable,Max_numchannels,/double)
  elx_pxf_en_spec2plot_para=make_array(nhalfspinsavailable,Max_numchannels,/double)
  elx_pxf_en_spec2plot_anti=make_array(nhalfspinsavailable,Max_numchannels,/double)
  elx_pxf_en_spec2plot_perp=make_array(nhalfspinsavailable,Max_numchannels,/double)
  case mytype of
    'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_omni[*,jthchan]= $ ; just total counts
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
    'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_omni[*,jthchan]= $ ; average cps between different directions
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan],2,/NaN)/(nspinsectors/2) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
    else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_omni[*,jthchan]= $ ; everything else gets scaled to domega
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  endcase
  store_data,mystring+'en_spec2plot_omni',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_spec2plot_omni, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  calc,' "paraedgedeg" = 180.*arcsin(sqrt("elx_igrf_Btot"/"elx_ifoot_igrf_Btot"))/pival '
  get_data,"paraedgedeg",data=paraedgedeg
  arrayofones=make_array((nspinsectors/2)+2,/double,value=1.)
;  select parapas for energy spectra first
  iparapas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) lt -LCfatol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))), jparapas)
  if jparapas gt 0 then begin
    elx_pxf_en_spec2plot_allowable[iparapas]=1.
  endif
  elx_pxf_en_spec2plot_allowable=reform(elx_pxf_en_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+2)
  case mytype of
    'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_para[*,jthchan]= $ ; just total counts here
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)
    'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_para[*,jthchan]= $ ; just average counts over allowable look directions here
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)
  else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_para[*,jthchan]= $ ; flux scaled by solid angle here
    total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
    total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  endcase
  store_data,mystring+'en_spec2plot_para',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_spec2plot_para, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
; ... antipas for energy spectra now
  elx_pxf_en_spec2plot_allowable=make_array(nhalfspinsavailable*((nspinsectors/2)+2),/double,value=!VALUES.F_NaN) ; same for all energies
  iantipas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) gt 180.+LCfatol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))), jantipas)
  if jantipas gt 0 then begin
    elx_pxf_en_spec2plot_allowable[iantipas]=1.
  endif
  elx_pxf_en_spec2plot_allowable=reform(elx_pxf_en_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+2)
  case mytype of
    'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_anti[*,jthchan]= $  ; just total counts here
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)
    'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_anti[*,jthchan]= $  ; just average counts over allowable look directions here
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)
  else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_anti[*,jthchan]= $ ; flux scaled by solid angle here
    total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
    total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  endcase
    store_data,mystring+'en_spec2plot_anti',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_spec2plot_anti, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
; ... perppas for energy spectra now
  elx_pxf_en_spec2plot_allowable=make_array(nhalfspinsavailable*((nspinsectors/2)+2),/double,value=!VALUES.F_NaN) ; same for all energies
  iperppas=where((reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) lt 180.-LCfptol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))) and $
    (reform(elx_pxf_pa_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+2)) gt +LCfptol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+2))), jperppas)
  if jperppas gt 0 then begin
    elx_pxf_en_spec2plot_allowable[iperppas]=1.
  endif
  elx_pxf_en_spec2plot_allowable=reform(elx_pxf_en_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+2)
  case mytype of
    'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_perp[*,jthchan]= $ ; just total counts here
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)
    'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_perp[*,jthchan]= $ ; just average counts over allowable look directions here
      total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)
  else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_spec2plot_perp[*,jthchan]= $  ; flux scaled by solid angle here
    total(elx_pxf_pa_spec2plot_full[*,1:(nspinsectors/2),jthchan]*elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN)/ $
    total(elx_pxf_en_spec2plot_domega[*,1:(nspinsectors/2)]*elx_pxf_en_spec2plot_allowable[*,1:(nspinsectors/2)],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
  endcase
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
    elx_pxf_en_reg_spec2plot_allowable=make_array(nhalfspinsavailable*((nspinsectors/2)+1),/double,value=!VALUES.F_NaN) ; same for all energies
    elx_pxf_en_reg_spec2plot_omni=make_array(nhalfspinsavailable,Max_numchannels,/double)
    elx_pxf_en_reg_spec2plot_para=make_array(nhalfspinsavailable,Max_numchannels,/double)
    elx_pxf_en_reg_spec2plot_anti=make_array(nhalfspinsavailable,Max_numchannels,/double)
    elx_pxf_en_reg_spec2plot_perp=make_array(nhalfspinsavailable,Max_numchannels,/double)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_omni[*,jthchan]= $
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_omni[*,jthchan]= $
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan],2,/NaN)/((nspinsectors/2)+1)
    else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_omni[*,jthchan]= $
      total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)],2,/NaN)/ $
      total(elx_pxf_en_spec2plot_domega[*,0:(nspinsectors/2)],2,/NaN) ; IGNORE SECTORS WITH NaNs
    endcase
    store_data,mystring+'en_reg_spec2plot_omni',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_omni, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    arrayofones=make_array((nspinsectors/2)+1,/double,value=1.)
;  select parapas for energy spectra first
    iparapas=where((reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) lt -LCfatol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))), jparapas)
    if jparapas gt 0 then begin
      elx_pxf_en_reg_spec2plot_allowable[iparapas]=1.
    endif
    elx_pxf_en_reg_spec2plot_allowable=reform(elx_pxf_en_reg_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+1)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_para[*,jthchan]= $ ; just total counts here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_para[*,jthchan]= $ ; just average counts over allowable look directions here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
        total(elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)
      else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_para[*,jthchan]= $ ; flux scaled by solid angle here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
        total(elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)
    endcase
    store_data,mystring+'en_reg_spec2plot_para',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_para, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
; ... antipas for energy spectra now
    elx_pxf_en_reg_spec2plot_allowable=make_array(nhalfspinsavailable*((nspinsectors/2)+1),/double,value=!VALUES.F_NaN) ; reset array!
    iantipas=where((reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) gt 180.+LCfatol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))), jantipas)
    if jantipas gt 0 then begin
      elx_pxf_en_reg_spec2plot_allowable[iantipas]=1.
    endif
    elx_pxf_en_reg_spec2plot_allowable=reform(elx_pxf_en_reg_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+1)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_anti[*,jthchan]= $ ; just total counts here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_anti[*,jthchan]= $ ; just average counts over allowable look directions here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
        total(elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN) 
      else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_anti[*,jthchan]= $ ; flux scaled by solid angle here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
        total(elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN) 
    endcase
    store_data,mystring+'en_reg_spec2plot_anti',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_anti, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
; ... perppas for energy spectra now
    elx_pxf_en_reg_spec2plot_allowable=make_array(nhalfspinsavailable*((nspinsectors/2)+1),/double,value=!VALUES.F_NaN) ; reset array!
    iperppas=where((reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) lt 180.-LCfptol-reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))) and $
      (reform(elx_pxf_pa_reg_spec_pas2plot,nhalfspinsavailable*((nspinsectors/2)+1)) gt +LCfptol+reform(paraedgedeg.y#arrayofones,nhalfspinsavailable*((nspinsectors/2)+1))), jperppas)
    if jperppas gt 0 then begin
      elx_pxf_en_reg_spec2plot_allowable[iperppas]=1.
    endif
    elx_pxf_en_reg_spec2plot_allowable=reform(elx_pxf_en_reg_spec2plot_allowable,nhalfspinsavailable,(nspinsectors/2)+1)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_perp[*,jthchan]= $ ; just total counts here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_perp[*,jthchan]= $ ; just average counts over allowable look directions here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
        total(elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)
      else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_spec2plot_perp[*,jthchan]= $ ; flux scaled by solid angle here
        total(elx_pxf_pa_reg_spec2plot_full[*,0:(nspinsectors/2),jthchan]*elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)/ $
        total(elx_pxf_en_reg_spec2plot_domega[*,0:(nspinsectors/2)]*elx_pxf_en_reg_spec2plot_allowable[*,0:(nspinsectors/2)],2,/NaN)
    endcase
    store_data,mystring+'en_reg_spec2plot_perp',data={x:elx_pxf_pa_spec_times, y:elx_pxf_en_reg_spec2plot_perp, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
  endif
  ;
  ; repeat the above for fulspn case: make energy spectra: Omni, Para, Perp, Anti
  ; Para and Anti: check when theta less that losscone+tolerance, where LCfatol tolerance=FOVo2+SectWidth/2 and LCfptol=-FOVo2 (open perp) unless user-specified
  ; Omni fuspn need NOT include one more sector, since full spin has symmetric pitch angles now.
  if keyword_set(fullspin) then begin ; process and store fulspn arrays and tplot var's
    elx_pxf_en_fulspn_spec2plot_domega=make_array(nfullspinsavailable,nspinsectors+2,/double) ; same for all energies
    elx_pxf_en_fulspn_spec2plot_domega[*,*]=(2.*!PI/nspinsectors)*sin(!PI*elx_pxf_pa_fulspn_spec_pas2plot[*,*]/180.)
    elx_pxf_en_fulspn_spec2plot_domega1d=reform(elx_pxf_en_fulspn_spec2plot_domega,nfullspinsavailable*(nspinsectors+2))
    i1d=make_array(nfullspinsavailable*(nspinsectors+2),/index,/long)
    izeropas=where((reform(elx_pxf_pa_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+2)) lt 360./nspinsectors/2) or $
      (reform(elx_pxf_pa_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+2)) gt 180.-360./nspinsectors/2), jzeropas)
    if jzeropas gt 0 then elx_pxf_en_fulspn_spec2plot_domega1d[izeropas]=(!PI/nspinsectors)*sin(!PI/nspinsectors) ; in degrees, that's pa = dpa = 22.5/2 = 11.25 for 16 sectors
    elx_pxf_en_fulspn_spec2plot_domega=reform(elx_pxf_en_fulspn_spec2plot_domega1d,nfullspinsavailable,nspinsectors+2)
    elx_pxf_en_fulspn_spec2plot_allowable=make_array(nfullspinsavailable*(nspinsectors+2),/double,value=!VALUES.F_NaN) ; same for all energies
    elx_pxf_en_fulspn_spec2plot_omni=make_array(nfullspinsavailable,Max_numchannels,/double)
    elx_pxf_en_fulspn_spec2plot_para=make_array(nfullspinsavailable,Max_numchannels,/double)
    elx_pxf_en_fulspn_spec2plot_anti=make_array(nfullspinsavailable,Max_numchannels,/double)
    elx_pxf_en_fulspn_spec2plot_perp=make_array(nfullspinsavailable,Max_numchannels,/double)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_omni[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_omni[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan],2,/NaN)/nspinsectors
      else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_omni[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors],2,/NaN)/ $
        total(elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors],2,/NaN) ; IGNORE FIRST AND LAST APPENDED SECTORS, WHICH ARE THERE ONLY FOR PLOTTING PURPOSES
    endcase
    store_data,mystring+'en_fulspn_spec2plot_omni',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_fulspn_spec2plot_omni, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    arrayofones=make_array(nspinsectors+2,/double,value=1.)
    ;  select parapas for energy spectra first
    paraedgedeg_fulspn=(paraedgedeg.y[ifirsthalfspin+2*ispins]+paraedgedeg.y[ifirsthalfspin+2*ispins+1])/2.
    iparapas=where((reform(elx_pxf_pa_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+2)) lt -LCfatol+reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+2))), jparapas)
    if jparapas gt 0 then begin
      elx_pxf_en_fulspn_spec2plot_allowable[iparapas]=1.
    endif
    elx_pxf_en_fulspn_spec2plot_allowable=reform(elx_pxf_en_fulspn_spec2plot_allowable,nfullspinsavailable,nspinsectors+2)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_para[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_para[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)/ $
        total(elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
      else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_para[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)/ $
        total(elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
    endcase
    store_data,mystring+'en_fulspn_spec2plot_para',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_fulspn_spec2plot_para, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    ; ... antipas for energy spectra now
    elx_pxf_en_fulspn_spec2plot_allowable=make_array(nfullspinsavailable*(nspinsectors+2),/double,value=!VALUES.F_NaN) ; same for all energies
    iantipas=where((reform(elx_pxf_pa_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+2)) gt 180.+LCfatol-reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+2))), jantipas)
    if jantipas gt 0 then begin
      elx_pxf_en_fulspn_spec2plot_allowable[iantipas]=1.
    endif
    elx_pxf_en_fulspn_spec2plot_allowable=reform(elx_pxf_en_fulspn_spec2plot_allowable,nfullspinsavailable,nspinsectors+2)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_anti[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_anti[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)/ $
        total(elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
      else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_anti[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)/ $
        total(elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
    endcase
    store_data,mystring+'en_fulspn_spec2plot_anti',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_fulspn_spec2plot_anti, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    ; ... perppas for energy spectra now
    elx_pxf_en_fulspn_spec2plot_allowable=make_array(nfullspinsavailable*(nspinsectors+2),/double,value=!VALUES.F_NaN) ; same for all energies
    iperppas=where((reform(elx_pxf_pa_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+2)) lt 180.-LCfptol-reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+2))) and $
      (reform(elx_pxf_pa_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+2)) gt +LCfptol+reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+2))), jperppas)
    if jperppas gt 0 then begin
      elx_pxf_en_fulspn_spec2plot_allowable[iperppas]=1.
    endif
    elx_pxf_en_fulspn_spec2plot_allowable=reform(elx_pxf_en_fulspn_spec2plot_allowable,nfullspinsavailable,nspinsectors+2)
    case mytype of
      'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_perp[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
      'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_perp[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)/ $
        total(elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)
      else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_fulspn_spec2plot_perp[*,jthchan]= $
        total(elx_pxf_pa_fulspn_spec2plot_full[*,1:nspinsectors,jthchan]*elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN)/ $
        total(elx_pxf_en_fulspn_spec2plot_domega[*,1:nspinsectors]*elx_pxf_en_fulspn_spec2plot_allowable[*,1:nspinsectors],2,/NaN) 
    endcase
    store_data,mystring+'en_fulspn_spec2plot_perp',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_fulspn_spec2plot_perp, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    ;
    if keyword_set(regularize) then begin
      elx_pxf_pa_reg_fulspn_spec_pas2plot=elx_pxf_pa_reg_fulspn_spec_pas
      elx_pxf_en_reg_fulspn_spec2plot_domega=make_array(nfullspinsavailable,nspinsectors+1,/double) ; same for all energies
      elx_pxf_en_reg_fulspn_spec2plot_domega[*,*]=(2.*!PI/nspinsectors)*sin(!PI*elx_pxf_pa_reg_fulspn_spec_pas2plot[*,*]/180.)
      elx_pxf_en_reg_fulspn_spec2plot_domega1d=reform(elx_pxf_en_reg_fulspn_spec2plot_domega,nfullspinsavailable*(nspinsectors+1))
      i1d=make_array(nfullspinsavailable*(nspinsectors+1),/index,/long)
      izeropas=where((reform(elx_pxf_pa_reg_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+1)) lt 360./nspinsectors/2) or $
        (reform(elx_pxf_pa_reg_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+1)) gt 180.-360./nspinsectors/2), jzeropas)
      if jzeropas gt 0 then elx_pxf_en_reg_fulspn_spec2plot_domega1d[izeropas]=(!PI/nspinsectors)*sin(!PI/nspinsectors) ; in degrees, that's pa = dpa = 22.5/2 = 11.25 for 16 sectors
      elx_pxf_en_reg_fulspn_spec2plot_domega=reform(elx_pxf_en_reg_fulspn_spec2plot_domega1d,nfullspinsavailable,nspinsectors+1)
      elx_pxf_en_reg_fulspn_spec2plot_allowable=make_array(nfullspinsavailable*(nspinsectors+1),/double,value=!VALUES.F_NaN) ; same for all energies
      elx_pxf_en_reg_fulspn_spec2plot_omni=make_array(nfullspinsavailable,Max_numchannels,/double)
      elx_pxf_en_reg_fulspn_spec2plot_para=make_array(nfullspinsavailable,Max_numchannels,/double)
      elx_pxf_en_reg_fulspn_spec2plot_anti=make_array(nfullspinsavailable,Max_numchannels,/double)
      elx_pxf_en_reg_fulspn_spec2plot_perp=make_array(nfullspinsavailable,Max_numchannels,/double)
      case mytype of
        'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_omni[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan],2,/NaN)
        'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_omni[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan],2,/NaN)/(nspinsectors+1)
        else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_omni[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_domega[*,0:nspinsectors],2,/NaN)/ $
          total(elx_pxf_en_fulspn_spec2plot_domega[*,0:nspinsectors],2,/NaN)
      endcase
      store_data,mystring+'en_reg_fulspn_spec2plot_omni',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_reg_fulspn_spec2plot_omni, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
      arrayofones=make_array(nspinsectors+1,/double,value=1.)
      ;  select parapas for energy spectra first
      iparapas=where((reform(elx_pxf_pa_reg_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+1)) lt -LCfatol+reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+1))), jparapas)
      if jparapas gt 0 then begin
        elx_pxf_en_reg_fulspn_spec2plot_allowable[iparapas]=1.
      endif
      elx_pxf_en_reg_fulspn_spec2plot_allowable=reform(elx_pxf_en_reg_fulspn_spec2plot_allowable,nfullspinsavailable,nspinsectors+1)
      case mytype of
        'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_para[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
        'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_para[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)/ $
          total(elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
        else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_para[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_domega[*,0:nspinsectors]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)/ $
          total(elx_pxf_en_reg_fulspn_spec2plot_domega[*,0:nspinsectors]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
      endcase
      store_data,mystring+'en_reg_fulspn_spec2plot_para',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_reg_fulspn_spec2plot_para, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
      ; ... antipas for energy spectra now
      elx_pxf_en_reg_fulspn_spec2plot_allowable=make_array(nfullspinsavailable*(nspinsectors+1),/double,value=!VALUES.F_NaN) ; reset array!
      iantipas=where((reform(elx_pxf_pa_reg_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+1)) gt 180.+LCfatol-reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+1))), jantipas)
      if jantipas gt 0 then begin
        elx_pxf_en_reg_fulspn_spec2plot_allowable[iantipas]=1.
      endif
      elx_pxf_en_reg_fulspn_spec2plot_allowable=reform(elx_pxf_en_reg_fulspn_spec2plot_allowable,nfullspinsavailable,(nspinsectors+1))
      case mytype of
        'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_anti[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
        'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_anti[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)/ $
          total(elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
        else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_anti[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_domega[*,0:nspinsectors]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)/ $
          total(elx_pxf_en_reg_fulspn_spec2plot_domega[*,0:nspinsectors]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
      endcase
      store_data,mystring+'en_reg_fulspn_spec2plot_anti',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_reg_fulspn_spec2plot_anti, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
      ; ... perppas for energy spectra now
      elx_pxf_en_reg_fulspn_spec2plot_allowable=make_array(nfullspinsavailable*(nspinsectors+1),/double,value=!VALUES.F_NaN) ; reset array!
      iperppas=where((reform(elx_pxf_pa_reg_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+1)) lt 180.-LCfptol-reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+1))) and $
        (reform(elx_pxf_pa_reg_fulspn_spec_pas2plot,nfullspinsavailable*(nspinsectors+1)) gt +LCfptol+reform(paraedgedeg_fulspn#arrayofones,nfullspinsavailable*(nspinsectors+1))), jperppas)
      if jperppas gt 0 then begin
        elx_pxf_en_reg_fulspn_spec2plot_allowable[iperppas]=1.
      endif
      elx_pxf_en_reg_fulspn_spec2plot_allowable=reform(elx_pxf_en_reg_fulspn_spec2plot_allowable,nfullspinsavailable,nspinsectors+1)
      case mytype of
        'raw': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_perp[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
        'cps': for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_perp[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)/ $
          total(elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
        else: for jthchan=0,Max_numchannels-1 do elx_pxf_en_reg_fulspn_spec2plot_perp[*,jthchan]= $
          total(elx_pxf_pa_reg_fulspn_spec_full[*,0:nspinsectors,jthchan]*elx_pxf_en_reg_fulspn_spec2plot_domega[*,0:nspinsectors]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)/ $
          total(elx_pxf_en_reg_fulspn_spec2plot_domega[*,0:nspinsectors]*elx_pxf_en_reg_fulspn_spec2plot_allowable[*,0:nspinsectors],2,/NaN)
      endcase
      store_data,mystring+'en_reg_fulspn_spec2plot_perp',data={x:elx_pxf_pa_fulspn_spec_times, y:elx_pxf_en_reg_fulspn_spec2plot_perp, v:elx_pxf.v},dlim=mypxfdata_dlim,lim=mypxfdata_lim
    endif
  endif
  ;
  options,'el?_p?f_en*spec*',spec=1
  ylim,'el?_p?f_en*spec*',55.,6800.,1
  case mytype of
    'raw': begin
      zlim,'el?_p?f_en*spec*',0.5,8.*4.e4,1
      zlim,'el?_pef_pa_*spec2plot_ch0*',1.e1,1.e4,1
      zlim,'el?_pef_pa_*spec2plot_ch1*',0.5e1,1.e4,1
      zlim,'el?_pef_pa_*spec2plot_ch2*',0.2e1,1.e4,1
      zlim,'el?_pef_pa_*spec2plot_ch3*',0.2e-1,0.2e4,1
      myysubtitle='counts'
      ylim,'el?_p?f_en*spec*',-0.5,15.5,0
    end
    'cps': begin
      zlim,'el?_p?f_en*spec*',0.1,2.e5,1
      zlim,'el?_pef_pa_*spec2plot_ch0*',5.e1,5.e5,1
      zlim,'el?_pef_pa_*spec2plot_ch1*',2.e1,5.e5,1
      zlim,'el?_pef_pa_*spec2plot_ch2*',1.e1,5.e5,1
      zlim,'el?_pef_pa_*spec2plot_ch3*',1.e-1,1.e5,1
      myysubtitle='counts/s'
    end
    'eflux': begin
      zlim,'el?_p?f_en*spec*',1e4,1e9,1
      zlim,'el?_pef_pa_*spec2plot_ch0*',5.e5,1.e10,1
      zlim,'el?_pef_pa_*spec2plot_ch1*',5.e5,5.e9,1
      zlim,'el?_pef_pa_*spec2plot_ch2*',5.e5,2.5e9,1
      zlim,'el?_pef_pa_*spec2plot_ch3*',1.e5,1.e8,1
      myysubtitle=mypxfdata_dlim.ysubtitle
    end
    'nflux': begin
      zlim,'el?_p?f_en*spec*',10,2e7,1
      zlim,'el?_pef_pa_*spec2plot_ch0*',2.e3,5.e6,1
      zlim,'el?_pef_pa_*spec2plot_ch1*',1.e3,3.e6,1
      zlim,'el?_pef_pa_*spec2plot_ch2*',1.e2,1.e6,1
      zlim,'el?_pef_pa_*spec2plot_ch3*',1.e1,5.e3,1
      myysubtitle=mypxfdata_dlim.ysubtitle
    end
  endcase
  options,'el?_p?f_en*spec2plot_????','ysubtitle',myysubtitle ; for plotting purposes
  ; 
  ; The above code naturally produces one non-nominal t-res point per gap (rogue, has aliased sectors)
  ; near the middle of gap, and no NaNs between that point and its neighbors (gaps don't show in specs)
  ; The code below removs of the rogue point, if needed, and insertion of NaNs so the gap shows.
  ; You can (by keyowrd delsplitspins=1) request removal of the rogue mid-gap points
  ; 
  ; these are the quantities to operate on:
  tplot_names,'el?_p?f_en*spec2plot_???? el?_p?f_pa*spec*ch?',names=vars2fixgaps,/silent ; ONLY 2D QUANTITIES!!! NOT LOSSCONE ONES
  if keyword_set(delsplitspins) and jgaps gt 0 then begin ; if there are indeed sector gaps then do this
      foreach element, vars2fixgaps do begin
        copy_data,element,'var2fix'
        get_data,'var2fix',data=mydata_var2fix,dlim=mydlim_var2fix,lim=mylim_quant2clean
        inongapelems=make_array(n_elements(mydata_var2fix.x),value=1,/long)
        for jthgap=0,jgaps-1 do begin
          ivarelemsingap=where(mydata_var2fix.x gt elx_pxf.x[igapbegins[jthgap]] and mydata_var2fix.x lt elx_pxf.x[igapends[jthgap]],jvarelemsingap)
          if jvarelemsingap gt 0 then inongapelems[ivarelemsingap] = 0
        endfor
        inongappnts=where(inongapelems gt 0,jnongappnts)
        if jnongappnts lt 1 then inongappnts = [0] ; first point only if no good data (so it wont crash)
        arrayinfo=size(mydata_var2fix.v)
        case 1 of 
          arrayinfo[0] eq 1: myvsarray=mydata_var2fix.v
          arrayinfo[0] eq 2: myvsarray=mydata_var2fix.v[inongappnts,*]
        else: print,element,' v array has incorrect dimensions (>2?)'
        endcase
        store_data,'var2fix',data={x:mydata_var2fix.x[inongappnts],y:mydata_var2fix.y[inongappnts,*],v:myvsarray},dlim=mydlim_var2fix,lim=mylim_quant2clean
        copy_data,'var2fix',element
      endforeach
  endif
  ; ;
  ; ;degap interior gaps with two NaNs per gap
  if ~keyword_set(nonansingaps) then begin
    if keyword_set(fullspin) then mydt=Tspineff else mydt=Tspineff/2.
    tdegap,vars2fixgaps,dt=mydt,margin=0.5*mydt/2.,/twonanpergap,/over
    tdeflag,mystring+'losscone','linear',/over ; no degap for this one!
    tdeflag,mystring+'antilosscone','linear',/over ; no degap for this one!
  endif
end
