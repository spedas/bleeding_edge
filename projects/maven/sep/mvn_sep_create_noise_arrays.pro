

pro mvn_sep_create_noise_arrays,data_str,tname=tname,prefix=prefix

if n_elements(prefix) eq 0 then prefix='mvn_'
if keyword_set(data_str) then begin
   t = data_str.time
   data = transpose(data_str.data)
;   value = findgen(256)
;   map = byte(median(data_str.mapid))    
endif else begin
   return
;   if not keyword_set(tname) then begin
;     mvn_sep_create_subarrays,tname = prefix+ 'sep1',bmaps=bmaps
;     mvn_sep_create_subarrays,tname = prefix+ 'sep2',bmaps=bmaps
;     return
;   endif
;   get_data,tname+'_svy_DATA',t,data,value
endelse

nt = n_elements(t)
sidename = '_'+['A','B']
for s=0,1 do begin
   store_data,tname+sidename[s]+'_sigma',t, transpose(data_str.sigma[s*3:s*3+2]) ,dlimit ={colors:'bgr',yrange:[.5,2],ystyle:1,psym:-3,labels:['O','T','F'],labflag:-1}
   store_data,tname+sidename[s]+'_baseline',t, transpose(data_str.baseline[s*3:s*3+2]) ,dlimit ={colors:'bgr',yrange:[-1,1],ystyle:1,psym:-3,labels:['O','T','F'],labflag:-1}
   store_data,tname+sidename[s]+'_total',t, transpose(data_str.tot[s*3:s*3+2]) ,dlimit ={colors:'bgr',ystyle:1,psym:-3,labels:['O','T','F'],labflag:-1}
endfor
end


