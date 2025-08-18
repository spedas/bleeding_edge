;+
;NAME:
; mvn_load_all_qlook
;PURPOSE:
; Loads all of the data needed to do ALL of the qlook plots, this is
; done to avoid multiple data loads in mvn_over shell, the individual
; plot routines can then be called with a /noload_data option.
;CALLING SEQUENCE:
; mvn_load_all_qlook, date = date, $
;      l0_input_file = l0_input_file, _extra=_extra
;INPUT:
; No explicit input, everthing is via keyword.
;OUTPUT:
; No explicit outputs, a bunch of tplot variables are created
;KEYWORDS:
; date = If set, a plot for the input date.
; l0_input_file = A filename for an input file, if this is set, the
;                 date and trange keywords are ignored.
;HISTORY:
; 16-jul-2013, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-03-19 13:42:44 -0700 (Thu, 19 Mar 2015) $
; $LastChangedRevision: 17150 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_load_all_qlook.pro $
Pro mvn_load_all_qlook, date_in = date_in, l0_input_file = l0_input_file, $
                        device = device, stop_in_catch = stop_in_catch, $
                        _extra=_extra

;Hold load position for error handling
common mvn_load_all_qlook, load_position


catch, error_status
If(error_status Ne 0) Then Begin
  dprint, dlevel = 0, 'Got Error Message'
  help, /last_message, output = err_msg
  For ll = 0, n_elements(err_msg)-1 Do print, err_msg[ll]
  If(keyword_set(stop_in_catch)) Then stop
  Case load_position Of
    'init':Begin
      print, 'Bad initialization: Exiting'
      Return
    End
    'lpw':Begin
      print, 'Skipped LPW Load: '+filex
      Goto, skip_lpw
    End
    'mag':Begin
      print, 'Skipped MAG Load: '+filex
      Goto, skip_mag
    End
    'sep':Begin
      print, 'Skipped SEP Load: '+filex
      Goto, skip_sep
    End
    'swe':Begin
      print, 'Skipped Swe Load: '+filex
      Goto, skip_swe
    End
    'swia':Begin
      print, 'Skipped Swia load: '+filex
      Goto, skip_swia
    End
    'sta':Begin
      print, 'Skipped STA Load: '+filex
      Goto, skip_sta
    End
    'ngi':Begin
      print, 'Skipped NGIMS Load: '+filex
      Goto, skip_ngi
    End
    Else: Begin
      print, 'MVN_LOAD_ALL_QLOOK exiting with no clue'
    End
  Endcase
Endif

load_position = 'init'

mvn_qlook_init, device = device

;Load all of the data
If(keyword_set(l0_input_file)) Then Begin
   filex = l0_input_file[0]
Endif Else If(keyword_set(date_in)) Then Begin
   filex = mvn_l0_db2file(date_in, l0_file_type = 'all')
Endif Else Begin
   message, /info, 'Need to set date or l0_input_file keyword'
Endelse

;Here you have a filename, some of these inputs require a time span or
;date, extract the date from the filename
If(is_string(filex)) Then Begin
   p1  = strsplit(file_basename(filex), '_',/extract)
   date = p1[4]
Endif Else Begin
   dprint, 'Missing Input File, Returning'
   Return
Endelse
yyyy = strmid(date, 0, 4)
mm = strmid(date, 4, 2)
dd = strmid(date, 6, 2)
date_str = yyyy+'-'+mm+'-'+dd
d0 = time_double(date_str)
time_range = d0+[0.0, 86400.0]
timespan, d0, 1 

If(~is_string(filex)) Then message, 'No file found:'

load_position = 'mag'

;MAG data, switched dcommutation, jmm, 29-sep-2014
mvn_pfp_l0_file_read, file = filex, /mag
magvar0 = ['mvn_mag1_svy_BAVG', 'mvn_mag2_svy_BAVG']
magvar1 = ['mvn_ql_mag1', 'mvn_ql_mag2']
For j = 0, 1 Do Begin
   get_data, magvar0[j], data = dj
   If(is_struct(dj)) Then Begin
      copy_data, magvar0[j], magvar1[j]
;units and coordinate system?
      data_att = {units:'nT', coord_sys:'Sensor'}
      dlimits = {spec:0, log:0, colors:[2, 4, 6], labels: ['x', 'y', 'z'],  $
                 labflag:1, color_table:39, data_att:data_att}
      store_data, magvar1[j], dlimits = dlimits
   Endif
Endfor

skip_mag:

load_position = 'sep'
;SEP data
mvn_pfp_l0_file_read, file=filex, /sep 

skip_sep:

load_position = 'swe'

;SWE data, may need a time range
mvn_swe_load_l0, time_range, filename = filex
mvn_swe_ql

skip_swe:
load_position = 'swia'
;SWI data
mvn_swia_load_l0_data, filex, /tplot, /sync
;Create an "energy spectrogram"
get_data, 'mvn_swis_en_counts', data=ddd
If(is_struct(ddd)) Then Begin
   ddd1 = ddd
   ddd1.y = ddd1.y*ddd1.v
   ddd1.zrange = minmax(ddd1.zrange) & ddd1.zrange[0] = 10.0
   ddd1.ztitle = 'SWIA!cEnergy'
   store_data, 'mvn_swis_en_energy', data = ddd1
Endif Else store_data, 'mvn_swis_en_energy', data = ddd

skip_swia:

load_position = 'sta'
;STA data
mvn_sta_gen_ql, file = filex

skip_sta:

;Load NGIMS data, if available, 
load_position = 'ngi'
ngi_file = '/disks/data/maven/data/sci/ngi/ql/mvn_ngi_ql_'+date+'.csv'
ppp = mvn_ngi_read_csv(ngi_file)

skip_ngi:

load_position = 'lpw'
;LPW data
mvn_lpw_load, date_str, tplot_var='all', packet='nohsbm', /notatlasp, /noserver
;mvn_lpw_load, filex, filetype='L0', tplot_var='all', packet='nohsbm', /notatlasp, /noserver, board = 'FM'
mvn_lpw_ql_3panels
mvn_lpw_ql_instr_page

skip_lpw:

;Orbit number
load_position = 'orb'
orbdata = mvn_orbit_num()
store_data, 'mvn_orbnum', orbdata.peri_time, orbdata.num, $
            dlimit={ytitle:'Orbit'}

mvn_qlook_init, device = device


Return
End
