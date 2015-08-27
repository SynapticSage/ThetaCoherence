function subs = getAllSubs(object, animalField, dataField)
% Function finds all subscripts in our objects that have data. In a
% forthcoming special mode, there will also be an ability to find out who
% who have specific types of data, e.g. coherograms. I intend to use this
% method to get a pretty trivial list of subs to for-loop over, instead of
% painfully having to rely on paramSets to pass in hard-coded subs to
% process. This will be unavoidable for the very first object that's
% generated, the acquisition, but subsequent downstream functions will not
% have to rely so heavily on it.


if isstruct(object)					% if users pass in parrent structure
	
	numstrc = numel(object);

	complete_sub_list = [];			% change this to preallocation to run faster
	
	for a = 1:numstrc
		
		field_list = fields(object(a));
		field_to_read = field_list{2};
		cell_object = object(a).(field_to_read);

		single_cell_sub = getCellSubs(cell_object);
		struct_terms = a * ones(size(single_cell_sub,1),1);
		
		complete_sub_list = [struct_terms single_cell_sub];
		
	end
	
elseif iscell(object)
	
	complete_sub_list = getCellSubs(object);
	
else
	disp('Invalid data type provided to getAllSubs');
end

sub = complete_sub_list;

return;			% true end of parent function

%% HELPER FUNCTIONS

	function idx_list = getCellSubs(object)
	
	idx_list = []
	
	num_i1 = size(object,1);
	num_i2 = size(object,2);
	num_i3 = size(object,3);
	num_i4 = size(object,4);
	num_i5 = size(object,5);
	
	for i1 = 1:num_i1
	for i2 = 1:num_i2
	for i3 = 1:num_i3
	for i4 = 1:num_i4
	for i5 = 1:num_i5
		
		maybe_has_data = object{i1,i2,i3,i4,i5};
		
		if isstruct(maybe_has_data) || ~isempty(maybe_has_data)
			idx_list = [idx_list; i1 i2 i3 i4 i5];
		end
		
	end
	end
	end
	end
	end

end

end

