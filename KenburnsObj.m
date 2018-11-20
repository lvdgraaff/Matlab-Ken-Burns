% Written by Leon van der Graaff
% Copyright (c) 2018 by the author. Some rights reserved, see LICENCE.

classdef KenburnsObj < handle
    % KenburnsObj Create a Ken Burns movie creator object.
    %
    %   OBJ = KenburnsObj(videoWriter, Image) constructs a KenburnsObj object to
    %   create a video with a Ken Burns effect from an image
    
    properties
        videoWriter
        Image
        
        duration = 3
        frameSize = [240 320]; % [height width]
        
        % method should be either 'crop' or 'translate'
        method = 'translate'
        
        % startRect & endRect should have the format
        % [x, y, scale] where x, y are in Canvas space
        startRect
        endRect
        
        % translation should be a function handle mapping [0, 1] -> [0, 1]
        translation
        
        % some defaults
        translationSin = @(t) sin(pi/2*t)
        translationCos = @(t) .5-.5*cos(pi*t);
        translationLin = @(t) t;
        translationBackForth = @(t) 2*t.*(t<.5) + (2-2*t).*(t>=.5);
        
    end
    
    properties(Constant)
        plotNFrames = 7;
    end
    
    methods
        function this = KenburnsObj(videoWriter, Image)
            validateattributes(videoWriter, {'VideoWriter'}, {'scalar'});
            validateattributes(Image, {'numeric'}, {'2d'});
            
            this.videoWriter = videoWriter;
            this.Image = Image;
            
            this.startRect = [1 1 1];
            this.endRect = [.2*round(flip(size(Image))), .5];
            
            this.translation = this.translationSin;
        end
        
        function make(this)
            this.validate();
            
            open(this.videoWriter);
            
            [cropRect, baseScale] = createCrops(this);
                 
            fprintf('Making %s...\nTotal frames: %d\n', this.videoWriter.Filename, size(cropRect,1));
            fprintf('Creating frame ');
            
            for k = 1:size(cropRect,1)
            
                fprintf('%d ', k);
                
                switch(this.method)
                    case 'crop'
                        % image crop does not resample, which gives 'shaky' results
                        % only use for large images
                        xy = cropRect(k,[1 2]);
                        wh = flip(this.frameSize)/baseScale*cropRect(k,3);
                        C = imcrop(this.Image, [xy wh]);
                        Frame = imresize(C, this.frameSize);
                    case 'translate'
                        % use interpolated shift.
                        C = imtranslate(this.Image, -cropRect(k,[1,2])+[1 1]);
                        % interpolated resize
                        C = imresize(C, 1/cropRect(k,3) * baseScale);
                        % now we can do a 'hard' crop
                        Frame = C(1:this.frameSize(1),1:this.frameSize(2));
                end
                
                writeVideo(this.videoWriter,Frame);
            end
            
            close(this.videoWriter);
            fprintf('\ndone.\n');
        end
        
        function h = plot(this, hAxis)
            this.validate();
            
            [cropRect, baseScale] = createCrops(this);
            
            if nargin < 2 || isempty(hAxis)
                hAxis = gca;
            end
            
            axis(hAxis, 'image');
            hold(hAxis, 'on');
            hAxis.YDir = 'reverse';
            hAxis.XLim = [1 size(this.Image,1)];
            hAxis.YLim = [1 size(this.Image,2)];
            title(hAxis, this.videoWriter.Filename, 'Interpreter', 'none');
 
            frames = round(linspace(1, size(cropRect,1), this.plotNFrames));
            h = gobjects(size(frames));
            
            for i = 1:numel(frames)
                k = frames(i); 
                xy = cropRect(k,[1 2]);
                wh = flip(this.frameSize)/baseScale*cropRect(k,3);
                x = xy(1) + [0 0 1 1 0] * wh(1);
                y = xy(2) + [0 1 1 0 0] * wh(2);
                h(i) = plot(hAxis, x,y);
                h(i).DisplayName = sprintf('Frame %d', k);
            end
            
            legend -DynamicLegend Location NorthEastOutside
        end
    end
    
    methods(Access=private)
        
        function [cropRect, baseScale] = createCrops(this)
            nFrames = this.duration * this.videoWriter.FrameRate;
            t = this.translation(linspace(0,1,nFrames));
            cropRect = this.startRect(:)' + t(:) .* (this.endRect(:)' - this.startRect(:)');
            
            canvasSize = [size(this.Image,1) size(this.Image,2)];
            baseScale = max(this.frameSize(:)./canvasSize(:)); % define what scale==1 means
        end
        
        function validate(this)
            assert(strcmp(this.method, 'crop') || strcmp(this.method, 'translate'), ...
                'KenBurnsObj.method should either be ''crop'' or ''translate''');
            validateattributes(this.translation, {'function_handle'}, {}, 'KenBurnsObj', 'translation');
            validateattributes(this.duration, {'numeric'}, {'scalar'}, 'KenBurnsObj', 'duration');
            validateattributes(this.frameSize, {'numeric'}, {'integer', 'positive', 'numel', 2}, 'KenBurnsObj', 'frameSize');
            
            validateattributes(this.startRect, {'numeric'}, {'numel', 3}, 'KenBurnsObj', 'startRect');            
            validateattributes(this.startRect(1), {'numeric'}, {'scalar', '>=', 1, '<=', size(this.Image,2)}, 'KenBurnsObj', 'startRect(1)');
            validateattributes(this.startRect(2), {'numeric'}, {'scalar', '>=', 1, '<=', size(this.Image,1)}, 'KenBurnsObj', 'startRect(2)');
            validateattributes(this.startRect(3), {'numeric'}, {'scalar', '>', 0, '<=', 1}, 'KenBurnsObj', 'startRect(3)');
            
            validateattributes(this.endRect, {'numeric'}, {'numel', 3}, 'KenBurnsObj', 'endRect');            
            validateattributes(this.endRect(1), {'numeric'}, {'scalar', '>=', 1, '<=', size(this.Image,2)}, 'KenBurnsObj', 'endRect(1)');
            validateattributes(this.endRect(2), {'numeric'}, {'scalar', '>=', 1, '<=', size(this.Image,1)}, 'KenBurnsObj', 'endRect(2)');
            validateattributes(this.endRect(3), {'numeric'}, {'scalar', '>', 0, '<=', 1}, 'KenBurnsObj', 'endRect(3)');
        end
    end   
end