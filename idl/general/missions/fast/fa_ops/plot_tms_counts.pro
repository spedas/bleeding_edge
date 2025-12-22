;
; ipnt at any time gives the index corresponding to the 'firstplot' parameter
;
; There may be apparent peculiar effects at low energies; some of these
; just have to do with the ram direction and 3-D effects. Don't blame the
; program until after careful thought.
;
; In slow progress, expect to add real units sometime....

;+****************************************************************************
;PROGRAM    (main program, a few functions down....)
;       plot_tms_counts
;
;DESCRIPTION
;       function to calculate velocity of ions in a 2-D mag-field referenced system
;       and to plot each count as an individual symbol in polar angle-energy plot.
;       (The program also contains a presently non-functional option to do v_x-v_y plots.) 
;       In order not to have a number of symbols covering each other, each count is plotted
;       at a random position within the (energy,angle) acceptance range of a pixel.
;       There are various options to be entered intereactively by typing, all with defaults.
;        These include norm=1 to correct for the projection effect when the acceptance
;        range of teams covers  
;
;       A structure of the following format is used: 
;                 DATA_NAME       STRING    'Tms Burst All'
;                 TIMES           DOUBLE    Array(76)
;                 END_TIMES       DOUBLE    Array(76)
;                 DATA            FLOAT     Array(48, 16, 4, 76)
;                 ENERGY          DOUBLE    Array(48, 76)
;                 THETA           FLOAT     Array(16, 76)
;                 THETA_FOV       FLOAT     Array(16, 76)
;                 SPHASE          INT       Array(76)
;                 SNUMBER         BYTE      Array(76)
;                 MAGDIR          INT       Array(76)
;                 MASS            FLOAT     Array(4)
;                 GEOMFACTOR      FLOAT        0.00150000
;                 HEADER_BYTES    BYTE      Array(44, 76)
;                 HDR_TIME        DOUBLE    Array(76)
;                 EFF_VERSION     FLOAT           1.00000
;
;CALLING SEQUENCE
;       plot__tms_counts, dat
;
;ARGUMENTS
;       dat              data structure in plot_dists.sav
;
;KEYWORDS
;
;RETURN VALUE
;
;REVISION HISTORY
;       Written by Jennifer Law, Cheryl Kang, and Tim Lee
;       July 18, 1997
;       Repeatedly modified by m. boehm, last aug 25, 1997
;LAST MODIFICATION
;
;
;-****************************************************************************


; 
;+****************************************************************************
; FUNCTION
;       logtick
;
; DESCRITPION
; very specific routine for formatting labels on a  logarithmic
; polar dist fn plot. The values are expected to run -5 to 5.
; Absolute valeus of these values are taken, and they are then
; regarded as log base 10 of the energy, with an offset such that
; 0 represents 0.0001 keV. The actual labeling in keV is to start at
; .01 keV (input value 2) and run upwards to what ever values are presented.
; This is a separate routine only because the [xyz]tickformat graphics 
; keyword requires it.
function logtick,axis,index,value  ; axis and index exist here because [xyz]tickformat
                                    ; passes them; not used.
common pllims,plotlim,plotlim0
truevalue=exp((abs(value)-4.)*alog(10.))*plotlim0(0) ; plotting is done explcitly
 ; in log-10 coordinates, with 0 radius corresponding to plotlim0(0)/10. (in eV)
 ; (alog is natural log, not anti-log; -4 rather than -1 because labeling is in keV, not eV) 
;print,truevalue
if abs(value) ge .1 then retstring=string(truevalue,format="(f6.2)")
if abs(value) lt .1 then retstring=' '
return,retstring
end


;--------------------------------------------------------------------------
function pointsplot, s, counts, psym, color, alpha_l, alpha_u, vtotal_l, vtotal_u
;--------------------------------------------------------------------------
;function to plot symbols psym of color 'color' at random positions
;within the polar region defined by the alpha_l, alpha_u,vtotal_l,vtotal_u
;(lower angle, uppper angle, lower radius, upper radius)
; 

if counts eq 0 then return,0 
randomangle=fltarr(counts) & randomvtotal=fltarr(counts)

randomangle=randomu(s, counts)
randomvtotal=randomu(s, counts)

oplot, /polar, (randomvtotal)*(vtotal_u-vtotal_l)+vtotal_l, $
(randomangle)*(alpha_u-alpha_l)+alpha_l,  psym=psym, color=color   

return,1
end 

;--------------------------------------------------------------------------
function pointsplot2, s, counts, psym, color, alpha_l, alpha_u, etotal_l, etotal_u,norm
;--------------------------------------------------------------------------
;
; Use norm=0 only if using for velocity plotting; normalizations not done right
; in that case.    mb aug 20 1997
;
; function to plot symbols psym of color 'color' at random positions
; within the polar region defined by the alpha_l, alpha_u,etotal_l,etotal_u
; (lower angle, uppper angle, lower radius, upper radius)
; If norm=true (anything other than 0), 
; then the number of counts is first normalized by the area of the angular
; sector in the display, i.e. mainly by multiplying by |alpha_u-alpha_l|/(22.5*!dtor).
; Energy normalization is only marginally necessary in a log display,
; but is done. Note that etotal_l, etotal_u are normally brought in as alog10(energy)+
; offset. At the moment, this is essential to the normalized mode of the program mb aug20 97.
; All counts are then also multiplied by 'norm', unless norm=0.
; this allows the plotting of overly large numbers of counts.

if counts eq 0 then return,0 
if norm ne 0 then begin 
 ncounts=((etotal_u-etotal_l)/.0877)* $   ; .0877 is the average difference of alog10(energy)'s
     (abs(alpha_u-alpha_l)/(22.5*!dtor))*norm*counts ; normalize (to float) # of counts
 counts=fix(ncounts)+fix(ncounts-fix(ncounts)+randomu(s)) ; translate fractional count to 
                                   ; a probability of an extra count. Counts=integer now.  
endif
if counts eq 0 then begin return,0 & endif
randomangle=fltarr(counts) & randomvtotal=fltarr(counts)
randomangle=randomu(s, counts)
randometotal=randomu(s, counts)
oplot, /polar, (randometotal)*(etotal_u-etotal_l)+etotal_l, $
       (randomangle)*(alpha_u-alpha_l)+alpha_l,  psym=psym, color=color 
return,1
end 







;-------------------------------------------------------------------------------
; dat=get_fa_tball_ts('1997-02-09/19:41:20','1997-02-09/19:41:50')        ;  orbit 1864


;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
pro plot_tms_counts, dat
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------

common colors,r_orig,b_orig,g_orig,r_curr,g_curr,b_curr
common pllims,plotlim,plotlim0

;********************************************************************************
;*******************************************************************************
; Section 1: setup, determine mag field direction and pitch angles and energies of bin boundaries
;****************************************************************************
print,'"loadct,39" expected to have been done'
;r_curr(10:14)=[0,0,195,255,255] & g_curr(10:14)=[212,255,255,180,205] & b_curr(10:14)=[255,127,0,255,0]
; the above was an attempt to get equal brightnesses for several colors on the screen, i.e.
; colors to use for mass symbols on screen=[[0,212,255],[0,255,127],[195,255,0],[255,180,255],[255,205,0]]
; for printing, three colors were optimised
cstart=!d.table_size-32
;r_curr(cstart:cstart+4)=[0,0,195,255,255] & g_curr(cstart:cstart+4)=[212,255,255,180,205] & b_curr(cstart:cstart+4)=[255,127,0,255,0]
; the above was an attempt to get equal brightnesses for several colors on the screen, i.e.
; colors to use for mass symbols on screen=[[0,212,255],[0,255,127],[195,255,0],[255,180,255],[255,205,0]]
; for printing, three colors were optimised
r_curr(cstart:cstart+4)=[0,0,255,200,100] 
g_curr(cstart:cstart+4)=[212,255,205,150,255] 
b_curr(cstart:cstart+4)=[255,127,0,200,200]
tvlct,r_curr,g_curr,b_curr


if (size(dat))(0) eq 0 then begin print, "structure 'dat' undefined;"
    print,"Use statement of the form dat=get_fa_tball_ts('1997-02-09/19:41:20','1997-02-09/19:41:50')"
    return
endif
s=438659456780l  ; random number generator input value

vi=sqrt((2*dat.energy)/dat.mass(1)) ; 'velocity' to be used for linear
                                    ; velocity scale plot

magsource=' '
repeat begin 
  read,magsource,format='(a)', $
    prompt='Enter magnetic field source: sp (for sphase,magdir) or mag (requires MagXDC etc in sdt):'
  magsource=strlowcase(magsource)
end   until magsource eq 'sp' or magsource eq 'mag' 

magn=fltarr(dat.npts,3)
case magsource of ; calculate mag direction in s/c system for dat.times
 'mag': begin $ ; read mag field data from sdt
    sttime=dat.times(0) & endtime=dat.times(dat.npts-1) 
    mdat=get_fa_fields('MagDC',sttime,endtime)
    magx=interpol(mdat.comp1,mdat.time,dat.times)
    magy=interpol(mdat.comp2,mdat.time,dat.times)
    magz=interpol(mdat.comp3,mdat.time,dat.times)
    magtotal=sqrt(magx^2+magy^2+magz^2)
    minpa=abs(asin(magz/magtotal))
    magn(*,0)=magx/magtotal & magn(*,1)=magy/magtotal & magn(*,2)=magz/magtotal ; magn normalized to 1

   end 
 'sp': begin $ ; assume magnetic field lying in spin plane
    phi_b=-2*3.14159*(dat.magdir/4096.+dat.sphase/1024.)+3.14159 ;phi_B (dat.npts)
       ; angle of magnetic field in radians form having [3,4] particle direction field-aligned
    magn(*,0)=cos(phi_b)   ; spacecraft-x component
    magn(*,1)=sin(phi_b)    ; spacecraft-y component
    magn(*,2)=0.            ; spacecraft-z component
    minpa=fltarr(dat.npts)
   end
endcase   
         
magnarr=fltarr(48,dat.npts,3) ; interpolated array for different energies
          ; has accuracy problems with acos later, so normalize afterwards
for i=0,47 do begin 
  magnarr(i,*,*)=((47.-i)/47.)*magn+(float(i)/47.)*shift(magn,-1)
   ; plus exception for the last time point:
  magnarr(i,dat.npts-1,*)=magn(dat.npts-1,*)+(float(i)/47.)*(magn(dat.npts-1,*)-magn(dat.npts-2,*))
end
magtarr=sqrt(total(magnarr^2,3))
for i=0,2 do begin $
  magnarr(*,*,i)=magnarr(*,*,i)/magtarr & $
end

theta_fov=dat.theta_fov*!dtor
theta_fovlower=fltarr(16,dat.npts) & theta_fovupper=fltarr(16,dat.npts)
for i=1,14 do begin $
   theta_fovlower(i,*)=(theta_fov(i-1,*)+theta_fov(i,*))/2
   theta_fovupper(i,*)=(theta_fov(i+1,*)+theta_fov(i,*))/2
endfor
              ;for i=0
   theta_fovlower(0,*)=1.5*theta_fov(0,*)-0.5*theta_fov(1,*)
   theta_fovupper(0,*)=(theta_fov(1,*)+theta_fov(0,*))/2.
       
              ;for i=15
   theta_fovlower(15,*)=(theta_fov(14,*)+theta_fov(15,*))/2.
   theta_fovupper(15,*)=-0.5*theta_fov(14,*)+1.5*theta_fov(15,*)

vx_cn=fltarr(16,dat.npts) ; spacecraft-x, norm. ion velocities at centers of sectors
vz_cn=fltarr(16,dat.npts) ; spacecraft-z, norm. ion velocities at centers of sectors
vx_un=fltarr(16,dat.npts) ; spacecraft-x, norm. ion velocities at 'upper' boundaries of sectors
vz_un=fltarr(16,dat.npts) ; spacecraft-z, norm. ion velocities at 'upper' boundaries of sectors
vx_ln=fltarr(16,dat.npts) ; spacecraft-x, norm. ion velocities at 'lower' boundaries of sectors
vz_ln=fltarr(16,dat.npts) ; spacecraft-z, norm. ion velocities at 'lower' boundaries of sectors

for i=0,15 do begin
   vx_cn(i,*)=-cos(theta_fov(i,*))    ; norm velocity com perpendicular to spin axis 
   vz_cn(i,*)=-sin(theta_fov(i,*))   ; norm. velocity component along spin axis
   vx_un(i,*)=-cos(theta_fovupper(i,*)) ; norm vel com perpendicular to spin axis
   vz_un(i,*)=-sin(theta_fovupper(i,*)) ; norm vel com along spin axis (upper sector boundary)
   vx_ln(i,*)=-cos(theta_fovlower(i,*)) ; norm vel com perpendicular to spin axis
   vz_ln(i,*)=-sin(theta_fovlower(i,*)) ; norm vel com along spin axis (lower sector boundary)
endfor
              ; magnarr(energy,npts,x-y-z); vxcn etc (theta,npts);   pac(energy,theta,npts)
       ; note that npts could potentially be up to 64/spin*~15 spins=1000, fltarr(48,16,npts) is up to 3 MBytes
       ; (then data in float form is 12 Mbytes)
alpha=fltarr(48,16,dat.npts) & alphalower=alpha & alphaupper=alpha
for i=0,15 do begin 
 for j=0,47 do begin 
   alpha(j,i,*)=acos(vx_cn(i,*)*magnarr(j,*,0)+vz_cn(i,*)*magnarr(j,*,2)) 
                                ; pitch angle of sector centers, no variation within sweep 
   alphalower(j,i,*)=acos(vx_ln(i,*)*magnarr(j,*,0)+vz_ln(i,*)*magnarr(j,*,2)) 
                                 ; pitch angle of sector lower boundaries, no variation within sweep 
   alphaupper(j,i,*)=acos(vx_un(i,*)*magnarr(j,*,0)+vz_un(i,*)*magnarr(j,*,2)) 
                               ; pitch angle of sector upper boundaries, no variation within sweep 
 endfor
endfor
 
if magsource eq 'mag' then begin   
; Now correct for cases where the minimum pitch angle falls in the middle of a sector
; i.e. the minimum (or maximum) pitch angle will be set to the angle between the detector
; plane and the magnetic field
 alphamin=fltarr(48,dat.npts)   ; just for easier interpretation and debugging
 alphamax=fltarr(48,dat.npts)       ; many time periods will be left 0
 for ipnt=0,dat.npts-1 do begin 
   alphamin(*,ipnt)=abs(asin(magnarr(*,ipnt,1))) 
   alphamax(*,ipnt)=!pi- alphamin(*,ipnt)
 endfor
 pointset=where(alphamin(24,*) lt 0.5) ; if minimum angle is not less than 30 deg,
                                  ; don't worry about it, i.e. no correction
 for i=0,(size(pointset))(1)-1 do begin $
  ipnt=pointset(i)
  maxl=max(alphalower(24,*,ipnt),sect_ind_maxl)
  maxu=max(alphaupper(24,*,ipnt),sect_ind_maxu)
  minl=min(alphalower(24,*,ipnt),sect_ind_minl)
  minu=min(alphaupper(24,*,ipnt),sect_ind_minu)
  if alphaupper(sect_ind_maxl) gt alphalower(sect_ind_maxu) then begin
    alphalower(*,sect_ind_maxl,ipnt)=alphamax(*,ipnt) ; sect_ind_maxl is the sector closest to B
  endif else begin
    alphaupper(*,sect_ind_maxu,ipnt)=alphamax(*,ipnt) ; sect_ind_maxu is closest to B
  endelse
  if alphaupper(sect_ind_minl) lt alphalower(sect_ind_minu) then begin
    alphalower(*,sect_ind_minl,ipnt)=alphamin(*,ipnt)
  endif else begin
    alphaupper(*,sect_ind_minu,ipnt)=alphamin(*,ipnt)
  endelse
 endfor
endif
    
vtotallower=fltarr(48) & etotallower=fltarr(48)
vtotalupper=fltarr(48) & etotalupper=fltarr(48)
vtotal=sqrt(2.*dat.energy(*,0)/dat.mass(1)) ; velocity assuming hydrogen
etotal=dat.energy(*,0)
       
for i=1,46 do begin $
   vtotallower(i)=(vtotal(i+1)+vtotal(i))/2
   vtotalupper(i)=(vtotal(i-1)+vtotal(i))/2
   etotallower(i)=(etotal(i+1)+etotal(i))/2
   etotalupper(i)=(etotal(i-1)+etotal(i))/2

endfor
       ;for i=0
   vtotalupper(0)=vtotal(0)+(-vtotal(1)+vtotal(0))/2
   vtotallower(0)=(vtotal(1)+vtotal(0))/2
   etotalupper(0)=etotal(0)+(-etotal(1)+etotal(0))/2
   etotallower(0)=(etotal(1)+etotal(0))/2
       
       ;for i=47
   vtotalupper(47)=(vtotal(47)+vtotal(46))/2
   vtotallower(47)=vtotal(47) + (vtotal(47)-vtotal(46))/2
   etotalupper(47)=(etotal(47)+etotal(46))/2
   etotallower(47)=etotal(47) + (etotal(47)-etotal(46))/2


;********************************************************************************
;*******************************************************************************
; Section 2: Read in variable parameters.
;****************************************************************************
       
psymset=['none(0)','+(1)','*(2)','.(3)','diamond(4)','triangle(5)','square(6)','X(7)','usersym(8)']
psym_ar=[5,4,2,6]

color_ar_x=[cstart+2,cstart+3,cstart,cstart+4]
color_ar_ps=[cstart+2,cstart+3,cstart,cstart+4]
color_ar=color_ar_x
firstplot=0 & nplotsx=2 & nplotsy=1
npts=dat.npts
lastpagestartplot=fix(npts-1-firstplot)-nplotsx*nplotsy
postscript=0
ps_string=['x','ps']
mass_set=['O+','H+','He+','He++'] 
mass_str=string(mass_set,format='(4(a,x))')
masses=mass_set
mode_string=['single page','movie'] & mode=0
scaletype='e'  
plotlim0=[etotallower(47),etotalupper(0)] & plotlim=[1.,alog10(plotlim0(1))-alog10(plotlim0(0))+1.]  
norm=0.
increment=1

while firstplot ge 0 do begin ;         start non-indented loop 0
 
; There appears to be no way to test whether a window exists already except by
; trying to switch to it, hence the following error handler. Other run-time errors
; will now not cause the program to stop; for debugging, "print, !ERR_STRING" 
; after an error is useful; to stop at the error, remove the following lines.
catch,error_status
 if error_status ne 0 then begin
  print, 'error index ', error_status, '   ',!err_string 
 if error_status eq -324 then begin window, win_num & print,'Window nonexistent, new created' & end
 end
instring='list' & instringm=' '
ftime='        '
repeat begin
 CASE STRLOWCASE(instring) OF
  'list':print,' firstplot        (f)= ', firstplot, $
        ' ,        ftime  (ft)= ', time_to_str(dat.times(firstplot)), $
        ' nplotsx         (nx)= ', nplotsx, $
        ' nplotsy         (ny)= ', nplotsy, $
        ' postscript (ps or x)= ', ps_string(postscript),$
        ' lastpagestartplot(l)= ', lastpagestartplot, $
        ' masses          (ma)= ', masses, $
        ' psym_ar       (psym)= ', psymset(psym_ar), '(order = ',mass_str,')',$
        ' mode            (mo)= ', mode_string(mode), '          (movie or single page)',$
        ' scaletype       (sc)= ', scaletype, '         (energy (log) or velocity (linear- probably not working))', $
        ' plotlim         (pl)= ', plotlim0, '         (eV or km/s)', $
        ' color_ar_ps  (carps)= ', color_ar_ps, $
        ' color_ar_x    (carx)= ', color_ar_x, $
        ' norm          (norm)= ', norm,    '        (type "norm" to get definition)',  $
        ' window           (w)= ', !d.window,     '       (number of current window)',$
        ' increment        (i)= ', increment, format= $
     '(a,i4,a,a,/,a,i2,/,a,i2,/,a,x,a,/,a, i3,/,a,4(a,2x),/,a,7(a,2x),/,3a,/,3a,/,a,2(f6.0,2x),a,/,a,4(i3,2x),/,a,4(i3,2x),/,a,f4.2,a,/,a,i1,a,/,a,i1,a)'
;        f   ftime   nx      ny      ps/x   last     masses      psym    mode scale        pl        carps       carx       norm       window   increment
  'f': read,firstplot,format='(i)', $
     prompt='Enter seq # of distribution (presently='+string(firstplot)+') to start at:'
  'ft': begin read,ftime,format='(a8)',prompt='Enter time in format "05:23:00"' &$
         ftime=strmid(time_to_str(dat.times(0)),0,11)+ftime 
        firstplot=(where(dat.times ge str_to_time(ftime)))(0) & end  
  'nx': read,nplotsx,format='(i)',prompt='Enter # of plots across page:'
  'ny': read,nplotsy,format='(i)',prompt='Enter # of plots down page:'
  'ps': begin postscript=1 & print, 'Plot type set to postscript'  & end
  'x': begin postscript=0 & print, 'Plot type set to X'  & end
  'l': read,lastpagestartplot,format='(i)', $
       prompt='Enter approximate seq # of plots on last page, max='+string(npts-nplotsx*nplotsy)+':'
  'ma': begin
        for i=0,3 do begin 
          read,instringm,format='(a)', $
            prompt='enter species in order to be plotted, last on top (O+,H+,He+, He++; other to inactivate):'
          masses(i)=instringm
        endfor
        print,' masses= ', masses, format='(5(a,x))'
       end
  'mo': read,mode,prompt='Enter 0 for one page at a time, 1 for movie (type any character to stop):'
  'sc': begin 
         read,scaletype,prompt='Enter e (log energy) or v (linear velocity) for plot scale:'
         if scaletype eq 'e' then begin plotlim0=[etotallower(47),etotalupper(0)] 
             plotlim=alog10(plotlim0)+1 & end ; alog10(energy)+1 will be the actual plot coord
         if scaletype eq 'v' then begin plotlim=[0.,sqrt(2*dat.energy(0)/dat.mass(1))] & norm=0. & end
        end
  'pl': begin  if scaletype eq 'e' then  begin
                   temp=reverse(etotalupper)
                   read,temp1,prompt='Enter lower, plot limit, eV:' & plotlim0(0)=temp1
                   if plotlim0(0) le etotallower(47) then plotlim0(1)=etotallower(0) else begin
                   plotlim0(0)=(etotallower(where(etotallower lt plotlim0(0))))(0) & endelse
                   read,temp1,prompt='Enter upper, plot limit, eV:' & plotlim0(1)=temp1
                   if plotlim0(1) ge etotalupper(0) then plotlim0(1)=etotalupper(0) else begin
                   plotlim0(1)=(temp(where(temp gt plotlim0(1))))(0) & endelse
                   plotlim(1)=alog10(plotlim0(1))-alog10(plotlim0(0))+1.   ; energy(data) needs
                             ; to be converted to plot coordinates with alog10(energy/plotlim(0))+1.
                    plotlim(0)=1 & end ; plotlim(0) is now the limit where symbols should actually be put
                if scaletype eq 'v' then begin read,plotlim0(1),prompt='Enter upper plot limit, km/s:'
                   plotlim(1)=plotlim0(1) & plotlim0(0)=0. & plotlim(0)=0.  & end
         end
  'psym': begin     print,'available symbols=',psymset(1:8)
          mass_str=string(mass_set,format='(4(a,x))')
         read,psym_ar,prompt='enter exactly 4 symbol indices in the sequence:'+mass_str+':'
         print,' New symbols in'+mass_str+'sequence:', psymset(psym_ar) & end
  'carps': begin   print,'present postscript color array for 4 masses=', color_ar_ps
           read,color_ar_ps, prompt='Enter exactly 4 color indices for ' $
            +mass_str+': ' &  end
  'carx': begin   print,'present x-display color array for 4 masses=', color_ar_x
           read,color_ar_x, prompt='Enter exactly 4 color indices for ' $
           +mass_str+': ' & end
  'norm': begin if scaletype eq 'e' then begin
              print,' norm=0. means display all counts without any changes for normalization.'
              print,' norm=1. means normalize counts to displayed angle range of sector (scaletype "e" only!)'
              print,' norm ne 0, norm ne 1., means same as norm=1., but then multiply counts by norm'
              print,' (fractional counts converted to a probablitiy of displaying a count)'
              read,norm,prompt='Enter floating point value for norm:'
            endif else begin norm=0. & print, 'scale type e, norm=0 unchanged'  & endelse 
          end
  'w': begin read,instring, prompt='Enter 0-9 to activate different window, preceded by ! to redraw'
        win_num=!d.window
        if strmid(instring,0,1) eq '!' then reads,instring,win_num,format='(1x,i1)' else begin
                                            reads,instring,win_num,format='(i1)' & endelse
        if strmid(instring,0,1) eq '!' then window, win_num     else wset, win_num 
       end
   'i': read,increment,prompt='Enter 1 to increment firstplot by nx*ny, 0 for firstplot=constant, -n to increment by n'
   else: print,'Unrecognized input'
 endcase
 if mode eq 1 and postscript eq 1 then print,'Warning: Movie mode set in postscript' 
 read,instring,$
  prompt='To change a parameter enter a string listed in parentheses; or enter "list", "p" for plot, or "exit":'
 if instring eq 'exit' then return
end until instring eq 'p'

;   lastpagestartplot=nplotsx*nplotsy*fix(lastpagestartplot-firstplot)/(fix(nplotsx*nplotsy))+$
;              firstplot ; make sure the difference from first to last is an even # of pages

  
if mode eq 1 then begin
  lastpnt=min([dat.npts-1,lastpagestartplot])-nplotsx*nplotsy+1 ; 1 -> movie
  end else begin
  lastpnt=firstplot ; do single page only
endelse 

if postscript then begin 
   filestring=' ' 
   read, filestring, prompt='Save as (filename): ' 
   set_plot, 'ps', /copy
   device, filename=filestring 
   !p.font=0
   device,/times
   device, /color 
   device,ysize=26.
   device,yoffset=1.
   color_ar=color_ar_ps
endif else begin
   set_plot,'x'
   color_ar=color_ar_x
   !p.font=-1
endelse       
;********************************************************************************
;*******************************************************************************
; Section 3: Make plots.
;****************************************************************************

firstplot_ipnt=firstplot
while firstplot_ipnt le lastpnt and get_kbrd(0) eq '' do begin ; firstplot_ipnt is incremented each page
                                      ; any keyboard entry will exit movie at end of page       
   massorder=fltarr(4)                               
   unsorted=fltarr(4)
   !p.multi=[0,nplotsx,nplotsy,1,0]
   iplot=0
   while iplot le nplotsx*nplotsy-1 and get_kbrd(0) eq ''  do begin $ ; keyboard entry will exit within page
      ipnt=iplot + firstplot_ipnt
      datestring=time_to_str(dat.times(ipnt), fmt=0, /ms )
      timestring=strmid(datestring,11,12)
      dateonlystring=strmid(datestring,0,10)
                     
         ;scaling the axes 
      k=iplot/nplotsx                       ; vertical position (number) of plot
      j=iplot-nplotsx*fix(iplot/nplotsx)    ; horizontal position (number) of plot
                     
      x0=((.02 +float(j))/nplotsx)*.87+.20-.010*nplotsx        ; detailed positioning of plot box
      y0=((.03 +float(nplotsy-k-1))/nplotsy)*.83+.005*nplotsy+.025
                     
      dx_max = (.78*.95)/(nplotsx+nplotsx^2/100.)     ; maximum allowable extension of plot box
      dy_max = (.83*.95)/(nplotsy+nplotsy^2/50.)      
                                   
      vert_to_hor=2.*(float(!d.x_size)/float(!d.y_size))  ; ratio, in coords such that window [min,max] =[0,1],
                                                        ; of vertical to horizontal individual plot size
 
      if vert_to_hor gt dy_max/dx_max then begin     ; fit plot size to given vert or horizontal limits
         deltay=dy_max                            ; whichever is more constraining
         deltax=dy_max/vert_to_hor
      endif else begin
         deltax=dx_max
         deltay=dx_max*vert_to_hor
      endelse       
                     
      x1=x0+deltax
      y1=y0+deltay
                     

; Following makes empty plot outline and scales with titles etc but not yet mass/symbol labels                                          
      if scaletype eq 'v' then begin                                                               
         yposrange=plotlim(1)
         plot, [0, yposrange], [-yposrange, yposrange], $
            position=[x0,y0,x1,y1], ystyle=9, xstyle=9, /nodata, $
            title='Multiple Mass Distribution', subtitle=datestring, $
            XTITLE = 'Velocity assuming H+ mass (sqrt(2*E/m_H)', YTITLE = 'sqrt(2*E/m_H), km/s' 
      endif else begin
         yposrange=plotlim(1)-plotlim(0)+1.    ; don't ask (lots of nonsense just to generate
           ; tick marks at whole orders of magnitude and reasonable positions) pos=>positive
         ltickv=1-(alog10(plotlim0(0))-fix(alog10(plotlim0(0))))
         yticks=2*fix(plotlim(1)-plotlim(0)+1.2)
         if yticks le 4 and ltickv lt .1 then yticks=yticks+2
                ; lowest tick values lt 0.1 not labeled, so insist on a minimum of two labels
         ytickpvals=findgen(yticks/2)+ltickv
         ytickvalues=[-reverse(ytickpvals),0,ytickpvals]
         csize1=2.0-nplotsx/16.
         if postscript then csize1=2.*(max([nplotsx,nplotsy]))^(-0.12) 
         plot, findgen(2),findgen(2), yrange=[-yposrange,yposrange],xrange=[0,yposrange],/nodata,$
           position=[x0,y0,x1,y1], ystyle=9, xstyle=5,ytickformat='logtick',yticks=yticks, $
            ; ytick labels are 10^(yvalue-4), plotted value later must be log10(energy)+4
           ytickv=ytickvalues,charsize=csize1,/noclip
         csize=0.5+2.5/max([nplotsx/1.1,nplotsy])
         if postscript eq 1 then begin csize=0.8*csize & ytoffs=-1.20 & endif else ytoffs=-1.10
         xtoffs=.05
         xyouts, [xtoffs*yposrange], [ytoffs*yposrange], timestring,charsize=csize
         xyouts, 0.05, 0.5, 'Energy (keV)', /norm, charsize=2.5, orientation=90, $
              ;text_axes=3, $
            alignment=0.5 
         if postscript eq 0 then begin 
          if float(!d.x_size)/float(!d.y_size) le 1.8 then begin
            titlestring=dateonlystring+': Multiple-Mass!CEnergy-Pitch-Angle Plots'
            chsize=1.2*!d.x_size*2.5/750. & titleoffset=0.
          endif else begin
            titlestring=dateonlystring+': Multiple-Mass Energy-Pitch-Angle Plots'
            chsize=!d.x_size*2.5/750. & titleoffset=-.06
          endelse
         endif else begin
           titlestring=dateonlystring+': Multiple-Mass!CEnergy-Pitch-Angle Plots'
            chsize=3. & titleoffset=0.0
         endelse
         xyouts,0.5,0.93+titleoffset,titlestring, /norm,charsize=chsize,alignment=0.5
      endelse
                           
              
; now define and then color in measurement region
      amax=fltarr(49) & amin=fltarr(49) 
      for i=0,47 do begin                                        
        amax(i)=max(alphaupper(i,*,ipnt),maxa_ind)              ; for each energy, take max angle
        amin(i)=min(alphalower(i,*,ipnt),mina_ind)
      endfor      
      amax(48)=amax(47) & amin(48)=amin(47)              ; extra point to cover upper and lower e-limit
      alphal=reverse(reform(alphalower(0,sort(alphalower(0,*,ipnt)),ipnt))) ; angles in incr order at enrgy indx 0
      if scaletype eq 'v' then begin                     ; fill in pie-shaped measurement region
         vtotalr=[vtotalupper,vtotallower(47)]           ; vtotalupper decreasing; append lower limit
         temp= where(vtotalr gt plotlim(1),count)
         if counte ne 0 then vtotalr(temp)=plotlim(1)       ; prevent colored-in region from going out of plot
         xfill=sin([reverse(amax),alphal,amin])*[vtotalr, $     ; x-coords for measurement region outline
                      (vtotalr(0)*(fltarr(16)+1)),vtotalr]
         yfill=cos([reverse(amax),alphal,amin])*[vtotalr, $     ; y-coords for measurement region outline
                      (vtotalr(0)*(fltarr(16)+1)),vtotalr]
      endif else begin     ; fill in the measurement region with emin inner border
         etotalr=alog10([etotalupper,etotallower(47)]/plotlim0(0))+1.     ; explicit conversion to radial
                                                     ;  plotlim0(0) is always placed at radial pos=1
         temp=where(etotalr gt plotlim(1),count) 
         if count ne 0 then etotalr(temp)=plotlim(1) 
         temp=where(etotalr lt plotlim(0),count) 
         if count ne 0 then etotalr(temp)=plotlim(0) 
         xfill=sin([reverse(amax),alphal,amin,reverse(alphal)])*([reverse(etotalr), $
            (etotalr(0)*(fltarr(16)+1)),etotalr,etotalr(48)*(fltarr(16)+1)])     ; ok, the second alphal should be         
         yfill=cos([reverse(amax),alphal,amin,reverse(alphal)])*([reverse(etotalr), $   ; at energy index 47.  big deal.
            (etotalr(0)*(fltarr(16)+1)),etotalr,etotalr(48)*(fltarr(16)+1)])
      endelse
      polyfill , xfill, yfill, color=20
              
;   the following produces an ordering of the masses according to total nuber of counts, using mass_set indices;
;      superseded by explicit entry of the mass order for the moment mb aug 4 1997
;              for ienergy=0,47 do begin 
;                       for anglebin=0,15 do begin 
;                              for i = 0, 3 do begin
;                                  unsorted(i) = unsorted(i) + dat.data(ienergy, anglebin, i, ipnt) 
;                              endfor
;                       endfor
;                  endfor 
;                  massorder = reverse(sort (unsorted))
              
      for i=0,3 do begin                          ; go through 4 masses
         imass=(where(mass_set eq masses(i)))(0)  ; first mass in list plotted first
          ; funny notation in order to get out scalar, ie element index 0 of 1-element array
         if imass ne -1 then begin       ; in case masses(i) is not a valid descriptor, don't plot anything 
      
            for ienergy=0,47 do begin    ; (note this usually doesn't work this way, but imass is a scalar here
               if scaletype eq 'v' or $
                  (etotallower(ienergy) lt plotlim0(1) and etotalupper(ienergy) gt plotlim0(0)) then begin
                                           ; (temporarily not paying attention to 'v' case for limits)

                  for anglebin=0,15 do begin
                     alpha_l=!pi/2.-alphalower(ienergy,anglebin,ipnt) ; convert pitch angle to polar
                     alpha_u=!pi/2.-alphaupper(ienergy,anglebin,ipnt)  ;               coordinate angle
                     if scaletype eq 'v' then begin       ; actually, only difference is etotal vs vtotal...
                          ; following plots a set of randomly positioned symbols in sector angle and vel range
                          ; number of points = number of counts
                        a=pointsplot(s, dat.data(ienergy, anglebin, imass, ipnt), $
                          psym_ar(imass), color_ar(imass), alpha_l,alpha_u, $
                          vtotallower(ienergy), vtotalupper(ienergy)) &$
                     endif else begin
                          ; plot a set of random-position points 
                        a=pointsplot2(s, dat.data(ienergy, anglebin, imass, ipnt), $
                          psym_ar(imass), color_ar(imass), alpha_l,alpha_u,$
                          alog10(etotallower(ienergy)/plotlim0(0))+1.,$
                          alog10(etotalupper(ienergy)/plotlim0(0))+1.,norm)
                     endelse
                  endfor
               endif 
            endfor
         endif
      endfor                    
                       

      ;    mass_set=['O+','H+','He+','He++'] default
                                                 
     perppos=fltarr(4,2)
     parlpos=fltarr(4,2)
                      
     psymposx=fltarr(4,2)
     psymposy=fltarr(4,2)

   ;positioning of symbols and labels, x*min + (1-x)*max
     parlpos(0)=-yposrange*.07 + yposrange*.93
     parlpos(1)=-yposrange*.14 + yposrange*.86
     parlpos(2)=-yposrange*.91  + yposrange*.09
     parlpos(3)=-yposrange*0.98 + yposrange*.02
                 
                  
     ypoffset=.02                
     psymposy(0)=-yposrange*.07 + yposrange*(.93+ypoffset)
     psymposy(1)=-yposrange*.14 + yposrange*(.86+ypoffset)
     psymposy(2)=-yposrange*.91 + yposrange*(.09+ypoffset)
     psymposy(3)=-yposrange*.98 + yposrange*(.02+ypoffset)  
     if postscript then begin 
         psymposx(*)=.85*yposrange & psymposx(3)=.77*yposrange ; symbol position
         perppos(*)=0.00*.2+yposrange*.80 & perppos(3)=.72*yposrange  ; symbol text label
         psymposx(1:2)=psymposx(1:2)+.04*yposrange & perppos(1:2)=perppos(1:2)+.04*yposrange
         if nplotsx ge nplotsy and nplotsx ge 6 then begin
          psymposx(*)=psymposx(*)-0.1*yposrange & perppos(*)=perppos(*)-0.1*yposrange
         endif
     endif else begin $
         psymposx(*)=.93*yposrange & psymposx(3)=.85*yposrange
         perppos(*)=0.00*.12+yposrange*.88 & perppos(3)=.80*yposrange
     end
                                        ; x-position the same for all
; now print symbol labels
     for i=0,3 do begin
        if (where(masses eq mass_set(i)))(0) ne -1 then begin
           xyouts,perppos(i),parlpos(i),mass_set(i),col=color_ar(i),charsize=csize , $
              alignment=1
        endif
     endfor
; then print symbols
     for i=0,3 do begin
        sym=psym_ar(i)
        colr=color_ar(i)
        if (where(masses eq mass_set(i)))(0) ne -1 then begin    
           oplot,[psymposx(i)],[psymposy(i)],psym=sym,color=colr,/noclip
        endif   
     endfor
     if not(postscript) then xyouts,yposrange*0.1,-yposrange*.98 + yposrange*(.02), '#'+string(ipnt,format='(i4)')
     xyouts,yposrange*0.01,-yposrange*.435 + yposrange*(0.565),string(mina_ind,format='(i2)')
     xyouts,yposrange*0.01,-yposrange*.585 + yposrange*(0.415),string(maxa_ind,format='(i2)')
     iplot=iplot+1

  endwhile 
         ; end of one page   
  if postscript then begin       
    device,/close 
    color_ar=color_ar_x
  endif
  set_plot,'x'              
  if mode eq 1 then wait,1
  if increment eq 1  then firstplot_ipnt=firstplot_ipnt+nplotsx*nplotsy
  if increment lt 0  then firstplot_ipnt=firstplot_ipnt-increment
endwhile 
if increment ne 0 then firstplot=firstplot_ipnt   
endwhile   ; end of  non-indented loop 0 

end



