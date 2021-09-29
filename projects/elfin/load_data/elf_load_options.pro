;+
;Procedure:
;  elf_load_options
;
;Purpose:
;  Provides information on valid data rates, levels, and datatypes
;  for ELFIN science instruments.
;
;  Valid load options for a specified instrument will be returned
;  via a corresponding keyword.

;  Each output keyword may be used as an input to narrow the results
;  the the contingent options.
;
;Calling Sequence:
;  elf_load_options, instrument=instrument
;                    [,rate=rate] [,level=level], [,datatype=datatype]
;                    [valid=valid]
;
;Example Usage:
;
;
;Input:
;  instrument:  (string) Instrument designation, e.g. 'afg'
;  rate:  (string)(array) Data rate e.g. 'fast', 'srvy'
;  level:  (string)(array) Data processing level e.g. 'l1b', 'ql'
;  datatype:  (string)(array) Data type, e.g. 'moments'
;
;Output:
;  rate:  If not used as an input this will contain all valid
;         rates for the instrument.
;  level:  If not used as an input this will contain all valid
;          levels, given any specified rate.
;  datatype:  If not used as an input this will contain all valid
;             datatypes, given any specified rate and level.
;  valid:  1 if valid outputs were found, 0 otherwise
;
;Notes:
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-09-22 12:22:45 -0700 (Thu, 22 Sep 2016) $
;$LastChangedRevision: 21901 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/elfin/elf_load_options.pro $
;-

;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for State files
;-
function elf_load_options_state

  compile_opt idl2, hidden

  s = { $
    v1: { $
    pred: $
    ['pos_gei', $
     'vel_gei', $
     'att_gei' $
    ], $
    defn: $
    ['pos_gei', $
     'vel_gei', $
     'att_gei' $
    ] $
   } $
  }
  
return, s

end


;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for MRM ACB
;-
function elf_load_options_mrma
  compile_opt idl2, hidden

  s = { $
    v1: { $
    l1: ['mrma' $
    ], $
    l2: ['mrma' $
    ] $
   } $
 }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for MRM IDPU
;-
function elf_load_options_mrmi
  compile_opt idl2, hidden

  s = { $
    v1: { $
    l1: ['mrmi' $
    ], $
    l2: ['mrmi' $
    ] $
  } $
}

return, s

end


;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for engineering data
;-
function elf_load_options_eng
  compile_opt idl2, hidden

  s = { $
    v1: { $
    l1: ['sips_5v0_voltage', $
    'sips_5v0_current', $
    'sips_input_voltage', $
    'sips_input_current', $
    'sips_input_temp', $
    'epd_biash', $
    'epd_biasl', $
    'epd_efe_temp', $
    'idpu_msp_version', $
    'fgm_3_3_volt', $
    'fgm_8_volt', $
    'fgm_analog_ground', $
    'fgm_sh_temp', $
    'fgm_eu_temp', $
    'fc_chassis_temp', $
    'fc_idpu_temp', $
    'fc_batt_temp_1', $
    'fc_batt_temp_2', $
    'fc_batt_temp_3', $
    'fc_batt_temp_4', $
    'fc_avionics_temp_1', $
    'fc_avionics_temp_2' $
    ], $
    l2: ['sips_5v0_voltage', $
    'sips_5v0_current', $
    'sips_input_voltage', $
    'sips_input_current', $
    'sips_input_temp', $
    'epd_biash', $
    'epd_biasl', $
    'epd_efe_temp', $
    'idpu_msp_version', $
    'fgm_3_3_volt', $
    'fgm_8_volt', $
    'fgm_analog_ground', $
    'fgm_sh_temp', $
    'fgm_eu_temp', $
    'fc_chassis_temp', $
    'fc_idpu_temp', $
    'fc_batt_temp_1', $
    'fc_batt_temp_2', $
    'fc_batt_temp_3', $
    'fc_batt_temp_4', $
    'fc_avionics_temp_1', $
    'fc_avionics_temp_2' $
    ] $
  } $
}

return, s

end


;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for FGM
;-
function elf_load_options_fgm

  compile_opt idl2, hidden

  s = { $
    fast: { $
      l1: ['fgf' $
      ], $
      l2: [ $
      'fgf_gei', $
      'fgf_dsl', $
      'fgf_sm' $
      ] $
    }, $
    srvy: { $
      l1: ['fgs' $
      ], $
      l2: [ $
      'fgs_gei', $
      'fgs_dsl', $
      'fgs_sm' $
      ] $
    } $
  }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for EPD
;-
function elf_load_options_epd

  compile_opt idl2, hidden

  s = { $
    fast: { $
      l1: [ $
      'pif', $
      'pef' $
      ], $
      l2: [ $
      'pif_eflux', $
      'pef_eflux' $
      ] $
    }, $
    srvy: { $
      l1: [ $
      'pis', $
      'pes' $
      ], $
      l2: [ $
      'pis_eflux', $
      'pes_eflux' $
      ] $
    } $
   }

return, s

end


;+
;Purpose:
;  Extracts valid rate/level/datatype based on input.
;  If an input is specified then only subsets of that input are checked.
;  If an input is not specified then all possible matches are used.
;
;    e.g.  -If rate is specified then only levels and datatypes for
;           that rate are retuned.
;          -If nothing is specified then all rates/levels/datatypes
;           are returned.
;          -If all three are specified then then the output will
;           be identical to the input (if the input is valid).
;-
pro elf_load_options_getvalid, $
  s, $

  rate_in=rate, $
  level_in=level, $
  datatype_in=datatype, $

  rates_out=rates_out, $
  levels_out=levels_out, $
  datatypes_out=datatypes_out

  compile_opt idl2, hidden


  ;get all rates for this instrument
  valid_rates = tag_names(s)

  ;loop over rates
  for i=0, n_elements(valid_rates)-1 do begin

    ;if the input is specified and doesn't match then ignore
    if is_string(rate) then begin
      if ~in_set(valid_rates[i], strupcase(rate)) then continue
    endif

    ;if input matched or wasn't specified then add this to the output list
    rates_out = array_concat(valid_rates[i], rates_out)

    ;get all levels for this rate
    valid_levels = tag_names(s.(i))

    ;loop over levels
    for j=0, n_elements(valid_levels)-1 do begin

      ;if the input is specified but doesn't match then ignore
      if is_string(level) then begin
        if ~in_set(valid_levels[j], strupcase(level)) then continue
      endif

      ;if input matched or wasn't specified then add this to the output list
      levels_out = array_concat(valid_levels[j], levels_out)

      ;get datatypes for this rate/level
      valid_datatypes = s.(i).(j)

      ;if input is specified and matches then add matching entries
      ;otherwise add all entries
      if is_string(datatype) then begin
        intersect = ssl_set_intersection(valid_datatypes,strupcase(datatype))
        if is_string(intersect) then begin
          datatypes_out = array_concat(intersect, datatypes_out)
        endif
      endif else begin
        datatypes_out = array_concat(valid_datatypes, datatypes_out)
      endelse

    endfor

  endfor

end


pro elf_load_options, $
  instrument, $
  rate=rate, $
  level=level, $
  datatype=datatype, $
  valid=valid

  compile_opt idl2, hidden

  valid = 0

  if ~is_string(instrument) then begin
    dprint, dlevel=1, 'No instrument provided'
    return
  endif

  ;Get structure specifying availability of data types
  ;---------------------------------------------------
  case strupcase(instrument) of
    'FGM': s = elf_load_options_fgm()
    'EPD': s = elf_load_options_epd()
    'STATE': s = elf_load_options_state()
    'ENG': s = elf_load_options_eng()
    else: begin
      dprint, dlevel=1, 'Instrument "'+instrument+'" not recognized'
      return
    endelse
  endcase


  ;Extract information from structure
  ;---------------------------------------------------

  ;get valid options based on input
  ;  -if one or more of the *_out quantities is missing
  ;   afterward then no valid matches were found
  elf_load_options_getvalid, s, rate_in=rate, level_in=level, datatype_in=datatype, $
    rates_out=rates_out, levels_out=levels_out, datatypes_out=datatypes_out

  valid = ~undefined(rates_out) && ~undefined(levels_out) && ~undefined(datatypes_out)

  if ~valid then begin
    return
  endif

  ;pass out any information that wasn't specified as input
  if undefined(rate) then rate = strlowcase(spd_uniq(rates_out))
  if undefined(level) then level = strlowcase(spd_uniq(levels_out))
  if undefined(datatype) then datatype = strlowcase(spd_uniq(datatypes_out))


end