;+
; Name: crib_tplotxy
;
; Purpose:crib to demonstrate capabilities of tplotxy
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


;sets the colors correctly for crib
init_crib_colors
;

timespan,'2007-09-21'
thm_load_state,probe='b c',coord='gsm',datatype='pos'

tKm2Re,'thb_state_pos',/replace

tKm2Re,'thc_state_pos',/replace

options,'thb_state_pos',/def,ysubtitle='[RE gsm]'

options,'thc_state_pos',/def,ysubtitle='[RE gsm]'

;basic call

tplotxy,'thb_state_pos'

stop

;now different axis

;this plots the x axis reversed vs the z axis
tplotxy,'thb_state_pos',versus='xrz'

stop

;now plot the points projected into the plane defined
;by the span of [1,1,0] and [0,0,1]
;(this is the xz plane rotated counter clockwise in
;the xy plane by pi/4 radians

;the custom plane is specified using a 2x3 matrix
tplotxy,'thb_state_pos',versus='cc',custom=transpose([[1,1,0],[0,0,1]])

stop

;same plot as above but with the y axis of the plot reversed

tplotxy,'thb_state_pos',versus='ccr',custom=transpose([[1,1,0],[0,0,1]])

stop

;range setting example: xrange

tplotxy,'thb_state_pos',xrange=[0,5]

stop

;range setting example: yrange

tplotxy,'thb_state_pos',yrange=[-10,-5]

stop

;range setting example: xrange & yrange

tplotxy,'thb_state_pos',xrange=[0,5],yrange=[-10,-5]

stop

;plot two tplot variables on the same panel

tplotxy,'thb_state_pos thc_state_pos'

stop

;two variables using a different method

tplotxy,'thb_state_pos'
tplotxy,'thc_state_pos',/over

stop

;two variables using a third method

tplotxy,'th?_state_pos'

stop

;two variables using a fourth method

store_data,'temp',data='thb_state_pos thc_state_pos'

tplotxy,'temp'

stop

;plot two tplot variables on the same panel in different colors

tplotxy,'temp',colors=[2,4]

stop

;plot two tplot variables on the same panel in different colors using letters

tplotxy,'temp',colors=['b','g']

stop

;plot those values in different colors different method

options,'thb_state_pos',colorsxy=2

options,'thc_state_pos',colorsxy=4

tplotxy,'temp'

stop

;plot on multiple panels
;in new window

tplotxy,'thb_state_pos',multi='3 1',xsize=900,ysize=300

tplotxy,'thb_state_pos',/add,versus='xz'

tplotxy,'thb_state_pos',/add,versus='yz'

stop

;plot on multiple panels, paneling direction reversed

tplotxy,'thb_state_pos',multi='3r 1'

tplotxy,'thb_state_pos',/add,versus='xz'

tplotxy,'thb_state_pos',/add,versus='yz'

stop

;plot on multiple panels, and with multiple variables per panel

window,xsize=500,ysize=500

tplotxy,'thb_state_pos',multi='2 2'

tplotxy,'thc_state_pos',/over

tplotxy,'thb_state_pos',/add,versus='xz'

tplotxy,'thc_state_pos',/over,versus='xz'


tplotxy,'thb_state_pos',/add,versus='yz'

tplotxy,'thc_state_pos',/over,versus='yz'

stop

;plot with multi panels/vars and set linestyle

tplotxy,'thb_state_pos',multi='2 2'

tplotxy,'thc_state_pos',/over,linestyle=2

tplotxy,'thb_state_pos',/add,versus='xz'

tplotxy,'thc_state_pos',/over,versus='xz',linestyle=2

tplotxy,'thb_state_pos',/add,versus='yz'

tplotxy,'thc_state_pos',/over,versus='yz',linestyle=2

stop

;resize window and replot

window,xsize= 750,ysize=750

tplotxy

stop

;isotropic plots plot on multiple panels
;titles and margins
;unlike tplot
;margins are measured in % of the plot panel
;and margins are set for each plot
;margins are measured in % of the plot area
;so since there are 3 plots across and one high
;each plot area will be 300x300px
;since the xmargin is .3 on both sides
;for the first plot
;each side will have a margin of ~100px

tplotxy,'temp',multi='3 1',title='SC Position',xtitle='X km',ytitle='Y km',xmargin=[.3,.3],xsize=900,ysize=300

tplotxy,'temp',/add,versus='xz',title='SC Position',xtitle='X km',ytitle='Z km',xmargin=[0,.3]

tplotxy,'thb_state_pos',/add,versus='yz',title='SC Position',xtitle='Y km',ytitle='Z km',ymargin=[.4,.4]

stop

;demonstrate interleave with plotxyz
;first generate plotxyz data

x = dindgen(5)
y = dindgen(7)
z = dindgen(5,7) mod 2.

tplotxy,'temp',multi='3,1'
plotxyz,x,y,z,/add

x = dindgen(10)
y = alog(dindgen(10)+1)
u = x[1:9]-x[0:8]
v = y[1:9]-y[0:8]

plotxyvec,[[x[1:9]],[y[1:9]]],[[u],[v]],/add

stop

;can also do an automatic replot on interleaved plots

window,xsize=600,ysize=300

tplotxy

stop

;window options

tplotxy,'temp',window=2,xsize=800,ysize=500,wtitle='WINDOW WINDOW'

stop

;non isotropic plot

tplotxy,'temp',window=2,xsize=800,ysize=500,wtitle='WINDOW WINDOW',/noisotropic

stop

;change character size

tplotxy,'thb_state_pos',multi='2 1',charsize=.75

tplotxy,'thc_state_pos',/add,charsize=2.0

stop

;change character size, and change margin size to make room for text, set start and end symbols

tplotxy,'thb_state_pos',multi='2 1',charsize=.75,xsize=800,ysize=400,pstart=4,pstop=2

tplotxy,'thc_state_pos',/add,charsize=3.0,ymargin=[.15,.2],pstart=2,pstop=4,symsize=1.5

stop

;demonstrate use of ytitle,ysubtitle, and labels to change plotting info

options,'thb_state_pos',ytitle='Spacecraft Position'

options,'thb_state_pos',ysubtitle='RE'

options,'thb_state_pos',labels=['xPos','yPos','zPos']

tplotxy,'thb_state_pos',multi='3/1',xmargin=[.2,.1]

tplotxy,'thb_state_pos',/add,versus='xz',xmargin=[.2,.1]

tplotxy,'thb_state_pos',/add,versus='yz',xmargin=[.2,.1]

; Add an overall title, change overall margins, and use a nonsymmetric plot layout

tplotxy,'thb_state_pos',multi='3,2',xmargin=[.2,.1], mtitle='The title', mmargin=[0.1,0.1,0.1,0.1], mpanel='0:1,0:1'

tplotxy,'thb_state_pos',/add,versus='xz',xmargin=[.05,.05]

tplotxy,'thb_state_pos',/add,versus='yz',xmargin=[.05,.05], ymargin=[0.2,0]

end
