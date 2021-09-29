;+
; Procedure:
;         mms_part_slice2d
;
; Purpose:
;         This is a wrapper around spd_slice2d and spd_slice2d_plot that loads required
;         support data, creates and plots the slice
;
; Keywords:
;         PROBE: MMS s/c # to create the 2D slice for
;         INSTRUMENT: fpi or hpca
;         SPECIES: depends on instrument:
;             FPI: 'e' for electrons, 'i' for ions
;             HPCA: 'hplus' for H+, 'oplus' for O+, 'heplus' for He+, 'heplusplus', for He++
;         LEVEL: level of the data you'd like to plot
;         DATA_RATE: data rate of the distribution data you'd like to plot
;         TIME: time of the 2D slice
;         TRANGE: two-element time range over which data will be averaged (optional, ignored if 'time' is specified)
;         SPDF: load the data from the SPDF instead of the LASP SDC
;         OUTPUT: returns the computed slice
;         UNITS: units of the slice (default is df_cm - other options include 'df_km', 'flux', 'eflux')
;         
;         TRANGE: Two-element time range over which data will be averaged. (string or double)
;         TIME: Time at which the slice will be computed. (string or double)
;           SAMPLES: Number of nearest samples to TIME to average. (int/double)
;             If neither SAMPLES nor WINDOW are specified then default=1.
;           WINDOW: Length in seconds from TIME over which data will be averaged. (int/double)
;             CENTER_TIME: Flag denoting that TIME should be midpoint for window instead of beginning.
;
;           SUM_SAMPLES: Flag denoting that the data should be summed over the requested trange rather than averaged
;
;         THREE_D_INTERP: Flag to use 3D interpolation method (described below)
;         TWO_D_INTERP: Flag to use 2D interpolation method (described below)
;         GEOMETRIC: Flag to use geometric interpolation method (described below)
;  
;         RESOLUTION: Integer specifying the resolution along each dimension of the
;              slice (defaults:  2D/3D interpolation: 150, geometric: 500)
;         SMOOTH: An odd integer >=3 specifying the width of a smoothing window in #
;              of points.  Smoothing is applied to the final plot using a gaussian
;              convolution. Even entries will be incremented, 0 and 1 are ignored.
;
;         ENERGY: Flag to plot data against energy (in eV) instead of velocity.
;         LOG: Flag to apply logarithmic scaling to the radial measure (i.e. energy/velocity).
;              (on by default if /ENERGY is set)
;
;         ERANGE: Two element array specifying the energy range to be used in eV.
;
;         THETARANGE: (2D interpolation only)
;              Angle range, in degrees [-90,90], used to calculate slice.
;              Default = [-20,20]; will override ZDIRRANGE.
;         ZDIRRANGE: (2D interpolation only)
;             Z-Axis range, in km/s, used to calculate slice.
;             Ignored if called with THETARANGE.
;
;         AVERAGE_ANGLE: (geometric interpolation only)
;                 Two element array specifying an angle range over which
;                 averaging will be applied. The angle is measured
;                 from the slice plane and about the slice's horizontal axis;
;                 positive in the right handed direction. This will
;                 average over all data within that range.
;
;                 Note: for the default rotation='xy', the angle is measured from the XY
;                 slice plane and about the x-axis
;                    e.g. rotation='xy', average_angle=[-25,25] will average data within 25 degrees
;                         of the XY slice plane about it's x-axis
;                    or
;                         rotation='yz', average_angle=[-25,25] will average data within 25 degrees
;                         of the YZ slice plane about it's y-axis
;
;         SUM_ANGLE: (geometric interpolation only)
;                 Two element array specifying an angle range over which
;                 summing will be applied. The angle is measured
;                 from the slice plane and about the slice's horizontal axis;
;                 positive in the right handed direction. This will
;                 sum over all data within that range.
;
;                 Note: for the default rotation='xy', the angle is measured from the XY
;                 slice plane and about the x-axis
;                    e.g. rotation='xy', sum_angle=[-25,25] will sum data within 25 degrees
;                         of the XY slice plane about it's x-axis
;                    or
;                         rotation='yz', sum_angle=[-25,25] will sum data within 25 degrees
;                         of the YZ slice plane about it's y-axis
;
;         DETERM_TOLERANCE:  tolerance of the determinant of the custom rotation matrix
;           (maximum acceptable difference from determ(C)=1 where C is the
;           user's custom rotation matrix); default is 1e-6
;           
;         SUBTRACT_BULK: subtract the bulk velocity prior to doing the calculations
;         PERP_SUBTRACT_BULK: subtract the perpendicular bulk velocity in field-aligned coordinates
;                 i.e., finds the perp velocity by rotating into the 'bv' system, then sets the X component 
;                 of velocity to zero, and inverse, then subtracts this velocity instead of the full bulk
;                 velocity
;
;Orientation Keywords:
;         ROTATION: Aligns the data relative to the magnetic field and/or bulk velocity.
;            This is applied after the CUSTOM_ROTATION. (BV and BE are invariant
;            between coordinate systems)
;
;            'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;            'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;            'xy':  (default) The x axis is along the data's x axis and y is along the data's y axis
;            'xz':  The x axis is along the data's x axis and y is along the data's z axis
;            'yz':  The x axis is along the data's y axis and y is along the data's z axis
;            'xvel':  The x axis is along the data's x axis; the x-y plane is defined by the bulk velocity
;            'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)
;            'perp_xy':  The data's x & y axes are projected onto the plane normal to the B field
;            'perp_xz':  The data's x & z axes are projected onto the plane normal to the B field
;            'perp_yz':  The data's y & z axes are projected onto the plane normal to the B field
;            
;         CUSTOM_ROTATION: Applies a custom rotation matrix to the data.  Input may be a
;                   3x3 rotation matrix or a tplot variable containing matrices.
;                   If the time window covers multiple matrices they will be averaged.
;                   This is applied before other transformations
;
;         SLICE_X & SLICE_NORM: These keywords respectively specify the slice plane's
;                        x-axis and normal within the coordinates specified by
;                        CUSTOM_ROTATION and ROTATION. Both keywords take
;                        3-vectors as input. (See note below)
;
;                        If SLICE_X is not specified then the given coordinate's
;                        x-axis will be used. If SLICE_X is not perpendicular to
;                        the normal it's projection onto the slice plane will be used.
;                        An error will be thrown if no projection exists.
;
;                        If SLICE_NORM is not specified then the given coordinate's
;                        z-axis will be used (slice along by x-y plane in those
;                        coordinates).
;
;              examples:
;                Slice along the data's x-z plane:
;                  ROTATION='xz'
;
;                Slice plane's x axis is GSM x and y is in the direction of the bulk velocity:
;                  CUSTOM_ROTATION='my_gsm_tvar', ROTATION='xvel'
;
;                Slice is perpendicular to "tvar1" and x axis is defined by projection of "tvar2"
;                  SLICE_NORM='tvar1', SLICE_X='tvar2'
;
;       NOTE: Update at 06/04/2018 - The SLICE_X & SLICE_NORM are defined after CUSTOM_ROTATION
;         but before the ROTATION.
;
;        DISPLACEMENT: Vector. New center of the coordinate system.
;              example:
;                Slice at the point x=0.5, y = 0.5 and z=0.1.
;                DISPLACEMENT = [0.5, 0.5. 0.1]
;
;Plotting Keywords:
;        LEVELS: Number of color contour levels to plot (default is 60)
;        OLINES: Number of contour lines to plot (default is 0)
;        CONTOURS_OPLOT: Boolean indicating to only plot contours, not the data.
;           this is especially useful if you're interested in plotting
;           2-d or 3-d interpolated contours onto plots using geometric
;           interpolation; requires an already existing 2d slice plot
;        ZLOG: Boolean indicating logarithmic contour scaling (on by default)
;        ECIRCLE: Boolean to plot circle(s) designating min/max energy
;           from distribution (on by default)
;        SUNDIR: Boolean to plot the projection of scaled sun direction (black line).
;          Requires GET_SUN_DIRECTION set with spd_dist_array.
;        PLOTAXES: Boolean to plot x=0 and y=0 axes (on by default)
;        PLOTBULK: Boolean to plot projection of bulk velocity vector (red line).
;            (on by default)
;        PLOTORIGIN: Boolean to plot a new origin at the bulk velocity and/or sun location
;              instead of plotting the projection
;        PLOTBFIELD: Boolean to plot projection of scaled B field (cyan line).
;              Requires B field data to be loaded and specified to
;              spd_slice2d with mag_data keyword.
;
;        TITLE: String used as plot's title
;        SHORT_TITLE: Flag to only use time range and # of samples for title
;        CLABELS: Boolean to annotate contour lines.
;        CHARSIZE: Specifies character size of annotations (1 is normal)
;        [XYZ]RANGE: Two-element array specifying x/y/z axis range.
;        [XYZ]TICKS: Integer(s) specifying the number of ticks for each axis
;        [XYZ]PRECISION: Integer specifying annotation precision (sig. figs.).
;                  Set to zero to truncate printed values to integers.
;        [XYZ]STYLE: Integer specifying annotation style:
;             Set to 0 (default) for style to be chosen automatically.
;             Set to 1 for decimal annotations only ('0.0123')
;             Set to 2 for scientific notation only ('1.23e-2')
;        [B,V,SUN]_COLOR: Specify the color of the corresponding support vector.
;                   (e.g. "b_color=0", see IDL graphics documentation for options)
;        NOCOLORBAR: Suppress z axis color bar.
;
;        PLOTSIZE: The size of the plot in device units (usually pixels)
;            (Not implemented for postscript).
;
;        CUSTOM:  Flag that to disable automatic window creation and allow
;           user-controlled plots.
;
;        BACKGROUND_COLOR_INDEX: Integer (0-255) specifying a custom background color
;           where data = 0.0
;
;        BACKGROUND_COLOR_RGB: 3D array of integers (0-255) representing RGB values
;            of the background color where data == 0.0; this keyword modifies the
;            current color table to include this color at index = 7
;
;Exporting keywords:
;        EXPORT: String designating the path and file name of the desired file.
;          The plot will be exported to a PNG image by default.
;        EPS: Boolean indicating that the plot should be exported to
;          encapsulated postscript.
;       
;Interpolation Methods:
;
;   3D Interpolation:
;     The entire 3-dimensional distribution is linearly interpolated onto a
;     regular 3d grid and a slice is extracted from the volume.
;
;   2D Interpolation:
;     Datapoints within the specified theta or z-axis range are projected onto
;     the slice plane and linearly interpolated onto a regular 2D grid.
;
;   Geometric (default):
;     Each point on the plot is given the value of the bin it intersects.
;     This allows bin boundaries to be drawn at high resolutions.
; 
; Examples:
;         You can find examples in the following crib sheets:
;         
;         mms/examples/advanced/mms_slice2d_fpi_crib.pro
;         mms/examples/advanced/mms_slice2d_hpca_crib.pro
;
; Notes:
;         This routine always centers the distribution/moments data
;         
;         Default interpolation changed to geometric (from 3D), egrimes, 27Feb2020
;           (requested by the FPI team at last year's GEM)
;         
;$LastChangedBy: egrimes $
;$LastChangedDate: 2021-04-13 14:39:50 -0700 (Tue, 13 Apr 2021) $
;$LastChangedRevision: 29878 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_slice2d.pro $
;-

pro mms_part_slice2d, time=time, probe=probe, level=level, data_rate=data_rate, species=species, instrument=instrument, $
                      trange=trange, subtract_bulk=subtract_bulk, spdf=spdf, rotation=rotation, output=output, $
                      units=units, subtract_error=subtract_error, plotbulk=plotbulk, plotsun=plotsun, fgm_data_rate=fgm_data_rate, $
                      correct_photoelectrons=correct_photoelectrons, geometric=geometric, two_d_interp=two_d_interp, $
                      three_d_interp=three_d_interp, perp_subtract_bulk=perp_subtract_bulk, _extra=_extra

    start_time = systime(/seconds)
  
    if undefined(time) then begin
      if ~keyword_set(trange) then begin
        trange = timerange()
      endif else trange = timerange(trange)
    endif else trange = time_double(time)+[-60, 60]

    if undefined(instrument) then instrument = 'fpi' else instrument = strlowcase(instrument)
    if undefined(species) then begin
      if instrument eq 'fpi' then species = 'e'
      if instrument eq 'hpca' then species = 'hplus'
    endif
    if undefined(data_rate) then begin
      if instrument eq 'fpi' then data_rate = 'fast'
      if instrument eq 'hpca' then data_rate = 'srvy'
    endif

    if keyword_set(correct_photoelectrons) && (instrument ne 'fpi' or species ne 'e') then begin
      dprint, dlevel=0, 'Photoelectron corrections only valid for FPI electron data'
      return
    endif
    
    if undefined(two_d_interp) && undefined(three_d_interp) then geometric = 1b
    
    if undefined(fgm_data_rate) then fgm_data_rate = data_rate eq 'brst' ? 'brst' : 'srvy'
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    if undefined(rotation) then rotation = 'xy'
    
    if ~in_set(rotation, ['xy', 'yz', 'xz']) then load_support = 1b else load_support = 0b
    if keyword_set(subtract_bulk) || keyword_set(perp_subtract_bulk) then load_support = 1b ; need support data for bulk velocity subtraction as well
    if keyword_set(plotbulk) then load_support = 1b 
    if keyword_set(plotsun) then begin
       if ~spd_data_exists('mms'+probe+'_mec_r_sun_de421_gse', trange[0], trange[1]) then mms_load_mec, trange=trange, probe=probe, spdf=spdf, /time_clip
       ; need to convert J2000 ECI data to GSE
       spd_cotrans, 'mms'+probe+'_mec_r_sun_de421_eci', 'mms'+probe+'_mec_r_sun_de421_gse', out_coord='gse'
       sname = 'mms'+probe+'_mec_r_sun_de421_gse'
    endif
    
    
    bname = 'mms'+probe+'_fgm_b_gse_'+fgm_data_rate+'_l2_bvec'
    if load_support && ~spd_data_exists(bname, trange[0], trange[1]) then mms_load_fgm, trange=trange, probe=probe, spdf=spdf, data_rate=fgm_data_rate, /time_clip, varformat='*_fgm_b_gse_*
    
    if instrument eq 'fpi' then begin
      name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate
      vname = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate
      if keyword_set(subtract_error) then error_variable = 'mms'+probe+'_d'+species+'s_disterr_'+data_rate
      if ~spd_data_exists(name, trange[0], trange[1]) then mms_load_fpi, datatype='d'+species+'s-dist', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf, /time_clip, varformat='*_d'+species+'s_dist_* *s_disterr_* *_d?s_startdelphi_count_* *_d?s_steptable_parity*'
      if load_support && ~spd_data_exists(vname, trange[0], trange[1]) then mms_load_fpi, datatype='d'+species+'s-moms', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf, /time_clip, varformat='*_d'+species+'s_bulkv_gse_* *s_bulkv_spintone_gse_*'
    endif else if instrument eq 'hpca' then begin
      name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'
      vname = 'mms'+probe+'_hpca_'+species+'_ion_bulk_velocity'
      if ~spd_data_exists(name, trange[0], trange[1]) then mms_load_hpca, datatype='ion', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf, /time_clip, varformat='*_hpca_'+species+'_phase_space_density *_hpca_azimuth_angles_per_ev_degrees', /major_version
      if load_support && ~spd_data_exists(vname, trange[0], trange[1]) then mms_load_hpca, datatype='moments', data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf, /time_clip, varformat='*_hpca_'+species+'_ion_bulk_velocity', /major_version
    endif else begin
      dprint, dlevel=0, 'Error, unknown instrument; valid options are: fpi, hpca'
      return
    endelse

    if keyword_set(correct_photoelectrons) then begin
      dist = mms_fpi_correct_photoelectrons(name, probe=probe, subtract_error=subtract_error, error=error_variable, /structure)
    endif else dist = mms_get_dist(name, instrument=instrument, probe=probe, trange=trange, subtract_error=subtract_error, error=error_variable, /structure)
    
    if keyword_set(units) then begin
      for dist_idx=0, n_elements(dist)-1 do begin
        mms_convert_flux_units, dist[dist_idx], units=units, output=dist_tmp
        append_array, dist_out, dist_tmp
      endfor
    endif else dist_out = dist

    if ~undefined(time) then undefine, trange

    if load_support then slice = spd_slice2d(dist_out, time=time, trange=trange, rotation=rotation, mag_data=bname, vel_data=vname, sun_data=sname, subtract_bulk=subtract_bulk, perp_subtract_bulk=perp_subtract_bulk, geometric=geometric, two_d_interp=two_d_interp, three_d_interp=three_d_interp, _extra=_extra) $ 
      else slice = spd_slice2d(dist_out, time=time, trange=trange, rotation=rotation, sun_data=sname, subtract_bulk=subtract_bulk, perp_subtract_bulk=perp_subtract_bulk, geometric=geometric, two_d_interp=two_d_interp, three_d_interp=three_d_interp, _extra=_extra)
    
    spd_slice2d_plot, slice, plotbulk=plotbulk, sundir=plotsun, _extra=_extra
    output=slice
end