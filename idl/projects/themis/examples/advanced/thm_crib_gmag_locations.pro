;+
;Procedure:
;  thm_crib_gmag_locations
;
;Purpose:
;  Example 1:
;  -------------
;    Produce a plot showing the location of all gmag stations
;    similar to the ones shown on the THEMIS website.
;
;  Example 2:
;  -------------
;    Find available data within a specified latitude/longitude.
;
;
;See also:
;  thm_crib_gmag
;  thm_crib_greenland_gmag
;  thm_crib_maccs_gmag
;  thm_crib_gmag_wavelet
;
;More info:
;  http://themis.ssl.berkeley.edu/instrument_gmags.shtml
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-02-27 16:08:10 -0800 (Fri, 27 Feb 2015) $
;$LastChangedRevision: 17056 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/examples/advanced/thm_crib_gmag_locations.pro $
;-



;------------------------------------------------------------------------------
; Example 1: Produce a plot showing the location of all gmag stations
;------------------------------------------------------------------------------

thm_gmag_stations, label, location

loadct,0 ; change this to plot in colour

set_plot,'z'
device,set_resolution=[750,500]
chars=1.0

; edit lat/long and scale to display map as you'd like it
; below multiple maps are overlayed to draw country and us borders
map_set,58.5,-108,0.,/stereo,/conti,scale=2.8e7,$
   color=250,title='GMAG Stations'
borders=tvrd()
erase

map_set,58.5,-108,0.,/stereo,/conti,scale=2.8e7,$
   /usa,e_continents={COUNTRIES:1},color=100
usaborders=tvrd()
erase

map_set,58.5,-108,0.,/stereo,/conti,scale=2.8e7,$
   color=255,e_continents={FILL:1}
color_map=tvrd()
erase

color_map[where(usaborders eq 100)]=150
color_map[where(color_map eq 0)]=200
color_map[where(borders eq 250)]=1

tv,color_map
   
; plot the actual station locations. Edit settings to get the display the way you want it.
for i=0.1, 0.7, 0.1 do begin
  plots,location[1,*],location[0,*],color=0,psym=4,symsize=i
endfor

for i=0, n_elements(label)-1 do begin
  xyouts,location[1,i],location[0,i]+0.5,label[i],charsize=chars,charthick=2,color=0,alignment=0.5
endfor

for i=5, 85, 5 do begin
  plots,findgen(361),fltarr(361)+i,line=1,color=1
endfor

for i=0, 360, 30 do begin
  plots,fltarr(91)+i,findgen(91),line=1,color=1
endfor

image=tvrd()
device,/close
case !version.os_family of
 'Windows': os='win'
 'unix': os='x'
endcase

set_plot,os
window,5,xsize=750,ysize=500
tv,image

print, '  Plot the locations of all gmag stations available through TDAS'


;end of example 1
stop



;------------------------------------------------------------------------------
; Example 2: Find available data within a specified latitude/longitude.
;------------------------------------------------------------------------------

; set the time range
trange = ['2012-05-10/11:00:00', '2012-05-10/15:00:00']

; load data for all stations
thm_load_gmag, trange = trange 

; get a list of the ground mag tplot variables
tnames_list = tnames('thg_mag*')

; set the latitude range
latitude_range = [60, 65]

; set the longitude range
longitude_range = [0, 180]

; loop through the tplot variables
for tnum = 0, n_elements(tnames_list)-1 do begin
  
  get_data, tnames_list[tnum], dlimits=dl
  
  ; check that the 'cdf' tag exists
  if tag_exist(dl, 'cdf') then begin
    
    str_element, dl.cdf.vatt, 'station_latitude', latitude, SUCCESS=slat
    str_element, dl.cdf.vatt, 'station_longitude', longitude, SUCCESS=slong
    
    if (slat ne 0 and slong ne 0) then begin

      ; check the latitude range
      if (latitude ge latitude_range[0] and latitude le latitude_range[1]) then begin

        ; check the longitude range
        if (longitude ge longitude_range[0] and longitude le longitude_range[1]) then begin
          print, '' ;add line
          print, tnames_list[tnum], ' is at: ', string(latitude), ' deg latitude, ', string(longitude), ' deg longitude'
        endif

      endif
    endif 
  endif

endfor

;end of example 2
stop


end