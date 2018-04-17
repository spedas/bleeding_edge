;+
;NAME:
; thm_data2load
;PURPOSE:
; returns a list of variables that can be loaded for a given THEMIS
; instrument. For the most part, it calls the appropriate thm_load
; routine with the /valid_names keyword set. The dataypes and
; valid_names keywords are used inconsistently in the thm_loads, and
; do not allow for the distinction between level2 data that is
; to be input from level2 files, and level2 data the is to be input
; from level1 files and calbrated, cotrans'ed, etc... but has the same
; name as an L2 variable. Designed to be called from
; thm_ui_valid_dtype.pro
;CALLING SEQUENCE:
; dtyp = thm_data2load(instrument, level)
;INPUT:
; instrument = the THEMIS instrument: one of:
;           ['asi', 'ask', 'esa', 'efi', 'fbk', 'fft', 'fgm', 'fit', 'gmag', $
;            'mom', 'scm', 'spin', 'sst', 'state', 'bau', 'hsk', 'trg']
; level = 'l1' for any data that can be gotten from the l1 file --
;         including calibrated, etc... 'l2' for data gotten from L2
;         files. 'l10' for data that only is loaded from L1 files. For
;         ESA data, 'L10' data and 'L1' data are gotten from the
;         packet files.
;OUTPUT:
; dtyp = a string array that can be used as an input to the datatype
;        keyword for the given instrument
;HISTORY:
; started on 31-Jan-2008, jmm, jimm@ssl.berkeley.edu, this is under
; development for the next 6 months or so.
; 9-apr-2008, jmm, added all instruments, for Version 4_00
;$LastChangedBy: jimm $
;$LastChangedDate: 2018-04-16 10:47:48 -0700 (Mon, 16 Apr 2018) $
;$LastChangedRevision: 25050 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_data2load.pro $
;-
function thm_valid_variables, instrument, level
    compile_opt idl2, hidden
    case instrument of
    'asi' : begin ; All-sky imager (ASI)
        if(level eq 'l1' or level eq 'l10') then begin
            instr_data = ['asf', 'ast']
        endif else begin
            instr_data = ''
        endelse
    end
    'ask' : begin ; All-sky imager keograms
        if(level eq 'l1' or level eq 'l10') then begin
            instr_data = 'ask'
        endif else begin
            instr_data = ''
        endelse
    end
    'esa' : begin ; Electrostatic analyzer
        if(level eq 'l1' or level eq 'l10') then begin
            instr_data = ['peif', 'peir', 'peib', 'peef', 'peer', 'peeb']
        endif else begin
            instr_type = ['peif','peir','peib','peef','peer','peeb']
            valid_variables = ['mode', 'en_eflux', 'sc_pot', 'magf', $
                               'density', 'avgtemp', 'vthermal', 'flux', $
                               'ptens', 'mftens', 't3', 'symm', 'symm_ang', $
                               'magt3', 'velocity_dsl', 'velocity_gse', $
                               'velocity_gsm', 'data_quality']
            instr_data = ''
            for k = 0, n_elements(instr_type)-1 Do instr_data = [instr_data, instr_type[k]+'_'+valid_variables]
            instr_data = [instr_data[1:*], 'iesa_solarwind_flag', 'eesa_solarwind_flag']
        endelse
    end
    'efi' : begin ; Electric field instrument
        if(level eq 'l10') then begin
            instr_data = ['vaf', 'vap', 'vaw', 'vbf', 'vbp', 'vbw', 'eff', 'efp', 'efw']
        endif else if(level eq 'l1') then begin
            instr_data = ['vaf', 'vap', 'vaw', 'vbf', 'vbp', 'vbw', $
                          'eff', 'efp', 'efw', 'eff_0', 'efp_0', 'efw_0', $
                          'eff_dot0', 'efp_dot0', 'efw_dot0', 'eff_e12_efs', 'eff_e34_efs', $
                          'efp_e12_efs', 'efp_e34_efs', 'efw_e12_efs', 'efw_e34_efs', $
                          'eff_q_mag', 'eff_q_pha', 'efp_q_mag', 'efp_q_pha', $
                          'efw_q_mag', 'efw_q_pha']
        endif else begin
            instr_data = ['eff_dot0', 'efs_dot0', 'eff_q_mag', 'eff_q_pha', $
                          'efs_q_mag', 'efs_q_pha', 'eff_e12_efs', 'eff_e34_efs']
        endelse
    end
    'fbk' : begin ; Filter bank
        if(level eq 'l10') then begin
            instr_data = ['fbh', 'fb1', 'fb1_src', 'fb2', 'fb2_src']
        endif else if(level eq 'l1') then begin
            instr_data = ['fb1', 'fb2', 'fb_eac12', 'fb_eac34', 'fb_eac56', 'fb_edc12', $
                          'fb_edc34', 'fb_edc56', 'fb_hff', 'fb_scm1', 'fb_scm2', $
                          'fb_scm3', 'fb_v1', 'fb_v2', 'fb_v3', 'fb_v4', 'fb_v5', $
                          'fb_v6', 'fbh']
        endif else begin
            instr_data = ['fb_v1', 'fb_v2', 'fb_v3', 'fb_v4', 'fb_v5', 'fb_v6', $
                          'fb_edc12', 'fb_edc34', 'fb_edc56', 'fb_scm1', 'fb_scm2', $
                          'fb_scm3', 'fb_eac12', 'fb_eac34', 'fb_eac56', 'fb_hff']
        endelse
    end
    'fft' : begin ; Fourier power spectra
        if(level eq 'l10') then begin
            instr_data = ''
            instr_type = ['ffp_16', 'ffw_16', 'fff_16', 'ffp_32', 'ffw_32', 'fff_32', 'ffp_64', 'ffw_64', 'fff_64']
            valid_variables = ['src', 'adc', 'hed']
            instr_data = instr_type
            for k = 0, n_elements(instr_type)-1 do instr_data = [instr_data, instr_type[k]+'_'+valid_variables]
        endif else if(level eq 'l1') then begin
            instr_data = ''
            instr_type = ['ffp_16', 'ffw_16', 'fff_16', 'ffp_32', 'ffw_32', 'fff_32', 'ffp_64', 'ffw_64', 'fff_64']
            valid_variables = ['dbpara', 'dbperp', 'eac12', 'eac34', 'eac56', 'edc12', $
                               'edc34', 'edc56', 'epara', 'eperp', 'scm1', 'scm2', 'scm3', $
                               'undef', 'v1', 'v2', 'v3', 'v4', 'v5', 'v6','src','adc','hed']
            instr_data = instr_type
            for k = 0, n_elements(instr_type)-1 do instr_data = [instr_data, instr_type[k]+'_'+valid_variables]
        endif else begin
            instr_data = ''
            instr_type = ['ffp_16', 'ffw_16', 'fff_16', 'ffp_32', 'ffw_32', 'fff_32', 'ffp_64', 'ffw_64', 'fff_64']
            valid_variables = ['dbpara', 'dbperp', 'eac12', 'eac34', 'eac56', 'edc12', $
                               'edc34', 'edc56', 'epara', 'eperp', 'scm1', 'scm2', 'scm3', $
                               'v1', 'v2', 'v3', 'v4', 'v5', 'v6']
            instr_data = instr_type
            for k = 0, n_elements(instr_type)-1 do instr_data = [instr_data, instr_type[k]+'_'+valid_variables]
        endelse
    end
    'fgm' : begin ; Fluxgate magnetometer
        if(level eq 'l10') then begin
            instr_data = ['fge', 'fgl', 'fgh']
        endif else if(level eq 'l1') then begin
            instr_data = ['fge', 'fgl', 'fgh']
        endif else begin
            vl2_coord = '_'+['ssl', 'dsl', 'gse', 'gsm', 'btotal'] ;yes, btotal isn't a coordinate system
            vl2_coord_fgs = '_'+['dsl', 'gse', 'gsm', 'btotal']
            instr_data = ['fge'+vl2_coord, 'fgl'+vl2_coord, 'fgh'+vl2_coord, 'fgs'+vl2_coord_fgs]
        endelse
    end
    'fit' : begin ; On-board E/B spin fits
        if(level eq 'l10') then begin
            instr_data = 'fit'
        endif else if(level eq 'l1') then begin
            ; 'fit' removed 12-2-21
            instr_data = ['fit_bfit', 'fit_efit', 'fgs', 'fgs_sigma', 'efs', 'efs_0', 'efs_dot0', 'efs_sigma']
        endif else begin
            vl2_coord = '_'+['dsl', 'gse', 'gsm']
            vl2 = ['fgs'+vl2_coord, 'efs'+vl2_coord, $
                   'efs_0'+vl2_coord, 'efs_dot0'+vl2_coord]
            instr_data = [vl2, 'fit_efit', 'fit_bfit', 'fgs_sigma', 'efs_sigma']
        endelse
    end
    'gmag' : begin ; Ground magnetometers
        if(level eq 'l2') then begin
            instr_data = 'mag'
        endif else begin
            instr_data = ''
        endelse
    end
    'mom' : begin ; On-board moments
        instr_data = ''
        if(level eq 'l1' or level eq 'l10') then begin
            instr_data = ['peim', 'peem', 'psim', 'psem', 'ptim', 'ptem', 'pxxm', 'flags']
        endif else begin
;           instr_type = ['peim', 'peem', 'psim', 'psem', 'ptim', 'ptem']
            instr_type = ['peim', 'peem']
            valid_variables = ['density', 'flux', 'mftens', 'eflux', 'velocity_dsl', $
                               'ptens', 'ptot', 'velocity_mag', 'ptens_mag', 't3_mag', $
                               'mag', 'velocity_gse', 'velocity_gsm', 'data_quality']
            for k = 0, n_elements(instr_type)-1 do instr_data = [instr_data, instr_type[k]+'_'+valid_variables]
            instr_data = [instr_data[1:*], 'pxxm_pot', 'iesa_solarwind_flag', 'eesa_solarwind_flag']
        endelse
     end
     'gmom' : begin ; On-board moments
          instr_data = ''
          if(level eq 'l1' or level eq 'l10') then begin
            instr_data = ['None']
          endif else begin
            instr_type = ['ptiff', 'pteff', 'ptirf', 'pterf', 'ptebb']
            valid_variables = ['density', 'flux', 'mftens', 'en_eflux', $
              't3', 'magt3', 'ptens', 'sc_pot', 'magf', $
              'symm', 'symm_ang', 'avgtemp', 'vthermal', $
              'velocity_dsl', 'velocity_gse', 'velocity_gsm', 'data_quality']
            for k = 0, n_elements(instr_type)-1 do instr_data = [instr_data, instr_type[k]+'_'+valid_variables]
            instr_data = [instr_data[1:*], 'iesa_solarwind_flag', 'eesa_solarwind_flag']
          endelse
    end
    'scm' : begin ; Search-coil magnetometer
        if(level eq 'l10') then begin
            instr_data = ['scf', 'scp', 'scw']
        endif else if(level eq 'l1') then begin
            instr_data = ['scf', 'scp', 'scw']
        endif else begin
            vl2_coord = '_'+['dsl', 'gse', 'gsm', 'btotal'] ;yes, btotal isn't a coordinate system
            instr_data = ['scf'+vl2_coord, 'scp'+vl2_coord, 'scw'+vl2_coord]
        endelse
    end
    'spin' : begin
        if(level eq 'l1' or level eq 'l10') then begin
            instr_data = 'spin_'+['spinper', 'tend', 'c', 'phaserr', 'nspins', 'npts', 'maxgap']
        endif else begin
            instr_data = ''
        endelse
    end
    'sst' : begin ; Solid state telescope
        if(level eq 'l1' or level eq 'l10') then begin ;handle this in the same way as ESA L0
            instr_data = ['psif', 'psef', 'psir', 'pser', 'psib', 'pseb']
        endif else begin
           sst_l2_datatype_root_list = ['delta_time','en_eflux','density','avgtemp','vthermal',$
                                        'sc_pot','t3','magt3','ptens','mftens','flux','symm',$
                                        'symm_ang','magf','velocity_dsl','velocity_gse','velocity_gsm',$
                                        'data_quality']
        
            instr_data = ['psif' +'_'+sst_l2_datatype_root_list,'psef'+'_'+sst_l2_datatype_root_list, $
              'psib' +'_'+sst_l2_datatype_root_list,'pseb'+'_'+sst_l2_datatype_root_list]
        endelse
    end
    'state' : begin ; Spacecraft state data
        if(level eq 'l1' or level eq 'l10') then begin
            instr_data = ['pos', 'vel', 'man', 'roi', 'spinras', 'spindec', $
                          'spinalpha', 'spinbeta', 'spinper', 'spinphase', $
                          'spin_spinper',  'spin_tend', 'spin_c', $
                          'spin_phaserr', 'spin_nspins', 'spin_npts', 'spin_maxgap',$
                          'spinras_correction', 'spindec_correction', $
                          'spinras_corrected', 'spindec_corrected']
        endif else begin
            instr_data = ''
        endelse
    end
    else : begin ; BAU, HSK, TRG
        load_routine = 'thm_load_'+instrument
        resolve_routine, load_routine, /no_recompile
        if(level eq 'l1' or level eq 'l10') then begin
            call_procedure, load_routine, level = 'l1', /valid_names, datatype = instr_data
        endif else begin
            call_procedure, load_routine, level = 'l2', /valid_names, datatype = instr_data
        endelse
    end
    endcase
    return, instr_data
end

function thm_data2load, instrument, level
    compile_opt idl2, hidden
    
    ; clean up inputs
    instru = strcompress(strlowcase(instrument),/remove_all)
    lvl = strcompress(strlowcase(level),/remove_all)
    
    instru_list = ['asi', 'ask', 'esa', 'efi', 'fbk', 'fft', 'fgm', 'fit', 'gmag', $
                   'mom', 'gmom', 'scm', 'spin', 'sst', 'state', 'bau', 'hsk', 'trg']
                   
    ; 'l1': any data that can be gotten from the l1 file -- including calibrated, etc... 
    ; 'l10': data that is only loaded from L1 files. 
    ; 'l2': data gotten from L2 files. 
    ; For ESA data, 'l10' data and 'l1' data are gotten from the packet files.
    lvl_list = ['l1', 'l2', 'l10']
    
    ; make sure instrument input is in the instrument list
    if ~in_set(instru, instru_list) then begin
        dprint, 'Invalid input: ' + instrument
        dprint, 'Try, doc_library, ''thm_data2load'''
        return, ''
    endif
    
    ; make sure level input is in the level list
    if ~in_set(lvl, lvl_list) then begin
        dprint, 'Invalid input: ' + level
        dprint, 'Try, doc_library, ''thm_data2load'''
        return, ''
    endif
    
    return, thm_valid_variables(instru, lvl)
end
