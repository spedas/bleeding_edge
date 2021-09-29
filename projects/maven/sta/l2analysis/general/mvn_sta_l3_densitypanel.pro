;+
;Extract specified ion species from the default L3 tplot variable (which contains 1,2,16,32,44), and stick into a new
;tplot variable. This allows the user to only plot specific species, rather than showing all 5.
;
;
;INPUTS:
;species: string array: the ion species you want to include in the new tplot variable. 
;         options are: ['h', 'he', 'o', 'o2', 'co2'].
;
;KEYWORDS:
;tplotname: string: tplot name of output variable. If not set, 'mvn_sta_densitypanel' is used.
;
;trange: double array opf unix times, [a,b], start-stop times to grab data only between these times. Default if not set is
;        to use all data available.
;
;colors: float array containing the IDL color table indices for the colors of each ion species in the new array. Must be the same length
;        as species. For example, if species=['H', 'O'] and colors=[0, 254], H will be plotted in black (0) and O in red (254), assuming 
;        the user is using colortable 39 or 43. This allows the user to use their own color table. If not set, colors=[0,1,2,3,4] is used.
;
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_l3_densitypanel.pro  ;for testing only
;-
;

pro mvn_sta_l3_densitypanel, species, tplotname=tplotname, success=success, trange=trange, colors=colors

proname = 'mvn_sta_l3_densitypanel'

if size(species,/type) ne 7 then begin
    print, proname
    print, ": species must be set as a string containing the ion species you want included: "
    print, "The full set of options are ['h', 'he', 'o', 'o2', 'co2'].
    success=0
    return
endif

if not keyword_set(tplotname) then tplotname='mvn_sta_densitypanel'

species2 = strupcase(species)
neleS = n_elements(species) ;number of species needed

if not keyword_set(colors) then colors = findgen(neleS)

;GET DATA:
get_data, 'mvn_sta_density_prelim_2', data=ddsta  ;this name will change eventually ****

neleT = n_elements(ddsta.x)

dataarray = fltarr(neleT, neleS)  ;store densities in here

for ss = 0l, neleS-1l do begin
    ;Define which indice in the data 
    case species2[ss] of
      'H' : ind = 0
      'HE': ind = 1
      'O' : ind = 2
      'O2': ind = 3
      'CO2': ind = 4
      else: ind = 999  
    endcase
    
    if ss eq 0 then tlabel = [species2[ss]] else tlabel = [tlabel, species2[ss]]  ;add species name to label array
    
    if ind le 4 then begin
        ;If a valid species is entered, grab it:
        dataarray[*,ss] = ddsta.y[*,ind]     
    endif else begin
        ;If an invalid species is entered, skip it.
        print, proname, ": ", species[ss], " is not a valid option. Please use ['h', 'he', 'o', 'o2', 'co2']."
    endelse   
  
endfor  ;ss

;Figure out time range:
if keyword_set(trange) then begin
    iKP1 = where(ddsta.x ge trange[0] and ddsta.x le trange[1], niKP1)
    if niKP1 eq 0 then begin
        print, proname, ": I couldn't find any density data between the specified times in trange."
        success=0
        return
    endif
    
    timearray2 = ddsta.x[iKP1]
    dataarray2 = dataarray[iKP1]
endif else begin
    timearray2 = ddsta.x
    dataarray2 = dataarray
endelse

;Store:
store_data, tplotname, data={x: timearray2, y: dataarray2}
  ylim, tplotname, 0.1, 1E5
  options, tplotname, ylog=1
  options, tplotname, colors=colors
  options, tplotname, labels = tlabel
  options, tplotname, labflag=-1
  options, tplotname, ytitle='STA!Cdensity!C[cm!U-3!N]'

stop


end


