classdef MSC < mlepilepsy.BOLD
	%% MSC  

	%  $Revision$
 	%  was created 25-Oct-2020 20:00:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlepilepsy/src/+mlepilepsy.
 	%% It was developed on Matlab 9.9.0.1495850 (R2020b) Update 1 for MACI64.  Copyright 2020 John Joowon Lee.
 	 	
	properties (Constant)
        ARCHIVE_HOME = '/data/nil-bluearc/shimony/jjlee/MSC_JJL'
        DENOISING_TAG = '_faln_dbnd_xr3d_atl_g7_bpss_resid'
        TARGET_FOLDER = '/data/nil-bluearc/shimony/jjlee/MSC_999_mat'
    end
    
    methods (Static)
        function this = createFromNILArchive(varargin)      
            %% Creates mat-files, formatted by Patrick Luckett's conventions with object named 'dat', in targetFolder.
            
            ip = inputParser;
            addOptional(ip, 'targetFolder', mlepilepsy.MSC.TARGET_FOLDER, @(x) isfolder(x) || ischar(x))
            parse(ip, varargin{:})
            ipr = ip.Results;            
            if ~isfolder(ipr.targetFolder)
                mkdir(ipr.targetFolder)
            end
            this = mlepilepsy.MSC();
            
            pwd0 = pushd(this.ARCHIVE_HOME);  
            for mvb = globFoldersT('MSC*/vc*/bold*')
                try
                    fprintf(['createFromNILArchive:  working on ' this.boldFileprefix(mvb{1}) '\n'])
                    ic = mlfourd.ImagingContext2( ...
                        fullfile(mvb{1}, sprintf('%s.4dfp.hdr', this.boldFileprefix(mvb{1}))));
                    dat = this.obj2dat(ic);
                    save(fullfile(ipr.targetFolder, [strrep(mvb{1}, filesep, '_') '.mat']), 'dat')
                catch ME
                    handwarning(ME)
                end
            end
            popd(pwd0)
        end
    end

    %% PRIVATE
    
	methods (Access = private)
 		function this = MSC(varargin)
 			%% MSC
 			%  @param .

 			this = this@mlepilepsy.BOLD(varargin{:});
        end
        
        function fp = boldFileprefix(this, folds)
            % @param required folds ~ "MSC01/vc12345/bold\d+"
            
            assert(ischar(folds))
            ss = split(folds, filesep);
            idx = ss{3};
            idx = str2double(idx(5));
            fp = sprintf('%s_b%i%s', ss{2}, idx, this.DENOISING_TAG);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end
