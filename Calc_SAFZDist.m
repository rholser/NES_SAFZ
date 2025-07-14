% Created by: R.Holser (rholser@ucsc.edu)
% Created on: 28-Aug-2024
%
% Calculates minimum distance to the gyre-gyre boundary based on the 55cm
% contour of monthly average Absolute Dynamic Topography.
%
% Update Log:
%
%

% Load ADT and Eseal data from previously compiled .mat files
load('SAFZ_weekly_2004_2023.mat');
load('NES_Tracks.mat')

% ADT data only exists through year 2023, remove extra years from Tracks
Tracks(Tracks.Year>2023,:)=[];
Daily(Daily.Year>2023,:)=[];

% Create a column in Tracks that contains the index for that data point's
% year within the ADT_contour55 array
[~,Tracks.YearADT(:)] = ismember(Tracks.Year, GGB_Years);
[~,Daily.YearADT(:)] = ismember(Daily.Year, GGB_Years);

Tracks.Week = week(Tracks.DateTime);
Daily.Week = week(Daily.DateTime);

% Create empty columns
Tracks.GGBDist(:) = NaN;
Tracks.GGBLat(:) = NaN;
Tracks.GGBLon360(:) = NaN;
Daily.GGBDist(:) = NaN;
Daily.GGBLat(:) = NaN;
Daily.GGBLon360(:) = NaN;

Daily.Month = month(Daily.DateTime(:));

tic
% Loop through each data point to find the shortest distance to the GGB
for i=1:size(Tracks,1)
    % Vectorized calculation of distance between lat lon points.
    % Calculated dist between the current data point and all boundary
    % locations for the relevant Year/Month combination
    [GGBDist,~] = lldistkm_vector([Tracks.Lat(i), Tracks.Lon(i)], ...
        [GGB(:,2,Tracks.YearADT(i),Tracks.Week(i)),GGB(:,1,Tracks.YearADT(i),Tracks.Week(i))]);
    % Keep the minimum distance and it's index
    [Tracks.GGBDist(i),ind]=min(GGBDist);
    % Use the index to pull out the closest boundary location
    Tracks.GGBLat(i) = GGB(ind,2,Tracks.YearADT(i),Tracks.Week(i));
    Tracks.GGBLon360(i) = GGB(ind,3,Tracks.YearADT(i),Tracks.Week(i));
    clear GGBDist ind
end
toc

tic
% Loop through each data point to find the shortest distance to the GGB
for i=1:size(Daily,1)
    % Vectorized calculation of distance between lat lon points.
    % Calculated dist between the current data point and all boundary
    % locations for the relevant Year/Month combination
    [GGBDist,~] = lldistkm_vector([Daily.Lat(i), Daily.Lon(i)], ...
        [GGB(:,2,Daily.YearADT(i),Daily.Week(i)),GGB(:,1,Daily.YearADT(i),Daily.Week(i))]);
    % Keep the minimum distance and it's index
    [Daily.GGBDist(i),ind]=min(GGBDist);
    % Use the index to pull out the closest boundary location
    Daily.GGBLat(i) = GGB(ind,2,Daily.YearADT(i),Daily.Week(i));
    Daily.GGBLon360(i) = GGB(ind,3,Daily.YearADT(i),Daily.Week(i));
    clear GGBDist ind
end
toc

%Make distances south of the GGB negative
Tracks.GGBDist(Tracks.GGBLat>Tracks.Lat) = -Tracks.GGBDist(Tracks.GGBLat>Tracks.Lat);
Daily.GGBDist(Daily.GGBLat>Daily.Lat) = -Daily.GGBDist(Daily.GGBLat>Daily.Lat);

% Save new Tracks file
writetable(Tracks,'D:\Dropbox\GitHub\NES_SAFZ\Data\Tracks_SAFZDist.csv')
writetable(Daily,'D:\Dropbox\GitHub\NES_SAFZ\Data\Daily_SAFZDist.csv')

