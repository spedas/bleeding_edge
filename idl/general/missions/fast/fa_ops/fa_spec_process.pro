;+
;NAME:
;fa_spec_process
;PURPOSE:
;For a given orbit or time interval, grab fields spectral data (DSP,
;SVY) already loaded into sdt, via sdt_batch, and write out a CDF
;file with the data.
;CALLING SEQUENCE:
;fa_spec_process, full_database_management = full_database_management, $
;                 datatype = datatype
;INPUT:
;None, the data are assumed to have been loaded in an sdt_batch call
;OUTPUT:
;No explicit output
;KEYWORDS:
;full_database_management = if set, will handle deletion of a lock
;file created by the shell script that calles the program, and
;increment the file 'orbit.txt'. Also writes CDF file with proper
;orbit and datetime in filename. Otherwise a generic CDF is produced.
;datatype = 'sfa' or 'dsp', the default is DSP data. Not case sensitive.
;nocatch = run without the catch error block, so that you can debug
;directory = if set, the data will be put in a subdirectory of this,
;arranged by datatype and orbit number. The default is
;/disks/data/fast/l2/. Only used for full_database_management option,
;otherwise, the file is written to the current directory
;
;HISTORY:
; 28-Oct-2025, jmm, jimm@ssl.berkeley.edu
;-
Pro fa_spec_process, full_database_management = full_database_management, $
                     datatype = datatype, nocatch = nocatch, directory = directory, $
                     no_overwrite = no_overwrite

;catch errors
  error_status = 0
  If(~keyword_set(nocatch)) Then Begin
     catch, error_status
     If(error_status ne 0) Then Begin
        catch, /cancel
        print, '%FA_SPEC_PROCESS: Got Error Message'
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
  If(~is_string(datatype)) Then typ = 'dsp' Else Begin
     Case strlowcase(datatype) of
        'sfa':typ = 'sfa'
        'dsp':typ = 'dsp'
        Else:typ = 'dsp'
     Endcase
  Endelse
;Do not reproduce files, if asked not to
  If(keyword_set(no_overwrite)) Then Begin
     If(keyword_set(directory)) Then rdir = directory $
     Else rdir = '/disks/data/fast/l2/'
     orbit_dir = strmid(orb_str,0,2)+'000'
     fulldir = rdir+typ+'/'+orbit_dir+'/'
     test_file = file_search(fulldir+'fa_'+typ+'_l2_*_'+orb_str+'_v01.cdf')
     If(is_string(test_file)) Then message, 'File Exists: '+test_file
  Endif

;Despin the SDT fields data
  If(typ Eq 'dsp') Then Begin
     fa_fields_dsp2tplot, orb_info[1:2], tvar ;needs a time range
     to_be_stored = ['fa_dspadc_mag3ac', 'fa_dspadc_ne2', 'fa_dspadc_ne3', $
                     'fa_dspadc_ne6', 'fa_dspadc_ne7', 'fa_dspadc_v1', $
                     'fa_dspadc_v2', 'fa_dspadc_v3', 'fa_dspadc_v4', $
                     'fa_dspadc_v5', 'fa_dspadc_v6', 'fa_dspadc_v7', $
                     'fa_dspadc_v8', 'fa_dspadc_e12', 'fa_dspadc_e12hg', $
                     'fa_dspadc_e14', 'fa_dspadc_e14hg', $
                     'fa_dspadc_e34', 'fa_dspadc_e34hg', $
                     'fa_dspadc_e56', 'fa_dspadc_e58', 'fa_dspadc_e58hg', $
                     'fa_dspadc_e78', 'fa_dspadc_e910', $
                     'fa_dspadc_v12trk', 'fa_dspadc_v14trk', 'fa_dspadc_v910trk', $
                     'fa_dspadc_eomni', 'fa_dspadc_eomnihg', $
                     'fa_dsphsbm_mag3ac', 'fa_dsphsbm_e12', 'fa_dsphsbm_e14', $
                     'fa_dsphsbm_e34', 'fa_dsphsbm_e56', 'fa_dsphsbm_e58', $
                     'fa_dsphsbm_e78', 'fa_dsphsbm_e910']
     dsp_tmp = fa_dsp_process_varnames()
     dqds_to_check = reform(dsp_tmp[0, *])+'_Spectra'
     dqd_fsize_limit = 5000
  Endif Else If(typ Eq 'sfa') Then Begin
     fa_fields_sfa2tplot, orb_info[1:2], tvar ;needs a time range
     to_be_stored = ['fa_sfaave_mag3ac', 'fa_sfaave_e12', $
                     'fa_sfaave_e14', 'fa_sfaave_e34', $
                     'fa_sfaave_e56', 'fa_sfaave_e58', $
                     'fa_sfaave_e78', 'fa_sfaave_e910', $
                     'fa_sfaave_eomni', $
                     'fa_sfaburst_mag3ac', 'fa_sfaburst_e12', $
                     'fa_sfaburst_e14', 'fa_sfaburst_e34', $
                     'fa_sfaburst_e56', 'fa_sfaburst_e58', $
                     'fa_sfaburst_e78', 'fa_sfaburst_e910', $
                     'fa_sfaburst_eomni']
     sfa_tmp = fa_sfa_process_varnames()
     dqds_to_check = reform(sfa_tmp[0, *])
     dqd_fsize_limit = 5000
  Endif Else Begin
     message, /info, 'Bad TYP input'
  Endelse
;Datetime stuff for filename
  ntb = n_elements(to_be_stored) ;Check all variables
  For j = 0, ntb-1 Do Begin
     get_data, to_be_stored[j], data = e
     If(is_struct(e)) Then Begin
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
  If(~is_struct(e)) Then Begin
     message, /info, 'No '+strupcase(typ)+' data, no file output'
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
     If(typ Eq 'dsp') Then Begin
        desc0 = 'FA_DSP>Fast Auroral SnapshoT Explorer, Digital Signal Processor'
        desc1 = 'Digital Signal Processor Fields data'
     Endif Else If(typ Eq 'sfa') Then Begin
        desc0 = 'FA_SFA>Fast Auroral SnapshoT Explorer, Swept Frequency analyzer'
        desc1 = 'Swept Frequency analyzer data'
     Endif Else Begin
        desc0 = 'NA'
        desc1 = 'NA'
     Endelse
     global_att = {Acknowledgment:'None', $
                   Data_type:'CAL>Calibrated', $
                   Data_version:'1', $
                   Descriptor:desc0, $
                   Discipline:'Space Physics>Planetary Physics>Fields', $
                   File_naming_convention: 'descriptor_l2_yyyyMMddHHmmss_orbno', $
                   Generated_by:'FAST SOC' , $
                   Generation_date:gen_date , $
                   HTTP_LINK:'http://sprg.ssl.berkeley.edu/fast/', $
                   Instrument_type:'Electric Fields (space)' , $
                   LINK_TEXT:'General Information about the FAST mission' , $
                   LINK_TITLE:'FAST home page' , $
                   Logical_file_id:'fa_'+typ+'_l2_00000000000000_00000_v02.cdf' , $
                   Logical_source:'fa_'+typ+'_l2_XXX' , $
                   Logical_source_description:'FAST Spacecraft-collected Electric and Magnetic field', $
                   Mission_group:'FAST' , $
                   MODS:'Rev-0 2024-03-21' , $
                   PI_name:'R.E. Ergun', $
                   PI_affiliation:'LASP, C.U. Boulder', $
                   Planet:'Earth', $
                   Project:'FAST', $
                   Rules_of_use:'Open Data for Scientific Use' , $
                   Source_name:'FAST>Fast Auroral SnapshoT Explorer', $
                   TEXT:'EFI>Electric Field Instrument,DCB>DC Magnetic Field Instrument', $
                   Time_resolution:'Variable', $
                   Title:'FAST '+desc1}
;output with orbit and time in filename
     filename = 'fa_'+typ+'_l2_'+date+'_'+orb_str+'_v01'
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
        vattj = fa_spec_process_vatt(tb[j])
;Create a CDF structure for the output, and put the vattj structure in
;the attrptr for the structure
        fa_tplot_add_cdf_structure, tb[j], /add_tname_to_epoch
        get_data, tb[j], alimit=al
        If(ptr_valid(al.cdf.vars.attrptr)) Then ptr_free, al.cdf.vars.attrptr
        al.cdf.vars.attrptr = ptr_new(vattj)
        store_data, tb[j], data = d, limits=al, dlimits=al
        print, 'PROCESSED: '+tb[j]
     Endfor
        
     fa_tplot2cdf, filename = fulldir+filename, tvars = tb, $
                   g_attributes = global_att, /compress_cdf, $
                   /add_tname_to_epoch, v_units = 'kHz'
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
     filename = 'fa_'+typ+'_l2_'+date+'_'+orb_str+'_v01'
     tplot2cdf, filename = filename, tvars = to_be_stored, /default
  Endelse
End
