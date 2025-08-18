;+
;Function: THM_FBK_DECOMPRESS
;
;Purpose:  Decompresses DFB FBK spectral data.
;Arguements:
;	DATA, any BYTE data type (scalar or array), 8-bit compressed FBK band-pass amplitude estimates.
;keywords:
;   VERBOSE.
;Example:
;   result = thm_fbk_compress( data)
;
;Notes:
;	-- none.
;
; $LastChangedBy: jimm $
; $LastChangedDate: 2007-11-16 12:28:13 -0800 (Fri, 16 Nov 2007) $
; $LastChangedRevision: 2043 $
; $URL $
;-
function thm_fbk_decompress, data, verbose=verbose

thm_init

   x=ulong(data)

   ;--- separate xxxx and yyyy ---
   n = x/16UL
   y = x and 15UL

   ;--- decompress ---
   z = ulonarr( size( data, /dim) > 1)
   indx = where(n eq 0, count, complement=indx2, ncomplement=count2)
   if (count gt 0)  then z[indx]= y[indx]
   if (count2 gt 0) then $
     z[indx2]=(y[indx2]+16UL)*2UL^(n[indx2]-1UL)
return, float(z)
end