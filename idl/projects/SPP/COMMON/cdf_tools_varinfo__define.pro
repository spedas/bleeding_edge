;+
; Written by Davin Larson October 2018
; $LastChangedBy: ali $
; $LastChangedDate: 2021-12-18 02:19:05 -0800 (Sat, 18 Dec 2021) $
; $LastChangedRevision: 30472 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/cdf_tools_varinfo__define.pro $
;-

function cdf_tools_varinfo::variable_attributes, vname,value
  dlevel =3
  fnan = !values.f_nan
  dnan = !values.d_nan
  dprint,dlevel=dlevel,'Creating variable attributes for: ',vname
  att = orderedhash()
  if ~isa(vname,/string) then return,att
  ;  Create default value place holders
  EPOCHname = 'Epoch'
  att['CATDESC']     = vname          ;required for all variables: (catalog description) is an approximately 80-character string which is a textual description of the variable and includes a description of what the variable depends on. This information needs to be complete enough that users can select variables of interest based only on this value.
  att['FIELDNAM']    = vname          ;required for all variables: holds a character string (up to 30 characters) which describes the variable. It can be used to label a plot either above or below the axis, or can be used as a data listing heading. Therefore, consideration should be given to the use of upper and lower case letters where the appearance of the output plot or data listing heading will be affected.
  att['LABLAXIS']    = vname          ;required if not using LABL_PTR_1: should be a short character string (approximately 10 characters, but preferably 6 characters - more only if absolutely required for clarity) which can be used to label a y-axis for a plot or to provide a heading for a data listing.
  att['UNITS']       = ' '            ;required if not using UNIT_PTR (optional for time variables): is a character string (no more than 20 characters, but preferably 6 characters) representing the units of the variable,e.g., nT for magnetic field. If the standard abbreviation used is short then the units value can be added to a data listing heading or plot label. Use a blank character, rather than "None" or "unitless", for variables that have no units (e.g., a ratio or a direction cosine). For CDF_TIME_TT2000: SI measurement unit: s, ms(milliseconds for EPOCH variables), ns(nanoseconds for CDF_TIME_TT2000), ps(picoseconds for EPOCH16).
  att['VAR_TYPE']    = 'support_data' ;required for all variables:  identifies a variable as either (data): integer or real numbers that are plottable (support_data): integer or real "attached" variables (metadata): labels or character variables (ignore_data): placeholders.
  att['DISPLAY_TYPE']= 'time_series'  ;required for data variables: tells automated software what type of plot to make and what associated variables in the CDF are required in order to do so. Some valid values are listed below: time_series spectrogram stack_plot image no_plot.
  att['DEPEND_0']    = EPOCHname      ;required for time-varying variables: explicitly ties a data variable to the time variable on which it depends. All variables which change with time must have a DEPEND_0 attribute defined. The value of DEPEND_0 is 'Epoch', the time ordering parameter for ISTP/IACG. Different time resolution data can be supported in a single CDF data set by defining the variables Epoch, Epoch_1, Epoch_2, etc. each representing a different time resolution. These are "attached" appropriately to the variables in the CDF data set via the attribute DEPEND_0. The value of the attribute must be a variable in the same CDF data set.
  att['DEPEND_1']    = ''             ;required for dimensional variables as shown in table above. (1D time series data variables do not need a DEPEND_1 defined.) ties a dimensional data variable to a support_data variable on which the i-th dimension of the data variable depends. The number of DEPEND attributes must match the dimensionality of the variable, i.e., a one-dimensional variable must have a DEPEND_1, a two-dimensional variable must have a DEPEND_1 and a DEPEND_2 attribute, etc. The value of the attribute must be a variable in the same CDF data set.
  att['FORMAT']      = 'E12.4'        ;required if not using FORM_PTR: is the output format used when extracting data values out to a file or screen (using CDFlist). The magnitude and the number of significant figures needed should be carefully considered. A good check is to consider it with respect to the values of VALIDMIN and VALIDMAX attributes. The output should be in Fortran format.
  att['FILLVAL']     = fnan           ;required for time varying variables: is the number inserted in the CDF in place of data values that are known to be bad or missing. Fill data are always non-valid data. The ISTP standard fill values are listed below. Fill values are automatically supplied in the ISTP CDHF ICSS environment (ICSS_KP_FILL_VALUES.INC) for key parameters produced at the CDHF. The FILLVAL data type must match the data type of the variable.
  att['VALIDMIN']    = -1e30          ;required for time varying data and support_data: hold values which are, respectively, the minimum and maximum values for a particular variable that are expected over the lifetime of the mission. The values must match the data type of the variable.
  att['VALIDMAX']    = 1e30           ;ditto.
  att['SCALETYP']    = 'linear'       ;recommended for non-linear scales if not using SCAL_PTR: indicates whether the variable should have a linear or a log scale as a default. If this attribute is not present, linear scale is assumed.
  att['DICT_KEY']    = ''             ;optional: comes from a data dictionary keyword list and describes the variable to which it is attached. The ISTP/IACG standard dictionary keyword list is described in ISTP/IACG Dictionary Keywords.
  att['MONOTON']     = ''             ;optional: Indicates whether the variable is monotonically increasing or monotonically decreasing. Use of MONOTON is strongly recommended for the Epoch time variable, and can significantly increase the performance speed on retrieval of data. Valid values: INCREASE, DECREASE.

  case strupcase(vname) of
    'EPOCH': begin
      att['CATDESC']     = 'Time at middle of sample'
      att['FIELDNAM']    = 'Time in TT2000 format'
      att['LABLAXIS']    = EPOCHname
      att['UNITS']       = 'ns'
      att['FORMAT']      = 'F24.1'
      ;att['FILLVAL']    = -1LL
      att['FILLVAL']     = -9223372036854775808
      att['VALIDMIN']    = -315575942816000000
      att['VALIDMAX']    = 946728068183000000
      att['DICT_KEY']    = 'time>Epoch'
      att['MONOTON']     = 'INCREASE'
    end
    'TIME': begin
      att['CATDESC']     = 'Time at middle of sample'
      att['FIELDNAM']    = 'Time in UTC format'
      att['LABLAXIS']    = 'Unix Time'
      att['UNITS']       = 's'
      att['FORMAT']      = 'F24.7'
      att['FILLVAL']     = dnan
      att['VALIDMIN']    = time_double('2010')
      att['VALIDMAX']    = time_double('2100')
      att['DICT_KEY']    = 'time>UTC'
      att['MONOTON']     = 'INCREASE'
    end
    'ENERGY': begin
      att['CATDESC']     = 'Energy'
      att['FIELDNAM']    = 'Energy'
      att['LABLAXIS']    = 'Energy'
      att['UNITS']       = 'eV'
      att['VALIDMIN']    = 0.01
      att['VALIDMAX']    = 1e5
      att['SCALETYP']    = 'log'
    end
    'ENERGY_VALS': begin
      att['CATDESC']     = 'Energy'
      att['FIELDNAM']    = 'Energy'
      att['LABLAXIS']    = 'Energy'
      att['UNITS']       = 'eV'
      att['VALIDMIN']    = 0.01
      att['VALIDMAX']    = 1e5
      att['SCALETYP']    = 'log'
    end
    'THETA': begin
      att['CATDESC']     = 'Elevation Angle in instrument coordinates'
      att['FIELDNAM']    = 'Instrument Theta'
      att['LABLAXIS']    = 'Elevation Angle'
      att['UNITS']       = 'Degrees'
      att['VALIDMIN']    = -90.
      att['VALIDMAX']    = 90.
    end
    'THETA_VALS': begin
      att['CATDESC']     = 'Elevation Angle in instrument coordinates'
      att['FIELDNAM']    = 'Instrument Theta'
      att['LABLAXIS']    = 'Elevation Angle'
      att['UNITS']       = 'Degrees'
      att['VALIDMIN']    = -90.
      att['VALIDMAX']    = 90.
    end
    'PHI': begin
      att['CATDESC']     = 'Azimuth Angle in instrument coordinates'
      att['FIELDNAM']    = 'Instrument Phi'
      att['LABLAXIS']    = 'Azimuth Angle'
      att['UNITS']       = 'Degrees'
      att['VALIDMIN']    = -180.
      att['VALIDMAX']    = 360.
    end
    'PHI_VALS': begin
      att['CATDESC']     = 'Azimuth Angle in instrument coordinates'
      att['FIELDNAM']    = 'Instrument Phi'
      att['LABLAXIS']    = 'Azimuth Angle'
      att['UNITS']       = 'Degrees'
      att['VALIDMIN']    = -180.
      att['VALIDMAX']    = 360.
    end
    'PITCHANGLE': begin
      att['CATDESC']     = 'Electron Pitch Angle'
      att['FIELDNAM']    = 'Pitch Angle'
      att['LABLAXIS']    = 'Pitch Angle'
      att['UNITS']       = 'Degrees'
      att['VALIDMIN']    = 0.
      att['VALIDMAX']    = 180.
    end
    'COUNTS': begin
      att['CATDESC']     = 'Counts in Energy/angle bin'
      att['FIELDNAM']    = 'Counts'
      att['LABLAXIS']    = 'Counts'
      att['UNITS']       = 'Counts'
      att['VALIDMIN']    = 0.
      att['VALIDMAX']    = 1e6
      att['SCALETYP']    = 'log'
    end
    'EFLUX': begin
      att['CATDESC']     = 'Differential Energy Flux vs Energy/angle bin'
      att['FIELDNAM']    = 'Eflux'
      att['LABLAXIS']    = 'Diff Energy Flux'
      att['UNITS']       = 'eV/cm2-s-ster-eV'
      att['VAR_TYPE']    = 'data'
      att['DISPLAY_TYPE']= 'spectrogram'
      att['DEPEND_1']    = 'ENERGY'
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e16
      att['SCALETYP']    = 'log'
    end
    'EFLUX_VS_ENERGY': begin
      att['CATDESC']     = 'Differential Energy Flux vs Energy'
      att['FIELDNAM']    = 'Eflux vs Energy'
      att['LABLAXIS']    = 'Eflux vs Energy'
      att['UNITS']       = 'eV/cm2-s-ster-eV'
      att['VAR_TYPE']    = 'data'
      att['DISPLAY_TYPE']= 'spectrogram'
      att['DEPEND_1']    = 'ENERGY_VALS'
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e16
      att['SCALETYP']    = 'log'
    end
    'EFLUX_VS_THETA': begin
      att['CATDESC']     = 'Differential Energy Flux vs Theta'
      att['FIELDNAM']    = 'Eflux vs Theta'
      att['LABLAXIS']    = 'Eflux vs Theta'
      att['UNITS']       = 'eV/cm2-s-ster-eV'
      att['VAR_TYPE']    = 'data'
      att['DISPLAY_TYPE']= 'spectrogram'
      att['DEPEND_1']    = 'THETA_VALS'
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e16
      att['SCALETYP']    = 'log'
    end
    'EFLUX_VS_PHI': begin
      att['CATDESC']     = 'Differential Energy Flux vs Phi'
      att['FIELDNAM']    = 'Eflux vs Phi'
      att['LABLAXIS']    = 'Eflux vs Phi'
      att['UNITS']       = 'eV/cm2-s-ster-eV'
      att['VAR_TYPE']    = 'data'
      att['DISPLAY_TYPE']= 'spectrogram'
      att['DEPEND_1']    = 'PHI_VALS'
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e16
      att['SCALETYP']    = 'log'
    end
    'EFLUX_VS_PA_E': begin
      att['CATDESC']     = 'Differential Energy Flux vs Pitch-angle and Energy'
      att['FIELDNAM']    = 'Eflux vs Pitch-angle and Energy'
      att['LABLAXIS']    = 'Eflux vs PA-E'
      att['UNITS']       = 'eV/cm2-s-ster-eV'
      att['VAR_TYPE']    = 'data'
      att['DISPLAY_TYPE']= 'spectrogram'
      att['DEPEND_1']    = 'PITCHANGLE'
      att['DEPEND_2']    = 'ENERGY_VALS'
      att['VALIDMIN']    = 0.001
      att['VALIDMAX']    = 1e16
      att['SCALETYP']    = 'log'
    end
    'DENS': begin
      att['CATDESC']     = 'Partial Moment Density'
      att['FIELDNAM']    = 'Density'
      att['LABLAXIS']    = 'Density'
      att['UNITS']       = 'cm^-3'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = .01
      att['VALIDMAX']    = 1e5
      att['SCALETYP']    = 'log'
    end
    'VEL_INST': begin
      att['CATDESC']     = 'Partial Moment Velocity in Instrument Coordinates'
      att['FIELDNAM']    = 'Velocity (Instrument)'
      att['LABLAXIS']    = 'Vx;Vy;Vz'
      att['UNITS']       = 'km/s'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -10000.
      att['VALIDMAX']    = 10000.
      att['VAR_NOTES']   = 'In instrument frame'
    end
    'VEL_SC': begin
      att['CATDESC']     = 'Partial Moment Velocity in Spacecraft Coordinates'
      att['FIELDNAM']    = 'Velocity (Spacecraft)'
      att['LABLAXIS']    = 'Vx;Vy;Vz'
      att['UNITS']       = 'km/s'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -10000.
      att['VALIDMAX']    = 10000.
      att['VAR_NOTES']   = 'In spacecraft frame, spacecraft velocity NOT removed'
    end
    'VEL_RTN_SUN': begin
      att['CATDESC']     = 'Partial Moment Velocity in RTN Coordinates and Sun reference frame'
      att['FIELDNAM']    = 'Velocity (RTN_SUN)'
      att['LABLAXIS']    = 'Vx;Vy;Vz'
      att['UNITS']       = 'km/s'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -10000.
      att['VALIDMAX']    = 10000.
      att['VAR_NOTES']   = 'In Sun frame, spacecraft velocity removed'
    end
    'SC_VEL_RTN_SUN': begin
      att['CATDESC']     = 'Spacecraft Velocity in RTN Coordinates and Sun reference frame'
      att['FIELDNAM']    = 'Spacecraft Velocity (RTN_SUN)'
      att['LABLAXIS']    = 'Vx;Vy;Vz'
      att['UNITS']       = 'km/s'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -10000.
      att['VALIDMAX']    = 10000.
      att['VAR_NOTES']   = 'In Sun frame'
    end
    'QUAT_SC_TO_RTN': begin
      att['CATDESC']     = 'Quaternion for Rotating from Spacecraft to RTN Coordinates'
      att['FIELDNAM']    = 'Quaternion'
      att['LABLAXIS']    = 'Q1;Q2;Q3;Q4'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -1.
      att['VALIDMAX']    = 1.
    end
    'SUN_DIST': begin
      att['CATDESC']     = 'Spacecraft Distance to the Sun'
      att['FIELDNAM']    = 'Sun Distance'
      att['LABLAXIS']    = 'Sun Distance'
      att['UNITS']       = 'km'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = 0.
      att['VALIDMAX']    = 1e9
    end
    'VENUS_DIST': begin
      att['CATDESC']     = 'Spacecraft Distance to Venus'
      att['FIELDNAM']    = 'Venus Distance'
      att['LABLAXIS']    = 'Venus Distance'
      att['UNITS']       = 'km'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = 0.
      att['VALIDMAX']    = 1e9
    end
    'MAGF_SC': begin
      att['CATDESC']     = 'Magnetic Field in Spacecraft Coordinates'
      att['FIELDNAM']    = 'Magnetic Field (Spacecraft)'
      att['LABLAXIS']    = 'Bx;By;Bz'
      att['UNITS']       = 'nT'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -10000.
      att['VALIDMAX']    = 10000.
      att['VAR_NOTES']   = 'In spacecraft frame'
    end
    'MAGF_INST': begin
      att['CATDESC']     = 'Magnetic Field in Instrument Coordinates'
      att['FIELDNAM']    = 'Magnetic Field (Instrument)'
      att['LABLAXIS']    = 'Bx;By;Bz'
      att['UNITS']       = 'nT'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -10000.
      att['VALIDMAX']    = 10000.
      att['VAR_NOTES']   = 'In instrument frame'
    end
    'T_TENSOR_INST': begin
      att['CATDESC']     = 'Partial Moment Temperature Tensor in instrument frame'
      att['FIELDNAM']    = 'Temperature Tensor (Instrument)'
      att['LABLAXIS']    = 'Txx;Tyy;Tzz;Txy;Txz;Tyz'
      att['UNITS']       = 'eV'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = -10000.
      att['VALIDMAX']    = 10000.
      att['VAR_NOTES']   = 'In instrument frame'
    end
    'TEMP': begin
      att['CATDESC']     = 'Average of Trace of Partial Moment Temperature Tensor'
      att['FIELDNAM']    = 'Temperature'
      att['LABLAXIS']    = 'Temperature'
      att['UNITS']       = 'eV'
      att['VAR_TYPE']    = 'data'
      att['VALIDMIN']    = 0.
      att['VALIDMAX']    = 10000.
    end
    'TOF': begin
      att['CATDESC']     = 'Time of Flight'
      att['FIELDNAM']    = 'Time of Flight'
      att['LABLAXIS']    = 'Time of Flight'
      att['UNITS']       = 'Counts'
      att['VAR_TYPE']    = 'data'
      att['DISPLAY_TYPE']= 'spectrogram'
      att['VALIDMIN']    = 0.
      att['VALIDMAX']    = 1e6
      att['SCALETYP']    = 'log'
    end
    'QUALITY_FLAG': begin
      att['CATDESC']     = 'Quality Flag'
      att['FIELDNAM']    = 'Quality Flag'
      att['LABLAXIS']    = 'Quality Flag'
      att['VAR_TYPE']    = 'data'
      att['FORMAT']      = 'I10'
      att['FILLVAL']     = -1u
      att['VALIDMIN']    = 0u
      att['VALIDMAX']    = -2u
    end
    'ROTMAT_SC_INST': begin
      att['CATDESC']     = 'Rotation Matrix from Spacecraft to Instrument Coordinates'
      att['FIELDNAM']    = 'Rotation Matrix'
      att['LABLAXIS']    = ''
      att['VAR_TYPE']    = 'metadata'
      att['DEPEND_0']    = ''
    end
    else:  begin    ; assumed to be support
      att['VAR_TYPE']    = 'ignore_data'
      att['FORMAT']      = 'I20'
      att['FILLVAL']     = ''
      att['VALIDMIN']    = ''
      att['VALIDMAX']    = ''

      dprint,dlevel=dlevel, 'variable ' +vname+ ' not recognized'
    end

  endcase

  return, att
end


PRO cdf_tools_varinfo::GetProperty, data=data, name=name, attributes=attributes, numrec=numrec,strct=strct
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(name)) THEN name = self.name
  IF (ARG_PRESENT(numrec)) THEN numrec = self.numrec
  IF (ARG_PRESENT(attributes)) THEN attributes = self.attributes
  IF (ARG_PRESENT(data)) THEN data = self.data
  IF (ARG_PRESENT(strct)) THEN struct_assign,strct,self
END


FUNCTION cdf_tools_varinfo::Init,name,value,all_values=all_values,structure_array=str_arr,set_default_atts=set_default_atts,attr_name=attr_name,_EXTRA=ex
  COMPILE_OPT IDL2
  ;  self.dlevel = 4
  void = self.generic_Object::Init(_extra=ex)   ; Call the superclass Initialization method.
  if keyword_set(str_arr) then begin
    str_element,str_arr,name,dat_values
    ;if n_elements(str_arr) gt 1 then begin
    all_values = transpose([dat_values])
    ;endif else begin
    ;dprint,'Weird bug.  single value?'
    ;all_values = dat_values   ;  Not sure if this is really a fix????
    ;endelse
    str_element,str_arr[0],name,value
  endif
  if isa(name,/string) then self.name=name
  if keyword_set(set_default_atts) then self.attributes = self.variable_attributes(name,value)
  self.data = dynamicarray(all_values,name=self.name)
  self.is_zvar = 1
  self.type = size(/type,value)
  self.ndimen = size(/n_dimensions,value)
  self.d = size(/dimen,value)
  ;  if debug(3) and keyword_set(ex) then dprint,ex,phelp=2,dlevel=4
  IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
  if self.recvary then self.numrec = (size(/dimen,all_values))[0]
  RETURN, 1
end


PRO cdf_tools_varinfo__define
  void = {cdf_tools_varinfo, $
    inherits generic_Object, $    ; superclass
    name:'', $
    num:0, $
    is_zvar:0,  $
    datatype:'',  $
    type:0, $
    numattr:-1,  $
    numelem:0, $
    recvary:0b, $
    numrec:0l, $
    ndimen:0, $
    d:lonarr(6) , $
    data:obj_new(), $
    attributes:obj_new()   $
  }
end
