This is a plugin for the magnetometer data of the SOSMAG (Service Oriented Spacecraft Magnetometer) instrument 
aboard the GEO-KOMPSAT-2A satellite (geostationary orbit at 128.2 East). 

For more information about SOSMAG, see:
https://swe.ssa.esa.int/sosmag
https://link.springer.com/article/10.1007/s11214-020-00742-2

For summary plots, see:
http://themis.ssl.berkeley.edu/summary.php?year=2023&month=09&day=04&hour=0024&sumType=kompsat&type=sosmag


Currently, IDL cannot directly access data in the ESA HAPI server because of incombatibilities of IDL 
with the authentication method used in the ESA HAPI server.

However, the user can manually download data as a CSV file and then load this data into SPEDAS using:

sosmag_load_csv, filename, tformat=tformat, desc=desc, prefix=prefix, suffix=suffix


To download data as csv files, the user can use a web browser with the ESA HAPI web server.
For example, the following URL downloads calibrated data (data product esa_gk2a_sosmag_recalib) for 2021/01/31 1am to 2am UTC:
https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_recalib&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv

And the following downloads real-time data (data product esa_gk2a_sosmag_1m):
https://swe.ssa.esa.int/hapi/data?id=spase://SSA/NumericalData/GEO-KOMPSAT-2A/esa_gk2a_sosmag_1m&time.min=2021-01-31T01:00:00.000Z&time.max=2021-01-31T02:00:00.000Z&format=csv
