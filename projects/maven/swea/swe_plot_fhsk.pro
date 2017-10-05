;+
;PROCEDURE:   swe_plot_fhsk
;PURPOSE:
;  Plots SWEA fast housekeeping data (A6).
;
;USAGE:
;  swe_plot_fhsk
;
;INPUTS:
;
;KEYWORDS:
;
;CREATED BY:    David L. Mitchell  07-24-12
;FILE: swe_plot_fhsk.pro
;VERSION:   1.0
;LAST MODIFICATION:   03/23/13
;-
pro swe_plot_fhsk

  @mvn_swe_com
  
  Twin = !d.window
  tplot_options,get=opt
  
  if (size(a6,/type) ne 8) then begin
    print,"No fast housekeeping data."
    return
  endif
  
  npkt = n_elements(a6)
  
  for i=0,(npkt-1) do begin
    window,/free
    
    dt = min(abs(swe_hsk.time - a6[i].time),j)
    chksum = swe_hsk[j].chksum[swe_hsk[j].ssctl]
    tabnum = mvn_swe_tabnum(chksum)
    title = time_string(a6[i].time) + $
            string([tabnum,chksum],format='(4x,"Table Number: ",i1,4x,"Checksum: ",Z2.2)')

    t = a6[i].time + (1.95D/224D)*dindgen(224)

    pans = 'a6_' + a6[i].name
    for j=0,3 do begin
      store_data,pans[j],data={x:t, y:a6[i].value[*,j]}
      options,pans[j],'ytitle',a6[i].name[j]
      options,pans[j],'psym',10
    endfor

    tplot_options,'title',title
    tplot,pans,trange=[min(t),max(t)]
  endfor
  
  wset, Twin
  tplot_options,opt=opt
  tplot_options,'title',''
  
  return

end
