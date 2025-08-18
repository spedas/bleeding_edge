;+
; NAME:
;   iug_show_obsinfo
;
; PURPOSE:
;   Show site information obtained from IUGONET metadata database.
;
; Written by Y.-M. Tanaka, Feb. 13, 2013 (ytanaka at nipr.ac.jp)
;-

pro iug_show_obsinfo, obs=obs

label_stn='Site name'
def_lenstn=strlen(label_stn)

max_lenstn=max(strlen(obs.name))
if max_lenstn lt def_lenstn then max_lenstn=def_lenstn

labels=label_stn
for i=0, max_lenstn-def_lenstn+2 do begin
    labels=labels+' '
endfor
labels=labels+'Geo.Lat.   Geo.Lon.'

horline=''
for i=0, strlen(labels)-1 do begin
    horline=horline+'-'
endfor

print, horline
print, labels
print, horline

nstn=n_elements(obs.name)
for istn=0, nstn-1 do begin

    dataline=strupcase(obs.name[istn])
    for i=0, max_lenstn-strlen(dataline)+2 do begin
        dataline=dataline+' '
    endfor

    dataline=dataline+string(float(obs.glat[istn]), $
      format='(f6.2)')+'     '+string(float(obs.glon[istn]), format='(f7.2)')
    print, dataline
endfor

print, horline
print, 'Number of sites = '+string(nstn)

end
