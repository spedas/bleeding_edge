;;  @(#)panplot.pro	1.2 12/15/94   Fast orbit display program

function panplottimeaxis,axis,index,value

common panplottimeaxis,timeaxis

hour=long(value)
min=round(60*(value-hour))
return,string(hour,min,form='(2i2.2)')
end

pro panplot,title=title,stamp=stamp, $
            xdata=xdata,xaxis=xaxis,ydata=ydata,yaxis=yaxis,timeoff=timeoff

; If timeoff is set, abscissa values are in seconds after the value of timeoff.
; Format for timeoff is an array with the zeroth element being a code as to
; how the offset is specified.  Currently there is only one recognized code as
; follows.
;     Code   Format
;        1   Array of year,doy,hour,minute,second,millisecond
;            (Only fields up to last non-zero are req'd, others assumed 0.)

common panplottimeaxis,timeaxis

nplots=n_elements(yaxis)
posx=[!x.margin(0)*!d.x_ch_size,!d.x_vsize-!x.margin(1)*!d.x_ch_size]
yaxlen=(!d.y_vsize-(!y.margin(0)+!y.margin(1))*!d.y_ch_size)/nplots
posy=[0,yaxlen]+!y.margin(0)*!d.y_ch_size
posy=[-yaxlen,0]+!d.y_vsize-!y.margin(1)*!d.y_ch_size
xsave=!x
ysave=!y
!x=xaxis
for i=0,nplots-1 do begin
  if(i eq 0) then begin
    if(keyword_set(title)) then tit=title else tit=''
  endif else begin
    tit=''
  endelse
  if((size(xdata))(0) eq 2) then x=xdata(*,i) else x=xdata
  xtickformat=''
  if(keyword_set(timeoff)) then begin
    if(i eq 0) then begin
      if(xaxis.range(0) ge xaxis.range(1)) then begin
        xmin=min(x,max=xmax)
      endif else begin
        xmin=xaxis.range(0)*3600l
        xmax=xaxis.range(1)*3600l
      endelse
      xrange=xmax-xmin
    endif
    case 1 of
      (xrange gt 3600l*24*1.5): begin
        xtit='Day of '+string(timeoff(1),form='(i4)')
        x=timeoff(2)+timeoff(3)/24.0+timeoff(4)/24.0/60.0+ $
          (timeoff(5)+x)/24.0/3600.0
      end
      (xrange gt 3600l): begin
        xtit='Universal Time   Day '+string(timeoff(2),form='(i3.3)')+' of '+ $
             string(timeoff(1),form='(i4)')
        x=timeoff(3)+timeoff(4)/60.0+(timeoff(5)+x)/3600.0
        timeaxis=1
        xtickformat='panplottimeaxis'
      end
    endcase
  endif else begin
    xtit=!x.title
    xtickformat=''
  endelse
  if(i ne nplots-1) then begin
    xtit=''
    xtickname=replicate(' ',30)
    xtickformat=''
  endif else xtickname=''
  !y=(yaxis([i]))(0)
  if((size(ydata))(0) eq 2) then y=ydata(*,i) else y=ydata
  plot,/dev,noe=(i ne 0),pos=[posx(0),posy(0),posx(1),posy(1)],tit=tit, $
       x,xtit=xtit,xtickname=xtickname,xtickformat=xtickformat,y
  posy=posy-yaxlen
endfor
if(keyword_set(stamp)) then xyouts,/dev,posx(1)+0.7*!d.y_ch_size,posy(1), $
                                   orient=90,chars=0.6,stamp
!x=xsave
!y=ysave
return
end
