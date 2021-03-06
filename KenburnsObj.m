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
        
        % method should be 'griddedInterpolant'
        % depreciated: methods: 'crop' or 'translate'
        method = 'griddedInterpolant'
        
        antialias = false % this method is experimental and sould be off by default
        filterKernelSize = 0.5 % scalar setting 1: hardly any aliasing, 0.5: some aliasing but crisp contast. >>1: blurry images
        
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
        plotNFrames = 25;
    end
    
    methods
        function this = KenburnsObj(videoWriter, Image)
            validateattributes(videoWriter, {'VideoWriter'}, {'scalar'});
            validateattributes(Image, {'numeric'}, {});
            assert(size(Image,3)==1 || size(Image,3)==3, 'size(Image,3) must either be 1 or 3');
            
            this.videoWriter = videoWriter;
            this.Image = Image;
            
            this.startRect = [1 1 1];
            this.endRect = [.2*round(flip([size(Image,1) size(Image,2)])), .5];
            
            this.translation = this.translationSin;
        end
        
        function make(this)
            this.validate();
            
            open(this.videoWriter);
            
            [cropRect, baseScale] = createCrops(this);
                 
            fprintf('Making %s...\nTotal frames: %d\n', this.videoWriter.Filename, size(cropRect,1));
            
            
            if strcmp(this.method, 'griddedInterpolant') && ~isa(this.Image, 'double')
                fprintf('Converting image to single precision... ');
                this.Image = im2single(this.Image);
                fprintf('done.\n');
            end
               
            if ~this.antialias 
                Interpolant = griddedInterpolant(this.Image);
            end
            
            fprintf('Creating frame ');
            
            for k = 1:size(cropRect,1)
            
                fprintf(' %d', k);
                
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
                        Frame = C(1:this.frameSize(1),1:this.frameSize(2), :);
                    case 'griddedInterpolant'
                        xy = cropRect(k,[1 2]);
                        wh = flip(this.frameSize)/baseScale*cropRect(k,3);
                        x = linspace(xy(1), xy(1)-1+wh(1), this.frameSize(2));
                        y = linspace(xy(2), xy(2)-1+wh(2), this.frameSize(1));
                        
                        if this.antialias 
                            % griddedInterpolant does not provide low pass
                            % filtering, only aliasing. So we do it ourselves
                            d = max(diff(x(1:2)), diff(y(1:2)));
                            if d > 1
                                % @todo: we might want to use a filter that has
                                % a shaper cutoff and/or is more efficient.
                                Interpolant = griddedInterpolant(imgaussfilt(this.Image, d*this.filterKernelSize));
                                % fprintf('*');
                            else
                                Interpolant = griddedInterpolant(this.Image);
                            end
                        end
                        
                        if size(this.Image,3)>1
                            Frame = Interpolant({y,x,1:size(this.Image,3)});
                        else
                            Frame = Interpolant({y,x});
                        end
                end
                
                writeVideo(this.videoWriter,Frame);
            end
            
            close(this.videoWriter);
            fprintf('\ndone.\n');
        end
        
        function h = image(this, hAxis)
            if nargin < 2 || isempty(hAxis)
                hAxis = gca;
            end
            
            h = imshow(this.Image, 'Parent', hAxis);
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
            hAxis.XLim = [1 size(this.Image,2)];
            hAxis.YLim = [1 size(this.Image,1)];
            title(hAxis, this.videoWriter.Filename, 'Interpreter', 'none');
            
            if this.plotNFrames < size(cropRect,1)
                frames = round(linspace(1, size(cropRect,1), this.plotNFrames));
            else
                frames = 1:size(cropRect,1);
            end
                
            h = gobjects(size(frames));
            
            for i = 1:numel(frames)
                k = frames(i); 
                xy = cropRect(k,[1 2]);
                wh = flip(this.frameSize)/baseScale*cropRect(k,3);
                x = xy(1) + [0 0 1 1 0] * wh(1);
                y = xy(2) + [0 1 1 0 0] * wh(2);
                h(i) = plot(hAxis, x,y);
                h(i).DisplayName = sprintf('Frame %d', k);
                h(i).Color = interp1(linspace(0,1,size(hAxis.Parent.Colormap,1)), hAxis.Parent.Colormap, (frames(i)-frames(1))/frames(end));
            end
            
            legend(h([1 end]), 'Start', 'End', 'Location', 'NorthEastOutside');
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
            assert(strcmp(this.method, 'crop') || strcmp(this.method, 'translate') || strcmp(this.method, 'griddedInterpolant'), ...
                'KenBurnsObj.method should be ''crop'' or ''translate'' or ''griddedInterpolant''');
            if strcmp(this.method, 'crop')
                warning('Crop is depreciated. Use griddedInterpolant.')
            end
            if strcmp(this.method, 'translate')
                warning('Translate is depreciated. Use griddedInterpolant.')
            end
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