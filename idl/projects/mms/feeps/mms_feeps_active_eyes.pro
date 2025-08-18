;+
; Function:
;     mms_feeps_active_eyes
;
; Purpose:
;    this function returns the FEEPS active eyes,
;    based on date/probe/species/rate
;
; Output:
;    Returns a hash table containing 2 hash tables:
;       output['top'] -> maps to the active top eyes
;       output['bottom'] -> maps to the active bottom eyes
; 
; Notes:
; 1) Burst mode should include all sensors (TOP and BOTTOM):
;     electrons: [1, 2, 3, 4, 5, 9, 10, 11, 12]
;     ions: [6, 7, 8]
; 
; 2) SITL should return (TOP only):
;     electrons: set_intersection([5, 11, 12], active_eyes)
;     ions: None
;     
; 3) From Drew Turner, 9/7/2017, srvy mode:
; 
;   - before 16 August 2017:
;      electrons: [3, 4, 5, 11, 12]
;      iond: [6, 7, 8]
; 
;   - after 16 August 2017:
;       MMS1
;         Top Eyes: 3, 5, 6, 7, 8, 9, 10, 12
;         Bot Eyes: 2, 4, 5, 6, 7, 8, 9, 10
;
;       MMS2
;         Top Eyes: 1, 2, 3, 5, 6, 8, 10, 11
;         Bot Eyes: 1, 4, 5, 6, 7, 8, 9, 11
;
;       MMS3
;         Top Eyes: 3, 5, 6, 7, 8, 9, 10, 12
;         Bot Eyes: 1, 2, 3, 6, 7, 8, 9, 10
;
;       MMS4
;         Top Eyes: 3, 4, 5, 6, 8, 9, 10, 11
;         Bot Eyes: 3, 5, 6, 7, 8, 9, 10, 12
;   
;   
;$LastChangedBy: jwl $
;$LastChangedDate: 2024-03-27 16:34:54 -0700 (Wed, 27 Mar 2024) $
;$LastChangedRevision: 32511 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/feeps/mms_feeps_active_eyes.pro $
;-

function mms_feeps_active_eyes, trange, probe, data_rate, species, level, keep_bad_eyes = keep_bad_eyes
  if undefined(keep_bad_eyes) then begin
    keep_bad_eyes = 0
  endif

  ; handle burst mode first
  if strlowcase(data_rate) eq 'brst' and strlowcase(species) eq 'electron' then return, hash('top', [1, 2, 3, 4, 5, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 9, 10, 11, 12])
  if strlowcase(data_rate) eq 'brst' and strlowcase(species) eq 'ion' then return, hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
  
  ; old eyes, srvy mode, prior to 16 August 2017
  if strlowcase(species) eq 'electron' then sensors = hash('top', [3, 4, 5, 11, 12], 'bottom', [3, 4, 5, 11, 12]) else sensors = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
  
  ; srvy mode, after 16 August 2017
  if time_double(trange[0]) ge time_double('2017-08-16') and strlowcase(data_rate) eq 'srvy' then begin
    active_table = hash()
    if not keep_bad_eyes then begin
      ; Normal case, without bad eyes
      active_table['1-electron'] = hash('top', [3, 5, 9, 10, 12], 'bottom', [2, 4, 5, 9, 10])
      active_table['1-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
    
      active_table['2-electron'] = hash('top', [1, 2, 3, 5, 10, 11], 'bottom', [1, 4, 5, 9, 11])
      active_table['2-ion'] = hash('top', [6, 8], 'bottom', [6, 7, 8])
    
      active_table['3-electron'] = hash('top', [3, 5, 9, 10, 12], 'bottom', [1, 2, 3, 9, 10])
      active_table['3-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])
    
      active_table['4-electron'] = hash('top', [3, 4, 5, 9, 10, 11], 'bottom', [3, 5, 9, 10, 12])
      active_table['4-ion'] = hash('top', [6, 8], 'bottom', [6, 7, 8])
    endif else begin
      ; If keep_bad_eyes, include everything
      active_table['1-electron'] = hash('top', [1, 2, 3, 4, 5, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 9, 10, 11, 12])
      active_table['1-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])

      active_table['2-electron'] = hash('top', [1, 2, 3, 4, 5, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 9, 10, 11, 12])
      active_table['2-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])

      active_table['3-electron'] = hash('top', [1, 2, 3, 4, 5, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 9, 10, 11, 12])
      active_table['3-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])

      active_table['4-electron'] = hash('top', [1, 2, 3, 4, 5, 9, 10, 11, 12], 'bottom', [1, 2, 3, 4, 5, 9, 10, 11, 12])
      active_table['4-ion'] = hash('top', [6, 7, 8], 'bottom', [6, 7, 8])

    endelse
    sensors = active_table[strcompress(string(probe), /rem)+'-'+species]
    if strlowcase(level) eq 'sitl' then return, hash('top', ssl_set_intersection(sensors['top'], [5, 11, 12]), 'bottom', [])
  endif
  if strlowcase(level) eq 'sitl' then return, hash('top', [5, 11, 12], 'bottom', [])
  return, sensors
end