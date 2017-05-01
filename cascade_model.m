function model = cascade_model(N)
% MAPK-like cascade with variable number of "units"
% See https://icb-dcm.github.io/AMICI/doc/def_simu.html
% Test out model generation syntaxes
% Note: need to do extra checks to make sure all the states and params are
%   actually present in the model. If not, it may still run, but stuff may
%   go into undefined states and be lost.
% Typos in params will probably be caught properly during compilation.
% After a compile error, may need to delete output and intermediates. These
%   are in the specified output folder and ICB-DCM-AMICI-d9751cf/models.

% Set default size
if nargin < 1
    N = 3;
end

% States
x_names = {'A'}; % initial activator
for iN = 1:N
    x_names = [x_names, sprintf('X%i', iN), sprintf('Xp%i', iN)];
end
x = sym(x_names); % this just works if state names are valid. Need a step of string subs if they're not.
nx = length(x);

% Parameters - sensitivities will be calculated for these
%   kon: 2nd order catalytic activation/phosphorylation by prev active member (or initial activator) -
%   koff: 1st order auto-dephosphorylation
p_names = {};
for iN = 1:N
    p_names = [p_names, sprintf('kon%i', iN), sprintf('koff%i', iN)];
end
p = sym(p_names);
np = length(p);

% Eqs from reactions
% Assemble stoichiometry matrix and rate vector
%   S: [nx x nr] stoichimetry matrix
%   v: [nr x 1] rate vector
%   dx/dt = S*v
reactions = {{'X1'}, {'Xp1'}, 'kon1*X1*A'};
reactions = [reactions; {{'Xp1'}, {'X1'}, 'koff1*Xp1'}];
for iN = 2:N
    reactions = [reactions; {{sprintf('X%i', iN)}, {sprintf('Xp%i', iN)}, sprintf('kon%i*X%i*Xp%i', iN, iN, iN-1)}]; % activate
    reactions = [reactions; {{sprintf('Xp%i', iN)}, {sprintf('X%i', iN)}, sprintf('koff%i*Xp%i', iN, iN)}]; % deactivation
end
rxns = cell2struct(reactions, {'Reac','Prod','Rate'}, 2);
nr = length(rxns);

S = zeros(nx,nr);
v = sym('v', [nr,1]);
for ir = 1:nr
    reac = rxns(ir).Reac;
    nri = length(reac);
    for iri = 1:nri
        ind = find(ismember(x_names, reac{iri}));
        S(ind, ir) = S(ind, ir) - 1; % takes care of stoich > 1
    end
    
    prod = rxns(ir).Prod;
    npi = length(prod);
    for ipi = 1:npi
        ind = find(ismember(x_names, prod{ipi}));
        S(ind, ir) = S(ind, ir) + 1; % takes care of stoich > 1
    end
    
    rate = rxns(ir).Rate;
    v(ir) = sym(rate); % this just works if state names are valid. Need a step of string subs if they're not.
end
xdot = S*v;

% Initial conditions
%   Activator and unphosphorylated stuff start out with nonzero concs
x0 = zeros(1, nx);
x0(1) = 10;
for iN = 1:N
    x0(2*iN) = 10; % it happend that the even numbered states are unphos
end

% Observables - outputs
y = x(2:end); % everything except activator

% Attach to model
model.sym.x = x;
model.sym.k = [];
model.sym.event = [];
model.sym.xdot = xdot;
model.sym.p = p;
model.sym.x0 = x0;
model.sym.y = y;
% model.sym.sigma_y = [];
% model.sym.sigma_t = [];

end
