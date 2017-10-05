;+
; Procedure: bin1d
;
; Purpose: 
;Uses histogram to bin data according to array binarr. The elements in binarr
; that are in a specific bin correspond to elements in other arrays (like
; density, temperature etc) and the averages of those are computed within
; each bin. The arrays to be averaged within each bin are passed in
; arrs2bin(NXM) where N is the number of elements of the binarr and M is the
; number of quantities.
;
; Output: kinbin is K-array of elements (K=number of bins) containing
;         number of points within each bin, bincenters a K-array with center
;         of bins, averages is KXM array with averages (zero if no points)
;         stdevs an KXM array with stdevs about the mean and medians is
;         KXM array of medians within each bin
;
; If any of the keywords maxvarvec or minvarvec is set to a name
; then it is assumed that the first two
; elements of the array "arrs2bin" correspond to the X,Y coordinates of
; a "flow" field. The corresponding data in each cell will be rotated
; in a max/min variance direction. The maxvariance direction will
; be in 2D vector maxvarvec for each cell. The minvariance direction
; will be in 2D vector minvarvec for each cell. The vector norm is the
; variance in the max/min direction, i.e.,
; lambda_i=sqrt(maxvarvec(*,0)^2+maxvarvec(*,1)^2).
;
; if keyword flag4nodata is set, then points with no data are flags set equal
; to the value passed in, not zeros.
;
; Usage:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; bin1D,Ygse,[[Ni],[Ti],[Vx],[fx],[Qx],[Eylep]],-15.,15.,1.,kinbin,Ycntrs,avrg,std,med
; Niavg=avrg(*,0)&Tiavg=avrg(*,1)&Vxavg=avrg(*,2)&fxavg=avrg(*,3)&Qxavg=avrg(*,4)&Eylepavg=avrg(*,5)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2007-10-03 14:49:09 -0700 (Wed, 03 Oct 2007) $
; $LastChangedRevision: 1661 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/idl_socware/trunk/external/IDL_GEOPACK/t01/t01.pro $
;-
pro bin1D,binarr,arrs2bin,minval,maxval,binwidth,kinbin,bincenters,averages,stdevs,medians,revarr=iinbin,maxvarvec=maxvarvec,minvarvec=minvarvec,flag4nodata=flag4nodata
if (keyword_set(flag4nodata) eq 0) then flag4nodata=0
;
; find out how many arrays and points
;
npoints=long(n_elements(binarr))
marrays=n_elements(arrs2bin(0,*))
;
if (npoints ne n_elements(arrs2bin(*,0))) then begin
  dprint, 'In bin1D, npoints of binarr differs from npoints of arrs2bin'
  return
endif
;
; Perform histogram and find points and reverse indices
;
kinbin=histogram(binarr,min=minval,max=maxval,binsize=binwidth,reverse=iinbin)
nbins=n_elements(kinbin)-1
kinbin=kinbin(0:nbins-1)
bincenters=binwidth*make_array(nbins,/float,/index)+binwidth/2.+minval
;
; define begin and end positions within reverse index array denoting
; points within each bin
;
nindxstarts=make_array(nbins,/long)&nindxends=nindxstarts
;
izeroinbin=where(iinbin(1:nbins)-iinbin(0:nbins-1) eq 0,jzeroinbin)
if (jzeroinbin gt 0) then begin
  nindxstarts(izeroinbin)=-1
  nindxends(izeroinbin)=-1
endif
inonzeroinbin=where(iinbin(1:nbins)-iinbin(0:nbins-1) ne 0,jnonzeroinbin)
if (jnonzeroinbin gt 0) then begin
  nindxstarts(inonzeroinbin)=iinbin(inonzeroinbin)
  nindxends(inonzeroinbin)=iinbin(inonzeroinbin+1)
endif
;
; create medians, averages and stdevs
;
if (arg_present(minvarvec) or arg_present(maxvarvec)) then begin
  maxvarvec=make_array(nbins,2,/double)
  minvarvec=make_array(nbins,2,/double)
endif
averages=make_array(nbins,marrays,/float)
stdevs=make_array(nbins,marrays,/float)
medians=make_array(nbins,marrays,/float)
for mtharr=0L,marrays-1L do begin
  for nthbin=0L,nbins-1L do begin
    if (kinbin(nthbin) ne 0) then begin
      averages(nthbin,mtharr)=total(arrs2bin(iinbin(nindxstarts(nthbin):nindxends(nthbin)-1),mtharr))/kinbin(nthbin); same as using mean()
      if (kinbin(nthbin) gt 1) then begin
        stdevs(nthbin,mtharr)=stddev(arrs2bin(iinbin(nindxstarts(nthbin):nindxends(nthbin)-1),mtharr))
        if (keyword_set(minvarvec) or keyword_set(maxvarvec)) then begin
          Vx=arrs2bin(iinbin(nindxstarts(nthbin):nindxends(nthbin)-1),0)
          Vy=arrs2bin(iinbin(nindxstarts(nthbin):nindxends(nthbin)-1),1)
          Vz=dblarr(n_elements(Vy))
          minvar,transpose([[Vx],[Vy],[Vz]]),eigenVij,lambdas2=lambdaij
          maxvarvec(nthbin,*)=eigenVij(0:1,0)*sqrt(lambdaij(0))
          minvarvec(nthbin,*)=eigenVij(0:1,1)*sqrt(lambdaij(1))
        endif
      endif
      medians(nthbin,mtharr)=median(arrs2bin(iinbin(nindxstarts(nthbin):nindxends(nthbin)-1),mtharr))
    endif
  endfor
endfor
iclip=where(kinbin le 0,jclip) 
if (jclip gt 0) then begin 
  for jtharray=0,marrays-1 do begin
    averages(iclip,jtharray)=flag4nodata 
    stdevs(iclip,jtharray)=flag4nodata
    medians(iclip,jtharray)=flag4nodata
  endfor
;  kinbin(iclip)=flag4nodata
endif 
;
return
;
end
