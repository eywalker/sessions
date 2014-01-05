%{
acq.SessionTimestamps (manual) # events recorded by the timestamper

->acq.Sessions
channel          : tinyint unsigned # channel that received a message
timestamper_time : bigint           # real time on computer
---
count            : int unsigned     # hardware count
%}

classdef SessionTimestamps < dj.Relvar
    properties(Constant)
        table = dj.Table('acq.SessionTimestamps');
    end
    
    methods
        function self = SessionTimestamps(varargin)
            self.restrict(varargin{:})
        end
    end
       
    methods (Static)
        function accurateTime = getRealTimes(relvar)
            % Convert hardware counter to real times accounting for wraparound
            %   accurateTime = getRealTimes(self) converts counter values to real times
            %   in ms for the tuples in relvar self.
            
            [count, timestamperTime, sessionStartTime] = fetchn(relvar, 'count', 'timestamper_time', 'session_start_time');
            timestamperTime = double(timestamperTime);
            sessionStartTime = double(sessionStartTime);
            
            % Rescale to times
            counterRate = 10e6 / 1000; % pulses / ms (should be stored somewhere)
            counterPeriod = 2^32 / counterRate; % period of time it takes to count one cycle
            
            countTime = count / counterRate; 
            approximateSessionTime = timestamperTime - sessionStartTime; % approximately how long it has passed since session began
            
            % Compute expected counter value based on CPU time
            approximateSessionPeriods = floor(approximateSessionTime / counterPeriod); % approximately how many cycles it has gone through
            approximateResidualPeriod = mod(approximateSessionTime, counterPeriod); %
            
            % Correct edge cases where number of periods is off by one
            idx = find((approximateResidualPeriod - countTime) > counterPeriod / 2);
            approximateSessionPeriods(idx) = approximateSessionPeriods(idx) + 1;
            %approximateSessionPeriods = approximateSessionPeriods + fix((approximateResidualPeriod - countTime) / (counterPeriod / 2));
            
            accurateTime = countTime + approximateSessionPeriods * counterPeriod;
            plot(abs(accurateTime - approximateSessionTime));
            val = max(abs(accurateTime - approximateSessionTime));
            if ~isempty(val)
                assert(val < counterPeriod / 2);
            end
            
        end
    end
end
