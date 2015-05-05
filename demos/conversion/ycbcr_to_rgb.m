function [ image_output ] = ycbcr_to_rgb( image_matrix )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

Y = image_matrix(:, :, 1);
Cb = image_matrix(:, :, 2);
Cr = image_matrix(:, :, 3);

Y = double(Y);
Cb = double(Cb);
Cr = double(Cr);

R = 298.082*Y/256 + 408.583*Cr/256 -222.921;
G = 298.082*Y/256 - 100.291*Cb/256 - 208.120*Cr/256 + 135.576;
B = 298.082*(Y)/256 + 516.412*Cb/256 - 276.836;

image_output(:, :, 1) = R;
image_output(:, :, 2) = G;
image_output(:, :, 3) = B;

image_output = uint8(image_output);

end

