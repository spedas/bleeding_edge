  <cdf_var
      name   = "dfb_dc_bpf_en"
      type   = "integer">
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
        CATDESC = "enable"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_dc_bpf_rslt_sel"
      type   = "integer">
  <cdf_att
        FIELDNAM = "rslt_sel"
        FORMAT = "I08"
        LABLAXIS = "rslt_sel"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "3"
        SCALEMIN = "0"
        SCALEMAX = "3"
        UNITS = "None"
        CATDESC = "rslt_sel"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_dc_bpf_src_sel"
      type   = "integer"
      string = "true"
      string_len = "16">
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
        CATDESC = "src_sel"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_dc_bpf_cad_sel"
      type   = "integer">
  <cdf_att
        FIELDNAM = "cad_sel"
        FORMAT = "I08"
        LABLAXIS = "cad_sel"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "15"
        SCALEMIN = "0"
        SCALEMAX = "15"
        UNITS = "None"
        CATDESC = "cad_sel"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
  
  <cdf_var
      name   = "dfb_dc_bpf_peak"
      type   = "integer"
      nelem	 = "15">
  <cdf_att
        FIELDNAM = "peak"
        FORMAT = "I08"
        LABLAXIS = "peak"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "255"
        SCALEMIN = "0"
        SCALEMAX = "255"
        UNITS = "None"
        CATDESC = "peak"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_dc_bpf_avg"
      type   = "integer"
      nelem	 = "15">
  <cdf_att
        FIELDNAM = "avg"
        FORMAT = "I08"
        LABLAXIS = "avg"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "255"
        SCALEMIN = "0"
        SCALEMAX = "255"
        UNITS = "None"
        CATDESC = "avg"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

