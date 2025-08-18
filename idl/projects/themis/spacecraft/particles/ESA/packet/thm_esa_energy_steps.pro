pro print_sweep_params,iesa=pi,eesa=pe,filename=file
common lastsweeps_com, pil,pel

if keyword_set(file) then openw,lun,file,/get_lun else lun = -1
if keyword_set(pi) then begin
   if not keyword_set(pel) then pel=pi
   pil = pi
   printf,lun,format='("/iesarawhex ",Z06,"    ; Ion   Xstart=",i5)', 'E00000'x or (pil.xstart*4 and 'FFFF'x), pil.xstart
   printf,lun,format='("/iesarawhex ",Z06,"    ; Ion   Cstart=",i5)', 'E30000'x or (pil.cstart*4 and 'FFFF'x), pil.cstart
   word = (pil.xslope * 2ul^8 + pil.cslope ) and 'FFFF'x
   printf,lun,format='("/iesarawhex ",Z06,"    ; Ion   Xslope=",i4, "    Cslope=",i4)', 'E20000'x or word, pil.xslope,pil.cslope
endif
if keyword_set(pe) then begin
   if not keyword_set(pil) then pil=pe
   pel = pe
   printf,lun,format='("/iesarawhex ",Z06,"    ; Elec  Xstart=",i5)', 'E10000'x or (pel.xstart*4 and 'FFFF'x), pel.xstart
   printf,lun,format='("/iesarawhex ",Z06,"    ; Elec  Cstart=",i5)', 'E40000'x or (pel.cstart*4 and 'FFFF'x), pel.cstart
   word = (pel.xslope * 2ul^8 + pel.cslope ) and 'FFFF'x
   printf,lun,format='("/iesarawhex ",Z06,"    ; Elec  Xslope=",i4, "    Cslope=",i4)', 'E50000'x or word, pel.xslope,pel.cslope
endif
if keyword_set(pe) or keyword_set(pi) then begin
   word = (pil.retrace * 2ul^4 + pel.retrace ) and 'FFFF'x
   printf,lun,format='("/iesarawhex ",Z06,"    ; I retrace=",i3, "     E retrace=",i3)', 'E60000'x or word, pil.retrace,pel.retrace
   word = 0
   if pil.dblsweep then word = '8000'x else word = 0
   if pel.dblsweep then word = word or '4000'x
   printf,lun,format='("/iesarawhex ",Z06,"    ; I dblsweep=",i3, "     E dblsweep=",i3)', 'E70000'x or word, pil.dblsweep,pel.dblsweep
endif
if lun gt 0 then free_lun,lun

end

;pro print_esteps,esteps
;period =93.81*32
;for i=0,n_elements(esteps)-1 do begin
;   print,i,(i+.5)*period/32/128,esteps[i],esteps[i]*5./(2ul^14-1)
;endfor
;end



function thm_esa_energy_steps,xstart=xstart,xslope=xslope,cstart=cstart $
    ,cslope=cslope,number=n,bsh=bsh,retrace=retrace,dblsweep=dblsweep,verbose=verbose,sweep=p
if not keyword_set(n) then n=128
if n_elements(retrace) eq 0 then retrace=8
if n_elements(dblsweep) eq 0 then dblsweep=0
if not keyword_set(bsh) then bsh = 8
div = 2^bsh
if n_elements(cslope) eq 0 then cslope=16
if not keyword_set(cstart) then cstart=cslope*(n-retrace) /4
if n_elements(xslope) eq 0 then xslope = uint(.09 * div)
if n_elements(xstart) eq 0 then xstart = uint(-1)/4 - cstart/4
dac = uintarr(4,n/4)
xstart = long(xstart)
xslope = fix(xslope)
cstart = long(cstart)
cslope = fix(cslope)
if keyword_set(verbose) then help,xstart,cstart,xslope,cslope,div
p = {xstart:xstart, xslope:xslope, cstart:cstart, cslope:cslope, retrace:retrace, dblsweep:dblsweep, number:n}
if keyword_set(verbose) then printdat,p
x = xstart   * 16                      ; note: x is 18 bit
c = cstart   * 4
for i=0,n-1 do begin
   dac[i] = (x + c) / 16
   if keyword_set(verbose) then  dprint, i,x,c,dac[i], (i+.5)/128.*93.81, dac[i] * 5./ (2ul^14-1), dac[i]*35000./2ul^14
   if i ge retrace then begin
     x = x -   x*xslope /div
     c = c - cslope
   endif

endfor
;if keyword_set(verbose) then print,dac
return,dac
end



;esteps = esa_energy_steps(sweep=pe,xstart=0,cstart=496,retrace=4,/verb)
;isteps = esa_energy_steps(sweep=pi,xstart=0,cstart=495,retrace=4,/verb)
;esteps = esa_energy_steps(sweep=pe,retrace=0,dblsweep=1,/verb)
;isteps = esa_energy_steps(sweep=pi,retrace=4,/verb)
;print_sweep_params,eesa=pe,iesa=pi,file='scripts/esa_sweep.txt'

;plot,esteps > isteps,/nodata
;oplot,esteps,psym=10,color=3
;oplot,isteps,color=5,psym=10

;end
