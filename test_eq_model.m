% Test AMICI Matlab-Sundials with sensitivity package
%   https://icb-dcm.github.io/AMICI/
%   https://icb-dcm.github.io/AMICI/doc/def_simu.html
% Use our standard equilibrium model A + B <-> C
% Note that states are the usual x, but parameters (of interest) are p (instead of k)
clear; close all; clc
rng('default');

model_name = 'eq_model';
model_dir = '_eq_model_files';

build_model = true; % build the model initially and after modification

%% Build model
if build_model
    if ~exist(model_dir, 'dir')
        mkdir(model_dir);
    end
    o2_flag = false;
    amiwrap(model_name, model_name, model_dir, o2_flag)
    addpath(model_dir);
end

%% Simulate model
nt = 51;
t = linspace(0, 1, nt);
p = [5; 3];

tic
sol = simulate_eq_model(t, p);
disp(['Time to simulate: ' num2str(toc) ])

% Plot states
figure
plot(t, sol.x)
xlabel('Time')
ylabel('Conc')
legend('A','B','C')
title('A + B <-> C Simulation')

%% Forward sensitivities
opts = amioption('sensi', 1); % default is forward sensitivity

tic
sol_fwd_sens = simulate_eq_model(t, p, [], [], opts);
disp(['Time to simulate with fwd sensitivities: ' num2str(toc) ])

% Plot sensitivities
% sx is sensitivity of x w.r.t. p with [time, x, p]
x_names = {'A', 'B', 'C'}; % this metadata isn't carried around in the model
nx = 3;
p_names = {'kf', 'kr'};
np = 2;

figure
hold on
legend_entries = {};
for ix = 1:nx
    for ip = 1:np
        plot(t, sol_fwd_sens.sx(:,ix,ip))
        legend_entries = [legend_entries, sprintf('d%s/d%s', x_names{ix}, p_names{ip})];
    end
end
hold off
xlabel('Time')
ylabel('Sens')
legend(legend_entries, 'Location', 'best')
title('A + B <-> C Forward Sensitivities')

%% Adjoint sensitivities with some test data
% Test data from KroneckerBio
obs_list   = [1    1    2    2    3    3  ]'; % index of the output this measurement refers to
times_list    = [0.1  1    0.1  1    0.1  1  ]';
measurements = [0.6  0.4  1.5  1.3  0.4  0.6]';

y_names = x_names;
ny = length(y_names);

data = [];
data.obs_inds = obs_list;
data.times = times_list;
data.measurements = measurements;
data.std_devs = measurements * 0.05;

t_sens = unique(times_list);

D = build_amici_data(data, ny);
opts = amioption('sensi', 1, 'sensi_meth', 'adjoint');

% Simulate with adjoint sensitivities
tic
sol_adj_sens = simulate_eq_model(t_sens, p, [], D, opts);
disp(['Time to simulate with adj sensitivities: ' num2str(toc) ])

%% Compute same likelihood and sensitivities with forward sensitivities
tic
opts = amioption('sensi', 1, 'sensi_meth', 'forward');
sol_fwd_sens = simulate_eq_model(t_sens, p, [], D, opts);
disp(['Time to simulate with fwd sensitivities: ' num2str(toc) ])

% TODO: Compute using manual implementation of likelihood and fwd
%   sensitivities

%% Fit data
fit_opts = [];
fit_opts.p0 = [1, 10]; % initial guess
fit_opts.p_lo = [0.1, 0.1];
fit_opts.p_hi = [10, 10];
fit_opts.sens_method = 'fwd'; % or 'adj'
fit_opts.verbose = 2; % or 0 for none, 1 for final only

[p, G] = fit_eq_model(data, ny, fit_opts);

opts = amioption('sensi', 0);

tic
sol_fit = simulate_eq_model(t, p, [], [], opts);
disp(['Time to fit: ' num2str(toc) ])

% Plot fits
figure
hold on
plot(t, sol.x)
ax = gca;
ax.ColorOrderIndex = 1;
plot(D.t, D.Y, '+')
ax = gca;
ax.ColorOrderIndex = 1;
plot(t, sol_fit.x, ':')
hold off
legend('A','B','C','A data','B data','C data','A fit','B fit','C Fit')
xlabel('Time')
ylabel('Amount')

