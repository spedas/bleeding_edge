;+
;NAME:
;fa_efi_probedatafile
;PURPOSE:
;Creates a file /disks/data/fast/l2/fa_efi_probedata.csv
;with probe data, distance from payload and phase angle with respect to
;the sun phase
;CALLING SEQUENCE:
;fa_probedatafile
;INPUT:
;none
;OUTPUT:
;filename = creates a file with columns for FAST EFI probe phase and
;           distances
;HISTORY:
;2024-11-20, jmm, jimm@ssl.berkeley.edu
;-
Function fa_efi_probedatafile, cdf_filename = cdf_filename

  test_file = file_search('/disks/data/fast/l2/fa_efi_probedata.csv')
;  If(is_string(test_file)) Then Return, test_file

  filename = '/disks/data/fast/l2/fa_efi_probedata.csv'

  boom_times = time_double(['1995-07-26/00:00:00',$
                            '1996-09-03/16:53:40', $
                            '1996-09-10/14:16:40', $
                            '1996-09-11/00:00:00', $
                            '1996-09-15/00:00:00', $
                            '1996-09-29/00:00:00', $
                            '1997-02-03/10:07:20'])
  nbt = n_elements(boom_times)

;probe length, distance from center of probe
  probel = fltarr(n_elements(boom_times), 10)
  probel[0, *] = 0.0            ;Launch configuration
  probel[1, *] = [5.5, 0.5, 0.0, 0.6, 0.0, $
                  0.0, 0.0, 0.0, 0.0, 0.0]
  probel[2, *] = [5.5, 0.5, 0.0, 0.6, 5.5, $
                  0.5, 0.5, 5.5, 0.0, 0.0]
  probel[3, *] = [8.0, 3.0, 0.0, 0.6, 8.0, $
                  3.0, 3.0, 8.0, 0.0, 0.0]
  probel[4, *] = [8.0, 3.0, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 0.0, 0.0]
  probel[5, *] = [28.3, 23.3, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 0.0, 0.0]
  probel[6, *] = [28.3, 23.3, 0.0, 0.6, 28.0, $
                  23.0, 23.0, 28.0, 4.05, 0.0]
;probe phase, add to sphase to get angle between probe vector and DSC
;X-axis
  probep = fltarr(n_elements(boom_times), 10)
  probep[0, *] = 0.0            ;Launch configuration
  probep[1, *] = [-142.0, -142.0, 0.0, 38.0, 0.0, $
                  0.0, 0.0, 0.0, 0.0, 0.0]
  probep[2, *] = [-142.0, -142.0, 0.0, 38.0, -45.0, $
                  -45.0, 121.0, 121.0, 0.0, 0.0]
;All probes that will be out are out after this
  probep[3, *] = probep[2, *]
  probep[4, *] = probep[2, *]
  probep[5, *] = probep[2, *]
  probep[6, *] = probep[2, *]

;length for probe differences, in meters
  v12_dist = [0.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0]
  v14_dist = [0.0, 6.1, 6.1, 8.6, 8.6, 28.9, 28.9] 
  v58_dist = [0.0, 0.0, 11.0, 16.0, 56.0, 56.0, 56.0]
  v910_dist = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.05]

  data1 = {time:time_string(boom_times), $
           dist_probe1:probel[*,0], phase_probe1:probep[*,0], $
           dist_probe2:probel[*,1], phase_probe2:probep[*,1], $
           dist_probe3:probel[*,2], phase_probe3:probep[*,2], $
           dist_probe4:probel[*,3], phase_probe4:probep[*,3], $
           dist_probe5:probel[*,4], phase_probe5:probep[*,4], $
           dist_probe6:probel[*,5], phase_probe6:probep[*,5], $
           dist_probe7:probel[*,6], phase_probe7:probep[*,6], $
           dist_probe8:probel[*,7], phase_probe8:probep[*,7], $
           dist_probe9:probel[*,8], phase_probe9:probep[*,8], $
           dist_probe10:probel[*,9], phase_probe10:probep[*,9], $
           v12_dist:v12_dist, v14_dist:v14_dist, v58_dist:v58_dist, $
           v910_dist:v910_dist}

  header = ['Time', 'dist_probe1', 'phase_probe1', $
            'dist_probe2', 'phase_probe2', $
            'dist_probe3', 'phase_probe3', $
            'dist_probe4', 'phase_probe4', $
            'dist_probe5', 'phase_probe5', $
            'dist_probe6', 'phase_probe6', $
            'dist_probe7', 'phase_probe7', $
            'dist_probe8', 'phase_probe8', $
            'dist_probe9', 'phase_probe9', $
            'dist_probe10', 'phase_probe10', $
            'v12_dist', 'v14_dist', 'v58_dist', 'v910_dist']

  table_header = ['FILE: '+filename, $
                  'Contains distance from paylod to probes 1 to 10', $
                  'Angular phase with respect to sun pulse for probes 1 to 10', $
                  'Probe to probe distances for Voltage differences used in electric field calculations']
  write_csv, filename, data1, header = header, table_header = table_header

;Create a CDF file too
  del_data, '*'
  cdf_filename = '/disks/data/fast/l2/fa_efi_probedata.csv'
  to_be_stored1 = ['fa_probe_dist', 'fa_probe_phase', $
                   'fa_v12_dist', 'fa_v14_dist', 'fa_v58_dist', $
                   'fa_v910_dist']
  store_data, 'fa_probe_dist', data = {x:boom_times, y:probel}
  store_data, 'fa_probe_phase', data = {x:boom_times, y:probep}
  store_data, 'fa_v12_dist', data = {x:boom_times, y:v12_dist}
  store_data, 'fa_v14_dist', data = {x:boom_times, y:v14_dist}
  store_data, 'fa_v58_dist', data = {x:boom_times, y:v58_dist}
  store_data, 'fa_v910_dist', data = {x:boom_times, y:v910_dist}

;create global attributes
  gen_date = time_string(systime(/sec), precision=-3)
  global_att = {Acknowledgment:'None', $
                Data_type:'CAL>Calibrated', $
                Data_version:'0', $
                Descriptor:'FA_DESPUN_EFIELD>Fast Auroral SnapshoT Explorer, Support data for Despun Electric Field', $
                Discipline:'Space Physics>Planetary Physics>Fields', $
                File_naming_convention: 'fa_efi_probedata.cdf', $
                Generated_by:'FAST SOC' , $
                Generation_date:gen_date , $
                HTTP_LINK:'http://sprg.ssl.berkeley.edu/fast/', $
                Instrument_type:'Electric Fields (space)' , $
                LINK_TEXT:'General Information about the FAST mission' , $
                LINK_TITLE:'FAST home page' , $
                Logical_file_id:'fa_efi_probedata.cdf' , $
                Logical_source:'fa_efi_probedata' , $
                Logical_source_description:'FAST Spacecraft Support Data for (EFI) Electric field', $
                Mission_group:'FAST' , $
                MODS:'Rev-0 2024-03-21' , $
                PI_name:'R.E. Ergun', $
                PI_affiliation:'LASP, C.U. Boulder', $
                Planet:'Earth', $
                Project:'FAST', $
                Rules_of_use:'Open Data for Scientific Use' , $
                Source_name:'FAST>Fast Auroral SnapshoT Explorer', $
                TEXT:'EFI>Electric Field Instrument', $
                Time_resolution:'NA', $
                Title:'FAST EFI Despun Electric Field Support Data'}
;output with orbit and time in filename
     filename = 'fa_efi_probedata'
     If(keyword_set(directory)) Then fulldir = directory $
     Else fulldir = '/disks/data/fast/l2/'
;Create variable attributes for each variable, and add CDF structure
;to limits array
     vatt_str = {CATDESC:'NA', $
                 DISPLAY_TYPE:'time_series', $
                 FIELDNAM:'NA', $
                 FORMAT:'E25.18', $
                 LABLAXIS:'NA', $ ;        STRING    'E NEAR B!C!C(mV/m)'
                 UNITS:'undefined', $
                 VAR_TYPE:'data', $
                 FILLVAL:!values.d_nan, $
                 VALIDMIN:-10000.0, $
                 VALIDMAX:10000.0, $
                 DEPEND_0:'Epoch'}
     tb = tnames(to_be_stored1)
     print, tnames()
     nvar = n_elements(tb)
     For j = 0, nvar-1 Do Begin
        vattj = vatt_str
        vattj.fieldnam = tb[j]
        If(strpos(tb[j], 'dist') Ne -1) Then Begin
           vattj.units = 'm'
           vattj.lablaxis = tb[j]
           vattj.var_type = 'support_data'
           vattj.validmin = 0.0
           vattj.validmax = 100.0
        Endif Else If(tb[j] Eq 'fa_probe_phase') Then Begin
           vattj.units = 'radians'
           vattj.lablaxis = tb[j]
           vattj.var_type = 'support_data'
           vattj.validmin = -10.0
           vattj.validmax = 10.0
        Endif
           
        Case tb[j] Of
           'fa_probe_dist': vattj.catdesc = 'FAST distance of each EFI probe from payload, values valid after variable time'
           'fa_probe_phase': vattj.catdesc = 'FAST angle between each EFI probe and spin X-axis in spin plane, spin plane DSC position = probe_dist*[cos(sphase+probe_phase), sin(sphase+probe_phase)]'
           'fa_v12_dist': vattj.catdesc = 'Fast distance between spin-plane probes 1 and 2 in meters, values valid after variable time'
           'fa_v14_dist': vattj.catdesc = 'Fast distance between spin-plane probes 1 and 4 in meters, values valid after variable time'
           'fa_v58_dist': vattj.catdesc = 'Fast distance between spin-plane probes 5 and 8 in meters, values valid after variable time'
           'fa_v910_dist': vattj.catdesc = 'Fast distance between axial probes 9 and 10 in meters, values valid after variable time'
           Else: print, 'MISSING: '+tb[j]
        End
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
                   /add_tname_to_epoch

  Return, filename
End

            
