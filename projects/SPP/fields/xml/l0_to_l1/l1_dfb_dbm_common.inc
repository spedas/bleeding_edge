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
      name   = "dfb_acdc"
      type   = "integer">
    <cdf_att
        FIELDNAM = "acdc"
        FORMAT = "I08"
        LABLAXIS = "acdc"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "acdc"
        DEPEND_0 = "epoch">
		</cdf_att>
  </cdf_var>
  
  <cdf_var
      name   = "dfb_ftap"
      type   = "integer">
    <cdf_att
        FIELDNAM = "ftap"
        FORMAT = "I08"
        LABLAXIS = "ftap"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "6"
        SCALEMIN = "0"
        SCALEMAX = "6"
        UNITS = "None"
        CATDESC = "ftap"
        DEPEND_0 = "epoch">
		</cdf_att>
  </cdf_var>
  
  <cdf_var
    name   = "dfb_src_sel"
    type   = "integer">
  	<cdf_att
      FIELDNAM = "src_sel"
      FORMAT = "I12"
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
    name   = "payload_data_start"
    type   = "integer">
  	<cdf_att
      FIELDNAM = "payload_data_start"
      FORMAT = "I12"
      LABLAXIS = "payload_data_start"
      VAR_TYPE = "data"
      DATA_TYPE = "CDF_INT2"
      FILLVAL = "-32767"
      DISPLAY_TYPE = "time_series"
      VALIDMIN = "0"
    	VALIDMAX = "15"
      SCALEMIN = "0"
      SCALEMAX = "15"
      UNITS = "None"
      CATDESC = "payload_data_start"
      DEPEND_0 = "epoch">
  	</cdf_att>
	</cdf_var>

  <cdf_var
    name   = "ccsds_total_packet_length"
    type   = "integer">
  	<cdf_att
      FIELDNAM = "ccsds_total_packet_length"
      FORMAT = "I12"
      LABLAXIS = "ccsds_total_packet_length"
      VAR_TYPE = "data"
      DATA_TYPE = "CDF_INT2"
      FILLVAL = "-32767"
      DISPLAY_TYPE = "time_series"
      VALIDMIN = "0"
    	VALIDMAX = "15"
      SCALEMIN = "0"
      SCALEMAX = "15"
      UNITS = "None"
      CATDESC = "ccsds_total_packet_length"
      DEPEND_0 = "epoch">
  	</cdf_att>
	</cdf_var>

  <cdf_var
    name   = "ccsds_meat_length"
    type   = "integer">
  	<cdf_att
      FIELDNAM = "ccsds_meat_length"
      FORMAT = "I12"
      LABLAXIS = "ccsds_meat_length"
      VAR_TYPE = "data"
      DATA_TYPE = "CDF_INT2"
      FILLVAL = "-32767"
      DISPLAY_TYPE = "time_series"
      VALIDMIN = "0"
    	VALIDMAX = "15"
      SCALEMIN = "0"
      SCALEMAX = "15"
      UNITS = "None"
      CATDESC = "ccsds_meat_length"
      DEPEND_0 = "epoch">
  	</cdf_att>
	</cdf_var>

  <cdf_var
    name   = "payload_data_start"
    type   = "integer">
  	<cdf_att
      FIELDNAM = "payload_data_start"
      FORMAT = "I12"
      LABLAXIS = "payload_data_start"
      VAR_TYPE = "data"
      DATA_TYPE = "CDF_INT2"
      FILLVAL = "-32767"
      DISPLAY_TYPE = "time_series"
      VALIDMIN = "0"
    	VALIDMAX = "15"
      SCALEMIN = "0"
      SCALEMAX = "15"
      UNITS = "None"
      CATDESC = "payload_data_start"
      DEPEND_0 = "epoch">
  	</cdf_att>
	</cdf_var>


  <cdf_var
    name   = "payload_length"
    type   = "integer">
  	<cdf_att
      FIELDNAM = "payload_length"
      FORMAT = "I12"
      LABLAXIS = "payload_length"
      VAR_TYPE = "data"
      DATA_TYPE = "CDF_INT2"
      FILLVAL = "-32767"
      DISPLAY_TYPE = "time_series"
      VALIDMIN = "0"
    	VALIDMAX = "15"
      SCALEMIN = "0"
      SCALEMAX = "15"
      UNITS = "None"
      CATDESC = "payload_length"
      DEPEND_0 = "epoch">
  	</cdf_att>
	</cdf_var>

  <cdf_var
    name   = "event_length"
    type   = "integer">
  	<cdf_att
      FIELDNAM = "event_length"
      FORMAT = "I12"
      LABLAXIS = "event_length"
      VAR_TYPE = "data"
      DATA_TYPE = "CDF_INT2"
      FILLVAL = "-32767"
      DISPLAY_TYPE = "time_series"
      VALIDMIN = "0"
    	VALIDMAX = "15"
      SCALEMIN = "0"
      SCALEMAX = "15"
      UNITS = "None"
      CATDESC = "event_length"
      DEPEND_0 = "epoch">
  	</cdf_att>
	</cdf_var>

  <cdf_var
      name   = "dbm_data"
      type   = "integer"
      convert_routine = "none"
      nelem  = "dbm_nsamples">
  	<cdf_att
        FIELDNAM = "dbm_data"
        FORMAT = "I12"
        LABLAXIS = "dbm_data"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT4"
        FILLVAL = "-2147483647"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-2147483647"
        VALIDMAX = "2147483647"
        SCALEMIN = "-2147483647"
        SCALEMAX = "2147483647"
        UNITS = "None"
        CATDESC = "dbm_data"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>


