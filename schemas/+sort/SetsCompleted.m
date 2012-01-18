%{
sort.SetsCompleted (imported) # Completed clustering sets
->sort.Sets
---
%}

classdef SetsCompleted < dj.Relvar & dj.AutoPopulate
    properties(Constant)
        table = dj.Table('sort.SetsCompleted');
        popRel = sort.Sets ...
            - (sort.Electrodes * sort.Methods('sort_method_name = "TetrodesMoG"') - sort.TetrodesMoGFinalize);
    end
    
    methods
        function self = SetsCompleted(varargin)
            self.restrict(varargin{:})
        end
        
        function makeTuples(self, key)
            self.insert(key);
        end
    end
end
