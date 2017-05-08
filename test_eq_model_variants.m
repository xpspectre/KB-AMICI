% Build a Model and ModelVariants
clear; close all; clc
rng('default');

%% Build model
build_model = false;
model_name = 'eq_model_1';
model_dir = '_eq_model_1';
model_file = [model_dir '/model_file.mat'];
if build_model
    m = Model(model_name, model_dir);
    
    m.AddState('A', 1);
    m.AddState('B', 2);
    m.AddState('C', 0);
    
    m.AddParameter('kf', 5);
    m.AddParameter('kr', 3);
    
    m.AddReaction({'bind', 'unbind'}, {'A', 'B'}, {'C'}, 'kf*A*B', 'kr*C')
    
    m.AddObservation('A', 'A');
    m.AddObservation('B', 'B');
    m.AddObservation('C', 'C');
    
    m.Finalize();
    
    save(model_file, 'm');
else
    loaded = load(model_file);
    m = loaded.m;
    addpath(m.Directory);
end

%% Build 3 variants with different initial conditions
nv = 3;
kfs = [1, 5, 10]; % change binding rate
for iv = 1:nv
    pi = [m.Parameters.Value];
    pi(1) = kfs(iv);
    mvs(iv) = ModelVariant(sprintf('Eq%i',iv), m, [], pi);
end

%% Simulate model
nt = 51;
t = linspace(0, 1, nt);
[xs, ys] = simulate_models(mvs, t);

% Plot states
figure
hold on
for iv = 1:nv
    ax = gca;
    ax.ColorOrderIndex = 1;
    plot(t, xs{iv})
end
hold off
xlabel('Time')
ylabel('Conc')
legend({m.States.Name})
title('A + B <-> C Simulations')

%% Generate some synthetic data to fit
t_gen = [0.1, 0.3, 0.5]';
nt_gen = length(t_gen);
[~, ys_gen] = simulate_models(mvs, t_gen);
ny = 3;

%% Fit data
% Assemble Fit objects
np = 2;
for iv = 1:nv
    obs_list = [];
    times_list = [];
    measurements = [];
    for iy = 1:ny
        obs_list = [obs_list; repmat(iy,nt_gen,1)];
        times_list = [times_list; t_gen];
        measurements = [measurements; ys_gen{iv}(:,iy)];
    end
    
    % Add some noise to the measurements - part of data generation
    measurements = measurements + normrnd(0,0.05*measurements);
    
    data_i = [];
    data_i.obs_inds = obs_list;
    data_i.times = times_list;
    data_i.measurements = measurements;
    data_i.std_devs = measurements * 0.05;
    
    opts_i = [];
    opts_i.p0 = [4, 4];
    opts_i.p_lo = repmat(0,1,np);
    opts_i.p_hi = repmat(10,1,np);
    opts_i.p_fit = [iv, 1]; % kf is different, kr is shared
    % Keep default sens_method = fwd
    
    fits(iv) = Fit(sprintf('Fit%i',iv), mvs(iv), data_i, opts_i);
end

% Overall fit options
fit_opts = [];
fit_opts.verbose = 2; % or 0 for none, 1 for final only
% Keep default all weights = 1

%% Do fit
[ps_fit, G, exit_flag, fit_output] = fit_models(fits, fit_opts);

%% Simulate fit model results
for iv = 1:nv
    mvs_fit(iv) = ModelVariant(sprintf('FitEq%i',iv), m, [], ps_fit(:,iv));
end
[xs_fit, ys_fit] = simulate_models(mvs_fit, t);

% Plot fits
figure
hold on
for iv = 1:nv
    ax = gca;
    ax.ColorOrderIndex = 1;
    plot(t, xs{iv})
end
for iv = 1:nv
    ax.ColorOrderIndex = 1;
    plot(fits(iv).Data.times(1:nt_gen), reshape(fits(iv).Data.measurements,nt_gen,ny), '+')
end
for iv = 1:nv
    ax.ColorOrderIndex = 1;
    plot(t, xs_fit{iv}, ':')
end
hold off
% legend('A','B','C','A data','B data','C data','A fit','B fit','C Fit')
xlabel('Time')
ylabel('Amount')
title('A + B <-> C Fit')
