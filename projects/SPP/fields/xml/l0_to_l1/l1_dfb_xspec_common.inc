  <cdf_var
      name   = "dfb_xspec_src1"
      type   = "integer"      
      string = "true"
      string_len = "8">
  <cdf_att
        FIELDNAM = "src1"
        FORMAT = "I08"
        LABLAXIS = "src1"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "3"
        SCALEMIN = "0"
        SCALEMAX = "3"
        UNITS = "None"
        CATDESC = "Source select Spectrum 1"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_xspec_src2"
      type   = "integer"      
      string = "true"
      string_len = "8">
  <cdf_att
        FIELDNAM = "src2"
        FORMAT = "I08"
        LABLAXIS = "src2"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "3"
        SCALEMIN = "0"
        SCALEMAX = "3"
        UNITS = "None"
        CATDESC = "Source select Spectrum 2"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_xspec_concat"
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
        VALIDMAX = "2"
        SCALEMIN = "0"
        SCALEMAX = "2"
        UNITS = "None"
        CATDESC = "Number of cross spectra concatenated in a packet"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_xspec_enable"
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
        CATDESC = "DFB cross spectra enable"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_xspec_gain"
      type   = "integer"
    	string = "true"
      string_len = "16">
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
        CATDESC = "DFB cross spectra gain"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_xspec_navg"
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
        CATDESC = "Number of averaged 1024-point FFTs per DFB cross spectra = 2^navg"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>


  <cdf_var
      name   = "dfb_xspec_pkt_length"
      type   = "integer">
  <cdf_att
        FIELDNAM = "xspec_pkt_length"
        FORMAT = "I08"
        LABLAXIS = "xspec_pkt_length"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "32767"
        SCALEMIN = "0"
        SCALEMAX = "32767"
        UNITS = "None"
        CATDESC = "DFB X-spec packet length (not counting header)"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
