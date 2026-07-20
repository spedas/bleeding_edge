;+
;2026-04-24: CMF added extra functionality: code will extract counts at each timestamp, and determine the % of counts in the 
;peak count bin +-4 energy bins. This is the same as done in nbc, to determine if the IDF is a beam or not (in energy space).
;
;OUTPUTS:
;
;Routine uses c6 and ca data to produce two tplot variable products. The routine finds the peak eflux bin at each timestep, and produces:
;
;mvn_sta_ca_anode_cnts: two rows: top: the counts in the peak count anode; bottom: the counts in the peak anode+- one anode
;                       (summed).
;
;mvn_sta_ca_anode_perc: two rows: top: the % of counts in the peak count anode; bottom: % of counts in the peak anode+- one anode
;                       (summed).
;
;mvn_sta_ca_panode_index: single number, the anode index that the peak counts lie in. 7 is nominal pointing at periapsis.
;
;mvn_sta_c6_energypeak: the energy (in eV) that the peak counts lie in at each timestep. Counts are summed over all masses.
;
;mvn_sta_c6_peak_counts_energy: counts that lie within the energy bin with peak counts, +-4 bins as well. This is the
;                                   same method as used in nbc_4d.
;
;mvn_sta_c6_peak_counts_perc_total: % of counts that lie within the energy bin with peak counts, +-4 bins as well. This is the
;                                   same method as used in nbc_4d. 
;
;
;:
;INPUTS:
;
;trange: [a,b]: UNIX double start and stop times to calculate parameters over. If not set, entire time range available is used.
;
;species: 'h', 'he', 'o', 'o2', 'co2': if set will calculate the added functionality for L3 for this mass range. Note - the 
;        original three outputs are not affected by this keyword. 
;
;mass_range: output that contains the mass range used to address the species keyword if set. If not set, mass_range=[0., 120.],
;         all ions. Can be used to check the correct mass range was used.
;
;Routine requires ca and c6 data to be loaded into tplot (mvn_sta_ca_A and mvn_sta_c6_E), and c6 L2 data in the IDL common block.
;
;/energywidth: if set, routine will use c6 data to calculate the energy width characteristics, and will output the tplot variables
;              above that are related to c6.
;
;/angularwidth: if set, routine will use ca data to calculate the angular (anode) wide characteristics, and will output the tplot 
;               variables above that are related to ca.
;
;tnameadd: string: this will be added onto the end of any tplot variables output. eg tnameadd='_v1' will add this string to the
;                  end of the tplot variables output (based on energywidth and angularwidth keywords).
;
;NOTES:
;when using the species or mass_range keywords, note that, eg stragglers, may impact your results. For example, in the solar
;     wind, if using species='O2', if there is no pickup O2+, the results may track the solar wind protons, as the H+ 
;     stragglers may dominate. Using the iv_level='4' keyword when using L2 data should minimize this (by removing the background
;     counts in all products). But it may not be perfect- be careful! Perhaps check a significant density exists if you want to
;     trust these results.
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

pro mvn_sta_cac6_energy_peak, trange=trange, success=success, species=species, mass_range=mass_range, $
                              angularwidth=angularwidth, energywidth=energywidth, tnameadd=tnameadd

proname='mvn_sta_cac6_energy_peak'

if not keyword_set(tnameadd) then tnameadd=''

cols=get_colors()

massr = mvn_sta_get_mrange()

common mvn_c6,mvn_c6_ind,mvn_c6_dat

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
ca_arr = fltarr(neleCA,2)+!values.f_nan ;peak count rate, top row = peak bin, bottom row = total from the peak + each neighbor
ca_arr_perc = ca_arr ;corresponding % of total counts across all anodes
ca_panode_arr = fltarr(neleCA)+!values.f_nan ;index of anode peak eflux lies in
c6_en_arr = fltarr(neleC6)+!values.f_nan  ;energy of peak eflux bin
c6_peak_cnts = fltarr(neleC6)+!values.f_nan  ;% of counts that lie in the peak count bin
c6_peak_cnts_en = fltarr(neleC6)+!values.f_nan ;energy of the corresponding bin with peak counts

if keyword_set(angularwidth) then begin
    if size(ddca,/type) ne 8 then begin
      print, proname, ": you must load STATIC ca data into tplot using mvn_sta_l2_load and mvn_sta_l2_tplot."
      success=0
      return
    endif
    
    ;Pick all times if trange not set:
    if keyword_set(trange) then begin
      iTIME_ca = where(ddca.x ge trange[0] and ddca.x le trange[1], neleCA)
    endif else begin
      neleCA = n_elements(ddca.x)
      iTIME_ca = findgen(neleCA)      
    endelse

    ;Loop:
    for tt = 0l, neleCA -1l do begin
      ;Find peak counts:
      catimeTMP = ddca.x[iTIME_ca[tt]]

      datTMP0 = mvn_sta_get_ca(catimeTMP)
      
      ;datTMP0: has [16,64] arrays: [16] are the energies.
      ;64 are the angles: 4 deflector and 16 anodes.
      ;phi=0-15 anodes, theta = deflectors
      ;dattmp0[0,*] = energy step [0], all 64 angular steps. They are in groups of 4 per anode, i.e. the second dimension, [0-3]
      ;is anode 0; [4-7] = anode 1, etc. As I don't care about deflector step, just anode, I think compress the deflector 
      ;dimension down, which means integrating every four elements together:

      datTMP1 = datTMP0.cnts ;extract counts array
      datTMP2 = total(datTMP1, 1, /nan) ;sum across energy dimension
      counts_anode = fltarr(16) ;counts in each anode for this timestsamp, summed over the 4 deflectors in each anode bin
      
      for ano = 0l, 15l do begin
        a1 = ano*4l
        a2 = a1+4l
        ainds = [a1:a2]
        
        counts_anode[ano] = total(datTMP2[ainds], /nan) ;sum over these deflector bins
        
      endfor ;ano
      
      ;Find peak (no mass info so can't sum over that dimension):
      max_ca_counts1 = max(counts_anode, imax, /nan) ;the peak bin
        ca_panode_arr[tt] = imax ;index of anode with peak eflux - save here
              
      ;Count one anode either side of this:
      if imax eq 0 then imax_lo = 15l else imax_lo = imax-1l ;add and subtract one anode each side, remember it can loop at 15.
      if imax eq 15 then imax_hi = 0l else imax_hi = imax+1l
      
      max_ca_counts3 = counts_anode[imax_lo] + counts_anode[imax] + counts_anode[imax_hi] ;the peak three bins
      
      peak_perc_count1 = 100.*max_ca_counts1/total(counts_anode,/nan)
      peak_perc_count3 = 100.*max_ca_counts3/total(counts_anode,/nan)
      
      ;Store:
      ca_arr[tt,0] = max_ca_counts1
      ca_arr[tt,1] = max_ca_counts3
      ca_arr_perc[tt,0] = peak_perc_count1
      ca_arr_perc[tt,1] = peak_perc_count3
  
    endfor
    
    tname='mvn_sta_ca_anode_cnts'+tnameadd
    store_data, tname, data={x: ddca.x[iTIME_ca], y: ca_arr}
      options, tname, colors=[cols.black, cols.blue]
      options, tname, labels=['1', '3']
      options, tname, labflag=1
      options, tname, ytitle='STA ca!Canode counts'
    
    tname='mvn_sta_ca_anode_perc'+tnameadd
    store_data, tname, data={x: ddca.x[iTIME_ca], y: ca_arr_perc}
      options, tname, colors=[cols.black, cols.blue]
      options, tname, labels=['1', '3']
      options, tname, labflag=1
      ylim, tname, 0, 105
      options, tname, ytitle='STA ca!Canode perc [%]'

    tname='mvn_sta_ca_panode_index'+tnameadd
    store_data, tname, data={x: ddca.x[iTIME_ca], y: ca_panode_arr}
      ylim, tname, -1, 16
      options, tname, ytitle='STA ca!Canode index!Cpeak eflux'

endif


;Loop over c6 and find energy of peak eflux: this part can be mass dependent if set by user:
;This loop figures out the mass range to used based on species keyword etc:
if keyword_set(species) then begin
    species2 = strupcase(species)
    tags1 = tag_names(massr)
    itag = where(species2 eq tags1, nitag)
    if nitag eq 1 then result = execute("mass_range = massr."+species) else mass_range=[0., 120.]
    
endif

if keyword_set(energywidth) then begin
    if size(ddc6,/type) ne 8 then begin
      print, proname, ": you must load STATIC c6 data into tplot using mvn_sta_l2_load and mvn_sta_l2_tplot."
      success=0
      return
    endif

    ;Pick all times if trange not set:
    if keyword_set(trange) then begin
      iTIME_c6 = where(ddc6.x ge trange[0] and ddc6.x le trange[1], neleC6)
    endif else begin
      neleC6 = n_elements(ddc6.x)
      iTIME_c6 = findgen(neleC6)
    endelse
  
    ;ARRAYS:
    c6_peak_cnts = fltarr(neleC6,2)+!values.f_nan  ;counts that lie in the peak count energy bin, and peak+-4 energy bins
    c6_peak_cnts_perc = c6_peak_cnts
    c6_peak_cnts_en = fltarr(neleC6)+!values.f_nan ;energy of the corresponding bin with peak counts

    nne = 4.  ;number of energy bins either side of peak to use below
    ;Loop:
    for tt = 0l, neleC6-1l do begin
      efluxtmp = ddc6.y[iTIME_c6[tt],*]
    
      m1 = max(efluxtmp, imax, /nan)
    
      ;Find closest
      c6_en_arr[tt] = ddc6.v[iTIME_c6[tt], imax]  ;energy at peak eflux
      
      
      ;Find peak counts:
      c6timeTMP = ddc6.x[iTIME_c6[tt]]
      
      datTMP0 = mvn_sta_get_c6(c6timeTMP)
      
      datTMP1 = datTMP0.cnts ;extract counts array
      datTMP2 = datTMP1
      
      enTMP1 = datTMP0.energy
          
      ;Remove numbers outside the mass range:
      if keyword_set(species) then begin
        ind = where(datTMP0.mass_arr lt mass_range[0] or datTMP0.mass_arr gt mass_range[1],count)
        if count ne 0 then datTMP2[ind]=0.
      endif
      
      ;Compress dimension down to just energy - integrate across mass:
      datTMP3 = total(datTMP2,2) ;just 32 energies
      
      peak_counts1 = max(datTMP3, imax, /nan) ;peak, from all data
      
      ;In nbc_4d, Jim sums counts around the peak bin +-4 either side for 32E bins, the ncompares to the total for all E. Do the same here. Set all other values to zero.
      inds_low = (imax-nne)>0.
      inds_high = (imax+nne)<31.  ;this is hard coded to 32E
      inds = [inds_low : inds_high]
      
      datTMP4 = datTMP3
      datTMP4[0:inds_low] = 0 ;just the peak +- 4 bins exist here
      datTMP4[inds_high:*] = 0
      
      peak_counts2 = total(datTMP4, /nan) ;just +-4 around peak E
      total_counts = total(datTMP3, /nan) ;all counts across all E
      
      peak_perc_counts1 = 100.*peak_counts1/total_counts ;% of peak counts in peak energy bin, of total counts
      peak_perc_counts2 = 100.*peak_counts2/total_counts ;% of peak counts in peak energy bin +-4, of total counts
      
      energy_peak_counts = enTMP1[imax,0] ;the '0' is the mass dimension, the same for all masses. Energy in eV of peak counts
      
      c6_peak_cnts[tt,0] = peak_counts1 ;counts in the energy bin with most counts
      c6_peak_cnts[tt,1] = peak_counts2 ;counts in peak+-4 energy bins
      
      c6_peak_cnts_perc[tt,0] = peak_perc_counts1
      c6_peak_cnts_perc[tt,1] = peak_perc_counts2
      
      c6_peak_cnts_en[tt] = energy_peak_counts
      ;if c6timeTMP ge 1513948645.0000000d then stop
    endfor  ;tt
    

  ;  tname = 'mvn_sta_c6_energypeak'+tnameadd  ;this is the energy of the peak eflux, which is no longer used (we use counts now)
  ;  store_data, tname, data={x: ddc6.x[iTIME_c6], y: c6_en_arr}
  ;    ylim, tname, 0.1, 3E4
  ;    options, tname, ylog=1
  ;    options, tname, ytitle='STA energypeak!C[eV]'
    
    tname = 'mvn_sta_c6_peak_counts'+tnameadd
      store_data, tname, data={x: ddc6.x[iTIME_c6], y: c6_peak_cnts}
        options, tname, colors=[cols.black, cols.blue]
        options, tname, labels=['1', '9']
        options, tname, labflag=-1
        options, tname, ytitle='STA c6!CPeak counts'
    
    tname = 'mvn_sta_c6_peak_counts_perc'+tnameadd
      store_data, tname, data={x: ddc6.x[iTIME_c6], y: c6_peak_cnts_perc}
        options, tname, colors=[cols.black, cols.blue]
        options, tname, labels=['1', '9']
        options, tname, labflag=-1
        ylim, tname, 0, 100
        options, tname, ytitle='STA c6!CPeak counts!C% of!Ctotal counts'
    
    tname = 'mvn_sta_c6_peak_counts_energy'+tnameadd
      store_data, tname, data={x: ddc6.x[iTIME_c6], y: c6_peak_cnts_en}
        options, tname, ylog=1
        options, tname, ytitle='STA c6!CEnergy of!Cpeak counts'
endif

success=1

end


