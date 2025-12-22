;;  @(#)fastorbfileread.pro	1.2 12/15/94   Fast orbit display program

pro fastorbfileread,new=new

@fastorb.cmn
@fastorbdisp.cmn

widget_control,wa,/hour
; Define data structures if necessary.
if(n_elements(satdesc) le 0) then begin
  satdesc={satd,filename:'',firstdata:0l,ndata:0l,sat:'',orbit:0l,epochyr:0, $
                epochdoy:0,epochhr:0,epochmin:0,epochsec:0.0d0,axis:0.0d0, $
                ecc:0.0,inc:0.0d0,node:0.0d0,aperigee:0.0d0,manomaly:0.0d0}
  rdvec={orbvec,satptr:0l,time:0.0d0,x:0.0d0,y:0.0d0,z:0.0d0,vx:0.0d0,  $
                vy:0.0d0,vz:0.0d0,lat:0.0d0,lng:0.0d0,alt:0.0d0,mlat:0.0d0,  $ 
                mlng:0.0d0,mlt:0.0d0,ilat:0.0d0,ilng:0.0d0,bx:0.0d0,  $
                by:0.0d0,bz:0.0d0}
  cd,current=curpath  ; Initialize data search path to current directory.
  curfile=''          ; Initialize data file name to null string.
endif

; Read file in two passes.  First pass reads headers and locates data.
; Second pass reads in first set of data.
if((curfile eq '') or keyword_set(new)) then begin
  dumfile=''
  while(dumfile eq '') do begin
    dumfile=pickfile(path=curpath,get_path=curpath, $
                     title='FASTOrb file to use:',/read,/must)
    if(dumfile eq '') then begin
      if(curfile ne '') then dumfile=curfile
    endif else curfile=dumfile
  endwhile
  widget_control,wa,/hour
endif
openr,lun,/get_lun,curfile
filestat=fstat(lun)
instr=''
filestamp=''
readf,lun,filestamp
nhdr=0l
hdrpos=1
ird=0l
satdesc(nhdr).filename=filestat.name
repeat begin
  repeat begin
    if(hdrpos gt 0) then begin
      readf,lun,instr
      case hdrpos of                               ;  Parsing is so much fun!
        1: satdesc(nhdr).sat=strtrim(strmid(instr,strpos(instr,':')+1,100),2)
        2: begin
          dumlong1=0l & dumlong2=dumlong1
          dumdble=0.0d0
          ptr=strpos(instr,':')+1
          reads,strmid(instr,ptr,100),dumlong1
          satdesc(nhdr).orbit=dumlong1
          ptr=strpos(strmid(instr,ptr,100),':')+ptr+1
          reads,strmid(instr,ptr,100),dumlong1,dumlong2
          satdesc(nhdr).epochyr=dumlong1
          satdesc(nhdr).epochdoy=dumlong2
          ptr=strpos(strmid(instr,ptr,100),':')+ptr-2
          reads,strmid(instr,ptr,100),dumlong1,dumlong2,dumdble,form='(i2,1x,i2,1x,f15.7)'
          satdesc(nhdr).epochhr=dumlong1
          satdesc(nhdr).epochmin=dumlong2
          satdesc(nhdr).epochsec=dumdble
        end
        3: begin
          ptr=strpos(instr,'=')+1
          reads,strmid(instr,ptr,100),dumdble
          satdesc(nhdr).axis=dumdble
          ptr=strpos(strmid(instr,ptr,100),'=')+ptr+1
          reads,strmid(instr,ptr,100),dumdble
          satdesc(nhdr).ecc=dumdble
          ptr=strpos(strmid(instr,ptr,100),'=')+ptr+1
          reads,strmid(instr,ptr,100),dumdble
          satdesc(nhdr).inc=dumdble
        end
        4: begin
          ptr=strpos(instr,'=')+1
          reads,strmid(instr,ptr,100),dumdble
          satdesc(nhdr).node=dumdble
          ptr=strpos(strmid(instr,ptr,100),'=')+ptr+1
          reads,strmid(instr,ptr,100),dumdble
          satdesc(nhdr).aperigee=dumdble
          ptr=strpos(strmid(instr,ptr,100),'=')+ptr+1
          reads,strmid(instr,ptr,100),dumdble
          satdesc(nhdr).manomaly=dumdble
        end
        else: begin
          point_lun,-lun,dumlong1
          satdesc(nhdr).firstdata=dumlong1
          hdrpos=-1
        end
      endcase
      hdrpos=hdrpos+1
    endif else begin
      readf,lun,instr
      if(instr eq filestamp) then hdrpos=1 else ird=ird+1
    endelse
  endrep until((instr eq filestamp) or (eof(lun)))
  satdesc(nhdr).ndata=ird
  for j=0l,nhdr-1 do satdesc(nhdr).ndata=satdesc(nhdr).ndata-satdesc(j).ndata
  if(not (eof(lun))) then begin
    nhdr=nhdr+1
    hdrpos=1
    if(nhdr gt (n_elements(satdesc)-1)) then satdesc=[satdesc,{satd}]
    satdesc(nhdr).filename=filestat.name
  endif
endrep until(eof(lun))
close,lun
free_lun,lun
satdesc=satdesc(0:nhdr)

; Headers have been read.  Get first set of vectors.
satdescindx=0l
tpdoy=satdesc(0).epochdoy
fastorbgetdata
return
end
