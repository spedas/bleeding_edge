;+
; NAME:   elf_plot_orbit_conjunctions_test
; PURPOSE:  create ELFIN, THEMIS, MMS, ERG orbit plots in GSM coordinates for web site
; INPUT:  tstart like '2009-12-01'
; OUTPUT: gif files may be generated
; KEYWORDS: gifout = gif images are generated
;           file = specify file if not reading THEMIS ephemeris
;           insert = insert stop at end of program
;           rbsp_too = if set, overlay RBSP orbits
;           mms_too = if set, overlay MMS orbits
;           erg_too = if set, overlay ERG orbigts
;           goes_too = if set, GOES 15 and 16 orbits are overlaid
;               (NOTE: need to modify to handle any goes orbits)
;           model = name of Tsyganenko model ('t89', 't96', 'ta15'). default is 't96' (Not yet implemented)
; HISTORY:  original file in March 2007, hfrey
; MODIFICATIONS: 2010-01-14, hfrey, new definition of plot area
;
; REQUIREMENTS: compile two programs for instance in
;
; .r /home/sfrey/themis/MOC/pro/mpause_2
; .r /home/sfrey/themis/MOC/pro/bshock_2
;
; VERSION:
;   $LastChangedBy: jimm $
;   $LastChangedDate: 2020-11-18 13:03:02 -0800 (Wed, 18 Nov 2020) $
;   $LastChangedRevision: 29359 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/thmsoc/asi/themis_orbits.pro $
;-  ;elf_plot_orbit_conjunctions,'2021-07-11/00:00:00',rbsp_too=0,mms_too=0,erg_too=0,gifout=0

pro elf_plot_orbit_conjunctions,tstart,gifout=gifout,file=file, elf_too=elf_too, tstep=tstep, $
  rbsp_too=rbsp_too, mms_too=mms_too, erg_too=erg_too, move=move,insert=insert, model=model, $
  trange=trange, goes_too=goes_too

  ; some setup
  ;@thg_asi_setup.init
  thm_init,/no_color_setup

  if undefined(gifout) then gifout=1
  if undefined(tstep) then tstep=1
  if undefined(elf_too) then elf_too=1
  if undefined(mms_too) then mms_too=1
  if undefined(erg_too) then erg_too=1
  if undefined(goes_too) then goes_too=1
  if undefined(move) then move=1

  re=6378.

  ; Set the time
  if undefined(trange) then begin
    if undefined(tstart) then begin
      dprint, 'The user must specify either a start date or a time range'
      dprint, 'elf_plot_orbit_conjunctions, "2022-01-01" or'
      dprint, 'elf_plot_orbit_conjunctions, trange=["2022-01-01/00:05","2022-01-01/00:10"]'
      return 
    endif
    timespan,tstart,1,/day
    tend=time_string(time_double(tstart)+86400.0d0)
  endif else begin
    tstart=time_double(trange[0])
    tend=time_double(trange[1])
    dur=tend-tstart
    timespan, tstart, dur, /sec  
  endelse
  If (keyword_set(rbsp_too)) AND  (~keyword_set(mms_too)) Then lim = 16 Else lim = 21;pull in limits for +RBSP plots
  earth=findgen(361)

  ; set up plot window for footprint
  !p.multi=0
  ;del_data,'*'

  ; average solar wind conditions
  dst=-10.
  dynp=2.
  bswx=2.
  bswy=-2.
  bswz=-1.
  swv=400.  ; default
  bp = sqrt(bswy^2 + bswz^2)/40.
  hb = (bp^2)/(1.+bp)
  bs = abs(bswz<0)
  th = atan(bswy,bswz)
  g1 = swv*hb*sin(th/2.)^3
  g2 = 0.005 * swv*bs
  if keyword_set(model) then tsyg_mod=model else tsyg_mod='t96'

  ; Get Magnetopause and Bow shock location
  mpause_2,xmp,ymp
  bshock_2,xbs,ybs

  ;**************************************
  ;
  ;  RETRIEVE ORBITS FOR ALL MISSIONS
  ;  ELFIN, THEMIS, ERG, and MMS
  ;
  ;**************************************

  ;---------------------------
  ; Get THEMIS state data
  ;---------------------------
  thm_probes=['a','d','e']
  for sc=0,2 do begin
    thm_load_state,probe=thm_probes[sc]
    get_data,'th'+thm_probes[sc]+'_state_pos',data=dat  ; position in GEI
    cotrans,'th'+thm_probes[sc]+'_state_pos','th'+thm_probes[sc]+'_state_pos_gse',/GEI2GSE
    cotrans,'th'+thm_probes[sc]+'_state_pos_gse','th'+thm_probes[sc]+'_state_pos_gsm',/GSE2GSM
    get_data, 'th'+thm_probes[sc]+'_state_pos_gsm', data=datgsm, dlimits=dlgsm, limits=lgsm
    ; calculate lat (needed to determine N/S hemisphere)
    cart2latlong, datgsm.y[*,0], datgsm.y[*,1], datgsm.y[*,2], thm_r, thm_lat, thm_lon
    nidx=where(thm_lat GE 0, thm_ncnt)
    sidx=where(thm_lat LT 0, thm_scnt)
    datgsm_foot=datgsm    ; use thx_pos_foot for inserting north and south traces
    ; TRACE TO EQUATOR
    if thm_ncnt GT 2 then begin
      npos=make_array(thm_ncnt, 3, /double)
      ntime=datgsm.x[nidx]
      npos[*,0]=datgsm.y[nidx,0]
      npos[*,1]=datgsm.y[nidx,1]
      npos[*,2]=datgsm.y[nidx,2]
      store_data, 'th'+thm_probes[sc]+'_state_pos_gsm_north', data={x:ntime, y:npos}, dlimits=dlgsm, limits=lgsm
      tsyg_param_count=thm_ncnt ; prepare fewer replicated parameters below
      tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
        [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
      ttrace2equator,'th'+thm_probes[sc]+'_state_pos_gsm_north',new_name='th'+thm_probes[sc]+'_state_pos_gsm_north_foot', $
        external_model='t96',internal_model='igrf',/km, in_coord='gsm',out_coord='gsm',par=tsyg_parameter,R0= 1.0156;,rlim=100.*Re
      get_data,'th'+thm_probes[sc]+'_state_pos_gsm_north_foot',data=d
      datgsm_foot.y[nidx,0]=d.y[*,0]
      datgsm_foot.y[nidx,1]=d.y[*,1]
      datgsm_foot.y[nidx,2]=d.y[*,2]
    endif
    if thm_scnt GT 2 then begin
      spos=make_array(thm_scnt, 3, /double)
      stime=datgsm.x[sidx]
      spos[*,0]=datgsm.y[sidx,0]
      spos[*,1]=datgsm.y[sidx,1]
      spos[*,2]=datgsm.y[sidx,2]
      store_data, 'th'+thm_probes[sc]+'_state_pos_gsm_south', data={x:stime, y:spos}, dlimits=dlgsm, limits=lgsm
      tsyg_param_count=thm_scnt ; prepare fewer replicated parameters below
      tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
        [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
      ttrace2equator,'th'+thm_probes[sc]+'_state_pos_gsm_south',new_name='th'+thm_probes[sc]+'_state_pos_gsm_south_foot', $
        external_model='t96',internal_model='igrf',/km, in_coord='gsm',out_coord='gsm',par=tsyg_parameter, /south;,R0= 1.0156,rlim=100.*Re
      get_data,'th'+thm_probes[sc]+'_state_pos_gsm_south_foot',data=d
      datgsm_foot.y[sidx,0]=d.y[*,0]
      datgsm_foot.y[sidx,1]=d.y[*,1]
      datgsm_foot.y[sidx,2]=d.y[*,2]
    endif
    store_data, 'th'+thm_probes[sc]+'_state_pos_gsm_foot',data={x: datgsm_foot.x, y: datgsm_foot.y}, $
      dlimits=dlgsm, limits=lgsm
  endfor                          ; sc loop
  get_data,'tha_state_pos_gsm',data=tha_state_pos_gsm
  get_data,'thd_state_pos_gsm',data=thd_state_pos_gsm
  get_data,'the_state_pos_gsm',data=the_state_pos_gsm
  get_data,'tha_state_pos_gsm_foot', data=tha_state_pos_gsm_foot
  get_data,'thd_state_pos_gsm_foot', data=thd_state_pos_gsm_foot
  get_data,'the_state_pos_gsm_foot', data=the_state_pos_gsm_foot

  ;---------------------------
  ; Get MMS state data
  ; --------------------------
  If(keyword_set(mms_too)) Then Begin
    mms1 = 0
    mms2 = 0
    mms3 = 0
    mms4 = 0
    mms_init, /no_color_setup
    probes=['1','2','3','4']
    tr=[tstart,tend]
    for sc=0,0 do begin
      print, 'Loading data for MMS'+probes[sc]
      batch_procedure_error_handler, 'mms_load_state', probe=probes[sc], datatypes='pos', trange=tr, $
        login_info=!mms.local_data_dir+'mms_auth_info.sav'
      get_data,'mms'+probes[sc]+'_defeph_pos',data=dat ; default position is GEI
      ; check that definitive data was successfully retrieved, if not then check for predicted data
      if size(dat, /type) Ne 8 then begin
        batch_procedure_error_handler, 'mms_load_state', probe=probes[sc], datatypes='pos', trange=tr, level='pred',$
          login_info=!mms.local_data_dir+'mms_auth_info.sav'
        get_data,'mms'+probes[sc]+'_predeph_pos',data=dat ; default position is GEI
      endif
      ;interpolate to 1 minute resolution (this is to reduce the time required to trace to equator
      if(size(dat, /type) Eq 8) then begin
        temp_array = time_double(tstart)+60.0*dindgen(1440)
        dtemp = data_cut(dat, temp_array)
        store_data, 'mms'+probes[sc]+'_state_pos_gei', data = {x:temp_array, y:dtemp}
        cotrans,'mms'+probes[sc]+'_state_pos_gei','mms'+probes[sc]+'_state_pos_gse',/GEI2GSE
        cotrans,'mms'+probes[sc]+'_state_pos_gse','mms'+probes[sc]+'_state_pos_gsm',/GSE2GSM
      endif else begin
        mms_too=0
      endelse
      get_data, 'mms'+probes[sc]+'_state_pos_gsm', data=datgsm, dlimits=dlgsm, limits=lgsm
      ; calculate lat (needed to determine N/S hemisphere)
      cart2latlong, datgsm.y[*,0], datgsm.y[*,1], datgsm.y[*,2], mms_r, mms_lat, mms_lon
      nidx=where(mms_lat GE 0, mms_ncnt)
      sidx=where(mms_lat LT 0, mms_scnt)
      datgsm_foot=datgsm    ; use thx_pos_foot for inserting north and south traces
      ; TRACE TO EQUATOR
      if mms_ncnt GT 2 then begin
        npos=make_array(mms_ncnt, 3, /double)
        ntime=datgsm.x[nidx]
        npos[*,0]=datgsm.y[nidx,0]
        npos[*,1]=datgsm.y[nidx,1]
        npos[*,2]=datgsm.y[nidx,2]
        store_data, 'mms'+probes[sc]+'_state_pos_gsm_north', data={x:ntime, y:npos}, dlimits=dlgsm, limits=lgsm
        tsyg_param_count=mms_ncnt ; prepare fewer replicated parameters below
        tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
          [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
        ttrace2equator,'mms'+probes[sc]+'_state_pos_gsm_north',new_name='mms'+probes[sc]+'_state_pos_gsm_north_foot', $
          external_model='t96',internal_model='igrf',/km, in_coord='gsm',out_coord='gsm',par=tsyg_parameter;,R0= 1.0156,rlim=100.*Re
        get_data,'mms'+probes[sc]+'_state_pos_gsm_north_foot',data=d
        datgsm_foot.y[nidx,0]=d.y[*,0]
        datgsm_foot.y[nidx,1]=d.y[*,1]
        datgsm_foot.y[nidx,2]=d.y[*,2]
      endif
      if mms_scnt GT 2 then begin
        spos=make_array(mms_scnt, 3, /double)
        stime=datgsm.x[sidx]
        spos[*,0]=datgsm.y[sidx,0]
        spos[*,1]=datgsm.y[sidx,1]
        spos[*,2]=datgsm.y[sidx,2]
        store_data, 'mms'+probes[sc]+'_state_pos_gsm_south', data={x:stime, y:spos}, dlimits=dlgsm, limits=lgsm
        tsyg_param_count=mms_scnt ; prepare fewer replicated parameters below
        tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
          [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]

        ttrace2equator,'mms'+probes[sc]+'_state_pos_gsm_south',new_name='mms'+probes[sc]+'_state_pos_gsm_south_foot', $
          external_model='t96',internal_model='igrf',/km, in_coord='gsm',out_coord='gsm',par=tsyg_parameter, /south;,R0= 1.0156,rlim=100.*Re
        get_data,'mms'+probes[sc]+'_state_pos_gsm_south_foot',data=d
        datgsm_foot.y[sidx,0]=d.y[*,0]
        datgsm_foot.y[sidx,1]=d.y[*,1]
        datgsm_foot.y[sidx,2]=d.y[*,2]
      endif
      store_data, 'mms'+probes[sc]+'_state_pos_gsm_foot',data={x: datgsm_foot.x, y: datgsm_foot.y}, $
        dlimits=dlgsm, limits=lgsm
    endfor
    get_data, 'mms1_state_pos_gsm',data=mms1_state_pos_gsm
    get_data, 'mms1_state_pos_gsm_foot',data=mms1_state_pos_gsm_foot
    if size(mms1_state_pos_gsm, /type) Eq 8 then mms1 = 1
  endif

  ;---------------------------
  ; Get ERG state data
  ; --------------------------
  If(keyword_set(erg_too)) Then Begin
    tr=[tstart,tend]
    erg_init, local_data_dir=spd_default_local_data_dir()+'erg/'
    ;erg_init
    print, 'Loading data for ERG'
    batch_procedure_error_handler, 'erg_load_orb', trange=tr
    get_data,'erg_orb_l2_pos_gsm',data=dat, dlimits=dl, limits=l
    ; check that data was found, if not then try predicted data
    if size(dat, /type) Ne 8 then begin
      print, 'no definitive data, trying predicted'
      batch_procedure_error_handler, 'erg_load_orb_predict', trange=tr
      get_data,'erg_orb_pre_l2_pos_gsm', data=dat, dlimits=dlgsm, limits=lgsm
    endif
    if size(dat, /type) Ne 8 then begin
      erg_too = 0
      print, 'no data downloaded'
    endif else begin
      erg_too = 1
      erg_orb_l2_pos_time = time_double(tstart)+60.0*dindgen(1440)
      erg_orb_l2_pos_gsm = data_cut(dat, erg_orb_l2_pos_time)
      for m=0,2 do erg_orb_l2_pos_gsm[*,m]=erg_orb_l2_pos_gsm[*,m]*6375.
      store_data, 'erg_orb_l2_pos_gsm', data={x:erg_orb_l2_pos_time, y:erg_orb_l2_pos_gsm}, dlimits=dlgsm, limits=lgsm
    endelse
    ; calculate lat (needed to determine N/S hemisphere)
    get_data, 'erg_orb_l2_pos_gsm', data=erg_pos, dlimits=dlgsm, limits=lgsm
    cart2latlong, erg_pos.y[*,0], erg_pos.y[*,1], erg_pos.y[*,2], erg_r, erg_lat, erg_lon
    nidx=where(erg_lat GE 0, erg_ncnt)
    sidx=where(erg_lat LT 0, erg_scnt)
    erg_pos_foot=erg_pos
    ;trace to equator
    if erg_ncnt GT 2 then begin
      npos=make_array(erg_ncnt, 3, /double)
      npos[*,0]=erg_pos.y[nidx,0]
      npos[*,1]=erg_pos.y[nidx,1]
      npos[*,2]=erg_pos.y[nidx,2]
      store_data, 'erg_orb_l2_pos_gsm_north', data={x:erg_pos.x[nidx], y:npos}, dlimits=dlgsm, limits=lgsm
      tsyg_param_count=erg_ncnt ; prepare fewer replicated parameters below
      tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
        [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
      ttrace2equator,'erg_orb_l2_pos_gsm_north',new_name='erg_orb_l2_pos_gsm_north_foot',external_model='T96',internal_model='igrf',/km, $
        in_coord='gsm',out_coord='gsm',par=tsyg_parameter;,R0= 1.0156,rlim=100.*Re
      get_data, 'erg_orb_l2_pos_gsm_north_foot', data=d
      erg_pos_foot.y[nidx,0]=d.y[*,0]
      erg_pos_foot.y[nidx,1]=d.y[*,1]
      erg_pos_foot.y[nidx,2]=d.y[*,2]
    endif
    if erg_scnt GT 2 then begin
      spos=make_array(erg_scnt, 3, /double)
      spos[*,0]=erg_pos.y[sidx,0]
      spos[*,1]=erg_pos.y[sidx,1]
      spos[*,2]=erg_pos.y[sidx,2]
      store_data, 'erg_orb_l2_pos_gsm_south', data={x:erg_pos.x[sidx], y:spos}, dlimits=dlgsm, limits=lgsm
      tsyg_param_count=erg_scnt ; prepare fewer replicated parameters below
      tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
        [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
        [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
      ttrace2equator,'erg_orb_l2_pos_gsm_south',new_name='erg_orb_l2_pos_gsm_south_foot',external_model='T96',internal_model='igrf',/km, $
        in_coord='gsm',out_coord='gsm',par=tsyg_parameter,/south;,R0=1.;, 1.0156,rlim=100.*Re
      get_data, 'erg_orb_l2_pos_gsm_south_foot', data=d
      erg_pos_foot.y[sidx,0]=d.y[*,0]
      erg_pos_foot.y[sidx,1]=d.y[*,1]
      erg_pos_foot.y[sidx,2]=d.y[*,2]
    endif
    store_data, 'erg_orb_l2_pos_gsm_foot', data = {x:erg_pos_foot.x, y:erg_pos_foot.y}
    get_data, 'erg_orb_l2_pos_gsm_foot', data=erg_orb_l2_pos_gsm_foot

  endif

  ;---------------------------
  ; Get GOES 15 and 16 state data
  ; --------------------------
;  If(keyword_set(goes_too)) Then Begin
;    tr=[tstart,tend]
;    goes=['16','17']
;    goes_init, local_data_dir=spd_default_local_data_dir()+'goes/'
;    for sc=0,1 do begin
;      print, 'Loading data for GOES '+goes[sc]
;      goes_trange=time_string(time_double(trange))
;      dat=goes_load_pos(trange=goes_trange, probe=goes[sc], coord_sys='gsm')
;      if size(dat, /type) Ne 8 then begin
;        goes_too = 0
;        print, 'no data downloaded'
;      endif else begin
;        goes_too = 1
;        store_data, 'goes_pos_gsm', data={x:dat.time, y:dat.pos_values}
;      endelse
;      ; calculate lat (needed to determine N/S hemisphere)
;      get_data, 'goes_pos_gsm', data=goes_pos;, dlimits=dlgsm, limits=lgsm
;      cart2latlong, goes_pos.y[*,0], goes_pos.y[*,1], goes_pos.y[*,2], goes_r, goes_lat, goes_lon
;      nidx=where(goes_lat GE 0, goes_ncnt)
;      sidx=where(goes_lat LT 0, goes_scnt)
;      goes_pos_foot=goes_pos
;      ;trace to equator
;      if goes_ncnt GT 0 then begin
;        npos=make_array(goes_ncnt, 3, /double)
;        npos[*,0]=goes_pos.y[nidx,0]
;        npos[*,1]=goes_pos.y[nidx,1]
;        npos[*,2]=goes_pos.y[nidx,2]
;        store_data, 'goes_orb_l2_pos_gsm_north', data={x:goes_pos.x[nidx], y:npos}, dlimits=dlgsm, limits=lgsm
;        tsyg_param_count=goes_ncnt ; prepare fewer replicated parameters below
;        tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
;          [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
;          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
;          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
;        ttrace2equator,'goes_orb_l2_pos_gsm_north',new_name='goes_orb_l2_pos_gsm_north_foot',external_model='T96',internal_model='igrf',/km, $
;          in_coord='gsm',out_coord='gsm',par=tsyg_parameter;,R0= 1.0156,rlim=100.*Re
;        get_data, 'goes_orb_l2_pos_gsm_north_foot', data=d
;        goes_pos_foot.y[nidx,0]=d.y[*,0]
;        goes_pos_foot.y[nidx,1]=d.y[*,1]
;        goes_pos_foot.y[nidx,2]=d.y[*,2]
;      endif
;      if goes_scnt GT 0 then begin
;        spos=make_array(goes_scnt, 3, /double)
;        spos[*,0]=goes_pos.y[sidx,0]
;        spos[*,1]=goes_pos.y[sidx,1]
;        spos[*,2]=goes_pos.y[sidx,2]
;        store_data, 'goes_orb_l2_pos_gsm_south', data={x:goes_pos.x[sidx], y:spos}, dlimits=dlgsm, limits=lgsm
;        tsyg_param_count=goes_scnt ; prepare fewer replicated parameters below
;        tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
;          [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
;          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
;          [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
;        ttrace2equator,'goes_orb_l2_pos_gsm_south',new_name='goes_orb_l2_pos_gsm_south_foot',external_model='T96',internal_model='igrf',/km, $
;          in_coord='gsm',out_coord='gsm',par=tsyg_parameter,/south;,R0=1.;, 1.0156,rlim=100.*Re
;        get_data, 'goes_orb_l2_pos_gsm_south_foot', data=d
;        goes_pos_foot.y[sidx,0]=d.y[*,0]
;        goes_pos_foot.y[sidx,1]=d.y[*,1]
;        goes_pos_foot.y[sidx,2]=d.y[*,2]
;      endif
;      store_data, 'goes'+goes[sc]+'_orb_l2_pos_gsm_foot', data = {x:goes_pos_foot.x, y:goes_pos_foot.y}
      ;this_goes_dat_name='goes'+goes[sc]+'_orb_l2_pos_gsm_foot
;      if sc EQ 0 then get_data, 'goes'+goes[sc]+'_orb_l2_pos_gsm_foot', data=goes15_orb_l2_pos_gsm_foot
;      if sc EQ 1 then get_data, 'goes'+goes[sc]+'_orb_l2_pos_gsm_foot', data=goes16_orb_l2_pos_gsm_foot      
;    endfor
;  endif

  ;-----------------------------------
  ; Setup for orbits - 12 hr plots
  ;-----------------------------------
  if undefined(trange) then begin
    hr_st = 12*indgen(2)
    dhr = 12+intarr(2)
    hr_en = hr_st+dhr
    ; Stings for labels, filenames
    hr_ststr = string(hr_st, format='(i2.2)')
    hr_enstr = string(hr_en, format='(i2.2)')
    plot_lbl = '/'+hr_ststr+'-'+hr_enstr
    file_lbl = '_'+hr_ststr+hr_enstr
    ;the data has 1 minute time resolution  ;(except for elfin)
    min_st = hr_st*60
    min_en = hr_en*60-1
    nplots = n_elements(dhr)
  endif else begin
    tstring=time_string(timerange())
    hr_st=[strmid(tstring[0],11,2)]
    hr_en=[strmid(tstring[1],11,2)]
    hr_ststr=[hr_st]
    hr_enstr=[hr_en]
    plot_lbl = '/'+hr_ststr+'-'+hr_enstr
    file_lbl = '_'+hr_ststr+hr_enstr
    min_st = hr_st*60
    min_en = hr_en*60-1
    nplots = 1
  endelse
;  nplots = n_elements(dhr)

  ;---------------------------------------
  ; set up for plotting the earth
  ;---------------------------------------
  pts = (2*!pi/99.0)*findgen(100)
  earth=findgen(361)
  ex=[0]
  ey=[0]
  for i=0.,1.,0.025 do ex=[ex,i*cos(earth*!dtor)]
  for i=0.,1.,0.025 do ey=[ey,i*sin(earth*!dtor)]
  night_idx = where(ex LT 0.)

  ; restrict the plot range to be within abs(15re)
  xrange=[15,-15]
  yrange=[15,-15]

  ;*******************************************
  ;
  ;  MAIN LOOP FOR 12 HOUR CONJUNCTION PLOTS
  ;
  ;*******************************************

  for j = 0, nplots-1 do begin
    set_plot,'z'
    loadct,0
    tvlct,r,g,b,/get
    ; colors and symbols, closest numbers for loadct,39
    ;P1 red        [255,0,0],   250 IDL symbol 5
    ;P2 green      [0,255,0],   146 IDL symbol 2
    ;P3 light blue [0,255,255], 102 IDL symbol 1
    ;P4 dark blue  [0,0,255],    57 IDL symbol 4
    ;P5 purple     [87,0,145],   30 IDL symbol 6
    ; color=254 will be purple for P5
    r[254]=255 & g[254]=0   & b[254]=255
    ; color=253 will be dark blue for P4
    r[253]=0   & g[253]=0   & b[253]=255
    ; color=252 will be light blue for P3
    r[252]=0   & g[252]=255 & b[252]=255
    ; color=251 will be green for P2
    r[251]=0   & g[251]=255 & b[251]=0
    ; color=250 will be red for P1
    r[250]=255 & g[250]=0   & b[250]=0

    ;Usurp color values 248 and 249 for rbsp a and b, orange and black,
    ;a will use 'X' (psym = 7) , b will use '*' (psym = 2) for positions...
    r[249]=255   & g[249]=127   & b[249]=0
    r[248]=0   & g[248]=0   & b[248]=0

    ;Usurp color values 244 and 247 for MMS 1-4
    ;1=yellow, 2=Coral, 3=bluegreen, 4=purple
    ;will use symbols 1='x' (psym=7), 2='*' (psym=2), 3='triangle'
    ;(psym=5), 4='square' (psym=6)
    If(keyword_set(mms_too)) Then Begin
      r[244]=255   & g[244]=215  & b[244]=0
      r[245]=205   & g[245]=92   & b[245]=92
      r[246]=70    & g[246]=130  & b[246]=180
      r[247]=138   & g[247]=43   & b[247]=226
    Endif

    ;Usurp color values 243
    ;erg=darkgreen
    ;will use symbol 'diamond' (psym=4)
    If(keyword_set(erg_too)) Then Begin
      r[243]=46   & g[243]=139   & b[243]=87
    Endif

    If(keyword_set(goes_too)) Then Begin
      ; GOES 15 - gold
      ; GOES 16 - light green
      ;    r[240]=135   & g[240]=206   & b[240]=235
      ;    r[239]=90   & g[239]=162   & b[239]=255
      r[240]=235   & g[240]=180   & b[240]=52
      r[239]=146   & g[239]=235   & b[239]=52
    Endif
    
    ; elf A - blue
    ; elf B - orange (red)
    ;    r[242]=135   & g[242]=206   & b[242]=235
    ;    r[241]=90   & g[241]=162   & b[241]=255
    r[242]=65  & g[242]=140   & b[242]=255
    r[241]=255   & g[241]=0   & b[241]=0

    ; more plot set-up
    tvlct,r,g,b
    set_plot,'z'
    symbols=[5,2,1,4,6]

    !p.multi=[0,1,1]
    if keyword_set(gifout) then begin
      set_plot,'z'
      device,set_resolution=[800,800]
      charsize=1
      noview=1
    endif else begin
      set_plot,'x'
      window,0,xsize=800,ysize=800
      charsize=1
      !P.Color = '000000'xL
      !P.Background = 'FFFFFF'xL
    endelse

    ;----------------------------------------------
    ; Plot the frame and range for the orbit plots
    ;----------------------------------------------
    plot,findgen(10),xrange=xrange,yrange=yrange,/xstyle,/ystyle,/nodata, $
      title='Multi-mission orbits: T96 magnetic equator projections, '+strmid(tstart[0],0,10)+plot_lbl[j],$
      xtitle='Xeq-GSM',ytitle='Yeq-GSM',charsize=charsize,/isotropic

    ; plot earth
    oplot, ex[night_idx], ey[night_idx]
    oplot, 1.0*cos(pts), 1.0*sin(pts)
    oplot,[-100,100],[0,0],line=1
    oplot,[0,0],[-100,100],line=1

    ; plot the bow shock line
    oplot,xbs,ybs,line=1
    ; plot the magnetopause line
    oplot,xmp,ymp,line=2

    time = make_array(301,/double)
    thisstart=tha_state_pos_gsm.x[min_st[j]]
    thisend=tha_state_pos_gsm.x[min_en[j]]

    ;----------------
    ; Plot THEMIS
    ;----------------
    ; retrieve the data for this 12 hour time period
    tha_time=tha_state_pos_gsm.x[min_st[j]:min_en[j]]
    tha_pos=tha_state_pos_gsm.y[min_st[j]:min_en[j],*]/6375.
    thd_time=thd_state_pos_gsm.x[min_st[j]:min_en[j]]
    thd_pos=thd_state_pos_gsm.y[min_st[j]:min_en[j],*]/6375.
    the_time=the_state_pos_gsm.x[min_st[j]:min_en[j]]
    the_pos=the_state_pos_gsm.y[min_st[j]:min_en[j],*]/6375.
    tha_foot=tha_state_pos_gsm_foot.y[min_st[j]:min_en[j],*]/6375.
    thd_foot=thd_state_pos_gsm_foot.y[min_st[j]:min_en[j],*]/6375.
    the_foot=the_state_pos_gsm_foot.y[min_st[j]:min_en[j],*]/6375.

    ; Use the position data to determine whether the spacecraft is within the magnetopause
    mpause_flag, tha_pos[*,0], tha_pos[*,1], tha_pos[*,2], xmp, ymp, mpauseflag=tha_mpauseflag
    mpause_flag, thd_pos[*,0], thd_pos[*,1], thd_pos[*,2], xmp, ymp, mpauseflag=thd_mpauseflag
    mpause_flag, the_pos[*,0], the_pos[*,1], the_pos[*,2], xmp, ymp, mpauseflag=the_mpauseflag
    ; find the indices for points in the magnetopause
    aidx=where(tha_mpauseflag GT 0, acnt)
    didx=where(thd_mpauseflag GT 0, dcnt)
    eidx=where(the_mpauseflag GT 0, ecnt)
    ; get the x and y components to be plotted
    tha_foot_t=tha_time[aidx]
    tha_foot_x=tha_foot[aidx,0]
    tha_foot_y=tha_foot[aidx,1]
    tha_foot_z=tha_foot[aidx,2]
    thd_foot_t=thd_time[didx]
    thd_foot_x=thd_foot[didx,0]
    thd_foot_y=thd_foot[didx,1]
    thd_foot_z=thd_foot[didx,2]
    the_foot_t=the_time[eidx]
    the_foot_x=the_foot[eidx,0]
    the_foot_y=the_foot[eidx,1]
    the_foot_z=the_foot[eidx,2]

    ;----------------
    ; PLOT THEMIS
    ;----------------
    if acnt GT 0 then begin
      xidx=where(abs(tha_foot_x) LE 15, xcnt)
      if xcnt GT 0 then begin
        tha_foot_t=tha_foot_t[xidx]
        tha_foot_x=tha_foot_x[xidx]
        tha_foot_y=tha_foot_y[xidx]
        tha_foot_z=tha_foot_z[xidx]
        yidx=where(abs(tha_foot_y) LE 15, ycnt)
        if ycnt GT 0 then begin
          tha_foot_t=tha_foot_t[yidx]
          tha_foot_x=tha_foot_x[yidx]
          tha_foot_y=tha_foot_y[yidx]
          tha_foot_z=tha_foot_z[yidx]
          npts=n_elements(tha_foot_x)
          oplot,tha_foot_x,tha_foot_y,color=254, psym=3 ;thick=1.5
          if tha_foot_t[0] EQ thisstart then plots,tha_foot_x[0],tha_foot_y[0],color=254,psym=5
          if tha_foot_t[npts-1] EQ thisend then plots,tha_foot_x[npts-1],tha_foot_y[npts-1],color=254,psym=2
        endif
      endif
    endif

    if dcnt GT 0 then begin
      xidx=where(abs(thd_foot_x) LE 15, xcnt)
      if xcnt GT 0 then begin
        thd_foot_t=thd_foot_t[xidx]
        thd_foot_x=thd_foot_x[xidx]
        thd_foot_y=thd_foot_y[xidx]
        thd_foot_z=thd_foot_z[xidx]
        yidx=where(abs(thd_foot_y) LE 15, ycnt)
        if ycnt GT 0 then begin
          thd_foot_t=thd_foot_t[yidx]
          thd_foot_x=thd_foot_x[yidx]
          thd_foot_y=thd_foot_y[yidx]
          thd_foot_z=thd_foot_z[yidx]
          npts=n_elements(thd_foot_x)
          oplot,thd_foot_x,thd_foot_y,color=252, psym=3 ;thick=1.5
          if thd_foot_t[0] EQ thisstart then plots,thd_foot_x[0],thd_foot_y[0],color=252,psym=5
          if thd_foot_t[npts-1] EQ thisend then plots,thd_foot_x[npts-1],thd_foot_y[npts-1],color=252,psym=2
        endif
      endif
    endif

    if ecnt GT 0 then begin
      xidx=where(abs(the_foot_x) LE 15, xcnt)
      if xcnt GT 0 then begin
        the_foot_t=the_foot_t[xidx]
        the_foot_x=the_foot_x[xidx]
        the_foot_y=the_foot_y[xidx]
        the_foot_z=the_foot_z[xidx]
        yidx=where(abs(the_foot_y) LE 15, ycnt)
        if ycnt GT 0 then begin
          the_foot_t=the_foot_t[yidx]
          the_foot_x=the_foot_x[yidx]
          the_foot_y=the_foot_y[yidx]
          the_foot_z=the_foot_z[yidx]
          npts=n_elements(the_foot_x)
          oplot,the_foot_x,the_foot_y,color=253, psym=3 ;thick=1.5
          if the_foot_t[0] EQ thisstart then plots,the_foot_x[0],the_foot_y[0],color=253,psym=5
          if the_foot_t[npts-1] EQ thisend then plots,the_foot_x[npts-1],the_foot_y[npts-1],color=253,psym=2
        endif
      endif
    endif

    ; ADD Tick Marks for THEMIS
    if keyword_set(tstep) then begin
      tstep=3600.    ; 1 hr
      this_time=tha_state_pos_gsm.x[min_st[j]:min_en[j]]
      res=this_time[1]-this_time[0]
      istep=tstep/res
      last = n_elements(this_time)
      steps=lindgen(last/istep+1)*istep
      tmp=max(steps,nmax)
      if tmp gt (last-1) then steps=steps[0:nmax-1]
      tsteps0=this_time[steps[0]]
      dummy=min(abs(this_time-tsteps0),istep0)
      isteps=steps+istep0
      isteps=isteps[1:n_elements(isteps)-1]    ; don't plot first tick mark
    endif
    ; PLOT tick marks at 1 hour intervals
    this_gsm_x=tha_state_pos_gsm_foot.y[min_st[j]:min_en[j],0]
    this_gsm_y=tha_state_pos_gsm_foot.y[min_st[j]:min_en[j],1]
    plots, this_gsm_x[isteps]/6375., this_gsm_y[isteps]/6375., psym=1, color=254
    this_gsm_x=thd_state_pos_gsm_foot.y[min_st[j]:min_en[j],0]
    this_gsm_y=thd_state_pos_gsm_foot.y[min_st[j]:min_en[j],1]
    plots, this_gsm_x[isteps]/6375., this_gsm_y[isteps]/6375., psym=1, color=252
    this_gsm_x=the_state_pos_gsm_foot.y[min_st[j]:min_en[j],0]
    this_gsm_y=the_state_pos_gsm_foot.y[min_st[j]:min_en[j],1]
    plots, this_gsm_x[isteps]/6375., this_gsm_y[isteps]/6375., psym=1, color=253

    ;-----------------
    ; PLOT MMS
    ;-----------------
    If (keyword_set(mms_too)) && n_elements(mms1_state_pos_gsm.x) GT 5 Then Begin
      ;-------
      ; MMS 1
      ;-------
      ; retrieve the data for this 12 hour time period
      mms1_time=mms1_state_pos_gsm.x[min_st[j]:min_en[j]]
      mms1_pos=mms1_state_pos_gsm.y[min_st[j]:min_en[j],*]/6375.
      mms1_foot=mms1_state_pos_gsm_foot.y[min_st[j]:min_en[j],*]/6375.
      ; Use the position data to determine whether the spacecraft is within the magnetopause
      mpause_flag, mms1_pos[*,0], mms1_pos[*,1], mms1_pos[*,2], xmp, ymp, mpauseflag=mms1_mpauseflag
      ; find the indices for points in the magnetopause
      m1idx=where(mms1_mpauseflag GT 0, m1cnt)
      ; NOTE: Temporarily not plotting MMS 1, 2, and 3 since all 4 probes are on top of each other

      if m1cnt GT 0 then begin
        mms1_foot_t=mms1_time[m1idx]
        mms1_foot_x=mms1_foot[m1idx,0]
        mms1_foot_y=mms1_foot[m1idx,1]
        xidx=where(abs(mms1_foot_x) LE 15, xcnt)
        if xcnt GT 0 then begin
          mms1_foot_t=mms1_foot_t[xidx]
          mms1_foot_x=mms1_foot_x[xidx]
          mms1_foot_y=mms1_foot_y[xidx]
          yidx=where(abs(mms1_foot_y) LE 15, ycnt)
          if ycnt GT 0 then begin
            mms1_foot_t=mms1_foot_t[yidx]
            mms1_foot_x=mms1_foot_x[yidx]
            mms1_foot_y=mms1_foot_y[yidx]
            npts=n_elements(mms1_foot_x)
            oplot,mms1_foot_x,mms1_foot_y, psym=3 ;thick=1.5
            if mms1_foot_t[0] EQ thisstart then plots,mms1_foot_x[0],mms1_foot_y[0], psym=5 ;color=244
            if mms1_foot_t[npts-1] EQ thisend then plots,mms1_foot_x[npts-1],mms1_foot_y[npts-1], psym=2 ;color=244
          endif
        endif
      endif
      ; Set up for ticks
      if keyword_set(tstep) then begin
        tstep=3600.    ; 1 hr
        this_time=mms1_state_pos_gsm.x[min_st[j]:min_en[j]]
        res=this_time[1]-this_time[0]
        istep=tstep/res
        last = n_elements(this_time)
        steps=lindgen(last/istep+1)*istep
        tmp=max(steps,nmax)
        if tmp gt (last-1) then steps=steps[0:nmax-1]
        tsteps0=this_time[steps[0]]
        dummy=min(abs(this_time-tsteps0),istep0)
        isteps=steps+istep0
        isteps=isteps[1:n_elements(isteps)-1]    ; don't plot first tick mark
      endif
      ; plot tick marks
      this_gsm_x=mms1_state_pos_gsm_foot.y[min_st[j]:min_en[j],0]
      this_gsm_y=mms1_state_pos_gsm_foot.y[min_st[j]:min_en[j],1]
      plots, this_gsm_x[isteps]/6375., this_gsm_y[isteps]/6375., psym=1;, color=244
    Endif

    ;----------------------
    ; PLOT ERG Orbits
    ;----------------------
    If(keyword_set(erg_too)) Then Begin
      erg_foot_x=erg_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],0]/6375.
      erg_foot_y=erg_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],1]/6375.
      erg_pts=n_elements(erg_foot_x)
      oplot, erg_foot_x, erg_foot_y ,color=243, thick=1.5
      plots, erg_foot_x[0], erg_foot_y[0],color=243,psym=5
      plots, erg_foot_x[erg_pts-1], erg_foot_y[erg_pts-1],color=243,psym=2
      ; Determine the indices for the tick marks
      if keyword_set(tstep) then begin
        tstep=3600.    ; 1 hr
        this_time=erg_orb_l2_pos_time[min_st[j]:min_en[j]]
        res=this_time[1]-this_time[0]
        istep=tstep/res
        last = n_elements(this_time)
        steps=lindgen(last/istep+1)*istep
        tmp=max(steps,nmax)
        if tmp gt (last-1) then steps=steps[0:nmax-1]
        tsteps0=this_time[steps[0]]
        dummy=min(abs(this_time-tsteps0),istep0)
        isteps=steps+istep0
        isteps=isteps[1:n_elements(isteps)-1]    ; don't plot first tick mark
      endif
      ; plot tick marks for projection
      this_gsm_x=erg_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],0]/6375.
      this_gsm_y=erg_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],1]/6375.
      plots, this_gsm_x[isteps], this_gsm_y[isteps], psym=1, color=243
    Endif

    ;----------------------
    ; PLOT GOES Orbits
    ;----------------------
;    If(keyword_set(goes_too)) Then Begin
;      for sc=0,0 do begin
;        
;        if sc EQ 0 then goes_orb_l2_pos_gsm_foot = goes15_orb_l2_pos_gsm_foot
;        if sc EQ 1 then goes_orb_l2_pos_gsm_foot = goes16_orb_l2_pos_gsm_foot
      ;***** NOTE: this section needs to be replaced with min_st and 
      ; min_end. This also means data loaded will need to be for full
      ; day and interpolated to 1 min resolution
;      goes_foot_x=goes_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],0]/6375.
;      goes_foot_y=goes_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],1]/6375.
;      goes_foot_x=goes_orb_l2_pos_gsm_foot.y[*,0]/6375.
;      goes_foot_y=goes_orb_l2_pos_gsm_foot.y[*,1]/6375.
;      goes_pts=n_elements(goes_foot_x)
;      oplot, goes_foot_x, goes_foot_y ,color=243, thick=1.5
;      plots, goes_foot_x[0], goes_foot_y[0],color=243,psym=5
;      plots, goes_foot_x[goes_pts-1], goes_foot_y[goes_pts-1],color=243,psym=2
      ; Determine the indices for the tick marks
;;      if keyword_set(tstep) then begin
;        tstep=3600.    ; 1 hr
;        this_time=goes_orb_l2_pos_time[min_st[j]:min_en[j]]
;        goes_time=goes_orb_l2_pos_gsm_foot.x
;;        goes_orb_l2_pos_gsm_foot.x[0]:goes_orb_l2_pos_gsm_foot.x[goes_pts-1]]
;        res=goes_time[1]-goes_time[0]
;        istep=tstep/res
;        last = n_elements(goes_time)
;        steps=lindgen(last/istep+1)*istep
;        tmp=max(steps,nmax)
;        if tmp gt (last-1) then steps=steps[0:nmax-1]
;        tsteps0=goes_time[steps[0]]
;        dummy=min(abs(goes_time-tsteps0),istep0)
;        isteps=steps+istep0
;        isteps=isteps[1:n_elements(isteps)-1]    ; don't plot first tick mark
;      endif
      ; plot tick marks for projection
;      ;***** NOTE: this section needs to be replaced with min_st and
      ; min_end. This also means data loaded will need to be for full
      ; day and interpolated to 1 min resolution
;      this_gsm_x=goes_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],0]/6375.
;      this_gsm_y=goes_orb_l2_pos_gsm_foot.y[min_st[j]:min_en[j],1]/6375.
;      this_gsm_x=goes_orb_l2_pos_gsm_foot.y[*,0]/6375.
;      this_gsm_y=goes_orb_l2_pos_gsm_foot.y[*,1]/6375.
;      plots, this_gsm_x[isteps], this_gsm_y[isteps], psym=1, color=243
;      endfor
;    Endif

    ;----------------------
    ; PLOT ELFIN Orbits
    ;----------------------

    ;--------------------------------------------------
    ; Get ELFIN state data and trace2equator
    ; -------------------------------------------------
    elf_probes=['b','a']
    elf_colors=[241,242]
    elfa = 0
    elfb = 0
    par_iter=[2.,-10.,-2.,-1.,0.,0.,0.,0.,0.,0.]
    for scl=0,1 do begin
      if scl eq 0 then sc=1 else sc=0
      sci_zones=get_elf_science_zone_start_end(trange=[thisstart,thisend], probe=elf_probes[sc])
      ;check that there is data
      if size(sci_zones, /type) EQ 8 && n_elements(sci_zones.starts) GT 0 then begin
        elx_sidx=where((sci_zones.starts GE thisstart AND sci_zones.starts LE thisend) OR $
          (sci_zones.ends GE thisstart AND sci_zones.starts LE thisend), szcnt)
        xstarts=sci_zones.starts[elx_sidx]
        xends=sci_zones.ends[elx_sidx]
        nzones=n_elements(xstarts)

        ; SCIENCE ZONE LOOP
        for sz=0, nzones-1 do begin
          ;----------------
          ; GET ELFIN DATA
          ;----------------
          incre=10. ; just want to speed up tracing
          sctime=dindgen(long(xends[sz]-xstarts[sz])/incre+1,start=xstarts[sz],increment=incre) ;
          thistr=[xstarts[sz], xends[sz]]
          elf_load_state, probe=elf_probes[sc], trange=thistr
          get_data, 'el'+elf_probes[sc]+'_pos_gei',data=dat, dlimits=dl, limits=l    ; position in GEI
          cotrans,'el'+elf_probes[sc]+'_pos_gei','el'+elf_probes[sc]+'_pos_gse',/GEI2GSE
          cotrans,'el'+elf_probes[sc]+'_pos_gse','el'+elf_probes[sc]+'_pos_gsm',/GSE2GSM

          tinterpol_mxn,'el'+elf_probes[sc]+'_pos_gsm',sctime ;if necessary change time resolution to speed up tracing
          get_data,'el'+elf_probes[sc]+'_pos_gsm_interp',data=elx_pos, dlimits=dlgsm, limits=lgsm
          ; determine field sign and seperate into north and south tracing
          tt89,'el'+elf_probes[sc]+'_pos_gsm_interp', kp=2,newname='el'+elf_probes[sc]+'_bt89_gsm',/igrf_only
          tdotp,'el'+elf_probes[sc]+'_bt89_gsm','el'+elf_probes[sc]+'_pos_gsm_interp',newname='el'+elf_probes[sc]+'_Br_sign'
          get_data,'el'+elf_probes[sc]+'_Br_sign',data=Br_sign_tmp
          nidx=where(Br_sign_tmp.y lt 0., elx_ncnt)
          sidx=where(Br_sign_tmp.y gt 0., elx_scnt)

          elx_pos_foot=elx_pos
          elx_pos_foot.y[*,*]=!VALUES.F_NAN
          ;------------------------------------------------
          ;              north hemisphere
          ;------------------------------------------------
          if elx_ncnt GT 0 then begin
            npos=make_array(elx_ncnt, 3, /double)
            ntime=elx_pos.x[nidx]
            npos[*,0]=elx_pos.y[nidx,0]
            npos[*,1]=elx_pos.y[nidx,1]
            npos[*,2]=elx_pos.y[nidx,2]
            store_data, 'el'+elf_probes[sc]+'_pos_gsm_north', data={x:ntime, y:npos}, dlimits=dlgsm, limits=lgsm
            tsyg_param_count=elx_ncnt ; prepare fewer replicated parameters below
            tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
              [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
              [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
              [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]

            ; trace to conjugate ionosphere first
            ttrace2iono,'el'+elf_probes[sc]+'_pos_gsm_north',newname='el'+elf_probes[sc]+'_pos_gsm_north_ifoot', $
              external_model='t96',internal_model='igrf',/km, in_coord='gsm', out_coord='gsm',par=tsyg_parameter, $
              R0= 1.0156*Re, rlim=400.*Re,/south,trace_var_name='el'+elf_probes[sc]+'_pos_gsm_north_trace'

            ; choose only close field line
            get_data,'el'+elf_probes[sc]+'_pos_gsm_north_ifoot',data=north_ifoot
            niclsB=where(sqrt(north_ifoot.y[*,0]^2+north_ifoot.y[*,1]^2+north_ifoot.y[*,2]^2) lt 7000.,njclsB)
            get_data,'el'+elf_probes[sc]+'_pos_gsm_north_trace',data=north_trace
            north_trace_size=size(north_trace.y,/dim)

            ; loop of each closed field line
            faketime=make_array(north_trace_size[1],value=north_trace.x[0])
            efoot_north=make_array(n_elements(north_trace.x),3,value=!VALUES.F_NAN)
            efoot_north_dis=make_array(n_elements(north_trace.x),value=!VALUES.F_NAN)
            efoot_north_id=make_array(n_elements(north_trace.x),value=!VALUES.F_NAN)

            for ii=0,njclsB-1 do begin
              itime=niclsB[ii]
              store_data,'el'+elf_probes[sc]+'_pos_gsm_north_trace1',data={x:faketime,y:reform(north_trace.y[itime,*,*],north_trace_size[1],3)}, dlimits=dlgsm, limits=lgsm
              tt89,'el'+elf_probes[sc]+'_pos_gsm_north_trace1',newname='el'+elf_probes[sc]+'_bt89_gsm_north_trace1',kp=2
              cotrans,'el'+elf_probes[sc]+'_bt89_gsm_north_trace1','el'+elf_probes[sc]+'_bt89_sm_north_trace1',/gsm2sm
              cotrans,'el'+elf_probes[sc]+'_pos_gsm_north_trace1','el'+elf_probes[sc]+'_pos_sm_north_trace1',/gsm2sm
              get_data,'el'+elf_probes[sc]+'_bt89_sm_north_trace1',data=bt89_north_trace1
              get_data,'el'+elf_probes[sc]+'_pos_sm_north_trace1',data=north_trace1_sm
              ; when sm_B*sm_pos changing sign in xy plane
              dotprod=bt89_north_trace1.y[*,0]*north_trace1_sm.y[*,0]+bt89_north_trace1.y[*,1]*north_trace1_sm.y[*,1]
              index=indgen(n_elements(dotprod)-1)
              iBrsign=where(dotprod[index]*dotprod[index+1] lt 0,jBrsign)
              get_data,'el'+elf_probes[sc]+'_pos_gsm_north_trace1',data=north_trace1_gsm
              if jBrsign ne 1 then begin
                ;stop
              endif else begin
                ;efoot_t=north_trace1_gsm.x[iBRsign]
                efoot_x=(dotprod[iBrsign+1]*north_trace1_gsm.y[iBrsign,0]-dotprod[iBrsign]*north_trace1_gsm.y[iBrsign+1,0])/(dotprod[iBrsign+1]-dotprod[iBrsign])
                efoot_y=(dotprod[iBrsign+1]*north_trace1_gsm.y[iBrsign,1]-dotprod[iBrsign]*north_trace1_gsm.y[iBrsign+1,1])/(dotprod[iBrsign+1]-dotprod[iBrsign])
                efoot_z=(dotprod[iBrsign+1]*north_trace1_gsm.y[iBrsign,2]-dotprod[iBrsign]*north_trace1_gsm.y[iBrsign+1,2])/(dotprod[iBrsign+1]-dotprod[iBrsign])
                ; determine when the field line is inside magnetopause
                mpause_t96,dynp,xmgnp=xmgnp,ymgnp=ymgnp,xgsm=north_trace1_gsm.y[*,0]/re,ygsm=north_trace1_gsm.y[*,1]/re,zgsm=north_trace1_gsm.y[*,2]/re,id=id,distan=distan
                ;oplot,xmgnp,ymgnp,linestyle=2, thick=1.2 ; plot new magnetopause boundary
                mindis=min(distan,imindis) ; min distance of trace field line to mp
                iid=where(id lt 0,cid) ; whether field line is inside or outside mp
                if cid eq 0 and mindis gt 0.1 then begin ; if field line has points outside mp or min distance is too small, discard this field line
                  efoot_north[itime,0]=efoot_x
                  efoot_north[itime,1]=efoot_y
                  efoot_north[itime,2]=efoot_z
                endif
              endelse
            endfor
            iefoot_north=where(finite(efoot_north[*,0]) and abs(efoot_north[*,0]/re) lt 14 and abs(efoot_north[*,1]/re) lt 14)
            plots,efoot_north[iefoot_north,0]/re, efoot_north[iefoot_north,1]/re,color=elf_colors[sc] ; eqautor footprint
            plots,efoot_north[iefoot_north[0],0]/re, efoot_north[iefoot_north[0],1]/re,color=elf_colors[sc],psym=5 ; start point
            plots,efoot_north[iefoot_north[-1],0]/re, efoot_north[iefoot_north[-1],1]/re,color=elf_colors[sc],psym=2  ; end point
            if (efoot_north[iefoot_north[0],0]/re)^2+(efoot_north[iefoot_north[0],1]/re)^2 gt $  ; if elf goes from far to close to earth
              (efoot_north[iefoot_north[-1],0]/re)^2+(efoot_north[iefoot_north[-1],1]/re)^2 then begin
              midpt=0
              efoot_time=strmid(time_string(north_trace.x[iefoot_north[midpt]]),11,2)+strmid(time_string(north_trace.x[iefoot_north[midpt]]),14,2)
              dxy0=atan(efoot_north[iefoot_north[midpt],1]-efoot_north[iefoot_north[midpt]+1,1],efoot_north[iefoot_north[midpt],0]-efoot_north[iefoot_north[midpt]+1,0])
              xyouts, efoot_north[iefoot_north[midpt],0]/re+0.9*cos(dxy0),  efoot_north[iefoot_north[midpt],1]/re+0.9*sin(dxy0), $
                efoot_time, charsize=0.8, color=elf_colors[sc], ALIGNMENT=0.5, ORIENTATION=dxy0*180/!dpi+270  
            endif else begin ; if elf goes from close to earth to far
              midpt=-1
              dxy0=atan(efoot_north[iefoot_north[midpt],1]-efoot_north[iefoot_north[midpt]-1,1],efoot_north[iefoot_north[midpt],0]-efoot_north[iefoot_north[midpt]-1,0])
              efoot_time=strmid(time_string(north_trace.x[iefoot_north[midpt]]),11,2)+strmid(time_string(north_trace.x[iefoot_north[midpt]]),14,2)
              xyouts, efoot_north[iefoot_north[midpt],0]/re+0.9*cos(dxy0*0.9), efoot_north[iefoot_north[midpt],1]/re+0.9*sin(dxy0*0.9), $
                efoot_time, charsize=0.8, color=elf_colors[sc], ALIGNMENT=0.5, ORIENTATION=dxy0*180/!dpi+270 
            endelse

           ; Determine the indices for the tick marks
            if keyword_set(tstep) then begin
              tstep=60.    ; 1 min
              ttime=ntime
              dur=ttime[n_elements(ttime)-1]-ttime[0]
              if dur GT 62 then begin
                res=ttime[1]-ttime[0]
                istep=tstep/res
                last = n_elements(iefoot_north)
                steps=lindgen(last/istep+1)*istep
                tmp=max(steps,nmax)
                tsteps0=ttime[steps[0]]
                if tmp gt (last-1) then steps=steps[0:nmax-1]
                dummy=min(abs(ttime-tsteps0),istep0)
                isteps=steps+istep0
                if n_elements(isteps) eq 2 then isteps=isteps[1]
                if n_elements(isteps) gt 2 then isteps=isteps[1:n_elements(isteps)-2]    ; don't plot first and last tick mark
                if n_elements(isteps) ge 1 then plots, efoot_north[iefoot_north[isteps],0]/re, efoot_north[iefoot_north[isteps],1]/re, psym=1, color=elf_colors[sc]
              endif
            endif
          endif   ; end of NORTH hemisphere
          ;------------------------------------------------
          ;              south hemisphere
          ;------------------------------------------------
          if elx_scnt GT 0 then begin
            spos=make_array(elx_scnt, 3, /double)
            stime=elx_pos.x[sidx]
            spos[*,0]=elx_pos.y[sidx,0]
            spos[*,1]=elx_pos.y[sidx,1]
            spos[*,2]=elx_pos.y[sidx,2]
            store_data, 'el'+elf_probes[sc]+'_pos_gsm_south', data={x:elx_pos.x[sidx], y:spos}, dlimits=dlgsm, limits=lgsm
            tsyg_param_count=elx_scnt ; prepare fewer replicated parameters below
            tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
              [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
              [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
              [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]

            ; trace to conjugate ionosphere first
            ttrace2iono,'el'+elf_probes[sc]+'_pos_gsm_south',newname='el'+elf_probes[sc]+'_pos_gsm_south_ifoot', $
              external_model='t96',internal_model='igrf',/km, in_coord='gsm', out_coord='gsm',par=tsyg_parameter, $
              R0= 1.0156*Re, rlim=400.*Re, trace_var_name='el'+elf_probes[sc]+'_pos_gsm_south_trace'

            ; choose only close field line
            get_data,'el'+elf_probes[sc]+'_pos_gsm_south_ifoot',data=south_ifoot
            siclsB=where(sqrt(south_ifoot.y[*,0]^2+south_ifoot.y[*,1]^2+south_ifoot.y[*,2]^2) lt 7000.,sjclsB)
            get_data,'el'+elf_probes[sc]+'_pos_gsm_south_trace',data=south_trace
            south_trace_size=size(south_trace.y,/dim) ; time * points of each field line * 3

            ; loop of each closed field line
            faketime=make_array(south_trace_size[1],value=south_trace.x[0])
            efoot_south=make_array(n_elements(south_trace.x),3,value=!VALUES.F_NAN)
            efoot_south_dis=make_array(n_elements(south_trace.x),value=!VALUES.F_NAN)
            efoot_south_id=make_array(n_elements(south_trace.x),value=!VALUES.F_NAN)

            for ii=0,sjclsB-1 do begin
              itime=siclsB[ii]
              store_data,'el'+elf_probes[sc]+'_pos_gsm_south_trace1',data={x:faketime,y:reform(south_trace.y[itime,*,*],south_trace_size[1],3)}, dlimits=dlgsm, limits=lgsm
              tt89,'el'+elf_probes[sc]+'_pos_gsm_south_trace1', kp=2,newname='el'+elf_probes[sc]+'_bt89_gsm_south_trace1'
              cotrans,'el'+elf_probes[sc]+'_bt89_gsm_south_trace1','el'+elf_probes[sc]+'_bt89_sm_south_trace1',/gsm2sm
              cotrans,'el'+elf_probes[sc]+'_pos_gsm_south_trace1','el'+elf_probes[sc]+'_pos_sm_south_trace1',/gsm2sm
              get_data,'el'+elf_probes[sc]+'_bt89_sm_south_trace1',data=bt89_south_trace1
              get_data,'el'+elf_probes[sc]+'_pos_sm_south_trace1',data=south_trace1_sm
              ; when sm_B*sm_pos changing sign in xy plane
              dotprod=bt89_south_trace1.y[*,0]*south_trace1_sm.y[*,0]+bt89_south_trace1.y[*,1]*south_trace1_sm.y[*,1]
              index=indgen(n_elements(dotprod)-1)
              iBrsign=where(dotprod[index]*dotprod[index+1] lt 0,jBrsign)
              get_data,'el'+elf_probes[sc]+'_pos_gsm_south_trace1',data=south_trace1_gsm
              if jBrsign ne 1 then begin
                ;stop
              endif else begin
                efoot_x=(dotprod[iBrsign+1]*south_trace1_gsm.y[iBrsign,0]-dotprod[iBrsign]*south_trace1_gsm.y[iBrsign+1,0])/(dotprod[iBrsign+1]-dotprod[iBrsign])
                efoot_y=(dotprod[iBrsign+1]*south_trace1_gsm.y[iBrsign,1]-dotprod[iBrsign]*south_trace1_gsm.y[iBrsign+1,1])/(dotprod[iBrsign+1]-dotprod[iBrsign])
                efoot_z=(dotprod[iBrsign+1]*south_trace1_gsm.y[iBrsign,2]-dotprod[iBrsign]*south_trace1_gsm.y[iBrsign+1,2])/(dotprod[iBrsign+1]-dotprod[iBrsign])
                ; determine when the field line is inside magnetopause
                mpause_t96,dynp,xmgnp=xmgnp,ymgnp=ymgnp,xgsm=south_trace1_gsm.y[*,0]/re,ygsm=south_trace1_gsm.y[*,1]/re,zgsm=south_trace1_gsm.y[*,2]/re,id=id,distan=distan
                mindis=min(distan,imindis) ; min distance of trace field line to mp
                iid=where(id lt 0,cid) ; whether field line is inside or outside mp
                if cid eq 0 and mindis gt 0.1 then begin ; if field line has points outside mp or min distance is too small, discard this field line
                  efoot_south[itime,0]=efoot_x
                  efoot_south[itime,1]=efoot_y
                  efoot_south[itime,2]=efoot_z
                endif
              endelse
            endfor
            iefoot_south=where(finite(efoot_south[*,0]) and abs(efoot_south[*,0]/re) lt 14 and abs(efoot_south[*,1]/re) lt 14)
            plots,efoot_south[iefoot_south,0]/re, efoot_south[iefoot_south,1]/re,color=elf_colors[sc] ; eqautor footprint
            plots,efoot_south[iefoot_south[0],0]/re, efoot_south[iefoot_south[0],1]/re,color=elf_colors[sc],psym=5 ; start point
            plots,efoot_south[iefoot_south[-1],0]/re, efoot_south[iefoot_south[-1],1]/re,color=elf_colors[sc],psym=2 ; end point
            if (efoot_south[iefoot_south[0],0]/re)^2+(efoot_south[iefoot_south[0],1]/re)^2 gt $  ; if elf goes from far to close to earth
              (efoot_south[iefoot_south[-1],0]/re)^2+(efoot_south[iefoot_south[-1],1]/re)^2 then begin
              midpt=0
              dxy0=atan(efoot_south[iefoot_south[midpt],1]-efoot_south[iefoot_south[midpt]+1,1], efoot_south[iefoot_south[midpt],0]-efoot_south[iefoot_south[midpt]+1,0])
              efoot_time=strmid(time_string(south_trace.x[iefoot_south[midpt]]),11,2)+strmid(time_string(south_trace.x[iefoot_south[midpt]]),14,2)
              xyouts, efoot_south[iefoot_south[midpt],0]/re+0.9*cos(dxy0), efoot_south[iefoot_south[midpt],1]/re+0.9*sin(dxy0), $
                efoot_time, charsize=0.8, color=elf_colors[sc], ALIGNMENT=0.5, ORIENTATION=dxy0*180/!dpi+270 ;ORIENTATION=dxy0*180/!dpi+180
            endif else begin  ; if elf goes from close to earth to far
              midpt=-1
              dxy0=atan(efoot_south[iefoot_south[midpt],1]-efoot_south[iefoot_south[midpt]-1,1], efoot_south[iefoot_south[midpt],0]-efoot_south[iefoot_south[midpt]-1,0])
              efoot_time=strmid(time_string(south_trace.x[iefoot_south[midpt]]),11,2)+strmid(time_string(south_trace.x[iefoot_south[midpt]]),14,2)
              xyouts, efoot_south[iefoot_south[midpt],0]/re+0.9*cos(dxy0), efoot_south[iefoot_south[midpt],1]/re+0.9*sin(dxy0), $
                efoot_time, charsize=0.8, color=elf_colors[sc], ALIGNMENT=0.5, ORIENTATION=dxy0*180/!dpi+270
            endelse
            
            if keyword_set(tstep) then begin
              tstep=60.    ; 1 min
              ttime=stime
              dur=ttime[n_elements(ttime)-1]-ttime[0]
              if dur GT 62 then begin
                res=ttime[1]-ttime[0]
                istep=tstep/res
                last = n_elements(iefoot_north)
                steps=lindgen(last/istep+1)*istep
                tmp=max(steps,nmax)
                tsteps0=ttime[steps[0]]
                if tmp gt (last-1) then steps=steps[0:nmax-1]
                dummy=min(abs(ttime-tsteps0),istep0)
                isteps=steps+istep0
                if n_elements(isteps) eq 2 then isteps=isteps[1]
                if n_elements(isteps) gt 2 then isteps=isteps[1:n_elements(isteps)-2]    ; don't plot first and last tick mark
                if n_elements(isteps) ge 1 then plots, efoot_south[iefoot_south[isteps],0]/re, efoot_south[iefoot_south[isteps],1]/re, psym=1, color=elf_colors[sc]
              endif
            endif
          endif   ; end of SOUTH hemisphere
        endfor  ; end of science zone loop
      endif    ; end of data exists
    endfor ; end of spacecraft loop

    ;-----------------------------
    ; DISPLAY ANNOTATIONS/LEGEND
    ;-----------------------------
    xy1=97
    ; create legend
    chsz=.78
    xyouts,xy1,190,'Orbits:',/device,charsize=chsz,color=255
    xyouts,xy1,170,'THEMIS-P3 (D)',/device,charsize=chsz,color=252
    xyouts,xy1,155,'THEMIS-P4 (E)',/device,charsize=chsz,color=253
    xyouts,xy1,140,'THEMIS-P5 (A)',/device,charsize=chsz,color=254

    If(keyword_set(mms_too)) Then Begin
      xyouts,xy1,120,'MMS-1',/device,charsize=chsz;,color=244
    Endif

    If(keyword_set(erg_too)) Then Begin
      xyouts,xy1,100,'Arase (ERG)',/device,charsize=chsz,color=243
    Endif

    If(keyword_set(erg_too)) Then Begin
      xyouts,xy1,100,'Arase (ERG)',/device,charsize=chsz,color=243
    Endif

    If(keyword_set(elf_too)) Then Begin
      xyouts,xy1,80,'ELF (A)',/device,charsize=chsz,color=242
      xyouts,xy1,65,'ELF (B)',/device,charsize=chsz,color=241
    Endif

    xyouts, xy1, 720, 'Legend:',/device,charsize=chsz,color=255
    xyouts, xy1, 700, 'Trace2Equator(t96): Solid',/device,charsize=chsz,color=255
    xyouts, xy1, 685, 'Orbit Start: Triangle',/device,charsize=chsz,color=255
    xyouts, xy1, 670, 'Orbit End: Asterisk',/device,charsize=chsz,color=255
    xyouts, xy1, 655, 'Science Zone is FULL Minutes',/device,charsize=chsz,color=255
    xyouts, xy1, 640, 'Hr or Min Tick Mark: Plus Sign',/device,charsize=chsz,color=255
    xyouts, xy1, 625, 'BowShock: Dotted Line',/device,charsize=chsz,color=255
    xyouts, xy1, 610, 'Magnetopause: Dashed Line',/device,charsize=chsz,color=255

    ; note the time of creation and model used
    xyouts,xy1-10,10, 'Created: '+systime(),/device,charsize=chsz,color=255

    ; gif or other output
    date=strmid(tstart,0,10)
    If(keyword_set(rbsp_too)) or (keyword_set(mms_too)) or (keyword_set(erg_too)) Then rbext='multi_mission_conjunctions_' Else rbext=''
    if keyword_set(gifout) then begin
      image=tvrd()
      device,/close
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      if undefined(trange) then begin
        dir_products = !elf.local_data_dir + 'gtrackplots/'+ strmid(date,0,4)+'/'+strmid(date,5,2)+'/'+strmid(date,8,2)+'/'
      endif else begin
        dir_products = !elf.local_data_dir + 'gtrackplots/'
      endelse
      file_mkdir, dir_products
      if not keyword_set(noview) then tv,image
      if undefined(trange) then begin
        name=dir_products+'orbit_'+rbext+strmid(date,0,4) + strmid(date,5,2) + strmid(date,8,2)+file_lbl[j]+'.gif'
      endif else begin
        name=dir_products+'orbit_multi_mission_conjunctions.gif'        
      endelse
      ;name=dir_products+'orbit_'+rbext+date+file_lbl[j]+'.gif'
      write_gif,name,image,r,g,b
      print,'Output in ',name
    endif
    if keyword_set(insert) then stop
  endfor
end
