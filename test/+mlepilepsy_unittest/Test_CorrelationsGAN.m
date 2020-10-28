classdef Test_CorrelationsGAN < matlab.unittest.TestCase
	%% TEST_CORRELATIONSGAN 

	%  Usage:  >> results = run(mlepilepsy_unittest.Test_CorrelationsGAN)
 	%          >> result  = run(mlepilepsy_unittest.Test_CorrelationsGAN, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 27-Oct-2020 15:34:46 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlepilepsy/test/+mlepilepsy_unittest.
 	%% It was developed on Matlab 9.9.0.1495850 (R2020b) Update 1 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
        function test_prepTrainingData(~)
            sourceFolder = '/data/nil-bluearc/shimony/jjlee/GSP_999_mat';
            datasetFolder = '/home2/jjlee/Docker/Epilepsy/GSP_999/png';
            
            pwd0 = pushd(sourceFolder);
            for m = globT('Sub*_buildCorrelations.mat')
                amat = load(m{1}, 'this');
                cc = amat.this.itsCorrcoef(1:2000,1:2000);
                [~,fp] = fileparts(m{1});
                imwrite(cc, fullfile(datasetFolder, [fp '.png']), 'BitDepth', 16)
            end
            popd(pwd0)
        end
		function test_all(this)
            %% See also:
            %  https://www.mathworks.com/matlabcentral/answers/492678-two-issues-about-matlab-s-official-example-of-gan
            
            this.testObj = this.testObj.trainAll();
            this.testObj.generateNewImages()
 		end
	end

 	methods (TestClassSetup)
		function setupCorrelationsGAN(this)
 			import mlepilepsy.*;
 			this.testObj_ = CorrelationsGAN;
 		end
	end

 	methods (TestMethodSetup)
		function setupCorrelationsGANTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

