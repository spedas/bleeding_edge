;author: baldwin $
;Date: 2017/04/25 19:35:46 $
;Header: /home/cdaweb/dev/control/RCS/spd_cdawlib_plotmaster.pro,v 1.382 2017/04/25 19:35:46 rchimiak Exp rchimiak $
;Locker: rchimiak $
;Revision: 1.382 $
;+------------------------------------------------------------------------
; NAME: spd_cdawlib_plotmaster
; PURPOSE: To plot the data given in 1 to 10 anonymous structure of the type
;          returned by the spd_cdawlib_read_mycdf function.  This function determines
;          the plot type for each variable, and generates the plot.
; CALLING SEQUENCE:
;       out = spd_cdawlib_plotmaster(a,[more_structures])
; INPUTS:
;       a = structure returned by the spd_cdawlib_read_mycdf procedure.
;
; KEYWORD PARAMETERS:
;   TSTART =  String of the form '1996/01/02 12:00:00' or a DOUBLE CDF_EPOCH
;   time that is the desired start time of the plots. Data is clipped or
;   padded to conform to this time. Default is the start time of the
;   earliest data.
;
;   TSTOP = String of the form '1996/01/02 12:00:00' or a DOUBLE
;   CDF_EPOCH time that is the desired stop time of the plots. Data is
;   clipped or padded to conform to this time. Default is the stop time of
;   the latest data.
;
;   GIF
;    Set to send plot(s) to a gif file, ie. /GIF or GIF=1L. If set a file
;    will be produced in the current working directory (see OUTDIR keyword),
;    using the following naming conventions: Spacecraft_instrument_pid_# (see
;    the PID keyword for customization). If GIF is not set then the plot(s)
;    will be put into an x-window.
;
;    PS
;      Set to send plot to a ps file. Works just as GIF above.
;
;    PID
;    May be used to customize part of the name of a gif file. The value of
;    PID may be either a number or a string and will be inserted in the gif
;    file name as follows: Spacecraft_instrument_pid_#.gif. If GIF is not
;    set then the plot(s) will be put into an x-window and this keyword is
;    ignored.
;
;    OUTDIR
;    This keyword indiates the output directory where a gif file will be
;    placed. If GIF is set but OUTDIR is not, then the gif file will be put
;    in the user's current working directory.GIF
;
;    AUTO
;    Set this keyword to use autoscaling instead of the variables SCALEMIN
;    and SCALEMAX attribute values. The scales will be set to the min and
;    max values of the data, after fill values have been filtered from the
;    data (see also NONOISE keyword). If the user wishes to modify variable
;    scale values for plotting purposes, you may do so by changing the
;    appropriate data structure values, ie. struct.variable.scalemin = 0.0.
;    Please use great care in modifying the data structures values since
;    they will greatly influence what your plots or listings may look like.
;
;    CDAWEB
;    Set this keyword to force the margin on the right side of time series
;    plots to be 100 pixels. This is the same margin used for spectrograms
;    for the color bar. By default, spd_cdawlib_plotmaster will examine the data, and if
;    ANY spectrograms will be produced, then it will align the margins
;    properly. This keyword is only necessary for use in the CDAWeb system.
;
;    SLOW
;    Set this keyword to have spectrogram plotted using the POLYFILL method.
;    This method is slower but more accurate than TV (used in the QUICK method).
;
;    SMOOTH
;    Set this keyword to have spectrogram data reduced prior to plotting.
;    This will increase plotting speed significantly.
;
;    QUICK
;    Set this keyword to have spectrograms plotted using the TV method.
;    This method is very fast, but will produce inaccurate spectrograms
;    if scales are non-linear or if fill data or data gaps are present
;    in the data.
;
;    THUMBSIZE
;    Set this to change the "thumbnail" size of each image when plotting
;    a series of images. The default is 50w x 62h. 12 pixels is added to
;    the height to allow for the time stamps under each image. So, if
;    you specify a thumsize of 70 pixels, each will actually be 70x82.
;
;    FRAME
;    Used to indicate the frame number within a series of images. If you
;    specify FRAME = 2, then spd_cdawlib_plotmaster will produce a "full size" version
;    of the 3rd image in a sequence of images.
;
;       COMBINE  = if set, all time series and spectrogram plots will be
;                  combined into a single window or gif file.
;       NONOISE  = if set, filter values outside 3-sigma from the mean
;       DEBUG    = if set, turns on additional debug output.
;       ELEMENTS = if set, then only these elements of a dimensional variable
;                  will be plotted for stack_plot use only (right now).
;
;   LIMIT_MOVIE = if set, then the number of frames in a movie file
;   will be limited by the underlying s/w routines (to 200 or so as of
;   2/2006)       if not set, no limit on the # of frames (TJK 2/9/2006)
;
;   TOP_TITLE - if set, adjust the top margin a bit to allow a total
;               of 3 lines of title.  The value of top_title allows a
;               user to pass in an additional line of text, which
;               cdaweb is using for the binning labels.
;
;  PLOTMERGE
;    Set this keyword to plot multiple time series data on the same panel.
;    PLOTMERGE = 'vector' will plot together vector components (i.e. Bx, By, Bz)
;    emanating from a single variable.
;    PLOTMERGE = 'mission' will plot together identical variables from
;    cluster missions (i.e., MMS)
;
;
; OUTPUTS:
;       out = status flag, 0=0k, -1 = problem occurred.
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 22, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;       8/13/96 : R. Burley    : Add NONOISE keyword
;       8/30/96 : R. Baldwin   : Add error handling STATUS,DATASET,IMAGE,GIF
;       8/30/96 : R. Baldwin   : Add orbit plotting
;	1/7/97  ; T. Kovalick  : Modified many of the code that goes w/ the
;				 keywords; GIF, CDAWEB, TSTART,	TSTOP and added
;				 the header documentation for them. Still more
;				 work to do...
;       2/10/97 ; R. Baldwin   : Add SSCWEB keyword and map_keywords.pro
;				 function
;	6/6/97  ; T. Kovalick  : Added the Stacked time series plot type.
;
;	9/4/97	; T. Kovalick  : Added the ELEMENTS keyword for stack_plot
;				 usage, it could also be used in time_series.
;        4/98   ; R. Baldwin   : Added virtual variable plot types;
;				 plot_map_images.pro
;       11/98   ; R. Baldwin   : Added movie_images and movie_map_images
;
;
;Copyright 1996-2013 United States Government as represented by the
;Administrator of the National Aeronautics and Space Administration. All Rights Reserved.
;
;-------------------------------------------------------------------------
FUNCTION spd_cdawlib_plotmaster, a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,$
  a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,$
  a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,$
  COMBINE=COMBINE,PANEL_HEIGHT=PANEL_HEIGHT,$
  XSIZE=XSIZE,CDAWEB=CDAWEB,DEBUG=DEBUG,FILLER=FILLER,$
  AUTO=AUTO,QUICK=QUICK,SLOW=SLOW,SMOOTH=SMOOTH,$
  GIF=GIF, PS=PS, TSTART=TSTART,TSTOP=TSTOP,NONOISE=NONOISE,$
  COLORTAB=COLORTAB,THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
  REPORT=REPORT,PID=PID,STATUS=STATUS,OUTDIR=OUTDIR, $
  SSCWEB=SSCWEB, ELEMENTS=ELEMENTS, LIMIT_MOVIE=LIMIT_MOVIE, $
  TOP_TITLE=TOP_TITLE,PLOTMERGE = PLOTMERGE


  compile_opt idl2

  ; Verify that number of parameters is acceptable
  if ((n_params() le 0)OR(n_params() gt 30)) then begin
    print, 'STATUS= No data selected for plotting'
    print,'ERROR=Number of parameters must be from 1 to 30' & return,-1
  endif

  ;RCJ be careful using 'ps' in this program!
  if keyword_set(gif) then plottype='gif' else $
    if keyword_set(ps) then plottype='pscript' else $
    plottype=''

  if(N_Elements(plotmerge)eq 0) then plotmerge = 0
  if( N_Elements(plotmerge)ne 0 && STRCMP (plotmerge,'vector') eq 1) then plotmerge = 1
  if(N_Elements(plotmerge)ne 0 && STRCMP (plotmerge,'mission') eq 1) then plotmerge = 2

  ; Initialize window state structure - fyi WS.ymargin = [top, bottom]
  WS = plotmerge gt 0 ? plottype eq 'pscript'? $
    {snum:0L,xs:0L,ys:0L,pos:lonarr(4),xmargin:[3500,2500],ymargin:[2200,3000]} : $
    {snum:0L,xs:0L,ys:0L,pos:lonarr(4),xmargin:[100L,40L],ymargin:[40L,110L]} : $

    plottype eq 'pscript'? keyword_set(TOP_TITLE)?$

    {snum:0L,xs:0L,ys:0L,pos:lonarr(4),xmargin:[3500,1500],ymargin:[2200,3000]}:$
    {snum:0L,xs:0L,ys:0L,pos:lonarr(4),xmargin:[3500,1500],ymargin:[2000,3000]} :$

    keyword_set(TOP_TITLE)?$

    {snum:0L,xs:0L,ys:0L,pos:lonarr(4),xmargin:[100L,40L],ymargin:[40L,110L]}:$
    {snum:0L,xs:0L,ys:0L,pos:lonarr(4),xmargin:[100L,40L],ymargin:[30L,110L]}

  PS = 0 ; Initialize plot script structure
  ; RTB Test for Z-buffer use of carriage returns in labels
  ;!P.Charsize=1

  ; Initialize other local variables
  a          = 0       ; create variable to be filled via the execute function
  a_id       = -1      ; initialize the current structure number
  ini_complex = dcomplex(0.0D0)
  ;11/3/2006 TJK - Changed the named structure PLOTDESC to PLOTDESC2 so
  ;that when running this s/w in client/server mode, like sscweb does,
  ;the ops definition doesn't conflict w/ the dev. version (because I've
  ;added btime16 and etime16 to this structure).

  ; Added ibad tag to the PS structure.  We will use the value of this tag to flag
  ; any invalid data structures that were passed to us. 
  ; Ron Yurow (March 9, 2017)
  ;p_template = {PLOTDESC2,snum:0,vname:'',vnum:0,ptype:0,npanels:0,$
  ;  iwidth:0,iheight:0,btime:0.0D0,etime:0.0D0,btime16:ini_complex, $
  ;  etime16:ini_complex,btimett2000:long64(0),etimett2000:long64(0),title:'',source:'',movie_frame_rate:0, movie_loop:0}

  ;################ Important!!!
  ;################ Whenever makcing any changes to the PLOTDESC variable, you must change its name
  ;################ or it will conflict with the version of the structure in the idlrpc process. 

  p_template = {PLOTDESC3,snum:0,vname:'',vnum:0,ptype:0,npanels:0,$
    iwidth:0,iheight:0,btime:0.0D0,etime:0.0D0,btime16:ini_complex,ibad:0, $
    etime16:ini_complex,btimett2000:long64(0),etimett2000:long64(0),title:'',source:'',movie_frame_rate:0, movie_loop:0}

  ; Verify proper keyword parameters
  ;  9/96 RTB added STATUS, OUTDIR, PID
  ; statusflag is not currently checked before printing
  if keyword_set(STATUS) then statusflag= 1L else statusflag= 0L

  ;TJK took out the following and replaced with one line below.
  ;if keyword_set(OUTDIR) then outdir=OUTDIR else begin
  ;   if keyword_set(CDAWEB) then outdir='/home/rumba/cdaweb/html/tmp/' $
  ;    else outdir='tmp'
  ;endelse

  if keyword_set(OUTDIR) then outdir=OUTDIR else outdir=''
  ;test to see if LIMIT_MOVIE has been set at all by the calling program
  if (n_elements(LIMIT_MOVIE) gt 0) then begin
    if (keyword_set(LIMIT_MOVIE)) then limit_movie=1L else limit_movie=0L
  endif else limit_movie=1L

  ; TJK take out the relationship between CDAWEB and GIF keywords...
  ;if keyword_set(CDAWEB) then GIF=1L else GIF=0L

  if keyword_set(PID) then pid=strtrim(string(PID),2) else pid=''

  ; panel_height now being set below.  RCJ 02/26/2007
  ;if keyword_set(PANEL_HEIGHT) then pheight=PANEL_HEIGHT else pheight=100

  ; RCJ 10/29/03 Commented this out.  Now that mode code for the combine
  ; keyword was added this doesn't seem to be needed.
  ;if n_params() eq 1 then COMBINE=1 ; single structure must be combined

  ;gifopen = 0L ; initialize flag indicating no gif is currently open
  gif_ps_open = 0L ; initialize flag indicating no gif or ps is currently open
  case plottype of
    'gif': begin
      max_xsize=640
      ; a = size(GIF) & b = n_elements(a) ; validate gif keyword
      ; if (a(b-2) ne 7) then GIF='idl00.gif'
      noclipflag = 1
      if keyword_set(PANEL_HEIGHT) then pheight=PANEL_HEIGHT else pheight=100
    end
    'pscript': begin
      max_xsize = 18000
      ;max_xsize = 16000 ; fits in latex doc w/o having to fix the width
      noclipflag = 1
      ; RCJ The numbers below are checked for later. If you change them
      ; here, change them in the code ahead too.
      if keyword_set(PANEL_HEIGHT) then pheight=10000 else pheight=5000
    end
    else: begin ; determine xwindow resolution
      ;GIF = 0L ; set gif keyword to no gif
      a = lonarr(2) & DEVICE,GET_SCREEN_SIZE=a ; get device resolution
      max_xsize = (a[0] * 0.9) & max_ysize = (a[1] * 0.9)
      noclipflag = 0
      if keyword_set(PANEL_HEIGHT) then pheight=PANEL_HEIGHT else pheight=100
    end
  endcase

  ; Open report file if keyword is set
  ;if keyword_set(REPORT) then begin & reportflag=1L & a=size(REPORT)
  ;  if (a(n_elements(a)-2) ne 7) then REPORT='idl.rep'
  if keyword_set(REPORT) then begin
    reportflag=1L &  OPENW,1,REPORT,132,WIDTH=132
  endif else reportflag=0L
  if keyword_set(XSIZE) then WS.xs=XSIZE else WS.xs=max_xsize
  if keyword_set(AUTO) then autoscale = 1L else autoscale = 0L
  ;if keyword_set(SMOOTH) then smoothflag = 1L else smoothflag = 0L
  if keyword_set(QUICK) then quickflag = 1L else quickflag = 0L
  if keyword_set(SLOW) then slowflag = 1L else slowflag = 0L
  if keyword_set(FILLER) then fillflag = 1L else fillflag = 0L
  if keyword_set(DEBUG) then debugflag = 1L else debugflag = 0L
  if keyword_set(SSCWEB) then SSCWEB=1L else SSCWEB=0L

  ; Evaluate each dataset structure, and each variable within each dataset,
  ; in order to determine the plot type for each variable, as well as the total
  ; number of panels to be plotted so that the windows (or Z-buffer) can be
  ; created with the proper size.


  plottable_found = 0 ; initialize flag

  for i=0,n_params()-1 do begin ; process each structure parameter
    w = execute('a=a'+strtrim(string(i),2))
    if w ne 1 then begin
      if (reportflag eq 1) then begin
        printf, 1, 'STATUS= A plotting error has occurred' & close,1
      endif
      print,'ERROR= Error in EXECUTE function'
      print, 'STATUS= A plotting error has occurred'
      return, -1
    endif
    ; RTB Add code to trap a=-1 bad structures
    ibad=0
    str_tst=size(a)
    if(str_tst[str_tst[0]+1] ne 8) then begin
      ibad=1
      v_data='DATASET=UNDEFINED'
      v_err='ERROR=a'+strtrim(string(i),2)+' not a structure.'
      v_stat='STATUS=Cannot plot this data'
      a=create_struct('DATASET',v_data,'ERROR',v_err,'STATUS',v_stat)
    endif else begin
      ; Test for errors trapped in spd_cdawlib_read_mycdf
      atags=tag_names(a)
      rflag=spd_cdawlib_tagindex('DATASET',atags)
      if(rflag[0] ne -1) then ibad=1
    endelse
    ;
    if(ibad) then begin
      atags=tag_names(a)
      aw=where(atags eq 'ERROR',awc)
      print,a.DATASET
      if(awc gt 0) then print,a.ERROR
      print,a.STATUS
      p=p_template
      ;TJK 1/24/01 - change the ptype to -1 so that the plotting s/w lower down
      ;won't bother trying to do anything w/ this variables data (since it won't
      ;be there).  I believe, the main reason we end up here is that the data
      ;is fill and indicates that the instrument was off.
      ;      p(0).ptype=0
      p[0].ptype=-1
      p[0].snum=i
      ; Needed to distiguish the no_plot display type from invalid data structures.
      ; Ron Yurow (March 9, 2017)
      p[0].ibad=1
    endif else begin
      ;total_npanels=0
      vnames = tag_names(a)
      p = replicate(p_template,n_elements(vnames))
      for j=0,n_elements(tag_names(a))-1 do begin
        b = evaluate_varstruct(a.(j)) & c = size(b)
        if c[n_elements(c)-2] ge 8 then begin ; record the evaluation results
          p[j].snum   = i        & p[j].vnum    = j
          p[j].ptype  = b.ptype  &  p[j].npanels = (plotmerge eq 1) and (b.npanels ne 0) and (b.ptype eq 1) ? 1: b.npanels
          p[j].iwidth = b.iwidth & p[j].iheight = b.iheight
          p[j].btime  = b.btime  & p[j].etime   = b.etime
          p[j].btime16  = b.btime16  & p[j].etime16   = b.etime16
          p[j].btimett2000  = b.btimett2000  & p[j].etimett2000   = b.etimett2000
          ;TJK 3/9/2016 add capability to pass in a title (needed for binning)
          if keyword_set(TOP_TITLE) then begin
            if (b.title ne '') then b.title = b.title+'!C'+top_title else b.title = top_title
          endif
          p[j].title  = b.title
          p[j].source   = b.source
          p[j].movie_frame_rate = b.movie_frame_rate
          p[j].movie_loop = b.movie_loop

          if (b.vname ne '') then p[j].vname=b.vname else p[j].vname=vnames[j]
          if b.ptype ne 0 then plottable_found = 1; set flag

          ; RCJ 02/21/2007 This is only working for timeseries for now:
          ;if p(j).ptype eq 1 then total_npanels=total_npanels+p(j).npanels
          ; RCJ 03/16/2007 Timeseries and spectrograms:
          ;if (p(j).ptype eq 1 or p(j).ptype eq 2) then total_npanels=total_npanels+p(j).npanels
          ; RCJ 04/23/2007 Timeseries, spectrograms, stack_plots, radar and
          ; orbit plots, and time_text,
          ; but we don't have to add npanels for radar, orbit plots, or time_text:
          ;if (p(j).ptype eq 1 or p(j).ptype eq 2 or p(j).ptype eq 7) then total_npanels=total_npanels+p(j).npanels

        endif else begin ; fatal error during evaluation
          if (reportflag eq 1) then $
            printf,1,'STATUS=A plotting error has occurred' & close,1
          print,'STATUS=A plotting error has occurred'
          print,'ERROR=FATAL error during eval'
          return,-1
        endelse
      endfor ; for every variable
    endelse
    if (plottype eq 'pscript') then begin
      failed=0
      ;q=where (p(*).ptype gt 1)
      ;q=where (p(*).ptype gt 2)
      q=where (p[*].ptype gt 2 and p[*].ptype ne 7 $
        and p[*].ptype ne 3 and p[*].ptype ne 5 and p[*].ptype ne 12 and p[*].ptype ne 6)
      if q[0] ne -1 then begin
        for k=0,n_elements(q)-1 do begin
          ; RCJ   For each case that's commented out I have to
          ;   remove the condition "and (plottype ne 'pscript')"
          ;   from the part of the code that does the specific plot
          case p[q[k]].ptype of
            ;1:thisptype='time_series'
            ;2: thisptype='spectrogram, topside_ionogram or bottomside_ionogram'
            ;3:thisptype='radar_vector'
            4:thisptype='image'
            ;5:thisptype='orbit'
            ;6:thisptype='mapped'  ; commented out 06Dec2016
            ;7:thisptype='stack_plot'
            8:thisptype='map_image'
            9:thisptype='plasmagram'
            10:thisptype='movie'
            11:thisptype='map_movie'
            ;12:thisptype='time_text'
            13:thisptype='flux_image'
            14:thisptype='flux_movie'
            15:thisptype='plasma_movie'
            16:thisptype='fuv_image'
            17:thisptype='fuv_movie'
            18:thisptype='wind_plot'
            19:thisptype='wind_movie'
            20:thisptype='skymap' ;special mapped image s/w for TWINS
            21:thisptype='skymap_movie' ;special mapped image s/w for TWINS
            else: thisptype='unknown type'
          endcase
          failed=failed+1
          mm=''
          ;if (pheight eq 5000 and total_npanels gt 4) then mm=' and no more than 4 plots for ps/pdf please!'
          ;if (pheight eq 10000 and total_npanels gt 2) then mm=' and no more than 2 plots for ps/pdf please!'
          ;print,'STATUS= Sorry. PS/PDF output is not now possible for '+p(q[k]).vname+ $
          ;      ', which is a '+thisptype+' display'+mm
        endfor
        ;print, 'ERROR= PS/PDF output(s) failed.'
        ; RCJ  if all are going to fail (-1 because one is Epoch) return error
        ;    if not, each failing ps plot will be skipped below,
        ;    when its turn comes about.
        ;if failed eq n_elements(p(*).ptype)-1 then return, -1
      endif
      ;if (pheight eq 5000 and total_npanels gt 4) then begin
      ;   print,'STATUS= No more than 4 plots for ps/pdf please!'
      ;   print, 'ERROR= More than 4 plots requested for ps'
      ;   return, -1
      ;endif
      ;if (pheight eq 10000 and total_npanels gt 2) then begin
      ;   print,'STATUS= No more than 2 plots for ps/pdf please!'
      ;   print, 'ERROR= More than 2 plots requested for ps'
      ;   return, -1
      ;endif
    endif

    ; append the plot evaluations of the current structure to any previous ones
    if (i eq 0) then PS = p else PS = [PS,p]
    ; RTB changed from a_id = i
    ; a_id = i
    ; if (i eq 0) then a_id=-1 else a_id = i ; set parameter id variable
  endfor ; evaluate every data structure

  ; Check flag to determine if any plottable variables were found.
  ;TJK changed the two status messages to be a little more descriptive -
  ;basically, no data was found that could be plotted.
  ;TJK 12/21/2005 added check for ptype - if its equal to -1, then we've
  ;already printed out the error and status, don't print the message below
  if (plottable_found eq 0) then begin
    if (p[0].ptype gt -1) then begin
      print,'STATUS=No plottable data found for selected variables.'
      print,'STATUS=Please select another time range. Either your time range was too short (no data found for the interval) or'
      print,'STATUS=too long (your session timed out before all of the data you requested could be read).'
    endif
    if (reportflag eq 1) then begin
      printf,1,'STATUS=A plotting error has occurred'
      close,1
    endif
    return,-1
  endif

  ; make sure timetexts will be displayed last in gif/ps/window:
  if keyword_set(combine) then begin
    ;   q12 = where(ps.ptype eq 12 or ps.ptype eq 0)
    ;   if q12[0] ne -1 then begin
    ;      qnot12=where(ps.ptype ne 12 and ps.ptype ne 0)
    ;      if qnot12[0] ne -1 then begin
    ;         ps_tmp=[ps[qnot12],ps[q12]]
    ;      endif else begin
    ;         ps_tmp=[ps[q12[0]],ps[q12]]
    ;         ps_tmp[0].vname='CDAWeb_created_variable' & ps_tmp[0].ptype=1 & ps_tmp[0].npanels=1
    ;      endelse
    ;
    ; RCJ 21Oct2016.  Replaced code above with below. Timetext failed if there were plot types listed that
    ;       were not 1, for example: [9,0,0,0,12]
    q12 = where(ps.ptype eq 12,count12)
    q_zero=where(ps.ptype eq 0,count0)
    if q12[0] ne -1 then begin
      qnot12=where(ps.ptype ne 12)
      ;q1=where(ps.ptype eq 1)
      ; RCJ 24Mar2017  Time axis above plot if type 2 or 7, so added these here:
      q1=where(ps.ptype eq 1 or ps.ptype eq 2 or ps.ptype eq 7)
      if (q12[0] eq -1) then begin
        ps_tmp=[ps[qnot12],ps[q_zero]]
      endif else begin
        if (q1[0] eq -1) then begin
          ps_tmp=[ps[q12[0]],ps[qnot12],ps[q12],ps[q_zero]]
          ps_tmp[0].vname='CDAWeb_created_variable' & ps_tmp[0].ptype=1 & ps_tmp[0].npanels=1
        endif else begin
          ps_tmp=[ps[qnot12],ps[q12],ps[q_zero]]
        endelse
      endelse
    endif else begin
      ps_tmp=ps
    endelse
    ps=ps_tmp
  endif else begin
    min_snum=min(ps.snum,max=max_snum)
    psd=[ps[0]]
    psd.ptype=-99
    for i=min_snum,max_snum do begin
      q_snum=where(ps.snum eq i)
      ps_snum=ps[q_snum]
      ;;q12=where(ps_snum.ptype eq 12 or ps_snum.ptype eq 0) ; support data (0) goes
      ;q12=where(ps_snum.ptype eq 12 or ps_snum.ptype eq 0) ; support data (0) goes
      ;							; after plot types
      ;q_zero=where(ps_snum.ptype eq 0,count)
      ;;if q12[0] ne -1 then begin
      ;if (q12[0] ne -1) and (count ne n_elements(ps_snum.ptype)) then begin
      ;   qnot12=where(ps_snum.ptype ne 12 and ps_snum.ptype ne 0)
      ;   if qnot12[0] ne -1 then begin
      ;      ps_tmp=[ps_snum[qnot12],ps_snum[q12]]
      ;   endif else begin
      ;      ps_tmp=[ps_snum[q12[0]],ps_snum[q12]]
      ;      ps_tmp[0].vname='CDAWeb_created_variable' & ps_tmp[0].ptype=1 & ps_tmp[0].npanels=1
      ;   endelse

      ; RCJ 21Oct2016.  Similarly as above
      q12=where(ps_snum.ptype eq 12,count12) ; support data (0) goes
      ; after plot types
      q_zero=where(ps_snum.ptype eq 0,count0)
      ;if (q12[0] ne -1) and ((count0+count12) ne n_elements(ps_snum.ptype)) then begin
      ; RCJ 24Mar2017 Did not return plot if only timetext requested, fix: ne -> le
      if (q12[0] ne -1) and ((count0+count12) le n_elements(ps_snum.ptype)) then begin
        qnot12=where(ps_snum.ptype ne 12)
        ;q1=where(ps_snum.ptype eq 1)
        ; RCJ 24Mar2017  Time axis above plot if type 2 or 7, so added these here:
        q1=where(ps_snum.ptype eq 1 or ps_snum.ptype eq 2 or ps_snum.ptype eq 7)
        if (q12[0] eq -1) then begin
          ps_tmp=[ps_snum[qnot12],ps_snum[q_zero]]
        endif else begin
          if (q1[0] eq -1) then begin
            ps_tmp=[ps_snum[q12[0]],ps_snum[qnot12],ps_snum[q12],ps_snum[q_zero]]
            ps_tmp[0].vname='CDAWeb_created_variable' & ps_tmp[0].ptype=1 & ps_tmp[0].npanels=1
          endif else begin
            ps_tmp=[ps_snum[qnot12],ps_snum[q12],ps_snum[q_zero]]
          endelse
        endelse
      endif else begin
        ps_tmp=[ps_snum]
      endelse
      psd=[psd,ps_tmp]
    endfor
    ps=psd[where(psd.ptype ne -99)]
  endelse
  ;
  ; n_q12 and q12 to be used later, if keyword 'combine' is set. RCJ
  q12 = where(ps.ptype eq 12,n_q12)
  ;
  ; For SSCWEB read keyword file
  if(SSCWEB) then begin
    REPORT=OUTDIR+'idl_'+PID+'.rep'
    reportflag=1L
    OPENW,1,REPORT,132,WIDTH=132
    station=create_struct('NUM',0)
    status=map_keywords(ORB_VW=orb_vw, XUMN=xumn, XUMX=xumx, YUMN=yumn, $
      YUMX=yumx,ZUMN=zumn,ZUMX=zumx,RUMN=rumn,RUMX=rumx,  $
      DOYMARK=doymark, HRMARK=hrmark, HRTICK=hrtick, $
      MNTICK=mntick,MNMARK=mnmark,LNTHICK=lnthick,$
      CHTSIZE=chtsize, BZ=bz, PRESS=press, STATION=station, $
      IPROJ=iproj,LIM=lim,LATDEL=latdel, LONDEL=londel, $
      Ttitle=thetitle,SYMSIZ=symsiz, SYMCOL=symcol, POLAT=polat, $
      POLON=polon, ROT=rot, LNLABEL=lnlabel,BSMP=bsmp,ATLB=autolabel,$
      DTLB=datelabel,XSIZE=xs_ssc,YSIZE=ys_ssc, NOCONT=nocont,$
      EQLSCL=eqlscl,PANEL=panel,$
      REPORT=reportflag,PID=PID,OUTDIR=OUTDIR,US=us,_extra=extras)

    ;TJK quick test to see if I can change the line thickness
    ;lnthick = 2.0
    if (not(keyword_set(ps))) then begin
      if(n_elements(xs_ssc) ne 0) then WS.xs=xs_ssc
      if(n_elements(ys_ssc) ne 0) then WS.ys=ys_ssc
      print, 'not setting xs_ssc and yx_ssc because want postscript'
    endif
  endif

  ; Need to determine GIF naming method, which depends on whether only a single ; GIF file or multiple ones.  Currently, only a single GIF can be produced
  ; by this routine, but this will have to change, and this will involve the
  ; other plot types, which will have to be in separate gifs.
  multiple_gifs = 0L & gif_counter = 0L ; initialize assuming single
  if keyword_set(GIF) then begin
    if ((NOT keyword_set(COMBINE))AND(n_params() gt 1)) then multiple_gifs=1L
  endif
  ; RCJ. multiple_gifs is not used so I'm not going to create
  ; the same var for postscript, only ps_counter:
  ps_counter=0L

  ; If we are combining variables from different megastructures, then we must
  ; determine the start time and stop time of the data so that they can be
  ; plotted along a common axis.  This is overridden by TSTART/TSTOP keywords

  ; TJK commented out start_time = 0.0D0 ; initialize
  ; need to set default values for start_time and stop_time
  ; if min in p.btime = [0,0,epoch] then min epoch will be missed RTB
  btime=ps.btime                                ; RTB
  we=where(btime ne 0.D0,wc)                   ; RTB
  if (wc gt 0) then min_ep=btime[we] $
  else min_ep=0.D0  ; need some default value. min_ep would be
  ;undefined below if time range requested has no data in it

  ; RCJ 05/28/2003  var fUHR from dataset po_h1_pwi caused problem here
  ; when one of its cdfs had all virtual values for epoch,
  ; making btime=0.0D0, the default
  ; TJK 10/27/2006 - add checking for epoch16 times when epoch doesn't exist
  ; RCJ 04/09/2013  Look for tt2000 too
  if we[0] eq -1 then begin
    ;btime = ps.btime16 ;try looking for epoch16 value
    ;we=where(btime ne 0.D0,wc)
    ;if we[0] eq -1 then min_ep=0.0D0 else min_ep=btime[we]
    btime16 = ps.btime16 ;try looking for epoch16 value
    btime2000 = ps.btimett2000 ;try looking for tt2000 value
    we1=-1 & we2=-1
    we1=where(btime16 ne 0.D0,wc)
    we2=where(btime2000 ne long64(0),wc)
    if we1[0] ne -1 then min_ep=btime16[we1]
    if we2[0] ne -1 then min_ep=btime2000[we2]
  endif

  etime=ps.etime
  we=where(etime ne 0.D0,wc)
  if (wc gt 0) then max_ep=etime[we] else $
    max_ep=0.D0  ; need some default value. max_ep would be
  ;undefined below if time range requested has no data in it


  ;TJK 10/27/2006 - add checking for epoch16 end times when epoch doesn't exist
  ; RCJ 04/09/2013  Look for tt2000 too
  if we[0] eq -1 then begin
    ;etime = ps.etime16 ;try looking for epoch16 value
    ;we=where(etime ne 0.D0,wc)
    ;if we[0] eq -1 then max_ep=0.0D0 else max_ep=etime[we]
    etime16 = ps.etime16 ;try looking for epoch16 value
    etime2000 = ps.etimett2000 ;try looking for tt2000 value
    we1=-1 & we2=-1
    we1=where(etime16 ne 0.D0,wc)
    we2=where(etime2000 ne 0.D0,wc)
    if we1[0] ne -1 then max_ep=etime16[we1]
    if we2[0] ne -1 then max_ep=etime2000[we2]
  endif

  start_time = min(min_ep)
  stop_time = max(max_ep)
  ;print,'start time ', start_time, ' ', 'stop_time ',stop_time, ' before tstart/tstop code'

  ; TJK 7/20/2006 - compute the equivalent epoch16 start/stop times so
  ;                 that comparison w/ data stored as epoch16 is
  ;                 possible.

  ;if keyword_set(TSTART) then begin ; determine datatype and process if needed
  if (keyword_set(TSTART) or ((not keyword_set(TSTART)) and (start_time ne 0.0))) then begin ; determine datatype and process if needed
    if ((not keyword_set(TSTART)) and (start_time ne 0.0)) then TSTART=start_time
    b = size(TSTART) & c = n_elements(b)
    ;   if (b(c-2) eq 5) then start_time = TSTART $    ; double float already
    ;   else if (b(c-2) eq 7) then start_time = encode_cdfepoch(TSTART) $ ; string

    case b[c-2] of
      5: begin
        start_time = TSTART
      end
      7: begin
        ;TJK 10/23/2009 if the TSTART value has a milliseconds component, use
        ;that when computing the start time (to get the precision)
        split_ep=strsplit(TSTART,'.',/extract)

        start_time = encode_cdfepoch(TSTART) ; string
        ;start_time16 = encode_cdfepoch(TSTART,/EPOCH16) ; string
        if (n_elements(split_ep) eq 2) then begin
          start_time16 = encode_cdfepoch(TSTART,/EPOCH16,msec=split_ep[1]) ; string
          start_timett = encode_cdfepoch(TSTART, /TT2000, MSEC=split_ep[1])    ;TJK added for TT2000 time
        endif else begin
          start_time16 = encode_cdfepoch(TSTART,/EPOCH16) ; string
          start_timett = encode_cdfepoch(TSTART, /TT2000)    ;TJK added for TT2000 time
        endelse
      end
      14:  begin
        start_timett=TSTART ; already long64
      end
      else: begin
        if (reportflag eq 1) then $
          printf,1,'STATUS= Time Range Error' & close, 1
        print,'STATUS= Time Range Error'
        print,'ERROR= TSTART parameter must be STRING or DOUBLE' & return,-1
      end
    endcase

  endif else begin
    if keyword_set(COMBINE) then begin
      ; first find all structures with variable plotted as t/s or spectrum
      if keyword_set(DEBUG) then print,'Computing combined axis start time...'
      w = where(((PS.ptype eq 1) OR (PS.ptype eq 2)),wc)
      if (wc gt 0) then begin ; now find earliest time of these structures
        b = PS[w].snum & bs = size(b) ; determine structure numbers
        if (bs[0] gt 0) then begin & c=uniq(b) & b=b[c] & endif ; make list
        ;c = where(PS.btime ne 0.0D0,wc) ; find list of all start times
        c = where(((PS.btime ne 0.0D0) and (strpos(strupcase(ps.vname),'EPOCH') ne -1)),wc)
        if (wc gt 0) then begin ;TJK added
          w = where(PS[c].snum eq b) ; find which times belong to t/s & spectro
          start_time = min(PS[c[w]].btime) & b = decode_cdfepoch(start_time)
          if keyword_set(DEBUG) then print,'Combined axis start time=',b
        endif else $
          if keyword_set(DEBUG) then print,'Combined axis start time=',start_time
      endif
    endif
  endelse


  ; If we are combining variables from different megastructures, then we must
  ; determine the stop time of the data so that they can be plotted along a
  ; common axis.  This is overridden by TSTOP keyword.
  ; TJK commented out stop_time = 0.0D0 ; initialize

  ;if keyword_set(TSTOP) then begin ; determine datatype and process if needed
  if (keyword_set(TSTOP) or ((not keyword_set(TSTOP)) and (stop_time ne 0.0)))  then begin ; determine datatype and process if needed
    if ((not keyword_set(TSTOP)) and (stop_time ne 0.0)) then TSTOP=stop_time
    b = size(TSTOP) & c = n_elements(b)
    ;   if (b(c-2) eq 5) then stop_time = TSTOP $ ; double float already
    ;   else if (b(c-2) eq 7) then stop_time = encode_cdfepoch(TSTOP) $ ; string

    case b[c-2] of
      5: begin
        stop_time = TSTOP       ; stop_time is double float already
      end
      7: begin
        ;TJK 10/23/2009 if the TSTOP value has a milliseconds component, use
        ;that when computing the start time (to get the precision)
        split_ep=strsplit(TSTOP,'.',/extract)
        stop_time = encode_cdfepoch(TSTOP) ; string
        ;          stop_time16 = encode_cdfepoch(TSTOP,/EPOCH16) ; string
        if (n_elements(split_ep) eq 2) then begin
          stop_time16 = encode_cdfepoch(TSTOP,/EPOCH16,msec=split_ep[1]) ; string
          stop_timett = encode_cdfepoch(TSTOP, /TT2000, MSEC=split_ep[1])    ;TJK added for TT2000 time
        endif else begin
          stop_time16 = encode_cdfepoch(TSTOP,/EPOCH16) ; string
          stop_timett = encode_cdfepoch(TSTOP, /TT2000)    ;TJK added for TT2000 time
        endelse
      end
      14: begin
        stop_timett= TSTOP  ; already long64
      end
      else: begin
        if (reportflag eq 1) then $
          printf,1,'STATUS= Time range error.' & close,1
        print,'ERROR= TSTOP parameter must be STRING or DOUBLE' & return,-1
        print, 'STATUS= Time range error.'
      end
    endcase

  endif else begin
    if keyword_set(COMBINE) then begin
      ; first find all structures with variable plotted as t/s or spectrum
      if keyword_set(DEBUG) then print,'Computing combined axis stop time...'
      w = where(((PS.ptype eq 1)OR(PS.ptype eq 2)),wc)
      if (wc gt 0) then begin ; now find latest time of these structures
        b = PS[w].snum & bs = size(b) ; determine structure numbers
        if (bs[0] gt 0) then begin & c=uniq(b) & b=b[c] & endif ; make list
        c = where(PS.etime ne 0.0D0,wc) ; find list of all stop times
        if (wc gt 0) then begin ;TJK added
          w = where(PS[c].snum eq b) ; find which times belong to t/s & spectro
          stop_time = max(PS[c[w]].etime) & b = decode_cdfepoch(stop_time)
          if keyword_set(DEBUG) then print,'Combined axis stop time=',b
        endif else $
          if keyword_set(DEBUG) then print,'Combined axis stop time=',stop_time
      endif
    endif
  endelse


  ; Modify the window margin if ordered or required for spectrogram plots
  if keyword_set(CDAWEB) then begin ; leave space for colorbar
    ; TJK change this allow more space on the right  WS.xmargin=[100,100] & cdawebflag = 1L
    case plottype of
      'pscript': begin
        ;WS.xmargin=[2000,1500] ; see later if this needs to change
        cdawebflag = 1L
      end
      else: begin  ; gif/xwindows
        WS.xmargin=[90,110]
        cdawebflag = 1L
      end
    endcase
  endif else begin ; determine if extra space for spectrogram colorbar is needed
    w = where(PS.ptype eq 2,wc)
    if (wc gt 0) then WS.xmargin=[89,110]
    cdawebflag = 0L
  endelse

  ;if ((NOT keyword_set(GIF)) and keyword_set(CDAWEB)) then begin
  if (plottype eq '' and keyword_set(CDAWEB)) then begin
    CDAWEB = 0L ; turn CDAWEB off if no gif.
    cdawebflag = 0L
  endif

  ; Make a pass thru the plot script and generate all timeseries and
  ; spectrogram plots.  Create windows or gif files as needed.

  ; gather some info to be used if there is ptype = 12. RCJ
  case plottype of
    'pscript': begin  ; these are all .... empirical.
      pheight_12=500
      labeloffset=-1500
    end
    else: begin  ; same for gif/xwindows
      pheight_12=10 ; 10 is the ysize of each line of label
      labeloffset=-40
    end
  endcase
  prev_snum=ps[0].snum
  ;
  if keyword_set(COMBINE) then begin
    combined_title = 'Multiple datasets being plotted; refer to labels on either side of plot. ' ;TJK added 10/14/2003
    pi_list = 'Please acknowledge data provider(s), '
    l_source = ''
  endif
  if keyword_set(TOP_TITLE) then begin
    combined_title = 'Multiple datasets being plotted; refer to labels on either side of plot. !C'+top_title ;TJK added 10/14/2003
    pi_list = 'Please acknowledge data provider(s), '
    l_source = ''
  endif

  for i=0,n_elements(PS)-1 do begin

    ;TJK 3/14/2012 - add this check for ptype of -1 to go w/ added a
    ;                display_type value of "no_plot", so that we can turn
    ;                off plotting of certain variables in the masters.
    ; Added condition that ibad be 0.  The following section should only be 
    ; executed in response to the the no_plot display type.  Adding this condition
    ; ensures that it is not also entered when a invalid data structure is passed
    ; to plotmaster.
    ; Ron Yurow (March 9, 2017)
    ; if (PS[i].ptype eq -1 and  PS[i].npanels eq 0) then begin
    if (PS[i].ptype eq -1 and  PS[i].npanels eq 0 and PS[i].ibad eq 0) then begin
      print, 'STATUS=',PS[i].source,':',PS[i].vname,' plotting not supported.'
    endif
    ; Prepare for plotting by creating window and last_plot flag
    ;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if ((PS[i].ptype eq 1)OR(PS[i].ptype eq 2)OR(PS[i].ptype eq 7)OR $
      (PS[i].ptype eq 12)) then begin
      ; 1: time_series
      ; 2: spectrogram, topside_ionogram, bottomside_ionogram
      ; 7: stack_plot
      ; 12: time_text
      ;
      q12snum=where(ps.snum eq ps[i].snum and ps.ptype eq 12,n_q12snum)
      if not keyword_set(combine) and (q12snum[0] ne -1) and (ps[i].snum ne prev_snum) then begin
        if plottype eq 'gif' then labeloffset=-40  ; reset offset for next timetext
        if plottype eq 'pscript' then labeloffset=-1500  ; reset offset for next timetext
        prev_snum=ps[i].snum
      endif
      ;if q12snum[0] ne -1 then print,ps(q12snum).vname,ps(q12snum).ptype,ps(q12snum).npanels
      ;
      ; Determine if this plot will fit within current window/gif
      ;if (ps[i].ptype eq 12) then b = WS.pos[3] - (ps[i].npanels * pheight_12) $
      ;else b = WS.pos[3] - (ps[i].npanels * pheight)
      ; RCJ 09/28/2007  This *1. is needed. npanels and pheight
      ; are integers and if npanels is too high (8 already caused
      ; problems) then the multiplication of the 2 will give us
      ; garbage in return.
      if (PS[i].ptype eq 12) then b = WS.pos[3] - (PS[i].npanels*1. * pheight_12) $
      else b = WS.pos[3] - (PS[i].npanels*1. * pheight)
      ;if (b lt WS.ymargin[1]) then new_window = 1 else new_window = 0
      ; the above statement was valid when we only had graphs
      ; but now we have labels too. RCJ 03/10/00
      if (b lt 50) then new_window = 1 else new_window = 0

      ; if nonoise is set, make title say so
      if keyword_set(nonoise) then ps[i].title=ps[i].title+'!CFiltered to remove values >3-sigma from mean of all plotted values'

      ; Create a window/gif/ps file if current plot will not fit

      if (new_window eq 1) then begin
        if keyword_set(DEBUG) then print,'Creating new window...'
        ;if keyword_set(GIF) then begin ; writing to gif file
        if (plottype eq 'gif' or plottype eq 'pscript') then begin
          ; writing to gif/ps file
          ; Close the currently open gif file - if any
          ;if (gifopen eq 1) then begin
          if (gif_ps_open eq 1) then begin
            if plottype eq 'pscript' then $
              project_subtitle,a.(0),mytitle,/ps,SSCWEB=SSCWEB,tcolor=0 $; title/subtitle the ps
            else $
              project_subtitle,a.(0),mytitle,SSCWEB=SSCWEB,tcolor=0 ; title/subtitle the gif
            deviceclose & gif_ps_open=0 ; close it
          endif
          ;TJK 12/14/2004 - need to check whether ELEMENTS are specified, if so this determines the
          ;number of panels for a given variable for a dataset.  Reine is trying to use this in her
          ;Web services client...

          if n_elements(ELEMENTS) ne 0 then begin
            PS[i].npanels = n_elements(ELEMENTS)
          endif
          ; Determine the size for the next gif file
          if keyword_set(COMBINE) then begin
            ; compute size to fit t/s and spectrograms for ALL variables
            w = where((PS.ptype eq 1)OR(PS.ptype eq 2)OR(PS.ptype eq 7))
            ;RChimiak 09 June 2016 changes below to accomodate combine with plotmerge
            ;if (w[0] ne -1) then b = (total(PS[w].npanels)*1. * pheight) else b = 0

            if (w[0] ne -1) then begin
              wp = where(PS.ptype eq 1)
              if (plotmerge  eq 2 && wp[0] ne -1) then begin
                arr = STRARR(N_ELEMENTS(wp))
                for ind=0,N_ELEMENTS(wp)-1 DO BEGIN 
                  sub = STRJOIN(STRSPLIT( PS[wp[ind]].VNAME, (STRSPLIT( PS[wp[ind]].SOURCE,'_',/EXTRACT))[0],/Regex, /Extract, $
                    /Preserve_Null,/fold_case))
                 
                  if(where (STRCMP(arr ,sub)) EQ -1 ) then begin
                    arr[ind] = sub
                    if (n_elements(wtemp) eq 0) then  wtemp = [wp[ind]] else $
                      wtemp= [wtemp,wp[ind]]
                  endif
                endfor            
                w = [wtemp,where(PS.ptype ne 1)] 
              endif
              
              b = (total(PS[w].npanels)*1. * pheight)
            endif else b = 0

            if (q12[0] ne -1) then b = b +(total(ps[q12].npanels)*1.* pheight_12)
            if (n_params() eq 1) then mytitle = ps[i].title else mytitle=''
          endif else begin
            ; compute size to fit t/s and spectrograms for THIS structure
            w = where((PS.snum eq PS[i].snum) and ((PS.ptype eq 1)OR(PS.ptype eq 2)OR(PS.ptype eq 7)))
            if (w[0] ne -1) then b = plotmerge eq 2 ? $
              (PS[i].npanels*1. * pheight): $
              (total(PS[w].npanels)*1. * pheight) else b = 0
            if (q12snum[0] ne -1) then b = b + (total(ps[q12snum].npanels)*1. * pheight_12)
            mytitle = PS[i].title
          endelse

          ; Determine name for new gif file and create GIF/window
          ;if (gif_counter gt 0) then begin
          ;c = strpos(GIF,'.gif') ; search for .gif suffix
          ;if (c ne -1) then begin
          ;c = strmid(GIF,0,c) & GIF=c+strtrim(string(gif_counter),2)+'.gif'
          ;endif else GIF=GIF+strtrim(string(gif_counter),2)
          ;endif
          if plottype eq 'gif' then begin
            if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
            if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
            if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
            GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
            ; Initialize window state and open the gif file
            WS.ys = b + WS.ymargin[0] + WS.ymargin[1] ; add room for timeaxis
            ;
            deviceopen,6,fileOutput=GIF,sizeWindow=[WS.xs,WS.ys]
            ;deviceopen,6,fileOutput=GIF,sizeWindow=[20000,20000]
            gif_ps_open=1L & gif_counter = gif_counter + 1
          endif
          if plottype eq 'pscript' then begin
            if(ps_counter lt 100) then psn='0'+strtrim(string(ps_counter),2)
            if(ps_counter lt 10) then psn='00'+strtrim(string(ps_counter),2)
            if(ps_counter ge 100) then psn=strtrim(string(ps_counter),2)
            out_ps=outdir+PS[i].source+'_'+pid+'_'+psn+'.eps'
            ; Initialize window state and open the ps file
            WS.ys = b + WS.ymargin[0] + WS.ymargin[1] ; add room for timeaxis
            ;
            deviceopen,1,fileOutput=out_ps,/portrait,sizeWindow=[WS.xs,WS.ys]
            gif_ps_open=1L & ps_counter = ps_counter + 1
          endif
          ; RTB test p.charsize for carriage returns in labels
          ;!P.Charsize=1

          ; Modify source name for SSCWEB DATASET label
          if(SSCWEB) then begin
            if (ps[i].snum ne a_id) then begin
              s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
            endif
            satname=strtrim(a.epoch.source_name,2)
            PS[i].source= PS[i].source + '_' + satname
          endif

          if (reportflag eq 1) then begin
            printf, 1, 'DATASET=',PS[i].source
            ;printf,1,'GIF=',GIF
            if plottype eq 'gif' then printf,1,'GIF=',GIF
            if plottype eq 'pscript' then printf,1,'PS=',out_ps
          endif

          ;TJK 7/11/2007 dataset names are too long to fit on one IDL output
          ;line, need to split in two.  Decided not to get into this split
          ;name/dir business for the SSC case (reportflag section above) since
          ;we only have short s/c names to deal w/ in SSC.


          print, 'DATASET=',PS[i].source

          ;            if plottype eq 'gif' then print,'GIF=',GIF
          if plottype eq 'gif' then begin
            split=strsplit(GIF,'/',/extract)
            loutdir='/'
            for t=0L,n_elements(split)-2 do loutdir=loutdir+split[t]+'/'
            print, 'GIF_OUTDIR=',loutdir
            fmt='(a9,a'+strtrim(strlen(split[t]),2)+')'
            print, 'LONG_GIF=',split[t], format=fmt

          endif
          ;            if plottype eq 'pscript' then print,'PS=',out_ps
          if plottype eq 'pscript' then begin
            split=strsplit(out_ps,'/',/extract)
            loutdir='/'
            for t=0L,n_elements(split)-2 do loutdir=loutdir+split[t]+'/'
            print, 'PS_OUTDIR=',loutdir
            fmt='(a8,a'+strtrim(strlen(split[t]),2)+')'
            print, 'LONG_PS=',split[t], format=fmt
          endif
        endif  ; end if keyword_set(GIF)

        ;if NOT keyword_set(GIF) then begin ; producing XWINDOWS
        if (plottype ne 'gif' and plottype ne 'pscript') then begin ; producing XWINDOWS
          if keyword_set(COMBINE) then begin ; size for as many vars as possible
            b=0 & c=0 ; initialize loop
            for j=i,n_elements(PS)-1 do begin & d = PS[j].ptype
            ;if ((d eq 1)OR(d eq 2)) then begin
            if ((d eq 1)OR(d eq 2)OR(d eq 7)OR(d eq 12)) then begin
              if (d eq 12) then b = PS[j].npanels*1. * pheight_12 $
              else b = PS[j].npanels*1. * pheight
              if ((c+b) le (max_ysize - WS.ymargin[1])) then c=c+b
            endif
          endfor
          if (n_params() eq 1) then mytitle = PS[i].title else mytitle=''
        endif else begin ; size only for variables from current structure
          b=0 & c=0 ; initialize loop
          for j=i,n_elements(PS)-1 do begin
            if (PS[j].snum eq PS[i].snum) then begin & d = PS[j].ptype
            if ((d eq 1)OR(d eq 2)OR(d eq 7)OR(d eq 12)) then begin
              ;if ((d eq 1)OR(d eq 2)) then begin
              if (d eq 12) then b = PS[j].npanels*1. * pheight_12 $
              else b = PS[j].npanels*1. * pheight
              if ((c+b) le (max_ysize - WS.ymargin[1])) then c=c+b
            endif
          endif
        endfor
        mytitle = PS[i].title
      endelse

      ; Verify that the height of the new window is valid
      if (c eq 0) then begin
        if (reportflag eq 1) then begin
          printf,1,'STATUS=An error occurred plotting this variable
          close, 1
        endif
        print,'STATUS=An error occurred plotting this variable
        print,'ERROR=Single variable does not fit in window' & return,-1
      endif else begin ; create the window and initialize window_state
        WS.ys = c + WS.ymargin[0] + WS.ymargin[1] ; add room for timeaxis
        deviceopen, 0 ;TJK added so that labels will come out on stacked and spectrogram
        window,/FREE,XSIZE=WS.xs,YSIZE=WS.ys,TITLE=mytitle
        ; RCJ 01/29/2007  Set gifopen=1 even if this is not a gif
        ;  because we want the subtitles to the graphs, which
        ;  is done below and only if gif_ps_open=1.
        gif_ps_open=1
        if (reportflag eq 1) then printf,1,'WINDOW=',mytitle
      endelse
      ;endif  ; end if not keyword_set(GIF)
    endif  ; end if plottype is not gif or ps, ie, it's an xwindow

    ; Reinitialize window state
    WS.snum = PS[i].snum
    WS.pos[0] = WS.xmargin[0]                     ; x origin
    WS.pos[2] = WS.xs - WS.xmargin[1]             ; x corner
    WS.pos[3] = WS.ys - WS.ymargin[0]             ; y corner
    if (PS[i].ptype eq 12) then WS.pos[1] = (WS.ys - WS.ymargin[0]) - pheight_12 $
    else WS.pos[1] = (WS.ys - WS.ymargin[0]) - pheight ; y origin

  endif  ; end if new_window eq 1

  ; Determine if this plot will be the first/last in the window
  first_plot = new_window ; it is first if this is a new window
  ; RCJ 09/28/2007  The *1. below is needed. See full explanation by searching for 'RCJ 09/28/2007'
  if (PS[i].ptype eq 12) then b = WS.pos[1] - (PS[i].npanels*1. * pheight_12) $
  else b = WS.pos[1] - (PS[i].npanels*1. * pheight)

  ; Life was simple before the time_text plots:    RCJ
  ;if (b lt WS.ymargin[1]) then last_plot = 1 else last_plot = 0
  ; Now this is what we have to do to determine last_plot:
  if (PS[i].ptype ne 12) then begin
    if (b lt WS.ymargin[1]) then last_plot = 1 else last_plot = 0
    if (q12[0] ne -1) then begin
       ;  RCJ 14Dec2016  This is a bit of a trick because I need to know if there's no other
       ;  plot type before type 12 (ie, timetext).  So, what I need to know is if there are only
       ; zeros between the plot I'm going to do now and the first timetext.
       ;  If my PS.ptype array is [1,1,0,0,1,0,12] I need to find out what's between the current
       ;  plot (type 1 here) and the first type 12.  If there are only zeros then last_plot=1
       ;
       ;  RCJ 10Feb2017 Added this 'if' for case ps.ptype = [0,1,1,0,0,1,12,12,0] , came up for binned data. 
       if (ps[i+1].ptype eq 12) then begin
         last_plot=1
       endif else begin 
         ; RCJ 10Jan2017  Test case where PS.ptype=[2,1,0,12,12,0,2,1,0,12,12,0,0] .  Need to add another 'where':
         qq12=where(q12 gt i)
         if qq12[0] ne -1 then begin
           ;RCJ 02Feb2017  Added this 'if' for case PS.ptype = [2,1,0,0,0,12,0,0,0,2,0,0,0]
          qq=where(PS[i+1:q12[qq12[0]]-1].ptype ne 0) 
          if qq[0] eq -1 then last_plot=1 else last_plot=0
         endif
       endelse
    endif
  endif else last_plot=1     
  if (PS[i].ptype eq 12) then begin
    if keyword_set(combine) then begin
      if (n_q12 eq 1) then last_plot = 1 else last_plot = 0
      n_q12=n_q12-1
    endif else begin
      if (n_q12snum eq 1) then last_plot = 1 else last_plot = 0
      n_q12snum=n_q12snum-1
    endelse
  endif
endif   ; end if ps.ptype eq 1,2,7 or 12


;TJK 11/30/2006 - save off and restore start/stop time values so that
;subsequent dataset calls w/o epoch16 values will work (they need the
;regular epoch value

if (i eq 0) then begin
  save_start_time = start_time
  save_stop_time = stop_time
endif else begin
  start_time = save_start_time
  stop_time = save_stop_time
endelse

; Generate TIME SERIES plots
if (PS[i].ptype eq 1) then begin
  ; Ensure that 'a' holds the correct data structure
  SCATTER = 0L  ; turn off by default
  noerrorbars = 0L  ; turn off by default

  if (PS[i].snum ne a_id) then begin
    s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
  endif
  ; Get the index of the time variable associated with variable to be plotted
  b = a.(PS[i].vnum).DEPEND_0 & c = spd_cdawlib_tagindex(b[0],tag_names(a))
  ; Produce debug output if requested
  if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as time series.'
  ;****** TJK adding code for handling the parsing of the DISPLAY_TYPE attribute
  ; 	for time series plots.  In this plot types case, we are looking for a
  ;        a syntax like time_series>y=flux[1] (July 30, 1999).
  ; determine how many dimensions are in the data by looking at
  ; the data - unfortunately I have to get it out of either the plain
  ; structure or a handle.

  Yvar = (a.(PS[i].vnum))
  t = size(Yvar)
  if (t[n_elements(t)-2] ne 8) then begin
    print,'ERROR=input to spd_cdawlib_plotmaster not a structure' & return,-1
  endif else begin
    YTAGS = tag_names(Yvar) ; avoid multiple calls to tag_names
    t = spd_cdawlib_tagindex('DAT',YTAGS)
    if (t[0] ne -1) then THEDATA = Yvar.DAT $
    else begin
      t = spd_cdawlib_tagindex('HANDLE',YTAGS)
      if (t[0] ne -1) then handle_value,Yvar.HANDLE,THEDATA $
      else begin
        print,'ERROR=Yvariable does not have DAT or HANDLE tag' & return,-1
      endelse
    endelse
  endelse
  datasize = size(thedata)
  ; Determine if the display type variable attribute is present
  d = spd_cdawlib_tagindex('DISPLAY_TYPE',tag_names(a.(PS[i].vnum)))
  if (d[0] ne -1) then begin
    ;TJK 5/14/2001 - added two "keywords" to the display_type syntax for time_series, scatter and noauto
    ; to allow for scatter plots vs. line plots and no auto scaling (use the values specified in
    ; the scalemin/max attributes.
    keywords=str_sep(a.(PS[i].vnum).display_type,'>')  ; keyword 1 or greater
    scn=where(strupcase(keywords) eq 'SCATTER',sn)
    ;turn scatter plot on if "scatter" is set
    if (sn gt 0) then SCATTER = 1L else SCATTER = 0L
    ; Reusing vars:
    scn=where(strupcase(keywords) eq 'NOERRORBARS',sn)
    if (sn gt 0) then noerrorbars = 1L else noerrorbars = 0L

    ;TJK 2/4/2004, save the autoscaling setup that was passed in by the calling program
    ;so that it can be restored at the bottom of the time-series plot type code.
    if (autoscale) then save_auto = 1L else save_auto = 0L
    acn=where(strupcase(keywords) eq 'NOAUTO',noauto) ;noauto is a display_type keyword that overrides
    ;auto that's passed in.
    ;turn autoscaling off if "noauto" is set
    ;TJK 10/21/2004 don't set autoscale "on" if noauto isn't set
    ;	  if (noauto gt 0) then autoscale = 0L else autoscale = 1L
    if (noauto gt 0) then autoscale = 0L

    ; examine_spectrogram_dt looks at the DISPLAY_TYPE structure member in
    ; detail. for spectrograms and stacked time series the DISPLAY_TYPE
    ; can contain syntax like the following: stack_plot>y=flux[1],y=flux[3],
    ; y=flux[5],z=energy where this indicates that we only want to plot
    ; the 1st, 3rd and 5th energy channel for the flux variable. This
    ; routine returns a structure of the form e = {x:xname,y:yname,z:zname,
    ; npanels:npanels,dvary:dvary,elist:elist,lptrn:lptrn,igram:igram},

    e = examine_spectrogram_dt(a.(PS[i].vnum).DISPLAY_TYPE, thedata=thedata,$
      data_fillval=a.(PS[i].vnum).fillval, $
      valid_minmax=[a.(PS[i].vnum).validmin,a.(PS[i].vnum).validmax], debug=debugflag)

    esize=size(e)
    ;if keyword_set(ELEMENTS) then begin
    ; RCJ 11/13/2003 Statement above was not a good way to check for elements
    ; because if elements=0 (we want the x-component) it's as if the keyword
    ; is not set and we get all 3 time_series plots: x,y and z.
    if n_elements(ELEMENTS) ne 0 then begin
      if esize[n_elements(esize)-2] eq 8 then begin
        datasize = size(ELEMENTS)
        ;rebuild e structure and set the e.elist to contain the index values for
        ;all elements in the y variable.
        elist = lonarr(datasize[1])
        elist = ELEMENTS
        e = {x:e.x,y:e.y,z:e.z,npanels:datasize[1],$
          dvary:e.dvary,elist:elist,lptrn:e.lptrn,igram:e.igram}
        esize=size(e) ; since I rebuild e, then need to determine the size again.
      endif else begin
        ; RCJ 11/13/2003 Elements is set but display_type is empty
        elist = ELEMENTS
        e = {elist:elist}
        esize=size(e) ; recalculate esize
      endelse
    endif else begin
      if (esize[n_elements(esize)-2] eq 8) then begin ; results confirmed
        if (e.npanels eq 0) then begin
          ;rebuild e structure and set the e.elist to contain the index values for
          ;all elements in the y variable.
          elist = lindgen(datasize[1]) ;TJK changed this from a for loop
          e = {x:e.x,y:e.y,z:e.z,npanels:datasize[1],$
            dvary:e.dvary,elist:elist,lptrn:e.lptrn,igram:e.igram}
          esize=size(e) ; since I rebuild e, then need to determine the size again.
        endif
      endif else begin ;no arguments to time_series display_type
        ;build an e structure and set the e.elist to contain the index values for
        ;all elements in the y variable.
        elist = lindgen(datasize[1]) ;TJK changed this from a for loop
        e = {elist:elist}
        esize=size(e) ; since I rebuild e, then need to determine the size again.
      endelse
    endelse ;else looking for the element information through the display_type
    ;attribute vs. the direct IDL use of the ELEMENTS keyword

  endif else begin ;else if no display_type exists
    ;build an e structure and set the e.elist to contain the index values for
    ;all elements in the y variable.
    if n_elements(elements) ne 0 then begin
      elist=elements
    endif else begin
      elist = lindgen(datasize[1]) ;TJK changed this from a for loop
    endelse
    e = {elist:elist}
    esize=size(e) ; since I build e, then need to determine the size again.
  endelse

  ;****** end of added section for picking out single array elements to
  ;be plotted.
  ;q12snum is where(PS(current_snum).ptype eq 12). if there are extra x-axis labels do not print
  ; subtitle after the last graph:
  if keyword_set(combine) then begin
    if (q12[0] ne -1) then nosubtitle=1 else nosubtitle=0
  endif else begin
    if (q12snum[0] ne -1) then nosubtitle=1 else nosubtitle=0
  endelse
  if ps[i].vname eq 'CDAWeb_created_variable' then onlylabel=1
  ;
  if (plotmerge eq 0) then begin
    ;Find out if we are supposed to use error bars:
    tags=tag_names(a.(PS[i].vnum))
    err_p=spd_cdawlib_tagindex('DELTA_PLUS_VAR',tags)
    err_m=spd_cdawlib_tagindex('DELTA_MINUS_VAR',tags)
    if ((err_p[0] ne -1) and (err_m[0] ne -1)) then begin
      ; get the names
      err_p=a.(PS[i].vnum).(err_p[0])
      err_m=a.(PS[i].vnum).(err_m[0])
      ; RCJ 02/07/2005 Added the test below.
      if ((err_p[0] ne '') and (err_m[0] ne '')) then begin
        ; where in a are those variables?
        ; RCJ 04/22/2003  'vnames' was here instead of 'tag_names(a)'
        ; but vnames will be the tag names of the *last* structure a
        ; read during another loop above.
        err_p1=spd_cdawlib_tagindex(replace_bad_chars(err_p[0]),tag_names(a))
        err_m1=spd_cdawlib_tagindex(replace_bad_chars(err_m[0]),tag_names(a))
        if a.(err_p1).var_type eq 'additional_data' then $
          err_p=-1 else $
          err_p=spd_cdawlib_tagindex(replace_bad_chars(err_p[0]),tag_names(a))
        if a.(err_m1).var_type eq 'additional_data' then $
          err_m=-1 else $
          err_m=spd_cdawlib_tagindex(replace_bad_chars(err_m[0]),tag_names(a))
      endif else begin ; RCJ 02/08/2005 Added this so the test below will work.
        err_m=-1 & err_p=-1
      endelse
    endif
  endif
  ;

  ;TJK 7/20/2006 if data is epoch16, then set the start/stop_time
  ;variables to the ep16 values
  ;determine datatype and process if needed

  if (strpos(a.(c[0]).CDFTYPE, 'CDF_EPOCH16') ge 0) then begin
    ;The following if statements are needed in the case where TSTART/TSTOP is not
    ;used but the data is in epoch16
    if (n_elements(start_time16) eq 0) then begin ;convert the regular epoch to epoch16
      cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_epoch16, start_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
    endif
    if (n_elements(stop_time16) eq 0) then begin ;convert the regular epoch to epoch16
      cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_epoch16, stop_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
    endif
    start_time = start_time16 & stop_time = stop_time16
  endif

  if (strpos(a.(c[0]).CDFTYPE, 'CDF_TIME_TT2000') ge 0) then begin
    ;The following if statements are needed in the case where TSTART/TSTOP is not
    ;used but the data is in time TT2000
    ;instead of regular Epoch or Epoch16
    if (n_elements(start_timett) eq 0) then begin ;convert the regular epoch to tt2000
      cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_tt2000, start_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
    endif
    if (n_elements(stop_timett) eq 0) then begin ;convert the regular epoch to tt2000
      cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_tt2000, stop_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
    endif
    start_time = start_timett & stop_time = stop_timett
  endif

  time_series = where(PS[*].ptype eq 1, num_timeseries)

  if (plotmerge gt 0) then begin

    group = a.(PS[time_series[0]].vnum).MISSION_GROUP[0]
    source = a.(PS[time_series[0]].vnum).SOURCE_NAME
    descriptor = a.(PS[time_series[0]].vnum).DESCRIPTOR
    type =  a.(PS[time_series[0]].vnum).DATA_TYPE

    case plotmerge of
      1: begin
        num_timeseries = 1
        ;Added if statement to check for binning titles - 03/16/2017 - CWG
        if keyword_set(TOP_TITLE) then begin
          mytitle = STRMID(source,0,STRPOS(source,'>')) + " " + STRMID(descriptor,STRPOS(descriptor,'>') +1)+" " + STRJOIN( STRSPLIT(type,'_',/EXTRACT),' ') + STRJOIN("!C" + TOP_TITLE) 
        endif else begin
          mytitle = STRMID(source,0,STRPOS(source,'>')) +" " + STRMID(descriptor,STRPOS(descriptor,'>') +1)+" " + STRJOIN( STRSPLIT(type,'_',/EXTRACT),' ')
        endelse

      end
      2: begin

        for t = 1, num_timeseries-1 do begin
          
          s=execute('a=a'+strtrim(string(PS[time_series[t]].snum),2));get the structure         
          if STRMATCH(group, '*'+a.(PS[time_series[t]].vnum).MISSION_GROUP[0]+'*', /FOLD_CASE ) eq 0 then begin
            group = group + " and " + a.(PS[time_series[t]].vnum).MISSION_GROUP[0]
          endif

        endfor


         if keyword_set(TOP_TITLE) then begin
          mytitle = group+" " +STRMID(descriptor,STRPOS(descriptor,'>')  +1)+" " + $
          STRJOIN( STRSPLIT(type,'_',/EXTRACT),' ') + STRJOIN("!C" + TOP_TITLE) 
        endif else begin
          mytitle = group+" " +STRMID(descriptor,STRPOS(descriptor,'>')  +1)+" " + $
          STRJOIN( STRSPLIT(type,'_',/EXTRACT),' ')
        endelse

      end
    endcase


    for t = 0, num_timeseries-1 do begin

      s=execute('a=a'+strtrim(string(PS[time_series[t]].snum),2));get the structure

      if (t eq 0) then begin
        origString =  (tag_names(a))[(PS[time_series[0]].vnum)]
        origSource = (STRSPLIT( a.(PS[time_series[0]].vnum).SOURCE_NAME,'>',/EXTRACT))[0]
        origsub = STRJOIN(STRSPLIT(origString, origSource,/Regex, /Extract, $
          /Preserve_Null,/fold_case))
      endif
      string =   (tag_names(a))[(PS[time_series[t]].vnum)]
      source = (STRSPLIT( a.(PS[time_series[t]].vnum).SOURCE_NAME,'>',/EXTRACT))[0]
      sub = STRJOIN(STRSPLIT(string, source,/Regex, /Extract, $
        /Preserve_Null,/fold_case))

      if (STRCMP (origsub,sub )) then begin
        Xvar = a.(PS[time_series[t]].vnum).DEPEND_0 ;Should be the epoch varname
        Xidx = strtrim(string(spd_cdawlib_tagindex(Xvar[0],tag_names(a))),2) ; x index value as a string
        Yvar = a.(PS[time_series[t]].vnum).VARNAME
        Yidx = strtrim(string(PS[time_series[t]].vnum),2) ; y index value as a string
        PS[time_series[t]].ptype = 0

        x= t eq 0 ? create_struct(Xvar + STRTRIM(t, 2),a.(Xidx)) : create_struct(x, Xvar + STRTRIM(t, 2),a.(Xidx))
        y= t eq 0 ? create_struct(Yvar + STRTRIM(t, 2),a.(Yidx)) : create_struct(y, Yvar + STRTRIM(t, 2),a.(Yidx))


        ;Find out if we are supposed to use error bars:
        tags=tag_names(a.(PS[i].vnum))
        err_p=spd_cdawlib_tagindex('DELTA_PLUS_VAR',tags)
        err_m=spd_cdawlib_tagindex('DELTA_MINUS_VAR',tags)

        if ((err_p[0] ne -1) and (err_m[0] ne -1)) then begin
          ; get the names
          err_p=a.(PS[i].vnum).(err_p[0])
          err_m=a.(PS[i].vnum).(err_m[0])
          ; RCJ 02/07/2005 Added the test below.
          if ((err_p[0] ne '') and (err_m[0] ne '')) then begin
            ; where in a are those variables?
            ; RCJ 04/22/2003  'vnames' was here instead of 'tag_names(a)'
            ; but vnames will be the tag names of the *last* structure a
            ; read during another loop above.
            err_p1=spd_cdawlib_tagindex(replace_bad_chars(err_p[0]),tag_names(a))
            err_m1=spd_cdawlib_tagindex(replace_bad_chars(err_m[0]),tag_names(a))
            if a.(err_p1).var_type eq 'additional_data' then $
              err_p=-1 else $
              err_p=spd_cdawlib_tagindex(replace_bad_chars(err_p[0]),tag_names(a))
            if a.(err_m1).var_type eq 'additional_data' then $
              err_m=-1 else $
              err_m=spd_cdawlib_tagindex(replace_bad_chars(err_m[0]),tag_names(a))


            ; read uncertainty variables
            handle_value,a.(err_p[0]).handle,err_plus
            handle_value,a.(err_m[0]).handle,err_minus


            err_plus_over= t EQ 0 ? Ptr_New(err_plus, /No_Copy) : [err_plus_over,Ptr_New(err_plus, /No_Copy)]
            err_minus_over= t EQ 0  ? Ptr_New(err_minus, /No_Copy) : [err_minus_over,Ptr_New(err_minus, /No_Copy)]
          endif else begin ; RCJ 02/08/2005 Added this so the test below will work.
            err_m=-1 & err_p=-1
          endelse
        endif
      endif
    endfor
    a_id = -1
  endif


  ; Produce the time series plot with specific time axis range

  if ((start_time ne 0.0D0)AND(stop_time ne 0.0D0)) then begin
    ; Plot with error bars:
    if ((err_p[0] ne -1) and (err_m[0] ne -1)) then begin
      if (plotmerge eq 0)then begin
          ; read uncertainty variables
          handle_value,a.(err_p[0]).handle,err_plus
          handle_value,a.(err_m[0]).handle,err_minus
      endif
      ; RCJ 02/27/2007  Note: we don't need to pass a keyword 'ps' to
      ; plot_timeseries because it only needs to know if the plot is a
      ; gif or otherwise if a new window/page is to be open.
      ; Since we offer only one page of ps for the moment we don't
      ; have to worry about this.
      ;

      s = plotmerge gt 0 ? $
        plot_over(x,y,POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        TSTART=start_time,TSTOP=stop_time,COMBINE=COMBINE,$
        err_plus=err_plus_over,err_minus=err_minus_over,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
        NONOISE=NONOISE,SCATTER=SCATTER, $
        NOERRORBARS=NOERRORBARS, $
        gif=gif,DEBUG=debugflag,PLOTMERGE=PLOTMERGE)$
        :  plot_timeseries(a.(c[0]),a.(PS[i].vnum),POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        TSTART=start_time,TSTOP=stop_time,COMBINE=COMBINE,$
        err_plus=err_plus,err_minus=err_minus,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
        NONOISE=NONOISE,SCATTER=SCATTER, $
        NOERRORBARS=NOERRORBARS, $
        ;gif=gif,ps=out_ps,DEBUG=debugflag)
        gif=gif,DEBUG=debugflag)
    endif else begin
      ; Plot without error bars:
      s = plotmerge gt 0 ? $
        plot_over(x,y,POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        TSTART=start_time,TSTOP=stop_time,COMBINE=COMBINE,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
        NONOISE=NONOISE,SCATTER=SCATTER,$
        NOERRORBARS=NOERRORBARS, $
        gif=gif,DEBUG=debugflag,PLOTMERGE=PLOTMERGE):$
        plot_timeseries(a.(c[0]),a.(PS[i].vnum),POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        TSTART=start_time,TSTOP=stop_time,COMBINE=COMBINE,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
        NONOISE=NONOISE,SCATTER=SCATTER,$
        NOERRORBARS=NOERRORBARS, $
        ;gif=gif,ps=out_ps,DEBUG=debugflag)
        gif=gif,DEBUG=debugflag)

    endelse
    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Time-series plot failed' & close, 1
      print, 'STATUS=Time-series plot failed'
      ;return, -1
    endif
  endif else begin ; Produce the time series plot normally
    ; Plot with error bars:
    if ((err_p[0] ne -1) and (err_m[0] ne -1)) then begin
      if (plotmerge eq 0)then begin     
          ; read uncertainty variables
          handle_value,a.(err_p[0]).handle,err_plus
          handle_value,a.(err_m[0]).handle,err_minus
      endif
      s = plotmerge gt 0 ? $
        plot_over(x,y,POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,COMBINE=COMBINE,$
        err_plus=err_plus_over,err_minus=err_minus_over,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        NONOISE=NONOISE,SCATTER=SCATTER,$
        gif=gif,DEBUG=debugflag, PLOTMERGE = PLOTMERGE) :$
        plot_timeseries(a.(c[0]),a.(PS[i].vnum),POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,COMBINE=COMBINE,$
        err_plus=err_plus,err_minus=err_minus,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        NONOISE=NONOISE,SCATTER=SCATTER,$
        ;gif=gif,ps=out_ps,DEBUG=debugflag)
        gif=gif,DEBUG=debugflag)
    endif else begin
      ; Plot without error bars:
      s = plotmerge gt 0 ? $
        plot_over(x,y,POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,COMBINE=COMBINE,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        NONOISE=NONOISE,SCATTER=SCATTER,$
        ;gif=gif,ps=out_ps,DEBUG=debugflag)
        gif=gif,DEBUG=debugflag, PLOTMERGE = PLOTMERGE):$
        plot_timeseries(a.(c[0]),a.(PS[i].vnum),POSITION=WS.pos,/CDAWEB,$
        PANEL_HEIGHT=pheight,AUTO=autoscale, ELEMENTS=e.elist,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,COMBINE=COMBINE,$
        NOSUBTITLE=nosubtitle, ONLYLABEL=onlylabel,$
        NONOISE=NONOISE,SCATTER=SCATTER,$
        ;gif=gif,ps=out_ps,DEBUG=debugflag)
        gif=gif,DEBUG=debugflag)
    endelse

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Time-series plot failed' & close, 1
      print, 'STATUS=Time-series plot failed'
      return, -1
    endif
  endelse
  onlylabel=0
  ; Update the state of the window
  WS.pos[3] = WS.pos[3] - (pheight * PS[i].npanels) ; update Y corner
  WS.pos[1] = WS.pos[1] - (pheight * PS[i].npanels) ; update Y origin
  ;check if "noauto" was set and turn it back on for subsequent variables/datasets
  if (n_elements(save_auto) gt 0) then begin
    if (save_auto) then autoscale = 1L else autoscale = 0L
  endif

endif   ; end if ps[i].ptype eq 1

; Generate SPECTROGRAM plots
if (PS[i].ptype eq 2) then begin
  ; Ensure that 'a' holds the correct data structure
  if (PS[i].snum ne a_id) then begin
    s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
  endif
  ; Determine default x and y variable from depend attributes
  b = a.(PS[i].vnum).DEPEND_0 & c = spd_cdawlib_tagindex(b[0],tag_names(a))
  b = a.(PS[i].vnum).DEPEND_1
  ; RCJ 05/16/2013 If alt_cdaweb_depend_1 exists use it instead:
  if (spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_1',tag_names(a.(PS[i].vnum)))) ne -1 then $
    if (a.(PS[i].vnum).ALT_CDAWEB_DEPEND_1 ne '') then b = a.(PS[i].vnum).ALT_CDAWEB_DEPEND_1
  d = spd_cdawlib_tagindex(b[0],tag_names(a))

  ; Determine if the display type variable attribute is present
  b = spd_cdawlib_tagindex('DISPLAY_TYPE',tag_names(a.(PS[i].vnum)))
  if (b[0] ne -1) then begin
    ; examine_spectrogram_dt looks at the DISPLAY_TYPE structure member in detail.
    ; for spectrograms and stacked time series the DISPLAY_TYPE can contain syntax
    ; like the following: SPECTROGRAM>y=flux[1],y=flux[3],y=flux[5],z=energy
    ; where this indicates that we only want to plot the 1st, 3rd and 5th energy
    ; channel for the flux variable. This routine returns a structure of the form
    ;	e = {x:xname,y:yname,z:zname,npanels:npanels,dvary:dvary,elist:elist,
    ;	lptrn:lptrn,igram:igram},

    ;TJK 2/4/2004, save the autoscaling setup that was passed in by the calling program
    ;so that it can be restored at the bottom of the spectrogram plot type code.
    if (autoscale) then save_auto = 1L else save_auto = 0L

    ;TJK 2/12/2003 add the capability to look for the 'noauto' keyword
    keywords=str_sep(a.(PS[i].vnum).display_type,'>')  ; keyword 1 or greater

    acn=where(strupcase(keywords) eq 'NOAUTO',an)
    ;turn autoscaling off if "noauto" is set
    if (an gt 0) then autoscale = 0L else autoscale = 1L

    ; RCJ 03/15/2013 Added this code to get thedata and dfillval:
    Yvar = (a.(PS[i].vnum))
    t = size(Yvar)
    if (t[n_elements(t)-2] ne 8) then begin
      print,'ERROR=input to plotmaster not a structure' & return,-1
    endif else begin
      YTAGS = tag_names(Yvar) ; avoid multiple calls to tag_names
      t = spd_cdawlib_tagindex('DAT',YTAGS)
      if (t[0] ne -1) then begin
        THEDATA = Yvar.DAT
        dfillval=yvar.fillval
      endif else begin
        t = spd_cdawlib_tagindex('HANDLE',YTAGS)
        if (t[0] ne -1) then begin
          handle_value,Yvar.HANDLE,THEDATA
          dfillval=yvar.fillval
        endif else begin
          print,'ERROR=Yvariable does not have DAT or HANDLE tag' & return,-1
        endelse
      endelse
    endelse
    e = examine_spectrogram_dt(a.(PS[i].vnum).DISPLAY_TYPE, thedata=thedata, data_fillval=dfillval,$
      valid_minmax=[a.(PS[i].vnum).VALIDMIN,a.(PS[i].vnum).VALIDMAX], debug=debugflag)

    esize=size(e)
    if (esize[n_elements(esize)-2] eq 8) then begin ; results confirmed
      if (e.x ne '') then c = spd_cdawlib_tagindex(e.x,tag_names(a))
      if (e.y ne '') then d = spd_cdawlib_tagindex(e.y,tag_names(a))
    endif
  endif
  ; Produce debug output if requested.
  if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as spectrogram.'
  ; Generate the spectrogram
  ;if NOT keyword_set(GIF) then deviceopen,0 ; producing XWINDOWS
  if (plottype ne 'gif' and plottype ne 'pscript') then deviceopen,0; producing XWINDOWS

  ;q12snum is where(PS(current_snum).ptype eq 12)  if there are extra x-axis labels do not print
  ; subtitle after the last graph:
  if keyword_set(combine) then begin
    if (q12[0] ne -1) then nosubtitle=1 else nosubtitle=0
  endif else begin
    if (q12snum[0] ne -1) then nosubtitle=1 else nosubtitle=0
  endelse
  ;
  if (strpos(a.(c[0]).CDFTYPE, 'CDF_EPOCH16') ge 0) then begin
    ;The following if statements are needed in the case where TSTART/TSTOP is not
    ;used but the data is in epoch16
    if (n_elements(start_time16) eq 0) then begin ;convert the regular epoch to epoch16
      cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_epoch16, start_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
    endif
    if (n_elements(stop_time16) eq 0) then begin ;convert the regular epoch to epoch16
      cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_epoch16, stop_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
    endif
    start_time = start_time16 & stop_time = stop_time16
  endif
  ;
  if (strpos(a.(c[0]).CDFTYPE, 'CDF_TIME_TT2000') ge 0) then begin
    ;The following if statements are needed in the case where TSTART/TSTOP is not
    ;used but the data is in time TT2000
    ;instead of regular Epoch or Epoch16
    if (n_elements(start_timett) eq 0) then begin ;convert the regular epoch to tt2000
      cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_tt2000, start_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
    endif
    if (n_elements(stop_timett) eq 0) then begin ;convert the regular epoch to tt2000
      cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_tt2000, stop_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
    endif
    start_time = start_timett & stop_time = stop_timett
  endif

  print, 'DEBUG in spectrogram section i = ',i, 'start_time = ',start_time

  s = plot_spectrogram(a.(c[0]),a.(d[0]),a.(PS[i].vnum),$
    POSITION=WS.pos,/CDAWEB,QUICK=quickflag,$
    PANEL_HEIGHT=pheight,AUTO=autoscale,NOCLIP=noclipflag,$
    TSTART=start_time,TSTOP=stop_time,FILLER=fillflag,$
    FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
    NOSUBTITLE=nosubtitle, COMBINE=COMBINE,npanels=PS[i].npanels,$
    SLOW=slowflag,DEBUG=debugflag)
  ;SLOW=slowflag,SMOOTH=smoothflag,DEBUG=debugflag)
  if(s eq -1) then begin
    if(reportflag) then printf, 1, 'STATUS=Spectrogram plot failed' & close, 1
    print, 'STATUS=Spectrogram plot failed'
    return, -1
  endif
  ; Update the state of the window
  WS.pos[3] = WS.pos[3] - (pheight * PS[i].npanels) ; update Y corner
  WS.pos[1] = WS.pos[1] - (pheight * PS[i].npanels) ; update Y origin
  ;check if "noauto" was set and turn it back on for subsequent variables/datasets
  if (n_elements(save_auto) gt 0) then begin
    if (save_auto) then autoscale = 1L else autoscale = 0L
  endif

endif

; Make a pass thru the plot script and generate all stacked time series plots
; Generate STACKED TIME SERIES plot
if (PS[i].ptype eq 7) then begin
  ; Ensure that 'a' holds the correct data structure
  scatter = 0L
  reverse_order = 0L
  if (PS[i].snum ne a_id) then begin
    s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
  endif
  ; Get the index of the time variable associated with variable to be plotted
  ; Determine default x, y and z variables from depend attributes
  b = a.(PS[i].vnum).DEPEND_0 & c = spd_cdawlib_tagindex(b[0],tag_names(a))
  b = a.(PS[i].vnum).DEPEND_1
  ; RCJ 05/16/2013 If alt_cdaweb_depend_1 exists use it instead:
  if (spd_cdawlib_tagindex('ALT_CDAWEB_DEPEND_1',tag_names(a.(PS[i].vnum)))) ne -1 then $
    if (a.(PS[i].vnum).ALT_CDAWEB_DEPEND_1 ne '') then b = a.(PS[i].vnum).ALT_CDAWEB_DEPEND_1
  z = spd_cdawlib_tagindex(b[0],tag_names(a))

  ; Determine if the display type variable attribute is present
  b = spd_cdawlib_tagindex('DISPLAY_TYPE',tag_names(a.(PS[i].vnum)))
  if (b[0] ne -1) then begin
    ;  RCJ 10/15/2013  added scatter:
    keywords=str_sep(a.(PS[i].vnum).display_type,'>')  ; keyword 1 or greater
    scn=where(strupcase(keywords) eq 'SCATTER',sn)
    ;turn scatter plot on if "scatter" is set
    if (sn gt 0) then SCATTER = 1L else SCATTER = 0L

    ; TJK 12/31/2013 added reverse:
    keywords=str_sep(a.(PS[i].vnum).display_type,'>')  ; keyword 1 or greater
    scn=where(strupcase(keywords) eq 'REVERSE',sn)
    ;turn scatter plot on if "scatter" is set
    if (sn gt 0) then REVERSE_ORDER = 1L else REVERSE_ORDER = 0L

    ; TJK 4/16/2014 added nobar (no colorbar, numeric labels instead):
    keywords=str_sep(a.(PS[i].vnum).display_type,'>')  ; keyword 1 or greater
    scn=where(strupcase(keywords) eq 'NOBAR',sn)
    ;turn colorbar off if "nobar" is set (turns numeric labels on)
    if (sn gt 0) then COLORBAR = 0L else COLORBAR = 1L

    ; examine_spectrogram_dt looks at the DISPLAY_TYPE structure member in
    ; detail. for spectrograms and stacked time series the DISPLAY_TYPE
    ; can contain syntax like the following: stack_plot>y=flux[1],y=flux[3],
    ; y=flux[5],z=energy where this indicates that we only want to plot
    ; the 1st, 3rd and 5th energy channel for the flux variable. This
    ; routine returns a structure of the form e = {x:xname,y:yname,z:zname,
    ; npanels:npanels,dvary:dvary,elist:elist,lptrn:lptrn,igram:igram},

    e = examine_spectrogram_dt(a.(PS[i].vnum).DISPLAY_TYPE, thedata=thedata, $
      data_fillval=a.(PS[i].vnum).fillval, $
      valid_minmax=[a.(PS[i].vnum).validmin,a.(PS[i].vnum).validmax], debug=debugflag)

    esize=size(e)

    ; determine how many dimensions are in the data by looking at
    ; the data - unfortunately I have to get it out of either the plain
    ; structure or a handle.

    Yvar = (a.(PS[i].vnum))
    t = size(Yvar)
    if (t[n_elements(t)-2] ne 8) then begin
      print,'ERROR=input to spd_cdawlib_plotmaster not a structure' & return,-1
    endif else begin
      YTAGS = tag_names(Yvar) ; avoid multiple calls to tag_names
      t = spd_cdawlib_tagindex('DAT',YTAGS)
      if (t[0] ne -1) then THEDATA = Yvar.DAT $
      else begin
        t = spd_cdawlib_tagindex('HANDLE',YTAGS)
        if (t[0] ne -1) then handle_value,Yvar.HANDLE,THEDATA $
        else begin
          print,'ERROR=Yvariable does not have DAT or HANDLE tag' & return,-1
        endelse
      endelse
    endelse
    datasize = size(thedata)

    ;TJK shouldn't need here as well as above
    ;if keyword_set(PANEL_HEIGHT) then pheight=PANEL_HEIGHT else pheight=100

    if keyword_set(ELEMENTS) then begin
      ; RCJ 11/13/2003 Unlike for time_series plots, the options here are not to have
      ; the element keyword set or to have it set to an array ([0,1] for instance)
      ; so we don't run into the same problem as w/ time_series where elements could
      ; be =0 and the keyword wouldn't be set.
      datasize = size(ELEMENTS)
      ;rebuild e structure and set the e.elist to contain the index values for
      ;all elements in the y variable.
      elist = lonarr(datasize[1])
      elist = ELEMENTS
      e = {x:e.x,y:e.y,z:e.z,npanels:datasize[1],$
        dvary:e.dvary,elist:elist,lptrn:e.lptrn,igram:e.igram}
      esize=size(e) ; since I rebuild e, then need to determine the size again.

      ;TJK rearranged the logic below to check for whether e is even a structure before
      ;trying to use it, this is an issue if the following is specified "DISPLAY_TYPE=stack_plot"
      ;w/ no "y=var(i), etc. syntax. - 2/14/2002
    endif else begin

      if (n_tags(e) gt 0) then begin ; e is a structure
        if (e.npanels eq 0) then begin
          ;rebuild e structure and set the e.elist to contain the index values for
          ;all elements in the y variable.
          elist = lonarr(datasize[1])
          for j = 0, datasize[1]-1 do elist[j] = j
          ;TJK	pheight = pheight*(n_elements(elist))
          e = {x:e.x,y:e.y,z:e.z,npanels:datasize[1],$
            dvary:e.dvary,elist:elist,lptrn:e.lptrn,igram:e.igram}
          esize=size(e) ; since I rebuild e, then need to determine the size again.
          print, 'Setting elements to ',e.elist
        endif
      endif else begin ; e isn't a structure yet because no elements were specified.
        ; want to to set elist to all index values - just like above.
        elist = lonarr(datasize[1])
        for j = 0, datasize[1]-1 do elist[j] = j
        ;need initialize the structure members
        xname='' & yname='' & zname='' & lptrn=1 & igram=0
        npanels=0 & dvary=-1
        e = {x:xname,y:yname,z:zname,npanels:datasize[1],$
          dvary:dvary,elist:elist,lptrn:lptrn,igram:igram}
        esize=size(e) ; since I rebuild e, then need to determine the size again.
      endelse
    endelse

    if (esize[n_elements(esize)-2] eq 8) then begin ; results confirmed
      if (e.x ne '') then c = spd_cdawlib_tagindex(e.x,tag_names(a))
      if (e.y ne '') then d = spd_cdawlib_tagindex(e.y,tag_names(a))
      if (e.z ne '') then f = spd_cdawlib_tagindex(e.z,tag_names(a)) $
      else f = z
    endif

    ;if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    ;print, 'DATASET=',PS[i].source

    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as stacked time series.'

    ; Generate the stack plot
    if (plottype ne 'gif' and plottype ne 'pscript') then deviceopen,0; producing XWINDOWS

    ;q12snum is where(PS(current_snum).ptype eq 12) ; if there are extra x-axis labels do not print
    ; subtitle after the last graph:
    if keyword_set(combine) then begin
      if (q12[0] ne -1) then nosubtitle=1 else nosubtitle=0
    endif else begin
      if (q12snum[0] ne -1) then nosubtitle=1 else nosubtitle=0
    endelse

    ;TJK 4/26/2013 added the code to accept epoch16 and tt2000 time types
    ;TJK 7/20/2006 if data is epoch16, then set the start/stop_time
    ;variables to the ep16 values
    ;determine datatype and process if needed

    if (strpos(a.(c[0]).CDFTYPE, 'CDF_EPOCH16') ge 0) then begin
      ;The following if statements are needed in the case where TSTART/TSTOP is not
      ;used but the data is in epoch16
      if (n_elements(start_time16) eq 0) then begin ;convert the regular epoch to epoch16
        cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_epoch16, start_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
      endif
      if (n_elements(stop_time16) eq 0) then begin ;convert the regular epoch to epoch16
        cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_epoch16, stop_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
      endif
      start_time = start_time16 & stop_time = stop_time16
    endif

    if (strpos(a.(c[0]).CDFTYPE, 'CDF_TIME_TT2000') ge 0) then begin
      ;The following if statements are needed in the case where TSTART/TSTOP is not
      ;used but the data is in time TT2000
      ;instead of regular Epoch or Epoch16
      if (n_elements(start_timett) eq 0) then begin ;convert the regular epoch to tt2000
        cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_tt2000, start_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
      endif
      if (n_elements(stop_timett) eq 0) then begin ;convert the regular epoch to tt2000
        cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_tt2000, stop_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
      endif
      start_time = start_timett & stop_time = stop_timett
    endif


    ; Produce the stacked time series plot with specific time axis range
    if ((start_time ne 0.0D0)AND(stop_time ne 0.0D0)) then begin
      s = plot_stack(a.(c[0]),a.(PS[i].vnum),a.(f[0]),/CDAWEB,$
        ELEMENTS = e.elist, $ ;XSIZE = 400,$
        ;YSIZE = 700, $
        PANEL_HEIGHT=pheight,COMBINE=COMBINE,$
        POSITION=WS.pos, NOSUBTITLE=nosubtitle,$
        AUTO=autoscale,GIF=GIF,$
        TSTART=start_time,TSTOP=stop_time,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
        SCATTER=SCATTER, REVERSE_ORDER=REVERSE_ORDER,$
        NONOISE=NONOISE,DEBUG=debugflag, COLORBAR=colorbar);,$/NOGAPS)

      if(s eq -1) then begin
        if(reportflag) then printf, 1, 'STATUS=Stack plot failed' & close, 1
        print, 'STATUS=Stack plot failed'
        ;return, -1 RTB; Allows remaining structures to plot
      endif else begin
        if(s eq -2) then begin ;all fill data found - status being printed from plot_stack
          ; return, -1  RTB; Allows remaining structures to plot
        endif
      endelse
    endif else begin ; Produce the stack plot normally
      s = plot_stack(a.(c[0]),a.(PS[i].vnum),a.(f[0]),/CDAWEB,$
        ELEMENTS = e.elist, $ ;XSIZE = 400,$
        ;YSIZE = 700, $
        POSITION=WS.pos, NOSUBTITLE=nosubtitle,$
        PANEL_HEIGHT=pheight,COMBINE=COMBINE,$
        AUTO=autoscale, GIF=GIF,$
        FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
        SCATTER=SCATTER, REVERSE_ORDER=REVERSE_ORDER,$
        NONOISE=NONOISE,DEBUG=debugflag, COLORBAR=colorbar);,$/NOGAPS)
      if(s eq -1) then begin
        if(reportflag) then printf, 1, 'STATUS=Stack plot failed' & close, 1
        print, 'STATUS=Stack plot failed'
        deviceclose ; close any open gif
        ;return, -1 RTB; Allows remaining structures to plot
      endif else begin
        if(s eq -2) then begin ;all fill data found - status being printed from plot_stack
          deviceclose ; close any open gif
          ;return, -1 RTB; Allows remaining structures to plot
        endif
      endelse

      ; if keyword_set(GIF) then begin
      ;if (reportflag) then printf, 1, 'GIF=',GIF else print,'GIF=',GIF
      ;endif

    endelse ; end stacked time series plot w/o start and stop time specs.
  endif ;   if (b[0] ne -1)
  ; Update the state of the window
  WS.pos[3] = WS.pos[3] - (pheight * PS[i].npanels) ; update Y corner
  WS.pos[1] = WS.pos[1] - (pheight * PS[i].npanels) ; update Y origin

endif ; if plottype eq stacked time series
;  Generate PLOT_TIMETEXT plot
;
if (PS[i].ptype eq 12) then begin
  ;if ((PS[i].ptype eq 12) and (plottype ne 'pscript')) then begin
  ; the following was copied/pasted from the time series section above
  ; and modified
  ;
  ; Ensure that 'a' holds the correct data structure
  if (PS[i].snum ne a_id) then begin
    s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
  endif
  ; Get the index of the time variable associated with variable to be plotted
  b = a.(PS[i].vnum).DEPEND_0 & c = spd_cdawlib_tagindex(b[0],tag_names(a))
  ; Produce debug output if requested
  if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as time text.'
  ;
  ; TJK added code for handling the parsing of the DISPLAY_TYPE attribute
  ; for time series plots.  In this plot types case, we are looking for a
  ; a syntax like time_series>y=flux[1] (July 30, 1999).
  ; determine how many dimensions are in the data by looking at
  ; the data - unfortunately I have to get it out of either the plain
  ; structure or a handle.

  Yvar = (a.(PS[i].vnum))
  t = size(Yvar)
  if (t[n_elements(t)-2] ne 8) then begin
    print,'ERROR=input to spd_cdawlib_plotmaster not a structure' & return,-1
  endif else begin
    YTAGS = tag_names(Yvar) ; avoid multiple calls to tag_names
    t = spd_cdawlib_tagindex('DAT',YTAGS)
    if (t[0] ne -1) then THEDATA = Yvar.DAT $
    else begin
      t = spd_cdawlib_tagindex('HANDLE',YTAGS)
      if (t[0] ne -1) then handle_value,Yvar.HANDLE,THEDATA $
      else begin
        print,'ERROR=Yvariable does not have DAT or HANDLE tag' & return,-1
      endelse
    endelse
  endelse
  datasize = size(thedata)
  ; Determine if the display type variable attribute is present
  d = spd_cdawlib_tagindex('DISPLAY_TYPE',tag_names(a.(PS[i].vnum)))
  if (d[0] ne -1) then begin
    ; examine_spectrogram_dt looks at the DISPLAY_TYPE structure member in
    ; detail. for time series, time text, spectrograms and
    ; stacked time series the DISPLAY_TYPE
    ; can contain syntax like the following: stack_plot>y=flux[1],y=flux[3],
    ; y=flux[5],z=energy where this indicates that we only want to plot
    ; the 1st, 3rd and 5th energy channel for the flux variable. This
    ; routine returns a structure of the form e = {x:xname,y:yname,z:zname,
    ; npanels:npanels,dvary:dvary,elist:elist,lptrn:lptrn,igram:igram},
    e = examine_spectrogram_dt(a.(PS[i].vnum).DISPLAY_TYPE, thedata=thedata,$
      data_fillval=a.(PS[i].vnum).fillval, $
      valid_minmax=[a.(PS[i].vnum).validmin,a.(PS[i].vnum).validmax], debug=debugflag)
    esize=size(e)

    ;if keyword_set(ELEMENTS) then begin
    ; RCJ 11/13/2003 As for time_series plots, statement above was not a good way to check for elements
    ; because if elements=0 (we want the x-component) it's as if the keyword
    ; is not set and we get all 3 time_series plots: x,y and z.
    if n_elements(ELEMENTS) ne 0 then begin
      datasize = size(ELEMENTS)
      ;rebuild e structure and set the e.elist to contain the index values for
      ;all elements in the y variable.
      elist = lonarr(datasize[1])
      elist = ELEMENTS
      e = {x:e.x,y:e.y,z:e.z,npanels:datasize[1],$
        dvary:e.dvary,elist:elist,lptrn:e.lptrn,igram:e.igram}
      esize=size(e) ; since I rebuild e, then need to determine the size again.
    endif else begin
      if (esize[n_elements(esize)-2] eq 8) then begin ; results confirmed
        if (e.npanels eq 0) then begin
          ;rebuild e structure and set the e.elist to contain the index values for
          ;all elements in the y variable.
          elist = lindgen(datasize[1]) ;TJK changed this from a for loop
          e = {x:e.x,y:e.y,z:e.z,npanels:datasize[1],$
            dvary:e.dvary,elist:elist,lptrn:e.lptrn,igram:e.igram}
          esize=size(e) ; since I rebuild e, then need to determine the size again.
        endif
      endif else begin ;no arguments to time_text display_type
        ;build an e structure and set the e.elist to contain the index values for
        ;all elements in the y variable.
        elist = lindgen(datasize[1]) ;TJK changed this from a for loop
        e = {elist:elist}
        esize=size(e) ; since I rebuild e, then need to determine the size again.
      endelse
    endelse ;else looking for the element information through the display_type
    ;attribute vs. the direct IDL use of the ELEMENTS keyword

  endif else begin ;else if no display_type exists
    ;build an e structure and set the e.elist to contain the index values for
    ;all elements in the y variable.
    elist = lindgen(datasize[1]) ;TJK changed this from a for loop
    e = {elist:elist}
    esize=size(e) ; since I build e, then need to determine the size again.
  endelse
  if keyword_set(combine) then begin
    if (last_plot eq 1) then nosubtitle=0 else nosubtitle=1
  endif else begin
    if ps[i].ptype ne ps[i+1].ptype then nosubtitle=0 else nosubtitle=1
  endelse
  ;
  if (strpos(a.(c[0]).CDFTYPE, 'CDF_EPOCH16') ge 0) then begin
    ;The following if statements are needed in the case where TSTART/TSTOP is not
    ;used but the data is in epoch16
    if (n_elements(start_time16) eq 0) then begin ;convert the regular epoch to epoch16
      cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_epoch16, start_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
    endif
    if (n_elements(stop_time16) eq 0) then begin ;convert the regular epoch to epoch16
      cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_epoch16, stop_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
    endif
    start_time = start_time16 & stop_time = stop_time16
  endif
  ;
  if (strpos(a.(c[0]).CDFTYPE, 'CDF_TIME_TT2000') ge 0) then begin
    ;The following if statements are needed in the case where TSTART/TSTOP is not
    ;used but the data is in time TT2000
    ;instead of regular Epoch or Epoch16
    if (n_elements(start_timett) eq 0) then begin ;convert the regular epoch to tt2000
      cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_tt2000, start_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
    endif
    if (n_elements(stop_timett) eq 0) then begin ;convert the regular epoch to tt2000
      cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
      cdf_tt2000, stop_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
    endif
    start_time = start_timett & stop_time = stop_timett
  endif

  ; Produce the time text with specific time axis range

  if ((start_time ne 0.0D0)AND(stop_time ne 0.0D0)) then begin
    ; warning: Plot_timetext assumes there's no need to open a new window.
    qv=where(ps.vname eq 'CDAWeb_created_variable')
    if (qv[0] ne -1) then onlylabel=1
    s = plot_timetext(a.(c[0]),a.(PS[i].vnum),notime=1, $
      PANEL_HEIGHT=pheight_12,AUTO=autoscale, ELEMENTS=e.elist,$
      plabeloffset=labeloffset, nosubtitle=nosubtitle, $
      TSTART=start_time,TSTOP=stop_time, GIF=GIF,$
      FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
      DEBUG=debugflag, onlylabel=onlylabel, COMBINE=COMBINE)
    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Time-text plot failed' & close, 1
      ;TJK 5/167/2013 don't need to error out
      ;print, 'STATUS=Time-text plot failed'
      ;return, -1
    endif
  endif else begin ; Produce the time text plot normally
    s = plot_timetext(a.(c[0]),a.(PS[i].vnum),notime=1, $
      PANEL_HEIGHT=pheight_12,AUTO=autoscale, ELEMENTS=e.elist,$
      plabeloffset=labeloffset, nosubtitle=nosubtitle, $
      GIF=GIF, COMBINE=COMBINE,$
      FIRSTPLOT=first_plot,LASTPLOT=last_plot,$
      DEBUG=debugflag, onlylabel=onlylabel)
    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Time-text plot failed' & close, 1
      print, 'STATUS=Time-text plot failed'
      return, -1
    endif
  endelse
  onlylabel=0
  if plottype eq 'pscript' then begin
    labeloffset=labeloffset-(ps[i].npanels * 400) ; yup, empirical
  endif else begin
    labeloffset=labeloffset-(ps[i].npanels * 10) ; this is in number of pixels
  endelse
  ; Update the state of the window
  WS.pos[3] = WS.pos[3] - (pheight_12 * PS[i].npanels) ; update Y corner
  WS.pos[1] = WS.pos[1] - (pheight_12 * PS[i].npanels) ; update Y origin
endif ; if plottype eq time_text

if keyword_set(COMBINE) then begin
  mytitle=combined_title

  ;now determine the pi and affiliation for this dataset
  ;only add a pi/affiliation to the pi_list if its a new one
  t_source = ''
  b = spd_cdawlib_tagindex('LOGICAL_SOURCE',tag_names(a.(0)))
  if (b[0] ne -1) then begin
    if(n_elements(a.(0).LOGICAL_SOURCE) eq 1) then t_source = a.(0).LOGICAL_SOURCE
  endif

  if (t_source ne l_source) then begin  ; if logical source changed
    l_source = t_source ;set this for the next iteration
    b = spd_cdawlib_tagindex('PI_NAME',tag_names(a.(0)))
    if (b[0] ne -1) then begin
      ;if(n_elements(a.(0).PI_NAME) eq 1) then pi = a.(0).PI_NAME else pi=' '
      ; RCJ 01/05/2004 Sometimes the pi_name can be an array of n elements so I changed
      ; the line above to:
      if(n_elements(a.(0).PI_NAME) ge 1) then pi = a.(0).PI_NAME[0]
      ; RCJ 01/05/2004  The line below can handle n-element arrays
      ; but the subtitle could get pretty long if there are more pi's and affiliations
      ; from other instruments (additional datasets).
      ;for pii=1,n_elements(a.(0).PI_NAME)-1 do pi = pi +' '+ a.(0).PI_NAME(pii)
    endif else pi='' ; RCJ 02/10/2006  Added this 'else'. pi needed to be
    ; initialized or program would break further down.
    b = spd_cdawlib_tagindex('PI_AFFILIATION',tag_names(a.(0)))
    if (b[0] ne -1) then begin
      ;if((n_elements(a.(0).PI_AFFILIATION) eq 1) and (a.(0).PI_AFFILIATION[0] ne "")) then $
      ; RCJ 01/05/2004  Same as above, pi_affiliation can be an array of n elements
      if((n_elements(a.(0).PI_AFFILIATION) ge 1) and $
        (a.(0).PI_AFFILIATION[0] ne "")) then begin
        affil=a.(0).PI_AFFILIATION[0]
        ; RCJ 01/05/2004 Same case here as above, this line can handle n-element arrays
        ; but the subtitle could get pretty long if there are more pi's and affiliations
        ; from other instruments (additional datasets).
        ;for pii=1,n_elements(a.(0).PI_AFFILIATION)-1 do affil = affil +', '+ a.(0).PI_AFFILIATION(pii)
        ;pi = pi + ' at '+ a.(0).PI_AFFILIATION
        pi = pi + ' at '+ affil
      endif
      if (i lt n_elements(PS)-1) then pi = pi + ' and '
    endif
  endif else pi = ''  ; endif logical source changed
endif

if (n_elements(pi_list) gt 0 and n_elements(pi) gt 0) then begin ;if this is a combined request
  ;pi_list will exist, otherwise not.
  ;check if this pi is already in list
  if (strpos(pi_list, pi) eq -1) then pi_list = pi_list + pi

endif

endfor


if (gif_ps_open eq 1) then begin
  if (keyword_set(COMBINE)) then begin
    ;combined_subtitle, a.(0), pi_list, mytitle
    case plottype of
      'pscript': combined_subtitle, a.(0), pi_list, mytitle,/ps
      'gif':  combined_subtitle, a.(0), pi_list, mytitle
      else:combined_subtitle, a.(0), pi_list, mytitle ; subtitle the xwindows
    endcase
  endif else begin
    ;project_subtitle,a.(0),mytitle,SSCWEB=SSCWEB ; subtitle the gif
    case plottype of
      'pscript': project_subtitle,a.(0),mytitle,SSCWEB=SSCWEB,/ps,tcolor=0
      'gif': project_subtitle,a.(0),mytitle,SSCWEB=SSCWEB,tcolor=0
      else: project_subtitle,a.(0),mytitle,SSCWEB=SSCWEB,tcolor=0; subtitle the xwindows
    endcase
  endelse
  deviceclose ; close any open gif
endif

;  end for time_series, spectrogram, topside and bottomside ionograms, stack_plot and
;          time_text
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all image plots
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 4) then begin
  if ((PS[i].ptype eq 4) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      ;if (gif_counter gt 0) then begin
      ;c = strpos(GIF,'.gif') ; search for .gif suffix
      ;if (c ne -1) then begin
      ;c = strmid(GIF,0,c) & GIF=c+strtrim(string(gif_counter),2)+'.gif'
      ;endif else GIF=GIF+strtrim(string(gif_counter),2)
      ;endif
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as images...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    print, 'DATASET=',PS[i].source
    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce the images

    s = plot_images(a,PS[i].vname,THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      DEBUG=debugflag,/COLORBAR)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...
    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Image plot failed' & close, 1
      print, 'STATUS=Image plot failed'
      return, -1
    endif

  endif
endfor
;  end for image plots.  plot_images calls tv, making ps's really big....
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;S/W to create Rick Burley's new flux images w/ an earth superimposed on the image.

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all flux_image plots
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 13) then begin
  if ((PS[i].ptype eq 13) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as flux images...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    print, 'DATASET=',PS[i].source
    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98

    ;No matter what size thumbnail you specifiy you can't get one smaller
    ;than 140x140

    if(cdawebflag) then FRAME=0
    ; Produce the images
    ;TJK 4/25/01 set smoothflag to false because it doesn't work well for euv yet
    smoothflag = 0
    s = plot_fluximages(a,PS[i].vname,THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      DEBUG=debugflag, SMOOTH=smoothflag,/COLORBAR)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Image plot failed' & close, 1
      print, 'STATUS=Image plot failed'
      return, -1
    endif

  endif
endfor

; end for flux images
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all image plots for flux movies
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 14) then begin
  if ((PS[i].ptype eq 14) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif' ; was '.mpg'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as flux movie...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    print, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    ; Produce the images
    ;TJK 4/25/01 set smoothflag to false because it doesn't work well for euv yet
    smoothflag = 0

    s = flux_movie(a,PS[i].vname,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      movie_frame_rate=ps[i].movie_frame_rate,$
      movie_loop=ps[i].movie_loop, limit=limit_movie,$
      DEBUG=debugflag,/COLORBAR,SMOOTH=smoothflag)


    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Image flux movie failed' & close, 1
      print, 'STATUS=Image flux movie failed'
      return, -1
    endif

  endif
endfor

; end for flux movies
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all image plots for movies
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 10) then begin
  if ((PS[i].ptype eq 10) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as images...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    print, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce the images

    s = movie_images(a,PS[i].vname,THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      movie_frame_rate=ps[i].movie_frame_rate,$
      movie_loop=ps[i].movie_loop,limit=limit_movie,$
      DEBUG=debugflag,/COLORBAR)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Image movie failed' & close, 1
      print, 'STATUS=Image movie failed'
      return, -1
    endif

  endif
endfor


; end for mapped movies
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all image plots for map movies
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 11) then begin
  if ((PS[i].ptype eq 11) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as images...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    print, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce the images
    ;s = plot_images(a,PS[i].vname,THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
    s = movie_map_images(a,PS[i].vname,THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      movie_frame_rate=ps[i].movie_frame_rate,$
      movie_loop=ps[i].movie_loop,LIMIT=limit_movie,$
      DEBUG=debugflag,/COLORBAR)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Image movie failed' & close, 1
      print, 'STATUS=Image movie failed'
      return, -1
    endif
  endif
endfor

; end for movie map images
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; Make a pass thru the plot script and generate all radar plots
a_id=-1 ; Reset structure id
for i=0,n_elements(PS)-1 do begin
  if (PS[i].ptype eq 3) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Only DARN radar data is currently plottable.  Verify that the source
    ; of this variable is DARN.
    proceed = 1L & b = spd_cdawlib_tagindex('SOURCE_NAME',tag_names(a.(PS[i].vnum)))
    if (b[0] eq -1) then begin
      proceed = 0L & print,'ERROR=Unable to determine source for radar plot...'
    endif
    if (strpos(strupcase(a.(PS[i].vnum).SOURCE_NAME),'DARN') eq -1) then begin
      proceed = 0L & print,'ERROR=Source of radar plot not equal to DARN...'
    endif
    if (proceed eq 1) then begin
      if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as Radar...'

      ;if keyword_set(GIF) then begin
      ;   ;if (gif_counter gt 0) then begin
      ;   ;c = strpos(GIF,'.gif') ; search for .gif suffix
      ;   ; if (c ne -1) then begin
      ;   ; c = strmid(GIF,0,c) & GIF=c+strtrim(string(gif_counter),2)+'.gif'
      ;   ;endif else GIF=GIF+strtrim(string(gif_counter),2)
      ;   ;endif
      ;   if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      ;   if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      ;   if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      ;   GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      ;endif
      if plottype eq 'gif' then begin
        if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
        if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
        if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
        GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
        gif_ps_open=1L & gif_counter = gif_counter + 1
        xysize=400
      endif
      if plottype eq 'pscript' then begin
        if(ps_counter lt 100) then psn='0'+strtrim(string(ps_counter),2)
        if(ps_counter lt 10) then psn='00'+strtrim(string(ps_counter),2)
        if(ps_counter ge 100) then psn=strtrim(string(ps_counter),2)
        out_ps=outdir+PS[i].source+'_'+pid+'_'+psn+'.eps'
        ;; Initialize window state and open the ps file
        ;WS.ys = b + WS.ymargin[0] + WS.ymargin[1] ; add room for timeaxis
        ;;
        ;deviceopen,1,fileOutput=out_ps,/portrait,sizeWindow=[WS.xs,WS.ys]
        gif_ps_open=1L & ps_counter = ps_counter + 1
        xysize=15000  ; RCJ 04/18/2007  This number is 100% arbitrary.
      endif
      ; Modify source name for SSCWEB DATASET label
      if(SSCWEB) then begin
        satname=strtrim(a.epoch.source_name,2)
        PS[i].source= PS[i].source + '_' + satname
      endif

      if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
      print, 'DATASET=',PS[i].source

      ; Produce the radar plots
      s = plot_radar(a,PS[i].vnum,XYSIZE=XYSIZE,GIF=GIF,GCOUNT=gif_counter,$
        ps=out_ps,pcount=ps_counter,$
        TSTART=start_time,TSTOP=stop_time,$
        REPORT=reportflag,DEBUG=debugflag)
      if(s eq -1) then begin
        print, 'STATUS=Radar Plot Failed'
        if(reportflag) then printf, 1, 'STATUS=Radar Plot Error'
        ;endif else gif_counter=s
      endif else begin
        if keyword_set(GIF) then gif_counter=s
        if keyword_set(ps) then ps_counter=s
      endelse
    endif
  endif
endfor

; end for radar plots
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all mapped plots
pwc=where(PS.ptype eq 6,pwcn)
; RCJ 02/17/2006  Picking better colors. Avoiding yellow and picking
; greens/blues as far from each other as possible.
; If the max number of satellites allowed to be plotted increases
; more lines have to be added here.
isymcol=0
if pwcn/2 le 2 then symcols=[70,238]
if pwcn/2 eq 3 then symcols=[70,200,238]
if pwcn/2 eq 4 then symcols=[70,130,200,238]
if pwcn/2 eq 5 then symcols=[46,82,128,200,238]
if pwcn/2 eq 6 then symcols=[40,70,100,170,200,238]
if pwcn/2 eq 7 then symcols=[40,65,85,110,160,200,238]
if pwcn/2 eq 8 then symcols=[10,40,70,100,130,170,200,238]
if pwcn/2 eq 9 then symcols=[10,25,40,70,100,130,170,200,238]
if pwcn/2 eq 10 then symcols=[10,25,40,55,70,100,130,170,200,238]
if pwcn/2 eq 11 then symcols=[10,25,40,55,70,100,130,145,170,200,238]
if pwcn/2 eq 12 then symcols=[10,25,40,55,70,100,130,145,170,185,200,238]

; Added this section to find the names of all the spacecraft whose orbits are
; being mapped.  This list is then passed to get_ssc_colors() to get the colors
; to use in the plot.
; Ron Yurow (Jan 24, 2017)
IF  (SSCWEB) THEN BEGIN
    n = -1
    names = ['']

    FOR i=0, N_ELEMENTS (PS) - 1 DO BEGIN
        IF  (PS [i].ptype eq 6) THEN BEGIN
            IF  PS [i].snum gt n THEN BEGIN

                n = PS [i].snum
                res = EXECUTE ('s = a' + STRTRIM (STRING (n), 2) + '.epoch.source_name')
                names = [names, s]

            ENDIF
        ENDIF
    ENDFOR

    IF  N_ELEMENTS (names) gt 1 THEN BEGIN

        names = names [1:*]
        symcols = get_ssc_colors (names)

    ENDIF
ENDIF 

for i=0,n_elements(PS)-1 do begin
  if (PS[i].ptype eq 6) then begin
  ;if ((PS[i].ptype eq 6) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
       ; Modify source name for SSCWEB DATASET label
      if(SSCWEB) then begin
        satname=strtrim(a.epoch.source_name,2)
        PS[i].source= PS[i].source + '_' + satname
      endif  
        if(reportflag) then begin
          printf, 1, 'DATASET=',PS[i].source
        endif
        print, 'DATASET=',PS[i].source

      ; Determine name for new gif file and create GIF/window

      case plottype of
       'gif': begin
        ; Write dataset name for each structure processed for overplotting s/c on
        ; 1 plot
        if(i eq pwc[0]) then begin ; Remove this condition blk for single gifs
          ; This condition will allow multiple s/c to be overploted
          if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
          if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
          if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
          GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
          ;gif_counter = gif_counter + 1
          gif_ps_open=1L & gif_counter = gif_counter + 1

          ; Control size for projection
          xs=790 & ys=612
          yoffset=0.23 ; For mulitple gif files

          ; Changed the following statement so that GIF plots will use the RAINBOW+WHITE
          ; color table.  This matches the color table used by ORB_MGR.
          ; Ron Yurow (Jan 24, 2017)
          ; deviceopen,6,fileOutput=GIF,sizeWindow=[xs,ys]
          deviceopen,6,fileOutput=GIF,sizeWindow=[xs,ys],COLORTAB=39
        endif  ; Remove this condition for single gifs.
        ; This condition will allow multiple s/c to be overploted
      endcase 
      'pscript' : begin
        if(i eq pwc[0]) then begin ; Remove this condition blk for single gifs
          ; This condition will allow multiple s/c to be overploted
          if(ps_counter lt 100) then psn='0'+strtrim(string(ps_counter),2)
          if(ps_counter lt 10) then psn='00'+strtrim(string(ps_counter),2)
          if(ps_counter ge 100) then psn=strtrim(string(ps_counter),2)
          out_ps=outdir+PS[i].source+'_'+pid+'_'+psn+'.eps'
          ;ps_counter = ps_counter + 1
          gif_ps_open=1L & ps_counter = ps_counter + 1

          xs=28000 & ys=21000
          deviceopen,1,fileOutput=out_ps, /portrait,sizeWindow=[xs,ys]
        endif  ; Remove this condition for single gifs.
        ; This condition will allow multiple s/c to be overploted
      endcase
      else: window,/FREE,XSIZE=xs,YSIZE=ys,TITLE='MAPPED PLOT'
      endcase
      ; Produce debug output if requested
      if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' ... as MAPPED.'
      rng_val=[start_time,stop_time]

      ; Produce the mapped plots
      ; RCJ 12/20/2007  pmode is (number_of_satellite_traces_I_want - 1)
      if(i eq pwc[0]) then pmode=0 else if(pmode eq -1) then pmode=11
      if((n_elements(polon) ne 0) and (n_elements(polat) ne 0) and $
        (n_elements(rot) ne 0)) then begin
        vlat=fltarr(3)
        vlat[0]=polat
        vlat[1]=polon
        vlat[2]=rot
      endif
      symcol=symcols[isymcol]
      isymcol=isymcol+1

      s = plot_maps(a,station=station,vlat=vlat,iproj=iproj,lim=lim,$
        latdel=latdel,londel=londel,Ttitle=thetitle,$
        pmode=pmode,rng_val=rng_val,num_int=num_int,$
        lthik=lthik,symsiz=symsiz,symcol=symcol,$
        charsize=chtsize,xmargin=xmargin,ymargin=ymargin,$
        xoffset=xoffset,yoffset=yoffset,lnlabel=lnlabel,nocont=nocont,$
        SSCWEB=SSCWEB,doymark=doymark,hrmark=hrmark,hrtick=hrtick,$
        mntick=mntick,mnmark=mnmark,lnthick=lnthick,$
        autolabel=autolabel,datelabel=datelabel,_extra=extras)

      if(s eq -1) then begin
        if(reportflag) then printf, 1, 'STATUS=Mapped plot failed' & close, 1
        print, 'STATUS=Mapped plot failed'
        return, -1
      endif
    endif
  endif
  ; The following condition should be removed for separate single gif files
  ; This will allow multiple s/c to be overploted
  if(pwcn gt 0) then begin
    if(i eq pwc[pwcn-1]) then begin
      if(reportflag) then begin
         if plottype eq 'gif' then printf,1,'GIF=',GIF
         if plottype eq 'pscript' then printf,1,'PS=',out_ps
      endif
      if plottype eq 'gif' then print,'GIF=',GIF
      if plottype eq 'pscript' then print,'PS=',out_ps
      deviceclose
    endif
  endif
endfor
; end for mapped plots
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; Make a pass thru the plot script, select all structures for orbit plots,
; submit all structures to orb_mgr to plot satellites by coordinate system
; chosen.
iorb=0
orbit_trip=0
a_id=-1 ; Reset structure id
for i=0,n_elements(PS)-1 do begin
  if (PS[i].ptype eq 5) then begin
    orbit_trip=1
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      aa_lab='aa'+strtrim(string(iorb),2)
      s=execute(aa_lab+'=a'+strtrim(string(PS[i].snum),2))
      if(iorb eq 0) then begin
        mega_aa=create_struct(aa_lab,aa0)
      endif else begin
        if(iorb eq 1) then temp_mg=create_struct(aa_lab,aa1)
        if(iorb eq 2) then temp_mg=create_struct(aa_lab,aa2)
        if(iorb eq 3) then temp_mg=create_struct(aa_lab,aa3)
        if(iorb eq 4) then temp_mg=create_struct(aa_lab,aa4)
        if(iorb eq 5) then temp_mg=create_struct(aa_lab,aa5)
        if(iorb eq 6) then temp_mg=create_struct(aa_lab,aa6)
        if(iorb eq 7) then temp_mg=create_struct(aa_lab,aa7)
        if(iorb eq 8) then temp_mg=create_struct(aa_lab,aa8)
        if(iorb eq 9) then temp_mg=create_struct(aa_lab,aa9)
        if(iorb eq 10) then temp_mg=create_struct(aa_lab,aa10)
        if(iorb eq 11) then temp_mg=create_struct(aa_lab,aa11)
        if(iorb eq 12) then temp_mg=create_struct(aa_lab,aa12)
        mega_aa=create_struct(mega_aa,temp_mg)
      endelse
      a_id = PS[i].snum
      iorb=iorb+1
      ; Modify source name for SSCWEB DATASET label
      if(SSCWEB) then begin
        if(n_elements(xs_ssc) ne 0) then xsize=xs_ssc
        if(n_elements(ys_ssc) ne 0) then ysize=ys_ssc ; Orbits xsize=ysize
        ;   satname=strtrim(temp_mg.epoch.source_name,2)
        x1=execute('satname='+aa_lab+'.epoch.source_name')
        PS[i].source= PS[i].source + '_' + satname
      endif

      if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
      print, 'DATASET=',PS[i].source

    endif
  endif
endfor
if(orbit_trip eq 1) then begin
  out_name=strarr(10)
  if(n_elements(start_time) ne 0) then tstart=start_time
  if(n_elements(stop_time) ne 0) then tstop=stop_time
  ;if keyword_set(GIF) then begin
  ;   ;if (gif_counter gt 0) then begin
  ;   ; c = strpos(GIF,'.gif') ; search for .gif suffix
  ;   ;if (c ne -1) then begin
  ;   ;c = strmid(GIF,0,c) & GIF=c+strtrim(string(gif_counter),2)+'.gif'
  ;   ;endif else GIF=GIF+strtrim(string(gif_counter),2)
  ;   ; endif
  ;   ; For orbit 1 image can have multiple sources
  ;   ; GIF=outdir+PS[i].source+'_'+pid+'_'+string(gif_counter)+'.gif'
  ;   if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
  ;   if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
  ;   if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
  ;   GIF=outdir+'ORBIT_'+pid+'_'+gifn+'.gif'
  ;endif
  if plottype eq 'gif' then begin
    if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
    if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
    if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
    GIF=outdir+'ORBIT_'+pid+'_'+gifn+'.gif'
    gif_ps_open=1L & gif_counter = gif_counter + 1
    xsize=720 & ysize=850  ; RCJ  Default in orb_mgr.pro
  endif
  if plottype eq 'pscript' then begin
    if(ps_counter lt 100) then psn='0'+strtrim(string(ps_counter),2)
    if(ps_counter lt 10) then psn='00'+strtrim(string(ps_counter),2)
    if(ps_counter ge 100) then psn=strtrim(string(ps_counter),2)
    out_ps=outdir+'ORBIT_'+pid+'_'+psn+'.eps'
    ;; Initialize window state and open the ps file
    ;WS.ys = b + WS.ymargin[0] + WS.ymargin[1] ; add room for timeaxis
    ;;
    ;deviceopen,1,fileOutput=out_ps,/portrait,sizeWindow=[WS.xs,WS.ys]
    gif_ps_open=1L & ps_counter = ps_counter + 1
    ;3/18/2010 TJK needed smaller x for 4 panel (ssc type) orbits - somehow making
    ;the x dimension smaller males the 4 panels fit... go figure
    ;xsize=25000 & ysize=28000 ; RCJ Utter guesses
    xsize=21000 & ysize=28000 ; TJK seems to work better...
  endif

  ;Check to see if plotmaster is being called by ssc_plot, and
  ;Postscript option requested
  help, /traceback, output=trace_back
  if (n_elements(trace_back) gt 1) then begin
    if (strcmp('ssc_plot',trace_back[n_elements(trace_back)-1], /fold_case) && keyword_set(PS)) then begin

      ;    print, 'TJK DEBUG Requested size of orbit plot is ',xsize, ysize
      ;    print, 'TJK setting orb_vw to xy'
      orb_vw='xy'
    endif
  endif

  ; RCJ 09Dec2016   Set smaller character size if ps plot
  if plottype eq 'pscript' then chtsize='0.95' else chtsize='1.2'
  
  out_strc=orb_mgr(mega_aa,$
    tstart=tstart,tstop=tstop,xsize=xsize,ysize=ysize, $
    orb_vw=orb_vw,press=press,bz=bz,xmar=xmar,$
    ymar=ymar,doymark=doymark,hrmark=hrmark,hrtick=hrtick, $
    mntick=mntick,mnmark=mnmark,xumn=xumn,xumx=xumx,yumn=yumn,$
    yumx=yumx,zumn=zumn,zumx=zumx,rumn=rumn,rumx=rumx,labpos=labpos,$
    chtsize=chtsize,GIF=GIF,GCOUNT=gif_counter,ps=out_ps,pCOUNT=ps_counter, $
    SSC=SSCWEB,REPORT=reportflag,$
    DEBUG=debugflag,us=us,bsmp=bsmp, $
    symsiz=symsiz,lnthick=lnthick,autolabel=autolabel,datelabel=datelabel,$
    eqlscl=eqlscl,panel=panel)

   
  s=out_strc
  if(s eq -1) then begin
    if(reportflag) then begin
      printf, 1, 'STATUS=Orbit Plot Failed'
      close, 1
    endif
    print, 'STATUS=Orbit Plot Failed'
    return, -1
  endif
endif

; Display of map images will be accomplished through calls to plotmaster
; where the DISPLAY_TYPE for map image variables will be set to "MAP_IMAGE"
; These variables will be passed to a new function called plot_map_images.pro
; which will process and display each image in a fashion similar to plot_images
; (ie. an image of thumbnails will initially be produced w/ an option to
; select & displays individual thumbnails).  The auroral_image.pro function will
; be incorporated into plot_map_images.  Uviptg.pro used to generate lats and
; lons for polar uvi display will be incorporated into the virtual variables
; scheme.

; AT THIS POINT SETTING UP CASE SPECIFIC CODE. WIll NEED TO GO BACK
; AND INCORPORATE SOME OF THIS INTO VIRTUAL VARIABLES
;
; end for orbit plots
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all auroral image map plots
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 8) then begin
  if ((PS[i].ptype eq 8) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as map images...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    print, 'DATASET=',PS[i].source

    ;Test for GPS - does work for Dieter's additional request
    ;     Continent = 0
    ;     Grid = 0

    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce the images
    s = plot_map_images(a,PS[i].vname,CENTERLONLAT=CENTERLONLAT,$
      THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      DEBUG=debugflag,/COLORBAR)
    ;GPS Test                 DEBUG=debugflag,/COLORBAR,GRID=GRID,CONTINENT=CONTINENT)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Map Image plot failed' & close, 1
      print, 'STATUS=Map Image plot failed'
      return, -1
    endif
  endif
endfor ;for all mapped image plots

; end for mapped images
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all skymap plots (TWINS)
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 20) then begin
  if ((PS[i].ptype eq 20) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as skymap images...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    print, 'DATASET=',PS[i].source

    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/
    ; image data to be processed otherwise
    ; keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce the images
    s = plot_skymap(a,PS[i].vname,THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      DEBUG=debugflag,/COLORBAR)
    ;,GRID=GRID,CONTINENT=CONTINENT)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next
    ;plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=SkyMap Image plot failed' & close, 1
      print, 'STATUS=SkyMap Image plot failed'
      return, -1
    endif
  endif
endfor ;for all skymap image plots

; end for skymap images - special for TWINS
;                         ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all skymap image movies
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 21) then begin
  if ((PS[i].ptype eq 21) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as skymap movie images...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    print, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)

    ; Produce the skymap movie file
    s = movie_skymap(a,PS[i].vname,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      xsize=xsize, ysize=ysize, movie_frame_rate=ps[i].movie_frame_rate,$
      movie_loop=ps[i].movie_loop,LIMIT=limit_movie,$
      DEBUG=debugflag,/COLORBAR)

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=SKYmap movie failed' & close, 1
      print, 'STATUS=SKYmap movie failed'
      return, -1
    endif
  endif
endfor

; end for movie skymap images
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


;Generate all Plasmagram plots
a_id=-1
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 9) then begin ;look for all plasmagrams
  if ((PS[i].ptype eq 9) and (plottype ne 'pscript')) then begin ;look for all plasmagrams
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif

    ; Produce debug output if requested.
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as plasmagram.'

    ; Generate the plasmagram
    ; Determine name for new gif file and create GIF/X-window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif else deviceopen,0 ; producing XWINDOWS

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source

    print, 'DATASET=',PS[i].source

    ; Get the index of the time variable associated with variable to be plotted
    b = a.(PS[i].vnum).DEPEND_0 & c = spd_cdawlib_tagindex(b[0],tag_names(a))

    if (strpos(a.(c[0]).CDFTYPE, 'CDF_EPOCH16') ge 0) then begin
      ;The following if statements are needed in the case where TSTART/TSTOP is not
      ;used but the data is in epoch16
      if (n_elements(start_time16) eq 0) then begin ;convert the regular epoch to epoch16
        cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_epoch16, start_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
      endif
      if (n_elements(stop_time16) eq 0) then begin ;convert the regular epoch to epoch16
        cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_epoch16, stop_time16, yr,mo,dd,hr,mm,ss,mil,0,0,0,/compute
      endif
      start_time = start_time16 & stop_time = stop_time16
    endif

    if (strpos(a.(c[0]).CDFTYPE, 'CDF_TIME_TT2000') ge 0) then begin
      ;The following if statements are needed in the case where TSTART/TSTOP are not
      ;used but the data is in time TT2000
      ;instead of regular Epoch or Epoch16
      if (n_elements(start_timett) eq 0) then begin ;convert the regular epoch to tt2000
        cdf_epoch, start_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_tt2000, start_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
      endif
      if (n_elements(stop_timett) eq 0) then begin ;convert the regular epoch to tt2000
        cdf_epoch, stop_time, yr,mo,dd,hr,mm,ss,mil,/break
        cdf_tt2000, stop_timett, yr,mo,dd,hr,mm,ss,mil,0,0,/compute
      endif
      start_time = start_timett & stop_time = stop_timett
    endif


    s = plot_plasmagram(a,PS[i].vname,$
      GIF=GIF, /CDAWEB, TSTART=start_time,TSTOP=stop_time, $
      /colorbar, DEBUG=debugflag, thumbsize=thumbsize,$
      FRAME=FRAME, REPORT=reportflag, NONOISE=NONOISE, TOP_TITLE=top_title)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Plasmagram plot failed' & close, 1
      print, 'STATUS=Plasmagram plot failed'
      return, -1
    endif
    ; Update the state of the window
    WS.pos[3] = WS.pos[3] - (pheight * PS[i].npanels) ; update Y corner
    WS.pos[1] = WS.pos[1] - (pheight * PS[i].npanels) ; update Y origin
  endif
endfor

; end for plasmagrams
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all image plots for plasmagram
; movies
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 15) then begin
  if ((PS[i].ptype eq 15) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as flux movie...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    print, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    ; Produce the images

    s = plasma_movie(a,PS[i].vname,XSIZE=XSIZE,YSIZE=YSIZE,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      movie_frame_rate=ps[i].movie_frame_rate,$
      movie_loop=ps[i].movie_loop,$
      DEBUG=debugflag,/COLORBAR)


    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Plasmagram movie failed' & close, 1
      print, 'STATUS=Plasmagram movie failed'
      return, -1
    endif

  endif
endfor
; end for plasma movies
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate fuv images
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 16) then begin
  if ((PS[i].ptype eq 16) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as flux image...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    print, 'DATASET=',PS[i].source
    ; Produce the images
    print,'Calling plot_fuv_images. Gif = ',gif
    s = plot_fuv_images(a,PS[i].vname,$
      CDAWEB=cdawebflag,GIF=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,NONOISE=NONOISE,$
      DEBUG=debugflag,/COLORBAR)

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=FUV image failed' & close, 1
      print, 'STATUS=FUV image failed'
      return, -1
    endif

  endif
endfor

; end for fuv images
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate fuv movies
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 17) then begin
  if ((PS[i].ptype eq 17) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif' ; was 'mpg'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as fuv movie...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    print, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    ; Produce the images
    ;print,'Calling fuv_movie. mpeg = ',gif
    s = fuv_movie(a,PS[i].vname,$
      MPEG=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,$
      movie_frame_rate=ps[i].movie_frame_rate,$
      movie_loop=ps[i].movie_loop,LIMIT=limit_movie,$
      /COLORBAR)

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=FUV movie failed' & close, 1
      print, 'STATUS=FUV movie failed'
      return, -1
    endif

  endif
endfor
;
a_id=-1 ; Reset structure id

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 18) then begin
  if ((PS[i].ptype eq 18) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    ;if keyword_set(GIF) then begin
    ;   if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
    ;   if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
    ;   if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
    ;   GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
    ;   gif_counter = gif_counter + 1
    ;endif
    if plottype eq 'gif' then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_ps_open=1L & gif_counter = gif_counter + 1
    endif
    if plottype eq 'pscript' then begin
      if(ps_counter lt 100) then psn='0'+strtrim(string(ps_counter),2)
      if(ps_counter lt 10) then psn='00'+strtrim(string(ps_counter),2)
      if(ps_counter ge 100) then psn=strtrim(string(ps_counter),2)
      out_ps=outdir+PS[i].source+'_'+pid+'_'+psn+'.eps'
      gif_ps_open=1L & ps_counter = ps_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as wind plot...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    print, 'DATASET=',PS[i].source

    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce the images
    s = plot_wind_map(a,PS[i].vname,$
      THUMBSIZE=THUMBSIZE,FRAME=FRAME,$
      CDAWEB=cdawebflag,GIF=GIF,ps=out_ps,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,$
      ; following line is for tidi.  15 orbits in one day, 29 points each
      MYSCALE=200., xy_step=29.*15.,$
      DEBUG=debugflag)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Wind plot failed' & close, 1
      print, 'STATUS=Wind plot failed'
      return, -1
    endif
  endif
endfor ;for all mapped image plots

; end for wind maps
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all image plots for map movies
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 19) then begin
  if ((PS[i].ptype eq 19) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new gif file and create GIF/window
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      ;GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.mpg'
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.gif'
      gif_counter = gif_counter + 1
    endif
    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Plotting ',PS[i].vname,' as movie...'

    ; Modify source name for SSCWEB DATASET label
    if(SSCWEB) then begin
      satname=strtrim(a.epoch.source_name,2)
      PS[i].source= PS[i].source + '_' + satname
    endif

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source
    print, 'DATASET=',PS[i].source
    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce movie
    s = movie_wind_map(a,PS[i].vname,$
      CDAWEB=cdawebflag,mgif=GIF,REPORT=reportflag,$
      TSTART=start_time,TSTOP=stop_time,$
      ; following line is for tidi.  15 orbits in one day, 29 points each
      MYSCALE=200., xy_step=29.*15.,$
      movie_frame_rate=ps[i].movie_frame_rate,$
      movie_loop=ps[i].movie_loop,$
      DEBUG=debugflag)
    thumbsize = 50 ;reset thumbsize otherwise what is set inside the
    ;above call will be used for the next plot type...

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Wind map movie failed' & close, 1
      print, 'STATUS=Wind map movie failed'
      return, -1
    endif
  endif
endfor

; end for wind map movies
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Added code to handle generating audio files for Audio display type.
; Ron Yurow (Sep 13, 2016)

a_id=-1 ; Reset structure id
; Make a pass thru the plot script and generate all sound files for audio
for i=0,n_elements(PS)-1 do begin
  ;if (PS[i].ptype eq 10) then begin
  if ((PS[i].ptype eq 22) and (plottype ne 'pscript')) then begin
    ; Ensure that 'a' holds the correct data structure
    if (PS[i].snum ne a_id) then begin
      s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
    endif
    ; Determine name for new audio file.
    if keyword_set(GIF) then begin
      if(gif_counter lt 100) then gifn='0'+strtrim(string(gif_counter),2)
      if(gif_counter lt 10) then gifn='00'+strtrim(string(gif_counter),2)
      if(gif_counter ge 100) then gifn=strtrim(string(gif_counter),2)
      ;GIF=outdir+PS[i].source+'_'+pid+'_'+gifn+'.mpg'
      GIF=outdir+PS[i].source+'_'+pid+'_'+gifn
      gif_counter = gif_counter + 1
    endif

    ; Produce debug output if requested
    if keyword_set(DEBUG) then print,'Writing  ',PS[i].vname,' as audio file...'

    if (reportflag eq 1) then printf, 1, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    print, 'DATASET=',PS[i].source+': '+strupcase(PS[i].vname)
    ; For CDAWEB set the FRAME=0. This will allow multiple structures w/ image
    ; data to be processed otherwise keyword_set(FRAME) is true even for structures
    ; where it shouldn't be  RTB  4/98
    if(cdawebflag) then FRAME=0
    ; Produce the audio file

    s = AUDIO_WAV (a,PS[i].vname, RANGE=range, TSTART=TSTART, TSTOP=TSTOP, $
      GIF=gif, DEBUG=debugflag)

    if(s eq -1) then begin
      if(reportflag) then printf, 1, 'STATUS=Audio file creation failed' & close, 1
      print, 'STATUS=Audio file creation failed'
      return, -1
    endif

  endif
endfor
; end for audio file generation
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

a_id=-1 ; Reset structure id

;TJK - 2/14/2005 - handle the case where the values for data variable(s) are all fill.
for i=0,n_elements(PS)-1 do begin
  ; Since it makes no sense to check invalid data structures for variables that are all
  ; FILL, we just force the next iteration of the loop when we encounter one.
  ; Ron Yurow (March 9, 2017)
  IF ps[i].ibad eq 1 then CONTINUE

  eflag = strpos(strupcase(PS[i].vname),'EPOCH') ;don't tell the user about epoch variables.
  ; Ensure that 'a' holds the correct data structure
  if (PS[i].snum ne a_id) then begin
    s=execute('a=a'+strtrim(string(PS[i].snum),2)) & a_id = PS[i].snum
  endif
  ;j = PS[i].vname
  ;stat = execute('v_type = a.'+j+'.var_type')
  ; RCJ 02/25/2005  Changed this line to get the number instead
  ; of the name because a var called 'Ne' gave us a syntax error!
  stat = execute('v_type = a.('+strtrim(string(ps[i].vnum),2)+').var_type')
  stat = execute('c_type = a.('+strtrim(string(ps[i].vnum),2)+').cdftype')
  ;print, 'TJK DEBUG: VARIABLE ',ps[i].vname,'  ',v_type
  ; RCJ 03/29/2006  The line below fails if there's no v_type
  ;if (strupcase(v_type) eq 'DATA' and stat) then begin
  if (stat ne 0) then begin
    if (strupcase(v_type) eq 'DATA') then begin
      if (PS[i].ptype eq 0 and PS[i].npanels eq 0 and eflag eq -1)then begin
        if (n_elements(ds) eq 0) then begin
          ds = PS[i].source
          print, 'DATASET=',ds
          if strupcase(c_type) eq 'CDF_CHAR' then $
            print, 'STATUS= ',PS[i].vname,' is of CDF_CHAR type and is not plottable.' else $
            print, 'STATUS= ',PS[i].vname,' data are all fill: reselect time range.'
        endif else begin
          if (PS[i].source ne ds) then begin
            ds = PS[i].source
            print, 'DATASET=',ds
          endif
          if strupcase(c_type) eq 'CDF_CHAR' then $
            print, 'STATUS= ',PS[i].vname,' is of CDF_CHAR type and is not plottable.' else $
            print, 'STATUS= ',PS[i].vname,' data are all fill: reselect time range.'
        endelse
      endif
    endif
  endif
endfor

; If generating a log/report file then close it.
if (reportflag eq 1) then close,1

; Set plot back to native method
case strupcase(strtrim(strmid(!version.os_family,0,3),2)) of
  'MAC' : set_plot,'MAC' ; return to interactive on Mac
  'WIN' : set_plot,'WIN' ; return to interactive on Windows
  else  : set_plot,'X'   ; return to interactive on Unix/X
endcase

return,0
end









