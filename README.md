# NES_SAFZ
[![DOI](https://zenodo.org/badge/1015169581.svg)](https://doi.org/10.5281/zenodo.15833168)

Code associated with analysis of movement and foraging success of northern elephant seals in relation to the subarctic frontal zone (SAFZ).

Processed data used in the code provided here are available through this Dryad repository: 

Raw elephant seal movement data are publicly available through Dryad respositories https://doi.org/10.7291/D1W101 and https://doi.org/10.7291/D18D7W. 

Scripts were written in both R and MATLAB to accomplish the following objectives:

  1. Extract contours of the subarctic frontal zone (prepADTdata) <--Matlab
  2. Calculate distance from each elephant seal location to the nearest SAFZ contour (Calc_SAFZDist, Calc_SAFZPct) <--Matlab
  3. Determine distributions of seal movement from the SAFZ and from 43 degrees latitude (SAFZ_LatDistribution) <--R
  4. Model relationship between SAFZ and diel diving behavior (SAFZ_Analyses) <--R
  5. Model relationship between SAFZ and foraging success (SAFZ_ForagingSuccess) <--R

