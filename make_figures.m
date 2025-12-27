% ============================================================
% make_figures_Q5.m
% Export figures (PNG, high-res) for LaTeX report
% ============================================================

close all; clear; clc;

S = load("AS3B_Q5_Results.mat","Results","p","E_heat_kWh","E_cool_kWh");
Results   = S.Results;
p         = S.p;
E_heat_kWh = S.E_heat_kWh;
E_cool_kWh = S.E_cool_kWh;

% ---- Output folder ----
outDir = fullfile(pwd,"figures");
if ~exist(outDir, "dir"), mkdir(outDir); end

% ---- Export settings ----
dpi = 600;                 % good for LaTeX
figBG = "white";

% ---- Colors (match your current palette) ----
col_glass = [0.90 0.15 0.15];
col_air   = [0.10 0.40 0.80];
col_wall3 = [0.80 0.70 0.10];
col_wall4 = [0.55 0.20 0.70];
col_out   = [0.20 0.60 0.20];

% Convenience
t = Results.HOUR_CUM(:);
N = numel(t);

% ---- Font settings (LaTeX-friendly) ----
set(groot, ...
    "defaultAxesFontSize",        14, ...
    "defaultTextFontSize",        14, ...
    "defaultAxesLabelFontSizeMultiplier", 1.1, ...
    "defaultAxesTitleFontSizeMultiplier", 1.2, ...
    "defaultLegendFontSize",      9);




%% ============================================================
% FIG 3 — Daily profiles (temps + solar + HVAC) for a selected day
% ============================================================
day_to_plot = 15;  % change this later if you want

i_start = (day_to_plot-1)*24;
i_end   = day_to_plot*24;

idx = (t >= i_start) & (t <= i_end);

T0_day  = Results.T0(idx);
T1_day  = Results.T1(idx);
T2_day  = Results.T2(idx);
T3_day  = Results.T3(idx);
T4_day  = Results.T4(idx);

QkW_day  = Results.Q_LOAD(idx)/1000;
Qsol_day = Results.Q_SOL(idx);

% Your time alignment convention (endpoints vs midpoints)
t_end = 0:24;
t_mid = 0.5:1:23.5;

QkW_mid  = QkW_day(2:end);
Qsol_mid = Qsol_day(2:end);

idx_heat = QkW_mid > 0;
idx_cool = QkW_mid < 0;

f3 = figure("Units","pixels","Position",[220 60 980 980],"Color",figBG);
tlo3 = tiledlayout(f3, 2, 1, "TileSpacing","compact", "Padding","compact");

% --- Tile 1: Temperatures ---
a1 = nexttile(tlo3); hold(a1,"on");
plot(a1, t_end, T1_day, "LineWidth",1.4, "Color",col_glass);
plot(a1, t_end, T2_day, "LineWidth",1.4, "Color",col_air);
plot(a1, t_end, T3_day, "LineWidth",1.4, "Color",col_wall3);
plot(a1, t_end, T4_day, "LineWidth",1.4, "Color",col_wall4);
plot(a1, t_end, T0_day, "LineWidth",1.4, "Color",col_out);
grid(a1,"on"); box(a1,"on");
ylabel(a1,"Temperature [°C]");
title(a1, sprintf("Daily profiles — Day %d", day_to_plot));
xlim(a1,[0 24]); xticks(a1,0:1:24);
legend(a1, {"T_1 (glass)","T_2 (air)","T_3","T_4","T_{out}"}, "Location","best");

% --- Tile 2: Combined bars (HVAC + People gains + Solar) ---
a2 = nexttile(tlo3);
hold(a2,"on"); box(a2,"on");

% Units (kW)
Qsol_kW = Qsol_mid/1000;     % keep unless Qsol_mid already in kW

% People gains: NP * 100 W -> kW (aligned with midpoints)
NP_mid = Results.NP(idx);     % same idx used for the day window
NP_mid = NP_mid(2:end);       % align with t_mid (23.5 points)
Qppl_kW = (NP_mid * 100) / 1000;   % = 0.1*NP_mid

idx_ppl = Qppl_kW > 0;

% 1) HVAC bars (background)
bh = bar(a2, t_mid(idx_heat), QkW_mid(idx_heat), 1.0, ...
    "FaceColor","red", "EdgeColor","none");
bh.FaceAlpha = 0.6;

bc = bar(a2, t_mid(idx_cool), QkW_mid(idx_cool), 1.0, ...
    "FaceColor","blue", "EdgeColor","none");
bc.FaceAlpha = 0.6;

% 2) People heating (in front of HVAC, behind solar)
bp = bar(a2, t_mid(idx_ppl), Qppl_kW(idx_ppl), 1.0, ...
    "FaceColor",[0.7 0.7 0.7], "EdgeColor","none");
bp.FaceAlpha = 0.85;

% 3) Solar gains (foreground, not summed)
bs = bar(a2, t_mid, Qsol_kW, 1.0, ...
    "FaceColor",[0.95 0.85 0.20], "EdgeColor","none");
bs.FaceAlpha = 1.0;

% Make sure layering is exactly as requested
uistack(bh,"bottom");
uistack(bc,"bottom");
uistack(bp,"top");
uistack(bs,"top");

grid(a2,"on");
ylabel(a2,"Power [kW]");
xlim(a2,[0 24]); xticks(a2,0:1:24);
xlabel(a2,"Hour of day");

legend(a2, [bh bc bp bs], ...
    {"Heating (kW)","Cooling (kW)","People gains (kW)","Solar gains (kW)"}, ...
    "Location","best", "Orientation","vertical");

exportgraphics(f3, fullfile(outDir, sprintf("Q5_day%02d_profiles.png",day_to_plot)), "Resolution", dpi);

%% ============================================================
% Done
% ============================================================
fprintf("Saved figures to: %s\n", outDir);
close all;