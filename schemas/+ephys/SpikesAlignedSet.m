%{
ephys.SpikesAlignedSet (computed) # Set of spikes binned a certain way

-> stimulation.StimTrialGroup
-> ephys.SpikesAlignedConditions
-> ephys.SpikeSet
---
spikesalignedset_ts=CURRENT_TIMESTAMP: timestamp             # automatic timestamp. Do not edit
%}

classdef SpikesAlignedSet < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('ephys.SpikesAlignedSet');
        popRel = (ephys.SpikeSet .* ephys.Spikes) * acq.EphysStimulationLink * ...
            stimulation.StimTrialGroup * ephys.SpikesAlignedConditions;
    end
    
    methods 
        function self = SpikesAlignedSet(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods (Access=protected)        
        function makeTuples(this, key)
            tuple = key;
            insert(this, tuple);
            
            % Insert a StimTrialGroupBinned for each neuron
            tuples = dj.struct.join(key, fetch(ephys.Spikes(key)));
            for tuple = tuples'
                fprintf('Importing aligned spikes for unit id %d\n', tuple.unit_id);
                makeTuples(ephys.SpikesAligned, tuple);
            end
        end
    end
end
