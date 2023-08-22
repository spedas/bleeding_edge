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
;   Isolu:              specify a start of inital guess of dSectr2add
;                       (default) Isolu=0, initial guess of dSectr2add is [-4,-2,0,2,4]
;                       Isolu=1, initial guess of dSectr2add is [-2,0,2,4]
;   onlypng:            (default) onlypng=0, pop-up window and save png
;                       onlypng=1, only save png
;   outputplot:        (default) outputplot=0 save summary plot for all fits (summary_IsoluX_ItersX)
;                       outputplot=1 save summary plot for all fits (summary_IsoluX_ItersX) and plots for each iteration (IsoluX_ItersX_XXX)           
;                       
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
; :Last edited: Jiashu Wu
;-
pro elf_phase_delay_AUTO, pick_times=pick_times, new_config=new_config, probe=probe, Echannels=Echannels, $
  overwrite_attitude=overwrite_attitude, badFlag = badFlag, check_nonmonotonic=check_nonmonotonic, sstart = sstart, $
  send = send, soldtimes = soldtimes, Isolu=Isolu, onlypng=onlypng, outputplot=outputplot

  ;elf_init
  ;
  tplot_options, 'xmargin', [15,15]
  xmargin1 = 0.1
  xmargin2 = 0.2
  
  if undefined(probe) then probe='a' else if probe ne 'a' and probe ne 'b' then begin
    print, 'Please enter a valid probe.'
    return
  endif

  ; HISTORY OF TIME INTERVALS USED
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  tstart= sstart ; (result: -1 sector + 2.5 deg)
  tend= send


  ; JWu:
  ; create a new folder to save all plots for one sci zone, detele exisitng folder
  ; folder name is sci zone date and time
  ; also create a finalplot folder to save only the final results of each sci zone
  tstart_str=time_string(tstart, format=6)
  temp_path = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots/temp_' + tstart_str 
  if size(temp_path,/dimen) eq 1 then FILE_DELETE,temp_path,/RECURSIVE ; delete old folder
  FILE_MKDIR,temp_path ; make new folder
  ; check whether folder exist
  finalfolder=temp_path+'/Fitplots'
  fileresult=FILE_SEARCH(finalfolder)
  if size(fileresult,/dimen) eq 1 then FILE_DELETE,finalfolder,/RECURSIVE ; delete old folder
  FILE_MKDIR,finalfolder ; make new folder
  CD,finalfolder
 
  if ~keyword_set(onlypng) then onlypng=1
  if ~keyword_set(outputplot) then outputplot=0
  
  if onlypng eq 1 then begin
    set_plot,'z'     ; z-buffer
    device,set_resolution=[1000,650]
    TVLCT, 255, 255, 255, 254 ; White color
    TVLCT, 0, 0, 0, 253       ; Black color
    !P.Color = 253
    !P.Background = 254
  endif else begin
    ;set_plot,'x'
    TVLCT, 255, 255, 255, 254 ; White color
    TVLCT, 0, 0, 0, 253       ; Black color
    !P.Color = 253
    !P.Background = 254
  endelse

  ;;; BEGIN CODE ;;;
  ; If phase delay file is not stored locally: copy over from server

  ; Read calibration (phase delay) file and store data
  file = 'el'+probe+'_epde_phase_delays_new.csv'
  filedata = read_csv(!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+file, header = cols, types = ['String', 'String', 'Float', 'Float','Float','Float','Float','Float'])
  dat = CREATE_STRUCT(cols[0], filedata.field1, cols[1], filedata.field2, cols[2], filedata.field3, cols[3],  filedata.field4, cols[4], filedata.field5, cols[5], filedata.field6, cols[6], filedata.field7, cols[7], filedata.field8, cols[8], filedata.field9)
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;make a copy of previous existing phase delay file, with date noted (akr)

  ;note current date
;  dateprev = time_string(systime(/seconds),format=2,precision=-3)
;  fileprev = 'el'+probe+'_epde_phase_delays_' + dateprev + '.csv'

  ;create folder for old pdp copies
;  cwdirnametemp=!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'
;  cd,cwdirnametemp
 ; pdpprev_folder = 'pdpcsv_archive'
;  fileresult=file_search(pdpprev_folder)
;  if size(fileresult,/dimen) eq 0 then file_mkdir,pdpprev_folder

;  write_csv, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/pdpcsv_archive/'+ fileprev, filedata, header = cols
  
  ;return back to original directory
  cd,finalfolder
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  timeduration=time_double(tend)-time_double(tstart)
  timespan,tstart,timeduration,/seconds
  pival=double(!PI)
  err_trshod = 0.5  ; dq/q ratio
  eightones = [1.,1.,1.,1.,1.,1.,1.,1.]

  ; Prepare to load data of interest
  mytype='cps'
  ; Extract spin period for current data
  ;elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype, suffix='_current'
  elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype
  get_data, 'el'+probe+'_pef_spinper', data=spinper_current
  ;tspin_current=average(spinper_current.y)


  ;check
  check1 = total(n_elements(dat.tstart))

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FILE READING AND CONFIGURATION               ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;START OF FITS                                       ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;JWu
  if undefined(Isolu) then Isolu=0
  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  nspinsectors=long(max(elf_pef_sectnum.y)+1)
  if nspinsectors eq 16 then iniSec=[-4,-2,0,2,4] else iniSec=[-8,-4,0,4,8]
  PAdiff=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)  ; 0-3 for different inital Sec 4-7 for skiptime
  LastIter=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  PAdSectr=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  PAdPhAng=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  pafit_even_med=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  pafit_odd_med=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  PAfit_even_num=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  PAfit_odd_num=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  PAeven_var=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  PAodd_var=make_array(n_elements(iniSec)+1,value=!VALUES.F_NAN)
  skiptime=[]
  maxiter = 6
  autobad = 0
  badFlag = 0
  ;stop

  BODY:
  ;dSectr2add=dat.LatestMedianSectr[-1]; initial guesses (doesn't usually matter, but pos/neg sector should be correct otherwise parabolas might open upward)
  ;dPhAng2add=dat.LatestMedianPhAng[-1]

  ;INITIAL GUESSES
  dSectr2add = iniSec[Isolu]
  dPhAng2add = 4
  ;read, dSectr2add, PROMPT='IG, Sector: '
  ;read, dPhAng2add, PROMPT='IG Phase Angle: '

  ; make sure you pick a time just prior to an ascending PA!!!! This will make "even" PAs ascending ones (red), and "odd" PAs descending one (blue)
  elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype, suffix='_orig',/no_spec
  elf_load_state, probes=[probe],/get_support_data
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM
  tt89,'el'+probe+'_pos_gsm',/igrf_only,newname='el'+probe+'_bt89_gsm',period=1.
  tdotp,'el'+probe+'_bt89_gsm','el'+probe+'_pos_gsm',newname='el'+probe+'_Br_sign'
  get_data,'el'+probe+'_Br_sign',data=elf_Br_sign
  if median(elf_Br_sign.y) lt 0 then hemisp='North' else hemisp='South'

  ;elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype, /no_spec
  if keyword_set(pick_times) then begin
    tplot,'el'+probe+'_pef_'+mytype
    print, 'explore time interval'
    stop

    ctime,tstartendtimes4pa2plot ; here pick 2 times between which to determine from the symmetry of the PA distribution around 90deg the time delay to use
    ;JWu
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
    tstartendtimes4pa2plot=time_double([tstart,tend]) ; do fits on full interval
    tplot,['el'+probe+'_pef_'+mytype+'_orig','el'+probe+'_pef_sectnum'],title=' EPD Electrons EL-'+strupcase(probe)+', '+time_string(tstartendtimes4pa2plot[0])+' - '+strmid(time_string(tstartendtimes4pa2plot[1]),11,8)+' UT, '+hemisp
    timebar,time_string(tstartendtimes4pa2plot)
    makepng,'pef_counts'
    ;stop
  endelse

  iters=0
  FINDSHIFT:
  elf_load_state, probes=[probe],/get_support_data

  ; JWu edit start: load error
  elf_load_epd, probes=probe, datatype='pef', level='l1', type='raw'
  get_data,'el'+probe+'_pef_raw',data=elf_pef_raw,dlim=raw_dlim,lim=raw_lim

  ; load cps
  elf_load_epd, probes=probe, datatype='pef', level='l1', type=mytype ; DEFAULT UNITS ARE NFLUX THIS ONE IS CPS
  get_data,'el'+probe+'_att_gei',data=elf_att_gei,dlim=myattdata_dlim,lim=myattdata_lim
  get_data,'el'+probe+'_pos_gei',data=elf_pos_gei,dlim=mypostdata_dlim,lim=myposdata_lim

  ;JWu edit: ibo spread
  get_data, 'el'+probe+'_pef_nspinsinsum', data=my_nspinsinsum
  my_nspinsinsum2use=my_nspinsinsum.y
  ;;;;;;;;;;;;;;;;;
  get_data,'el'+probe+'_pef_'+mytype,data=elf_pef,dlim=mypxfdata_dlim,lim=mypxfdata_lim
  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  get_data,'el'+probe+'_pef_spinper',data=elf_pef_spinper,dlim=myspinperdata,lim=myspinperdata_lim
  nsectors=n_elements(elf_pef.x)
  Max_numchannels = n_elements(elf_pef.v) ; this is 16 (nominally)
  nspinsectors=long(max(elf_pef_sectnum.y)+1)
  angpersector = 360./nspinsectors
  tcor=(my_nspinsinsum2use-1.)*(elf_pef_spinper.y/nspinsectors)*(float(elf_pef_sectnum.y)-float(nspinsectors)/2.+0.5) ; spread in time
  elf_pef.x=elf_pef.x+tcor ; here correct (spread) sectors to full accumulation interval
  elf_pef_sectnum.x=elf_pef_sectnum.x+tcor ; (spread) sectors to full accumulation interval
  elf_pef_spinper.x=elf_pef_spinper.x+tcor ; (spread) sectors to full accumulation interval
  
  ;JWU check time for tplot variables. sometimes they are not monotonic
  length = n_elements(elf_pef_sectnum.x)
  diff = elf_pef_sectnum.x[1:length-1] - elf_pef_sectnum.x[0:length-2]
  ianynegs=where(diff lt 0,janynegs)
  if janynegs gt 0 then begin
    badflag = 4
    goto, Median_Calculation
  endif
  ;JWU
  ;
  ;mypxforigarray=reform(elf_pef.y,nsectors*nspinsectors)
  mypxforigarray=reform(elf_pef.y,nsectors*Max_numchannels)
  ianynegpxfs=where(mypxforigarray lt 0.,janynegpxfs) ; eliminate negative values from raw data -- these should not be there!
  if janynegpxfs gt 0 then mypxforigarray[ianynegpxfs]=0.
  ;elf_pef.y=reform(mypxforigarray,nsectors,nspinsectors)
  elf_pef.y=reform(mypxforigarray,nsectors,Max_numchannels)
  store_data,'el'+probe+'_pef',data=elf_pef,dlim=mypxfdata_dlim,lim=mypxfdata_lim
  store_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  store_data,'el'+probe+'_pef_spinper',data=elf_pef_spinper,dlim=myspinperdata,lim=myspinperdata_lim
  options,'el'+probe+'_pef',spec=0
  ;JWu end

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
  ;nsectors=n_elements(elf_pef.x)
  ;nspinsectors=n_elements(reform(elf_pef.y[0,*]))  ; JWu 32 sec
  if dSectr2add ne 0 then begin
    xra=make_array(nsectors-abs(dSectr2add),/index,/long)
    if dSectr2add gt 0 then begin
      elf_pef.y[dSectr2add:nsectors-1,*]=elf_pef.y[xra,*]
      elf_pef.y[0:dSectr2add-1,*]=!VALUES.F_NaN
      ; JWu
      elf_pef_raw.y[dSectr2add:nsectors-1,*]=elf_pef_raw.y[xra,*]
      elf_pef_raw.y[0:dSectr2add-1,*]=!VALUES.F_NaN
    endif else if dSectr2add lt 0 then begin
      elf_pef.y[xra,*]=elf_pef.y[abs(dSectr2add):nsectors-1,*]
      elf_pef.y[dSectr2add:nsectors-1,*]=!VALUES.F_NaN
      ; JWu
      elf_pef_raw.y[xra,*]=elf_pef_raw.y[abs(dSectr2add):nsectors-1,*]
      elf_pef_raw.y[dSectr2add:nsectors-1,*]=!VALUES.F_NaN
    endif
    store_data,'el'+probe+'_pef',data={x:elf_pef.x,y:elf_pef.y,v:elf_pef.v},dlim=mypefdata_dlim,lim=mypefdata_lim ; you can save a NaN!
    store_data,'el'+probe+'_pef_raw',data={x:elf_pef.x,y:elf_pef_raw.y,v:elf_pef.v},dlim=raw_dlim, lim=raw_lim
  endif

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; extrapolate on the left and right to [0,...nspinsectors-1], degap the data
  tres,'el'+probe+'_pef_sectnum',dt_sectnum
  dt_sectnum_left=median(elf_pef_sectnum.x[1:nspinsectors-1]-elf_pef_sectnum.x[0:nspinsectors-2]) ; median dt of first spin's sectors
  dt_sectnum_rite=median(elf_pef_sectnum.x[nsectors-nspinsectors+1:nsectors-1]-elf_pef_sectnum.x[nsectors-nspinsectors:nsectors-2]) ; median of last spin's sectors
  elf_pef_sectnum_new=elf_pef_sectnum.y
  elf_pef_sectnum_new_times = elf_pef_sectnum.x
  if elf_pef_sectnum.y[0] gt 0 then begin
    ;JWu
    npadsleft=elf_pef_sectnum.y[0]
    rapadleft=make_array(npadsleft,/index,/int)
    elf_pef_sectnum_new = [rapadleft, elf_pef_sectnum.y]
    elf_pef_sectnum_new_times = [elf_pef_sectnum.x[0] - (elf_pef_sectnum.y[0]-rapadleft)*dt_sectnum_left, elf_pef_sectnum_new_times]
    if (n_elements(my_nspinsinsum2use) gt 1) then my_nspinsinsum2use=[rapadleft*0+my_nspinsinsum2use[0],my_nspinsinsum2use]
  endif
  if elf_pef_sectnum.y[n_elements(elf_pef_sectnum.y)-1] lt (nspinsectors-1) then begin
    ;JWu
    npadsright=(nspinsectors-1)-elf_pef_sectnum.y[n_elements(elf_pef_sectnum.y)-1]
    rapadright=make_array(npadsright,/index,/int)
    elf_pef_sectnum_new = [elf_pef_sectnum_new, elf_pef_sectnum.y[n_elements(elf_pef_sectnum.y)-1]+rapadright+1]
    elf_pef_sectnum_new_times = $
      [elf_pef_sectnum_new_times , elf_pef_sectnum_new_times[n_elements(elf_pef_sectnum.y)-1] + (rapadright+1)*dt_sectnum_rite]
    if (n_elements(my_nspinsinsum2use) gt 1) then my_nspinsinsum2use=[my_nspinsinsum2use,rapadright*0+my_nspinsinsum2use[-1]]
  endif
  store_data,'el'+probe+'_pef_sectnum',data={x:elf_pef_sectnum_new_times,y:elf_pef_sectnum_new},dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;;JWu--the following two line fails if big gap exist in data
  ;tdegap,'el'+probe+'_pef_sectnum',dt=dt_sectnum,/over
  ;tdeflag,'el'+probe+'_pef_sectnum','linear',/over
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; JWu check gaps in sectnum and detele sectors is not 0-15
  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum
  
  elf_pef_sectnum_degap=[]
  elf_pef_sectnum_tdegap=[]
  sec_zero=where(elf_pef_sectnum.y eq 0)
  seczero_start=sec_zero(where(sec_zero[1:-1]-sec_zero[0:-2] eq nspinsectors))
  seczero_end=sec_zero(where(sec_zero[1:-1]-sec_zero[0:-2] eq nspinsectors)+1)-1
  for isecgap=0,n_elements(seczero_start)-1 do begin
    if total(elf_pef_sectnum.y[seczero_start[isecgap]:seczero_end[isecgap]] eq indgen(nspinsectors)) eq nspinsectors then begin ; check whether sectnum is exactly 0-15
      ; one example of sectnum is not exactly 0-15
      ; 2021-08-20/10:56:58 sectnum ...,14,0,15,1,2,3,4,5,6,7,8,9,10,11,12,13,14,0...
      append_array,elf_pef_sectnum_degap, elf_pef_sectnum.y[seczero_start[isecgap]:seczero_end[isecgap]]
      append_array,elf_pef_sectnum_tdegap, elf_pef_sectnum.x[seczero_start[isecgap]:seczero_end[isecgap]]
    endif
  endfor
  if undefined(elf_pef_sectnum_tdegap) then begin
    badflag=4
    goto, Median_Calculation
  endif
  store_data,'el'+probe+'_pef_sectnum_degap',data={x:elf_pef_sectnum_tdegap, y:elf_pef_sectnum_degap}
  copy_data,'el'+probe+'_pef_sectnum_degap','el'+probe+'_pef_sectnum'
  ; JWu this doesn't correct when sector number is not continous, so comment for now
  ;  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum ; now pad middle gaps!
  ;  ksectra=make_array(n_elements(elf_pef_sectnum.x)-1,/index,/long)
  ;  dts=(elf_pef_sectnum.x[ksectra+1]-elf_pef_sectnum.x[ksectra])
  ;  dsectordt=(elf_pef_sectnum.y[ksectra+1]-elf_pef_sectnum.y[ksectra])/dts
  ;  ianygaps=where((dsectordt lt 0.75*median(dsectordt) and (dsectordt gt -0.5*float(-1)/dt_sectnum)),janygaps) ; slope below 0.75*nspinsectors/(nspinsectors*dt_sectnum) when a spin gap exists (gives <0.5), force it to median
  ;  if janygaps gt 0 then begin
  ;    dsectordt[ianygaps]=median(dsectordt)
  ;    stop
  ;  endif else return
  ;  stop
  ;  dsectordt=[dsectordt[0],dsectordt]
  ;  dts=[0,dts]
  ;  tol=0.25*median(dts)
  ;  mysectornumpadded=long(total(dsectordt*dts,/cumulative) + elf_pef_sectnum.y[0]+tol) mod nspinsectors
  ;  mysectornewtimes=(total(dts,/cumulative) + elf_pef_sectnum.x[0])
  ;  store_data,'el'+probe+'_pef_sectnum',data={x:mysectornewtimes,y:float(mysectornumpadded)},dlim=mysectnumdata_dlim,lim=mysectnumdata_lim
  ;
  ;AT THIS POINT (lines above): pef_sectnum tplot variable turns into step function at interpolated gaps
  ;
  ; now pad the rest of the quantities
  get_data,'el'+probe+'_pef_spinper',data=elf_pef_spinper,dlim=myspinperdata_dlim,lim=myspinperdata_lim ; this preserved the original times
  spin_med=median(elf_pef_spinper.y)
  spin_var=variance(elf_pef_spinper.y)/spin_med*100.

  store_data,'el'+probe+'_pef_times',data={x:elf_pef_spinper.x,y:elf_pef_spinper.x-elf_pef_spinper.x[0]} ; this is to track gaps
  ;JWu start
  ;tinterpol_mxn,'el'+probe+'_pef_times','el'+probe+'_pef_sectnum',/nearest_neighbor,/NAN_EXTRAPOLATE,/over ; middle gaps have constant values after interpolation, side pads are NaNs themselves
  tinterpol_mxn,'el'+probe+'_pef_times','el'+probe+'_pef_sectnum',/NAN_EXTRAPOLATE,/over
  ;JWu end
  get_data,'el'+probe+'_pef_times',data=elf_pef_times
  xra=make_array(n_elements(elf_pef_times.x)-1,/index,/long)
  iany=where(elf_pef_times.y[xra+1]-elf_pef_times.y[xra] lt 1.e-6, jany) ; takes care of middle gaps
  inans=where(FINITE(elf_pef_times.y,/NaN),jnans) ; identifies side pads
  ;
  tinterpol_mxn,'el'+probe+'_pef_raw','el'+probe+'_pef_sectnum',/over
  get_data,'el'+probe+'_pef_raw',data=elf_pef,dlim=mypefdata_dlim,lim=mypefdata_lim
  if jnans gt 0 then elf_pef.y[inans,*]=!VALUES.F_NaN
  if jany gt 0 then elf_pef.y[iany,*]=!VALUES.F_NaN
  store_data,'el'+probe+'_pef_raw',data={x:elf_pef.x,y:elf_pef.y,v:elf_pef.v},dlim=mypefdata_dlim,lim=mypefdata_lim  ;

  tinterpol_mxn,'el'+probe+'_pef','el'+probe+'_pef_sectnum',/over
  get_data,'el'+probe+'_pef',data=elf_pef,dlim=mypefdata_dlim,lim=mypefdata_lim
  if jnans gt 0 then elf_pef.y[inans,*]=!VALUES.F_NaN
  if jany gt 0 then elf_pef.y[iany,*]=!VALUES.F_NaN
  store_data,'el'+probe+'_pef',data={x:elf_pef.x,y:elf_pef.y,v:elf_pef.v},dlim=mypefdata_dlim,lim=mypefdata_lim  ;

  tinterpol_mxn,'el'+probe+'_pef_spinper','el'+probe+'_pef_sectnum',/overwrite ; linearly interpolated, this you keep
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;
  ; Extrapolation and degapping completed!!! Now start viewing
  ;
  get_data,'el'+probe+'_pef',data=elf_pef,dlim=mypefdata_dlim,lim=mypefdata_lim
  get_data,'el'+probe+'_pef_spinper',data=elf_pef_spinper,dlim=myspinperdata_dlim,lim=myspinperdata_lim
  get_data,'el'+probe+'_pef_sectnum',data=elf_pef_sectnum,dlim=mysectnumdata_dlim,lim=mysectnumdata_lim

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
  spinphase180=((dPhAng2add+float(elf_pef_sectnum.x-elf_pef_sectnum.x[lastzero]+0.5*my_nspinsinsum2use*elf_pef_spinper.y/float(nspinsectors))*360./my_nspinsinsum2use/elf_pef_spinper.y)+360.) mod 360.
  spinphase=spinphase180*!PI/180. ; in radians corresponds to the center of the sector
  store_data,'spinphase',data={x:elf_pef_sectnum.x,y:spinphase} ; just to see...
  store_data,'spinphasedeg',data={x:elf_pef_sectnum.x,y:spinphase*180./!PI} ; just to see...
  ylim,"spinphasedeg",0.,360.,0.
  options,'spinphasedeg','databar',180.
  options,'ddts','databar',{yval:[0.], color:[6], linestyle:2}

  threeones=[1,1,1]
  tinterpol_mxn,'el'+probe+'_att_gei','el'+probe+'_pos_gei',/over
  cotrans,'el'+probe+'_pos_gei','el'+probe+'_pos_gse',/GEI2GSE
  cotrans,'el'+probe+'_pos_gse','el'+probe+'_pos_gsm',/GSE2GSM
  tt89,'el'+probe+'_pos_gsm',/igrf_only,newname='el'+probe+'_bt89_gsm',period=1.
  cotrans,'el'+probe+'_pos_gsm','el'+probe+'_pos_sm',/GSM2SM ; <-- use SM geophysical coordinates plus Despun Spacecraft coord's with Lvec (DSL)
  cotrans,'el'+probe+'_bt89_gsm','el'+probe+'_bt89_sm',/GSM2SM ; Bfield in same coords as well
  get_data, 'el'+probe+'_att_gei', data=d
  if size(d, /type) NE 8 then begin
    badflag=4
    goto, Median_Calculation
  endif
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
  ;sqrt(total("el'+probe+'_pef_sm_interp_partdir"^2,2)) supposed to be 1
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
  ;tplot,'el'+probe+'_pef_pa spinphasedeg el'+probe+'_pef_sectnum el'+probe+'_pef'
  tplot_apply_databar

  tplot, 'el'+probe+'_pef el'+probe+'_pef_pa',title=''
  timebar,time_string(tstartendtimes4pa2plot)
  ;stop
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
  ;Jwu
  calc," 'el"+probe+"_pef_err' = 1/sqrt('el"+probe+"_pef_raw'+1)"
  get_data,'el'+probe+'_pef_err',data=elf_pef_err, dlim=err_dlim, lim=err_lim
  elf_pef_val_err=make_array(nsectors,numchannels,/double)
  if (mytype eq 'nflux' or mytype eq 'eflux' ) then $
    for jthchan=0,numchannels-1 do $
    elf_pef_val[*,jthchan]=(elf_pef.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]] # $
    (Emaxs[MinE_channels[jthchan]:MaxE_channels[jthchan]]-Emins[MinE_channels[jthchan]:MaxE_channels[jthchan]])) / $
    total(Emaxs[MinE_channels[jthchan]:MaxE_channels[jthchan]]-Emins[MinE_channels[jthchan]:MaxE_channels[jthchan]]) ; MULTIPLIED BY ENERGY WIDTH AND THEN DIVIDED BY BROAD CHANNEL ENERGY
  if (mytype eq 'raw' or mytype eq 'cps' ) then $
    for jthchan=0,numchannels-1 do begin
    elf_pef_val[*,jthchan]=total(elf_pef.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]],2) ; JUST SUMMED
    elf_pef_val_err[*,jthchan]=sqrt(total((elf_pef.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]]*elf_pef_err.y[*,MinE_channels[jthchan]:MaxE_channels[jthchan]])^2,/nan,2))/elf_pef_val[*,jthchan]
  endfor

  elf_pef_val_full = elf_pef.y ; this array contains all angles and energies (in that order, same as val), to be used to compute energy spectra
  store_data,'el'+probe+'_pef_val_err',data={x:elf_pef_err.x,y:elf_pef_val_err}
  get_data,'el'+probe+'_pef_pa',data=elf_pef_pa
  store_data,'el'+probe+'_pef_val',data={x:elf_pef.x,y:elf_pef_val}
  store_data,'el'+probe+'_pef_val_full',data={x:elf_pef.x,y:elf_pef_val_full,v:elf_pef.v},dlim=mypefdata_dlim,lim=mypefdata_lim ; contains all angles and energies
  ylim,'el'+probe+'_pef_val*',1,1,1
  ;------------------------------------------------------------
  ; JWu : if skip time
  if skiptime ne [] then begin
    for iskiptime=0,n_elements(skiptime)-1 do begin
      iskip=where(elf_pef.x eq skiptime[iskiptime], jskip)
      elf_pef_val[iskip,*]=!VALUES.F_NAN
      elf_pef_val_full[iskip,*]=!VALUES.F_NAN
      ;stop
    endfor
  endif
  ;------------------------------------------------------------
  ; investigate logic -- feeds into selection of full PA ranges
  ;JWu
  Tspin=average(my_nspinsinsum2use*elf_pef_spinper.y)
  ipasorted=sort(elf_pef_pa.y[0:nspinsectors-1]) ;PAs for each sector? sorted from low to high
  istartAscnd=max(elf_pef_sectnum.y[ipasorted[0:1]]) ;sector nums associated with lowest + next lowest PAs. take highest one
  if abs(ipasorted[0]-ipasorted[1]) ge 2 then istartAscnd=min(elf_pef_sectnum.y[ipasorted[0:1]])
  istartDscnd=max(elf_pef_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]]) ;sector nums associated with highest + second highest PAs. take highest one
  if abs(ipasorted[nspinsectors-2]-ipasorted[nspinsectors-1]) ge 2 then istartDscnd=min(elf_pef_sectnum.y[ipasorted[nspinsectors-2:nspinsectors-1]])
  istartAscnds=where(abs(elf_pef_sectnum.y-elf_pef_sectnum.y[istartAscnd]) lt 0.1) ;get all starts of ascending PA ranges - anywhere that has same sector num (wt)
  istartDscnds=where(abs(elf_pef_sectnum.y-elf_pef_sectnum.y[istartDscnd]) lt 0.1) ;get all starts of descending PA ranges - anywhere that has same sector num (wt)
  tstartAscnds=elf_pef_sectnum.x[istartAscnds]
  tstartDscnds=elf_pef_sectnum.x[istartDscnds]

  ;------------------------------------------------------------
  ;  ; JWu test whether each spin is 16 sectors. if not delete
  ;  sectnumAscnds=elf_pef_sectnum.y[istartAscnds]
  ;  sectnumDscnds=elf_pef_sectnum.y[istartDscnds]
  ;  if n_elements(istartAscnds) gt 1 or n_elements(istartDscnds) gt 1 then begin
  ;    isectnumAscnds=where(ts_diff(sectnumAscnds,1) ne 0,jsectnumAscnds)
  ;    isectnumDscnds=where(ts_diff(sectnumDscnds,1) ne 0,jsectnumDscnds)
  ;    if jsectnumAscnds ne 0 or jsectnumDscnds ne 0 then stop
  ;  endif else begin
  ;    print,'no enough data, skip this sci zone'
  ;    return
  ;  endelse
  ;------------------------------------------------------------
  ; BELOW FOR TESTING PURPOSES ONLY
  ;***istartAscnd=3 and istartDscnd=12 (for my test case)
  ;NOTE: in 2019-08-31/16:33:35 case, first [0,nspin_sectors-1] range of elf_pef_sectnum has sector=1 missing!
  ; check how many are missing sector numbers
  arr=findgen(n_elements(elf_pef_sectnum.y)/nspinsectors)*nspinsectors
  elements_missing_secs=[-1]
  foreach element,arr do begin
    sectnums=elf_pef_sectnum.y[element:element+nspinsectors-1]
    secs=indgen(nspinsectors)
    foreach s,secs do begin
      if total(where(s eq sectnums)) eq -1 then elements_missing_secs=[elements_missing_secs,element]
      ; a sector number is missing! ...most zones have multiple segments with many "missing" sectors (wt)
      ; this is due to gaps in the epde data (sectnum is interpolated across, giving a step pattern)
    endforeach
  endforeach
  elements_missing_secs=elements_missing_secs(uniq(elements_missing_secs))
  if n_elements(elements_missing_secs) gt 1 then begin
    elements_missing_secs=elements_missing_secs[1:n_elements(elements_missing_secs)-1]
    stop
  endif
  ;stop ;check alongside elf_pef_sectnum & elf_pef_pa
  ; END SECTION FOR TESTING PURPOSES ONLY

  ;stop
  if tstartAscnds[0] lt tstartDscnds[0] then begin ; add a half period on the left as a precaution since there is a chance that hanging sectors exist (not been accounted for yet)
    tstartDscnds=[tstartDscnds[0]-Tspin,tstartDscnds]
  endif else begin
    tstartAscnds=[tstartAscnds[0]-Tspin,tstartAscnds]
  endelse
  nstartAscnds=n_elements(tstartAscnds)
  nstartDscnds=n_elements(tstartDscnds)
  ;nstartregAscnds=n_elements(tstartregAscnds) ; JWu not used
  ;nstartregDscnds=n_elements(tstartregDscnds)

  if tstartDscnds[nstartDscnds-1] lt tstartAscnds[nstartAscnds-1] then begin ; add a half period on the right as a precautionsince chances are there are hanging ectors (not been accounted for yet)
    tstartDscnds=[tstartDscnds,tstartDscnds[nstartDscnds-1]+Tspin]
  endif else begin
    tstartAscnds=[tstartAscnds,tstartAscnds[nstartAscnds-1]+Tspin]
  endelse
  nstartAscnds=n_elements(tstartAscnds)
  nstartDscnds=n_elements(tstartDscnds)
  ;nstartregAscnds=n_elements(tstartregAscnds)
  ;nstartregDscnds=n_elements(tstartregDscnds)
  
  ; find the first starttime of a full PA range that contains any data (Ascnd or Descnd), add integer # of halfspins
  istart2reform=min(istartAscnd,istartDscnd)
  nhalfspinsavailable=long((nsectors-(istart2reform+1))/(nspinsectors/2.))
  ifinis2reform=(nspinsectors/2)*nhalfspinsavailable+istart2reform-1 ; exact # of half-spins (full PA ranges)
  elf_pef_pa_spec=make_array(nhalfspinsavailable,(nspinsectors/2),numchannels,/double)
  elf_pef_pa_spec_full=make_array(nhalfspinsavailable,(nspinsectors/2),Max_numchannels,/double) ; has ALL ENERGIES = Max_numchannels
  for jthchan=0,numchannels-1 do elf_pef_pa_spec[*,*,jthchan]=transpose(reform(elf_pef_val[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
  ; Jwu
  elf_pef_pa_spec_err=make_array(nhalfspinsavailable,(nspinsectors/2),numchannels,/double)
  for jthchan=0,numchannels-1 do elf_pef_pa_spec_err[*,*,jthchan]=transpose(reform(elf_pef_val_err[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))


  for jthchan=0,Max_numchannels-1 do elf_pef_pa_spec_full[*,*,jthchan]=transpose(reform(elf_pef_val_full[istart2reform:ifinis2reform,jthchan],(nspinsectors/2),nhalfspinsavailable))
  elf_pef_pa_spec_times_full=transpose(reform(elf_pef_pa.x[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))
  elf_pef_pa_spec_times=total(elf_pef_pa_spec_times_full,2)/(nspinsectors/2.) ; these are midpoints anyway, no need for the ones above
  elf_pef_pa_spec_pas=transpose(reform(elf_pef_pa.y[istart2reform:ifinis2reform],(nspinsectors/2),nhalfspinsavailable))
  test=transpose(reform(elf_pef_pa.y[istart2reform+1:ifinis2reform+1],(nspinsectors/2),nhalfspinsavailable))
  ; fixes non-monotonic at beginning, but now problem exists at end (WT)
  ; likewise, some are fixed completely and some still have exact same problem (used to have 2 non-monotonics at start)
  ; integer # of half-spins does NOT correspond to full PA ranges?
  ;stop ;now check PAs with same elements found above
  
  elf_pef_pa_spec_signum=signum(elf_pef_pa_spec_pas[*,nspinsectors/2-1]-elf_pef_pa_spec_pas[*,0]) ; ascending vs descending. ADDED FROM PREVIOUS CODE (wt)

  if undefined(elf_pef_pa_spec_signum) then begin
    badflag=4
    goto, Median_Calculation
  endif
  if (elf_pef_pa_spec_signum[0] gt 0) then $ ; between halfspin 0 and 1 you can build plus and minus sorted pa maps
    ipasortmapplus=sort(elf_pef_pa_spec_pas[0,*]) else ipasortmapminus=sort(elf_pef_pa_spec_pas[0,*])
  if n_elements(elf_pef_pa_spec_signum) EQ 1 then begin
    badflag=4
    goto, Median_Calculation
  endif
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
  ; JWu
  elf_pef_pa_spec2plot_err=make_array(nhalfspinsavailable,(nspinsectors/2)+2,numchannels,/double)
  for jthchan=0,numchannels-1 do elf_pef_pa_spec2plot_err[*,*,jthchan]=transpose([transpose(elf_pef_pa_spec_err[*,0,jthchan]*!VALUES.F_NaN),transpose(elf_pef_pa_spec_err[*,*,jthchan]),transpose(elf_pef_pa_spec_err[*,(nspinsectors/2)-1,jthchan]*!VALUES.F_NaN)])
  deltapafirst=(elf_pef_pa_spec_pas[*,1]-elf_pef_pa_spec_pas[*,0])
  deltapalast=(elf_pef_pa_spec_pas[*,(nspinsectors/2)-1]-elf_pef_pa_spec_pas[*,(nspinsectors/2)-2])

  ;BELOW LINE: elf_pef_pa_spec_pas2plot is problematic (each jthspec start/stop not set correctly?) (wt)
  ;traces back to elf_pef_pa_spec_pas
  elf_pef_pa_spec_pas2plot=transpose([transpose(elf_pef_pa_spec_pas[*,0]-deltapafirst),transpose(elf_pef_pa_spec_pas),transpose(elf_pef_pa_spec_pas[*,(nspinsectors/2)-1]+deltapalast)])
  ;elf_pef_pa_spec_pas2plot=transpose([transpose(elf_pef_pa_spec_pas[*,0]),transpose(elf_pef_pa_spec_pas),transpose(elf_pef_pa_spec_pas[*,(nspinsectors/2)-1])]) ;WT test

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
  pef2plots_even=make_array(n_elements(ispeceven),nspinsectors/2+2,/float,value=!Values.F_NAN)
  pa2plots_even=pef2plots_even
  pafitminus90_even=make_array(n_elements(ispeceven),/float,value=!Values.F_NAN)
  pef2plots_odd=make_array(n_elements(ispecodd),nspinsectors/2+2,/float,value=!Values.F_NAN)
  pa2plots_odd=pef2plots_odd
  pafitminus90_odd=make_array(n_elements(ispecodd),/float,value=!Values.F_NAN)

  ; check if a spin period is missing in ascending or descending; correct times if so
  uneven_flag=0
  if n_elements(pafitminus90_odd) ne n_elements(pafitminus90_even) then uneven_flag=1 ;spin period missing in one
  if uneven_flag then begin ; OR do this regardless
    t_i=time_double(tstartendtimes4pa2plot[0])
    t_f=time_double(tstartendtimes4pa2plot[1])
    tstart_init=elf_pef_pa_spec_times(where(abs(elf_pef_pa_spec_times-t_i) eq min(abs(elf_pef_pa_spec_times-t_i))))
    tend_init=elf_pef_pa_spec_times(where(abs(elf_pef_pa_spec_times-t_f) eq min(abs(elf_pef_pa_spec_times-t_f))))
  endif

  ;------------------------------------------------------------------------------------
  xfit=[20:160:0.01]
  chisq_even=[]
  yfit_even=make_array(n_elements(xfit),/float,value=0.)
  count_fits=0
  num_decreasing_pa=0
  for jthspec=0,n_elements(ispeceven)-1 do begin ;EVEN FITS
    pa2plots_even[jthspec,*]=reform(elf_pef_pa_spec_pas2plot[ispeceven[jthspec],*],nspinsectors/2+2)
    pef2plots_even[jthspec,*]=reform(elf_pef_pa_spec2plot[ispeceven[jthspec],*,0]) ; JWu
    x2fit_full=reform(pa2plots_even[jthspec,*])
    y2fit_full=reform(pef2plots_even[jthspec,*])
    ; JWu
    y2fit_err_full=reform(elf_pef_pa_spec2plot_err[ispeceven[jthspec],*,0])
    ierr=where(y2fit_err_full ge err_trshod, jerr)
    if jerr gt 0 then begin
      y2fit_full[ierr]=!Values.F_NAN
      x2fit_full[ierr]=!Values.F_NAN
    endif
    ;
    broad = where(y2fit_full gt 0, count_secs)
    pa_diffs=ts_diff(x2fit_full,1)
    monotonic = where(pa_diffs gt 0, decreasing_pa)
    ; SKIP if it doesn't have at least 5 sectors
    if decreasing_pa gt 0 and count_secs ge 5 then num_decreasing_pa+=1 ;non-monotonic PAs in a spin period of use
    if count_secs lt 3 then begin
      pef2plots_even[jthspec,*]=!Values.F_NAN
      pafitminus90_even[jthspec]=!Values.F_NAN
      chisq_even=[chisq_even,!Values.F_NAN]
      continue
    endif
    iy2fit=where(finite(y2fit_full) and y2fit_full ne 0)
    y2fit=y2fit_full(iy2fit)
    x2fit=x2fit_full(iy2fit)
    y2fit_err=y2fit_err_full(iy2fit)
    fit_errors=make_array(3,value=!Values.F_NAN) ; order 2,3,4 polyfits + quadratic interpolation
    fit_maxorders=min([count_secs-1,4])
    for n=2,fit_maxorders do begin ; n=order of fit
      ;coeffs=poly_fit(x2fit,alog10(y2fit),n,measure_errors=alog10(y2fit_err*y2fit),sigma=sigma)
      coeffs=poly_fit(x2fit,alog10(y2fit),n)
      model_poly=10^poly(x2fit_full,coeffs)
      ;stop
      ;JWu
      ;plotxy,[[reform(pa2plots_even[jthspec,1:-2])],[reform(pef2plots_even[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[1,max(pef2plots_even[jthspec,1:-2])*1.5], xsize=800.,ysize=500.,colors=['o'],thick=5,/noisotropic,psym=1
      ;plots,x2fit_full,model_poly, psym=0
      ;fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
      ;model_poly=model_poly(where(abs(x2fit_full-90) le 45)) ;only analyze points between 45-135deg
      ;fit_diff=fit_diff(where(abs(x2fit_full-90) le 45))
      model_poly=10^poly(x2fit,coeffs)
      fit_diff=(model_poly-y2fit)^2/(y2fit_err*y2fit)
      check_nans=where(finite(fit_diff), num_finite)
      fit_goodness=total(fit_diff,/NaN)/num_finite
      fit_errors[n-2]=fit_goodness
    endfor
    ; determine ideal fit order
    fit_order=where(fit_errors eq min(fit_errors))+2
    if n_elements(fit_order) gt 1 then fit_order=fit_order[1]
    fit_order=long(fit_order[0])

    ;if fit_order eq 4 then fit_order=2 ;1/31: PREVENT FROM DOING 4TH ORDER FITS
    ;coeffs=poly_fit(x2fit,alog10(y2fit),fit_order,measure_errors=alog10(y2fit_err*y2fit))
    coeffs=poly_fit(x2fit,alog10(y2fit),fit_order)
    result=10^poly(xfit,coeffs)
    ;
    ;plotxy,[[reform(pa2plots_even[jthspec,1:-2])],[reform(pef2plots_even[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[min(pef2plots_even[jthspec,1:-2])*0.8,max(pef2plots_even[jthspec,1:-2])*1.2], $
    ;  xsize=800.,ysize=500.,colors=['o'],title=' ',thick=5,/noisotropic,psym=1
    ;plots,xfit,result, psym=0
    ;plots,x2fit,y2fit, psym=4, SymSize=2.0

    if FINITE(average(result)) then begin ; if result doesn't diverge
      close2center=where(xfit gt 50 and xfit lt 130)
      ;close2center=where(xfit gt 60 and xfit lt 130)
      result_close2center=result(close2center)
      x_close2center=xfit(close2center)
      dy=DERIV(xfit(close2center),result(close2center))
      ;ypeak=result_close2center(where(abs(dy) eq min(abs(dy)))) ; sometimes abs(dy) min is where y == 0
      ;JWu start
      ;stop
      index=where(result_close2center lt median(result_close2center))
      x_close2center[index]=!VALUES.F_NAN
      result_close2center[index]=!VALUES.F_NAN
      dy[index]=!VALUES.F_NAN
      index=indgen(n_elements(dy)-1)
      izero=where((dy[index] gt 0 and dy[index+1] le 0) or (dy[index] ge 0 and dy[index+1] lt 0),jzero)
      if jzero eq 0 then begin  ; situations with no dy=0 point
        if outputplot eq 1 then begin
          plotxy,[[reform(pa2plots_even[jthspec,1:-2])],[reform(pef2plots_even[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[1,max(pef2plots_even[jthspec,1:-2])*1.5], ylog=1, $
            xsize=800.,ysize=500.,colors=['o'],title='dSectr2add='+string(dSectr2add,FORMAT='(I2)')+' dPhAng2add='+string(dPhAng2add,FORMAT='(f6.1)')+' even='+string(ispeceven[jthspec],FORMAT='(I3)'),$
            thick=5,/noisotropic,psym=1,xmargin=[xmargin1,xmargin2]
          plots,xfit,result, psym=0
          plots,x2fit,y2fit, psym=4, SymSize=2.0
          makepng,finalfolder+'/Isolu'+string(Isolu,format='(I1)')+'_Iters'+string(iters,format='(I1)')+'_'+string(ispeceven[jthspec],FORMAT='(I03)')
          ;stop
        endif
        pef2plots_even[jthspec,*]=!Values.F_NAN
        pafitminus90_even[jthspec]=!Values.F_NAN
        chisq_even=[chisq_even,!Values.F_NAN]
        continue
      endif

      ypeak=result_close2center(izero)
      ;ypeak=result_close2center(where(abs(dy) eq min(abs(dy))))
      ;JWu end
      izero_max=izero
      if total(where(dy eq 0)) eq -1 then print,'dy=0 not found! using min dy'
      if n_elements(ypeak) gt 1 then begin
        ypeak=max(ypeak,imax)
        izero_max=izero[imax]
      endif
      ypeak=ypeak[0]
      ; below 'fix' probably forces fits to be unrepresentative of real pef
      ;JWu
      ;      if max(result)/ypeak gt 1.5 then begin
      ;        stop
      ;        ypeak=max(result_close2center) ; quick fix in case poly fit results in higher not representative peak (local max)
      ;      endif
      xpeak=x_close2center[izero_max] ; could be larger than 1 element
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
      ;  xsize=800.,ysize=500.,colors=['o'],title=' ',linestyle=2,thick=5,/noisotropic,psym=2
      if outputplot eq 1 then begin
        plotxy,[[reform(pa2plots_even[jthspec,1:-2])],[reform(pef2plots_even[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[1,max(pef2plots_even[jthspec,1:-2])*1.5], ylog=1,$
          xsize=800.,ysize=500.,colors=['o'],title='dSectr2add='+string(dSectr2add,FORMAT='(I2)')+' dPhAng2add='+string(dPhAng2add,FORMAT='(f6.1)')+' even='+string(ispeceven[jthspec],FORMAT='(I3)'),$
          thick=5,/noisotropic,psym=1,xmargin=[xmargin1,xmargin2]
        model_poly_full=10^poly(x2fit_full,coeffs)
        plots,xfit,result, psym=0
        plots,x2fit,y2fit, psym=4, SymSize=2.0
        plots,[xpeak,xpeak],[1,max(pef2plots_even[jthspec,1:-2])*1.5]
        makepng,finalfolder+'/Isolu'+string(Isolu,format='(I1)')+'_Iters'+string(iters,format='(I1)')+'_'+string(ispeceven[jthspec],FORMAT='(I03)')
      endif
      pef2plots_even[jthspec,*]=pef2plots_even[jthspec,*]/ypeak
      pafitminus90_even[jthspec]=xpeak-90.
      ;stop
      ;print,xpeak
      ;stop
      ;if fit_order eq 2 then pafitminus90_even[jthspec]=-coeffs[1]/coeffs[2]/2.-90. $  ;CHANGE
      ;  else pafitminus90_even[jthspec]=xfit(where(result eq ypeak))-90.
      ;yfit_even=yfit_even+result
      ;yfit_even/=ypeak
      ;JWu try average result
      ;
      yfit_even=yfit_even*count_fits/(count_fits+1)+result/ypeak/(count_fits+1)
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
  

  ;----------------------------------------------------------------------------------------
  xfit=[20:160:0.01]
  yfit_odd=make_array(n_elements(xfit),/float,value=0.)
  count_fits=0
  num_increasing_pa=0
  chisq_odd=[]
  for jthspec=0,n_elements(ispecodd)-1 do begin ;ODD FITS
    pa2plots_odd[jthspec,*]=reform(elf_pef_pa_spec_pas2plot[ispecodd[jthspec],*],nspinsectors/2+2)
    pef2plots_odd[jthspec,*]=reform(elf_pef_pa_spec2plot[ispecodd[jthspec],*,0])  ;JWu
    x2fit_full=reform(pa2plots_odd[jthspec,*])
    y2fit_full=reform(pef2plots_odd[jthspec,*])
    ; JWu
    y2fit_err_full=reform(elf_pef_pa_spec2plot_err[ispecodd[jthspec],*,0])
    ierr=where(y2fit_err_full ge err_trshod, jerr)
    if jerr gt 0 then begin
      y2fit_full[ierr]=!Values.F_NAN
      x2fit_full[ierr]=!Values.F_NAN
    endif

    broad = where(y2fit_full gt 0, count_secs)
    pa_diffs=ts_diff(x2fit_full,1)
    monotonic = where(pa_diffs lt 0, increasing_pa)
    ;stop
    if increasing_pa gt 0 and count_secs ge 5 then num_increasing_pa+=1 ;non-monotonic PAs in a spin period of use
    ; SKIP if it doesn't have at least 5 sectors
    if count_secs lt 3 then begin
      pef2plots_odd[jthspec,*]=!Values.F_NAN
      pafitminus90_odd[jthspec]=!Values.F_NAN
      chisq_odd=[chisq_odd,!Values.F_NAN]
      continue
    endif
    iy2fit=where(finite(y2fit_full) and y2fit_full ne 0)
    y2fit=y2fit_full(iy2fit)
    x2fit=x2fit_full(iy2fit)
    y2fit_err=y2fit_err_full(iy2fit)
    fit_errors=make_array(3,value=!Values.F_NAN)
    fit_maxorders=min([count_secs-1,4])
    for n=2,fit_maxorders do begin ; n=order of fit
      ;coeffs=poly_fit(x2fit,alog10(y2fit),n,measure_errors=alog10(y2fit_err*y2fit),sigma=sigma)
      coeffs=poly_fit(x2fit,alog10(y2fit),n)
      model_poly=10^poly(x2fit_full,coeffs)
      ;JWu
      ;plotxy,[[reform(pa2plots_odd[jthspec,1:-2])],[reform(pef2plots_odd[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[0.,5000.], $
      ;   xsize=800.,ysize=500.,colors=['o'],title=' ',thick=5,/noisotropic,psym=1
      ;plots,x2fit_full,model_poly, psym=0
      ;plots,x2fit,y2fit, psym=4, SymSize=2.0
      ;stop
      ;fit_diff=((model_poly-y2fit_full)^2)/y2fit_full
      ;model_poly=model_poly(where(abs(x2fit_full-90) le 45))
      ;fit_diff=fit_diff(where(abs(x2fit_full-90) le 45))
      model_poly=10^poly(x2fit,coeffs)
      fit_diff=(model_poly-y2fit)^2/(y2fit_err*y2fit)
      check_nans=where(finite(fit_diff), num_finite)
      fit_goodness=total(fit_diff,/NaN)/num_finite
      fit_errors[n-2]=fit_goodness
    endfor
    ; determine ideal fit order
    fit_order=where(fit_errors eq min(fit_errors))+2
    if n_elements(fit_order) gt 1 then fit_order=fit_order[1]
    fit_order=long(fit_order[0])

    ;if fit_order eq 4 then fit_order=2 ;1/31: PREVENT FROM DOING 4TH ORDER FITS
    ;coeffs=poly_fit(x2fit,alog10(y2fit),fit_order,measure_errors=alog10(y2fit_err*y2fit))
    coeffs=poly_fit(x2fit,alog10(y2fit),fit_order)
    result=10^poly(xfit,coeffs)

    ;plotxy,[[reform(pa2plots_odd[jthspec,1:-2])],[reform(pef2plots_odd[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[min(pef2plots_odd[jthspec,1:-2])*0.8,max(pef2plots_odd[jthspec,1:-2])*1.2], $
    ;  xsize=800.,ysize=500.,colors=['o'],title=' ',thick=5,/noisotropic,psym=1
    ;plots,xfit,result, psym=0
    ;plots,x2fit,y2fit, psym=4, SymSize=2.0
    ;stop
    if FINITE(average(result)) then begin
      ;close2center=where(xfit gt 60 and xfit lt 130)
      close2center=where(xfit gt 50 and xfit lt 130)
      result_close2center=result(close2center)
      x_close2center=xfit(close2center)
      dy=DERIV(xfit(close2center),result(close2center))
      ;ypeak=result_close2center(where(abs(dy) eq min(abs(dy))))
      ;JWu start
      index=where(result_close2center lt median(result_close2center))
      x_close2center[index]=!VALUES.F_NAN
      result_close2center[index]=!VALUES.F_NAN
      dy[index]=!VALUES.F_NAN
      index=indgen(n_elements(dy)-1)
      izero=where((dy[index] gt 0 and dy[index+1] le 0) or (dy[index] ge 0 and dy[index+1] lt 0),jzero)
      if jzero eq 0 then begin  ; situations with no dy=0 point
        if outputplot eq 1 then begin
          plotxy,[[reform(pa2plots_odd[jthspec,1:-2])],[reform(pef2plots_odd[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[1,max(pef2plots_odd[jthspec,1:-2])*1.5], ylog=1,$
            xsize=800.,ysize=500.,colors=['o'],title='dSectr2add='+string(dSectr2add,FORMAT='(I2)')+' dPhAng2add='+string(dPhAng2add,FORMAT='(f6.1)')+' odd='+string(ispecodd[jthspec],FORMAT='(I3)'),$
            thick=5,/noisotropic,psym=1,xmargin=[xmargin1,xmargin2]
          plots,xfit,result, psym=0
          plots,x2fit,y2fit, psym=4, SymSize=2.0
          makepng,finalfolder+'/Isolu'+string(Isolu,format='(I1)')+'_Iters'+string(iters,format='(I1)')+'_'+string(ispecodd[jthspec],FORMAT='(I03)')
        endif
        pef2plots_odd[jthspec,*]=!Values.F_NAN
        pafitminus90_odd[jthspec]=!Values.F_NAN
        chisq_odd=[chisq_odd,!Values.F_NAN]
        continue
      endif
      ypeak=result_close2center(izero)
      ;ypeak=result_close2center(where(abs(dy) eq min(abs(dy))))
      ;JWu end
      if total(where(dy eq 0)) eq -1 then print,'dy=0 not found! using min dy'
      izero_max=izero
      if n_elements(ypeak) gt 1 then begin
        ypeak=max(ypeak,imax)
        izero_max=izero[imax]
      endif
      ypeak=ypeak[0]

      ;JWu
      ;      if max(result)/ypeak gt 1.5 then begin
      ;        stop
      ;        ypeak=max(result_close2center) ; quick fix in case poly fit results in higher not representative peak
      ;      endif

      xpeak=x_close2center[izero_max] ; could be larger than 1 element
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
      if outputplot eq 1 then begin
        plotxy,[[reform(pa2plots_odd[jthspec,1:-2])],[reform(pef2plots_odd[jthspec,1:-2])]],xrange=[-15.,185.],yrange=[1,max(pef2plots_odd[jthspec,1:-2])*1.5], ylog=1,$
          xsize=800.,ysize=500.,colors=['o'],title='dSectr2add='+string(dSectr2add,FORMAT='(I2)')+' dPhAng2add='+string(dPhAng2add,FORMAT='(f6.1)')+' odd='+string(ispecodd[jthspec],FORMAT='(I3)'),$
          thick=5,/noisotropic,psym=1,xmargin=[xmargin1,xmargin2]
        model_poly_full=10^poly(x2fit_full,coeffs)
        plots,xfit,result, psym=0
        plots,x2fit,y2fit, psym=4, SymSize=2.0
        ;plots,make_array(max(pef2plots_odd[jthspec,1:-2])*1.5,value=xpeak),indgen(max(pef2plots_odd[jthspec,1:-2])*1.5)
        plots,[xpeak,xpeak],[1,max(pef2plots_odd[jthspec,1:-2])*1.5]
        makepng,finalfolder+'/Isolu'+string(Isolu,format='(I1)')+'_Iters'+string(iters,format='(I1)')+'_'+string(ispecodd[jthspec],FORMAT='(I03)')
        ;stop
      endif
      pef2plots_odd[jthspec,*]=pef2plots_odd[jthspec,*]/ypeak
      pafitminus90_odd[jthspec]=xpeak-90.

      ;if fit_order eq 2 then pafitminus90_odd[jthspec]=-coeffs[1]/coeffs[2]/2.-90. $
      ;  else pafitminus90_odd[jthspec]=xfit(where(result eq ypeak))-90.
      ;  JWu
      ;yfit_odd=yfit_odd+result
      ;yfit_odd/=ypeak
      ;count_fits+=1
      yfit_odd=yfit_odd*count_fits/(count_fits+1)+result/ypeak/(count_fits+1)
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
  ;----------------------------------------------------------------------------------------
  ;Check for matching spin periods that have results for even or odd but not the other (shouldn't happen)
  if Isolu lt n_elements(iniSec) then begin
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
  endif


  ;plot
  ;window,1
  miny=3.e-3
  maxy=6.; 1.
  ;stop
  deltaPA_est=(average(pafitminus90_even(where(FINITE(pafitminus90_even))))-average(pafitminus90_odd(where(FINITE(pafitminus90_odd)))))/2.
  plotxy,[[reform(pa2plots_even[0,*])],[reform(pef2plots_even[0,*])]], $
    xrange=[-5.,185.],yrange=[miny,maxy],/ylog,/noisotropic, $
    xsize=800.,ysize=500.,psym=-2,colors=['r'], xmargin=[xmargin1,xmargin2],$
    title=' EPD Electrons EL-'+strupcase(probe)+', '+time_string(tstartendtimes4pa2plot[0])+' - '+strmid(time_string(tstartendtimes4pa2plot[1]),11,8)+ $
    ' UT, !c dSectr2add = '+strtrim(string(dSectr2add,format="(I7)"),1)+', dPhAng2add = '+strtrim(string(dPhAng2add,format="(f6.2)"),1)+'deg, dPA290_est='+string(deltaPA_est,format="(f6.1)")+'deg',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  plotxy,[[reform(pa2plots_odd[0,*])],[reform(pef2plots_odd[0,*])]],/over,psym=-1,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispeceven)-1 do plotxy,[[reform(pa2plots_even[jthspec,*])],[reform(pef2plots_even[jthspec,*])]],/over,psym=-1,colors=['r'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispeceven)-1 do plotxy,[[pafitminus90_even[jthspec]+90.,pafitminus90_even[jthspec]+90.],[0.2*maxy,maxy]],/over,colors=['r'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispecodd)-1 do plotxy,[[reform(pa2plots_odd[jthspec,*])],[reform(pef2plots_odd[jthspec,*])]],/over,psym=-1,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  for jthspec=0,n_elements(ispecodd)-1 do plotxy,[[pafitminus90_odd[jthspec]+90.,pafitminus90_odd[jthspec]+90.],[0.2*maxy,maxy]],/over,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  plotxy,[[xfit],[yfit_odd]],/over,colors=['o'],title=' ',linestyle=2,thick=5,yrange=[miny,maxy],xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  plotxy,[[xfit],[yfit_even]],/over,colors=['g'],title=' ',linestyle=2,thick=5,yrange=[miny,maxy],xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
  finalfile='/summary_Isolu'+string(Isolu,format='(I1)')+'_Iters'+string(iters,format='(I1)')
  makepng,finalfolder+finalfile
  
  avg_nonmonotonic_frac=(nonmonotonic_frac_odd+nonmonotonic_frac_even)/2.
  print,'Times=',time_string(tstartendtimes4pa2plot[0])+' - '+strmid(time_string(tstartendtimes4pa2plot[1]),11,8)+'UT,', $
    '    dPhAng2add=',dPhAng2add,'deg,   Tspin=',Tspin,'sec'
  print, 'Average fraction of spin periods w/ non-monotonic PAs:', avg_nonmonotonic_frac
  ;if avg_nonmonotonic_frac gt 0 then stop
  ;stop

  ; After checking if additional sector should be added, add the above estimate to dSectr2add and dPhAng2add,
  ; then re-run until deltaPA_est=0 or fit process reaches 10 iterations.
  ; NOTE: below code wouldn't work properly when multiple sectors should be added, or going from negative to positive phase (>= 11 deg diff)
  if finite(deltaPA_est) then begin   ; sometimes no fit results from this initial guess
    deltaPA_est = round(deltaPA_est*4)/4.
  endif else begin
    deltaPA_est = 0 ; if no fit results from this intial guess
  endelse

  if deltaPA_est eq 0 or iters gt maxiter then begin
    ;-------- end of iter ----------------
    if iters le maxiter then print, 'Max iterations reached; using latest result'
    print,'Final dSectr2add, dPhAng2add after ', iters-1, ' iterations:', dSectr2add, ' sectors, ', dPhAng2add, ' deg'
    PAfit_even_num[Isolu]=n_elements(where(FINITE(pafitminus90_even)))
    PAfit_odd_num[Isolu]=n_elements(where(FINITE(pafitminus90_odd)))
    LastIter[Isolu]=iters
    PAdiff[Isolu]=(average(pafitminus90_even(where(FINITE(pafitminus90_even))))-average(pafitminus90_odd(where(FINITE(pafitminus90_odd)))))/2.
    PAdSectr[Isolu]=dSectr2add
    PAdPhAng[Isolu]=dPhAng2add
    pafit_even_med[Isolu]=average(pafitminus90_even(where(FINITE(pafitminus90_even))))+90
    pafit_odd_med[Isolu]=average(pafitminus90_odd(where(FINITE(pafitminus90_odd))))+90
    PAeven_var[Isolu]=variance(pafitminus90_even(where(FINITE(pafitminus90_even))))
    PAodd_var[Isolu]=variance(pafitminus90_odd(where(FINITE(pafitminus90_odd))))
    
    angle_3points=45
    threepoints:
    even_3points=transpose(interp(transpose(pef2plots_even),transpose(pa2plots_even),[pafit_even_med[Isolu]-angle_3points,pafit_even_med[Isolu],pafit_even_med[Isolu]+angle_3points],/NO_CHECK_MONOTONIC,/NO_EXTRAPOLATE))
    odd_3points=transpose(interp(transpose(pef2plots_odd),transpose(pa2plots_odd),[pafit_odd_med[Isolu]-angle_3points,pafit_odd_med[Isolu],pafit_odd_med[Isolu]+angle_3points],/NO_CHECK_MONOTONIC,/NO_EXTRAPOLATE))
    ieven45=where(finite(even_3points[*,0]), jeven45) ; check whether pa=45 has data or not
    ieven135=where(finite(even_3points[*,2]), jeven135)
    iodd45=where(finite(odd_3points[*,0]), jodd45)
    iodd135=where(finite(odd_3points[*,2]), jodd135)
    if jeven45 eq 0 or jeven135 eq 0 or jodd45 eq 0 or jodd135 eq 0 then begin
      ; if one pa doesn't have data
      angle_3points=angle_3points-5
      if angle_3points ge 25 then goto,threepoints
    endif

    str2exec="store_data,'pef2plots_even_"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispeceven], y:pef2plots_even}"
    dummy=execute(str2exec)
    str2exec="store_data,'pa2plots_even_"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispeceven], y:pa2plots_even}"
    dummy=execute(str2exec)
    str2exec="store_data,'pef2plots_odd_"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispecodd], y:pef2plots_odd}"
    dummy=execute(str2exec)
    str2exec="store_data,'pa2plots_odd_"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispecodd], y:pa2plots_odd}"
    dummy=execute(str2exec)
    str2exec="store_data,'even_3points"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispeceven], y:even_3points}"
    dummy=execute(str2exec)
    str2exec="store_data,'odd_3points"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispecodd], y:odd_3points}"
    dummy=execute(str2exec)
    str2exec="store_data,'pafitminus90_even"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispeceven], y:pafitminus90_even}"
    dummy=execute(str2exec)
    str2exec="store_data,'pafitminus90_odd"+string(Isolu,format='(I1)')+"',data={x:elf_pef_pa_spec_times[ispecodd], y:pafitminus90_odd}"
    dummy=execute(str2exec)

  endif else if abs(dPhAng2add-deltaPA_est) gt angpersector/2 then begin ; calculate estimate in terms of additional sectors if needed (rest of code doesn't work with angles above 11)
    ;-------- iter continue ----------------
    if dPhAng2add-deltaPA_est lt 0 then begin
      dSectr2add-=1
      phase_shift=abs(deltaPA_est)-angpersector
    endif else begin
      dSectr2add+=1
      phase_shift=angpersector-abs(deltaPA_est)
    endelse
    dPhAng2add-=phase_shift
    ;if abs(dPhAng2add+deltaPA_est) lt 11 then begin
    ;  dPhAng2add=dPhAng2add+deltaPA_est
    ;  stop
    ;if abs(dPhAng2add-deltaPA_est) le 22 then begin
    ;  dSectr2add+=1
    ;  phase_shift = angpersector-abs(deltaPA_est)
    ;  dPhAng2add -= phase_shift
    ;endif else if abs(dPhAng2add-deltaPA_est) gt 22 then begin
    ;  dSectr2add+=2
    ;  phase_shift = angpersector*2-abs(deltaPA_est)
    ;  dPhAng2add -= phase_shift
    ;endif
    print, 'New dSectr2add, dPhAng2add from iteration ', iters, ':', dSectr2add, ' sectors, ', dPhAng2add, ' deg'
    ;stop
    ;    if abs(dPhAng2add) gt 11 then begin
    ;      ; edge case
    ;      skipfit=' '
    ;      print, 'edge case detected. skip fit? [y]'
    ;      read, skipfit
    ;      if skipfit eq 'y' then begin
    ;        badflag = 2
    ;        bad_comment = 'algorithm failed'
    ;        autobad = 1
    ;        ;iters = maxiter+1
    ;        goto, endoffits
    ;      endif
    ;
    ;      ;return
    ;      print, 'edge'
    ;    endif
    goto, FINDSHIFT
  endif else begin
    ;stop
    dPhAng2add += -1.*deltaPA_est
    print, 'New dSectr2add, dPhAng2add from iteration ', iters, ':', dSectr2add, ' sectors, ', dPhAng2add, ' deg'
    ;stop
    goto, FINDSHIFT
  endelse

  Isolu += 1
  if Isolu lt n_elements(iniSec) then goto, BODY   ; continue the initial sector loop

  ;
  ; ---------------------------------------------------------
  ;           end of inital guesss loop: isolu0-4
  ;           start skiptime on isolu5
  ; ---------------------------------------------------------

  if Isolu eq n_elements(iniSec) then begin
    ;-----------------select best solution-------------------
    ; if the solution doesn't have enough fit then nan
    index=where(PAfit_even_num le 2 or PAfit_odd_num le 2, count) 
    if count gt 0 then begin
      PAdSectr[index]=!VALUES.F_NAN
      PAdPhAng[index]=!VALUES.F_NAN
      PAdiff[index]=!VALUES.F_NAN
      PAeven_var[index]=!VALUES.F_NAN
      PAodd_var[index]=!VALUES.F_NAN
    endif
    

    index=where((PAfit_even_num+PAfit_odd_num) le median(PAfit_even_num+PAfit_odd_num)*0.1, count)
    if count gt 0 then begin
      PAdSectr[index]=!VALUES.F_NAN
      PAdPhAng[index]=!VALUES.F_NAN
      PAdiff[index]=!VALUES.F_NAN
      PAeven_var[index]=!VALUES.F_NAN
      PAodd_var[index]=!VALUES.F_NAN
    endif 
    
    ; if complementary solution exist choose the smaller angle
    dTotAng2add= PAdSectr*angpersector+PAdPhAng
    
    ; choose the min PAdiff solution
    ;costFun=abs(PAdiff) 
    alpha=0.3
    PAdiff_norm = (abs(PAdiff)-min(abs(PAdiff)))/(max(abs(PAdiff))-min(abs(PAdiff)))
    PAeven_var_norm = (PAeven_var-min(PAeven_var))/(max(PAeven_var)-min(PAeven_var))
    PAodd_var_norm = (PAodd_var-min(PAodd_var))/(max(PAodd_var)-min(PAodd_var))
    
    costFun= PAdiff_norm + alpha*(PAeven_var_norm + PAodd_var_norm)
    icostFun=sort(costFun)
    
    for i=0,n_elements(iniSec)-1 do begin
      imincostFun=icostFun[i]
      if finite(dTotAng2add[imincostFun]) eq 1 then begin
        icomplem=where(abs(dTotAng2add[imincostFun]-dTotAng2add) lt 185 and abs(dTotAng2add[imincostFun]-dTotAng2add) gt 175,jcomplem)
        case 1 of
          ;(jcomplem ge 1) and (abs(dTotAng2add[imincostFun]) le 90): begin ; has complementary solution, and this one is the smaller angle
          (jcomplem ge 1) and (dTotAng2add[imincostFun] ge 0): begin ; has complementary solution, and this one is the smaller angle
            dSectr2add= PAdSectr[imincostFun]
            dPhAng2add= PAdPhAng[imincostFun]
            goto,skiptime
          end
          (jcomplem eq 0): begin ; doesn't have complementary solution
            dSectr2add= PAdSectr[imincostFun]
            dPhAng2add= PAdPhAng[imincostFun]
            goto,skiptime
          end
          else: ; has complementary solution, and this one is the larger angle
        endcase
      endif
    endfor

    ;-------------------skiptime------------------------
    skiptime:
    str2exec="get_data,'pa2plots_even_"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    pa2plots_even=data.y
    str2exec="get_data,'pef2plots_even_"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    pef2plots_even=data.y
    str2exec="get_data,'pa2plots_odd_"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    pa2plots_odd=data.y
    str2exec="get_data,'pef2plots_odd_"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    pef2plots_odd=data.y
    str2exec="get_data,'even_3points"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    even_3points=data.y
    str2exec="get_data,'odd_3points"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    odd_3points=data.y
    str2exec="get_data,'pafitminus90_even"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    pafitminus90_even=data.y
    str2exec="get_data,'pafitminus90_odd"+string(imincostFun,format='(I1)')+"',data=data"
    dummy=execute(str2exec)
    pafitminus90_odd=data.y

    ;stop
    if median(elf_Br_sign.y) lt 0 then begin ; northern hemisphere
      evendiff_45_90=even_3points[*,1]-even_3points[*,0] ;90-45
      evendiff_90_135=even_3points[*,1]-even_3points[*,2] ;90-135
      ;even_ratio=evendiff_45_90/evendiff_90_135
      odddiff_45_90=odd_3points[*,1]-odd_3points[*,0] ;90-45
      odddiff_90_135=odd_3points[*,1]-odd_3points[*,2] ;90-135
      ;odd_ratio=odddiff_45_90/odddiff_90_135  ; prec/back
    endif else begin  ; southern hemisphere
      evendiff_45_90=even_3points[*,1]-even_3points[*,0] ;90-45
      evendiff_90_135=even_3points[*,1]-even_3points[*,2] ;90-135
      ;even_ratio=evendiff_90_135/evendiff_45_90
      odddiff_45_90=odd_3points[*,1]-odd_3points[*,0] ;90-45
      odddiff_90_135=odd_3points[*,1]-odd_3points[*,2] ;90-135
      ;odd_ratio=odddiff_90_135/odddiff_45_90 ; prec/back
    endelse

    plot,evendiff_45_90,evendiff_90_135,psym=2,yrange=[0,1.5],xrange=[0,1.5]
    plots,evendiff_45_90,evendiff_90_135,psym=2,color=240
    plots,odddiff_45_90,odddiff_90_135,psym=2,color=70
    oplot,findgen(16,start=0.,incre=0.1),findgen(16,start=0.,incre=0.1)+sqrt(2)*0.05,linestyle=0
    oplot,findgen(16,start=0.,incre=0.1),findgen(16,start=0.,incre=0.1)-sqrt(2)*0.05,linestyle=0
    oplot,findgen(16,start=0.,incre=0.1),findgen(16,start=0.,incre=0.1)+sqrt(2)*0.1,linestyle=1
    oplot,findgen(16,start=0.,incre=0.1),findgen(16,start=0.,incre=0.1)-sqrt(2)*0.1,linestyle=1
    oplot,findgen(16,start=0.,incre=0.1),findgen(16,start=0.,incre=0.1)+sqrt(2)*0.2,linestyle=2
    oplot,findgen(16,start=0.,incre=0.1),findgen(16,start=0.,incre=0.1)-sqrt(2)*0.2,linestyle=2
    makepng,finalfolder+'/gradient prec vs back'


    even_dis=abs(evendiff_45_90-evendiff_90_135)/sqrt(2)
    odd_dis=abs(odddiff_45_90-odddiff_90_135)/sqrt(2)
    ieven_skip=where((even_dis gt 0.1) or (finite(even_dis) eq 0), ieven_skip_count, COMPLEMENT=ieven_keep)  ; skip
    iodd_skip=where((odd_dis gt 0.1) or (finite(odd_dis) eq 0), iodd_skip_count, COMPLEMENT=iodd_keep)

    if n_elements(where(finite(even_dis[ieven_keep]))) lt 5 or n_elements(where(finite(odd_dis[iodd_keep]))) lt 5 then begin
      ieven_skip=where((even_dis gt 0.2) or (finite(even_dis) eq 0), ieven_skip_count, COMPLEMENT=ieven_keep)  ; skip
      iodd_skip=where((odd_dis gt 0.2) or (finite(odd_dis) eq 0), iodd_skip_count, COMPLEMENT=iodd_keep)
    endif

    ; isolu5 iters0: same as the best result with fewer lines
    if ieven_skip_count ne 0 then begin
      foreach jthspec, ieven_skip do begin
        pef2plots_even[jthspec,*]=!Values.F_NAN
        pafitminus90_even[jthspec]=!Values.F_NAN
      endforeach
    endif
    if iodd_skip_count ne 0 then begin
      foreach jthspec, iodd_skip do begin
        pef2plots_odd[jthspec,*]=!Values.F_NAN
        pafitminus90_odd[jthspec]=!Values.F_NAN
      endforeach
    endif

    deltaPA_est=(average(pafitminus90_even(where(FINITE(pafitminus90_even))))-average(pafitminus90_odd(where(FINITE(pafitminus90_odd)))))/2.
    plotxy,[[reform(pa2plots_even[0,*])],[reform(pef2plots_even[0,*])]], $
      xrange=[-5.,185.],yrange=[miny,maxy],/ylog,/noisotropic, $
      xsize=800.,ysize=500.,psym=-2,colors=['r'], xmargin=[xmargin1,xmargin2],$
      title=' EPD Electrons EL-'+strupcase(probe)+', '+time_string(tstartendtimes4pa2plot[0])+' - '+strmid(time_string(tstartendtimes4pa2plot[1]),11,8)+ $
      ' UT !c dSectr2add = '+strtrim(string(dSectr2add,format="(I7)"),1)+', dPhAng2add = '+strtrim(string(dPhAng2add,format="(f6.2)"),1)+'deg, dPA290_est='+string(deltaPA_est,format="(f6.1)")+'deg',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    plotxy,[[reform(pa2plots_odd[0,*])],[reform(pef2plots_odd[0,*])]],/over,psym=-1,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    for jthspec=0,n_elements(ispeceven)-1 do plotxy,[[reform(pa2plots_even[jthspec,*])],[reform(pef2plots_even[jthspec,*])]],/over,psym=-1,colors=['r'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    for jthspec=0,n_elements(ispeceven)-1 do plotxy,[[pafitminus90_even[jthspec]+90.,pafitminus90_even[jthspec]+90.],[0.2*maxy,maxy]],/over,colors=['r'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    for jthspec=0,n_elements(ispecodd)-1 do plotxy,[[reform(pa2plots_odd[jthspec,*])],[reform(pef2plots_odd[jthspec,*])]],/over,psym=-1,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    for jthspec=0,n_elements(ispecodd)-1 do plotxy,[[pafitminus90_odd[jthspec]+90.,pafitminus90_odd[jthspec]+90.],[0.2*maxy,maxy]],/over,colors=['b'],title=' ',xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    ;plotxy,[[xfit],[yfit_odd]],/over,colors=['o'],title=' ',linestyle=2,thick=5,yrange=[miny,maxy],xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    ;plotxy,[[xfit],[yfit_even]],/over,colors=['g'],title=' ',linestyle=2,thick=5,yrange=[miny,maxy],xtitle='PA [deg]',ytitle='nflux [#/(cm^2 s sr MeV)]'
    makepng,finalfolder+'/summary_Isolu5_Iters0_BestIsolu'+string(imincostFun,format='(I1)')
    
    
    ;n_elements(where(FINITE(pafitminus90_even)))+n_elements(where(FINITE(pafitminus90_odd)))
    if n_elements(where(finite(even_dis[ieven_keep])))+n_elements(where(finite(odd_dis[iodd_keep]))) gt 4 then begin  ;if after skip the remaining is enough
      iters=0
      skiptime=[]
      if ieven_skip_count ne 0 then foreach jthspec, ieven_skip do append_array,skiptime,reform(elf_pef_pa_spec_times_full[ispeceven[jthspec],*])
      if iodd_skip_count ne 0 then foreach jthspec, iodd_skip do append_array,skiptime,reform(elf_pef_pa_spec_times_full[ispecodd[jthspec],*])
      goto,FINDSHIFT
    endif else begin
      ; if skip too much, then do not fit again, use the current best fit as isolu=5, badflag=-2
;      finalfile='summary_Isolu'+string(imincostFun,format='(I1)')+'_Iters'+string(LastIter[imincostFun],format='(I1)')
;      PAdiff[Isolu]=PAdiff[imincostFun]
;      str2exec="get_data,'pafitminus90_even"+string(imincostFun,format='(I1)')+"',data=data"
;      dummy=execute(str2exec)
;      pafitminus90_even=data.y
;      str2exec="get_data,'pafitminus90_odd"+string(imincostFun,format='(I1)')+"',data=data"
;      dummy=execute(str2exec)
;      pafitminus90_odd=data.y
      iters=0
      skiptime=[]
      badflag=-2
      goto,FINDSHIFT
    endelse
  endif

  ;  move final plot to finalplot folder
  ;file_copy,finalfile+'.png','bestfit.png',/OVERWRITE
  ;cwd,cwdirname
  ;return
  ;-----------------------------------------------------------
  ;       end of fitting
  ;-----------------------------------------------------------

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

  ;check2 = total(n_elements(dat.tstart))
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FITS                                  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  endoffits: print, 'fits ended'
  
  ;PHASE DELAY CSV FILE ARCHIVING
  ; Read calibration (phase delay) file and store data
  file = 'el'+probe+'_epde_phase_delays_new.csv'
  filedata = read_csv(!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'+file, header = cols, types = ['String', 'String', 'Float', 'Float','Float','Float','Float','Float', 'String'])
  dat = CREATE_STRUCT(cols[0], filedata.field1, cols[1], filedata.field2, cols[2], filedata.field3, cols[3],  filedata.field4, cols[4], filedata.field5, cols[5], filedata.field6, cols[6], filedata.field7, cols[7], filedata.field8, cols[8], filedata.field9)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;make a copy of previous existing phase delay file, with date noted (akr)

  ;note current date
;  dateprev = time_string(systime(/seconds),format=2,precision=-3)
;  fileprev = 'el'+probe+'_epde_phase_delays_' + dateprev + '.csv'

  ;create folder for old pdp copies
;  cwdirnametemp=!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'
;  cd,cwdirnametemp
;  pdpprev_folder = 'pdpcsv_archive'
;  fileresult=file_search(pdpprev_folder)
;  if size(fileresult,/dimen) eq 0 then file_mkdir,pdpprev_folder

;  write_csv, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/pdpcsv_archive/'+ fileprev, filedata, header = cols

  ;return back to original directory
  cd, finalfolder
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;START OF MEDIAN CALCULATION                  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;MEDIANS WITH NANs, WILL BECOME OBSOLETE IN TIME {{{:
  Median_Calculation:
  starttimes = time_double(dat.tstart)
  angles = dat.dSectr2add*360./dat.SectNum+dat.dPhAng2add
  meds = dat.LatestMedianSectr*360./dat.SectNum+dat.LatestMedianPhAng
  badmeds= where(~finite(dat.LatestMedianPhAng))
  if badmeds[0] ne -1 then begin
    foreach nan, badmeds do begin

      int_end = starttimes[nan]
      int_start = int_end-3600.*24.*14.
      valid_items = where(starttimes ge int_start and starttimes le int_end and dat.badflag eq 0)
      current_median = median(angles[valid_items])

      if abs(current_median) gt 360./dat.SectNum[nan]*2.5 then begin
        dat.LatestMedianSectr[nan]=round(3*sign(current_median))
        dat.LatestMedianPhAng[nan]=current_median-3*360./dat.SectNum[nan]*sign(current_median)
      endif else if abs(current_median) gt 360./dat.SectNum[nan]*1.5 then begin
        dat.LatestMedianSectr[nan]=round(2*sign(current_median))
        dat.LatestMedianPhAng[nan]=current_median-2*360./dat.SectNum[nan]*sign(current_median)
      endif else if abs(current_median) gt 360./dat.SectNum[nan]*0.5 and abs(abs(current_median)-360./dat.SectNum[nan]) le 11 then begin
        dat.LatestMedianSectr[nan]=round(1*sign(current_median))
        dat.LatestMedianPhAng[nan]=current_median-360./dat.SectNum[nan]*sign(current_median)
      endif else if abs(current_median) le 360./dat.SectNum[nan]*0.5 then begin
        dat.LatestMedianSectr[nan] = 0
        dat.LatestMedianPhAng[nan] = current_median
      endif

      ;if abs(current_median) gt 11 and abs(abs(current_median)-angpersector) le 11 then begin
      ;  dat.LatestMedianSectr[nan]=round(1*sign(current_median))
      ;  dat.LatestMedianPhAng[nan]=current_median-angpersector*sign(current_median)
      ;endif else if abs(current_median) gt 34 then begin
      ;  dat.LatestMedianSectr[nan]=round(2*sign(current_median))
      ;  dat.LatestMedianPhAng[nan]=current_median-2*angpersector*sign(current_median)
      ;endif else if abs(current_median) gt 56.5 then begin
      ;  dat.LatestMedianSectr[nan]=round(3*sign(current_median))
      ;  dat.LatestMedianPhAng[nan]=current_median-3*angpersector*sign(current_median)
      ;endif else if abs(current_median) le 11 then begin
      ;  dat.LatestMedianSectr[nan] = 0
      ;  dat.LatestMedianPhAng[nan] = current_median
      ;endif
    endforeach

    if ~finite(dat.LatestMedianSectr[nan]) or ~finite(dat.LatestMedianPhAng[nan]) then begin
      dprint, 'Median failed'
      ;stop
    endif
  endif
  check3 = total(n_elements(dat.tstart))
  
  ;;;CURRENT MEDIAN
  if (probe eq 'a') and (time_double(tstart) gt time_double('2022-03-15/13:00:00')) and (time_double(tstart) lt time_double('2022-05-05/00:00:00')) then begin
    print,'skip comparing with median value due to setting change between 2022-03-15/13:00:00 and 2022-05-05/00:00:00 for ela\n'
    int_start = time_double('2022-03-15/13:00:00')
    int_end = time_double(tstart)
    valid_items = where(starttimes ge int_start and starttimes le int_end and dat.badflag eq 0)
    if valid_items[0] eq -1 then begin
      current_median = dSectr2add*angpersector+dPhAng2add
      placeholder_phase = current_median
    endif else begin
      current_median = median(angles[valid_items])
      placeholder_phase = current_median
    endelse  
  endif else begin
    if (probe eq 'a') and (time_double(tstart) gt time_double('2022-05-05/00:00:00')) and (time_double(tstart) lt time_double('2022-05-20/00:00:00')) then begin
      int_start = time_double('2022-05-05/00:00:00')
      int_end = time_double(tstart)
      valid_items = where(starttimes ge int_start and starttimes le int_end and dat.badflag eq 0)
      if valid_items[0] eq -1 then begin
        current_median = dSectr2add*angpersector+dPhAng2add
        placeholder_phase = current_median
      endif else begin
        current_median = median(angles[valid_items])
        placeholder_phase = current_median
      endelse    
    endif else begin
      int_end = time_double(tstart)
      median_range = 21. ;it will go back 7 days to find a new median
      int_start = int_end-3600.*24.*median_range
      valid_items = where(starttimes ge int_start and starttimes le int_end and dat.badflag eq 0)
      if valid_items[0] eq -1 then begin ; 30 days good fitting result not avaialble
        print, 'The phase delay procedure has stopped because there is no entry within the median range. Will use current value as median.
;        current_median = dSectr2add*angpersector+dPhAng2add
;        placeholder_phase = current_median
        valid_items = where(starttimes ge int_start and starttimes le int_end)
        if valid_items[0] eq -1 then begin ; if no median found, use current value
           current_median = dSectr2add*angpersector+dPhAng2add
           placeholder_phase = current_median
           if badflag ne 4 then badflag=-1 
        endif else begin; 30 days all fitting result avaialble
          current_median = median(angles[valid_items])
          placeholder_phase = current_median
        endelse
      endif else begin ; 30 days good fitting result avaialble
        current_median = median(angles[valid_items])
        placeholder_phase = current_median
      endelse
    endelse
  endelse

  elf_phase_delay_SectrPhAng, current_median, angpersector, LatestMedianSectr=LatestMedianSectr, LatestMedianPhAng=LatestMedianPhAng

  print, current_median
  ;print, latestmedianPhAng
  print, latestmedianSectr 

;stop
  if ~finite(LatestMedianSectr) or ~finite(LatestMedianPhAng) then begin
    print, 'Median failed'
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
  ; ---------------------------------------------------------------------------------
  ; determine flag
  ; -- badflag=-1 sus: phase delay angle is far away from median, export to csv
  ; -- badflag=-2 sus: no enough data for Isolu5, meaning no enough date are symmetric, export to csv
  ; -- badflag=-3 sus: fit peak is far away from 90 degree, export to csv
  ; -- badflag=-4 sus: variance of fit peak is too large, export to csv
  ; -- badflag=1 bad: fitting is not converge
  ; -- badflag=2 bad: no fit
  ; -- badflag=3 bad: bad fgm state
  ; -- badflag=4 bad: no able to run
  ; ---------------------------------------------------------------------------------
  ;stop
  ;
  ;note time that this value has been processed (and updated in the csv)
  timeofprocessing = time_string(systime(/seconds),format=0,precision=0)
  
  if badflag eq 4 then begin
    dSectr2add = LatestMedianSectr
    dPhAng2add = LatestMedianPhAng
    plot,[0,0],[0,0], title=' EPD Electrons EL-'+strupcase(probe)+', '+time_string(tstartendtimes4pa2plot[0])+' - '+strmid(time_string(tstartendtimes4pa2plot[1]),11,8)+ $
      ' UT'

    goto, writeCSV
  endif
  ; badflag=-1,-2,-3 sus, needs further check
  ; badflag=-1, large difference between median and current solution (1.5 sector=35 deg)
  if abs((dSectr2add*angpersector+dPhAng2add)-(LatestMedianSectr*angpersector+LatestMedianPhAng)) gt 35 then begin
    badFlag = -1
    ;dSectr2add=LatestMedianSectr
    ;dPhAng2add=LatestMedianPhAng
    ;stop
  endif

  ; badflag=-2, no enough data for Isolu=5, already defined in Line1406
  ; meaning no enough symmetric solutions around pa=90
;  if badflag eq -2 then begin
;    dSectr2add=LatestMedianSectr
;    dPhAng2add=LatestMedianPhAng
;  endif

  ; badflag=-3, fit peak is far away from 90 degree (12 deg)
  if undefined(pafitminus90_even) or undefined(pafitminus90_odd) then begin
     badFlag = -3 
  endif else begin 
    pafitminus90_even_mean=mean(abs(pafitminus90_even),/nan)
    pafitminus90_odd_mean=mean(abs(pafitminus90_odd),/nan)
    if abs(pafitminus90_even_mean) gt 12 or abs(pafitminus90_odd_mean) gt 12 then begin
      badFlag = -3
      ;dSectr2add=LatestMedianSectr
      ;dPhAng2add=LatestMedianPhAng
      ;stop
    endif
   endelse  
  ; badflag=-4, variance of fit peak is too large (15 deg)
  pafitminus90_even_std=stddev(abs(pafitminus90_even),/nan)
  pafitminus90_odd_std=stddev(abs(pafitminus90_odd),/nan)
  if ((pafitminus90_even_std gt 15) and (pafitminus90_odd_std gt 15)) then begin
    badFlag = -4
  endif

  ; badflag=1: not converge 
  if abs(PAdiff[5]) gt 1 then begin
    badFlag= 1
    dSectr2add=LatestMedianSectr
    dPhAng2add=LatestMedianPhAng
    ;stop
  endif

  ; badflag=2, no fit
  if n_elements(where(FINITE(pafitminus90_even))) lt 2 or n_elements(where(FINITE(pafitminus90_odd))) lt 2 then begin
    badFlag = 2
    dSectr2add=LatestMedianSectr
    dPhAng2add=LatestMedianPhAng
    ;stop
  endif
  
  ; badflag=3, bag fgm state
;  get_data,'el'+probe+'_pef_spinper',data=elf_pef_spinper
;  spin_med=median(elf_pef_spinper.y)
;  spin_var=variance(elf_pef_spinper.y)
;  spin_var=variance(elf_pef_spinper.y)/spin_med*100.
;  if spin_med lt 2.3 or spin_var/spin_med gt 0.1 then begin
;get_data, 'el'+probe+'_pef_spinper', data=spin
;spin_med=median(spin.y)
;spin_var=variance(spin.y)/spin_med*100.
;stop
  if spin_med lt 2.3 or spin_var gt 0.1 then begin
    badFlag = 3
    dSectr2add=LatestMedianSectr
    dPhAng2add=LatestMedianPhAng
    ;stop
  endif
  
  writeCSV:
  xyouts,  .1, .015, 'nspininsum = '+string(my_nspinsinsum2use[0],format='(I2)')+'  sectors = '+string(nspinsectors,format='(I2)'), /normal
  xyouts,  .55, .015, 'Created: '+systime()+ '   flag =' + string(badflag,FORMAT='(I2)'), /normal
  xyouts,  .81, 0.26, 'flag',/normal
  xyouts,  .81, 0.24, ' 0 good fit',/normal
  xyouts,  .81, 0.22, ' 1 bad: not converge',/normal
  xyouts,  .81, 0.20, ' 2 bad: no fit',/normal
  xyouts,  .81, 0.18, ' 3 bad: bad fgm state',/normal
  xyouts,  .81, 0.16, '-1 sus: far off median',/normal
  xyouts,  .81, 0.14, '-2 sus: not symmetric',/normal
  xyouts,  .81, 0.12, '-3 sus: fit peak off 90',/normal
  xyouts,  .81, 0.10, '-4 sus: peaks high var',/normal
  ;file_path= !elf.LOCAL_DATA_DIR + 'el' +probe+ '/phasedelayplots'
  cd, finalfolder
  makepng,finalfolder+'/bestfit'
;  stop
;  stop
  ;cwd,cwdirname
  ;stop
  ;print,'Average chi squared of fits from last iteration:', chisq_avg
  
  ; Re-write to file
  if autobad then phase_result = placeholder_phase else phase_result=dSectr2add*angpersector+dPhAng2add

  ; JWu comment start
  ;  if autobad eq 0 then begin
  ;    print,'Do you want to flag this result as bad (y)?'
  ;    incommand=' '
  ;    read,incommand
  ;    ;incommand = 'n'
  ;    bad_comment = ' '
  ;    if incommand eq 'y' then begin
  ;      badFlag=1
  ;      read, bad_comment
  ;      phase_result = placeholder_phase
  ;    endif
  ;  endif
  ; JWu comment end

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FIT ANALYSIS                          ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;START OF FILE FORMATTING                     ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  elf_mlt_l_lat,'el'+probe+'_pos_sm',MLT0=MLT0,L0=L0,lat0=lat0
;  get_data, 'el'+probe+'_pos_sm', data=elfin_pos
;  ;get_data, 'el'+probe+'_pef_nflux', data=pef_nflux
;  store_data,'el'+probe+'_MLAT_dip',data={x:elfin_pos.x,y:lat0*180./!pi}
;  get_data,'el'+probe+'_MLAT_dip',data=this_lat

  ; based on latitude and whether s/c is ascending or descending
  ; determine zone name
;  sz_name=''
;  if size(this_lat, /type) EQ 8 then begin ;change to num_scz?
;    sz_tstart=time_string(tstart)
;    sz_lat=this_lat.y
;    median_lat=median(sz_lat)
;    dlat = sz_lat[1:n_elements(sz_lat)-1] - sz_lat[0:n_elements(sz_lat)-2]
;    if median_lat GT 0 then begin
;      if median(dlat) GT 0 then sz_plot_lbl = ', North Ascending' else $
;        sz_plot_lbl = ', North Descending'
;      if median(dlat) GT 0 then sz_name = 'nasc' else $
;        sz_name = 'ndes'
;    endif else begin
;      if median(dlat) GT 0 then sz_plot_lbl = ', South Ascending' else $
;        sz_plot_lbl = ', South Descending'
;      if median(dlat) GT 0 then sz_name = 'sasc' else $
;        sz_name =  'sdes'
;    endelse
;    print, sz_name
;  endif
;stop
  ;find index where starttime should be
  valid_items = where(starttimes le time_double(tstart)+5.*60.)
  newindex = valid_items[-1]
  newentry = [string(time_string(tstart)), string(time_string(tend)), string(dSectr2add), string(dPhang2add), string(LatestMedianSectr), string(LatestMedianPhAng), string(badFlag), string(nspinsectors), string(timeofprocessing)]
;stop
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
    newdat = CREATE_STRUCT(cols[0], dat.(0), cols[1], dat.(1), cols[2], dat.(2), cols[3], dat.(3), cols[4], dat.(4), cols[5], dat.(5), cols[6], dat.(6), cols[7], dat.(7), cols[8], dat.(8))
    print, 'classified as repeat'

  endif else begin
    tstarts =  [dat.tstart, time_string(newentry[0])]
    tends =  [dat.tend, time_string(newentry[1])]
    dSectr2adds = [dat.dSectr2add, newentry[2]]
    dPhang2adds = [dat.dPhang2add, newentry[3]]
    LatestMedianSectrs = fix([dat.LatestMedianSectr, newentry[4]])
    LatestMedianPhAngs = [dat.LatestMedianPhAng,newentry[5]]
    badFlags = [dat.badFlag, newentry[6]]
    SectNum = [dat.SectNum, newentry[7]]
    proctimes = [dat.timeofprocessing, time_string(newentry[8])]
    
    newdat = CREATE_STRUCT(cols[0], tstarts, cols[1], tends, cols[2], dSectr2adds, cols[3], dPhAng2adds, cols[4], LatestMedianSectrs, cols[5], LatestMedianPhAngs, cols[6], badFlags, cols[7], SectNum, cols[8], proctimes)
    
    sorting = sort(tstarts)
    ;sorting = uniq(tstarts, sort(tstarts))

    for i = 0, n_elements(cols)-1 do begin
      newdat.(i) = newdat.(i)[sorting]
    endfor
    print, 'didnt classify as repeat'
  endelse

  ;note current date
;   dateprev = time_string(systime(/seconds),format=2,precision=-3)
;    dateprev=time_string(systime(/seconds),format=2,precision=-3)
;    dateprev=strmid(time_string(systime(/seconds),format=2,precision=3),0,15)
    thisdate=time_string(newentry[0], format=6)
    thisfile = 'el'+probe+'_epde_phase_delays_' + thisdate + '.csv'

  ;create folder for old pdp copies
;    cwdirnametemp=!elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/'
;    cd,cwdirnametemp
;    pdpprev_folder = 'pdpcsv_archive'
    cal_path = !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files'
    fileresult=file_search(cal_path)
    if size(fileresult,/dimen) eq 0 then file_mkdir,cal_path
    cd, cal_path
    pdpcsv_folder = cal_path + '/pdpcsv_archive'
    fileresult=file_search(pdpcsv_folder)
    if size(fileresult,/dimen) eq 0 then file_mkdir,pdpcsv_folder


    ;write_csv, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/pdpcsv_archive/'+ fileprev, filedata, header = cols
    dprint, 'Writing file: ' + !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/pdpcsv_archive/'+thisfile 
    print, newentry
    write_csv, !elf.LOCAL_DATA_DIR + 'el' +probe+ '/calibration_files/pdpcsv_archive/'+thisfile, newentry  ;, header = cols

  check5 = total(n_elements(tstarts))

  ;if check1-check2+check3-check4+check5-1 ne check1 then stop
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;END OF FILE FORMATTING                       ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;newdat = read_csv(file, N_TABLE_HEADER = 1)
  ;mask = uniq(time_double(newdat.field01), sort(time_double(newdat.field01)))
  ;close, /all
  ;JWu comment start
  ;  logentry = [string(tstart), string(tend), string(oldtimes_current[0]), string(oldtimes_current[1]), string(dSectr2add), string(dPhAng2add), strtrim(badFlag), strtrim(bad_comment)]
  ;  logentry = strjoin(logentry, ', ')
  ;  CD, 'epd_processing'
  ;  OPENW, 1, 'el'+probe+'_epd_processing_log.csv', /APPEND
  ;  PRINTF, 1, logentry
  ;  CD, '..'
  ;  ;entry = [oldtimes_current[0], oldtimes_current[1], chisq_avg, new_entry
  ;  ;oldtimes_start = [oldszs.field3, oldtimes_current[0]]
  ;  ;oldtimes_end = [oldszs.field4, oldtimes_current[1]]
  ;  CLOSE, 1
  ;  print, 'log entry: '
  ;  print, logentry
  ;JWu comment end
  ;stop

  ; Manually copy updated calibration file to server, if desired


end
