;+
;Procedure: tplot_quaternion_rotate, vectorname, quatname, name=name
;
;PURPOSE:
;  Rotates a tplot vector using the tplot quaternion. Will create a new tplot variable.
;  This function may be used with the "fit" curve fitting procedure.
;
;Written by: Davin Larson
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-12-16 13:28:30 -0800 (Wed, 16 Dec 2020) $
; $LastChangedRevision: 29513 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_quaternion_rotate.pro $
;-

pro tplot_quaternion_rotate,vecname,quatname,names=names,newname=newname

names=[]
vecnames = tnames(vecname,nvecnames)
quatnames = tnames(quatname,nquatnames)
if nvecnames eq 0 then begin
  dprint,'No Vector names found to transform'
endif

if nquatnames eq 0 then begin
  dprint,'No Quaternion names found to transform'
endif

for i=0,nvecnames-1 do begin
   get_data,vecnames[i],data=vec
   if ~keyword_set(vec) then begin
     dprint,'tplot vector variable: ',vecnames[i],' Not found!'
     continue
   endif
   for j=0,nquatnames-1 do begin
      get_data,quatnames[j],data=quat
      if ~keyword_set(quat) then begin
        dprint,'tplot quaternion variable: ',quatnames[j],' Not found!'
        continue
      endif
      vname = vecnames[i]
      qname = quatnames[j]

      if ~keyword_set(newname) then begin
        name = vname
        p = strpos(vname,'_',/reverse_search)
        coord1a = strmid(vname,p+1)
        rotname = strmid( qname, strpos(/reverse_search,qname,'_')+1 )
        coord1 = strmid(rotname,0,strpos(rotname,'>'))
        coord2 = strmid(rotname,strpos(rotname,'>')+1)
        if coord1a ne coord1 then begin
          dprint,dlevel=1,'Warning! Improper coord transform: '+coord1a+' '+coord1
          name += '_'+rotname
        endif else    str_replace,name,'_'+coord1a, '_'+coord2
        ;         name = vecnames[i]+'_R('+quatnames[j]+')'
        ;         newname = vecnames[i]
        ;         newname = strmid(newname,strpos(/reverse,newname,'_'))

      endif else begin
        name = newname
      endelse
      quati = interp(quat.y,quat.x,vec.x,/no_extrap,/ignore_nan)
      quati /= sqrt(total(quati^2,2)) # replicate(1,4)
      newvec  = quaternion_rotation(vec.y , quati)
      store_data,name,data={x:vec.x,y:newvec},dlimit={colors:'bgr',quaternion_name:qname}
      append_array,names,name
   endfor
endfor


end


; tplot_quaternion_rotate,'sta_B_8Hz_SC','sta_euler_param_SC>RTN'

