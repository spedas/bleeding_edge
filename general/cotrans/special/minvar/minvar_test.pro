;+
;Basic tests for minvar.pro
;
;Written by Vassilis Angelopolous(vassilis@ssl.berkeley.edu)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2007-10-04 15:40:27 -0700 (Thu, 04 Oct 2007) $
; $LastChangedRevision: 1667 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/cotrans/special/minvar/minvar.pro $
;
;-

t=make_array(1000.,/index,/float)
period=100.

x=sin(t*2.*!PI/period)
y=4.*cos(t*2.*!PI/period)
z=0.2*sin(t*2.*!PI/period)

mydata=[[x],[y],[z]]

t0=double(1.1867904e+009)
treal=double(t0)+double(t)

store_data,'mydata',data={x:treal,y:mydata}
tplot,'mydata',trange=['7 8 11/00','7 8 11/00:30:00']

minvar,transpose(mydata),eigenVijk,Vrot=Vrot,lambdas2=lambdas2

store_data,'myrotdata',data={x:treal,y:transpose(Vrot)}
tplot,'myrotdata',/add

end
