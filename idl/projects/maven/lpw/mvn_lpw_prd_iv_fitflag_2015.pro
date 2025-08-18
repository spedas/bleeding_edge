pro mvn_lpw_prd_iv_fitflag_2015,data,data_x,data_y,data_dy,data_dv,data_flag,data_boom,data_version 

;the flag information
; 9999 not a good fit
; 9119  this boom has been by defolt for this time period identified as bad Vsc
; 88888  the SC pot is high and therefore is Ne and TE not reliable but vsc should be provied if reasnoble - need to be the largest value

;------------------------------------------------------------



get_data,'mvn_lpw_w_n_l2',data=wn
print,'#######   wn  fitflag_2015 in'
help,wn,/st
print,'####### '


SC_pot_thershold = 8 ; the Vsc threshold when Ne and Te is deemed unrelaible 


  date=time_string(min(data.x))
  result=strsplit(date,'/',/extract)
  st=result[0]
  print,'Working with date: ',st


   dir2='/spg/maven/test_products/cmf_temp/filled_lpstruc17/' 
   filter2='fitstruc_filled_'+st
      mvn_lpw_prd_iv_read_in_structure4,                  dir2+filter2+'_b2.sav',2
      mvn_lpw_prd_iv_read_in_structure4,                  dir2+filter2+'_b1.sav',1



      dir3='/spg/maven/test_products/cmf_temp/fitstrucGD/'     
      filename1=file_search(dir3,'*'+st+'*',count=count)
  if time_double(st) GT time_double('2015-01-01')  and count GT 1 then begin
     restore,dir3+'swp_fit_'+st+'_b1.sav'
     store_data,'gd_all1',data={x:swp_fit.time,y:  [[swp_fit.n_e],[swp_fit.te],[swp_fit.vsc],[swp_fit.n_i],[swp_fit.alt]]}
    restore,dir3+'swp_fit_'+st+'_b2.sav'
    store_data,'gd_all2',data={x:swp_fit.time,y  :[[swp_fit.n_e],[swp_fit.te],[swp_fit.vsc],[swp_fit.n_i],[swp_fit.alt]]}
  endif else begin

    xx=[0,0]
    store_data,'gd_all1',data={x:xx,y:  [[xx],[xx],[xx],[xx],[xx]]}
    store_data,'gd_all2',data={x:xx,y  :[[xx],[xx],[xx],[xx],[xx]]}

  endelse



data_version = ' filled_lpstruc17 '
;------------------------------------------------------------------
;these are the products that is needed


get_data,'mvn_lpw_w_n_l2',data=wn
;get_data,'mvn_lpw_act_V1',data=av1
;get_data,'mvn_lpw_pas_V1',data=pv1
;get_data,'mvn_lpw_swp2_V1',data=sv1
;get_data,'mvn_lpw_act_V2',data=av2
;get_data,'mvn_lpw_pas_V2',data=pv2
;get_data,'mvn_lpw_swp1_V2',data=sp2

;get the active only
subcycle=where(finite(wn.y), nn_s)   ; 1 is act and 2 is pas, work only with active

for uui=0,1 do begin
  
if uui EQ 0 then st='1' else st = '2'
   get_data,'da_alt_iau_'+st   ,data=alt
   get_data,'ree_Ne_'+st       ,data=Nee
   get_data,'ree_Te_'+st       ,data=Tee
   get_data,'ree_Vsc_'+st      ,data=vsc
   get_data,'ree_erra_'+st     ,data=erra
   get_data,'ree_flag_info_'+st,data=data0
   get_data,'ree_Tpoints_'+st  ,data=Tpoints
   get_data,'ree_sucsess_'+st  ,data=sucsess
   get_data,'ree_valid_'+st  ,data=valid
   get_data,'mm_Vsc_'+st      ,data=mmvsc
   get_data,'gd_all'+st        ,data=datx

; choose which points the L2 should be based on
    ne_res = fltarr(n_elements(alt.y),6)  *1./0   ; the value, lower bound, upper bound and then the flag
    Te_res = fltarr(n_elements(alt.y),6)  *1./0
    Vs_res = fltarr(n_elements(alt.y),6)  *1./0

; ----------- for each boom evaluate each point individually ----------------------

   for ii=0,n_elements(alt.y) -1 do begin
       ;check if we have a density in the vicinity
       tmp_time= wn.x[subcycle]
       tmp=min(abs( tmp_time-alt.x[ii]),n_wn0)
       
       n_wn = subcycle[n_wn0 >0]
       n_wn1 = subcycle[n_wn0-1]
       n_wn2 = subcycle[(n_wn0+1)<(n_elements(subcycle)-1)]
       tmp=min(abs(Nee.x-alt.x[ii]),n_ne)
       
       n_wn = (n_wn > 1) <(n_elements(wn.x)-2)
       n_ne = (n_ne > 1) <(n_elements(Nee.x)-2)
   
  if sucsess.y[n_ne] EQ 2  and valid.y[n_ne] EQ 1  then begin   ; this is high resolution data check valid and sucess, use onlu these points
        ;see if there is a waves density to be used as a lower bound of the LP fit
        if wn.y[n_wn] GT 1 then nnww=wn.y[n_wn] ELSE nnww=max([ wn.y[n_wn1]   ,  wn.y[n_wn]   ,  wn.y[n_wn2] ],/nan)
              if finite(nnww) EQ 0 then nnww=nee.y[n_ne,0]
              Nmin =min([nee.y[n_ne,0],nnww],/nan)
              Nmax =max([nee.y[n_ne,0],nnww],/nan)
              Nmaxlo =min([nee.y[n_ne,1], wn.y[n_wn1] - wn.dv[n_wn1] ,wn.y[n_wn] - wn.dv[n_wn],wn.y[n_wn2] - wn.dv[n_wn2]],/nan)  ; make the waves density the lowest....
              Nmaxup =max([nee.y[n_ne,2] ,wn.y[n_wn1] + wn.dy[n_wn1],wn.y[n_wn] + wn.dy[n_wn],wn.y[n_wn2]+  wn.dy[n_wn2] ],/nan)      
              if nnww GT 1 and nnww LT 500 then ne_res[ii,0]=Nmax  ELSE ne_res[ii,0]=Nmax               
 
 
;; print,ii,alt.y[ii],'##',nnww,nee.y[n_ne,0],datx.y[ii,0], nnww GT nee.y[n_ne,0],  wn.y[n_wn]   , n_wn ,' # ', tmp,n_elements(subcycle),n_wn0
              if n_elements(datx.x) GT 5 and ii LT n_elements(datx.x)-1 then $
              ne_res[ii,0]=ne_res[ii,0]* ( ne_res[ii,0] LE  datx.y[ii,0] )  
              ne_res[ii,1]=Nmaxlo > (ne_res[ii,0] / 4)
              ne_res[ii,2]=Nmaxup < (ne_res[ii,0] * 4)           
              ne_res[ii,3]= erra.y[n_ne] 
              ne_res[ii,4]= alt.y[ii]
              ne_res[ii,5]=uui+1
               
           te_res[ii,0]= tee.y[ii,0]    ; the value
           te_res[ii,1]= tee.y[ii,1] < (0.9* te_res[ii,0])   ;the lower bound
           te_res[ii,2]= tee.y[ii,2] > (1.1* te_res[ii,0])    ;the upper bound
           te_res[ii,3]= erra.y[ii]
           te_res[ii,4]= alt.y[ii]
           te_res[ii,5]=uui+1
           
           vs_res[ii,0]= vsc.y[ii,0]  ; the value
           vs_res[ii,1]= vsc.y[ii,1]  < (0.9* vs_res[ii,0])   ;the lower bound
           vs_res[ii,2]= vsc.y[ii,2]  > (1.1* vs_res[ii,0]) ;the upper bound
           if mmvsc.y[ii,0] GT 0 then vs_res[ii,2]= vsc.y[ii,2]  <  mmvsc.y[ii,0]   ;the upper bound 
           ;invalidate the point if VSC-ree is larger than mm and GD model
           if n_elements(datx.x) GT 5  and  n_elements(datx.x)-1 LT ii then $
           vs_res[ii,3]= erra.y[ii] + 500 * (  (vs_res[ii,0]  GT  mmvsc.y[ii,0]) + (vs_res[ii,0]  GT -1.0*datx.y[ii,2]) + (vs_res[ii,0] EQ 0) ) ELSE $
           vs_res[ii,3]= erra.y[ii] + 500 * (  (vs_res[ii,0]  GT  mmvsc.y[ii,0]) +                                        (vs_res[ii,0] EQ 0) )
            if n_elements(datx.x) GT 5 and  n_elements(datx.x)-1 LT ii then $
           if finite(mmvsc.y[ii,0])+finite(datx.y[ii,2]) EQ 0 and ii GT 1 then  vs_res[ii,1]= vs_res[ii-1,1] else $ ; this is to show that the potential might be lower     
           if finite(mmvsc.y[ii,0])                      EQ 0 and ii GT 1 then  vs_res[ii,1]= vs_res[ii-1,1]
           vs_res[ii,4]= alt.y[ii] 
           vs_res[ii,5]=uui+1    

if uui EQ 0 and time_double('2015-03-01') GT alt.x[ii] and  time_double('2015-03-17') LT alt.x[ii] then  vs_res[ii,3]= 9119  ; boom 1 Vsc not good in March 2015
if uui EQ 0 and time_double('2015-03-17') GT alt.x[ii] and  time_double('2015-03-31') LT alt.x[ii] then  vs_res[ii,3]= 9119  ; boom 1 Vsc not good in March 2015

       endif else begin
         ne_res[ii,3]=9999
         te_res[ii,3]=9999
         vs_res[ii,3]=9999
      endelse
   endfor  
         store_data,'ne'+st,data={x:alt.x,y:ne_res}
         store_data,'te'+st,data={x:alt.x,y:te_res}
         store_data,'vs'+st,data={x:alt.x,y:vs_res}  
         options,'ne'+st,psym=1
         options,'te1',yrange=[0.01,1] 
         options,'vs*',yrange=[-1,9]
         options,'vs*',colors=[0,2,2,6,4,4]
endfor

; ----------- create one array  of Ne Te and Vsc ----------------------

;store_data,'test',data=['ne1','mvn_lpw_w_n_l2']
;stanna

; ----------- ; For Vsc  smooth the values.....
get_data,'vs1',data=dat1
get_data,'vs2',data=dat2
xx=[dat1.x,dat2.x]
yy=[dat1.y,dat2.y]
tmp=sort(xx)
x1=xx[tmp]
y1=yy[tmp,*]

;smooth where it is possible only small delta time and the difference should be less than 30 %
dt_ind = where(  x1[1:n_elements(x1)-2]-x1[0:n_elements(x1)-3] LT 6  and   $
  y1[2:n_elements(x1)-1,3] GT 0    and  y1[1:n_elements(x1)-2,3] GT 0   and  y1[0:n_elements(x1)-3,3] GT 0  and $
  y1[2:n_elements(x1)-1,3] LT 100  and  y1[1:n_elements(x1)-2,3] LT 100 and  y1[0:n_elements(x1)-3,3] LT 100 ,nq)
y1_new=y1
y1_new[dt_ind,0] = (y1[dt_ind-1,0] +       2* y1[dt_ind,0] +         y1[dt_ind+1,0]) / $
  ((y1[dt_ind-1,0] GT 0) + 2* (y1[dt_ind,0] GT 0) + (y1[dt_ind+1,0] GT 0))
y1=y1_new   ; this is where the smoothing is applied

y1[*,1]=y1[*,1] < (y1[*,0]*0.8) ; double check that we get marging
y1[*,2]=y1[*,2] > (y1[*,0]*1.2) ; double check that we get marging
y1[*,3]= y1[*,3] + 500 *(y1[*,0] GT 20)  ; to make sure we do not get a unrealistic number through

store_data,'vs_all',data={x:x1,y:y1}

; ----------- ; Merge to getting the Ne

get_data,'ne1',data=dat1
get_data,'ne2',data=dat2
xx=[dat1.x,dat2.x]
yy=[dat1.y,dat2.y]
tmp=sort(xx)
x1=xx[tmp]
y1=yy[tmp,*]

; decouple the lower bound if the wn it too low
y1[*,1] = y1[*,1] > (y1[*,0]/2)   

; doulbe check with the density
for ui=0,n_elements(x1)-1 do begin
  tmp=min(abs(x1[ui] - wn.x),nq)
  if wn.y[nq] GT 10 then $
    y1[ui,0]=  y1[ui,0] >wn.y[nq]
endfor

; smooth the data with the points on either side to minimize the two boom effect
dt_ind = where(  x1[1:n_elements(x1)-2]-x1[0:n_elements(x1)-3] LT 6 ,nq)
y1_new=y1 
y1_new[dt_ind,0] = (y1[dt_ind-1,0] + 2* y1[dt_ind,0] + y1[dt_ind+1,0]) / $
  ((y1[dt_ind-1,0] GT 0) + 2* (y1[dt_ind,0] GT 0) + (y1[dt_ind+1,0] GT 0)) 
y1=y1_new

; double check that we get marging
y1[*,1]=y1[*,1] < (y1[*,0]*0.8) 
y1[*,2]=y1[*,2] > (y1[*,0]*1.2) 

; the LP model is low when the SC potential is high therefore deemed invalid   hard coded number
get_data,'vs_all',data=vs
y1[*,3] = y1[*,3]*( vs.y[*,0] LE SC_pot_thershold)  + 88888 * ( vs.y[*,0] GT SC_pot_thershold)   ;

store_data,'ne_all',data={x:x1,y:y1}


; ----------- ;for Te use only Boom1 

get_data,'te1',data=dat1
get_data,'te2',data=dat2

;lets use only boom 1
y1=dat1.y
y1[*,1]=y1[*,1] < (y1[*,0]*0.8) ; double check that we get marging
y1[*,2]=y1[*,2] > (y1[*,0]*1.2) ; double check that we get marging

y2=dat2.y
y2[*,3]=99999   ; invalidate all boom 2 data
;no smoothing is used here


;but we need to make an array based on boom 1 and boom 2
xx=[dat1.x,dat2.x]
yy=[y1,y2]
tmp=sort(xx)
x1=xx[tmp]
y1=yy[tmp,*]

; the LP model is low when the SC potential is high therefore deemed invalid   hard coded number
get_data,'vs_all',data=vs
y1[*,3] = y1[*,3]*( vs.y[*,0] LE SC_pot_thershold)  + 88888 * ( vs.y[*,0] GT SC_pot_thershold)   ;

store_data,'te_all',data={x:x1,y:y1}
options,'te_all',yrange=[0.01,1] 

;----------------- get it in the output format ----------

get_data,'ne_all',data=dne
get_data,'te_all',data=dte
get_data,'vs_all',data=dvs
nn=n_elements(dne.x)

data_x       =   dblarr(nn)
data_y       = fltarr(nn,10) * !values.f_nan
data_dy      = fltarr(nn,10) * !values.f_nan
data_dv      = fltarr(nn,10) * !values.f_nan
data_flag    = dblarr(nn)
; this is the order 
;  str_arr=['ne [cc]','te [K]','usc [V]','not used yet','not used yet','not used yet','not used yet', 'not used yet', 'not used yet','not used yet']   ;['u0','u1','usc','ne','ne1','ne2','Te','Te1','Te2','nsc']
;  str_col=[        0,       6,        4,    3,   3,   3,     3,    3,    3,   3]
data_x       =    dne.x
good = dne.y[*,3] GT 0 and dne.y[*,3] LT 100
data_y(*,0)  =   dne.y[*,0]  *good
data_dy(*,0) =   dne.y[*,1]  *good       ; dy upper value
data_dv(*,0) =   dne.y[*,2]  *good       ; dv lower value, 
good = dne.y[*,3] GT 0 and dne.y[*,3] LT 100
data_y(*,1)  =   dte.y[*,0]*good
data_dy(*,1) =   dte.y[*,1] *good     ; dy upper value
data_dv(*,1) =   dte.y[*,2] *good       ; dv lower value
good = dne.y[*,3] GT 0 and dne.y[*,3] LT 100
data_y(*,2)  =   dvs.y[*,0]*good
data_dy(*,2) =   dvs.y[*,1] *good       ; dy upper value
data_dv(*,2) =   dvs.y[*,2] *good        ; dv lower value
data_boom    =   dne.y[*,5] * 0.1  ; the first decimal in the flad indicates which boom is used
for i=0,n_elements(dne.y[*,3])-1 do $
data_flag[i]    =   max([dne.y[i,3],dte.y[i,3],dvs.y[i,3]],/nan)  ; since they are slightly derived independently


end