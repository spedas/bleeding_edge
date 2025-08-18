;+
;Procedure: dmpa2gse
;
;Purpose: MMS coordinate transformation:
;            DMPA <--> GSE
;
;         interpolates, right ascension, declination
;         updates coord_sys attribute of output tplot variable.
;
;inputs
;
;     name_mms_xxx_in   ... data to transform (dmpa coordinates)
;   name_mms_spinras     ... right ascension of the L-vector (J2000 coordinates)
;   name_mms_spindec     ... declination of the L-vector (J2000 coordinates)
;   name_mms_xxx_out     ... name for output (t-plot variable name)
;
;keywords:
;
;   /GSE2DMPA inverse transformation
;
;   /IGNORE_DLIMITS if the specified from coord is different from the
;coord system labeled in the dlimits structure of the tplot variable
;setting this keyword prevents an error
;
;Example:
;     
;
;Notes: 
;    Based on dsl2gse from THEMIS, forked 6/22/2015
;    
;    dmpa2gse is functionally equivalent to dsl2gse, and with proper
;    input it can be used to perform a DSL to GSE transformation,
;    as described below.
;    
;    MEC L_vec assumes rigid-body rotation even when the wire booms
;    are oscillating, and thus, at any point in time it does not
;    give L, but rather the average orientation of the nutating
;    MPA (which is also assumed fixed relative to the rigid body)
;    as it wobbles in inertial space with a period of ~7 minutes.
;
;    
;    When the user wants a DSL to GSE transformation, this can be done 
;    if the spinra/spindec give the actual orientation of the angular 
;    momentum vector.  This can come from:
;           predatt (e.g. via AFG/DFG QL RADec_gse), or
;           defatt, (e.g. via MEC L_vec data), sufficiently smoothed to remove any ‘wobble’
;             - The wobble is large: it can be as large as 0.2 degrees in amplitude 
;               right after a maneuver, and still as large as 0.1 degrees 12 hours 
;               after a maneuver.
;             - A gaussian filter with a low-pass cutoff low enough to clobber the 
;               7-minute wobble works well.
;    
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-06-12 15:08:37 -0700 (Mon, 12 Jun 2017) $
; $LastChangedRevision: 23455 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/cotrans/dmpa2gse.pro $
;-

pro dmpa2gse,name_mms_xxx_in,name_mms_spinras,name_mms_spindec,name_mms_xxx_out,GSE2DMPA=GSE2DMPA,ignore_dlimits=ignore_dlimits

    cotrans_lib
    
    ; get the data using t-plot names
    get_data,name_mms_xxx_in,data=mms_xxx_in, limit=l_in, dl=dl_in ; krb
    get_data,name_mms_spinras,data=mms_spinras
    get_data,name_mms_spindec,data=mms_spindec
    
    if size(mms_spinras, /type) ne 8 || size(mms_spindec, /type) ne 8 then begin
       message, 'aborted: must load spin vector (right ascension/declination of L) data.  Try calling mms_load_state'
    endif
    
    if min(mms_spinras.x,/nan)-min(mms_xxx_in.x,/nan) gt 60*60 || max(mms_xxx_in.x,/nan) - max(mms_spinras.x,/nan) gt 60*60 then begin
      dprint,'NON-FATAL-ERROR: ' + name_mms_spinras + ' and ' + name_mms_xxx_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
    endif
      
    if min(mms_spindec.x,/nan)-min(mms_xxx_in.x,/nan) gt 60*60 || max(mms_xxx_in.x,/nan) - max(mms_spindec.x,/nan) gt 60*60 then begin
      dprint,'NON-FATAL-ERROR: ' + name_mms_spindec + ' and ' + name_mms_xxx_in + ' fail to overlap for time greater than 1 hour. Data may have significant interpolation errors.' 
    endif
    
    data_in_coord = cotrans_get_coord(dl_in) ; krb
    
    mms_xxx_out=mms_xxx_in
    
    ;convert the time
    timeS=time_struct(mms_xxx_in.X)
    
    ;convert the time
    timeSAtt=time_struct(mms_spinras.X)
    
    ;get direction
    if keyword_set(GSE2DMPA) then begin
        DPRINT, 'GSE-->DMPA'
            ; krb
    
      if keyword_set(ignore_dlimits) then begin
    
         data_in_coord='gse'
    
      endif
    
      if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                                  'gse') then begin
         dprint,  'coord of input '+name_mms_xxx_in+': '+data_in_coord+ $
                ' must be GSE'
         return
      end
      out_coord = 'dmpa'
      ; krb
      isGSE2DMPA=1
    endif else begin
       DPRINT, 'DMPA-->GSE'
    
       if keyword_set(ignore_dlimits) then begin
    
         data_in_coord='dmpa'
    
      endif
    
       ; krb
       if ~ strmatch(data_in_coord, 'unknown') && ~ strmatch(data_in_coord, $
                                                             'dmpa') then begin
          dprint,  'coord of input '+name_mms_xxx_in+': '+data_in_coord+ $
                      ' must be DMPA'
          return
       end
       out_coord = 'gse'
       ; krb
       isGSE2DMPA=0
    endelse
    
    
    ;linearly interpolate the elevation and the right ascencion angle
    ;rasInterp = interpol( mms_spinras.Y,mms_spinras.X,mms_xxx_in.X)
    ;decInterp = interpol( mms_spindec.Y,mms_spindec.X,mms_xxx_in.X)
    
    
   ; mms_spinras_highres=thm_interpolate_state(thx_xxx_in=mms_xxx_in,thx_spinras=mms_spinras) ;--> linear interpolation
   ; mms_spindec_highres=thm_interpolate_state(thx_xxx_in=mms_xxx_in,thx_spindec=mms_spindec) ;--> linear interpolation
    
    rasInterp = interpol( mms_spinras.Y,mms_spinras.X,mms_xxx_in.X)
    mms_spinras_highres = CREATE_STRUCT('X',mms_xxx_in.X ,'Y',rasInterp,'V',0.0)
    decInterp = interpol( mms_spindec.Y,mms_spindec.X,mms_xxx_in.X)
    mms_spindec_highres = CREATE_STRUCT('X',mms_xxx_in.X ,'Y',decInterp,'V',0.0)

    ;cdatj00,2,3,4,5
    
    ;convert the time
    timeS=time_struct(mms_xxx_in.X)
    
    ; get array sizes
    count=SIZE(mms_xxx_in.X,/N_ELEMENTS)
    DPRINT, 'number of records: ',count
    
    ; get array sizes
    countAtt=SIZE(mms_spinras.X,/N_ELEMENTS)
    DPRINT, 'number of records: ',countAtt
    
    ;make a unit vector that points along the spin axis
    spla=(90.d0-(mms_spindec_highres.Y))*!dpi/180.d0
    splo=mms_spinras_highres.Y*!dpi/180.d0
    zscs=[[(sin(spla)*cos(splo))],[(sin(spla)*sin(splo))],[(cos(spla))]] ;spherical to cartesian
    if isGSE2DMPA eq 0 then begin
      subJ20002GEI,timeS,zscs,zscsGEI
        subGEI2GSE,timeS,zscsGEI,zscsGSE;unit vector that points along the spin axis in GSE
        sun=[1.d0,0.d0,0.d0]
        ;yscs= crossp(zscsGSE,sun) ;NORMALIZE
        yscs=[[zscsGSE[*,1]*sun[2]-zscsGSE[*,2]*sun[1]],[zscsGSE[*,2]*sun[0]-zscsGSE[*,0]*sun[2]],[zscsGSE[*,0]*sun[1]-zscsGSE[*,1]*sun[0]]]
        yscsNorm=sqrt(yscs[*,0]^2.0+yscs[*,1]^2.0+yscs[*,2]^2.0)
        yscs[*,0]=yscs[*,0]/yscsNorm
        yscs[*,1]=yscs[*,1]/yscsNorm
        yscs[*,2]=yscs[*,2]/yscsNorm
        ;xscs=crossp(yscs,zscsGSE)
        xscs=[[yscs[*,1]*zscsGSE[*,2]-yscs[*,2]*zscsGSE[*,1]],[yscs[*,2]*zscsGSE[*,0]-yscs[*,0]*zscsGSE[*,2]],[yscs[*,0]*zscsGSE[*,1]-yscs[*,1]*zscsGSE[*,0]]]
    
        ;gse2scs=[transpose(xscs),transpose(yscs),transpose(zscs)]
        ;scs2gse=invert(gse2scs,/double)
        ;DATA_out=scs2gse#binp
    
    
    
        ;do dot products (inverse from **** below) (the inverse is just the transpose for rotation matrices)
        mms_xxx_out.Y[*,0]=mms_xxx_in.Y[*,0]*xscs[*,0]+mms_xxx_in.Y[*,1]*yscs[*,0]+mms_xxx_in.Y[*,2]*zscsGSE[*,0]
    
        mms_xxx_out.Y[*,1]=mms_xxx_in.Y[*,0]*xscs[*,1]+mms_xxx_in.Y[*,1]*yscs[*,1]+mms_xxx_in.Y[*,2]*zscsGSE[*,1]
    
        mms_xxx_out.Y[*,2]=mms_xxx_in.Y[*,0]*xscs[*,2]+mms_xxx_in.Y[*,1]*yscs[*,2]+mms_xxx_in.Y[*,2]*zscsGSE[*,2]
    
    
    endif else begin
      subJ20002GEI,timeS,zscs,zscsGEI
      subGEI2GSE,timeS,zscsGEI,zscsGSE;unit vector that points along the spin axis in GSE
        ;zscsGSE=zscs;unit vector that points along the spin axis in GSE
        sun=[1.d0,0.d0,0.d0]
        ;yscs= crossp(zscsGSE,sun) ;NORMALIZE
        yscs=[[zscsGSE[*,1]*sun[2]-zscsGSE[*,2]*sun[1]],[zscsGSE[*,2]*sun[0]-zscsGSE[*,0]*sun[2]],[zscsGSE[*,0]*sun[1]-zscsGSE[*,1]*sun[0]]]
        yscsNorm=sqrt(yscs[*,0]^2.0+yscs[*,1]^2.0+yscs[*,2]^2.0)
        yscs[*,0]=yscs[*,0]/yscsNorm
        yscs[*,1]=yscs[*,1]/yscsNorm
        yscs[*,2]=yscs[*,2]/yscsNorm
        ;xscs=crossp(yscs,zscsGSE)
        xscs=[[yscs[*,1]*zscsGSE[*,2]-yscs[*,2]*zscsGSE[*,1]],[yscs[*,2]*zscsGSE[*,0]-yscs[*,0]*zscsGSE[*,2]],[yscs[*,0]*zscsGSE[*,1]-yscs[*,1]*zscsGSE[*,0]]]
        ;gse2scs=[transpose(xscs),transpose(yscs),transpose(zscsGSE)]
    
        ;DATA_out=gse2scs#binp
    
    
        ;do dot products (****)
        mms_xxx_out.Y[*,0]=mms_xxx_in.Y[*,0]*xscs[*,0]+mms_xxx_in.Y[*,1]*xscs[*,1]+mms_xxx_in.Y[*,2]*xscs[*,2]
    
        mms_xxx_out.Y[*,1]=mms_xxx_in.Y[*,0]*yscs[*,0]+mms_xxx_in.Y[*,1]*yscs[*,1]+mms_xxx_in.Y[*,2]*yscs[*,2]
    
        mms_xxx_out.Y[*,2]=mms_xxx_in.Y[*,0]*zscsGSE[*,0]+mms_xxx_in.Y[*,1]*zscsGSE[*,1]+mms_xxx_in.Y[*,2]*zscsGSE[*,2]
    
    
    endelse
    
    ;mms_xxx_out.Y=DATA_out
    
    l_out=l_in
    dl_out=dl_in
    cotrans_set_coord,  dl_out, out_coord ; krb
    
    store_data,name_mms_xxx_out,data=mms_xxx_out, limit=l_out, dl=dl_out ; krb
    
    DPRINT, 'done'
    
    ;RETURN,mms_xxx_out
end





