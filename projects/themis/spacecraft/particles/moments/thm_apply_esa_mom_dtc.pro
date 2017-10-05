;+
;NAME:
; thm_apply_esa_mom_dtc
;PURPOSE:
; Corrects ESA on-board moments for dead time. Note that this will
; apply the dead-time correction to all of the moments for the given
; probe and species.
;CALLING SEQUENCE:
; thm_apply_esa_mom_dtc, probe=probe, instrument=instrument,
;                        out_suffix=out_suffix,in_suffix=in_suffix
;INPUT:
; All via keyword
;OUTPUT:
; None explicit, a number of tplot variables are created.
;KEYWORDS:
; probe='a','b','c','d' or 'e'
; instrument='peim' or 'peem', similar in use to the 'instrument'
;            keyword for thm_part_moments
; use_esa_mode = 'f','r', or 'b', use this mode for the ESA data to get
;                the dead time correction, the default is 'f'
; out_suffix= a suffix to add to new tplot variables for the
;             moments. The default is the null string, so that
;             variables are overwritten.
; in_suffix= if set, only variables with this suffix will be
;            corrected, to avoid correcting variables that have been
;            loaded without corrections.
;HISTORY:
; 13-may-2011, jmm, jimm@ssl.berkeley.edu
; 27-may-2011, jmm, dropped save_esa_vars keywords, to avoid suffix
;              confusion, also passes out_suffix keyword through to
;              thm_esa_dtc4mom
; 9-aug-2011, jmm, added in_suffix keyword
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-04-30 15:28:49 -0700 (Thu, 30 Apr 2015) $
; $LastChangedRevision: 17458 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_apply_esa_mom_dtc.pro $
;-
Pro thm_apply_esa_mom_dtc,  probe = probe, instrument = instrument, $
                            out_suffix = out_suffix, $
                            in_suffix = in_suffix, $
                            use_esa_mode = use_esa_mode, $
                            _extra = _extra

  vprobes = ['a', 'b', 'c', 'd', 'e']
  If(keyword_set(probe)) Then Begin
    probes = ssl_check_valid_name(strlowcase(probe), vprobes, /include_all)
    If(is_string(probes) Eq 0) Then Begin
      dprint, 'No valid probe input: '+probe
      Return
    Endif
  Endif Else probes = vprobes
  vinstruments = ['peim', 'peem']
  If(keyword_set(instrument)) Then Begin
    instruments = ssl_check_valid_name(strlowcase(instrument), $
                                       vinstruments, /include_all)
    If(is_string(instruments) Eq 0) Then Begin
      dprint, 'No valid instrument input: '+instrument
      dprint, 'Use peim or peem'
      Return
    Endif
  Endif Else instruments = vinstruments
  species = strmid(instruments, 2, 1) ;i or e
  If(is_string(use_esa_mode)) Then Begin
    mode = strlowcase(strcompress(use_esa_mode, /remove_all))
  Endif Else mode = 'f'
  If(keyword_set(out_suffix)) Then osfx = out_suffix Else osfx = ''
  If(keyword_set(in_suffix)) Then isfx = in_suffix Else isfx = ''
;For each probe  
;  vv = ['density', 'flux', 'mftens', 'eflux', 'velocity', $
;        'ptens', 't3']          ;these are the moments with corrections
  vv = ['density', 'flux', 'mftens', 'eflux', 'velocity', $
        'ptens', 'ptot']       ;these are the moments in L1 files
  For j = 0, n_elements(probes)-1 Do Begin
    sc = probes[j] & thx = 'th'+sc
    init_dtc_vars = 0b
;For each species
    For i = 0, n_elements(instruments)-1 Do Begin
      For k = 0, n_elements(vv)-1 Do Begin
        mvk = thx+'_'+instruments[i]+'_'+vv[k]
        mvk_0 = tnames(mvk+'*'+isfx) ;for suffixes
        If(is_string(mvk_0) Eq 0) Then Begin
          dprint, 'No variable: '+mvk
        Endif Else Begin 
          For l = 0, n_elements(mvk_0)-1 Do Begin
            get_data, mvk_0[l], data = d, dlimits = dl, limits = al
;check the data_att for the 'dead_time_corrected' tag
            If(is_struct(dl)) Then Begin
              str_element, dl, 'data_att', data_att, success = yes_data_att
              If(yes_data_att) Then Begin
                str_element, data_att, 'dead_time_corrected', success = yes_dtc
              Endif Else yes_dtc = 0b
            Endif Else yes_dtc = 0b
;if uncorrected then correct it
            If(yes_dtc Eq 0) Then Begin
;Only call dtc4mom program once per probe, we do it here to avoid
;calling this for variables that have been corrected.
              If(~init_dtc_vars) Then Begin
                thm_esa_dtc4mom, probe = sc, out_suffix = out_suffix, $
                  use_esa_mode = use_esa_mode, _extra = _extra
                init_dtc_vars = 1b
              Endif
;here you now have dead time corrections, all that is needed it to
;interpolate the corrections and multiply by the appropriate variable
;data
              dtcvar = thx+'_pe'+species[i]+mode+'_'+vv[k]+'_dtc'+osfx
              dtc = data_cut(dtcvar, d.x)
              dydtc = d.y*dtc
              store_data, mvk_0[l]+osfx, data = {x:d.x, y:dydtc}, limits = al
;set data_att tag to avoid overcorrection
              If(is_struct(dl)) Then Begin
                If(yes_data_att Eq 0) Then data_att = {dead_time_corrected:1} $
                Else str_element, data_att, 'dead_time_corrected', 1, /add
                str_element, dl, 'data_att', data_att, /add
              Endif Else dl = {data_att:{dead_time_corrected:1}}
              store_data,  mvk_0[l]+osfx, dlimits = dl
            Endif; Else message, /info, 'Variable: '+mvk_0[l]+' Has already been corrected'
          Endfor
        Endelse
      Endfor
    Endfor
  Endfor
;If you're in the GUI, delete the dead time corrections and the
;delta_time variables for moment calculation
  If(xregistered('spd_gui') Ne 0) Then Begin
     store_data, 'th?_pe??_delta_time', /delete
     store_data, 'th?_pe??_*_dtc', /delete
  Endif
     
  Return
End

