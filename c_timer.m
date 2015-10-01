classdef c_timer < handle
properties (SetAccess = private)
        handle;
        index;
        stopped;
        paused;
        previous_paused_flag;
        previous_paused;
        loop;
        num_frames;
        
        recording_output_file;
        recording_started;
        recording_ended;
        recording_index;
        recording_quality;
        recording_fps;
        recording_obj;
        recording_gui;
        recording_opened;
        
        normal_increment;
        velocity;
        vel_array;
        vel_index;
end
methods
        %{
        %  Destructor
        %}
        function [] = delete(obj)
                delete(obj.handle);
        end

        %{
        %  Constructor
        %}
        function [ret] = c_timer(num_frames)
                ret.index = 1;
                ret.stopped = 1;
                ret.paused = 0;
                ret.num_frames = num_frames;
                ret.previous_paused_flag = 0;
                ret.previous_paused = 1;
                ret.loop = 1;               
                
                ret.recording_output_file = 'file_movie.mp4';
                ret.recording_started = 0;
                ret.recording_ended = 0;
                ret.recording_index = 1;
                ret.recording_quality = 100;
                ret.recording_fps = 15;
                ret.recording_gui = 'on';
                ret.recording_opened = 0;
                
                ret.normal_increment = 1;
                ret.vel_array = [1 5 10 15 50 100 200];
                ret.vel_index = 1;
                ret.velocity = ret.vel_array(1,ret.vel_index);
        end

        function [ret] = isstopped(obj)
                ret = obj.stopped;
        end
        function [ret] = isloop(obj)
                ret = obj.loop;
        end
        function [] = start(obj)
                %{
                %  Variable stopped MUST be set before actually stoping.
                %  Else, horrible things will happen.
                %}
                obj.stopped = 0;
                start(obj.handle);
        end
        function [] = stop(obj)
                %{
                %  Variable stopped MUST be set before actually stoping.
                %  Else, horrible things will happen.
                %}
                obj.stopped = 1;
                stop(obj.handle);
        end
        function [] = loop_on(obj)
                obj.loop = 1;
        end
        function [] = loop_off(obj)
                obj.loop = 0;
        end
        function [] = restart(obj)
                obj.index = 1;
        end
        function [ret] = get_index(obj)
                ret = obj.index; 
        end
        function [] = increment_index(obj)
                if ~obj.paused
                        obj.index = obj.index + ...
                        obj.normal_increment * obj.velocity;
                end
                if obj.index > obj.num_frames
                        obj.index = obj.num_frames;
                        if ~obj.loop
                                obj.paused = 1;
                        else
                                obj.index = 1;
                        end
                end
        end
        function [] = set_handle(obj, data)
                obj.handle = data;
        end
        function [ret] = get_handle(obj)
                ret = obj.handle;
        end
        function [] = set_velocity(obj, data)
                obj.vel_index = data;
                obj.velocity = obj.vel_array(1,obj.vel_index);
        end
        function [ret] = ispaused(obj)
                ret = obj.paused;
        end
        function [] = pause(obj)
                obj.paused = 1;
        end
        function [] = unpause(obj)
                obj.paused = 0;
        end
        function [] = set_index(obj, new_index)
                if new_index < 1 || new_index > obj.num_frames
                            return;
                end
                obj.index = new_index;
        end
        function [] = move_index_forward(obj)
                obj.index = obj.index + ...
                obj.normal_increment * obj.velocity * 2;
                if obj.index > obj.num_frames
                        obj.index = 1 + obj.index - obj.num_frames;
                        if ~obj.loop
                                obj.paused = 1;
                                obj.index = obj.num_frames;
                        end
                end
        end
        function [] = move_index_backward(obj)
                obj.index = obj.index - ...
                obj.normal_increment * obj.velocity * 2;
                if obj.index < 1
                        obj.index = obj.num_frames + obj.index;
                        if ~obj.loop
                                obj.paused = 1;
                                obj.index = 1;
                        end
                end
        end
        function [] = set_previous_paused(obj, data)
                obj.previous_paused = data;
        end
        function [ret] = get_previous_paused(obj)
                ret = obj.previous_paused;
        end
        function [] = set_previous_paused_flag(obj, data)
                obj.previous_paused_flag = data;
        end
        function [ret] = get_previous_paused_flag(obj)
                ret = obj.previous_paused_flag;
        end
        function [ret] = get_max_frames(obj)
                ret = obj.num_frames;
        end
        function [] = increase_velocity(obj)
                array_length = size(obj.vel_array,2);
                obj.vel_index = obj.vel_index + 1;
                if obj.vel_index > array_length
                        obj.vel_index = array_length;
                end
                obj.velocity = obj.vel_array(obj.vel_index);
        end
        function [] = decrease_velocity(obj)
                obj.vel_index = obj.vel_index - 1;
                if obj.vel_index < 1
                        obj.vel_index = 1;
                end
                obj.velocity = obj.vel_array(obj.vel_index);
        end
        function [ret] = get_velocity(obj)
                ret = obj.vel_array(1,obj.vel_index);
        end
        function [ret] = get_vel_array(obj)
                ret = obj.vel_array;
        end
        function [ret] = get_vel_index(obj)
                ret = obj.vel_index;
        end
        function [ret] = get_paused(obj)
                ret = obj.paused;
        end
                
        function [] = set_recording(obj, data)
                if data                      
                        disp('ANIMATED: recording');                     
                        
                        obj.clear_recording;
                        obj.recording_index = 1;
                        obj.recording_ended = 0;
                        obj.recording_started = 1;
                        obj.set_recording_gui('off');
                        
                        file = obj.recording_output_file;
                        if exist(file, 'file') == 2
                                disp('ANIMATED ERROR: file exists');
                                obj.clear_recording;
                                obj.set_recording_gui('on');
                                return;
                        end
                        obj.recording_obj = ...
                            VideoWriter(file, 'MPEG-4');
                        obj.recording_obj.FrameRate = obj.recording_fps;
                        obj.recording_obj.Quality = obj.recording_quality;
                        
                        open(obj.recording_obj);
                        obj.recording_opened = 1;
                                    
                        fps = num2str(obj.recording_fps);
                        quality = num2str(obj.recording_quality);
                        disp('    VIDEO OPTIONS:');
                        disp(['        File: ' file]);
                        disp(['        Fps: ' fps]);
                        disp(['        Quality: ' quality]);
                        disp(['        Compression: ' obj.recording_obj.VideoCompressionMethod]);
                        disp(['        Format: ' obj.recording_obj.VideoFormat]);
                else 
                       file = obj.recording_output_file;
                       if exist(file, 'file') ~= 2
                                disp('ANIMATED ERROR: file does not exist');
                                obj.clear_recording;
                                obj.set_recording_gui('on');
                                return;
                        end
                        if ~obj.recording_opened
                                return;
                        end
                        obj.recording_ended = 1;
                        obj.recording_started = 0;
                        obj.set_recording_gui('on');

                        close(obj.recording_obj);
                        obj.recording_opened = 0;
                        disp('ANIMATED: recording ended');
                        disp('  ');
                end
        end
        function [ret] = get_recording_started(obj)
            ret = obj.recording_started;
        end
        function [ret] = get_recording_ended(obj)
            ret = obj.recording_ended;
        end
        function [ret] = get_recording_index(obj)
                ret = obj.recording_index;
        end
        function [] = increment_recording_index(obj)
                obj.recording_index = obj.recording_index + 1;
        end 
        function [] = set_recording_output_file(obj, data)
                obj.recording_output_file = data;
        end
        function [ret] = get_recording_output_file(obj)
                ret = obj.recording_output_file;
        end
        function [] = set_recording_quality(obj, data)
                obj.recording_quality = data;
        end
        function [ret] = get_recording_quality(obj)
                ret = obj.recording_quality;
        end
        function [] = set_recording_fps(obj, data)
                obj.recording_fps = data;
        end
        function [ret] = get_recording_fps(obj)
                ret = obj.recording_fps;
        end
        function [] = set_recording_frame(obj, frame)
                if obj.recording_opened
                        writeVideo(obj.recording_obj, frame);
                end
        end
        function [] = clear_recording(obj)
                obj.recording_started = 0;
                obj.recording_ended = 0;
           
                obj.recording_opened = 0;
        end
        function [] = set_recording_gui(obj, data)
                obj.recording_gui = data;
        end
        function [ret] = get_recording_gui(obj)
                ret = obj.recording_gui;
        end
end
end