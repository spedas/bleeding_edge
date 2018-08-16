  <cdf_var
      name   = "message_id"
      type   = "integer"
      base   = "event_data_start"
      offset = "0"
      width  = "16"
      />

  <cdf_var
      name   = "mag_sync_1"
      type   = "integer"
      base   = "event_data_start"
      offset = "2 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_sync_2"
      type   = "integer"
      base   = "event_data_start"
      offset = "4 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "cmd_ctr"
      type   = "integer"
      base   = "event_data_start"
      offset = "6 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_frm_ctr"
      type   = "integer"
      base   = "event_data_start"
      offset = "8 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_cycle_f0"
      type   = "integer"
      base   = "event_data_start"
      offset = "10 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_time_f1"
      type   = "integer"
      base   = "event_data_start"
      offset = "12 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_time_f2"
      type   = "integer"
      base   = "event_data_start"
      offset = "14 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_time_f3"
      type   = "integer"
      base   = "event_data_start"
      offset = "16 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_status"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_spp"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8"
      width  = "1"
      />

  <cdf_var
      name   = "mag_fpga_ver"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 1"
      width  = "5"
      />

  <cdf_var
      name   = "mag_pcbnum"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 6"
      width  = "4"
      />

  <cdf_var
      name   = "mag_drive"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 10"
      width  = "2"
      />

  <cdf_var
      name   = "mag_cal"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 12"
      width  = "1"
      />

  <cdf_var
      name   = "mag_manual"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_manual"
        FORMAT = "I8"
        LABLAXIS = "mag_manual"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG Manual mode"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_range"
      type   = "integer"
      base   = "event_data_start"
      offset = "18 * 8 + 14"
      width  = "2"
      />

  <cdf_var
      name   = "mag_xtest_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_xtest_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_xtest_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG X Test Output, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_xtest"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_xtest"
        FORMAT = "F15.3"
        LABLAXIS = "mag_xtest"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-1024"
        VALIDMAX = "1024"
        SCALEMIN = "-1024"
        SCALEMAX = "1024"
        UNITS = "nT"
        CATDESC = "MAG X Test Output, in nT"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_ytest_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_ytest_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_ytest_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG Y Test Output, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_ytest"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_ytest"
        FORMAT = "F15.3"
        LABLAXIS = "mag_ytest"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-1024"
        VALIDMAX = "1024"
        SCALEMIN = "-1024"
        SCALEMAX = "1024"
        UNITS = "nT"
        CATDESC = "MAG Y Test Output, in nT"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_ztest_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_ztest_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_ztest_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG Z Test Output, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_ztest"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_ztest"
        FORMAT = "F15.3"
        LABLAXIS = "mag_ztest"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-1024"
        VALIDMAX = "1024"
        SCALEMIN = "-1024"
        SCALEMAX = "1024"
        UNITS = "nT"
        CATDESC = "MAG Z Test Output, in nT"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_htrvmon_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_htrvmon_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_htrvmon_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG Heater Bus Voltage Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_htrvmon"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_htrvmon"
        FORMAT = "F15.3"
        LABLAXIS = "mag_htrvmon"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-100"
        VALIDMAX = "100"
        SCALEMIN = "-100"
        SCALEMAX = "100"
        UNITS = "V"
        CATDESC = "MAG Heater Bus Voltage Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_htrcurr_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_htrcurr_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_htrcurr_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG Heater Bus Current Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_htrcurr"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_htrcurr"
        FORMAT = "F15.3"
        LABLAXIS = "mag_htrcurr"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_DOUBLE"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "200"
        SCALEMIN = "0"
        SCALEMAX = "200"
        UNITS = "mA"
        CATDESC = "MAG Heater Bus Current Monitor, in mA"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_snsrtemp_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_snsrtemp_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_snsrtemp_raw"
				DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG Sensor Temperature, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_snsrtemp"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_snsrtemp"
        FORMAT = "F15.3"
        LABLAXIS = "mag_snsrtemp"
				DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E30"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-100"
        VALIDMAX = "100"
        SCALEMIN = "-100"
        SCALEMAX = "100"
        UNITS = "C"
        CATDESC = "MAG Sensor Temperature, in degrees C"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_pcbtemp_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_pcbtemp_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_pcbtemp_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG PCB Temperature, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_pcbtemp"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_pcbtemp"
        FORMAT = "F15.3"
        LABLAXIS = "mag_pcbtemp"
				DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E30"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-100"
        VALIDMAX = "100"
        SCALEMIN = "-100"
        SCALEMAX = "100"
        UNITS = "C"
        CATDESC = "MAG PCB Temperature, in degrees C"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p12curr_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_p12curr_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_p12curr_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG +12V Current Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p12curr"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_p12curr"
        FORMAT = "F15.3"
        LABLAXIS = "mag_p12curr"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "200"
        SCALEMIN = "0"
        SCALEMAX = "200"
        UNITS = "mA"
        CATDESC = "MAG +12V Current Monitor, in mA"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_m12curr_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_m12curr_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_m12curr_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG -12V Current Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_m12curr"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_m12curr"
        FORMAT = "F15.3"
        LABLAXIS = "mag_m12curr"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "200"
        SCALEMIN = "0"
        SCALEMAX = "200"
        UNITS = "mA"
        CATDESC = "MAG -12V Current Monitor, in mA"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p12vmon_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_p12vmon_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_p12vmon_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG +12V Voltage Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p12vmon"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_p12vmon"
        FORMAT = "F15.3"
        LABLAXIS = "mag_p12vmon"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "20"
        SCALEMIN = "0"
        SCALEMAX = "20"
        UNITS = "V"
        CATDESC = "MAG +12V Voltage Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_m12vmon_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_m12vmon_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_m12vmon_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG -12V Voltage Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_m12vmon"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_m12vmon"
        FORMAT = "F15.3"
        LABLAXIS = "mag_m12vmon"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "20"
        SCALEMIN = "0"
        SCALEMAX = "20"
        UNITS = "V"
        CATDESC = "MAG -12V Voltage Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p10vref_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_p10vref_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_p10vref_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG +10V VREF Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p10vref"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_p10vref"
        FORMAT = "F15.3"
        LABLAXIS = "mag_p10vref"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "20"
        SCALEMIN = "0"
        SCALEMAX = "20"
        UNITS = "V"
        CATDESC = "MAG +10V VREF Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p25dmon_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_p25dmon_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_p25dmon_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG 2.5V FPGA Core Voltage Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p25dmon"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_p25dmon"
        FORMAT = "F15.3"
        LABLAXIS = "mag_p25dmon"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "3"
        SCALEMIN = "0"
        SCALEMAX = "3"
        UNITS = "V"
        CATDESC = "MAG 2.5V FPGA Core Voltage Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p33dmon_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_p33dmon_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_p33dmon_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG 3.3V Digital IO Voltage Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p33dmon"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_p33dmon"
        FORMAT = "F15.3"
        LABLAXIS = "mag_p33dmon"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "5"
        SCALEMIN = "0"
        SCALEMAX = "5"
        UNITS = "V"
        CATDESC = "MAG 3.3V Digital IO Voltage Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p5vmon_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_p5vmon_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_p5vmon_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG ADC +5 Voltage Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_p5vmon"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_p5vmon"
        FORMAT = "F15.3"
        LABLAXIS = "mag_p5vmon"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "10"
        SCALEMIN = "0"
        SCALEMAX = "10"
        UNITS = "V"
        CATDESC = "MAG ADC +5 Voltage Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_m5vmon_raw"
      type   = "integer">
    <cdf_att
        FIELDNAM = "mag_m5vmon_raw"
        FORMAT = "I8"
        LABLAXIS = "mag_m5vmon_raw"
        DATA_TYPE = "CDF_INT2"
        VAR_TYPE = "data"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-32767"
        VALIDMAX = "32767"
        SCALEMIN = "-32767"
        SCALEMAX = "32767"
        UNITS = "Counts"
        CATDESC = "MAG ADC -5 Voltage Monitor, in raw ADC counts"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_m5vmon"
      type   = "double">
    <cdf_att
        FIELDNAM = "mag_m5vmon"
        FORMAT = "F15.3"
        LABLAXIS = "mag_m5vmon"
        DATA_TYPE = "CDF_DOUBLE"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-10"
        VALIDMAX = "0"
        SCALEMIN = "-10"
        SCALEMAX = "0"
        UNITS = "V"
        CATDESC = "MAG ADC -5 Voltage Monitor, in V"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_dig_hk_00"
      type   = "integer"
      base   = "event_data_start"
      offset = "52 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_testbus"
      type   = "integer"
      base   = "event_data_start"
      offset = "52 * 8"
      width  = "4"
      />

  <cdf_var
      name   = "mag_digxtra"
      type   = "integer"
      base   = "event_data_start"
      offset = "52 * 8 + 4"
      width  = "4"
      />

  <cdf_var
      name   = "mag_rgupdat"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8"
      width  = "1"
      />

  <cdf_var
      name   = "mag_digpps"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 1"
      width  = "1"
      />

  <cdf_var
      name   = "mag_timehi"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 2"
      width  = "1"
      />

  <cdf_var
      name   = "mag_timemid"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 3"
      width  = "1"
      />

  <cdf_var
      name   = "mag_timelow"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 4"
      width  = "1"
      />

  <cdf_var
      name   = "mag_cmdrcd"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 5"
      width  = "1"
      />

  <cdf_var
      name   = "mag_parerr"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 6"
      width  = "1"
      />

  <cdf_var
      name   = "mag_stoperr"
      type   = "integer"
      base   = "event_data_start"
      offset = "53 * 8 + 7"
      width  = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_01"
      type   = "integer"
      base   = "event_data_start"
      offset = "54 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_02"
      type   = "integer"
      base   = "event_data_start"
      offset = "56 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_cmdrjct"
      type   = "integer"
      base   = "event_data_start"
      offset = "56 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_lstrjct"
      type   = "integer"
      base   = "event_data_start"
      offset = "57 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_03"
      type   = "integer"
      base   = "event_data_start"
      offset = "58 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_r0_hi"
      type   = "integer"
      base   = "event_data_start"
      offset = "58 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_r1_lo"
      type   = "integer"
      base   = "event_data_start"
      offset = "59 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_04"
      type   = "integer"
      base   = "event_data_start"
      offset = "60 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_r1_hi"
      type   = "integer"
      base   = "event_data_start"
      offset = "60 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_r2_lo"
      type   = "integer"
      base   = "event_data_start"
      offset = "61 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_05"
      type   = "integer"
      base   = "event_data_start"
      offset = "62 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_r2_hi"
      type   = "integer"
      base   = "event_data_start"
      offset = "62 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_r3_lo"
      type   = "integer"
      base   = "event_data_start"
      offset = "63 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_06"
      type   = "integer"
      base   = "event_data_start"
      offset = "64 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_lle"
      type   = "integer"
      base   = "event_data_start"
      offset = "64 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_ule"
      type   = "integer"
      base   = "event_data_start"
      offset = "65 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_07"
      type   = "integer"
      base   = "event_data_start"
      offset = "66 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_numpkt"
      type   = "integer"
      base   = "event_data_start"
      offset = "66 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_cnt_pkt"
      type   = "integer"
      base   = "event_data_start"
      offset = "67 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_dig_hk_08"
      type   = "integer"
      base   = "event_data_start"
      offset = "68 * 8"
      width  = "16"
      />

  <cdf_var
      name   = "mag_cnt_ule"
      type   = "integer"
      base   = "event_data_start"
      offset = "68 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_cnt_lle"
      type   = "integer"
      base   = "event_data_start"
      offset = "69 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_rate"
      type   = "integer"
      base   = "event_data_start"
      offset = "70 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_opt"
      type   = "integer"
      base   = "event_data_start"
      offset = "71 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_rstlmt"
      type   = "integer"
      base   = "event_data_start"
      offset = "72 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_rstsec"
      type   = "integer"
      base   = "event_data_start"
      offset = "73 * 8"
      width  = "8"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff0"
      type   = "integer"
      base   = "event_data_start"
      offset = "74 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff0"
      type   = "integer"
      base   = "event_data_start"
      offset = "76 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff0"
      type   = "integer"
      base   = "event_data_start"
      offset = "78 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff1"
      type   = "integer"
      base   = "event_data_start"
      offset = "80 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff1"
      type   = "integer"
      base   = "event_data_start"
      offset = "82 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff1"
      type   = "integer"
      base   = "event_data_start"
      offset = "84 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff2"
      type   = "integer"
      base   = "event_data_start"
      offset = "86 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff2"
      type   = "integer"
      base   = "event_data_start"
      offset = "88 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff2"
      type   = "integer"
      base   = "event_data_start"
      offset = "90 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_xoff3"
      type   = "integer"
      base   = "event_data_start"
      offset = "92 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_yoff3"
      type   = "integer"
      base   = "event_data_start"
      offset = "94 * 8"
      width  = "16"
      signed = "1"
      />

  <cdf_var
      name   = "mag_zoff3"
      type   = "integer"
      base   = "event_data_start"
      offset = "96 * 8"
      width  = "16"
      signed = "1"
      />
