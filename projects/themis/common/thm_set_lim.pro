;+
;Purpose:
;This is a helper procedure that will set the maximum and minimum for a given mnemonic
;within a specific time range (used by thm_fitmom_overviews and thm_fitgmom_overviews)
;
;Example:
; thm_fitmom_overviews,'2007-03-23','b',dir='~/out',device='z'
;
; $LastChangedBy: lphilpott $
; $LastChangedDate: 2012-06-15 12:50:32 -0700 (Fri, 15 Jun 2012) $
; $LastChangedRevision: 10570 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/common/thm_set_lim.pro $
;-

pro thm_set_lim,mnem,start,stop,min,max,log

COMPILE_OPT idl2,hidden

if tnames(mnem) then begin 

   get_data,mnem,data=d

   if(n_elements(d) eq 1) then begin

      t_idx = where(d.x ge start and d.x le stop)

      n = size(d.y,/n_dim)

   
      if(t_idx[0] eq -1) then begin
         ylim,mnem,min,max,log
         return
      endif


      if(n eq 1) then dy = d.y[t_idx] $
      else if(n eq 2) then dy = d.y[t_idx,*] $
      else if(n eq 3) then dy = d.y[t_idx,*,*] $
      else message,'cannot handle n_dim'

      i_idx = where(finite(dy))

      if(i_idx[0] ne -1) then dy = dy[i_idx]

      min2 = min(dy)
      max2 = max(dy)

      if(min2 lt min) then minf = min else minf=min2
      if(max2 gt max) then maxf = max else minf=max2

   endif else begin
      
      min2 = -1*!VALUES.D_INFINITY
      max2 = !VALUES.D_INFINITY
   
      for i=0,n_elements(d)-1 do begin 

         get_data,d[i],data=d2

         If(is_struct(d2) Eq 0) Then continue ;jmm, 3-jan-2009

         t_idx = where(d2.x ge start and d2.x le stop)

         n = size(d2.y,/n_dim)

         if(t_idx[0] eq -1) then continue

         if(n eq 1) then dy = d2.y[t_idx] $
         else if(n eq 2) then dy = d2.y[t_idx,*] $
         else if(n eq 3) then dy = d2.y[t_idx,*,*] $
         else message,'cannot handle n_dim'

         i_idx = where(finite(dy))

         if(i_idx[0] ne -1) then dy = dy[i_idx]

; The following two lines are syntax errors, jmm, 12-jun-2008
;         min2 = min(dy,min2)
;         max2 = max(dy,max2)
         min2i = min(dy)
         max2i = max(dy)
         If(i Eq 0) Then Begin
           min2 = min2i & max2 = max2i
         Endif Else Begin
           If(min2i Lt min2) Then min2 = min2i
           If(max2i Gt max2) Then max2 = max2i
         Endelse
      endfor
   
      if(min2 lt min) then minf = min else minf=min2
      if(max2 gt max) then maxf = max else minf=max2

;      minf = max(min2,min)
;      maxf = min(max2,max)
;      if(max2 gt maxf) then maxf = max else minf=max2
   endelse

   ylim,mnem,minf,maxf,log

endif else begin
   dprint,'Mnemonic does not exist: ' + mnem
endelse

end