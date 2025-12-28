close all; clear; clc;

xlsxPath = "Energy demand - dynamic (2025-11-04) v1.4.xlsx";
sheet    = "Hourly";

firstDataRow = 5;
lastDataRow  = 8764;

C_AG = readcell(xlsxPath, "Sheet", sheet, "Range", "A" + firstDataRow + ":G" + lastDataRow);
C_Q  = readcell(xlsxPath, "Sheet", sheet, "Range", "AM" + firstDataRow + ":AM" + lastDataRow);

n = size(C_AG,1);
AG = nan(n,7);
for j = 1:7
    col = C_AG(:,j);

    numMask = cellfun(@(x) isnumeric(x) && isscalar(x), col);
    if any(numMask)
        AG(numMask,j) = cell2mat(col(numMask));
    end

    txtMask = ~numMask & ~cellfun(@isempty, col);
    if any(txtMask)
        AG(txtMask,j) = str2double(strtrim(string(col(txtMask))));
    end
end

Q_SOL = nan(n,1);
numMask = cellfun(@(x) isnumeric(x) && isscalar(x), C_Q);
if any(numMask)
    Q_SOL(numMask) = cell2mat(C_Q(numMask));
end
txtMask = ~numMask & ~cellfun(@isempty, C_Q);
if any(txtMask)
    Q_SOL(txtMask) = str2double(strtrim(string(C_Q(txtMask))));
end

YEAR              = AG(:,1);
MONTH             = AG(:,2);
DAY               = AG(:,3);
HOUR_MET          = AG(:,4);
HOUR              = AG(:,5);
T0                = AG(:,7);

df  = table(YEAR,MONTH,DAY,HOUR_MET,HOUR,T0,Q_SOL);

save("HourlyEnergyData.mat", "df");
fprintf("Saved in: '%s'\n", fullfile(pwd,"HourlyEnergyData.mat"));