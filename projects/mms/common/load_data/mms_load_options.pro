;+
;Procedure:
;  mms_load_options
;
;Purpose:
;  Provides information on valid data rates, levels, and datatypes
;  for MMS science instruments.
;
;  Valid load options for a specified instrument will be returned
;  via a corresponding keyword.

;  Each output keyword may be used as an input to narrow the results
;  the the contingent options.
;
;Calling Sequence:
;  mms_load_options, instrument=instrument
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
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/mms_load_options.pro $
;-

;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for MEC files
;-
function mms_load_options_mec

    compile_opt idl2, hidden

    s = { srvy: { $
        l2: [ 'epht89d', 'epht89q', 'ephts04d' ] $
    } $
  }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for ASPOC
;-
function mms_load_options_aspoc

    compile_opt idl2, hidden


    s = { srvy: { $
        sitl: [ 'aspoc', 'asp1', 'asp2' ], $
        l1b: [ 'aspoc', 'asp1', 'asp2' ], $
        l2: [ 'aspoc', 'asp1', 'asp2' ], $
        ql:  [ 'aspoc', 'asp1', 'asp2' ] $
    } $

}


return, s

end

;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for EDP
;-
function mms_load_options_edp

    compile_opt idl2, hidden

    s = { $
        fast: { $
            ql: [ $
            'dce', $
            'dce2d' $
            ], $
            l2: ['dce', 'scpot'] $
           }, $
         brst: { $
            l2: ['dce', 'hmfe', 'scpot'] $
            }, $
         slow: { $
            l2: ['dce', 'scpot'] $
            } $
}

return, s

end

;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for DSP
;-
function mms_load_options_dsp

    compile_opt idl2, hidden

s = { $
      slow: { $
            l1a: [ $
                'epsd' $
            ], $
            l2: [ $
                'bpsd', $
                'epsd' $
            ] $
      }, $
      fast: { $
              l1a: [ $
                     'epsd', $
                     'swd' $
                   ], $
              l2: [ $
                     'bpsd', $
                     'epsd', $
                     'swd' $
                   ] $
            }, $
      srvy: { $
              l1a: [ $
                     '173', $
                     '174', $
                     '175', $
                     '176', $
                     '177', $
                     '178', $
                     '179' $
                   ], $
              l1b: [ $
                     '173', $
                     '174', $
                     '175', $
                     '176', $
                     '177', $
                     '178' $
                   ] $
            } $
    }

return, s

end

;+
;Purpose:
;  Helper function to return structure describing
;  the available data types for EDI
;-
function mms_load_options_edi

    compile_opt idl2, hidden

s = { $
      brst: { $
              l1a: [ $
                     'amb' $
                   ], $
              l2: [ 'amb', 'efield', 'q0'] $
            }, $
       srvy: { $
              l2: [ 'amb', 'efield', 'q0'] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for AFG or DFG
;-
function mms_load_options_fgm

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1a: [ '' ], $
              l1b: [ '' ], $
              ql: [ '' ], $
              l2: [''], $
              l2pre: [''] $
            }, $
      fast: { $
              l1a: [ '' ], $
              l1b: [ '' ], $
              ql: [ '' ] $
            }, $
      slow: { $
              l1a: [ '' ], $
              l1b: [ '' ], $
              ql: [ '' ] $
            }, $
      srvy: { $
              l1a: [ '' ], $
              l1b: [ '' ], $
              ql:  [ '' ], $
              l2: [''], $
              l2pre: [''] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for EIS
;-
function mms_load_options_eis

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1a: [ $
                     'extof', $
                     'phxtof' $
                   ], $
              l1b: [ $
                     'extof', $
                     'phxtof' $
                   ], $
               l2: [ $
                     'extof', $
                     'phxtof' $
               ] $
            }, $
      srvy: { $
              l1a: [ $
                     'electronenergy', $
                     'extof', $
                     'partenergy', $
                     'phxtof' $
                   ], $
              l1b: [ $
                     'electronenergy', $
                     'extof', $
                     'partenergy', $
                     'phxtof' $
                   ], $
               l2: [ $
                     'electronenergy', $
                     'extof', $
                     'phxtof' $
               ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for FEEPS
;-
function mms_load_options_feeps

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1a: [ $
                     'electron-bottom', $
                     'electron-top', $
                     'ion-bottom', $
                     'ion-top' $
                   ], $
              l2: [ $
                     'electron', $
                     'ion' $
                   ] $
            }, $
      srvy: { $
              l1a: [ $
                     'electron-bottom', $
                     'electron-top', $
                     'ion-bottom', $
                     'ion-top' $
                   ], $
              sitl: [ $
                   'electron' $
                   ], $
              l1b: [ $
                     'electron', $
                     'ion' $
                   ], $
              l2: [ $
                     'electron', $
                     'ion' $
                   ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for FPI
;-
function mms_load_options_fpi

    compile_opt idl2, hidden
    
s = { $
      fast: { $
              sitl: [ '' ], $
              trig: [ '' ], $
              L2: [ 'des-dist', 'des-moms', 'dis-dist', 'dis-moms' ] $
            }, $

      brst: { $
              L2: [ 'des-dist', 'des-moms', 'dis-dist', 'dis-moms' ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for HPCA
;-
function mms_load_options_hpca

    compile_opt idl2, hidden
    
s = { $
      brst: { $
              l1a: [ $
                     'spinangles' $
                   ], $
              l1b: [ $
                     'count_rate', $
                     'flux', $
                     'vel_dist', $
                     'rf_corr', $
                     'bkgd_corr', $
                     'moments' $
                   ], $
              l2:  [ $
                     'ion', $
                     'moments' $
                     ] $
            }, $
      srvy: { $
              l1a: [ $
                     'spinangles' $
                   ], $
              l1b: [ $
                     'count_rate', $
                     'flux', $
                     'vel_dist', $
                     'rf_corr', $
                     'bkgd_corr', $
                     'moments' $
                   ], $
              l2:  [ $
                   'ion', $
                   'moments' $
                   ], $
              sitl:[ $
                     'count_rate', $
                     'flux', $
                     'vel_dist', $
                     'rf_corr', $
                     'bkgd_corr', $
                     'moments' $
                   ] $
            } $
    }

return, s

end


;+
;Purpose:
;  Helper function to return structure describing 
;  the available data types for SCM
;-
function mms_load_options_scm

    compile_opt idl2, hidden
    
;use placeholder where datatype will go
s = { $
      brst: { $
              l1a: [ $
                     'scb', $
                     'schb' $
                   ], $
              l2: [ $
                     'scb', $
                     'schb' $
                   ] $
            }, $
      fast: { $
              l1a: [ $
                     'scf' $
                   ], $
              l1b: [ $
                     'scf' $
                   ], $
              l2: [ $
                     'scf' $
               ] $
            }, $
      slow: { $
              l1a: [ $
                     'scs' $
                   ], $
              l2: [ $
                     'scs' $
                   ] $
            }, $
      srvy: { $
              l1a: [ $
                     'cal', $
                     'scm' $
                   ], $
              l2: [ $
                   'scsrvy' $
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
pro mms_load_options_getvalid, $
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

pro mms_load_options, $
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
  'AFG': s = mms_load_options_fgm()
  'DFG': s = mms_load_options_fgm()
  'FGM': s = mms_load_options_fgm()
  'EIS': s = mms_load_options_eis()
  'FEEPS': s = mms_load_options_feeps()
  'FPI': s = mms_load_options_fpi()
  'HPCA': s = mms_load_options_hpca()
  'SCM': s = mms_load_options_scm()
  'EDI': s = mms_load_options_edi()
  'DSP': s = mms_load_options_dsp()
  'EDP': s = mms_load_options_edp()
  'ASPOC': s = mms_load_options_aspoc()
  'MEC': s = mms_load_options_mec()
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
mms_load_options_getvalid, s, rate_in=rate, level_in=level, datatype_in=datatype, $
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