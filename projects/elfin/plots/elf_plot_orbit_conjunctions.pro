;+
; NAME:		elf_plot_orbit_conjunctions
; PURPOSE:	create ELFIN, THEMIS, MMS, ERG orbit plots in GSM coordinates for web site
; INPUT:	tstart like '2009-12-01'
; OUTPUT:	gif files may be generated
; KEYWORDS:	gifout = gif images are generated
;           file = specify file if not reading THEMIS ephemeris
;           insert = insert stop at end of program
;           rbsp_too = if set, overlay RBSP orbits
;           mms_too = if set, overlay MMS orbits
;           erg_too = if set, overlay ERG orbigts
;           model = name of Tsyganenko model ('t89', 't96', 'ta15'). default is 't96'
; HISTORY:	original file in March 2007, hfrey
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
;-

pro elf_plot_orbit_conjunctions,tstart,gifout=gifout,file=file, elf_too=elf_too, tstep=tstep, $
   rbsp_too=rbsp_too, mms_too=mms_too, erg_too=erg_too, move=move,insert=insert, no_trace=no_trace, $
   model=model

	; some setup
;@thg_asi_setup.init
thm_init,/no_color_setup

if undefined(gifout) then gifout=1
if undefined(tstep) then tstep=1
if undefined(elf_too) then elf_too=1
if undefined(mms_too) then mms_too=1
if undefined(erg_too) then erg_too=1
if undefined(move) then move=1

re=6378.

if ~keyword_set(gifout) then gifout=1
	; color and symbol definition
set_plot,'z'
loadct,0
tvlct,r,g,b,/get
; colors and symbols, closest numbers for loadct,39
;P1 red        [255,0,0],   250	IDL symbol 5
;P2 green      [0,255,0],   146	IDL symbol 2
;P3 light blue [0,255,255], 102 IDL symbol 1
;P4 dark blue  [0,0,255],    57	IDL symbol 4
;P5 purple     [87,0,145],   30	IDL symbol 6
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

; elf A - blue
; elf B - orange (red)
If(keyword_set(erg_too)) Then Begin
  r[242]=0   & g[242]=0   & b[242]=255
  r[241]=255   & g[241]=0   & b[241]=0  
Endif

; more plot set-up
tvlct,r,g,b
set_plot,'z'
symbols=[5,2,1,4,6]

; Set the time
timespan,tstart,1,/day
tend=time_string(time_double(tstart)+86400.0d0)
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

;--------------------------------------------------
; Get ELFIN state data and trace2equator
; -------------------------------------------------
elf_probes=['a','b']
elfa = 0
elfb = 0
tr=timerange()
for sc=0,1 do begin
  ; get position data
  elf_load_state, probe=elf_probes[sc]
  get_data, 'el'+elf_probes[sc]+'_pos_gei',data=dat, dlimits=dl, limits=l    ; position in GEI
    if size(dat, /type) EQ 8 then begin
      cotrans,'el'+elf_probes[sc]+'_pos_gei','el'+elf_probes[sc]+'_pos_gse',/GEI2GSE
      cotrans,'el'+elf_probes[sc]+'_pos_gse','el'+elf_probes[sc]+'_pos_gsm',/GSE2GSM
    endif 
    ; TRACE TO EQUATOR
    get_data, 'el'+elf_probes[sc]+'_pos_gsm', data=elx_pos, dlimits=dlgsm, limits=lgsm
    ; calculate lat (needed to determine N/S hemisphere)
    cart2latlong, elx_pos.y[*,0], elx_pos.y[*,1], elx_pos.y[*,2], elx_r, elx_lat, elx_lon
    nidx=where(elx_lat GE 0, elx_ncnt)
    sidx=where(elx_lat LT 0, elx_scnt)
    elx_pos_foot=elx_pos
    ;trace to equator
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
      ttrace2equator,'el'+elf_probes[sc]+'_pos_gsm_north',new_name='el'+elf_probes[sc]+'_pos_gsm_north_foot', $
        external_model='t96',internal_model='igrf',/km, in_coord='gsm',out_coord='gsm',par=tsyg_parameter,R0= 1.0156 ;,rlim=100.;*Re
      get_data,'el'+elf_probes[sc]+'_pos_gsm_north_foot',data=d
      elx_pos_foot.y[nidx,0]=d.y[*,0]
      elx_pos_foot.y[nidx,1]=d.y[*,1]
      elx_pos_foot.y[nidx,2]=d.y[*,2]
     endif
     if elx_scnt GT 0 then begin
       spos=make_array(elx_scnt, 3, /double)
       spos[*,0]=elx_pos.y[sidx,0]
       spos[*,1]=elx_pos.y[sidx,1]
       spos[*,2]=elx_pos.y[sidx,2]
       store_data, 'el'+elf_probes[sc]+'_pos_gsm_south', data={x:elx_pos.x[sidx], y:spos}, dlimits=dlgsm, limits=lgsm
       tsyg_param_count=elx_scnt ; prepare fewer replicated parameters below
       tsyg_parameter=[[replicate(dynp,tsyg_param_count)],[replicate(dst,tsyg_param_count)],$
         [replicate(bswy,tsyg_param_count)],[replicate(bswz,tsyg_param_count)],$
         [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],$
         [replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)],[replicate(0.,tsyg_param_count)]]
       ttrace2equator,'el'+elf_probes[sc]+'_pos_gsm_south',new_name='el'+elf_probes[sc]+'_pos_gsm_south_foot', $
         external_model='t96',internal_model='igrf',/km, in_coord='gsm',out_coord='gsm',par=tsyg_parameter,R0= 1.0156;,rlim=100.*Re
       get_data,'el'+elf_probes[sc]+'_pos_gsm_south_foot', data=d
       elx_pos_foot.y[sidx,0]=d.y[*,0]
       elx_pos_foot.y[sidx,1]=d.y[*,1]
       elx_pos_foot.y[sidx,2]=d.y[*,2]
     endif
     store_data, 'el'+elf_probes[sc]+'_pos_gsm_foot',data={x: elx_pos_foot.x, y: elx_pos_foot.y}, $
            dlimits=dlgsm, limits=lgsm
endfor                          ; sc loop
get_data,'ela_pos_gsm',data=ela_pos_gsm
get_data,'elb_pos_gsm',data=elb_pos_gsm
get_data,'ela_pos_gsm_foot',data=ela_pos_gsm_foot
get_data,'elb_pos_gsm_foot',data=elb_pos_gsm_foot
sci_zones_a=get_elf_science_zone_start_end(trange=tr, probe='a')
sci_zones_b=get_elf_science_zone_start_end(trange=tr, probe='b')
save, filename='elab_pos_gsm_foot_2', ela_pos_gsm_foot, elb_pos_gsm_foot, sci_zones_a, sci_zones_b

;---------------------------
; Get THEMIS state data
;---------------------------
thm_probes=['a','d','e']
for sc=0,2 do begin
  thm_load_state,probe=thm_probes[sc]
  get_data,'th'+thm_probes[sc]+'_state_pos',data=dat	; position in GEI
  cotrans,'th'+thm_probes[sc]+'_state_pos','th'+thm_probes[sc]+'_state_pos_gse',/GEI2GSE
  cotrans,'th'+thm_probes[sc]+'_state_pos_gse','th'+thm_probes[sc]+'_state_pos_gsm',/GSE2GSM
  get_data, 'th'+thm_probes[sc]+'_state_pos_gsm', data=datgsm, dlimits=dlgsm, limits=lgsm
  ; calculate lat (needed to determine N/S hemisphere)
  cart2latlong, datgsm.y[*,0], datgsm.y[*,1], datgsm.y[*,2], thm_r, thm_lat, thm_lon
  nidx=where(thm_lat GE 0, thm_ncnt)
  sidx=where(thm_lat LT 0, thm_scnt)
  datgsm_foot=datgsm    ; use thx_pos_foot for inserting north and south traces
  ; TRACE TO EQUATOR
  if thm_ncnt GT 0 then begin
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
  if thm_scnt GT 0 then begin
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
           login_info='/disks/socware/thmsoc_dp_current/src/config/mms_auth_info.sav', $
           local_data_dir='/mydisks/home/thmsoc/mms/'
        get_data,'mms'+probes[sc]+'_defeph_pos',data=dat ; default position is GEI
        ; check that definitive data was successfully retrieved, if not then check for predicted data
        if size(dat, /type) Ne 8 then begin
            batch_procedure_error_handler, 'mms_load_state', probe=probes[sc], datatypes='pos', trange=tr, level='pred',$
              login_info='/disks/socware/thmsoc_dp_current/src/config/mms_auth_info.sav', $
              local_data_dir='/mydisks/home/thmsoc/mms/'
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
        if mms_ncnt GT 0 then begin
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
        if mms_scnt GT 0 then begin
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
    erg_init, local_data_dir='/mydisks/home/thmsoc/ergsc/'
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
    if erg_ncnt GT 0 then begin
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
    if erg_scnt GT 0 then begin
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

;-----------------------------------
; Setup for orbits - 12 hr plots
;-----------------------------------
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
!p.multi=[0,1,1]	
if keyword_set(gifout) then begin
   set_plot,'z'
   device,set_resolution=[800,800]
   charsize=0.75
   noview=1
endif else begin
   set_plot,'x'
   window,0,xsize=800,ysize=800
   charsize=1.5
endelse

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

    ;----------------------------------------------
    ; Plot the frame and range for the orbit plots
    ;----------------------------------------------
    plot,findgen(10),xrange=xrange,yrange=yrange,/xstyle,/ystyle,/nodata, $
      title='Multi-mission orbits: T96 magnetic equator projections, '+strmid(tstart,0,10)+plot_lbl[j],$
      xtitle='Xeq-GSM',ytitle='Yeq-GSM',charsize=charsize+.2,/isotropic

    ; plot earth
    oplot, ex[night_idx], ey[night_idx]
    oplot, 1.0*cos(pts), 1.0*sin(pts)
    oplot,[-100,100],[0,0],line=1
    oplot,[0,0],[-100,100],line=1

    ; plot the magnetopause line
    oplot,xmp,ymp,line=2
    ; plot the bow shock line
    oplot,xbs,ybs,line=1

    ; plot Neutral Sheet
    ; **** TO DO - should probably remove
    time = make_array(301,/double)
    thisstart=tha_state_pos_gsm.x[min_st[j]]
    thisend=tha_state_pos_gsm.x[min_en[j]]
;    for tm=0,300 do time[tm]=time_double(thisstart) + tm*143.8
;    ns_gsm_pos = make_array(301,3,/double)
;    ns_gsm_pos[*,0] = -1.*dindgen(301)/5.
;    ns_gsm_pos[*,2] = 0
;    neutral_sheet, time, ns_gsm_pos, model='aen', distance2NS=dz2NS
;    ns_gsm_pos[*,1]=dz2NS
;    oplot, ns_gsm_pos[*,0], ns_gsm_pos[*,1],  color=248, linestyle=4

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
    thd_foot_t=thd_time[didx]
    thd_foot_x=thd_foot[didx,0]
    thd_foot_y=thd_foot[didx,1]    
    the_foot_t=the_time[eidx]
    the_foot_x=the_foot[eidx,0]
    the_foot_y=the_foot[eidx,1]
    
    ;----------------
    ; PLOT THEMIS
    ;----------------
    if acnt GT 0 then begin 
      xidx=where(abs(tha_foot_x) LE 15, xcnt)
      if xcnt GT 0 then begin
        tha_foot_t=tha_foot_t[xidx]
        tha_foot_x=tha_foot_x[xidx]
        tha_foot_y=tha_foot_y[xidx]
        yidx=where(abs(tha_foot_y) LE 15, ycnt)
        if ycnt GT 0 then begin
          tha_foot_t=tha_foot_t[yidx]
          tha_foot_x=tha_foot_x[yidx]
          tha_foot_y=tha_foot_y[yidx]
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
        yidx=where(abs(thd_foot_y) LE 15, ycnt)
        if ycnt GT 0 then begin
          thd_foot_t=thd_foot_t[yidx]
          thd_foot_x=thd_foot_x[yidx]
          thd_foot_y=thd_foot_y[yidx]
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
        yidx=where(abs(the_foot_y) LE 15, ycnt)
        if ycnt GT 0 then begin
          the_foot_t=the_foot_t[yidx]
          the_foot_x=the_foot_x[yidx]
          the_foot_y=the_foot_y[yidx]
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
    If(keyword_set(mms_too)) Then Begin
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
;          oplot,mms1_foot_x,mms1_foot_y,color=244, psym=3 ;thick=1.5
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
    ; PLOT ELFIN Orbits
    ;----------------------
    If(keyword_set(elf_too)) Then Begin
      ;----------
      ; ELFIN B
      ;----------
      elb_idx=where(elb_pos_gsm_foot.x GE thisstart AND elb_pos_gsm_foot.x LE thisend, bcnt)
      if bcnt GT 0 then begin
        elb_pos_foot_t=elb_pos_gsm_foot.x[elb_idx]
        elb_pos_foot_x=elb_pos_gsm_foot.y[elb_idx,0]/6375.
        elb_pos_foot_y=elb_pos_gsm_foot.y[elb_idx,1]/6375.
        elb_pos_foot_z=elb_pos_gsm_foot.y[elb_idx,2]/6375.
        mpause_flag, elb_pos_foot_x,elb_pos_foot_y,elb_pos_foot_z,xmp, ymp, mpauseflag=mflag
        emidx=where(mflag GT 0, emcnt)
        if emcnt GT 0 then begin
           elb_pos_foot_tf=elb_pos_foot_t[emidx]
           elb_pos_foot_xf=elb_pos_foot_x[emidx]
           elb_pos_foot_yf=elb_pos_foot_y[emidx]
           elb_pos_foot_zf=elb_pos_foot_z[emidx]
        endif
        if ~undefined(sci_zones_b) && n_elements(sci_zones_b.starts) GT 0 then begin
          elb_sidx=where((sci_zones_b.starts GE thisstart AND sci_zones_b.starts LE thisend) OR $
            (sci_zones_b.ends GE thisstart AND sci_zones_b.starts LE thisend), szcnt)
          bstarts=sci_zones_b.starts[elb_sidx]
          bends=sci_zones_b.ends[elb_sidx]
          for sz=0, szcnt-2 do begin
            bidx=where(elb_pos_foot_tf GE bstarts[sz] AND elb_pos_foot_tf LE bends[sz], bcnt)  
            if bcnt GT 0 then begin
              elb_foot_t=elb_pos_foot_tf[bidx]   ;
              elb_foot_x=elb_pos_foot_xf[bidx]   ;
              elb_foot_y=elb_pos_foot_yf[bidx]   ; 
              elb_foot_z=elb_pos_foot_zf[bidx]   ;
              xidx=where(abs(elb_foot_x) LE 15, xcnt)
              if xcnt GT 0 then begin
                elb_foot_t=elb_foot_t[xidx]
                elb_foot_x=elb_foot_x[xidx]
                elb_foot_y=elb_foot_y[xidx]
                elb_foot_z=elb_foot_z[xidx]
                yidx=where(abs(elb_foot_y) LE 15, ycnt)
                if ycnt GT 0 then begin
                  elb_foot_t=elb_foot_t[yidx]
                  elb_foot_x=elb_foot_x[yidx]
                  elb_foot_y=elb_foot_y[yidx]
                  elb_foot_z=elb_foot_z[yidx]
                  zidx=where(abs(elb_foot_z) LE 10, zcnt)
                  if zcnt GT 0 then begin
                    elb_foot_t=elb_foot_t[zidx]
                    elb_foot_x=elb_foot_x[zidx]
                    elb_foot_y=elb_foot_y[zidx]  
                    npts=n_elements(elb_foot_x)
                    mididx=fix(npts/2)
                    oplot, elb_foot_x, elb_foot_y, color=241,psym=3 
                    plots, elb_foot_x[0], elb_foot_y[0], color=241, psym=5
                    plots, elb_foot_x[npts-1], elb_foot_y[npts-1], color=241, psym=2
                    plots, elb_foot_x[mididx], elb_foot_y[mididx], color=241, psym=4
                    ;endif
                  endif
                endif
              endif
            endif
            ; Determine the indices for the tick marks
            if keyword_set(tstep) && bcnt GT 0 then begin
              tstep=60.    ; 1 min
              this_time=elb_foot_t
              res=this_time[1]-this_time[0]
              istep=tstep/res
              last = n_elements(this_time)
              steps=lindgen(last/istep+1)*istep
              tmp=max(steps,nmax)
              if tmp gt (last-1) then steps=steps[0:nmax-1]
              tsteps0=this_time[steps[0]]
              dummy=min(abs(this_time-tsteps0),istep0)
              isteps=steps+istep0
              isteps=isteps[1:n_elements(isteps)-1]    ; don't plot first and last tick mark 
              plots, elb_foot_x[isteps], elb_foot_y[isteps], psym=1, color=241
            endif
          endfor
        endif
      endif

      ;----------
      ; ELFIN A
      ;----------
      ela_idx=where(ela_pos_gsm_foot.x GE thisstart AND ela_pos_gsm_foot.x LE thisend, acnt)
      if acnt GT 0 then begin
        ela_pos_foot_t=ela_pos_gsm_foot.x[ela_idx]        
        ela_pos_foot_x=ela_pos_gsm_foot.y[ela_idx,0]/6375.
        ela_pos_foot_y=ela_pos_gsm_foot.y[ela_idx,1]/6375.
        ela_pos_foot_z=ela_pos_gsm_foot.y[ela_idx,2]/6375.
        mpause_flag, ela_pos_foot_x,ela_pos_foot_y,ela_pos_foot_z,xmp, ymp, mpauseflag=mflag
        emidx=where(mflag GT 0, emcnt)
        if emcnt GT 0 then begin
          ela_pos_foot_tf=ela_pos_foot_t[emidx]
          ela_pos_foot_xf=ela_pos_foot_x[emidx]
          ela_pos_foot_yf=ela_pos_foot_y[emidx]
          ela_pos_foot_zf=ela_pos_foot_z[emidx]
        endif
        if ~undefined(sci_zones_a) && n_elements(sci_zones_a.starts) GT 0 then begin
         ela_sidx=where((sci_zones_a.starts GE thisstart AND sci_zones_a.starts LE thisend) OR $
                       (sci_zones_a.ends GE thisstart AND sci_zones_a.starts LE thisend), szcnt)
         astarts=sci_zones_a.starts[ela_sidx]
         aends=sci_zones_a.ends[ela_sidx]
         for sz=0, szcnt-1 do begin 
           aidx=where(ela_pos_foot_tf GE astarts[sz] AND ela_pos_foot_tf LE aends[sz], acnt)
           if acnt GT 0 then begin
             ela_foot_t=ela_pos_foot_tf[aidx]     
             ela_foot_x=ela_pos_foot_xf[aidx]
             ela_foot_y=ela_pos_foot_yf[aidx]
             ela_foot_z=ela_pos_foot_zf[aidx]
             xidx=where(abs(ela_foot_x) LE 15, xcnt)
             if xcnt GT 0 then begin
               ela_foot_t=ela_foot_t[xidx]
               ela_foot_x=ela_foot_x[xidx]
               ela_foot_y=ela_foot_y[xidx]
               ela_foot_z=ela_foot_z[xidx]
               yidx=where(abs(ela_foot_y) LE 15, ycnt)
               if ycnt GT 0 then begin
                 ela_foot_t=ela_foot_t[yidx]
                 ela_foot_x=ela_foot_x[yidx]
                 ela_foot_y=ela_foot_y[yidx]
                 ela_foot_z=ela_foot_z[yidx]
                 zidx=where(abs(ela_foot_z) LE 10., zcnt)
                 if zcnt GT 0 then begin
                   ela_foot_t=ela_foot_t[zidx]
                   ela_foot_x=ela_foot_x[zidx]
                   ela_foot_y=ela_foot_y[zidx]                  
                   ela_foot_z=ela_foot_z[zidx]
                   npts=n_elements(ela_foot_x)
                   mididx=fix(npts/2)
                   oplot, ela_foot_x, ela_foot_y, color=242, psym=3 
                   plots, ela_foot_x[0], ela_foot_y[0], color=242, psym=5
                   plots, ela_foot_x[npts-1], ela_foot_y[npts-1], color=242, psym=2
                   plots, ela_foot_x[mididx], ela_foot_y[mididx], color=242, psym=4                  
                 ; Determine the indices for the tick marks
                 endif
                 if keyword_set(tstep) then begin
                   tstep=60.    ; 1 min
                   this_time=ela_foot_t
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
                   ; plot tick marks for projection
                   plots, ela_foot_x[isteps], ela_foot_y[isteps], psym=1, color=242
                 endif
               endif
             endif
           endif 
         endfor        
        endif
      endif
      
endif    ; end ELFIN 

    ;-----------------------------
    ; DISPLAY ANNOTATIONS/LEGEND
    ;-----------------------------
    xy1=96
    ; annotate (create legend)
    xyouts,xy1,260,'Orbits:',/device,charsize=1.15,color=255
    xyouts,xy1,230,'THEMIS-P3 (D)',/device,charsize=1.15,color=252
    xyouts,xy1,205,'THEMIS-P4 (E)',/device,charsize=1.15,color=253
    xyouts,xy1,180,'THEMIS-P5 (A)',/device,charsize=1.15,color=254

    If(keyword_set(mms_too)) Then Begin
      xyouts,xy1,150,'MMS-1',/device,charsize=1.15;,color=244
    Endif

    If(keyword_set(erg_too)) Then Begin
        xyouts,xy1,120,'Arase (ERG)',/device,charsize=1.15,color=243
    Endif
    
    If(keyword_set(elf_too)) Then Begin
      xyouts,xy1,90,'ELF (A)',/device,charsize=1.15,color=242
      xyouts,xy1,65,'ELF (B)',/device,charsize=1.15,color=241
    Endif
 
    xy1=552
    xy1=530
    xyouts, xy1, 250, 'Legend:',/device,charsize=1.15,color=255
    xyouts, xy1, 220, 'Trace2Equator(t96): solid',/device,charsize=1.15,color=255
    xyouts, xy1, 195, 'Orbit Start: Triangle',/device,charsize=1.15,color=255
    xyouts, xy1, 170, 'Orbit End: Asterisk',/device,charsize=1.15,color=255
    xyouts, xy1, 145, 'Orbit Midpt: Diamond',/device,charsize=1.15,color=255
    xyouts, xy1, 120, 'Hr or Min Tick Mark: Plus Sign',/device,charsize=1.15,color=255
    xyouts, xy1, 95, 'BowShock: Dotted Line',/device,charsize=1.15,color=255
    xyouts, xy1, 70, 'Magnetopause: Dashed Line',/device,charsize=1.15,color=255

    ; note the time of creation and model used
    xyouts,xy1,10, 'Created: '+systime(),/device,color=255
    ;xyouts,xy1,-10,'Tsyganenko-1996',/device,color=255
    
    ; gif or other output
    date=strmid(tstart,0,10)
    If(keyword_set(rbsp_too)) or (keyword_set(mms_too)) or (keyword_set(erg_too)) Then rbext='multi_mission_conjunctions_' Else rbext=''
    if keyword_set(gifout) then begin
        image=tvrd()
        device,/close
        image[where(image eq 255)]=1
        image[where(image eq 0)]=255
        dir_out=!elf.local_data_dir + '/gtrackplots/'
        if not keyword_set(noview) then tv,image
        name=dir_out+'orbit_'+rbext+date+file_lbl[j]+'.gif' 
        write_gif,name,image,r,g,b
        print,'Output in ',name
    endif
endfor
if keyword_set(insert) then stop
end
