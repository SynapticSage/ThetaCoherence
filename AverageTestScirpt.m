output = grams.output;

for i = 1:size(output,1)
	for j = 1:size(output,2)
		for k = 1:size(output,3)
			for l = 1:size(output,4)

				o = output(i,j,k,l);
				o = o{1};
				
				if isstruct(o)
					
					size(o)
					
					S(i,j,k,l,:,:) = o.S;
					
					
				end
				
			end
		end
	end
end
