;+
; NAME: rbsp_read_ect_mag_ephem
; SYNTAX:
; PURPOSE: Read in RBSP ECT's official magnetic field model predicted quantities
; INPUT: sc -> 'a' or 'b'
;		 date -> '2014-01-01'
;        type -> defaults to OP77Q. Can also have "TS04D" (definitive)
;        or "T89Q" for predicted.
; OUTPUT: tplot variables with prefix 'rbsp'+sc+'_ME_'
;		  Will also return perigeetimes as keyword
; KEYWORDS:
; HISTORY: Written by Aaron W Breneman, UMN
; VERSION:
;   $LastChangedBy: $
;   $LastChangedDate: $
;   $LastChangedRevision: $
;   $URL: $
;-


pro rbsp_read_ect_mag_ephem,sc,perigeetimes,$
  pre=pre,type=type,$
  _extra=extra

  if ~keyword_set(type) then type = 'OP77Q'



  if ~tag_exist(extra,'no_rbsp_efw_init') then rbsp_efw_init
  rbsp_spice_init


  local_data_dir = !rbsp_spice.local_data_dir
  local_data_dir += 'ect_definitive_ephem/'

  if ~keyword_set(pre) then remote_data_dir = 'http://www.rbsp-ect.lanl.gov/data_pub/rbsp'+sc+'/MagEphem/definitive/'
  if keyword_set(pre) then remote_data_dir = 'http://www.rbsp-ect.lanl.gov/data_pub/rbsp'+sc+'/MagEphem/predicted/'

  ;Find number of days to load data for
  tr = timerange()
  ndays = ceil((tr[1]-tr[0])/86400)

  unixtime = [0d]
  lstar = dblarr(1,18)
  bgsm = dblarr(1,3)
  bmag = [0d]
  dipoletiltangle = [0d]
  orbitnumber = [0d]
  ed_mlat = [0d]
  ed_mlon = [0d]
  ed_mlt = [0d]
  ed_r = [0d]
  cd_mlat = [0d]
  cd_mlon = [0d]
  cd_mlt = [0d]
  cd_r = [0d]
  mlat_diff = [0d]
  mlon_diff = [0d]
  mlt_diff = [0d]
  r_diff = [0d]
  ;fieldlinetype_int = [0]
  pos_gsm = dblarr(1,3)
  pos_gse = dblarr(1,3)
  lshell = [0d]  ;from simple dipole
  lvalue = [0d]  ;not simple dipole.
  invlat = [0d]
  invlat_eq = [0d]
  kp = [0d]
  lc = dblarr(1,2)
  perigeetimes = ['']
  bfn_geo = dblarr(1,3)
  bfn_gsm = dblarr(1,3)
  bfs_geo = dblarr(1,3)
  bfs_gsm = dblarr(1,3)
  bmag_mirror = dblarr(1,18)

  pfn_cd_mlat = [0d]
  pfn_cd_mlon = [0d]
  pfn_cd_mlt = [0d]
  pfn_ed_mlat = [0d]
  pfn_ed_mlon = [0d]
  pfn_ed_mlt = [0d]
  pfn_geo = dblarr(1,3)         ;Northern footpoint in GEO coord
  pfn_geod_height = [0d]
  pfn_geod_latlon = dblarr(1,2)
  pfn_gsm = dblarr(1,3)

  pfs_cd_mlat = [0d]
  pfs_cd_mlon = [0d]
  pfs_cd_mlt = [0d]
  pfs_ed_mlat = [0d]
  pfs_ed_mlon = [0d]
  pfs_ed_mlt = [0d]
  pfs_geo = dblarr(1,3)         ;Southern footpoint in GEO coord
  pfs_geod_height = [0d]
  pfs_geod_latlon = dblarr(1,2)
  pfs_gsm = dblarr(1,3)


  for i=0,ndays-1 do begin

    date = strmid(time_string(tr[0] + 86400*i),0,10)
    date2 = strmid(date,0,4)+strmid(date,5,2)+strmid(date,8,2)
    dirpath = strmid(date,0,4) + '/'

    ;; if ~keyword_set(pre) then fn = 'rbsp'+sc+'_def_MagEphem_OP77Q_'+date2+'_v?.?.?.h5'
    ;; if keyword_set(pre) then fn = 'rbsp'+sc+'_pre_MagEphem_OP77Q_'+date2+'_v?.?.?.h5'
    if ~keyword_set(pre) then fn = 'rbsp'+sc+'_def_MagEphem_'+type+'_'+date2+'_v?.?.?.h5'
    if keyword_set(pre) then fn = 'rbsp'+sc+'_pre_MagEphem_'+type+'_'+date2+'_v?.?.?.h5'


    ;Find out what files are online
    ;	FILE_HTTP_COPY,dirpath,url_info=ui,links=links,localdir=local_data_dir,$
    ;		serverdir=remote_data_dir

    ;load file
    if ~keyword_set(pre) then relpathnames = dirpath + fn
    if keyword_set(pre) then relpathnames = fn
    ;; relpathnames = '2015//rbspa_def_MagEphem_OP77Q_20150106_v?.?.?.h5'
    ;     file_loaded = file_retrieve(relpathnames,remote_data_dir=remote_data_dir,$
    ;                                 local_data_dir=local_data_dir,/last_version)
    ;    file_loaded = file_retrieve(relpathnames,remote_data_dir='https://www.rbsp-ect.lanl.gov/data_pub/rbsp'+sc+'/MagEphem/definitive/',$
    ;                                local_data_dir=local_data_dir,/last_version)

    file_loaded = spd_download(remote_path='https://www.rbsp-ect.lanl.gov/data_pub/rbsp'+sc+'/MagEphem/definitive/',$
    remote_file=relpathnames,$
    local_path=local_data_dir,$
    /last_version)


    ;'https://www.rbsp-ect.lanl.gov/data_pub/rbspb/MagEphem/def/'
    ;'http://www.rbsp-ect.lanl.gov/data_pub/rbspb/MagEphem/def/'

    ;*****  UNDER CONSTRUCTION

    ;stop

    ;	R2 = FILE_INFO(file_loaded)
    ;	help,r2,/st
    ;file_loaded = '/Users/aaronbreneman/Desktop/Research/RBSP_Firebird_microburst_conjunction_jan20/ECT_magephem/rbspa_def_MagEphem_T89D_20160120_v1.0.0.h5'
    ;**************************

    ft = file_test(file_loaded)
    if ~ft then begin
      print,'***NO ECT MAG EPHEM FILE FOUND.....RETURNING****'
      return
    endif
    if ~H5F_IS_HDF5(file_loaded) then begin
      print,'***NO ECT MAG EPHEM FILE FOUND.....RETURNING****'
      return
    endif

    result = h5_parse(file_loaded,/READ_DATA)

    ;Time variable
    ;Get to GPS time (starts at Jan 6th 1980 at 0:00:00)
    offset = time_double('1980-01-06/00:00:00') - time_double('1970-01-01/00:00:00')
    gpstime = result.gpstime._data
    unixtime = [unixtime,gpstime + offset]


    ;L*  (L-star parameter)
    lstar = [lstar,transpose(result.lstar._data)]




    ;BGSM
    tmp = result.bsc_gsm._data
    bmag = [bmag,reform(tmp[3,*])]
    bgsm = [bgsm,transpose(tmp[0:2,*])]

    ;Dipole tilt angle
    dipoletiltangle = [dipoletiltangle,result.dipoletiltangle._data]


    ;orbit number
    orbitnumber = [orbitnumber,result.orbitnumber._data]

    ;eccentric dipole stuff
    ed_mlat = [ed_mlat,result.edmag_mlat._data]
    ed_mlon = [ed_mlon,result.edmag_mlon._data]
    ed_mlt = [ed_mlt,result.edmag_mlt._data]
    ed_r = [ed_r,result.edmag_r._data]

    ;centered dipole stuff
    cd_mlat = [cd_mlat,result.cdmag_mlat._data]
    cd_mlon = [cd_mlon,result.cdmag_mlon._data]
    cd_mlt = [cd_mlt,result.cdmag_mlt._data]
    cd_r = [cd_r,result.cdmag_r._data]

    ;differences b/t centered dipole and eccentric dipole
    mlat_diff = [mlat_diff,cd_mlat - ed_mlat]
    mlon_diff = [mlon_diff,cd_mlon - ed_mlon]
    mlt_diff = [mlt_diff,cd_mlt - ed_mlt]
    r_diff = [r_diff,cd_r - ed_r]


    ;Field Line Type
    ;Description of the type of field line the S/C is on.,
    ;Can be one of 4 types:

    ;1 = LGM_CLOSED - FL hits Earth at both ends.
    ;2 = LGM_OPEN_N_LOBE - FL is an OPEN field line rooted in the Northern polar cap.
    ;3 = LGM_OPEN_S_LOBE - FL is an OPEN field line rooted in the Southern polar cap.
    ;4 = LGM_OPEN_IMF - FL does not hit Earth at eitrher end.
    ;		fieldlinetype = result.fieldlinetype._data
    ;		goo = where(fieldlinetype eq 'LGM_OPEN_N_LOBE')
    ;		if goo[0] ne -1 then fieldlinetype_int[goo] = [fieldlinetype_int,replicate(2,n_elements(fieldlinetype))]
    ;		goo = where(fieldlinetype eq 'LGM_OPEN_S_LOBE')
    ;		if goo[0] ne -1 then fieldlinetype_int[goo] = [fieldlinetype_int,replicate(3,n_elements(fieldlinetype))]
    ;		goo = where(fieldlinetype eq 'LGM_OPEN_IMF')
    ;		if goo[0] ne -1 then fieldlinetype_int[goo] = [fieldlinetype_int,replicate(4,n_elements(fieldlinetype))]

    ;Lshell
    pos_gsm = [pos_gsm,transpose(result.rgsm._data)]
    pos_gse = [pos_gse,transpose(result.rgsm._data)]
    lshell = [lshell,result.lsimple._data]
    ;     lvalue = [lvalue,result.L._data] ;L* maybe??? [x,18] array, similar to result.lstar
    invlat = [invlat,result.invlat._data]
    invlat_eq = [invlat_eq,result.invlat_eq._data]

    ;Kp index
    kp = [kp,result.kp._data]

    ;loss cone
    lc_n = result.loss_cone_alpha_n._data
    lc_s = result.loss_cone_alpha_s._data
    lc = [lc,[[lc_n],[lc_s]]]

    ;perigee times
    perigeetimes = [perigeetimes,result.perigeetimes._data]



    ;Field line footpoint coordinates and field strengths at the footpoints
    bfn_geo = [bfn_geo,transpose(result.Bfn_geo._data[0:2,*])]
    bfn_gsm = [bfn_gsm,transpose(result.Bfn_gsm._data[0:2,*])]
    bfs_geo = [bfs_geo,transpose(result.Bfs_geo._data[0:2,*])]
    bfs_gsm = [bfs_gsm,transpose(result.Bfs_gsm._data[0:2,*])]
    bmag_mirror = [bmag_mirror,transpose(result.Bm._data)]


    pfn_cd_mlat = [pfn_cd_mlat,result.Pfn_CD_MLAT._data]
    pfn_cd_mlon = [pfn_cd_mlon,result.Pfn_CD_MLON._data]
    pfn_cd_mlt = [pfn_cd_mlt,result.Pfn_CD_MLT._data]
    pfn_ed_mlat = [pfn_ed_mlat,result.Pfn_ED_MLAT._data]
    pfn_ed_mlon = [pfn_ed_mlon,result.Pfn_ED_MLON._data]
    pfn_ed_mlt = [pfn_ed_mlt,result.Pfn_ED_MLT._data]
    pfn_geo = [pfn_geo,transpose(result.Pfn_geo._data)]
    pfn_geod_height = [pfn_geod_height,result.Pfn_geod_Height._data]
    pfn_geod_latlon = [pfn_geod_latlon,transpose(result.Pfn_geod_LatLon._data)]
    pfn_gsm = [pfn_gsm,transpose(result.Pfn_gsm._data)]



    pfs_cd_mlat = [pfs_cd_mlat,result.Pfs_CD_MLAT._data]
    pfs_cd_mlon = [pfs_cd_mlon,result.Pfs_CD_MLON._data]
    pfs_cd_mlt = [pfs_cd_mlt,result.Pfs_CD_MLT._data]
    pfs_ed_mlat = [pfs_ed_mlat,result.Pfs_ED_MLAT._data]
    pfs_ed_mlon = [pfs_ed_mlon,result.Pfs_ED_MLON._data]
    pfs_ed_mlt = [pfs_ed_mlt,result.Pfs_ED_MLT._data]
    pfs_geo = [pfs_geo,transpose(result.Pfs_geo._data)]
    pfs_geod_height = [pfs_geod_height,result.Pfs_geod_Height._data]
    pfs_geod_latlon = [pfs_geod_latlon,transpose(result.Pfs_geod_LatLon._data)]
    pfs_gsm = [pfs_gsm,transpose(result.Pfs_gsm._data)]


  endfor



  ;Remove 0th element
  n = n_elements(Lshell)-1
  np = n_elements(perigeetimes)-1

  unixtime = unixtime[1:n]
  lstar = lstar[1:n,*]
  bgsm = bgsm[1:n,*]
  bmag = bmag[1:n]
  dipoletiltangle = dipoletiltangle[1:n]
  orbitnumber = orbitnumber[1:n]
  ed_mlat = ed_mlat[1:n]
  ed_mlon = ed_mlon[1:n]
  ed_mlt = ed_mlt[1:n]
  ed_r = ed_r[1:n]
  cd_mlat = cd_mlat[1:n]
  cd_mlon = cd_mlon[1:n]
  cd_mlt = cd_mlt[1:n]
  cd_r = cd_r[1:n]
  mlat_diff = mlat_diff[1:n]
  mlon_diff = mlon_diff[1:n]
  mlt_diff = mlt_diff[1:n]
  r_diff = r_diff[1:n]
  ;fieldlinetype_int = fieldlinetype_int[1:n]
  pos_gsm = pos_gsm[1:n,*]
  pos_gse = pos_gse[1:n,*]
  lshell = lshell[1:n]
  ;lvalue = lvalue[1:n]
  invlat = invlat[1:n]
  invlat_eq = invlat_eq[1:n]
  kp = kp[1:n]
  lc = lc[1:n,*]
  perigeetimes = perigeetimes[1:np]
  bfn_geo = bfn_geo[1:n,*]
  bfn_gsm = bfn_gsm[1:n,*]
  bfs_geo = bfs_geo[1:n,*]
  bfs_gsm = bfs_gsm[1:n,*]
  bmag_mirror = bmag_mirror[1:n,*]

  pfn_cd_mlat = pfn_cd_mlat[1:n]
  pfn_cd_mlon = pfn_cd_mlon[1:n]
  pfn_cd_mlt = pfn_cd_mlt[1:n]
  pfn_ed_mlat = pfn_ed_mlat[1:n]
  pfn_ed_mlon = pfn_ed_mlon[1:n]
  pfn_ed_mlt = pfn_ed_mlt[1:n]
  pfn_geo = pfn_geo[1:n,*]
  pfn_geod_height = pfn_geod_height[1:n]
  pfn_geod_latlon = pfn_geod_latlon[1:n,*]
  pfn_gsm = pfn_gsm[1:n,*]

  pfs_cd_mlat = pfs_cd_mlat[1:n]
  pfs_cd_mlon = pfs_cd_mlon[1:n]
  pfs_cd_mlt = pfs_cd_mlt[1:n]
  pfs_ed_mlat = pfs_ed_mlat[1:n]
  pfs_ed_mlon = pfs_ed_mlon[1:n]
  pfs_ed_mlt = pfs_ed_mlt[1:n]
  pfs_geo = pfs_geo[1:n,*]
  pfs_geod_height = pfs_geod_height[1:n]
  pfs_geod_latlon = pfs_geod_latlon[1:n,*]
  pfs_gsm = pfs_gsm[1:n,*]




  ;remove unrealistic values near perigee
  goo = where((lstar ge 1d10) or (lstar le -1d10))
  if goo[0] ne -1 then lstar[goo] = !values.f_nan
  store_data,'rbsp'+sc+'_ME_lstar',data={x:unixtime,y:lstar}


  ;units = result.bsc_gsm.units._data
  store_data,'rbsp'+sc+'_ME_bmag',data={x:unixtime,y:bmag}
  store_data,'rbsp'+sc+'_ME_bgsm',data={x:unixtime,y:bgsm}
  options,'rbsp'+sc+'_ME_bmag',ytitle='|B| nT'
  options,'rbsp'+sc+'_ME_bgsm',ytitle='Bgsm nT'

  ;tplot,['rbsp'+sc+'_ME_bmag','rbsp'+sc+'_ME_bgsm']


  store_data,'rbsp'+sc+'_ME_dipoletiltangle',data={x:unixtime,y:dipoletiltangle}
  options,'rbsp'+sc+'_ME_dipoletiltangle',ytitle='Dipole tilt angle (deg)'

  ;tplot,'rbsp'+sc+'_ME_dipoletiltangle'


  store_data,'rbsp'+sc+'_ME_orbitnumber',data={x:unixtime,y:orbitnumber}
  options,'rbsp'+sc+'_ME_orbitnumber',ytitle='Orbit number'

  ;tplot,'rbsp'+sc+'_ME_orbitnumber'


  store_data,'rbsp'+sc+'_ME_mlat_eccdipole',data={x:unixtime,y:ed_mlat}
  store_data,'rbsp'+sc+'_ME_mlon_eccdipole',data={x:unixtime,y:ed_mlon}
  store_data,'rbsp'+sc+'_ME_mlt_eccdipole',data={x:unixtime,y:ed_mlt}
  store_data,'rbsp'+sc+'_ME_r_eccdipole',data={x:unixtime,y:ed_r}
  options,'rbsp'+sc+'_ME_mlat_eccdipole',ytitle='MLAT (ecc dip) deg'
  options,'rbsp'+sc+'_ME_mlon_eccdipole',ytitle='MLON (ecc dip) deg'
  options,'rbsp'+sc+'_ME_mlt_eccdipole',ytitle='MLT (ecc dip) hours'
  options,'rbsp'+sc+'_ME_r_eccdipole',ytitle='R (ecc dip) RE'

  ;tplot,['rbsp'+sc+'_ME_mlat_eccdipole','rbsp'+sc+'_ME_mlon_eccdipole','rbsp'+sc+'_ME_mlt_eccdipole','rbsp'+sc+'_ME_r_eccdipole']



  store_data,'rbsp'+sc+'_ME_mlat_centereddipole',data={x:unixtime,y:ed_mlat}
  store_data,'rbsp'+sc+'_ME_mlon_centereddipole',data={x:unixtime,y:ed_mlon}
  store_data,'rbsp'+sc+'_ME_mlt_centereddipole',data={x:unixtime,y:ed_mlt}
  store_data,'rbsp'+sc+'_ME_r_centereddipole',data={x:unixtime,y:ed_r}
  options,'rbsp'+sc+'_ME_mlat_centereddipole',ytitle='MLAT (cent dip) deg'
  options,'rbsp'+sc+'_ME_mlon_centereddipole',ytitle='MLON (cent dip) deg'
  options,'rbsp'+sc+'_ME_mlt_centereddipole',ytitle='MLT (cent dip) hours'
  options,'rbsp'+sc+'_ME_r_centereddipole',ytitle='R (cent dip) RE'

  ;tplot,['rbsp'+sc+'_ME_mlat_centereddipole','rbsp'+sc+'_ME_mlon_centereddipole','rbsp'+sc+'_ME_mlt_centereddipole','rbsp'+sc+'_ME_r_centereddipole']



  store_data,'rbsp'+sc+'_ME_mlat_diff',data={x:unixtime,y:mlat_diff}
  store_data,'rbsp'+sc+'_ME_mlon_diff',data={x:unixtime,y:mlon_diff}
  store_data,'rbsp'+sc+'_ME_mlt_diff',data={x:unixtime,y:mlt_diff}
  store_data,'rbsp'+sc+'_ME_r_diff',data={x:unixtime,y:r_diff}
  options,'rbsp'+sc+'_ME_mlat_diff',ytitle='mlat centdip-mlat eccdip'
  options,'rbsp'+sc+'_ME_mlon_diff',ytitle='mlon centdip-mlon eccdip'
  options,'rbsp'+sc+'_ME_mlt_diff',ytitle='mlt centdip-mlt eccdip'
  options,'rbsp'+sc+'_ME_r_diff',ytitle='R centdip-R eccdip'

  ;tplot,['rbsp'+sc+'_ME_mlat_diff','rbsp'+sc+'_ME_mlon_diff','rbsp'+sc+'_ME_mlt_diff','rbsp'+sc+'_ME_r_diff']


  ;		store_data,'rbsp'+sc+'_ME_fieldlinetype',data={x:unixtime,y:fieldlinetype_int}
  ;		options,'rbsp'+sc+'_ME_fieldlinetype',ytitle='fieldlinetype:!C1=connected!C2=connected in N!C3=connected in S!C4=open both ends'
  ;		ylim,'rbsp'+sc+'_ME_fieldlinetype',0,5,0
  ;	;tplot,'rbsp'+sc+'_ME_fieldlinetype'



  store_data,'rbsp'+sc+'_ME_pos_gsm',data={x:unixtime,y:pos_gsm}
  store_data,'rbsp'+sc+'_ME_pos_gse',data={x:unixtime,y:pos_gse}
  store_data,'rbsp'+sc+'_ME_lshell',data={x:unixtime,y:lshell}
  ;store_data,'rbsp'+sc+'_ME_lvalue',data={x:unixtime,y:lvalue}
  store_data,'rbsp'+sc+'_ME_invlat',data={x:unixtime,y:invlat}
  store_data,'rbsp'+sc+'_ME_invlat_eq',data={x:unixtime,y:invlat_eq}
  options,'rbsp'+sc+'_ME_pos_gsm',ytitle='Pos GSM (RE)'
  options,'rbsp'+sc+'_ME_pos_gse',ytitle='Pos GSE (RE)'
  options,'rbsp'+sc+'_ME_lshell',ytitle='L shell'
  ;options,'rbsp'+sc+'_ME_lvalue',ytitle='L value'
  options,'rbsp'+sc+'_ME_invlat',ytitle='Inv lat (deg)'
  options,'rbsp'+sc+'_ME_invlat_eq',ytitle='Inv lat at eq (deg)'


  store_data,'rbsp'+sc+'_ME_Kp',data={x:unixtime,y:Kp}
  options,'rbsp'+sc+'_ME_Kp',ytitle='Kp index'
  ylim,'rbsp'+sc+'_ME_Kp',0,10,0

  ;tplot,['rbsp'+sc+'_ME_lshell','rbsp'+sc+'_ME_invlat','rbsp'+sc+'_ME_invlat_eq','rbsp'+sc+'_ME_Kp']



  store_data,'rbsp'+sc+'_ME_loss_cone_alpha',data={x:unixtime,y:lc}
  options,'rbsp'+sc+'_ME_loss_cone_alpha',ytitle='loss cone alpha!Cblack=N,red=S'
  ylim,'rbsp'+sc+'_ME_loss_cone_alpha',0,10,0



  store_data,'rbsp'+sc+'_ME_bfn_geo',data={x:unixtime,y:bfn_geo}
  store_data,'rbsp'+sc+'_ME_bfn_gsm',data={x:unixtime,y:bfn_gsm}
  store_data,'rbsp'+sc+'_ME_bfs_geo',data={x:unixtime,y:bfs_geo}
  store_data,'rbsp'+sc+'_ME_bfs_gsm',data={x:unixtime,y:bfs_gsm}

  options,'rbsp'+sc+'_ME_bfn_geo','ytitle','|B| at!CNorth footpoint!CGEO coord'
  options,'rbsp'+sc+'_ME_bfn_gsm','ytitle','|B| at!CNorth footpoint!CGSM coord'
  options,'rbsp'+sc+'_ME_bfs_geo','ytitle','|B| at!CSouth footpoint!CGEO coord'
  options,'rbsp'+sc+'_ME_bfs_gsm','ytitle','|B| at!CSouth footpoint!CGSM coord'

  ;tplot,['rbsp'+sc+'_ME_bfn_geo','rbsp'+sc+'_ME_bfn_gsm','rbsp'+sc+'_ME_bfs_geo','rbsp'+sc+'_ME_bfs_gsm']


  store_data,'rbsp'+sc+'_ME_pfn_cd_mlat',data={x:unixtime,y:pfn_cd_mlat}
  store_data,'rbsp'+sc+'_ME_pfn_cd_mlon',data={x:unixtime,y:pfn_cd_mlon}
  store_data,'rbsp'+sc+'_ME_pfn_cd_mlt',data={x:unixtime,y:pfn_cd_mlt}
  store_data,'rbsp'+sc+'_ME_pfn_ed_mlat',data={x:unixtime,y:pfn_ed_mlat}
  store_data,'rbsp'+sc+'_ME_pfn_ed_mlon',data={x:unixtime,y:pfn_ed_mlon}
  store_data,'rbsp'+sc+'_ME_pfn_ed_mlt',data={x:unixtime,y:pfn_ed_mlt}
  store_data,'rbsp'+sc+'_ME_pfn_geo',data={x:unixtime,y:pfn_geo}
  store_data,'rbsp'+sc+'_ME_pfn_geod_height',data={x:unixtime,y:pfn_geod_height}
  store_data,'rbsp'+sc+'_ME_pfn_geod_latlon',data={x:unixtime,y:pfn_geod_latlon}
  store_data,'rbsp'+sc+'_ME_pfn_gsm',data={x:unixtime,y:pfn_gsm}

  options,'rbsp'+sc+'_ME_pfn_cd_mlat','ytitle','Mlat!CNorth!Cfootpoint!Ccentered!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfn_cd_mlon','ytitle','Mlong!CNorth!Cfootpoint!Ccentered!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfn_cd_mlt','ytitle','MLT!CNorth!Cfootpoint!Ccentered!Cdipole!CHours'
  options,'rbsp'+sc+'_ME_pfn_ed_mlat','ytitle','Mlat!CNorth!Cfootpoint!Cecc!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfn_ed_mlon','ytitle','Mlong!CNorth!Cfootpoint!Cecc!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfn_ed_mlt','ytitle','MLT!CNorth!Cfootpoint!Cecc!Cdipole!CHours'
  options,'rbsp'+sc+'_ME_pfn_geo','ytitle','Location of!CNorth!Cfootpoint!CGEO!CRE'
  options,'rbsp'+sc+'_ME_pfn_geod_height','ytitle','Geodetic!CHeight!CNorth!Cfootpoint!Ckm'
  options,'rbsp'+sc+'_ME_pfn_geod_latlon','ytitle','Geodetic!Clat and lon!CNorth!Cfootpoint!Cdeg'
  options,'rbsp'+sc+'_ME_pfn_gsm','ytitle','Location of!CNorth!Cfootpoint!CGSM!CRE'

  ;tplot,['rbsp'+sc+'_ME_pfn_cd_mlat','rbsp'+sc+'_ME_pfn_cd_mlon','rbsp'+sc+'_ME_pfn_cd_mlt']
  ;tplot,['rbsp'+sc+'_ME_pfn_ed_mlat','rbsp'+sc+'_ME_pfn_ed_mlon','rbsp'+sc+'_ME_pfn_ed_mlt']
  ;tplot,['rbsp'+sc+'_ME_pfn_geo','rbsp'+sc+'_ME_pfn_geod_height','rbsp'+sc+'_ME_pfn_geod_latlon','rbsp'+sc+'_ME_pfn_gsm']


  store_data,'rbsp'+sc+'_ME_pfs_cd_mlat',data={x:unixtime,y:pfs_cd_mlat}
  store_data,'rbsp'+sc+'_ME_pfs_cd_mlon',data={x:unixtime,y:pfs_cd_mlon}
  store_data,'rbsp'+sc+'_ME_pfs_cd_mlt',data={x:unixtime,y:pfs_cd_mlt}
  store_data,'rbsp'+sc+'_ME_pfs_ed_mlat',data={x:unixtime,y:pfs_ed_mlat}
  store_data,'rbsp'+sc+'_ME_pfs_ed_mlon',data={x:unixtime,y:pfs_ed_mlon}
  store_data,'rbsp'+sc+'_ME_pfs_ed_mlt',data={x:unixtime,y:pfs_ed_mlt}
  store_data,'rbsp'+sc+'_ME_pfs_geo',data={x:unixtime,y:pfs_geo}
  store_data,'rbsp'+sc+'_ME_pfs_geod_height',data={x:unixtime,y:pfs_geod_height}
  store_data,'rbsp'+sc+'_ME_pfs_geod_latlon',data={x:unixtime,y:pfs_geod_latlon}
  store_data,'rbsp'+sc+'_ME_pfs_gsm',data={x:unixtime,y:pfs_gsm}


  options,'rbsp'+sc+'_ME_pfs_cd_mlat','ytitle','Mlat!CSouth!Cfootpoint!Ccentered!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfs_cd_mlon','ytitle','Mlong!CSouth!Cfootpoint!Ccentered!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfs_cd_mlt','ytitle','MLT!CSouth!Cfootpoint!Ccentered!Cdipole!CHours'
  options,'rbsp'+sc+'_ME_pfs_ed_mlat','ytitle','Mlat!CSouth!Cfootpoint!Cecc!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfs_ed_mlon','ytitle','Mlong!CSouth!Cfootpoint!Cecc!Cdipole!Cdeg'
  options,'rbsp'+sc+'_ME_pfs_ed_mlt','ytitle','MLT!CSouth!Cfootpoint!Cecc!Cdipole!CHours'
  options,'rbsp'+sc+'_ME_pfs_geo','ytitle','Location of!CSouth!Cfootpoint!CGEO!CRE'
  options,'rbsp'+sc+'_ME_pfs_geod_height','ytitle','Geodetic!CHeight!CSouth!Cfootpoint!Ckm'
  options,'rbsp'+sc+'_ME_pfs_geod_latlon','ytitle','Geodetic!Clat and lon!CSouth!Cfootpoint!Cdeg'
  options,'rbsp'+sc+'_ME_pfs_gsm','ytitle','Location of!CSouth!Cfootpoint!CGSM!CRE'

  ;tplot,['rbsp'+sc+'_ME_pfs_cd_mlat','rbsp'+sc+'_ME_pfs_cd_mlon','rbsp'+sc+'_ME_pfs_cd_mlt']
  ;tplot,['rbsp'+sc+'_ME_pfs_ed_mlat','rbsp'+sc+'_ME_pfs_ed_mlon','rbsp'+sc+'_ME_pfs_ed_mlt']
  ;tplot,['rbsp'+sc+'_ME_pfs_geo','rbsp'+sc+'_ME_pfs_geod_height','rbsp'+sc+'_ME_pfs_geod_latlon','rbsp'+sc+'_ME_pfs_gsm']


  if keyword_set(perigeetimes) then perigeetimes = time_string(perigeetimes)

end
