pro esa_anode_calib,orbit, $

  ENERGY=energy,$
  DIR=dir,$
  DATASRC=datasrc,$
  SDT=sdt, $
  SHOW4=show4, $
  SHOW8=show8, $
  SHOWALL=showall
;+
; PROCEDURE: esa_anode_calib,orbit
;
; reads in data from individual angle bins from esa burst data,
; asks user to click on boundaries of loss cone, and averages
; remaining points
;
; INPUT:
;  orbit  the orbit number (used in the filename) which you are calibrating
;
; OUTPUT:
;  prints calibration values (nomalized to 1.0) for 32 angle bins
;
; KEYWORDS:
;
; ENERGY  passed onto get_2dt.  If not set, default is [1000,20000]
; DIR     set this keyword to the directory in which tplot files
;         are stored.  Default is current directory.
; DATASRC set this keyword to the string passed by get_2dt (i.e. 'fa_eeb',
;         'fa_ieb', 'fa_seb1','fa_seb2', etc) If this keyword is
;         not set it defaults to 'fa_eeb'
; SHOW4   set this keyword to show plots of 4 bins and the losscones
; SHOW8   set this keyword to show plots of 8 bins and the losscones
; SHOWALL set this keyword to show plots of all bins and the losscones
; SDT     set this keyword to get esa data directly from SDT 
;     (default is to read in tplot files)  Note that SDT needs to
;     be running anyways, because of the fa_fields_phase
;
; Need to have phase (1032) in SDT.  If SDT keyword set, need also to
; have EesaBurstAggregate in SDT.
;
; Written 97-4-15   by Y-K Tung
; Modified 98-2-11  by Y-K Tung  added keyword DIR
; Modified 98-2-20  by Y-K Tung  added keyword ENERGY
;
;-

show=intarr(32)

if not keyword_set(DIR) then dir=''

if not keyword_set(ENERGY) then energy=[1000,20000]

if not keyword_set(DATASRC) then datasrc='fa_eeb'

if keyword_set(SHOW4) then begin
  show(0)=1
  show(8)=1
  show(16)=1
  show(24)=1
endif

if keyword_set(SHOW8) then begin
  show(0)=1
  show(4)=1
  show(8)=1
  show(12)=1
  show(16)=1
  show(20)=1
  show(24)=1
  show(28)=1
endif

if keyword_set(SHOWALL) then begin
  show(*)=1
endif


if orbit le 99 then begin
  print,'Do not calibrate using data before orbit 100'
  return
endif 

if orbit ge 1000 then begin
  orb=strmid(strcompress(string(orbit)),1,4)
endif else begin
  orb=strmid(strcompress(string(orbit)),1,3)
endelse

for i=0,9 do begin
filena ='bin'+strmid(strcompress(string(i)),1,1)
if keyword_set(SDT) then begin
  get_2dt,'c_2d',datasrc,energy=energy,arange=[i,i],name=filena
  tplot_file,filena,orb+filena+'.tplot',/sav
endif else begin
  tplot_file,1,dir+orb+filena+'.tplot',/res
endelse
endfor

for i=10,31 do begin
filena ='bin'+strmid(strcompress(string(i)),1,2)
if keyword_set(SDT) then begin
  get_2dt,'c_2d',datasrc,energy=[1000,20000],arange=[i,i],name=filena
  tplot_file,filena,orb+filena+'.tplot',/sav
endif else begin
  tplot_file,1,dir+orb+filena+'.tplot',/res
endelse
endfor

phase=fa_fields_phase()
get_data,'bin0',data=mydata
esatime=mydata.x
esacounts=mydata.y
esaphi=interp(phase.comp1,phase.time,esatime)
esaphi=esaphi mod (2*!pi)
window,0,ret=2
print,'Click on beginning and end of loss cone.  Click on right-mouse when' $
    +' done'
plot,esaphi,esacounts
crosshairs,x,y
phasebeg=fltarr(32)   ; phasebeg and phaseend hold the beginning and end
phaseend=fltarr(32)   ; phases of the loss cone for each bin (0-31)
phasebeg(0)=x(0)
phaseend(0)=x(1)

for i=1,31 do begin
  phasebeg(i)=phasebeg(i-1)+(2*!pi/32.0)
  if phasebeg(i) gt 2*!pi then phasebeg(i) = phasebeg(i)-2*!pi
  phaseend(i)=phaseend(i-1)+(2*!pi/32.0)
  if phaseend(i) gt 2*!pi then phaseend(i) = phaseend(i)-2*!pi
endfor

; Note that all values in phasebeg and phaseend are between 0 and 2 pi
;

avgcounts=fltarr(32)

for i=0,31 do begin
  if i le 9 then begin
    filena='bin'+strmid(strcompress(string(i)),1,1)
  endif else begin
    filena='bin'+strmid(strcompress(string(i)),1,2)
  endelse
  get_data,filena,data=mydata
  if phasebeg(i) lt phaseend(i) then begin
    indices=where(esaphi ge phasebeg(i) and esaphi le phaseend(i))
  endif else begin
    indices=where(esaphi le phaseend(i) or esaphi ge phasebeg(i))
  endelse
;
; Add up total counts, then add up loss cone counts, and take the difference
;
  esacounts=mydata.y
  losscone=esacounts(indices)
  lossconephi=esaphi(indices)
  sum=total(esacounts)-total(losscone)
  totpoints=size(esacounts)
  rempoints=size(losscone)
  numpoints=totpoints(1)-rempoints(1)
  avgcounts(i)=sum/numpoints
;
;  Plot out individual bins and individual loss cones, as indicated by
;  the array show.
;
  if show(i) then begin
    window,0,ret=2,ysize=200
    plot,esaphi,esacounts,psym=2,title=filena,xtitle='Phase (radians)', $
      ytitle='Counts',yrange=[0,150]
    oplot,[0,2*!pi],[avgcounts(i),avgcounts(i)]
    window,1,ret=2,ysize=200,xpos=384,ypos=350
    plot,lossconephi,losscone,xrange=[0,8],psym=2,title='Loss Cone', $
       yrange=[0,150],xtitle='Phase (radians)',ytitle='Counts'
    xyouts,6,140,'click right-mouse to continue'
    crosshairs,x,y
  endif
endfor

print,avgcounts/max(avgcounts)

end


