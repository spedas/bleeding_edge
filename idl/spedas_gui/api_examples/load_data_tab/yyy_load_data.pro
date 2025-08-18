;+
;NAME: 
;  yyy_load_data
;           This routine is a template for loading data into tplot variables and
;           must be replaced with mission specific load routines.
;           For this example fake data is generated using dindgen.
;           Typically SPEDAS load routines load data into tplot variables. The 
;           SPEDAS load routines uses http copies to retrieve the cdf file. The
;           file is then read and data placed into tplot variables.
;          
;KEYWORDS (commonly used by other load routines):
;  PROBE    = Probe name. The default is 'all', i.e., load all available probes.
;             This can be an array of strings, e.g., ['a', 'b'] or a
;             single string delimited by spaces, e.g., 'a b'
;  DATATYPE = The type of data to be loaded, can be an array of strings
;             or single string separate by spaces.  The default is 'all'
;  TRANGE   = (Optional) Time range of interest  (2 element array), if
;             this is not set, the default is to prompt the user. Note
;             that if the input time range is not a full day, a full
;             day's data is loaded
;  LEVEL    = Level is not used in this example but is common to many mission. 
;             Please refer to the equivalent GOES, WIND, SPEDAS or ACE load 
;             routines for examples. 
;          
;EXAMPLE:
;   yyy_load_data,probe='x'
; 
;NOTES:
;   Each mission is different and you may not need all of the keywords listed below
;   or you may need more to adequately specify instrument, probe, and data types.
;     
;--------------------------------------------------------------------------------------
PRO yyy_load_data, probe=probe, instrument=instrument, datatype=datatype, timerange=timerange

  ; this sets the time range for use with the thm_load routines
  timespan, timerange

  ; Generate fake data for the tplot variable
  y=[[dindgen(1440)],[dindgen(1440)*2.],[dindgen(1440)-50.]]
  x=dindgen(1440)*60+time_double(timerange[0])  
  d={x:x, y:y}
  ; Create some fake data limits
  dl={colors:[2,4,6], labels:['x','y','z']}
 
  ; and store it data in the new tplot variable 
  yyy_tplot_name = 'p'+probe[0]+'_'+instrument[0]+'_'+datatype[0] 
  store_data, yyy_tplot_name, data=d, dlimits=dl

END
