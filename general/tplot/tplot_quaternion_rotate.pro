;+
;Procedure: tplot_quaternion_rotate, vectorname, quatname, name=name
;
;PURPOSE:
;  Rotates a tplot vector using the tplot quaternion. Will create a new tplot variable.
;  This function may be used with the "fit" curve fitting procedure.
;
;Written by: Davin Larson
;
; $LastChangedBy: davin-win $
; $LastChangedDate: 2011-02-15 16:17:03 -0800 (Tue, 15 Feb 2011) $
; $LastChangedRevision: 8224 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_quaternion_rotate.pro $
;-

pro tplot_quaternion_rotate,vecname,quatname,name=name


vecnames = tnames(vecname,nvecnames)
quatnames = tnames(quatname,nquatnames)
for i=0,nvecnames-1 do begin
   get_data,vecnames[i],data=vec
   for j=0,nquatnames-1 do begin
      get_data,quatnames[j],data=quat

      if keyword_set(vec) && keyword_set(quat) then begin
          vname = vecnames[i]
          qname = quatnames[j]
          p = strpos(vname,'_',/reverse_search)
          coord1a = strmid(vname,p+1)
          rotname = strmid( qname, strpos(/reverse_search,qname,'_')+1 )
          coord1 = strmid(rotname,0,strpos(rotname,'>'))
          coord2 = strmid(rotname,strpos(rotname,'>')+1)
          if coord1a ne coord1 then begin
             dprint,dlevel=1,'Warning! Improper coord transform: '+coord1a+' '+coord1
             vname += '_'+rotname
          endif else    str_replace,vname,'_'+coord1a, '_'+coord2
;         name = vecnames[i]+'_R('+quatnames[j]+')'
;         newname = vecnames[i]
;         newname = strmid(newname,strpos(/reverse,newname,'_'))
         quati = interp(quat.y,quat.x,vec.x,/no_extrap,/ignore_nan)
         quati /= sqrt(total(quati^2,2)) # replicate(1,4)
         newvec  = quaternion_rotation(vec.y , quati)
         store_data,vname,data={x:vec.x,y:newvec},dlimit={colors:'bgr'}
      endif
   endfor
endfor


end


; tplot_quaternion_rotate,'sta_B_8Hz_SC','sta_euler_param_SC>RTN'

