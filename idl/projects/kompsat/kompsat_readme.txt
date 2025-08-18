This is a plugin for the GEO-KOMPSAT-2A satellite (geostationary orbit at 128.2 East).

It can download data from the ESA HAPI server. Four datasets are available:

1. recalib (recalibrated data from the SOSMAG magnetometer)
2. 1m (1minute real-time data from the SOSMAG magnetometer)
3. p (proton flux from the particle detector)
4. e (electron flux from the particle detector)

For more information about SOSMAG, see:
https://swe.ssa.esa.int/sosmag
https://link.springer.com/article/10.1007/s11214-020-00742-2

For summary plots, see:
http://themis.ssl.berkeley.edu/summary.php?year=2023&month=09&day=04&hour=0024&sumType=kompsat&type=sosmag


The ESA HAPI server requires registration.
After registering, the user should edit the file kompsat_password.txt, replacing the values with his username and password.

The user can load data using kompsat_load_data.pro, which requires IDL 9.1 or later.
For earlier versions of IDL, the user can download data as CSV files and then load these CSV files into tplot using kompsat_load_csv.pro 

