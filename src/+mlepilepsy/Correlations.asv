classdef Correlations 
	%% CORRELATIONS provisions temporal correlations of BOLD suitable for deep learning epilepsy representations.
    %  Truncates early time-frames of each BOLD series to remove aural disturbances.  
    %  See also mlepilepsy.BOLD.

	%  $Revision$
 	%  was created 25-Oct-2020 13:44:14 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlepilepsy/src/+mlepilepsy.
 	%% It was developed on Matlab 9.9.0.1495850 (R2020b) Update 1 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        itsCorrcoef % matrix
        net17 % ImagingContext2
        net17Partitions % vec ~ [2009 1]
        net17Positions  % vec ~ [2009 1]
        Ntruncate = 5
    end
    
    properties (Dependent)
        net17Selections % containers.Map:  RSN -> vec of positions withint RSN
    end
    
    methods (Static)
        function this = createFromMat(fn)
            assert(isfile(fn))
            amat = load(fn, 'dat');
            this = mlepilepsy.Correlations(amat.dat);
        end
    end
    
    methods 
        
        %% GET
        
        function g = get.net17Selections(this)            
            cs_parts = cumsum(this.net17Partitions);
            g = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            g(1) = 1:cs_parts(1);
            for inet = 2:17
                g(inet) = (cs_parts(inet-1)+1):cs_parts(inet);
            end
        end
        
        %%
        
        function cc = corrcoef(this, dat)
            %% @param dat is [Nxyz Nt].
            %  @return cc is symmetric [Nxyz Nxyz].
            
            assert(ismatrix(dat))
            dur = size(dat,2);
            if dur > this.Ntruncate
                dat = dat(:,this.Ntruncate+1:end);
            end
            cc = corrcoef(dat'); % cols are variables; rows are observations
        end
        function h = imagesc(this, varargin)
            h = figure;
            imagesc(this.itsCorrcoef, varargin{:})
            colorbar
        end
        function dat = nonzero(~, dat0)
            %% excludes positions with all zeros.
            
            assert(ismatrix(dat0))
            msk0 = dat0 ~= 0;
            msk0 = sum(msk0, 2) ~= 0;
            dat = zeros(numel(msk0), size(dat0,2), 'single');
            for t = 1:size(dat,2)
                dat(:,t) = dat0(msk0,t);
            end
        end
        function dat = reshape(~, dat0)
            %% to [Nxyz Nt] or [numel() 1].
            
            assert(isnumeric(dat0))
            sz_dat = size(dat0);
            if length(sz_dat) < 4
                dat = reshape(dat0, [numel(dat0) 1]);
                return
            end
            Nxyz = prod(sz_dat(1:3));
            Nt = sz_dat(4);
            dat = reshape(dat0, [Nxyz, Nt]);
        end      
        function save(this, fn)
            save(fn, 'this')
        end
        function [dat,pos,parts] = sortByNet17(this, dat0)
            %% @param required dat0 is [Nx Ny Nz Nt].
            %  @return dat is [Nxyz Nt].
            %  @return pos is [Nxyz 1].
            
            assert(length(size(dat0)) >= 3)
            img = flip(this.net17.fourdfp.img, 2);
            img = this.reshape(img);
            if isempty(this.net17Positions)
                pos = [];
                parts = [];
                for inet = 1:17
                    pos1 = find(img == inet);
                    pos  = [pos; pos1]; %#ok<AGROW>
                    parts = [parts; numel(pos1)]; %#ok<AGROW>
                end 
            else
                pos = this.net17Positions;
                parts = this.net17Partitions;
            end
            dat0 = this.reshape(dat0);
            dat = dat0(pos, :);            
        end
        function net17ts = buildNet17Timeseries(this, dat)
            %% averages timeseries for each of net17.
            %  @param required dat is output from sortByNet17 ~ [Nxyz Nt].
            %  @param net17ts is containers.Map:  RSN -> timeseries.
            
            select = this.net17Selections;
            net17ts = containers.Map('KeyType', 'uint32', 'ValueType', 'any');            
            for inet = 1:17
                net17ts(inet) = mean(dat(select(inet),:), 1);
            end
        end
    end

    %% PRIVATE
    
	methods (Access = private)		  
 		function this = Correlations(dat)
            % @param required dat is in R^{3 + 1}
            % @return itsCorrcoef contains corrcoef of all combinations of time-series.

            this.net17 = mlfourd.ImagingContext2( ...
                fullfile(getenv('HOME'), 'MATLAB-Drive', 'mldl', 'data', 'argmax_MeanImageForJohn_999.4dfp.hdr'));
            
            [dat,this.net17Positions,this.net17Partitions] = this.sortByNet17(dat);            
 			this.itsCorrcoef = this.corrcoef(dat);
            net17ts = this.buildNet17Timeseries(dat);
            this = this.replaceDiagonals(dat, net17ts);
        end
        
        function this = loadNet17Sorting(this)
            %% read empirically sorted values for this.{net17Positions,net17Partitions}.
            
            theMat = load(fullfile(getenv('HOME'), 'MATLAB-Drive', 'mldl', 'data', 'net17Sorting.mat'), 'net17Sorting');
            this.net17Partitions = zeros(17,1);
            pos = [];
            for inet = 1:17
                this.net17Partitions(inet) = numel(theMat.net17Sorting(inet)); % containers.Map
                pos = [pos; theMat.net17Sorting(inet)]; %#ok<AGROW>
            end
            this.net17Positions = pos;
        end
        function this = replaceDiagonals(this, dat, net17ts)
            %% replaces diagonals of itsCorrcoef with intra-RSN correlations.
            %  @param required dat is output from sortByNet17 ~ [Nxyz Nt].
            %  @param required net17ts is containers.Map:  RSN -> timeseries.            
            
            select = this.net17Selections;
            for inet = 1:17
                for iselect = select(inet)
                    cc = corrcoef(dat(iselect,:), net17ts(inet));
                    this.itsCorrcoef(iselect,iselect) = cc(1,2); % offdiagonal 
                end
            end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

