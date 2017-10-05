  <cdf_var
      name   = "dfb_spec_src"
      type   = "integer"      
      string = "true"
      string_len = "8">
  <cdf_att
        FIELDNAM = "src_sel"
        FORMAT = "I08"
        LABLAXIS = "src_sel"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "15"
        SCALEMIN = "0"
        SCALEMAX = "15"
        UNITS = "None"
        CATDESC = "Source select"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_spec_enable"
      type   = "integer"
    	string = "true"
      string_len = "8">
  <cdf_att
        FIELDNAM = "enable"
        FORMAT = "I08"
        LABLAXIS = "enable"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "DFB spectra enable"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_spec_bin"
      type   = "integer"
      string = "true"
      string_len = "8">
  <cdf_att
        FIELDNAM = "bin"
        FORMAT = "I08"
        LABLAXIS = "bin"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "DFB spectra binning mode"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
  
  <cdf_var
      name   = "dfb_spec_scm_rotate"
      type   = "integer"
      string = "true"
      string_len = "20">
  <cdf_att
        FIELDNAM = "scm_rotate"
        FORMAT = "I08"
        LABLAXIS = "scm_rotate"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "DFB spectra SCM rotation"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_spec_gain"
      type   = "integer"
      string = "true"
      string_len = "12">
  <cdf_att
        FIELDNAM = "gain"
        FORMAT = "I08"
        LABLAXIS = "gain"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "DFB spectra gain setting"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
  
  <cdf_var
      name   = "dfb_spec_navg"
      type   = "integer">
  <cdf_att
        FIELDNAM = "navg"
        FORMAT = "I08"
        LABLAXIS = "navg"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "10"
        SCALEMIN = "0"
        SCALEMAX = "10"
        UNITS = "None"
        CATDESC = "Number of averaged 1024-point FFTs per DFB spectra = 2^navg"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
  
  <cdf_var
      name   = "dfb_spec_concat"
      type   = "integer">
  <cdf_att
        FIELDNAM = "concat"
        FORMAT = "I08"
        LABLAXIS = "concat"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "15"
        SCALEMIN = "0"
        SCALEMAX = "15"
        UNITS = "None"
        CATDESC = "Number of spectra concatenated in a packet"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_spec_nelem"
      type   = "integer">
  <cdf_att
        FIELDNAM = "spec_nelem"
        FORMAT = "I08"
        LABLAXIS = "spec_nelem"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1536"
        SCALEMIN = "0"
        SCALEMAX = "1536"
        UNITS = "None"
        CATDESC = "Number of elements in the DFB spectral packet"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  
  <cdf_var
      name   = "dfb_spec"
      type   = "integer"
      nelem  = "dfb_spec_nelem">
  <cdf_att
        FIELDNAM = "spec"
        FORMAT = "I08"
        LABLAXIS = "spec"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "255"
        SCALEMIN = "0"
        SCALEMAX = "255"
        UNITS = "None"
        CATDESC = "spec"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
  

