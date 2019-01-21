classdef AkyuzNoise_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        OpenMenu             matlab.ui.container.Menu
        InputImagesMenu      matlab.ui.container.Menu
        SaveMenu             matlab.ui.container.Menu
        ClearedLDRFilesMenu  matlab.ui.container.Menu
        HDRandTMImageofClearedStackMenu  matlab.ui.container.Menu
        ToneMappedImageofRegularStackMenu  matlab.ui.container.Menu
        CRFCurveMenu         matlab.ui.container.Menu
        UIAxes               matlab.ui.control.UIAxes
        SelectInputFormatDropDownLabel  matlab.ui.control.Label
        SelectInputFormatDropDown       matlab.ui.control.DropDown
        UIAxes2                         matlab.ui.control.UIAxes
        UIAxes3                         matlab.ui.control.UIAxes
        ApplicationoftheAkyuzandReinhardsNoiseReductionMethodLabel  matlab.ui.control.Label
        CreateHDRfromDeNoisedButton     matlab.ui.control.Button
        CreateHDRfromNonModifiedButton  matlab.ui.control.Button
        ReduceNoiseButton               matlab.ui.control.Button
        EnterClusterSizeEditFieldLabel  matlab.ui.control.Label
        EnterClusterSizeEditField       matlab.ui.control.NumericEditField
    end

    
    properties (Access = public)
        size % holds the size of the input files
        files % holds the ldr input files
        file_format % holds the extension of the input files
        sortedStack
        sortedStack_exposure
        clusterSizeInfo
        crfCurve
        resultingStack
        
        regularHDR
        regularTM
        
        clearHDR
        clearTM
    end
    
    methods (Access = private)
        
        function results = loadInputImages(app)
            
        end
    end
    

    methods (Access = private)

        % Menu selected function: InputImagesMenu
        function InputImagesMenuSelected(app, event)
            
            folderName = uigetdir('Select Input Files Folder');
            
            h = waitbar(0, 'Loading Input Images');
            
            [stack, norm_value] = ReadLDRStack(folderName, app.file_format, 1);
            stack_exposure = ReadLDRStackInfo(folderName, app.file_format);
            waitbar(0.25);
            [app.sortedStack, app.sortedStack_exposure] = SortStack(stack, stack_exposure, 'ascend');
            
            [r, c, col, n] = size(app.sortedStack);
            waitbar(0.5);
            out = imtile(app.sortedStack,'BorderSize', 7, 'BackgroundColor', 'w', 'GridSize', [n 1]);
            waitbar(0.75);
            imshow(out,'Parent',app.UIAxes);
            close(h);
            %figure;
            %imshow(out);
            
            %loadInputImages(app);
            %[stack, norm_value] = ReadLDRStack(name_folder, format, 1);
            %out = imtile(app., map, 'Frames', 1:8, 'GridSize', [2 4]);
            
        end
        
        function SelectInputFormatDropDownValueChanged(app, event)
            app.file_format = app.SelectInputFormatDropDown.Value;
            
        end
        
        % Button pushed function: ReduceNoiseButton
        function ReduceNoiseButtonPushed(app, event)
            disp('I am here');
            wB = waitbar(0, 'Applying Akyuz Noise Reduction');
            %FIND CRF
            [app.crfCurve, ~] = DebevecCRF(app.sortedStack, app.sortedStack_exposure);
            waitbar(0.5);
            %APPLY AKYUZ DENOISE
            app.resultingStack = AkyuzDenoise(app.sortedStack, app.sortedStack_exposure, app.crfCurve, app.clusterSizeInfo);
            waitbar(0.6);
            
            [r, c, col, n] = size(app.resultingStack);
            
            out2 = imtile(app.resultingStack,'BorderSize', 7, 'BackgroundColor', 'w', 'GridSize', [n 1]);
            waitbar(0.8);
            imshow(out2,'Parent',app.UIAxes2);
            
          
            plot(app.UIAxes3, app.crfCurve(:,1), '-r');
            hold(app.UIAxes3);
            plot(app.UIAxes3, app.crfCurve(:,2), '--g');
            %hold(app.UIAxes3);
            plot(app.UIAxes3, app.crfCurve(:,3), ':b');
            
            close(wB);
        end
        
        function EnterClusterSizeEditFieldValueChanged(app, event)
            app.clusterSizeInfo = app.EnterClusterSizeEditField.Value;
        end
        
        % Button pushed function: CreateHDRfromDeNoisedButton
        function CreateHDRfromDeNoisedButtonPushed(app, event)
            wB1 = waitbar(0, 'Creating HDR image');
            disp('*) Build the radiance map using the noise reduced inputs via Debevec');
            imgHDR = BuildHDR(app.resultingStack, app.sortedStack_exposure, 'LUT', app.crfCurve, 'Deb97', 'log');
            waitbar(0.33);
            disp('*) Show the tone mapped version of the radiance map with gamma encoding');
            h = figure(1);
            set(h, 'Name', 'Tone mapped version of the built HDR image (Noise Reduced)');
            waitbar(0.66);
            imgTMO = GammaTMO(ReinhardTMO(imgHDR, 0.18), 2.2, 0, 1);
            waitbar(0.9);
            
            app.clearHDR = imgHDR;
            app.clearTM = imgTMO;
            
            close(wB1);
        end
        
        % Button pushed function: CreateHDRfromNonModifiedButton
        function CreateHDRfromNonModifiedButtonPushed(app, event)
            wB2 = waitbar(0, 'Creating HDR image');
            disp('*) Build the radiance map using the regular inputs via Debevec');
            imgHDR1 = BuildHDR(app.sortedStack, app.sortedStack_exposure, 'LUT', app.crfCurve, 'Deb97', 'log');
            waitbar(0.33);
            disp('*) Show the tone mapped version of the radiance map with gamma encoding');
            h = figure(1);
            set(h, 'Name', 'Tone mapped version of the built HDR image (Regular)');
            waitbar(0.66);
            imgTMO1 = GammaTMO(ReinhardTMO(imgHDR1, 0.18), 2.2, 0, 1);
            waitbar(0.9);
            
            app.regularHDR = imgHDR1;
            app.regularTM = imgTMO1;
            
            close(wB2);
        end
        
        % Menu selected function: ClearedLDRFilesMenu
        function ClearedLDRFilesMenuSelected(app, event)
            [r, c, col, n] = size(app.resultingStack);
            for i = 1:(n)
                
                name = strcat('clearStack', string(i), '.png');
                imwrite(app.resultingStack(:,:,:,i), name);
            end
        end
        
        % Menu selected function: HDRandTMImageofClearedStackMenu
        function HDRandTMImageofClearedStackMenuSelected(app, event)
            imwrite(app.clearTM, 'clearTMimage.png');
        end
        
        % Menu selected function: ToneMappedImageofRegularStackMenu
        function ToneMappedImageofRegularStackMenuSelected(app, event)
            imwrite(app.regularTM, 'regularTMimage.png');
        end
        
        % Menu selected function: CRFCurveMenu
        function CRFCurveMenuSelected(app, event)
            csvwrite('crfCurve.txt',app.crfCurve);
        end
    end

    % App initialization and construction
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure
            app.UIFigure = uifigure;
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'Main Window';

            % Create OpenMenu
            app.OpenMenu = uimenu(app.UIFigure);
            app.OpenMenu.Text = 'Open...';

            % Create InputImagesMenu
            app.InputImagesMenu = uimenu(app.OpenMenu);
            app.InputImagesMenu.MenuSelectedFcn = createCallbackFcn(app, @InputImagesMenuSelected, true);
            app.InputImagesMenu.Text = 'Input Images...';

            % Create SaveMenu
            app.SaveMenu = uimenu(app.UIFigure);
            app.SaveMenu.Text = 'Save...';

            % Create ClearedLDRFilesMenu
            app.ClearedLDRFilesMenu = uimenu(app.SaveMenu);
            app.ClearedLDRFilesMenu.MenuSelectedFcn = createCallbackFcn(app, @ClearedLDRFilesMenuSelected, true);
            app.ClearedLDRFilesMenu.Text = 'Cleared LDR Files';

            % Create HDRandTMImageofClearedStackMenu
            app.HDRandTMImageofClearedStackMenu = uimenu(app.SaveMenu);
            app.HDRandTMImageofClearedStackMenu.MenuSelectedFcn = createCallbackFcn(app, @HDRandTMImageofClearedStackMenuSelected, true);
            app.HDRandTMImageofClearedStackMenu.Text = 'Tone Mapped Image of Cleared Stack';

            % Create ToneMappedImageofRegularStackMenu
            app.ToneMappedImageofRegularStackMenu = uimenu(app.SaveMenu);
            app.ToneMappedImageofRegularStackMenu.MenuSelectedFcn = createCallbackFcn(app, @ToneMappedImageofRegularStackMenuSelected, true);
            app.ToneMappedImageofRegularStackMenu.Text = 'Tone Mapped Image of Regular Stack';

            % Create CRFCurveMenu
            app.CRFCurveMenu = uimenu(app.SaveMenu);
            app.CRFCurveMenu.MenuSelectedFcn = createCallbackFcn(app, @CRFCurveMenuSelected, true);
            app.CRFCurveMenu.Text = 'CRF Curve';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Input Stack')
            app.UIAxes.Visible = 'off';
            app.UIAxes.Position = [1 1 226 428];

            % Create SelectInputFormatDropDownLabel
            app.SelectInputFormatDropDownLabel = uilabel(app.UIFigure);
            app.SelectInputFormatDropDownLabel.HorizontalAlignment = 'right';
            app.SelectInputFormatDropDownLabel.Position = [1 459 111 22];
            app.SelectInputFormatDropDownLabel.Text = 'Select Input Format';

            % Create SelectInputFormatDropDown
            app.SelectInputFormatDropDown = uidropdown(app.UIFigure);
            app.SelectInputFormatDropDown.Items = {'jpg', 'png', 'tiff', 'jpeg'};
            app.SelectInputFormatDropDown.Position = [127 459 100 22];
            app.SelectInputFormatDropDown.Value = 'jpg';
            app.file_format = app.SelectInputFormatDropDown.Value;

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Noise-Reduced Stack')
            app.UIAxes2.Visible = 'off';
            app.UIAxes2.Position = [226 1 226 428];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            title(app.UIAxes3, 'CRF of the Input')
            xlabel(app.UIAxes3, 'Pixel Value')
            ylabel(app.UIAxes3, 'Normalized Irradiance')
            app.UIAxes3.Position = [453 263 185 185];

            % Create ApplicationoftheAkyuzandReinhardsNoiseReductionMethodLabel
            app.ApplicationoftheAkyuzandReinhardsNoiseReductionMethodLabel = uilabel(app.UIFigure);
            app.ApplicationoftheAkyuzandReinhardsNoiseReductionMethodLabel.HorizontalAlignment = 'center';
            app.ApplicationoftheAkyuzandReinhardsNoiseReductionMethodLabel.FontWeight = 'bold';
            app.ApplicationoftheAkyuzandReinhardsNoiseReductionMethodLabel.Position = [226 459 415 22];
            app.ApplicationoftheAkyuzandReinhardsNoiseReductionMethodLabel.Text = 'Application of the Akyuz and Reinhard''s Noise Reduction Method';

            % Create CreateHDRfromDeNoisedButton
            app.CreateHDRfromDeNoisedButton = uibutton(app.UIFigure, 'push');
            app.CreateHDRfromDeNoisedButton.ButtonPushedFcn = createCallbackFcn(app, @CreateHDRfromDeNoisedButtonPushed, true);
            app.CreateHDRfromDeNoisedButton.Position = [464 179 164 22];
            app.CreateHDRfromDeNoisedButton.Text = 'Create HDR from DeNoised';

            % Create CreateHDRfromNonModifiedButton
            app.CreateHDRfromNonModifiedButton = uibutton(app.UIFigure, 'push');
            app.CreateHDRfromNonModifiedButton.ButtonPushedFcn = createCallbackFcn(app, @CreateHDRfromNonModifiedButtonPushed, true);
            app.CreateHDRfromNonModifiedButton.Position = [453 115 185 22];
            app.CreateHDRfromNonModifiedButton.Text = 'Create HDR from Non-Modified';
            
            % Create ReduceNoiseButton
            app.ReduceNoiseButton = uibutton(app.UIFigure, 'push');
            app.ReduceNoiseButton.ButtonPushedFcn = createCallbackFcn(app, @ReduceNoiseButtonPushed, true);
            app.ReduceNoiseButton.Position = [64 428 100 22];
            app.ReduceNoiseButton.Text = 'Reduce Noise';
            
            % Create EnterClusterSizeEditFieldLabel
            app.EnterClusterSizeEditFieldLabel = uilabel(app.UIFigure);
            app.EnterClusterSizeEditFieldLabel.HorizontalAlignment = 'right';
            app.EnterClusterSizeEditFieldLabel.Position = [226 428 101 22];
            app.EnterClusterSizeEditFieldLabel.Text = 'Enter Cluster Size';

            % Create EnterClusterSizeEditField
            app.EnterClusterSizeEditField = uieditfield(app.UIFigure, 'numeric');
            app.EnterClusterSizeEditField.ValueChangedFcn = createCallbackFcn(app, @EnterClusterSizeEditFieldValueChanged, true);
            app.EnterClusterSizeEditField.Position = [342 428 25 22];
            app.clusterSizeInfo = 2;
        end
    end

    methods (Access = public)

        % Construct app
        function app = AkyuzNoise_GUI

            % Create and configure components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end