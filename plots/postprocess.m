close all; clear; clc;

this = fileparts(mfilename("fullpath"));
root = fileparts(this);

addpath(genpath(fullfile(root,"src")));
addpath(genpath(fullfile(root,"plots")));

S = load(fullfile(root,"results","AS3B_Q5_Results.mat"),"Results","p","in");
Results = S.Results;
p = S.p;
in = S.in;

E_heat_kWh = sum(max(Results.Q_LOAD,0), "omitnan")/1000;
E_cool_kWh = sum(max(-Results.Q_LOAD,0), "omitnan")/1000;

fprintf("\n==== ANNUAL ENERGY ====\n");
fprintf("Annual heating demand: %.1f kWh\n", E_heat_kWh);
fprintf("Annual cooling demand: %.1f kWh\n", E_cool_kWh);

fprintf('\n==== GLOBAL TEMPERATURE CHECKS ====\n');
fprintf('T0   min/max: %.1f / %.1f °C\n', min(Results.T0), max(Results.T0));
fprintf('T2   min/max: %.1f / %.1f °C\n', min(Results.T2), max(Results.T2));
fprintf('T3   min/max: %.1f / %.1f °C\n', min(Results.T3), max(Results.T3));
fprintf('T4   min/max: %.1f / %.1f °C\n', min(Results.T4), max(Results.T4));

idx_unocc = in.NP == 0;
idx_occ   = ~idx_unocc;

fprintf('\n==== TEMPERATURE STATS (OCC vs UNOCC) ====\n');
fprintf('T2 occupied   mean/min/max: %.2f / %.2f / %.2f °C\n', ...
    mean(Results.T2(idx_occ)), min(Results.T2(idx_occ)), max(Results.T2(idx_occ)));
fprintf('T2 unoccupied mean/min/max: %.2f / %.2f / %.2f °C\n', ...
    mean(Results.T2(idx_unocc)), min(Results.T2(idx_unocc)), max(Results.T2(idx_unocc)));

idx_hot  = idx_unocc & Results.T2 > p.T_cool_unocc + 0.1;
idx_cold = idx_unocc & Results.T2 < p.T_heat_unocc - 0.1;

fprintf('\n==== UNOCCUPIED SETPOINT VIOLATIONS ====\n');
fprintf('Hours above T_cool_unocc (%.1f °C): %d\n', p.T_cool_unocc, nnz(idx_hot));
fprintf('Hours below T_heat_unocc (%.1f °C): %d\n', p.T_heat_unocc, nnz(idx_cold));

marg = 0.5;
idx_hot_near  = idx_unocc & Results.T2 > p.T_cool_unocc - marg;
idx_cold_near = idx_unocc & Results.T2 < p.T_heat_unocc + marg;

fprintf('\n==== NEAR SETPOINT (UNOCC ± %.1f °C) ====\n', marg);
fprintf('Hours near upper limit: %d\n', nnz(idx_hot_near));
fprintf('Hours near lower limit: %d\n', nnz(idx_cold_near));

fprintf('\n==== HVAC ACTION CHECK (UNOCC HOT HOURS) ====\n');
if any(idx_hot)
    ii = find(idx_hot,5,'first');
    disp(table( ...
        ii, ...
        Results.HOUR_CUM(ii), ...
        Results.T2(ii), ...
        Results.Q_LOAD(ii), ...
        Results.Q_SOL(ii), ...
        in.NP(ii), ...
        'VariableNames',{'idx','hour','T2','Qload_W','Qsol_W','NP'}));
else
    disp('No unoccupied overheating detected.');
end

fprintf('\n==== HVAC DURING UNOCCUPIED ====\n');
fprintf('Hours HVAC ON while unoccupied: %d\n', nnz(idx_unocc & abs(Results.Q_LOAD) > 1e-3));

fprintf('\n==== PEAK HEATING / COOLING ====\n');
Q = Results.Q_LOAD;

[Qheat_peak, iH] = max(Q);
if Qheat_peak > 0
    fprintf('Peak HEATING: %.2f kW at hour_cum = %d (hour_day = %d)\n', ...
        Qheat_peak/1000, Results.HOUR_CUM(iH), mod(Results.HOUR_CUM(iH)-1,24));
    disp(table(Results.HOUR_CUM(iH), Results.T0(iH), Results.T2(iH), Results.Q_SOL(iH)/1000, in.NP(iH), Q(iH)/1000, ...
        'VariableNames', {'hour_cum','T0','T2','Qsol_kW','NP','Qheat_kW'}));
else
    disp('No heating occurred (Q_LOAD never > 0).');
end

[Qcool_peak, iC] = max(-Q);
if Qcool_peak > 0
    fprintf('Peak COOLING: %.2f kW at hour_cum = %d (hour_day = %d)\n', ...
        Qcool_peak/1000, Results.HOUR_CUM(iC), mod(Results.HOUR_CUM(iC)-1,24));
    disp(table(Results.HOUR_CUM(iC), Results.T0(iC), Results.T2(iC), Results.Q_SOL(iC)/1000, in.NP(iC), (-Q(iC))/1000, ...
        'VariableNames', {'hour_cum','T0','T2','Qsol_kW','NP','Qcool_kW'}));
else
    disp('No cooling occurred (Q_LOAD never < 0).');
end

fprintf('\n==== SOLAR vs HVAC ====\n');
idx_solar_dom = abs(Results.Q_SOL) > abs(Results.Q_LOAD);
idx_hvac_dom  = abs(Results.Q_LOAD) > abs(Results.Q_SOL);
fprintf('Hours solar-dominated: %d\n', nnz(idx_solar_dom));
fprintf('Hours HVAC-dominated : %d\n', nnz(idx_hvac_dom));

fprintf('\n==== WORST 5 HOURS (ABS LOAD) ====\n');
[~,ix] = maxk(abs(Results.Q_LOAD),5);
disp(table( ...
    ix, ...
    Results.HOUR_CUM(ix), ...
    mod(Results.HOUR_CUM(ix)-1,24), ...
    Results.T0(ix), ...
    Results.T2(ix), ...
    Results.Q_LOAD(ix)/1000, ...
    Results.Q_SOL(ix)/1000, ...
    in.NP(ix), ...
    'VariableNames',{'idx','hour_cum','hour_day','T0','T2','Q_kW','Qsol_kW','NP'}));
