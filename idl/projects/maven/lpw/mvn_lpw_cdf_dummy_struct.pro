Function mvn_lpw_cdf_dummy_struct, var
  ;+
  ;Function, mvn_lpw_cdf_dummy_struct, var
  ;
  ; Original file was from SSL Berkeley, for creating CDF files from tplot variables. Original file edited by Chris Fowler from Oct 2013 onwards
  ; for use with the mvn_lpw_cdf software. This routine is within the mvn_lpw_cdf_write.pro routine and takes its inputs from there.
  ;
  ; Routine saves the plotting data, along with tplot dlimits and limits data, from a tplot variable, for saving as a CDF file.
  ;
  ; INPUTS:
  ; - vars: a string of the tplot variable in IDL memory to be saved as a CDF file. Only one variable at a time can be entered and saved.
  ;
  ; OUTPUTS:
  ; - A structure for the tplot variable suitable for saving as a CDF file. The save directory and save routine are input into mvn_lpw_cdf_write.pro.
  ;
  ; EXAMPLE:
  ; - mvn_lpw_cdf_dummy_struct, 'test1'   ;where 'test1' is a tplot variable saved in IDL memory.
  ;
  ; EDITS:
  ; - Through till Jan 7th 2014.
  ;
  ; ;Original file notes:
  ; Takes an array of tplot variables, creates a dummy CDF master
  ; structure, inserts data, returns structure suitable for output
  ;
  ;  Version 2.0
  ; ;140718 clean up for check out L. Andersson
  ; 2014-09-10: CF: added / fixed attributes after SIS review, based on ISTP requirements.
  ; 2014-09-11: CF: still adding ISTP requirements, made routine only accept one tplot variable at a time to simplify it. Major changes to structure
  ;                 format so that several time formats are carried through (UNIX, TT2000, MET). All CDF variables renamed here for easier interpretation
  ;                 in Autoplot. Names are reverted back to their tplot equivalents when reading the CDF file back into tplot.
  ;-

  otp_struct = -1  ;used later in code

  ;Check whether we have a line plot or spectrogram, as this determines the fields in the attribute structures:
  if size(var, /type) ne 7 then begin
    message, /info, '#### Input variable is not a string ####
    message, /info, 'Returning to terminal.'
    retall
  endif

  vj = strtrim(tnames(var),2)       ;be sure it's a string
  If(is_string(vj) Eq 0) Then Begin
    message, /info, '#### NO VARIABLE NAME ####: '+var ;tplot name isn't loaded into IDL memory
    message, /info, "#### Check tplot variable is loaded into memory. ####"
    retall
  Endif

  get_data, var, data = dd, dlimits = dl, limits = ll ;do limits = ll as well, for plot limits, titles, etc
  If(is_struct(dd) Eq 0) Then Begin
    message, /info, '#### data NOT A STRUCTURE ####: '+var
    message, /info, "#### Check tplot variable is loaded into memory. ####"
    retall
  Endif

  ;Check for line plot or spectrogram:
  if (tag_exist(dd, 'y') eq 1) and (tag_exist(dd, 'v') eq 0) then type = 1  ;line plot: y att needs depend_0 only. NOTE: some LPW line products will have a dy and dv, for errors in x and y directions.
  if (tag_exist(dd, 'y') eq 1) and (tag_exist(dd, 'v') eq 1) then type = 2  ;spectrogram: y and dy atts need depend_0 and depend_1; v att needs depend_0.
  if (tag_exist(dd, 'y') eq 0) then begin  ;no data, exit
    message, /info, "#### WARNING #### no data.y variabe present in the input tplot variable. Data is required to save as a CDF file. Returning."
    retall
  endif

  ;NOTE: we should always have UNIX time attached with the data. Print a warning if it's not found, but for now the routine will still complete:
  if tag_exist(dd, 'x') then has_unix = 1. else begin
    has_unix = 0.
    message, /info, "#### WARNING #### : UNIX time data not found with input tplot variable. This is required to create the CDF file. Returning."
    retall
  endelse
  if tag_exist(dd, 'MET') then has_met = 1. else begin
    has_met = 0.
    ;message, /info, "#### WARNING #### : UNIX time data not found with input tplot variable. This is required to create the CDF file. Returning."
  endelse

  ;For each variable, I need a variable attributes structure. Cannot have any '' blank strings as routine will crash when trying to save. Add a default value
  ;to each entry.
  ;In tplot, data.x and data.y are data and will have var_attributes.
  ;data.v will be energy steps (if present) and will be support data.

  ;The following are missing from var_atts (Case 1 and 2), awaiting final decision on inclusion:
  ;x_tt2000_catdesc:'xcatdesc', x_met_catdesc: 'xcatdesc', x_tt2000_Var_notes:'xVar_notes', x_met_Var_notes: 'xVar_notes'

  ;==========
  ;Change upper and lower limit variables names depending on variables being saved:
  ;wn: dfreq => ddata_up, ddata => ddata_lo
  ;lpnt: dfreq => ddata_lo, ddata => ddata_up
  ;lpic: dfreq => dvolt, freq => volt

  dfreq_lab = 'dfreq'
  ddata_lab = 'ddata'
  freq_lab = 'freq'

  if strmatch(var, '*w_n*', /fold_case) eq 1. then begin
    dfreq_lab = 'ddata_lo'
    ddata_lab = 'ddata_up'
  endif

  if strmatch(var, '*lp_n_t*', /fold_case) eq 1. then begin   ;Not needed for lp_nt
    dfreq_lab = 'ddata_lo'
    ddata_lab = 'ddata_up'
  endif

  if strmatch(var, '*lp_iv*', /fold_case) eq 1. then begin
    dfreq_lab = 'dvolt'
    freq_lab = 'volt'
  endif

  ;==========

  if type eq 1 then begin  ;only depend_0 required for y, dy and flag
    var_attributes = {tplot_name:'NA', product_name:'NA', catdesc:'NA', x_catdesc: 'NA',  $
      y_catdesc:'NA', v_catdesc:'NA', dy_catdesc:'NA', dv_catdesc:'NA', flag_catdesc:'NA', info_catdesc: 'NA', $
      depend_0:'depend_0', Display_type:'NA', $
      Fieldnam:'NA', xFieldnam:'NA', yFieldnam:'NA', vFieldnam:'NA', dyFieldnam:'NA', dvFieldnam:'NA', flagFieldnam:'NA', infofieldnam:'NA', $
      Fillval:!values.f_nan, Form_ptr:'form_ptr', Lablaxis:'NA', Monoton:'INCREASE', Scalemin:0., Scalemax:1., Units:'NA', Validmin:(-1.)*1.E38, Validmax:1.E38, $
      Var_type:'data', $
      Var_notes: 'NA', x_Var_notes: 'NA', y_Var_notes:'NA', v_Var_notes:'NA', dy_Var_notes:'NA', dv_Var_notes:'NA', flag_Var_notes:'NA', info_var_notes:'NA', $ ;end of ISTP var_attributes, begin additional LPW fields:
      info_info:'NA', t_epoch: 1.D, l0_datafile: 'L0_datafile', cal_vers:'NA', cal_y_const1:'NA', cal_y_const2:'NA', cal_datafile:'NA', $
      cal_source:'NA', flag_info:'NA', flag_source:'NA', xsubtitle:'NA', ysubtitle:'NA', zsubtitle:'NA', spec:0., ylog:0., cal_v_const1:'NA', $
      cal_v_const2:'NA', zlog:0., char_size: 1., xtitle:'NA', ytitle:'NA', yrange:[0.,1.], $
      ztitle:'NA', zrange:[0.,1.], labels:'NA', colors: '0', labflag: 0., noerrorbars:1., psym:0., no_interp:0., $
      Time_start:dblarr(7), Time_end:dblarr(7), Time_field:'NA', SPICE_kernel_version:'NA', $
      SPICE_kernel_flag: 'NA', derivn:'NA', sig_digits:'NA', SI_conversion:'NA'}

    yvar_attributes1 = {catdesc:'catdesc', depend_0:'depend_0', Display_type:'Display_type', Fieldnam:'Fieldnam', Fillval:!values.f_nan, $
      Form_ptr:'form_ptr', Lablaxis:'Lablaxis', Label:'Label', Monoton:'INCREASE', Scalemin:0., Scalemax:1., Units:'Units', Validmin:-1.E38, Validmax:1.E38, $
      Var_type:'Support_data', Var_notes: 'Var_notes', $ ;end of ISTP var_attributes, begin additional LPW fields:
      t_epoch: 1.D}

  endif else begin  ;depend_0 and _1 required for y and dy; depend_0 required for v and dv

    ;Both depends:
    var_attributes = {tplot_name:'NA', catdesc:'NA', x_catdesc: 'NA', $
      y_catdesc:'NA', v_catdesc:'NA', dy_catdesc:'NA', dv_catdesc:'NA', flag_catdesc:'NA', info_catdesc:'NA', $
      depend_0:'depend_0', depend_1: 'depend_1', Display_type:'NA', Fieldnam:'NA', xFieldnam:'NA', yFieldnam:'NA', vFieldnam:'NA', $
      dyFieldnam:'NA', dvFieldnam:'NA', flagFieldnam:'NA', infofieldnam:'NA', Fillval:!values.f_nan, $
      Form_ptr:'form_ptr', Lablaxis:'NA', Monoton:'INCREASE', Scalemin:0., Scalemax:1., Units:'NA', Validmin:(-1.)*1.E38, Validmax:1.E38, $
      Var_type:'data', Var_notes: 'NA', x_Var_notes: 'NA', $
      y_Var_notes:'NA', v_Var_notes:'NA', dy_Var_notes:'NA', dv_Var_notes:'NA', flag_Var_notes:'NA', info_var_notes:'NA', $ ;end of ISTP var_attributes, begin additional LPW fields:
      info_info:'NA', t_epoch: 1.D, l0_datafile: 'L0_datafile', cal_vers:'NA', cal_y_const1:'NA', cal_y_const2:'NA', cal_datafile:'NA', $
      cal_source:'NA', flag_info:'NA', flag_source:'NA', xsubtitle:'NA', ysubtitle:'NA', zsubtitle:'NA', spec:0., ylog:0., cal_v_const1:'NA', $
      cal_v_const2:'NA', zlog:0., char_size: 1., xtitle:'NA', ytitle:'NA', yrange:[0.,1.], $
      ztitle:'NA', zrange:[0.,1.], labels:'NA', colors: '0', labflag: 0., noerrorbars:1., psym:0., no_interp:0., $
      Time_start:dblarr(7), Time_end:dblarr(7), Time_field:'NA', SPICE_kernel_version:'NA', $
      SPICE_kernel_flag: 'NA', derivn:'NA', sig_digits:'NA', SI_conversion:'NA'}

    ;Depend:0:
    yvar_attributes1 = {catdesc:'catdesc', depend_0:'depend_0', Display_type:'Display_type', Fieldnam:'NA', Fillval:!values.f_nan, $
      Form_ptr:'form_ptr', Lablaxis:'Lablaxis', Monoton:'INCREASE', Scalemin:0., Scalemax:1., Units:'Units', Validmin:-1.E38, Validmax:1.E38, $
      Var_type:'Support_data', Var_notes: 'var_notes', $ ;end of ISTP var_attributes, begin additional LPW fields:
      t_epoch: 1.D}
    ;Both depends:
    yvar_attributes2 = {catdesc:'catdesc', depend_0:'depend_0', depend_1:'NA', Display_type:'Display_type', Fieldnam:'Fieldnam', Fillval:!values.f_nan, $
      Form_ptr:'form_ptr', Lablaxis:'Lablaxis', Monoton:'INCREASE', Scalemin:0., Scalemax:1., Units:'Units', Validmin:-1.E38, Validmax:1.E38, $
      Var_type:'Support_data', Var_notes: 'Var_notes',$ ;end of ISTP var_attributes, begin additional LPW fields:
      t_epoch: 1.D}

  endelse

  ;Attributes for data.x, the same regardless of whether line plot or spec:
  timevar_attributes = {catdesc:'catdesc', depend_0: 'depend_0', Display_type:'Display_type', Fieldnam:'Fieldnam', Fillval:!values.f_nan, $
    Form_ptr:'form_ptr', Lablaxis:'Lablaxis', Monoton:'INCREASE', Scalemin:0., Scalemax:1., Units:'Units', Validmin:-1.E38, Validmax:1.E38, $
    Var_type:'Support_data', Var_notes: 'Var_notes', $ ;end of ISTP var_attributes, begin additional LPW fields:
    t_epoch: 1.D}

  ;Instead of saving everything in var_attributes, save global attributes here:
  glob_attributes = {Product_name: 'Product_name', Project: 'Project', Discipline:'Discipline', data_type:'data type', Descriptor:'Descriptor', data_version:'data version', $
    Instrument_type:'Instrument Type', Logical_File_ID:'Logical file ID', Logical_source:'Logical Source', $
    Logical_source_description:'Logical source description', Mission_group:'Mission Group', PI_name:'PI name', PI_affiliation:'PI affiliation', $
    TEXT:'TEXT', Source_name:'Source name', Generated_by: 'Generated_by', Generation_date:'Generation date', Rules_of_use:'Rules of use', $
    Acknowledgement: 'Acknowledgement'}

  vars_struct = {name:'NA', num:0, is_zvar:1, datatype:'CDF_FLOAT', $
    type:4, numattr: -1, numelem: 1, recvary: 1b, $
    numrec:0L, ndimen: 0, d:lonarr(6), dataptr:ptr_new(), $
    attrptr:ptr_new()}

  ;One tplot variable has within it several data variables:
  ;data.x is the time variable, data.y is the data. If present: data.v is the energy channel (spec info), data.dy is the error info, data.dv is the energy error,
  ;data.flag is the flag info. We create vatt for data.y, vtatt for data.x, vdyatt for data.dy, vvatt for data.v, vdvatt for data.dv, vflagatt for data.flag

  ;data.x, data.v, data.dy, data.dv, data.flag are support data
  ;data.y is data


  ;flags for whether each variable has the appropriate tag
  has_v = 0.
  has_dv = 0.
  has_dy = 0.
  has_flag = 0.
  has_data = 0.
  has_info = 0.

  ;===================
  ;Attach attributes to arrays
  ;===================
  ;Not a whole lot of error checking here

  ;Create structures for present variables. Time and data.y assumed always present (routine won't get to here if they're not)
  glattr = glob_attributes  ;the same for either case

  ;structures for time variables
  vtatt = timevar_attributes   ;primary time variable in CDF is the CDF TT2000 time. This will be created from the UNIX times via Davin's time conversion routines.
  vmetatt = timevar_attributes  ;MET
  vunixatt = timevar_attributes   ;UNIX

  vstr = vars_struct  ;for var_atts
  vtstr = vars_struct ;structures for each variable
  vmetstr = vars_struct
  vunixstr = vars_struct

  has_data = 1  ;there's y data present (checked earlier)

  ;if has_tt2000 eq 1 then epoch = dd.tt2000 ;the CDF naming  convention is epoch for time.  ;this is calcualted later based on unix_time
  if has_unix eq 1 then time_unix = dd.x  ;UNIX time from data
  if has_met eq 1 then time_met = dd.met  ;MET

  data = dd.y   ;I've renamined the other data. fields to be easier to interpret in the CDF file. These will be converted back to the names
  ;required by tplot in our reader.
  ny = n_elements(data)  ;number of total y data points
  ny2 = n_elements(data[0, *]);number of energy bands, or frequencies, etc...

  dtime = 'epoch' ;'time_unix'   ;this is tt2000 time for CDF files, for which the variable name is 'epoch' for CDF files.
  if type eq 1 then begin
    ;structures for data variables
    vatt = var_attributes
    vatt.depend_0 = dtime
    vatt.tplot_name = var  ;save the name for which we want the tplot to have when we re-load the CDF file

    if (is_struct(dd) && tag_exist(dd, 'dy', /quiet)) then begin
      ddata = dd.dy

      ;Create structure:
      vdyatt = yvar_attributes1
      vdystr = vstr
      vdyatt.depend_0 = dtime
      has_dy = 1
    endif

    if (is_struct(dd) && tag_exist(dd, 'dv', /quiet)) then begin
      dfreq = dd.dv   ;this might not be dfreq in this case, but this is the array later code looks for

      ;Create structure:
      vdvatt = yvar_attributes1
      vdvstr = vstr
      vdvatt.depend_0 = dtime
      has_dv = 1
    endif

    if (is_struct(dd) && tag_exist(dd, 'flag', /quiet)) then begin
      ;Create structure:
      vflagatt = yvar_attributes1
      vflagstr = vstr
      vflagatt.depend_0 = dtime  ;flag errors depend on time
      has_flag = 1
      flag = dd.flag
    endif

    if (is_struct(dd) && tag_exist(dd, 'info', /quiet)) then begin
      ;Create structure:
      vinfoatt = yvar_attributes1
      vinfostr = vstr
      vinfoatt.depend_0 = dtime  ;info depends on time
      has_info = 1
      info = dd.info
    endif
  endif  ;assume no v and dv info for type 1

  if type eq 2 then begin
    ;structures for data variables
    vatt = var_attributes  ;depend_0 and _1 here
    vatt.depend_0 = dtime
    vatt.depend_1 = "freq"
    vatt.tplot_name = var

    if (is_struct(dd) && tag_exist(dd, 'dy', /quiet)) then begin
      ddata = dd.dy

      ;Create structure:
      vdyatt = yvar_attributes2  ;need depend_0 and _1 here
      vdystr = vstr
      vdyatt.depend_0 = dtime
      vdyatt.depend_1 = "freq"
      has_dy = 1
    endif

    if (is_struct(dd) && tag_exist(dd, 'flag', /quiet)) then begin
      ;Create structure:
      vflagatt = yvar_attributes1
      vflagstr = vstr
      vflagatt.depend_0 = dtime  ;flag errors depend on time
      has_flag = 1
      flag = dd.flag
    endif

    if (is_struct(dd) && tag_exist(dd, 'info', /quiet)) then begin
      ;Create structure:
      vinfoatt = yvar_attributes1
      vinfostr = vstr
      vinfoatt.depend_0 = dtime  ;info depends on time
      has_info = 1
      info = dd.info
    endif

    if (is_struct(dd) && tag_exist(dd, 'v', /quiet)) then begin
      freq = dd.v   ;LPW only produces wave power spectra, no energy spectra

      ;Create structure:
      vvatt = yvar_attributes1  ;only needs depend_0
      vvstr = vstr
      vvatt.depend_0 = dtime  ;spec freqs depend on time
      has_v = 1
    endif

    if (is_struct(dd) && tag_exist(dd, 'dv', /quiet)) then begin
      ;Create structures:
      vdvatt = yvar_attributes2  ;needs depend_0 and _1
      vdvstr = vstr
      vdvatt.depend_0 = dtime  ;errors for spec depend on time and freq for plotting
      vdvatt.depend_1 = "freq"
      has_dv = 1
      dfreq = dd.dv
    endif

  endif  ;type 2


  ;====================================
  ;Get information from tplot variable:
  ;====================================
  ;dlimit info:
  ;Required for cdf production. Most are not stored in vatt.
  ;These go to g_attributes:
  If (is_struct(dl)) THEN BEGIN

    IF tag_exist(dl, 'Product_name') THEN glattr.product_name = dl.Product_name
    IF tag_exist(dl, 'Project') THEN glattr.project = dl.Project
    IF tag_exist(dl, 'Discipline') THEN glattr.discipline = dl.Discipline
    IF tag_exist(dl, 'data_type') THEN glattr.data_type = dl.data_type
    IF tag_exist(dl, 'Descriptor') THEN glattr.descriptor = dl.Descriptor
    IF tag_exist(dl, 'data_version') THEN glattr.data_version = dl.data_version
    IF tag_exist(dl, 'Instrument_type') THEN glattr.instrument_type = dl.Instrument_type

    ;Logical fie info generated below:

    IF tag_exist(dl, 'Mission_group') THEN glattr.mission_group = dl.Mission_group
    IF tag_exist(dl, 'PI_name') THEN glattr.PI_name = dl.PI_name
    IF tag_exist(dl, 'PI_affiliation') THEN glattr.PI_Affiliation = dl.PI_affiliation
    IF tag_exist(dl, 'Source_name') THEN glattr.source_name = dl.Source_name
    IF tag_exist(dl, 'TEXT') THEN glattr.TEXT = dl.TEXT
    IF tag_exist(dl, 'Generated_by') THEN glattr.generated_by = dl.generated_by
    IF tag_exist(dl, 'Generation_date') THEN glattr.generation_date = dl.generation_date
    IF tag_exist(dl, 'Rules_of_use') THEN glattr.rules_of_use = dl.rules_of_use
    IF tag_exist(dl, 'Source_name') THEN glattr.Source_name = dl.Source_name
    If tag_exist(dl, 'Acknowledgement') THEN glattr.Acknowledgement = dl.Acknowledgement


    ;Display_type is generated within this CDF routine based on the data.
    ;Depend_0 etc are not needed in dlimits, just vatts for the CDF files
    IF tag_exist(dl, 'derivn') THEN vatt.derivn = dl.derivn
    IF tag_exist(dl, 'sig_digits') THEN vatt.sig_digits = dl.sig_digits
    IF tag_exist(dl, 'SI_conversion') THEN vatt.SI_conversion = dl.SI_conversion
    IF tag_exist(dl, 'x_tt2000_catdesc') THEN vatt.x_tt2000_catdesc = dl.x_tt2000_catdesc   ;These go to dlimits, catalog description of each variable
    IF tag_exist(dl, 'x_catdesc') THEN vatt.x_catdesc = dl.x_catdesc   ;These go to dlimits, catalog description of each variable
    IF tag_exist(dl, 'x_met_catdesc') THEN vatt.x_met_catdesc = dl.x_met_catdesc   ;These go to dlimits, catalog description of each variable
    IF tag_exist(dl, 'y_catdesc') THEN vatt.y_catdesc = dl.y_catdesc
    IF tag_exist(dl, 'v_catdesc') THEN vatt.v_catdesc = dl.v_catdesc
    IF tag_exist(dl, 'dy_catdesc') THEN vatt.dy_catdesc = dl.dy_catdesc
    IF tag_exist(dl, 'dv_catdesc') THEN vatt.dv_catdesc = dl.dv_catdesc
    IF tag_exist(dl, 'flag_catdesc') THEN vatt.flag_catdesc = dl.flag_catdesc
    IF tag_exist(dl, 'info_catdesc') THEN vatt.info_catdesc = dl.info_catdesc
    IF tag_exist(dl, 'x_tt2000_Var_notes') THEN vatt.x_tt2000_var_notes = dl.x_tt2000_Var_notes  ;Notes on each variable
    IF tag_exist(dl, 'x_Var_notes') THEN vatt.x_var_notes = dl.x_Var_notes  ;Notes on each variable
    IF tag_exist(dl, 'x_met_Var_notes') THEN vatt.x_met_var_notes = dl.x_met_Var_notes  ;Notes on each variable
    IF tag_exist(dl, 'y_Var_notes') THEN vatt.y_var_notes = dl.y_Var_notes
    IF tag_exist(dl, 'v_Var_notes') THEN vatt.v_var_notes = dl.v_Var_notes
    IF tag_exist(dl, 'dy_Var_notes') THEN vatt.dy_var_notes = dl.dy_Var_notes
    IF tag_exist(dl, 'dv_Var_notes') THEN vatt.dv_var_notes = dl.dv_Var_notes
    IF tag_exist(dl, 'flag_Var_notes') THEN vatt.flag_var_notes = dl.flag_Var_notes
    IF tag_exist(dl, 'info_Var_notes') THEN vatt.info_var_notes = dl.info_Var_notes
    If tag_exist(dl, 'xFieldnam') THEN vatt.xFieldnam = dl.xFieldnam
    If tag_exist(dl, 'yFieldnam') THEN vatt.yFieldnam = dl.yFieldnam
    If tag_exist(dl, 'vFieldnam') THEN vatt.vFieldnam = dl.vFieldnam
    If tag_exist(dl, 'dyFieldnam') THEN vatt.dyFieldnam = dl.dyFieldnam
    If tag_exist(dl, 'dvFieldnam') THEN vatt.dvFieldnam = dl.dvFieldnam
    If tag_exist(dl, 'flagFieldnam') THEN vatt.flagFieldnam = dl.flagFieldnam
    If tag_exist(dl, 'infoFieldnam') THEN vatt.infoFieldnam = dl.infoFieldnam
    If tag_exist(dl, 'Form_ptr') THEN vatt.Form_ptr = dl.Form_ptr
    If tag_exist(dl, 'Units') THEN vatt.Units = dl.Units
    IF tag_exist(dl, 'validmin') THEN vatt.validmin = dl.validmin
    IF tag_exist(dl, 'validmax') THEN vatt.validmax = dl.validmax
    IF tag_exist(dl, 'fillval') THEN vatt.fillval = dl.fillval
    IF tag_exist(dl, 'MONOTON') THEN vatt.MONOTON = dl.MONOTON
    IF tag_exist(dl, 'SCALEMIN') THEN vatt.SCALEMIN = dl.SCALEMIN
    IF tag_exist(dl, 'SCALEMAX') THEN vatt.SCALEMAX = dl.SCALEMAX
    IF (is_struct(ll) && tag_exist(ll, 'ytitle')) THEN vatt.lablaxis = ll.ytitle   ;ytitle is stored in limits
    IF tag_exist(dl, 'ysubtitle') THEN vatt.units = dl.ysubtitle   ;also units, stored as dl.units aswell
    IF tag_exist(dl, 'Var_type') THEN vatt.var_type = dl.Var_type
    IF tag_exist(dl, 'info_info') THEN vatt.info_info = dl.info_info
    ;End of cdf required fields

    ;SPICE times: we have up to 6 entries, but we may not have all 6 if we're archiving <L2 data:
    ;============
    ;SPICE fields need to be compressed from multiple element string arrays down to one string:
    IF tag_exist(dl, 'Time_start') THEN BEGIN
      nele_spice = n_elements(dl.time_start)
      vatt.time_start[0:nele_spice-1] = dl.time_start[0:nele_spice-1]  ;carry across times
      vatt.time_end[0:nele_spice-1] = dl.time_end[0:nele_spice-1]
      str_fields = strjoin(dl.time_field, '::', /single)
      vatt.time_field = str_fields[0]
    ENDIF ELSE BEGIN
      vatt.time_start[*] = !values.f_nan  ;default values if no times found
      vatt.time_end[*] = !values.f_nan
      vatt.time_field = 'WARNING: NO SPICE START / STOP TIMES FOUND.'
    ENDELSE
    ;============

    ;=============
    ;Generate Logical_file information:
    ;Logical_file_ID: source_name / data_type / descriptor / date / data_version
    ;Get date from dl.time_start[1]: take the first 8 characters which is yyyymmdd:
    date = strmid(dl.time_start[1], 0, 8)
    lfid = strtrim(glattr.Source_name,2)+'_'+strtrim(glattr.data_type,2)+'_'+strtrim(glattr.Descriptor,2)+'_'+strtrim(date,2)+'_'+strtrim(glattr.data_version,2)
    ls = strtrim(glattr.Source_name,2)+'_'+strtrim(glattr.data_type,2)+'_'+strtrim(glattr.Descriptor,2)
    ;level = 'Calibrated L2'  ;temp fix, put in case statement for L1a, L1b, L2 etc
    lsd = 'MAVEN Langmuir Probe and Waves data'

    glattr.logical_file_id = lfid
    glattr.logical_source = ls
    glattr.logical_source_description = lsd
    ;==============


    IF tag_exist(dl, 't_epoch') THEN vatt.t_epoch = dl.t_epoch
    ;Can't save a string array, so save time fields above as single strings, uncompress in cdf_read
    IF tag_exist(dl, 'SPICE_kernel_version') THEN vatt.SPICE_kernel_version = dl.SPICE_kernel_version
    IF tag_exist(dl, 'SPICE_kernel_flag') THEN vatt.SPICE_kernel_flag = dl.SPICE_kernel_flag
    IF tag_exist(dl, 'L0_datafile') THEN vatt.l0_datafile = dl.l0_datafile
    IF tag_exist(dl, 'cal_vers') THEN vatt.cal_vers = dl.cal_vers
    IF tag_exist(dl, 'cal_y_const1') THEN vatt.cal_y_const1 = dl.cal_y_const1
    IF tag_exist(dl, 'cal_y_const2') THEN vatt.cal_y_const2 = dl.cal_y_const2
    IF tag_exist(dl, 'cal_datafile') THEN vatt.cal_datafile = dl.cal_datafile
    IF tag_exist(dl, 'cal_source') THEN vatt.cal_source = dl.cal_source
    IF tag_exist(dl, 'flag_info') THEN vatt.flag_info = dl.flag_info
    IF tag_exist(dl, 'flag_source') THEN vatt.flag_source = dl.flag_source
    IF tag_exist(dl, 'xsubtitle') THEN vatt.xsubtitle = dl.xsubtitle
    IF tag_exist(dl, 'ysubtitle') THEN vatt.ysubtitle = dl.ysubtitle
    If tag_exist(dl, 'zsubtitle') THEN vatt.zsubtitle = dl.zsubtitle
    IF tag_exist(dl, 'cal_v_const1') THEN vatt.cal_v_const1 = dl.cal_v_const1
    IF tag_exist(dl, 'cal_v_const2') THEN vatt.cal_v_const2 = dl.cal_v_const2
    IF tag_exist(dl, 'zsubtitle') THEN vatt.zsubtitle = dl.zsubtitle

  ENDIF  ;dl exists

  ;Limit info:
  If (is_struct(ll)) THEN begin
    IF tag_exist(ll, 'char_size') THEN vatt.char_size = ll.char_size
    IF tag_exist(ll, 'xtitle') THEN vatt.xtitle = ll.xtitle
    IF tag_exist(ll, 'ytitle') THEN vatt.ytitle = ll.ytitle
    IF tag_exist(ll, 'ztitle') THEN vatt.ztitle = ll.ztitle
    IF tag_exist(ll, 'yrange') THEN vatt.yrange = ll.yrange
    IF tag_exist(ll, 'zrange') THEN vatt.zrange = ll.zrange
    IF tag_exist(ll, 'spec') THEN vatt.spec = ll.spec
    If tag_exist(ll, 'spec') && (ll.spec Eq 1) Then vatt.display_type = 'spectrogram' Else vatt.display_type = 'time_series' ;Spectrogram or line plot
    IF tag_exist(ll, 'ylog') THEN vatt.ylog = ll.ylog
    IF tag_exist(ll, 'zlog') THEN vatt.zlog = ll.zlog
    IF tag_exist(ll, 'noerrorbars') THEN vatt.noerrorbars = ll.noerrorbars
    IF tag_exist(ll, 'psym') THEN vatt.psym = ll.psym
    IF tag_exist(ll, 'no_interp') THEN vatt.no_interp = ll.no_interp
    ;========================
    ;Labels, colors, labflag:
    ;========================
    ;These are dealt with differently. As we don't know how many label elements will be present, compress to a single string, then
    ;uncompress this string when the CDF file is read again (this is done in the CDF read routine).
    IF tag_exist(ll, 'labels') THEN BEGIN
      ;If we have labels, need to compress them to one long string, then uncompress when re-loading from CDF to tplot.
      nele_lab = n_elements(ll.labels)
      IF nele_lab GE 1. THEN BEGIN
        strlabel = strjoin(ll.labels, '::', /single)  ;strings separated by '::'
        vatt.labels = strlabel[0]  ;make a string, not string array.
      ENDIf
    ENDIF
    IF tag_exist(ll, 'colors') THEN BEGIN
      ;If we have colors, compress into one string, then uncompress when re-loading from CDF to tplot. We dont know how many color elements we have
      ;hence the string compression.
      nele_color = n_elements(ll.colors)
      IF nele_color GE 1 then BEGIN
        strcolor = strjoin(ll.colors, '::', /single)  ;compress to single string, elements separated by '::'
        vatt.colors = strcolor[0]  ;make a string, not string array
      ENDIF
    ENDIF
    IF tag_exist(ll, 'labflag') THEN vatt.labflag = ll.labflag
    ;=======
  endif  ;over ll exists
  ;====================================

  ;==========================================
  ;The data attributes go in the vars_struct:
  ;==========================================
  ;This is the data, data.y in tplot:
  vstr.name = "data"   ;name of the data set (eg mvn_lpw_act_V1)
  vstr.num = n_elements(time_unix)  ;number of data points (in time)
  Case(size(data, /type)) Of        ;text code for type
    1: otp = 'CDF_UINT1'
    2: otp = 'CDF_INT2'
    3: otp = 'CDF_INT4'
    4: otp = 'CDF_FLOAT'
    5: otp = 'CDF_DOUBLE'
    7: otp = 'CDF_CHAR'
    12: otp = 'CDF_UINT2'
    13: otp = 'CDF_UINT4'
    14: otp = 'CDF_INT8'
    15: otp = 'CDF_UINT8'
    Else: otp = 'Undefined format'
  Endcase

  ;Attributes for data.y (depend atts already fixed earlier):
  vatt.FORM_PTR = otp
  vatt.catdesc = vatt.y_catdesc
  vatt.Var_notes = vatt.y_Var_notes
  vatt.Fieldnam = vatt.yFieldnam
  vstr.type = size(data, /type) ; number code for type
  vstr.ndimen = 1
  vstr.d[0] = n_elements(data[0,*])
  vstr.dataptr = ptr_new(data)   ;##### NOTE: you must add the pointers after adding everything to the structures. Anything added after the pointers will not
  ;be registered in the pointer and won't carry across.
  vstr.attrptr = ptr_new(vatt)  ;add attributes (vatt) to vars_struct (vstr)

  ;======================
  ;Now do time variables:
  ;======================
  ;Go through the 3 time types: data.tt2000 (CDF required), data.x (UNIX, for tplot), data.met (mission elapsed time)
  ;We will not carry TT2000 in our output tplot vars, it is produced here based on the UNIX times via Davin's time routines.

  utc_time = time_string(time_unix, precision=5)

  ;Need to replace '/' with 'T' in the utc string:
  for aa = 0, n_elements(utc_time)-1 do begin
    split = strsplit(utc_time[aa], '/', /extract)
    utc_time[aa] = split[0]+'T'+split[1]
  endfor

  ;time_tt2000 = cdf_parse_tt2000(utc_time)  ;OLD
  cdf_leap_second_init
  time_tt2000 = long64((add_tt2000_offset(time_unix) $
    - time_double('2000-01-01/12:00'))*1e9)
  has_tt2000 = 1.

  if has_tt2000 eq 1 then begin
    Case(size(time_tt2000, /type)) Of        ;text code for epoch
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase

    vtatt.depend_0 = "epoch"  ;must be called this for PDS, does time variable need a depend_0?
    vtatt.catdesc = "CDF TT2000 time."
    vtatt.Var_notes = "Calculated using Berkeley SSL IDL tplot package."   ;"Calculated using IDL8.3 'cdf_parse_tt2000' routine."
    vtatt.Fieldnam = 'NA'
    vtatt.Display_type = vatt.Display_type
    vtatt.Form_ptr = 'CDF_TIME_TT2000(33)  '  ;otp
    vtatt.Lablaxis = 'cdf TT2000 Time [secs]
    vtatt.Scalemin = min(time_tt2000, /nan)
    vtatt.Scalemax = max(time_tt2000, /nan)
    vtatt.Units = '[secs]'
    ;  vtatt.Validmin = Leave if we leave valid min/max at +-1.E38
    ;  vtatt.Validmax =

    vtstr.name = "epoch"  ;ISTP required
    vtstr.num = n_elements(time_tt2000)
    vtstr.datatype = 'CDF_TIME_TT2000'   ;NOTE: ISTP wanted CDF_TIME_TT2000(33), IDL doesn't like () in strings for structure creation
    vtstr.type = 5
    vtstr.ndimen = 1
    vtstr.d[0] = n_elements(time_tt2000[0,*])
    vtstr.dataptr = ptr_new(time_tt2000)
    vtstr.attrptr = ptr_new(vtatt)
  endif  ;tt2000

  if has_unix eq 1 then begin
    Case(size(time_unix, /type)) Of        ;text code for unix_time
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase
    vunixatt.depend_0 = 'time_unix'   ;is this needed?
    vunixatt.catdesc = vatt.x_catdesc
    vunixatt.Var_notes = vatt.x_Var_notes
    vunixatt.Fieldnam = vatt.xFieldnam
    vunixatt.Display_type = vatt.Display_type
    vunixatt.Form_ptr = otp
    vunixatt.Lablaxis = 'UNIX Time [secs]
    vunixatt.Scalemin = min(time_unix, /nan)
    vunixatt.Scalemax = max(time_unix, /nan)
    vunixatt.Units = '[secs]'
    ;  vtatt.Validmin = Leave if we leave valid min/max at +-1.E38
    ;  vtatt.Validmax =

    vunixstr.name = "time_unix"  ;has to be called this for Autoplot to find it
    vunixstr.num = n_elements(time_unix)
    vunixstr.datatype = 'CDF_DOUBLE'
    vunixstr.type = 5
    vunixstr.ndimen = 1
    vunixstr.d[0] = n_elements(time_unix[0,*])
    vunixstr.dataptr = ptr_new(time_unix)
    vunixstr.attrptr = ptr_new(vunixatt)
  endif  ;unix


  if has_met eq 1 then begin
    Case(size(time_met, /type)) Of        ;text code for met_time
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase
    vmetatt.depend_0 = 'time_met'   ;is this needed?
    vmetatt.catdesc = vatt.x_met_catdesc
    vmetatt.Var_notes = vatt.x_met_Var_notes
    vmetatt.Fieldnam = vatt.xFieldnam
    vmetatt.Display_type = vatt.Display_type
    vmetatt.Form_ptr = otp
    vmetatt.Lablaxis = 'MET [secs]
    vmetatt.Scalemin = min(time_met, /nan)
    vmetatt.Scalemax = max(time_met, /nan)
    vmetatt.Units = '[secs]'
    ;  vtatt.Validmin = Leave if we leave valid min/max at +-1.E38
    ;  vtatt.Validmax =

    vmetstr.name = "time_met"  ;has to be called this for Autoplot to find it
    vmetstr.num = n_elements(time_met)
    vmetstr.datatype = 'CDF_DOUBLE'
    vmetstr.type = 5
    vmetstr.ndimen = 1
    vmetstr.d[0] = n_elements(time_met[0,*])
    vmetstr.dataptr = ptr_new(time_met)
    vmetstr.attrptr = ptr_new(vmetatt)
  endif  ;MET


  ;==================================
  ;Add in other variables if present:
  ;==================================

  ;Now a v variable, if necessary. Need to ensure axis titles are now correct, as in tplot, data.y is the z variable.
  If(has_v Eq 1) Then Begin
    ;Correct data.y attributes to take into account a spectrogram:
    vatt.lablaxis = vatt.ztitle+" ["+vatt.zsubtitle+"]"
    vatt.Units = vatt.zsubtitle

    ;Attributes for v variable:
    vvatt.catdesc = vatt.v_catdesc
    vvatt.Var_notes = vatt.v_Var_notes
    vvatt.fieldnam = vatt.vFieldnam
    vvatt.Display_type = vatt.Display_type
    vvatt.lablaxis = vatt.ytitle+" ["+vatt.ysubtitle+"]"  ;data.v is the yaxis title for a spectrogram
    vvatt.Units = vatt.ysubtitle
    ;vars_struct
    vvstr.name = freq_lab  ;"freq"
    vvstr.num = n_elements(freq[*, 0])
    Case(size(freq, /type)) Of        ;text code for type
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase
    vvatt.FORM_PTR = otp
    vvstr.type = size(freq, /type)
    vvstr.ndimen = 1
    vvstr.d[0] = n_elements(freq[0, *])
    vvstr.dataptr = ptr_new(freq)
    vvstr.attrptr = ptr_new(vvatt)
  Endif


  ;Now an error variable for the data (DY)
  If(has_dy Eq 1) Then Begin
    ;Attributes
    vdyatt.catdesc = vatt.dy_catdesc
    vdyatt.Var_notes = vatt.dy_Var_notes
    vdyatt.fieldnam = vatt.dyFieldnam
    If(has_v Eq 1) Then vdyatt.depend_1 = "freq"
    vdyatt.lablaxis = vatt.ytitle+" ["+vatt.ysubtitle+"] "  ;For a line plot
    vdyatt.Units = vatt.ysubtitle
    ;Correct data.y attributes to take into account a spectrogram:
    if (has_v eq 1) then begin
      vdyatt.lablaxis = vatt.ztitle+" ["+vatt.zsubtitle+"]"
      vdyatt.Units = vatt.zsubtitle
    endif
    ;vars_struct
    vdystr.name = ddata_lab  ;'ddata'
    vdystr.num = n_elements(time_unix)
    Case(size(ddata, /type)) Of        ;text code for type
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase
    vdyatt.FORM_PTR = otp
    vdystr.type = size(ddata, /type)
    vdystr.ndimen = 1
    vdystr.d[0] = n_elements(ddata[0,*])
    vdystr.dataptr = ptr_new(ddata)
    vdystr.attrptr = ptr_new(vdyatt)
  Endif

  ;Now a V error variable
  If(has_dv Eq 1) Then Begin
    ;Attributes
    vdvatt.catdesc = vatt.dv_catdesc
    vdvatt.Var_notes = vatt.dv_Var_notes
    vdvatt.fieldnam = vatt.dvFieldnam
    vdvatt.lablaxis = vatt.ytitle + " ["+vatt.ysubtitle+"] "
    vdvatt.Units = vatt.ysubtitle
    ;vars_struct
    vdvstr.name = dfreq_lab  ;'dfreq'
    vdvstr.num = n_elements(dfreq[*, 0])
    Case(size(dfreq, /type)) Of        ;text code for type
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase
    vdvatt.FORM_PTR = otp
    vdvstr.type = size(dfreq, /type)
    vdvstr.ndimen = 1
    vdvstr.d[0] = n_elements(dfreq[0, *])
    vdvstr.dataptr = ptr_new(dfreq)
    vdvstr.attrptr = ptr_new(vdvatt)
  Endif

  ;flag variable
  If(has_flag Eq 1) Then Begin
    ;Attributes
    vflagatt.catdesc = vatt.flag_catdesc
    vflagatt.Var_notes = vatt.flag_Var_notes
    vflagatt.fieldnam = vatt.flagFieldnam
    vflagatt.lablaxis = 'flag'
    vflagatt.Units = 'flag'
    ;vars_struct
    vflagstr.name = 'flag'
    vflagstr.num = n_elements(flag[*, 0])
    Case(size(flag, /type)) Of        ;text code for type
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase
    vflagatt.FORM_PTR = otp
    vflagstr.type = size(flag, /type)
    vflagstr.ndimen = 1
    vflagstr.d[0] = n_elements(flag[0, *])
    vflagstr.dataptr = ptr_new(flag)
    vflagstr.attrptr = ptr_new(vflagatt)
  Endif

  ;info variable
  If(has_info Eq 1) Then Begin
    ;Attributes
    vinfoatt.catdesc = vatt.info_catdesc
    vinfoatt.Var_notes = vatt.info_Var_notes
    vinfoatt.fieldnam = vatt.infoFieldnam
    vinfoatt.lablaxis = 'info'
    vinfoatt.Units = 'info'
    ;vars_struct
    vinfostr.name = 'info'
    vinfostr.num = n_elements(info[*, 0])
    Case(size(info, /type)) Of        ;text code for type
      1: otp = 'CDF_UINT1'
      2: otp = 'CDF_INT2'
      3: otp = 'CDF_INT4'
      4: otp = 'CDF_FLOAT'
      5: otp = 'CDF_DOUBLE'
      7: otp = 'CDF_CHAR'
      12: otp = 'CDF_UINT2'
      13: otp = 'CDF_UINT4'
      14: otp = 'CDF_INT8'
      15: otp = 'CDF_UINT8'
      Else: otp = 'Undefined format'
    Endcase
    vinfoatt.FORM_PTR = otp
    vinfostr.type = size(info, /type)
    vinfostr.ndimen = 1
    vinfostr.d[0] = n_elements(info[0, *])
    vinfostr.dataptr = ptr_new(info)
    vinfostr.attrptr = ptr_new(vinfoatt)
  Endif

  ;==========  Over attaching attributes

  keep_data = where(has_data Eq 1, vc)

  If(vc Gt 0) Then Begin
    ;allvars = [vstr[keep_data], vtstr[keep_data]]
    allvars = [vstr[keep_data]]
    keep_tt2000 = where(has_tt2000 eq 1, nkeep)  ;tt2000 time
    if (nkeep gt 0) then allvars = [allvars, vtstr[keep_tt2000]]
    keep_unix = where(has_unix eq 1, nkeep)  ;UNIX type
    if (nkeep gt 0) then allvars = [allvars, vunixstr[keep_unix]]
    keep_met = where(has_met eq 1, nkeep)  ;MET type
    if (nkeep gt 0) then allvars = [allvars, vmetstr[keep_met]]
    keep_v = where(has_v Eq 1, nkeep)   ;if we have a 'v' value
    If(nkeep Gt 0) Then allvars = [allvars, vvstr[keep_v]]
    keep_dv = where(has_dv Eq 1, nkeep)   ;if we have a 'dv' value
    If(nkeep Gt 0) Then allvars = [allvars, vdvstr[keep_dv]]
    keep_dy = where(has_dy Eq 1, nkeep)   ;if we have a 'dy' value
    If(nkeep Gt 0) Then allvars = [allvars, vdystr[keep_dy]]
    keep_flag = where(has_flag Eq 1, nkeep) ;if we have a flag variable
    If(nkeep Gt 0) Then allvars = [allvars, vflagstr[keep_flag]]
    keep_info = where(has_info Eq 1, nkeep) ;if we have a info variable
    If(nkeep Gt 0) Then allvars = [allvars, vinfostr[keep_info]]

    nvars = n_elements(allvars)

    global_att = glattr

    natts = n_tags(global_att)+n_tags(var_attributes)

    inq = {ndims:0l, decoding:'HOST_DECODING', $
      encoding:'NETWORK_ENCODING', $
      majority:'ROW_MAJOR', maxrec:-1,$
      nvars:0, nzvars:nvars, natts:natts, dim:lonarr(1)}
    otp_struct = {filename:'', g_attributes:global_att, inq:inq, nv:nvars, vars:allvars}
  Endif Else Begin
    message, /info, 'No Non-composite tplot variables'
    otp_struct = 1
  Endelse

  Return, otp_struct
End

