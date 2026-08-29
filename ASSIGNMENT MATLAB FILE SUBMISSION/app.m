% TITLE : TASK 2 Thermal System Explorer
% AUTHOR : Jhoshna Udayakumar
% Description :An user interactive app to explore the two capacitance thermal system. 
% It calls the thermal_model_simulink.slx from Task 1.
% Features of the app: User can run simulation, compare plots of their
% choice, export the image of the plot as png, toggle between the units,
% presets defined for easy simulations, there is a metric table with values
% of the simulation, there is a (how to use)column to guide the user to run
% the app, there is also interpretation table giving an analysis of the
% plot and finally we also have parameter sensitivity sweep to for five
% different values.


classdef app < matlab.apps.AppBase  % Declaring class def to initialse the app

properties (Access = public)        %Initialising the app GUI elements
    UIFigure          matlab.ui.Figure

    MainAxes         matlab.ui.control.UIAxes
    SweepAxes        matlab.ui.control.UIAxes

    C1Slider         matlab.ui.control.Slider
    C2Slider         matlab.ui.control.Slider
    R1Slider         matlab.ui.control.Slider
    R2Slider         matlab.ui.control.Slider
    R3Slider         matlab.ui.control.Slider
    ThetaASlider     matlab.ui.control.Slider
    AmpSlider        matlab.ui.control.Slider
    StepTimeSlider   matlab.ui.control.Slider

    C1Field           matlab.ui.control.NumericEditField
    C2Field           matlab.ui.control.NumericEditField
    R1Field           matlab.ui.control.NumericEditField
    R2Field           matlab.ui.control.NumericEditField
    R3Field           matlab.ui.control.NumericEditField
    ThetaAField       matlab.ui.control.NumericEditField
    AmpField          matlab.ui.control.NumericEditField
    StepTimeField     matlab.ui.control.NumericEditField

    RunButton           matlab.ui.control.Button
    AddCompareButton    matlab.ui.control.Button
    ClearCompareButton  matlab.ui.control.Button
    ResetButton         matlab.ui.control.Button
    ExportButton        matlab.ui.control.Button
    KelvinButton        matlab.ui.control.Button
    CelsiusButton       matlab.ui.control.Button
    SweepButton         matlab.ui.control.Button


    PresetDrop            matlab.ui.control.DropDown
    SweepDrop             matlab.ui.control.DropDown

    MetricsTable           matlab.ui.control.Table
    InterpretationArea     matlab.ui.control.TextArea
    HowToArea              matlab.ui.control.TextArea

    TitleLabel              matlab.ui.control.Label
    ParamTitleLabel         matlab.ui.control.Label
    C1Label                 matlab.ui.control.Label
    C2Label                 matlab.ui.control.Label
    R1Label                 matlab.ui.control.Label
    R2Label                 matlab.ui.control.Label
    R3Label                 matlab.ui.control.Label
    ThetaALabel             matlab.ui.control.Label
    AmpLabel                matlab.ui.control.Label
    StepTimeLabel           matlab.ui.control.Label
    PresetLabel             matlab.ui.control.Label
    UnitsLabel              matlab.ui.control.Label
    SweepLabel              matlab.ui.control.Label
    MetricsLabel            matlab.ui.control.Label
    InterpLabel             matlab.ui.control.Label
    HowToLabel              matlab.ui.control.Label
     end 


properties (Access = private)
        % Creating a struct of the elements
        CompareRuns = struct ('t',{},'theta1',{},'theta2',{},'label',{});
         
        LastT = [];
        LastTheta1 = [];
        LastTheta2 = [];

        Display_Celsius = false;
        % Setting the default values of the parameters
        Defaults = struct('C1',50,'C2',60,'R1',10,'R2',10,'R3',10,'ThetaA',293.15,'Amp',3,'StepTime',10);

        Simu_Model = 'thermal_model_simulink';
        end

methods (Access = private)
    % Runs the Simulink Model with parameters in struct p.
    function [t_min, theta1, theta2, q1] = runSimulation(app, p)

      R12 = (p.R1 * p.R2) / (p.R1 + p.R2);
      R23 = (p.R2 * p.R3) / (p.R2 + p.R3);
      
      % Setting simulation time limit
      t_max = max(p.C1 * R12, p.C2 * R23);
      t_end = max(p.StepTime * 60 + 15 * t_max,p.StepTime * 60 + 600);
     
      
      % Writes all the parameters to the base workspace 
      assignin('base', 'C1',        p.C1);
      assignin('base', 'C2',        p.C2);
      assignin('base', 'R1',        p.R1);
      assignin('base', 'R2',        p.R2);
      assignin('base', 'R3',        p.R3);
      assignin('base', 'R12',       R12);
      assignin('base', 'R23',       R23);
      assignin('base', 'theta_a',   p.ThetaA);
      assignin('base', 'q_amp',     p.Amp);
      assignin('base', 't_step',    p.StepTime * 60);
      assignin('base', 't_end_sim', t_end);

      if ~bdIsLoaded (app.Simu_Model)
          load_system(app.Simu_Model);
      end

      % Reads the output and stores the values
      simOut = sim(app.Simu_Model,'StopTime', num2str(t_end));

      t_seconds = simOut.tout;
      th1 = simOut.theta1.Data;
      th2 = simOut.theta2.Data;

      t_seconds= t_seconds(:);
      th1 = th1(:);
      th2 = th2(:);

      % Converts incremental to absolute temperatures
      theta1 = th1+p.ThetaA;
      theta2 = th2+p.ThetaA;
      
      % Creates the step vector
      q1 = p.Amp.*(t_seconds>=p.StepTime*60);
      t_min = t_seconds/60;
       
      % Cleans the base workspace after every simulation
      var_names = {'C1','C2','R1','R2','R3','R12','R23','theta_a','q_amp','t_step','t_end_sim'};
      
      for k = 1:length(var_names)
          if evalin('base',['exist(''' var_names{k} ''',''var'')'])
              evalin('base', ['clear ' var_names{k}]);

          end
      end
end

% Computes the metric values
function [ss1, ss2, settle1, settle2, tc1, tc2]= computeMetrics(~, t_min, theta1, theta2, stepTime_min) 
    
   idx = t_min >= stepTime_min;
   post_t = t_min(idx);
   post_th1 = theta1(idx);
   post_th2 = theta2(idx);
    
   % Steady state values
   ss1 = post_th1(end);
   ss2 = post_th2(end);
  
   % 2% Settling time
   settling_band_1 = 0.02 * abs(ss1 - post_th1(1));
   settling_band_2 = 0.02 * abs(ss2 - post_th2(1));

   settling_outside_1 = find(abs(post_th1 - ss1) > settling_band_1, 1, 'last');
   settling_outside_2 = find(abs(post_th2 - ss2) > settling_band_2, 1, 'last');

   if isempty(settling_outside_1)
       settle1 = 0;
   else
       idx1 = min( settling_outside_1+1, length(post_t));
       settle1 = post_t(idx1) - stepTime_min;
   end

    if isempty(settling_outside_2)
       settle2 = 0;
   else
       idx2 = min( settling_outside_2+1, length(post_t));
       settle2 = post_t(idx2) - stepTime_min;
   end
   

   rise_time1     = abs(ss1 - post_th1(1));
   rise_time2     = abs(ss2 - post_th2(1));
   tcIdx1   = find(post_th1 >= post_th1(1) + 0.632*rise_time1, 1, 'first'); % Finding the time constants
   tcIdx2   = find(post_th2 >= post_th2(1) + 0.632*rise_time2, 1, 'first');

   if isempty(tcIdx1)
            tc1 = NaN;
   else
            tc1 = post_t(tcIdx1) - stepTime_min;
   end

   if isempty(tcIdx2)
              tc2 = NaN;
   else
              tc2 = post_t(tcIdx2) - stepTime_min;
   end

end

% Generates explanation of the parameter changes
function str = getInterpretation(~, p, def)
    
      lines = {};
      
      % For changes in Parameter in R2
      if abs(p.R2 - def.R2)>0.1
          if p.R2 > def.R2
              lines{end+1} = sprintf( ...
                  [ 'R2 = %.1f K/W (increased from %.1f K/W)\n'...
                    'R2 is the thermal resistance between the two bodies.\n'...
                    'like the wall separating two rooms. A higher R2 means \n'...
                    'more insulation between them: less heat flows form body \n'...
                    '1 to body 2. Theta 2 responds more slowly and reaches \n'...
                    ' a lower steady-state temperature.' ], p.R2, def.R2);
          else
              lines{end+1}= sprintf( ...
                  [ 'R2 = %.1f K/W (increased from %.1f K/W)\n'...
                    'Lower R2 means better thermal contact between the two\n'...
                    'bodies. Heat Transfer more freely so theta2 closely \n'...
                    'follows theta1 and both react similar temperatures' ], p.R2, def.R2);

          end
      end
      
      % For changes in Parameter in R1
      if abs(p.R1 - def.R1) > 0.1
          if p.R1 > def.R1 
              lines{end+1} = sprintf( ...
                  ['R1 = %.1f K/W (increased from %.1f K/W)\n' ...
                  'R1 is the left-side resistance to the environment.\n' ...
                  'Higher R1 = better left insulation: theta1 Steady State increases.'], p.R1, def.R1);
          else
              lines{end+1} = sprintf( ...
                  ['R1 = %.1f K/W (decreased from %.1f K/W)\n' ...
                  'Lower R1 = more heat lost to the left environment.\n' ...
                   'Steady-state theta1 decreases.'], p.R1, def.R1);
          end
      end    
 
      % For changes in Parameter in R3
     if abs( p.R3 - def.R3)> 0.1
        if p.R3 > def.R3
          lines{end+1} = sprintf( ...
                  [ 'R3 = %.1f K/W (increased from %.1f K/W)\n' ...
                    'R3 is the resistance on the right side of body 2 to\n' ...
                    'the environment. Higher R3 reduces heat loss from body\n' ...
                     '2, so theta2 steady state increases.'], p.R3, def.R3); ...


      else
          lines{end+1} = sprintf( ...
              ['R3 = %.1f K/W (decreased from %.1f K/W)\n' ...
               'Lower R3 increases heat loss from body 2 to the right\n' ...
               'environment, reducing steady-state theta2.'], ...
                p.R3, def.R3); ...
             
              
      end
  end
  
  % For changes in Parameter in C1
  if abs(p.C1 - def.C1)>0.1
      if p.C1 > def.C1
          lines{end+1} = sprintf( ...
              ['C1 = %.1f J/K (increased from %.1f J/K)\n' ...
               'C1 is the heat capacity of body 1: how much energy is\n' ...
               'needed to raise its temperature by 1 K. Higher C1 means\n' ...
               'body 1 heats up more slowly (larger time constant).\n' ...
               'Importantly, steady-state temperature is UNCHANGED because\n' ...
                'capacitance only affects dynamics, not equilibrium.'], ...
                         p.C1, def.C1);
      else
           lines{end+1} = sprintf( ...
                 ['C1 = %.1f J/K (decreased from %.1f J/K)\n' ...
                   'Lower C1 means body 1 has less thermal mass so it heats\n' ...
                   'up faster. Steady-state temperature is unchanged.'], ...
                         p.C1, def.C1);
       end
  end       
    
      % For changes in Parameter in C2
      if abs(p.C2 - def.C2) > 0.1
                if p.C2 > def.C2
                    lines{end+1} = sprintf( ...
                        ['C2 = %.1f J/K (increased from %.1f J/K)\n' ...
                         'C2 is the heat capacity of body 2. Higher C2 increases\n' ...
                         'the time constant of theta2: it responds more slowly\n' ...
                         'to changes in theta1. Steady state is unaffected.'], ...
                         p.C2, def.C2);
                else
                    lines{end+1} = sprintf( ...
                        ['C2 = %.1f J/K (decreased from %.1f J/K)\n' ...
                         'Lower C2 means body 2 has less thermal mass and responds\n' ...
                         'faster to changes in theta1.'], p.C2, def.C2);
                end


      end
           % For changes in Parameter in Ambient Temperature
           if abs(p.ThetaA - def.ThetaA) > 0.5
                lines{end+1} = sprintf( ...
                    ['theta_a = %.2f K (%.1f deg C), changed from %.2f K\n' ...
                     'theta_a is the ambient environment temperature. Changing\n' ...
                     'it shifts the absolute values of BOTH theta1 and theta2\n' ...
                     'by the same amount. The dynamics (shape of response,\n' ...
                     'settling time) are completely unchanged because the model\n' ...
                     'uses incremental variables referenced to theta_a.'], ...
                     p.ThetaA, p.ThetaA-273.15, def.ThetaA);
           end
          
           if isempty(lines)
                str = sprintf(['All parameters at default values.\n\n' ...
                    'Adjust a slider and press Run Simulation to see\n' ...
                    'a physical interpretation of the change here.']);
           else
                str = strjoin(lines, sprintf('\n\n'));
           end


end
        
function p = getCurrentParams(app)
   % Reads all the parameter values taken from the UI Fields
   p.C1 =  app.C1Field.Value;
   p.C2 =  app.C2Field.Value;
   p.R1 =  app.R1Field.Value;
   p.R2 =  app.R2Field.Value;
   p.R3 =  app.R3Field.Value;
   p.ThetaA =  app.ThetaAField.Value;
   p.Amp =  app.AmpField.Value;
   p.StepTime =  app.StepTimeField.Value;


end

function ok = validateParams(app, p)
   % This checks if all the parameters are within valid bounds.
   ok = true;
   checks={
       p.C1,       1,   500,  'C1';
       p.C2,       1,   500,  'C2';
       p.R1,       0.1, 500,  'R1';
       p.R2,       0.1, 500,  'R2';
       p.R3,       0.1, 500,  'R3';
       p.ThetaA,   200, 400,  'theta_a';
       p.Amp,      0,   500,  'Step amplitude';
       p.StepTime, 0,   300,  'Step time'
       };

   % Condition to check the value within the bound
   for k =1:size(checks, 1)
       val = checks{k,1};
       low = checks{k,2};
       high = checks{k,3};
       name = checks{k,4};
       if val< low || val> high || ~isfinite(val)
           uialert(app.UIFigure, ...
               sprintf('%s must be between %.1f and %.1f', name, low, high), ...
               'Invalid input');
           ok = false;
           return

       end
   end
end


function updateMetricsTable(app , ss1, ss2, settle1, settle2, tc1, tc2)
    % Writes the simulation results into the metric table.
    
    app.MetricsTable.Data = {
        'Steady state (K)',           sprintf('%.3f', ss1),    sprintf('%.3f', ss2);
        'Steady state (deg C)',        sprintf('%.2f', ss1-273.15), sprintf('%.2f', ss2-273.15);
        '2% Settling Time (min)',      sprintf('%.2f', settle1), sprintf('%.2f', settle2);
        'Time Constant (min)',    sprintf('%.2f', tc1),   sprintf('%.2f', tc2);
        };

end

function plotOnMainAxes(app, t_min, theta1, theta2, q1, lineStyle, runLabel)
   % Helps plot the simulation of the parameter set on the main axes.
   if app.Display_Celsius
       y1 = theta1 - 273.15;
       y2 = theta2 - 273.15;
       tempLabel = 'Temperature (deg C)';
   else
       y1 = theta1;
       y2 = theta2;
       tempLabel = 'Temperature (K)';

   end

   hold(app.MainAxes, 'on');
   % Plot labels and the assigned values
   yyaxis(app.MainAxes, 'left');
   plot (app.MainAxes, t_min, y1, 'Color',[0.00 0.45 0.74],'LineStyle', lineStyle,'LineWidth',2,'DisplayName',['\theta_1' runLabel]);
   plot (app.MainAxes, t_min, y2, 'Color',[0.85 0.33 0.10],'LineStyle',lineStyle,'LineWidth', 2, 'DisplayName',['\theta_2' runLabel]);
   ylabel(app.MainAxes, tempLabel);


   yyaxis(app.MainAxes, 'right');
   plot (app.MainAxes, t_min, q1, 'Color',[0.47 0.67 0.19],'LineStyle','-' ,'LineWidth',1.5,'DisplayName',['q_1' runLabel]);
   ylabel(app.MainAxes, 'Heat input q_1 (W)');
   app.MainAxes.YAxis(2).Limits = [0 3.1];

   yyaxis(app.MainAxes,'left');
   hold(app.MainAxes,'off');


   xlabel(app.MainAxes, 'Time (minutes)');
   title(app.MainAxes,'Thermal System Response');
   legend(app.MainAxes, 'Location','best');
   grid(app.MainAxes,'on');
   app.MainAxes.FontSize = 12;
   app.MainAxes.XLabel.FontWeight = 'bold';
   app.MainAxes.YLabel.FontWeight = 'bold';

end
end

methods (Access = private)
    
% Sets the callbacks
function RunButtonPushed(app, ~)
   p = app.getCurrentParams(); % Gets the parameter values

   if ~app.validateParams(p)
       return
   end

   try
       [t_min, theta1, theta2, q1] = app.runSimulation(p);
   catch ME
       uialert(app.UIFigure,['Simulation error: ' ME.message newline ...
           'Check that thermal_model_simulink.slx is in the same folder'],'simulation error');
       return
   end

   % Assigns the values to the UI in the app
   app.LastT = t_min;      
   app.LastTheta1 = theta1;
   app.LastTheta2 = theta2;

   yyaxis(app.MainAxes,'left'); cla(app.MainAxes);
   yyaxis(app.MainAxes,'right'); cla(app.MainAxes);

   for k = 1:length(app.CompareRuns)
       r = app.CompareRuns(k);
       app.plotOnMainAxes(r.t,r.theta1,r.theta2,zeros(size(r.t)),'--',['[' r.label ']']);

   end
   
   % Current changes are represented as a solid line
   app.plotOnMainAxes(t_min, theta1, theta2, q1, '-','(current)');

   [ss1, ss2, settle1, settle2, tc1, tc2] = app.computeMetrics(t_min, theta1, theta2, p.StepTime);
   app.updateMetricsTable(ss1, ss2, settle1, settle2, tc1, tc2);

   % Update the physical intepretation
   app.InterpretationArea.Value = app.getInterpretation(p, app.Defaults);

end

function AddCompareButtonPushed(app, ~)
    % Sets the callback for the compare button to compare the plots
    if isempty(app.LastT)
        uialert(app.UIFigure, 'Run a simulation first.','No Data');
        return
    end

    if length(app.CompareRuns)>=3
        uialert(app.UIFigure, 'Maximum 3 comaprisons only. Please clear the comparison first.','Limit Reached');
        return
    end


    p= app.getCurrentParams();

    newRun.t = app.LastT;
    newRun.theta1 = app.LastTheta1;
    newRun.theta2 = app.LastTheta2;
    newRun.label = sprintf('Default'); % Legend of the plot 

    app.CompareRuns(end+1) = newRun;
     
    % Updates the information in the interpretation area.
    app.InterpretationArea.Value = sprintf( ...
        [ 'Run saved as comparison %d/3: %s\n\n'...
          'Now change a parameter (e.g. set R2=50)\n' ...
          'and press Run Simulation again to see\n' ...
          'both responses overlaid on the same plot.'], length(app.CompareRuns), newRun.label);
    fprintf('Comparison %d/3 saved: %s\n', length(app.CompareRuns), newRun.label);



end

function ClearCompareButtonPushed(app, ~)
  % Clears the plot when pushed for the next simulation
  app.CompareRuns = struct('t', {}, 'theta1', {}, 'theta2', {},'label',{});
  yyaxis(app.MainAxes, 'left'); cla(app.MainAxes);
  yyaxis(app.MainAxes,'right'); cla(app.MainAxes);
  legend(app.MainAxes,'off');

end

function ResetButtonPushed(app, ~)
       % Brings the slider back to the default values of the assignment.
       d = app.Defaults; 
       app.C1Slider.Value = d.C1;    app.C1Field.Value = d.C1;
       app.C2Slider.Value = d.C2;    app.C2Field.Value = d.C2;
       app.R1Slider.Value = d.R1;    app.R1Field.Value = d.R1;
       app.R2Slider.Value = d.R2;    app.R2Field.Value = d.R2;
       app.R3Slider.Value = d.R3;    app.R3Field.Value = d.R3;
       app.ThetaASlider.Value = d.ThetaA;    app.ThetaAField.Value = d.ThetaA;
       app.AmpSlider.Value = d.Amp;    app.AmpField.Value = d.Amp;
       app.StepTimeSlider.Value = d.StepTime;    app.StepTimeField.Value = d.StepTime;

       app.InterpretationArea.Value = {'Parameters are reset to default. Press Run Simulation'};
end

function ExportButtonPushed(app, ~)
    % Takes a image of the plot and helps the user save in their file
    if isempty(app.LastT)
        uialert(app.UIFigure, 'Runa simulation first.', 'Nothing found to Export');
        return
    end

    [fname, fpath] = uiputfile('*.png','Save figure','thermal_response.png');
    if fname == 0
        return
    end

    exportgraphics(app.MainAxes, fullfile(fpath, fname), 'Resolution', 300);
    uialert(app.UIFigure, ['Saved t0:' fullfile(fpath, fname)], 'Exported');

end

function PresetDropChanged(app, ~)
    % Shows all the preset conditions in the drop down
    sel= app.PresetDrop.Value;
    if strcmp(sel, 'Select a Case')
        return
    end

    app.ResetButtonPushed([]);
    switch sel 
        case 'Default Task 1 values'
        case 'Case 1: R2 = 50K/W'
            app.R2Slider.Value = 50;
            app.R2Field.Value = 50;
        case 'Case 2: R1 = 50k/W'
            app.R1Slider.Value = 50;
            app.R1Field.Value = 50;

        case 'Case 3: C1 = 150J/K'
            app.C1Slider.Value = 150;
            app.C1Field.Value = 150;

        case 'Case 4: theta_a = 313K'
            app.ThetaASlider.Value = 313.15;
            app.ThetaAField.Value = 313.15;

    end

    app.RunButtonPushed([]);

end
function KelvinButtonPushed(app, ~)
    % Displays the result in Kelvin 
    app.Display_Celsius = false;
    app.KelvinButton.BackgroundColor = [0.18 0.37 0.55];
    app.KelvinButton.FontColor = [1 1 1];
    app.CelsiusButton.BackgroundColor = [0.94 0.94 0.94];
    app.CelsiusButton.FontColor = [0.2 0.2 0.2];
    if ~isempty(app.LastT)
        app.RunButtonPushed([]);
    end
end

function CelsiusButtonPushed(app, ~)
    % Displays the result in Kelvin
    app.Display_Celsius = true;
    app.CelsiusButton.BackgroundColor = [0.18 0.37 0.55];
    app.CelsiusButton.FontColor = [1 1 1];
    app.KelvinButton.BackgroundColor = [0.94 0.94 0.94];
    app.KelvinButton.FontColor = [0.2 0.2 0.2];
    if ~isempty(app.LastT)
        app.RunButtonPushed([]);
    end
end

function SweepButtonPushed(app, ~)
     % Creates the sweep plot for the selected parameter
     sweepParams = app.SweepDrop.Value;
     p = app.getCurrentParams();

     if ~app.validateParams(p)
         return
     end

     baseVal = p.(sweepParams);
     low =  max(1, baseVal*0.2);
     high = baseVal *5;
     sweepVals = linspace(low, high, 5);

     colours = [
         0.00 0.45 0.74;
         0.47 0.67 0.19;
         0.93 0.69 0.13;
         0.85 0.33 0.10;
         0.49 0.18 0.56];
     cla(app.SweepAxes);
     hold(app.SweepAxes, 'on');
     y_unit = '(K)';

     for k = 1:5
          p.(sweepParams) = sweepVals(k);
          try 
              [t_min, ~, theta2, ~] = app.runSimulation(p);
          catch
              continue
          end


          if app.Display_Celsius
              y2 = theta2 - 273.15;
              y_unit = '(deg C)';

          else
              y2 = theta2;
              y_unit = '(K)';

          end

          lbl = sprintf('%s = %.1f', sweepParams, sweepVals(k));
          plot(app.SweepAxes, t_min, y2, 'Color', colours(k,:), 'LineWidth', 1.8, 'DisplayName', lbl);
     end
     hold(app.SweepAxes, 'off');
    
     % Sweep Plot
     xlabel(app.SweepAxes, 'Time (minutes)');
     ylabel(app.SweepAxes, ['\theta_2' y_unit]);
     title(app.SweepAxes, ['\theta_2 for 5 values of ' sweepParams ' (all other parameters are fixed)']);
     legend(app.SweepAxes, 'Location','best');
     grid(app.SweepAxes, 'on');
     app.SweepAxes.FontSize = 12;
     app.SweepAxes.XLabel.FontWeight = 'bold';
     app.SweepAxes.YLabel.FontWeight = 'bold';
end

function C1SliderChanged(app, ~)
    app.C1Field.Value = app.C1Slider.Value;
end

function C1FieldChanged(app, ~)
   v = max(1, min(500, app.C1Field.Value));
   app.C1Field.Value = v; app.C1Slider.Value = v;

end

function C2SliderChanged(app, ~)
    app.C2Field.Value = app.C2Slider.Value;
end

function C2FieldChanged(app, ~)
   v = max(1, min(500, app.C2Field.Value));
   app.C2Field.Value = v; app.C2Slider.Value = v;

end         

function R1SliderChanged(app, ~)
    app.R1Field.Value = app.R1Slider.Value;
end

function R1FieldChanged(app, ~)
   v = max(0.1, min(500, app.R1Field.Value));
   app.R1Field.Value = v; app.R1Slider.Value = v;

end

function R2SliderChanged(app, ~)
    app.R2Field.Value = app.R2Slider.Value;
end

function R2FieldChanged(app, ~)
   v = max(0.1, min(500, app.R2Field.Value));
   app.R2Field.Value = v; app.R2Slider.Value = v;

end

function R3SliderChanged(app, ~)
    app.R3Field.Value = app.R3Slider.Value;
end

function R3FieldChanged(app, ~)
   v = max(0.1, min(500, app.R3Field.Value));
   app.R3Field.Value = v; app.R3Slider.Value = v;

end

function ThetaASliderChanged(app, ~)
    app.ThetaAField.Value = app.ThetaASlider.Value;
end

function ThetaAFieldChanged(app, ~)
   v = max(200, min(400, app.ThetaAField.Value));
   app.ThetaAField.Value = v; app.ThetaASlider.Value = v;

end

function AmpSliderChanged(app, ~)
    app.AmpField.Value = app.AmpSlider.Value;
end

function AmpFieldChanged(app, ~)
   v = max(0, min(500, app.AmpField.Value));
   app.AmpField.Value = v; app.AmpSlider.Value = v;

end
function StepTimeSliderChanged(app, ~)
    app.StepTimeField.Value = app.StepTimeSlider.Value;
end

function StepTimeFieldChanged(app, ~)
   v = max(0, min(300, app.StepTimeField.Value));
   app.StepTimeField.Value = v; app.StepTimeSlider.Value = v;

end

end

methods (Access = private )
 
% Components of the app are created in this function
function createComponents(app)
     % Main Figure
     app.UIFigure = uifigure('Visible','off');
     app.UIFigure.Position = [50 50 1350 720];
     app.UIFigure.Resize = 'on';
     app.UIFigure.Name = 'ELE120 TASK2 THERMAL SYSTEM SIMULATOR';
     app.UIFigure.Color = [0.94 0.96 0.98];

     % Title Panel 
     titlePanel = uipanel(app.UIFigure);
     titlePanel.Position        = [0 690 1350 30];
     titlePanel.BackgroundColor = [0.10 0.22 0.38];
     titlePanel.BorderType      = 'none';
     
     % Labelling of the Title
     app.TitleLabel = uilabel(titlePanel);
     app.TitleLabel.Position = [10 4 900 22];
     app.TitleLabel.Text = 'Two Capacitance Thermal System';
     app.TitleLabel.FontSize = 13;
     app.TitleLabel.FontWeight = 'bold';
     app.TitleLabel.FontColor  = [1 1 1];
     
     % Parameters panel
     paramPanel = uipanel(app.UIFigure);
     paramPanel.Position        = [0 628 1350 62];
     paramPanel.BackgroundColor = [0.82 0.90 0.97];
     paramPanel.BorderType      = 'none';

     % Sets the parameter sliders and fields
      param_define = {
         'C1 (J/K)', 'C1', 1, 500, 50;
         'C2 (J/K)', 'C2', 1, 500, 60;
         'R1 (K/W)', 'R1', 0.1, 500 ,10;
         'R2 (K/W)', 'R2', 0.1, 500 ,10;
         'R3 (K/W)', 'R3', 0.1, 500 ,10;
         'Ambient(θa)(K)', 'ThetaA', 200, 400, 293.15;
         'Step amp(W)', 'Amp', 0, 500, 3;
         'Step time (min)', 'StepTime', 0, 300, 10
         };

  
  colX  = [8 166 324 482 640 798 956 1114];  
  lblW = 90;   
  fW   = 52;    
  slW  = 130;  


   for k = 1:8
       x = colX(k);
       pLabel = param_define{k,1};
       pTag = param_define{k,2};
       pMin = param_define{k,3};
       pMax = param_define{k,4};
       pVal = param_define{k,5};
       
       % Label
       lbl = uilabel(paramPanel);
       lbl.Position = [x 42 lblW 14];
       lbl.Text = pLabel;
       lbl.FontSize = 12;
       lbl.FontWeight = 'bold'; 
       lbl.FontColor= [0.10 0.22 0.38];
       app.([pTag 'Label']) = lbl;

       %Slider 
       sl = uislider(paramPanel);
       sl.Position = [x 22 slW 3];
       sl.Limits = [pMin pMax];
       sl.Value = pVal;
       sl.FontSize = 8;
       app.([pTag 'Slider']) =sl;
      
       ef = uieditfield(paramPanel, 'numeric');
       ef.Position = [x+lblW+2 40 fW 18];
       ef.Limits = [pMin pMax];
       ef.Value = pVal;
       ef.FontSize = 9;
       app.([pTag 'Field']) = ef;
   end

   % The Button Panel comprising all the buttons
   btnPanel = uipanel(app.UIFigure);
   btnPanel.Position        = [0 592 1350 36];
   btnPanel.BackgroundColor = [0.88 0.93 0.98];
   btnPanel.BorderType      = 'none';

   
   app.RunButton = uibutton(btnPanel, 'Push');
   app.RunButton.Position = [8 6 178 24];
   app.RunButton.Text = 'Run Simulation:Simulink';
   app.RunButton.FontSize = 11;
   app.RunButton.FontWeight = 'bold';
   app.RunButton.BackgroundColor = [0.10 0.22 0.38];
   app.RunButton.FontColor = [1 1 1];

   app.AddCompareButton = uibutton(btnPanel, 'push');
   app.AddCompareButton.Position = [192 6 108 24];
   app.AddCompareButton.Text = 'Add To Compare ';
   app.AddCompareButton.FontWeight = 'bold';
   app.AddCompareButton.FontSize = 11;

   app.ClearCompareButton = uibutton(btnPanel, 'push');
   app.ClearCompareButton.Position = [304 6 108 24];
   app.ClearCompareButton.Text = 'Clear Comparison';
   app.ClearCompareButton.FontWeight = 'bold';
   app.ClearCompareButton.FontSize = 11;

   app.ResetButton = uibutton(btnPanel, 'push');
   app.ResetButton.Position = [416 6 100 24];
   app.ResetButton.Text = 'Reset To Default';
   app.ResetButton.FontWeight = 'bold';
   app.ResetButton.FontSize = 11;

   app.ExportButton = uibutton(btnPanel,'push');
   app.ExportButton.Position = [520 6 100 24];
   app.ExportButton.Text = 'Export Plot As PNG';
   app.ExportButton.FontSize = 10.5;
   app.ExportButton.BackgroundColor = [0.10 0.45 0.28];
   app.ExportButton.FontColor = [1 1 1];

   app.PresetLabel = uilabel(btnPanel);
   app.PresetLabel.Position = [638 10 75 16];
   app.PresetLabel.Text = 'Task 2 quick presets';
   app.PresetLabel.FontWeight = 'bold';
   app.PresetLabel.FontSize = 11;

   app.PresetDrop = uidropdown(btnPanel);
   app.PresetDrop.Position = [716 6 170 24];
   app.PresetDrop.Items = {
       'Select a Case',
       'Default Task 1 values',
       'Case 1: R2 = 50K/W',
       'Case 2: R1 = 50k/W',
       'Case 3: C1 = 150J/K',
       'Case 4: theta_a = 313K'};

   % Preset Dropdown
  app.PresetDrop.Value = 'Select a Case';
  app.PresetDrop.FontWeight = 'bold';
  app.PresetDrop.FontSize = 11;
  
  % Units toggle between Kelvin and Celsius
  app.UnitsLabel = uilabel(btnPanel);
  app.UnitsLabel.Position = [894 10 42 16];
  app.UnitsLabel.Text = 'Units:';
  app.UnitsLabel.FontWeight = 'bold';
  app.UnitsLabel.FontSize = 11;

  app.KelvinButton = uibutton(btnPanel, 'push');
  app.KelvinButton.Position = [936 6 62 24];
  app.KelvinButton.Text = 'Kelvin';
  app.KelvinButton.FontSize = 11;
  app.KelvinButton.BackgroundColor = [0.10 0.22 0.38];
  app.KelvinButton.FontColor = [1 1 1];

  app.CelsiusButton = uibutton(btnPanel, 'push');
  app.CelsiusButton.Position = [1002 6 60 24];
  app.CelsiusButton.Text = 'Celsius';
  app.CelsiusButton.FontWeight = 'bold';
  app.CelsiusButton.FontSize = 11;

  app.CelsiusButton.BackgroundColor = [0.94 0.94 0.94];
  app.CelsiusButton.FontColor = [0.2 0.2 0.2];

  % Main axes the temperature response
  app.MainAxes = uiaxes(app.UIFigure);
  app.MainAxes.Position = [8 297 815 255];

  
  app.SweepLabel = uilabel(app.UIFigure);
  app.SweepLabel.Position  = [8 279 195 18];
  app.SweepLabel.Text = 'Parameter sensitivity sweep:';
  app.SweepLabel.FontSize = 12;
  app.SweepLabel.FontWeight = 'bold';

  app.SweepDrop = uidropdown(app.UIFigure);
  app.SweepDrop.Position = [206 270 110 20];
  app.SweepDrop.Items = {'R1','R2','R3','C1','C2'};
  app.SweepDrop.Value = 'R2';
  app.SweepDrop.FontWeight = 'bold';
  app.SweepDrop.FontSize = 11;

  
  app.SweepButton = uibutton(app.UIFigure, 'push');
  app.SweepButton.Position = [322 270 95 22];
  app.SweepButton.Text = 'Run Sweep';
  app.SweepButton.FontSize = 11;
  app.SweepButton.FontWeight = 'bold';
  app.SweepButton.BackgroundColor = [0.10 0.45 0.28];
  app.SweepButton.FontColor = [1 1 1];
 
  % Parameter Sensitivity
  app.SweepAxes = uiaxes(app.UIFigure);
  app.SweepAxes.Position = [8 8 815 252];


  rightX = 930;
  rightW = 400;
  % Right Column Metrics Table shows the result of the simulation
  app.MetricsLabel = uilabel(app.UIFigure);
  app.MetricsLabel.Position  = [rightX 562 rightW 22];
  app.MetricsLabel.Text = 'Metrics (Simulation)';
  app.MetricsLabel.FontSize = 13;
  app.MetricsLabel.FontWeight = 'bold';
  app.MetricsLabel.HorizontalAlignment = 'center';

  app.MetricsTable = uitable(app.UIFigure);
  app.MetricsTable.Position = [rightX 428 rightW 132];
  app.MetricsTable.ColumnName = {'Metric', 'Theta1(θ₁)','Theta2(θ₂)'};
  app.MetricsTable.FontWeight = 'bold';
  app.MetricsTable.ColumnWidth = {158, 108, 108};
  app.MetricsTable.FontSize = 10;
  app.MetricsTable.Data = {
      'Steady state (K)',          '—', '—';
      'Steady state (deg C)',       '—', '—';
      '2% settling time (min)',     '—', '—';
      'Time constant  (min)',   '—', '—'

      };


  app.HowToLabel            = uilabel(app.UIFigure);
  app.HowToLabel.Position   = [rightX 406 rightW 18];
  app.HowToLabel.Text       = 'How to use';
  app.HowToLabel.FontSize   = 13;
  app.HowToLabel.FontWeight = 'bold';
  app.HowToLabel.HorizontalAlignment = 'center';

  % Guides the user on how to use certain features of the app
  app.HowToArea          = uitextarea(app.UIFigure);
  app.HowToArea.Position = [rightX 210 rightW 194];
  app.HowToArea.Editable = 'off';
  app.HowToArea.FontSize = 11;
  app.HowToArea.FontWeight = 'bold';
  app.HowToArea.Value    = {
        '1. Set parameters using the sliders or type values in the fields above.'
        ''
        '2. Click Run Simulation (Simulink) to run and plot the response.'
        ''
        'To COMPARE two runs:'
        '   a) Run the default simulation first.'
        '   b) Click Add to Compare to save it.'
        '   c) Change a parameter (e.g. set R2 = 50).'
        '   d) Click Run Simulation again.'
        '   e) Both curves appear overlaid. Repeat up to 3 times.'
        '   f) Click Clear Comparison to reset.'
        ''
        'To use PARAMETER SWEEP:'
        '   a) Select a parameter from the sweep dropdown.'
        '   b) Click Run Sweep — 5 values plotted on lower graph.'
        ''
        'Use PRESETS dropdown to instantly load Task 2 cases.'
            };

  app.InterpLabel = uilabel(app.UIFigure);
  app.InterpLabel.Position = [rightX 188 rightW 18];
  app.InterpLabel.Text = 'Physical Interpretation';
  app.InterpLabel.FontSize = 13;
  app.InterpLabel.FontWeight = 'bold';
  app.InterpLabel.HorizontalAlignment = 'center';

  % Gives the interpretation of the plot for understanding 
  app.InterpretationArea = uitextarea(app.UIFigure);
  app.InterpretationArea.Position = [rightX 8 rightW 178];
  app.InterpretationArea.Value = {'Set the parameters and press Run Simulation to see'
      'a physical interpretation here.'
      };
  app.InterpretationArea.FontSize = 11;
  app.InterpretationArea.FontWeight = 'bold';
  app.InterpretationArea.Editable = 'off';

  % Removing all the tick labels in the slider for clarity
 app.C1Slider.MajorTicks       = [];   app.C1Slider.MinorTicks       = [];
 app.C2Slider.MajorTicks       = [];   app.C2Slider.MinorTicks       = [];
 app.R1Slider.MajorTicks       = [];   app.R1Slider.MinorTicks       = [];
 app.R2Slider.MajorTicks       = [];   app.R2Slider.MinorTicks       = [];
 app.R3Slider.MajorTicks       = [];   app.R3Slider.MinorTicks       = [];
 app.ThetaASlider.MajorTicks   = [];   app.ThetaASlider.MinorTicks   = [];
 app.AmpSlider.MajorTicks      = [];   app.AmpSlider.MinorTicks      = [];
 app.StepTimeSlider.MajorTicks = [];   app.StepTimeSlider.MinorTicks = [];

  % Assigning callbacks for all the functions created
  app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);
  app.AddCompareButton.ButtonPushedFcn = createCallbackFcn(app, @AddCompareButtonPushed, true);
  app.ClearCompareButton.ButtonPushedFcn = createCallbackFcn(app, @ClearCompareButtonPushed, true);
  app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
  app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
  app.PresetDrop.ValueChangedFcn = createCallbackFcn(app, @PresetDropChanged, true);
  app.KelvinButton.ButtonPushedFcn = createCallbackFcn(app, @KelvinButtonPushed, true);
  app.CelsiusButton.ButtonPushedFcn = createCallbackFcn(app, @CelsiusButtonPushed, true);
  app.SweepButton.ButtonPushedFcn = createCallbackFcn(app, @SweepButtonPushed, true);


  app.C1Slider.ValueChangedFcn = createCallbackFcn(app, @C1SliderChanged, true);
  app.C2Slider.ValueChangedFcn = createCallbackFcn(app, @C2SliderChanged, true);
  app.R1Slider.ValueChangedFcn = createCallbackFcn(app, @R1SliderChanged, true);
  app.R2Slider.ValueChangedFcn = createCallbackFcn(app, @R2SliderChanged, true);
  app.R3Slider.ValueChangedFcn = createCallbackFcn(app, @R3SliderChanged, true);
  app.ThetaASlider.ValueChangedFcn = createCallbackFcn(app, @ThetaASliderChanged, true);
  app.AmpSlider.ValueChangedFcn = createCallbackFcn(app, @AmpSliderChanged, true);
  app.StepTimeSlider.ValueChangedFcn = createCallbackFcn(app, @StepTimeSliderChanged, true);

  app.C1Field.ValueChangedFcn = createCallbackFcn (app, @C1FieldChanged, true);
  app.C2Field.ValueChangedFcn = createCallbackFcn (app, @C2FieldChanged, true);
  app.R1Field.ValueChangedFcn = createCallbackFcn (app, @R1FieldChanged, true);
  app.R2Field.ValueChangedFcn = createCallbackFcn (app, @R2FieldChanged, true);
  app.R3Field.ValueChangedFcn = createCallbackFcn (app, @R3FieldChanged, true);
  app.ThetaAField.ValueChangedFcn = createCallbackFcn (app, @ThetaAFieldChanged, true);
  app.AmpField.ValueChangedFcn = createCallbackFcn (app, @AmpFieldChanged, true);
  app.StepTimeField.ValueChangedFcn = createCallbackFcn (app, @StepTimeFieldChanged, true);
  

  fprintf('\n     ELE120 THERMAL SYSTEMS TASK2     \n');
  fprintf('Simulink Model Used : thermal_model_simulink.slx\n');
  fprintf('Default values: C1=50, C2=60, R1=R2=R3=10 ThetaA = 293.15K  Amp=3W\n\n');
  app.UIFigure.Visible = 'on';

end
end

% Opening and Closing of the apps.
methods(Access = public)
  
       function app = app
          createComponents(app);
          registerApp(app, app.UIFigure);
       if nargout == 0 
           clear app
       end
       end

       function delete(app)
         delete(app.UIFigure);
       end

       
end
end


