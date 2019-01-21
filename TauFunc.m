function tau = TauFunc(img)

tau = ones(size(img));

if(img >= (250/255))
    tau = 0;
end 

h = 1 - (250/255 - img) / (50/255);

if(img >= (200/255) & img < (250/255))
    tau = 1 - 3 * h.^2 + 2 * h.^3;
end


end