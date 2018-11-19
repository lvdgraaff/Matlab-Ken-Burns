% Written by Leon van der Graaff
% Copyright (c) 2018 by the author. Some rights reserved, see LICENCE.

%% Minimal working example
Image = imread('cameraman.tif');
videoWriter = VideoWriter('kenburns','MPEG-4');
KenBurns = KenburnsObj(videoWriter, Image);

% Demo
clf;
imshow(Image); 
colormap gray; 
axis image;
KenBurns.plot();

%% Write to output file
KenBurns.make();

%% Demonstration of options
videoWriter = VideoWriter('kenburns_options','MPEG-4');
KenBurns = KenburnsObj(videoWriter, Image);
KenBurns.fps = 25; % [1/s]
KenBurns.frameSize = [256 256]; % [height width]
KenBurns.duration = 2; % [s]
KenBurns.startRect = [1 1 1]; % x, y, scale
KenBurns.endRect = [50 10 .7]; % x, y, scale
KenBurns.translation = KenBurns.translationLin;

% demo
clf;
imshow(Image); 
colormap gray; 
axis image;
KenBurns.plot();

% Write to output file
KenBurns.make();

%% Chaining of translation effects
videoWriter = VideoWriter('kenburns_chained','MPEG-4');
KenBurns = KenburnsObj(videoWriter, Image);
KenBurns.translation = @(t) KenBurns.translationBackForth(KenBurns.translationSin(t));

% demo
clf;
imshow(Image); 
colormap gray; 
axis image;
KenBurns.plot();

KenBurns.make();

%% For very large images
% the default 'translation' method is computationally expensive 
% this can be reduced at the expense of some aliasing at high zoom levels
% by setting KenBurns.method = 'crop';

videoWriter = VideoWriter('kenburns_crop','MPEG-4');
KenBurns = KenburnsObj(videoWriter, Image);
KenBurns.duration = 3;
KenBurns.method = 'crop';

% demo
% don't image the Canvas, just the crops
clf;
colormap gray; 
axis image;
KenBurns.plot();

KenBurns.make();
