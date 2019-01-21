clear all;

name_folder = 'inputFiles';
format = 'jpg';

disp('1) Read a stack of LDR images');
[stack, norm_value] = ReadLDRStack(name_folder, format, 1);
stack_exposure = ReadLDRStackInfo(name_folder, format);
%stack_exposure = [1/32,1/16,1/8,1/4,1/2,1,2];
[sortedStack, sortedStack_exposure] = SortStack(stack, stack_exposure, 'ascend');
[lin_fun, ~] = DebevecCRF(sortedStack, sortedStack_exposure);

resultingStack = AkyuzDenoise(sortedStack, sortedStack_exposure, lin_fun, 6);

h = figure(1);
imshow(resultingStack(:,:,:,1));
h = figure(2);
imshow(resultingStack(:,:,:,2));

disp('4) Build the radiance map using the stack and stack_exposure');
imgHDR = BuildHDR(resultingStack, sortedStack_exposure, 'LUT', lin_fun, 'Deb97', 'log');
hdrimwrite(imgHDR, 'clearHDRimage.jp2');

disp('6) Show the tone mapped version of the radiance map with gamma encoding');
h = figure(5);
set(h, 'Name', 'Tone mapped version of the built HDR image');
imgTMO = GammaTMO(ReinhardTMO(imgHDR, 0.18), 2.2, 0, 1);
