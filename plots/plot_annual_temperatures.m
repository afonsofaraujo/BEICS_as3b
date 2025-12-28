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



%%

%% ============================================================
% FIG 1 — Annual temperatures (month transitions + centered labels)
% ============================================================

% ---- Month definition (non-leap year) ----
days_in_month = [31 28 31 30 31 30 31 31 30 31 30 31];
month_names   = ["Jan","Feb","Mar","Apr","May","Jun", ...
                 "Jul","Aug","Sep","Oct","Nov","Dec"];

month_edges   = [0 cumsum(days_in_month)*24];           % month boundaries
month_centers = month_edges(1:end-1) + diff(month_edges)/2;


f1 = figure("Units","pixels","Position",[80 60 1400 900],"Color",figBG);

% ---------- T0 ----------
tlo = tiledlayout(5,1, ...
    "TileSpacing","compact", ...
    "Padding","loose");

ax1 = nexttile;
plot(t, Results.T0, "LineWidth",1.1, "Color",col_out);
grid on; box on;
ylabel("T_0 [°C]");
xlim([1 N]);
xticks(month_edges(2:end-1));
set(ax1,"XTickLabel",[]);
ax1.XGrid = "on"; ax1.YGrid = "on";

% ---------- T1 ----------
ax2 = nexttile;
plot(t, Results.T1, "LineWidth",1.1, "Color",col_glass);
grid on; box on;
ylabel("T_1 [°C]");
xlim([1 N]);
xticks(month_edges(2:end-1));
set(ax2,"XTickLabel",[]);
ax2.XGrid = "on"; ax2.YGrid = "on";

% ---------- T2 ----------
ax3  = nexttile;
plot(t, Results.T2, "LineWidth",1.1, "Color",col_air);
grid on; box on;
ylabel("T_2 [°C]");
xlim([1 N]);
xticks(month_edges(2:end-1));
set(ax3,"XTickLabel",[]);
ax3.XGrid = "on"; ax3.YGrid = "on";

% ---------- T3 ----------
ax4  = nexttile;
plot(t, Results.T3, "LineWidth",1.1, "Color",col_wall3);
grid on; box on;
ylabel("T_3 [°C]");
xlim([1 N]);
xticks(month_edges(2:end-1));
set(ax4,"XTickLabel",[]);
ax4.XGrid = "on"; ax4.YGrid = "on";

% ---------- T4 (grid at month transitions + centered month labels) ----------
ax5  = nexttile;
plot(t, Results.T4, "LineWidth",1.1, "Color",col_wall4);
grid on; box on;
ylabel("T_4 [°C]");
xlim([1 N]);

% 1) Month-transition ticks for vertical grid alignment
xticks(month_edges);              % transitions (includes 0 and 8760)
set(ax5,"XTickLabel",[]);         % no labels on the main axis
ax5.XGrid = "on"; ax5.YGrid = "on";

% 2) Overlay axis ONLY for centered labels
ax5_lbl = axes("Position", ax5.Position, ...
               "Color","none", ...
               "XAxisLocation","bottom", ...
               "YAxisLocation","right", ...
               "XLim", ax5.XLim, ...
               "YLim", ax5.YLim);

% Centered labels
ax5_lbl.XTick = month_centers;
ax5_lbl.XTickLabel = month_names;
ax5_lbl.YTick = [];
ax5_lbl.Box = "off";
ax5_lbl.XGrid = "off";
ax5_lbl.YGrid = "off";
ax5_lbl.TickLength = [0 0];       % no extra tick marks
xlabel(ax5_lbl, "Month of year");

% keep the main axis on top for data visibility
uistack(ax5, "top");

set([ax1 ax2 ax3 ax4 ax5], "PositionConstraint","innerposition");

exportgraphics(f1, fullfile(figDir,"Q5_annual_temperatures.png"), ...
               "Resolution", dpi);
