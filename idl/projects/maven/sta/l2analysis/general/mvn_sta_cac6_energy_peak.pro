;+
;Routine uses c6 and c8 data to produce two tplot variable products. The routine finds the peak eflux bin at each timestep, and produces:
;
;mvn_sta_ca_anode_perc: three rows: top: the % of eflux in the peak eflux bin; middle: the % of eflux in the top two eflux bins; 
;                       bottom: the % of eflux in the top three eflux bins. This is a function of energy only, eflux is summed over all masses.
;
;mvn_sta_c6_energypeak: the energy (in eV) that the peak eflux lies in at each timestep. Again, eflux is summed over all masses.
;
;mvn_sta_ca_anode_peak: the anode INDEX that the peak energy flux lies in. I believe STATIC anodes start at zero as well.
;
;trange: [a,b]: UNIX double start and stop times to calculate parameters over. If not set, entire time range available is used.
;
;Routine requires ca and c6 data to be loaded into tplot (mvn_sta_ca_A and mvn_sta_c6_E).
;
;
;EG:
;timespan, '2019-01-01', 1.
;mvn_sta_l2_load, sta_apid=['c6', 'ca']
;mvn_sta_l2_tplot
;mvn_sta_c6_energy_peak
;
;Testing only:
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_cac6_energy_peak.pro
;-

pro mvn_sta_cac6_energy_peak, trange=trange, success=success

proname='mvn_sta_cac6_energy_peak'

cols=get_colors()

get_data, 'mvn_sta_ca_A', data=ddca
get_data, 'mvn_sta_c6_E', data=ddc6

if size(ddca,/type) ne 8 or size(ddc6,/type) ne 8 then begin
  print, proname, ": you must load STATIC c6 and ca data into tplot using mvn_sta_l2_load and mvn_sta_l2_tplot."
  success=0
  return
endif

;Pick all times if trange not set:
if keyword_set(trange) then begin
  iTIME_ca = where(ddca.x ge trange[0] and ddca.x le trange[1], neleCA)
  iTIME_c6 = where(ddc6.x ge trange[0] and ddc6.x le trange[1], neleC6)
endif else begin
  neleCA = n_elements(ddca.x)
  iTIME_ca = findgen(neleCA)
  neleC6 = n_elements(ddc6.x)
  iTIME_c6 = findgen(neleC6)
endelse

;ARRAYS:
ca_arr = fltarr(neleCA,3)
ca_panode_arr = fltarr(neleCA) ;index of anode peak eflux lies in
c6_en_arr = fltarr(neleC6)  ;energy of peak eflux bin

for tt = 0l, neleCA -1l do begin
  efluxtmp = ddca.y[iTIME_ca[tt],*]
  efluxTOT = total(efluxtmp,/nan)  ;total eflux

  m1 = max(efluxtmp, imax, /nan)

  ;Pick the two bins either side of the peak; if the peak is at the edge of the anode array, loop around to next one
  case imax of
    0  : inds = [15, 1]
    15 : inds = [14, 0]
    else: inds = [imax-1l, imax+1l]
  endcase

  efluxtmp2 = [m1, efluxtmp[inds]]  ;put all three eflux values into one array
  isort = reverse(sort(efluxtmp2))  ;sort array, put into descending order

  ;Put data into arrays:
  ca_arr[tt,0] = 100.*efluxtmp2[0]/efluxTOT
  ca_arr[tt,1] = 100.*total(efluxtmp2[0:1],/nan)/efluxTOT
  ca_arr[tt,2] = 100.*total(efluxtmp2[0:2],/nan)/efluxTOT
  
  ca_panode_arr[tt] = imax ;index of anode with peak eflux
endfor

;Loop over c6 and find energy of peak eflux:
for tt = 0l, neleC6-1l do begin
  efluxtmp = ddc6.y[iTIME_c6[tt],*]

  m1 = max(efluxtmp, imax, /nan)

  ;Find closest
  c6_en_arr[tt] = ddc6.v[iTIME_c6[tt], imax]  ;energy at peak eflux

endfor  ;tt

tname='mvn_sta_ca_anode_perc'
store_data, tname, data={x: ddca.x[iTIME_ca], y: ca_arr}
  options, tname, colors=[cols.black, cols.blue, cols.green]
  options, tname, labels=['1', '2', '3']
  options, tname, labflag=1
  ylim, tname, 0, 105
  options, tname, ytitle='STA ca!Canode perc [%]'

tname='mvn_sta_ca_panode_index'
store_data, tname, data={x: ddca.x[iTIME_ca], y: ca_panode_arr}
  ylim, tname, -1, 16
  options, tname, ytitle='STA ca!Canode index!Cpeak eflux'

tname = 'mvn_sta_c6_energypeak'
store_data, tname, data={x: ddc6.x[iTIME_c6], y: c6_en_arr}
  ylim, tname, 0.1, 3E4
  options, tname, ylog=1
  options, tname, ytitle='STA energypeak!C[eV]'

success=1

end


