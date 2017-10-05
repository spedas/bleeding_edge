;等間隔補間

pro data_interpolation2,$
    data_01,$
    time_01,$
    data_02,$
    time_02,$
    r_data=r_data,$
    st_time0=st_time0,$
    ed_time0=ed_time0,$
    rev=rev,$
    set_interval=set_interval,$
    itp_interval

;データ入れ替え
if keyword_set(rev) then begin
    if(rev eq 1) then begin
        tmpD=data_01
        tmpT=time_01
        data_01=data_02
        time_01=time_02
        data_02=tmpD
        time_02=tmpT
    endif
endif

s=''

for i=0,n_elements(data_01)-1 do begin
    if finite(data_01(i)) then begin
        first01=i
        break
    endif
endfor
for i=0,n_elements(data_01)-1 do begin
    if finite(data_01(n_elements(data_01)-1-i)) then begin
        last01=n_elements(data_01)-1-i
        break
    endif
endfor
for i=0,n_elements(data_02)-1 do begin
    if finite(data_02(i)) then begin
        first02=i
        break
    endif
endfor
for i=0,n_elements(data_02)-1 do begin
    if finite(data_02(n_elements(data_02)-1-i)) then begin
        last02=n_elements(data_02)-1-i
        break
    endif
endfor

st_time=max([time_01(first01),time_02(first02)])
ed_time=min([time_01(last01),time_02(last02)])

if keyword_set(st_time0) then begin
    if time_double(st_time0) ge st_time then st_time=time_double(st_time0)
endif 
if keyword_set(ed_time0) then begin
    if time_double(ed_time0) le ed_time then ed_time=time_double(ed_time0)
endif 
print,'Start Time : ',time_string(st_time)
print,'End Time : ',time_string(ed_time)
;st_timeとed_timeの幅内で初めて データが出た点をdata_01の開始点とする
;最終点もデータのある点にする




;補間間隔の決定　指定がなければ最小時間間隔
for i=1,n_elements(data_01)-1 do begin
    append_array,interval,time_01(i)-time_01(i-1)
endfor

if keyword_set(set_interval) then begin
    itp_interval=set_interval
endif else begin
    itp_interval=min(interval)
endelse
print,itp_interval,'  [sec] : Time Interval'

i=0
while (st_time+itp_interval*i le ed_time) do begin
    append_array,time_03,st_time+itp_interval*i
    i++
endwhile

inter_numX=0
inter_numY=0

flag2=0
tmp=!values.f_NAN
for i=0,n_elements(time_03)-1 do begin
    if (where(time_01 eq time_03(i)) ne -1) then begin
        if finite(data_01(where(time_01 eq time_03(i)))) then begin
            append_array,data_03,data_01(where(time_01 eq time_03(i)))
            flag2=1
        endif
        ;if ~keyword_set(data_03) or (i eq n_elements(time_03)-1) then begin
        ;    flag2=1
        ;endif
    endif
    if (flag2 eq 0) then begin
        data_01l=data_01(where(time_01 lt time_03(i)))
        time_01l=time_01(where(time_01 lt time_03(i)))
        for j=1,n_elements(data_01l) do begin
            if finite(data_01l(n_elements(data_01l)-j)) then begin
                inter_lowD=data_01l(n_elements(data_01l)-j)
                inter_lowT=time_01l(n_elements(data_01l)-j)
                break
            endif
        endfor
        data_01h=data_01(where(time_01 ge time_03(i)))
        time_01h=time_01(where(time_01 ge time_03(i)))
        for j=0,n_elements(data_01h)-1 do begin
            if finite(data_01h(j)) then begin
                inter_highD=data_01h(j)
                inter_highT=time_01h(j)
                break
            endif
        endfor
        calA=double(inter_lowD)
        calB=double(inter_highD)-double(inter_lowD)
        calC=(double(time_03(i))-double(inter_lowT))/(double(inter_highT)-double(inter_lowT))
        append_array,data_03,calA+calB*calC
        inter_numX++
    endif
    flag2=0
endfor


flag2=0
for i=0,n_elements(time_03)-1 do begin
    if (where(time_02 eq time_03(i)) ne -1) then begin
        if finite(data_02(where(time_02 eq time_03(i)))) then begin
            append_array,data_04,data_02(where(time_02 eq time_03(i)))
            flag2=1
        endif
        ;if ~keyword_set(data_04) or (i eq n_elements(time_03)-1) then begin
        ;    flag2=1
        ;endif
    endif
    if (flag2 eq 0) then begin
        data_02l=data_02(where(time_02 le time_03(i)))
        time_02l=time_02(where(time_02 le time_03(i)))
        for j=1,n_elements(data_02l) do begin
            if finite(data_02l(n_elements(data_02l)-j)) then begin
                inter_lowD=data_02l(n_elements(data_02l)-j)
                inter_lowT=time_02l(n_elements(data_02l)-j)
                break
            endif
        endfor
        data_02h=data_02(where(time_02 gt time_03(i)))
        time_02h=time_02(where(time_02 gt time_03(i)))
        for j=0,n_elements(data_02h)-1 do begin
            if finite(data_02h(j)) then begin
                inter_highD=data_02h(j)
                inter_highT=time_02h(j)
                break
            endif
        endfor
        calA=double(inter_lowD)
        calB=double(inter_highD)-double(inter_lowD)
        calC=(double(time_03(i))-double(inter_lowT))/(double(inter_highT)-double(inter_lowT))
        append_array,data_04,calA+calB*calC
        inter_numY++
    endif
    flag2=0
endfor

;print,'data04',n_elements(data_04),n_elements(data_03)
r_data=fltarr(2,n_elements(time_03))
for i=0,n_elements(time_03)-1 do begin
    r_data[0,i]=float(data_03(i))
    r_data[1,i]=float(data_04(i))
endfor

tmp0=0
tmp1=0
;print,time_string(time_01),data_01
;for i=0,n_elements(data_01)-1 do begin
    ;print,time_string(time_1(i)),data_1(i),data_01(i),data_03(i)
;    if (finite(data_01(i))) and (finite(data_03(i))) then begin
;        tmp1=i
;    endif
;    if (tmp1 ne tmp0) then begin
 ;       append_array,span_data,time_01(tmp1)-time_01(tmp0)
        ;if time_01(tmp1)-time_01(tmp0) ne 3600 then print,tmp0,tmp1,time_string(time_01(tmp0)),time_string(time_01(tmp1)),data_01(tmp0),data_03(tmp0),data_01(tmp1),data_03(tmp1)
;        tmp0=tmp1
;    endif
;endfor
;print,span_data
;print,'-----------------interpolation status--------------------------------'
;print,'|                       number of all data     =',n_elements(data_01)
;print,'|            number of effective data pair     =',n_elements(span_data)+1
;minV=min(span_data)
;if minV le 0 then begin
;    idx=where(span_data gt 0)
;    minV=min(span_data(idx))
;endif
;print,'|            minimum time interval[second]     =',minV
;print,'|              maximum time interval / min     =',max(span_data)/minV
;print,'|              mean of time interval / min     =',mean(span_data)/minV
;print,'|standard deviation of time interval / min     =',stddev(span_data)/minV
;print,'---------------------------------------------------------------------'
;result=static_analysis_iugonet3(data_01,data_02)

print,n_elements(data_01),' : number of data1'
print,n_elements(data_02),' : number of data2'
print,n_elements(data_03),' : number of data3(interpolated data1)'
print,n_elements(data_04),' : number of data4(interpolated data2)'
print,inter_numX,' : interpolation number of data3'
print,inter_numY,' : interpolation number of data4'

;データの描画
;store_data,'sq_wind',data={x:time_01, y:data_03}
;         options,'sq_wind',ytitle='uwind[m/s]'
;window, 1, xsize=1100, ysize=700
;!p.multi=[0,1,4]
;plot,data_01,psym=0;,xticks = 4, xtickv = [time_string(time_01(0)),time_string(time_01((n_elements(time_01)-1)/4)), time_string(time_01((n_elements(time_01)-1)*2/4)),time_string(time_01((n_elements(time_01)-1)*3/4)), time_string(time_01(n_elements(time_01)-1))];,xrange = [time_01(0),ed_time],ytitle='Res sq';,yrange = [-30,30]
;plot,data_03,yticks = 6;data_01,psym=0,xrange = [16600,17000], yrange = [-150,150];,xcharsize=1.25,ycharsize=1.25
;plot,data_02,psym=0;
;plot,data_04;data_02,psym=0,xrange = [100,500];,psym=7;


end
