function stack = AkyuzDenoise(stack, stack_exposure, crf, cluster_size)
%           IMPLEMENTATION OF THE "Noise reduction in high dynamic range
%           imaging" BY AKYUZ AND REINHARD.
%
%           INPUT -> stack = INPUT LDR SEQUENCE
%                 -> stack_exposure = INPUT LDR SEQUENCE EXPUSRE VALUES (IN LIST FORM)
%                 -> crf = CAMERA RESPONSE FUNCTION (DETERMINED USING DEBEVEC'S METHOD IN THIS CASE)
%                 -> cluster_size = CLUSTER SIZE FOR NOISE REDUCTION

[rows, columns, color_channels, no_of_images] = size(stack);

%PROCESS EVERY CLUSTER, DETERMINED BY USER
for i=1:cluster_size:no_of_images

    outputImg    = zeros(rows, columns, color_channels, 'single');
    
    totalClusterWeight = zeros(rows, columns, color_channels, 'single');
    
    %TRAVERSE IN CLUSTER
    for j=0:(cluster_size - 1)

        if((i + j) <= no_of_images) %LIMIT CLUSTER PROCESS IF EXCEEDS THE STACK BOUND
            
            tempImage = stack(:,:,:,i + j);

            %EXPOSURE TIME
            t = stack_exposure(i + j);
            
            %CLAMP FOR BETTER RESULT
            tempImage = ClampImg(tempImage, 0.0, 1.0);

            %IF INDEX IS NOT ITSELF, USE TAU (EQN 2)
            if(j == 0)
                %PREPARE FOR TAKING ONLY ITS EXP TIME
                weight = ones(rows, columns, color_channels, 'single');
            else
                weight = TauFunc(tempImage); %SEE TauFunc.m FOR DETAILS (EQN 5 & 6)
            end
            % LINEARIZE USING CAMERA RESPONSE FUNCTION
            %------------------------------------------------------------------
            
            total_valuesLocal = size(crf, 1);
            
            colLocal = size(tempImage, 3);

            deltaLocal = 1.0 / (total_valuesLocal - 1);
            
            x = 0 : deltaLocal : 1;
            localImage = zeros(size(tempImage));

            for qq=1:colLocal
                localImage(:,:,qq) = interp1(x, crf(:, qq), tempImage(:,:,qq), 'nearest', 'extrap'); %INTERPOLATE VALUES USING CRF
            end
            
            tempImage = localImage; %WRITE BACK THE LINEARIZED IMAGE
            %------------------------------------------------------------------
            
            %CALCULATION OF THE WEIGHT FUNCTION (EQN 2)
            weight = weight * t;

            if(t > 0.0)
                outputImg    = outputImg + (weight .* tempImage) / t;  % eqn 3
                totalClusterWeight = totalClusterWeight + weight;
            end
        end
    end

    if(totalClusterWeight <= 0.0) % IN CASE IT GOT OUT AS A NON POSITIVE VALUE
        totalClusterWeight = 1.0;
    end

    outputImg = outputImg ./ totalClusterWeight; %EQN 3
    stack(:,:,:,i) = ClampImg(outputImg * stack_exposure(i), 0.0, 1.0); %EQN 4

end

end
