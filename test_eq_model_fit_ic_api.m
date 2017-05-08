% Build a model using the Model class API. Include IC dependence on params
% All state ICs are represented by params:
%   IC params to be fit go in p (some expression)
%   IC params that won't be fit go in k (a single constant)
clear; close all; clc
rng('default');

%% Build model
build_model = false;
model_name = 'eq_model_fit_ic_1';
model_dir = '_eq_model_fit_ic_1';
model_file = [model_dir '/model_file.mat'];
if build_model
    m = Model(model_name, model_dir);
    
    m.AddState('A', 'A0');
    m.AddState('B', '2*B01+B02');
    m.AddState('C', 0);
    
    m.AddParameter('kf', 5);
    m.AddParameter('kr', 3);
    m.AddParameter('A0', 1);
    m.AddParameter('B01', 0.7);
    m.AddParameter('B02', 0.6);
    
    m.AddReaction({'bind', 'unbind'}, {'A', 'B'}, {'C'}, 'kf*A*B', 'kr*C')
    
    m.AddObservation('A', 'A');
    m.AddObservation('B', 'B');
    m.AddObservation('C', 'C');
    
    m.Finalize(); % single arg = false to suppress amiwrap
    
    save(model_file, 'm');
else
    loaded = load(model_file);
    m = loaded.m;
    addpath(m.Directory);
end
%% Simulate model
nt = 51;
t = linspace(0, 1, nt);

% 1) Use default ICs from model - this is the condition for the fit below
[x, y] = simulate_model(m, t);

% 2) Override default constant ICs
% x0 = [0, 0, 0.25]; % 1st 2 ICs are ignored since they are defined by expressions
% [x, y] = simulate_model(m, t, x0);

% 3) Override all ICs with new constants
% x0 = [7, 6, 0.25];
% [x, y] = simulate_model(m, t, x0, [], struct('x0_override_p', true));

% 4) Override (some) parameters that make up ICs
% p = [m.Parameters.Value];
% p(3) = 7; % only change A0
% [x, y] = simulate_model(m, t, [], p);

% Plot states
figure
plot(t, x)
xlabel('Time')
ylabel('Conc')
legend({m.States.Name})
title('A + B <-> C Simulation')

%% Fit data
% Test data from KroneckerBio
obs_list   = [1    1    2    2    3    3  ]'; % index of the output this measurement refers to
times_list    = [0.1  1    0.1  1    0.1  1  ]';
measurements = [0.6  0.4  1.5  1.3  0.4  0.6]';

data = [];
data.obs_inds = obs_list;
data.times = times_list;
data.measurements = measurements;
data.std_devs = measurements * 0.05;

fit_opts = [];
fit_opts.p0 = [4, 4]; % initial guess; these params correspond to the fit params in order
fit_opts.p_lo = [0.1, 0.1];
fit_opts.p_hi = [10, 10];
fit_opts.p_fit = [1, 1, 0, 0, 0]; % only fit rate params
fit_opts.sens_method = 'fwd'; % or 'adj'
fit_opts.verbose = 2; % or 0 for none, 1 for final only

[p_fit, G, exit_flag, fit_output] = fit_model(m, data, fit_opts); % p_fit returns all params in the fit model, including those that weren't fit

x_fit = simulate_model(m, t, [], p_fit);

% Plot fits
figure
hold on
plot(t, x)
ax = gca;
ax.ColorOrderIndex = 1;
plot(times_list(1:2), reshape(measurements,2,3), '+')
ax = gca;
ax.ColorOrderIndex = 1;
plot(t, x_fit, ':')
hold off
legend('A','B','C','A data','B data','C data','A fit','B fit','C Fit')
xlabel('Time')
ylabel('Amount')
title('A + B <-> C Fit')
