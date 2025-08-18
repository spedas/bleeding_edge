;+
; PROCEDURE erg_load_sdfit
;
; PURPOSE:
;    Load fitacf CDF files of SuperDARN as tplot variables.
;
;
;
; :KEYWORDS:
;    sites: 3-letter code of SD radar name.
;           Currently only the following station codes work:
;                 'ade', 'adw', 'bks', 'cly', 'cve', 'cvw', 'dce', 'fhe',
;                  'fhw', 'gbr', 'hal', 'han', 'hok', 'inv', 'kap', 'kod',
;                  'ksr', 'pgr', 'pyk', 'rkn', 'san', 'sas', 'sto', 'sye',
;                  'sys', 'tig', 'unw', 'wal', 'zho'
;    cdffn: File path of a CDF file if given explicitly.
;    get_support_data: Turn this on to load the supporting data
;    trange: time range for which data are loaded.
;            e.g., ['2008-10-01/00:00:00','2008-10-02/00:00:00']
;
; :AUTHOR:
;     Tomo Hori (E-mail: horit at isee.nagoya-u.ac.jp)
; :HISTORY:
;   2010/03/09: Created as a draft version
;   2010/07/01: now work for hok and ksr
;   2010/09/10: added some keywords
;
;---------------------------------------------------------------------------
;!!!!! NOTICE !!!!!
;The common time fitacf data of SuperDARN in CDF are distributed
;by Energization and Radiation in Geospace Science Center (ERG-SC) at
;Solar-Terrestrial Environment Laboratory, Nagoya University, in
;collaboration with the SuperDARN PI groups.
;
;It is required for users to read carefully and follow
;the rules of the road attached to the CDF files upon using the data for
;his/her scientific researches.
;
;As for questions and request for the data, please feel free to contact
;the ERG-SC office (E-mail:  erg-sc-core at st4a.isee.nagoya-u.ac.jp,
;please replace "at" by "@").
;------------------------------------------------------------------------------
;
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
;---------------------------------------------------
;Internal routine to get the table of the pixel
;centers from the table of the pixel corners.
PRO get_pixel_cntr, tbl, cnttbl
  dim = SIZE( tbl, /dim )
  rgmax = dim[0]-1 & azmax = dim[1]-1
  cnttbl = fltarr(rgmax,azmax,2)
  for i=0L,rgmax-1 do begin
    for j=0L,azmax-1 do begin
      latarr = tbl[ [i,i+1,i+1,i],[j,j,j+1,j+1],1 ]
      lonarr = tbl[ [i,i+1,i+1,i],[j,j,j+1,j+1],0 ]
      pos = get_sphcntr( latarr, lonarr)
      cnttbl[i,j,1]=pos[0] & cnttbl[i,j,0]=pos[1]
    endfor
  endfor

  return
end
;----------------------------------------------------
PRO erg_load_sdfit, sites=sites, cdffn=cdffn, $
  get_support_data=get_support_data, $
  noacknowledgment=noacknowledgment, trange=trange, $
  downloadonly=downloadonly, no_download=no_download, $
  compact=compact

  ;Initialize the TDAS environment
  thm_init
  sd_init

  ;Set the list of the available sites
  valid_sites = [ 'ade', 'adw', 'bks', 'bpk', 'cly', 'cve', 'cvw', 'dce', 'fhe', $
    'fhw', 'fir', 'gbr', 'hal', 'han', 'hok', 'hkw', 'inv', 'kap', 'ker', 'kod', $
    'ksr', 'mcm', 'pgr', 'pyk', 'rkn', 'san', 'sas', 'sps', 'sto', 'sye', $
    'sys', 'tig', 'unw', 'wal', 'zho', 'lyr' ]

  ;If a CDF file path is not given explicitly
  IF ~KEYWORD_SET(cdffn) THEN BEGIN

    ;Check sites keyword
    if ~keyword_set(sites) then begin
      print, 'Please give a radar name with sites keyword.'
      print, 'Data currently available: ',valid_sites
      return
    endif

    ;Check the site name
    stns = ssl_check_valid_name( sites, valid_sites, /ignore_case, /include_all )
    if strlen(stns[0]) eq 0 then begin
      print, 'No valid radar name in sites!'
      print, 'Data currently available: ',valid_sites
      return
    endif

    ;If multiple radars are set, call this procedure recursively for each radar
    if n_elements(stns) gt 1 then begin
      for i=0, n_elements(stns)-1 do begin
        erg_load_sdfit, sites=stns[i], get_support_data=get_support_data,$
          noacknowledgment=noacknowledgment, trange=trange,$
          downloadonly=downloadonly, no_download=no_download, $
          compact=compact
      endfor
      return
    endif

    stn = stns[0]

    source = file_retrieve(/struct)
    source.local_data_dir = root_data_dir()+'ergsc/ground/radar/sd/fitacf/'+stn+'/'
    source.remote_data_dir = !sdarn.remote_data_dir+stn+'/'
    source.min_age_limit = 900
    if keyword_set(downloadonly) then source.downloadonly = 1
    if keyword_set(no_download) then begin
      source.no_download = 1
      source.nowait = 1
      source.no_update = 1
    endif

    ;Currently only the first element of array "sites" is adjusted.
    ;to be implemented in future for loading data of multiple stations
    datfileformat = 'YYYY/sd_fitacf_l2_'+stn+'_YYYYMMDD*cdf'
    relfnames = file_dailynames(file_format=datfileformat, trange=trange, times=times)

;    datfiles = file_retrieve(relfnames, $
;      local_data_dir=source.local_data_dir,remote_data_dir=source.remote_data_dir, _extra=source)
    datfiles = $
      spd_download( remote_file = relfnames, remote_path = source.remote_data_dir $
      , local_path = source.local_data_dir $
      , /last_version, no_download=no_download $
      )
    IF total(file_test(datfiles)) eq 0 THEN BEGIN
      print, 'Cannot download/find data file: '+datfiles
      PRINT, 'No data was loaded!'
      RETURN
    ENDIF
    ;If a CDF file path is given
  ENDIF ELSE BEGIN
    datfiles = cdffn
    IF FIX(TOTAL(FILE_TEST(datfiles))) LT 1 THEN BEGIN
      PRINT, 'Cannot find any of the data file(s): ', cdffn
      RETURN
    ENDIF
    IF KEYWORD_SET(sites) THEN stn = sites[0] ELSE stn='stn'
  ENDELSE

  ;for the case of "donwload only"
  if keyword_set(downloadonly) then return

  ;Read CDF files and create tplot variables
  prefix='sd_' + stn + '_'
  cdf2tplot,file=datfiles, prefix=prefix, $
    /get_support_data, $
    /convert_int1_to_int2, tplotnames=tplotn

  ;Quit if no data have been loaded
  if strlen( tplotn[0] ) lt 7 then begin
    print, 'No tplot var loaded.'
    return
  endif

  ;Set data values to NaN if abs(data) > 9000
  tclip, prefix+['pwr','spec','vlos'] +'*', -9000,9000, /over
  s = tnames(prefix+'elev*')
  if strlen(s[0]) gt 5 then begin
    tclip, prefix+'elev' +'*', -9000,9000, /over
  endif

  ;For the case of a CDF including multiple range gate data
  suf = strmid( tplotn[ where( strpos(tplotn, prefix+'azim_no_') ne -1) ], 0, 1, /reverse )
  for i=0, n_elements(suf)-1 do begin

    ;Set labels for some tplot variables
    options,prefix+'pwr_'+suf[i], ysubtitle='[range gate]',ztitle='Backscatter power [dB]'
    options,prefix+'pwr_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'pwr_err_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='power err [dB]'
    options,prefix+'pwr_err_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'spec_width_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='Spec. width [m/s]'
    options,prefix+'spec_width_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'spec_width_err_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='Spec. width err [m/s]'
    options,prefix+'spec_width_err_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'vlos_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='Doppler velocity [m/s]'
    options,prefix+'vlos_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'vlos_err_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='Vlos err [m/s]'
    options,prefix+'vlos_err_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'elev_angle_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='Elev. angle [deg]'
    options,prefix+'elev_angle_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'echo_flag_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='1: iono. echo'
    options,prefix+'echo_flag_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'quality_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='quality'
    options,prefix+'quality_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'
    options,prefix+'quality_flag_'+suf[i], ytitle=strupcase(stn)+'!Call beams',ysubtitle='[range gate]',ztitle='quality flg'
    options,prefix+'quality_flag_'+suf[i], 'ytitle',strupcase(stn)+'!Call beams'

    ;Split vlos_? tplot variable into 3 components
    get_data, prefix+'vlos_'+suf[i], data=d, dl=dl, lim=lim
    store_data, prefix+'vlos_'+suf[i], data={x:d.x, $
      y:d.y[*,*,2],v:d.v},dl=dl,lim=lim
    options,prefix+'vlos_'+suf[i],ztitle='LOS Doppler vel. [m/s]'
    store_data, prefix+'vnorth_'+suf[i], data={x:d.x, y:d.y[*,*,0],v:d.v},dl=dl,lim=lim
    options,prefix+'vnorth_'+suf[i],ztitle='LOS V Northward [m/s]'
    store_data, prefix+'veast_'+suf[i], data={x:d.x, y:d.y[*,*,1],v:d.v},dl=dl,lim=lim
    options,prefix+'veast_'+suf[i],ztitle='LOS V Eastward [m/s]'

    ;Combine iono. echo and ground echo for vlos
    nm = ['vlos_','vnorth_','veast_']
    for n=0L, n_elements(nm)-1 do begin
      get_data, prefix+nm[n]+suf[i], data=d, dl=dl, lim=lim
      get_data, prefix+'echo_flag_'+suf[i], data=flg, dl=flgdl, lim=flglim
      d_g = d
      idx = where( flg.y eq 1. )
      if idx[0] ne -1 then d_g.y[idx] = !values.f_nan
      idx = where( flg.y ne 1. )
      if idx[0] ne -1 then d.y[idx] = !values.f_nan
      maxrg = max(d.v, /nan)+1
      store_data, prefix+nm[n]+'iscat_'+suf[i], data=d, lim=lim, $
        dl={ytitle:'',ysubtitle:'',ztitle:'',spec:1}
      store_data, prefix+nm[n]+'gscat_'+suf[i], data=d_g, lim=lim, $
        dl={ytitle:'',ysubtitle:'',ztitle:'',spec:1,fill_color:5}
      store_data, prefix+nm[n]+'bothscat_'+suf[i], $
        data=[prefix+nm[n]+'iscat_'+suf[i],prefix+nm[n]+'gscat_'+suf[i]], $
        dl={yrange:[0,maxrg]}
    endfor

    ;Set the z range explicitly for some tplot variables
    zlim, prefix+'pwr_'+suf[i], 0,30
    zlim, prefix+'pwr_err_'+suf[i], 0,30
    zlim, prefix+'spec_width_'+suf[i], 0,200
    zlim, prefix+'spec_width_err_'+suf[i], 0,300
    zlim, prefix+'vlos_*_'+suf[i], -400,400
    zlim, prefix+'vnorth_*_'+suf[i], -400,400
    zlim, prefix+'veast_*_'+suf[i], -400,400
    zlim, prefix+'vlos_err_'+suf[i], 0,300

    ;Fill values --> NaN
    get_data, prefix+'pwr_'+suf[i], data=d & pwr = d.y
    idx = WHERE( ~FINITE(pwr) )

    tn=prefix+'echo_flag_'+suf[i]
    get_data, tn, data=d, dl=dl, lim=lim & val=FLOAT(d.y)
    IF idx[0] NE -1 THEN val[idx] = !values.f_nan
    store_data, tn, data={x:d.x, y:val, v:d.v}, dl=dl, lim=lim

    tn=prefix+'quality_'+suf[i]
    get_data, tn, data=d, dl=dl, lim=lim & val=FLOAT(d.y)
    IF idx[0] NE -1 THEN val[idx] = !values.f_nan
    store_data, tn, data={x:d.x, y:val, v:d.v}, dl=dl, lim=lim

    tn=prefix+'quality_flag_'+suf[i]
    get_data, tn, data=d, dl=dl, lim=lim & val=FLOAT(d.y)
    IF idx[0] NE -1 THEN val[idx] = !values.f_nan
    store_data, tn, data={x:d.x, y:val, v:d.v}, dl=dl, lim=lim

    ;Reassign scan numbers for the combined data
    tn=prefix+'scanstartflag_'+suf[i]
    get_data, tn, data=d, dl=dl, lim=lim & scflg = abs(d.y)
    scno = long(scflg) & scno[*] = -1
    scno_t = 0L & scno[0] = scno_t
    for n = 1L, n_elements(scno)-1 do begin
      if scflg[n] gt 0 then scno_t = scno_t + 1
      scno[n] = scno_t
    endfor
    tn=prefix+'scanno_'+suf[i]
    get_data, tn, data=d, dl=dl, lim=lim
    store_data, tn, data={x:d.x, y:scno}, dl=dl, lim=lim

    ;Apply tclip the vlos data temporarily for demo
    ;tclip, prefix+'vlos_'+suf[i] , -500.,500., /over

  endfor


  ;Load the position table(s) ;;;;;;;;;;;;;;;;;;
  ;Currently supports SD fitacf CDFs containing up to 4 pos. tables.
  ;tbl_0='' & tbl_1='' & tbl_2='' &tbl_3='' & tbl_4=''
  ;tbl_5='' & tbl_6='' & tbl_7='' &tbl_8=''&tbl_9=''
  ;time_0='' & time_1='' & time_2='' & time_3='' & time_4=''
  ;time_5='' & time_6='' & time_7='' & time_8=''& time_9=''
  tbllist = ['tbl_0', 'tbl_1' , 'tbl_2', 'tbl_3', 'tbl_4', $
    'tbl_5', 'tbl_6' , 'tbl_7', 'tbl_8', 'tbl_9' ]
  timelist = ['time_0','time_1','time_2','time_3', 'time_4', $
    'time_5','time_6','time_7','time_8','time_9']
  FOR i=0L, N_ELEMENTS(datfiles)-1 DO BEGIN
    if ~file_test(datfiles[i]) then continue
    cdfi = cdf_load_vars( datfiles[i], varformat='*',/convert_int1_to_int2 )
    timevn = strfilter( cdfi.vars.name, 'Epoch_?' )
    ptblvn = strfilter( cdfi.vars.name, 'position_tbl_?' )
    ;Error check
    IF N_ELEMENTS(timevn) EQ 0 OR N_ELEMENTS(ptblvn) EQ 0 OR $
      N_ELEMENTS(timevn) NE N_ELEMENTS(ptblvn) THEN BEGIN
      dprint, 'Epoch_x and position_tbl_x mismatch in CDF!'
      RETURN
    ENDIF
    timevn = timevn[ SORT(timevn) ] ;sort the variable names
    ptblvn = ptblvn[ SORT(ptblvn) ]

    FOR j=0, N_ELEMENTS(ptblvn)-1 DO BEGIN
      tvn = timevn[j] & pvn = ptblvn[j]
      stblno = STRMID(tvn, 0, 1, /reverse)
      tvnidx = (WHERE( STRCMP(cdfi.vars.name,tvn ) , nw))[0]
      pvnidx = (WHERE( STRCMP(cdfi.vars.name,pvn ) , nw))[0]
      time = *cdfi.vars[tvnidx].dataptr
      tbl  = *cdfi.vars[pvnidx].dataptr
      get_pixel_cntr, tbl, cnttbl ;Obtain the pixel centers
      dim = SIZE( tbl, /dim ) & tbl2 = REFORM( tbl, 1, dim[0],dim[1],dim[2] )
      cnttbl2 = REFORM( cnttbl, 1, dim[0]-1,dim[1]-1,dim[2] )
      case (fix(stblno)) of
        0: begin
          if n_elements(time_0) eq 0 then time_0 = [time[0],time[n_elements(time)-1]] $
          else time_0 = [ time_0, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_0) eq 0 then tbl_0 = [tbl2,tbl2] $
          else tbl_0 = [ tbl_0, tbl2, tbl2 ]
          if n_elements(cnttbl_0) eq 0 then cnttbl_0 = [cnttbl2,cnttbl2] $
          else cnttbl_0 = [ cnttbl_0, cnttbl2, cnttbl2 ]
        end
        1: begin
          if n_elements(time_1) eq 0 then time_1 = [time[0],time[n_elements(time)-1]] $
          else time_1 = [ time_1, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_1) eq 0 then tbl_1 = [tbl2,tbl2] $
          else tbl_1 = [ tbl_1, tbl2, tbl2 ]
          if n_elements(cnttbl_1) eq 0 then cnttbl_1 = [cnttbl2,cnttbl2] $
          else cnttbl_1 = [ cnttbl_1, cnttbl2, cnttbl2 ]
        end
        2: begin
          if n_elements(time_2) eq 0 then time_2 = [time[0],time[n_elements(time)-1]] $
          else time_2 = [ time_2, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_2) eq 0 then tbl_2 = [tbl2,tbl2] $
          else tbl_2 = [ tbl_2, tbl2, tbl2 ]
          if n_elements(cnttbl_2) eq 0 then cnttbl_2 = [cnttbl2,cnttbl2] $
          else cnttbl_2 = [ cnttbl_2, cnttbl2, cnttbl2 ]
        end
        3: begin
          if n_elements(time_3) eq 0 then time_3 = [time[0],time[n_elements(time)-1]] $
          else time_3 = [ time_3, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_3) eq 0 then tbl_3 = [tbl2,tbl2] $
          else tbl_3 = [ tbl_3, tbl2, tbl2 ]
          if n_elements(cnttbl_3) eq 0 then cnttbl_3 = [cnttbl2,cnttbl2] $
          else cnttbl_3 = [ cnttbl_3, cnttbl2, cnttbl2 ]
        end
        4: begin
          if n_elements(time_4) eq 0 then time_4 = [time[0],time[n_elements(time)-1]] $
          else time_4 = [ time_4, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_4) eq 0 then tbl_4 = [tbl2,tbl2] $
          else tbl_4 = [ tbl_4, tbl2, tbl2 ]
          if n_elements(cnttbl_4) eq 0 then cnttbl_4 = [cnttbl2,cnttbl2] $
          else cnttbl_4 = [ cnttbl_4, cnttbl2, cnttbl2 ]
        end
        5: begin
          if n_elements(time_5) eq 0 then time_5 = [time[0],time[n_elements(time)-1]] $
          else time_5 = [ time_5, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_5) eq 0 then tbl_5 = [tbl2,tbl2] $
          else tbl_5 = [ tbl_5, tbl2, tbl2 ]
          if n_elements(cnttbl_5) eq 0 then cnttbl_5 = [cnttbl2,cnttbl2] $
          else cnttbl_5 = [ cnttbl_5, cnttbl2, cnttbl2 ]
        end
        6: begin
          if n_elements(time_6) eq 0 then time_6 = [time[0],time[n_elements(time)-1]] $
          else time_6 = [ time_6, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_6) eq 0 then tbl_6 = [tbl2,tbl2] $
          else tbl_6 = [ tbl_6, tbl2, tbl2 ]
          if n_elements(cnttbl_6) eq 0 then cnttbl_6 = [cnttbl2,cnttbl2] $
          else cnttbl_6 = [ cnttbl_6, cnttbl2, cnttbl2 ]
        end
        7: begin
          if n_elements(time_7) eq 0 then time_7 = [time[0],time[n_elements(time)-1]] $
          else time_7 = [ time_7, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_7) eq 0 then tbl_7 = [tbl2,tbl2] $
          else tbl_7 = [ tbl_7, tbl2, tbl2 ]
          if n_elements(cnttbl_7) eq 0 then cnttbl_7 = [cnttbl2,cnttbl2] $
          else cnttbl_7 = [ cnttbl_7, cnttbl2, cnttbl2 ]
        end
        8: begin
          if n_elements(time_8) eq 0 then time_8 = [time[0],time[n_elements(time)-1]] $
          else time_8 = [ time_8, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_8) eq 0 then tbl_8 = [tbl2,tbl2] $
          else tbl_8 = [ tbl_8, tbl2, tbl2 ]
          if n_elements(cnttbl_8) eq 0 then cnttbl_8 = [cnttbl2,cnttbl2] $
          else cnttbl_8 = [ cnttbl_8, cnttbl2, cnttbl2 ]
        end
        9: begin
          if n_elements(time_9) eq 0 then time_9 = [time[0],time[n_elements(time)-1]] $
          else time_9 = [ time_9, [time[0],time[n_elements(time)-1]] ]
          if n_elements(tbl_9) eq 0 then tbl_9 = [tbl2,tbl2] $
          else tbl_9 = [ tbl_9, tbl2, tbl2 ]
          if n_elements(cnttbl_9) eq 0 then cnttbl_9 = [cnttbl2,cnttbl2] $
          else cnttbl_9 = [ cnttbl_9, cnttbl2, cnttbl2 ]
        end
        else: begin
        end
      endcase

    ENDFOR
  ENDFOR

  if n_elements(tbl_0) gt 2 then begin
    store_data, prefix+'position_tbl_0', $
      data={x:time_double(time_0,/epoch), y:tbl_0}
    store_data, prefix+'positioncnt_tbl_0', $
      data={x:time_double(time_0,/epoch), y:cnttbl_0}
  endif
  if n_elements(tbl_1) gt 2 then begin
    store_data, prefix+'position_tbl_1', $
      data={x:time_double(time_1,/epoch), y:tbl_1}
    store_data, prefix+'positioncnt_tbl_1', $
      data={x:time_double(time_1,/epoch), y:cnttbl_1}
  endif
  if n_elements(tbl_2) gt 2 then begin
    store_data, prefix+'position_tbl_2', $
      data={x:time_double(time_2,/epoch), y:tbl_2}
    store_data, prefix+'positioncnt_tbl_2', $
      data={x:time_double(time_2,/epoch), y:cnttbl_2}
  endif
  if n_elements(tbl_3) gt 2 then begin
    store_data, prefix+'position_tbl_3', $
      data={x:time_double(time_3,/epoch), y:tbl_3}
    store_data, prefix+'positioncnt_tbl_3', $
      data={x:time_double(time_3,/epoch), y:cnttbl_3}
  endif
  if n_elements(tbl_4) gt 2 then begin
    store_data, prefix+'position_tbl_4', $
      data={x:time_double(time_4,/epoch), y:tbl_4}
    store_data, prefix+'positioncnt_tbl_4', $
      data={x:time_double(time_4,/epoch), y:cnttbl_4}
  endif
  if n_elements(tbl_5) gt 2 then begin
    store_data, prefix+'position_tbl_5', $
      data={x:time_double(time_5,/epoch), y:tbl_5}
    store_data, prefix+'positioncnt_tbl_5', $
      data={x:time_double(time_5,/epoch), y:cnttbl_5}
  endif
  if n_elements(tbl_6) gt 2 then begin
    store_data, prefix+'position_tbl_6', $
      data={x:time_double(time_6,/epoch), y:tbl_6}
    store_data, prefix+'positioncnt_tbl_6', $
      data={x:time_double(time_6,/epoch), y:cnttbl_6}
  endif
  if n_elements(tbl_7) gt 2 then begin
    store_data, prefix+'position_tbl_7', $
      data={x:time_double(time_7,/epoch), y:tbl_7}
    store_data, prefix+'positioncnt_tbl_7', $
      data={x:time_double(time_7,/epoch), y:cnttbl_7}
  endif
  if n_elements(tbl_8) gt 2 then begin
    store_data, prefix+'position_tbl_8', $
      data={x:time_double(time_8,/epoch), y:tbl_8}
    store_data, prefix+'positioncnt_tbl_8', $
      data={x:time_double(time_8,/epoch), y:cnttbl_8}
  endif
  if n_elements(tbl_9) gt 2 then begin
    store_data, prefix+'position_tbl_9', $
      data={x:time_double(time_9,/epoch), y:tbl_9}
    store_data, prefix+'positioncnt_tbl_9', $
      data={x:time_double(time_9,/epoch), y:cnttbl_9}
  endif

  ;Release unused ptrs
  tplot_ptrs = ptr_extract(tnames(/dataquant))
  unused_ptrs = ptr_extract(cdfi,except=tplot_ptrs)
  PTR_FREE,unused_ptrs

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;Show the rules of the road
  ;unless keyword noacknowledgement is defined.
  if ~keyword_set(noacknowledgment) then begin
    vstr = tnames(prefix+'pwr_?')
    if strlen(vstr[0]) gt 5 then begin
      get_data, vstr[0], data=d, dl=dl
      ror = dl.cdf.gatt.rules_of_use

      print, ''
      print, '############## RULES OF THE ROAD ################'
      line_length = 78
      rorlen = strlen(ror)

      for i=0L, rorlen/line_length do begin
        print, strmid( ror, i*line_length, line_length )
      endfor

      print, '############## RULES OF THE ROAD ################'
    endif
  endif

  ;Leave only minimal set of the variables if keyword "compact" is set.
  if keyword_set(compact) then begin
    varn1= 'cpid channel int_time azim_no pwr_err spec_width_err vlos_err elev_angle elev_angle_err '
    varn2= 'phi0 phi0_err echo_flag quality quality_flag scanno scanstartflag '
    varn3= 'lagfr smsep nrang_max tfreq noise num_ave txpl vnorth veast '
    varn4= 'vlos_bothscat vlos_iscat vlos_gscat vnorth_iscat vnorth_gscat vnorth_bothscat '
    varn5= 'veast_iscat veast_gscat veast_bothscat position_tbl positioncnt_tbl '
    varn_removed = strsplit(varn1+varn2+varn3+varn4+varn5, /ext )
    store_data, 'sd_'+stn+'_'+varn_removed+'_?', /delete
  endif

  ;Normal end
  RETURN
END

