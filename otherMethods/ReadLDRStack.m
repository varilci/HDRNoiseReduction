function [stack, norm_value] = ReadLDRStack(dir_name, format, bNormalization, bToSingle)

if(~exist('bNormalization', 'var'))
    bNormalization = 0;
end

if(~exist('bToSingle', 'var'))
    bToSingle = 1;
end

if(bNormalization)
    bToSingle = 1;
end

norm_value = 1.0;

list = dir([dir_name, '/*.', format]);
n = length(list);

if(n > 0)
    img_info = [];
    name = [dir_name, '/', list(1).name];
    
    try
        if(exist('imfinfo') == 2)
            img_info = imfinfo(name);
        end
    catch err
        disp(err);
        
        try 
            if(exist('exifread') == 2)
                img_info = exifread(name);
                
                if(isfield(img_info, 'SamplesPerPixel'))                    
                    if(img_info.SamplesPerPixel == 3)
                        img_info.ColorType = 'truecolor';                      
                    end
                    
                    if(img_info.SamplesPerPixel == 1)
                        img_info.ColorType = 'grayscale';                      
                    end
                else
                    img_info.ColorType = 'truecolor';
                end
                
                if(isfield(img_info, 'BitsPerSample'))
                    img_info.BitDepth = round(mean(img_info.BitsPerSample));
                else
                    img_info.BitDepth = 8;
                end
                
                if(isfield(img_info, 'ImageWidth'))
                    img_info.Width = img_info.ImageWidth;
                end
                
                if(isfield(img_info, 'ImageLength'))
                    img_info.Height = img_info.ImageLength;
                end                
                
                if(isfield(img_info, 'PixelXDimension'))
                    img_info.Width = PixelXDimension;
                end
                
                if(isfield(img_info, 'PixelYDimension'))
                    img_info.Height = PixelYDimension;
                end
            end
        catch
            disp(err);
        end
    end
    
    colorChannels = 0;
    
    norm_value = 255.0;
    
    if(~isempty(img_info))
        if(isfield(img_info, 'NumberOfSamples'))
            colorChannels = img_info.NumberOfSamples;
        else
            switch img_info.ColorType
                case 'grayscale'
                    colorChannels = 1;

                    switch img_info.BitDepth
                        case 8
                            norm_value = 255.0;
                        case 16
                            norm_value = 65535.0;
                    end

                case 'truecolor'
                    colorChannels = 3;

                    switch img_info.BitDepth
                        case 24
                            norm_value = 255.0;
                        case 48
                            norm_value = 65535.0;
                    end
            end
        end  

        if(img_info.Height == 0 || img_info.Width == 0)
            tmp = imread(name);
            [img_info.Height, img_info.Width, n] = size(tmp);
            clear('tmp');
        end
        
        stack = zeros(img_info.Height, img_info.Width, colorChannels, n, 'single');

        for i=1:n
            disp(list(i).name);
            %read an image, and convert it into floating-point
            img_tmp = imread([dir_name, '/', list(i).name]);  

            %store in the stack
            if(bToSingle)
                stack(:,:,:,i) = single(img_tmp);   
            else
                stack(:,:,:,i) = img_tmp;   
            end
        end

        if(bNormalization)
            stack = stack / norm_value;
        end
    else
        warning('The stack is empty!');
        stack = [];        
    end
else
    warning('The stack is empty!');
    stack = [];
end

end