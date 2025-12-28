function [TT1, TT2, TT3, TT4] = HHS_model4(p, T0, Qsol, Tpast_init, Qheat, vent, np)

if nargin < 5 || isempty(Qheat), Qheat = 0; end
if nargin < 6 || isempty(vent),  vent  = 0; end
if nargin < 7 || isempty(np),    np    = 0; end

T0 = T0(:); 
L = p.L; W = p.W; H = p.H;
d1 = p.d1; a1 = p.a1; Ug = p.Ug; Uf = p.Uf; pGlass = p.pGlass;

if any([L,W,H] <= 0), error('L, W, H must be > 0.'); end
if pGlass <= 0 || pGlass >= 1, error('pGlass must be in (0,1).'); end

Qsol = Qsol(:);
if numel(Qsol) ~= numel(T0), error('T0 and Qz must have the same length.'); end
nSteps = numel(T0);

Tpast = Tpast_init(:).';
if numel(Tpast) < 3, error('Tpast_init must contain at least 3 past values.'); end
if numel(Tpast) > 4
    Tpast = Tpast(1:4);
elseif numel(Tpast) < 4
    Tpast = [Tpast, repmat(Tpast(end), 1, 4-numel(Tpast))];
end

alfai = 7.8;
alfac = 2.5;
alfar = 5.0;

rhoair = p.rho_air;
Cpair  = p.Cp_air;

mvent = rhoair * vent;
Qpeople = np * p.Qpp;

Dt = 3600;

Afac = L * H;
Afloor   = L * W;
Aceiling = L * W;
Aback    = L * H;
Aside    = W * H;

A1 = pGlass * Afac;
A4 = (1-pGlass) * Afac;
A3 = Afloor + Aceiling + Aback + 2*Aside;

F13 = 1; F31 = (A1/A3) * F13;
F14 = 0; F41 = 0;
F43 = 1; F34 = (A4/A3) * F43;
F33 = 1 - F34 - F31; 

labda  = 0.2;
Cpcon  = 840;
rhocon = 720;

NRF = 4;
X0 = (2/sqrt(pi)) * sqrt(labda*rhocon*Cpcon/Dt);

X = zeros(1, NRF-1);
for n = 1:NRF-1
    X(n) = -X0*(2*sqrt(n) - sqrt(n+1) - sqrt(n-1));
end

err = X0;
for ii = 1:NRF-1
    err = err + X(ii);
end
for n = 2:NRF-1
    X(n) = X(n) - err/(NRF-2);
end

M  = zeros(4,4);
B  = zeros(4,1);

TT1 = zeros(nSteps,1);
TT2 = zeros(nSteps,1);
TT3 = zeros(nSteps,1);
TT4 = zeros(nSteps,1);

for i = 1:nSteps

    if i > 1
        for kk = 1:2
            Tpast(4-kk) = Tpast(4-kk-1);
        end
        Tpast(1) = TT3(i-1);
    end

    kg = alfai*Ug/(alfai - Ug);
    kf = alfai*Uf/(alfai - Uf);

    M(1,1) = -( kg + alfac + alfar*(F13 + F14) ) * A1;
    M(1,2) =  alfac * A1;
    M(1,3) =  alfar * F13 * A1;
    M(1,4) =  alfar * F14 * A1;

    M(2,1) =  alfac * A1;
    M(2,2) = -(alfac*A1 + alfac*A3 + alfac*A4 + mvent*Cpair);
    M(2,3) =  alfac * A3;
    M(2,4) =  alfac * A4;

    M(3,1) =  alfar * F31 * A3;
    M(3,2) =  alfac * A3;
    M(3,3) = -(alfac + alfar*(F31 + F34) + X0) * A3;
    M(3,4) =  alfar * F34 * A3;

    M(4,1) =  alfar * F41 * A4;
    M(4,2) =  alfac * A4;
    M(4,3) =  alfar * F43 * A4;
    M(4,4) = -( kf + alfac + alfar*(F41 + F43) ) * A4;

    B(1) = -kg * A1 * T0(i) - A1 * a1 * Qsol(i);
    B(2) = -mvent * Cpair * T0(i) - (Qheat + Qpeople);
    B(3) = -d1 * A1 * Qsol(i) + A3*( X(1)*Tpast(1) + X(2)*Tpast(2) + X(3)*Tpast(3) );
    B(4) = -kf * A4 * T0(i);

    T = M \ B;

    TT1(i) = T(1);
    TT2(i) = T(2);
    TT3(i) = T(3);
    TT4(i) = T(4);
end

end