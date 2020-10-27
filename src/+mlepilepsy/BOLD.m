classdef BOLD 
	%% BOLD provisions BOLD data suitable for deep learning epilepsy representations.
    %  BOLD originates from 4dfp repositories of normal and epilepsy subjects.  
    %  For dimensionality reduction, BOLD is downsampled from 333 images to 999 images,
    %  preserving temporal resolution.  

	%  $Revision$
 	%  was created 25-Oct-2020 13:35:52 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlepilepsy/src/+mlepilepsy.
 	%% It was developed on Matlab 9.9.0.1495850 (R2020b) Update 1 for MACI64.  Copyright 2020 John Joowon Lee.
 	
    properties (Constant)
        SIZE = [16 22 16]
        MMPPIX = [9 (3*32/11) 9]
    end
    
	properties (Dependent)
 		gm333 % ImagingContext2
 		gm999 % ImagingContext2
    end
    
    methods (Static)
        function mean_cc = buildCorrelations(patt)
            
            deleteExisting('*Correlations.mat')
            
            assert(ischar(patt))
            mean_cc = zeros(2009, 2009); 
            count = 0;
            assert(~isempty(globT(patt)))
            for m = globT('*.mat')
                count = count + 1;
                c = mlepilepsy.Correlations.createFromMat(m{1});
                mean_cc = mean_cc + c.itsCorrcoef;
                [~,fp] = fileparts(m{1});
                save(c, [fp '_buildCorrelations.mat'])
            end
            mean_cc = mean_cc/count;
            save('mlepilepsy_BOLD_buildCorrelations_mean_cc.mat', 'mean_cc')
            
            figure
            imagesc(mean_cc)
            colorbar
        end
    end

	methods 
        
        %% GET
        
        function g = get.gm333(this)
            g = this.gm333_;
        end
        function g = get.gm999(this)
            g = this.gm999_;
        end
        
        %%        
        
        function ic = dat2ic(this, dat, varargin)
            ip = inputParser;
            addParameter(ip, 'filename', ['mlepilepsy_BOLD_dat2ic_dt' datestr(now, 'yyyymmddHHMMSS') '.4dfp.hdr'])
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            if contains(ipr.filename, '.nii')
                ifc = this.gm999.nifti;
            else
                ifc = this.gm999.fourdfp;
            end
            ifc.filename = ipr.filename;
            ifc.img = flip(dat, 2);
            ic = mlfourd.ImagingContext2(ifc);
        end
        function dat = obj2dat(this, obj)
            ic = this.imresize3(obj);
            dat = single(ic.nifti.img); % == single(ic.fourdfp.img)
            dat = flip(dat, 2); % Patrick's convention
        end
        function ic = imresize3(this, obj, varargin)
            % @param obj is understood by ImagingContext2
            % @return ImagingContext2
            
            ic = mlfourd.ImagingContext2(obj);
            sic = size(ic);
            assert(all(sic(1:3) == [48 64 48]))
            ifc = ic.fourdfp;
            if ndims(ifc) == 3
                ifc.img = imresize3(ifc.img, this.SIZE, varargin{:});
            else
                img = zeros([this.SIZE size(ifc,4)]);
                for t = 1:size(ifc,4)
                    img(:,:,:,t) = imresize3(ifc.img(:,:,:,t), this.SIZE, varargin{:});
                end
                ifc.img = img;
            end
            ifc.mmppix = this.MMPPIX;
            if contains(ifc.fileprefix, '333')
                ifc.fileprefix = strrep(ifc.fileprefix, '333', '999');
            else
                ifc.fileprefix = [ifc.fileprefix '_999'];
            end
            ic = mlfourd.ImagingContext2(ifc);
        end
        
 		function this = BOLD(varargin)
            gm333_fn_ = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mldl', 'data', 'gm3d_and_cerebellum.4dfp.hdr');
            this.gm333_ = mlfourd.ImagingContext2(gm333_fn_);
            this.gm999_ = this.imresize3(this.gm333_, 'Method', 'nearest');
            this.gm999_.fileprefix = 'gm3d_and_cerebellum_999';
        end
    end
    
    %% PRIVATE

    properties (Access = private)
        gm333_
        gm999_
    end
    
	methods (Access = private)	  
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

