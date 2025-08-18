;+
; PROCEDURE:
;         elf_epd_l2_postproc
;
; PURPOSE:
;         This routines sets the limits and data limits
;
; KEYWORDS:
;         probes:       probe name 'a' or 'b', default is 'a'
;         tplotnames:   list of tplot names
;
; NOTES:  This routine is called when loading epd level 2 data
;
;$LastChangedBy: clrussell $
;$LastChangedDate: 2018-12-06 11:58:25 -0700 (Mon, 06 Aug 2018) $
;$LastChangedRevision: 25588 $
;-
pro elf_epd_l2_postproc, tplotnames, probes=probes

  sclet='el'+probes
  
  energies = [63.2455,97.9796,138.564,183.303,238.118,305.205,385.162,520.48, $
              752.994,1081.67,1529.71,2121.32,2893.96,3728.61,4906.12,6500.0]

  ; Et_nflux
  get_data, sclet+'_pef_Et_nflux', data=d, dlimits=dl, limits=l
  newd={x:d.x, y:d.y, v:energies}
  l = {ylog: 1, spec: 0, labflag: 1, yrange: [1., 1.], ystyle: 0}
  dl = {spec: 0, log: 0, ysubtitle: '#/(scm!U2!NstrMeV)'}
  store_data, sclet+'_pef_Et_nflux', data=newd, dlimits=dl, limits=l
  options, sclet+'_pef_Et_nflux', charsize=.9
  options, sclet+'_pef_Et_nflux', 'ztitle','nflux'
  zlim, sclet+'_pef_Et_nflux', 1.e1, 2.e7
  options, sclet+'_pef_Et_nflux',zstyle=1
  options, sclet+'_pef_Et_nflux','extend_edges',1
  
  ; Et_eflux
  get_data, sclet+'_pef_Et_eflux', data=d, dlimits=dl, limits=l
  newd={x:d.x, y:d.y, v:energies}
  l = {ylog: 1, spec: 0, labflag:1, yrange: [1., 1.], ystyle: 0}
  dl = {spec: 0, log: 0, ysubtitle: 'keV/(scm!U2!NstrMeV)'}
  store_data, sclet+'_pef_Et_eflux', data=newd, dlimits=dl, limits=l
  options, sclet+'_pef_Et_eflux', charsize=.9
  options, sclet+'_pef_Et_eflux', 'ztitle','eflux'
  zlim, sclet+'_pef_Et_eflux', 1.e1, 2.e7
  options, sclet+'_pef_Et_eflux',zstyle=1
  options, sclet+'_pef_Et_eflux','extend_edges',1

  ; Et_dforf
  get_data, sclet+'_pef_Et_dfovf', data=d, dlimits=dl, limits=l
  newd={x:d.x, y:d.y, v:energies}
  l = {ylog: 1, spec: 1, labflag:1, ystyle: 0}
  dl = {spec: 0, log: 0, labels: 'total', colors: 0}
  store_data, sclet+'_pef_Et_dfovf', data=newd, dlimits=dl, limits=l

  ; pef_pa
  get_data, sclet+'_pef_pa', data=d, dlimits=dl, limits=l
  dl = {spec: 0, log: 0, labels: 'total', colors: 0}
  l = {yrange: [0. ,180.], ystyle: 1, ylog: 0, databar: 90.}
  store_data, sclet+'_pef_pa', data=d, dlimits=dl, limits=l
  options, sclet+'_pef_pa', charsize=.9

  ; pef_spinphase
  get_data, sclet+'_pef_spinphase', data=d, limits=l
  l = {yrange: [-5. ,365.], ystyle: 1, ylog: 0, databar: 180.}
  store_data, sclet+'_pef_spinphase', data=d, limits=l
  options, sclet+'_pef_spinphase', charsize=.9

  ; pef_tspin
  get_data, sclet+'_pef_tspin', data=d, dlimits=dl
  dl = {spec: 0, log: 0, ysubtitle: '[sec]'}
  store_data, sclet+'_pef_tspin', data=d, dlimits=dl
  options, sclet+'_pef_tspin', charsize=.9

  ; pef_sectnum
  get_data, sclet+'_pef_sectnum', data=d, dlimits=dl
  dl = {spec: 0, log: 0, ysubtitle: '[ ]'}
  store_data, sclet+'_pef_sectnum', data=d, dlimits=dl
  options, sclet+'_pef_sectnum', charsize=.9

  ; pef_nspinsinsum
  get_data, sclet+'_pef_nspinsinsum', data=d, dlimits=dl
  dl = {spec: 0, log: 0, ysubtitle: '[ ]'}
  store_data, sclet+'_pef_nspinsinsum', data=d, dlimits=dl
  options, sclet+'_pef_nspinsinsum', charsize=.9

  ; pef_nsectors
  get_data, sclet+'_pef_nsectors', data=d, dlimits=dl
  dl = {spec: 0, log: 0, ysubtitle: '[ ]'}
  store_data, sclet+'_pef_nsectors', data=d, dlimits=dl
  options, sclet+'_pef_nsectors', charsize=.9

  ; pef_spinphase2add - has no limits
  ; pef_sect2add - has no limits

  ; pef_hs_Epat_nflux
  get_data, sclet+'_pef_hs_Epat_nflux', data=d, limits=l
  l = {spec: 1, yrange: [0., 180.], ystyle: 1, zrange: [1., 1.], zstyle: 0, zlog: 1, databar: 90.}
  store_data, sclet+'_pef_hs_Epat_nflux', data=d, limits=l
  options, sclet+'_pef_hs_Epat_nflux', charsize=.9
  options, sclet+'_pef_hs_Epat_nflux', 'ztitle','nflux'
  zlim, sclet+'_pef_hs_Epat_nflux', 1.e1, 2.e7
  options, sclet+'_pef_hs_Epat_nflux',zstyle=1
  options, sclet+'_pef_hs_Epat_nflux','extend_edges',1
  
  ; pef_hs_Epat_eflux
  get_data, sclet+'_pef_hs_Epat_eflux', data=d, limits=l
  l = {spec: 1, yrange: [0., 180.], ystyle: 1, zrange: [1., 1.], zstyle: 0, zlog: 1, databar: 90.}
  store_data, sclet+'_pef_hs_Epat_eflux', data=d, limits=l
  options, sclet+'_pef_hs_Epat_eflux', charsize=.9
  options, sclet+'_pef_hs_Epat_eflux', 'ztitle','eflux'
  zlim, sclet+'_pef_hs_Epat_eflux', 1.e1, 2.e7
  options, sclet+'_pef_hs_Epat_eflux',zstyle=1
  options, sclet+'_pef_hs_Epat_eflux','extend_edges',1

  ; pef_hs_Epat_dfovf
  get_data, sclet+'_pef_hs_Epat_dfovf', data=d, limits=l
  l = {spec: 1, yrange: [0., 180.], ystyle: 1, zrange: [1., 1.], zstyle: 0, zlog: 1, databar: 90.}
  store_data, sclet+'_pef_hs_Epat_dfovf', data=d, limits=l
  options, sclet+'_pef_hs_Epat_dfovf', charsize=.9

  ; pef_fs_Epat_nflux
  get_data, sclet+'_pef_fs_Epat_nflux', data=d, limits=l
  l = {spec: 1, yrange: [0., 180.], ystyle: 1, zrange: [1., 1.], zstyle: 0, zlog: 1, databar: 90.}
  store_data, sclet+'_pef_fs_Epat_nflux', data=d, limits=l
  options, sclet+'_pef_fs_Epat_nflux', charsize=.9
  options, sclet+'_pef_fs_Epat_nflux', 'ztitle','nflux'
  zlim, sclet+'_pef_fs_Epat_nflux', 1.e1, 2.e7
  options, sclet+'_pef_fs_Epat_nflux',zstyle=1
  options, sclet+'_pef_fs_Epat_nflux','extend_edges',1

  ; pef_fs_Epat_eflux
  get_data, sclet+'_pef_fs_Epat_eflux', data=d, limits=l
  l = {spec: 1, yrange: [0., 180.], ystyle: 1, zrange: [1., 1.], zstyle: 0, zlog: 1, databar: 90.}
  store_data, sclet+'_pef_fs_Epat_eflux', data=d, limits=l
  options, sclet+'_pef_fs_Epat_eflux', charsize=.9
  options, sclet+'_pef_fs_Epat_eflux', 'ztitle','eflux'
  zlim, sclet+'_pef_fs_Epat_eflux', 1.e1, 2.e7
  options, sclet+'_pef_fs_Epat_eflux',zstyle=1
  options, sclet+'_pef_fs_Epat_eflux','extend_edges',1

  ; pef_hs_Epat_dfovf
  get_data, sclet+'_pef_fs_Epat_dfovf', data=d, limits=l
  l = {spec: 1, yrange: [0., 180.], ystyle: 1, zrange: [1., 1.], zstyle: 0, zlog: 1, databar: 90.}
  store_data, sclet+'_pef_fs_Epat_dfovf', data=d, limits=l
  options, sclet+'_pef_hs_Epat_dfovf', charsize=.9


end