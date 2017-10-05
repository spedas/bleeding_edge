;+
;Procedure: st_ste_load
;
;Purpose:  Loads stereo ste data
;keywords:
;   TRANGE= (Optional) Time range of interest  (2 element array).
;   /VERBOSE : set to output some useful info
;
;Example:
;   st_load_ste
;Notes:
;  This routine is (should be) platform independent.
;
;
; $LastChangedBy:  $
; $LastChangedDate:  $
; $LastChangedRevision: $
; $URL:$
;-
pro st_ste_load,type,all=all,files=files,trange=trange, $
    verbose=verbose,burst=burst,probes=probes, res=tres, $
    source_options=source_options, $
    version=ver

if not keyword_set(source_options) then begin
    stereo_init
    source_options = !stereo
endif
mystereo = source_options

if not keyword_set(probes) then probes = ['a','b']
if not keyword_set(type) then type = ''
if not keyword_set(ver) then ver='V01'

res = 3600l*24     ; one day resolution in the files
tr = timerange(trange)
n = ceil((tr[1]-tr[0])/res)  > 1
dates = dindgen(n)*res + tr[0]

for i=0,n_elements(probes)-1 do begin
   probe = probes[i]
   pref = 'st'+probe+'_' + (keyword_set(burst) ? '_b' : '')
   case probe of
   'a' :  path = 'impact/level1/ahead/ste/YYYY/MM/STA_L1_STE_YYYYMMDD_'+ver+'.cdf'
   'b' :  path = 'impact/level1/behind/ste/YYYY/MM/STB_L1_STE_YYYYMMDD_'+ver+'.cdf'
   endcase

   relpathnames= time_string(dates,tformat= path)

   files = file_retrieve(relpathnames,_extra = mystereo)

   if 0 then begin
     vfm = 'STE_spectra STE_mode STE_energy'
     cdf2tplot,file=files,varformat=vfm,all=all,verbose=!stereo.verbose ,prefix=pref , /convert_int1   ; load data into tplot variables
   endif else begin
     dprint,'Using Peters code'
cdfnames = ['STE_spectra', 'STE_energy']
ppx = 'st' + probe
;myformat = '/disks/stereodata/l1/ahead/ste/????/??/STA_L1_STE_*V01.cdf'
d=0
nodat = 0
loadallcdf,filenames=files,time_range=trange, $
    cdfnames=cdfnames,data=d,res =tres

if keyword_set(d) eq 0 then begin
   message,'No STA STE data during this time.',/info
   nodat = 1
  return
endif


;if data_type(prefix) eq 7 then px=prefix else px = 'sta_ste'
px = ppx+'_ste'

time  = reform(d.time)
str_element,d,cdfnames(0),STE_spectra
STE_spectra_U0 = reform(STE_spectra[0,*,*])
STE_spectra_U0 = transpose(STE_spectra_U0)
STE_spectra_U1 = reform(STE_spectra[1,*,*])
STE_spectra_U1 = transpose(STE_spectra_U1)
STE_spectra_U2 = reform(STE_spectra[2,*,*])
STE_spectra_U2 = transpose(STE_spectra_U2)
STE_spectra_U3 = reform(STE_spectra[3,*,*])
STE_spectra_U3 = transpose(STE_spectra_U3)

STE_spectra_D0 = reform(STE_spectra[4,*,*])
STE_spectra_D0 = transpose(STE_spectra_D0)
STE_spectra_D1 = reform(STE_spectra[5,*,*])
STE_spectra_D1 = transpose(STE_spectra_D1)
STE_spectra_D2 = reform(STE_spectra[6,*,*])
STE_spectra_D2 = transpose(STE_spectra_D2)
STE_spectra_D3 = reform(STE_spectra[7,*,*])
STE_spectra_D3 = transpose(STE_spectra_D3)

str_element,d,cdfnames(1),STE_energy
STE_energy_U0 = reform(STE_energy[0,*,*])
STE_energy_U0 = transpose(STE_energy_U0)
STE_energy_U1 = reform(STE_energy[1,*,*])
STE_energy_U1 = transpose(STE_energy_U1)
STE_energy_U2 = reform(STE_energy[2,*,*])
STE_energy_U2 = transpose(STE_energy_U2)
STE_energy_U3 = reform(STE_energy[3,*,*])
STE_energy_U3 = transpose(STE_energy_U3)

STE_energy_D0 = reform(STE_energy[4,*,*])
STE_energy_D0 = transpose(STE_energy_D0)
STE_energy_D1 = reform(STE_energy[5,*,*])
STE_energy_D1 = transpose(STE_energy_D1)
STE_energy_D2 = reform(STE_energy[6,*,*])
STE_energy_D2 = transpose(STE_energy_D2)
STE_energy_D3 = reform(STE_energy[7,*,*])
STE_energy_D3 = transpose(STE_energy_D3)

store_data,px+'_U0',data={x:time,y:STE_spectra_U0,v:STE_energy_U0}, $
   dlim={spec: 1, ylog: 1}
store_data,px+'_U1',data={x:time,y:STE_spectra_U1,v:STE_energy_U1}, $
   dlim={spec: 1, ylog: 1}
store_data,px+'_U2',data={x:time,y:STE_spectra_U2,v:STE_energy_U2}, $
   dlim={spec: 1, ylog: 1}
store_data,px+'_U3',data={x:time,y:STE_spectra_U3,v:STE_energy_U3}, $
   dlim={spec: 1, ylog: 1}
store_data,px+'_D0',data={x:time,y:STE_spectra_D0,v:STE_energy_D0}, $
   dlim={spec: 1, ylog: 1}
store_data,px+'_D1',data={x:time,y:STE_spectra_D1,v:STE_energy_D1}, $
   dlim={spec: 1, ylog: 1}
store_data,px+'_D2',data={x:time,y:STE_spectra_D2,v:STE_energy_D2}, $
   dlim={spec: 1, ylog: 1}
store_data,px+'_D3',data={x:time,y:STE_spectra_D3,v:STE_energy_D3}, $
   dlim={spec: 1, ylog: 1}


   endelse
;   vname=pref+'Distribution'
;
;   get_data,vname,data=d
; ;  printdat,d,vname
;
;   d2 = {x:d.x,  y:total(d.y,2), v:d.v1}
;   store_data,pref+'s',data=d2,dlimit={spec:1,zlog:1,ylog:1}
endfor


end
