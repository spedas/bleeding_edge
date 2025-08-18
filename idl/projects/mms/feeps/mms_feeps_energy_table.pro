;+
; FUNCTION:
;       mms_feeps_energy_table
;
; PURPOSE:
;       This function returns the energy table based on
;       each spacecraft and eye; based on the table from:
;       
;               FlatFieldResults_V3.xlsx
;               
;       from Drew Turner, 1/19/2017
;               
;
; NOTES:
;     BAD EYES are replaced by NaNs
;     
;     - different original energy tables are used depending on if the sensor head is 6-8 (ions) or not (electrons)
;     
;     Electron Eyes: 1, 2, 3, 4, 5, 9, 10, 11, 12
;     Ion Eyes: 6, 7, 8
;     
;     If keep_bad_eyes is set, replace NaNs in energy table corrections with zeroes
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2024-03-27 16:34:54 -0700 (Wed, 27 Mar 2024) $
; $LastChangedRevision: 32511 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_energy_table.pro $
;-

function mms_feeps_energy_table, probe, eye, sensor_id, keep_bad_eyes=keep_bad_eyes
  if eye ne 'top' and eye ne 'bot' then begin
    dprint, dlevel = 0, 'FEEPS EYE must be specified: "top" for the top sensors or "bot" for the bottom sensors'
    return, -1
  endif
  if undefined(probe) then begin
    dprint, dlevel = 0, 'Must specify a probe to return the proper probe specific energy table'
    return, -1
  endif else probe = strcompress(string(probe), /rem)
  
  if undefined(sensor_id) or (sensor_id lt 1 or sensor_id gt 12) then begin
    dprint, dlevel  = 0, 'Must specify the sensor_id (1-12) for this sensor)'
    return, -1.
  endif
  
  if undefined(keep_bad_eyes) then begin
    keep_bad_eyes=0
  endif
  
  table = hash()
  if not keyword_set(keep_bad_eyes) then begin
    ; Default table -- use NaN entries to mark bad eyes
    
    table['mms1-top'] = [14.0, 7.0, 16.0, 14.0, 14.0, 0.0, 0.0, 0.0, 14.0, 14.0, 17.0, 15.0]
    table['mms1-bot'] = [!values.d_nan, 14.0, 14.0, 13.0, 14.0, 0.0, 0.0, 0.0, 14.0, 14.0, -25.0, 14.0]
  
    table['mms2-top'] = [-1.0, 6.0, -2.0, -1.0, !values.d_nan, 0.0, !values.d_nan, 0.0, 4.0, -1.0, -1.0, 0.0]
    table['mms2-bot'] = [-2.0, -1.0, -2.0, 0.0, -2.0, 15.0, !values.d_nan, 15.0, -1.0, -2.0, -1.0, -3.0]
  
    table['mms3-top'] = [-3.0, !values.d_nan, 2.0, -1.0, -5.0, 0.0, 0.0, 0.0, -3.0, -1.0, -3.0, !values.d_nan]
    table['mms3-bot'] = [-7.0, !values.d_nan, -5.0, -6.0, !values.d_nan, 0.0, 0.0, 12.0, 0.0, -2.0, -3.0, -3.0]
  
    table['mms4-top'] = [!values.d_nan, !values.d_nan, -2.0, -5.0, -5.0, 0.0, !values.d_nan, 0.0, -1.0, -3.0, -6.0, -6.0]
    table['mms4-bot'] = [-8.0, !values.d_nan, -2.0, !values.d_nan, !values.d_nan, -8.0, 0.0, 0.0, -2.0, !values.d_nan, !values.d_nan, -4.0]
  endif else begin
    ; If keep_bad_eyes is requested, we replace the NaNs in the above table with zeroes
    
    table['mms1-top'] = [14.0, 7.0, 16.0, 14.0, 14.0, 0.0, 0.0, 0.0, 14.0, 14.0, 17.0, 15.0]
    table['mms1-bot'] = [0.0, 14.0, 14.0, 13.0, 14.0, 0.0, 0.0, 0.0, 14.0, 14.0, -25.0, 14.0]

    table['mms2-top'] = [-1.0, 6.0, -2.0, -1.0, 0.0, 0.0, 0.0, 0.0, 4.0, -1.0, -1.0, 0.0]
    table['mms2-bot'] = [-2.0, -1.0, -2.0, 0.0, -2.0, 15.0, 0.0, 15.0, -1.0, -2.0, -1.0, -3.0]

    table['mms3-top'] = [-3.0, 0.0, 2.0, -1.0, -5.0, 0.0, 0.0, 0.0, -3.0, -1.0, -3.0, 0.0]
    table['mms3-bot'] = [-7.0, 0.0, -5.0, -6.0, 0.0, 0.0, 0.0, 12.0, 0.0, -2.0, -3.0, -3.0]

    table['mms4-top'] = [0.0, 0.0, -2.0, -5.0, -5.0, 0.0, 0.0, 0.0, -1.0, -3.0, -6.0, -6.0]
    table['mms4-bot'] = [-8.0, 0.0, -2.0, 0.0, 0.0, -8.0, 0.0, 0.0, -2.0, 0.0, 0.0, -4.0]
   
  endelse
  
  if sensor_id ge 6 and sensor_id le 8 then begin ; ions
    ; old values, taken from intensity spectra for 12/15/15 L2 ion data downloaded on 1/24/17
    mms_energies = [57.900000, 76.800000, 95.400000, 114.10000, 133.00000, 153.70000, 177.60000, $
       205.10000, 236.70000, 273.20000, 315.40000, 363.80000, 419.70000, 484.20000,  558.60000,  609.90000]
  endif else begin
    ; old values, taken from intensity spectra for 12/15/15 L2 electron data downloaded on 1/18/17
    mms_energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
       200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d, 575.80000d]
  endelse

  return, mms_energies+(table['mms'+probe+'-'+eye])[sensor_id-1]
end