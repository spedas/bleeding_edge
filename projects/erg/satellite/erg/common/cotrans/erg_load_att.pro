;+
; PRO/FUN
;
; :Description:
;    Describe the procedure.
;
; :Params:
; ${parameters}
;
; :Keywords:
; ${keywords}
;
; :Examples:
;
; :History:
; 2016/9/10: drafted
;
; :Author: Tomo Hori, ISEE (tomo.hori at nagoya-u.jp)
;
;   $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
;   $LastChangedRevision: 26838 $
;
;-
pro erg_load_att, dbg=dbg

  if undefined(dbg) then dbg = 0

  ;Initialize the user environmental variables for ERG data
  erg_init

  local_data_dir = !erg.local_data_dir + 'satellite/erg/att/txt/'
  ;remote_data_dir = !erg.remote_data_dir + 'satellite/erg/att/txt/'
  ;Temporarily hard-coded for training session in Tainan 201709, which should be reverted
  ;after the training.
  remote_data_dir = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/' + 'satellite/erg/att/txt/'
  relfpathformat = 'YYYYMMDD_v??.txt'
  relfp = file_dailynames( file_format=relfpathformat, /unique, times=times)
  relfpath = 'erg_att_l2_' + relfp

  files = spd_download( $
    remote_path = remote_data_dir, remote_file = relfpath, $
    local_path = local_data_dir )
  if dbg then print, 'data files: ', files
  if total(file_test(files)) eq 0 then begin
    print, 'the att file is not found in the local dir!'
    return
  endif

  ;Obtain the directory path where erg_load_att.pro and
  ;the save file for the template are located.
  tmpl_fpath = file_source_dirname() + '/tmpl_erg_att_l2.sav'
  restore, tmpl_fpath  ; A structure "tmpl" is restored

  ;Initialize
  unxt = ''
  sprate = '' & spphase = '' & izras = '' & izdec = ''
  gxras = '' & gxdec = '' & gzras = '' & gzdec = ''
  for i=0, n_elements(files)-1 do begin
    file = files[i]
    if ~file_test(file) then continue
    finfo = file_info(file)
    if finfo.size lt 1 then continue

    dat = read_ascii( file, template=tmpl_erg_att_l2 )

    append_array, unxt, time_double( dat.datestr )
    append_array, sprate, dat.sprate
    append_array, spphase, dat.spphase
    append_array, izras, dat.izras
    append_array, izdec, dat.izdec
    append_array, gxras, dat.gxras
    append_array, gxdec, dat.gxdec
    append_array, gzras, dat.gzras
    append_array, gzdec, dat.gzdec

  endfor


  ;Create tplot variables containing the att parameters
  prefix = 'erg_att_'
  coord = 'j2000'
  postfix = '' ; postfix = '_'+coord
  store_data, prefix+'sprate'+postfix, data={ x:unxt, y:sprate }
  store_data, prefix+'spphase'+postfix, data={ x:unxt, y:spphase }
  store_data, prefix+'izras'+postfix, data={ x:unxt, y:izras }
  store_data, prefix+'izdec'+postfix, data={ x:unxt, y:izdec }
  store_data, prefix+'gxras'+postfix, data={ x:unxt, y:gxras }
  store_data, prefix+'gxdec'+postfix, data={ x:unxt, y:gxdec }
  store_data, prefix+'gzras'+postfix, data={ x:unxt, y:gzras }
  store_data, prefix+'gzdec'+postfix, data={ x:unxt, y:gzdec }
  options, prefix+'*'+postfix, 'coord', coord

  options, prefix+'sprate'+postfix, ystyle=1

  return
end
