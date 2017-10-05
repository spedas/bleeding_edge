pro barrel_sp_patch_drmrow,f
;Look for the signature of an upward spike and zero out above that:
n=n_elements(f)
shift = shift(f,1)
a=f[1:n-1]
b=shift[1:n-1]
w=where(a gt b*1000.,nw)
if nw GT 0 then begin
   f[w[0]:n-1]=0.d
endif
end

