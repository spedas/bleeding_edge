pro psp_fld_example_tds
  compile_opt defint32

  ; @my_colors.inc

  print, 'IDL version ', !version.release, ' running on ', !version.os_name, ' on ', systime()

  StartString = '2020-05-27'

  my_YYYY = strmid(StartString, 0, 4)
  my_MM = strmid(StartString, 5, 2)
  my_DD = strmid(StartString, 8, 2)
  my_YYYYMMDD = my_YYYY + my_MM + my_DD

  my_CDF_Volume = '/Volumes/mySpace/'
  my_CDF_branch = 'PSP/SOC/UMN/'
  my_CDF_path = 'l2/TDS_WF/'
  my_CDF_YYYYMM = my_YYYY + '/' + my_MM + '/'
  my_CDF_filename = 'psp_fld_l2_tds_wf_' + my_YYYYMMDD + '_v00'
  my_CDF_filetype = '.cdf'

  my_CDF_filespec = my_CDF_Volume + my_CDF_branch + my_CDF_path + my_CDF_YYYYMM + my_CDF_filename + my_CDF_filetype

  ; ;
  ; ;		..let's see if there's an existing CDF and open it up if so
  ; ;

  if file_test(my_CDF_filespec, /Read) then begin
    print, " It looks like the desired L2 TDS WF CDF file is actually there!"
    print, " It is >", my_CDF_filespec, "<"
  endif else begin
    print, " It looks like the desired L2 TDS WF CDF file NOT there!"
    print, " Tried for >", my_CDF_filespec, "<"

    print, " Try loading with SPEDAS"
    timespan, StartString

    psp_fld_load, type = 'tds_wf', files = tds_wf_file, /no_load

    my_CDF_filespec = tds_wf_file[0]

    if file_test(my_CDF_filespec, /Read) eq 0 then begin
      print, " Unable to download file with SPEDAS"
      stop, 'Sad...'
    endif
  endelse

  print, "Let's open it..."
  print, "             ...open the L2 TDS WF CDF named ", my_CDF_filename
  CDFid = cdf_open(my_CDF_filespec)
  if n_elements(CDFid) le 0 then begin
    help, CDFid
    print, n_elements(CDFid), format = "(' CDFid has this many elements: ', i10, ' which should be 1.')"
    print, "We can't seem to open the named CDF and so we're stuck."
    stop, 'STOP - no blank CDF'
  endif
  if CDFid le 0 then begin
    help, CDFid
    print, n_elements(CDFid), format = "(' with N elements: ',i10)"
    print, CDFid, format = "('  and in hex: ',Z20)"
    print, CDFid
    ErrorString = cdf_error(CDFid)
    print, ErrorString
    print, "We got back a negative CDFid but maybe we should just plow ahead anyhow."
  endif

  ; ;
  ; ;		..first get the basic variables for this CDF file - they don't really vary by record
  ; ;

  cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_N_Bursts_Today", N_Bursts
  cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_N_Samples_per_Channel_MAX", N_MAX, REC_START = 0, REC_COUNT = 1

  print, "Ok, we have opened the CDF and it seems to contain ", N_Bursts, ". multi-channel bursts for the day."
  print

  for i = 0, N_Bursts - 1 do begin
    ; ;
    ; ;		..now get some of the simple variables/scalers that vary only by record
    ; ;

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_ID", Burst_ID, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Quality", Burst_Q, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Start_Time_UR8", Burst_SCET, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Version", Burst_FSW, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Type_Name", Burst_Type, REC_START = i, REC_COUNT = 1, /STRING
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_N_Samples_per_Channel", Burst_Nsamples, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_N_Samples_per_Channel_MAX", Burst_NsamplesMAX, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Start_Time_UR8", Burst_Start_SCET, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Start_Time_ASCII", Burst_Start_String, REC_START = i, REC_COUNT = 1, /STRING

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Sample_Speed", Burst_SPS, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Sample_Period", Burst_Sample_Period, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Period", Burst_Period, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Low_Pass_Filters_Match_Flag", Burst_LPF_Match, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Low_Pass_Filter", Burst_LPF_Ch1, REC_START = i, REC_COUNT = 1

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Trigger_Source_Name", Burst_Trigger, REC_START = i, REC_COUNT = 1, /STRING
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Trigger_Threshold_Engineering_mV", Burst_Threshold_mV, REC_START = i, REC_COUNT = 1
    ; CDF_VARGET, CDFid, "PSP_FLD_L2_TDS_WF_Trigger_Threshold_Engineering_nT",Burst_Threshold_nT,	REC_START=i,	REC_COUNT=1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Trigger_Position", Burst_Position, REC_START = i, REC_COUNT = 1
    Burst_Position = Burst_Position * 1000.

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_DFB_Bursting_Flag", Burst_DFB_too, REC_START = i, REC_COUNT = 1

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_TM_Xmit_Sequence_Number", Burst_Xmit_N, REC_START = i, REC_COUNT = 1

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Saturation_Flag", Burst_TDS_Sat, REC_START = i, REC_COUNT = 1

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SWEAP_Status", Burst_SWP_Status, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SWEAP_Ion_Mask", Burst_SWP_ion_Mask, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SWEAP_Electron_Mask", Burst_SWP_e_Mask, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SWEAP_Start", Burst_SWP_Time, REC_START = i, REC_COUNT = 1

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_DFB_Voltages_Valid_Flag", Burst_DFB_V_ok, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_DFB_Voltage_V1", Burst_DFB_V1, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_DFB_Voltage_V2", Burst_DFB_V2, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_DFB_Voltage_V3", Burst_DFB_V3, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_DFB_Voltage_V4", Burst_DFB_V4, REC_START = i, REC_COUNT = 1

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SC_Reaction_Wheel_Speeds_Valid_Flag", Burst_RWA_ok, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SC_Reaction_Wheel_Speed_RW1", Burst_RW1, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SC_Reaction_Wheel_Speed_RW2", Burst_RW2, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SC_Reaction_Wheel_Speed_RW3", Burst_RW3, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_SC_Reaction_Wheel_Speed_RW4", Burst_RW4, REC_START = i, REC_COUNT = 1

    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_All_Channels_Exist_Flag", Burst_Exists_ALL, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SWEAP_Exists_Flag", Burst_Exists_SWEAP, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1_Exists_Flag", Burst_Exists_V1, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V2_Exists_Flag", Burst_Exists_V2, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V3_Exists_Flag", Burst_Exists_V3, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V4_Exists_Flag", Burst_Exists_V4, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V5_Exists_Flag", Burst_Exists_V5, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1V2_Exists_Flag", Burst_Exists_V1V2, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V3V4_Exists_Flag", Burst_Exists_V3V4, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1234_Exists_Flag", Burst_Exists_V1234, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SCM4_Exists_Flag", Burst_Exists_SCM4, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SCM5_Exists_Flag", Burst_Exists_SCM5, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SCM4LG_Exists_Flag", Burst_Exists_SCM4LG, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1LG_Exists_Flag", Burst_Exists_V1LG, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V2LG_Exists_Flag", Burst_Exists_V2LG, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V3LG_Exists_Flag", Burst_Exists_V3LG, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V4LG_Exists_Flag", Burst_Exists_V4LG, REC_START = i, REC_COUNT = 1
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V5LG_Exists_Flag", Burst_Exists_V5LG, REC_START = i, REC_COUNT = 1
    ; ;
    ; ;		..now get some of the burst time-series variables
    ; ;
    ; ;		..Bobby says to try it this way - VARget only what you need - no copying or trimming needed - obvious enough if it works
    ; ;			it is the case that one need not define the fltarr first
    ; ;
    cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_Times", Burst_WF_Times, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    Burst_WF_Times = Burst_WF_Times * 1000.
    ; ;
    ; ;		..here we clear the graphical channels to start a fresh burst
    ; ;		..we do not need to create these variables but we're trying to clear them from one burst to the next
    ; ;		..in particular, we do NOT need to make the time series data arrays
    ; ;			the call to CDF_VARGET makes them and sizes them and types them as needed
    ; ;			so I make trivial place holders to start them fresh
    ; ;		..as we get the burst time series data, CDF_VARGET puts them into local variables
    ; ;			these local variables are simply named for the six TDS channel numbers [0 thru 5]
    ; ;
    Burst_Exists_Ch0 = 0l
    Burst_Exists_Ch1 = 0l
    Burst_Exists_Ch2 = 0l
    Burst_Exists_Ch3 = 0l
    Burst_Exists_Ch4 = 0l
    Burst_Exists_Ch5 = 0l
    Burst_Path_Ch0 = 'N/A'
    Burst_Path_Ch1 = 'N/A'
    Burst_Path_Ch2 = 'N/A'
    Burst_Path_Ch3 = 'N/A'
    Burst_Path_Ch4 = 'N/A'
    Burst_Path_Ch5 = 'N/A'
    Burst_WF_Ch0 = fltarr(2)
    Burst_WF_Ch1 = fltarr(2)
    Burst_WF_Ch2 = fltarr(2)
    Burst_WF_Ch3 = fltarr(2)
    Burst_WF_Ch4 = fltarr(2)
    Burst_WF_Ch5 = fltarr(2)
    Burst_WF_Ch0[*] = !values.f_nan
    Burst_WF_Ch1[*] = !values.f_nan
    Burst_WF_Ch2[*] = !values.f_nan
    Burst_WF_Ch3[*] = !values.f_nan
    Burst_WF_Ch4[*] = !values.f_nan
    Burst_WF_Ch5[*] = !values.f_nan

    if Burst_Exists_SWEAP ne 0 then begin
      Burst_Exists_Ch0 = 1l
      Burst_Path_Ch0 = 'SWEAP'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SWEAP_Counts", Burst_WF_Ch0, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V1 ne 0 then begin
      Burst_Exists_Ch1 = 1l
      Burst_Path_Ch1 = 'V1'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1_Engineering_mV", Burst_WF_Ch1, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V2 ne 0 then begin
      Burst_Exists_Ch2 = 1l
      Burst_Path_Ch2 = 'V2'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V2_Engineering_mV", Burst_WF_Ch2, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V3 ne 0 then begin
      Burst_Exists_Ch3 = 1l
      Burst_Path_Ch3 = 'V3'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V3_Engineering_mV", Burst_WF_Ch3, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V4 ne 0 then begin
      Burst_Exists_Ch4 = 1l
      Burst_Path_Ch4 = 'V4'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V4_Engineering_mV", Burst_WF_Ch4, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V5 ne 0 then begin
      Burst_Exists_Ch5 = 1l
      Burst_Path_Ch5 = 'V5'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V5_Engineering_mV", Burst_WF_Ch5, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V1LG ne 0 then begin
      Burst_Exists_Ch3 = 1l
      Burst_Path_Ch3 = 'V1LG'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1LG_Engineering_mV", Burst_WF_Ch3, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V2LG ne 0 then begin
      Burst_Exists_Ch5 = 1l
      Burst_Path_Ch5 = 'V2LG'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V2LG_Engineering_mV", Burst_WF_Ch5, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V3LG ne 0 then begin
      Burst_Exists_Ch1 = 1l
      Burst_Path_Ch1 = 'V3LG'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V3LG_Engineering_mV", Burst_WF_Ch1, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V4LG ne 0 then begin
      Burst_Exists_Ch2 = 1l
      Burst_Path_Ch2 = 'V4LG'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V4LG_Engineering_mV", Burst_WF_Ch2, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V5LG ne 0 then begin
      Burst_Exists_Ch4 = 1l
      Burst_Path_Ch4 = 'V5LG'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V5LG_Engineering_mV", Burst_WF_Ch4, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V1V2 ne 0 then begin
      Burst_Exists_Ch3 = 1l
      Burst_Path_Ch3 = 'V1V2'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1V2_Engineering_mV", Burst_WF_Ch3, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V3V4 ne 0 then begin
      Burst_Exists_Ch1 = 1l
      Burst_Path_Ch1 = 'V3V4'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V3V4_Engineering_mV", Burst_WF_Ch1, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_V1234 ne 0 then begin
      Burst_Exists_Ch2 = 1l
      Burst_Path_Ch2 = 'V1234'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_V1234_Engineering_mV", Burst_WF_Ch2, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_SCM4 ne 0 then begin
      Burst_Exists_Ch4 = 1l
      Burst_Path_Ch4 = 'SCM4'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SCM4_Engineering_mV", Burst_WF_Ch4, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_SCM5 ne 0 then begin
      Burst_Exists_Ch5 = 1l
      Burst_Path_Ch5 = 'SCM5'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SCM5_Engineering_mV", Burst_WF_Ch5, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    if Burst_Exists_SCM4LG ne 0 then begin
      Burst_Exists_Ch4 = 1l
      Burst_Path_Ch4 = 'SCM4LG'
      cdf_varget, CDFid, "PSP_FLD_L2_TDS_WF_Burst_Time_Series_SCM4LG_Engineering_mV", Burst_WF_Ch4, COUNT = Burst_Nsamples, REC_START = i, REC_COUNT = 1
    endif
    ; ;
    ; ;		..and finally, with all the CDF data in hand, we could make some plots or what not
    ; ;			but first we do some graphics setup but just the once
    ; ;
    if i eq 0 then begin
      windowTitle = 'TDS all (Level-2)'
      window, 0, xsize = 640, ysize = 1280, title = windowTitle
      wset, 0
      !p.font = -1
      if n_elements(white) ne 0 then !p.background = white
      if n_elements(black) ne 0 then !p.color = black
      !y.range = [0, 0]
      !x.style = 1
      !p.multi = [0, 1, 6]
    endif
    wait, 1. ; ;wait a little to let IDL and X-11 calm down

    EvTitle = string(Burst_ID, format = "('Burst # ',i0,'.')")

    XaxisTitle = "Time (ms)"

    ; ;panel 1 (top)
    if Burst_Exists_Ch1 ne 0 then begin
      YaxisTitle = Burst_Path_Ch1 + " (mV)"
      YaxisTitle = strcompress(YaxisTitle)
      plot, Burst_WF_Times, Burst_WF_Ch1, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle
      oplot, Burst_WF_Times, Burst_WF_Ch1, color = black, psym = 3
    endif else begin
      YaxisTitle = "Null Ch1"
      plot, Burst_WF_Times, Burst_WF_Ch1, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle, YRange = [-100., 100.]
      myPlaceX = !x.crange(0) + (!x.crange(1) - !x.crange(0)) / 2.
      myPlaceY = !y.crange(0) + (!y.crange(1) - !y.crange(0)) / 2.
      line = 'No data for this channel'
      xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1.5, Alignment = .5
    endelse

    ; ;panel 2
    if Burst_Exists_Ch2 ne 0 then begin
      YaxisTitle = Burst_Path_Ch2 + " (mV)"
      YaxisTitle = strcompress(YaxisTitle)
      plot, Burst_WF_Times, Burst_WF_Ch2, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle
      oplot, Burst_WF_Times, Burst_WF_Ch2, color = black, psym = 3
    endif else begin
      YaxisTitle = "Null Ch2"
      plot, Burst_WF_Times, Burst_WF_Ch2, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle, YRange = [-100., 100.]
      myPlaceX = !x.crange(0) + (!x.crange(1) - !x.crange(0)) / 2.
      myPlaceY = !y.crange(0) + (!y.crange(1) - !y.crange(0)) / 2.
      line = 'No data for this channel'
      xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1.5, Alignment = .5
    endelse
    line = string(Burst_SWP_ion_Mask, format = "('SWP ion mask:',Z9.8)")
    myPlaceX = !x.crange(0)
    myPlaceY = !y.crange(1) + (!y.crange(1) - !y.crange(0)) * (2. / 100.)
    if Burst_DFB_too eq 0 then begin
      xyouts, myPlaceX, myPlaceY, "noDFB", color = black, Charsize = 1, Alignment = 0.
    endif else begin
      xyouts, myPlaceX, myPlaceY, "DFB bursting!", color = red, Charsize = 1, Alignment = 0.
    endelse

    ; ;panel 3
    if Burst_Exists_Ch3 ne 0 then begin
      YaxisTitle = Burst_Path_Ch3 + " (mV)"
      YaxisTitle = strcompress(YaxisTitle)
      plot, Burst_WF_Times, Burst_WF_Ch3, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle
      oplot, Burst_WF_Times, Burst_WF_Ch3, color = black, psym = 3
    endif else begin
      YaxisTitle = "Null Ch3"
      plot, Burst_WF_Times, Burst_WF_Ch3, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle, YRange = [-100., 100.]
      myPlaceX = !x.crange(0) + (!x.crange(1) - !x.crange(0)) / 2.
      myPlaceY = !y.crange(0) + (!y.crange(1) - !y.crange(0)) / 2.
      line = 'No data for this channel'
      xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1.5, Alignment = .5
    endelse

    ; ;panel 4
    if Burst_Exists_Ch4 ne 0 then begin
      YaxisTitle = Burst_Path_Ch4 + " (mV)"
      if Burst_Path_Ch4 eq "SCM4" then begin
        YaxisTitle = Burst_Path_Ch4 + " (nT)"
      endif
      if Burst_Path_Ch4 eq "SCM4LG" then begin
        YaxisTitle = Burst_Path_Ch4 + " (nT)"
      endif
      YaxisTitle = strcompress(YaxisTitle)
      plot, Burst_WF_Times, Burst_WF_Ch4, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle
      oplot, Burst_WF_Times, Burst_WF_Ch4, color = black, psym = 3
    endif else begin
      YaxisTitle = "Null Ch4"
      plot, Burst_WF_Times, Burst_WF_Ch4, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle, YRange = [-100., 100.]
      myPlaceX = !x.crange(0) + (!x.crange(1) - !x.crange(0)) / 2.
      myPlaceY = !y.crange(0) + (!y.crange(1) - !y.crange(0)) / 2.
      line = 'No data for this channel'
      xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1.5, Alignment = .5
    endelse

    ; ;panel 5
    if Burst_Exists_Ch5 ne 0 then begin
      YaxisTitle = Burst_Path_Ch5 + " (mV)"
      if Burst_Path_Ch4 eq "SCM5" then begin
        YaxisTitle = Burst_Path_Ch5 + " (nT)"
      endif
      YaxisTitle = strcompress(YaxisTitle)
      plot, Burst_WF_Times, Burst_WF_Ch5, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle
      oplot, Burst_WF_Times, Burst_WF_Ch5, color = black, psym = 3
    endif else begin
      YaxisTitle = "Null Ch5"
      plot, Burst_WF_Times, Burst_WF_Ch5, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle, YRange = [-100., 100.]
      myPlaceX = !x.crange(0) + (!x.crange(1) - !x.crange(0)) / 2.
      myPlaceY = !y.crange(0) + (!y.crange(1) - !y.crange(0)) / 2.
      line = 'No data for this channel'
      xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1.5, Alignment = .5
    endelse

    ; ;panel 6 (bottom)
    if Burst_Exists_Ch0 ne 0 then begin
      YaxisTitle = "SWEAP (Counts)"
      plot, Burst_WF_Times, Burst_WF_Ch0, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle, YRange = [0., 5.]
      oplot, Burst_WF_Times, Burst_WF_Ch0, color = black, psym = 0
      if max(Burst_WF_Ch0) eq 0 then begin
        myPlaceX = !x.crange(0) + (!x.crange(1) - !x.crange(0)) / 2.
        myPlaceY = !y.crange(0) + (!y.crange(1) - !y.crange(0)) / 2.
        line = 'All zeroes!'
        xyouts, myPlaceX, myPlaceY, line, color = red, Charsize = 1.5, Alignment = .5
      endif
    endif else begin
      YaxisTitle = "Null SWEAP"
      plot, Burst_WF_Times, Burst_WF_Ch0, /NOdata, /YNOzero, charsize = 2, title = EvTitle, xTitle = XaxisTitle, yTitle = YaxisTitle, YRange = [0., 5.]
      myPlaceX = !x.crange(0) + (!x.crange(1) - !x.crange(0)) / 2.
      myPlaceY = !y.crange(0) + (!y.crange(1) - !y.crange(0)) / 2.
      line = 'No data for this channel'
      xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1.5, Alignment = .5
    endelse
    line = string(Burst_SWP_Time * 1000., format = "('SWEAP sweep',f20.1,' ms ago')")
    line = strcompress(line)
    myPlaceX = !x.crange(0)
    myPlaceY = !y.crange(1) + (!y.crange(1) - !y.crange(0)) * (2. / 100.)
    xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1, Alignment = 0.
    count_N = total(Burst_WF_Ch0)
    count_rate = double(count_N) / (Burst_WF_Times[Burst_Nsamples - 1] / 1000.d)
    line = string(count_rate, format = "('SWEAP Count Rate ',f10.1,' (p/s)')")
    line = strcompress(line)
    myPlaceX = !x.crange(0)
    myPlaceY = !y.crange(1) + (!y.crange(1) - !y.crange(0)) * (10. / 100.)
    xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1, Alignment = 0.
    line = string(count_N, format = "('SWEAP Count: ',i0)")
    myPlaceX = !x.crange(0)
    myPlaceY = !y.crange(1) + (!y.crange(1) - !y.crange(0)) * (18. / 100.)
    xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1, Alignment = 0.
    line = string(Burst_SWP_Status, format = "('SWP Status:', Z9.8)")
    myPlaceX = !x.crange(1)
    myPlaceY = !y.crange(1) + (!y.crange(1) - !y.crange(0)) * (18. / 100.)
    xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1, Alignment = 1.
    line = string(Burst_SWP_e_Mask, format = "('SWP e mask:',Z9.8)")
    myPlaceX = !x.crange(1)
    myPlaceY = !y.crange(1) + (!y.crange(1) - !y.crange(0)) * (10. / 100.)
    xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1, Alignment = 1.
    line = string(Burst_SWP_ion_Mask, format = "('SWP ion mask:',Z9.8)")
    myPlaceX = !x.crange(1)
    myPlaceY = !y.crange(1) + (!y.crange(1) - !y.crange(0)) * (2. / 100.)
    xyouts, myPlaceX, myPlaceY, line, color = black, Charsize = 1, Alignment = 1.

    if Burst_Type eq 'Quality ' then xyouts, .003, .985, "Q", color = green, Charsize = 2, /normal
    if Burst_Type eq 'Honesty ' then xyouts, .003, .985, "H", color = blue, Charsize = 2, /normal
    if Burst_Type eq 'Promptly' then xyouts, .003, .985, "P", color = red, Charsize = 2, /normal

    if Burst_Q lt 1000000000 then begin
      line = string(Burst_Q, format = "('Q: ',i0)")
    endif else begin
      line = "Q: 1M+"
    endelse
    if Burst_Q eq Burst_ID then begin
      line = '    Q: Event#'
    endif
    xyouts, .990, .990, line, color = black, Charsize = 1.5, Alignment = 1., /normal

    line = string(Burst_Xmit_N, format = "('TMseq: ',i0,'.')")
    xyouts, .975, .005, line, color = black, charsize = 1.333, Alignment = 1., /normal
    xyouts, .010, .005, Burst_Start_String + ' (UTC start)', color = black, charsize = 1.333, Alignment = 0., /normal

    print, i, Burst_Start_String, Burst_ID, Burst_Q, Burst_Xmit_N, Burst_Nsamples, Burst_SPS, format = "(i5,'.  Start time (UTC) ',a,'   ',i10,i10,i10,i10,f13.1)"

    ; wait, 1.
  endfor

  print
  print, "Closing our CDF file now."
  cdf_close, CDFid

  stop, 'all done!'
end
