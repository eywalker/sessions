classdef SpikeSortingHelper

	properties
        Waveforms = [];
        SpikeTimes = [];
        Features = [];
        tt = [];
        dataSource = [];
	end

	methods
		function [self args] = SpikeSortingHelper(electrode,varargin)
            if isstruct(electrode) && isfield(electrode, 'ClusterAssignment')
                % Construct from a saved structure
                f = properties('SpikeSortingHelper');
                for i = 1:length(f)
                    self.(f{i}) = electrode.(f{i});
                end
                return;
            elseif isstruct(electrode) && isfield(electrode, 't')
                self.dataSource = struct('type','tt');
                self.tt = electrode;
                args = varargin;
            elseif isstruct(electrode) && count(detect.Electrodes(electrode)) > 0
                self.dataSource = struct('type','DataJoint', 'key', electrode);
                self = loadTT(self);
                args = varargin;
            elseif ismatrix(electrode) && nargin > 1 && any(size(electrode) == length(varargin{1}))
                warning('Construct fake spike structure.  Only use for debugging.'); %#ok
                self.dataSource = struct('type','Raw');
                self.SpikeTimes = struct('data', varargin{1}, 'meta', struct);
                self.Features = struct('data', electrode, 'meta', struct);
                args = varargin(2:end);
                return; % Don't try and get waveforms and spike times
            else
                error('Could not construct data for the SpikeSortingHelper');
            end
            self = getWaveforms(self);
            self = getTimes(self);
        end        

        function self = compress(self, index)
            if strcmp(self.dataSource.type,'DataJoint') ~= 1
                warning('SpikeSortingHelper:uncompress','Compressing without a DJ source is not reversible');
            end
            if nargin < 2
                self.Waveforms.data = [];
                self.SpikeTimes.data = [];
                self.Features.data = [];
            else
                self.Waveforms.data = cellfun(@(x) x(:, index), self.Waveforms.data, 'UniformOutput', false);
                self.Waveforms.meta.subset = index;
            end
            self.tt = [];
        end
        
        function self = uncompress(self)
            if strcmp(self.dataSource.type,'DataJoint') == 1
                self = loadTT(self);
                self = getWaveforms(self);
                self = getTimes(self);
                if isfield(self.Features, 'meta') && isfield(self.Features.meta,'Feature')
                    if isfield(self.Features.meta,'num')
                        self = getFeatures(self,self.Features.meta.Feature,self.Features.meta.num);
                    else
                        self = getFeatures(self,self.Features.meta.Feature);
                    end
                end
            else
                error('Cannot uncompress other sources than DataJoint');
            end
        end
        
        function self = loadTT(self)
            % Load the TT file
            assert(count(detect.Electrodes(self.dataSource.key)) == 1, 'Only call this for one VC');

            de = fetch(detect.Electrodes(self.dataSource.key), 'detect_electrode_file');
            fn = getLocalPath(de.detect_electrode_file);

            self.tt = ah_readTetData(fn);
        end

        % Get the waveforms (and scale them) from the tt file
        function self = getWaveforms(self)
            % Get and scale the waveforms

            % old tt files were not stored in consistent units, try and
            % convert them
            if ~isfield(self.tt, 'units') || ~strcmp(self.tt.units, 'muV')

                % By default, assume data was recorded on Tolias lab system and
                % determine gain automatically
                if max(mean(self.tt.w{1}, 2)) > 1  % data originally was in raw values
                    gain = 2^23 / 317000;
                else % new data is in volts, convert to muV
                    gain = 1e-6;
                end

                % with old Neuralynx and newer Blackrock data we need to
                % convert the recordings manually to muV. For those datasets we
                % manually put the gains into the table acq.AmplifierGains.
                % Those values are used to override the automatically
                % determined gains (if a tuple exists).
                if isstruct(self.dataSource) && isequal(self.dataSource.type, 'DataJoint')
                    key = self.dataSource.key;
                    if count(acq.AmplifierGains(key))
                        gain = fetch1(acq.AmplifierGains(key), 'preamp_gain');
                    elseif ~count(acq.Sessions(key) & 'recording_software IN ("Hammer", "Acquisition2.0")')
                        warning('SpikeSortingHelper:automaticGain', ...
                            ['Scaling waveforms based on heuristics that apply only to Tolias lab system\n' ...
                            'but data were recorded by a different system.\n' ...
                            'Enter the gains into acq.AmplifierGains if the scale is important!'])
                    end
                end
            else
                gain = 1; % new files are already in muV
            end

            wf = cellfun(@(x) x / gain, self.tt.w, 'UniformOutput',false);
            self.Waveforms = struct('data', {wf}, 'meta', struct('units', 'muV', 'gain', gain));
        end

        % Get the times from the tt file
        function self = getTimes(self)
            self.SpikeTimes = struct('data', self.tt.t, 'meta', struct);
        end

        function times = getSpikeTimes(self, ids)
            % Return all (or a subset) of the spike times in ms
            if nargin < 2
                times = self.SpikeTimes.data;
            else
                times = self.SpikeTimes.data(ids);
            end
        end

        % Extract features from spike waveforms
        function self = getFeatures(self,feature,n)
            if nargin < 3, n = 3; end
            if strcmp(feature, 'Points') == 1
                dat = cat(1,self.Waveforms.data{:});
                X = dat([25 15 10],:)';
            elseif strcmp(feature, 'PCA') == 1
                X = [];
                for i = 1:length(self.Waveforms.data)
                    [~,P] = princomp(self.Waveforms.data{i}');
                    X = [X P(:,1:n)]; %#ok
                end
            else
                error('Unsupported feature');
            end
            self.Features = struct('data',X,'meta',struct('Feature',feature,'num',n));
        end
    end
end
