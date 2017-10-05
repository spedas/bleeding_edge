





;common mav_apid_sep_handler_com , sep_all_ptrs ,  sep1_hkp,sep2_hkp,sep1_svy,sep2_svy,sep1_arc,sep2_arc,sep1_noise,sep2_noise ,sep1_memdump,sep2_memdump
if 0 then begin
mvn_mag_extract_data,'mag1_svy_misc',mag1
mvn_mag_extract_data,'mag2_svy_misc',mag2
mvn_mag_extract_data,'mag1_hkp',mag1_hkp
mvn_mag_extract_data,'mag2_hkp',mag2_hkp

mvn_mag_handler,svy='F0'
endif

mvn_sep_extract_data,'mvn_mag1_hkp',mag1
mvn_sep_extract_data,'mvn_mag2_hkp',mag2
mvn_sep_extract_data,'mvn_sep1_svy',sep1        ;,trange=trange,tnames=tnames,tags=tags,num=num
mvn_sep_extract_data,'mvn_sep2_svy',sep2        ;,trange=trange,tnames=tnames,tags=tags,num=num


;mag =mag2_hkp 
;mag =mag1_hkp  
;mag = mag1    
;mag = mag2     
mag=mag1

mag = mag[ where(mag.f_met gt 4e8 ) ]   ; get rid of NAN (0)

decimate=256d
decimate=640d
;decimate=0
if keyword_set(decimate) then begin
  n = n_elements(mag)
  mets= dgen(res=decimate,range=minmax(mag.f_met))
  i = floor( interp(lindgen(n) , mag.f_met,mets ) )
  i = i[uniq(i)]
  mag = mag[i]
endif

met = mag.f_met
f0 = mag.f0
store_data,'F0',mvn_spc_met_to_unixtime(met),f0

; Compute cumulative F0  - this will insure that F0 is monotonically increasing
neg = ulong(f0 lt shift(f0,1))
neg[0] = 0   ; start counting at beginning of first loaded data file
;neg[0] = floor( ((met[0]- 438004800 ) - f0[0] )/2d^16 )   ; start counting on launch day
neg[0] = floor( (met[0] - f0[0] )/2d^16 )   ; start counting at beginning of MET epoch
rollover = total(/preserve,neg,/cumulative)
f0 += rollover * 2UL^16

if total((f0 mod 2uL^16) ne mag.f0) ne 0 then message,'cumulative error'

if 1 then begin
store_data,'F0_cum',mvn_spc_met_to_unixtime(met),f0,dlim={ynozero:1}
df0 = f0 - shift(f0,1) 
df0[0] = df0[1]

store_data,'F0mod32',mvn_spc_met_to_unixtime(met),f0 mod 32

store_data,'dF0',mvn_spc_met_to_unixtime(met),df0,dlim={ylog:1}
creep = met-f0 -(met[0]-f0[0])
store_data,'creep',mvn_spc_met_to_unixtime(met), creep  mod 1d
creep_dt = deriv(met,creep)
w = where(abs(creep_dt) lt .0001)
store_data,'creep_dt',mvn_spc_met_to_unixtime(met),creep_dt,dlim={yrange:minmax(creep_dt[w]),constant:0.}

;Filter out the 0.5 second glitches
d_met1 = shift(met,1) + df0 - met
d_met2 = shift(met,-1) - shift(df0,-1) - met
d_met =  (d_met1 + d_met2)/2                          ; this will catch 2 consecutive errors - but not 3
d_met[0] = 0
d_met[n_elements(d_met)-1] = 0
store_data,'d_MET',mvn_spc_met_to_unixtime(met), d_met , dlim={yrange:[-1,1]}
w = where(abs(d_met) lt .1,nw)
dprint,'Rejecting ',n_elements(f0)-nw,' time glitches'
met = met[w]
f0=f0[w]
creep = creep[w]

store_data,'Creep',mvn_spc_met_to_unixtime(met), creep mod 1d
creep_dt = deriv(met,creep)
w = where(abs(creep_dt) gt .0001,nw)
if nw ne 0 then creep_dt[w] = !values.f_nan
store_data,'Creep_dt',mvn_spc_met_to_unixtime(met), creep_dt,dlim={constant:0.}

;deriv_data,'creep'


;!p.multi= [0,1,4]
;plot,df0,/ylog
;plot,met mod 1.
;plot,met-f0 -(met[0]-f0[0])

sep=sep1

sep_f0a = interp(double(f0),met,sep.met ,/ignore_nan)
sep_f0b = interp(double(f0),met,sep.met - sep.duration/2.)

sep.f0 = sep_f0b + .5  ; round to nearest unsigned integer
store_data,'dmF0',sep.time,sep_f0a -sep.f0

;sep.f0 = interp(double(f0),met,sep.met )


df0 = sep.f0 - shift(sep.f0,1)
df0[0]=df0[1]
dmet = sep.met - shift(sep.met,1)
dmet[0]=dmet[1]
store_data,'sep_dF0',sep.time,df0
store_data,'sep_dMET',sep.time,dmet
sep_creep = (sep.met - sep[1].met) -  ( sep.f0-sep[1].f0)
store_data,'sep_creep',sep.time  , sep_creep mod 10d
deriv_data,'sep_creep'
endif


;printdat,sep.f0
if 0 then begin
t1=sep1.time
t2=sep2.time

t1 = t1[where(finite(t1))]
mt1 = t1 mod 1.
dmt1 = mt1 - shift(mt1,1)
dmt1 = shift(mt1,-1) - shift(mt1,1)
dt1 = t1 - shift(t1,1)
dmt1_dt = dmt1/dt1

w = where( abs(dmt1) lt .01 )

!p.multi= [0,1,4]
plot, mt1 
plot, dmt1 , yrange=minmax( dmt1[w] )
plot, dmt1_dt, yrange= minmax( dmt1_dt[w] )
store_data,'mt1',t1,mt1
store_data,'dmt1',t1,dmt1, dlim={yrange:minmax(dmt1[w])}
store_data,'dmt1_dt',t1,dmt1 ,dlim={yrange: minmax( dmt1_dt[w] )}
endif

;timespan

if 0 then begin
w1 = where(finite(sep1.met) ,nw1 )
w2 = where(finite(sep2.met) ,nw2 )
sep1 = sep1[w1]
sep2 = sep2[w2]
endif 

if 0 then begin
sep1.f0 = .5 + interp(double(f0),met,sep1.met - sep1.duration/2.  )
sep2.f0 = .5 + interp(double(f0),met,sep2.met - sep2.duration/2.  )

gap1 =   (sep1.f0 -shift(sep1.f0+sep1.duration ,1)) 
wgap1 = where(gap1)
gap2 =   (sep2.f0 -shift(sep2.f0+sep2.duration ,1)) 
wgap2 = where(gap2)


i1 = lindgen(n_elements(sep1))
i2 = lindgen(n_elements(sep2))

sf0 = [sep1.f0*4+sep1.sensor,sep2.f0*4+sep2.sensor]
sn  = [sep1.sensor,sep2.sensor]
ii = [i1,i2]
s = sort(sf0)
sf0 = sf0/4
u = uniq(sf0[s])
iis =ii[s]
sn_s = sn[s]
sn_su = sn_s[u]
sf0s  = sf0[s]
sf0su = sf0[s[u]]
printdat,sep1.f0,sep2.f0
printdat,u,s,sf0,sf0su,sn_s,sn_su

dprint

sepnan = fill_nan(sep1[0])
;sepstruct = [sep1:sepnan, sep2:sepnan}
nan=!values.f_nan
sepstruct = {time:0d,f0:0UL,valid:0,bvec:[nan,nan,nan],sep:replicate(sepnan,2) }
sepc = replicate(sepstruct, n_elements(sf0su) )
u = 0L
sf0s_last = sf0s[0]
for i=0L,n_elements(sf0s)-1 do begin
  if sf0s[i] ne sf0s_last then u=u+1
  sf0s_last = sf0s[i]
  case sn_s[i] of
    1: sepc[u].sep[0] = sep1[ iis[i] ] 
    2: sepc[u].sep[1] = sep2[ iis[i] ] 
    else: dprint,i,sn_s[i],phelp=3
  endcase
endfor
sepc.time = max(sepc.sep.time,dimension=1)
sepc.f0   = max(sepc.sep.f0,dimension=1)
dprint,/phelp,u,sepc
w_f0 = where (sepc.sep[0].f0 ne sepc.sep[1].f0)
printdat,w_f0
w_duration = where(sepc.sep[0].duration ne sepc.sep[1].duration)
printdat,w_duration
print,sepc[w_f0].sep.f0
print,sepc[w_duration].sep.duration
;printdat,minmax(sf0)
;print,sepc[w].sep.f0
endif

end
