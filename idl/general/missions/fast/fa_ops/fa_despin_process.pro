;+
;NAME:
;fa_despin_process
;PURPOSE:
;For a given orbit or time interval, grab fields data already loaded
;into sdt, via sdt_batch, run fa_fields_despin, and write out a CDF
;file with the data.
;CALLING SEQUENCE:
;fa_despin_process, full_database_management = full_database_management, $
;                   datatype = datatype
;INPUT:
;None, the data are assumed to have been loaded in an sdt_batch call
;OUTPUT:
;No explicit output
;KEYWORDS:
;full_database_management = if set, will handle deletion of a lock
;file created by the shell script that calles the program, and
;increment the file 'orbit.txt'. Also writes CDF file with proper
;orbit and datetime in filename. Otherwise a generic CDF is produced.
;datatype = 'S', 'svy' (same as S), '4k', '16k', the default is survey
;data.
;nocatch = run without the catch error block, so that you can debug
;directory = if set, the data will be put in a subdirectory of this,
;arranged by datatype and orbit number. The default is
;/disks/data/fast/l2/. Only used for full_database_management option,
;otherwise, the file is written to the current directory
;
;HISTORY:
; 19-mar-2024, jmm, jimm@ssl.berkeley.edu
; 16-apr-2024, jmm, adds sc/potential to output
; 5-sep-2024, jmm, added E_0_S_GSE, GSM, DSC, and all probe
;                  potentials, version 3
; 16-sep-2024, jmm, added spin axis direction in GSE, GSM, prepended
;                   FAST_ to variables that didn't have
;                   it. Dropped spinfit variables.
; 10-dec-2025, jmm, Added dqds_to_check; this will check to see if
;                   files were created by SDT for the given DQDs, and
;                   writes the orbit number to a file, if there is no
;                   useful data for that orbit. This is an aid to
;                   reprocessing if an orbit does not show up in the
;                   database.
;-
Pro fa_despin_process, full_database_management = full_database_management, $
                       datatype = datatype, nocatch = nocatch, directory = directory, $
                       no_overwrite = no_overwrite

;catch errors
  error_status = 0
  If(~keyword_set(nocatch)) Then Begin
     catch, error_status
     If(error_status ne 0) Then Begin
        catch, /cancel
        print, '%FA_DESPIN_PROCESS: Got Error Message'
        help, /last_message, output = err_msg
        For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
        If(keyword_set(full_database_management)) Then Begin
           message, /info, 'Full database management invoked.'
           If(orb_process) Then Begin
              message, /info, 'Incrementing orbit.txt'
              orbit = long(orb_str)
              orbit = orbit+1
              orb_str = strcompress(string(orbit), /remove_all)
              openw, unit1, 'orbit.txt', /get_lun
              printf, unit1, orb_str
              free_lun, unit1
           Endif
        Endif
        If(is_string(file_search('process_orbit.lock'))) Then Begin
           message, /info, 'deleting process_orbit.lock'
           file_delete, 'process_orbit.lock'
        Endif
        Return
     Endif
  Endif
;Zbuffer
  set_plot, 'z'
;Read in orbit, if available, then put in a five character string for filename
  If(is_string(file_search('orbit.txt'))) Then Begin
     orb_process = 1b
     openr, unit, 'orbit.txt', /get_lun
     orb_str = strarr(1)
     readf, unit, orb_str
     free_lun, unit
     orb_info = fa_orbit_to_time(orb_str[0])
     If(n_elements(orb_info) Ne 3) Then Begin
        orb_process = 0b
        message, 'Bad Orbit. Returning'
     Endif Else Begin
        print, 'Orbit: ', orb_info[0]
        print, 'Orbit start: ', time_string(orb_info[1])
        print, 'Orbit end: ', time_string(orb_info[2])
     Endelse
     orb_str = string(orb_str[0], format = '(i5.5)')
  Endif Else Begin
     orb_process = 0b
     message, /info, 'No orbit.txt file'
     orb_str = 'XXXXX'
  Endelse
  If(is_string(file_search('end_orbit.txt'))) Then Begin
     openr, unit3, 'end_orbit.txt', /get_lun
     end_orb_str = strarr(1)
     readf, unit3, end_orb_str
     free_lun, unit3
  Endif Else Begin
     message, /info, 'No end_orbit.txt file'
     end_orb = '51000'
  Endelse

;Don't process past the end_orbit
  If(long(orb_str) Gt long(end_orb_str[0])) Then Begin
     message, /info, 'End Orbit reached, No Process'
     Return
  Endif

;Set up datatype for survey, 4k burst, and 16k burst
  If(~is_string(datatype)) Then typ = 'esv' Else Begin
     Case datatype of
        'S':typ = 'esv'
        's':typ = 'esv'
        'esv':typ='esv'
        '4k':typ = 'e4k'
        '16k':typ = 'e16k'
        'e4k':typ = 'e4k'
        'e16k':typ = 'e16k'
        'esv_long':typ = 'esv_long'
        Else:typ = 'esv'
     Endcase
  Endelse
;Do not reproduce files, if asked not to
  If(keyword_set(no_overwrite)) Then Begin
     If(keyword_set(directory)) Then rdir = directory $
     Else rdir = '/disks/data/fast/l2/'
     orbit_dir = strmid(orb_str,0,2)+'000'
     fulldir = rdir+typ+'/'+orbit_dir+'/'
     test_file = file_search(fulldir+'fa_despun_'+typ+'_l2_*_'+orb_str+'_v02.cdf')
     If(is_string(test_file)) Then message, 'File Exists: '+test_file
  Endif

;Despin the SDT fields data
  If(typ Eq 'esv') Then Begin
     fa_fields_despin3
     get_data, 'fa_e_near_b', data = e
     If(~is_struct(e)) Then message, /info, 'FA_FIELDS_DESPIN3 Failed:'
     potvar = get_fa_potential(/store)
     get_data, 's/c$potential', data = p
     If(~is_struct(p)) Then message, /info, 'GET_FA_POTENTIAL Failed:'
     copy_data, 's/c$potential', 'fa_sc_pot'
     potvar_spin = get_fa_potential(/store, /spin)
     get_data, 's/c$potential', data = p
     If(~is_struct(p)) Then message, /info, 'GET_FA_POTENTIAL Failed:'
     copy_data, 's/c$potential', 'fa_sc_pot_fit'
     to_be_stored = ['fa_e_near_b','fa_e_along_v', $
                     'fa_efit_near_b', 'fa_efit_along_v', $
                     'fa_sc_pot', 'fa_sc_pot_fit', 'fa_data_quality',$
                     'fa_e12','fa_e58','fa_bphase', 'fa_sphase', $
                     'fa_e0_s_gse', 'fa_e0_s_gsm', 'fa_e0_s_dsc', $
                     'fa_v1_v2_s', 'fa_v1_v4_s', 'fa_v5_v8_s', 'fa_v9_v10_s', $
                     'fa_v2_s', 'fa_v4_s', $
                     'fa_v6_s', 'fa_v7_s', 'fa_v8_s', 'fa_v9_s', $
                     'fa_v10_s', 'fa_dsc_gse', 'fa_dsc_gsm', $
                     'fa_spin_axis_gse', 'fa_spin_axis_gsm']
     to_check = ['fa_e_near_b','fa_e_along_v', $
                 'fa_sc_pot', 'fa_sc_pot_fit', $
                 'fa_e12','fa_e58', 'fa_e0_s_dsc', $
                 'fa_v1_v2_s', 'fa_v1_v4_s', 'fa_v5_v8_s', 'fa_v9_v10_s', $
                 'fa_v2_s', 'fa_v4_s', $
                 'fa_v6_s', 'fa_v7_s', 'fa_v8_s', 'fa_v9_s', $
                 'fa_v10_s', 'fa_dsc_gse']
     dqds_to_check = ['V5-V8_S', 'V1-V4_S', 'V4_S', 'V8_S', 'V1-V2_S', $
                      'E_0_S_GSE_X', 'E_0_S_GSE_Y', 'E_0_S_GSE_Z', $
                      'E_0_S_GSM_X', 'E_0_S_GSM_Y', 'E_0_S_GSM_Z', $
                      'V9_S', 'V10_S', 'V2_S', 'V3_S', 'V6_S', 'V7_S', $
                      'V9-V10_S']
     dqd_fsize_limit = 5000 ;if cdfs are fewer bytes than this, then NO_DATA
  Endif Else If(typ Eq 'e4k') Then Begin
     fa_fields_despin_4k
     to_be_stored = 'fa_'+['e_near_b_4k','e_along_v_4k', $
                           'e1458_4k', 'e58_4k', $
                           'sphase_4k', 'bphase_4k', $
                           'v1_v2_4k', 'v1_v4_4k', $
                           'v5_v8_4k', 'v5_v6_4k', $
                           'v5_v7_4k', 'v6_v8_4k', $
                           'v7_v8_4k', 'v2_4k', 'v6_4k', $
                           'v7_4k', 'v9_4k', 'v10_4k']
     to_check = 'fa_'+['e_near_b_4k','e_along_v_4k', $
                       'e1458_4k', 'e58_4k', $
                       'v1_v2_4k', 'v1_v4_4k', $
                       'v5_v8_4k', 'v5_v6_4k', $
                       'v5_v7_4k', 'v6_v8_4k', $
                       'v7_v8_4k', 'v2_4k', 'v6_4k', $
                       'v7_4k', 'v9_4k', 'v10_4k']
     dqds_to_check = ['V1-V4_4k', 'V14-V58_4k', 'V10_4k', $
                      'V1-V2_4k', 'V2-V4_4k', 'V2_4k', $
                      'V5-V6_4k', 'V5-V8_4k', 'V6-V8_4k', $
                      'V5-V7_4k', 'V6_4k', 'V7-V8_4k', $
                      'V9-V10_4k', 'V7_4k', 'V9_4k']
     dqd_fsize_limit = 5000 ;if cdfs are fewer bytes than this, then NO_DATA
  Endif Else If(typ Eq 'e16k') Then Begin
     fa_fields_despin_16k
     to_be_stored = 'fa_'+['e_near_b_16k','e_along_v_16k', $
                           'e1458_16k', 'e58_16k', $
                           'sphase_16k', 'bphase_16k', $
                           'v1_v2_16k', 'v1_v3_16k', $
                           'v1_v4_16k', 'v2_v4_16k', $
                           'v3_v4_16k', 'v5_v8_16k', $
                           'v5_v6_16k', 'v5_v7_16k', $
                           'v6_v8_16k', 'v7_v8_16k', $
                           'v9_v10_16k', 'v1_v2hg_16k', $
                           'v1_v4hg_16k', 'v3_v4hg_16k', $
                           'v5_v8hg_16k', 'v1_16k', $
                           'v2_16k', 'v3_16k', 'v4_16k', $
                           'v5_16k', 'v6_16k', $
                           'v7_16k', 'v9_16k']
     to_check = 'fa_'+['e_near_b_16k','e_along_v_16k', $
                       'e1458_16k', 'e58_16k', $
                       'v1_v2_16k', 'v1_v3_16k', $
                       'v1_v4_16k', 'v2_v4_16k', $
                       'v3_v4_16k', 'v5_v8_16k', $
                       'v5_v6_16k', 'v5_v7_16k', $
                       'v6_v8_16k', 'v7_v8_16k', $
                       'v9_v10_16k', 'v1_v2hg_16k', $
                       'v1_v4hg_16k', 'v3_v4hg_16k', $
                       'v5_v8hg_16k', 'v1_16k', $
                       'v2_16k', 'v3_16k', 'v4_16k', $
                       'v5_16k', 'v6_16k', $
                       'v7_16k', 'v9_16k']
     dqds_to_check = ['V1-V2HG_16k', 'V1-V2_16k', 'V1-V3_16k', $
                      'V1-V4HG_16k', 'V1-V4_16k', 'V14-V58_16k', $
                      'V1_16k', 'V2-V4_16k', 'V2_16k', 'V3-V4HG_16k', $
                      'V3-V4_16k', 'V3_16k', 'V4_16k', 'V5-V6_16k', $
                      'V5-V7_16k', 'V5-V8HG_16k', 'V5-V8_16k', $
                      'V5_16k', 'V6-V8_16k', 'V6_16k', 'V7-V8_16k', $
                      'V7_16k', 'V8_16k', 'V9-V10_16k', 'V9_16k']
     dqd_fsize_limit = 5000 ;if cdfs are fewer bytes than this, then dude, 'NO_DATA'
  Endif Else Begin
     message, /info, 'Bad TYP input'
  Endelse
;Datetime stuff for filename
  ntb = n_elements(to_check) ;Only check for E or V variables
  cc = 0
  For j = 0, ntb-1 Do Begin
     get_data, to_check[j], data = e
     If(is_struct(e)) Then Begin
        cc = 1
        date = time_string(min(e.x), format=6)
        break
     Endif 
  Endfor
;files to check for -- if there is no data for the input dqd's
;                      then add to missed orbits file.
  ntb1 = n_elements(dqds_to_check)
  cc1 = 0
  For j = 0, ntb1-1 Do Begin
     fsizej = fa_cdf_file_test(long(orb_str), dqds_to_check[j])
     If(fsizej Gt dqd_fsize_limit) Then Begin
        cc1 = 1
        break                   ;found a good file, so there must be ok data
     Endif
  Endfor
  If(cc1 Eq 0) Then Begin       ;Add to no_data_orbits.txt
     If(~is_string(file_search('orbits_no_data.txt'))) Then Begin
        openw, ndunit, 'orbits_no_data.txt', /get_lun
     Endif Else openw, ndunit, 'orbits_no_data.txt', /get_lun, /append
     printf, ndunit, orb_str
  Endif
     
  If(cc Eq 0) Then Begin
     message, /info, 'No E, V or SCPOT data, no file output'
     If(orb_process) Then Begin
        message, /info, 'Incrementing orbit.txt'
        orbit = long(orb_str)
        orbit = orbit+1
        orb_str = strcompress(string(orbit), /remove_all)
        openw, unit2, 'orbit.txt', /get_lun
        printf, unit2, orb_str
        free_lun, unit2
     Endif
     If(is_string(file_search('process_orbit.lock'))) Then Begin
        message, /info, 'deleting process_orbit.lock'
        spawn, 'rm -f process_orbit.lock'
     Endif
     Return
  Endif
  
;If required, handle database stuff
  If(keyword_set(full_database_management)) Then Begin
     message, /info, 'Full database management invoked.'
;create global attributes
     gen_date = time_string(systime(/sec), precision=-3)
     global_att = {Acknowledgment:'None', $
                   Data_type:'CAL>Calibrated', $
                   Data_version:'2', $
                   Descriptor:'FA_DESPUN_EFIELD>Fast Auroral SnapshoT Explorer, Despun Electric Field', $
                   Discipline:'Space Physics>Planetary Physics>Fields', $
                   File_naming_convention: 'descriptor_datatype_yyyyMMddHHmmss_orbno', $
                   Generated_by:'FAST SOC' , $
                   Generation_date:gen_date , $
                   HTTP_LINK:'http://sprg.ssl.berkeley.edu/fast/', $
                   Instrument_type:'Electric Fields (space)' , $
                   LINK_TEXT:'General Information about the FAST mission' , $
                   LINK_TITLE:'FAST home page' , $
                   Logical_file_id:'fa_despun_'+typ+'_l2_00000000000000_00000_v02.cdf' , $
                   Logical_source:'fa_despun_'+typ+'_l2_XXX' , $
                   Logical_source_description:'FAST Spacecraft-collected (EFI) Electric field', $
                   Mission_group:'FAST' , $
                   MODS:'Rev-0 2024-03-21' , $
                   PI_name:'R.E. Ergun', $
                   PI_affiliation:'LASP, C.U. Boulder', $
                   Planet:'Earth', $
                   Project:'FAST', $
                   Rules_of_use:'Open Data for Scientific Use' , $
                   Source_name:'FAST>Fast Auroral SnapshoT Explorer', $
                   TEXT:'EFI>Electric Field Instrument', $
                   Time_resolution:'0.001-4.0 s', $
                   Title:'FAST EFI Despun Electric Field'}
;output with orbit and time in filename
     filename = 'fa_despun_'+typ+'_l2_'+date+'_'+orb_str+'_v02'
     If(keyword_set(directory)) Then rdir = directory $
     Else rdir = '/disks/data/fast/l2/'
     orbit_dir = strmid(orb_str,0,2)+'000'
     fulldir = rdir+typ+'/'+orbit_dir+'/'
     If(~is_string(file_search(fulldir))) Then file_mkdir, fulldir
;Create variable attributes for each variable, and add CDF structure
;to limits array
     vatt_str = {CATDESC:'NA', $
                 DISPLAY_TYPE:'time_series', $
                 FIELDNAM:'NA', $
                 FORMAT:'E25.18', $
                 LABLAXIS:'NA', $;        STRING    'E NEAR B!C!C(mV/m)'
                 UNITS:'undefined', $
                 VAR_TYPE:'data', $
                 FILLVAL:!values.d_nan, $
                 VALIDMIN:-10000.0, $
                 VALIDMAX:10000.0, $
                 DEPEND_0:'Epoch'}
     print, tnames()
     tb = tnames(to_be_stored)
     print, tb
     nvar = n_elements(tb)
     For j = 0, nvar-1 Do Begin
;For orbits 5270 and 5271, SDT puts data for both orbits into the
;final output, so check the orbit data, and time clip the variable
;before output
;        If(orb_info[0] Eq 5270.0) Or (orb_info[0] Eq 5271) Then Begin
;           message, /info, 'Clipping: '+tb[j]+' Orbit: '+orb_str[0]
;           time_clip, tb[j], orb_info[1], orb_info[2], /replace
;        Endif
        vattj = fa_despin_process_vatt(tb[j])
;Create a CDF structure for the output, and put the vattj structure in
;the attrptr for the structure
        print, 'PROCESSING: '+tb[j]
        fa_tplot_add_cdf_structure, tb[j], /add_tname_to_epoch
        get_data, tb[j], alimit=al
        If(ptr_valid(al.cdf.vars.attrptr)) Then ptr_free, al.cdf.vars.attrptr
        al.cdf.vars.attrptr = ptr_new(vattj)
        store_data, tb[j], data = d, limits=al, dlimits=al
        print, 'PROCESSED: '+tb[j]
     Endfor
        
     fa_tplot2cdf, filename = fulldir+filename, tvars = tb, $
                   g_attributes = global_att, /compress_cdf, $
                   /add_tname_to_epoch
     If(orb_process) Then Begin
        message, /info, 'Incrementing orbit.txt'
        orbit = long(orb_str)
        orbit = orbit+1
        orb_str = strcompress(string(orbit), /remove_all)
        openw, unit2, 'orbit.txt', /get_lun
        printf, unit2, orb_str
        free_lun, unit2
     Endif
;If there is a lock file, delete it
     If(is_string(file_search('process_orbit.lock'))) Then Begin
        message, /info, 'deleting process_orbit.lock'
        spawn, 'rm -f process_orbit.lock'
     Endif
     If(is_string(file_search('process_orbit.lock'))) Then Begin
        wait, 60.0
        message, /info, 'deleting process_orbit.lock Again'
        spawn, 'rm -f process_orbit.lock'
     Endif
     If(is_string(file_search('process_orbit.lock'))) Then Begin
        message, /info, 'process_orbit.lock not deleted'
     Endif
  Endif Else Begin              ;output with nothing
     filename = 'fa_despun_'+typ+'_l2_'+date+'_'+orb_str+'_v02'
     tplot2cdf, filename = filename, tvars = to_be_stored, /default
  Endelse
End
