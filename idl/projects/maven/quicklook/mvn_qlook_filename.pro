;+
;NAME:
; mvn_qlook_filename
;PURPOSE:
; Create s filename for a qlook plot
;CALLING SEQUENCE:
; filename = mvn_qlook_filename(intstrument, time_range, $
;                               date_only = date_only)
;INPUT:
; instrument = a string for the instrument, e.g., 'swia', 'swea',
;              etc...
; time_range = start and end times for the data
;OUTPUT:
; filename = a filename
; 'mvn_'+instrument+'_ql_'+date+start_hour+end_hour
;KEYWORDS:
; date_only =  if set, only put the start date in the filename
;HISTORY:
; jmm, 2013-06-05
;-
Function mvn_qlook_filename, instrument, time_range, date_only = date_only, $
                             alt_name = alt_name, file_version = file_version, $
                             level = level, descriptor = descriptor, _extra = _extra
  common mvn_qlook_init_private, init_done, sw_vsn

  trs = time_string(time_range, precision = -2, format=6)
  date = strmid(trs[0], 0, 8)
  yyyy = strmid(date, 0, 4)

  start_hour = strmid(trs[0], 8, 2)
  end_hour = strmid(trs[1], 8, 2)

;Obsolete date_only keyword
  date_only = 1b

  If(keyword_set(date_only)) Then date_ext = date $
  Else date_ext = date+'_'+start_hour+end_hour

  If(keyword_set(alt_name)) Then Begin
     sw_vsn_str = 'r'+string(sw_vsn, format='(i2.2)')
     If(keyword_set(level)) Then Begin
        If(is_string(level)) Then lvl = level $
        Else lvl = string(level, format='(i1.1)')
     Endif Else lvl = 'l2'
     If(keyword_set(descriptor)) Then desc = descriptor Else desc = 'gen'
     fname_proto = 'mvn_'+instrument+'_'+lvl+'_'+desc+'_'+date_ext+'_v??_'+sw_vsn_str+'.cdf'
     If(keyword_set(file_version)) Then Begin
        fv_str = 'v'+string(file_version, format='(i2.2)')
     Endif Else Begin
        rdir = root_data_dir()
        rel_path = 'maven/data/sci/'+instrument+'/'+lvl+'/'+yyyy+'/' ;(may need months and days in directory name)
        test4file = file_search(rdir+rel_path+fname_proto)
        If(~is_string(test4file)) Then fv_str = 'v00' Else Begin
           test4file = test4file[nfiles-1] ;last version
           vss = strpos(test4file, '_v', /reverse_search)
           If(vss[0] Ne -1) Then Begin
              vno = fix(strmid(test4file, vss[0]+2, 2))+1
              fv_str = 'v'+string(vno, format='(i2.2)')
           Endif Else fv_str = 'v00'
        Endelse
     Endelse
     fname = 'mvn_'+instrument+'_'+lvl+'_'+desc+'_'+date_ext+'_'+fv_str+'_'+sw_vsn_str
  Endif Else Begin
     If(instrument Eq 'l2') Then fname = 'mvn_pfp_'+instrument+'_'+date_ext $
     Else fname = 'mvn_'+instrument+'_ql_'+date_ext
  Endelse

  Return, fname
End

