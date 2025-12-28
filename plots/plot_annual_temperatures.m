close all; clear; clc;

[root, figDir, resFile] = paths_from_plots();
addpath(genpath(fullfile(root,"src")));
addpath(genpath(fullfile(root,"plots")));

S = load(resFile,"Results","p","in");
R = S.Results;

dpi = 600;

set(groot, ...
 "defaultAxesFontSize",14, ...
 "defaultTextFontSize",14, ...
 "defaultAxesLabelFontSizeMultiplier",1.1, ...
 "defaultAxesTitleFontSizeMultiplier",1.2, ...
 "defaultLegendFontSize",9);

cols = struct( ...
 "out",  [0.20 0.60 0.20], ...
 "glass",[0.90 0.15 0.15], ...
 "air",  [0.10 0.40 0.80], ...
 "wall3",[0.80 0.70 0.10], ...
 "wall4",[0.55 0.20 0.70]);

t = R.HOUR_CUM(:);
N = numel(t);

[mEdges, mCenters, mNames] = month_ticks_hours();

f = figure("Units","pixels","Position",[80 60 1400 900],"Color","white");
tlo = tiledlayout(f, 5, 1, "TileSpacing","compact", "Padding","loose");

ax1 = nexttile(tlo); plot_tile(ax1, t, R.T0, cols.out,  "T_0 [°C]", N, mEdges);
ax2 = nexttile(tlo); plot_tile(ax2, t, R.T1, cols.glass,"T_1 [°C]", N, mEdges);
ax3 = nexttile(tlo); plot_tile(ax3, t, R.T2, cols.air,  "T_2 [°C]", N, mEdges);
ax4 = nexttile(tlo); plot_tile(ax4, t, R.T3, cols.wall3,"T_3 [°C]", N, mEdges);

ax5 = nexttile(tlo);
plot_tile(ax5, t, R.T4, cols.wall4,"T_4 [°C]", N, mEdges, true); % last = true -> keep xticks grid
add_month_labels(ax5, mCenters, mNames, "Month of year");

exportgraphics(f, fullfile(figDir,"Q5_annual_hourly_t.png"), "Resolution", dpi);

% ===================== helpers =====================

function [root, figDir, resFile] = paths_from_plots()
    this = fileparts(mfilename("fullpath"));
    root = fileparts(this);
    figDir  = fullfile(root,"figures"); if ~exist(figDir,"dir"), mkdir(figDir); end
    resFile = fullfile(root,"results","AS3B_Q5_Results.mat");
end

function [edges, centers, names] = month_ticks_hours()
    days = [31 28 31 30 31 30 31 31 30 31 30 31];
    names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    edges = [0 cumsum(days)*24];                 % includes 0 and 8760
    centers = edges(1:end-1) + diff(edges)/2;
end

function plot_tile(ax, x, y, col, ylab, N, month_edges, isLast)
    if nargin < 8, isLast = false; end
    plot(ax, x, y, "LineWidth",1.1, "Color",col);
    grid(ax,"on"); box(ax,"on");
    ylabel(ax, ylab);
    xlim(ax,[1 N]);

    if isLast
        % month transitions including 0/8760 (for grid alignment)
        set(ax,"XTick",month_edges,"XTickLabel",[]);
    else
        % internal transitions only (avoid 0/8760 ticks)
        set(ax,"XTick",month_edges(2:end-1),"XTickLabel",[]);
    end
    ax.XGrid = "on"; ax.YGrid = "on";
end

function add_month_labels(ax, centers, names, xlab)
    ax_lbl = axes("Position", ax.Position, ...
        "Color","none", "XAxisLocation","bottom", "YAxisLocation","right", ...
        "XLim", ax.XLim, "YLim", ax.YLim);

    ax_lbl.XTick = centers;
    ax_lbl.XTickLabel = names;
    ax_lbl.YTick = [];
    ax_lbl.Box = "off";
    ax_lbl.XGrid = "off"; ax_lbl.YGrid = "off";
    ax_lbl.TickLength = [0 0];
    xlabel(ax_lbl, xlab);

    uistack(ax,"top");
end