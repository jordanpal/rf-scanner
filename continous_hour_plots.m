%% Jordan Palamos 2016
% Continuously sweep and record rf spectrum. Uses MATLAB TMTOOL
% to control the R&S FSC3 spectrum analyzer. Will save plots in 
% hour long blocks. Frequency band is hard coded (but may be chaged)
% and other sweep parameters are autoset by spectrum analyzer.

% Create a device object. 
deviceObj = icdevice('rsspecan.mdd', 'TCPIP0::169.254.17.1::inst0');
 
% Connect device object to hardware.
connect(deviceObj);

% Querying the device IDN string.
% This is just to verify the connection
[data] = invoke(get(deviceObj, 'Utilityfunctionsinstrumentio'), 'queryvistring', '*IDN?', 200)


%Initialize amplitude, frequency, and time in each band:
%  FSC3 model has 631 points per sweep, cannot be changed
%  Preinitializing numSweeps for speed. Will cut out blank points at end.
%  (not necessarily fixed numSweep per hour.

Amplitude = zeros(ArrayLength, numSweeps); %initialize array with zeroes
Fstart = 9E+3;
Fend = 1E+8;
ArrayLength = 631;
numSweeps = 8000;
Frequency = linspace(Fstart,Fend,ArrayLength);
Time = zeros(numSweeps,1);



% Setting sweep parameters on Spectrum Analyzer
invoke(get(deviceObj, 'Configuration'), 'configureacquisition', 1, 0, 1);
invoke(get(deviceObj, 'Configuration'), 'configuresweeptime', 1, 1, 0);
invoke(get(deviceObj, 'Configuration'), 'configurefrequencystartstop', 1, Fstart, Fend);
%invoke(get(deviceObj, 'Configuration'),'configurefrequencystepsize',1,100000);

% Start Loop, outer loop always true...Inner loop recycles every hour
while (true)
startTime = datetime;
sweep=1;
    while hour(datetime) == hour(startTime)
        % Fetching the trace
        [ActualPoints, Amplitude(:,sweep)] = invoke(get(deviceObj, 'Measurement'), 'readytrace', 1, 1, 5000, ArrayLength, Amplitude(:,sweep));
        Time(sweep)=datetime;
        sweep=sweep+1;
    end
%Cut out empty values
Time = Time(1:sweep);
Amplitude = Amplitude(:,1:sweep);
imagesc(Time,Frequency,Amplitude)
set(gca,'YDir', 'normal')
ylabel('Frequency')
xlabel('Time')
%savefig(['200MHz_3GHz' datestr(startTime,'mm_dd_yyyy_HHMMSS') '.fig'])
title(['10kHz_100MHz_' datestr(startTime,'dd_mm_yyyy_HHMMSS')], 'interpreter', 'none')
saveas(gca,[datestr(startTime,'dd_mm_yyyy_HHMMSS') '_10k_100M' '.fig'], 'compact')
close(h);
end

% Disconnect device object from hardware.
disconnect(deviceObj);
	 
% Delete the  device object.
delete (deviceObj);