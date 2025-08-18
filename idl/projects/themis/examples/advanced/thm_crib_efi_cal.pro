;+
;Name:
;  thm_crib_efi_cal
;
;Purpose:
;  Allows comparison of calibrated, semi-calibrated and raw EFI data
;
;Calling Sequence:
;  thm_crib_efi_cal [,probe=probe]  [,datatype=datatype]
;                   [,date=date,] [,trange = trange]
;                   [/split_components]
;
;Input:
;  probe:  probe designation, e.g. 'a', 'b', 'c', 'd', 'e'
;  datatype:  efi datatype:  'eff', 'efp', 'efw'
;  trange:  two element time range
;  date:  date from which to load 1 day of data (alternative to trange)
;  split_components:  flag to split ouputs into separate tplot variables
; 
;Output:
;  No explicit output.
;  Tplot variables are created for the given probe, date and datatype:
;     th?_ef?_raw:            Raw data
;     th?_ef?_no_edc_offset:  Data in physical units with no EDC offsets 
;                             subtracted from the spin-plane components E12 and E34.
;     th?_ef?_calfile_edc_offset:  Data in physical units with EDC offsets 
;                                  obtained from the calibration file subtracted 
;                                  from the spin-plane components E12 and E34.
;     th?_ef?_full:  Data in physical units with spin-averaged EDC offsets 
;                    from the spin-plane components E12 and E34.
;
;Notes:
;  -Default inputs if not explicitly set:
;     probe = 'a'
;     date = '2010-01-01'
;     datatype = 'eff'
;
;HISTORY:
; 20-sep-2010, jmm, jimm@ssl.berkeley.edu
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2015-05-13 18:00:26 -0700 (Wed, 13 May 2015) $
; $LastChangedRevision: 17598 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_efi_cal.pro $
;-

Pro thm_crib_efi_cal, date = date, probe = probe, datatype = datatype, $
                      split_components = split_components, trange = trange, $
                      _extra = _extra


  ;Check inputs
  ;---------------------------------------

  ;time
  If(keyword_set(trange)) Then Begin
    tr = time_double(trange)
  Endif Else Begin
    If(keyword_set(date)) Then Begin
      tr = time_double(date)+[0.0d0, 86400.0d0]
    Endif Else tr = time_double('2010-01-01')+[0.0d0, 86400.0d0]
  Endelse

  ;probe
  If(keyword_set(probe)) Then sc = strlowcase(strcompress(/remove_all, probe[0])) $
  Else sc = 'a'
  ok =  where(sc Eq ['a', 'b', 'c', 'd', 'e'], nok)
  If(nok Eq 0) Then Begin
    message, /info, 'Bad probe: mut be one of a, b, c, d, e'
    Return
  Endif

  ;datatype
  If(keyword_set(datatype)) Then dt = strlowcase(strcompress(/remove_all, datatype[0])) $
  Else dt = 'eff'
  ok = where(dt Eq ['eff', 'efp', 'efw'], nok)
  If(nok Eq 0) Then Begin
    message, /info, 'Bad Datatype: must be one of efs, eff, efw'
    Return
  Endif


  ;Load data
  ;---------------------------------------

  ;Load data, use suffixes to denote the different stages of data:
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, type = 'raw', suffix = '_raw'
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, /no_edc_offset, suffix = '_no_edc_offset'
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, /calfile_edc_offset, suffix = '_calfile_edc_offset'

  ;For comparison sake, set the output coordinate system to 'spg'
  thm_load_efi, probe = sc[0], datatype = dt[0], trange = tr, coord = 'spg', suffix = '_full'

  ;print out an explanation
  thxv = 'th'+sc[0]+'_'+dt[0]

  print, ssl_newline()
  print, 'Outputs:  '
  print, 'Variable: '+thxv+'_raw contains raw data'
  print, 'Variable: '+thxv+'_no_edc_offset contains data in physical units with no EDC offsets subtracted from the spin-plane components E12 and E34.'
  print, 'Variable: '+thxv+'_calfile_edc_offset contains data in physical units with EDC offsets obtained from the calibration file subtracted from the spin-plane components E12 and E34.'
  print, 'Variable: '+thxv+'_full contains data in physical units with spin-averaged EDC offsets from the spin-plane components E12 and E34.'
  print, ssl_newline()

  If(keyword_set(split_components)) Then Begin
    split_vec, thxv+'_raw'
    split_vec, thxv+'_no_edc_offset'
    split_vec, thxv+'_calfile_edc_offset'
    split_vec, thxv+'_full'
  Endif

  Return

End


