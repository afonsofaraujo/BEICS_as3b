close all; clear; clc;

this = fileparts(mfilename("fullpath"));
root = fileparts(this);

addpath(fullfile(root,"src"));
addpath(fullfile(root,"plots"));

S = load(fullfile(root,"results","AS3B_Q5_Results.mat"),"Results","p","in");
R = S.Results;

figDir = fullfile(root,"figures"); if ~exist(figDir,"dir"), mkdir(figDir); end
dpi = 600;

set(groot, ...
 "defaultAxesFontSize",14, ...
 "defaultTextFontSize",14, ...
 "defaultAxesLabelFontSizeMultiplier",1.1, ...
 "defaultAxesTitleFontSizeMultiplier",1.2, ...
 "defaultLegendFontSize",9);

QkW = R.Q_LOAD(:)/1000;

% ---------- FIG 1: hourly load (kW), month labels ----------
t = R.HOUR_CUM(:);
f = figure("Units","pixels","Position",[140 120 1400 520],"Color","white");
ax = axes(f); hold(ax,"on");

plot_posneg_bars(ax, t, QkW, 1.0, 1.0);

grid(ax,"on"); box(ax,"on");
ylabel(ax,"HVAC load [kW]");
xlim(ax,[1 numel(t)]);

[mEdges, mCenters, mNames] = month_ticks("hours");
set(ax,"XTick",mEdges,"XTickLabel",[]);
ax.XGrid = "on"; ax.YGrid = "on";
add_month_labels(ax, mCenters, mNames, "Month of year");

legend(ax,{"Heating","Cooling"}, "Location","best", "Orientation","horizontal");
exportgraphics(f, fullfile(figDir,"Q5_annual_hourly_HVAC.png"), "Resolution", dpi);

% ---------- FIG 2: daily average load (kW), month labels ----------
ndays = floor(numel(QkW)/24);
Qday = mean(reshape(QkW(1:ndays*24),24,ndays),1,"omitnan")';
d = (1:ndays)';

f = figure("Units","pixels","Position",[140 120 1400 520],"Color","white");
ax = axes(f); hold(ax,"on");

plot_posneg_bars(ax, d, Qday, 1.0, 1.0);

grid(ax,"on"); box(ax,"on");
ylabel(ax,"Daily average HVAC load [kW]");
xlim(ax,[1 ndays]);

[mEdges, mCenters, mNames] = month_ticks("days");
set(ax,"XTick",mEdges+1,"XTickLabel",[]);
ax.XGrid = "on"; ax.YGrid = "on";
add_month_labels(ax, mCenters+1, mNames, "Month of year");

legend(ax,{"Heating","Cooling"}, "Location","best", "Orientation","horizontal");
exportgraphics(f, fullfile(figDir,"Q5_annual_daily_HVAC.png"), "Resolution", dpi);

% ===================== local helpers =====================

function plot_posneg_bars(ax, x, y, width, alpha)
    idxH = y > 0; idxC = y < 0;
    if any(idxH)
        b = bar(ax, x(idxH), y(idxH), width, "FaceColor","red","EdgeColor","none");
        b.FaceAlpha = alpha;
    end
    if any(idxC)
        b = bar(ax, x(idxC), y(idxC), width, "FaceColor","blue","EdgeColor","none");
        b.FaceAlpha = alpha;
    end
end

function [edges, centers, names] = month_ticks(mode)
    days = [31 28 31 30 31 30 31 31 30 31 30 31];
    names = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    if mode == "hours"
        edges = [0 cumsum(days)*24];
    else
        edges = [0 cumsum(days)];
    end
    centers = edges(1:end-1) + diff(edges)/2;
end

function add_month_labels(ax, centers, names, xlab)
    ax_lbl = axes("Position", ax.Position, "Color","none", ...
        "XAxisLocation","bottom", "YAxisLocation","right", ...
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