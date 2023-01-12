;+
; PRO erg_load_pwe_efd
;
; The read program for Level-2 PWE/EFD data
; This program can run on IDL 8.0 or later version.
;
; :Keywords:
;   level: level of data products. Currently only 'l2' is acceptable.
;   datatype: types of data products. 'E_spin', 'pot', 'spec' are
;   acceptable. 
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
;   get_suuport_data: Set to load support data in CDF data files.
;   trange: Set a time range to load data explicitly for the specified
;           time range.
;   downloadonly: If set, data files are downloaded and the program
;                exits without generating tplot variables.
;   no_download: Set to prevent the program from searching in the
;                remote server for data files.
;   verbose:  Set to make some commands in this program verbose.
;   uname: user ID to be passed to the remote server for
;          authentication.
;   passwd: password to be passed to the remote server for
;           authentication.
;   band_width: return the band width of the variable "spectra".
;   ror: If set a string, rules of the road (RoR) for data products 
;        are displayed at your terminal.
;
; :Examples:
;   ERG> timespan, '2017-04-01'
;   ERG> erg_load_pwe_efd
;   ERG> erg_load_pwe_efd, datatype='E_spin'
;   ERG> erg_load_pwe_efd, datatype='spec', band_width=band_width
;
; :Authors:
;   Masafumi Shoji, ERG Science Center (E-mail: masafumi.shoji at
;   nagoya-u.jp)
;
; $LastChangedDate: 2023-01-11 10:09:14 -0800 (Wed, 11 Jan 2023) $
; $LastChangedRevision: 31399 $
; https://ergsc-local.isee.nagoya-u.ac.jp/svn/ergsc/trunk/erg/satellite/erg/pwe/erg_load_pwe_efd.pro $
;-



pro erg_load_pwe_efd, $
   datatype=datatype, coord=coord, level = level, $
   downloadonly=downloadonly, $
   no_download=no_download, $
   get_support_data=get_support_data, $
   verbose=verbose, $
   uname=uname, $
   passwd=passwd, $
   band_width=band_width, $
   ror=ror, $
   _extra=_extra  
  
  erg_init
  
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then begin
     no_download = 0
;     if ~keyword_set(uname) then begin
;        uname=''
;        read, uname, prompt='Enter username: '
;     endif
;
;     if ~keyword_set(passwd) then begin
;        passwd=''
;        read, passwd, prompt='Enter passwd: '
;     endif
  endif
  
  if ~keyword_set(level) then begin 
     level='l2'
  endif
  
  if isa(level, 'INT') then begin
     level=strcompress('l'+string(level), /remove_all)
  endif
  
  if ~keyword_set(datatype) then datatype='E_spin'
  
  case level of
     
     'l2': begin
        Lvl = 'L2'
        prefix='erg_pwe_efd_l2_'        
     end
     
     'l3': begin
        Lvl = 'L3'
        prefix='erg_pwe_efd_l3_'
     end
     
     else: begin
        dprint, 'Incorrect keyword setting: level'
        return
     end
     
  endcase
  
  case datatype of
     'E_spin': begin
        md='E_spin'
        component=['Eu','Ev','Eu1','Ev1','Eu2','Ev2']
        labels=['Ex', 'Ey']
        coord=''
     end
     'spin': begin
        md='E_spin'
        component=['Eu','Ev','Eu1','Ev1','Eu2','Ev2']
        labels=['Ex', 'Ey']
        coord=''
     end
     'spec': begin
        md='spec'
        coord=''
     end
     '64': begin
        mode='64Hz'
        md='E'+mode
        IF ~keyword_set(coord) THEN coord='dsi'
        component = ['Ex', 'Ey']
        IF coord EQ 'wpt' then component=['Eu', 'Ev']
        component = component +'_waveform'
        IF coord EQ 'dsi' then component = [component, 'Eu_offset'+'_'+mode, 'Ev_offset'+'_'+mode]
     end
     '256': begin
        mode='256Hz'
        md='E'+mode
        IF ~keyword_set(coord) THEN coord='dsi'
        component = ['Ex', 'Ey']
        IF coord EQ 'wpt' then component=['Eu', 'Ev']
        component = component +'_waveform'
        IF coord EQ 'dsi' then component = [component, 'Eu_offset'+'_'+mode, 'Ev_offset'+'_'+mode]
     end
     'pot': begin
        md='pot'
        coord=''
        component=['Vu1','Vu2','Vv1','Vv2']
     end
     'pot8Hz': begin
        md='pot8Hz'
        coord=''
        component=['Vu1','Vu2','Vv1','Vv2']
        component=component+'_waveform_8Hz'
     end

     'pot_burst': begin
        md='pot_burst'
        coord=''
        component=['Vu1','Vu2','Vv1','Vv2','Vave']
     end

     'E_burst': begin
        md='E_burst'
        IF ~KEYWORD_SET(coord) THEN coord='dsi'
        component= ['Ex', 'Ey']
        IF coord EQ 'wpt' then component=['Eu', 'Ev']
        component = component +'_waveform'
        IF coord EQ 'dsi' then component = [component,'Eu_offset', 'Ev_offset']
     end
     else: begin
        dprint, 'Incorrect keyword setting: datatype'
        return
     end

  endcase

  IF ~keyword_set(coord) THEN coord=''
  IF coord NE '' THEN coord='_'+coord
  IF ~keyword_set(datatype) THEN datatype=''
  IF coord NE '' THEN datatype='_'+datatype


  prefix = prefix+md+coord+'_'

  localdir=!erg.local_data_dir+'satellite/erg/pwe/efd/'+level+'/'+md+'/'
  remotedir=!erg.remote_data_dir+'satellite/erg/pwe/efd/'+level+'/'+md+'/'
  
  relfpathfmt= 'YYYY/'+'MM/' + 'erg_pwe_efd_'+level+'_'+md+coord+'_YYYYMMDD_v??_??.cdf'
  relfpaths=file_dailynames(file_format=relfpathfmt)

  files=spd_download(remote_file=relfpaths, remote_path= remotedir, local_path=localdir,no_download=no_download,$
                     _extra=source,authentication=2, url_username=uname, url_password=passwd, /last_version)


  filestest=file_test(files)  

  PRINT, relfpaths
  STOP

  if(total(filestest) ge 1) then begin
     datfiles=files[where(filestest eq 1)]
  endif else begin
     print, 'No file is loaded.'
     return
  endelse

  if keyword_set(downloadonly) then return
  cdf2tplot, file=datfiles, prefix=prefix, get_support_data=get_support_data
  
  if strcmp(md,'E_spin') then begin
     foreach elem, component do $
        options, prefix+elem+'_dsi', labels=labels, ytitle=elem+' vector in DSI', constant=0
     goto, gt0
  endif
  
  if strcmp(md,'pot') then begin
     foreach elem, component do $
        options, prefix+elem, labels=labels, ytitle=elem+' potential', constant=0
     goto, gt0
  endif
  
  
  if strcmp(md,'spec') then begin
     cdfi = cdf_load_vars(datfiles,varformat=varformat,var_type='support_data',/spdf_depend, $
                          varnames=varnames2,verbose=verbose,record=record, convert_int1_to_int2=convert_int1_to_int2, all=all)
     idx_bw=where(strmatch(cdfi.vars.name, 'band_width_*') eq 1)
     band_width=*cdfi.vars[idx_bw].dataptr
     
     
     zlim, 'erg_pwe_efd_l2_spec*', 1e-6, 1e-2, 1
     ylim, 'erg_pwe_efd_l2_spec_spectra', 0,220.5,0
     ylim, 'erg_pwe_efd_l2_spec_*',0,100,0
     
     options, 'erg_pwe_efd_l2_spec*', 'ysubtitle', '[Hz]'
     options, 'erg_pwe_efd_l2_spec*', 'ztitle','[mV^2/m^2/Hz]'
     
     goto, gt0

  endif





foreach elem, component do begin
   
   get_data, prefix+elem, data=data, dlim=dlim
   
   time1=data.x
   dt=data.v                    ;time offsets
     delta=time1[1]-time1[0]
     nt=n_elements(time1)

     ndt=n_elements(dt)
     
     ndata=nt*ndt

     time_new=dblarr(ndata)
     data_new=fltarr(ndata)

     for i=0, nt-1 do begin
        time_new[ndt*i:ndt*(i+1)-1]=time1[i]+dt[*]*1e-3
     endfor
     data_new = reform(transpose(data.y), ndata)


     store_data, prefix+elem, data={x:time_new, y:data_new}, dlim=dlim


  end

  gt0:

  ; storing data information
  erg_export_filever, datfiles

  ; view RoR on terminal
  gatt=cdf_var_atts(datfiles[0])

  print_str_maxlet, ' '
  print, '**********************************************************************'
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 80
  print, ''
  print, 'Information about ERG PWE EFD'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 80
  print, ''
  
  if keyword_set(ror) then begin
    print, 'Rules of the Road for ERG PWE EFD Data Use:'
    for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 80
    print, ''
    print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  endif else begin
    print, 'RoR of ERG project common: https://ergsc.isee.nagoya-u.ac.jp/data_info/rules_of_the_road.shtml.en'
    print, 'RoR of PWE/EFD: https://ergsc.isee.nagoya-u.ac.jp/mw/index.php/ErgSat/Pwe/Efd'
    print, 'To show the RoR, set "ror" keyword'
    print, 'Contact: erg_pwe_info at isee.nagoya-u.ac.jp'
  endelse

  print, '**********************************************************************'



END
