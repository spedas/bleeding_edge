;+
; PRO erg_load_lepe_pa
;
; The read program for Level-3 provisional LEP-e pitch angle data
;
; :Keywords:
;   varformat: If set a string with wildcards, only variables with
;              matching names are extrancted as tplot variables.
;   get_support_data: Set to load support data in CDF data files.
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
;   localdir: Set a local directory path to save data files in the
;             designated directory.
;   remotedir: Set a remote directory in the URL form where the
;              program will look for data files to download.
;   datafpath: If set a full file path of CDF file(s), then the
;              program loads data from the designated CDF file(s), ignoring any
;              other options specifying local/remote data paths.
;
; :Examples:
;  IDL> timespan,'2017-03-24'
;  IDL> erg_load_lepe_pa  ;
;
; :Authors:
;   Chae-Woo Jun, ERG Science Center (E-mail: chae-woo at isee.nagoya-u.ac.jp)
;   Tomo Hori, ERG Science Center (E-mail: tomo.hori at nagoya-u.jp)
;   Tzu-Fang Chang, ERG Science Center (E-mail: jocelyn at isee.nagoya-u.ac.jp)
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
; $LastChangedRevision: 29823 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/lepe/erg_load_lepe_pa.pro $
;-
pro erg_load_lepe_pa, $
  debug=debug, $
  varformat=varformat, $
  get_support_data=get_support_data, $
  trange=trange, $
  downloadonly=downloadonly, no_download=no_download, $
  verbose=verbose, $
  uname=uname, passwd=passwd, $
  localdir=localdir, $
  remotedir=remotedir, $
  datafpath=datafpath, $
   _extra=_extra

  ;;Initialize the user environmental variables for ERG
  erg_init

  ;;Arguments and keywords
  if ~keyword_set(debug) then debug = 0  ;; Turn off the debug mode unless keyword debug is set
  if ~keyword_set(downloadonly) then downloadonly = 0
  if ~keyword_set(no_download) then no_download = 0
  
  ;;Local and remote data file paths
  if ~keyword_set(localdir) then begin
    localdir = !erg.local_data_dir + 'satellite/erg/lepe/l3_prov/PA/'
  endif
  if ~keyword_set(remotedir) then begin
    remotedir = !erg.remote_data_dir + 'satellite/erg/lepe/l3pre/'
  endif

  if debug then print, 'localdir = '+localdir
  if debug then print, 'remotedir = '+localdir

  ;;Relative file path
  relfpathfmt = 'YYYY/MM/erg-lepe-pad-YYYYMMDD-000000-YYYYMMDD-240000-lut??-all-11.25deg.nc'
;
;  ;;Expand the wildcards for the designated time range
  relfpaths = file_dailynames(file_format=relfpathfmt, trange=trange, times=times)
  if debug then print, 'RELFPATHS: ', relfpaths

  ;;Download data files
  if keyword_set(datafpath) then datfiles = datafpath else begin
    datfiles = $
      spd_download( local_path=localdir $
      , remote_path=remotedir, remote_file=relfpaths $
      , no_download=no_download, /last_version $
      , url_username=uname, url_password=passwd $
      )
  endelse
  idx = where( file_test(datfiles), nfile )
  if nfile eq 0 then begin
    print, 'Cannot find any data file. Exit!'
    return
  endif
  datfiles = datfiles[idx] ;;Clip empty strings and non-existing files
  if keyword_set(downloadonly) then return ;;Stop here if downloadonly is set
  
  ; Read nCDF file
  ncdf_list, datfiles,vname=vnames,/variables
  ncdf_get, datfiles,vnames,result
  
  ; convert time for tplot
  time = result['time','value']
  t_info = result['time','attributes','units']
  unit_info = (strsplit(t_info,' ',/ext))[0]
  time_info = strsplit(t_info,' ',/ext)
  date_info = time_info[2]
  hms_info = time_info[3]
  st_time = time_double(date_info+'/'+hms_info) ; initial time
  time_arr = time+st_time

  ; load variables
  e_flux = transpose(result['eflux','value'])
  energy_arr =  result['energy','value']
  pa_arr = result['pa','value']

  ;;Read CDF files and generate tplot variables
  level = 'l3_prov'
  datatype = 'PA'
  prefix = 'erg_lepe_' + level + '_' + datatype + '_'
  append_array, vns, prefix+['energy','pitch_angle']
  for i = 0, n_elements(vns)-1 do begin
    case (i) of 
      0: begin ; energy channels
        n_chn = n_elements(energy_arr)
        for j = 0, n_chn -1 do begin
          vn = prefix+'energy_'+string(j+1, '(i02)')
          store_data, vn, data={x:time_arr, y:reform(e_flux[*,*,j]), v:pa_arr}, dlim={ylog:0, zlog:1, spec:1, ystyle:1, zstyle:1,$
            extend_y_edges:1,$ ;if this option is set, tplot only plots to bin center on the top and bottom of the specplot
            x_no_interp:1,y_no_interp:1,$ ;copied from original thm_part_getspec, don't think this is strictly necessary, since specplot interpolation is disabled by default
            minzlog:1,ytickformat:'pwr10tick',ztickformat:'pwr10tick', zticklen:-0.4}
          options, vn, ztitle='[eV/s-cm!U2!N-sr-eV]',ytitle='ERG LEP-e!CL3 prov. '+string(energy_arr[j],'(f8.1)')+' eV!CPitch angle [deg]', ztickformat='pwr10tick', extend_y_edges=1, $
            datagap=17., zticklen=-0.4
        endfor
        end
      1: begin ; Pitch angle-based flux spectrum
        n_chn = n_elements(pa_arr)
        for j = 0, n_chn -1 do begin
          vn = prefix+'pitchangle_'+string(j+1, '(i02)')
          store_data, vn, data={x:time_arr, y:reform(e_flux[*,j,*]), v:energy_arr},dlim={ylog:1, zlog:1, spec:1, ystyle:1, zstyle:1,$
            extend_y_edges:1,$ ;if this option is set, tplot only plots to bin center on the top and bottom of the specplot
            x_no_interp:1,y_no_interp:1,$ ;copied from original thm_part_getspec, don't think this is strictly necessary, since specplot interpolation is disabled by default
            minzlog:1,ytickformat:'pwr10tick',ztickformat:'pwr10tick', zticklen:-0.4}
          options, vn, ztitle='[eV/s-cm!U2!N-sr-eV]',ytitle='ERG LEP-e!CL3 prov. '+string(pa_arr[j],'(f7.3)')+' deg!CEnergy [eV]', ztickformat='pwr10tick', extend_y_edges=1, $
            datagap=17., zticklen=-0.4
        endfor
        end
    endcase
  endfor

  return
end
