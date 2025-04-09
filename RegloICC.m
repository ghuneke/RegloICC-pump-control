%-----------------------------------------
% Reglo ICC Peristaltic Pump Adapter Class
%-----------------------------------------

%--------------------------------------------------------------------------------------%
% CUSTOM CLASS MANAGING THE COMMUNICATION WITH A REGLO ICC WITH 4 INDEPENDENT CHANNELS %
%--------------------------------------------------------------------------------------%

% adapted from https://blog.darwin-microfluidics.com/how-to-control-the-reglo-icc-pump-using-python-and-matlab/

classdef RegloICC

    %%% Define the class properties
    properties
        sp        = []; % serial port
        COM       = ''; % input parameter: COM port to use for the pump
        direction = [0 0 0 0]; % direction of rotation of each channel: 0 = clockwise, 1 = counter-clockwise
        mode      = [0 0 0 0]; % operational mode of each channel: 0 = RPM, 1 = Flow Rate, 2 = Volume (over time), one can add here all other modes (check Table 3)
        speed     = zeros(4,1); % rotation speed for each channel in case of RPM mode
    end

    %%% Define the class methods
    methods
        % Initialize the pump
        function obj = RegloICC(COM)
            obj.COM = COM;
            obj.sp = serialport(obj.COM,9600,'Parity','None','DataBits',8,'StopBits',1); % open the serial port with the data format corresponding to the RegloICC pump
        end

        % Delete the pump
        function obj = delete(obj)
            delete(obj.sp);
            obj.sp = [];
        end

        % Start the corresponding channel
        function startChannel(obj,channel)
            write(obj.sp,strcat(num2str(channel),'H',13),"uint8"); % 'H' to start the channel
            % 13 for the carriage return [CR] required to tell the pump that the command is finished
            pause(0.1); % give the pump time to process the command before reading the response
            while obj.sp.NumBytesAvailable > 0 % clear the buffer
                response = read(obj.sp, obj.sp.NumBytesAvailable, "char");
            end
            if response == '-'
                error 'channel setting(s) are not correct or unachievable.'
            end
        end

        % Stop the corresponding channel
        function stopChannel(obj,channel)
            write(obj.sp,strcat(num2str(channel),'I',13),"uint8"); % 'I' to stop the channel
            pause(0.1);
            while obj.sp.NumBytesAvailable > 0
                read(obj.sp, obj.sp.NumBytesAvailable, "char");
            end
        end

        % Set the rotation direction for a single channel
        function obj = setDirection(obj,channel,direction)
            if direction == 1
                write(obj.sp,strcat(num2str(channel),'K',13),"uint8"); % counter-clockwise rotation
                pause(0.1);
                while obj.sp.NumBytesAvailable > 0
                    read(obj.sp, obj.sp.NumBytesAvailable, "char");
                end
            else
                write(obj.sp,strcat(num2str(channel),'J',13),"uint8"); % clockwise rotation
                pause(0.1);
                while obj.sp.NumBytesAvailable > 0
                    read(obj.sp, obj.sp.NumBytesAvailable, "char");
                end
            end
            obj.direction(channel) = direction;
        end

        % Get the rotation direction of a single channel
        function getDir = getDirection(obj,channel)
            write(obj.sp,strcat(num2str(channel),'xD',13),"uint8"); % 'xD' to get the rotation direction
            pause(0.1);
            getDir = read(obj.sp,obj.sp.NumBytesAvailable,"char"); % read the rotation direction from the corresponding channel
        end

        % Set the speed for a single channel in mL/min
        function obj = setSpeed(obj,channel,speed) % in mL/min
            % floating point dissection to put command in correct format
            exponent = floor(log10(abs(speed)));
            mantissa = abs(speed) / 10^exponent;

            % Convert to string format
            if speed < 1
                % Scale mantissa to desired format
                mantissa = mantissa * 10^(floor(log10(abs(speed)) + 1));
                % preserves correct number of digits
                if (speed < .1) && (speed > .00999999)
                    mantissa = round(mantissa * 10^4);
                elseif speed < .01
                    mantissa = round(mantissa * 10^5);
                else
                    mantissa = round(mantissa * 10^3);
                end
            elseif speed >= 1
                % different offsets preserve number of digits
                if (speed >= 10) && (speed < 100)
                    mantissa = mantissa * 10^(floor(log10(abs(speed)) + 2));
                elseif (speed >= 100) && (speed < 999)
                    mantissa = mantissa * 10^(floor(log10(abs(speed)) + 1));
                elseif speed >= 1000
                    mantissa = mantissa * 10^(floor(log10(abs(speed)) + 0));
                elseif speed < 10
                    mantissa = mantissa * 10^(floor(log10(abs(speed)) + 3));
                end
            end
            if exponent >= 0
                speedString = sprintf('%4d+%1d', mantissa, exponent );
            elseif exponent <0
                speedString = sprintf('%4d-%1d', mantissa, abs(exponent));
            end
            write(obj.sp,strcat(num2str(channel),'f',speedString,13),"uint8"); % write the speed to the corresponding channel
            pause(0.1);
            while obj.sp.NumBytesAvailable > 0
                response = read(obj.sp, obj.sp.NumBytesAvailable, "char");
                fprintf('Channel %d speed (uL/min): %s',channel,response)
            end
            if (response == '#') 
                error 'The command was not executed successfully.'
            end
        end

        % Read out speed of a single channel in RPM when in RPM mode
        function getRPM = getSpeed(obj,channel)
            write(obj.sp,strcat(num2str(channel),'f',13),"uint8"); % 'f' to get the speed in ml/min
            pause(0.1);
            getRPM = read(obj.sp,obj.sp.NumBytesAvailable,"char");
        end

        % Set the operational mode for a single channel
        function obj = setMode(obj,channel,mode)
            if mode == 'L'
                write(obj.sp,strcat(num2str(channel),'L',13),"uint8"); % RPM mode
                pause(0.1);
                while obj.sp.NumBytesAvailable > 0
                    read(obj.sp, obj.sp.NumBytesAvailable, "char");
                end
            elseif mode == 'M'
                write(obj.sp,strcat(num2str(channel),'M',13),"uint8"); % Flow rate mode
                pause(0.1);
                while obj.sp.NumBytesAvailable > 0
                    read(obj.sp, obj.sp.NumBytesAvailable, "char");
                end
            elseif mode == 'O'
                write(obj.sp,strcat(num2str(channel),'O',13),"uint8"); % Volume at rate
                pause(0.1);
                while obj.sp.NumBytesAvailable > 0
                    read(obj.sp, obj.sp.NumBytesAvailable, "char");
                end
            elseif mode == 'G'
                write(obj.sp,strcat(num2str(channel),'G',13),"uint8"); % Volume (over time) mode
                pause(0.1);
                while obj.sp.NumBytesAvailable > 0
                    read(obj.sp, obj.sp.NumBytesAvailable, "char");
                end
            elseif mode == 'N'
                write(obj.sp,strcat(num2str(channel),'N',13),"uint8"); % Time mode
                pause(0.1);
                while obj.sp.NumBytesAvailable > 0
                    read(obj.sp, obj.sp.NumBytesAvailable, "char");
                end
            else
                error('Error. Please enter a valid mode command: L (RPM), M (Flow Rate), O (Volume at rate), G (Volume over time), N (Time)')
            end

            obj.mode(channel) = mode;
        end

        % Get the operational mode of a single channel
        function getMd = getMode(obj,channel)
            write(obj.sp,strcat(num2str(channel),'xM',13),"uint8"); % 'xM' to get the operational mode
            pause(0.1);
            getMd = read(obj.sp,obj.sp.NumBytesAvailable,"char");
        end

        function obj = setTubeDiameter(obj,channel,size) % size given as xx.xx mm
            % format input to discrete type 2 input
            sizeStr = num2str(size);
            sizeStr = strrep(sizeStr, '.', '');
            while length(sizeStr) < 4
                sizeStr = strcat('0', sizeStr);
            end

            write(obj.sp,strcat(num2str(channel),'+',sizeStr,13),"uint8"); 
            pause(0.1);
            while obj.sp.NumBytesAvailable > 0
                read(obj.sp, obj.sp.NumBytesAvailable, "char");
            end        
        end

    end

end




%-------------------------------------------------------------------%
% Examples on how to use the defined class to control the Reglo ICC %
%-------------------------------------------------------------------%

%%% To start the communication and open the serial port %%%
% pump = RegloICC('COM5') % Replace 'COM5' with your actual COM port

%%% Start channel 3 %%%
% pump.start_channel(3)

%%% Get the rotation direction of channel 3 %%%
% pump.get_direction(3)

%%% Set the rotation direction of channel 3 to clockwise %%%
% pump.set_direction(3,0)

%%% Get the current operational mode of channel 3 %%%
% pump.get_mode(3)

%%% Set the operational mode of channel 3 to RPM %%%
% pump.set_mode(3,0)

%%% Get the current speed setting of channel 3 %%%
% pump.get_speed(3)

%%% Set the setting speed of channel 3 to 24 RPM %%%
% pump.set_speed(3,24)

%%% Stop channel 3 %%%
% pump.stop_channel(3)

%%% Delete pump %%%
% pump = delete(pump)