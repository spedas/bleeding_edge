  <cdf_var
      name   = "compressed"
      type   = "integer">
  <cdf_att
        FIELDNAM = "compressed"
        FORMAT = "I08"
        LABLAXIS = "compressed"
        VAR_TYPE = "data"
        DATA_TYPE = "CDF_INT2"
        FILLVAL = "-32767"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "1"
        SCALEMIN = "0"
        SCALEMAX = "1"
        UNITS = "None"
        CATDESC = "compressed"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "algorithm"
      type   = "integer"
      />

  <!-- unused 5 bits -->

  <cdf_var
      name   = "avg_period_raw"
      type   = "integer">
  <cdf_att
        FIELDNAM = "avg_period_raw"
        FORMAT = "F15.3"
        LABLAXIS = "avg_period_raw"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "None"
        CATDESC = "avg period raw"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "config2"
      type   = "integer"
      />

  <cdf_var
      name   = "config3"
      type   = "integer"
      />

  <cdf_var
      name   = "range_bits"
      type   = "integer">
    <cdf_att
        FIELDNAM = "range_bits"
        FORMAT = "F15.3"
        LABLAXIS = "range"
        VAR_TYPE = "data"
        FILLVAL = "4294967295"
        DATA_TYPE = "CDF_UINT4"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "0"
        VALIDMAX = "4294967295"
        SCALEMIN = "0"
        SCALEMAX = "4294967295"
        UNITS = "None"
        CATDESC = "Range"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_bx"
      type   = "integer"
      convert_routine = "none"
      nelem  = "512">
    <cdf_att
        FIELDNAM = "mag_bx_2d"
        FORMAT = "F15.3"
        LABLAXIS = "mag_bx_2d"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "Counts"
        CATDESC = "MAG BX: X component of the magnetic field"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_by"
      type   = "integer"
      convert_routine = "none"
      nelem  = "512">
    <cdf_att
        FIELDNAM = "mag_by_2d"
        FORMAT = "F15.3"
        LABLAXIS = "mag_by_2d"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "Counts"
        CATDESC = "MAG BY: Y component of the magnetic field"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>

  <cdf_var
      name   = "mag_bz"
      type   = "integer"
      convert_routine = "none"
      nelem  = "512">
    <cdf_att
        FIELDNAM = "mag_bz_2d"
        FORMAT = "F15.3"
        LABLAXIS = "mag_bz_2d"
        VAR_TYPE = "data"
        FILLVAL = "-1.0E31"
        DISPLAY_TYPE = "time_series"
        VALIDMIN = "-99999999"
        VALIDMAX = "99999999"
        SCALEMIN = "-99999999"
        SCALEMAX = "99999999"
        UNITS = "Counts"
        CATDESC = "MAG BZ: Z component of the magnetic field"
        DEPEND_0 = "epoch">
    </cdf_att>
  </cdf_var>
