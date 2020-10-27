classdef GSP < mlepilepsy.BOLD
	%% GSP  

	%  $Revision$
 	%  was created 25-Oct-2020 20:00:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlepilepsy/src/+mlepilepsy.
 	%% It was developed on Matlab 9.9.0.1495850 (R2020b) Update 1 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties (Constant)
        ARCHIVE_HOME = '/data/nil-bluearc/shimony/jjlee/GSP'
        DENOISING_TAG = '_faln_dbnd_xr3d_atl_g7_bpss_resid'
        TARGET_FOLDER = '/data/nil-bluearc/shimony/jjlee/GSP_999_mat'
    end
    
    methods (Static)
        function this = createFromNILArchive(varargin)
            %% Creates mat-files, formatted by Patrick Luckett's conventions with object named 'dat', in targetFolder.
            
            ip = inputParser;
            addOptional(ip, 'targetFolder', mlepilepsy.GSP.TARGET_FOLDER, @(x) isfolder(x) || ischar(x))
            parse(ip, varargin{:})
            ipr = ip.Results;            
            if ~isfolder(ipr.targetFolder)
                mkdir(ipr.targetFolder)
            end
            this = mlepilepsy.GSP();
            
            pwd0 = pushd(this.ARCHIVE_HOME);  
            for ss = globFoldersT('Sub*_Ses*')
                for ssb = globFoldersT(fullfile(ss{1}, 'bold*'))
                    try
                        fprintf(['createFromNILArchive:  working on ' this.boldFileprefix(ssb{1}) '\n'])
                        ic = mlfourd.ImagingContext2( ...
                            fullfile(ssb{1}, sprintf('%s.4dfp.hdr', this.boldFileprefix(ssb{1}))));
                        dat = this.obj2dat(ic);
                        save(fullfile(ipr.targetFolder, [strrep(ssb{1}, filesep, '_') '.mat']), 'dat')
                    catch ME
                        handwarning(ME)
                    end
                end
            end
            popd(pwd0)
        end
        function this = createFromNifti(varargin)
            %% Creates mat-files, formatted by Patrick Luckett's conventions with object named 'dat', in targetFolder.
            
            ip = inputParser;
            addOptional(ip, 'targetFolder', mlepilepsy.GSP.TARGET_FOLDER, @(x) isfolder(x) || ischar(x))
            parse(ip, varargin{:})
            ipr = ip.Results;            
            if ~isfolder(ipr.targetFolder)
                mkdir(ipr.targetFolder)
            end
            this = mlepilepsy.GSP();
            
            pwd0 = pushd([this.ARCHIVE_HOME '_nii_resid']);  
            for nii = globT(sprintf('Sub*_Ses*_b*%s.nii.gz', this.DENOISING_TAG))
                try
                    fprintf(['createFromNILArchive:  working on ' nii{1} '\n'])
                    ic = mlfourd.ImagingContext2(nii{1});
                    dat = this.obj2dat(ic);
                    save(fullfile(ipr.targetFolder, [strrep(nii{1}, filesep, '_') '.mat']), 'dat')
                catch ME
                    handwarning(ME)
                end
            end
            popd(pwd0)
        end
    end
    
    %% PRIVATE
    
	methods (Access = private)		  
 		function this = GSP(varargin)
 			this = this@mlepilepsy.BOLD(varargin{:});
        end
        
        function fp = boldFileprefix(this, folds)
            % @param required folds ~ "Sub0001_Ses1/bold\d+"
            
            assert(ischar(folds))
            ss = split(folds, filesep);
            idx = ss{2};
            idx = str2double(idx(5));
            fp = sprintf('%s_b%i%s', ss{1}, idx, this.DENOISING_TAG);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

