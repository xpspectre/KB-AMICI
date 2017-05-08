function [ps, G, exit_flag, output] = fit_models(fits, opts)
% Fit Fit objects of Models or ModelVariants to data using weighted sum of
%   squares objective function.
% Flexible specification of parameters to fit, and relations between
%   parameters of different models/model variants is allowed each fit's
%   Opts.p_fit. It's assumed that all models have the same number of
%   parameters and parameter order (i.e., all ModelVariants based off the
%   same model). Different values of  a single p_fit position indicate
%   different values within that  parameter, but different positions in
%   p_fit are independent.
% The overall fit is the sum of the individual obj funs/obj fun grads,
%   weighted by opts.weights
%
% Inputs:
%   fits [ nm Fit array ]
%       Array of Fit objects specifying each model/model variant condition
%   opts [ struct ]
%       Options struct with fields:
%       .verbose [ positive integer {1} ]
%           How much info to display. 0 for none. 2 for detailed iteration
%           data from optimizer.
%       .weights [ nf double array {ones(1,nm)} ]
%           Relative weight of each fit when summed. No normalization is
%           done to these values.
%
% Outputs:
%   ps [ np x nm double vector ]
%       Fit parameters for each model
%   G [ scalar double ]
%       Final objective function value
%   exit_flag [ scalar integer ]
%       Exit status code from optimizer
%   output [ struct ]
%       Detailed exit status info from optimizer
if nargin < 2
    opts = [];
end
% Default options
opts_ = [];
opts_.verbose = 1;
nm = length(fits);
opts_.weights = ones(1,nm);
opts = merge_structs(opts_, opts);

% Check inputs
assert(length(opts.weights) == nm, 'Weights length must match number of fits')

% Build map of model params <-> global params T
nps = zeros(1,nm);
for im = 1:nm
    nps(im) = length(fits(im).Opts.p_fit);
end
np = nps(1);
assert(all(nps==np), 'Models must have same number of parameters')

p_fits = zeros(np,nm);
for im = 1:nm
    p_fits(:,im) = fits(im).Opts.p_fit(:);
end

local2global = zeros(np,nm);
global2local = false(np,nm,0);
Tind = 1;
for ip = 1:np
    inds = p_fits(ip,:);
    inds(inds == 0) = []; % ignore params not being fit
    inds = sort(unique(inds)); % unique fit indices in order
    for i = 1:length(inds)
        ind = inds(i);
        pos = p_fits(ip,:) == ind;
        
        local2global(ip,pos) = Tind;
        
        g2l = false(np,nm);
        g2l(ip,:) = pos;
        global2local(:,:,Tind) = g2l;
        
        Tind = Tind + 1;
    end
end
nT = Tind - 1;

% Helper functions that map between model and global params
map_l2g = @(ps) map_local2global(ps, local2global, nT);
map_g2l = @(T) map_global2local(T, global2local);

% Assign initial guesses and bounds
ps = zeros(np,nm);
ps_lo = zeros(np,nm);
ps_hi = zeros(np,nm);
for im = 1:nm
    ps(:,im) = fits(im).Opts.p0(:);
    ps_lo(:,im) = fits(im).Opts.p_lo(:);
    ps_hi(:,im) = fits(im).Opts.p_hi(:);
end
T0 = map_l2g(ps);
T_lo = map_l2g(ps_lo);
T_hi = map_l2g(ps_hi);

% Get some params from Model or ModelVariant
nys = zeros(nm,1);
for im = 1:nm
    switch class(fits(im).Model)
        case 'Model'
            nys(im) = fits(im).Model.ny;
        case 'ModelVariant'
            nys(im) = fits(im).Model.Model.ny;
    end
end

% Build data
for im = 1:nm
    data(im) = build_amici_data(fits(im).Data, nys(im));
end

% Build overall objective function
fun = @(T) obj_fun(T, fits, data, opts.weights, map_l2g, map_g2l);

% Specify general fit options
switch opts.verbose
    case 0
        display = 'none';
    case 1
        display = 'final';
    case 2
        display = 'iter-detailed';
end
fit_opts = optimoptions('fmincon', 'SpecifyObjectiveGradient', true, 'Display', display);

% Run fit
[T, G, exit_flag, output] = fmincon(fun, T0, [], [], [], [], T_lo, T_hi, [], fit_opts);

ps = map_g2l(T);

end

% Helper functions that map between model and global params
function T = map_local2global(ps, local2global, nT)
[np, nm] = size(local2global);
T = zeros(nT,1);
for ip = 1:np
    for im = 1:nm
        ind = local2global(ip,im);
        T(ind) = ps(ip,im);
    end
end
end

function ps = map_global2local(T, global2local)
[np,nm,nT] = size(global2local);
ps = zeros(np,nm);
for iT = 1:nT
    ind = global2local(:,:,iT);
    ps(ind) = T(iT);
end
end

function [G, dGds] = obj_fun(T, fits, data, weights, map_l2g, map_g2l)
% Overall objective function for fit
np = length(fits(1).Model.Parameters); % good for Model or ModelVariant
nm = length(fits);
nT = length(T);
G_all = zeros(1,nm);
dGds_all = zeros(np,nm);
ps = map_g2l(T);
for im = 1:nm
    opts = amioption('sensi', 1);
    switch fits(im).Opts.sens_method
        case 'fwd'
            opts.sensi_meth = 'forward';
        case 'adj'
            opts.sensi_meth = 'adjoint';
    end
    
    % Get per-fit parameters
    switch class(fits(im).Model)
        case 'Model'
            model = fits(im).Model;
            p = [model.Parameters.Value];
        case 'ModelVariant'
            model = fits(im).Model.Model;
            p = fits(im).Model.Parameters;
    end
    nx = model.nx;
    
    % Use existing params as base; override with fit params from T
    ps_i = ps(:,im);
    p_fit_i = fits(im).Opts.p_fit ~= 0;
    p(p_fit_i) = ps_i(p_fit_i);
    
    % Get constant ICs
    ic_is_const = false(nx,1);
    ic_const = zeros(nx,1);
    for ix = 1:nx
        if isnumeric(model.States(ix).InitialValue)
            ic_is_const(ix) = true;
            switch class(fits(im).Model)
                case 'Model'
                    ic_const(ix) = model.States(ix).InitialValue;
                case 'ModelVariant'
                    ic_const(ix) = fits(im).Model.StateInitialValues(ix);
            end
        end
    end
    k = ic_const(ic_is_const);
    
    % Simulate with sensitivities
    sol_sens = model.model_fun(data(im).t, p, k, data(im), opts);
    if sol_sens.status ~= 0
        error('Sensitivity simulation returned non-zero exit status')
    end
    
    G = -sol_sens.llh; % obj fun is the negative log-likelihood
    dGds = -sol_sens.sllh; % and obj fun grad is also negated
    G_all(im) = G;
    dGds_all(:,im) = dGds;
end

% Add up all contributions to obj fun val
G = sum(G_all.*weights);

% Add up all contributions to gradient
dGds = zeros(nT,1);
for im = 1:nm
    dGds_i = zeros(np,nm);
    dGds_i(:,im) = dGds_all(:,im);
    dGds = dGds + weights(im)*map_l2g(dGds_i);
end

end
