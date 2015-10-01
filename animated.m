function [ret] = animated(file, varargin)
% ANIMATED  Create a graphical interface to visualise aerospace data.
%
%  ANIMATED(file) creates a graphical interface containing an animation
%      of the hill frame with the data inside file. file is a char array
%      containing the name of the file.
%      Ex.: animated('traject.mat');
%
%      file MUST be structured in the following way:
%      - traject.sc: a struct 1xn, where n is the number of objects.
%          - traject.sc(1,n).state: array of size 6xN, where N is the
%              number of frames.
%              - traject.sc(1,n).state(1,N): x position data.
%              - traject.sc(1,n).state(2,N): y position data.
%              - traject.sc(1,n).state(3,N): z position data.
%              - traject.sc(1,n).state(4,N): x velocity data.
%              - traject.sc(1,n).state(5,N): y velocity data.
%              - traject.sc(1,n).state(6,N): z velocity data.
%          - traject.sc(1,n).t: time data, array of size 1xN.
%
%  ANIMATED(file, centered_type) same as above, but will also create
%      another axes with an animation of the inertial frame.
%      centered_type is a char array that can be either:
%          'earth-centered': Earth as the center of the inertial frame; or
%          'sun-centered': Sun as the center of the inertial frame.
%      Ex.: animated('traject.mat','earth-centered');
%
%      When file and centered-type are given, file MUST included the
%          following variables (along with the variables described above):
%      - a: a parameter (scalar).
%      - ec: excentricity parameter of orbit (scalar).
%      - mu: mu parameter (scalar).
%      - theta: theta parameter (1xN array).
%      - inc: inc parameter (scalar).
%      - omega: omega parameter (scalar).
%      - Omega: Omega parameter (scalar).
%
%
%  Description of GUI:
%   
%  - Video Control:
%      - Speed (popupmenu): choose speed of animation.
%      - Hill Frame (checkbox): enable/disable hill axes.
%          - Centered (checkbox): move hill axes to the center of the
%              figure.
%      - Inertial Frame (checkbox): enable/disable inertial axes.
%          - Centered (checkbox): move inertial axes to the center of the
%              figure.
%   
%  - Global Options:
%      - Loop animation (checkbox): if enabled, animation will restart when
%          it reaches last point. If disabled, animation will be paused 
%          at the last point.
%      - Grid (pushbutton): enables/disables grid.
%      - Rotate (pushbutton): enables/disables rotation of axes.
%      - Zoom In (pushbutton): enables/disables zoom of axes.
%      - Zoom Out (pushbutton): return axes to initial position.
%      - Keypress Support (pushbutton): enables/disables support for keyboard.
%          - 'p': pauses animation.
%          - 'r': restarts animation.
%          - '>': increases speed.
%          - '<': decreases speed.
%          - 'R': starts/pauses recording.
%          - Arrow Right: moves slider position forwards by 2*speed.
%          - Arrow Left: moves slider position backwards by 2*speed.
%
%  - Local Options:
%      - Select Object (popupmenu)
%          - Enable (checkbox): enable/disable visualisation of object and 
%              trace.
%          - Trace (checkbox): enable/disable visualisation of trace.
%          - Velocity (checkbox): enable/disable visualisation of velocity
%              vector.
%          - Select (checkbox): if enabled, object is selected and every
%             other object visualisation is disabled. if disabled, all 
%             objects' visualisation is enabled.
%
%  - Record Movie:
%      - Start (pushbutton): if pressed, start recording. If then unpressed, 
%          recording is stopped.
%          Warning: if output file already exists, then the program will NOT
%              record and will output an error. The button will then be 
%              unpressed indicating that it is NOT recording.
%      - Go to (edit): go to time specified in the box.
%      - Output File (edit): change output file name (64 characters maximum).
%      - Quality (edit): change quality of compression (number from 0 to
%          100).
%      - Frames Per Second (edit): change number of frames per second in
%          movie.
%

%
% Copyright (c) 2014 Luis Paulo Manfre Ribeiro
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.
%
%  Author: Luis Paulo Manfre Ribeiro
%  Scholarship Student from CNPq - Brazil
%  University of Glasgow

        %{
        %  Opengl set to 'software' because 'hardware' has some bugs
        %  when recording frames.
        %}
        opengl('software');
        
        %{
        %  Check if file exists
        %}
        if exist(file, 'file') ~= 2
                error('file not found');
                ret = 0;
                return;
        end
        
        %{
        %  'mu' is also the name of a function in Matlab
        %}
        mu = [];
        
        load(file);
        
        num_objects = size(traject.sc, 2);
        num_frames = size(traject.sc(1,1).state, 2);
        data = zeros(num_objects, num_frames, 7);
        for i=1:num_objects
                data(i,:,1:6) = traject.sc(1,i).state';
                data(i,:,7) = traject.sc(1,i).t';
        end
        
        %{
        %  Validate input
        %}
        num_objects = size(data, 1);
        if num_objects <= 0
                error('invalid data');
                ret = 0;
                return;
        end
        
        %{
        %  Check hill frame data input
        %}
        num_columns = size(data, 3);
        if num_columns < 7
                error('too little data');
                ret = 0;
                return;
        elseif num_columns > 7
                error('too much data');
                ret = 0;
                return;
        end
        
        %{
        %  Validate inertial frame data input
        %}
        num_arg = nargin;
        if num_arg < 1
                error('too few arguments');
                ret = 0;
                return;
        elseif num_arg > 2
                error('too many arguments');
                ret = 0;
                return;
        end
        
        %{
        %  Check string input
        %}
        if num_arg > 1 && ~ischar(varargin{1})
                error('invalid input');
                ret = 0;
                return;
        end
        
        num_objects = size(data, 1);
        centered_option_is_enabled = 0;
        textured_body_is_enabled = 1;
        
        NOT_CENTERED    = 0;
        EARTH_CENTERED  = 1;
        SUN_CENTERED    = 2;

        num_axes = 1;
        
        HILL     = 1;
        INERTIAL = 2;

        %{
        %  Parse string input 
        %}
        if num_arg > 1
                string = varargin{1};
                if strcmp(string, 'earth-centered')
                        centered_option_is_enabled = 1;
                        num_axes = 2;
                        centered_type = EARTH_CENTERED;
                elseif strcmp(string, 'sun-centered')
                        centered_option_is_enabled = 1;
                        num_axes = 2;
                        centered_type = SUN_CENTERED;
                else
                    	error('invalid option: ''%s''', string);
                        ret = 0;
                        return; 
                end
        end      

        %{
        %  Check time values
        %}
        start_time = data(1,1,7);
        stop_time = data(1,end,7);
        num_frames = size(data,2);
        for i=1:num_objects
                new_start_time = data(i,1,7);
                new_stop_time = data(i,end,7);
                if new_start_time ~= start_time
                        error('objects start times differ');
                        ret = 0;
                        return;
                elseif new_stop_time ~= stop_time
                        error('objects stop time differ');
                        ret = 0;
                        return;
                end
                time_frame = data(i,1,7);
                for j=2:num_frames
                        new_time_frame = data(i,j,7);
                        if new_time_frame < 0
                                error('negative time');
                                ret = 0;
                                return;
                        elseif time_frame >= new_time_frame 
                                error('invalid time data');
                                ret = 0;
                                return;
                        end
                end
        end
        
        %{
        %  Parse input into 3 main arrays
        %}
        X_tmp = zeros(num_axes, num_frames, num_objects);
        Y_tmp = zeros(num_axes, num_frames, num_objects);
        Z_tmp = zeros(num_axes, num_frames, num_objects);
        vx_tmp = zeros(num_axes, num_frames, num_objects);
        vy_tmp = zeros(num_axes, num_frames, num_objects);
        vz_tmp = zeros(num_axes, num_frames, num_objects);
        t_tmp = zeros(num_frames, num_objects);

        for i=1:num_objects
                X_tmp(HILL,:,i) = data(i,:,1);
                Y_tmp(HILL,:,i) = data(i,:,2);
                Z_tmp(HILL,:,i) = data(i,:,3);
                vx_tmp(HILL,:,i) = data(i,:,4);
                vy_tmp(HILL,:,i) = data(i,:,5);
                vz_tmp(HILL,:,i) = data(i,:,6);
                t_tmp(:,i) = data(i,:,7);
        end
        
        %{
        %  Transformation from hill to inertial frame
        %  __if required by the user__
        %}
        if centered_option_is_enabled
                r = traject.sc(1,1).r;
                
                co_Omega = cos(Omega);
                si_Omega = sin(Omega);
                co_omega = cos(omega);
                si_omega = sin(omega);
                co_inc = cos(inc);
                si_inc = sin(inc);
                
                M11 = co_Omega * co_omega - si_Omega * co_inc * si_omega;
                M12 = -co_Omega * si_omega - si_Omega * co_inc * co_omega;
                M13 = si_Omega * si_inc;
                M21 = si_Omega * co_omega + co_Omega * co_inc * si_omega;
                M22 = -si_Omega * si_omega + co_Omega * co_inc * co_omega;
                M23 = -co_Omega * si_inc;
                M31 = si_inc * si_omega;
                M32 = si_inc * co_omega;
                M33 = co_inc;
                M = [M11 M12 M13; M21 M22 M23; M31 M32 M33];
                
                hill_pos = zeros(3, num_frames);      
                inertial_pos = zeros(3, num_frames);
                
                for i=1:num_objects
                        for j=1:num_frames
                                si_theta = sin(theta(1,j));
                                co_theta = cos(theta(1,j));
                                
                                drp  = (mu/sqrt(mu*a*(1 - ec^2))) * ...
                                    [-si_theta; ec + co_theta; 0];

                                rp   = r(1,j) * [co_theta; si_theta; 0];
                                
                                hill_pos(1,j) = X_tmp(HILL,j,i);
                                hill_pos(2,j) = Y_tmp(HILL,j,i);
                                hill_pos(3,j) = Z_tmp(HILL,j,i);
                      
                                rin     = M * rp;
                                drin    = M * drp;
                                h       = cross(rin,drin);
                                or      = rin/norm(rin);
                                oh  	= h/norm(h);
                                ot      = cross(oh,or);
                                ON      = [or'; ot'; oh'];
                                
                                inertial_pos(1:3,j) = rin + ON'*hill_pos(1:3,j);
                                
                                vx_tmp(INERTIAL,j,i) = drin(1,1);
                                vy_tmp(INERTIAL,j,i) = drin(2,1);
                                vz_tmp(INERTIAL,j,i) = drin(3,1);
                        end
                        X_tmp(INERTIAL,:,i) = inertial_pos(1,:);
                        Y_tmp(INERTIAL,:,i) = inertial_pos(2,:);
                        Z_tmp(INERTIAL,:,i) = inertial_pos(3,:);
                end
        end
        
        %{
        %  Interpolate data
        %}
        min_time_period = 1;
        start_time = round(data(1,1,7));
        stop_time = round(data(1,end,7));
        num_frames = 1+round((stop_time - start_time) / min_time_period);
        
        X = zeros(num_axes, num_frames, num_objects);
        Y = zeros(num_axes, num_frames, num_objects);
        Z = zeros(num_axes, num_frames, num_objects);
        vx = zeros(num_axes, num_frames, num_objects);
        vy = zeros(num_axes, num_frames, num_objects);
        vz = zeros(num_axes, num_frames, num_objects);
        t = zeros(num_frames, 1);
        
        t(:,1) = start_time:min_time_period:stop_time;
        for j=1:num_axes
                for i=1:num_objects
                        X(j,:,i) = interp1(t_tmp(:,i), X_tmp(j,:,i), t(:,1));
                        Y(j,:,i) = interp1(t_tmp(:,i), Y_tmp(j,:,i), t(:,1));
                        Z(j,:,i) = interp1(t_tmp(:,i), Z_tmp(j,:,i), t(:,1));
                        vx(j,:,i) = interp1(t_tmp(:,i), vx_tmp(j,:,i), t(:,1));
                        vy(j,:,i) = interp1(t_tmp(:,i), vy_tmp(j,:,i), t(:,1));
                        vz(j,:,i) = interp1(t_tmp(:,i), vz_tmp(j,:,i), t(:,1));
                end
        end
        
        %{
        %  Correct the last elements of the inertial array, in order to 
        %  link the final point to the first point
        %}
        if num_axes == 2
            X(INERTIAL,end,:) = X(INERTIAL,1,:);
            Y(INERTIAL,end,:) = Y(INERTIAL,1,:);
            Z(INERTIAL,end,:) = Z(INERTIAL,1,:);
        end
        
        %{
        %  Set variables and constants
        %  __There is no support for resizing windows manually, yet__
        %}
        SCREEN = get(0, 'screensize');
        SCREEN_WIDTH = SCREEN(3);
        SCREEN_HEIGHT = SCREEN(4);

        %{
        %  This is an 'acceptable' value. A period lesser
        %  than this may make some computers struggle.
        %}
        timer_period = 0.1;
        timer_update_gui_period = 0.1;

        FIGURE_WIDTH  = 0.7000*SCREEN_WIDTH;
        FIGURE_HEIGHT = 0.7812*SCREEN_HEIGHT;
        FIGURE_LEFT = 0.2660*SCREEN_WIDTH;
        FIGURE_BOTTOM = 0.1302*SCREEN_HEIGHT;
        FIGURE_POSITION = [FIGURE_LEFT FIGURE_BOTTOM ...
                                FIGURE_WIDTH FIGURE_HEIGHT];
                            
        %{
        %  These positions are relative to FIGURE limits.
        %  Matlab automatically assigns objects (in this case, the buttons)
        %  within the range of their parents (in this case, FIGURE)
        %}
        BOX_LEFT = 0.0550 * FIGURE_WIDTH + 0.015*SCREEN_WIDTH;
        BOX_BORDER_WIDTH = 4*0.0275*SCREEN_WIDTH;
        BOX_WIDTH = 3*0.0275*SCREEN_WIDTH;
        BOX_HEIGHT = 0.0200*SCREEN_HEIGHT;

        %{
        %  Axes borders
        %}
        AXES_BORDER_INERTIAL_WIDTH  = 0.20*SCREEN_WIDTH;
        AXES_BORDER_INERTIAL_HEIGHT = 0.45*SCREEN_HEIGHT;
        AXES_BORDER_INERTIAL_LEFT = 0.22*SCREEN_WIDTH;
        AXES_BORDER_INERTIAL_BOTTOM = 0.28*SCREEN_HEIGHT;
        AXES_BORDER_INERTIAL_POSITION = [AXES_BORDER_INERTIAL_LEFT  AXES_BORDER_INERTIAL_BOTTOM ...
                                         AXES_BORDER_INERTIAL_WIDTH AXES_BORDER_INERTIAL_HEIGHT];

        AXES_BORDER_HILL_WIDTH  = 0.20*SCREEN_WIDTH;
        AXES_BORDER_HILL_HEIGHT = 0.45*SCREEN_HEIGHT;
        AXES_BORDER_HILL_LEFT = 0.47*SCREEN_WIDTH;
        AXES_BORDER_HILL_BOTTOM = 0.30*SCREEN_HEIGHT;
        AXES_BORDER_HILL_POSITION = [AXES_BORDER_HILL_LEFT  AXES_BORDER_HILL_BOTTOM ...
                                     AXES_BORDER_HILL_WIDTH AXES_BORDER_HILL_HEIGHT];

        %{
        %  Axes
        %}                              
        AXES_HILL_WIDTH  = 0.20*SCREEN_WIDTH;
        AXES_HILL_HEIGHT = 0.50*SCREEN_HEIGHT;
        AXES_HILL_LEFT = 5*FIGURE_WIDTH/16 - AXES_HILL_WIDTH/2;
        AXES_HILL_BOTTOM = 0.39*FIGURE_HEIGHT;
        AXES_HILL_POSITION = [AXES_HILL_LEFT  AXES_HILL_BOTTOM ...
                              AXES_HILL_WIDTH AXES_HILL_HEIGHT];
                              
        AXES_INERTIAL_WIDTH  = 0.20*SCREEN_WIDTH;
        AXES_INERTIAL_HEIGHT = 0.50*SCREEN_HEIGHT;
        AXES_INERTIAL_LEFT = 12*FIGURE_WIDTH/16 - AXES_INERTIAL_WIDTH/2;
        AXES_INERTIAL_BOTTOM = 0.39*FIGURE_HEIGHT;
        AXES_INERTIAL_POSITION = [AXES_INERTIAL_LEFT  AXES_INERTIAL_BOTTOM ...
                                  AXES_INERTIAL_WIDTH AXES_INERTIAL_HEIGHT];
                             
        AXES_CENTERED_WIDTH  = 0.20*SCREEN_WIDTH;
        AXES_CENTERED_HEIGHT = 0.50*SCREEN_HEIGHT;
        AXES_CENTERED_LEFT = FIGURE_WIDTH/2 - AXES_HILL_WIDTH/2;
        AXES_CENTERED_BOTTOM = 0.39*FIGURE_HEIGHT;
        AXES_CENTERED_POSITION = [AXES_CENTERED_LEFT  AXES_CENTERED_BOTTOM ...
                                  AXES_CENTERED_WIDTH AXES_CENTERED_HEIGHT];            
        %{
        %  Local boxes
        %}
        NUM_BOXES = 6;
        ADJUST = 0.0125 * SCREEN_HEIGHT;
        
        BOX_BORDER_LOCAL_LEFT = BOX_LEFT + 0.4*FIGURE_WIDTH;
        BOX_BORDER_LOCAL_BOTTOM = 0.07*SCREEN_HEIGHT;
        BOX_BORDER_LOCAL_WIDTH = BOX_BORDER_WIDTH;
        BOX_BORDER_LOCAL_HEIGHT = 6*0.0260*SCREEN_HEIGHT;
        BOX_BORDER_LOCAL_POSITION = [BOX_BORDER_LOCAL_LEFT  BOX_BORDER_LOCAL_BOTTOM ...
                                     BOX_BORDER_LOCAL_WIDTH BOX_BORDER_LOCAL_HEIGHT];

        TEXT_BOX_BORDER_LOCAL_LEFT = BOX_BORDER_LOCAL_LEFT + 0.0050*SCREEN_WIDTH;
        TEXT_BOX_BORDER_LOCAL_BOTTOM = BOX_BORDER_LOCAL_BOTTOM + ...
                BOX_BORDER_LOCAL_HEIGHT - 0.0070*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_LOCAL_WIDTH = 3*0.0275*SCREEN_WIDTH;
        TEXT_BOX_BORDER_LOCAL_HEIGHT = 1*0.0260*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_LOCAL_POSITION = [TEXT_BOX_BORDER_LOCAL_LEFT  TEXT_BOX_BORDER_LOCAL_BOTTOM ...
                                          TEXT_BOX_BORDER_LOCAL_WIDTH TEXT_BOX_BORDER_LOCAL_HEIGHT];

        POPUPMENU_LEFT = BOX_BORDER_LOCAL_LEFT + ...
                (BOX_BORDER_LOCAL_WIDTH - BOX_WIDTH)/2;
        POPUPMENU_BOTTOM = BOX_BORDER_LOCAL_BOTTOM + ...
                (NUM_BOXES)*(BOX_BORDER_LOCAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        POPUPMENU_WIDTH = BOX_WIDTH;
        POPUPMENU_HEIGHT = BOX_HEIGHT;
        POPUPMENU_POSITION = [POPUPMENU_LEFT  POPUPMENU_BOTTOM ...
                              POPUPMENU_WIDTH POPUPMENU_HEIGHT];

        BOX_OBJ_ENABLE_LEFT = BOX_BORDER_LOCAL_LEFT + ...
                (BOX_BORDER_LOCAL_WIDTH - BOX_WIDTH)/2;
        BOX_OBJ_ENABLE_BOTTOM = BOX_BORDER_LOCAL_BOTTOM + ...
                (NUM_BOXES-1)*(BOX_BORDER_LOCAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_OBJ_ENABLE_WIDTH = BOX_WIDTH;
        BOX_OBJ_ENABLE_HEIGHT = BOX_HEIGHT;
        BOX_OBJ_ENABLE_POSITION = [BOX_OBJ_ENABLE_LEFT  BOX_OBJ_ENABLE_BOTTOM ...
                                   BOX_OBJ_ENABLE_WIDTH BOX_OBJ_ENABLE_HEIGHT];

        BOX_OBJ_TRACE_LEFT = BOX_BORDER_LOCAL_LEFT + ...
                (BOX_BORDER_LOCAL_WIDTH - BOX_WIDTH)/2;
        BOX_OBJ_TRACE_BOTTOM = BOX_BORDER_LOCAL_BOTTOM + ...
                (NUM_BOXES-2)*(BOX_BORDER_LOCAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_OBJ_TRACE_WIDTH = BOX_WIDTH;
        BOX_OBJ_TRACE_HEIGHT = BOX_HEIGHT;
        BOX_OBJ_TRACE_POSITION = [BOX_OBJ_TRACE_LEFT   BOX_OBJ_TRACE_BOTTOM ...
                                  BOX_OBJ_TRACE_WIDTH BOX_OBJ_TRACE_HEIGHT];

        BOX_OBJ_VEL_LEFT = BOX_BORDER_LOCAL_LEFT + ...
                (BOX_BORDER_LOCAL_WIDTH - BOX_WIDTH)/2;
        BOX_OBJ_VEL_BOTTOM = BOX_BORDER_LOCAL_BOTTOM + ...
                (NUM_BOXES-3)*(BOX_BORDER_LOCAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_OBJ_VEL_WIDTH = BOX_WIDTH;
        BOX_OBJ_VEL_HEIGHT = BOX_HEIGHT;
        BOX_OBJ_VEL_POSITION = [BOX_OBJ_VEL_LEFT  BOX_OBJ_VEL_BOTTOM ...
                                BOX_OBJ_VEL_WIDTH BOX_OBJ_VEL_HEIGHT];

        BOX_OBJ_SELECT_LEFT = BOX_BORDER_LOCAL_LEFT + ...
                (BOX_BORDER_LOCAL_WIDTH - BOX_WIDTH)/2;
        BOX_OBJ_SELECT_BOTTOM = BOX_BORDER_LOCAL_BOTTOM + ...
                (NUM_BOXES-4)*(BOX_BORDER_LOCAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_OBJ_SELECT_WIDTH = BOX_WIDTH;
        BOX_OBJ_SELECT_HEIGHT = BOX_HEIGHT;
        BOX_OBJ_SELECT_POSITION = [BOX_OBJ_SELECT_LEFT  BOX_OBJ_SELECT_BOTTOM ...
                                   BOX_OBJ_SELECT_WIDTH BOX_OBJ_SELECT_HEIGHT];
                               
        BOX_OBJ_COLOR_LEFT = BOX_BORDER_LOCAL_LEFT + ...
                (BOX_BORDER_LOCAL_WIDTH - BOX_WIDTH)/2;
        BOX_OBJ_COLOR_BOTTOM = BOX_BORDER_LOCAL_BOTTOM + ...
                (NUM_BOXES-5)*(BOX_BORDER_LOCAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_OBJ_COLOR_WIDTH = BOX_WIDTH;
        BOX_OBJ_COLOR_HEIGHT = BOX_HEIGHT;
        BOX_OBJ_COLOR_POSITION = [BOX_OBJ_COLOR_LEFT  BOX_OBJ_COLOR_BOTTOM ...
                                  BOX_OBJ_COLOR_WIDTH BOX_OBJ_COLOR_HEIGHT];

        %{
        % Global box
        %}
        NUM_BOXES = 6;
        ADJUST = 0.0125 * SCREEN_HEIGHT;
        
        BOX_BORDER_GLOBAL_LEFT = BOX_LEFT + 0.2*FIGURE_WIDTH;
        BOX_BORDER_GLOBAL_BOTTOM = 0.07*SCREEN_HEIGHT;
        BOX_BORDER_GLOBAL_WIDTH = BOX_BORDER_WIDTH;
        BOX_BORDER_GLOBAL_HEIGHT = 6*0.0260*SCREEN_HEIGHT;
        BOX_BORDER_GLOBAL_POSITION = [BOX_BORDER_GLOBAL_LEFT  BOX_BORDER_GLOBAL_BOTTOM ...
                                      BOX_BORDER_GLOBAL_WIDTH BOX_BORDER_GLOBAL_HEIGHT];

        TEXT_BOX_BORDER_GLOBAL_LEFT = BOX_BORDER_GLOBAL_LEFT + 0.0050*SCREEN_WIDTH;
        TEXT_BOX_BORDER_GLOBAL_BOTTOM = BOX_BORDER_GLOBAL_BOTTOM + ...
                    BOX_BORDER_GLOBAL_HEIGHT - 0.0120*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_GLOBAL_WIDTH = 3*0.0275*SCREEN_WIDTH;
        TEXT_BOX_BORDER_GLOBAL_HEIGHT = 1*0.0260*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_GLOBAL_POSITION = [TEXT_BOX_BORDER_GLOBAL_LEFT  TEXT_BOX_BORDER_GLOBAL_BOTTOM ...
                                           TEXT_BOX_BORDER_GLOBAL_WIDTH TEXT_BOX_BORDER_GLOBAL_HEIGHT];

        BOX_LOOP_LEFT = BOX_BORDER_GLOBAL_LEFT + ...
                    (BOX_BORDER_GLOBAL_WIDTH - BOX_WIDTH)/2;
        BOX_LOOP_BOTTOM = BOX_BORDER_GLOBAL_BOTTOM + ...
                    (NUM_BOXES)*(BOX_BORDER_GLOBAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_LOOP_WIDTH = BOX_WIDTH;
        BOX_LOOP_HEIGHT = BOX_HEIGHT;
        BOX_LOOP_POSITION = [BOX_LOOP_LEFT  BOX_LOOP_BOTTOM ...
                             BOX_LOOP_WIDTH BOX_LOOP_HEIGHT];

        BOX_GRID_LEFT = BOX_BORDER_GLOBAL_LEFT + ...
                    (BOX_BORDER_GLOBAL_WIDTH - BOX_WIDTH)/2;
        BOX_GRID_BOTTOM = BOX_BORDER_GLOBAL_BOTTOM + ...
                    (NUM_BOXES-1)*(BOX_BORDER_GLOBAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_GRID_WIDTH = BOX_WIDTH;
        BOX_GRID_HEIGHT = BOX_HEIGHT;
        BOX_GRID_POSITION = [BOX_GRID_LEFT  BOX_GRID_BOTTOM ...
                             BOX_GRID_WIDTH BOX_GRID_HEIGHT];

        GLOBAL_CONTROLGROUP_LEFT = 0;
        GLOBAL_CONTROLGROUP_BOTTOM = 0;
        GLOBAL_CONTROLGROUP_WIDTH = 5*0.0275*SCREEN_WIDTH;
        GLOBAL_CONTROLGROUP_HEIGHT = (3*0.0260+2*0.030)*SCREEN_HEIGHT;
        GLOBAL_CONTROLGROUP_POSITION = [GLOBAL_CONTROLGROUP_LEFT  GLOBAL_CONTROLGROUP_BOTTOM ...
                                        GLOBAL_CONTROLGROUP_WIDTH GLOBAL_CONTROLGROUP_HEIGHT];

        BOX_ROTATE_LEFT = BOX_BORDER_GLOBAL_LEFT + ...
                    (BOX_BORDER_GLOBAL_WIDTH - BOX_WIDTH)/2;
        BOX_ROTATE_BOTTOM = BOX_BORDER_GLOBAL_BOTTOM + ...
                    (NUM_BOXES-2)*(BOX_BORDER_GLOBAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_ROTATE_WIDTH = BOX_WIDTH;
        BOX_ROTATE_HEIGHT = BOX_HEIGHT;
        BOX_ROTATE_POSITION = [BOX_ROTATE_LEFT  BOX_ROTATE_BOTTOM ...
                               BOX_ROTATE_WIDTH BOX_ROTATE_HEIGHT];

        BOX_ZOOM_IN_LEFT = BOX_BORDER_GLOBAL_LEFT + ...
                    (BOX_BORDER_GLOBAL_WIDTH - BOX_WIDTH)/2;
        BOX_ZOOM_IN_BOTTOM = BOX_BORDER_GLOBAL_BOTTOM + ...
                    (NUM_BOXES-3)*(BOX_BORDER_GLOBAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_ZOOM_IN_WIDTH = BOX_WIDTH;
        BOX_ZOOM_IN_HEIGHT = BOX_HEIGHT;
        BOX_ZOOM_IN_POSITION = [BOX_ZOOM_IN_LEFT  BOX_ZOOM_IN_BOTTOM ...
                                BOX_ZOOM_IN_WIDTH BOX_ZOOM_IN_HEIGHT];

        BOX_ZOOM_OUT_LEFT = BOX_BORDER_GLOBAL_LEFT + ...
                    (BOX_BORDER_GLOBAL_WIDTH - BOX_WIDTH)/2;
        BOX_ZOOM_OUT_BOTTOM = BOX_BORDER_GLOBAL_BOTTOM + ...
                    (NUM_BOXES-4)*(BOX_BORDER_GLOBAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_ZOOM_OUT_WIDTH = BOX_WIDTH;
        BOX_ZOOM_OUT_HEIGHT = BOX_HEIGHT;
        BOX_ZOOM_OUT_POSITION = [BOX_ZOOM_OUT_LEFT  BOX_ZOOM_OUT_BOTTOM ...
                                 BOX_ZOOM_OUT_WIDTH BOX_ZOOM_OUT_HEIGHT];

        BOX_KEYPRESS_LEFT = BOX_BORDER_GLOBAL_LEFT + ...
                    (BOX_BORDER_GLOBAL_WIDTH - BOX_WIDTH)/2;
        BOX_KEYPRESS_BOTTOM = BOX_BORDER_GLOBAL_BOTTOM + ...
                    (NUM_BOXES-5)*(BOX_BORDER_GLOBAL_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_KEYPRESS_WIDTH = BOX_WIDTH;
        BOX_KEYPRESS_HEIGHT = BOX_HEIGHT;
        BOX_KEYPRESS_POSITION = [BOX_KEYPRESS_LEFT  BOX_KEYPRESS_BOTTOM ...
                                 BOX_KEYPRESS_WIDTH BOX_KEYPRESS_HEIGHT];
          
        %{
        %  Record box
        %}
        NUM_BOXES = 5;
        ADJUST = 0.0125 * SCREEN_HEIGHT;

        BOX_BORDER_RECORD_LEFT = BOX_LEFT + 0.6*FIGURE_WIDTH;
        BOX_BORDER_RECORD_BOTTOM = 0.07*SCREEN_HEIGHT;
        BOX_BORDER_RECORD_WIDTH = BOX_BORDER_WIDTH*2 - 2*ADJUST;
        BOX_BORDER_RECORD_HEIGHT = 6*0.0260*SCREEN_HEIGHT;
        BOX_BORDER_RECORD_POSITION = [BOX_BORDER_RECORD_LEFT  BOX_BORDER_RECORD_BOTTOM ...
                                      BOX_BORDER_RECORD_WIDTH BOX_BORDER_RECORD_HEIGHT];

        TEXT_BOX_BORDER_RECORD_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    0.0050*SCREEN_WIDTH;
        TEXT_BOX_BORDER_RECORD_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    BOX_BORDER_RECORD_HEIGHT - 0.0070*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_RECORD_WIDTH = 3*0.0275*SCREEN_WIDTH;
        TEXT_BOX_BORDER_RECORD_HEIGHT = 1*0.0260*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_RECORD_POSITION = [TEXT_BOX_BORDER_RECORD_LEFT  TEXT_BOX_BORDER_RECORD_BOTTOM ...
                                           TEXT_BOX_BORDER_RECORD_WIDTH TEXT_BOX_BORDER_RECORD_HEIGHT];
                         
        BUTTON_RECORD_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    (BOX_BORDER_RECORD_WIDTH - 2*BOX_WIDTH)/3;
        BUTTON_RECORD_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BUTTON_RECORD_WIDTH = BOX_WIDTH;
        BUTTON_RECORD_HEIGHT = BOX_HEIGHT;
        BUTTON_RECORD_POSITION = [BUTTON_RECORD_LEFT  BUTTON_RECORD_BOTTOM ...
                                  BUTTON_RECORD_WIDTH BUTTON_RECORD_HEIGHT];
                              
        TEXT_GOTO_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    (BOX_BORDER_RECORD_WIDTH - 2*BOX_WIDTH)/3;
        TEXT_GOTO_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-1)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        TEXT_GOTO_WIDTH = BOX_WIDTH;
        TEXT_GOTO_HEIGHT = BOX_HEIGHT;
        TEXT_GOTO_POSITION = [TEXT_GOTO_LEFT  TEXT_GOTO_BOTTOM ...
                              TEXT_GOTO_WIDTH TEXT_GOTO_HEIGHT];

        EDIT_GOTO_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    (BOX_BORDER_RECORD_WIDTH - 2*BOX_WIDTH)/3;
        EDIT_GOTO_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-2)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        EDIT_GOTO_WIDTH = BOX_WIDTH;
        EDIT_GOTO_HEIGHT = BOX_HEIGHT;
        EDIT_GOTO_POSITION = [EDIT_GOTO_LEFT   EDIT_GOTO_BOTTOM ...
                              EDIT_GOTO_WIDTH  EDIT_GOTO_HEIGHT];

        TEXT_OUTPUT_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    (BOX_BORDER_RECORD_WIDTH - 2*BOX_WIDTH)/3;
        TEXT_OUTPUT_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-3)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        TEXT_OUTPUT_WIDTH = BOX_WIDTH;
        TEXT_OUTPUT_HEIGHT = BOX_HEIGHT;
        TEXT_OUTPUT_POSITION = [TEXT_OUTPUT_LEFT  TEXT_OUTPUT_BOTTOM ...
                                TEXT_OUTPUT_WIDTH TEXT_OUTPUT_HEIGHT];

        EDIT_OUTPUT_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    (BOX_BORDER_RECORD_WIDTH - 2*BOX_WIDTH)/3;
        EDIT_OUTPUT_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-4)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        EDIT_OUTPUT_WIDTH = BOX_WIDTH;
        EDIT_OUTPUT_HEIGHT = BOX_HEIGHT;
        EDIT_OUTPUT_POSITION = [EDIT_OUTPUT_LEFT  EDIT_OUTPUT_BOTTOM ...
                                EDIT_OUTPUT_WIDTH EDIT_OUTPUT_HEIGHT];
                            
        TEXT_QUALITY_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    2*(BOX_BORDER_RECORD_WIDTH-2*BOX_WIDTH)/3 + BOX_WIDTH;
        TEXT_QUALITY_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-1)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        TEXT_QUALITY_WIDTH = BOX_WIDTH;
        TEXT_QUALITY_HEIGHT = BOX_HEIGHT;
        TEXT_QUALITY_POSITION = [TEXT_QUALITY_LEFT  TEXT_QUALITY_BOTTOM ...
                                 TEXT_QUALITY_WIDTH TEXT_QUALITY_HEIGHT];
                            
        EDIT_QUALITY_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    2*(BOX_BORDER_RECORD_WIDTH-2*BOX_WIDTH)/3 + BOX_WIDTH;
        EDIT_QUALITY_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-2)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        EDIT_QUALITY_WIDTH = BOX_WIDTH;
        EDIT_QUALITY_HEIGHT = BOX_HEIGHT;
        EDIT_QUALITY_POSITION = [EDIT_QUALITY_LEFT  EDIT_QUALITY_BOTTOM ...
                                 EDIT_QUALITY_WIDTH EDIT_QUALITY_HEIGHT];
                             
        TEXT_FPS_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    2*(BOX_BORDER_RECORD_WIDTH-2*BOX_WIDTH)/3 + BOX_WIDTH;
        TEXT_FPS_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-3)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        TEXT_FPS_WIDTH = BOX_WIDTH;
        TEXT_FPS_HEIGHT = BOX_HEIGHT;
        TEXT_FPS_POSITION = [TEXT_FPS_LEFT  TEXT_FPS_BOTTOM ...
                             TEXT_FPS_WIDTH TEXT_FPS_HEIGHT];
                            
        EDIT_FPS_LEFT = BOX_BORDER_RECORD_LEFT + ...
                    2*(BOX_BORDER_RECORD_WIDTH-2*BOX_WIDTH)/3 + BOX_WIDTH;
        EDIT_FPS_BOTTOM = BOX_BORDER_RECORD_BOTTOM + ...
                    (NUM_BOXES-4)*(BOX_BORDER_RECORD_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        EDIT_FPS_WIDTH = BOX_WIDTH;
        EDIT_FPS_HEIGHT = BOX_HEIGHT;
        EDIT_FPS_POSITION = [EDIT_FPS_LEFT  EDIT_FPS_BOTTOM ...
                             EDIT_FPS_WIDTH EDIT_FPS_HEIGHT];
 
        %{
        %  Video control
        %}
        NUM_BOXES = 6;
        ADJUST = 0.0125 * SCREEN_HEIGHT;

        BOX_BORDER_VIDEO_LEFT = BOX_LEFT;
        BOX_BORDER_VIDEO_BOTTOM = 0.07*SCREEN_HEIGHT;
        BOX_BORDER_VIDEO_WIDTH = BOX_BORDER_WIDTH;
        BOX_BORDER_VIDEO_HEIGHT = 6*0.0260*SCREEN_HEIGHT;
        BOX_BORDER_VIDEO_POSITION = [BOX_BORDER_VIDEO_LEFT  BOX_BORDER_VIDEO_BOTTOM ...
                                     BOX_BORDER_VIDEO_WIDTH BOX_BORDER_VIDEO_HEIGHT];

        TEXT_BOX_BORDER_VIDEO_LEFT = BOX_BORDER_VIDEO_LEFT + ...
                0.0050*SCREEN_WIDTH;
        TEXT_BOX_BORDER_VIDEO_BOTTOM = BOX_BORDER_VIDEO_BOTTOM + ...
                BOX_BORDER_VIDEO_HEIGHT - 0.0070*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_VIDEO_WIDTH = 3*0.0275*SCREEN_WIDTH;
        TEXT_BOX_BORDER_VIDEO_HEIGHT = 1*0.0260*SCREEN_HEIGHT;
        TEXT_BOX_BORDER_VIDEO_POSITION = [TEXT_BOX_BORDER_VIDEO_LEFT  TEXT_BOX_BORDER_VIDEO_BOTTOM ...
                                          TEXT_BOX_BORDER_VIDEO_WIDTH TEXT_BOX_BORDER_VIDEO_HEIGHT];
                         
        VIDEO_SLIDER_WIDTH  = AXES_INERTIAL_WIDTH + AXES_HILL_WIDTH + ...
                0.05*SCREEN_WIDTH;
        VIDEO_SLIDER_HEIGHT = 0.025*SCREEN_HEIGHT;
        VIDEO_SLIDER_LEFT = FIGURE_WIDTH/2 - VIDEO_SLIDER_WIDTH/2 + ...
                0.1*FIGURE_WIDTH;
        VIDEO_SLIDER_BOTTOM = 0.29*SCREEN_HEIGHT;
        VIDEO_SLIDER_POSITION = [VIDEO_SLIDER_LEFT  VIDEO_SLIDER_BOTTOM ...
                                 VIDEO_SLIDER_WIDTH VIDEO_SLIDER_HEIGHT];
                             
        TEXT_STATIC_VIDEO_SLIDER_WIDTH = 0.04*SCREEN_WIDTH;
        TEXT_STATIC_VIDEO_SLIDER_HEIGHT = 0.025*SCREEN_HEIGHT;
        TEXT_STATIC_VIDEO_SLIDER_LEFT = VIDEO_SLIDER_LEFT - ...
                TEXT_STATIC_VIDEO_SLIDER_WIDTH - ADJUST;
        TEXT_STATIC_VIDEO_SLIDER_BOTTOM = VIDEO_SLIDER_BOTTOM;
        TEXT_STATIC_VIDEO_SLIDER_POSITION = ...
                [TEXT_STATIC_VIDEO_SLIDER_LEFT  TEXT_STATIC_VIDEO_SLIDER_BOTTOM ...
                 TEXT_STATIC_VIDEO_SLIDER_WIDTH TEXT_STATIC_VIDEO_SLIDER_HEIGHT];

        TEXT_VOLATILE_VIDEO_SLIDER_WIDTH = 0.04*SCREEN_WIDTH;
        TEXT_VOLATILE_VIDEO_SLIDER_HEIGHT = 0.025*SCREEN_HEIGHT;
        TEXT_VOLATILE_VIDEO_SLIDER_LEFT = TEXT_STATIC_VIDEO_SLIDER_LEFT - ...
                1.0*(TEXT_VOLATILE_VIDEO_SLIDER_WIDTH);
        TEXT_VOLATILE_VIDEO_SLIDER_BOTTOM = VIDEO_SLIDER_BOTTOM;
        TEXT_VOLATILE_VIDEO_SLIDER_POSITION = ...
                [TEXT_VOLATILE_VIDEO_SLIDER_LEFT  TEXT_VOLATILE_VIDEO_SLIDER_BOTTOM ...
                 TEXT_VOLATILE_VIDEO_SLIDER_WIDTH TEXT_VOLATILE_VIDEO_SLIDER_HEIGHT];
                             
        BUTTON_PLAY_WIDTH = 0.0275*SCREEN_WIDTH;
        BUTTON_PLAY_LEFT = TEXT_VOLATILE_VIDEO_SLIDER_LEFT - ...
                BUTTON_PLAY_WIDTH;
        BUTTON_PLAY_BOTTOM = VIDEO_SLIDER_BOTTOM;
        BUTTON_PLAY_HEIGHT = 0.0260*SCREEN_HEIGHT;
        BUTTON_PLAY_POSITION = [BUTTON_PLAY_LEFT  BUTTON_PLAY_BOTTOM ...
                                BUTTON_PLAY_WIDTH BUTTON_PLAY_HEIGHT];

        TEXT_POPUPMENU_SPEED_LEFT = BOX_BORDER_VIDEO_LEFT + ...
                (BOX_BORDER_VIDEO_WIDTH - BOX_WIDTH)/2;
        TEXT_POPUPMENU_SPEED_BOTTOM = BOX_BORDER_VIDEO_BOTTOM + ...
                (NUM_BOXES)*(BOX_BORDER_VIDEO_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        TEXT_POPUPMENU_SPEED_WIDTH = BOX_WIDTH;
        TEXT_POPUPMENU_SPEED_HEIGHT = BOX_HEIGHT;
        TEXT_POPUPMENU_SPEED_POSITION = [TEXT_POPUPMENU_SPEED_LEFT  TEXT_POPUPMENU_SPEED_BOTTOM ...
                                         TEXT_POPUPMENU_SPEED_WIDTH TEXT_POPUPMENU_SPEED_HEIGHT];
                                     
        POPUPMENU_SPEED_LEFT = BOX_BORDER_VIDEO_LEFT + ...
                (BOX_BORDER_VIDEO_WIDTH - BOX_WIDTH)/2;
        POPUPMENU_SPEED_BOTTOM = BOX_BORDER_VIDEO_BOTTOM + ...
                (NUM_BOXES-1)*(BOX_BORDER_VIDEO_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        POPUPMENU_SPEED_WIDTH = BOX_WIDTH;
        POPUPMENU_SPEED_HEIGHT = BOX_HEIGHT;
        POPUPMENU_SPEED_POSITION = [POPUPMENU_SPEED_LEFT  POPUPMENU_SPEED_BOTTOM ...
                                    POPUPMENU_SPEED_WIDTH POPUPMENU_SPEED_HEIGHT];
                                                                                       
        BOX_AXES_HILL_WIDTH  = BOX_WIDTH;
        BOX_AXES_HILL_HEIGHT = BOX_HEIGHT;
        BOX_AXES_HILL_LEFT = BOX_BORDER_VIDEO_LEFT + ...
                (BOX_BORDER_VIDEO_WIDTH - BOX_WIDTH)/2;
        BOX_AXES_HILL_BOTTOM = BOX_BORDER_VIDEO_BOTTOM + ...
                (NUM_BOXES-2)*(BOX_BORDER_VIDEO_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_AXES_HILL_POSITION = [BOX_AXES_HILL_LEFT  BOX_AXES_HILL_BOTTOM ...
                                  BOX_AXES_HILL_WIDTH BOX_AXES_HILL_HEIGHT];
                              
        BOX_AXES_HILL_CENTERED_WIDTH  = BOX_WIDTH;
        BOX_AXES_HILL_CENTERED_HEIGHT = BOX_HEIGHT;
        BOX_AXES_HILL_CENTERED_LEFT = ADJUST + BOX_BORDER_VIDEO_LEFT + ...
                (BOX_BORDER_VIDEO_WIDTH - BOX_WIDTH)/2;
        BOX_AXES_HILL_CENTERED_BOTTOM = BOX_BORDER_VIDEO_BOTTOM + ...
                (NUM_BOXES-3)*(BOX_BORDER_VIDEO_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_AXES_HILL_CENTERED_POSITION = [BOX_AXES_HILL_CENTERED_LEFT  BOX_AXES_HILL_CENTERED_BOTTOM ...
                                           BOX_AXES_HILL_CENTERED_WIDTH BOX_AXES_HILL_CENTERED_HEIGHT];

        BOX_AXES_INERTIAL_WIDTH  = 3*0.0275*SCREEN_WIDTH;
        BOX_AXES_INERTIAL_HEIGHT = BOX_HEIGHT;
        BOX_AXES_INERTIAL_LEFT = BOX_BORDER_VIDEO_LEFT + ...
                (BOX_BORDER_VIDEO_WIDTH - BOX_WIDTH)/2;
        BOX_AXES_INERTIAL_BOTTOM = BOX_BORDER_VIDEO_BOTTOM + ...
                (NUM_BOXES-4)*(BOX_BORDER_VIDEO_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_AXES_INERTIAL_POSITION = [BOX_AXES_INERTIAL_LEFT  BOX_AXES_INERTIAL_BOTTOM ...
                                      BOX_AXES_INERTIAL_WIDTH BOX_AXES_INERTIAL_HEIGHT];
                                  
        BOX_AXES_INERTIAL_CENTERED_WIDTH  = 3*0.0275*SCREEN_WIDTH;
        BOX_AXES_INERTIAL_CENTERED_HEIGHT = BOX_HEIGHT;
        BOX_AXES_INERTIAL_CENTERED_LEFT = ADJUST + BOX_BORDER_VIDEO_LEFT + ...
                (BOX_BORDER_VIDEO_WIDTH - BOX_WIDTH)/2;
        BOX_AXES_INERTIAL_CENTERED_BOTTOM = BOX_BORDER_VIDEO_BOTTOM + ...
                (NUM_BOXES-5)*(BOX_BORDER_VIDEO_HEIGHT - BOX_HEIGHT - ADJUST)/NUM_BOXES;
        BOX_AXES_INERTIAL_CENTERED_POSITION = [BOX_AXES_INERTIAL_CENTERED_LEFT  BOX_AXES_INERTIAL_CENTERED_BOTTOM ...
                                               BOX_AXES_INERTIAL_CENTERED_WIDTH BOX_AXES_INERTIAL_CENTERED_HEIGHT];
        %{
        %  Configure timer
        %}
        obj_timer = c_timer(num_frames);
        h_timer = timer(...
                      'executionmode', 'fixedrate', ...
                      'period', timer_period);
        obj_timer.set_handle(h_timer);
        
        %{
        %  Configure timer update
        %}
        h_update_timer = timer(...
                      'executionmode', 'fixedrate', ...
                      'period', timer_update_gui_period);

        %{
        %  Configure GUI
        %}
        color_string = {'b' 'g' 'k' 'y' 'm' 'c' 'r'};
        length_color_string = length(color_string);

        %{
        %  Figure
        %}
        h_figure = figure(...
                      'color', [0.6 0.7 0.7], ...
                      'units', 'pixels', ...
                      'position', FIGURE_POSITION, ...
                      'toolbar', 'figure', ...
                      'keypressfcn', {@keypress_handler, obj_timer}, ...
                      'deletef', {@delete_figure, h_timer, h_update_timer}, ...
                      'resize', 'on', ...
                      'renderer', 'opengl');
                     
        %h_border_hill = uipanel(...
        %              'parent', h_figure, ...
        %              'position', AXES_BORDER_HILL_POSITION, ...
        %              'clipping', 'on', ...
        %              'bordertype', 'line');
                      %'borderwidth', 100);
                      %'foreground', [0 0 0]);
                      %'style', 'frame', ...

        %h_border_inertial = uipanel(...
        %              'parent', h_figure, ...
        %              'position', AXES_BORDER_INERTIAL_POSITION, ...
        %              'clipping', 'on', ...
        %              'bordertype', 'line');
                      %'borderwidth', 100);
                      %'foreground', [0 0 0]);
                      %'style', 'frame', ...
                      
        %{
        %  Control
        %}
        h_button_play = uicontrol(...
                      'style', 'togglebutton', ...
                      'units', 'pixels', ...
                      'string', 'Play', ...
                      'position', BUTTON_PLAY_POSITION, ...
                      'callback', {@button_play_handler, obj_timer}, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'value', 1);

        h_video_slider = uicontrol(...
                      'style', 'slider', ...
                      'position', VIDEO_SLIDER_POSITION, ...
                      'min', 1, ...
                      'max', num_frames, ...
                      'sliderstep', [1 1]/num_frames, ...
                      'callback', {@video_slider_released_handler, obj_timer}, ...
                      'value', 1);              

        h_text_volatile_video_slider = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_VOLATILE_VIDEO_SLIDER_POSITION, ...
                      'string', num2str(start_time));
                  
        h_text_static_video_slider = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_STATIC_VIDEO_SLIDER_POSITION, ...
                      'string', ['/ ' num2str(stop_time)]);
                  
        h_border_video = uicontrol(...
                      'style', 'frame', ...
                      'position', BOX_BORDER_VIDEO_POSITION, ...
                      'foreground', [0 0 0]);      
                  
        h_text_border_video = uicontrol(...,
                      'style', 'text', ...
                      'position', TEXT_BOX_BORDER_VIDEO_POSITION, ...
                      'string', 'Video Control');   

        %{
        %  Global
        %}
        h_border_global = uicontrol(...
                      'style', 'frame', ...
                      'position', BOX_BORDER_GLOBAL_POSITION, ...
                      'foreground', [0 0 0]);

        h_text_border_global = uicontrol(...,
                      'style', 'text', ...
                      'position', TEXT_BOX_BORDER_GLOBAL_POSITION, ...
                      'string', 'Global Options');

        h_box_loop = uicontrol(...
                      'style', 'checkbox', ...
                      'units', 'pixels', ...
                      'string', 'Loop animation', ...
                      'position', BOX_LOOP_POSITION, ...
                      'callback', {@box_loop_handler, obj_timer}, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'value', 1);

        h_button_grid = uicontrol(...
                      'style', 'togglebutton', ...
                      'units', 'pixels', ...
                      'string', 'Grid', ...
                      'position', BOX_GRID_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'value', 1);

        h_global_options_controlgroup = uibuttongroup(...
                      'parent', h_figure, ...
                      'position', GLOBAL_CONTROLGROUP_POSITION);

        h_button_rotate = uicontrol(...
                      'style', 'togglebutton', ...
                      'units', 'pixels', ...
                      'string', 'Rotate', ...
                      'position', BOX_ROTATE_POSITION, ...
                      'parent', h_global_options_controlgroup, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'value', 1);

        h_button_zoom_in = uicontrol(...
                      'style', 'togglebutton', ...
                      'units', 'pixels', ...
                      'string', 'Zoom In', ...
                      'position', BOX_ZOOM_IN_POSITION, ...
                      'parent', h_global_options_controlgroup, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'value', 0);

        h_button_zoom_out = uicontrol(...
                      'style', 'togglebutton', ...
                      'units', 'pixels', ...
                      'string', 'Zoom Out', ...
                      'position', BOX_ZOOM_OUT_POSITION, ...
                      'parent', h_global_options_controlgroup, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'value', 0);

        h_button_keypress = uicontrol(...
                      'style', 'togglebutton', ...
                      'units', 'pixels', ...
                      'string', 'Keypress Support', ...
                      'position', BOX_KEYPRESS_POSITION, ...
                      'parent', h_global_options_controlgroup, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'value', 0);

        %{
        %  Local
        %}
        h_border_local = uicontrol(...
                      'style', 'frame', ...
                      'position', BOX_BORDER_LOCAL_POSITION, ...
                      'foreground', [0 0 0]);

        h_text_border_local = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_BOX_BORDER_LOCAL_POSITION, ...
                      'string', 'Local Options');
                      
        h_popupmenu = uicontrol(...
                      'style', 'popupmenu', ...
                      'units', 'pixels', ...
                      'position', POPUPMENU_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'value', 1);

        popupmenu_string = cell(num_objects,1);
        h_box_obj_enable = zeros(num_objects, 1);
        h_box_obj_trace = zeros(num_objects, 1);
        h_box_obj_vel = zeros(num_objects, 1);
        h_box_obj_select = zeros(num_objects, 1);
        h_box_obj_color = zeros(num_objects, 1);
        for i=1:num_objects
                popupmenu_string(i,:) = cellstr(sprintf('Object %d', i));

                h_box_obj_enable(i,1) = uicontrol(...
                              'style', 'checkbox', ...
                              'units', 'pixels', ...
                              'string', 'Enable', ...
                              'position', BOX_OBJ_ENABLE_POSITION, ...
                              'parent', h_figure, ...
                              'backgroundcolor', [1 1 1], ...
                              'value', 1, ...
                              'visible', 'off');

                h_box_obj_trace(i,1) = uicontrol(...
                              'style', 'checkbox', ...
                              'units', 'pixels', ...
                              'string', 'Trace', ...
                              'position', BOX_OBJ_TRACE_POSITION, ...
                              'parent', h_figure, ...
                              'backgroundcolor', [1 1 1], ...
                              'value', 1, ...
                              'visible', 'off');

                h_box_obj_vel(i,1) = uicontrol(...
                              'style', 'checkbox', ...
                              'units', 'pixels', ...
                              'string', 'Velocity', ...
                              'position', BOX_OBJ_VEL_POSITION, ...
                              'parent', h_figure, ...
                              'backgroundcolor', [1 1 1], ...
                              'value', 1, ...
                              'visible', 'off');

                h_box_obj_select(i,1) = uicontrol(...
                              'style', 'checkbox', ...
                              'units', 'pixels', ...
                              'string', 'Select', ...
                              'position', BOX_OBJ_SELECT_POSITION, ...
                              'parent', h_figure, ...
                              'backgroundcolor', [1 1 1], ...
                              'value', 0, ...
                              'visible', 'off');
                          
               index = i;
               if index > length_color_string
                    index = 1;
               end
               h_box_obj_color(i,1) = uicontrol(...
                              'style', 'text', ...
                              'units', 'pixels', ...
                              'string', '', ...
                              'position', BOX_OBJ_COLOR_POSITION, ...
                              'parent', h_figure, ...
                              'background', color_string{index}, ...
                              'visible', 'off');

        end
        set(h_popupmenu, 'string', popupmenu_string);
        set(h_popupmenu, 'callback', {@popupmenu_handler, ...
                                      num_objects, ...
                                      h_box_obj_enable(:), ...
                                      h_box_obj_trace(:), ...
                                      h_box_obj_vel(:), ...
                                      h_box_obj_select(:), ...
                                      h_box_obj_color(:)});
       
        %{
        %  Initialize only boxes from first object as visible
        %}
        set(h_box_obj_enable(1,1), 'visible', 'on');
        set(h_box_obj_trace(1,1), 'visible', 'on');
        set(h_box_obj_vel(1,1), 'visible', 'on');
        set(h_box_obj_select(1,1), 'visible', 'on');
        set(h_box_obj_color(1,1), 'visible', 'on');

        vel_array = obj_timer.get_vel_array;
        array_length = size(vel_array,2);
        vel_string = cell(array_length,1);
        for i=1:array_length
                vel_string(i) = cellstr(strcat(num2str(vel_array(1,i)), 'x'));
        end
        h_popupmenu_speed = uicontrol(...
                      'string', vel_string, ...
                      'style', 'popupmenu', ...
                      'units', 'pixels', ...
                      'position', POPUPMENU_SPEED_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'value', 1, ...
                      'callback', {@popupmenu_vel_handler, ...
                                   obj_timer});

        h_text_popupmenu_vel = uicontrol(...
                      'style', 'text', ...
                      'string', 'Speed:', ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'position', TEXT_POPUPMENU_SPEED_POSITION);

        %{
        %  Record
        %}
        h_border_record = uicontrol(...
                      'style', 'frame', ...
                      'position', BOX_BORDER_RECORD_POSITION, ...
                      'foreground', [0 0 0]);

        h_text_border_record = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_BOX_BORDER_RECORD_POSITION, ...
                      'string', 'Record Movie');
                      
        h_button_record = uicontrol(...
                      'style', 'togglebutton', ...
                      'string', 'Start', ...
                      'units', 'pixels', ...
                      'position', BUTTON_RECORD_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'value', 0, ...
                      'callback', {@button_record_handler, obj_timer});
                  
        h_text_goto = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_GOTO_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'string', 'Go to (time):');
                                        
        h_edit_goto = uicontrol(...
                      'style', 'edit', ...
                      'units', 'pixels', ...
                      'position', EDIT_GOTO_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'string', num2str(start_time), ...
                      'callback', {@edit_goto_handler, ...
                                   obj_timer, 1, ...
                                   start_time, ...
                                   min_time_period});
                               
        h_text_output = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_OUTPUT_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'string', 'Output File (*.mp4):');
                  
        h_edit_output = uicontrol(...
                      'style', 'edit', ...
                      'units', 'pixels', ...
                      'position', EDIT_OUTPUT_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'string', num2str(obj_timer.get_recording_output_file), ...
                      'callback', {@edit_output_handler, obj_timer});
                  
        h_text_quality = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_QUALITY_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'string', 'Quality (0-100):');
                  
        h_edit_quality = uicontrol(...
                      'style', 'edit', ...
                      'units', 'pixels', ...
                      'position', EDIT_QUALITY_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'string', num2str(obj_timer.get_recording_quality), ...
                      'callback', {@edit_quality_handler, obj_timer});
                  
        h_text_fps = uicontrol(...
                      'style', 'text', ...
                      'position', TEXT_FPS_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [0.8 0.8 0.8], ...
                      'string', 'Frames Per Second:');
                  
        h_edit_fps = uicontrol(...
                      'style', 'edit', ...
                      'units', 'pixels', ...
                      'position', EDIT_FPS_POSITION, ...
                      'parent', h_figure, ...
                      'backgroundcolor', [1 1 1], ...
                      'string', num2str(obj_timer.get_recording_fps), ...
                      'callback', {@edit_fps_handler, obj_timer});                  
                  
        %{
        %   Initialize axes and text
        %}
        h_axes(HILL) = axes(...
                      'parent', h_figure, ...
                      'units', 'pixels', ...
                      'position', AXES_HILL_POSITION, ...
                      'drawmode', 'fast');
                      %'parent', h_border_hill, ...

        h_axes(INERTIAL) = axes(...
                      'parent', h_figure, ...
                      'units', 'pixels', ...
                      'position', AXES_INERTIAL_POSITION, ...
                      'drawmode', 'fast');
                      %'parent', h_border_inertial, ...
                  
        h_box_axes_hill = uicontrol(...
                      'parent', h_figure, ...
                      'style', 'checkbox', ...
                      'position', BOX_AXES_HILL_POSITION, ...
                      'string', 'Hill Frame', ...
                      'value', 1, ...
                      'callback', {@box_axes_handler, h_axes(HILL)});    
        
        h_box_axes_hill_centered = uicontrol(...
                      'parent', h_figure, ...
                      'style', 'checkbox', ...
                      'position', BOX_AXES_HILL_CENTERED_POSITION, ...
                      'string', 'Centered', ...
                      'value', 0, ...
                      'backgroundcolor', [1 1 1], ...
                      'callback', {@box_axes_centered_handler, ...
                                   h_axes(HILL), ...
                                   AXES_HILL_POSITION, ...
                                   AXES_CENTERED_POSITION, ...
                                   FIGURE_POSITION, ...
                                   h_figure});
                  
        h_box_axes_inertial = uicontrol(...
                      'parent', h_figure, ...
                      'style', 'checkbox', ...
                      'position', BOX_AXES_INERTIAL_POSITION, ...
                      'string', 'Inertial Frame', ...
                      'value', 1, ...
                      'callback', {@box_axes_handler, h_axes(INERTIAL)});
                  
        h_box_axes_inertial_centered = uicontrol(...
                      'parent', h_figure, ...
                      'style', 'checkbox', ...
                      'position', BOX_AXES_INERTIAL_CENTERED_POSITION, ...
                      'string', 'Centered', ...
                      'value', 0, ...
                      'backgroundcolor', [1 1 1], ...
                      'callback', {@box_axes_centered_handler, ...
                                   h_axes(INERTIAL), ...
                                   AXES_INERTIAL_POSITION, ...
                                   AXES_CENTERED_POSITION, ...
                                   FIGURE_POSITION, ...
                                   h_figure});
                               
       if ~centered_option_is_enabled
                setAllowAxesRotate(rotate3d(h_axes(INERTIAL)), h_axes(INERTIAL), 0);
                setAllowAxesZoom(zoom(h_axes(INERTIAL)), h_axes(INERTIAL), 0);
                set(h_axes(INERTIAL), 'visible', 'off');
                set(h_box_axes_inertial, 'enable', 'off');
                set(h_box_axes_inertial_centered, 'enable', 'off');
                set(h_box_axes_hill_centered, 'enable', 'off');

                set(h_axes(HILL), 'units', 'pixels');
                set(h_figure, 'units', 'pixels');
                figure_position = get(h_figure, 'position');
                position = get(h_axes(HILL), 'position');
        
                for i=1:2
                    position(i) = (AXES_CENTERED_POSITION(i) / figure_position(i+2)) * ...
                            figure_position(i+2);
                end

                set(h_axes(HILL), 'position', position);
                set(h_axes(HILL), 'units', 'normalized');
                set(h_figure, 'units', 'normalized');
        end

        %{
        %  Convert all uicontrol/axes under main figure 
        %  from 'pixels' to 'normalized', to enable resizing.
        %}
        set(h_figure, 'units', 'normalized');
        
        uicontrol_handles = findobj(h_figure, 'type', 'uicontrol');
        axes_handles = findobj(h_figure, 'type', 'axes');
        uipanel_handles = findobj(h_figure, 'type', 'uipanel');
        
        set(uicontrol_handles(:), 'units', 'normalized');
        set(axes_handles(:), 'units', 'normalized');
        set(uipanel_handles(:), 'units', 'normalized');

        %{
        %  Show axes and prepare them for plotting
        %}
        for j=1:num_axes
                hold(h_axes(j), 'on');
        end
        
        h_trace = zeros(num_axes, num_objects);
        h_plot = zeros(num_axes, num_objects);
        for i=1:num_objects
                for j=1:num_axes
                        index = i;
                        if index > length_color_string
                                index = 1;
                        end
                        h_trace(j,i) = plot3(h_axes(j), ...
                                        X(j,:,i), Y(j,:,i), Z(j,:,i), ...
                                        'color', color_string{index});
                        h_plot(j,i) = plot3(h_axes(j), ...
                                        X(j,1,i), Y(j,1,i), Z(j,1,i), ...
                                        'ro', 'markersize', 7, ...
                                        'markerfacecolor', color_string{index}, ...
                                        'color', 'k');
                end
        end

        h_velocity_arrow = zeros(num_axes, num_objects);
        
        range = zeros(num_axes, 3);
        scale = zeros(num_axes, 1);
        for i=1:num_axes
                x_limit = get(h_axes(i), 'xlim');
                y_limit = get(h_axes(i), 'ylim');
                z_limit = get(h_axes(i), 'zlim');
                range(i,1) = abs(x_limit(2) - x_limit(1));
                range(i,2) = abs(y_limit(2) - y_limit(1));
                range(i,3) = abs(z_limit(2) - z_limit(1));
        end        
        
        scale(HILL,1)       = median(range(HILL)) / 2;
        scale(INERTIAL,1)   = median(range(INERTIAL)) / 100;
        
        for k=1:num_axes
                for i=1:num_objects
                        h_velocity_arrow(k,i) = quiver3(h_axes(k), ...
                                         X(k,1,i), ...
                                         Y(k,1,i), ...
                                         Z(k,1,i), ...
                                         vx(k,1,i), ...
                                         vy(k,1,i), ...
                                         vz(k,1,i), ...
                                         scale(k,1));
                        set(h_velocity_arrow(k,i), ...
                            'linewidth', 2, ...
                            'color', 'r', ...
                            'maxheadsize', 100);
                 end
        end

        set_plot_options(h_figure);
        
        scale = median(range(INERTIAL)) / 10;
        if centered_option_is_enabled 
                x = r.*cos(theta);
                y = r.*sin(theta);
                z = zeros(1, length(x));
                rot_result = M * [x; y; z];
                x2 = rot_result(1,:);
                y2 = rot_result(2,:);
                z2 = rot_result(3,:);
                plot3(h_axes(INERTIAL), x2,y2,z2, 'm', 'linewidth', 2);
                if textured_body_is_enabled
                        if centered_type == EARTH_CENTERED
                                if ispc
                                        image_path = 'images\earth.jpg';
                                else
                                        image_path = './images/earth.jpg';
                                end
                        elseif centered_type == SUN_CENTERED
                                if ispc
                                        image_path = 'images\sun.jpg';
                                else
                                        image_path = './images/sun.jpg';
                                end
                        end
                        %{
                        %  Test
                        %}
                        earth_a = scale;
                        earth_b = scale;
                        earth_c = scale;
                        cdata = imread(image_path);
                        [x, y, z] = ellipsoid(h_axes(INERTIAL), ...
                                   0, 0, 0, ...
                                   earth_a, earth_b, earth_c, ...
                                   30);
                        globe = surf(h_axes(INERTIAL), x, y, -z, ...
                                   'facecolor', 'none', ...
                                   'edgecolor', 0.5*[1 1 1]);
                        set(globe, 'facecolor', 'texturemap', ...
                                   'cdata', cdata, ....
                                   'facealpha', 1, ...
                                   'edgecolor', 'none');
                else
                        earth_a = scale;
                        earth_b = scale;
                        earth_c = scale;
                        [x1, y1, z1] = sphere(20);
                        x = earth_a.*x1;
                        y = earth_b.*y1;
                        z = earth_c.*z1;
                        globe = surf(h_axes(INERTIAL), x, y, z, ...
                                    'edgealpha', 0.4, ...
                                    'edgecolor', 0.5*[1 1 1]);
                end
        end

        %{
        %  Set callback for boxes
        %}
        set(h_box_obj_enable(:), 'callback', {@box_obj_enable_handler, ...
                                              h_axes, ...
                                              h_popupmenu, ...
                                              num_objects, ...
                                              num_axes, ...
                                              h_trace, ...
                                              h_plot, ...
                                              h_velocity_arrow});
        set(h_box_obj_trace(:), 'callback', {@box_obj_trace_handler, ...
                                              h_axes, ...
                                              h_popupmenu, ...
                                              num_objects, ...
                                              num_axes, ...
                                              h_trace, ...
                                              h_plot, ...
                                              h_velocity_arrow});
        set(h_box_obj_vel(:), 'callback', {@box_obj_vel_handler, ...
                                              h_axes, ...
                                              h_popupmenu...
                                              num_objects, ...
                                              num_axes, ...
                                              h_trace, ...
                                              h_plot, ...
                                              h_velocity_arrow});
        set(h_box_obj_select(:), 'callback', {@box_obj_select_handler, ...
                                              h_axes, ...
                                              h_popupmenu...
                                              num_objects, ...
                                              num_axes, ...
                                              h_trace, ...
                                              h_plot, ...
                                              h_velocity_arrow});

        %{
        %  Set callback for pushbuttons
        %}
        set(h_button_grid, 'callback', {@button_grid_handler, h_figure});
        set(h_button_rotate, 'callback', {@button_rotate_handler, h_figure});
        set(h_button_zoom_in, 'callback', {@button_zoom_in_handler, h_figure});
        set(h_button_zoom_out, 'callback', {@button_zoom_out_handler, h_figure});
        set(h_button_keypress, 'callback', {@button_keypress_handler, h_figure});

        %{
        %  Set listener for video slider
        %}
        h_listener = handle.listener(h_video_slider, ...
                                     'actionevent', ...
                                     {@video_slider_pressed_handler, ...
                                     obj_timer, ...
                                     h_video_slider, ...
                                     h_figure});
        setappdata(h_video_slider, 'sliderlistener', h_listener);

        %{
        %  Set timer function
        %}
        set(obj_timer.get_handle, 'timerfcn', ...
                            {@timer_handler, ...
                             h_figure, ...
                             num_objects, ...
                             num_axes, ...
                             h_video_slider, ...
                             h_plot, ...
                             h_text_volatile_video_slider, ...
                             obj_timer, ...
                             t, X, Y, Z, ...
                             h_velocity_arrow, vx, vy, vz});
                         
        %{
        %  Set timer update function
        %}
        set(h_update_timer, 'timerfcn', ...
                            {@timer_update_gui_handler, ...
                            obj_timer, ...
                            h_button_play, ...
                            h_popupmenu_speed, ...
                            h_button_record, ...
                            h_figure, ...
                            h_button_rotate, ...
                            h_button_zoom_in, ...
                            h_edit_output, ...
                            h_edit_quality, ...
                            h_edit_fps});                      

        if isvalid(obj_timer)
            obj_timer.start;
        end
        
        if isvalid(h_update_timer)
        	start(h_update_timer);
        end
        
        clear a;
        clear ec;
        clear inc;
        clear mu;
        clear omega;
        clear Omega;
        clear theta;
        clear traject;

        ret = 1;
end

function [ret] = get_min_range(varargin)
        min_range = varargin{1}(2) - varargin{2}(1);
        for i=2:nargin
                range = varargin{i}(2) - varargin{i}(1);
                if range < min_range
                    min_range = range;
                end
        end
        ret = abs(min_range);
end

function [] = set_plot_options(h_figure)
        %{
        %  __Note: rotate3d must be disabled in order for keypresses
        %  to work when inside figure_plot__
        %}
        axes_handles = findobj(h_figure, 'type', 'axes');
        num_handles = numel(axes_handles);

        zoom(h_figure, 'on');
        rotate3d(h_figure, 'on');
        for i=1:num_handles
                visible = get(axes_handles(i), 'visible');
                if strcmp(visible, 'off')
                    continue;
                end
                grid(axes_handles(i), 'on');
                setAllowAxesZoom(zoom(axes_handles(i)), axes_handles(i), 1);
                setAllowAxesRotate(rotate3d(axes_handles(i)), axes_handles(i), 1);
                axis(axes_handles(i), 'equal');
                axis(axes_handles(i), 'tight');
                view(axes_handles(i), 3);
        end
end

function [] = button_play_handler(~, ~, obj_timer)
        if obj_timer.ispaused
                obj_timer.unpause;
        else
                obj_timer.pause;
        end
end

function [] = box_loop_handler(h, ~, obj_timer)
        if ~get(h, 'value')
                obj_timer.loop_off;
        else
                obj_timer.loop_on;
        end
end

function [] = button_grid_handler(~, ~, h_figure)
        axes_handles = findobj(h_figure, 'type', 'axes');
        num_handles = numel(axes_handles);
        for i=1:num_handles          
                grid(axes_handles(i));
        end
end

function [] = button_rotate_handler(h, ~, h_figure)
        pressed = get(h, 'value');
        axes_handles = findobj(h_figure, 'type', 'axes');
        num_handles = numel(axes_handles);
        %if ~pressed
        %        return;
        %end
        if pressed
                rotate3d(h_figure, 'on');
        else
                rotate3d(h_figure, 'off');
        end
        
        for i=1:num_handles
                axes_visible = get(axes_handles(i), 'visible');
                if strcmp(axes_visible, 'on')
                        setAllowAxesRotate(rotate3d(axes_handles(i)), axes_handles(i), 1);
                else
                        setAllowAxesRotate(rotate3d(axes_handles(i)), axes_handles(i), 0);
                end
        end
end

function [] = button_zoom_in_handler(h, ~, h_figure)
        pressed = get(h, 'value');
        axes_handles = findobj(h_figure, 'type', 'axes');
        num_handles = numel(axes_handles);
        %if ~pressed
        %        return;
        %end
        if pressed
                zoom(h_figure, 'on');
        else
                zoom(h_figure, 'off');
        end
        
        for i=1:num_handles          
                axes_visible = get(axes_handles(i), 'visible');
                if strcmp(axes_visible, 'on')
                        setAllowAxesZoom(zoom(axes_handles(i)), axes_handles(i), 1);
                else
                        setAllowAxesZoom(zoom(axes_handles(i)), axes_handles(i), 0);
                end
        end
end

function [] = button_zoom_out_handler(h, ~, h_figure)
        pressed = get(h, 'value');
        axes_handles = findobj(h_figure, 'type', 'axes');
        num_handles = numel(axes_handles);
        if pressed
                for i=1:num_handles          
                    zoom(axes_handles(i), 'out');
                end
        end
end

function [] = set_uicontrol(h_figure, opt)
        uicontrol_handles = findobj(h_figure, 'type', 'uicontrol');
        set(uicontrol_handles(:,1), 'enable', opt);
end

function [] = button_keypress_handler(h, ~, h_figure)
        pressed = get(h, 'value');
        axes_handles = findobj(h_figure, 'type', 'axes');
        num_handles = numel(axes_handles);
        if ~pressed
                rotate3d(h_figure, 'on');
                for i=1:num_handles          
                        setAllowAxesRotate(rotate3d(axes_handles(i)), axes_handles(i), 1);
                end
                return;
        end
        zoom(h_figure, 'off');
        rotate3d(h_figure, 'off');

        %{
        %  Release focus from button 
        %  __this is an ugly way of doing that but... matlab__
        %}
        set_uicontrol(h_figure, 'off');
        drawnow;
        set_uicontrol(h_figure, 'on');
        disp('ANIMATED: keypress enabled');
end

function [] = delete_figure(~, ~, h_timer, h_update_timer)
        stop(h_timer);
        delete(h_timer);
        
        stop(h_update_timer);
        delete(h_update_timer);
end

function [] = popupmenu_handler(h, ~, num_obj, varargin)
        string = {'on' 'off'};
        opt = get(h, 'value');
        num_box = size(varargin, 2);
        for i=1:num_obj
                if opt == i
                        index = 1;
                else
                        index = 2;
                end
                for j=1:num_box
                        set(varargin{j}(i), 'visible', string{index});
                end
        end
end

function [] = box_obj_enable_handler(h, ~, ...
                                     h_axes, ...
                                     h_popupmenu, ...
                                     ~, ...
                                     num_axes, ...
                                     h_trace, ...
                                     h_plot, ...
                                     h_velocity_arrow)
        string = {'off' 'on'};
        obj = get(h_popupmenu, 'value');
        index = get(h, 'value');
        for j=1:num_axes
                axes_visible = get(h_axes(j), 'visible');
                if strcmp(axes_visible, 'on')
                        set(h_trace(j,obj), 'visible', string{index+1});
                        set(h_plot(j,obj), 'visible', string{index+1});
                        set(h_velocity_arrow(j,obj), 'visible', string{index+1});
                end
        end
end

function [] = box_obj_trace_handler(h, ~, ...
                                    h_axes, ...
                                    h_popupmenu, ...
                                    ~, ...
                                    num_axes, ...
                                    h_trace, ...
                                    ~, ...
                                    ~)
        string = {'off' 'on'};
        obj = get(h_popupmenu, 'value');
        index = get(h, 'value');
        for j=1:num_axes
                axes_visible = get(h_axes(j), 'visible');
                if strcmp(axes_visible, 'on')
                        set(h_trace(j,obj), 'visible', string{index+1});
                end
        end
end

function [] = box_obj_vel_handler(h, ~, ...
                                  h_axes, ...
                                  h_popupmenu, ...
                                  ~, ...
                                  num_axes, ...
                                  ~, ...
                                  ~, ...
                                  h_velocity_arrow)
        string = {'off' 'on'};
        obj = get(h_popupmenu, 'value');
        index = get(h, 'value');
        for j=1:num_axes
                axes_visible = get(h_axes(j), 'visible');
                if strcmp(axes_visible, 'on')
                        set(h_velocity_arrow(j,obj), 'visible', string{index+1});
                end
        end
end

function [] = box_obj_select_handler(h, ~, ...
                                     h_axes, ...
                                     h_popupmenu, ...
                                     num_objects, ...
                                     num_axes, ...
                                     h_trace, ...
                                     h_plot, ...
                                     h_velocity_arrow)
        string = {'off' 'on'};
        obj = get(h_popupmenu, 'value');
        box_selected = get(h, 'value');
        if box_selected
                for j=1:num_axes
                        axes_visible = get(h_axes(j), 'visible');
                        if ~strcmp(axes_visible, 'on')
                                continue;
                        end
                        for i=1:num_objects
                                index = (obj == i);
                                set(h_trace(j,i), 'visible', string{index+1});
                                set(h_plot(j,i), 'visible', string{index+1});
                                set(h_velocity_arrow(j,i), 'visible', string{index+1});
                        end
                end
        else
                for j=1:num_axes
                        axes_visible = get(h_axes(j), 'visible');
                        if ~strcmp(axes_visible, 'on')
                                continue;
                        end
                        for i=1:num_objects
                                set(h_trace(j,i), 'visible', 'on');
                                set(h_plot(j,i), 'visible', 'on');
                                set(h_velocity_arrow(j,i), 'visible', 'on');
                        end
                end
        end

end

function [] = popupmenu_vel_handler(h, ~, obj_timer)
        vel_index = get(h, 'value');
        %vel_array = obj_timer.get_vel_array;
        obj_timer.set_velocity(vel_index);
end

function [] = video_slider_pressed_handler(~, ~, obj_timer, ...
                                           h_video_slider, ...
                                           h_figure)
        %%{
        %%  Setting 'units' to 'pixels' for math-wise purposes
        %%}
        set(h_video_slider, 'units', 'pixels');
        set(h_figure, 'units', 'pixels');
        
        pointer_location = get(0, 'pointerlocation');
        figure_position = get(h_figure, 'position');
        video_slider_position = get(h_video_slider, 'position');
        
        max_frames = obj_timer.get_max_frames;
        
        pointer = pointer_location(1);
        
        left_slider = video_slider_position(1);
        width       = video_slider_position(3);
        
        left_figure = figure_position(1);
        
        %{
        %  'adjust' is to compensate for the width of the arrows in the slider
        %}
        adjust = 25;
        left = left_slider + left_figure;
     
        new_index = round((max_frames - 1) * ...
                (pointer - left - adjust)/(width-2*adjust) + 1);
        if new_index > max_frames
                new_index = max_frames;
        elseif new_index < 1
                new_index = 1;
        end
        paused = obj_timer.paused;
        if ~obj_timer.get_previous_paused_flag
                obj_timer.set_previous_paused(paused);
                obj_timer.set_previous_paused_flag(1);
        end
        if ~paused
                obj_timer.pause;
        end
        obj_timer.set_index(new_index);

        %%{
        %%  Returning 'units' to 'normalized'
        %%}
        set(h_video_slider, 'units', 'normalized');
        set(h_figure, 'units', 'normalized');
end

function [] = video_slider_released_handler(~, ~, obj_timer)
        if ~obj_timer.get_previous_paused_flag
                return;
        end
        paused = obj_timer.get_previous_paused;
        if ~paused
                obj_timer.unpause;
        end
        obj_timer.set_previous_paused_flag(0);
end

function [] = box_axes_handler(h, ~, h_axes)
        string = {'off' 'on'};
        pressed = get(h, 'value');
        h_children = get(h_axes, 'children');
        set(h_axes, 'visible', string{pressed+1});
        set(h_children(:), 'visible', string{pressed+1});
        setAllowAxesZoom(zoom(h_axes), h_axes, pressed);
        setAllowAxesRotate(rotate3d(h_axes), h_axes, pressed);

end

function [] = box_axes_centered_handler(h, ~, h_axes, ...
                                        standard_position, ...
                                        centered_position, ...
                                        figure_initial_position, ...
                                        h_figure)
        set(h_axes, 'units', 'pixels');
        set(h_figure, 'units', 'pixels');
        figure_position = get(h_figure, 'position');
        pressed = get(h, 'value');
        position = get(h_axes, 'position');
        
        if pressed
            for i=1:2
                position(i) = (centered_position(i) / figure_initial_position(i+2)) * ...
                        figure_position(i+2);
            end
        else
            for i=1:2
                position(i) = (standard_position(i) / figure_initial_position(i+2)) * ...
                        figure_position(i+2);
            end
        end

        set(h_axes, 'position', position);
        set(h_axes, 'units', 'normalized');
        set(h_figure, 'units', 'normalized');
end

function [] = button_record_handler(h, ~, obj_timer)
        pressed = get(h, 'value');
        obj_timer.set_recording(pressed);
end
                  
function [] = edit_goto_handler(h, ~, obj_timer, ...
                                start_time_index, ...
                                start_time, ...
                                time_period)
        time = str2double(get(h, 'string'));
        index = start_time_index + start_time + time*time_period;
        obj_timer.set_index(index);
end
                  
function [] = edit_output_handler(h, ~, obj_timer)
        string = get(h, 'string');
        length_string = length(string);
        if length_string > 64 || length_string < 1
                return;
        end
        obj_timer.set_recording_output_file(string);
end

function [] = edit_quality_handler(h, ~, obj_timer)
        data = str2double(get(h, 'string'));
        if data < 1 || data > 100
                return;
        end
        obj_timer.set_recording_quality(data);
end

function [] = edit_fps_handler(h, ~, obj_timer)
        data = str2double(get(h, 'string'));
        obj_timer.set_recording_fps(data);
end

function [] = keypress_handler(~, event, obj_timer)
        c = double(event.Character);
        %{
        %  When pressing characters like ESC, Alt, F1, etc,
        %  Matlab reads it as a vector. This is a workaround,
        %  as I assume these keys are not going to be used.
        %}
        if ~size(c, 1)
                return;
        end

        switch c
        case 'p'
                if obj_timer.ispaused
                        obj_timer.unpause;
                else
                        obj_timer.pause;
                end
                disp('ANIMATED: play/pause');
        case 'r'
                obj_timer.restart;
                disp('ANIMATED: restart');
        case 'R'
                started = obj_timer.get_recording_started;
                obj_timer.set_recording(~started);
        case '>'
                obj_timer.increase_velocity;
                new_vel = obj_timer.get_velocity;
                disp(['ANIMATED: velocity: ' num2str(new_vel) 'x']);
        case '<'
                obj_timer.decrease_velocity;
                new_vel = obj_timer.get_velocity;
                disp(['ANIMATED: velocity: ' num2str(new_vel) 'x']);
        case 28
                obj_timer.move_index_backward;
                disp('ANIMATED: backward');
        case 29
                obj_timer.move_index_forward;
                disp('ANIMATED: forward');
        otherwise
        end
end

function [] = timer_handler(~, ~, ...
                            h_figure, ...
                            num_objects, ...
                            num_axes, ...
                            h_video_slider, ...
                            h_plot, ...
                            h_text, ...
                            obj_timer, ...
                            t, ...
                            X, Y, Z, ...
                            h_velocity_arrow, ...
                            vx, vy, vz)
                        
        %{
        %  Update slider position
        %}
        index = obj_timer.get_index;
        set(h_video_slider, 'value', index);

        %{
        %  Update time visualisation
        %}
        set(h_text, 'string', num2str(t(index)));
        
        for i=1:num_objects
                for j=1:num_axes
                        x = X(j,index,i);
                        y = Y(j,index,i);
                        z = Z(j,index,i);

                        set(h_plot(j,i), ...
                           'xdata', x, ...
                           'ydata', y, ...
                           'zdata', z);
                        
                        set(h_velocity_arrow(j,i), ...
                            'xdata', x, ...
                            'ydata', y, ...
                            'zdata', z, ...
                            'udata', vx(j,index,i), ...
                            'vdata', vy(j,index,i), ...
                            'wdata', vz(j,index,i));
                 end
        end
        
        drawnow;

        %{
        %  Record data into file
        %}
        started = obj_timer.get_recording_started;
        ended = obj_timer.get_recording_ended;
        if started
                frame = getframe(h_figure);
                obj_timer.set_recording_frame(frame);
        elseif ended
                obj_timer.clear_recording;
        end

        obj_timer.increment_index;
end

function [] = timer_update_gui_handler(~, ~, ...
                                       obj_timer, ...
                                       h_button_play, ...
                                       h_popupmenu_speed, ...
                                       h_button_record, ...
                                       h_figure, ...
                                       h_button_rotate, ...
                                       h_button_zoom_in, ...
                                       h_edit_output, ...
                                       h_edit_quality, ...
                                       h_edit_fps)
        paused = obj_timer.get_paused;
        set(h_button_play, 'value', paused);
        
        vel_index = obj_timer.get_vel_index;
        obj_timer.set_velocity(vel_index);
        set(h_popupmenu_speed, 'value', vel_index);      
         
        rotate3d_enabled = get(rotate3d(h_figure), 'enable');
        if strcmp(rotate3d_enabled, 'on')
            enabled = 1;
        else
            enabled = 0;
        end
        set(h_button_rotate, 'value', enabled);
         
        zoom_enabled = get(zoom(h_figure), 'enable');
        if strcmp(zoom_enabled, 'on')
            enabled = 1;
        else
            enabled = 0;
        end
        set(h_button_zoom_in, 'value', enabled);
        
        recording_started = obj_timer.get_recording_started;
        set(h_button_record, 'value', recording_started);
        
        recording_gui = obj_timer.get_recording_gui;
        set(h_edit_output, 'enable', recording_gui);
        set(h_edit_quality, 'enable', recording_gui);
        set(h_edit_fps, 'enable', recording_gui);
end
