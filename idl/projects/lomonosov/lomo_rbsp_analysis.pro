;+
;NAME:
;  lomo_rbsp_analysis
;           This routine loads local ELFIN ENG Lomonosov data.
;           
;         
;KEYWORDS (commonly used by other load routines):
;  DATATYPE = (Currently downloads all data types. Should change that.)
;  LEVEL    = levels include 1 (2 will be available shortly)
;  TRANGE   = (Optional) Time range of interest  (2 element array), if
;             this is not set, the default is to prompt the user. Note
;             that if the input time range is not a full day, a full
;             day's data is loaded
;  LOCAL_DATA_DIR = local directory to store the CDF files; should be set if
;             you're on *nix or OSX, the default currently assumes the IDL working directory
;  SOURCE   = sets a different system variable. By default the MMS mission system variable
;             is !elf
;  TPLOTNAMES = set to override default names for tplot variables
;  NO_UPDATES = use local data only, don't query the http site for updated files.
;  SUFFIX   = append a suffix to tplot variables names
;
;EXAMPLE:
;   lomo_load_eng, trange=['2016-06-24', '2016-06-25']

;NOTES:
;  *********Need to compile aacgmidl.pro first*********
;  *********Need to run aacgmidl_example and aacgm_plot*******
;  *********Need to install cspice_install (run > print, spice_test() for directions)********
;--------------------------------------------------------------------------------------
;-
PRO lomo_rbsp_analysis, dist_crit=dist_crit, mlt_crit=mlt_crit, lshell_crit=lshell_crit


;************ NOTE run elf_init ***************
;************ AND .compile aacgmidl ***********
;             AND run aacgm_example
;             AND run aacgm_plot
;**********************************************
  re=6378.
;  thm_init
;  elf_init
  t0 = time_double('2016-01-01')
  
  timespan, '2016-06-01'  ;, 2d
  tr = timerange()
  t1 = timerange()
  
  if ~keyword_set(lshell_crit) then lshell_crit=.5
  if ~keyword_set(dist_crit) then dist_crit=.5
  if ~keyword_set(mlt_crit) then mlt_crit=2
  mlts='mlt'+strtrim(string(mlt_crit),1)
  lshs='lshell'+strtrim(string(lshell_crit),1)
  ds='dist'+strtrim(string(dist_crit),1)  
  root_file='lomonosov_rbspa_conjunctions_'+mlts+lshs+ds
  
  
  for j=0,90 do begin
;goto, restore_file    
    tr = t1 + (j * 86400.)
    timespan, tr
print, '******** J = '+string(j)+ '*********'
    ; get lomonosov data
    get_lomo_data, tr=tr
    get_data, 'lomo_pos_gsm', data=lomo_pos_gsm
    ; and calc lshell and mlt
    xyz2rthph, lomo_pos_gsm.y[*,0], lomo_pos_gsm.y[*,1], lomo_pos_gsm.y[*,2], radius, lomo_lat, lomo_lon, 0
    tstruc=time_struct(lomo_pos_gsm.x)
    year=tstruc.year
    sec=lomo_pos_gsm.x-t0
    lomo_mlt=make_array(n_elements(lomo_pos_gsm.x), /double)
;    stop
    for k=0,n_elements(lomo_mlt)-1 do lomo_mlt[k]=calc_mlt(year[k],sec[k],lomo_lon[k])
    lomo_pos_gsm_re = make_array(4, n_elements(lomo_pos_gsm.x), /double)
    lomo_pos_gsm_re[0,*]=lomo_pos_gsm.x
    lomo_pos_gsm_re[1,*]=lomo_pos_gsm.y[*,0] / re
    lomo_pos_gsm_re[2,*]=lomo_pos_gsm.y[*,1] / re
    lomo_pos_gsm_re[3,*]=lomo_pos_gsm.y[*,2] / re
    lomo_lshell=calculate_lshell(lomo_pos_gsm_re)   ; in re

    ; get rbsp data
    rbsp_efw_init, /no_color_setup, /no_download
    rbsp_spice_init, /no_color_setup, /no_download
    rbsp_load_state, probe='a'
    cotrans, 'rbspa_pos_gse', 'rbspa_pos_gsm', /gse2gsm
    get_data, 'rbspa_pos_gsm', data=rbspa_pos_gsm, dlimits=rbspa_pos_dlimits, limits=rbspa_pos_limits
    ; interpolate data to lomo times
    rbspa_pos_xgsm = interpol(rbspa_pos_gsm.y[*,0], rbspa_pos_gsm.x, lomo_pos_gsm.x)
    rbspa_pos_ygsm = interpol(rbspa_pos_gsm.y[*,1], rbspa_pos_gsm.x, lomo_pos_gsm.x)
    rbspa_pos_zgsm = interpol(rbspa_pos_gsm.y[*,2], rbspa_pos_gsm.x, lomo_pos_gsm.x)
    rbspa_time = lomo_pos_gsm.x
    ; and calc lshell and mlt
    xyz2rthph, rbspa_pos_xgsm, rbspa_pos_ygsm, rbspa_pos_zgsm, radius, rbspa_lat, rbspa_lon, 0
    tstruc=time_struct(rbspa_time)
    year=tstruc.year
    sec=rbspa_time-t0
    rbspa_mlt=make_array(n_elements(rbspa_time), /double)
    for k=0,n_elements(rbspa_time)-1 do rbspa_mlt[k]=calc_mlt(year[k],sec[k],rbspa_lon[k])
    rbspa_pos_gsm_re = make_array(4, n_elements(rbspa_time), /double)
    rbspa_pos_gsm_re[0,*]=rbspa_time
    rbspa_pos_gsm_re[1,*]=rbspa_pos_xgsm / re
    rbspa_pos_gsm_re[2,*]=rbspa_pos_ygsm / re
    rbspa_pos_gsm_re[3,*]=rbspa_pos_zgsm / re
    rbspa_lshell=calculate_lshell(rbspa_pos_gsm_re)   ; in re
;stop
    ; Now find when they are within +/- 2 mlt of each other and
    ; within +/-.5 lshell and
    ; within .5 re of each other and
    ; lomo is between lshells 3-7
    ; calculate lshell difference
    dif_lshell = abs(rbspa_lshell - lomo_lshell)
    ; calculate distance between 2 points
    dist_rbspa2lomo = sqrt((rbspa_pos_xgsm - lomo_pos_gsm.y[*,0])^2 + $
                           (rbspa_pos_ygsm - lomo_pos_gsm.y[*,1])^2 + $
                           (rbspa_pos_zgsm - lomo_pos_gsm.y[*,2])^2)/re
    dif_mlt = abs(rbspa_mlt - lomo_mlt)

;    ind=where((dif_lshell LE .5) AND (dif_mlt LE 2.25) AND $
;      (lomo_lshell GE 3 AND lomo_lshell LE 7), ncnt)  ; AND $
;      (dif_mlt LE 2.), ncnt)
    ind=where((dif_lshell LE lshell_crit) AND (dif_mlt LE mlt_crit) AND $
       (dist_rbspa2lomo LE dist_crit) AND (lomo_lshell GE 3 AND lomo_lshell LE 7), ncnt)  
;      (dif_mlt LE 2.), ncnt)
;save, file='lomo_rbsp_'+strtrim(i, 1)+'.sav'
;restore_file:
;restore, file='lomo_rbsp_'+strtrim(j, 1)+'.sav'
    if ncnt GT 0 then begin
;stop
 ;ind=where((dif_lshell LE .5), ncnt)   ; AND $
;  (lomo_lshell GE 3 AND lomo_lshell LE 7), ncnt)  ; AND $

        find_interval, ind, st, et
        plot, lomo_pos_gsm.x, lomo_lshell, yrange=[0,10]
        oplot, lomo_pos_gsm.x, lomo_lshell, color=85
        oplot, lomo_pos_gsm.x, rbspa_lshell, color=150
        oplot, lomo_pos_gsm.x, dif_lshell, color=85, linestyle=2
        oplot, lomo_pos_gsm.x, dist_rbspa2lomo, color=250
        oplot, lomo_pos_gsm.x, dif_mlt, color=50
        if ncnt GT 1 then begin
            symsize=.2
            oplot, lomo_pos_gsm.x[ind], lomo_lshell[ind], color=85, psym=2, symsize=symsize
            oplot, lomo_pos_gsm.x[ind], rbspa_lshell[ind], color=150, psym=2, symsize=symsize
            oplot, lomo_pos_gsm.x[ind], dif_lshell[ind], color=85, linestyle=2, psym=2, symsize=symsize
            oplot, lomo_pos_gsm.x[ind], dist_rbspa2lomo[ind], color=250, psym=2, symsize=symsize
            oplot, lomo_pos_gsm.x[ind], dif_mlt[ind], color=50, psym=2, symsize=symsize
            endif
;            print, '*************************'
;            print, lomo_root+dates[i]+'.dat'
;            print, '*************************'
;            help, ind
            ;for k=0,n_elements(st)-1 do begin
              if undefined(start_conj) then start_conj = [lomo_pos_gsm.x[st[0]]] else start_conj = [start_conj, lomo_pos_gsm.x[st[0]]]
              if undefined(end_conj) then end_conj = [lomo_pos_gsm.x[et[0]]] else end_conj = [end_conj, lomo_pos_gsm.x[et[0]]]
              tsecs=lomo_pos_gsm.x[et[0]] - lomo_pos_gsm.x[st[0]]
              if undefined(total_sec) then total_sec = [tsecs] else total_sec = [total_sec, tsecs]
              print, tsecs
              if undefined(tstart) then tstart = [start_conj] else tstart=[start_conj, tstart]
        endif
;    stop
  endfor
  if ~undefined(total_sec) then begin
  save, file='C:\Users\clrussell\Desktop\barrel\'+root_file+'.sav'
  write_csv,'C:\Users\clrussell\Desktop\barrel\'+root_file+'.csv', time_string(start_conj), time_string(end_conj), total_sec
stop
  endif
END
