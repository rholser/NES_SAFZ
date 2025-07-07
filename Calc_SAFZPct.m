load('Tracks_SAFZDist.mat')

% Remove all data with QC worse than 2
Tracks(Tracks.QCFlag >3,:) = [];

% Distance tresholds to test
d = [100;200;250;300;400;500];

% Longitudinal threshold to exclude coastal region (in 360 longitude)
lonMax = 230;

% List of TOOPPIDs that will be included
TOPPIDs = unique(Tracks.TOPPID);

% Preallocate table to write outputs into
GGB_Pct = table('Size',[size(TOPPIDs,1),12],'VariableTypes', ...
    {'double','double','double','double','double','double','double','string','double','string','string','double'}, ...
    'VariableNames',...
    {'TOPPID','Pct100km','Pct200km','Pct250km','Pct300km','Pct400km','Pct500km','Season','Year','Colony','SealID','TrackQC'});

GGB_NegPct = table('Size',[size(TOPPIDs,1),11],'VariableTypes', ...
    {'double','double','double','double','double','double','double','string','double','string','string'}, ...
    'VariableNames',...
    {'TOPPID','Pct100km','Pct200km','Pct250km','Pct300km','Pct400km','Pct500km','Season','Year','Colony','SealID'});

GGB_PosPct = table('Size',[size(TOPPIDs,1),11],'VariableTypes', ...
    {'double','double','double','double','double','double','double','string','double','string','string'}, ...
    'VariableNames',...
    {'TOPPID','Pct100km','Pct200km','Pct250km','Pct300km','Pct400km','Pct500km','Season','Year','Colony','SealID'});

% Loop through each TOPPID
for i=1:size(TOPPIDs,1)
    data = Tracks(Tracks.TOPPID==TOPPIDs(i),:);
    GGB_Pct.TOPPID(i) = TOPPIDs(i);
    GGB_Pct.SealID(i) = data.SealID(1);
    GGB_Pct.Season(i) = data.Season(1);
    GGB_Pct.Colony(i) = data.Colony(1);
    GGB_Pct.Year(i) = data.Year(1);
    GGB_Pct.TrackQC(i) = data.QCFlag(1);
    GGB_NegPct.TOPPID(i) = TOPPIDs(i);
    GGB_NegPct.SealID(i) = data.SealID(1);
    GGB_NegPct.Season(i) = data.Season(1);
    GGB_NegPct.Colony(i) = data.Colony(1);
    GGB_NegPct.Year(i) = data.Year(1);
    GGB_PosPct.TOPPID(i) = TOPPIDs(i);
    GGB_PosPct.SealID(i) = data.SealID(1);
    GGB_PosPct.Season(i) = data.Season(1);
    GGB_PosPct.Colony(i) = data.Colony(1);
    GGB_PosPct.Year(i) = data.Year(1);
% Loop through the distance thresholds in d and find the % of trip spent within d km of GGB
    for j=1:size(d,1)
        ind = find(data.Lon < lonMax & abs(data.GGBDist) < d(j));
        ind1 = find(data.Lon < lonMax & abs(data.GGBDist) < d(j) & data.GGBDist < 0);
        ind2 = find(data.Lon < lonMax & data.GGBDist < d(j) & data.GGBDist > 0);
        if ~isempty(ind)
            GGB_Pct{i,j+1} = size(ind,1)./size(data,1);
        else
        end
        if ~isempty(ind1)
            GGB_NegPct{i,j+1} = size(ind1,1)./size(ind,1);
        else
        end        
        if ~isempty(ind2)
            GGB_PosPct{i,j+1} = size(ind2,1)./size(ind,1);
        else
        end
    end
end

save('D:\Dropbox\GitHub\NES_SAFZ\Data\SAFZ_Pct.mat','GGB_Pct')
writetable(GGB_Pct,'D:\Dropbox\GitHub\NES_SAFZ\Data\SAFZ_Pct.csv')
