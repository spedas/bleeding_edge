;20170505 Ali
;saves 3d images for swia and static data-model comparisons
;
pro mvn_pui_tplot_3d_save,graphics=g,datestr=datestr

if ~keyword_set(g) then g=window(/current)
if ~keyword_set(datestr) then datestr='pui'

  g.erase
  mvn_pui_tplot_3d,/swia,/mo,/nowin
  g.save,datestr+'_3d_swia_model.png'

  g.erase
  mvn_pui_tplot_3d,/swia,/da,/nowin
  g.save,datestr+'_3d_swia_data.png'

  g.erase
  mvn_pui_tplot_3d,/swia,/d2,/nowin
  g.save,datestr+'_3d_swia_d2m.png'

  g.erase
  mvn_pui_tplot_3d,/stah,/mo,/nowin
  g.save,datestr+'_3d_stah_model.png'

  g.erase
  mvn_pui_tplot_3d,/stah,/da,/nowin
  g.save,datestr+'_3d_stah_data.png'

  g.erase
  mvn_pui_tplot_3d,/stah,/d2,/nowin
  g.save,datestr+'_3d_stah_d2m.png'

  g.erase
  mvn_pui_tplot_3d,/stao,/mo,/nowin
  g.save,datestr+'_3d_stao_model.png'

  g.erase
  mvn_pui_tplot_3d,/stao,/da,/nowin
  g.save,datestr+'_3d_stao_data.png'

  g.erase
  mvn_pui_tplot_3d,/stao,/d2,/nowin
  g.save,datestr+'_3d_stao_d2m.png'

end