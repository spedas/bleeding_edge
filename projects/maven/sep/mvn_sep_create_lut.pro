
pro mvn_sep_define_widths,range=range,nsteps=nsteps,binwidths=binwidths,scale=scale,de_e=de_e
if ~keyword_set(scale) then scale= 1.5  ;[10,1.5]
if ~keyword_set(range) then range = [11.,6000.]
if ~keyword_set(de_e) then de_e = 0.2
if ~keyword_set(nsteps) then nsteps = round( alog(range[1]/range[0])/alog(1+de_e) ) 
printdat,scale,range,nsteps,de_e
esteps = dgen(range=range,/log,nsteps)
adcsteps = round(esteps/scale)
adcsteps[nsteps-1] = 4096
print,adcsteps
binwidths =  adcsteps - shift(adcsteps,1) 
binwidths[0] = adcsteps[0]
print,binwidths
printdat,/val,binwidths,width=300
;stop
end





pro  mvn_sep_fill_lut,lut,startbin,TIDs=TIDs,ftos=ftos,nbins=nbins,binwidths=binwidths,increment=inc
   if n_elements(inc) eq 0 then inc=1
   if n_elements(lut) ne 2L^16 then lut = bytarr(2L^16)
   if n_elements(nbins) eq 0 then nbins = replicate(1,n_elements(binwidths) )
   if total(nbins*binwidths,/preserve) ne 4096 then message, 'Improper binwidths'
   for k=0,n_elements(TIDS)-1 do begin
   tid = tids[k]
   for j=0,n_elements(ftos)-1 do begin
   fto = ftos[j]
   memptr = (fto *2 + TID) * 2L^12
   for i=0,n_elements(nbins)-1 do begin
      for st=0,nbins[i]-1 do begin
         for w=0,binwidths[i]-1 do begin
             lut[memptr++] = startbin
         endfor
         if keyword_set(inc) then   startbin++
      endfor
   endfor
   endfor
   endfor
end

pro mvn_sep_fill_lut_basemap,lut
  fto_s = [1,2,4,3,6,7]
  startbin = 244
  for tid = 0,1 do $
     for j=0,5  do $
        mvn_sep_fill_lut,lut,startbin,TID=tid,fto=fto_s[j],nbins=[1],binwidth=[4096]
end

; https://maven.ssl.berkeley.edu/svn/gse/software/GSEOS/Instruments/SEP/Python/scripts/sep_map.py

function mvn_sep_create_lut,mapname,mapnum=mapnum
if ~keyword_set(mapname) then mapname = mvn_sep_mapnum_to_mapname(mapnum)
;dprint,/phelp,mapname
case mapname of
'ATLO': begin ; mapnum=4, used since launch until 2014-03-17/22:45 UTC
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=1,nbins=[30,9,1],binwidth=[2,400,436]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=2,nbins=[30,9,1],binwidth=[2,400,436]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=4,nbins=[30,9,1],binwidth=[2,400,436]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=3,nbins=[2,1],binwidth=[48,4000]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=6,nbins=[2,1],binwidth=[48,4000]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=7,nbins=[1,1],binwidth=[48,4048]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=1,nbins=[30,9,1],binwidth=[2,400,436]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=2,nbins=[30,9,1],binwidth=[2,400,436]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=4,nbins=[30,9,1],binwidth=[2,400,436]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=3,nbins=[2,1],binwidth=[48,4000]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=6,nbins=[2,1],binwidth=[48,4000]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=7,nbins=[1,1],binwidth=[48,4048]
  end
'Flight1': begin  ; mapnum=6  Never used
  startbin = 0
;  BINWIDTHS = [7,2,2,2,3,4,5,5,7,9,10,13,15,19,23,29,35,42,53,64,79,96,118,145,177,217,267,326,400,490,600,832]
  
  BW32 = [13, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 17, 20, 25, 30, 36, 44, 52, 62, 76, 90, 110, 132, 158, 190, 228, 274, 330, 396, 476, 572, 694]
  BW32 = [13, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 17, 20, 25, 30, 36, 44, 52, 62, 76, 90, 110, 132, 158, 190, 228, 274, 330, 396, 476, 571, 695]
  BW16 = total(/preserve,reform(bw32,2,16),1)
  
  startbin = 243
  mvn_sep_fill_lut,lut,startbin,TIDs=[0,1],ftos=[0,5],binwidth=4096,inc=0
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=1,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=2,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=4,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=3,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=6,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=7,binwidth=bw16

  mvn_sep_fill_lut,lut,startbin,TID=1,fto=1,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=2,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=4,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=3,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=6,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=7,binwidth=bw16
  end
'Flight2': begin   ; mapnum=8, used since 2014-03-17/22:45 UTC until MOI: 2014-09-22/19:40 UTC (S/C in hybernation since 2014-07-17 UTC until MOI)
  startbin = 0
;  bw=round(exp(i/3.63)/3.))
;  BW32 = [7,2,2,2,3,4,5,6,7,9,11,13,15,19,23,29,35,42,53,64,79,96,118,144,176,216,268,326,400,490,600,832]
  BW32 = [4, 2, 1, 1, 1, 1, 2, 2, 3, 4, 5, 7, 9, 12, 16, 21, 27, 36, 47, 63, 82, 108, 143, 188, 248, 327, 430, 566, 746, 984, 9 ,1]
  ;       0  1  2  3  4  5  6  7  8  9  10 11 12 13  14  15  16  17  18  19  20   21   22   23   24   25   26   27   28   29 30 31
  BW16 = total(/preserve,reform(bw32,2,16),1)
  
  if n_elements(BW32) ne 32 then Message,'Wrong number of elements'
  if total(BW32,/preserve) ne 4096 then message,'Bin error'
  
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TIDs=[0,1],ftos=[0,5],binwidth=4096,inc=0
  startbin = 0
  
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=1,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=2,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=4,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=3,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=6,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=7,binwidth=bw16

  mvn_sep_fill_lut,lut,startbin,TID=1,fto=1,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=2,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=4,binwidth=bw32
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=3,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=6,binwidth=bw16
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=7,binwidth=bw16
  chksum = total(/preserve,lut)
;  printdat,chksum,/hex
  correction = 'AA'x - chksum
  lut[0] = correction
;  printdat,varname='checksum',total(/preserve,lut),/hex
  
  end

'Flight3': begin   ; mapnum=9, used since 2014-09-22/19:40 UTC until present
  startbin = 0
;  bw=round(exp(i/3.63)/3.))
;  BW32 = [7,2,2,2,3,4,5,6,7,9,11,13,15,19,23,29,35,42,53,64,79,96,118,144,176,216,268,326,400,490,600,832]
; BW32 = [4, 2, 1, 1, 1, 1, 2, 2, 3, 4, 5, 7, 9, 12, 16, 21, 27, 36, 47, 63, 82, 108, 143, 188, 248, 327, 430, 566, 746, 984, 9 ,1] ;Flight 2
  BW_O = [4+ 2, 1, 1, 1, 1, 2, 2, 3, 4, 5, 7, 9, 12, 16, 21, 27, 36, 47, 63, 82, 108, 143, 188, 248, 327, 430, 566, 746, 984+ 9 ,1]
  BW_F = BW_O
  ;       0  1  2  3  4  5  6  7  8  9  10 11 12 13  14  15  16  17  18  19  20   21   22   23   24   25   26   27   28   29 30 31
;  BW16 = total(/preserve,reform(bw32,2,16),1)
;  BW16 = [6,  2,  2,  4,  7,  12,  21,  37,   63,  110, 190   , 331 ,  575,  996,    1730,   10]
  BW_T  = [6+  2,  2,  4,  7,  12,  21,  37,   63,  110+ 190   , 331 +  575,  996,    1730+   10]

;  BW16 = [6,  2,  2,  4,  7,  12,  21,  37,   63,     110,     190   , 331 ,  575,    996,      1730,      10]
  BW_OT = [6+  2,  2,  4,  7,  12,  21,  37,   27,36,  47,63,   190   , 331 ,  575,  429,567,   746,984 ,   10]
  BW_FT = BW_OT

;  BW16 = [6,  2,  2,  4,  7,  12,  21,  37,      63,     110,     190   , 331 ,    575,    996,      1730,      10]
  BW_FTO= [6+  2,  2,  4,  7,  12,  21,  16,21,   27,36,  110,     190   , 331 ,  248,327,  429,567,  1730+10]
  
;  if n_elements() ne 32 then Message,'Wrong number of elements'
;  if total(BW32,/preserve) ne 4096 then message,'Bin error'
  
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TIDs=[0,1],ftos=[0,5],binwidth=4096,inc=0
  startbin = 0
  
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=1,binwidth=bw_O
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=2,binwidth=bw_T
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=4,binwidth=bw_F
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=3,binwidth=bw_OT
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=6,binwidth=bw_FT
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=7,binwidth=bw_FTO

  mvn_sep_fill_lut,lut,startbin,TID=1,fto=1,binwidth=bw_O
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=2,binwidth=bw_T
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=4,binwidth=bw_F
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=3,binwidth=bw_OT
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=6,binwidth=bw_FT
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=7,binwidth=bw_FTO
  chksum = total(/preserve,lut)
;  printdat,chksum,/hex
  correction = 'AA'x - chksum
  lut[0] = correction
;  printdat,varname='checksum',total(/preserve,lut),/hex
  
  end


'fullstack0': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=1,nbins=[50,9,1],binwidth=[1,400,446]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=2,nbins=[50,9,1],binwidth=[1,400,446]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=4,nbins=[50,9,1],binwidth=[1,400,446]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=3,nbins=[20,4,1],binwidth=[2,800,856]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=6,nbins=[20,4,1],binwidth=[2,800,856]
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=7,nbins=[10,3,1],binwidth=[2,800,1676]
  end  
'fullstack1': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=1,nbins=[50,9,1],binwidth=[1,400,446]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=2,nbins=[50,9,1],binwidth=[1,400,446]
;stop
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=4,nbins=[50,9,1],binwidth=[1,400,446]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=3,nbins=[20,4,1],binwidth=[2,800,856]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=6,nbins=[20,4,1],binwidth=[2,800,856]
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=7,nbins=[10,3,1],binwidth=[2,800,1676]
  end  
'SEP-A-O-alpha': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=1,nbins=[60,90,87,1],binwidth=[1,40,5,1]
  end  
'SEP-B-O-alpha': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=1,nbins=[60,90,87,1],binwidth=[1,40,5,1]
  end  
'SEP-A-F-alpha': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=4,nbins=[60,90,87,1],binwidth=[1,40,5,1]
  end  
'SEP-A-O-alpha_low': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=0,fto=1,nbins=[60,88,87,2,1],binwidth=[1,40,5,40,1]
  end  
'SEP-B-O-alpha_low': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=1,nbins=[60,88,87,2,1],binwidth=[1,40,5,40,1]
  end  
'SEP-B-F-alpha_low': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=4,nbins=[60,88,87,2,1],binwidth=[1,40,5,40,1]
  end  
'SEP-B-F-alpha_low80': begin
  mvn_sep_fill_lut_basemap,lut
  startbin = 0
  mvn_sep_fill_lut,lut,startbin,TID=1,fto=4,nbins=[60,80,87,10,1],binwidth=[1,40,5,40,1]
  end  
endcase
return,lut
end


