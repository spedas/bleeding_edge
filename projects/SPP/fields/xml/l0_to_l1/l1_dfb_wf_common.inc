  <item
      name   = "dfb_wav_sample_rate"
      type   = "double"
      value  = "18750. / (2. ** dfb_wav_tap)"
      />
      
  <item
      name   = "dfb_wav_time_step"
      type   = "double"
      value  = "1. / dfb_wav_sample_rate"
      />

  <item
      name   = "dfb_wav_time_series_times"
      type   = "double"
      value  = "r8gen(0, dfb_wav_time_step, wf_pkt_data_elements, 1, 1, 1, 0)"
      />

  <cdf_var
      name   = "dfb_compression"
      type   = "integer">
  <cdf_att
        FIELDNAM = "compression"
        FORMAT = "I08"
        LABLAXIS = "compression"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "compression"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_wav_tap"
      type   = "integer">
  <cdf_att
        FIELDNAM = "wav_tap"
        FORMAT = "I08"
        LABLAXIS = "wav_tap"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "15"
        SCALEMIN = "0"
        SCALEMAX = "15"
        UNITS = "None"
        CATDESC = "wav_tap"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_wav_en"
      type   = "integer">
  <cdf_att
        FIELDNAM = "wav_enable"
        FORMAT = "I08"
        LABLAXIS = "wav_enable"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "wav_enable"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "dfb_wav_sel"
      type   = "integer">
  	<cdf_att
        FIELDNAM = "wav_sel"
        FORMAT = "I08"
        LABLAXIS = "wav_sel"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "15"
        SCALEMIN = "0"
        SCALEMAX = "15"
        UNITS = "None"
        CATDESC = "wav_sel"
        DEPEND_0 = "epoch">
    	</cdf_att>
  </cdf_var>
    
	<cdf_var
      name   = "wf_pkt_data"
      type   = "integer"
      convert_routine = "none"
      nelem  = "wf_pkt_data_elements">
  	<cdf_att
        FIELDNAM = "wf_pkt_data"
        FORMAT = "I12"
        LABLAXIS = "wf_pkt_data"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT4"
        FILLVAL = "-2147483647"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-2147483647"
        VALIDMAX = "2147483647"
        SCALEMIN = "-2147483647"
        SCALEMAX = "2147483647"
        UNITS = "None"
        CATDESC = "wf_pkt_data"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

