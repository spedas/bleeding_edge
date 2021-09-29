;+
; Procedure: bas_load_data
;
; Keywords:
;             sites:         list of sites user wants to load into tplot 
;             trange:        time range of interest [starttime, endtime] with the format
;                            ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                            ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;             datatype:      type of bas data to be loaded (Is this needed?)
;             suffix:        String to append to the end of the loaded tplot variables
;             prefix:        String to append to the beginning of the loaded tplot variables
;             /downloadonly: Download the file but don't read it (not implemented yet)
;             /noupdate:     Don't download if file exists (not implemented, need to test when
;                            two tvars are requested)
;             /nodownload:   Don't download - use only local files (not implemented)
;             verbose:       controls amount of error/information messages displayed
;             /valid_names:  get list of BAS sites
;
; EXAMPLE:
;   bas_load_data, site='ssss', trange=['2021-01-03','2021-01-04']
;
; NOTE:
; - Need to add No Update and No clobber
; - Need to correctly handle time clip
; - Add all standard tplot options
; - If no files downloaded notify user
;
; $LastChangedBy: clrusell $
; $LastChangedDate: 2017-02-13 15:32:14 -0800 (Mon, 13 Feb 2017) $
; $LastChangedRevision: 22769 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/bas/bas_load_data.pro $
;-

pro bas_load_data, site=site, trange = trange, suffix = suffix, prefix = prefix, $
  downloadonly = downloadonly, no_update = no_update, no_download = no_download, $
  verbose = verbose, valid_names = valid_names

  compile_opt idl2

  ; handle possible server errors
  catch, errstats
  if errstats ne 0 then begin
    dprint, dlevel=1, 'Error: ', !ERROR_STATE.MSG
    catch, /cancel
    return
  endif

  ; initialize variables and parameters
  defsysv, '!bas', exists=exists
  if not(exists) then bas_init
  if undefined(suffix) then suffix = ''
  if undefined(prefix) then prefix = ''
  if not keyword_set(source) then source = !bas
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  if keyword_set(valid_names) then valid_names=1 else valid_names=0
  if keyword_set(no_download) then no_download=1 else no_download=0
  
  ; maintain a list of valid site names 
  site_names = ['M65-297','M66-294','M67-292','M78-337','M79-336','M81-003','M81-338', $
                'M83-347','M83-348','M84-336','M85-002','M85-096','M87-028','M87-068','M88-316']

  ; if user just requested the list of valid sites then return the site array
  if keyword_set(valid_names) then begin
    valid_names = site_names
    return
  endif

  ; loop for each site
  for j = 0, n_elements(site)-1 do begin

    ; check for valid site names
    idx = where(site[j] EQ site_names, nsite)
    if nsite LE 0 then begin
      print, 'Invalid BAS site name'
      print, 'Valid sites include: '
      print, site_names
      return
    endif

    ; BAS download data
    tstruct=time_struct(tr[0])
    year4=strtrim(string(tstruct.year),1)
    year2=strmid(year4,2,2)
    doy=strtrim(string(tstruct.doy),1)

    ; EXAMPLE FILE M85-096-2015.lpm.dg4.18.001.txt
    if tstruct.doy lt 100 and tstruct.doy ge 10 then doy='0'+doy   
    if tstruct.doy lt 10 then doy='00'+doy
    remote_path = !bas.remote_data_dir + site[j] + '/' + year4 + '/data/proc/Revision1.0/ascii/daily/00000/'
    local_path =  !bas.local_data_dir + site[j] + '/' + year4 + '/'

    filename=''
    filename=bas_get_filename(site=site[j], year=year2, doy=doy)
    if filename eq '' then begin
      print, 'There is no BAS data for BAS site '+site[j]+' on '+year4+'/'+doy
      return
    endif

    ;filename=site[j] + '-' + year4 + '.lpm.dg4.' + year2 + '.' + doy + '.txt'
    ;http://psddb.nerc-bas.ac.uk/data/psddata/atmos/space/lpm/
    ;M73-159//2008/data/proc/Revision1.0/ascii/daily/00000/M73-159-2008.lpm.dg4.08.072.txt    
    
    if strlowcase(!version.os_family) eq 'windows' then local_path = strjoin(strsplit(local_path, '/', /extract), path_sep())
    local_path = spd_addslash(local_path)

    paths = ''
    ; download data as long as no flags are set
    if no_download eq 0 then begin
      if file_test(local_path,/dir) eq 0 then file_mkdir2, local_path
      dprint, dlevel=1, 'Downloading ' + filename + ' to ' + local_path
      paths = spd_download(remote_file=filename, remote_path=remote_path, $
        local_file=filename, local_path=local_path, ssl_verify_peer=1, ssl_verify_host=1)
      if undefined(paths) or paths EQ '' then dprint, devel=1, 'Unable to download ' + filename 
    endif

    ; if remote file not found or no_download set then look for local copy
    if paths EQ '' OR no_download NE 0 then begin
      full_filename=local_path+filename
      if file_test(full_filename) eq 0 then begin
         dprint, devel=1, 'Unable to find local file ' + full_filename
         return
      endif; get all files from the beginning of the first day
    endif else begin
      full_filename=paths[0]
    endelse
       
    ; read the BAS data file
    undefine, bas_data
    bas_data = bas_read_data(full_filename)

    if size(bas_data,/type) eq 8 then begin
      tvar_name = 'thm_mag_'+site
      store_data, tvar_name, data=bas_data
      options, tvar_name, colors=[2,4,5]
      options, tvar_name, labels=['H','D','Z']
      options, tvar_name, lab_flag=1
      options, tvar_name, ysubtitle='B (nT)'
      options, tvar_name, ytitle=site
    endif else begin
      print, 'No BAS data found for site '+strlowcase(site[j])+' on '+time_string(trange[0])
      continue
    endelse

  endfor
  
end