function [ image_output ] = rgb_to_hsv( image_matrix )
%Takes a three-dimensional image matrix of an RBG image as input.
%Returns a three-dimension image matrix of an HSV image as output!
%   Detailed explanation goes here

%used to control loop counters later
%array_size(1) = rows array_size(2) = cols
array_size = size(image_matrix);


R = image_matrix(:, :, 1);
G = image_matrix(:, :, 2);
B = image_matrix(:, :, 3);

%cast as double in case of fractions.
R = double(R)/255;
G = double(G)/255;
B = double(B)/255;

%need max and min to find delta.
Cmax = max(R, max(G, B));
Cmin = min(R, min(G, B));

%delta is used in hue and saturation calculations!
delta = Cmax - Cmin; 

%Preallocate space for H so this program runs faster than molassses
H = zeros(array_size(1), array_size(2));


%calculate hue
for i = 1:array_size(1)
    for j = 1:array_size(2)
        if Cmax(i,j) == R(i,j)
            H(i,j) = (pi/3) * mod(((G(i,j)-B(i,j))/delta(i,j)), 6);
        elseif Cmax(i,j) == G(i,j)
            H(i,j) = (pi/3) * ((B(i,j)-R(i,j))/delta(i,j) + 2);
        elseif Cmax(i,j) == B(i,j)
            H(i,j) = (pi/3) * ((R(i,j)-G(i,j))/delta(i,j) + 4);
        elseif delta(i,j) == 0
            %delta = 0 means hue is all 0's
            H(i,j) = 0;
        end
    end
end
H_max = max(max(H));
H_min = min(min(H));
H = (H - H_min)*255/(H_max-H_min);

%calculate saturation
if delta == 0
    S = R * 0;
else
    S = 255* (delta ./ Cmax);
end

%Calculate value
V = 255* Cmax;

image_output(:, :, 1) = H;
image_output(:, :, 2) = S;
image_output(:, :, 3) = V;

image_output = uint8(image_output);

end

