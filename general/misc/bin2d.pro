;+
;
; Procedure: bin2d
;
; Purpose:
; A slightly simpler wrapper for vassilis's routine for 2-d binning
; NOTE: despite the fact that they are keywords either binsize or
; binnum must be set for the proceedure to function
;
; Inputs: 
;     x: the x components for the bins. Should be
;           an N length array.
;     y:  the y components for the bins. Should be an 
;           N length array.
;     arrs2bin: the arrays to be binned should be an NxM
;               sized array or an N sized array
;               (Note: Interpolation to match the N component
;                of input arrays is the responsibility of the 
;                user.)
;
; Keywords:
;     
;     binsize: a number or a 2 element array.  If a single number
;              it will be treated as size of the bins for the x dimension
;              and the y dimension.  If it is a two element array, the
;              first element will be the size of the bins on the x
;              axis and the second element will be the size of the
;              bins on the y axis.
;              Warning: Either Binsize or binum must always be set.
;
;     binum: a number of 2 element array.  If a single number it
;             will be treated as the number of bins on for both
;             axes.  If a 2 element array, the first element is 
;             number of bins on the x-axis and the second element is
;             the number of bins on the y-axis. (Note: The number of
;             bins actually produced may vary by +- 1) Bins will be
;             evenly spaced over xrange and yrange if provided, and 
;             over the range of the data if not.
;
;             Warning: Either Binsize or binum must always be set.
;
;     xrange,yrange(optional): a 2 element array specifying the min
;             and the max over which binning will occur for the
;             respective axis(default: all data)
;
;     flagnodata(optional): set this keyword to a flag to replace
;             output values with if there is no data. (default: 0) 
;
;     averages(output): outputs 2-d array in which the bin averages
;                   are stored
;
;     medians(output): outputs 2-d array in which the bin medians are stored
;
;     stdevs(output): outputs 2-d array in which the bin stdevs are stored.
;
;     binhistogram(output): a 2-d histogram of the number of elements
;             used for constructing each cell
;
;     xcenters,ycenters(output): 1-d array of the centers for the bins 
;             on each axis.
;
;     minvarvec,maxvarvec(output): Either of these are set arrs2bin
;             will must have dimension M >= 2. The first 2 arrays
;             of the M dimension(ie arrs2bin[*,0] and arrs2bin[*,1]
;             will be treated as corresponding elements of an X,Y flow
;             field. The maxvariance direction will be a 2D vector in
;             maxvarvec for each cell. The minvariance direction
;             will be a 2D vector in minvarvec for each cell. The 
;             vector norm is the variance in the max/min direction, i.e., 
;             lambda_i=sqrt(maxvarvec(*,0)^2+maxvarvec(*,1)^2).
; 
;
; Notes and Warnings:
;   1.  Interpolation to match the N component of input arrays is the 
;       responsibility of the user.
;
;   2.  The number of bins actually produced may vary by +- 1 from the
;       number requested by binum
;
;   3.  Either binsize or binum must always be set.
;
;   4.  If both binsize and binum, binsize will take precedent.
;
;  SEE ALSO: bin1d.pro,plotxyz.pro,thm_crib_plotxyz.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-02-06 13:43:58 -0800 (Wed, 06 Feb 2008) $
; $LastChangedRevision: 2352 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/ssl_general/trunk/tplot/tplotxy.pro $
;-

;main function.
;written by vassilis
pro bin2Dmain, x, y,arrs2bin,xmin,xmax,xbinsize,ymin,ymax,ybinsize,kinbin,bincenters,$
               averages, stdevs, medians, maxvarvec=maxvarvec, minvarvec=minvarvec,flag4nodata=flag4nodata

;hidden to prevent clutter when the user uses
compile_opt hidden

if ~keyword_set(flag4nodata) then flag4nodata=0.
;
ioffsite=where((x lt xmin) or (x ge xmax) or (y lt ymin) or (y ge ymax), joffsite)
narrs=n_elements(arrs2bin(0,*))
nxbin=long((xmax-xmin)/xbinsize)
nybin=long((ymax-ymin)/ybinsize)
maxval=nxbin*nybin
;
ix=long((x-xmin)/xbinsize)
iy=long((y-ymin)/ybinsize)
iz=iy*nxbin+ix
;
if (joffsite gt 0) then iz(ioffsite)=nxbin*nybin+1
;
if (arg_present(maxvarvec) or arg_present(minvarvec)) then begin
  bin1D, iz, arrs2bin,0,maxval, 1, kinbin, bincenters, averages, stdevs, medians,maxvarvec=maxvarvec,minvarvec=minvarvec,flag4nodata=flag4nodata
endif else begin
  bin1D, iz, arrs2bin,0,maxval, 1, kinbin, bincenters, averages, stdevs, medians,flag4nodata=flag4nodata
endelse
;
xbincenters=make_array(nxbin, /float,/index)*xbinsize+(xmin)+xbinsize/2.
xbincenters=xbincenters#make_array(nybin,/float,value=1)
ybincenters=make_array(nybin, /float,/index)*ybinsize+(ymin)+ybinsize/2.
ybincenters=make_array(nxbin,/float,value=1)#ybincenters
bincenters=make_array(nxbin,nybin,2)
bincenters(*,*,0)=xbincenters
bincenters(*,*,1)=ybincenters
;
kinbin=reform(kinbin, nxbin, nybin)
averages=reform(averages, nxbin, nybin, narrs)
stdevs=reform(stdevs, nxbin, nybin, narrs)
medians=reform(medians, nxbin, nybin, narrs)
if (keyword_set(maxvarvec)) then maxvarvec=reform(maxvarvec, nxbin, nybin,2)
if (keyword_set(minvarvec)) then minvarvec=reform(minvarvec, nxbin, nybin,2)
;
end

pro bin2d,x,y,arrs2bin,binsize=binsize,binum=binum,xrange=xrange,yrange=yrange,flagnodata=flagnodata,$
          averages=averages,medians=medians,stdevs=stdevs,binhistogram=binhistogram,xcenters=xcenters,$
          ycenters=ycenters,minvarvec=minvarvec,maxvarvec=maxvarvec


  ;validate and set parameters, pretty straightforward

  if ~keyword_set(x) or ~keyword_set(y) or ~keyword_set(arrs2bin) then begin
     message,'x,y, and arrs2bin must always be set'
  endif

  if keyword_set(xrange) then begin

     if n_elements(xrange) ne 2 then begin
        message,'xrange must have 2 elements if set'
     endif

     xmin = xrange[0]
     xmax = xrange[1]

  endif else begin

     xmin = min(x,/nan)
     xmax = max(x,/nan)

  endelse

  if keyword_set(yrange) then begin

     if n_elements(yrange) ne 2 then begin
        message,'yrange must have 2 elements if set'
     endif

     ymin = yrange[0]
     ymax = yrange[1]

  endif else begin

     ymin = min(y,/nan)
     ymax = max(y,/nan)

  endelse

  if ~keyword_set(binsize) and ~keyword_set(binum) then begin
     message,'either binsize or binum must be set'
  endif

  if keyword_set(binum) then begin
 
     xbinum = binum[0]

     if n_elements(binum) eq 1 then begin
        ybinum = binum[0]
     endif else if n_elements(binum) eq 2 then begin
        ybinum = binum[1]
     endif else begin
        message,'binum must have one or two elements'
     endelse

     xbinsz = (xmax-xmin)/xbinum

     ybinsz = (ymax-ymin)/ybinum

  endif

  if keyword_set(binsize) then begin

     xbinsz = binsize[0]

     if n_elements(binsize) eq 1 then begin
        ybinsz = binsize[0]
     endif else if n_elements(binsize) eq 2 then begin
        ybinsz = binsize[1]
     endif else begin
        message,'binsize must have one or two elements'
     endelse
  endif

  arrdims = size(arrs2bin,/dimensions)


  if n_elements(x) ne n_elements(y) or n_elements(y) ne arrdims[0] then begin

     message,'number of elements in x,y and dim1 of arrs2bin must be equal'
     
  endif


  ;All the different combinations of min and max varvec,
  ;they need to be split like this because we need to be sure
  ;it doesn't perform the varvec operation accidentally
  if arg_present(minvarvec) or arg_present(maxvarvec) then begin

     if n_elements(arrdims) ne 2 or  arrdims[1] lt 2 then begin
        message,'maxvarvec or minvarvec cannot be set if second dimension of arrs2bin is less than 2'
     endif
     
     bin2dmain,x,y,arrs2bin,xmin,xmax,xbinsz,ymin,ymax,ybinsz,binhistogram,bincenters,averages,stdevs,medians,flag4nodata=flagnodata,maxvarvec=maxvarvec,minvarvec=minvarvec
     
     maxvarvec = reform(maxvarvec)
     minvarvec = reform(minvarvec)

  endif else begin
     
     bin2dmain,x,y,arrs2bin,xmin,xmax,xbinsz,ymin,ymax,ybinsz,binhistogram,bincenters,averages,stdevs,medians,flag4nodata=flagnodata

  endelse

  xcenters = reform(bincenters[*,0,0])

  ycenters = reform(bincenters[0,*,1])

  binhistogram=reform(binhistogram)

  averages= reform(averages)

  stdevs = reform(stdevs)
  
  medians = reform(medians)

end
