function model = eq_model_fit_ic()
% Simple equilibrium binding model A + B <-> C with forward and reverse
%   rates and variable initial condition
% See https://icb-dcm.github.io/AMICI/doc/def_simu.html

% States
syms A B C
x = [A, B, C];

% Parameters - sensitivities will be calculated for these
syms kf kr A0 B01 B02
p = [kf, kr, A0, B01, B02];

% Constants - no sensitivities
syms C0
k = [C0];

% Eqs
xdot(1) = -kf*A*B + kr*C;
xdot(2) = -kf*A*B + kr*C;
xdot(3) =  kf*A*B - kr*C;

% Initial conditions
x0 = [A0, B01+2*B02, C0];

% Observables - outputs
y(1) = A;
y(2) = B;
y(3) = C;

% Attach to model
model.sym.x = x;
model.sym.k = k;
model.sym.event = [];
model.sym.xdot = xdot;
model.sym.p = p;
model.sym.x0 = x0;
model.sym.y = y;
% model.sym.sigma_y = [];
% model.sym.sigma_t = [];

end
