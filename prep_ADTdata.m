%% Prep ADT data and find gyre-gyre boundary
% Step 1: Prep data
%           -read in netcdf file with ADT data 
%           -calculate weekly averages of absolute dynamic topography
%           -save monthly adt data as 3D array [lon, lat, year-month datetime]
% Step 2: Find gyre-gyre boundary for each year-month
%           -use 55 cm contour to find lat/lon coordinates of gyre-gyre boundary
%           -remove all other coordinates
%           -save as 4D array: [lon,lat,lon360] stacked for each year-month
%           where third and fourth dimensions specify year and month           

% Written by A. Favilla 
% Created 27-Aug-2024

%% Prep directories
clear
infolder=uigetdir; % Select folder where adt data is stored
cd(infolder)

fig_output=input("Plot and save figures? [Y/N] : ","s"); 
if fig_output=="Y"
    disp('Select folder to save figures')
    figfolder=uigetdir();
end

%% Read in netcdf file with ADT data and save monthly means -- ONLY need to do this once! 

ncname='cmems_obs-sl_glo_phy-ssh_my_allsat-l4-duacs-0.125deg_P1D_adt_165.06E-239.94E_25.06N-61.94N_2004-01-01-2023-06-30.nc'; 
% ncname='cmems_obs-sl_glo_phy-ssh_my_allsat-l4-duacs-0.25deg_P1D_multi-vars_150.12E-259.88E_10.12N-64.88N_2004-01-01-2021-12-31.nc'; 
% ncdisp(ncname)
info=ncinfo(ncname); 

lon = ncread(ncname,'longitude'); % [150, 260] step=0.125
lat = ncread(ncname,'latitude'); % [10, 65] step=0.125
lon = double(lon); lat = double(lat); 
time = ncread(ncname,'time'); % 'days since 1950-01-01 00:00:00'
date = datetime('1950-01-01','InputFormat','yyyy-MM-dd')+days(time); % days since 1950-01-01
adt = ncread(ncname, 'adt'); % dim: [lon, lat, date]
adt = adt*100; % convert from m to cm

[y,m,d,H,M,S] = datevec(date); 
unique_y=unique(y); 
weekofyear = week(date); 

% Calculate weekly mean ADT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

adt_weekly = NaN(length(lon),length(lat),length(unique_y)*53); 
adt_weekly_std = NaN(length(lon),length(lat),length(unique_y)*53); 
year_month_week = NaN(length(unique_y)*53,3); 
n=1; 
for i=1:length(unique_y)
    for j=1:53
        idx = find(y==unique_y(i) & weekofyear==j); 
        adt_weekly(:,:,n) = mean(adt(:,:,idx),3); 
        adt_weekly_std(:,:,n) = std(adt(:,:,idx),[],3); 
        year_month_week(n,1)=unique_y(i); 
        year_month_week(n,2)=mode(month(date(idx))); 
        year_month_week(n,3)=j; 
        n=n+1; 
    end
end
adt_weekly=round(adt_weekly); 
% since data for 2023 only goes through June (week 26)
% so remove weeks 27-53 of 2023
nan_idx = find(isnan(year_month_week(:,2))); 
year_month_week(nan_idx,:)=[];
adt_weekly(:,:,nan_idx)=[]; 
adt_weekly_std(:,:,nan_idx)=[]; 

% Save in mat file
save(strcat(infolder ,'\ADT_weekly.mat'),"adt_weekly","adt_weekly_std","year_month_week","lat","lon"); 

%% Find gyre-gyre boundary for each year-week
% Use 55 cm contour (see Hristova et al. 2019)

clearvars -except infolder fig_output figfolder

if fig_output=='Y'
    load(strcat(infolder ,'\Contour55colormap.mat')); 
end

% Read in ADT_weekly.mat 
load(strcat(infolder ,'\ADT_weekly.mat')); 

unique_y = unique(year_month_week(:,1)); 
[LAT,LON]=meshgrid(lat,lon);

% Pre-allocate 4D array
GGB=NaN(1000,3,length(unique_y),53); 

tic
for k=1:size(adt_weekly,3)
    clear C C_keep breakpts breakpts_lat breakpts_lon

    hFig = figure('Visible','off'); 
    C=contourm(LAT,LON,adt_weekly(:,:,k),[55 55],'white','LineWidth',1); close(hFig); 

    % Find 55 cm contour:
    % output C from contourm contains coordinates of where 55cm contour occurs (longitude in first row, latitude in second row)
    C=C'; % change from rows to columns [lon, lat]
    % Add column of Lon360
    minusLon=find(C(:,1)<0);
    C(:,3)=C(:,1);
    C(minusLon,3)=C(minusLon,3)+360; % columns [lon, lat, lon360]

    % Only keep coordinates that are between 30-50 deg lat and 165-230 deg lon
    C_keep=C(C(:,2)>30 & C(:,2)<50 & C(:,3)>165 & C(:,3)<230,:);
    C_keep(:,4)=[0;diff(C_keep(:,2))]; % columns [lon, lat, lon360, diff(lat)]
    C_keep(:,5)=[0;diff(C_keep(:,3))]; % columns [lon, lat, lon360, diff(lat), diff(lon360)]

    % Find where difference in consecutive latitudes is >=1 (i.e., breakpts_lat)
    C_keep(:,6)=0;
    C_keep(abs(C_keep(:,4))<1,6)=1; % columns [lon, lat, lon360, diff(lat), diff(lon360), keep_logical_lat]
    breakpts_lat=find(C_keep(:,6)==0);
    breakpts_lat=[1;breakpts_lat;size(C_keep,1)];

    % Find where difference in consecutive longitudes is >=2 (i.e., breakpts_lon)
    C_keep(:,7)=0;
    C_keep(abs(C_keep(:,5))<2,7)=1; % columns [lon, lat, lon360, diff(lat), diff(lon360), keep_logical_lat, keep_logical_lon]
    breakpts_lon=find(C_keep(:,7)==0);
    breakpts_lon=[1;breakpts_lon;size(C_keep,1)];

    % Combine lat and lon breakpts
    breakpts=[breakpts_lat;breakpts_lon];
    breakpts=unique(breakpts);

    % Only keep the longest sequence where difference in consecutive lat or lon are very small as defined above
    breakpts_length=diff(breakpts); % length between these breakpts
    max_length=find(breakpts_length==max(breakpts_length)); % index of longest sequence
    C_keep=C_keep(breakpts(max_length):breakpts(max_length+1)-1,:);
    
    % Save into GGB array
    Y=year_month_week(k,1);
    Y_idx=find(unique_y==Y);
    W=year_month_week(k,3);
    GGB(1:size(C_keep,1),:,Y_idx,W) = C_keep(:,1:3);

end
toc

% Find rows that contain non-NaN values in any of the other dimensions
rows_to_keep = any(~isnan(GGB), [2, 3, 4]);

% Extract only the rows that contain non-NaN data
GGB = GGB(rows_to_keep, :, :, :);

GGB_Years = [2004:2023]'; 
save(strcat(infolder ,'\SAFZ_weekly_2004_2023.mat'),"GGB_Years","GGB"); 
