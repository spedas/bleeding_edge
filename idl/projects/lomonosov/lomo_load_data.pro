;+
;NAME: 
;  lomo_load_data
;           This routine loads local ELFIN Lomonosov data. 
;           There is no server available yet so all files must
;           be local. The default value is currently set to
;          'C:/data/lomo/elfin/l1/'
;          If you do not want to place your cdf files there you 
;          must change the lomonosov system variable !lomo.local_data_dir = 'yourdirectorypath'
;KEYWORDS (commonly used by other load routines):
;  INSTRUMENT = options are 'fgm', 'epd', 'eng' (This will probably change
;               after launch 
;  DATATYPE = This is not yet implemented and may not be needed
;  LEVEL    = This is not yet implemented but options will  most likely include 
;             levels 1 or 2. For Elfin lomonosov fgm will be the only instrument
;             that has level 2 data. epd and eng only have level 1. Levels
;             have also not been implemented in the load panel gui. 
;  TRANGE   = (Optional) Time range of interest  (2 element array), if
;             this is not set, the default is to prompt the user. Note
;             that if the input time range is not a full day, a full
;             day's data is loaded
;          
;EXAMPLE:
;   lomo_load_data,probe='x'
; 
;NOTES:
;   Elfin lomonosov has limited data availability
;     
;--------------------------------------------------------------------------------------
PRO lomo_load_data, instrument=instrument, datatype=datatype, level=level, trange=trange

  ; set up system variable for MMS if not already set
  defsysv, '!lomo', exists=exists
  if not(exists) then lomo_init

  ; Construct file name
  ; TODO: The elfin lomo files must be located in the local_data_dir. Since the mission is not
  ; in flight yet - there is no server for the data. This will change. Also the file name is 
  ; currently lomo_APID_APIDNAME_YYMMDD.cdf. This will change - in the short term the names
  ; are more or less hard coded. 
  if undefined(level) then level=['l1'] else level=strlowcase(level)
  if undefined(instrument) then instrument=['epd','prm','eng']
  if instrument[0] EQ '*' then instrument=['epd','prm','eng']

  for i = 0,n_elements(instrument)-1 do begin
    case instrument[i] of 
      'prm' : lomo_load_prm, datatype=datatype, level=level, trange=trange
      'epd' : lomo_load_epd, datatype=datatype, level=level, trange=trange
      'eng' : lomo_load_eng, datatype=datatype, level=level, trange=trange
       else : print, 'Invalid ELFIN Lomonosov instrument name. Valid names are: epd, prm, eng'
    end
  endfor

END
