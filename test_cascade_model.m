clear; close all; clc
rng('default');

model_name = 'cascade_model';
model_dir = '_cascade_model_model_files';

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
t = linspace(0, 0.25, nt);
p = [5, 3, 5, 3, 5, 3];

tic
sol = simulate_cascade_model(t, p);
disp(['Time to simulate: ' num2str(toc) ])

% Plot states
figure
plot(t, sol.x)
xlabel('Time')
ylabel('Conc')
% legend('A','B','C')
title('Cascade Simulation')