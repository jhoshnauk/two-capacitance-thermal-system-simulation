%Assignment 2: Task1 Two Capacitance Thermal System Simulation
%Author : Jhoshna Udayakumar
% Description : Simulation of a two capacitance thermal system using a Simulink Model.
% The system has a two thermal bodies (Body 1 with Capacitance C1 and Body 2 with Capacitance C2) 
% connected through thermal resistances R1, R2, and R3 with an ambient temperature.
% A step input of 3W is applied at a time of 10 minutes and plots the figure of theta1, theta2 and q1 to 
% calculate the settling time and steady state temperatures.

clear; clc; close all;
%Parameters
C1 = 50;        % Thermal capacity of Body 1 (J/K)
C2 = 60;        % Thermal capacity of Body 2 (J/K)
R1 = 10;        % Thermal resistance 1 (K/W)
R2 = 10;        % Thermal resistance 2 (K/W)
R3 = 10;        % Thermal resistance 3 (K/W)
ambient_theta = 293.15; %Ambient temperature (K)
q_amp  = 3;     %Amplitude of heat input step (W)
t_step = 600;   %Step Input Time (s)
  
% Equivalent Resistances
R12 = (R1 * R2)/ (R1 + R2);
R23 = (R2 * R3)/ (R2 + R3);

% Simulation Time (90 minutes)
simu_time = 5400;

% Exporting workspace variables to the base workspace of the Simulink model
assignin ('base', 'C1', C1);
assignin('base','C2',C2);
assignin('base','R2',R2);
assignin('base','R12',R12);
assignin('base','R23',R23);

% Run and store the simulation results
simOut = sim('thermal_model_simulink','StopTime',num2str(simu_time));

% Extract simulation results
t = simOut.tout;
% Relative temperature to absolute Kelvin
theta1 = simOut.theta1.Data + ambient_theta ;
theta2 = simOut.theta2.Data + ambient_theta ;
q = simOut.q.Data;

% Plotting the graph
figure();
% Temperature on the left of Y axis
yyaxis left
plot(t/60, theta1, 'b-', 'LineWidth', 2);
hold on;
plot(t/60, theta2, 'r-', 'LineWidth', 2);
ylabel('Temperature (K)');
grid on;

% Heat Input on the right of Y axis
yyaxis right
plot(t/60, q, 'k--', 'LineWidth', 2);
ylabel('q1 Heat Input (W)');

xlabel('Time (mins)');
title('Thermal System Response');
legend('\theta_1', '\theta_2', 'q_1');
legend('Location','southeast','FontSize',9)

% Steady-state values
theta1_ss = theta1(end);
theta2_ss = theta2(end);

% Settling Time (2% of the total temperature change)
tol1 = 0.02*(theta1_ss - ambient_theta);
tol2 = 0.02*(theta2_ss - ambient_theta);

% Finding the last index
idx1 = find(abs(theta1 - theta1_ss)> tol1, 1, 'last');
idx2 = find(abs(theta2 - theta2_ss)> tol2, 1,'last');
t_step_min = t_step / 60;

% Calculating settling time relative to the step applied
if isempty(idx1)
    t_settle1 = 0;
else
    t_settle1 = t(idx1)/60 - t_step_min; 
end

if isempty(idx2)
    t_settle2 = 0;
else
    t_settle2 = t(idx2)/60 - t_step_min ; 
end

%Displaying  results
fprintf('\n------Results------------\n');
fprintf('Theta1 steady-state: %.2f K\n', theta1_ss);
fprintf('Theta2 steady-state %.2f K\n', theta2_ss);
fprintf('Theta1 settling time: %.2f minutes after step \n', t_settle1);
fprintf('Theta2 settling time:%.2f minutes after step\n', t_settle2);

