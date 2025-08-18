
; Mask out unused portions of config word
; Account for unsupported modes
; 
; -APID argument is only required for APIDs with specific exceptions
;-----------------------------------------
function thm_part_get_config_mask, config_word, is_esa, apid

    compile_opt idl2, hidden


  ;check for legacy I&T modes 
  if config_word eq '1234'xu || config_word eq '5678'xu then begin

    config = '0000'xu


  ;legacy 45B no longer supported
  endif else if config_word eq '9abc'xu then begin
  
    config = keyword_set(apid) && apid eq '45b'xu ? 'ffff'xu:'0000'xu

  
  ;legacy 45E no longer supported
  endif else if config_word eq 'def0'xu then begin
  
    config = keyword_set(apid) && apid eq '45e'xu ? 'ffff'xu:'0000'xu


  ;default mask for ESA
  endif else if is_esa then begin
  
    config = config_word and '0F0F'xu

  
  ;default mask for SST
  endif else begin
  
    ; As of 2010-06-24 all but the least significant bit of 
    ; the least significan nybble are checked.
    ;  (previously used '0F00')
    config = config_word and '0F0E'xu
  
  
  endelse


  return, ishft(config and '0F00'xu, -4) + (config and '000F'xu) 


end



; Determine ESA solar wind mode from apid and config word
; -------------------------------------------------------
function thm_part_get_config_esawind, apid, cw

    compile_opt idl2, hidden

  f = 0b

  switch apid of 
    
    ;ion data
    '454'xu:
    '455'xu:
    '456'xu: begin
      if cw eq '0302'xu || $
         cw eq '0402'xu || $
         cw eq '0702'xu || $
         cw eq '0a02'xu || $ ;not implemented?
         cw eq '0b02'xu then begin ;not implemented?
            f = 1
      end
      break
    end
    
    ;electron data
    '457'xu:
    '458'xu:
    '459'xu: begin
      if cw eq '0102'xu || $
         cw eq '0202'xu || $
         cw eq '0112'xu || $ ;not implemented?
         cw eq '0212'xu then begin ;not implemented?
            f = 1
      end
      break
    end
    
    else:  ;nothing 
  
  endswitch
  
  
  return, f
  
end



; Determine number of spins for SST modes
;-----------------------------------------
function thm_part_get_config_sstspins, cw, burst=burst, reduced=reduced, full=full

    compile_opt idl2, hidden


  ;spin # possibilities
  nspins = [1, 4, 8, 32, 64, 128, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1]

  msb = ishft(cw,-12) and '0F'xu
  lsb = ishft(cw,-4) and '0F'xu

  if keyword_set(burst) then return, 1

  if keyword_set(reduced) then return, nspins[msb]
  
  if keyword_set(full) then return, nspins[lsb]
  
  return, 0

end



; Helper procedure intended to shorted length of case statements
; and make code more readable
;--------------------------------------------------------------
pro thm_part_get_config_setvalue, u, _extra=_extra

    compile_opt idl2, hidden


;  ;for testing
;  tags = tag_names(_extra)
;  for i=0, n_elements(tags)-1 do if ~in_set(tags[i],tag_names(u)) then $
;    message, 'Error: Attempt to set non-existent variable' 


  ; set valid flag, can be overwritten by STRUCT_ASSIGN
  u.valid = 1b

  ; copy keywords specified through _extra into structure
  struct_assign, _extra, u, /nozero

end



; ESA ion, FDF survey 88x32 (A x E)
;---------------------------------
pro thm_part_get_config_454, u

    compile_opt idl2, hidden


  u.is_esa = 1b

  u.esa_solarwind_flag = thm_part_get_config_esawind(u.apid, u.config_word)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=3, sweep_mode=0

    '11'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=1

    '21'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=1

    '32'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=176, energy_bins=16, nspins=128, sweep_mode=2

    '42'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=176, energy_bins=16, nspins=32, sweep_mode=2

    '13'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=3

    '53'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=3

    '61'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=1

    '72'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=176, energy_bins=16, nspins=32, sweep_mode=2

    ;Msph SS 1 - low-E   - added 2016-03-18
    '14'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=4

    ;Msph FS 1 - low-E   - added 2016-03-18
    '24'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=4

    else:
  endcase

end



; ESA ion, RDF survey 6x16 (A x E)
;---------------------------------
pro thm_part_get_config_455, u

    compile_opt idl2, hidden


  u.is_esa = 1b

  u.esa_solarwind_flag = thm_part_get_config_esawind(u.apid, u.config_word)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)


  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=6, energy_bins=16, nspins=3, sweep_mode=0

    '11'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=1

    '21'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=50, energy_bins=24, nspins=1, sweep_mode=2

    '32'xu:thm_part_get_config_setvalue, u, $
            angle_mode=3, angle_bins=1, energy_bins=16, nspins=1, sweep_mode=3

    '42'xu:thm_part_get_config_setvalue, u, $
            angle_mode=5, angle_bins=72, energy_bins=16, nspins=1, sweep_mode=3

    '13'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=4

    '53'xu:thm_part_get_config_setvalue, u, $
            angle_mode=4, angle_bins=50, energy_bins=24, nspins=1, sweep_mode=5

    '61'xu:thm_part_get_config_setvalue, u, $
            angle_mode=6, angle_bins=6, energy_bins=32, nspins=1, sweep_mode=1

    '72'xu:thm_part_get_config_setvalue, u, $
            angle_mode=7, angle_bins=6, energy_bins=16, nspins=1, sweep_mode=3

    ;Msph SS 1 - low-E   - added 2016-03-18
    '14'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=6

    ;Msph FS 1 - low-E   - added 2016-03-18
    '24'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=50, energy_bins=24, nspins=1, sweep_mode=6

    else:
  endcase

end



; ESA ion, FDF Burst 88x32 (A x E)
;---------------------------------
pro thm_part_get_config_456, u

    compile_opt idl2, hidden


  u.is_esa = 1b

  u.esa_solarwind_flag = thm_part_get_config_esawind(u.apid, u.config_word)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=0

    '11'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=1

    '21'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=1

    '32'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=176, energy_bins=16, nspins=1, sweep_mode=2

    '42'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=176, energy_bins=16, nspins=1, sweep_mode=2

    '13'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=3

    '53'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=3

    '61'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=1

    '72'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=176, energy_bins=16, nspins=1, sweep_mode=2

    ;Msph SS 1 - low-E   - added 2016-03-18
    '14'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=4

    ;Msph FS 1 - low-E   - added 2016-03-18
    '24'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=4

    else:
  endcase

end



; ESA electron, FDF survey 88x32 (A x E)
;-------------------------------------
pro thm_part_get_config_457, u

    compile_opt idl2, hidden


  u.is_esa = 1b

  u.esa_solarwind_flag = thm_part_get_config_esawind(u.apid, u.config_word)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)


  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=3, sweep_mode=0

    '11'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=1

    '21'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=1

    '31'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=15, nspins=1, sweep_mode=3

    '12'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=2

    '22'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=2
    
    ; Magnetospheric slow survey 4 (reduced energy map) - added ????-??-??
    '14'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=4
    
    ; Magnetospheric fast survey 4 (reduced energy map) - added ????-??-??
    '24'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=4
    
    ; Low energy magnetospheric mode  - Added 2013-07-26
    '34'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=88, energy_bins=15, nspins=1, sweep_mode=5

    ; Revised magnetospheric mode  - added 2014-03-26
    '15'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=6

    ; Revised magnetospheric mode  - added 2014-03-26
    '25'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=6

    ;Msph SS 1 - low-E   - added 2016-03-18
    '16'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=128, sweep_mode=7

    ;Msph FS 1 - low-E   - added 2016-03-18
    '26'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=32, sweep_mode=7

    else:
  endcase

end



; ESA electron, RDF survey 6x16 (A x E)
;--------------------------------------
pro thm_part_get_config_458, u

    compile_opt idl2, hidden


  u.is_esa = 1b

  u.esa_solarwind_flag = thm_part_get_config_esawind(u.apid, u.config_word)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=6, energy_bins=16, nspins=3, sweep_mode=0

    '11'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=1

    '21'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=6, energy_bins=32, nspins=1, sweep_mode=1

    '31'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=32, energy_bins=32, nspins=1, sweep_mode=1

    '12'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=2

    '22'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=6, energy_bins=32, nspins=1, sweep_mode=2
    
    ; Magnetospheric slow survey 4 (reduced energy map) - added ????-??-??
    '14'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=3
    
    ; Magnetospheric fast survey 4 (reduced energy map) - added ????-??-??
    '24'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=6, energy_bins=32, nspins=1, sweep_mode=3
    
    ; Low energy magnetospheric mode  - Added 2013-07-26
    '34'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=3

    ; Revised low-energy magnetospheric modes
    '15'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=4

    ; Revised low-energy magnetospheric modes
    '25'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=4

    ;Msph SS 1 - low-E   - added 2016-03-18
    '16'xu:thm_part_get_config_setvalue, u, $
            angle_mode=1, angle_bins=1, energy_bins=32, nspins=1, sweep_mode=5

    ;Msph FS 1 - low-E   - added 2016-03-18
    '26'xu:thm_part_get_config_setvalue, u, $
            angle_mode=2, angle_bins=6, energy_bins=32, nspins=1, sweep_mode=5
    
    else:
  endcase

end



; ESA electron, FDF burst 88x32 (A x E)
;--------------------------------------
pro thm_part_get_config_459, u

    compile_opt idl2, hidden


  u.is_esa = 1b

  u.esa_solarwind_flag = thm_part_get_config_esawind(u.apid, u.config_word)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=0

    '11'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=1

    '21'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=1

    '31'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=1

    '12'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=2

    '22'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=2
    
    ; Magnetospheric slow survey 4 (reduced energy map) - added ????-??-??
    '14'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=3
    
    ; Magnetospheric fast survey 4 (reduced energy map) - added ????-??-??
    '24'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=3
    
    ; Low energy magnetospheric mode  - Added 2013-07-26
    '34'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=3

    ; Revised low-energy magnetospheric modes
    '16'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=4

    ; Revised low-energy magnetospheric modes
    '26'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=4

    ;Msph SS 1 - low-E    - added 2016-03-18
    '16'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=5

    ;Msph FS 1 - low-E    - added 2016-03-18
    '26'xu:thm_part_get_config_setvalue, u, $
            angle_mode=0, angle_bins=88, energy_bins=32, nspins=1, sweep_mode=5
    
    else:
  endcase

end



; SST ion, FDF survey 64x16 (A x E)
;----------------------------------
pro thm_part_get_config_45A, u

    compile_opt idl2, hidden

  u.is_sst = 1b

  ; get # of spins
  u.nspins = thm_part_get_config_sstspins(u.config_word, /full)  


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_bins=64, energy_bins=16

    '10'xu:thm_part_get_config_setvalue, u, $
            angle_bins=128, energy_bins=16

    '20'xu:thm_part_get_config_setvalue, u, $
            angle_bins=64, energy_bins=16

    '30'xu:thm_part_get_config_setvalue, u, $
            angle_bins=32, energy_bins=16

    '40'xu:thm_part_get_config_setvalue, u, $
            angle_bins=32, energy_bins=16
    else:
  endcase

end



; SST ion, RDF survey 6x8 (A x E)
;---------------------------------
pro thm_part_get_config_45B, u

    compile_opt idl2, hidden


  u.is_sst = 1b

  ; get # of spins
  u.nspins = thm_part_get_config_sstspins(u.config_word, /reduced)


  ; mask unused bits from config word and return shortened version
  ; include APID to check for unsupported modes 
  config = thm_part_get_config_mask(u.config_word, u.is_esa, u.apid)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_bins=6, energy_bins=16

    '10'xu:thm_part_get_config_setvalue, u, $
            angle_bins=6, energy_bins=16

    '20'xu:thm_part_get_config_setvalue, u, $
            angle_bins=1, energy_bins=16

    '30'xu:thm_part_get_config_setvalue, u, $
            angle_bins=1, energy_bins=16

    '40'xu:thm_part_get_config_setvalue, u, $
            angle_bins=6, energy_bins=16
    else:
  endcase


end



; SST ion, FDF burst 64x16 (A x E)
;---------------------------------
pro thm_part_get_config_45C, u

    compile_opt idl2, hidden


  u.is_sst = 1b

  ; get # of spins
  u.nspins = thm_part_get_config_sstspins(u.config_word, /burst)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  switch config of
    '00'xu:
    '10'xu:
    '20'xu:
    '30'xu:
    '40'xu:thm_part_get_config_setvalue, u, $
            angle_bins=64, energy_bins=16
    else:
  endswitch

end



; SST electron, FDF survey 64x16 (A x E)
;---------------------------------------
pro thm_part_get_config_45D, u

    compile_opt idl2, hidden


  u.is_sst = 1b

  ; get # of spins
  u.nspins = thm_part_get_config_sstspins(u.config_word, /full)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_bins=64, energy_bins=16

    '10'xu:thm_part_get_config_setvalue, u, $
            angle_bins=128, energy_bins=16

    '20'xu:thm_part_get_config_setvalue, u, $
            angle_bins=64, energy_bins=16

    '30'xu:thm_part_get_config_setvalue, u, $
            angle_bins=32, energy_bins=16

    '40'xu:thm_part_get_config_setvalue, u, $
            angle_bins=32, energy_bins=16
    
    '50'xu:thm_part_get_config_setvalue, u, $
            angle_bins=64, energy_bins=16
    else:
  endcase

end



; SST electron, RDF survey 6x8 (A x E)
;--------------------------------------
pro thm_part_get_config_45E, u

    compile_opt idl2, hidden


  u.is_sst = 1b

  ; get # of spins
  u.nspins = thm_part_get_config_sstspins(u.config_word, /reduced)
  

  ; mask unused bits from config word and return shortened version
  ; include APID to check for unsupported modes
  config = thm_part_get_config_mask(u.config_word, u.is_esa, u.apid)

  
  ; determine attributes from masked config word
  case config of
    '00'xu:thm_part_get_config_setvalue, u, $
            angle_bins=6, energy_bins=16

    '10'xu:thm_part_get_config_setvalue, u, $
            angle_bins=6, energy_bins=16

    '20'xu:thm_part_get_config_setvalue, u, $
            angle_bins=1, energy_bins=16

    '30'xu:thm_part_get_config_setvalue, u, $
            angle_bins=1, energy_bins=16

    '40'xu:thm_part_get_config_setvalue, u, $
            angle_bins=6, energy_bins=16
    
    '50'xu:thm_part_get_config_setvalue, u, $
            angle_bins=6, energy_bins=16
    else:
  endcase

end



; SST electron, FDF burst 64x16 (A x E)
; **NOT CURRENTLY IN USE
;--------------------------------------
pro thm_part_get_config_45F, u

    compile_opt idl2, hidden


  u.is_sst = 1b

  ; get # of spins
  u.nspins = thm_part_get_config_sstspins(u.config_word, /burst)


  ; mask unused bits from config word and return shortened version 
  config = thm_part_get_config_mask(u.config_word, u.is_esa)

  
  ; determine attributes from masked config word
  switch config of
    '00'xu:
    '10'xu:
    '20'xu:
    '30'xu:
    '40'xu:
    '50'xu:thm_part_get_config_setvalue, u, $
            angle_bins=64, energy_bins=16
    else:
  endswitch

end


;+
;NAME:
;  thm_part_get_config.pro
;
;PURPOSE:
;  Returns structure containing particle distribution 
;  attributes based on APID and config word. 
;
;INPUT:
;  APID: Numerical APID (e.g. '045A'xu)
;  config_word: Two-byte config word 
;               Can be passed in as:  
;                 -single element variable (e.g. '1234'xu)
;                 -two element array (e.g. ['12'xu,'34'xu])
;                 -two separate arguments (e.g. '12'xu, '34'xu)
;  config_word2: (optional) see above
;
;EXAMPLES
;  struct = thm_part_get_config( '454'xu, '0101'xu)
;  struct = thm_part_get_config( '454'xu, ['01'xu,01'xu])
;  struct = thm_part_get_config( '454'xu, '01'xu, '01'xu)
;
;OUTPUT:
;  Returns anonymous structure containing distribution attributes:
;    {  apid:            APID from input
;       config_word:     Config word from input
;       
;       is_esa:          Flag denoting esa data
;       is_sst:          Flag denoting sst data
;       
;       valid:           Flag for valid data (1b=valid)
;       
;       nspins:          Number of spins per distribution
;       angle_bins:      Number of angle bins
;       energy_bins:     Number of energy bins
;       
;       sweep_mode:      Integer denoting ESA sweep mode index (thm_read_esa_sweep_*)
;       angle_mode:      Integer denoting ESA angle mode index (thm_read_esa_angle_*)
;       esa_solar_wind:  Solar wind flag for ESA
;     }
;
;NOTES:
;  2016-08 - This routine is not currently used but could be useful.
;
;-
function thm_part_get_config, apid0, config_word0, config_word1

    compile_opt idl2, hidden


  ;only accept byte, int, long, uint, ulong
  if total( size(/type, apid0) eq [1,2,3,12,13] ) lt 1  then begin
    dprint, dlevel=1, 'Must specify APID as byte or int ( e.g. ''45A''xu )'
    return, -1
  endif

  if total( size(/type, config_word0) eq [1,2,3,12,14] ) lt 1 then begin 
    dprint, dlevel=1, 'Must specify CONFIG_WORD as byte or int. ( e.g. ''9abc''xu )'
    return, -1
  endif

  if n_params() eq 3 then begin
    if total( size(/type, config_word1) eq [1,2,3,12,14] ) lt 1 then begin 
      dprint, dlevel=1, 'Must specify CONFIG_WORD as byte or int. ( e.g. ''9abc''xu )'
      return, -1
    endif
  endif


  ;copy input and ensure correct type
  apid = uint(apid0)
  if n_params() eq 3 then begin
    config_word = uint([config_word0,config_word1])
  endif else begin
    config_word = uint(config_word0)
  endelse
  
   
  ;account for possible two element input (esa load routines)
  if n_elements(config_word) eq 2 then begin
    config_word = ishft(config_word[0],8) or config_word[1]
  endif else if n_elements(config_word) gt 1 then begin
    dprint, dlevel=1, 'Too many elements in config word.  See usage'
    return, -1
  endif


  ; Initialize structure to be returned
  u = {   $
          apid: apid, $
          config_word: config_word, $
  
          is_esa: 0b, $
          is_sst: 0b, $
          
          valid: 0b, $
          
          nspins: 0L, $
          angle_bins: -1L, $
          energy_bins: -1L, $
          
          sweep_mode: 0L, $
          angle_mode: 0L,  $
          esa_solarwind_flag: 0b $
       }


  ; Set attributes based on APID
  case apid of
  
    ;ESA ion, FDF survey 88x32 (A x E)
    '454'xu: thm_part_get_config_454, u
    
    ;ESA ion, RDF survey 6x16
    '455'xu: thm_part_get_config_455, u
    
    ;ESA ion, FDF burst 88x32
    '456'xu: thm_part_get_config_456, u
    
    ;ESA electron, FDF survey 88x32
    '457'xu: thm_part_get_config_457, u
    
    ;ESA electron, RDF survey 6x16
    '458'xu: thm_part_get_config_458, u
    
    ;ESA electron, FDF burst 88x32
    '459'xu: thm_part_get_config_459, u
    
    ;SST ion, FDF survey 64x16
    '45A'xu: thm_part_get_config_45A, u
    
    ;SST ion, RDF survey 6x8
    '45B'xu: thm_part_get_config_45B, u
    
    ;SST ion, FDF burst, 64x16
    '45C'xu: thm_part_get_config_45C, u
    
    ;SST electron, FDF survey 64x16
    '45D'xu: thm_part_get_config_45D, u
    
    ;SST electron, RDF survey 6x8
    '45E'xu: thm_part_get_config_45E, u
    
    ;SST electron, FDF burst 64x16 (not used)
    '45F'xu: thm_part_get_config_45F, u
    
    else: begin
      dprint, dlevel=1, 'Uknown apid: ' + string(apid, format='(z)')
    end
  
  endcase

  return, u

end
