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
figDir = fullfile(root,"figures");
if ~exist(figDir,"dir"), mkdir(figDir); end

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
% FIG 2 — Annual HVAC load (monthly x-axis, no title)
% ============================================================

% ---- Month definition (non-leap year) ----
days_in_month = [31 28 31 30 31 30 31 31 30 31 30 31];
month_names   = ["Jan","Feb","Mar","Apr","May","Jun", ...
                 "Jul","Aug","Sep","Oct","Nov","Dec"];

month_edges   = [0 cumsum(days_in_month)*24];
month_centers = month_edges(1:end-1) + diff(month_edges)/2;

f2 = figure("Units","pixels","Position",[140 120 1400 520],"Color",figBG);

QkW = Results.Q_LOAD(:)/1000;
idx_heat = QkW > 0;
idx_cool = QkW < 0;

ax = axes(f2); hold(ax,"on");

bar(ax, t(idx_heat), QkW(idx_heat), 1.0, ...
    "FaceColor","red", "EdgeColor","none");
bar(ax, t(idx_cool), QkW(idx_cool), 1.0, ...
    "FaceColor","blue","EdgeColor","none");

grid on; box on;
ylabel("HVAC load [kW]");
xlim([1 N]);

% --- ticks at month transitions (for grid alignment)
xticks(month_edges);
set(ax,"XTickLabel",[]);
ax.XGrid = "on"; ax.YGrid = "on";

% --- overlay axis for centred month labels
ax_lbl = axes("Position", ax.Position, ...
              "Color","none", ...
              "XAxisLocation","bottom", ...
              "YAxisLocation","right", ...
              "XLim", ax.XLim, ...
              "YLim", ax.YLim);

ax_lbl.XTick = month_centers;
ax_lbl.XTickLabel = month_names;
ax_lbl.YTick = [];
ax_lbl.Box = "off";
ax_lbl.XGrid = "off";
ax_lbl.YGrid = "off";
ax_lbl.TickLength = [0 0];
xlabel(ax_lbl,"Month of year");

legend(ax, {"Heating","Cooling"}, ...
       "Location","best", ...
       "Orientation","horizontal");

uistack(ax,"top");

exportgraphics(f2, fullfile(figDir,"Q5_annual_HVAC_load.png"), ...
               "Resolution", dpi);
%% ============================================================
% FIG 2b — Daily AVERAGE HVAC load (1 bar/day), monthly x-axis, no title
% ============================================================

% ---- Month definition (non-leap year) in DAYS ----
days_in_month = [31 28 31 30 31 30 31 31 30 31 30 31];
month_names   = ["Jan","Feb","Mar","Apr","May","Jun", ...
                 "Jul","Aug","Sep","Oct","Nov","Dec"];

month_edges_d   = [0 cumsum(days_in_month)];                 % day boundaries
month_centers_d = month_edges_d(1:end-1) + diff(month_edges_d)/2;

% ---- Build daily means (kW) ----
QkW = Results.Q_LOAD(:)/1000;

ndays = floor(numel(QkW)/24);
QkW = QkW(1:ndays*24);

Qmat = reshape(QkW, 24, ndays);          % 24 x ndays
Qday_avg = mean(Qmat, 1, "omitnan")';    % ndays x 1

d = (1:ndays)';                          % day index (1..365)

idx_heat_d = Qday_avg > 0;
idx_cool_d = Qday_avg < 0;

% ---- Plot + export ----
f2b = figure("Units","pixels","Position",[140 120 1400 520],"Color",figBG);

ax = axes(f2b); hold(ax,"on");

bh = bar(ax, d(idx_heat_d), Qday_avg(idx_heat_d), 1.0, ...
    "FaceColor","red", "EdgeColor","none");
bh.FaceAlpha = 0.6;

bc = bar(ax, d(idx_cool_d), Qday_avg(idx_cool_d), 1.0, ...
    "FaceColor","blue","EdgeColor","none");
bc.FaceAlpha = 0.6;

grid on; box on;
ylabel("Daily average HVAC load [kW]");
xlim([1 ndays]);

% --- ticks at month transitions (for vertical grid alignment)
xticks(month_edges_d + 1);       % +1 because day index starts at 1
set(ax,"XTickLabel",[]);
ax.XGrid = "on"; ax.YGrid = "on";

% --- overlay axis for centred month labels
ax_lbl = axes("Position", ax.Position, ...
              "Color","none", ...
              "XAxisLocation","bottom", ...
              "YAxisLocation","right", ...
              "XLim", ax.XLim, ...
              "YLim", ax.YLim);

ax_lbl.XTick = month_centers_d + 1;
ax_lbl.XTickLabel = month_names;
ax_lbl.YTick = [];
ax_lbl.Box = "off";
ax_lbl.XGrid = "off";
ax_lbl.YGrid = "off";
ax_lbl.TickLength = [0 0];
xlabel(ax_lbl, "Month of year");

legend(ax, {"Heating","Cooling"}, "Location","best", "Orientation","horizontal");
uistack(ax,"top");

exportgraphics(f2b, fullfile(figDir,"Q5_dailyAvg_HVAC_load.png"), "Resolution", dpi);

close all;