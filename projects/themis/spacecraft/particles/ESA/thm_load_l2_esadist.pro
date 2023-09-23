; Helper function for file relpath
Function thm_load_l2_esadist_relpath, probe = probe, filetype = ft, $
                               trange=trange, _extra=_extra

  relpath = 'th'+probe+'/l2/esd/'
  prefix = 'th'+probe+'_l2_esa_'+ft+'_'
  dir = 'YYYY/'
  ending = '_v01.cdf'

  Return, file_dailynames(relpath, prefix, ending, dir = dir, trange = trange)
End


;Helper function to load one data type at a time
Pro thm_load_l2_esadist_type, probe, type, trange = trange, $
                         no_time_clip = no_time_clip, _extra = _extra

;Here we are loading one type
  type = strlowcase(strcompress(/remove_all, type[0]))
;handle time range
  tr0 = timerange(trange)
;relpath
  relpathnames = thm_load_l2_esadist_relpath(probe = probe, filetype = type, trange = tr0)
;Download if necessary
  filex = spd_download(remote_file = relpathnames,_extra = !themis)
;Only files that exist here
  filex = file_search(filex)
  If(~is_string(filex)) Then Begin
     dprint, 'No files found for time range and type:'+type
     dprint, '!themis.local_data_dir: '+!themis.local_data_dir
     dprint, 'relpathname: '+relpathnames
     Return
  Endif
;Only unique files here
  filex_u = filex[bsort(filex)]
  filex = filex_u[uniq(filex_u)]
;Ok, load the files
  nfiles = n_elements(filex)
  dat = -1
  ck = 0
  For j = 0, nfiles-1 Do Begin
     If(ck Eq 0) Then Begin     ;only load attributes for the first file
        datj = thm_esa_cmn_l2read(filex[j], cmn_att = vatt, gatt = gatt)
     Endif Else datj = thm_esa_cmn_l2read(filex[j])
     If(is_struct(datj)) Then Begin
        ck++
        If(~is_struct(dat)) Then dat = temporary(datj) $
        Else dat = thm_esa_cmn_l2concat(temporary(dat), temporary(datj))
     Endif
  Endfor
;Here load magf and sc_pot, from L2 file
  ntimes = n_elements(dat.time)
  thm_load_esa, probe = probe[0], level ='l2', datatype = '*'+type+['*magf', '*sc_pot'], /no_time_clip, trange = tr0
  get_data, 'th'+probe[0]+'_'+type+'_sc_pot', data = p
  If(is_struct(p) && n_elements(p.x) Eq ntimes) Then Begin
     dp = p.y
  Endif Else dp = fltarr(ntimes)
  str_element, dat, 'sc_pot', dp, /add_replace
  get_data, 'th'+probe[0]+'_'+type+'_magf', data = b
  If(is_struct(b) && n_elements(b.x) Eq ntimes) Then Begin
     db = b.y
  Endif Else dp = fltarr(ntimes, 3)
  str_element, dat, 'magf', db, /add_replace
;Check time range
  If(~keyword_set(no_time_clip)) Then Begin
     If(is_struct(dat)) Then dat = thm_esa_cmn_l2tclip(dat, tr0) $
     Else Begin
        dprint, 'No data for type: '+type
     Endelse
  Endif

;Which type, and what probe?
  If(probe[0] Eq 'a') Then Begin
     Case type of
        'peif': Begin
           common tha_peif_l2, tha_peif_ind, tha_peif_dat, tha_peif_vatt
           tha_peif_dat = dat & tha_peif_ind = 0L & tha_peif_vatt = vatt
        End
        'peir': Begin
           common tha_peir_l2, tha_peir_ind, tha_peir_dat, tha_peir_vatt
           tha_peir_dat = dat & tha_peir_ind = 0L & tha_peir_vatt = vatt
        End
        'peib': Begin
           common tha_peib_l2, tha_peib_ind, tha_peib_dat, tha_peib_vatt
           tha_peib_dat = dat & tha_peib_ind = 0L & tha_peib_vatt = vatt
        End
        'peef': Begin
           common tha_peef_l2, tha_peef_ind, tha_peef_dat, tha_peef_vatt
           tha_peef_dat = dat & tha_peef_ind = 0L & tha_peef_vatt = vatt
        End
        'peer': Begin
           common tha_peer_l2, tha_peer_ind, tha_peer_dat, tha_peer_vatt
           tha_peer_dat = dat & tha_peer_ind = 0L & tha_peer_vatt = vatt
        End
        'peeb': Begin
           common tha_peeb_l2, tha_peeb_ind, tha_peeb_dat, tha_peeb_vatt
           tha_peeb_dat = dat & tha_peeb_ind = 0L & tha_peeb_vatt = vatt
        End
     Endcase
  Endif Else If(probe[0] Eq 'b') Then Begin
     Case type of
        'peif': Begin
           common thb_peif_l2, thb_peif_ind, thb_peif_dat, thb_peif_vatt
           thb_peif_dat = dat & thb_peif_ind = 0L & thb_peif_vatt = vatt
        End
        'peir': Begin
           common thb_peir_l2, thb_peir_ind, thb_peir_dat, thb_peir_vatt
           thb_peir_dat = dat & thb_peir_ind = 0L & thb_peir_vatt = vatt
        End
        'peib': Begin
           common thb_peib_l2, thb_peib_ind, thb_peib_dat, thb_peib_vatt
           thb_peib_dat = dat & thb_peib_ind = 0L & thb_peib_vatt = vatt
        End
        'peef': Begin
           common thb_peef_l2, thb_peef_ind, thb_peef_dat, thb_peef_vatt
           thb_peef_dat = dat & thb_peef_ind = 0L & thb_peef_vatt = vatt
        End
        'peer': Begin
           common thb_peer_l2, thb_peer_ind, thb_peer_dat, thb_peer_vatt
           thb_peer_dat = dat & thb_peer_ind = 0L & thb_peer_vatt = vatt
        End
        'peeb': Begin
           common thb_peeb_l2, thb_peeb_ind, thb_peeb_dat, thb_peeb_vatt
           thb_peeb_dat = dat & thb_peeb_ind = 0L & thb_peeb_vatt = vatt
        End
     Endcase
  Endif Else If(probe[0] Eq 'c') Then Begin
     Case type of
        'peif': Begin
           common thc_peif_l2, thc_peif_ind, thc_peif_dat, thc_peif_vatt
           thc_peif_dat = dat & thc_peif_ind = 0L & thc_peif_vatt = vatt
        End
        'peir': Begin
           common thc_peir_l2, thc_peir_ind, thc_peir_dat, thc_peir_vatt
           thc_peir_dat = dat & thc_peir_ind = 0L & thc_peir_vatt = vatt
        End
        'peib': Begin
           common thc_peib_l2, thc_peib_ind, thc_peib_dat, thc_peib_vatt
           thc_peib_dat = dat & thc_peib_ind = 0L & thc_peib_vatt = vatt
        End
        'peef': Begin
           common thc_peef_l2, thc_peef_ind, thc_peef_dat, thc_peef_vatt
           thc_peef_dat = dat & thc_peef_ind = 0L & thc_peef_vatt = vatt
        End
        'peer': Begin
           common thc_peer_l2, thc_peer_ind, thc_peer_dat, thc_peer_vatt
           thc_peer_dat = dat & thc_peer_ind = 0L & thc_peer_vatt = vatt
        End
        'peeb': Begin
           common thc_peeb_l2, thc_peeb_ind, thc_peeb_dat, thc_peeb_vatt
           thc_peeb_dat = dat & thc_peeb_ind = 0L & thc_peeb_vatt = vatt
        End
     Endcase
  Endif Else If(probe[0] Eq 'd') Then Begin
     Case type of
        'peif': Begin
           common thd_peif_l2, thd_peif_ind, thd_peif_dat, thd_peif_vatt
           thd_peif_dat = dat & thd_peif_ind = 0L & thd_peif_vatt = vatt
        End
        'peir': Begin
           common thd_peir_l2, thd_peir_ind, thd_peir_dat, thd_peir_vatt
           thd_peir_dat = dat & thd_peir_ind = 0L & thd_peir_vatt = vatt
        End
        'peib': Begin
           common thd_peib_l2, thd_peib_ind, thd_peib_dat, thd_peib_vatt
           thd_peib_dat = dat & thd_peib_ind = 0L & thd_peib_vatt = vatt
        End
        'peef': Begin
           common thd_peef_l2, thd_peef_ind, thd_peef_dat, thd_peef_vatt
           thd_peef_dat = dat & thd_peef_ind = 0L & thd_peef_vatt = vatt
        End
        'peer': Begin
           common thd_peer_l2, thd_peer_ind, thd_peer_dat, thd_peer_vatt
           thd_peer_dat = dat & thd_peer_ind = 0L & thd_peer_vatt = vatt
        End
        'peeb': Begin
           common thd_peeb_l2, thd_peeb_ind, thd_peeb_dat, thd_peeb_vatt
           thd_peeb_dat = dat & thd_peeb_ind = 0L & thd_peeb_vatt = vatt
        End
     Endcase
  Endif Else If(probe[0] Eq 'e') Then Begin
     Case type of
        'peif': Begin
           common the_peif_l2, the_peif_ind, the_peif_dat, the_peif_vatt
           the_peif_dat = dat & the_peif_ind = 0L & the_peif_vatt = vatt
        End
        'peir': Begin
           common the_peir_l2, the_peir_ind, the_peir_dat, the_peir_vatt
           the_peir_dat = dat & the_peir_ind = 0L & the_peir_vatt = vatt
        End
        'peib': Begin
           common the_peib_l2, the_peib_ind, the_peib_dat, the_peib_vatt
           the_peib_dat = dat & the_peib_ind = 0L & the_peib_vatt = vatt
        End
        'peef': Begin
           common the_peef_l2, the_peef_ind, the_peef_dat, the_peef_vatt
           the_peef_dat = dat & the_peef_ind = 0L & the_peef_vatt = vatt
        End
        'peer': Begin
           common the_peer_l2, the_peer_ind, the_peer_dat, the_peer_vatt
           the_peer_dat = dat & the_peer_ind = 0L & the_peer_vatt = vatt
        End
        'peeb': Begin
           common the_peeb_l2, the_peeb_ind, the_peeb_dat, the_peeb_vatt
           the_peeb_dat = dat & the_peeb_ind = 0L & the_peeb_vatt = vatt
        End
     Endcase
  Endif Else dprint, dlevel=2, 'Invalid probe: '+probe
  Return
End

;+
;NAME:
; thm_load_l2_esadist
;PURPOSE:
; Loads THEMIS ESA L2 data for a given file(s), or time_range
;CALLING SEQUENCE:
; thm_load_l2_esadist, trange=trange, datatype=datatype
;INPUT:
; All via keyword, if none are set, then the output of timerange() is
; used for the time range, which may prompt for a time interval
;KEYWORDS:
; probe = ['a', 'b', 'c', 'd', 'e'] is the default
; datatype = ['peif', 'peir', 'peib', 'peef', 'peer', 'peeb'] is the default
; trange = read in the data from this time range, note that if both
;          files and time range are set, files, and orbits take precedence in
;          finding files.
; no_time_clip = if set do not clip the data to the time range. The
;                trange is only used for file selection. Note that
;                setting no_time_clip will always generate a reload of
;                data
;OUTPUT:
; No variables, data are loaded into common blocks
;HISTORY:
; 7-nov-2022, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2023-09-19 14:54:55 -0700 (Tue, 19 Sep 2023) $
; $LastChangedRevision: 32106 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_load_l2_esadist.pro $
;-
Pro thm_load_l2_esadist, probe = probe, datatype = datatype, $
   trange = trange, no_time_clip = no_time_clip, _extra = _extra

;thm_init, initializes a system variable
  thm_init

;probe
  vprobe = ['a', 'b', 'c', 'd', 'e']
  If(keyword_set(probe)) Then Begin
     probe = ssl_check_valid_name(strlowcase(probe), vprobe, /include_all)
     If(~is_string(probe)) Then Return
  Endif Else probe = vprobe
;datatype
  vdatatype = ['peif', 'peir', 'peib', 'peef', 'peer', 'peeb']
  If(keyword_set(datatype)) Then Begin
     datatype = ssl_check_valid_name(strlowcase(datatype), datatype, /include_all)
  Endif Else datatype = vdatatype
  For k = 0, n_elements(probe)-1 Do Begin
     For j = 0, n_elements(datatype)-1 Do Begin
        thm_load_l2_esadist_type, probe[k], datatype[j], $
           trange = trange, no_time_clip = no_time_clip, _extra = _extra
     Endfor
  Endfor
  Return
End

