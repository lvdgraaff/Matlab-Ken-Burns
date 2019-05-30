% Written by Leon van der Graaff
% Copyright (c) 2018 by the author. Some rights reserved, see LICENCE.

%% Minimal working example
Image = imread('cameraman.tif');
videoWriter = VideoWriter('kenburns','MPEG-4');
KenBurns = KenburnsObj(videoWriter, Image);

% Demo
clf;
KenBurns.image();
KenBurns.plot();

% write
KenBurns.make();

%% Color image
Image = imread('autumn.tif');
videoWriter = VideoWriter('kenburns_color','MPEG-4');
KenBurns = KenburnsObj(videoWriter, Image);

% Demo
clf;
KenBurns.image();
KenBurns.plot();

% write
KenBurns.make();

%% Demonstration of options
Image = imread('cameraman.tif');
videoWriter = VideoWriter('kenburns_options','MPEG-4');
videoWriter.FrameRate = 25;
KenBurns = KenburnsObj(videoWriter, Image);
KenBurns.frameSize = [256 256]; % [height width]
KenBurns.duration = 2; % [s]
KenBurns.startRect = [1 1 1]; % x, y, scale
KenBurns.endRect = [50 10 .7]; % x, y, scale
KenBurns.translation = KenBurns.translationLin;

% demo
clf;
KenBurns.image();
KenBurns.plot();

% write
KenBurns.make();

%% Chaining of transition effects
Image = imread('cameraman.tif');
videoWriter = VideoWriter('kenburns_chained','MPEG-4');
KenBurns = KenburnsObj(videoWriter, Image);
KenBurns.translation = @(t) KenBurns.translationCos(KenBurns.translationBackForth(t));

% demo
clf;
KenBurns.image();
KenBurns.plot();

% write
KenBurns.make();
