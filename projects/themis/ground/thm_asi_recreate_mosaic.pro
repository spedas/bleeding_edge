;+
; NAME:
;    THM_ASI_RECREATE_MOSAIC
;
; PURPOSE:
;    recreate mosaic from gif-input
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    THM_ASI_RECREATE_MOSAIC,file
;
; INPUTS:
;    filename	like 'MOSA.2008.01.28.10.58.30.gif'
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;    no_view	do not regenerate mosaic, only show command
;
; OUTPUTS:
;    None
;
; OPTIONAL OUTPUTS:
;    None
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    None
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
;    THM_ASI_RECREATE_MOSAIC,'MOSA.2008.01.28.10.58.30.gif'
;
; MODIFICATION HISTORY:
;    Written by: Harald Frey, 23/06/2009
;
; NOTES:
;     
; VERSION:
;   $LastChangedBy: aaflores $
;   $LastChangedDate: 2012-01-09 09:54:03 -0800 (Mon, 09 Jan 2012) $
;   $LastChangedRevision: 9515 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/ground/thm_asi_recreate_mosaic.pro $
;
;-

PRO THM_ASI_RECREATE_MOSAIC,file,no_view=no_view

; check that files is really a gif image
result=query_image(file,info)
if (result ne 1 or info.type ne 'GIF') then begin
  dprint, 'File is not a mosaic gif image'
  return
  endif

	; read file
read_gif,file,img

	; check for secret code
if (img[40,0] ne 13 or img[41,0] ne 251 or img[42,0] ne 117 or img[43,0] ne 239) then begin
   dprint, 'Mosaic was not created with special code'
   return
   endif

	; get station names
thm_asi_stations,label,loc
label=strlowcase(label)

	; start decoding bottom line
	; date and time
year=img[0,0]*100+img[1,0]
date=string(year,'(i4.4)')+'-'+string(img[2,0],'(i2.2)')+'-'+$
  string(img[3,0],'(i2.2)')+'/'+string(img[4,0],'(i2.2)')+':'+$
  string(img[5,0],'(i2.2)')+':'+string(img[6,0],'(i2.2)')
	; thumbnails
if (img[7,0] eq 1) then thumb_string='thumb=1' else thumb_string='thumb=0'
     	; central latitude and longitude
central_lon=img[8,0]*100.+img[9,0]+img[10,0]/100.
lon_string=strcompress(',central_lon='+string(central_lon),/remove_all)
central_lat=img[11]+img[12,0]/100.
lat_string=strcompress(',central_lat='+string(central_lat),/remove_all)
	; map_scale
map_scale=(img[13,0]+img[14,0]/100.)*10.^(img[15,0])
map_string=strcompress(',scale='+string(map_scale),/remove_all)
	; xsize and ysize
xsize=img[16,0]*100+img[17,0]
ysize=img[18,0]*100+img[19,0]
size_string=strcompress(',xsize='+string(xsize)+',ysize='+string(ysize),/remove_all)
	; rotation
rotation=img[20,0]*100.+img[21,0]+img[22,0]/100.
rot_string=strcompress(',rotation='+string(rotation),/remove_all)
	; minimum elevation
minimum_elevation=img[23,0]+img[24,0]/100.
ele_string=strcompress(',minimum_elevation='+string(minimum_elevation),/remove_all)
	; zbuffer
z_string=strcompress(',zbuffer='+string(img[25,0]),/remove_all)
	; stations
n_sites=img[49,0]
station_id=reform(img[50:50+n_sites-1,0])
exclude=where(station_id eq 0,count)
if (count gt 0) then begin
  start=",exclude=["
  for i=0,count-1 do begin $
    start=start+"'"+label[exclude[i]]+"'," & $
    endfor
  len=strlen(start)
  exclude_string=strmid(start,0,len-1)+"]"
  endif else exclude_string=''
show=where(station_id eq 2,count)  
if (count gt 0) then begin
  start=",show=["
  for i=0,count-1 do begin $
    start=start+"'"+label[show[i]]+"'," & $
    endfor
  len=strlen(start)
  show_string=strmid(start,0,len-1)+"]"
  endif else show_string=''

	; construct full command
command="thm_asi_create_mosaic,'"+date+"'"+show_string+exclude_string+$
        map_string+lon_string+lat_string+rot_string+size_string+$
        ele_string
dprint,  ''
if (img[25,0] eq 0) then begin
    if not keyword_set(no_view) then res=execute(command)
    dprint, 'Mosaic was generated with command:'
    dprint, command
    endif else begin
    a=1
    if not keyword_set(no_view) then begin
        res=execute(command+',zbuffer=a')
        window,xsize=xsize,ysize=ysize
        tv,a
        endif
    dprint, 'Mosaic was generated with command:'
    dprint, command+',zbuffer=1'
    endelse 
dprint,  ''
end
