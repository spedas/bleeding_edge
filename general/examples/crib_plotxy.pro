;+
; Name: crib_plotxy
;
; Purpose: crib to demonstrate capabilities of plotxy
;
; Notes: run it by compiling in idl and then typing ".go"
;        or copy and paste.
;
;Warning: this crib uses some data from the THEMIS branch.  You'll require those routines to run this crib
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-02-06 13:43:58 -0800 (Wed, 06 Feb 2008) $
; $LastChangedRevision: 2352 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/tplot/tplotxy.pro $
;-

;sets the colors correctly
init_crib_colors

;basic data: an Nx3 array is passed in
a = rebin(indgen(100),100,3)

;by default plotxy does a projection of the data into
;the x-y plane, although the user can select any plane
;they want.
plotxy,a

stop

;can be 2-d as well
;notice the plot shape, as it
;is isotropic by default

a = [[indgen(100)+1],[alog(indgen(100)+1)]]

plotxy,a

stop

;turn off isotropic
plotxy,a,/noisotropic

stop

;now with real themis data

timespan,'2007-09-21'
thm_load_state,probe='b c',coord='gsm',datatype='pos'

get_data,'thb_state_pos',data=d

d_thm_b = d.y/6371.2

get_data,'thc_state_pos',data=d

d_thm_c=d.y/6371.2

;basic call with themis data array

plotxy,d_thm_b

stop

;now different axis

;this plots the x axis reversed vs the z axis
plotxy,d_thm_b,versus='xrz'

stop

;now plot the points projected into the plane defined
;by the span of [1,1,0] and [0,0,1]
;(this is the xz plane rotated counter clockwise in
;the xy plane by pi/4 radians

;the custom plane is specified using a 2x3 matrix
plotxy,d_thm_b,versus='cc',custom=transpose([[1,1,0],[0,0,1]])

stop

;same plot as above but with the y axis of the plot reversed

plotxy,d_thm_b,versus='ccr',custom=transpose([[1,1,0],[0,0,1]])

stop

;range setting example: xrange

plotxy,d_thm_b,xrange=[0,5]

stop

;range setting example: yrange

plotxy,d_thm_b,yrange=[-10,-5]

stop

;range setting example: xrange & yrange

plotxy,d_thm_b,xrange=[0,5],yrange=[-10,-5]

stop

;plot two tplot variables on the same panel

plotxy,d_thm_b,color=2

plotxy,d_thm_c,color=4,/over

stop

;plot on multiple panels
;in new window

plotxy,d_thm_b,multi='3 1',xsize=900,ysize=300

plotxy,d_thm_b,/add,versus='xz'

plotxy,d_thm_b,/add,versus='yz'

stop

;plot on multiple panels, paneling direction reversed

plotxy,d_thm_b,multi='3r 1'

plotxy,d_thm_b,/add,versus='xz'

plotxy,d_thm_b,/add,versus='yz'

stop

;plot on multiple panels, and with multiple variables per panel

window,xsize=500,ysize=500

plotxy,d_thm_b,multi='2 2',color=2

plotxy,d_thm_c,/over,color=4

plotxy,d_thm_b,/add,versus='xz',color=2

plotxy,d_thm_c,/over,versus='xz',color=4

plotxy,d_thm_b,/add,versus='yz',color=2

plotxy,d_thm_c,/over,versus='yz',color=4

;linestyle example, letter color example
stop

plotxy,d_thm_b,multi='2 2',color='b'

plotxy,d_thm_c,/over,color='g',linestyle=2

plotxy,d_thm_b,/add,versus='xz',color='b'

plotxy,d_thm_c,/over,versus='xz',color='g',linestyle=2

plotxy,d_thm_b,/add,versus='yz',color='b'

plotxy,d_thm_c,/over,versus='yz',color='g',linestyle=2

stop

;resize window and replot

window,xsize= 750,ysize=750

plotxy

stop

;isotropic plots plot on multiple panels
;titles and margins
;unlike tplot
;margins are measured in % of the plot panel
;and margins are set for each plot
;so since there are 3 plots across and one high
;each plot area will be 300x300px
;since the xmargin is .3 on both sides
;for the first plot
;each side will have a margin of ~100px

plotxy,d_thm_b,multi='3 1',title='SC Position',xtitle='X km',ytitle='Y km',xmargin=[.3,.3],xsize=900,ysize=300

plotxy,d_thm_b,/add,versus='xz',title='SC Position',xtitle='X km',ytitle='Z km',xmargin=[0,.3]

plotxy,d_thm_b,/add,versus='yz',title='SC Position',xtitle='Y km',ytitle='Z km',ymargin=[.4,.4]

stop

;you can overplot arrows with plotxyvec

dim = dimen(d_thm_b)

n = dim[0]/50
idx = indgen(n)*50

x = d_thm_b[idx,0]
y = d_thm_b[idx,1]
u = x[1:n-1] - x[0:n-2]
v = y[1:n-1] - y[0:n-2]

plotxy,d_thm_b,xsize=600,ysize=600,title="XY orbital plot with change arrows",charsize=1.5
plotxyvec,[[x[1:n-1]],[y[1:n-1]]],[[u],[v]],/over,charsize=1.5

stop

;you can interleave with plotxyz & plotxyvec
;first generate plotxyz data

x = dindgen(5)
y = dindgen(7)
z = dindgen(5,7) mod 2.

plotxy,d_thm_b,multi='3,1'
plotxyz,x,y,z,/add
plotxyvec,[[x],[x]],[[replicate(-1.,n_elements(x))],[replicate(1.,n_elements(x))]],/add,/grid,xticks=4,yticks=6

stop

;can also do an automatic replot on interleaved plots

window,xsize=900,ysize=300

plotxy

stop

; You can also add a title to a multi panel plot, and use complicated non symmetric layouts
; mmargin lets you specify an outside margin distinct from the margin on each panel
; mpanel lets you create a panel that takes up more than one space on the multi panel grid
window,xsize=600,ysize=600
plotxy,d_thm_b,multi='2,2', mtitle='An overall title', mmargin=[0.1,0.1,0.1,0.1]
plotxyz,x,y,z,/add, mpanel='1,0:1', ymargin=[0.25,0]
plotxyvec,[[x],[x]],[[replicate(-1.,n_elements(x))],[replicate(1.,n_elements(x))]],/add,/grid,xticks=4,yticks=6
stop

;window options

plotxy,d_thm_b,window=2,xsize=800,ysize=500,wtitle='WINDOW WINDOW'

stop

;non isotropic plot

plotxy,d_thm_b,window=2,xsize=800,ysize=500,wtitle='WINDOW WINDOW',/noisotropic

stop

;change character size, set start/end syms

plotxy,d_thm_b,multi='2 1',charsize=.75,pstart=4,pstop=2

plotxy,d_thm_c,/add,charsize=2.0,pstart=2,pstop=4,symsize=1.5

stop

;change character size, and change margin size to make room for text

plotxy,d_thm_b,multi='2 1',charsize=.75,xsize=800,ysize=400

plotxy,d_thm_c,/add,charsize=3.0,ymargin=[.15,.2]

stop



end
