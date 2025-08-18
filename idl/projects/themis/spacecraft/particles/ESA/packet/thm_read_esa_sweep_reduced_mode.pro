;+
;PROCEDURE:	thm_read_esa_sweep_reduced_mode
;PURPOSE:	
;	Returns data structure with energy sweep tables
;INPUT:		
;	fm	int		flight model of esa sensor for energy calibration
;
;KEYWORDS:
;
;CREATED BY:	J. McFadden
;VERSION:	1
;LAST MODIFICATION:  07/03/22
;MOD HISTORY:
;
;NOTES:	  
;	Used by thm_load_esa_pkt.pro
;-
function thm_read_esa_sweep_reduced_mode,fm

; Ion Energy modes, 0-5

i_energy=fltarr(32,8)
i_denergy=fltarr(32,8)
i_nenergy=intarr(8)
i_cal=[1.539,1.501,1.497,1.501,1.519,1.5,1.5]

; Ion mode 0 - sweep mode 0, ~1/2 sweep, no linear, I&T mode
	dac=thm_esa_energy_steps(xstart=8181,xslope=16,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
; the following line is for LEO testing
	dac=thm_esa_energy_steps(xstart=16383,xslope=17,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	tmp=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	i_energy(0:15,0)=(tmp(2*indgen(16))+tmp(2*indgen(16)+1))/2.
	tmp(0)=0.
	tmp(1:30)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	tmp(31)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	i_denergy(1:15,0)=(tmp(2*indgen(15)+2)+tmp(2*indgen(15)+3))
	i_nenergy(0)=16

; Ion mode 1 - sweep mode 1, Full sweep, no linear, Msph mode
	dac=thm_esa_energy_steps(xstart=16383,xslope=17,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	i_energy(*,1)=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	i_denergy(1:30,1)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	i_denergy(31,1)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	i_nenergy(1)=32

; Ion mode 2 - sweep mode 1, Full sweep, no linear, Msph mode
	dac=thm_esa_energy_steps(xstart=16383,xslope=17,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	tmp=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	i_energy(0:15,2)=tmp(0:15)
	i_energy(16:23,2)=(tmp(2*indgen(8)+16)+tmp(2*indgen(8)+17))/2.
	tmp(0)=0.
	tmp(1:30)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	tmp(31)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	i_denergy(0:15,2)=tmp(0:15)
	i_denergy(16:23,2)=(tmp(2*indgen(8)+16)+tmp(2*indgen(8)+17))
	i_nenergy(2)=24
	
; Ion mode 3 - sweep mode 2, ~1/4 sweep, no linear, solar wind mode
	dac=thm_esa_energy_steps(xstart=4146,xslope=17,cstart=0,cslope=0,number=128,retrace=3,dblsweep=1)	
	tmp=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	i_energy(0:15,3)=tmp(0:15)
	tmp(1:15)=i_cal(fm-1)*(1.*dac(3,0:14)+dac(0,1:15)-dac(3,1:15)-dac(0,2:16))/2.
	i_denergy(1:15,3)=tmp(1:15)
	i_nenergy(3)=16

; Ion mode 4 - sweep mode 3, Full sweep, no linear, shock mode - no low energies
	dac=thm_esa_energy_steps(xstart=16383,xslope=11,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	i_energy(*,4)=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	i_denergy(1:30,4)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	i_denergy(31,4)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	i_nenergy(4)=32

; Ion mode 5 - sweep mode 3, Full sweep, no linear, shock mode - no low energies
	dac=thm_esa_energy_steps(xstart=16383,xslope=11,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	tmp=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	i_energy(0:3,5)=(tmp(2*indgen(4))+tmp(2*indgen(4)+1))/2.
	i_energy(4:19,5)=tmp(8:23)
	i_energy(20:23,5)=(tmp(2*indgen(4)+24)+tmp(2*indgen(4)+25))/2.
	tmp(0)=0.
	tmp(1:30)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	tmp(31)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	i_denergy(0,5)=0.
	i_denergy(1:3,5)=(tmp(2*indgen(3)+2)+tmp(2*indgen(3)+3))
	i_denergy(4:19,5)=tmp(8:23)
	i_denergy(20:23,5)=(tmp(2*indgen(4)+24)+tmp(2*indgen(4)+25))
	i_nenergy(5)=24

; Ion mode 6 - sweep mode 1, Full sweep, no linear, Msph mode, low E
  dac=thm_esa_energy_steps(xstart=16000,xslope=38,cstart=124,cslope=4,number=128,retrace=2,dblsweep=0)  
  i_energy(*,6)=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
  i_denergy(1:30,6)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
  i_denergy(31,6)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
  i_nenergy(6)=32

; Ion mode 7 - sweep mode 1, Full sweep, no linear, Msph mode, low E,
;              24 energies, analagous to ion mode 2
  dac=thm_esa_energy_steps(xstart=16000,xslope=38,cstart=124,cslope=4,number=128,retrace=2,dblsweep=0)  
  tmp=i_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
  i_energy(0:15,7)=tmp(0:15)
  i_energy(16:23,7)=(tmp(2*indgen(8)+16)+tmp(2*indgen(8)+17))/2.
  tmp(0)=0.
  tmp(1:30)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
  tmp(31)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
  i_denergy(0:15,7)=tmp(0:15)
  i_denergy(16:23,7)=(tmp(2*indgen(8)+16)+tmp(2*indgen(8)+17))
  i_nenergy(7)=24

; Electron Energy modes

e_energy=fltarr(32,6)
e_denergy=fltarr(32,6)
e_nenergy=intarr(6)

e_cal=[1.939,1.905,1.907,1.905,1.927,1.9]

; Electron mode 0 - 1/2 sweep, no linear, I&T mode
	dac=thm_esa_energy_steps(xstart=8191,xslope=16,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
; the following line is for LEO testing
	dac=thm_esa_energy_steps(xstart=16383,xslope=17,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	tmp=e_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	e_energy(0:15,0)=(tmp(2*indgen(16))+tmp(2*indgen(16)+1))/2.
	tmp(0)=0.
	tmp(1:30)=i_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	tmp(31)=i_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	e_denergy(1:15,0)=(tmp(2*indgen(15)+2)+tmp(2*indgen(15)+3))
	e_nenergy(0)=16

; Electron mode 1 - Full sweep, no linear, Msph mode
	dac=thm_esa_energy_steps(xstart=16383,xslope=17,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	e_energy(*,1)=e_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	e_denergy(1:30,1)=e_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	e_denergy(31,1)=e_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	e_nenergy(1)=32
	
; Electron mode 2 - 1/4 sweep, no linear, solar wind mode
	dac=thm_esa_energy_steps(xstart=4095,xslope=15,cstart=0,cslope=0,number=128,retrace=3,dblsweep=0)	
	e_energy(*,2)=e_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	e_denergy(1:30,2)=e_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	e_denergy(31,2)=e_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	e_nenergy(2)=32

; Electron mode 3 - Full sweep, linear at Low Energy, Msph mode
;   this mode had illegal values for parameters and was only used for about 12 days on THB starting 20140206
	dac=thm_esa_energy_steps(xstart=16383,xslope=19,cstart=15,cslope=2,number=128,retrace=3,dblsweep=0)	
;	e_energy(*,3)=e_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4. 
;	e_denergy(1:30,3)=e_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
;	e_denergy(31,3)=e_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	e_energy(*,3)=e_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4. > 0.0001
	e_energy(25:31,3) = 1.
	e_denergy(2:24,3)=e_cal(fm-1)*(1.*dac(3,1:23)+dac(0,2:24)-dac(3,2:24)-dac(0,3:25))/2.
	e_nenergy(3)=32

; Electron mode 4 - Revised low energy sweep, Msph mode
	dac=thm_esa_energy_steps(xstart=16375,xslope=19,cstart=31,cslope=1,number=128,retrace=3,dblsweep=0)	
	e_energy(*,4)=e_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
	e_denergy(1:30,4)=e_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
	e_denergy(31,4)=e_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
	e_nenergy(4)=32
	
; Electron mode 5 - Full sweep, no linear, Msph mode, low E
  dac=thm_esa_energy_steps(xstart=16000,xslope=38,cstart=124,cslope=4,number=128,retrace=2,dblsweep=0)  
  e_energy(*,5)=e_cal(fm-1)*(1.*dac(0,*)+dac(1,*)+dac(2,*)+dac(3,*))/4.
  e_denergy(1:30,5)=e_cal(fm-1)*(1.*dac(3,0:29)+dac(0,1:30)-dac(3,1:30)-dac(0,2:31))/2.
  e_denergy(31,5)=e_cal(fm-1)*(1.*dac(3,30)+dac(0,31)-2.*dac(3,31))/2.
  e_nenergy(5)=32
  

mode={i_energy:i_energy,i_denergy:i_denergy,i_nenergy:i_nenergy,$
	e_energy:e_energy,e_denergy:e_denergy,e_nenergy:e_nenergy}

return,mode

end

