
;+
; PROCEDURE:
;   elf_phase_delay
;
; PURPOSE:
;   Compute the best phase delay for an EPDE science collection and update the phase delay ASCII file accordingly.
;
; KEYWORDS:
;   probe:              Specify a probe; valid values are 'a' or 'b'.
;                       If no probe is specified the default is probe 'a'.
;   Echannels:          Specify the desired energy channel bins as a list. If keyword is not set, the default is [0,3,6,9].
;   new_config:         Specify a new on-board phase delay correction if it has changed since the previous entry
;                       in the calibration file. Do not set this keyword if the on-board correction is unchanged.
;                       Must be specified in degrees.
;   pick_times:         Set this keyword to manually select a timeframe within the data to perform fits on while
;                       running code. If this keyword is not set, the code will use the time interval specified
;                       in the "oldtimes" variable. It is recommended to pick an interval around 1 minute in length.
;   overwrite_attitude: Set this keyword to indicate a manual override of the attitude data from elf_load_state.
;                       The correct attitude must be defined as "correct_att" in the code (GEI) along with its uncertainity (deg).
;                       Note: with the new attitude solution generation method, this is likely not needed anymore.
;   reprocess:          Set this keyword to run the code in "reprocess" mode only. In this case, medians are computed
;                       for any NaNs in previous completed intervals, but no fits are done on the current time selection.
;                       To use this mode, the user must run the code on a time interval that falls in the 7-day interval
;                       that is next recorded after the interval to reprocess.
;
; EXAMPLES:
;   elf_phase_delay, probe='b', Echannels=[3,6,9,12], /pick_times
;
; NOTES:
;   This code only operates on data on or after 2019-04-30 (due to improper MSP configurations prior to
;   this time).
;
;   When running this code for the first time on a new science collection interval, the pick_times keyword must be
;   turned on in order to manually select a smaller interval to perform the fits on. After selection, the
;   user can store these times in the "oldtimes" variable if future runs on the same science collection are
;   desired. It is recommended to pick a time interval that does not exceed two minutes in length to keep
;   the code running efficiently. The optimal time interval length is around 40-60 seconds.
;
;   After the code determines the correct phase delay, it will first ask if you want to flag it as "bad".
;   A result should be flagged as "bad" if the quality of the data prohibits accurate fits to the
;   pitch angle distribution. It is advised that the user views the final plot showing fits to the PAD
;   for each spin period to determine if a "bad" flag is necessary. Type "y"+Enter to flag the result as
;   "bad", or anything else + Enter to not flag.
;
;   The code will then display the chi squared value of the final fits and ask the user if they want to
;   record the phase delay corresponding to these fits in the phase delay file, or instead record a
;   placeholder value (a median of all the previously computed phase delays with the same on-board
;   correction and spin period within 20% of the current spin period of interest). Type "y"+Enter to record
;   the computed phase delay, or "n"+Enter to record a placeholder value. Note that if a placeholder is used,
;   the user should also flag this result as "bad".
;
;   Lastly, the code will ask if the user would like to add these results to the phase delay file. Type "y"
;   +Enter to do so, or "n"+ Enter to refrain from adding this new line to the file. In the latter case,
;   the file will simply be re-written with all the pre-existing results after median-reprocessing, if
;   applicable.
;
;   Any new entry added to the phase delay file will have NaN values in place of the median sector and
;   median phase angle. One must run the code on any time within the NEXT pre-defined 7-day interval (beginning from
;   2019-04-30) with EPD data that follows this science collection in order to automatically compute a
;   median fit value that is then re-processed into the file. The median calculation for each 7-day interval
;   disregards any entries with badFlag=1, and divides the interval into smaller chunks corresponding to the
;   same on-board correction and similar spin period if a change is detected.
;
;   Note that dPhAng2add more than +/- 11 does not work. Additional sectors are added at this point.
;

      ;+
      ; :Description:
      ;    Describe the procedure.
      ;
      ;
      ;
      ; :Keywords:
      ;    pick_times
      ;    new_config
      ;    probe
      ;    Echannels
      ;    overwrite_attitude
      ;    check_nonmonotonic
      ;    sstart
      ;    send
      ;    soldtimes
      ;
      ; :Author: lauraigs
      ;-
pro elf_phase_delay_auto_new_a, pick_times=pick_times, new_config=new_config, probe=probe, Echannels=Echannels, overwrite_attitude=overwrite_attitude, badFlag = badFlag, check_nonmonotonic=check_nonmonotonic, sstart = sstart, send = send, soldtimes = soldtimes

  ;elf_init
  ;
  tplot_options, 'xmargin', [15,9]
  cwdirname='C:\Users\ELFIN\IDLWorkspace\spedas\idl\projects\elfin\idlphasedelays'
  cwd,cwdirname

  if undefined(probe) then probe='a' else if probe ne 'a' and probe ne 'b' then begin
    print, 'Please enter a valid probe.'
    return
  endif

  ; HISTORY OF TIME INTERVALS USED
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; EL-A
  ;unu
  tstart= sstart ; (result: -1 sector + 2.5 deg)
  tend= send
  

  ; EL-B
  ;
  ;tstart='2019-08-06/16:58:30' ; (result: +1 sector - 0.4 deg)
  ;tend='2019-08-06/17:03:00'
  ;oldtimes=['2019-08-06/16:58:56', '2019-08-06/16:59:42']

  ;tstart='2020-05-06/17:06:00' ; (result: 0 sectors + 3.7 deg)
  ;tend='2020-05-06/17:10:00'
  ;oldtimes=['2020-05-06/17:08:27', '2020-05-06/17:09:07']


  ;;; BEGIN CODE ;;;
  ; If phase delay file is not stored locally: copy over from server

  ; If check_monotonic keyword is on: read special file and match start time with file entry
  if keyword_set(check_nonmonotonic) then begin
    pa_file='el'+probe+'_nonmonotonic_pas.txt'
    OPENR, lun, pa_file, /get_lun
    array=''
    line=''
    while not EOF(lun) do begin
      READF, lun, line
      array=[array,line]
    endwhile
    free_lun, lun
    pa_cols=strsplit(array[1],',',/extract) ;header names
    pa_data=make_array(4, n_elements(array)-2,/double)
    for n=2,n_elements(array)-1 do begin ;data (excluding blank line + headers at beginning and new line at end)
      data=strsplit(array[n],',',/extract)
      tbegin=time_string(data[0])
      tstop=time_string(data[1])
      nonmono_percent=float(data[2])
      nonmono_time=time_string(data[3])
      pa_data[0,n-2]=time_double(tbegin)
      pa_data[1,n-2]=time_double(tstop)
      pa_data[2,n-2]=nonmono_percent
      pa_data[3,n-2]=time_double(nonmono_time)
    endfor
    ; find row that matches with current tstart, tend interval (if any)
    new_flag=0
    tstart_diffs=abs(pa_data[0,*]-time_double(tstart))
    nearest=where(tstart_diffs eq min(tstart_diffs))
    if n_elements(nearest) gt 1 || tstart_diffs[nearest] gt 5*60 then matching_ind=!VALUES.F_NaN ;no matching row within 5 mins
    if n_elements(nearest) eq 1 && tstart_diffs[nearest] le 5*60 then matching_ind=nearest
    if ~finite(matching_ind) then begin
      tstart_diffs_sign=pa_data[0,*]-time_double(tstart) ;find smallest positive diff
      pos_diffs=tstart_diffs_sign(where(tstart_diffs_sign gt 0))
      matching_ind=where(tstart_diffs_sign eq min(pos_diffs))
      new_flag=1
    endif
  endif

  ; Read calibration (phase delay) file and store data
  file='el'+probe+'_epde_phase_delays.csv'
  filedata = read_csv(file, header = cols, types = ['String', 'String', 'Float', 'Float','Float','Float','Float'])
  dat = CREATE_STRUCT(cols[0], filedata.field1, cols[1], filedata.field2, cols[2], filedata.field3, cols[3],  filedata.field4, cols[4], filedata.field5, cols[5], filedata.field6, cols[6], filedata.field7)


  ; Prepare to load data of interest
  mytype='cps'
  timeduration=time_double(tend)-time_double(tstart)
  timespan,tstart,timeduration,/seconds
  pival=double(!PI)
  eightones = [1.,1.,1.,1.,1.,1.,1.,1.]

  ; Extract spin period for current data
  ;elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype, suffix='_current'
  elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype
  get_data, 'el'+probe+'_pef_spinper', data=spinper_current
  ;tspin_current=average(spinper_current.y)
  
  ;check
  check1 = total(n_elements(dat.tstart))



;print, latest_med_deg
;interval_start = time_double(tstart)-3600.*24.*7.
;interval_end = time_double(tstart)

;cal_data[3,*] ;latest_med_deg
;cal_data[4,*] ;tstart, doub
;cal_data[5,*] ;tend, doub



; prev_int_cal_data[3,*]=med_prev_new
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; After computing results for current data, write to file: prev_reprocessed_cal_data + current_int_prev_cal_data + current results + later_cal_data
  ;prev_reprocessed_cal_data=[[prior_cal_data],[prev_int_cal_data],[current_int_prev_cal_data]]

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FILE READING AND CONFIGURATION               ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;START OF FITS                                       ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  BODY:
  ;dSectr2add=dat.LatestMedianSectr[-1]; initial guesses (doesn't usually matter, but pos/neg sector should be correct otherwise parabolas might open upward)
  ;dPhAng2add=dat.LatestMedianPhAng[-1]

  ;INITIAL GUESSES
  dSectr2add = 2
  dPhAng2add = 4
  ;read, dSectr2add, PROMPT='IG, Sector: '
  ;read, dPhAng2add, PROMPT='IG Phase Angle: '
  
  ; make sure you pick a time just prior to an ascending PA!!!! This will make "even" PAs ascending ones (red), and "odd" PAs descending one (blue)
  ;elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype, suffix='_orig',/no_spec
  elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype, /no_spec
  if keyword_set(pick_times) then begin
    tplot,'el'+probe+'_pef_'+mytype
    print, 'explore time interval'
    stop

    ctime,tstartendtimes4pa2plot ; here pick 2 times between which to determine from the symmetry of the PA distribution around 90deg the time delay to use
    print,time_string(tstartendtimes4pa2plot)
    oldtimes_current = [time_string(tstartendtimes4pa2plot[0]), time_string(tstartendtimes4pa2plot[1])]
    
    print, 'continue? [y/n]'
    incommand = ' '
    read, incommand
    if incommand eq 'n' then begin
      phaseresult = 0
      autobad = 1
      badFlag = 2
      bad_comment = 'Not enough data. No reasonable fit.'
      goto, endoffits
    endif
    
  endif else begin
    oldtimes= soldtimes
    ; apply pre-determined times
    tstartendtimes4pa2plot=time_double(oldtimes)
    ;tstartendtimes4pa2plot=time_double([tstart,tend]) ; do fits on full interval
    oldtimes_current = oldtimes
    tplot,'el'+probe+'_pef_'+mytype+'_orig'
    timebar,time_string(tstartendtimes4pa2plot)
  endelse

  iters=0
  FINDSHIFT:
  elf_load_state, probes=[probe],/get_support_data
  elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
  get_data,'el'+probe+'_att_gei',data=elf_att_gei,dlim=myattdata_dlim,lim=myattdata_lim
  get_data,'el'+probe+'_pos_gei',data=elf_pos_gei,dlim=mypostdata_dlim,lim=myposdata_lim
  get_data,'el'+probe+'_att_uncertainty',data=elf_att_unc
  elf_att_unc=median(elf_att_unc.y)

  ; Overwrite attitude with updated solution if desired
  if keyword_set(overwrite_attitude) then begin
    ;correct_att=[0.62071564, 0.17670628, 0.76386320] ; 2019-08-30 ELA
    ;elf_att_unc=1.41
    ;correct_att=[0.62027727, 0.18392227, 0.76251473] ; 2019-08-31 ELA. ANGLE DIFF NOW 8.22 deg (slightly worse, and larger unc than correct result)
    ;elf_att_unc=1.43
    ;correct_att=[0.53815934, 0.31622239, 0.78127327] ; 2019-09-01 ELA. ANGLE DIFF NOW 10 deg (worse than before)
    ;elf_att_unc=0.72
    ;correct_att=[0.62953896, 0.17877359, 0.75612215] ; 2019-09-02 ELA. ANGLE DIFF NOW 6.1 deg (slightly worse)
    ;elf_att_unc=1.21
    ;correct_att=[0.62205501, -0.64666323, 0.44144563] ; 2019-09-28 ELA. ANGLE DIFF NOW 1.8 DEG FROM DATABASE (smaller diff but still not correct)
    ;elf_att_unc=1.16
    ;correct_att=[0.59123383, -0.66197856, 0.46068095] ; 2019-09-29 ELA. ANGLE DIFF NOW 30 DEG FROM DATABASE (Fri)
    ;elf_att_unc=2.49 ; Mon 10/21: angle diff now 1.08 deg (smaller diff but still not correct)
    ;correct_att=[-0.50158691, -0.86418323, -0.039973866] ; 2019-08-30 ELB. ANGLE DIFF NOW 11.68 deg (slightly smaller but still not correct)
    ;elf_att_unc=0.96
    ;correct_att=[-0.54878167, -0.83582606, -0.015279864] ; 2019-08-31 ELB. ANGLE DIFF NOW 15.18 deg (slightly smaller but still not correct)
    ;elf_att_unc=0.66
    ;correct_att=[-0.48442246, -0.87472884, 0.013576750] ; 2019-09-01 ELB, also use for 2019-09-02
    ;elf_att_unc=1.40 ; ANGLE DIFF NOW 6.36 deg (slightly smaller but still not correct)
    ;correct_att=[-0.97041919, 0.22787842, 0.079737210] ;2019-09-28 ELB. ANGLE DIFF 8.9 DEG FROM DATABASE (same as before)
    ;elf_att_unc=0.93
    ;correct_att=[-0.97329805, 0.20774275, 0.097641486] ;2019-09-29 ELB. ANGLE DIFF 7.6 DEG FROM DATABASE (same as before)
    ;elf_att_unc=0.93

    ;correct_att=[0.85437437499675539, 0.43914147942310860, 0.27784741927717677] ;new att: ELB 7/25
    ;correct_att=[0.97242286644801978, -0.075536002981490338, 0.22065375832420575] ; new att: ELB 7/28
    ;correct_att=[0.97348718690298297, -0.14885435643749237, 0.17368096471777406] ; new att: ELB 7/30
    ;correct_att=[-0.36802567346539994, -0.92917121749136322, 0.034611446891981895] ; new att: ELB 8/31
    ;correct_att=[-0.95588813833793562, 0.27974130981871748, 0.089569339428980405] ; new att: ELB 9/29
    ;correct_att=[-0.63077110970924966, 0.77548806553761862, 0.027314233741476856] ;new att: ELB 10/10
    ;correct_att=[-0.58318683747271693, 0.80906869817346450, 0.072807652307064194] ;new att: ELB 10/11
    ;correct_att=[-0.60617103263845584, -0.76085946029559182, 0.23162374849900166] ;new att: ELB 12/27
    correct_att=[0.77457979806743416, 0.59057065030610334, -0.22639002500737349] ;new att: ELB 3/04
    ;correct_att=[0.84461619541580546, 0.48362599897219805, -0.22962877772499113] ;new att: ELB 3/05

    angle_diff_db=acos(elf_att_gei.y[0,*]#correct_att) * !RADEG
    print, 'Angle difference between correct_att and att now in db: ', angle_diff_db
    ;stop
    elf_att_gei.y[*,0]=correct_att[0]
    elf_att_gei.y[*,1]=correct_att[1]
    elf_att_gei.y[*,2]=correct_att[2]
    store_data, 'el'+probe+'_att_gei', data={x:elf_att_gei.x, y:elf_att_gei.y}
  endif

  tinterpol_mxn,'el'+probe+'_att_gei','el'+probe+'_pos_gei',/over
  copy_data,'el'+probe+'_pef_'+mytype,'el'+probe+'_pef'
  get_data,'el'+probe+'_pef',data=elf_pef,dlim=mypefdata_dlim,lim=mypefdata_lim
  elf_pef.v=[50.0000,      80.0000,      120.000,      160.000,      210.000, $
    270.000,      345.000,      430.000,      630.000,      900.000, $
    1300.00,      1800.00,      2500.00,      3350.00,      4150.00,      5800.00] ; these are the low energy bounds
  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; shift PEF times to the right by 1 sector, make 1st point a NaN, all times now represent mid-points!!!!
  ; The reason is that the actual FGS cross-correlation shows that the DBZDT zero crossing is exactly
  ; in the middle between sector nspinsectors-1 and sector 0, meaning there is no need for any other time-shift rel.to.FGM
  ;
  ; First redefine energies in structure to be middle of energy width. In the future this will be corrected in CDFs.
  Emins=elf_pef.v
  Max_numchannels = n_elements(elf_pef.v) ; this is 16
  Emaxs=(Emins[1:Max_numchannels-1])
  ; last channel is integral, add it anyway
  dEoflast=(Emaxs[Max_numchannels-2]-Emins[Max_numchannels-2])
  Emaxs=[Emaxs,Emins[Max_numchannels-1]+dEoflast] ; last channel's, max energy not representative, use same dE/E as previous
  Emids=(Emaxs+Emins)/2.
  elf_pef.v=Emids

  if keyword_set(Echannels) then MinE_channels=Echannels else MinE_channels = [0, 3, 6, 9]
  numchannels = n_elements(MinE_channels)
  if numchannels gt 1 then $
    MaxE_channels = [MinE_channels[1:numchannels-1]-1,Max_numchannels-1] else $
    MaxE_channels = MinE_channels+1
  nsectors=n_elements(elf_pef.x)
  nspinsectors=n_elements(reform(elf_pef.y[0,*]))
  
  if dSectr2add ne 0 then begin
    xra=make_array(nsectors-abs(dSectr2add),/index,/long)
    if dSectr2add gt 0 then begin
      elf_pef.y[dSectr2add:nsectors-1,*]=elf_pef.y[xra,*]
      elf_pef.y[0:dSectr2add-1,*]=!VALUES.F_NaN
    endif else if dSectr2add lt 0 then begin
      elf_pef.y[xra,*]=elf_pef.y[abs(dSectr2add):nsectors-1,*]
      elf_pef.y[dSectr2add:nsectors-1,*]=!VALUES.F_NaN
    endif
    store_data,'el'+probe+'_pef',data={x:elf_pef.x,y:elf_pef.y,v:elf_pef.v},dlim=mypefdata_dlim,lim=mypefdata_lim ; you can save a NaN!
  endif

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; extrapolate on the left and right to [0,...nspinsectors-1], degap the data
  tres,'el'+probe+'_pef_sectnum',dt_sectnum
  elf_pef_sectnum_new=elf_pef_sectnum.y
  elf_pef_sectnum_new_times = elf_pef_sectnum.x
  if elf_pef_sectnum.y[0] gt 0 then begin
    elf_pef_sectnum_new = [0., elf_pef_sectnum.y]
    elf_pef_sectnum_new_times = [elf_pef_sectnum.x[0] - elf_pef_sectnum.y[0]*dt_sectnum, elf_pef_sectnum_new_times]
  endif
  if elf_pef_sectnum.y[n_elements(elf_pef_sectnum.y)-1] lt (nspinsectors-1) then begin
    elf_pef_sectnum_new = [elf_pef_sectnum_new, float(nspinsectors-1)]
    elf_pef_sectnum_new_times = $
      [elf_pef_sectnum_new_times , elf_pef_sectnum_new_times[n_elements(elf_pef_sectnum_new_times)-1] + (float(nspinsectors-1)-elf_pef_sectnum.y[n_elements(elf_pef_sectnum.y)-1])*dt_sectnum]
  endif
  ;stop
  store_data,'el'+probe+'_pef_sectnum',data={x:elf_pef_sectnum_new_times,y:elf_pef_sectnum_new},dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  tdegap,'el'+probe+'_pef_sectnum',dt=dt_sectnum,/over
  tdeflag,'el'+probe+'_pef_sectnum','linear',/over
  ;
  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum ; now pad middle gaps!

  ksectra=make_array(n_elements(elf_pef_sectnum.x)-1,/index,/long)
  dts=(elf_pef_sectnum.x[ksectra+1]-elf_pef_sectnum.x[ksectra])
  dsectordt=(elf_pef_sectnum.y[ksectra+1]-elf_pef_sectnum.y[ksectra])/dts
  ianygaps=where((dsectordt lt 0.75*median(dsectordt) and (dsectordt gt -0.5*float(-1)/dt_sectnum)),janygaps) ; slope below 0.75*nspinsectors/(nspinsectors*dt_sectnum) when a spin gap exists (gives <0.5), force it to median
  if janygaps gt 0 then dsectordt[ianygaps]=median(dsectordt)
  dsectordt=[dsectordt[0],dsectordt]
  dts=[0,dts]
  tol=0.25*median(dts)
  mysectornumpadded=long(total(dsectordt*dts,/cumulative) + elf_pef_sectnum.y[0]+tol) mod nspinsectors
  mysectornewtimes=(total(dts,/cumulative) + elf_pef_sectnum.x[0])
  store_data,'el'+probe+'_pef_sectnum',data={x:mysectornewtimes,y:float(mysectornumpadded)},dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;
  ;AT THIS POINT (lines above): pef_sectnum tplot variable turns into step function at interpolated gaps
  ;
  ; now pad the rest of the quantities
  get_data,'el'+probe+'_pef_spinper',data=elf_pef_spinper,dlim=myspinperdata_dlim,lim=myspinperdata_lim ; this preserved the original times
  store_data,'el'+probe+'_pef_times',data={x:elf_pef_spinper.x,y:elf_pef_spinper.x-elf_pef_spinper.x[0]} ; this is to track gaps
  tinterpol_mxn,'el'+probe+'_pef_times','el'+probe+'_pef_sectnum',/nearest_neighbor,/NAN_EXTRAPOLATE,/over ; middle gaps have constant values after interpolation, side pads are NaNs themselves
  get_data,'el'+probe+'_pef_times',data=elf_pef_times
  xra=make_array(n_elements(elf_pef_times.x)-1,/index,/long)
  iany=where(elf_pef_times.y[xra+1]-elf_pef_times.y[xra] lt 1.e-6, jany) ; takes care of middle gaps
  inans=where(FINITE(elf_pef_times.y,/NaN),jnans) ; identifies side pads
  ;
  tinterpol_mxn,'el'+probe+'_pef','el'+probe+'_pef_sectnum',/over
  get_data,'el'+probe+'_pef',data=elf_pef,dlim=mypefdata_dlim,lim=mypefdata_lim
  if jnans gt 0 then elf_pef.y[inans,*]=!VALUES.F_NaN
  if jany gt 0 then elf_pef.y[iany,*]=!VALUES.F_NaN
  store_data,'el'+probe+'_pef',data={x:elf_pef.x,y:elf_pef.y,v:elf_pef.v},dlim=mypefdata_dlim,lim=mypefdata_lim
  ;
  tinterpol_mxn,'el'+probe+'_pef_spinper','el'+probe+'_pef_sectnum',/overwrite ; linearly interpolated, this you keep
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;
  ; Extrapolation and degapping completed!!! Now start viewing
  ;
  get_data,'el'+probe+'_pef',data=elf_pef,dlim=mypefdata_dlim,lim=mypefdata_lim
  get_data,'el'+probe+'_pef_spinper',data=elf_pef_spinper,dlim=myspinperdata_dlim,lim=myspinperdata_lim
  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;
  nsectors=n_elements(elf_pef.x)
  xra=make_array(nsectors-1,/index,/long)
  dts=elf_pef.x[xra+1]-elf_pef.x[xra]
  ddts=[0,dts-median(dts)]
  store_data,'ddts',data={x:elf_pef.x,y:ddts}
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;
  ; now assign spin phase (rel. to ascending Bz zero crossing) and pitch angle to each sector
  ;
  lastzero=[xra,nsectors]-long(elf_pef_sectnum.y+0.5)
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
  spinphase180=(dPhAng2add+float(elf_pef_sectnum.x-elf_pef_sectnum.x[lastzero]+0.5*elf_pef_spinper.y/float(nspinsectors))*360./elf_pef_spinper.y) mod 360.
  spinphase=spinphase180*!PI/180. ; in radians corresponds to the center of the sector
  store_data,'spinphase',data={x:elf_pef_sectnum.x,y:spinphase} ; just to see...
  store_data,'spinphasedeg',data={x:elf_pef_sectnum.x,y:spinphase*180./!PI} ; just to see...
  ylim,"spinphasedeg",0.,360.,0.
  options,'spinphasedeg','databar',180.
  options,'ddts','databar',{yval:[0.], color:[6], linestyle:2}

  threeones=[1,1,1]
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  tt89,'el'+probe+'_pos_gsm',/igrf_only,newname='el'+probe+'_bt89_gsm',period=1.
  cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; <-- use SM geophysical coordinates plus Despun Spacecraft coord's with Lvec (DSL)
  cotrans,'el'+probe+'_bt89_gsm','el'+probe+'_bt89_sm',/GSM2SM ; Bfield in same coords as well
  cotrans,'el'+probe+'_att_gei','el'+probe+'_att_gse',/GEI2GSE
  cotrans,'el'+probe+'_att_gse','el'+probe+'_att_gsm',/GSE2GSM
  cotrans,'el'+probe+'_att_gsm','el'+probe+'_att_sm',/GSM2SM ; attitude in SM
  ;
  calc,' "el'+probe+'_bt89_sm_par" = (total("el'+probe+'_bt89_sm"*"el'+probe+'_att_sm",2)#threeones)*"el'+probe+'_att_sm" '
  tvectot,"el"+probe+"_bt89_sm_par",newname="el"+probe+"_bt89_sm_part"
  ;
  calc,' "el'+probe+'_bt89_sm_per" = "el'+probe+'_bt89_sm"-"el'+probe+'_bt89_sm_par" '
  tvectot,"el"+probe+"_bt89_sm_per",newname="el"+probe+"_bt89_sm_pert"
  ;
  tinterpol_mxn,'el'+probe+'_bt89_sm','el'+probe+'_pef' ; interpolate Bt89SM
  tinterpol_mxn,'el'+probe+'_att_sm','el'+probe+'_pef' ; interpolate attitude
  calc,' "el'+probe+'_att_sm_interp" = "el'+probe+'_att_sm_interp" / (total("el'+probe+'_att_sm_interp"^2,2)#threeones) ' ; now for sure normalized!
  get_data,'el'+probe+'_att_sm_interp',data=elf_att_sm_interp,dlim=myattdlim,lim=myattlim
  ;
  tcrossp, 'el'+probe+'_bt89_sm_interp', 'el'+probe+'_att_sm_interp',newname="el"+probe+"_bt89_sm_interp_0xdir" ; not normalized to one yet!
  calc,' "el'+probe+'_bt89_sm_interp_0xdir" = "el'+probe+'_bt89_sm_interp_0xdir"  / (sqrt(total("el'+probe+'_bt89_sm_interp_0xdir"^2,2))#threeones) ' ; now also normalized!
  tcrossp,"el"+probe+"_att_sm_interp","el"+probe+"_bt89_sm_interp_0xdir",newname="el"+probe+"_bt89_sm_interp_bspinplanedir" ; already normalized!
  ; Now you have DSL system vectors in SM coordinates. Can form transformation matrix from DSL to SM. Its columns are the DSL unit vectors in SM.
  ; Rotation of ela_bt89_sm_0xdir vector about DSLz by spinphase angle is sector center unit direction in space in DSL coordinates.
  ; Then rotation of that direction from DSL to SM coordinates is the direction we need to use to compute pitch angle relative to Bfield in SM coords.
  ; Note that it is the opposite of that direction we need, as it is the particle motion direction (not the detector direction) that defines pitch angle.
  ; Here detector spinphase = 0 means 90degPA; det. spinphase = 90 means part.direction =270 and particle PA = 180 if B is on spin plane
  ; DSL rot matrix about Z is: [[cos(ph),-sin(ph),0],[sin(ph),cos(ph),0],[0,0,1]] but in IDL's majority column convention requires the transpose.
  ; However, this transposition it taken care of internally with tvector_rotate, so you can use that instead!
  rotaboutdslz=[[[cos(spinphase)],[-sin(spinphase)],[0*spinphase]],[[sin(spinphase)],[cos(spinphase)],[0*spinphase]],[[0.*spinphase],[0.*spinphase],[1.+0.*spinphase]]]
  get_data,'el'+probe+'_bt89_sm_interp_0xdir',data=DSLX ; in SM coord's
  get_data,'el'+probe+'_bt89_sm_interp_bspinplanedir',data=DSLY ; in SM coord's
  get_data,'el'+probe+'_att_sm_interp',data=DSLZ ; in SM coord's

  ;stop ;non-monotonic PA issue could originate above?

  ;; BELOW MATRIX is where attitude information is used
  rotDSL2SM = [[[DSLX.y[*,0]],[DSLX.y[*,1]],[DSLX.y[*,2]]],[[DSLY.y[*,0]],[DSLY.y[*,1]],[DSLY.y[*,2]]],[[DSLZ.y[*,0]],[DSLZ.y[*,1]],[DSLZ.y[*,2]]]]

  ; rotate unit vector [1,0,0] by spinphase about DSLZ, then into SM
  unitXvec2rot=[[1.+0.*spinphase],[0.*spinphase],[0.*spinphase]]
  store_data,'unitXvec2rot',data={x:elf_pef.x,y:unitXvec2rot},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
  store_data,'rotaboutdslz',data={x:elf_pef.x,y:rotaboutdslz},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
  store_data,'rotDSL2SM',data={x:elf_pef.x,y:rotDSL2SM},dlim=myattdlim,lim=myattlim ; pretend all coords are SM in dlim to force tvector_rotate to accept
  ;
  tvector_rotate,'rotaboutdslz','unitXvec2rot',newname='sectordir_dsl' ; says SM but OK
  tvector_rotate,'rotDSL2SM','sectordir_dsl',newname='sectordir_sm'
  ;NOTE: above rotation to sectordir_sm changes if using different attitude (but dsl is the same)
  calc,' "el'+probe+'_pef_sm_interp_partdir"= - "sectordir_sm" '
  ;
  calc,' "el'+probe+'_pef_pa" = arccos(total("el'+probe+'_pef_sm_interp_partdir" * "el'+probe+'_bt89_sm_interp",2) / (sqrt(total("el'+probe+'_bt89_sm_interp"^2,2)) * sqrt(total("el'+probe+'_pef_sm_interp_partdir"^2,2)))) *180./pival '
  get_data,'el'+probe+'_pef_sm_interp_partdir',data=partdir
  get_data,'el'+probe+'_bt89_sm_interp',data=bt89
  get_data,'el'+probe+'_pef_pa',data=elf_pef_pa

    
  ; now examine IGRF Bfield. transform elx_bt89_sm_interp from SM to GEI coords
  cotrans,'el'+probe+'_bt89_sm_interp','el'+probe+'_bt89_gsm_interp',/SM2GSM
  cotrans,'el'+probe+'_bt89_gsm_interp','el'+probe+'_bt89_gse_interp',/GSM2GSE
  cotrans,'el'+probe+'_bt89_gse_interp','el'+probe+'_bt89_gei_interp',/GSE2GEI
  get_data,'el'+probe+'_bt89_gei_interp',data=elf_bt89_gei_interp

  angles_bfield_att=make_array(n_elements(elf_bt89_gei_interp.x))
  min_pas=angles_bfield_att
  max_pas=angles_bfield_att
  correct_att=reform(elf_att_gei.y[0,*])
  for n=0,n_elements(elf_bt89_gei_interp.x)-1 do begin
    dot_prod=elf_bt89_gei_interp.y[n,*]#correct_att
    mag_bfield=(total(elf_bt89_gei_interp.y[n,*]^2))^0.5
    mag_att=(total(correct_att^2))^0.5
    angle=acos(dot_prod/(mag_bfield*mag_att)) * !RADEG
    angles_bfield_att[n]=angle
    ; compute theoretical min and max PAs (since B-field is time series, this should also be time series?)
    min_pa=abs((angle-90.) mod 180.)
    max_pa=180.-min_pa
    min_pas[n]=min_pa
    max_pas[n]=max_pa
  endfor
  store_data,'el'+probe+'_bfield_att_angle',data={x:elf_bt89_gei_interp.x, y:angles_bfield_att}
  store_data,'el'+probe+'_pas_minmax',data={x:elf_bt89_gei_interp.x, y:[[elf_pef_pa.y],[min_pas],[max_pas]]}
  tplot,'el'+probe+'_pas_minmax'

  ylim,"el"+probe+"_pef_pa",0.,180.,0.
  ylim,"spinphasedeg",-5.,365.,0.
  options,'el'+probe+'_pef_pa','databar',90.
  options,'spinphasedeg','databar',180.
  tplot,'el'+probe+'_pef_pa spinphasedeg el'+probe+'_pef_sectnum el'+probe+'_pef'
  tplot_apply_databar

  tplot, 'el'+probe+'_pef el'+probe+'_pef_pa'
  timebar,time_string(tstartendtimes4pa2plot)
  ;stop ;show selected region ;PAs were flat at peaks/troughs first time, then pointy second time

  ; Now plot PA spectrum for a given energy or range of energies
  ; Since the datapoints and sectors are contiguous and divisible by nspinsectors (e.g. 16)
  ; you can fit them completely in an integer number of spins.
  ; Since any spin covers twice the accessible Pitch Angles
  ; you create two points per spin in a new array and populate
  ; it with the neighboring counts/fluxes.
  ;
  ; Note that Bz ascending zero is when part PA is minimum (closest to 0).
  ; This is NOT sector 0, but between sectors 3 and 4.
  ;
  nspins=nsectors/nspinsectors
  npitchangles=2*nspins
  elf_pef_val=make_array(nsectors,numchannels,/double)
  if (mytype eq 'nflux' or mytype eq 'eflux' ) then $
    for jthchan=0,numchannels-1 do $
    elf_pef_val[*,jthchan]=(elf_pef.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]] # $
    (Emaxs[MinE_channels[jthchan]:MaxE_channels[jthchan]]-Emins[MinE_channels[jthchan]:MaxE_channels[jthchan]])) / $
    total(Emaxs[MinE_channels[jthchan]:MaxE_channels[jthchan]]-Emins[MinE_channels[jthchan]:MaxE_channels[jthchan]]) ; MULTIPLIED BY ENERGY WIDTH AND THEN DIVIDED BY BROAD CHANNEL ENERGY
  if (mytype eq 'raw' or mytype eq 'cps' ) then $
    for jthchan=0,numchannels-1 do $
    elf_pef_val[*,jthchan]=total(elf_pef.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]],2) ; JUST SUMMED
  elf_pef_val_full = elf_pef.y ; this array contains all angles and energies (in that order, same as val), to be used to compute energy spectra
  ;
  get_data,'el'+probe+'_pef_pa',data=elf_pef_pa
  store_data,'el'+probe+'_pef_val',data={x:elf_pef.x,y:elf_pef_val}
  store_data,'el'+probe+'_pef_val_full',data={x:elf_pef.x,y:elf_pef_val_full,v:elf_pef.v},dlim=mypefdata_dlim,lim=mypefdata_lim ; contains all angles and energies
  ylim,'el'+probe+'_pef_val*',1,1,1

  ; investigate logic -- feeds into selection of full PA ranges
  Tspin=average(elf_pef_spinper.y)
  ipasorted=sort(elf_pef_pa.y[0:nspinsectors-1]) ;PAs for each sector? sorted from low to high
  istartAscnd=max(elf_pef_sectnum.y[ipasorted[0:1]]) ;sector nums associated with lowest + next lowest PAs. take highest one
  if abs(ipasorted[0]-ipasorted[1]) ge 2 then istartAscnd=min(elf_pef_sectnum.y[ipasorted[0:1]])
  istartDscnd=max(elf_pef_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]]) ;sector nums associated with highest + second highest PAs. take highest one
  if abs(ipasorted[nspinsectors-2]-ipasorted[nspinsectors-1]) ge 2 then istartDscnd=min(elf_pef_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]])
  istartAscnds=where(abs(elf_pef_sectnum.y-elf_pef_sectnum.y[istartAscnd]) lt 0.1) ;get all starts of ascending PA ranges - anywhere that has same sector num (wt)
  istartDscnds=where(abs(elf_pef_sectnum.y-elf_pef_sectnum.y[istartDscnd]) lt 0.1) ;get all starts of descending PA ranges - anywhere that has same sector num (wt)
  tstartAscnds=elf_pef_sectnum.x[istartAscnds]
  tstartDscnds=elf_pef_sectnum.x[istartDscnds]

  ; BELOW FOR TESTING PURPOSES ONLY
  ;***istartAscnd=3 and istartDscnd=12 (for my test case)
  ;NOTE: in 2019-08-31/16:33:35 case, first [0,nspin_sectors-1] range of elf_pef_sectnum has sector=1 missing!
  ; check how many are missing sector numbers
  arr=findgen(n_elements(elf_pef_sectnum.y)/nspinsectors)*16
  elements_missing_secs=[-1]
  foreach element,arr do begin
    sectnums=elf_pef_sectnum.y[element:element+15]
    secs=findgen(16)
    foreach s,secs do begin
      if total(where(s eq sectnums)) eq -1 then elements_missing_secs=[elements_missing_secs,element]
      ; a sector number is missing! ...most zones have multiple segments with many "missing" sectors (wt)
      ; this is due to gaps in the epde data (sectnum is interpolated across, giving a step pattern)
    endforeach
  endforeach
  elements_missing_secs=elements_missing_secs(uniq(elements_missing_secs))
  if n_elements(elements_missing_secs) gt 1 then elements_missing_secs=elements_missing_secs[1:n_elements(elements_missing_secs)-1]
  ;stop ;check alongside elf_pef_sectnum & elf_pef_pa
  ; END SECTION FOR TESTING PURPOSES ONLY

  if tstartAscnds[0] lt tstartDscnds[0] then begin ; add a half period on the left as a precaution since there is a chance that hanging sectors exist (not been accounted for yet)
    tstartDscnds=[tstartDscnds[0]-Tspin,tstartDscnds]
  endif else begin
    tstartAscnds=[tstartAscnds[0]-Tspin,tstartAscnds]
  endelse
  nstartAscnds=n_elements(tstartAscnds)
  nstartDscnds=n_elements(tstartDscnds)
  nstartregAscnds=n_elements(tstartregAscnds)
  nstartregDscnds=n_elements(tstartregDscnds)

  if tstartDscnds[nstartDscnds-1] lt tstartAscnds[nstartAscnds-1] then begin ; add a half period on the right as a precautionsince chances are there are hanging ectors (not been accounted for yet)
    tstartDscnds=[tstartDscnds,tstartDscnds[nstartDscnds-1]+Tspin]
  endif else begin
    tstartAscnds=[tstartAscnds,tstartAscnds[nstartAscnds-1]+Tspin]
  endelse
  nstartAscnds=n_elements(tstartAscnds)
  nstartDscnds=n_elements(tstartDscnds)
  nstartregAscnds=n_elements(tstartregAscnds)
  nstartregDscnds=n_elements(tstartregDscnds)

  ; find the first starttime of a full PA range that contains any data (Ascnd or Descnd), add integer # of halfspins
  istart2reform=min(istartAscnd,istartDscnd)
  nhalfspinsavailable=long((nsectors-(istart2reform+1))/(nspinsectors/2.))
  ifinis2reform=(nspinsectors/2)*nhalfspinsavailable+istart2reform-1 ; exact # of half-spins (full PA ranges)
  elf_pef_pa_spec=make_array(nhalfspinsavailable,(nspinsectors/2),numchannels,/double)
  elf_pef_pa_spec_full=make_array(nhalfspinsavailable,(nspinsectors/2),Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
  for jthchan=0,numchannels-1 do elf_pef_pa_spec[*,*,jthchan]=transpose(reform(elf_pef_val[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
  for jthchan=0,Max_numchannels-1 do elf_pef_pa_spec_full[*,*,jthchan]=transpose(reform(elf_pef_val_full[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
  elf_pef_pa_spec_times=transpose(reform(elf_pef_pa.x[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))
  elf_pef_pa_spec_times=total(elf_pef_pa_spec_times,2)/(nspinsectors/2.) ; these are midpoints anyway, no need for the ones above
  elf_pef_pa_spec_pas=transpose(reform(elf_pef_pa.y[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))

  test=transpose(reform(elf_pef_pa.y[istart2reform+1:ifinis2reform+1],(nspinsectors/2),nhalfspinsavailable))
  ; fixes non-monotonic at beginning, but now problem exists at end (WT)
  ; likewise, some are fixed completely and some still have exact same problem (used to have 2 non-monotonics at start)
  ; integer # of half-spins does NOT correspond to full PA ranges?
  ;stop ;now check PAs with same elements found above

  elf_pef_pa_spec_signum=signum(elf_pef_pa_spec_pas[*,7]-elf_pef_pa_spec_pas[*,0]) ; ascending vs descending. ADDED FROM PREVIOUS CODE (wt)
  ;stop
  if (elf_pef_pa_spec_signum[0] gt 0) then $ ; between halfspin 0 and 1 you can build plus and minus sorted pa maps
    ipasortmapplus=sort(elf_pef_pa_spec_pas[0,*]) else ipasortmapminus=sort(elf_pef_pa_spec_pas[0,*])
  if (elf_pef_pa_spec_signum[1] gt 0) then $
    ipasortmapplus=sort(elf_pef_pa_spec_pas[1,*]) else ipasortmapminus=sort(elf_pef_pa_spec_pas[1,*])
  ; modify pas and spec accordingly to match increasing pa for both ascending and descending measurements
  elf_pef_pa_spec_indx=long(((elf_pef_pa_spec_signum+1.)/2.)#ipasortmapplus + ((1.-elf_pef_pa_spec_signum)/2.)#ipasortmapminus)
  ;
  ;stop
  ; NOTE: could below adding of extra angle bins cause changes in non-mono/monotonic regions?
  ;
  ; ADD EXTRA ANGLE BINS FOR ALL elf_pef_pa_spec, elf_pef_pa_spec_full and elf_pef_pa_reg_spec !!!
  ; WHEN BIN CENTERS ARE NOT REGULARIZED, THEN SPEDAS CUTS OFF HALF OF THE BIN WHICH MAKES THEM APPEAR HALF-WIDTH. ADD ONE ON EACH SIDE (ADD 2 PER PITCH ANGLE DISTRIBUTION)
  ; WHEN BIN CENTERS ARE REGULARIZED (SPIN PHASES: [0,180]) THEN THE ASCENDING DISTRIBUTION IS MISSING THE 180 BIN, AND THE DESCENDING THE 0 BIN, SO ADD THEM (ADD 1 PER PITCH ANGLE DISTRIBUTION)
  ;
  elf_pef_pa_spec2plot=make_array(nhalfspinsavailable,(nspinsectors/2)+2,numchannels,/double)
  for jthchan=0,numchannels-1 do elf_pef_pa_spec2plot[*,*,jthchan]=transpose([transpose(elf_pef_pa_spec[*,0,jthchan]*!VALUES.F_NaN),transpose(elf_pef_pa_spec[*,*,jthchan]),transpose(elf_pef_pa_spec[*,(nspinsectors/2)-1,jthchan]*!VALUES.F_NaN)])
  deltapafirst=(elf_pef_pa_spec_pas[*,1]-elf_pef_pa_spec_pas[*,0])
  deltapalast=(elf_pef_pa_spec_pas[*,(nspinsectors/2)-1]-elf_pef_pa_spec_pas[*,(nspinsectors/2)-2])

  ;BELOW LINE: elf_pef_pa_spec_pas2plot is problematic (each jthspec start/stop not set correctly?) (wt)
  ;traces back to elf_pef_pa_spec_pas
  elf_pef_pa_spec_pas2plot=transpose([transpose(elf_pef_pa_spec_pas[*,0]-deltapafirst),transpose(elf_pef_pa_spec_pas),transpose(elf_pef_pa_spec_pas[*,(nspinsectors/2)-1]+deltapalast)])
  ;elf_pef_pa_spec_pas2plot=transpose([transpose(elf_pef_pa_spec_pas[*,0]),transpose(elf_pef_pa_spec_pas),transpose(elf_pef_pa_spec_pas[*,(nspinsectors/2)-1])]) ;WT test

  nonmono_pas=0
  ; pick indices of non-monotonic segments -- TEST (wt)
  for i=0,n_elements(elf_pef_pa_spec_pas2plot[*,0])-1 do begin
    if float(i)/2 eq round(float(i)/2) then begin ;even, should be strictly increasing
      diffs=elf_pef_pa_spec_pas2plot[i,1:-1]-elf_pef_pa_spec_pas2plot[i,0:-2]
      diffs_neg=where(diffs lt 0, count_neg)
      if count_neg gt 0 then append_array, nonmono_pas, i ;non-monotonic!
    endif else begin ;odd, should be strictly decreasing
      diffs=elf_pef_pa_spec_pas2plot[i,1:-1]-elf_pef_pa_spec_pas2plot[i,0:-2]
      diffs_pos=where(diffs gt 0, count_pos)
      if count_pos gt 0 then append_array, nonmono_pas, i ;non-monotonic!
    endelse
  endfor

  print, minmax(nonmono_pas) ;starts about halfway through, goes through the end
  ; compare with elements in elf_pef_pa_spec_pas2plot[*,0]
  ; for each nonmono_pas, can check elf_pef_pa_spec_times at same ind
  mono_pa_times=0
  mono_pas_inds=0
  nonmono_pa_times=elf_pef_pa_spec_times[nonmono_pas]
  for i=0,n_elements(elf_pef_pa_spec_times)-1 do begin
    if total(where(nonmono_pas eq i)) eq -1 then begin
      append_array, mono_pa_times, elf_pef_pa_spec_times[i]
      append_array, mono_pas_inds, i
    endif
  endfor
  print, 'minmax whole range:', time_string(minmax(elf_pef_pa_spec_times))
  print, 'minmax times for non-monotonic PAs:', time_string(minmax(nonmono_pa_times))
  print, 'minmax times for monotonic PAs:', time_string(minmax(mono_pa_times))
  store_data,'pas_nonmonotonic',data={x:nonmono_pa_times,y:elf_pef_pa_spec_pas2plot[nonmono_pas,*]}
  store_data,'pas_monotonic',data={x:mono_pa_times,y:elf_pef_pa_spec_pas2plot[mono_pas_inds,*]}
  ; find when there's a large enough gap (skips over >1 time element) in non-monotonic and monotonic times
  pa_tres=elf_pef_pa_spec_times[1:-1]-elf_pef_pa_spec_times[0:-2] ;= 1/2 spin period
  if n_elements(nonmono_pa_times) gt 1 then time_diffs_nonmono=nonmono_pa_times[1:-1]-nonmono_pa_times[0:-2]
  if n_elements(mono_pa_times) gt 1 then time_diffs_mono=mono_pa_times[1:-1]-mono_pa_times[0:-2]
  if n_elements(nonmono_pa_times) gt 1 then gaps_nonmono=where(time_diffs_nonmono gt max(pa_tres))
  if n_elements(mono_pa_times) gt 1 then gaps_mono=where(time_diffs_mono gt max(pa_tres))
  ;apparently_nonmono_time=where(elf_pef_pa_spec_times ge time_double('2019-08-08/05:54:42') and elf_pef_pa_spec_times lt time_double('2019-08-08/05:54:46'))

  if n_elements(nonmono_pa_times) gt 0 then nonmono_data_flag=1 else nonmono_data_flag=0
  if nonmono_data_flag eq 0 then begin
    nonmono_percent=0
    avg_nonmono_time=946684800.00000000 ;translated from 0
  endif
  if nonmono_data_flag eq 1 then begin
    print, 'Collection has non-monotonic PAs'
    nonmono_percent=float(n_elements(nonmono_pa_times))/float(n_elements(nonmono_pa_times)+n_elements(mono_pa_times))
    avg_nonmono_time=average(nonmono_pa_times)
    print, 'Percent of times that have non-monotonic PAs = ', nonmono_percent*100
    print, 'Average time with non-monotonic PAs:', time_string(avg_nonmono_time)
  endif
  if keyword_set(check_nonmonotonic) then begin ;record in array
    if new_flag eq 0 then begin
      pa_data[2,matching_ind]=nonmono_percent*100
      pa_data[3,matching_ind]=avg_nonmono_time
    endif else if new_flag eq 1 then begin
      pa_data=[[pa_data[*,0:matching_ind-1]],[time_double(tstart),time_double(tend),nonmono_percent*100,avg_nonmono_time],[pa_data[*,matching_ind:-1]]]
    endif
    ; re-write file
    print, 'Stop here if editing file is not desired!'
    ;stop
    FILE_COPY, pa_file, pa_file+'.backup',/overwrite
    OPENW, 1, pa_file
    printf, 1, FORMAT = '(%"%s")', strjoin(strtrim(string(pa_cols),1),', ') ;re-write header
    for n=0,n_elements(pa_data[0,*])-1 do begin
      line=[time_string(pa_data[0,n]),time_string(pa_data[1,n]),strtrim(STRING(pa_data[2,n], FORMAT='(F5.2)'),1),time_string(pa_data[3,n])]
      line=strjoin(line, ', ')
      printf,1,FORMAT = '(%"%s")', line
    endfor
    close,1
    print, 'Finished editing PA file.'
    return
  endif
  ;stop ;check nonmono_pas array and the times
  ; NOTE: nonmonotonic_fraction only takes into account stuff in small selected time interval; the above checks everything between tstart and tend
  ;
  ; use below command to print PAs at a certain time
  ; elf_pef_pa_spec_pas2plot[where(abs(elf_pef_pa_spec_times-time_double('2019-08-30/12:24:20')) eq min(abs(elf_pef_pa_spec_times-time_double('2019-08-30/12:24:20')))),*]

  ; figure out which corresponds to elf_pef_pa.y[elements_missing_secs[12]:elements_missing_secs[12]+15] (non-monotonic segment)
  ; tlimit,'2019-08-08/05:45:35','2019-08-08/05:45:50'
  ; are there other non-monotonic areas WITHOUT problems with sectnum (gaps in data)?

  elf_pef_pa_spec2plot_full=make_array(nhalfspinsavailable,(nspinsectors/2)+2,Max_numchannels,/double)
  for jthchan=0,Max_numchannels-1 do elf_pef_pa_spec2plot_full[*,*,jthchan]=transpose([transpose(elf_pef_pa_spec_full[*,0,jthchan]*!VALUES.F_NaN),transpose(elf_pef_pa_spec_full[*,*,jthchan]),transpose(elf_pef_pa_spec_full[*,(nspinsectors/2)-1,jthchan]*!VALUES.F_NaN)])

  ; valid for starting (index 0) at an even (ascending) PA
  iters+=1
  i4pa2plot=where(tstartendtimes4pa2plot[0] lt elf_pef_pa_spec_times and tstartendtimes4pa2plot[1] gt elf_pef_pa_spec_times, j4pa2plot) ; unnecessary (just a list of all indices if doing full interval), but more general
  ispeceven=2*(i4pa2plot/2)
  ispecodd=2*((i4pa2plot-1)/2)+1
  ispeceven=ispeceven[UNIQ(ispeceven,sort(ispeceven))]
  ispecodd=ispecodd[UNIQ(ispecodd,sort(ispecodd))]

  ; set up arrays
  pef2plots_even=make_array(n_elements(ispeceven),10,/float)
  pa2plots_even=pef2plots_even
  pafitminus90_even=make_array(n_elements(ispeceven),/float)
  pef2plots_odd=make_array(n_elements(ispecodd),10,/float)
  pa2plots_odd=pef2plots_odd
  pafitminus90_odd=make_array(n_elements(ispecodd),/float)

  ; check if a spin period is missing in ascending or descending; correct times if so
  uneven_flag=0
  if n_elements(pafitminus90_odd) ne n_elements(pafitminus90_even) then uneven_flag=1 ;spin period missing in one
  if uneven_flag then begin ; OR do this regardless
    t_i=time_double(tstartendtimes4pa2plot[0])
    t_f=time_double(tstartendtimes4pa2plot[1])
    tstart_init=elf_pef_pa_spec_times(where(abs(elf_pef_pa_spec_times-t_i) eq min(abs(elf_pef_pa_spec_times-t_i))))
    tend_init=elf_pef_pa_spec_times(where(abs(elf_pef_pa_spec_times-t_f) eq min(abs(elf_pef_pa_spec_times-t_f))))
  endif

  ; do fits
  xfit=[20:160:0.01]
  chisq_even=[]
  yfit_even=make_array(n_elements(xfit),/float,value=0.)
  count_fits=0
  num_decreasing_pa=0
  for jthspec=0,n_elements(ispeceven)-1 do begin ;EVEN FITS
    pa2plots_even[jthspec,*]=reform(elf_pef_pa_spec_pas2plot[ispeceven[jthspec],*],10)
    pef2plots_even[jthspec,*]=reform(elf_pef_pa_spec2plot[ispeceven[jthspec],*])
    x2fit_full=reform(pa2plots_even[jthspec,*])
    y2fit_full=reform(pef2plots_even[jthspec,*])
    broad = where(y2fit_full gt 0, count_secs)
    pa_diffs=ts_diff(x2fit_full,1)
    monotonic = where(pa_diffs gt 0, decreasing_pa)
    ; SKIP if it doesn't have at least 5 sectors
    if decreasing_pa gt 0 and count_secs ge 5 then num_decreasing_pa+=1 ;non-monotonic PAs in a spin period of use
    if count_secs lt 5 then begin
      pef2plots_even[jthspec,*]=!Values.F_NAN
      pafitminus90_even[jthspec]=!Values.F_NAN
      chisq_even=[chisq_even,!Values.F_NAN]
      continue
    endif
    y2fit_full(where(FINITE(y2fit_full) eq 0))=0 ; re-assign NaN values to 0
    fit_errors=make_array(4) ; order 2,3,4 polyfits + quadratic interpolation
    for n=2,4 do begin ; n=order of fit
      ; find n+1 highest flux/count points
      sorted_y2fit_inds=reverse(sort(y2fit_full))
      y2fit=y2fit_full(sorted_y2fit_inds[0:n]) ; fit exactly n+1 points (highest flux)
      x2fit=x2fit_full(sorted_y2fit_inds[0:n])
      coeffs=poly_fit(x2fit,alog10(y2fit),n,measure_errors=measure_errors,sigma=sigma)
      model_poly=10^poly(x2fit_full,coeffs)
      fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
      model_poly=model_poly(where(abs(x2fit_full-90) le 45)) ;only analyze points between 45-135deg
      fit_diff=fit_diff(where(abs(x2fit_full-90) le 45))
      check_nans=where(finite(fit_diff), num_finite)
      fit_goodness=total(fit_diff,/NaN)/num_finite
      fit_errors[n-2]=fit_goodness

      if n eq 2 then begin ; also do quad interp method
        result = interpol(alog10(y2fit),x2fit,xfit,/quadratic)
        if FINITE(average(result)) then begin
          eqns=[[1, x2fit[0], x2fit[0]^2], $
            [1, x2fit[1], x2fit[1]^2], $
            [1, x2fit[2], x2fit[2]^2]]
          coeffs_interp=LA_LINEAR_EQUATION(eqns,alog10(y2fit))
          model_poly=10^poly(x2fit_full,coeffs)
          fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
          model_poly=model_poly(where(abs(x2fit_full-90) le 45)) ;only analyze points between 45-135deg
          fit_diff=fit_diff(where(abs(x2fit_full-90) le 45))
          check_nans=where(finite(fit_diff), num_finite)
          fit_goodness=total(fit_diff,/NaN)/num_finite
          fit_errors[-1]=fit_goodness
        endif else fit_errors[-1]=!Values.F_NAN
      endif
    endfor
    ; determine ideal fit order
    fit_order=where(fit_errors eq min(fit_errors))+2
    if n_elements(fit_order) gt 1 then fit_order=fit_order[1]
    fit_order=long(fit_order[0])
    quad_interp_flag=0
    if fit_order eq n_elements(fit_errors)+1 then begin ; place-holder for quadratic interpolation method
      quad_interp_flag=1
      fit_order=2
    endif

    ;if fit_order eq 4 then fit_order=2 ;1/31: PREVENT FROM DOING 4TH ORDER FITS
    y2fit=y2fit_full(sorted_y2fit_inds[0:fit_order]) ; do the fit
    x2fit=x2fit_full(sorted_y2fit_inds[0:fit_order])
    if quad_interp_flag then begin
      eqns=[[1, x2fit[0], x2fit[0]^2], $
        [1, x2fit[1], x2fit[1]^2], $
        [1, x2fit[2], x2fit[2]^2]]
      coeffs=LA_LINEAR_EQUATION(eqns,alog10(y2fit))
    endif else coeffs=poly_fit(x2fit,alog10(y2fit),fit_order)
    result=10^poly(xfit,coeffs)
    ;stop ; investigate fit (diverged or not?)
    if FINITE(average(result)) then begin ; if result doesn't diverge
      close2center=where(xfit gt 60 and xfit lt 130)
      result_close2center=result(close2center)
      x_close2center=xfit(close2center)
      dy=DERIV(xfit(close2center),result(close2center))
      ypeak=result_close2center(where(abs(dy) eq min(abs(dy))))
      if total(where(dy eq 0)) eq -1 then print,'dy=0 not found! using min dy'
      if n_elements(ypeak) gt 1 then ypeak=max(ypeak)
      ypeak=ypeak[0]
      ; below 'fix' probably forces fits to be unrepresentative of real pef
      if max(result)/ypeak gt 1.5 then ypeak=max(result_close2center) ; quick fix in case poly fit results in higher not representative peak (local max)
      xpeak=x_close2center(where(abs(dy) eq min(abs(dy)))) ; could be larger than 1 element
      if n_elements(xpeak) eq 1 then xpeak=xpeak[0] else begin
        dist_to_90=abs(xpeak-90.)
        closest_to_90=xpeak(where(dist_to_90 eq min(dist_to_90)))
        xpeak=closest_to_90[0]
      endelse
      foreach val,abs(xpeak-90.) do begin ;sanity check
        if val gt 23 then print,'at least one of max pts is far from 90deg!'
      endforeach

      ;if fit_order eq 2 then ypeak=10^poly(-coeffs[1]/coeffs[2]/2.,coeffs) ;only valid for quadratic (order 2)
      ;if fit_order ne 2 then ypeak=max(result(where(xfit gt 70 and xfit lt 120))) ;ignores error-prone edges

      model_poly=10^poly(x2fit_full,coeffs)
      fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
      model_poly=model_poly(where(abs(x2fit_full-90) le 45)) ; exclude regions around edges
      fit_diff=fit_diff(where(abs(x2fit_full-90) le 45))
      check_nans=where(finite(fit_diff), num_finite)
      fit_goodness=total(fit_diff,/NaN)/num_finite
      chisq_even=[chisq_even,fit_goodness]
      ;print, 'chi squared:', fit_goodness
      ;print,'even, jthspec:', jthspec
      ;print, 'count_secs:', count_secs
      ;plotxy,[[reform(pa2plots_even[jthspec,1:-2])],[reform(pef2plots_even[jthspec,1:-2]/max(pef2plots_even[jthspec,*]))]],xrange=[-15.,185.],yrange=[0.,1.], $
      ;  xsize=800.,ysize=500.,colors=['o'],title=' ',linestyle=2,thick=5,/noisotropic

      pef2plots_even[jthspec,*]=pef2plots_even[jthspec,*]/ypeak
      pafitminus90_even[jthspec]=xpeak-90.
      ;if fit_order eq 2 then pafitminus90_even[jthspec]=-coeffs[1]/coeffs[2]/2.-90. $  ;CHANGE
      ;  else pafitminus90_even[jthspec]=xfit(where(result eq ypeak))-90.
      yfit_even=yfit_even+result
      yfit_even/=ypeak
      count_fits+=1

    endif else if FINITE(average(result)) eq 0 then begin
      print, 'Not using result (not finite)'
      ;print,'x2fit, y2fit:', x2fit, y2fit
      ;stop
      pef2plots_even[jthspec,*]=!Values.F_NAN
      pafitminus90_even[jthspec]=!Values.F_NAN
      chisq_even=[chisq_even,!Values.F_NAN]
    endif
  endfor
  chisq_even_avg=average(chisq_even)
  print,'TOTAL LINES REMOVED FROM EVEN FITS:', n_elements(ispeceven)-count_fits
  print,'even count fits:', count_fits
  print,'average chi squared of all used even fits:', chisq_even_avg
  if count_fits eq 0 then print, 'None were fitted! Try a larger or higher quality time interval.'
  nonmonotonic_frac_even=float(num_decreasing_pa)/float(n_elements(ispeceven))

  xfit=[20:160:0.01]
  yfit_odd=make_array(n_elements(xfit),/float,value=0.)
  count_fits=0
  num_increasing_pa=0
  chisq_odd=[]
  for jthspec=0,n_elements(ispecodd)-1 do begin ;ODD FITS
    pa2plots_odd[jthspec,*]=reform(elf_pef_pa_spec_pas2plot[ispecodd[jthspec],*],10)
    pef2plots_odd[jthspec,*]=reform(elf_pef_pa_spec2plot[ispecodd[jthspec],*])
    x2fit_full=reform(pa2plots_odd[jthspec,*])
    y2fit_full=reform(pef2plots_odd[jthspec,*])
    broad = where(y2fit_full gt 0, count_secs)
    pa_diffs=ts_diff(x2fit_full,1)
    monotonic = where(pa_diffs lt 0, increasing_pa)
    ;stop
    if increasing_pa gt 0 and count_secs ge 5 then num_increasing_pa+=1 ;non-monotonic PAs in a spin period of use
    ;if count_secs ge 5 then begin
    ;  plotxy,[[reform(pa2plots_odd[jthspec,1:-2])],[reform(pef2plots_odd[jthspec,1:-2]/max(pef2plots_odd[jthspec,*]))]],xrange=[-15.,185.],yrange=[0.,1.], $
    ;    xsize=800.,ysize=500.,colors=['o'],title=' ',linestyle=2,thick=5,/noisotropic ;actual data
    ;  stop ; find the non-monotonic spin period
    ;endif

    ; SKIP if it doesn't have at least 5 sectors
    if count_secs lt 5 then begin
      pef2plots_odd[jthspec,*]=!Values.F_NAN
      pafitminus90_odd[jthspec]=!Values.F_NAN
      chisq_odd=[chisq_odd,!Values.F_NAN]
      continue
    endif
    y2fit_full(where(FINITE(y2fit_full) eq 0))=0 ; re-assign NaN values to 0
    fit_errors=make_array(4)
    for n=2,4 do begin ; n=order of fit
      ; find n+1 highest flux/count points
      sorted_y2fit_inds=reverse(sort(y2fit_full))
      y2fit=y2fit_full(sorted_y2fit_inds[0:n]) ; fit exactly n points (highest flux)
      x2fit=x2fit_full(sorted_y2fit_inds[0:n])
      coeffs=poly_fit(x2fit,alog10(y2fit),n,measure_errors=measure_errors,sigma=sigma)

      model_poly=10^poly(x2fit_full,coeffs)
      fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
      model_poly=model_poly(where(abs(x2fit_full-90) le 45))
      fit_diff=fit_diff(where(abs(x2fit_full-90) le 45))
      check_nans=where(finite(fit_diff), num_finite)
      fit_goodness=total(fit_diff,/NaN)/num_finite
      fit_errors[n-2]=fit_goodness

      if n eq 2 then begin ; also do quad interp method
        result = interpol(alog10(y2fit),x2fit,xfit,/quadratic)
        if FINITE(average(result)) then begin
          eqns=[[1, x2fit[0], x2fit[0]^2], $
            [1, x2fit[1], x2fit[1]^2], $
            [1, x2fit[2], x2fit[2]^2]]
          coeffs_interp=LA_LINEAR_EQUATION(eqns,alog10(y2fit))
          model_poly=10^poly(x2fit_full,coeffs)
          fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
          model_poly=model_poly(where(abs(x2fit_full-90) le 45)) ;only analyze points between 60-120deg
          fit_diff=fit_diff(where(abs(x2fit_full-90) le 45))
          check_nans=where(finite(fit_diff), num_finite)
          fit_goodness=total(fit_diff,/NaN)/num_finite
          fit_errors[-1]=fit_goodness
        endif else fit_errors[-1]=!Values.F_NAN
      endif
    endfor
    ; determine ideal fit order
    fit_order=where(fit_errors eq min(fit_errors))+2
    if n_elements(fit_order) gt 1 then fit_order=fit_order[1]
    fit_order=long(fit_order[0])
    quad_interp_flag=0
    if fit_order eq n_elements(fit_errors)+1 then begin ; place-holder for quadratic interpolation method
      quad_interp_flag=1
      fit_order=2
    endif

    ;if fit_order eq 4 then fit_order=2 ;1/31: PREVENT FROM DOING 4TH ORDER FITS
    y2fit=y2fit_full(sorted_y2fit_inds[0:fit_order]) ; do the fit
    x2fit=x2fit_full(sorted_y2fit_inds[0:fit_order])
    if quad_interp_flag then begin
      print,'using quad interp method'
      eqns=[[1, x2fit[0], x2fit[0]^2], $
        [1, x2fit[1], x2fit[1]^2], $
        [1, x2fit[2], x2fit[2]^2]]
      coeffs=LA_LINEAR_EQUATION(eqns,alog10(y2fit))
    endif else coeffs=poly_fit(x2fit,alog10(y2fit),fit_order)
    result=10^poly(xfit,coeffs)
    ;print, 'order of fit, count_secs, and error:', fit_order, count_secs, min(fit_errors)
    ;print,'result on original scale:', 10^poly(x2fit,coeffs)
    ;print,'y2fit:',y2fit

    if FINITE(average(result)) then begin
      close2center=where(xfit gt 60 and xfit lt 130)
      result_close2center=result(close2center)
      x_close2center=xfit(close2center)
      dy=DERIV(xfit(close2center),result(close2center))
      ypeak=result_close2center(where(abs(dy) eq min(abs(dy))))
      if total(where(dy eq 0)) eq -1 then print,'dy=0 not found! using min dy'
      if n_elements(ypeak) gt 1 then ypeak=max(ypeak)
      ypeak=ypeak[0]

      if max(result)/ypeak gt 1.5 then ypeak=max(result_close2center) ; quick fix in case poly fit results in higher not representative peak

      xpeak=x_close2center(where(abs(dy) eq min(abs(dy)))) ; could be larger than 1 element
      if n_elements(xpeak) eq 1 then xpeak=xpeak[0] else begin
        dist_to_90=abs(xpeak-90.)
        closest_to_90=xpeak(where(dist_to_90 eq min(dist_to_90)))
        xpeak=closest_to_90[0]
      endelse
      foreach val,abs(xpeak-90.) do begin ;sanity check
        if val gt 23 then print,'at least one of max pts is far from 90deg!'
      endforeach

      ;if fit_order eq 2 then ypeak=10^poly(-coeffs[1]/coeffs[2]/2.,coeffs) ;only valid for quadratic (order 2)
      ;if fit_order ne 2 then ypeak=max(result(where(xfit gt 70 and xfit lt 120))) ;ignores error-prone edges

      model_poly=10^poly(x2fit_full,coeffs)
      fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
      model_poly=model_poly(where(abs(x2fit_full-90) le 45))
      fit_diff=fit_diff(where(abs(x2fit_full-90) le 45)) ;exclude regions around edges
      check_nans=where(finite(fit_diff), num_finite)
      fit_goodness=total(fit_diff,/NaN)/num_finite
      chisq_odd=[chisq_odd,fit_goodness]
      ;plotxy,[[x2fit_full],[y2fit_full]],/noisotropic
      ;oplot,x2fit_full,10^poly(x2fit_full,coeffs),color=2 ;model (blue)

      pef2plots_odd[jthspec,*]=pef2plots_odd[jthspec,*]/ypeak
      pafitminus90_odd[jthspec]=xpeak-90.
      ;if fit_order eq 2 then pafitminus90_odd[jthspec]=-coeffs[1]/coeffs[2]/2.-90. $
      ;  else pafitminus90_odd[jthspec]=xfit(where(result eq ypeak))-90.
      yfit_odd=yfit_odd+result
      yfit_odd/=ypeak
      count_fits+=1

    endif else if FINITE(average(result)) eq 0 then begin
      print, 'Not using result (not finite)'
      ;stop
      pef2plots_odd[jthspec,*]=!Values.F_NAN
      pafitminus90_odd[jthspec]=!Values.F_NAN
      chisq_odd=[chisq_odd,!Values.F_NAN]
    endif
  endfor
  chisq_odd_avg=average(chisq_odd)
  print,'TOTAL LINES REMOVED FROM ODD FITS:', n_elements(ispecodd)-count_fits
  print,'odd count fits:', count_fits
  print,'average chi squared of all used odd fits:', chisq_odd_avg
  if count_fits eq 0 then print, 'None were fitted! Try a larger or higher quality time interval.'
  nonmonotonic_frac_odd=float(num_increasing_pa)/float(n_elements(ispecodd))

  ; Check for matching spin periods that have results for even or odd but not the other (shouldn't happen)
  if n_elements(pafitminus90_odd) ge n_elements(pafitminus90_even) then $ ; edit later because they'll be the same length
    pafitminus90_shorter=pafitminus90_even else if n_elements(pafitminus90_even) gt $
    n_elements(pafitminus90_odd) then pafitminus90_shorter=pafitminus90_odd
  for n=0,n_elements(pafitminus90_shorter)-1 do begin ;assuming length of pafitminus90_odd = length of pafitminus90_even
    even_odd_pair=[pafitminus90_odd[n],pafitminus90_even[n]]
    check_nan=where(FINITE(even_odd_pair) eq 0, num_nan)
    if num_nan eq 1 then begin ;disregard spin period in analysis
      pafitminus90_odd[n]=!Values.F_NAN
      pafitminus90_even[n]=!Values.F_NAN
      pef2plots_odd[n,*]=!Values.F_NAN
      pef2plots_even[n,*]=!Values.F_NAN
      chisq_odd[n]=!Values.F_NAN
      chisq_even[n]=!Values.F_NAN
      print,'inconsistency in spin period detected; spinper disregarded'
    endif
  endfor

;nflux = Normalized Flux, updated 2021-09-08
  window,1
  miny=3.e-3
  maxy=6.; 1.
  deltaPA_est=(average(pafitminus90_even(where(FINITE(pafitminus90_even))))-average(pafitminus90_odd(where(FINITE(pafitminus90_odd)))))/2.
  plotxy,[[reform(pa2plots_even[0,*])],[reform(pef2plots_even[0,*])]], $
    xrange=[-5.,185.],yrange=[miny,maxy],/ylog,/noisotropic, $
    xsize=800.,ysize=500.,psym=-2,colors=['r'], $
    title=time_string(tstartendtimes4pa2plot[0])+' - '+strmid(time_string(tstartendtimes4pa2plot[1]),11,8)+ $
    ' UT'+', dSectr2add = '+strtrim(string(dSectr2add,format="(I7)"),1)+', dPhAng2add = '+strtrim(string(dPhAng2add,format="(f5.1)"),1)+'deg, dPA290_est='+string(deltaPA_est,format="(f5.1)")+'deg',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  plotxy,[[reform(pa2plots_odd[0,*])],[reform(pef2plots_odd[0,*])]],/over,psym=-1,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispeceven)-1 do plotxy,[[reform(pa2plots_even[jthspec,*])],[reform(pef2plots_even[jthspec,*])]],/over,psym=-1,colors=['r'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispeceven)-1 do plotxy,[[pafitminus90_even[jthspec]+90.,pafitminus90_even[jthspec]+90.],[0.2*maxy,maxy]],/over,colors=['r'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispecodd)-1 do plotxy,[[reform(pa2plots_odd[jthspec,*])],[reform(pef2plots_odd[jthspec,*])]],/over,psym=-1,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispecodd)-1 do plotxy,[[pafitminus90_odd[jthspec]+90.,pafitminus90_odd[jthspec]+90.],[0.2*maxy,maxy]],/over,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  plotxy,[[xfit],[yfit_odd]],/over,colors=['o'],title=' ',linestyle=2,thick=5,yrange=[miny,maxy],xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  plotxy,[[xfit],[yfit_even]],/over,colors=['g'],title=' ',linestyle=2,thick=5,yrange=[miny,maxy],xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  
  ;
  avg_nonmonotonic_frac=(nonmonotonic_frac_odd+nonmonotonic_frac_even)/2.
  print,'Times=',time_string(tstartendtimes4pa2plot[0])+' - '+strmid(time_string(tstartendtimes4pa2plot[1]),11,8)+'UT,', $
    '    dPhAng2add=',dPhAng2add,'deg,   Tspin=',Tspin,'sec'
  print, 'Average fraction of spin periods w/ non-monotonic PAs:', avg_nonmonotonic_frac
  ;if avg_nonmonotonic_frac gt 0 then stop
  ;stop

  ; After checking if additional sector should be added, add the above estimate to dSectr2add and dPhAng2add,
  ; then re-run until deltaPA_est=0 or fit process reaches 10 iterations.
  ; NOTE: below code wouldn't work properly when multiple sectors should be added, or going from negative to positive phase (>= 11 deg diff)
  deltaPA_est = round(deltaPA_est*4)/4.
  
  maxiter = 4
  if deltaPA_est eq 0 or iters gt maxiter then begin
    if iters gt 7 then print, 'Max iterations reached; using latest result'
    print,'Final dSectr2add, dPhAng2add after ', iters-1, ' iterations:', dSectr2add, ' sectors, ', dPhAng2add, ' deg'
    ;stop
  endif else if abs(dPhAng2add-deltaPA_est) gt 11 then begin ; calculate estimate in terms of additional sectors if needed (rest of code doesn't work with angles above 11)
    ;stop
    if dPhAng2add-deltaPA_est lt 0 then begin
      dSectr2add-=1
      phase_shift=abs(deltaPA_est)-22.5
    endif else begin
      dSectr2add+=1
      phase_shift=22.5-abs(deltaPA_est)
    endelse
    dPhAng2add-=phase_shift
    ;if abs(dPhAng2add+deltaPA_est) lt 11 then begin
    ;  dPhAng2add=dPhAng2add+deltaPA_est
    ;  stop
    ;if abs(dPhAng2add-deltaPA_est) le 22 then begin
    ;  dSectr2add+=1
    ;  phase_shift = 22.5-abs(deltaPA_est)
    ;  dPhAng2add -= phase_shift
    ;endif else if abs(dPhAng2add-deltaPA_est) gt 22 then begin
    ;  dSectr2add+=2
    ;  phase_shift = 22.5*2-abs(deltaPA_est)
    ;  dPhAng2add -= phase_shift
    ;endif
    print, 'New dSectr2add, dPhAng2add from iteration ', iters, ':', dSectr2add, ' sectors, ', dPhAng2add, ' deg'
    ;stop
    if abs(dPhAng2add) gt 11 then begin
       ; edge case
       skipfit=' '
       print, 'edge case detected. skip fit? [y]'
       read, skipfit
       if skipfit eq 'y' then begin 
        badflag = 2
        bad_comment = 'algorithm failed'
        autobad = 1
        ;iters = maxiter+1
        goto, endoffits
       endif
       
       ;return
       print, 'edge'
    endif
    goto, FINDSHIFT
  endif else begin
    ;stop
    dPhAng2add += -1.*deltaPA_est
    print, 'New dSectr2add, dPhAng2add from iteration ', iters, ':', dSectr2add, ' sectors, ', dPhAng2add, ' deg'
    ;stop
    goto, FINDSHIFT
  endelse

  ; Now get loss cone and check if PAD captures it (if so, flag as high quality)
  tinterpol_mxn,'el'+probe+'_pos_gsm',elf_pef_pa_spec_times
  tt89,'el'+probe+'_pos_gsm_interp',/igrf_only,newname='el'+probe+'_bt89_gsm_interp',period=1.
  calc,' "radial_pos_gsm_vector"="el'+probe+'_pos_gsm_interp"/ (sqrt(total("el'+probe+'_pos_gsm_interp"^2,2))#threeones) '
  calc,' "radial_B_gsm_vector"=total("el'+probe+'_bt89_gsm_interp"*"radial_pos_gsm_vector",2) '
  get_data,"radial_B_gsm_vector",data=radial_B_gsm_vector
  i2south=where(radial_B_gsm_vector.y gt 0,j2south)
  idir=radial_B_gsm_vector.y*0.+1 ; when Br<0 the direction is 2north and loss cone is 0-90 deg. If Br>0 then idir=-1. and loss cone is 90-180.
  ttrace2iono,'el'+probe+'_pos_gsm_interp',newname='el'+probe+'_ifoot_gsm',/km ; to north by default can be changed if needed
  get_data,'el'+probe+'_pos_gsm_interp',data=elf_pos_gsm_interp
  if j2south gt 0 then begin
    idir[i2south]=-1.
    store_data,'el'+probe+'_pos_gsm_interp_2ionosouth',data={x:elf_pos_gsm_interp.x[i2south],y:elf_pos_gsm_interp.y[i2south,*]}
    ttrace2iono,'el'+probe+'_pos_gsm_interp_2ionosouth',newname='el'+probe+'_ifoot_gsm_2ionosouth',/km,/SOUTH
    get_data,'el'+probe+'_ifoot_gsm_2ionosouth',data=elf_ifoot_gsm_2ionosouth,dlim=myifoot_dlim,lim=myifoot_lim
    get_data,'el'+probe+'_ifoot_gsm',data=elf_ifoot_gsm,dlim=myifoot_dlim,lim=myifoot_lim
    elf_ifoot_gsm.y[i2south,*]=elf_ifoot_gsm_2ionosouth.y[i2south,*]
    store_data,'el'+probe+'_ifoot_gsm',data={x:elf_ifoot_gsm.x,y:elf_ifoot_gsm.y},dlim=myifoot_dlim,lim=myifoot_lim
  endif
  tt89,'el'+probe+'_ifoot_gsm',/igrf_only,newname='el'+probe+'_ifoot_bt89_gsm_interp',period=1.
  tvectot,'el'+probe+'_bt89_gsm_interp',tot='el'+probe+'_igrf_Btot'
  calc,' "onearray" = "el'+probe+'_igrf_Btot"/"el'+probe+'_igrf_Btot" ' ; contains the value of 1.
  tvectot,'el'+probe+'_ifoot_bt89_gsm_interp',tot='el'+probe+'_ifoot_igrf_Btot'
  calc,' "lossconedeg" = 180.*arcsin(sqrt("el'+probe+'_igrf_Btot"/"el'+probe+'_ifoot_igrf_Btot"))/pival '
  calc,' "lossconedeg" = "lossconedeg"*(idir+1)/2.+(180.*"onearray"-"lossconedeg")*((1.-idir)/2.) '
  calc,' "antilossconedeg" = 180.*"onearray"-"lossconedeg" '

  get_data, 'lossconedeg', data=loss_cone
  get_data, 'antilossconedeg', data=anti_loss_cone
  hq_flag=0
  loss_antiloss_arr=[min(loss_cone.y),max(anti_loss_cone.y)]
  trapped=loss_antiloss_arr(sort(loss_antiloss_arr))
  if max(min_pas) lt trapped[0] or min(max_pas) gt trapped[1] then hq_flag=1
 
  print, 'PAD high quality flag:', hq_flag
  print, avg_nonmonotonic_frac
  ;if avg_nonmonotonic_frac gt 0 then stop
  
  check2 = total(n_elements(dat.tstart))
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FITS                                  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  autobad = 0
  badFlag = 0
  endoffits: print, 'fits ended'
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;START OF MEDIAN CALCULATION                  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  ;;;MEDIANS WITH NANs, WILL BECOME OBSOLETE IN TIME {{{:
  starttimes = time_double(dat.tstart)
  angles = dat.dSectr2add*22.5+dat.dPhAng2add
  meds = dat.LatestMedianSectr*22.5+dat.LatestMedianPhAng
  badmeds= where(~finite(dat.LatestMedianPhAng))
  
  if badmeds[0] ne -1 then begin 
    foreach nan, badmeds do begin
      
      int_end = starttimes[nan]
      int_start = int_end-3600.*24.*7.
      valid_items = where(starttimes ge int_start and starttimes le int_end and dat.badflag eq 0)
      current_median = median(angles[valid_items])
      
      if abs(current_median) gt 56.5 then begin
        dat.LatestMedianSectr[nan]=round(3*sign(current_median))
        dat.LatestMedianPhAng[nan]=current_median-3*22.5*sign(current_median)
      endif else if abs(current_median) gt 34 then begin
        dat.LatestMedianSectr[nan]=round(2*sign(current_median))
        dat.LatestMedianPhAng[nan]=current_median-2*22.5*sign(current_median)
      endif else if abs(current_median) gt 11 and abs(abs(current_median)-22.5) le 11 then begin
        dat.LatestMedianSectr[nan]=round(1*sign(current_median))
        dat.LatestMedianPhAng[nan]=current_median-22.5*sign(current_median)
      endif else if abs(current_median) le 11 then begin
        dat.LatestMedianSectr[nan] = 0
        dat.LatestMedianPhAng[nan] = current_median
      endif
      
      ;if abs(current_median) gt 11 and abs(abs(current_median)-22.5) le 11 then begin
      ;  dat.LatestMedianSectr[nan]=round(1*sign(current_median))
      ;  dat.LatestMedianPhAng[nan]=current_median-22.5*sign(current_median)
      ;endif else if abs(current_median) gt 34 then begin
      ;  dat.LatestMedianSectr[nan]=round(2*sign(current_median))
      ;  dat.LatestMedianPhAng[nan]=current_median-2*22.5*sign(current_median)
      ;endif else if abs(current_median) gt 56.5 then begin
      ;  dat.LatestMedianSectr[nan]=round(3*sign(current_median))
      ;  dat.LatestMedianPhAng[nan]=current_median-3*22.5*sign(current_median)
      ;endif else if abs(current_median) le 11 then begin
      ;  dat.LatestMedianSectr[nan] = 0
      ;  dat.LatestMedianPhAng[nan] = current_median
      ;endif
    endforeach
    
    if ~finite(dat.LatestMedianSectr[nan]) or ~finite(dat.LatestMedianPhAng[nan]) then begin
      print, 'Median failed'
      stop
    endif
  endif
  check3 = total(n_elements(dat.tstart))
  
  ;;;CURRENT MEDIAN
  int_end = time_double(tstart)
  median_range = 7. ;it will go back 7 days to find a new median 
  int_start = int_end-3600.*24.*median_range
  valid_items = where(starttimes ge int_start and starttimes le int_end and dat.badflag eq 0)
  if valid_items[0] eq -1 then begin
    print, 'The phase delay procedure has stopped because there is no entry within the median range. Please extend the range to continue. 
  endif
  current_median = median(angles[valid_items])
  placeholder_phase = current_median
  
    if abs(current_median) gt 56.5 then begin
      LatestMedianSectr=round(3*sign(current_median))
      LatestMedianPhAng=current_median-3*22.5*sign(current_median)
    endif else if abs(current_median) gt 34 then begin
      LatestMedianSectr=round(2*sign(current_median))
      LatestMedianPhAng=current_median-2*22.5*sign(current_median)
    endif else if abs(current_median) gt 11 then begin
    ;and abs(abs(current_median)-22.5) le 11 then begin
      LatestMedianSectr=round(1*sign(current_median))
      LatestMedianPhAng=current_median-22.5*sign(current_median)
    endif else if abs(current_median) le 11 then begin
      LatestMedianSectr = 0
      LatestMedianPhAng = current_median
    ;if abs(current_median) ge 11 or abs(abs(current_median)-22.5) le 11 then begin
    ;  LatestMedianSectr=round(1*sign(current_median))
    ;  LatestMedianPhAng=current_median-22.5*sign(current_median)
    ;endif else if abs(current_median) gt 34 then begin
    ;  LatestMedianSectr=round(2*sign(current_median))
    ;  LatestMedianPhAng=current_median-2*22.5*sign(current_median)
    ;endif else if abs(current_median) gt 56.5 then begin
    ;  LatestMedianSectr=round(3*sign(current_median))
    ;  LatestMedianPhAng=current_median-3*22.5*sign(current_median)
    ;endif else if abs(current_median) le 11 then begin
    ;  LatestMedianSectr = 0
    ;  LatestMedianPhAng = current_median
    endif else begin
      print, 'no recognized median'
    endelse
    
    print, current_median
    ;print, latestmedianPhAng
    print, latestmedianSectr
    
    ;stop
    
  if ~finite(LatestMedianSectr) or ~finite(LatestMedianPhAng) then begin
    print, 'Median failed'
    stop
  endif
  
  check4 = total(n_elements(dat.tstart))
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF MEDIAN CALCULATION                    ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;START OF FIT ANALYSIS                        ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; Print average chi squared of final iteration's fits (and append to calibration file)
  ;chisq_avg=average([chisq_even(where(finite(chisq_even))),chisq_odd(where(finite(chisq_odd)))])
  

  
  if abs(dSectr2add) gt 10 then begin
    print, 'fit failed, using placeholder'
    badFlag = 1
    phase_result=placeholder_phase
    if abs(phase_result) gt 11 and abs(phase_result-22.5) le 11 then begin
      dSectr2add=1
      dPhAng2add=phase_result-22.5
    endif else if abs(phase_result) gt 34 then begin
      dSectr2add=2
      dPhAng2add=phase_result-2*22.5
    endif else if abs(phase_result) gt 56.5 then begin
      dSectr2add=3
      dPhAng2add=phase_result-3*22.5
    endif
    badcomment = 'Fit failed, exceeded reasonable limit'
    badFlag = 1
    autobad = 1
  endif
  
  ;print,'Average chi squared of fits from last iteration:', chisq_avg
  
  ; Re-write to file
  if autobad then phase_result = placeholder_phase else phase_result=dSectr2add*22.5+dPhAng2add
  
  if autobad eq 0 then begin 
    print,'Do you want to flag this result as bad (y)?'
    incommand=' '
    read,incommand
    ;incommand = 'n'
    bad_comment = ' '
    if incommand eq 'y' then begin 
       badFlag=1
       read, bad_comment
       phase_result = placeholder_phase
    endif
  endif

  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FIT ANALYSIS                          ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;START OF FILE FORMATTING                     ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;find index where starttime should be 
  valid_items = where(starttimes le time_double(tstart)+5.*60.)
  newindex = valid_items[-1]
  
  newentry = [string(time_string(tstart)), string(time_string(tend)), string(dSectr2add), string(dPhang2add), string(LatestMedianSectr), string(LatestMedianPhAng), string(badFlag)]
  
  ;figure out if this science zone is new. if not, it has to be appended in a different way.
  n = where(time_double(tstart) lt starttimes-60.*5, old)
  
  ;create new entry array
  ;newdat = CREATE_STRUCT(cols[0], tstarts, cols[1], tends, cols[2], dSectr2adds, cols[3], dPhAng2adds, cols[4], LatestMedianSectrs, cols[5], LatestMedianPhAngs, cols[6], badFlags)

  ;figure out if this science zone has already been fit
  if time_double(tstart) ge starttimes[newindex]-60.*5. and time_double(tstart) le starttimes[newindex]+60.*5. then begin
    ;stop
    replace = 1
    tbr = where(time_double(tstart) ge starttimes-60.*5. and time_double(tstart) le starttimes+60.*5.)
    for i = 0, n_elements(cols)-1 do begin 
      dat.(i)[tbr] = newentry[i]
    endfor
    newdat = CREATE_STRUCT(cols[0], dat.(0), cols[1], dat.(1), cols[2], dat.(2), cols[3], dat.(3), cols[4], dat.(4), cols[5], dat.(5), cols[6], dat.(6))
    print, 'classified as repeat'
    
  endif else begin
      tstarts =  [dat.tstart, time_string(newentry[0])]
      tends =  [dat.tend, time_string(newentry[1])]
      dSectr2adds = [dat.dSectr2add, newentry[2]]
      dPhang2adds = [dat.dPhang2add, newentry[3]]
      LatestMedianSectrs = [dat.LatestMedianSectr, newentry[4]]
      LatestMedianPhAngs = [dat.LatestMedianPhAng,newentry[5]]
      badFlags = [dat.badFlag, newentry[6]]
      newdat = CREATE_STRUCT(cols[0], tstarts, cols[1], tends, cols[2], dSectr2adds, cols[3], dPhAng2adds, cols[4], LatestMedianSectrs, cols[5], LatestMedianPhAngs, cols[6], badFlags)
      
      sorting = sort(tstarts)

      for i = 0, n_elements(cols)-1 do begin
        newdat.(i) = newdat.(i)[sorting]
      endfor
      print, 'didnt classify as repeat'
  endelse 
  
  ;sorting = uniq(tstarts, sort(tstarts))
  ;print, time_string(double(tstarts[0]))
  ;stop
  ;    tstarts =  [dat.tstart[0:newindex], tstart, dat.tstart[newindex+replace+1:-1]]
  ;    tends =  [dat.tend[0:newindex], tend, dat.tend[newindex+1:-1]]
  ;    dSectr2adds = [dat.dSectr2add[0:newindex], dSectr2add, dat.dSectr2add[newindex+1:-1]]
  ;    dPhang2adds = [dat.dPhang2add[0:newindex], dPhang2add, dat.dPhang2add[newindex+1:-1]]
  ;    LatestMedianSectrs = [dat.LatestMedianSectr[0:newindex], LatestMedianSectr, dat.LatestMedianSectr[newindex+1:-1]]
  ;    LatestMedianPhAngs = [dat.LatestMedianPhAng[0:newindex], LatestMedianPhAng, dat.LatestMedianPhAng[newindex+1:-1]]
  ;    badFlags = [dat.badFlag[0:newindex], badFlag, dat.badFlag[newindex+1:-1]]
  ;  endelse 
  ;   newdat = CREATE_STRUCT(cols[0], tstarts, cols[1], tends, cols[2], dSectr2adds, cols[3], dPhAng2adds, cols[4], LatestMedianSectrs, cols[5], LatestMedianPhAngs, cols[6], badFlags)
  ;   write_csv, file, newdat, header = cols
  ;endelse 
   
   
  ; if ~old then begin
  ;  tstarts =  [dat.tstart[0:newindex-replace], tstart]
  ;  tends =  [dat.tend[0:newindex-replace], tend]
  ;  dSectr2adds = [dat.dSectr2add[0:newindex-replace], dSectr2add]
  ;  dPhang2adds = [dat.dPhang2add[0:newindex-replace], dPhang2add]
  ;  LatestMedianSectrs = [dat.LatestMedianSectr[0:newindex-replace], LatestMedianSectr]
  ;  LatestMedianPhAngs = [dat.LatestMedianPhAng[0:newindex-replace], LatestMedianPhAng]
  ;  badFlags = [dat.badFlag[0:newindex-replace], badFlag]
  ;endif else begin
  ;  tstarts =  [dat.tstart[0:newindex-replace], tstart, dat.tstart[newindex+replace:-1]]
  ;  tends =  [dat.tend[0:newindex-replace], tend, dat.tend[newindex+1:-1]]
  ;  dSectr2adds = [dat.dSectr2add[0:newindex-replace], dSectr2add, dat.dSectr2add[newindex+1:-1]]
  ;  dPhang2adds = [dat.dPhang2add[0:newindex-replace], dPhang2add, dat.dPhang2add[newindex+1:-1]]
  ;  LatestMedianSectrs = [dat.LatestMedianSectr[0:newindex-replace], LatestMedianSectr, dat.LatestMedianSectr[newindex+1:-1]]
  ;  LatestMedianPhAngs = [dat.LatestMedianPhAng[0:newindex-replace], LatestMedianPhAng, dat.LatestMedianPhAng[newindex+1:-1]]
  ;  badFlags = [dat.badFlag[0:newindex-replace], badFlag, dat.badFlag[newindex+1:-1]]
  ;endelse
   ;newdat = CREATE_STRUCT(cols[0], tstarts, cols[1], tends, cols[2], dSectr2adds, cols[3], dPhAng2adds, cols[4], LatestMedianSectrs, cols[5], LatestMedianPhAngs, cols[6], badFlags)
   ;
  write_csv, file, newdat, header = cols
  ;temporary check
   temp_dub = time_double(newdat.tstart[-5:n_elements(newdat.tstart)-1])
   ordered_dub = temp_dub[sort(temp_dub)]
   a = temp_dub ne ordered_dub
   if total(a) ge 1 then stop
  ;end of temporary check 
   
  check5 = total(n_elements(tstarts))
  
  ;if check1-check2+check3-check4+check5-1 ne check1 then stop
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FILE FORMATTING                       ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;newdat = read_csv(file, N_TABLE_HEADER = 1) 
  ;mask = uniq(time_double(newdat.field01), sort(time_double(newdat.field01)))
  ;close, /all

  logentry = [string(tstart), string(tend), string(oldtimes_current[0]), string(oldtimes_current[1]), string(dSectr2add), string(dPhAng2add), strtrim(badFlag), strtrim(bad_comment)]
  logentry = strjoin(logentry, ', ')
  CD, 'epd_processing'
  OPENW, 1, 'el'+probe+'_epd_processing_log.csv', /APPEND
  PRINTF, 1, logentry
  CD, '..'
  ;entry = [oldtimes_current[0], oldtimes_current[1], chisq_avg, new_entry
  ;oldtimes_start = [oldszs.field3, oldtimes_current[0]]
  ;oldtimes_end = [oldszs.field4, oldtimes_current[1]]
  CLOSE, 1
  print, 'log entry: '
  print, logentry
  
  ;stop

  ; Manually copy updated calibration file to server, if desired
  
 
end
