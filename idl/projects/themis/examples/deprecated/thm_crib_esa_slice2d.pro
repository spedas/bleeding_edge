;+
;Procedure: thm_crib_esa_slice2d
;
;Propose:   Example to call the pro file of thm_esa_slice2d. PNG or PS files of ESA (ion or
;           electron) Distribution Functions for the spacecraft (sc) and the type of data (full, reduced
;           or burst) would be automatically printed, and the output file would be a 2-D slice of the
;           3-D distribution function. The detailed slice properties (such as the definition of x and y
;           axis, the two limits of the slice, etc) can be found in thm_esa_slice2d.
;
;Remarks:   You can select a start time and an end time to produce a set of distribution function plots
;           with the time increments (specified by INCREMENT) no less than 3 seconds. For each plot, it
;           is allowed to have a longer interval than 3 seconds (specified by TIMEINTERVAL) with the
;           distribution function being averaged during the whole time interval. Also you need to designate
;           the folder (specified by OUTPUTFOLDER) that you wish to put the output files.
;
;LAST EDITED BY XUZHI ZHOU 4-24-2008
;-

pro thm_crib_esa_slice2d

filetype='png'  ; 'png' or 'ps'
species ='ion'  ; 'ele' or 'ion'


;********************!!! Set Output Folder !!!******************************************
Case StrUpCase(!version.os_family) of
    'WINDOWS' : outputfolder='C:\THEMIS\'
    Else : outputfolder='/THEMIS/'
EndCase
; If you want to use your own folder, then only use one of the two lines below depending on which OS you are running
;outputfolder='C:\THEMIS\' ;Modify and uncomment this line if you're using Windows
;outputfolder='/THEMIS/'  ;Modify and uncomment this line if you're using Mac/Unix/Linux
;***************************************************************************************


; choose which spacecraft (a-e):
sc = 'b'

; choose type of data - f-full, r-reduced, b-burst:
typ = 'b'

;Choose start and end times
start_time='2008-02-26/04:50:00'
start_time=time_double(start_time)
timespan, start_time, 0.05
end_time = '2008-02-26/04:55:00'
end_time = time_double(end_time)

; Input the increment in seconds
increment = 3.0
; Input the time interval for each plot (in seconds)
timeinterval = 30.0

;load support data:
;thm_init
;thm_load_state,probe=sc,/get_supp,version=2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;load the esa data:
thm_load_esa_pkt,probe=sc

if typ eq 'f' then gap_time=1000. else gap_time=10.

thm_load_fgm,level=2,coord='dsl gse gsm',probe = sc

current_time = start_time

; ROTATION: SUGGESTING THE X AND Y AXIS IN THE OUTPUT FILE, WHICH CAN BE SELECTED AS THE FOLLOWINGS:
; 'BV': the x axis would be V_para (to the magnetic field) and the bulk velocity would be in the x-y plane. (DEFAULT)
; 'BE': the x axis would be V_para (to the magnetic field) and the VxB direction would be in the x-y plane.
; 'xy': the x axis would be V_x and the y axis would be V_y.
; 'xz': the x axis would be V_x and the y axis would be V_z.
; 'yz': the x axis would be V_y and the y axis would be V_z.
; 'perp': the x-y plane is perpendicular to the magnetic field, while the x axis would be the velocity projection on the plane.
; 'perp_xy': the x-y plane is perpendicular to the magnetic field, while the x axis representing the x projection on the plane.
; 'perp_xz': the x-y plane is perpendicular to the magnetic field, while the x axis representing the x projection on the plane.
; 'perp_yz': the x-y plane is perpendicular to the magnetic field, while the x axis representing the y projection on the plane.

rotation='perp'

angle=[-20.,20.]
;ThirdDirLim=[-600,-1000]
range=[1.E-14,1.E-6]

while current_time lt end_time do begin
	clock_time = time_string(format=2,current_time)
    if species eq 'ion' then begin
      outputfile = outputfolder+clock_time+'th'+sc+'pei'+typ

;	  thm_esa_slice2d,sc,typ,current_time,timeinterval,thebdata='th'+sc+'_fgs_dsl',species=species,range=range,rotation=rotation,ThirdDirlim=ThirdDirLim,filetype=filetype,outputfile=outputfile
	  thm_esa_slice2d,sc,typ,current_time,timeinterval,thebdata='th'+sc+'_fgs_dsl',species=species,range=range,rotation=rotation,angle=angle,filetype=filetype,outputfile=outputfile;,nosmooth=1
	endif
    if species eq 'ele' then begin
      outputfile = outputfolder+clock_time+'th'+sc+'pee'+typ
	  thm_esa_slice2d,sc,typ,current_time,timeinterval,thebdata='th'+sc+'_fgs_dsl',species=species,range=range,rotation=rotation,filetype=filetype,outputfile=outputfile,xrange=[-13000.,13000.]
    endif

	current_time = current_time + increment
;print, clock_time
endwhile

end