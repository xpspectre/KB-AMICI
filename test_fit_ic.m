% Test out simple model with variable initial conditions
%   A0 is a single param
%   B0 is the sum of 2 params B01 + B02
clear; close all; clc
rng('default');

model_name = 'eq_model_fit_ic';
model_dir = '_eq_model_files_fit_ic';

build_model = false; % build the model initially and after modification

%% Build model
if build_model
    if ~exist(model_dir, 'dir')
        mkdir(model_dir);
    end
    o2_flag = false;
    amiwrap(model_name, model_name, model_dir, o2_flag)
    addpath(model_dir);
end

%% Simulate model - specify all p only
% Result: Fills ICs in A0, B01+B02 as specified by p
nt = 51;
t = linspace(0, 1, nt);
p = [5, 3, 2.2, 1.1, 3.3];

tic
sol = simulate_eq_model_fit_ic(t, p);
disp(['Time to simulate: ' num2str(toc)])

% Plot states
figure
plot(t, sol.x)
xlabel('Time')
ylabel('Conc')
legend('A','B','C')
title('A + B <-> C Simulation')

%% Simulate model - specify all p and override x0
% Result: Overrides all initial conditions, including ignoring ICs specified by p
opts = amioption('sensi', 0);
opts.x0 = [1,3,0]'; % Actually must be a col vector (doc is wrong)

tic
sol = simulate_eq_model_fit_ic(t, p, [], [], opts);
disp(['Time to simulate: ' num2str(toc)])

% Plot states
figure
plot(t, sol.x)
xlabel('Time')
ylabel('Conc')
legend('A','B','C')
title('A + B <-> C Simulation')

%% Simulate with sensitivities
% Result: Makes sense
opts = amioption('sensi', 1);

tic
sol_sens_1 = simulate_eq_model_fit_ic(t, p, [], [], opts);
disp(['Time to simulate: ' num2str(toc)])

%% Simulate with sensitivities - with x0 override
opts = amioption('sensi', 1);
opts.x0 = [1,3,0]';

tic
sol_sens_2 = simulate_eq_model_fit_ic(t, p, [], [], opts);
disp(['Time to simulate: ' num2str(toc)])

% Plot sensitivities wrt params that control ICs - comparison
figure
plot(t, squeeze(sol_sens_1.sx(:,1,3:5)))
hold on
plot(t, squeeze(sol_sens_2.sx(:,1,3:5)))
hold off
xlabel('Time')
ylabel('Sensitivity')
legend('dA/dA0','dA/dB01','dA/dB02','Ov dA/dA0','Ov dA/dB01','Ov dA/dB02')
title('A + B <-> C Sensitivity')
% Result: different between this and above


