function [Qk, mode] = hvac_control(hvac_on, p, T0, Qsol, Tpast, vent, np, Theat, Tcool)

if ~hvac_on
    Qk = 0;
    mode = "OFF";
    return
end

[~, TT2, ~, ~] = HHS_model4(p, T0, Qsol, Tpast, 0, vent, np);
Tair_ff = TT2(end);

if Tair_ff < Theat
    Qk = solve_Q_for_setpoint(p, T0, Qsol, Tpast, vent, Theat, np);
    mode = "HEAT";
elseif Tair_ff > Tcool
    Qk = solve_Q_for_setpoint(p, T0, Qsol, Tpast, vent, Tcool, np);
    mode = "COOL";
else
    Qk = 0;
    mode = "DEAD";
end
end
