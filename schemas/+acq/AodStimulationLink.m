%{
acq.AodStimulationLink (computed)   # stimulation sessions that were recorded

->acq.AodScan
->acq.Stimulation
->acq.SessionsCleanup
---
%}


classdef AodStimulationLink < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('acq.AodStimulationLink');
        popRel = acq.AodScan * acq.Stimulation ...
            & acq.SessionsCleanup & '(stim_stop_time - stim_start_time) > 60000' & ...
            '(IF(aod_scan_stop_time > stim_stop_time, stim_stop_time, aod_scan_stop_time) - IF(aod_scan_start_time < stim_start_time, stim_start_time, aod_scan_start_time)) > 120000';
    end
    
    methods
        function self = AodStimulationLink(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            insert(self, key);
        end
    end
end
