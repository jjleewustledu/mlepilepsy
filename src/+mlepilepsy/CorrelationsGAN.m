classdef CorrelationsGAN 
	%% CORRELATIONSGAN adapts the following for representations of RSN correlations:
    %  web(fullfile(docroot, 'deeplearning/ug/train-generative-adversarial-network.html'))

	%  $Revision$
 	%  was created 27-Oct-2020 15:34:46 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlepilepsy/src/+mlepilepsy.
 	%% It was developed on Matlab 9.9.0.1495850 (R2020b) Update 1 for MACI64.  Copyright 2020 John Joowon Lee.
 	
	properties
        augimds
        datasetFolder = '/home2/jjlee/Docker/Epilepsy/GSP_999/png'
 		dlnetDiscriminator
        dlnetGenerator            
        executionEnvironment = "auto"
        flipFactor = 0.3 % balance learning of discriminator and generator by adding noise; randomly flip real labels
        filterSize = 5
        gradientDecayFactor = 0.5
        inputSize = [128 128 1]
        learnRate = 0.0002
        lgraphGenerator
        lgraphDiscriminator
        miniBatchSize = 17
        numEpochs = 500
        numFilters = 64
        numLatentInputs = 100
        numValidationImages = 9
        projectionSize = [4 4 512]
        scale = 0.2 % for leaky ReLU layers
        squaredGradientDecayFactor = 0.999
        validationFrequency = 100 % display generated validation images every vF iterations
    end
    
    methods (Static)
        function this = trainAll()
            this = mlepilepsy.CorrelationsGAN();
            this = this.loadTrainingData();
            this = this.defineNetworks();
            this = this.trainModel();
            save(this);
        end
    end

	methods		  
 		function this = CorrelationsGAN(varargin)
            ip = inputParser;
            addParameter(ip, 'datasetFolder', this.datasetFolder, @isfolder)
            addParameter(ip, 'flipFactor', this.flipFactor, @isnumeric)
            addParameter(ip, 'filterSize', this.filterSize, @isnumeric)
            addParameter(ip, 'gradientDecayFactor', this.gradientDecayFactor, @isnumeric)
            addParameter(ip, 'inputSize', this.inputSize, @isnumeric)
            addParameter(ip, 'learnRate', this.learnRate, @isnumeric)
            addParameter(ip, 'miniBatchSize', this.miniBatchSize, @isnumeric)
            addParameter(ip, 'numEpochs', this.numEpochs, @isnumeric)
            addParameter(ip, 'numFilters', this.numFilters, @isnumeric)
            addParameter(ip, 'numLatentInputs', this.numLatentInputs, @isnumeric)
            addParameter(ip, 'numValidationImages', this.numValidationImages, @isnumeric)
            addParameter(ip, 'projectionSize', this.projectionSize, @isnumeric)
            addParameter(ip, 'scale', this.scale, @isnumeric)
            addParameter(ip, 'squaredGradientDecayFactor', this.squaredGradientDecayFactor, @isnumeric)
            addParameter(ip, 'validationFrequency', this.validationFrequency, @isnumeric)
            parse(ip, varargin{:})
            ipr = ip.Results;
            
            this.datasetFolder = ipr.datasetFolder;
            this.flipFactor = ipr.flipFactor;
            this.filterSize = ipr.filterSize;
            this.gradientDecayFactor = ipr.gradientDecayFactor;
            this.inputSize = ipr.inputSize;
            this.learnRate = ipr.learnRate;
            this.miniBatchSize = ipr.miniBatchSize;
            this.numEpochs = ipr.numEpochs;
            this.numFilters = ipr.numFilters;
            this.numLatentInputs = ipr.numLatentInputs;
            this.numValidationImages = ipr.numValidationImages;
            this.projectionSize = ipr.projectionSize;
            this.scale = ipr.scale;
            this.squaredGradientDecayFactor = ipr.squaredGradientDecayFactor;
            this.validationFrequency = ipr.validationFrequency;
        end        
        
        function this = loadTrainingData(this)
            imds = imageDatastore(this.datasetFolder,'IncludeSubfolders',true);
            this.augimds = augmentedImageDatastore(this.inputSize(1:2),imds);
        end
        function this = defineNetworks(this)
            layersGenerator = [
                imageInputLayer([1 1 this.numLatentInputs],'Normalization','none','Name','in')
                mlepilepsy.projectAndReshapeLayer(this.projectionSize,this.numLatentInputs,'proj');
                transposedConv2dLayer(this.filterSize,8*this.numFilters,'Name','tconv1')
                batchNormalizationLayer('Name','bnorm1')
                reluLayer('Name','relu1')
                transposedConv2dLayer(this.filterSize,4*this.numFilters,'Stride',2,'Cropping','same','Name','tconv2')
                batchNormalizationLayer('Name','bnorm2')
                reluLayer('Name','relu2')
                transposedConv2dLayer(this.filterSize,2*this.numFilters,'Stride',2,'Cropping','same','Name','tconv3')
                batchNormalizationLayer('Name','bnorm3')
                reluLayer('Name','relu3')
                transposedConv2dLayer(this.filterSize,this.numFilters,'Stride',2,'Cropping','same','Name','tconv4')
                batchNormalizationLayer('Name','bnorm4')
                reluLayer('Name','relu4')
                transposedConv2dLayer(this.filterSize,1,'Stride',2,'Cropping','same','Name','tconv5')
                tanhLayer('Name','tanh')];
            this.lgraphGenerator = layerGraph(layersGenerator);
            this.dlnetGenerator = dlnetwork(this.lgraphGenerator);
            
            layersDiscriminator = [
                imageInputLayer(this.inputSize,'Normalization','none','Name','in')
                dropoutLayer(0.5,'Name','dropout')
                convolution2dLayer(this.filterSize,this.numFilters,'Stride',2,'Padding','same','Name','conv1')
                leakyReluLayer(this.scale,'Name','lrelu1')
                convolution2dLayer(this.filterSize,2*this.numFilters,'Stride',2,'Padding','same','Name','conv2')
                batchNormalizationLayer('Name','bn2')
                leakyReluLayer(this.scale,'Name','lrelu2')
                convolution2dLayer(this.filterSize,4*this.numFilters,'Stride',2,'Padding','same','Name','conv3')
                batchNormalizationLayer('Name','bn3')
                leakyReluLayer(this.scale,'Name','lrelu3')
                convolution2dLayer(this.filterSize,8*this.numFilters,'Stride',2,'Padding','same','Name','conv4')
                batchNormalizationLayer('Name','bn4')
                leakyReluLayer(this.scale,'Name','lrelu4')
                convolution2dLayer(this.filterSize,16*this.numFilters,'Stride',2,'Padding','same','Name','conv5')
                batchNormalizationLayer('Name','bn5')
                leakyReluLayer(this.scale,'Name','lrelu5')
                convolution2dLayer(4,1,'Name','conv6')];
            this.lgraphDiscriminator = layerGraph(layersDiscriminator);            
            this.dlnetDiscriminator = dlnetwork(this.lgraphDiscriminator);
        end        
        function this = trainModel(this)
            %% For each mini-batch:
            %  - Use the custom mini-batch preprocessing function preprocessMiniBatch (defined at the end of this example) 
            %    to rescale the images in the range [-1,1].
            %  - Discard any partial mini-batches with less than 128 observations.
            %  - Format the image data with the dimension labels 'SSCB' (spatial, spatial, channel, batch). 
            %    By default, the minibatchqueue object converts the data to dlarray objects with underlying type single.
            %  - Train on a GPU if one is available. When the 'OutputEnvironment' option of minibatchqueue is "auto", 
            %    minibatchqueue converts each output to a gpuArray if a GPU is available. 
            %    Using a GPU requires Parallel Computing Toolbox™ and a CUDA® enabled NVIDIA® GPU with compute capability 3.0 or higher.
            
            this.augimds.MiniBatchSize = this.miniBatchSize;
            
            mbq = minibatchqueue(this.augimds,...
                'MiniBatchSize',this.miniBatchSize,...
                'PartialMiniBatch','discard',...
                'MiniBatchFcn', @this.preprocessMiniBatch,...
                'MiniBatchFormat','SSCB',...
                'OutputEnvironment',this.executionEnvironment);

            % Train the model using a custom training loop. Loop over the training data and update the network
            % parameters at each iteration. To monitor the training progress, display a batch of generated images using
            % a held-out array of random values to input into the generator as well as a plot of the scores.
            
            % Initialize the parameters for Adam.

            trailingAvgGenerator = [];
            trailingAvgSqGenerator = [];
            trailingAvgDiscriminator = [];
            trailingAvgSqDiscriminator = [];
            
            % To monitor training progress, display a batch of generated images using a held-out batch of fixed arrays 
            % of random values fed into the generator and plot the network scores.

            % Create an array of held-out random values.
            
            ZValidation = randn(1,1,this.numLatentInputs,this.numValidationImages,'single');
            
            % Convert the data to dlarray objects and specify the dimension labels 'SSCB' (spatial, spatial, channel, batch).
            
            dlZValidation = dlarray(ZValidation,'SSCB');
            
            % For GPU training, convert the data to gpuArray objects.
                        
            if (this.executionEnvironment == "auto" && canUseGPU) || this.executionEnvironment == "gpu"
                dlZValidation = gpuArray(dlZValidation);
            end
            
            % Initialize the training progress plots. Create a figure and resize it to have twice the width.
            
            f = figure;
            f.Position(3) = 2*f.Position(3);
            imageAxes = subplot(1,2,1);
            scoreAxes = subplot(1,2,2);
            lineScoreGenerator = animatedline(scoreAxes,'Color',[0 0.447 0.741]);
            lineScoreDiscriminator = animatedline(scoreAxes, 'Color', [0.85 0.325 0.098]);
            legend('Generator','Discriminator');
            ylim([0 1])
            xlabel("Iteration")
            ylabel("Score")
            grid on            
            
            % Train the GAN. For each epoch, shuffle the datastore and loop over mini-batches of data.
            % For each mini-batch:
            % - Evaluate the model gradients using dlfeval and the modelGradients function.
            % - Update the network parameters using the adamupdate function.
            % - Plot the scores of the two networks.
            % - After every validationFrequency iterations, display a batch of generated images for a fixed held-out generator input.

            iteration = 0;
            start = tic;
            
            % Loop over epochs.
            for epoch = 1:this.numEpochs

                % Reset and shuffle datastore.
                shuffle(mbq);

                % Loop over mini-batches.
                while hasdata(mbq)
                    iteration = iteration + 1;

                    % Read mini-batch of data.
                    dlX = next(mbq);
                    
                    % Generate latent inputs for the generator network. Convert to
                    % dlarray and specify the dimension labels 'SSCB' (spatial,
                    % spatial, channel, batch). If training on a GPU, then convert
                    % latent inputs to gpuArray.
                    Z = randn(1,1,this.numLatentInputs,size(dlX,4),'single');
                    dlZ = dlarray(Z,'SSCB');
                    
                    if (this.executionEnvironment == "auto" && canUseGPU) || this.executionEnvironment == "gpu"
                        dlZ = gpuArray(dlZ);
                    end
                    
                    % Evaluate the model gradients and the generator state using
                    % dlfeval and the modelGradients function listed at the end of the
                    % example.
                    [gradientsGenerator, gradientsDiscriminator, stateGenerator, scoreGenerator, scoreDiscriminator] = ...
                        dlfeval(@this.modelGradients, this.dlnetGenerator, this.dlnetDiscriminator, dlX, dlZ, this.flipFactor);
                    this.dlnetGenerator.State = stateGenerator;
                    
                    % Update the discriminator network parameters.
                    [this.dlnetDiscriminator,trailingAvgDiscriminator,trailingAvgSqDiscriminator] = ...
                        adamupdate(this.dlnetDiscriminator, gradientsDiscriminator, ...
                        trailingAvgDiscriminator, trailingAvgSqDiscriminator, iteration, ...
                        this.learnRate, this.gradientDecayFactor, this.squaredGradientDecayFactor);
                    
                    % Update the generator network parameters.
                    [this.dlnetGenerator,trailingAvgGenerator,trailingAvgSqGenerator] = ...
                        adamupdate(this.dlnetGenerator, gradientsGenerator, ...
                        trailingAvgGenerator, trailingAvgSqGenerator, iteration, ...
                        this.learnRate, this.gradientDecayFactor, this.squaredGradientDecayFactor);
                    
                    % Every validationFrequency iterations, display batch of generated images using the
                    % held-out generator input
                    if mod(iteration,this.validationFrequency) == 0 || iteration == 1
                        % Generate images using the held-out generator input.
                        dlXGeneratedValidation = predict(this.dlnetGenerator,dlZValidation);
                        
                        % Tile and rescale the images in the range [0 1].
                        I = imtile(extractdata(dlXGeneratedValidation));
                        I = rescale(I);
                        
                        % Display the images.
                        subplot(1,2,1);
                        imagesc(imageAxes,I)
                        xticklabels([]);
                        yticklabels([]);
                        title("Generated Images");
                    end
                    
                    % Update the scores plot
                    subplot(1,2,2)
                    addpoints(lineScoreGenerator,iteration,...
                        double(gather(extractdata(scoreGenerator))));
                    
                    addpoints(lineScoreDiscriminator,iteration,...
                        double(gather(extractdata(scoreDiscriminator))));
                    
                    % Update the title with training progress information.
                    D = duration(0,0,toc(start),'Format','hh:mm:ss');
                    title(...
                        "Epoch: " + epoch + ", " + ...
                        "Iteration: " + iteration + ", " + ...
                        "Elapsed: " + string(D))
                    
                    drawnow
                    
                end
            end
        end
        function this = generateNewImages(this)
            
            % To generate new images, use the predict function on the generator with a dlarray object containing a batch
            % of 1-by-1-by-100 arrays of random values. To display the images together, use the imtile function and
            % rescale the images using the rescale function.
            
            ZNew = randn(1,1,this.numLatentInputs,25,'single');
            dlZNew = dlarray(ZNew,'SSCB');
            
            if (this.executionEnvironment == "auto" && canUseGPU) || this.executionEnvironment == "gpu"
                dlZNew = gpuArray(dlZNew);
            end
            
            dlXGeneratedNew = predict(this.dlnetGenerator,dlZNew);
            
            I = imtile(extractdata(dlXGeneratedNew));
            I = rescale(I);
            figure
            image(I)
            axis off
            title("Generated Images")
        end
        function        save(this)
            save(['mlepilepsy_CorrelationsGAN_' datestr(now, 'yyyymmddHHMMSS') '.mat'], 'this')
        end
    end 
    
    %% PROTECTED
    
    methods (Static, Access = protected)
        function [lossGenerator, lossDiscriminator] = ganLoss(probReal,probGenerated) 
            
            % Calculate the loss for the discriminator network.
            lossDiscriminator = -mean(log(probReal)) -mean(log(1-probGenerated));
            
            % Calculate the loss for the generator network.
            lossGenerator = -mean(log(probGenerated));            
        end
        function [gradientsGenerator, gradientsDiscriminator, stateGenerator, scoreGenerator, scoreDiscriminator] = ...
                modelGradients(dlnetGenerator, dlnetDiscriminator, dlX, dlZ, flipFactor)
            %% takes as input the generator and discriminator dlnetwork objects dlnetGenerator and dlnetDiscriminator, 
            %  a mini-batch of input data dlX, an array of random values dlZ and the percentage of real labels to 
            %  flip flipFactor, and returns the gradients of the loss with respect to the learnable parameters in 
            %  the networks, the generator state, and the scores of the two networks. Because the discriminator output 
            %  is not in the range [0,1], modelGradients applies the sigmoid function to convert it into probabilities.
            
            % Calculate the predictions for real data with the discriminator network.
            dlYPred = forward(dlnetDiscriminator, dlX);
            
            % Calculate the predictions for generated data with the discriminator network.
            [dlXGenerated,stateGenerator] = forward(dlnetGenerator,dlZ);
            dlYPredGenerated = forward(dlnetDiscriminator, dlXGenerated);
            
            % Convert the discriminator outputs to probabilities.
            probGenerated = sigmoid(dlYPredGenerated);
            probReal = sigmoid(dlYPred);
            
            % Calculate the score of the discriminator.
            scoreDiscriminator = ((mean(probReal)+mean(1-probGenerated))/2);
            
            % Calculate the score of the generator.
            scoreGenerator = mean(probGenerated);
            
            % Randomly flip a fraction of the labels of the real images.
            numObservations = size(probReal,4);
            idx = randperm(numObservations,floor(flipFactor * numObservations));
            
            % Flip the labels
            probReal(:,:,:,idx) = 1-probReal(:,:,:,idx);
            
            % Calculate the GAN loss.
            [lossGenerator, lossDiscriminator] = mlepilepsy.CorrelationsGAN.ganLoss(probReal,probGenerated);
            
            % For each network, calculate the gradients with respect to the loss.
            gradientsGenerator = dlgradient(lossGenerator, dlnetGenerator.Learnables,'RetainData',true);
            gradientsDiscriminator = dlgradient(lossDiscriminator, dlnetDiscriminator.Learnables);
            
        end
        function X = preprocessMiniBatch(data)
            
            % Concatenate mini-batch
            X = cat(4,data{:});

            % Rescale the images in the range [-1 1].
            X = rescale(X,-1,1,'InputMin',0,'InputMax',65535);
        end        
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

