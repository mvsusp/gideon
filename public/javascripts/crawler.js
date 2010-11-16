$(function() {
	$.getJSON('/next_page.json', function(data) {
		result = reduce(data);
	});
});

reduce = function(data) {
    result = word_count(data.page)
		$.post('/submit_page', { results: JSON.stringify(result), id: data._id.$oid }, function(e) {
			alert(e);
		});
	}

word_count = function(data) {
		var sum = 0;
    data.replace(',','')
		var words = data.split(/ /).sort();
    result = {}
    for (var i = 0; i < words.length; i++) {
      var word = words[i];
      if(result[word]){
        result[word] += 1;
      }else{
        result[word] = 0;
      }
    }
    return result;
}
