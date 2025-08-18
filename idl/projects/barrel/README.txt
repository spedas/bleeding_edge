README.txt (BARREL/TDAS), last updated December 23, 2013 (Karl Yando)

Description
-----------

This README contains instructions for installation and usage of TDAS analysis tools in the context of the BARREL 2012-2013 and 2013-2014 science campaigns.  

For general information regarding the BARREL project, see:

Millan, R.M., (et al).  "The Ballon Array for RBSP Relativistic Losses (BARREL),"  Space Science Reviews, 2013, ISSN 0038-6308, 10.1007/s11214-013-9971-z.

Millan, R.M., (et al).  "Understanding relativistic electron losses with BARREL,"  Journal of Atmospheric and Solar-Terrestrial Physics, Volume 73, Issues 11-12, July 2011, Pages 1425-1434, ISSN 1364-6826, 10.1016/j.jastp.2011.01.006.


Dependencies
-----------
Analysis code is written in the IDL programming language, and depends on the THEMIS TDAS data analysis package.  At the time of this writing, BARREL specific routines have been tested with IDL 7.1.1 and TDAS 8.00.


1. TDAS Installation
-----------
The latest version of TDAS, and a User's Guide containing platform-specific installation directions can be found at the THEMIS mission's software homepage: <http://themis.ssl.berkeley.edu/software.shtml>

NOTE: the BARREL-specific analysis routines require a CDF library that recognizes the CDF_TIME_TT2000 epoch type. 

At the time of this writing, this requires:
- an updated version of the CDF library for IDL: 
	http://cdf.gsfc.nasa.gov/html/cdf_patch_for_idl.html
- TDAS v8.00 or higher (NOTE: although not recommended, TDAS v7.xx may also be manually patched with the appropriate TT2000 routines)


2. Upgrading
-----------

After an update of the BARREL software package, it may be necessary to reset an local configuration.  This is accomplished by running:
IDL> barrel_init, /RESET


3. Setting up the BARREL/TDAS environment
-----------
The BARREL mission-specific data analysis routines enclosed in this directory may be placed in any convenient location.

The TDAS User's Guide will recommend that the user add the location of the local TDAS installation to their IDL PATH.  The same should be done for the location of the local BARREL data analysis routines. 

NOTE: I prefer an IDL script that adds the location to PATH at runtime.  The default PATH should include the directory containing this script.  This allows for multiple TDAS installations, or concurrent installations of conflicting software packages (e.g. SSW and TDAS), where only the desired package's PATH is loaded.   
    e.g., in a file named "load_tdas_lib.pro":
    PRO LOAD_TDAS_LIB
        pathsep = PATH_SEP(/SEARCH_PATH)
        
        ; specify location of TDAS install
        !PATH = !PATH + pathsep + EXPAND_PATH('+/path/to/tdas_8_00')

        ; specify location of BARREL analysis software install
        !PATH = !PATH + pathsep + EXPAND_PATH('+/path/to/barrel')
    END

The user may also specify a non-default location for the local data directory by setting the 'ROOT_DATA_DIR' environment variable.  For more information, see the documentation for /ssl_general/missions/root_data_dir.pro.


4. Usage
-----------
NOTE: BARREL-specific TDAS routines follow general TDAS conventions whenever possible, and it is recommended that the user review Section 2.5.3.1 "Plotting with Tplot", found in the "THEMIS Science Data Analysis Software (TDAS) Users' Guide", available at <http://themis.ssl.berkeley.edu/software.shtml>.

-- Usage:
Start IDL in the usual fashion.  Ensure that TDAS and BARREL installations are included in the !PATH variable. 

For help/documentation with any TDAS command, type:
IDL> doc_library, 'command_name'

Specifying a data range to load (also see "barrel_crib_basic_usage.pro") 
IDL> timespan, '2013-01-15', 2, /days   ; 2 days, starting Jan 15th, 2013

Selecting data (payload, data product, data level, etc).  TDAS will attempt
to fetch data from our CDF repository (internet connection required).
IDL> barrel_load_data, PROBE=['1D','1K'], DATATYPE=['FSPC'], LEVEL='l1'
IDL> ; Requests available fast spectral (lightcurve) data from 
IDL> ;  payloads 1D and 1K, at the L1 data level

List available (loaded) data 
IDL> tplot_names

Plot a TPLOT variable (e.g. 'variable_name')
IDL> tplot, 'variable_name'

Extract the contents of a TPLOT variable (e.g. 'variable_name')
IDL> get_data, 'variable_name', DATA=data_structure
IDL> ; data_structure.x will contain the abscissa (time values)
IDL> ; data_structure.y will contain the ordinate (data values)


Of note, it's also possible to wildcard many above arguments and keywords, using '?' to wildcard a single character, '*' to wildcard any number of characters, '[1-3]' to wildcard a single digit with any number in the range [1-3], etc.

For example, loading all available spectral data data:
IDL> barrel_load_data, PROBE='*', DATATYPE='?SPC'       ; matches FSPC,MSPC,SSPC

Plotting the three components of magnetometer data:
IDL> tplot, ['brl???_1D_MAG_?']         ; matches -MAG_X, -MAG_Y, -MAG_Z

Overplotting these same three components, in the same panel:
IDL> store_data, 'tdas_pseudovariable', DATA=['brl???_1D_MAG_?']
IDL> tplot, 'tdas_pseudovariable'

All of the usual IDL Direct Graphics plotting keyword parameters (e.g. PSYM, COLOR, LINESTYLE) are accessible through the 'options' command:
IDL> options, 'variable_name', 'psym', -4       ; set PSYM=-4 for the TPLOT variable whose handle is 'variable_name'


