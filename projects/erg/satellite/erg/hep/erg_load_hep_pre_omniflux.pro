;+
; PRO erg_load_hep_pre_omniflux
;
; :Description:
;    Read HEP provisional CDF files and load the data as tplot variables.
;
;:Params:
;
;:Keywords:
; files: CDF file path(s) if given explicitly 
; div_dene: If set, the counts in FEDO_L and FEDO_H are divided by energy ranges. 
;            The resultant values are in count/sample/keV. 
; lineplot: Set to generate tplot variables for broken line plots of FEDO_L/H.  
; uname: a string containing the user ID to acccess the data repository
; passwd: a string containing the password to access the data repository
; 
;:History:
; 2017/06/14:
;
;:Author:
; Tomo Hori, ERG Science Center ( E-mail: tomo.hori _at_ nagoya-u.jp )
;
; Written by: T. Hori
;   $LastChangedDate: 2021-03-25 13:26:37 -0700 (Thu, 25 Mar 2021) $
;   $LastChangedRevision: 29823 $
;-
pro erg_load_hep_pre_omniflux, files=files, $
  div_dene=div_dene, lineplot=lineplot, $
  uname=uname, passwd=passwd, no_download=no_download

  ;Initialize
  erg_init


  if ~keyword_set(files) then begin
    datfformat = 'YYYY/erg_hep_pre_omniflux_YYYYMMDD_v01.cdf'
    relfnames = file_dailynames( file_format=datfformat, /unique, times=times)


    localdir = !erg.local_data_dir + 'satellite/erg/hep/l2pre/omni/'

    if keyword_set(uname) and keyword_set(passwd) then $
      uidpass = uname + ':' + passwd + '@' else uidpass = ''

    ;remotedir = 'https://' + uidpass $
    ;  + 'ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg/hep/l2pre/omni/'
    remotedir = !erg.remote_data_dir + 'satellite/erg/hep/l2pre/omni/'

    files = spd_download( local_path=localdir, local_file=relfnames, $
      remote_path=remotedir, remote_file=relfnames, $
      no_download=no_download, no_update=no_update, $
      authentication=2, url_username=uname, url_password=passwd )

  endif

  ;Check if data files given exist
  idx = where( file_test(files), n )
  if n eq 0 then begin
    print, 'Cannot find prov. CDF files!'
    return
  endif
  files = files[idx]


  ;Load the data and convert to tplot variables
  prefix = 'erg_hep_pre_'
  cdf2tplot, file=files, varformat='*', prefix=prefix

  if strlen(tnames(prefix+'FEDO_L')) lt 1 then begin
    print, 'Tplot variables have not been loaded with unknown reason(s).'
    print, 'Program exited.'
    return
  endif


  ;Modify tplot variables so that they are plotted by simple tplot command
  for i=0, 1 do begin
    case (i) of
      0: begin
        suf = 'L'
        enerng = [ 70., 1800. ]
      end
      1: begin
        suf = 'H'
        enerng = [ 500., 2048. ]
      end
    endcase

    if tnames(prefix+'FEDO_'+suf) eq '' then continue
    options, prefix+'FEDO_'+suf, no_interp=1
    get_data, prefix+'FEDO_'+suf, data=d, dl=dl, lim=lim

    enecntr = 10^( total( alog10(d.v), 1 )/2 ) ;log average of energy bins
    dene = reform( d.v[1,*]-d.v[0,*] )
    ene_vvals = enecntr
    for j=0, n_elements(ene_vvals)-1 do begin
      if j eq 0 then begin
        ene_vvals[j] = 10.^( total( alog10(d.v[*,0]) )/2 )
        continue
      endif
      prev_vvals = ene_vvals[j-1]
      ebin_low = reform( d.v[0,j] )
      ene_vvals[j] = 10.^( alog10(ebin_low) + alog10(ebin_low)-alog10(prev_vvals) )

    endfor

    dene_mat = replicate( 1, n_elements(d.x) ) # transpose(dene)
    if keyword_set(div_dene) then omnicnt = d.y / dene_mat else omnicnt = d.y
    store_data, prefix+'FEDO_'+suf, data={x:d.x, y:omnicnt, v:ene_vvals}, dl=dl, lim=lim

    ztitle = keyword_set(div_dene) ? 'omni cnt!C[cnt/sample/keV]' : 'omni cnt!C[cnt/sample]'
    options, prefix+'FEDO_'+suf, $
      spec=1, ystyle=1, ytitle='HEP-'+suf+'!Cprov.!CEnergy', ysubtitle='[keV]', $
      ztitle=ztitle, zticklen=-0.4, zlog=1, ztickformat='pwr10tick', $
      labels=string(fix(enecntr),'(I4)')+' keV', labflag=-1
    ylim, prefix+'FEDO_'+suf, enerng[0], enerng[1], 1
    zlim, prefix+'FEDO_'+suf, 0, 0, 1
    tdegap, prefix+'FEDO_'+suf, /over

    ;Generate tplot vars for plotting with broken lines
    if keyword_set(lineplot) then begin
      copy_data, prefix+'FEDO_'+suf, prefix+'FEDO_'+suf+'_line'
      options, prefix+'FEDO_'+suf+'_line', $
        ytitle='HEP-'+suf,ysubtitle=ztitle,ytickformat='pwr10tick',spec=0
      ylim, prefix+'FEDO_'+suf+'_line', 0, 0, 1
    endif


  endfor


  ;--- print PI info and rules of the road
  gatt=cdf_var_atts(files[0])

  print_str_maxlet, ' '
  print, '**********************************************************************'
  print, gatt.PROJECT
  print_str_maxlet, gatt.LOGICAL_SOURCE_DESCRIPTION, 70
  print, ''
  print, 'Information about ERG HEP'
  print, ''
  print, 'PI: ', gatt.PI_NAME
  print_str_maxlet, 'Affiliation: '+gatt.PI_AFFILIATION, 70
  print, ''
  for igatt=0, n_elements(gatt.RULES_OF_USE)-1 do print_str_maxlet, gatt.RULES_OF_USE[igatt], 70
  print, ''
  print, gatt.LINK_TEXT, ' ', gatt.HTTP_LINK
  print, '**********************************************************************'
  print, ''


  return
end
